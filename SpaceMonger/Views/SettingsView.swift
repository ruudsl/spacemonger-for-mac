import SwiftUI
import AppKit

/// Preferences: general options, Full Disk Access status, and exclude patterns.
struct SettingsView: View {
    @EnvironmentObject var excludes: ExcludeStore
    @EnvironmentObject var settings: AppSettings
    @State private var newPattern = ""
    @State private var hasFullDiskAccess = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                generalSection
                Divider()
                fullDiskAccessSection
                Divider()
                exclusionsSection
            }
            .padding(20)
        }
        .frame(width: 500, height: 600)
        .onAppear { hasFullDiskAccess = DiskAccess.hasFullDiskAccess() }
    }

    // MARK: - General

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("General").font(.headline)

            Picker("Size units", selection: $settings.useBinaryUnits) {
                Text("Decimal (1000)").tag(false)
                Text("Binary (1024)").tag(true)
            }
            Picker("Default layout", selection: $settings.defaultViewModeRaw) {
                Text("Sunburst").tag("sunburst")
                Text("Treemap").tag("treemap")
            }
            Picker("Default colours", selection: $settings.defaultColorModeRaw) {
                Text("By Folder").tag("rainbow")
                Text("By File Type").tag("byType")
                Text("By Depth").tag("byDepth")
            }

            Toggle("Follow symbolic links", isOn: $settings.followSymlinks)
            Toggle("Confirm before deleting", isOn: $settings.confirmBeforeDelete)
            Toggle("Colour-blind palette", isOn: $settings.colorBlindPalette)
        }
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
        }
    }

    // MARK: - Exclusions

    private var exclusionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Exclusions").font(.headline)
                Spacer()
                Button("Import…") { importExclusions() }
                Button("Export…") { exportExclusions() }
                    .disabled(excludes.patterns.isEmpty)
            }
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
                    .frame(maxWidth: .infinity, minHeight: 70)
            } else {
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

            Text("Changes apply to the next scan.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func addPattern() {
        excludes.add(newPattern)
        newPattern = ""
    }

    private func exportExclusions() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "SpaceMonger Exclusions.txt"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            try? excludes.exportText.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func importExclusions() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText, .text]
        if panel.runModal() == .OK, let url = panel.url,
           let text = try? String(contentsOf: url, encoding: .utf8) {
            excludes.importText(text)
        }
    }
}
