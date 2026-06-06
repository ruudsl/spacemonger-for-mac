import SwiftUI
import AppKit

/// Shown while a scan is in progress: an indeterminate spinner with live item /
/// byte counts and the path currently being measured.
struct ScanProgressView: View {
    @EnvironmentObject var vm: ScanViewModel

    private var progressFraction: Double? {
        guard vm.expectedBytes > 0, let scanned = vm.scanProgress?.scannedBytes else { return nil }
        return min(1.0, Double(scanned) / Double(vm.expectedBytes))
    }

    var body: some View {
        VStack(spacing: 22) {
            if let fraction = progressFraction {
                ProgressView(value: fraction)
                    .progressViewStyle(.linear)
                    .frame(width: 280)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .scaleEffect(1.4)
            }

            VStack(spacing: 6) {
                Text(locf(loc("Scanning %@…"), vm.scannedVolume?.name ?? loc("folder")))
                    .font(.title3.weight(.semibold))

                if let progress = vm.scanProgress {
                    Text(locf(loc("%@ items · %@"),
                              Formatting.count(progress.scannedItems),
                              Formatting.bytes(progress.scannedBytes)))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text(progress.currentPath)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 480)
                } else {
                    Text("Preparing…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let tlp = vm.topLevelProgress, tlp.total > 0 {
                    Text(locf(loc("%lld of %lld top-level folders"), tlp.done, tlp.total))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            Button("Cancel") {
                vm.cancelScan()
                vm.backToStart()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
