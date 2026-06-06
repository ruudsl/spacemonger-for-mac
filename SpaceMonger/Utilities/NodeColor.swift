import SwiftUI

/// Centralises the colour scheme so the sunburst, the file list and the
/// collector all tint the same item identically.
///
/// Top-level children of the focused node each get an evenly spaced hue around
/// the wheel (the bright outer ring you see in DaisyDisk). Descendants inherit
/// their top-level ancestor's hue and get progressively lighter / less
/// saturated the deeper (further out) they sit.
enum NodeColor {

    static func color(hue: Double, depth: Int, isHiddenSpace: Bool = false) -> Color {
        if isHiddenSpace {
            return Color(white: 0.55)
        }
        let saturation = max(0.18, 0.62 - Double(depth) * 0.07)
        let brightness = min(0.97, 0.74 + Double(depth) * 0.05)
        return Color(hue: hue.truncatingRemainder(dividingBy: 1.0),
                     saturation: saturation,
                     brightness: brightness)
    }

    /// Hue for the `index`-th of `count` siblings on the first ring.
    static func topLevelHue(index: Int, count: Int) -> Double {
        guard count > 0 else { return 0.6 }
        // A small offset keeps the first slice off pure red, which reads nicer.
        return (0.58 + Double(index) / Double(count)).truncatingRemainder(dividingBy: 1.0)
    }
}
