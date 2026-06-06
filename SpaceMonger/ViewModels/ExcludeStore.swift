import Foundation
import Combine

/// User-configured glob patterns (matched against item names) that are skipped
/// while scanning — GrandPerspective's exclude/mask idea. Examples:
/// `node_modules`, `*.log`, `.DS_Store`, `*.xcuserstate`.
final class ExcludeStore: ObservableObject {
    @Published var patterns: [String] {
        didSet { save() }
    }

    private let key = "excludePatterns.v1"

    init() {
        patterns = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func add(_ pattern: String) {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !patterns.contains(trimmed) else { return }
        patterns.append(trimmed)
    }

    func remove(_ pattern: String) {
        patterns.removeAll { $0 == pattern }
    }

    private func save() {
        UserDefaults.standard.set(patterns, forKey: key)
    }
}
