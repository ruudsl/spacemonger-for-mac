import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var vm: ScanViewModel

    var body: some View {
        Group {
            switch vm.scanState {
            case .idle, .failed:
                DiskSelectionView()
            case .scanning:
                ScanProgressView()
            case .done:
                ResultsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { vm.loadVolumes() }
        .alert("Something went wrong",
               isPresented: Binding(
                get: { vm.lastError != nil },
                set: { if !$0 { vm.lastError = nil } })) {
            Button("OK", role: .cancel) { vm.lastError = nil }
        } message: {
            Text(vm.lastError ?? "")
        }
    }
}

/// The results screen: a toolbar with the breadcrumb on top, the sunburst on the
/// left and the detail / collector panel on the right.
private struct ResultsView: View {
    @EnvironmentObject var vm: ScanViewModel

    var body: some View {
        VStack(spacing: 0) {
            ResultsToolbar()
            Divider()
            HSplitView {
                SunburstView(vm: vm)
                    .frame(minWidth: 420)
                    .padding(12)
                    .layoutPriority(1)

                DetailPanel()
                    .frame(minWidth: 280, idealWidth: 340, maxWidth: 460)
            }
        }
    }
}

private struct ResultsToolbar: View {
    @EnvironmentObject var vm: ScanViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button {
                vm.loadVolumes()
                vm.backToStart()
            } label: {
                Label("Disks", systemImage: "externaldrive")
            }
            .buttonStyle(.borderless)

            Divider().frame(height: 18)

            BreadcrumbView()

            Spacer()

            Button {
                vm.rescan()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Rescan")
            .disabled(vm.rescanDisabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

/// Right-hand column: info about the selected/focused item, the list of its
/// contents, and the collector pinned to the bottom.
private struct DetailPanel: View {
    @EnvironmentObject var vm: ScanViewModel

    var body: some View {
        VStack(spacing: 0) {
            FileInfoView()
            Divider()
            FileListView()
                .layoutPriority(1)
            Divider()
            CollectorView()
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
