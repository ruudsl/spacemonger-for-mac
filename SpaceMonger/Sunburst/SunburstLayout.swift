import SwiftUI

/// One drawable ring sector in the sunburst.
struct SunburstSegment: Identifiable {
    let id: UUID            // mirrors the node's id
    let node: FileNode
    let depth: Int          // 0 == innermost ring (direct children of the focus)
    let startAngle: Double  // radians, 0 == straight up, increasing clockwise
    let endAngle: Double
    let hue: Double

    var sweep: Double { endAngle - startAngle }
    var midAngle: Double { (startAngle + endAngle) / 2 }
    var color: Color { NodeColor.color(hue: hue, depth: depth, isHiddenSpace: node.isHiddenSpace) }
}

/// Pure geometry for the sunburst: turns a focused `FileNode` into ring sectors
/// and answers hit-tests. Keeping this UI-free makes it easy to reason about and
/// reuse from both rendering and pointer handling.
struct SunburstLayout {

    let segments: [SunburstSegment]
    let focus: FileNode
    let maxDepth: Int

    /// Sectors whose angular sweep is below this are skipped (too thin to see or
    /// click), which also bounds the amount of work for huge trees.
    private static let minSweep = 0.012   // ~0.7°

    init(focus: FileNode, maxDepth: Int = 6) {
        self.focus = focus
        self.maxDepth = maxDepth

        var result: [SunburstSegment] = []
        let children = focus.children.filter { $0.size > 0 }
        let total = max(1.0, Double(focus.size))
        var angle = -Double.pi / 2   // start at the top

        for (index, child) in children.enumerated() {
            let sweep = (Double(child.size) / total) * (2 * .pi)
            if sweep < Self.minSweep { angle += sweep; continue }
            let hue = NodeColor.topLevelHue(index: index, count: children.count)
            let start = angle
            let end = angle + sweep
            result.append(SunburstSegment(id: child.id, node: child, depth: 0,
                                          startAngle: start, endAngle: end, hue: hue))
            Self.appendChildren(of: child, depth: 1, start: start, end: end,
                                hue: hue, maxDepth: maxDepth, into: &result)
            angle = end
        }
        self.segments = result
    }

    private static func appendChildren(of node: FileNode,
                                       depth: Int,
                                       start: Double,
                                       end: Double,
                                       hue: Double,
                                       maxDepth: Int,
                                       into result: inout [SunburstSegment]) {
        guard depth < maxDepth else { return }
        let total = max(1.0, Double(node.size))
        var angle = start
        let span = end - start
        for child in node.children where child.size > 0 {
            let sweep = (Double(child.size) / total) * span
            if sweep < minSweep { angle += sweep; continue }
            let childStart = angle
            let childEnd = angle + sweep
            result.append(SunburstSegment(id: child.id, node: child, depth: depth,
                                          startAngle: childStart, endAngle: childEnd, hue: hue))
            appendChildren(of: child, depth: depth + 1, start: childStart, end: childEnd,
                           hue: hue, maxDepth: maxDepth, into: &result)
            angle = childEnd
        }
    }

    // MARK: - Metrics

    struct Metrics {
        let center: CGPoint
        let holeRadius: CGFloat   // the central circle (the focus)
        let ringThickness: CGFloat
        let maxRadius: CGFloat

        func innerRadius(depth: Int) -> CGFloat { holeRadius + CGFloat(depth) * ringThickness }
        func outerRadius(depth: Int) -> CGFloat { innerRadius(depth: depth) + ringThickness }
    }

    func metrics(in size: CGSize) -> Metrics {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.width, size.height) / 2 - 8
        let holeRadius = maxRadius * 0.26
        let ringThickness = (maxRadius - holeRadius) / CGFloat(maxDepth)
        return Metrics(center: center, holeRadius: holeRadius,
                       ringThickness: ringThickness, maxRadius: maxRadius)
    }

    // MARK: - Hit testing

    enum Hit {
        case center            // the hole — navigate up one level
        case segment(SunburstSegment)
        case none
    }

    func hit(at point: CGPoint, in size: CGSize) -> Hit {
        let m = metrics(in: size)
        let dx = Double(point.x - m.center.x)
        let dy = Double(point.y - m.center.y)
        let radius = CGFloat(sqrt(dx * dx + dy * dy))

        if radius <= m.holeRadius { return .center }
        if radius > m.maxRadius { return .none }

        let depth = Int((radius - m.holeRadius) / m.ringThickness)

        // Inverse of `point(center:radius:angle:)`: 0 == straight up, clockwise.
        var angle = atan2(dx, -dy)
        // Normalise into the segment angle space, which starts at -pi/2.
        while angle < -Double.pi / 2 { angle += 2 * .pi }
        while angle >= 3 * Double.pi / 2 { angle -= 2 * .pi }

        for segment in segments where segment.depth == depth {
            if angle >= segment.startAngle && angle < segment.endAngle {
                return .segment(segment)
            }
        }
        return .none
    }

    /// Position on a circle for a sunburst angle: 0 == straight up, increasing
    /// clockwise. Shared by the renderer so drawing and hit-testing always agree.
    static func point(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(sin(angle)),
                y: center.y - radius * CGFloat(cos(angle)))
    }
}
