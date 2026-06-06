import SwiftUI

/// In-app user guide: a topic list on the left and the selected topic's text on
/// the right. Content is original and specific to SpaceMonger.
struct HelpView: View {
    var onClose: () -> Void
    @State private var selection: Int? = 0

    private struct Topic: Identifiable {
        let id: Int
        let title: String
        let body: String
    }

    private var topics: [Topic] {
        let raw: [(String, String)] = [
            (loc("Getting started"),
             loc("Open SpaceMonger and pick what to scan:\n\n• Choose a disk from the list, or click “Scan a Folder…” to pick any folder.\n• Recently scanned places appear under “Recent” for one-click rescanning.\n\nEach disk shows how much space is used and free, and its file system.")),
            (loc("Scanning"),
             loc("Scanning runs in the background and shows live progress. Press Cancel any time.\n\nSizes are the space items actually take on disk, like the Finder. Symbolic links aren’t followed and other mounted volumes aren’t crossed, so totals stay accurate.\n\nUse the refresh button to rescan.")),
            (loc("Reading the map"),
             loc("The map shows where your space goes. Each item’s size is proportional to its share of the disk.\n\n• Sunburst: rings radiate from the focused folder outward into subfolders.\n• Treemap: nested rectangles. Switch layouts from the toolbar.\n\nHover an item to highlight it and see its size in the centre. Use the colour menu to colour By Folder, By File Type or By Depth.")),
            (loc("Navigating"),
             loc("• Double-click an item (or a row in the list) to zoom into a folder.\n• Click the centre of the sunburst — or double-click empty space in the treemap — to go up one level.\n• Use the breadcrumb at the top to jump to any level.")),
            (loc("Inspecting items"),
             loc("Click an item to select it. The panel on the right shows its size, share of the folder and of the whole disk, item count and path.\n\nThe list below ranks the current folder by size; type in the Filter field to narrow it.\n\nActions (panel, context menu or menu bar): Quick Look (Space or ⌘Y), Open, Open With, Reveal in Finder, Copy Path.")),
            (loc("The Collector & deleting"),
             loc("Gather things you might delete in the Collector, then remove them together:\n\n• Drag items onto the Collector, or use “Add to Collector”.\n• Press “Move to Trash” to delete everything in it at once.\n\nDeletions always go to the Trash, so you can recover them. Safety stoppers refuse to delete system-critical files and whole volumes.")),
            (loc("Hidden & system space"),
             loc("“System & hidden space” is disk usage that couldn’t be attributed to readable files.\n\n• Grant Full Disk Access (the banner links to Settings) so system folders can be read.\n• Or use Rescan as Administrator to measure root-only files.\n• Open “Manage snapshots & purgeable space” to delete local Time Machine snapshots and reclaim purgeable space.")),
            (loc("Focus & exclusions"),
             loc("Focus highlights just the files you care about. Open the focus button in the toolbar and filter by name, type or minimum size; matching files stay bright while the rest dim and the list narrows.\n\nExclusions (Settings, ⌘,) skip items by name pattern while scanning, e.g. node_modules or *.log.")),
            (loc("Saving & comparing"),
             loc("• Save Scan… (⌘S) writes the current scan to a .smscan file.\n• Open Scan… (⇧⌘O) re-opens it; .gpscan files can also be imported.\n• Compare with Saved Scan… diffs the current scan against a saved one and lists what grew, shrank, was added or removed.")),
            (loc("Tips & shortcuts"),
             loc("⌘O Scan a folder · ⌘R Rescan · ⌥⌘R Rescan as administrator\n⌘S Save scan · ⇧⌘O Open scan\nSpace or ⌘Y Quick Look · ⇧⌘R Reveal · ⇧⌘C Copy path\n⌘D Add to Collector · ⌘⌫ Move to Trash · ⌘, Settings"))
        ]
        return raw.enumerated().map { Topic(id: $0.offset, title: $0.element.0, body: $0.element.1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(loc("SpaceMonger Help")).font(.title2.weight(.bold))
                Spacer()
                Button(loc("Done"), action: onClose).keyboardShortcut(.defaultAction)
            }
            .padding()
            Divider()

            HStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(topics) { topic in
                        Text(topic.title).tag(topic.id)
                    }
                }
                .listStyle(.sidebar)
                .frame(width: 200)

                Divider()

                ScrollView {
                    let topic = topics[selection ?? 0]
                    VStack(alignment: .leading, spacing: 12) {
                        Text(topic.title).font(.title3.weight(.semibold))
                        Text(topic.body)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 740, height: 560)
    }
}
