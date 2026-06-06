import SwiftUI
import AppKit

/// The contents of the focused folder as a sortable, size-ranked list. Rows are
/// colour-matched to the map, support ⌘/⇧ multi-selection, can be dragged into
/// the Collector, and expose actions via a context menu. A search field filters.
struct FileListView: View {
    @EnvironmentObject var vm: ScanViewModel
    @State private var anchorID: UUID?

    private var children: [FileNode] {
        _ = vm.revision   // re-read after in-place mutations
        return vm.filteredChildren
    }

    /// Inherited top-level hues that match the map's first ring exactly.
    private var hues: [UUID: Double] {
        var map: [UUID: Double] = [:]
        for segment in vm.sunburstLayout?.segments ?? [] where segment.depth == 0 {
            map[segment.node.id] = segment.hue
        }
        return map
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Contents")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(locf(loc("%lld items"), children.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 6)

            searchField

            Divider()

            if children.isEmpty {
                Spacer()
                Text(vm.searchText.isEmpty ? "This folder is empty" : "No matching items")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(children) { node in
                            FileRow(node: node,
                                    hue: hues[node.id] ?? 0.6,
                                    fraction: node.fraction(of: vm.focusNode ?? node),
                                    isSelected: isSelected(node),
                                    onTap: { handleTap(node) })
                        }
                    }
                }
            }
        }
    }

    private func isSelected(_ node: FileNode) -> Bool {
        vm.listSelection.contains(node.id) || vm.selectedNode?.id == node.id
    }

    /// Modifier-aware selection: ⌘ toggles, ⇧ extends a range, plain click sets.
    private func handleTap(_ node: FileNode) {
        let flags = NSEvent.modifierFlags
        if flags.contains(.command) {
            if vm.listSelection.contains(node.id) {
                vm.listSelection.remove(node.id)
            } else {
                vm.listSelection.insert(node.id)
            }
            anchorID = node.id
            vm.selectedNode = node
        } else if flags.contains(.shift),
                  let anchor = anchorID,
                  let a = children.firstIndex(where: { $0.id == anchor }),
                  let b = children.firstIndex(where: { $0.id == node.id }) {
            let range = a <= b ? a...b : b...a
            vm.listSelection = Set(children[range].map(\.id))
            vm.selectedNode = node
        } else {
            vm.select(node)
            anchorID = node.id
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField("Filter", text: $vm.searchText)
                .textFieldStyle(.plain)
                .font(.callout)
            if !vm.searchText.isEmpty {
                Button { vm.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}

private struct FileRow: View {
    @EnvironmentObject var vm: ScanViewModel
    let node: FileNode
    let hue: Double
    let fraction: Double
    let isSelected: Bool
    let onTap: () -> Void

    private var color: Color { vm.color(for: node, hue: hue, depth: 0) }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 11, height: 11)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(node.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if node.isUnreadable {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .help("Couldn't read this folder — grant Full Disk Access")
                    }
                    if node.isDirectory && !node.isHiddenSpace {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: 4)
                    Text(Formatting.bytes(node.size))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.18))
                        Capsule().fill(color.opacity(0.85))
                            .frame(width: max(2, geo.size.width * CGFloat(min(1, max(0, fraction)))))
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if node.isDirectory { vm.drill(into: node) } else { onTap() }
        }
        .onTapGesture {
            onTap()
        }
        .onDrag {
            if !vm.listSelection.contains(node.id) { onTap() }
            if node.isRealFileSystemItem {
                return NSItemProvider(object: node.url as NSURL)
            }
            return NSItemProvider()
        }
        .contextMenu { contextMenu }
    }

    private var isMultiSelection: Bool {
        vm.listSelection.count > 1 && vm.listSelection.contains(node.id)
    }

    @ViewBuilder
    private var contextMenu: some View {
        if isMultiSelection {
            let nodes = vm.selectedListNodes()
            Button(locf(loc("Add %lld to Collector"), nodes.count)) { vm.addToCollector(nodes) }
            Button(locf(loc("Move %lld to Trash"), nodes.count), role: .destructive) { vm.trash(nodes) }
        } else if node.isRealFileSystemItem {
            Button("Quick Look") { vm.quickLook(node) }
            Button("Open") { vm.open(node) }
            Menu("Open With") {
                let apps = vm.applications(for: node)
                if apps.isEmpty {
                    Text("No applications")
                } else {
                    ForEach(apps, id: \.self) { app in
                        Button(app.deletingPathExtension().lastPathComponent) {
                            vm.open(node, withApplicationAt: app)
                        }
                    }
                }
            }
            Button("Reveal in Finder") { vm.reveal(node) }
            Button("Copy Path") { vm.copyPath(node) }
            if node.isDirectory && !node.children.isEmpty {
                Button("Zoom In") { vm.drill(into: node) }
            }
            Divider()
            if vm.isInCollector(node) {
                Button("Remove from Collector") { vm.removeFromCollector(node) }
            } else {
                Button("Add to Collector") { vm.addToCollector(node) }
            }
            Button("Move to Trash", role: .destructive) { vm.trash(node) }
        }
    }
}
