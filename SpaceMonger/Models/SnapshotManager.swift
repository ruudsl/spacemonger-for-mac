import Foundation

/// Lists and removes local APFS (Time Machine) snapshots and asks macOS to
/// reclaim purgeable space — the biggest, controllable sources of "hidden space".
/// Listing runs unprivileged; deleting/thinning is run via an authorized
/// `tmutil` call (one admin password prompt).
enum SnapshotManager {

    struct LocalSnapshot: Identifiable, Hashable {
        let id: String          // the date component, unique per snapshot
        let name: String        // full snapshot name
        let dateString: String  // yyyy-MM-dd-HHmmss
        let date: Date?
    }

    enum SnapshotError: LocalizedError {
        case cancelled
        case failed(String)
        var errorDescription: String? {
            switch self {
            case .cancelled: return loc("Administrator access was not granted.")
            case .failed(let m): return m.isEmpty ? loc("The operation failed.") : m
            }
        }
    }

    /// Local snapshots for the given volume mount point.
    static func list(volume: URL) -> [LocalSnapshot] {
        guard let output = runCapturing(["/usr/bin/tmutil", "listlocalsnapshots", volume.path]) else {
            return []
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"

        var result: [LocalSnapshot] = []
        for rawLine in output.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let marker = line.range(of: "TimeMachine.") else { continue }
            var dateString = String(line[marker.upperBound...])
            if dateString.hasSuffix(".local") { dateString = String(dateString.dropLast(6)) }
            guard !dateString.isEmpty else { continue }
            result.append(LocalSnapshot(id: dateString, name: line,
                                        dateString: dateString, date: formatter.date(from: dateString)))
        }
        return result
    }

    static func delete(dateStrings: [String]) throws {
        guard !dateStrings.isEmpty else { return }
        let command = dateStrings
            .map { "/usr/bin/tmutil deletelocalsnapshots \(shellQuote($0))" }
            .joined(separator: "; ")
        try runAdmin(command)
    }

    /// Asks macOS to thin local snapshots aggressively, freeing purgeable space.
    static func thin(volume: URL, urgency: Int = 4) throws {
        let command = "/usr/bin/tmutil thinlocalsnapshots \(shellQuote(volume.path)) 9999999999999 \(urgency)"
        try runAdmin(command)
    }

    /// Estimated purgeable space (space macOS can free on demand) for a volume.
    static func purgeableBytes(volume: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]
        guard let values = try? volume.resourceValues(forKeys: keys) else { return 0 }
        let important = values.volumeAvailableCapacityForImportantUsage ?? 0
        let raw = Int64(values.volumeAvailableCapacity ?? 0)
        return max(0, important - raw)
    }

    // MARK: - Process helpers

    private static func runCapturing(_ args: [String]) -> String? {
        guard let first = args.first else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: first)
        process.arguments = Array(args.dropFirst())
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do { try process.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }

    private static func runAdmin(_ command: String) throws {
        let script = "do shell script \(appleScriptLiteral(command)) with administrator privileges"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let errPipe = Pipe()
        process.standardError = errPipe
        process.standardOutput = Pipe()
        do { try process.run() } catch { throw SnapshotError.failed(error.localizedDescription) }
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let message = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(),
                                 encoding: .utf8) ?? ""
            if message.contains("-128") || message.localizedCaseInsensitiveContains("canceled") {
                throw SnapshotError.cancelled
            }
            throw SnapshotError.failed(message.trimmingCharacters(in: .whitespacesAndNewlines))
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
