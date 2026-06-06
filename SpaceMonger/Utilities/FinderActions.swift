import AppKit

/// Thin wrappers around the Finder / file-system integrations used by the UI.
enum FinderActions {

    static func revealInFinder(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    static func reveal(_ url: URL) {
        revealInFinder([url])
    }

    struct TrashResult {
        var trashed: [URL]
        var failures: [(url: URL, error: Error)]
    }

    /// Moves the given items to the Trash. Returns which succeeded and which
    /// failed so the caller can update the tree and surface errors.
    @discardableResult
    static func moveToTrash(_ urls: [URL]) -> TrashResult {
        var trashed: [URL] = []
        var failures: [(URL, Error)] = []
        let fm = FileManager.default
        for url in urls {
            do {
                try fm.trashItem(at: url, resultingItemURL: nil)
                trashed.append(url)
            } catch {
                failures.append((url, error))
            }
        }
        return TrashResult(trashed: trashed, failures: failures)
    }
}
