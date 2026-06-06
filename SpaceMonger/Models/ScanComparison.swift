import Foundation

/// The result of diffing the current scan against a previously saved one.
struct ScanComparison: Identifiable {
    let id = UUID()
    let currentName: String
    let otherName: String
    let currentTotal: Int64
    let otherTotal: Int64
    var totalDelta: Int64 { currentTotal - otherTotal }

    var grown: [Entry]
    var shrunk: [Entry]
    var added: [Entry]
    var removed: [Entry]

    struct Entry: Identifiable {
        let id = UUID()
        let path: String
        let name: String
        let delta: Int64       // current - other (added: +size, removed: -size)
        let size: Int64        // current size (added/grown) or other size (removed)
    }

    /// Diffs two trees by flattening their leaf files to `path -> size` maps.
    static func compare(current: FileNode, currentName: String,
                        other: FileNode, otherName: String,
                        limit: Int = 100) -> ScanComparison {
        var currentMap: [String: Int64] = [:]
        var otherMap: [String: Int64] = [:]
        flatten(current, into: &currentMap)
        flatten(other, into: &otherMap)

        var grown: [Entry] = []
        var shrunk: [Entry] = []
        var added: [Entry] = []
        var removed: [Entry] = []

        for (path, size) in currentMap {
            if let was = otherMap[path] {
                let delta = size - was
                if delta > 0 {
                    grown.append(Entry(path: path, name: leaf(path), delta: delta, size: size))
                } else if delta < 0 {
                    shrunk.append(Entry(path: path, name: leaf(path), delta: delta, size: size))
                }
            } else {
                added.append(Entry(path: path, name: leaf(path), delta: size, size: size))
            }
        }
        for (path, size) in otherMap where currentMap[path] == nil {
            removed.append(Entry(path: path, name: leaf(path), delta: -size, size: size))
        }

        grown.sort { $0.delta > $1.delta }
        shrunk.sort { $0.delta < $1.delta }
        added.sort { $0.size > $1.size }
        removed.sort { $0.size > $1.size }

        return ScanComparison(
            currentName: currentName,
            otherName: otherName,
            currentTotal: current.size,
            otherTotal: other.size,
            grown: Array(grown.prefix(limit)),
            shrunk: Array(shrunk.prefix(limit)),
            added: Array(added.prefix(limit)),
            removed: Array(removed.prefix(limit))
        )
    }

    private static func flatten(_ node: FileNode, into map: inout [String: Int64]) {
        if node.children.isEmpty {
            if node.kind != .hiddenSpace {
                map[node.url.path] = node.size
            }
            return
        }
        for child in node.children { flatten(child, into: &map) }
    }

    private static func leaf(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }
}
