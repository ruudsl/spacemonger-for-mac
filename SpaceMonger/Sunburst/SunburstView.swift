import SwiftUI
import AppKit

/// The interactive radial map. Renders the cached `SunburstLayout` with a
/// `Canvas`, highlights the hovered/selected sector, and routes clicks back to
/// the view model (single click selects, double click drills in, clicking the
/// centre hole navigates up one level).
struct SunburstView: View {
    @ObservedObject var vm: ScanViewModel

    var body: some View {
        GeometryReader { geo in
            let layout = vm.sunburstLayout
            Canvas { context, size in
                guard let layout else { return }
                draw(layout: layout, context: &context, size: size)
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture(count: 2)
                    .onEnded { value in handleDoubleTap(at: value.location, size: geo.size) }
                    .exclusively(before:
                        SpatialTapGesture(count: 1)
                            .onEnded { value in handleSingleTap(at: value.location, size: geo.size) }
                    )
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    updateHover(at: location, size: geo.size)
                case .ended:
                    vm.hoveredNode = nil
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: vm.focusNode?.id)
    }

    // MARK: - Drawing

    private func draw(layout: SunburstLayout, context: inout GraphicsContext, size: CGSize) {
        let m = layout.metrics(in: size)
        let hoveredID = vm.hoveredNode?.id
        let selectedPath = Set(vm.selectedNode?.pathFromRoot.map(\.id) ?? [])
        let dimOthers = hoveredID != nil
        let focusActive = vm.isFocusActive
        let focusIDs = vm.focusMatchIDs

        for segment in layout.segments {
            let inner = m.innerRadius(depth: segment.depth)
            let outer = m.outerRadius(depth: segment.depth)
            let path = annularSector(center: m.center,
                                     innerRadius: inner,
                                     outerRadius: outer,
                                     startAngle: segment.startAngle,
                                     endAngle: segment.endAngle)

            var color = vm.color(for: segment.node, hue: segment.hue, depth: segment.depth)
            let isHovered = segment.node.id == hoveredID
            if focusActive && !focusIDs.contains(segment.node.id) {
                color = color.opacity(0.12)
            } else if dimOthers && !isHovered && !selectedPath.contains(segment.node.id) {
                color = color.opacity(0.55)
            }
            context.fill(path, with: .color(color))

            // Thin separators between sectors.
            context.stroke(path, with: .color(Color.black.opacity(0.18)), lineWidth: 0.75)

            if isHovered {
                context.fill(path, with: .color(Color.white.opacity(0.22)))
                context.stroke(path, with: .color(Color.white.opacity(0.9)), lineWidth: 1.5)
            } else if vm.selectedNode?.id == segment.node.id {
                context.stroke(path, with: .color(Color.white), lineWidth: 1.5)
            }
        }

        drawCenter(context: &context, metrics: m)
    }

    private func drawCenter(context: inout GraphicsContext, metrics m: SunburstLayout.Metrics) {
        let circle = Path(ellipseIn: CGRect(x: m.center.x - m.holeRadius,
                                            y: m.center.y - m.holeRadius,
                                            width: m.holeRadius * 2,
                                            height: m.holeRadius * 2))
        context.fill(circle, with: .color(Color(nsColor: .windowBackgroundColor)))
        context.stroke(circle, with: .color(Color.gray.opacity(0.35)), lineWidth: 1)

        let info = vm.hoveredNode ?? vm.focusNode
        guard let info else { return }

        let nameText = Text(info.name)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
        let sizeText = Text(Formatting.bytes(info.size))
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.primary)

        context.draw(sizeText, at: CGPoint(x: m.center.x, y: m.center.y - 2))
        context.draw(nameText, at: CGPoint(x: m.center.x, y: m.center.y + 16))

        if vm.focusNode?.parent != nil && vm.hoveredNode == nil {
            let up = Text("▲ up")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            context.draw(up, at: CGPoint(x: m.center.x, y: m.center.y - 20))
        }
    }

    /// Builds an annular sector as a polyline so it always lines up with the
    /// hit-testing math in `SunburstLayout`.
    private func annularSector(center: CGPoint,
                               innerRadius: CGFloat,
                               outerRadius: CGFloat,
                               startAngle: Double,
                               endAngle: Double) -> Path {
        var path = Path()
        let sweep = endAngle - startAngle
        let steps = max(2, Int((sweep / (Double.pi / 90)).rounded(.up)))   // ~2° chords

        path.move(to: SunburstLayout.point(center: center, radius: outerRadius, angle: startAngle))
        for i in 0...steps {
            let a = startAngle + sweep * Double(i) / Double(steps)
            path.addLine(to: SunburstLayout.point(center: center, radius: outerRadius, angle: a))
        }
        for i in 0...steps {
            let a = endAngle - sweep * Double(i) / Double(steps)
            path.addLine(to: SunburstLayout.point(center: center, radius: innerRadius, angle: a))
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Interaction

    private func updateHover(at location: CGPoint, size: CGSize) {
        guard let layout = vm.sunburstLayout else { return }
        switch layout.hit(at: location, in: size) {
        case .segment(let segment): vm.hoveredNode = segment.node
        case .center, .none: vm.hoveredNode = nil
        }
    }

    private func handleSingleTap(at location: CGPoint, size: CGSize) {
        guard let layout = vm.sunburstLayout else { return }
        switch layout.hit(at: location, in: size) {
        case .segment(let segment): vm.select(segment.node)
        case .center: vm.navigateUp()
        case .none: vm.select(nil)
        }
    }

    private func handleDoubleTap(at location: CGPoint, size: CGSize) {
        guard let layout = vm.sunburstLayout else { return }
        switch layout.hit(at: location, in: size) {
        case .segment(let segment): vm.drill(into: segment.node)
        case .center: vm.navigateUp()
        case .none: break
        }
    }
}
