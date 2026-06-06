import Foundation

/// Imports a `.gpscan` scan file (the XML format produced by some other disk
/// scanners) into a `FileNode` tree. Compressed `.gpscan` files must be exported
/// uncompressed.
enum GPScanImporter {

    enum ImportError: LocalizedError {
        case compressed
        case parseFailed(String)
        case empty

        var errorDescription: String? {
            switch self {
            case .compressed:
                return loc("This .gpscan file is compressed. Please re-export it uncompressed.")
            case .parseFailed(let message):
                return message.isEmpty ? loc("Couldn't read the .gpscan file.") : message
            case .empty:
                return loc("The .gpscan file contained no folders.")
            }
        }
    }

    static func importTree(from url: URL) throws -> (root: FileNode, name: String) {
        var data = try Data(contentsOf: url)
        // gzip magic number -> decompress first.
        if data.count >= 2, data[0] == 0x1f, data[1] == 0x8b {
            guard let inflated = gunzip(data) else { throw ImportError.compressed }
            data = inflated
        }

        let parser = XMLParser(data: data)
        let delegate = Delegate()
        parser.delegate = delegate
        guard parser.parse() else {
            throw ImportError.parseFailed(parser.parserError?.localizedDescription ?? "")
        }
        guard let root = delegate.root else { throw ImportError.empty }

        finalize(root)
        root.sortBySizeDescending(recursive: true)

        var name = root.name
        if let volumePath = delegate.volumePath, !volumePath.isEmpty {
            let leaf = (volumePath as NSString).lastPathComponent
            if !leaf.isEmpty { name = leaf }
        }
        return (root, name)
    }

    /// Decompresses gzip data via `/usr/bin/gzip -dc`, reading output on a
    /// background queue to avoid pipe-buffer deadlock on large files.
    private static func gunzip(_ data: Data) -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
        process.arguments = ["-dc"]
        let input = Pipe()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = Pipe()
        do { try process.run() } catch { return nil }

        var outData = Data()
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            outData = output.fileHandleForReading.readDataToEndOfFile()
            semaphore.signal()
        }
        input.fileHandleForWriting.write(data)
        input.fileHandleForWriting.closeFile()
        process.waitUntilExit()
        semaphore.wait()
        return process.terminationStatus == 0 ? outData : nil
    }

    /// Folder sizes aren't stored, so compute them from the files (post-order).
    private static func finalize(_ node: FileNode) {
        guard !node.children.isEmpty else {
            node.fileCount = node.kind == .file ? 1 : 0
            return
        }
        var total: Int64 = 0
        var count = 0
        for child in node.children {
            finalize(child)
            total += child.size
            count += child.fileCount
        }
        node.size = total
        node.fileCount = count
    }

    // MARK: - XML parsing

    private final class Delegate: NSObject, XMLParserDelegate {
        var root: FileNode?
        var volumePath: String?
        private var stack: [FileNode] = []

        func parser(_ parser: XMLParser, didStartElement element: String,
                    namespaceURI: String?, qualifiedName: String?,
                    attributes attrs: [String: String]) {
            switch element {
            case "ScanInfo":
                volumePath = attrs["volumePath"]
            case "Folder":
                let name = attrs["name"] ?? ""
                let parentURL = stack.last?.url ?? URL(fileURLWithPath: volumePath ?? "/")
                let url = stack.isEmpty
                    ? URL(fileURLWithPath: volumePath ?? (name.isEmpty ? "/" : name))
                    : parentURL.appendingPathComponent(name)
                let node = FileNode(url: url, name: name.isEmpty ? url.lastPathComponent : name,
                                    kind: .directory)
                if let parent = stack.last { parent.addChild(node) }
                if root == nil { root = node }
                stack.append(node)
            case "File":
                let name = attrs["name"] ?? ""
                let size = Int64(attrs["size"] ?? "0") ?? 0
                let parentURL = stack.last?.url ?? URL(fileURLWithPath: "/")
                let node = FileNode(url: parentURL.appendingPathComponent(name),
                                    name: name, kind: .file, size: size, fileCount: 1)
                stack.last?.addChild(node)
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, didEndElement element: String,
                    namespaceURI: String?, qualifiedName: String?) {
            if element == "Folder", !stack.isEmpty {
                stack.removeLast()
            }
        }
    }
}
