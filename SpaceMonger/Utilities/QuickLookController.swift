import AppKit
import Quartz

/// Presents the system Quick Look panel for one or more files, the same preview
/// you get by pressing Space in the Finder.
///
/// We drive the shared `QLPreviewPanel` directly with a long-lived data source.
/// This covers the common "show me this file" case used from the file list,
/// context menus and the ⌘Y menu command.
final class QuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {

    static let shared = QuickLookController()

    private var urls: [URL] = []

    func preview(_ urls: [URL]) {
        let existing = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !existing.isEmpty else { return }
        self.urls = existing

        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        if panel.isVisible {
            panel.reloadData()
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: QLPreviewPanelDataSource

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }
}
