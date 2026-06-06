import SwiftUI
import AppKit

/// Start screen: pick a mounted volume or choose any folder to scan. Mirrors
/// DaisyDisk's disk list with a usage bar per disk.
struct DiskSelectionView: View {
    @EnvironmentObject var vm: ScanViewModel

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

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(vm.volumes) { volume in
                        DiskCard(volume: volume) { vm.scan(volume: volume) }
                    }
                    ChooseFolderCard { chooseFolder() }
                }
            }
            .padding(28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
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
            Text("Select a disk or folder to visualise what's using your space.")
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

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: volume.isRemovable ? "externaldrive.fill" : "internaldrive.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(volume.name).font(.headline).lineLimit(1)
                        Text(volume.isInternal ? "Internal" : (volume.isRemovable ? "Removable" : "External"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                UsageBar(fraction: volume.usedFraction)

                HStack {
                    Text("\(Formatting.bytes(volume.usedCapacity)) used")
                    Spacer()
                    Text("\(Formatting.bytes(volume.availableCapacity)) free")
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
