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
        "/System/", "/bin/", "/sbin/", "/private/var/db/", "/private/var/folders/",
        "/dev/", "/usr/", "/Library/"
    ]

    static func isProtected(_ url: URL) -> Bool {
        // Check both the lexically-standardized path and the fully symlink-resolved
        // path. `standardizedFileURL` only collapses "." / ".." — it does NOT
        // resolve symlinks — so a link whose target (or whose ancestor) is a
        // protected location would otherwise slip past the deny-list.
        if isProtectedPath(url.standardizedFileURL.path) { return true }
        return isProtectedPath(url.resolvingSymlinksInPath().standardizedFileURL.path)
    }

    private static func isProtectedPath(_ rawPath: String) -> Bool {
        let path = logicalPath(rawPath)

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
        if path == home { return true }
        if path == home + "/Library" || path.hasPrefix(home + "/Library/") { return true }

        return false
    }

    /// On modern macOS the user's data lives on a separate APFS volume firmlinked
    /// in at `/System/Volumes/Data` (so `/Users/me` and
    /// `/System/Volumes/Data/Users/me` are the same bytes). `resolvingSymlinksInPath`
    /// can surface the latter form; map it back to the logical path so the user's
    /// own files aren't blanket-blocked by the `/System/` rule — while the data
    /// volume *root* itself stays protected.
    private static func logicalPath(_ path: String) -> String {
        let dataPrefix = "/System/Volumes/Data"
        if path == dataPrefix { return "/" }
        if path.hasPrefix(dataPrefix + "/") { return String(path.dropFirst(dataPrefix.count)) }
        return path
    }

    /// A directly-mounted volume root such as "/Volumes/Backup".
    private static func isVolumeRoot(_ path: String) -> Bool {
        (path as NSString).deletingLastPathComponent == "/Volumes"
    }
}
