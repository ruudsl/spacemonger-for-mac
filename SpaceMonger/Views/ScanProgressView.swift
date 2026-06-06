import SwiftUI
import AppKit

/// Shown while a scan is in progress: an indeterminate spinner with live item /
/// byte counts and the path currently being measured.
struct ScanProgressView: View {
    @EnvironmentObject var vm: ScanViewModel

    var body: some View {
        VStack(spacing: 22) {
            ProgressView()
                .controlSize(.large)
                .scaleEffect(1.4)

            VStack(spacing: 6) {
                Text("Scanning \(vm.scannedVolume?.name ?? "folder")…")
                    .font(.title3.weight(.semibold))

                if let progress = vm.scanProgress {
                    Text("\(Formatting.count(progress.scannedItems)) items · \(Formatting.bytes(progress.scannedBytes))")
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
