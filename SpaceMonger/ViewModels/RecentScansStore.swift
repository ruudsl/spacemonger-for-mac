import Foundation
import Combine

/// Persists recently scanned locations as security-scoped bookmarks in
/// `UserDefaults`, and resolves them back to usable URLs on demand.
final class RecentScansStore: ObservableObject {
    @Published private(set) var items: [RecentScan] = []

    private let defaultsKey = "recentScans.v1"
    private let maxItems = 8

    init() { load() }

    func remember(url: URL, name: String, isVolume: Bool) {
        guard let bookmark = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        let entry = RecentScan(name: name,
                               path: url.path,
                               bookmark: bookmark,
                               isVolume: isVolume)
        // De-duplicate by path, newest first, capped.
        var updated = items.filter { $0.path != url.path }
        updated.insert(entry, at: 0)
        if updated.count > maxItems { updated = Array(updated.prefix(maxItems)) }
        items = updated
        save()
    }

    func remove(_ scan: RecentScan) {
        items.removeAll { $0.id == scan.id }
        save()
    }

    func clear() {
        items = []
        save()
    }

    /// Resolves a bookmark and begins security-scoped access. The caller owns the
    /// returned URL and must call `URL.stopAccessingSecurityScopedResource()`
    /// when finished.
    func resolve(_ scan: RecentScan) -> URL? {
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: scan.bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return nil }

        _ = url.startAccessingSecurityScopedResource()

        if stale {
            // Refresh the stored bookmark opportunistically.
            if let fresh = try? url.bookmarkData(options: [.withSecurityScope],
                                                 includingResourceValuesForKeys: nil,
                                                 relativeTo: nil) {
                if let idx = items.firstIndex(where: { $0.id == scan.id }) {
                    items[idx].bookmark = fresh
                    save()
                }
            }
        }
        return url
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([RecentScan].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
