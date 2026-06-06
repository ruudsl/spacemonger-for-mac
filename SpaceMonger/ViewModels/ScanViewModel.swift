import SwiftUI
import AppKit
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

    enum ViewMode: String, CaseIterable, Identifiable {
        case sunburst, treemap
        var id: String { rawValue }
        var label: String { self == .sunburst ? "Sunburst" : "Treemap" }
        var symbol: String { self == .sunburst ? "circle.hexagongrid" : "square.grid.3x3.fill" }
    }

    enum ColorMode: String, CaseIterable, Identifiable {
        case rainbow, byType, byDepth
        var id: String { rawValue }
        var label: String {
            switch self {
            case .rainbow: return "By Folder"
            case .byType: return "By File Type"
            case .byDepth: return "By Depth"
            }
        }
    }

    // Start screen
    @Published var volumes: [VolumeInfo] = []
    let recentScans = RecentScansStore()
    let excludes = ExcludeStore()

    // Save / load / compare
    @Published var comparison: ScanComparison?
    @Published private(set) var isComparing = false
    @Published private(set) var loadedFromFile = false
    @Published var showTechSpecs = false

    // Display options
    @Published var viewMode: ViewMode = .sunburst
    @Published var colorMode: ColorMode = .rainbow
    @Published var searchText: String = ""
    @Published var focus = FocusCriteria() {
        didSet { recomputeFocusMatches() }
    }
    @Published private(set) var focusMatchIDs: Set<UUID> = []
    var isFocusActive: Bool { focus.isActive }

    // Diagnostics
    @Published private(set) var unreadableDirectories = 0
    @Published private(set) var hasFullDiskAccess = true
    @Published var accessBannerDismissed = false

    var shouldShowAccessBanner: Bool {
        guard !accessBannerDismissed else { return false }
        return unreadableDirectories > 0 || !hasFullDiskAccess
    }

    func dismissAccessBanner() { accessBannerDismissed = true }

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
    private var activeScopedURL: URL?

    var isScanning: Bool { scanState == .scanning }
    var hasResult: Bool { rootNode != nil && scanState == .done }
    var rescanDisabled: Bool { scannedURL == nil || isScanning }
    var breadcrumb: [FileNode] { focusNode?.pathFromRoot ?? [] }
    var collectorTotalSize: Int64 { collector.reduce(0) { $0 + $1.size } }

    // MARK: - Volumes

    func loadVolumes() {
        volumes = VolumeInfo.mountedVolumes()
        hasFullDiskAccess = DiskAccess.hasFullDiskAccess()
    }

    // MARK: - Scanning

    func scan(volume: VolumeInfo) {
        setScopedURL(nil)
        startScan(url: volume.url, volume: volume)
    }

    func scan(folder url: URL) {
        setScopedURL(nil)
        startScan(url: url, volume: nil)
    }

    func scanRecent(_ scan: RecentScan) {
        guard let url = recentScans.resolve(scan) else {
            lastError = "Couldn't open “\(scan.name)”. It may have been moved, renamed or disconnected."
            return
        }
        setScopedURL(url)
        let volume = scan.isVolume
            ? VolumeInfo.mountedVolumes().first { $0.url.path == url.path }
            : nil
        startScan(url: url, volume: volume)
    }

    func rescan() {
        guard let url = scannedURL else { return }
        startScan(url: url, volume: scannedVolume)
    }

    private func setScopedURL(_ url: URL?) {
        if let old = activeScopedURL, old.path != url?.path {
            old.stopAccessingSecurityScopedResource()
        }
        activeScopedURL = url
    }

    func rescanAsAdministrator() {
        guard let url = scannedURL else { return }
        startScan(url: url, volume: scannedVolume, privileged: true)
    }

    private func startScan(url: URL, volume: VolumeInfo?, privileged: Bool = false) {
        cancelScan()

        rootNode = nil
        focusNode = nil
        selectedNode = nil
        hoveredNode = nil
        sunburstLayout = nil
        collector = []
        scanSummary = nil
        unreadableDirectories = 0
        accessBannerDismissed = false
        loadedFromFile = false
        scannedVolume = volume
        scannedURL = url
        scanProgress = nil
        scanState = .scanning

        let displayName = volume?.name ?? (url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
        recentScans.remember(url: url, name: displayName, isVolume: volume != nil)

        let token = CancelToken()
        cancelToken = token
        let matcher = ExcludeMatcher(patterns: excludes.patterns)
        let start = Date()

        scanTask = Task.detached(priority: .userInitiated) {
            do {
                let result: DiskScanner.Result
                if privileged {
                    let root = try PrivilegedScanner.scan(
                        at: url,
                        exclude: matcher,
                        isCancelled: { token.isCancelled },
                        progress: { count in
                            DispatchQueue.main.async {
                                guard self.cancelToken === token else { return }
                                self.scanProgress = .init(scannedItems: count, scannedBytes: 0,
                                                          currentPath: loc("Reading as administrator…"))
                            }
                        }
                    )
                    result = DiskScanner.Result(root: root, unreadableDirectories: 0)
                } else {
                    let scanner = DiskScanner(exclude: matcher)
                    result = try scanner.scan(
                        at: url,
                        isCancelled: { token.isCancelled },
                        progress: { progress in
                            DispatchQueue.main.async {
                                guard self.cancelToken === token else { return }
                                self.scanProgress = progress
                            }
                        }
                    )
                }
                if token.isCancelled { return }
                let elapsed = Date().timeIntervalSince(start)
                DispatchQueue.main.async {
                    guard self.cancelToken === token else { return }
                    self.finishScan(result: result, volume: volume, elapsed: elapsed)
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
        setScopedURL(nil)
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

    private func finishScan(result: DiskScanner.Result, volume: VolumeInfo?, elapsed: TimeInterval) {
        scanTask = nil
        cancelToken = nil
        let root = result.root
        if let volume {
            addHiddenSpace(to: root, volume: volume)
        }
        root.sortBySizeDescending(recursive: false)

        rootNode = root
        focusNode = root
        selectedNode = nil
        unreadableDirectories = result.unreadableDirectories
        hasFullDiskAccess = DiskAccess.hasFullDiskAccess()
        scanState = .done
        rebuildSunburst()
        recomputeFocusMatches()

        let count = scanProgress?.scannedItems ?? root.fileCount
        scanSummary = locf(loc("%@ items · %@ · scanned in %@s"),
                           Formatting.count(count),
                           Formatting.bytes(root.size),
                           String(format: "%.1f", elapsed))
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

    // MARK: - Display helpers

    /// Resolves a node's colour for the current colour mode. `hue` is the
    /// inherited top-level hue used by the "By Folder" mode.
    func color(for node: FileNode, hue: Double, depth: Int) -> Color {
        if node.isHiddenSpace { return Color(white: 0.55) }
        switch colorMode {
        case .rainbow: return NodeColor.color(hue: hue, depth: depth)
        case .byType:  return NodeColor.colorForType(node.fileExtension, depth: depth)
        case .byDepth: return NodeColor.colorForDepth(depth)
        }
    }

    /// Children of the focused folder, filtered by the search text and focus mask.
    var filteredChildren: [FileNode] {
        var kids = focusNode?.children ?? []
        if focus.isActive {
            kids = kids.filter { focusMatchIDs.contains($0.id) }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            kids = kids.filter { $0.name.lowercased().contains(query) }
        }
        return kids
    }

    func isInFocus(_ node: FileNode) -> Bool {
        focusMatchIDs.contains(node.id)
    }

    func clearFocus() {
        focus = FocusCriteria()
    }

    /// Rebuilds the set of node ids that match the focus mask (matching files and
    /// all their ancestors, so paths to matches stay visible).
    private func recomputeFocusMatches() {
        guard focus.isActive, let root = rootNode else {
            if !focusMatchIDs.isEmpty { focusMatchIDs = [] }
            return
        }
        var matches: Set<UUID> = []
        func visit(_ node: FileNode) -> Bool {
            var hasMatch = false
            if node.children.isEmpty {
                hasMatch = focus.matchesFile(node)
            } else {
                for child in node.children where visit(child) { hasMatch = true }
            }
            if hasMatch { matches.insert(node.id) }
            return hasMatch
        }
        _ = visit(root)
        focusMatchIDs = matches
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

    func open(_ node: FileNode) {
        guard node.isRealFileSystemItem else { return }
        NSWorkspace.shared.open(node.url)
    }

    func copyPath(_ node: FileNode) {
        guard node.isRealFileSystemItem else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(node.url.path, forType: .string)
    }

    // MARK: - Save / load / compare

    var canSaveScan: Bool { rootNode != nil }
    var suggestedFileName: String {
        let base = scannedVolume?.name ?? rootNode?.name ?? "Scan"
        return "\(base).\(ScanArchive.fileExtension)"
    }

    func saveCurrentScan(to url: URL) {
        guard let root = rootNode else { return }
        let name = scannedVolume?.name ?? root.name
        do {
            try ScanArchive(root: root, displayName: name).write(to: url)
        } catch {
            lastError = locf(loc("Couldn't save the scan: %@"), error.localizedDescription)
        }
    }

    /// Loads either a native `.smscan` archive or a `.gpscan` file.
    private func loadTree(from url: URL) throws -> (root: FileNode, name: String) {
        if url.pathExtension.lowercased() == "gpscan" {
            return try GPScanImporter.importTree(from: url)
        }
        let archive = try ScanArchive.read(from: url)
        return (archive.makeTree(), archive.displayName)
    }

    func openScan(from url: URL) {
        do {
            let (root, name) = try loadTree(from: url)
            cancelScan()
            setScopedURL(nil)
            root.sortBySizeDescending(recursive: true)

            rootNode = root
            focusNode = root
            selectedNode = nil
            hoveredNode = nil
            collector = []
            scannedVolume = nil
            scannedURL = URL(fileURLWithPath: root.url.path)
            unreadableDirectories = 0
            accessBannerDismissed = true
            loadedFromFile = true
            scanState = .done
            scanSummary = locf(loc("Loaded “%@” · %@"), name, Formatting.bytes(root.size))
            rebuildSunburst()
            recomputeFocusMatches()
        } catch {
            lastError = locf(loc("Couldn't open the scan file: %@"), error.localizedDescription)
        }
    }

    func compareWith(url: URL) {
        guard let current = rootNode else { return }
        isComparing = true
        let currentName = scannedVolume?.name ?? current.name
        Task.detached(priority: .userInitiated) {
            do {
                let (other, otherName) = try self.loadTree(from: url)
                let result = ScanComparison.compare(current: current, currentName: currentName,
                                                    other: other, otherName: otherName)
                DispatchQueue.main.async {
                    self.comparison = result
                    self.isComparing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastError = locf(loc("Couldn't open the scan file: %@"), error.localizedDescription)
                    self.isComparing = false
                }
            }
        }
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
        let candidates = nodes.filter { $0.isRealFileSystemItem && $0.parent != nil }
        guard !candidates.isEmpty else { return }

        // Safety stopper: never trash system-critical locations.
        let blocked = candidates.filter { SystemPaths.isProtected($0.url) }
        let targets = candidates.filter { !SystemPaths.isProtected($0.url) }

        if !blocked.isEmpty {
            let names = blocked.map { $0.name }.joined(separator: ", ")
            lastError = locf(loc("These are protected system items and were not deleted: %@"), names)
            for node in blocked { collector.removeAll { $0 === node } }
        }
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
        recomputeFocusMatches()

        if !result.failures.isEmpty {
            let names = result.failures.map { $0.url.lastPathComponent }.joined(separator: ", ")
            lastError = locf(loc("Could not move to Trash: %@"), names)
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
