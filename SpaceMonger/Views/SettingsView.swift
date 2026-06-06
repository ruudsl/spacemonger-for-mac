import SwiftUI

/// Preferences window: manage exclude patterns (name masks).
struct SettingsView: View {
    @EnvironmentObject var excludes: ExcludeStore
    @State private var newPattern = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exclusions")
                .font(.headline)
            Text("Items whose name matches one of these glob patterns are skipped while scanning. Examples: node_modules, *.log, .DS_Store")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                TextField("Add pattern…", text: $newPattern, onCommit: addPattern)
                    .textFieldStyle(.roundedBorder)
                Button("Add", action: addPattern)
                    .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if excludes.patterns.isEmpty {
                Text("No exclusions")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                List {
                    ForEach(excludes.patterns, id: \.self) { pattern in
                        HStack {
                            Image(systemName: "nosign").foregroundStyle(.secondary)
                            Text(pattern).font(.system(.body, design: .monospaced))
                            Spacer()
                            Button {
                                excludes.remove(pattern)
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(minHeight: 140)
            }

            Text("Changes apply to the next scan.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(width: 460, height: 360)
    }

    private func addPattern() {
        excludes.add(newPattern)
        newPattern = ""
    }
}
