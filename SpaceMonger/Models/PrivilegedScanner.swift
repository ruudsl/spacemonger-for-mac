import Foundation

/// Scans with administrator privileges so that root-only system files are
/// measured too. Instead of bundling a separate privileged helper (which needs
/// XPC + Developer ID signing), this runs `du` as root via an authorized
/// `osascript` call — the user is prompted once for an admin password — and
/// parses its output into a `FileNode` tree.
enum PrivilegedScanner {

    enum ScanError: LocalizedError {
        case launchFailed
        case authorizationFailed(String)
        case noOutput

        var errorDescription: String? {
            switch self {
            case .launchFailed:
                return loc("Couldn't start the administrator scan.")
            case .authorizationFailed(let message):
                return message.isEmpty ? loc("Administrator access was not granted.") : message
            case .noOutput:
                return loc("The administrator scan produced no results.")
            }
        }
    }

    static func scan(at url: URL,
                     exclude: ExcludeMatcher,
                     isCancelled: @escaping () -> Bool,
                     progress: @escaping (Int) -> Void) throws -> FileNode {

        let rootURL = url.standardizedFileURL
        let path = rootURL.path
        let tmp = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("spacemonger-\(UUID().uuidString).txt")

        // Measure every file's disk usage as root, staying on one filesystem,
        // then make the result world-readable so we can parse it.
        let command = "/usr/bin/du -k -a -x -- \(shellQuote(path)) > \(shellQuote(tmp)) 2>/dev/null; /bin/chmod 644 \(shellQuote(tmp))"
        let appleScript = "do shell script \(appleScriptLiteral(command)) with administrator privileges"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]
        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        process.standardOutput = Pipe()

        do { try process.run() } catch { throw ScanError.launchFailed }

        while process.isRunning {
            if isCancelled() {
                process.terminate()
                try? FileManager.default.removeItem(atPath: tmp)
                throw CancellationError()
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        if process.terminationStatus != 0 {
            let message = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
                                 encoding: .utf8) ?? ""
            try? FileManager.default.removeItem(atPath: tmp)
            if message.contains("-128") || message.localizedCaseInsensitiveContains("canceled") {
                throw CancellationError()
            }
            throw ScanError.authorizationFailed(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        defer { try? FileManager.default.removeItem(atPath: tmp) }
        let root = try buildTree(fromFileAt: tmp, rootURL: rootURL,
                                 exclude: exclude, isCancelled: isCancelled, progress: progress)
        root.sortBySizeDescending(recursive: true)
        return root
    }

    /// Parses a `du` listing file (e.g. produced by the XPC helper) into a tree.
    static func tree(fromFile path: String, rootURL: URL, exclude: ExcludeMatcher) throws -> FileNode {
        let root = try buildTree(fromFileAt: path, rootURL: rootURL.standardizedFileURL,
                                 exclude: exclude, isCancelled: { false }, progress: { _ in })
        root.sortBySizeDescending(recursive: true)
        return root
    }

    // MARK: - Parsing du output

    static func buildTree(fromFileAt tmp: String,
                                  rootURL: URL,
                                  exclude: ExcludeMatcher,
                                  isCancelled: () -> Bool,
                                  progress: (Int) -> Void) throws -> FileNode {

        let rootPath = rootURL.path
        let boundary = rootPath == "/" ? "/" : rootPath + "/"
        let rootName = rootURL.lastPathComponent.isEmpty ? rootPath : rootURL.lastPathComponent
        let root = FileNode(url: rootURL, name: rootName, kind: .directory)

        var index: [String: FileNode] = [rootPath: root]
        var duKB: [String: Int64] = [:]
        var lineCount = 0

        func ensureNode(_ path: String) -> FileNode? {
            if let existing = index[path] { return existing }
            guard path == rootPath || path.hasPrefix(boundary) else { return nil }
            let parentPath = (path as NSString).deletingLastPathComponent
            guard parentPath.count >= rootPath.count, let parent = ensureNode(parentPath) else { return nil }
            let name = (path as NSString).lastPathComponent
            if exclude.matches(name: name) { return nil }
            let node = FileNode(url: URL(fileURLWithPath: path), name: name, kind: .directory)
            parent.addChild(node)
            index[path] = node
            return node
        }

        try forEachLine(inFileAt: tmp) { line in
            lineCount += 1
            if lineCount % 4000 == 0 {
                if isCancelled() { throw CancellationError() }
                progress(index.count)
            }
            guard let tab = line.firstIndex(of: "\t") else { return }
            let kb = Int64(line[..<tab]) ?? 0
            let path = String(line[line.index(after: tab)...])
            guard !path.isEmpty, ensureNode(path) != nil else { return }
            duKB[path] = kb
        }

        finalize(root, duKB: duKB)
        progress(index.count)
        if root.children.isEmpty && duKB.isEmpty { throw ScanError.noOutput }
        return root
    }

    /// Post-order pass: directory sizes are the sum of children; leaves take
    /// their `du` size and become files.
    private static func finalize(_ node: FileNode, duKB: [String: Int64]) {
        if node.children.isEmpty {
            node.size = (duKB[node.url.path] ?? 0) * 1024
            node.fileCount = node.kind == .file ? 1 : 0
            return
        }
        var total: Int64 = 0
        var count = 0
        for child in node.children {
            child.kind = child.children.isEmpty ? .file : .directory
            finalize(child, duKB: duKB)
            total += child.size
            count += child.fileCount
        }
        node.size = total
        node.fileCount = count
    }

    // MARK: - IO helpers

    private static func forEachLine(inFileAt path: String, _ body: (Substring) throws -> Void) throws {
        guard let handle = FileHandle(forReadingAtPath: path) else { throw ScanError.noOutput }
        defer { try? handle.close() }
        let newline = UInt8(0x0a)
        var leftover = Data()
        while true {
            let chunk = handle.readData(ofLength: 1 << 20)
            if chunk.isEmpty { break }
            var data = leftover
            data.append(chunk)
            var start = data.startIndex
            while let nl = data[start...].firstIndex(of: newline) {
                if let line = String(data: data[start..<nl], encoding: .utf8) {
                    try body(line[...])
                }
                start = data.index(after: nl)
            }
            leftover = Data(data[start...])
        }
        if !leftover.isEmpty, let line = String(data: leftover, encoding: .utf8) {
            try body(line[...])
        }
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func appleScriptLiteral(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        return "\"" + escaped + "\""
    }
}
