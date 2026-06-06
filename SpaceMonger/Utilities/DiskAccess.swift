import Foundation
import AppKit

/// Helpers around macOS privacy (TCC) for scanning system locations.
///
/// To measure the *whole* startup disk — including `~/Library`, other users'
/// data and most of `/System` and `/Library` — a normal (non-root) app needs
/// **Full Disk Access**. Without it those folders read as empty and their space
/// ends up lumped into the "System & hidden space" segment. The few files that
/// truly require root are rare; Full Disk Access unlocks the vast majority.
enum DiskAccess {

    /// Best-effort probe: tries to read a couple of TCC-protected locations. If
    /// any is listable we almost certainly have Full Disk Access.
    static func hasFullDiskAccess() -> Bool {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let probes = [
            home.appendingPathComponent("Library/Mail"),
            home.appendingPathComponent("Library/Safari"),
            URL(fileURLWithPath: "/Library/Application Support/com.apple.TCC")
        ]
        for url in probes where fm.fileExists(atPath: url.path) {
            if (try? fm.contentsOfDirectory(atPath: url.path)) != nil {
                return true
            }
        }
        // None of the probes exist or are readable — assume access is limited.
        return false
    }

    /// Opens System Settings at the Full Disk Access pane.
    static func openFullDiskAccessSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        ]
        for string in urls {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
