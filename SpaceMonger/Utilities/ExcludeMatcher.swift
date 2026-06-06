import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Case-insensitive glob matching for exclude patterns, applied to item names.
struct ExcludeMatcher {
    let patterns: [String]

    var isEmpty: Bool { patterns.isEmpty }

    func matches(name: String) -> Bool {
        guard !patterns.isEmpty else { return false }
        for pattern in patterns {
            if fnmatch(pattern, name, Int32(FNM_CASEFOLD)) == 0 {
                return true
            }
        }
        return false
    }
}
