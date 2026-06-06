import SwiftUI

/// The path from the root to the currently focused node. Clicking any crumb
/// navigates (zooms) back to that level.
struct BreadcrumbView: View {
    @EnvironmentObject var vm: ScanViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(vm.breadcrumb.enumerated()), id: \.element.id) { index, node in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Button {
                        vm.navigate(to: node)
                    } label: {
                        Text(displayName(node))
                            .lineLimit(1)
                            .fontWeight(node.id == vm.focusNode?.id ? .semibold : .regular)
                            .foregroundStyle(node.id == vm.focusNode?.id ? Color.primary : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
                if let hovered = vm.hoveredNode, hovered.isRealFileSystemItem {
                    Text("·  \(hovered.url.path)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.leading, 8)
                } else if let summary = vm.scanSummary {
                    Text("·  \(summary)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 8)
                }
            }
        }
    }

    private func displayName(_ node: FileNode) -> String {
        if node.parent == nil {
            return vm.scannedVolume?.name ?? (node.name.isEmpty ? node.url.path : node.name)
        }
        return node.name
    }
}
