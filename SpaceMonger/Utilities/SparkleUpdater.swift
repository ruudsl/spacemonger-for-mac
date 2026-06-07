import Foundation

// Real auto-updates via Sparkle (download, install, relaunch).
//
// This is compiled in two modes:
//  • Until you add the Sparkle package, `canImport(Sparkle)` is false and the
//    stub below is used (`isSupported == false`), so the app falls back to the
//    GitHub-Releases check and still builds.
//  • After you add Sparkle (File ▸ Add Package Dependencies ▸
//    https://github.com/sparkle-project/Sparkle) and the Info.plist keys, this
//    lights up automatically. See Distribution/Sparkle.md.

#if canImport(Sparkle)
import Sparkle

final class SparkleUpdater {
    static let shared = SparkleUpdater()

    private let controller: SPUStandardUpdaterController

    private init() {
        // Starts the updater; reads SUFeedURL / SUPublicEDKey from Info.plist.
        controller = SPUStandardUpdaterController(startingUpdater: true,
                                                  updaterDelegate: nil,
                                                  userDriverDelegate: nil)
    }

    var isSupported: Bool { true }

    /// User-initiated check (shows Sparkle's UI, including "you're up to date").
    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }

    /// Enables/disables Sparkle's silent scheduled background checks.
    func setAutomaticChecks(_ enabled: Bool) {
        controller.updater.automaticallyChecksForUpdates = enabled
    }
}

#else

/// Stub used until the Sparkle package is added. Keeps the app building.
final class SparkleUpdater {
    static let shared = SparkleUpdater()
    private init() {}
    var isSupported: Bool { false }
    func checkForUpdates() {}
    func setAutomaticChecks(_ enabled: Bool) {}
}

#endif
