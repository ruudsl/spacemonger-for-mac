import Foundation

/// Entry point for the privileged helper daemon. Listens on the Mach service and
/// serves `HelperProtocol` requests as root.
///
/// SECURITY: a production build MUST verify the connecting client's code-signing
/// identity (audit token / `SecCode`) in `shouldAcceptNewConnection` before
/// trusting it, so that only the signed SpaceMonger app can drive the helper.
/// That check is intentionally left as a clearly-marked TODO below because it
/// depends on your Developer ID team identifier.
final class HelperDelegate: NSObject, NSXPCListenerDelegate, HelperProtocol {

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        // TODO: verify connection.auditToken against your app's code requirement
        // (e.g. identifier "net.slaats.SpaceMonger" and your Team ID) before
        // accepting. Reject otherwise.
        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedObject = self
        connection.resume()
        return true
    }

    func helperVersion(withReply reply: @escaping (String) -> Void) {
        reply(HelperConstants.version)
    }

    func measureDiskUsage(path: String,
                          withReply reply: @escaping (String?, String?) -> Void) {
        let tmp = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("smhelper-\(UUID().uuidString).txt")
        let command = "/usr/bin/du -k -a -x -- \(shellQuote(path)) > \(shellQuote(tmp)) 2>/dev/null; /bin/chmod 644 \(shellQuote(tmp))"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            reply(nil, error.localizedDescription)
            return
        }
        reply(tmp, nil)
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
