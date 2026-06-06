import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// A focus mask: criteria that highlight matching files in the map and filter
/// the list, so you can answer questions like "show only videos over 500 MB".
struct FocusCriteria: Equatable {
    var enabled = false
    var nameQuery = ""        // glob (with * / ?) or case-insensitive substring
    var minSizeMB = 0.0
    var fileExtension = ""    // e.g. "mp4" (without the dot)

    var isMeaningful: Bool {
        !nameQuery.trimmingCharacters(in: .whitespaces).isEmpty
            || minSizeMB > 0
            || !fileExtension.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isActive: Bool { enabled && isMeaningful }

    /// Whether a leaf file satisfies the criteria.
    func matchesFile(_ node: FileNode) -> Bool {
        guard node.kind == .file else { return false }

        if minSizeMB > 0, Double(node.size) < minSizeMB * 1_000_000 { return false }

        let ext = fileExtension.trimmingCharacters(in: .whitespaces).lowercased()
        if !ext.isEmpty, node.fileExtension != ext { return false }

        let query = nameQuery.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            if query.contains("*") || query.contains("?") {
                if fnmatch(query, node.name, Int32(FNM_CASEFOLD)) != 0 { return false }
            } else if !node.name.localizedCaseInsensitiveContains(query) {
                return false
            }
        }
        return true
    }
}
