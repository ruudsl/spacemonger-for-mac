import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// The Collector: a tray you drag items into, review, and then send
/// to the Trash in one go. Items can also be added via the list/context menu.
struct CollectorView: View {
    @EnvironmentObject var vm: ScanViewModel
    @State private var isTargeted = false
    @State private var confirmDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if vm.collector.isEmpty {
                emptyState
            } else {
                list
                footer
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 130, maxHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundColor(isTargeted ? Color.accentColor : Color.gray.opacity(0.35))
                .padding(2)
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
        .confirmationDialog(
            locf(loc("Move %lld items to the Trash?"), vm.collector.count),
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) { vm.deleteCollected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(locf(loc("This frees %@. Items go to the Trash, so you can still recover them."),
                      Formatting.bytes(vm.collectorTotalSize)))
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "trash")
            Text("Collector")
                .font(.subheadline.weight(.semibold))
            Spacer()
            if !vm.collector.isEmpty {
                Text(Formatting.bytes(vm.collectorTotalSize))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("Drag items here to collect them")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Then move them all to the Trash at once")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(vm.collector) { node in
                    HStack(spacing: 8) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: node.url.path))
                            .resizable().frame(width: 16, height: 16)
                        Text(node.name)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 4)
                        Text(Formatting.bytes(node.size))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Button {
                            vm.removeFromCollector(node)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Empty") { vm.clearCollector() }
                .controlSize(.small)
            Spacer()
            Button {
                if vm.confirmBeforeDelete { confirmDelete = true } else { vm.deleteCollected() }
            } label: {
                Label(locf(loc("Move %lld to Trash"), vm.collector.count), systemImage: "trash")
            }
            .controlSize(.small)
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            handled = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                var url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let direct = item as? URL {
                    url = direct
                }
                if let url {
                    DispatchQueue.main.async { vm.addURLsToCollector([url]) }
                }
            }
        }
        return handled
    }
}
