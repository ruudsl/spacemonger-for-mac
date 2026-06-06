import SwiftUI
import Combine

/// Cooperative cancellation flag shared with the background scan.
final class CancelToken {
    private let lock = NSLock()
    private var cancelled = false
    var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelled
    }
    func cancel() {
        lock.lock(); cancelled = true; lock.unlock()
    }
}

/// Owns all app state: the scanned tree, navigation focus, selection, the
/// collector and the scan lifecycle. UI mutations are funnelled onto the main
/// thread; the heavy scan runs on a background task.
final class ScanViewModel: ObservableObject {

    enum ScanState: Equatable {
        case idle
        case scanning
        case done
        case failed(String)
    }

    // Start screen
    @Published var volumes: [VolumeInfo] = []

    // Scan lifecycle
    @Published private(set) var scanState: ScanState = .idle
    @Published private(set) var scanProgress: DiskScanner.Progress?
    @Published private(set) var scannedVolume: VolumeInfo?
    @Published private(set) var scanSummary: String?

    // The tree and navigation
    @Published private(set) var rootNode: FileNode?
    @Published private(set) var focusNode: FileNode?
    @Published var selectedNode: FileNode?
    @Published var hoveredNode: FileNode?
    @Published private(set) var sunburstLayout: SunburstLayout?

    // The collector
    @Published private(set) var collector: [FileNode] = []
    @Published var lastError: String?

    /// Bumped to force views to re-read the (mutated-in-place) tree after a
    /// deletion.
    @Published private(set) var revision = 0

    private var scanTask: Task<Void, Never>?
    private var cancelToken: CancelToken?
    private var scannedURL: URL?

    var isScanning: Bool { scanState == .scanning }
    var hasResult: Bool { rootNode != nil && scanState == .done }
    var rescanDisabled: Bool { scannedURL == nil || isScanning }
    var breadcrumb: [FileNode] { focusNode?.pathFromRoot ?? [] }
    var collectorTotalSize: Int64 { collector.reduce(0) { $0 + $1.size } }

    // MARK: - Volumes

    func loadVolumes() {
        volumes = VolumeInfo.mountedVolumes()
    }

    // MARK: - Scanning

    func scan(volume: VolumeInfo) {
        startScan(url: volume.url, volume: volume)
    }

    func scan(folder url: URL) {
        startScan(url: url, volume: nil)
    }

    func rescan() {
        guard let url = scannedURL else { return }
        startScan(url: url, volume: scannedVolume)
    }

    private func startScan(url: URL, volume: VolumeInfo?) {
        cancelScan()

        rootNode = nil
        focusNode = nil
        selectedNode = nil
        hoveredNode = nil
        sunburstLayout = nil
        collector = []
        scanSummary = nil
        scannedVolume = volume
        scannedURL = url
        scanProgress = nil
        scanState = .scanning

        let token = CancelToken()
        cancelToken = token
        let scanner = DiskScanner()
        let start = Date()

        scanTask = Task.detached(priority: .userInitiated) {
            do {
                let node = try scanner.scan(
                    at: url,
                    isCancelled: { token.isCancelled },
                    progress: { progress in
                        DispatchQueue.main.async {
                            guard self.cancelToken === token else { return }
                            self.scanProgress = progress
                        }
                    }
                )
                if token.isCancelled { return }
                let elapsed = Date().timeIntervalSince(start)
                DispatchQueue.main.async {
                    guard self.cancelToken === token else { return }
                    self.finishScan(root: node, volume: volume, elapsed: elapsed)
                }
            } catch is CancellationError {
                DispatchQueue.main.async {
                    guard self.cancelToken === token else { return }
                    self.scanState = .idle
                }
            } catch {
                DispatchQueue.main.async {
                    guard self.cancelToken === token else { return }
                    self.scanState = .failed(error.localizedDescription)
                }
            }
        }
    }

    func cancelScan() {
        cancelToken?.cancel()
        scanTask?.cancel()
        scanTask = nil
        cancelToken = nil
    }

    /// Returns to the disk selection screen, discarding the current scan.
    func backToStart() {
        cancelScan()
        rootNode = nil
        focusNode = nil
        selectedNode = nil
        hoveredNode = nil
        sunburstLayout = nil
        collector = []
        scanSummary = nil
        scanProgress = nil
        scannedVolume = nil
        scannedURL = nil
        scanState = .idle
    }

    private func finishScan(root: FileNode, volume: VolumeInfo?, elapsed: TimeInterval) {
        scanTask = nil
        cancelToken = nil
        if let volume {
            addHiddenSpace(to: root, volume: volume)
        }
        root.sortBySizeDescending(recursive: false)

        rootNode = root
        focusNode = root
        selectedNode = nil
        scanState = .done
        rebuildSunburst()

        let count = scanProgress?.scannedItems ?? root.fileCount
        scanSummary = "\(Formatting.count(count)) items · \(Formatting.bytes(root.size)) · scanned in \(String(format: "%.1f", elapsed))s"
    }

    /// Adds a synthetic node accounting for volume space we could not attribute
    /// to readable files (system/purgeable/protected data).
    private func addHiddenSpace(to root: FileNode, volume: VolumeInfo) {
        let used = volume.usedCapacity
        let unaccounted = used - root.size
        // Only show it when it's a meaningful chunk (>64 MB).
        guard unaccounted > 64 * 1024 * 1024 else { return }
        let hidden = FileNode(url: volume.url,
                              name: "System & hidden space",
                              kind: .hiddenSpace,
                              size: unaccounted,
                              fileCount: 0)
        root.addChild(hidden)
        root.size += unaccounted
    }

    // MARK: - Navigation

    func select(_ node: FileNode?) {
        selectedNode = node
    }

    func drill(into node: FileNode) {
        guard node.isRealFileSystemItem else { return }
        guard !node.children.isEmpty else { select(node); return }
        focusNode = node
        selectedNode = node
        hoveredNode = nil
        rebuildSunburst()
    }

    func navigateUp() {
        guard let parent = focusNode?.parent else { return }
        focusNode = parent
        selectedNode = parent
        hoveredNode = nil
        rebuildSunburst()
    }

    func navigate(to node: FileNode) {
        focusNode = node
        selectedNode = node
        hoveredNode = nil
        rebuildSunburst()
    }

    private func rebuildSunburst() {
        sunburstLayout = focusNode.map { SunburstLayout(focus: $0) }
    }

    // MARK: - Collector

    func isInCollector(_ node: FileNode) -> Bool {
        collector.contains { $0 === node }
    }

    func addToCollector(_ node: FileNode) {
        guard node.isRealFileSystemItem, !isInCollector(node) else { return }
        collector.append(node)
    }

    func removeFromCollector(_ node: FileNode) {
        collector.removeAll { $0 === node }
    }

    func clearCollector() {
        collector.removeAll()
    }

    func addURLsToCollector(_ urls: [URL]) {
        for url in urls {
            if let node = node(at: url) { addToCollector(node) }
        }
    }

    // MARK: - File operations

    func reveal(_ node: FileNode) {
        guard node.isRealFileSystemItem else { return }
        FinderActions.reveal(node.url)
    }

    func quickLook(_ node: FileNode?) {
        guard let node, node.isRealFileSystemItem else { return }
        QuickLookController.shared.preview([node.url])
    }

    func trash(_ node: FileNode) {
        trashNodes([node])
    }

    func deleteCollected() {
        trashNodes(collector)
    }

    private func trashNodes(_ nodes: [FileNode]) {
        let targets = nodes.filter { $0.isRealFileSystemItem && $0.parent != nil }
        guard !targets.isEmpty else { return }

        let result = FinderActions.moveToTrash(targets.map(\.url))
        let trashedURLs = Set(result.trashed.map { $0.standardizedFileURL })

        var focusInvalidated = false
        var changedParents: [FileNode] = []

        for node in targets where trashedURLs.contains(node.url.standardizedFileURL) {
            if let parent = node.parent { changedParents.append(parent) }
            if let focus = focusNode, isDescendantOrSelf(node, of: focus) || node === focus {
                focusInvalidated = true
            }
            removeFromTree(node)
            collector.removeAll { $0 === node }
        }

        // Keep every level along each affected branch sorted by size.
        for parent in changedParents {
            var current: FileNode? = parent
            while let node = current {
                node.sortBySizeDescending(recursive: false)
                current = node.parent
            }
        }

        if focusInvalidated {
            focusNode = rootNode
            selectedNode = nil
        } else if let selected = selectedNode, trashedURLs.contains(selected.url.standardizedFileURL) {
            selectedNode = nil
        }
        hoveredNode = nil

        revision += 1
        rebuildSunburst()

        if !result.failures.isEmpty {
            let names = result.failures.map { $0.url.lastPathComponent }.joined(separator: ", ")
            lastError = "Could not move to Trash: \(names)"
        }
    }

    private func removeFromTree(_ node: FileNode) {
        guard let parent = node.parent else { return }
        let freedSize = node.size
        let freedCount = node.fileCount
        parent.removeChild(node)            // adjusts parent.size / fileCount
        var ancestor = parent.parent
        while let a = ancestor {
            a.size -= freedSize
            a.fileCount -= freedCount
            ancestor = a.parent
        }
        node.parent = nil
    }

    private func isDescendantOrSelf(_ node: FileNode, of ancestor: FileNode) -> Bool {
        var current: FileNode? = ancestor
        while let c = current {
            if c === node { return true }
            current = c.parent
        }
        return false
    }

    // MARK: - Lookup

    /// Resolves a file URL back to a node by walking the tree from the root.
    func node(at url: URL) -> FileNode? {
        guard let root = rootNode else { return nil }
        let rootComponents = root.url.standardizedFileURL.pathComponents
        let targetComponents = url.standardizedFileURL.pathComponents
        guard targetComponents.count >= rootComponents.count,
              Array(targetComponents.prefix(rootComponents.count)) == rootComponents
        else { return nil }

        var current = root
        for component in targetComponents.dropFirst(rootComponents.count) {
            guard let next = current.children.first(where: { $0.url.lastPathComponent == component })
            else { return nil }
            current = next
        }
        return current
    }
}
