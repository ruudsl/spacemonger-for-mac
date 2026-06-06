import Foundation
import ServiceManagement

/// App-side integration for the optional privileged helper daemon.
///
/// Until a signed helper target is added and registered, `isAvailable` is false
/// and the app falls back to the authorized-`du` administrator scan. Once the
/// helper is bundled and approved, the admin scan goes through it with no
/// per-scan password prompt.
enum PrivilegedHelperManager {

    private static var daemon: SMAppService {
        SMAppService.daemon(plistName: HelperConstants.plistName)
    }

    /// True only when a registered, enabled helper is present.
    static var isAvailable: Bool {
        daemon.status == .enabled
    }

    /// Registers the helper (prompts the user to approve it in System Settings).
    /// Only meaningful once the helper executable is bundled in the app.
    static func install() throws {
        try daemon.register()
    }

    static func uninstall() throws {
        try daemon.unregister()
    }

    /// Asks the helper to measure `url` and returns the path of the `du` listing
    /// file it produced.
    static func measure(_ url: URL) async throws -> String {
        let connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName,
                                         options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.resume()
        defer { connection.invalidate() }

        return try await withCheckedThrowingContinuation { continuation in
            let proxy = connection.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as? HelperProtocol

            guard let proxy else {
                continuation.resume(throwing: NSError(
                    domain: "SpaceMonger", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Privileged helper is unavailable."]))
                return
            }
            proxy.measureDiskUsage(path: url.path) { resultPath, error in
                if let resultPath {
                    continuation.resume(returning: resultPath)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "SpaceMonger", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: error ?? "Helper failed"]))
                }
            }
        }
    }
}
