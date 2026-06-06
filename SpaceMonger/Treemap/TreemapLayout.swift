import SwiftUI

/// One rectangle in the treemap.
struct TreemapTile: Identifiable {
    let id: UUID
    let node: FileNode
    let rect: CGRect
    let depth: Int
    let hue: Double
}

/// Squarified treemap (Bruls, Huizing & van Wijk) for the focused node's
/// subtree. Like GrandPerspective: nested rectangles sized by on-disk usage,
/// laid out to keep tiles as close to square as possible.
struct TreemapLayout {
    private(set) var tiles: [TreemapTile] = []
    let focus: FileNode

    private let maxDepth: Int
    private let minTileSide: CGFloat = 3

    init(focus: FileNode, in size: CGSize, maxDepth: Int = 12) {
        self.focus = focus
        self.maxDepth = maxDepth
        let rect = CGRect(origin: .zero, size: size)
        guard size.width > 1, size.height > 1 else { return }
        place(children: focus.children, in: rect, depth: 0, hue: nil)
    }

    private mutating func place(children: [FileNode], in rect: CGRect, depth: Int, hue inheritedHue: Double?) {
        let visible = children.filter { $0.size > 0 }
        guard !visible.isEmpty, rect.width > minTileSide, rect.height > minTileSide else { return }

        let total = visible.reduce(0.0) { $0 + Double($1.size) }
        guard total > 0 else { return }
        let scale = Double(rect.width * rect.height) / total
        let areas = visible.map { Double($0.size) * scale }
        let rects = squarified(areas: areas, in: rect)

        for (index, node) in visible.enumerated() {
            let tileRect = rects[index]
            let hue = inheritedHue ?? NodeColor.topLevelHue(index: index, count: visible.count)
            tiles.append(TreemapTile(id: node.id, node: node, rect: tileRect, depth: depth, hue: hue))

            if node.isDirectory, !node.children.isEmpty, depth + 1 < maxDepth {
                let inset = nestedInset(for: tileRect)
                let inner = tileRect.insetBy(dx: inset, dy: inset)
                if inner.width > minTileSide, inner.height > minTileSide {
                    place(children: node.children, in: inner, depth: depth + 1, hue: hue)
                }
            }
        }
    }

    private func nestedInset(for rect: CGRect) -> CGFloat {
        let small = min(rect.width, rect.height)
        if small > 60 { return 3 }
        if small > 20 { return 2 }
        return 1
    }

    // MARK: - Squarified rows

    private func squarified(areas: [Double], in rect: CGRect) -> [CGRect] {
        var result = [CGRect](repeating: .zero, count: areas.count)
        var free = rect
        var i = 0
        while i < areas.count {
            let shortSide = Double(min(free.width, free.height))
            var rowSum = 0.0
            var end = i
            var bestWorst = Double.greatestFiniteMagnitude

            var j = i
            while j < areas.count {
                let newSum = rowSum + areas[j]
                let worst = worstRatio(rowMax: areas[i...j].max() ?? 0,
                                       rowMin: areas[i...j].min() ?? 0,
                                       sum: newSum,
                                       side: shortSide)
                if worst <= bestWorst {
                    bestWorst = worst
                    rowSum = newSum
                    end = j
                    j += 1
                } else {
                    break
                }
            }

            layoutRow(areas: Array(areas[i...end]), sum: rowSum, free: &free, into: &result, startIndex: i)
            i = end + 1
        }
        return result
    }

    private func worstRatio(rowMax: Double, rowMin: Double, sum: Double, side: Double) -> Double {
        guard sum > 0, side > 0, rowMin > 0 else { return .greatestFiniteMagnitude }
        let s2 = sum * sum
        let w2 = side * side
        return max(w2 * rowMax / s2, s2 / (w2 * rowMin))
    }

    private func layoutRow(areas: [Double], sum: Double, free: inout CGRect, into result: inout [CGRect], startIndex: Int) {
        guard sum > 0 else { return }
        let horizontal = free.width < free.height   // shortest side is width -> strip across the top
        if horizontal {
            let thickness = CGFloat(sum) / free.width
            var x = free.minX
            for (k, area) in areas.enumerated() {
                let w = CGFloat(area) / thickness
                result[startIndex + k] = CGRect(x: x, y: free.minY, width: w, height: thickness)
                x += w
            }
            free = CGRect(x: free.minX, y: free.minY + thickness,
                          width: free.width, height: free.height - thickness)
        } else {
            let thickness = CGFloat(sum) / free.height
            var y = free.minY
            for (k, area) in areas.enumerated() {
                let h = CGFloat(area) / thickness
                result[startIndex + k] = CGRect(x: free.minX, y: y, width: thickness, height: h)
                y += h
            }
            free = CGRect(x: free.minX + thickness, y: free.minY,
                          width: free.width - thickness, height: free.height)
        }
    }

    // MARK: - Hit testing

    /// Deepest tile containing the point (children are appended after parents).
    func tile(at point: CGPoint) -> TreemapTile? {
        for tile in tiles.reversed() where tile.rect.contains(point) {
            return tile
        }
        return nil
    }
}
