import SwiftUI
import AppKit

/// Shows details and quick actions for the active item (selection takes
/// precedence over hover, falling back to the focused folder).
struct FileInfoView: View {
    @EnvironmentObject var vm: ScanViewModel

    private var node: FileNode? { vm.selectedNode ?? vm.hoveredNode ?? vm.focusNode }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let node {
                header(node)
                stats(node)
                if node.isRealFileSystemItem {
                    actions(node)
                }
                if node.isHiddenSpace {
                    Button {
                        vm.openSnapshots()
                    } label: {
                        Label("Manage snapshots & purgeable space…", systemImage: "clock.arrow.circlepath")
                    }
                    .controlSize(.small)
                }
            } else {
                Text("Nothing selected")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func header(_ node: FileNode) -> some View {
        HStack(spacing: 10) {
            icon(node)
                .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(node.isHiddenSpace ? "Unattributed space"
                     : node.isPackage ? "Application / package"
                     : node.isDirectory ? "Folder" : "File")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if node.isUnreadable {
                    Label("Couldn't read — needs Full Disk Access", systemImage: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func icon(_ node: FileNode) -> some View {
        if node.isHiddenSpace {
            Image(systemName: "gearshape.2.fill")
                .resizable().scaledToFit()
                .foregroundStyle(.secondary)
        } else {
            Image(nsImage: NSWorkspace.shared.icon(forFile: node.url.path))
                .resizable().scaledToFit()
        }
    }

    private func stats(_ node: FileNode) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            statRow("Size", Formatting.bytes(node.size))
            if let focus = vm.focusNode, focus !== node {
                statRow("Of \(focus.name)", Formatting.percent(node.fraction(of: focus)))
            }
            if let root = vm.rootNode, root !== node {
                statRow("Of total", Formatting.percent(node.fraction(of: root)))
            }
            if node.isDirectory {
                statRow("Items", Formatting.count(node.fileCount))
            }
            if node.isRealFileSystemItem {
                statRow("Path", node.url.path, mono: true)
            }
        }
        .font(.callout)
    }

    private func statRow(_ label: String, _ value: String, mono: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 84, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
                .font(mono ? .system(.caption, design: .monospaced) : .callout)
                .lineLimit(mono ? 3 : 1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
    }

    private func actions(_ node: FileNode) -> some View {
        HStack(spacing: 8) {
            Button {
                vm.quickLook(node)
            } label: { Image(systemName: "eye") }
            .help("Quick Look")

            Button {
                vm.reveal(node)
            } label: { Image(systemName: "magnifyingglass") }
            .help("Reveal in Finder")

            Button {
                vm.open(node)
            } label: { Image(systemName: "arrow.up.forward.app") }
            .help("Open")

            Button {
                vm.copyPath(node)
            } label: { Image(systemName: "doc.on.doc") }
            .help("Copy Path")

            Spacer()

            if vm.isInCollector(node) {
                Button(role: .destructive) {
                    vm.removeFromCollector(node)
                } label: { Image(systemName: "tray.and.arrow.up") }
                .help("Remove from Collector")
            } else {
                Button {
                    vm.addToCollector(node)
                } label: { Image(systemName: "tray.and.arrow.down") }
                .help("Add to Collector")
                .disabled(node.parent == nil)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}
