import Foundation

/// Safety stoppers: identifies system-critical locations that must never be
/// moved to the Trash, to protect the user from accidentally breaking macOS or
/// wiping a whole volume. The user still decides what to delete among their own
/// files — this only blocks the dangerous, system-owned paths.
enum SystemPaths {

    private static let protectedExact: Set<String> = [
        "/", "/System", "/usr", "/bin", "/sbin", "/etc", "/var", "/tmp",
        "/private", "/dev", "/cores", "/Library", "/Applications", "/Users",
        "/opt", "/Network", "/Volumes", "/System/Library", "/private/var",
        "/private/etc", "/private/tmp"
    ]

    private static let protectedTrees = [
        "/System/", "/bin/", "/sbin/", "/private/var/db/", "/dev/", "/usr/"
    ]

    static func isProtected(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path

        if path == "/" { return true }
        if isVolumeRoot(path) { return true }
        if protectedExact.contains(path) { return true }

        for prefix in protectedTrees where path.hasPrefix(prefix) {
            // /usr/local is the standard place for user-installed software.
            if prefix == "/usr/" && (path == "/usr/local" || path.hasPrefix("/usr/local/")) {
                return false
            }
            return true
        }

        // The home directory itself and the whole ~/Library are off limits.
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        if path == home || path == home + "/Library" { return true }

        return false
    }

    /// A directly-mounted volume root such as "/Volumes/Backup".
    private static func isVolumeRoot(_ path: String) -> Bool {
        (path as NSString).deletingLastPathComponent == "/Volumes"
    }
}
