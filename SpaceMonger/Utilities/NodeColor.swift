import SwiftUI

/// Centralises the colour scheme so the sunburst, the file list and the
/// collector all tint the same item identically.
///
/// Top-level children of the focused node each get an evenly spaced hue around
/// the wheel (the bright outer ring). Descendants inherit
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

    /// Stable colour derived from a file's extension (the default for the
    /// "colour by file type"). Common types get hand-picked, recognisable hues.
    static func colorForType(_ ext: String, depth: Int) -> Color {
        if ext.isEmpty {
            return Color(white: 0.6)
        }
        let hue: Double
        if let known = knownTypeHues[ext] {
            hue = known
        } else {
            // Deterministic hash -> hue so the same type is always the colour.
            var hasher = 5381
            for byte in ext.utf8 { hasher = ((hasher << 5) &+ hasher) &+ Int(byte) }
            hue = Double(abs(hasher) % 360) / 360.0
        }
        return Color(hue: hue, saturation: 0.6, brightness: min(0.95, 0.8 + Double(depth) * 0.03))
    }

    static func colorForDepth(_ depth: Int) -> Color {
        let hue = (0.55 + Double(depth) * 0.12).truncatingRemainder(dividingBy: 1.0)
        return Color(hue: hue, saturation: 0.55, brightness: 0.85)
    }

    private static let knownTypeHues: [String: Double] = [
        // images
        "jpg": 0.08, "jpeg": 0.08, "png": 0.10, "gif": 0.11, "heic": 0.09,
        "tiff": 0.07, "raw": 0.06, "psd": 0.05,
        // video
        "mov": 0.95, "mp4": 0.96, "m4v": 0.94, "avi": 0.93, "mkv": 0.92,
        // audio
        "mp3": 0.78, "m4a": 0.79, "wav": 0.80, "flac": 0.81, "aiff": 0.77,
        // archives
        "zip": 0.13, "dmg": 0.14, "gz": 0.13, "tar": 0.135, "7z": 0.12,
        // documents
        "pdf": 0.00, "doc": 0.6, "docx": 0.6, "xls": 0.33, "xlsx": 0.33,
        "ppt": 0.04, "pptx": 0.04, "txt": 0.55, "md": 0.55,
        // code
        "swift": 0.03, "js": 0.16, "ts": 0.58, "py": 0.6, "json": 0.15,
        "c": 0.62, "h": 0.63, "cpp": 0.64, "java": 0.02,
        // apps / binaries
        "app": 0.5, "framework": 0.52, "dylib": 0.48, "o": 0.47
    ]
}
