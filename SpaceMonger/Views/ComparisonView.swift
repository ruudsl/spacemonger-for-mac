import SwiftUI
import AppKit

/// Presents the diff between the current scan and a previously saved one.
struct ComparisonView: View {
    let comparison: ScanComparison
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section(title: loc("Grown"), systemImage: "arrow.up.right", tint: .red, entries: comparison.grown)
                    section(title: loc("Added"), systemImage: "plus", tint: .red, entries: comparison.added)
                    section(title: loc("Shrunk"), systemImage: "arrow.down.right", tint: .green, entries: comparison.shrunk)
                    section(title: loc("Removed"), systemImage: "minus", tint: .green, entries: comparison.removed)
                }
                .padding(16)
            }
        }
        .frame(width: 560, height: 560)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc("Comparison"))
                    .font(.title3.weight(.semibold))
                Text(locf(loc("%@ (now) vs %@ (saved)"), comparison.currentName, comparison.otherName))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                let delta = comparison.totalDelta
                Text(locf(loc("Total change: %@"), signedBytes(delta)))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(delta == 0 ? Color.secondary : (delta > 0 ? Color.red : Color.green))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button(loc("Done"), action: onClose)
                    .keyboardShortcut(.defaultAction)
                Button(loc("Export…"), action: exportCSV)
            }
        }
        .padding(16)
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Comparison.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        var rows = ["change,delta_bytes,size_bytes,path"]
        func append(_ entries: [ScanComparison.Entry], _ label: String) {
            for e in entries {
                let path = e.path.replacingOccurrences(of: "\"", with: "\"\"")
                rows.append("\(label),\(e.delta),\(e.size),\"\(path)\"")
            }
        }
        append(comparison.grown, "grown")
        append(comparison.added, "added")
        append(comparison.shrunk, "shrunk")
        append(comparison.removed, "removed")
        try? rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    @ViewBuilder
    private func section(title: String, systemImage: String, tint: Color, entries: [ScanComparison.Entry]) -> some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label(locf(loc("%@ (%lld)"), title, entries.count), systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                ForEach(entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.name).lineLimit(1)
                            Text(entry.path)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Text(signedBytes(entry.delta))
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(entry.delta > 0 ? .red : .green)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func signedBytes(_ value: Int64) -> String {
        let sign = value > 0 ? "+" : (value < 0 ? "−" : "")
        return sign + Formatting.bytes(abs(value))
    }
}
