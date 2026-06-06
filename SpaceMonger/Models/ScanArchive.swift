import Foundation

/// On-disk format for saving and re-opening a scan (`.smscan`, JSON).
struct ScanArchive: Codable {
    static let fileExtension = "smscan"

    var version: Int = 1
    var rootPath: String
    var displayName: String
    var date: Date
    var totalSize: Int64
    var root: Node

    /// Codable mirror of `FileNode`.
    struct Node: Codable {
        var name: String
        var path: String
        var kind: String        // "file" | "directory" | "hidden"
        var isPackage: Bool
        var isUnreadable: Bool
        var size: Int64
        var fileCount: Int
        var children: [Node]
    }

    // MARK: - Encode

    init(root: FileNode, displayName: String, date: Date = Date()) {
        self.rootPath = root.url.path
        self.displayName = displayName
        self.date = date
        self.totalSize = root.size
        self.root = ScanArchive.encode(root)
    }

    private static func encode(_ node: FileNode) -> Node {
        Node(name: node.name,
             path: node.url.path,
             kind: kindString(node.kind),
             isPackage: node.isPackage,
             isUnreadable: node.isUnreadable,
             size: node.size,
             fileCount: node.fileCount,
             children: node.children.map(encode))
    }

    private static func kindString(_ kind: FileNode.Kind) -> String {
        switch kind {
        case .file: return "file"
        case .directory: return "directory"
        case .hiddenSpace: return "hidden"
        }
    }

    private static func kind(from string: String) -> FileNode.Kind {
        switch string {
        case "file": return .file
        case "hidden": return .hiddenSpace
        default: return .directory
        }
    }

    // MARK: - Decode

    func makeTree() -> FileNode {
        ScanArchive.decode(root)
    }

    private static func decode(_ node: Node) -> FileNode {
        let children = node.children.map(decode)
        let fileNode = FileNode(url: URL(fileURLWithPath: node.path),
                                name: node.name,
                                kind: kind(from: node.kind),
                                isPackage: node.isPackage,
                                size: node.size,
                                fileCount: node.fileCount,
                                children: children)
        fileNode.isUnreadable = node.isUnreadable
        return fileNode
    }

    // MARK: - File IO

    func write(to url: URL) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        try data.write(to: url)
    }

    static func read(from url: URL) throws -> ScanArchive {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ScanArchive.self, from: data)
    }
}
