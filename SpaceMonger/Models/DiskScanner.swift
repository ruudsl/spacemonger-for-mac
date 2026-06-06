import Foundation

/// Recursively measures on-disk usage and builds a `FileNode` tree.
///
/// The scan runs synchronously on whatever thread/Task calls `scan`; callers are
/// expected to run it off the main thread (see `ScanViewModel`). Progress is
/// reported through a throttled callback and cancellation is cooperative.
struct DiskScanner {

    struct Progress {
        var scannedItems: Int
        var scannedBytes: Int64
        var currentPath: String
    }

    private static let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isRegularFileKey,
        .isSymbolicLinkKey,
        .isPackageKey,
        .nameKey,
        .fileSizeKey,
        .fileAllocatedSizeKey,
        .totalFileAllocatedSizeKey,
        .volumeIdentifierKey
    ]

    /// Builds the tree rooted at `url`.
    ///
    /// - Parameters:
    ///   - url: directory (or file) to measure.
    ///   - isCancelled: polled frequently; when it returns `true` the scan stops
    ///     and throws `CancellationError`.
    ///   - progress: called periodically (throttled) on an arbitrary thread.
    func scan(at url: URL,
              isCancelled: () -> Bool,
              progress: @escaping (Progress) -> Void) throws -> FileNode {

        let fm = FileManager.default
        var counter = ScanCounter(progress: progress)

        // Identify the volume we start on so we never cross into other mounts.
        let rootValues = try? url.resourceValues(forKeys: [.volumeIdentifierKey])
        let rootVolumeID = rootValues?.allValues[.volumeIdentifierKey] as? NSObject

        let node = try scanDirectory(
            url: url,
            volumeID: rootVolumeID,
            fileManager: fm,
            isCancelled: isCancelled,
            counter: &counter
        )
        counter.flush(force: true)
        node.sortBySizeDescending(recursive: true)
        return node
    }

    // MARK: - Recursion

    private func scanDirectory(url: URL,
                               volumeID: NSObject?,
                               fileManager fm: FileManager,
                               isCancelled: () -> Bool,
                               counter: inout ScanCounter) throws -> FileNode {

        if isCancelled() { throw CancellationError() }

        let name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let directory = FileNode(url: url, name: name, kind: .directory)

        let contents: [URL]
        do {
            contents = try fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(Self.resourceKeys),
                options: []
            )
        } catch {
            // No permission / vanished: treat as an empty, zero-sized folder.
            return directory
        }

        var children: [FileNode] = []
        children.reserveCapacity(contents.count)
        var totalSize: Int64 = 0
        var totalCount = 0

        for childURL in contents {
            if isCancelled() { throw CancellationError() }

            let values = try? childURL.resourceValues(forKeys: Self.resourceKeys)

            // Don't follow symlinks (avoids cycles and double-counting).
            if values?.isSymbolicLink == true {
                let node = FileNode(url: childURL,
                                    name: values?.name ?? childURL.lastPathComponent,
                                    kind: .file,
                                    size: 0,
                                    fileCount: 1)
                children.append(node)
                totalCount += 1
                continue
            }

            // Don't cross volume boundaries (e.g. nested mounts under /Volumes).
            if let volumeID,
               let childVolume = values?.allValues[.volumeIdentifierKey] as? NSObject,
               !volumeID.isEqual(childVolume) {
                continue
            }

            let isPackage = values?.isPackage ?? false
            let isDirectory = values?.isDirectory ?? false

            if isDirectory {
                let childNode = try scanDirectory(
                    url: childURL,
                    volumeID: volumeID,
                    fileManager: fm,
                    isCancelled: isCancelled,
                    counter: &counter
                )
                // Mark packages so the UI can show them as app-like leaves while
                // still allowing the user to drill inside.
                let node = isPackage
                    ? FileNode(url: childURL, name: childNode.name, kind: .directory,
                               isPackage: true, size: childNode.size,
                               fileCount: childNode.fileCount, children: childNode.children)
                    : childNode
                children.append(node)
                totalSize += node.size
                totalCount += node.fileCount
            } else {
                let bytes = Self.allocatedSize(values)
                let node = FileNode(url: childURL,
                                    name: values?.name ?? childURL.lastPathComponent,
                                    kind: .file,
                                    size: bytes,
                                    fileCount: 1)
                children.append(node)
                totalSize += bytes
                totalCount += 1
                counter.add(bytes: bytes, items: 1, path: childURL.path)
            }
        }

        directory.setChildren(children)
        directory.size = totalSize
        directory.fileCount = totalCount
        counter.add(bytes: 0, items: 1, path: url.path)
        return directory
    }

    // MARK: - Helpers

    static func allocatedSize(_ values: URLResourceValues?) -> Int64 {
        if let v = values?.totalFileAllocatedSize { return Int64(v) }
        if let v = values?.fileAllocatedSize { return Int64(v) }
        if let v = values?.fileSize { return Int64(v) }
        return 0
    }
}

/// Accumulates progress and flushes to the callback at most ~20×/second worth of
/// item batches, so a fast scan doesn't drown the main thread in updates.
private struct ScanCounter {
    let progress: (DiskScanner.Progress) -> Void
    private var items = 0
    private var bytes: Int64 = 0
    private var lastPath = ""
    private var itemsSinceFlush = 0

    init(progress: @escaping (DiskScanner.Progress) -> Void) {
        self.progress = progress
    }

    mutating func add(bytes newBytes: Int64, items newItems: Int, path: String) {
        bytes += newBytes
        items += newItems
        lastPath = path
        itemsSinceFlush += newItems
        if itemsSinceFlush >= 1500 {
            flush(force: false)
        }
    }

    mutating func flush(force: Bool) {
        guard force || itemsSinceFlush > 0 else { return }
        itemsSinceFlush = 0
        progress(.init(scannedItems: items, scannedBytes: bytes, currentPath: lastPath))
    }
}
