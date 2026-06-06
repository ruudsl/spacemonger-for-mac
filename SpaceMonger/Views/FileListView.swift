import SwiftUI

/// The contents of the focused folder as a sortable, size-ranked list. Rows are
/// colour-matched to the sunburst, can be dragged into the Collector, and expose
/// the same actions via a context menu.
struct FileListView: View {
    @EnvironmentObject var vm: ScanViewModel

    private var children: [FileNode] {
        _ = vm.revision   // re-read after in-place mutations
        return vm.focusNode?.children ?? []
    }

    /// Colour lookup that matches the sunburst's first ring exactly.
    private var colors: [UUID: Color] {
        var map: [UUID: Color] = [:]
        for segment in vm.sunburstLayout?.segments ?? [] where segment.depth == 0 {
            map[segment.node.id] = segment.color
        }
        return map
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Contents")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(children.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()

            if children.isEmpty {
                Spacer()
                Text("This folder is empty")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(children) { node in
                            FileRow(node: node,
                                    color: colors[node.id] ?? Color.gray,
                                    fraction: node.fraction(of: vm.focusNode ?? node),
                                    isSelected: vm.selectedNode?.id == node.id)
                        }
                    }
                }
            }
        }
    }
}

private struct FileRow: View {
    @EnvironmentObject var vm: ScanViewModel
    let node: FileNode
    let color: Color
    let fraction: Double
    let isSelected: Bool

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
            if node.isDirectory { vm.drill(into: node) } else { vm.select(node) }
        }
        .onTapGesture {
            vm.select(node)
        }
        .onDrag {
            vm.select(node)
            if node.isRealFileSystemItem {
                return NSItemProvider(object: node.url as NSURL)
            }
            return NSItemProvider()
        }
        .contextMenu { contextMenu }
    }

    @ViewBuilder
    private var contextMenu: some View {
        if node.isRealFileSystemItem {
            Button("Quick Look") { vm.quickLook(node) }
            Button("Reveal in Finder") { vm.reveal(node) }
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
