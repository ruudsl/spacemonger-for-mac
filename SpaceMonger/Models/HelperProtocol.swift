import Foundation

/// XPC interface to the optional privileged helper (also present, identically,
/// in `PrivilegedHelper/` for the helper target). The app side lives here so the
/// integration compiles even before you add and sign the helper target.
@objc public protocol HelperProtocol {
    func measureDiskUsage(path: String,
                          withReply reply: @escaping (_ resultFilePath: String?, _ error: String?) -> Void)
    func helperVersion(withReply reply: @escaping (_ version: String) -> Void)
}

public enum HelperConstants {
    public static let machServiceName = "net.slaats.SpaceMonger.Helper"
    public static let plistName = "net.slaats.SpaceMonger.Helper.plist"
    public static let version = "1.0.0"
}
