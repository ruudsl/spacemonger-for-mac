import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Start screen: pick a mounted volume or choose any folder to scan. Shows the
/// list of disks with a usage bar per disk; also accepts dropped folders.
struct DiskSelectionView: View {
    @EnvironmentObject var vm: ScanViewModel
    @EnvironmentObject var recents: RecentScansStore
    @State private var dropTargeted = false

    private let columns = [GridItem(.adaptive(minimum: 240, maximum: 320), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if case .failed(let message) = vm.scanState {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .padding(.bottom, 4)
                }

                if !vm.hasFullDiskAccess {
                    fullDiskAccessHint
                }

                if let last = vm.lastCachedScan {
                    lastScanCard(last)
                }

                Text("Disks")
                    .font(.headline)
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(vm.volumes) { volume in
                        DiskCard(volume: volume) { vm.scan(volume: volume) }
                    }
                    ChooseFolderCard { chooseFolder() }
                }

                if !recents.items.isEmpty {
                    recentSection
                }
            }
            .padding(28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func lastScanCard(_ last: ScanViewModel.CachedScan) -> some View {
        Button {
            vm.openLastScan()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath").font(.title2).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Continue last scan").font(.callout.weight(.semibold))
                    Text("\(last.name) · \(last.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        }
        .buttonStyle(.plain)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }) else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            var url: URL?
            if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
            else if let direct = item as? URL { url = direct }
            guard let url else { return }
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            DispatchQueue.main.async {
                if isDir.boolValue { vm.scan(folder: url) }
                else { vm.scan(folder: url.deletingLastPathComponent()) }
            }
        }
        return true
    }

    private var fullDiskAccessHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("Enable Full Disk Access to scan system files")
                    .font(.callout.weight(.semibold))
                Text("Without it, system and other users' folders read as empty and show up as “System & hidden space”.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Settings…") { DiskAccess.openFullDiskAccessSettings() }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.12)))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent")
                    .font(.headline)
                Spacer()
                Button("Clear") { recents.clear() }
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
            VStack(spacing: 4) {
                ForEach(recents.items) { scan in
                    RecentRow(scan: scan,
                              action: { vm.scanRecent(scan) },
                              remove: { recents.remove(scan) })
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.tint)
                Text("SpaceMonger")
                    .font(.system(size: 26, weight: .bold))
            }
            Text("Find it. Free it.")
                .font(.title3.weight(.semibold))
            Text("See exactly what's filling your disk and reclaim the space — quickly and safely.")
                .foregroundStyle(.secondary)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan"
        panel.message = "Choose a folder or disk to scan"
        if panel.runModal() == .OK, let url = panel.url {
            vm.scan(folder: url)
        }
    }
}

private struct DiskCard: View {
    let volume: VolumeInfo
    let action: () -> Void
    @State private var hovering = false

    private var subtitle: String {
        let kind = volume.isInternal ? loc("Internal")
            : (volume.isRemovable ? loc("Removable") : loc("External"))
        if let format = volume.formatDescription, !format.isEmpty {
            return "\(kind) · \(format)"
        }
        return kind
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: volume.isRemovable ? "externaldrive.fill" : "internaldrive.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(volume.name).font(.headline).lineLimit(1)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }

                UsageBar(fraction: volume.usedFraction)

                HStack {
                    Text(locf(loc("%@ used"), Formatting.bytes(volume.usedCapacity)))
                    Spacer()
                    Text(locf(loc("%@ free"), Formatting.bytes(volume.availableCapacity)))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(hovering ? Color.accentColor : Color.gray.opacity(0.25),
                                  lineWidth: hovering ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct ChooseFolderCard: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text("Scan a Folder…")
                    .font(.headline)
                Text("Choose any folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 130)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: hovering ? 2 : 1, dash: [6, 4]))
                    .foregroundColor(hovering ? Color.accentColor : Color.gray.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct RecentRow: View {
    let scan: RecentScan
    let action: () -> Void
    let remove: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: scan.isVolume ? "internaldrive" : "folder")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(scan.name).font(.callout.weight(.medium)).lineLimit(1)
                Text(scan.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text(scan.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if hovering {
                Button { remove() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hovering ? Color.accentColor.opacity(0.10) : Color(nsColor: .controlBackgroundColor))
        )
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .onHover { hovering = $0 }
    }
}

struct UsageBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.22))
                Capsule()
                    .fill(barColor)
                    .frame(width: max(4, geo.size.width * CGFloat(min(1, max(0, fraction)))))
            }
        }
        .frame(height: 8)
    }

    private var barColor: Color {
        switch fraction {
        case ..<0.75: return .accentColor
        case ..<0.9: return .orange
        default: return .red
        }
    }
}
