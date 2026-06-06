import Foundation

/// Tiny localisation helpers so call sites stay readable.
/// `loc` looks up a localised string; `locf` formats an already-localised
/// template (use as `locf(loc("%@ used"), value)`).
func loc(_ key: String, _ comment: String = "") -> String {
    NSLocalizedString(key, comment: comment)
}

func locf(_ format: String, _ args: CVarArg...) -> String {
    String(format: format, arguments: args)
}
