import Foundation

enum Formatting {
    /// Toggled by AppSettings: base-1024 vs base-1000.
    static var useBinaryUnits = false

    private static let fileFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file        // base-1000, matches Finder
        f.allowsNonnumericFormatting = true
        return f
    }()

    private static let binaryFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .binary      // base-1024
        f.allowsNonnumericFormatting = true
        return f
    }()

    private static let percentFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 1
        return f
    }()

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    static func bytes(_ value: Int64) -> String {
        (useBinaryUnits ? binaryFormatter : fileFormatter).string(fromByteCount: value)
    }

    static func percent(_ fraction: Double) -> String {
        percentFormatter.string(from: NSNumber(value: fraction)) ?? "0%"
    }

    static func count(_ value: Int) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
