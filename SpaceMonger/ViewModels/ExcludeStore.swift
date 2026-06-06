import Foundation
import Combine

/// User-configured glob patterns (matched against item names) that are skipped
/// while scanning. Examples:
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

    var exportText: String { patterns.joined(separator: "\n") }

    func importText(_ text: String) {
        for line in text.split(whereSeparator: { $0.isNewline }) {
            add(String(line))
        }
    }

    private func save() {
        UserDefaults.standard.set(patterns, forKey: key)
    }
}
