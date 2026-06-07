import Foundation
import Combine

/// App-wide preferences, persisted in `UserDefaults`. Owned by `ScanViewModel`
/// and surfaced in the Settings window.
final class AppSettings: ObservableObject {

    /// base-1000 (Finder) vs base-1024 (binary) size units.
    @Published var useBinaryUnits: Bool {
        didSet {
            defaults.set(useBinaryUnits, forKey: "useBinaryUnits")
            Formatting.useBinaryUnits = useBinaryUnits
        }
    }

    /// Follow symbolic links to count their target's size (off by default to
    /// avoid double-counting and cycles).
    @Published var followSymlinks: Bool {
        didSet { defaults.set(followSymlinks, forKey: "followSymlinks") }
    }

    /// Ask before moving items to the Trash.
    @Published var confirmBeforeDelete: Bool {
        didSet { defaults.set(confirmBeforeDelete, forKey: "confirmBeforeDelete") }
    }

    /// Use a colour-blind-friendly palette.
    @Published var colorBlindPalette: Bool {
        didSet {
            defaults.set(colorBlindPalette, forKey: "colorBlindPalette")
            NodeColor.colorBlind = colorBlindPalette
        }
    }

    @Published var defaultViewModeRaw: String {
        didSet { defaults.set(defaultViewModeRaw, forKey: "defaultViewMode") }
    }
    @Published var defaultColorModeRaw: String {
        didSet { defaults.set(defaultColorModeRaw, forKey: "defaultColorMode") }
    }

    /// Check GitHub Releases for a newer version on launch.
    @Published var automaticUpdateChecks: Bool {
        didSet { defaults.set(automaticUpdateChecks, forKey: "automaticUpdateChecks") }
    }
    /// Whether we've shown the first-run "check automatically?" prompt yet.
    @Published var didAskAboutUpdates: Bool {
        didSet { defaults.set(didAskAboutUpdates, forKey: "didAskAboutUpdates") }
    }

    private let defaults = UserDefaults.standard

    init() {
        useBinaryUnits = defaults.bool(forKey: "useBinaryUnits")
        followSymlinks = defaults.bool(forKey: "followSymlinks")
        // confirmBeforeDelete defaults to true.
        confirmBeforeDelete = defaults.object(forKey: "confirmBeforeDelete") as? Bool ?? true
        colorBlindPalette = defaults.bool(forKey: "colorBlindPalette")
        defaultViewModeRaw = defaults.string(forKey: "defaultViewMode") ?? "sunburst"
        defaultColorModeRaw = defaults.string(forKey: "defaultColorMode") ?? "rainbow"
        automaticUpdateChecks = defaults.bool(forKey: "automaticUpdateChecks")
        didAskAboutUpdates = defaults.bool(forKey: "didAskAboutUpdates")

        // Apply to the global helpers (didSet doesn't run during init).
        Formatting.useBinaryUnits = useBinaryUnits
        NodeColor.colorBlind = colorBlindPalette
    }
}
