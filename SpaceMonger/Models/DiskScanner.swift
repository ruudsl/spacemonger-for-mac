import Foundation

/// Recursively measures on-disk usage and builds a `FileNode` tree.
///
/// The top-level directories of the scanned location are measured concurrently
/// across all CPU cores (`DispatchQueue.concurrentPerform`); each subtree is then
/// walked on its worker thread. Progress and the "unreadable" count are gathered
/// through thread-safe collectors. The whole scan runs on whatever background
/// task calls `scan`; cancellation is cooperative.
struct DiskScanner {

    /// Item names matching any of these globs are skipped during the scan.
    var exclude = ExcludeMatcher(patterns: [])

    /// Count the target size of symbolic links (still never recurse into them,
    /// to avoid cycles).
    var followSymlinks = false

    /// Reports (completed, total) top-level directories as they finish, for a
    /// live "filling in" feel during the scan. Called off the main thread.
    var onTopLevelProgress: ((Int, Int) -> Void)?

    struct Progress {
        var scannedItems: Int
        var scannedBytes: Int64
        var currentPath: String
    }

    struct Result {
        var root: FileNode
        var unreadableDirectories: Int
        var unreadableSample: [String] = []
    }

    // Only the keys we actually use, so `contentsOfDirectory` prefetches less.
    private static let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .isPackageKey,
        .nameKey,
        .totalFileAllocatedSizeKey,
        .fileAllocatedSizeKey,
        .volumeIdentifierKey,
        .fileResourceIdentifierKey,
        .linkCountKey
    ]

    func scan(at url: URL,
              isCancelled: @escaping () -> Bool,
              progress: @escaping (Progress) -> Void) throws -> Result {

        let fm = FileManager.default
        let reporter = ScanReporter(progress: progress)
        let unreadable = UnreadableCounter()
        let seen = SeenInodes()

        let rootValues = try? url.resourceValues(forKeys: [.volumeIdentifierKey])
        let rootVolumeID = rootValues?.allValues[.volumeIdentifierKey] as? NSObject

        let name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let root = FileNode(url: url, name: name, kind: .directory)

        let contents: [URL]
        do {
            contents = try fm.contentsOfDirectory(
                at: url, includingPropertiesForKeys: Array(Self.resourceKeys), options: [])
        } catch {
            root.isUnreadable = true
            return Result(root: root, unreadableDirectories: 1, unreadableSample: [url.path])
        }

        if isCancelled() { throw CancellationError() }

        // Partition the immediate children: files counted now, directories
        // queued for parallel scanning.
        var topFiles: [FileNode] = []
        var topDirs: [URL] = []
        var topDirIsPackage: [Bool] = []

        for childURL in contents {
            if exclude.matches(name: childURL.lastPathComponent) { continue }
            let values = try? childURL.resourceValues(forKeys: Self.resourceKeys)

            if values?.isSymbolicLink == true {
                let bytes = followSymlinks ? Self.symlinkTargetSize(childURL) : 0
                topFiles.append(FileNode(url: childURL,
                                         name: values?.name ?? childURL.lastPathComponent,
                                         kind: .file, size: bytes, fileCount: 1))
                reporter.add(bytes: bytes, items: 1, path: childURL.path)
                continue
            }
            if let rootVolumeID,
               let childVolume = values?.allValues[.volumeIdentifierKey] as? NSObject,
               !rootVolumeID.isEqual(childVolume) {
                continue
            }
            if values?.isDirectory == true {
                topDirs.append(childURL)
                topDirIsPackage.append(values?.isPackage ?? false)
            } else {
                let bytes = Self.countedSize(values, seen: seen)
                topFiles.append(FileNode(url: childURL,
                                         name: values?.name ?? childURL.lastPathComponent,
                                         kind: .file, size: bytes, fileCount: 1))
                reporter.add(bytes: bytes, items: 1, path: childURL.path)
            }
        }

        let results = ParallelResults(count: topDirs.count)
        DispatchQueue.concurrentPerform(iterations: topDirs.count) { i in
            if isCancelled() { results.markCancelled(); return }
            do {
                let node = try scanDirectory(url: topDirs[i], volumeID: rootVolumeID,
                                             fileManager: fm, isCancelled: isCancelled,
                                             reporter: reporter, unreadable: unreadable,
                                             seen: seen)
                if topDirIsPackage[i] {
                    let wrapped = FileNode(url: node.url, name: node.name, kind: .directory,
                                           isPackage: true, size: node.size,
                                           fileCount: node.fileCount, children: node.children)
                    wrapped.isUnreadable = node.isUnreadable
                    results.set(wrapped, at: i)
                } else {
                    results.set(node, at: i)
                }
                onTopLevelProgress?(results.markDone(), topDirs.count)
            } catch {
                results.markCancelled()
            }
        }

        if results.isCancelled || isCancelled() { throw CancellationError() }

        var children = topFiles
        for node in results.nodes { if let node { children.append(node) } }
        var total: Int64 = 0
        var count = 0
        for child in children { total += child.size; count += child.fileCount }
        root.setChildren(children)
        root.size = total
        root.fileCount = count

        reporter.flush()
        root.sortBySizeDescending(recursive: true)
        return Result(root: root, unreadableDirectories: unreadable.value,
                      unreadableSample: unreadable.sample)
    }

    // MARK: - Recursion (per worker thread)

    private func scanDirectory(url: URL,
                               volumeID: NSObject?,
                               fileManager fm: FileManager,
                               isCancelled: () -> Bool,
                               reporter: ScanReporter,
                               unreadable: UnreadableCounter,
                               seen: SeenInodes) throws -> FileNode {

        if isCancelled() { throw CancellationError() }

        let name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let directory = FileNode(url: url, name: name, kind: .directory)

        let contents: [URL]
        do {
            contents = try fm.contentsOfDirectory(
                at: url, includingPropertiesForKeys: Array(Self.resourceKeys), options: [])
        } catch {
            directory.isUnreadable = true
            unreadable.add(path: url.path)
            return directory
        }

        var children: [FileNode] = []
        children.reserveCapacity(contents.count)
        var totalSize: Int64 = 0
        var totalCount = 0

        for childURL in contents {
            if isCancelled() { throw CancellationError() }
            if exclude.matches(name: childURL.lastPathComponent) { continue }

            let values = try? childURL.resourceValues(forKeys: Self.resourceKeys)

            if values?.isSymbolicLink == true {
                let bytes = followSymlinks ? Self.symlinkTargetSize(childURL) : 0
                children.append(FileNode(url: childURL,
                                         name: values?.name ?? childURL.lastPathComponent,
                                         kind: .file, size: bytes, fileCount: 1))
                totalSize += bytes
                totalCount += 1
                if bytes > 0 { reporter.add(bytes: bytes, items: 1, path: childURL.path) }
                continue
            }
            if let volumeID,
               let childVolume = values?.allValues[.volumeIdentifierKey] as? NSObject,
               !volumeID.isEqual(childVolume) {
                continue
            }

            if values?.isDirectory == true {
                let childNode = try scanDirectory(url: childURL, volumeID: volumeID,
                                                  fileManager: fm, isCancelled: isCancelled,
                                                  reporter: reporter, unreadable: unreadable,
                                                  seen: seen)
                let node: FileNode
                if values?.isPackage == true {
                    node = FileNode(url: childURL, name: childNode.name, kind: .directory,
                                    isPackage: true, size: childNode.size,
                                    fileCount: childNode.fileCount, children: childNode.children)
                    node.isUnreadable = childNode.isUnreadable
                } else {
                    node = childNode
                }
                children.append(node)
                totalSize += node.size
                totalCount += node.fileCount
            } else {
                let bytes = Self.countedSize(values, seen: seen)
                children.append(FileNode(url: childURL,
                                         name: values?.name ?? childURL.lastPathComponent,
                                         kind: .file, size: bytes, fileCount: 1))
                totalSize += bytes
                totalCount += 1
                reporter.add(bytes: bytes, items: 1, path: childURL.path)
            }
        }

        directory.setChildren(children)
        directory.size = totalSize
        directory.fileCount = totalCount
        reporter.add(bytes: 0, items: 1, path: url.path)
        return directory
    }

    /// Size of a symlink's target file (0 for directory targets, which we never
    /// follow, or unreadable targets).
    static func symlinkTargetSize(_ url: URL) -> Int64 {
        let resolved = url.resolvingSymlinksInPath()
        guard let values = try? resolved.resourceValues(forKeys: [
            .isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey
        ]) else { return 0 }
        return values.isRegularFile == true ? allocatedSize(values) : 0
    }

    static func allocatedSize(_ values: URLResourceValues?) -> Int64 {
        if let v = values?.totalFileAllocatedSize { return Int64(v) }
        if let v = values?.fileAllocatedSize { return Int64(v) }
        if let v = values?.fileSize { return Int64(v) }
        return 0
    }

    /// On-disk size for a regular file, counting a hard-linked inode only once.
    /// A file with multiple hard links (common in Time Machine local snapshots,
    /// and pnpm/Homebrew stores) otherwise gets counted once per link and badly
    /// inflates the total. The first link encountered carries the size; the rest
    /// report 0. Files with a single link skip the (locked) set entirely.
    static func countedSize(_ values: URLResourceValues?, seen: SeenInodes) -> Int64 {
        let bytes = allocatedSize(values)
        let linkCount = (values?.allValues[.linkCountKey] as? Int) ?? 1
        if linkCount > 1, let id = values?.fileResourceIdentifier, !seen.firstSighting(id) {
            return 0
        }
        return bytes
    }
}

// MARK: - Thread-safe collectors

/// Throttled, thread-safe progress reporting shared by all scan workers.
private final class ScanReporter {
    private let progress: (DiskScanner.Progress) -> Void
    private let lock = NSLock()
    private var items = 0
    private var bytes: Int64 = 0
    private var lastPath = ""
    private var sinceFlush = 0

    init(progress: @escaping (DiskScanner.Progress) -> Void) {
        self.progress = progress
    }

    func add(bytes newBytes: Int64, items newItems: Int, path: String) {
        lock.lock()
        bytes += newBytes
        items += newItems
        lastPath = path
        sinceFlush += newItems
        if sinceFlush >= 2000 {
            let snapshot = DiskScanner.Progress(scannedItems: items, scannedBytes: bytes, currentPath: lastPath)
            sinceFlush = 0
            lock.unlock()
            progress(snapshot)
        } else {
            lock.unlock()
        }
    }

    func flush() {
        lock.lock()
        let snapshot = DiskScanner.Progress(scannedItems: items, scannedBytes: bytes, currentPath: lastPath)
        lock.unlock()
        progress(snapshot)
    }
}

/// Thread-safe set of file identities already counted, shared across all scan
/// workers so a hard-linked inode contributes its on-disk size only once.
final class SeenInodes {
    private let lock = NSLock()
    private var seen = Set<InodeKey>()

    /// Returns `true` the first time this identity is seen, `false` afterwards.
    func firstSighting(_ identifier: any NSObjectProtocol) -> Bool {
        let key = InodeKey(id: identifier)
        lock.lock(); defer { lock.unlock() }
        return seen.insert(key).inserted
    }
}

/// Hashable wrapper around an opaque `fileResourceIdentifier` so it can live in
/// a Swift `Set`. The identifier uniquely names a file within its volume.
private struct InodeKey: Hashable {
    let id: any NSObjectProtocol
    static func == (lhs: InodeKey, rhs: InodeKey) -> Bool { lhs.id.isEqual(rhs.id) }
    func hash(into hasher: inout Hasher) { hasher.combine(id.hash) }
}

private final class UnreadableCounter {
    private let lock = NSLock()
    private var count = 0
    private var samples: [String] = []
    func add(path: String) {
        lock.lock()
        count += 1
        if samples.count < 5 { samples.append(path) }
        lock.unlock()
    }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    var sample: [String] { lock.lock(); defer { lock.unlock() }; return samples }
}

private final class ParallelResults {
    private let lock = NSLock()
    private(set) var nodes: [FileNode?]
    private var cancelled = false

    init(count: Int) { nodes = [FileNode?](repeating: nil, count: count) }

    private var done = 0

    func set(_ node: FileNode, at index: Int) {
        lock.lock(); nodes[index] = node; lock.unlock()
    }
    func markDone() -> Int { lock.lock(); done += 1; let d = done; lock.unlock(); return d }
    func markCancelled() { lock.lock(); cancelled = true; lock.unlock() }
    var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
}
