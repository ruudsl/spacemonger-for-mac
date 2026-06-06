import SwiftUI

/// A scrollable, localised "Tech Specs" sheet describing what SpaceMonger can
/// scan and how it behaves. The content reflects the app's actual capabilities.
struct TechSpecsView: View {
    var onClose: () -> Void

    private let languages = "English, Français, Deutsch, Italiano, Polski, Русский, Español, Português, Svenska, Türkçe, Українська, 简体中文, 繁體中文, 日本語, Nederlands"

    private var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(loc("Tech Specs")).font(.title2.weight(.bold))
                Spacer()
                Button(loc("Done"), action: onClose).keyboardShortcut(.defaultAction)
            }
            .padding()
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    spec(loc("Supported disks"), "externaldrive",
                         loc("Any volume macOS mounts as a file system: internal, external, removable, optical, network (NAS, SMB, AFP, NFS, WebDAV) and disk images or FUSE volumes. File systems include APFS, HFS+, exFAT, FAT and NTFS."))
                    spec(loc("Scanning"), "speedometer",
                         loc("Concurrent, multi-core measurement using the macOS file-system APIs. Scan time depends on the disk type, file system and number of files."))
                    spec(loc("Hidden space"), "questionmark.circle",
                         loc("The difference between the disk's used space and the files that could be scanned. Shrink it with Full Disk Access, an administrator scan, or by deleting local snapshots."))
                    spec(loc("File preview"), "eye",
                         loc("Built-in Quick Look previews any file type — press Space or ⌘Y."))
                    spec(loc("Safety"), "checkmark.shield",
                         loc("Safety stoppers block deleting system-critical components and whole volumes. Nothing is cleaned automatically and deletions go to the Trash."))
                    spec(loc("Privacy"), "hand.raised",
                         loc("Reads only file metadata — names and sizes — never contents. Nothing is collected, analysed or sent off your Mac."))
                    spec(loc("System requirements"), "cpu",
                         locf(loc("macOS 13 or newer (currently %@), on Apple Silicon and Intel."), osVersion))
                    spec(loc("Languages"), "globe", languages)
                }
                .padding()
            }
        }
        .frame(width: 560, height: 600)
    }

    private func spec(_ title: String, _ symbol: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol).font(.headline)
            Text(body)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
