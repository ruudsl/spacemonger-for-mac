import Foundation

/// Minimal "Check for Updates" against the project's GitHub Releases.
enum UpdateChecker {
    private static let repo = "ruudsl/spacemonger-for-mac"

    /// Latest release tag (e.g. "v1.2" or "1.2"), or nil on failure.
    static func latestVersion() async -> String? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")
        else { return nil }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String else { return nil }
        return tag
    }

    static func normalized(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }
}
