import Foundation

/// XPC interface between SpaceMonger and its privileged helper.
///
/// Shared by both the app target and the helper target. The helper runs as root
/// (installed via `SMAppService.daemon`) and measures disk usage of locations
/// the unprivileged app cannot read.
@objc public protocol HelperProtocol {

    /// Measures on-disk usage of `path` as root, writes a `du`-style listing to
    /// a temporary file made readable by the caller, and returns that file's
    /// path (or an error message).
    func measureDiskUsage(path: String,
                          withReply reply: @escaping (_ resultFilePath: String?, _ error: String?) -> Void)

    /// Returns the helper's version, used to decide whether to (re)install it.
    func helperVersion(withReply reply: @escaping (_ version: String) -> Void)
}

public enum HelperConstants {
    /// Must match the Mach service name in the daemon's launchd plist and the
    /// helper executable name.
    public static let machServiceName = "net.slaats.SpaceMonger.Helper"
    public static let version = "1.0.0"
}
