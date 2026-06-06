import SwiftUI

/// A scrollable "Tech Specs" sheet describing what SpaceMonger can scan and how
/// it behaves. Written to reflect the app's actual capabilities.
struct TechSpecsView: View {
    var onClose: () -> Void

    private var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tech Specs").font(.title2.weight(.bold))
                Spacer()
                Button("Done", action: onClose).keyboardShortcut(.defaultAction)
            }
            .padding()
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("Supported disks", "externaldrive", [
                        "Any volume macOS mounts as a file system: internal, external, removable.",
                        "Rotational HDD, SSD, flash & memory cards, optical media.",
                        "Connections: USB, Thunderbolt, FireWire.",
                        "Network volumes (NAS, SMB, AFP, NFS, WebDAV) mounted in the Finder.",
                        "Virtual volumes: disk images and FUSE-based file systems.",
                        "File systems: APFS, HFS+/HFS, exFAT, FAT, NTFS, and anything else macOS mounts."
                    ])

                    section("Scanning", "speedometer", [
                        "Concurrent, multi-core scanning of the top-level folders for speed.",
                        "Scan time depends on disk type, file system and the number of files.",
                        "Use Rescan as Administrator for disks where system files aren't readable."
                    ])

                    section("Hidden space", "questionmark.circle", [
                        "Hidden space is the difference between the disk's used space and the files that could be scanned.",
                        "Lack of permissions → grant Full Disk Access, or Scan as Administrator.",
                        "Purgeable space & APFS snapshots are managed by macOS (About This Mac → Storage)."
                    ])

                    section("File preview", "eye", [
                        "Built-in Quick Look previews any file type (⌘Y) — documents, photos, videos and more."
                    ])

                    section("Safety", "checkmark.shield", [
                        "Safety stoppers block deletion of system-critical components and whole volumes.",
                        "No automatic cleaning — you decide what to delete.",
                        "Deletions go to the Trash, so they remain recoverable."
                    ])

                    section("Privacy", "hand.raised", [
                        "Reads only file metadata — names and sizes — never file contents.",
                        "Does not collect, analyse or transmit any data off your Mac.",
                        "No tracking, statistics or analytics."
                    ])

                    section("System requirements", "cpu", [
                        "macOS 13 Ventura or newer (currently running \(osVersion)).",
                        "Apple Silicon (ARM64) and Intel (x86-64).",
                        "Languages: English, Français, Deutsch, Italiano, Polski, Русский, Español, Português, Svenska, Türkçe, Українська, 简体中文, 繁體中文, 日本語, Nederlands."
                    ])
                }
                .padding()
            }
        }
        .frame(width: 540, height: 600)
    }

    private func section(_ title: String, _ symbol: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.headline)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("•").foregroundStyle(.secondary)
                    Text(item).fixedSize(horizontal: false, vertical: true)
                }
                .font(.callout)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
