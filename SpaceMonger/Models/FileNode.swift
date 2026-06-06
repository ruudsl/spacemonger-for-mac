import Foundation

/// A single entry (file, folder or synthetic "hidden space" placeholder) in the
/// scanned file tree. Reference type so children can point back to their parent
/// and so the tree can be mutated in place when items are deleted.
final class FileNode: Identifiable, Hashable {

    enum Kind {
        case file
        case directory
        /// Space reported as used by the volume that we could not attribute to
        /// any concrete file (system data, purgeable space, other users, files
        /// we were not allowed to read). Modelled after DaisyDisk's
        /// "hidden space" segment.
        case hiddenSpace
    }

    let id = UUID()
    let url: URL
    let name: String
    let kind: Kind
    /// `true` for application bundles and other file-system packages.
    let isPackage: Bool

    /// Total size on disk in bytes, including all descendants.
    var size: Int64
    /// Number of files contained (self counts as 1 for a file).
    var fileCount: Int

    private(set) var children: [FileNode]
    weak var parent: FileNode?

    init(url: URL,
         name: String,
         kind: Kind,
         isPackage: Bool = false,
         size: Int64 = 0,
         fileCount: Int = 0,
         children: [FileNode] = []) {
        self.url = url
        self.name = name
        self.kind = kind
        self.isPackage = isPackage
        self.size = size
        self.fileCount = fileCount
        self.children = children
        for child in children { child.parent = self }
    }

    var isDirectory: Bool { kind == .directory }
    var isHiddenSpace: Bool { kind == .hiddenSpace }
    var isLeaf: Bool { children.isEmpty }

    /// Whether this node maps to a real on-disk item that can be revealed,
    /// previewed or trashed.
    var isRealFileSystemItem: Bool { kind != .hiddenSpace }

    func setChildren(_ newChildren: [FileNode]) {
        children = newChildren
        for child in newChildren { child.parent = self }
    }

    func addChild(_ child: FileNode) {
        child.parent = self
        children.append(child)
    }

    /// Removes a direct child and returns the freed byte count so callers can
    /// propagate the size change up the ancestor chain.
    @discardableResult
    func removeChild(_ child: FileNode) -> Int64 {
        guard let idx = children.firstIndex(where: { $0 === child }) else { return 0 }
        let freed = children[idx].size
        let freedCount = children[idx].fileCount
        children.remove(at: idx)
        size -= freed
        fileCount -= freedCount
        return freed
    }

    /// Sorts children (and optionally the whole subtree) by descending size,
    /// which is what the sunburst and list views expect.
    func sortBySizeDescending(recursive: Bool) {
        children.sort { $0.size > $1.size }
        if recursive {
            for child in children { child.sortBySizeDescending(recursive: true) }
        }
    }

    /// Fraction of `ancestor`'s size occupied by this node (0...1).
    func fraction(of ancestor: FileNode) -> Double {
        guard ancestor.size > 0 else { return 0 }
        return Double(size) / Double(ancestor.size)
    }

    /// The chain of nodes from the root down to (and including) this node.
    var pathFromRoot: [FileNode] {
        var chain: [FileNode] = []
        var node: FileNode? = self
        while let current = node {
            chain.append(current)
            node = current.parent
        }
        return chain.reversed()
    }

    var depthFromRoot: Int {
        var depth = 0
        var node = parent
        while let current = node {
            depth += 1
            node = current.parent
        }
        return depth
    }

    // MARK: - Hashable

    static func == (lhs: FileNode, rhs: FileNode) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
