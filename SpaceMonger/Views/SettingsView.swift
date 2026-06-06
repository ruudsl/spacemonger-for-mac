import SwiftUI

/// Preferences window: Full Disk Access status and exclude patterns (name masks).
struct SettingsView: View {
    @EnvironmentObject var excludes: ExcludeStore
    @State private var newPattern = ""
    @State private var hasFullDiskAccess = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            fullDiskAccessSection
            Divider()
            exclusionsSection
        }
        .padding(20)
        .frame(width: 480, height: 460)
        .onAppear { hasFullDiskAccess = DiskAccess.hasFullDiskAccess() }
    }

    // MARK: - Full Disk Access

    private var fullDiskAccessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Full Disk Access").font(.headline)
            Text("With Full Disk Access, SpaceMonger can read system folders and other users' files, so they no longer count as “System & hidden space”.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Label(hasFullDiskAccess ? "Granted" : "Not granted",
                      systemImage: hasFullDiskAccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(hasFullDiskAccess ? Color.green : Color.orange)
                Spacer()
                Button("Re-check") { hasFullDiskAccess = DiskAccess.hasFullDiskAccess() }
                Button("Open Full Disk Access Settings…") { DiskAccess.openFullDiskAccessSettings() }
            }

            Text("After adding SpaceMonger in System Settings, return here and click Re-check (you may need to relaunch the app).")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Exclusions

    private var exclusionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exclusions").font(.headline)
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
                .frame(minHeight: 120)
            }

            Text("Changes apply to the next scan.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func addPattern() {
        excludes.add(newPattern)
        newPattern = ""
    }
}
