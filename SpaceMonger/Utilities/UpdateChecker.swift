import Foundation

/// Minimal "Check for Updates" against the project's GitHub Releases.
enum UpdateChecker {
    static let repo = "ruudsl/spacemonger-for-mac"
    static let releasesPage = URL(string: "https://github.com/\(repo)/releases")!

    struct Release {
        let version: String   // tag, e.g. "v1.1" or "1.1"
        let url: URL?         // release page
    }

    /// Latest published release, or nil on failure.
    static func latestRelease() async -> Release? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")
        else { return nil }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String else { return nil }
        let html = (json["html_url"] as? String).flatMap(URL.init(string:))
        return Release(version: tag, url: html ?? releasesPage)
    }

    static func normalized(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// True when `latest` is a higher version than what's running.
    static func isNewer(_ latest: String, than current: String) -> Bool {
        normalized(latest).compare(current, options: .numeric) == .orderedDescending
    }
}
