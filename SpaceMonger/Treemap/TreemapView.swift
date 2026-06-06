import SwiftUI
import AppKit

/// Caches the (size-dependent) squarified layout so hover/redraw doesn't rebuild
/// it every frame.
final class TreemapCache {
    private var key: String = ""
    private var layout: TreemapLayout?

    func layout(focus: FileNode, size: CGSize, revision: Int) -> TreemapLayout {
        let k = "\(focus.id.uuidString)-\(Int(size.width))x\(Int(size.height))-\(revision)"
        if k != key || layout == nil {
            layout = TreemapLayout(focus: focus, in: size)
            key = k
        }
        return layout ?? TreemapLayout(focus: focus, in: size)
    }
}

/// GrandPerspective-style treemap rendering with the same interaction model as
/// the sunburst (hover highlights, click selects, double-click zooms in, and
/// double-clicking empty space zooms out).
struct TreemapView: View {
    @ObservedObject var vm: ScanViewModel
    @State private var cache = TreemapCache()

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                guard let focus = vm.focusNode else { return }
                let layout = cache.layout(focus: focus, size: size, revision: vm.revision)
                draw(layout: layout, context: &context)
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture(count: 2)
                    .onEnded { handleDoubleTap(at: $0.location, size: geo.size) }
                    .exclusively(before:
                        SpatialTapGesture(count: 1)
                            .onEnded { handleSingleTap(at: $0.location, size: geo.size) }
                    )
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let layout = cache.layout(focus: vm.focusNode ?? rootFallback, size: geo.size, revision: vm.revision)
                    vm.hoveredNode = layout.tile(at: location)?.node
                case .ended:
                    vm.hoveredNode = nil
                }
            }
        }
    }

    private var rootFallback: FileNode {
        vm.focusNode ?? FileNode(url: URL(fileURLWithPath: "/"), name: "/", kind: .directory)
    }

    private func draw(layout: TreemapLayout, context: inout GraphicsContext) {
        let hoveredID = vm.hoveredNode?.id
        let selectedID = vm.selectedNode?.id

        for tile in layout.tiles {
            let path = Path(tile.rect)
            let color = vm.color(for: tile.node, hue: tile.hue, depth: tile.depth)

            // Leaves are filled solid; directories are mostly covered by their
            // children, so a lighter fill reads as a subtle container background.
            let fill = tile.node.isLeaf ? color : color.opacity(0.25)
            context.fill(path, with: .color(fill))
            context.stroke(path, with: .color(Color.black.opacity(0.22)), lineWidth: 0.5)

            if tile.node.id == hoveredID {
                context.fill(path, with: .color(Color.white.opacity(0.22)))
                context.stroke(path, with: .color(Color.white.opacity(0.9)), lineWidth: 1.5)
            } else if tile.node.id == selectedID {
                context.stroke(path, with: .color(Color.white), lineWidth: 1.5)
            }

            drawLabel(for: tile, context: &context)
        }
    }

    private func drawLabel(for tile: TreemapTile, context: inout GraphicsContext) {
        guard tile.rect.width > 78, tile.rect.height > 26,
              tile.node.isLeaf || tile.depth == 0 else { return }
        context.drawLayer { layer in
            layer.clip(to: Path(tile.rect.insetBy(dx: 3, dy: 2)))
            let origin = CGPoint(x: tile.rect.minX + 5, y: tile.rect.minY + 4)
            layer.draw(
                Text(tile.node.name).font(.system(size: 10, weight: .medium)).foregroundColor(.white),
                at: origin, anchor: .topLeading
            )
            layer.draw(
                Text(Formatting.bytes(tile.node.size)).font(.system(size: 9)).foregroundColor(.white.opacity(0.85)),
                at: CGPoint(x: origin.x, y: origin.y + 13), anchor: .topLeading
            )
        }
    }

    // MARK: - Interaction

    private func handleSingleTap(at location: CGPoint, size: CGSize) {
        guard let focus = vm.focusNode else { return }
        let layout = cache.layout(focus: focus, size: size, revision: vm.revision)
        if let node = layout.tile(at: location)?.node {
            vm.select(node)
        } else {
            vm.select(nil)
        }
    }

    private func handleDoubleTap(at location: CGPoint, size: CGSize) {
        guard let focus = vm.focusNode else { return }
        let layout = cache.layout(focus: focus, size: size, revision: vm.revision)
        if let node = layout.tile(at: location)?.node {
            vm.drill(into: node)
        } else {
            vm.navigateUp()
        }
    }
}
