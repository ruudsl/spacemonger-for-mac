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
        .overlay {
            if vm.isComparing {
                ProgressView("Comparing…")
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(item: $vm.comparison) { comparison in
            ComparisonView(comparison: comparison) { vm.comparison = nil }
        }
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
            if vm.shouldShowAccessBanner {
                AccessBanner()
                Divider()
            }
            HSplitView {
                Group {
                    switch vm.viewMode {
                    case .sunburst: SunburstView(vm: vm)
                    case .treemap:  TreemapView(vm: vm)
                    }
                }
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

            Picker("", selection: $vm.viewMode) {
                ForEach(ScanViewModel.ViewMode.allCases) { mode in
                    Image(systemName: mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 92)
            .help("Switch between Sunburst and Treemap")

            Menu {
                Picker("Colour", selection: $vm.colorMode) {
                    ForEach(ScanViewModel.ColorMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "paintpalette")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 44)
            .help("Colour mode")

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

/// Banner shown after a scan when system folders were unreadable, nudging the
/// user toward Full Disk Access so the "System & hidden space" shrinks.
private struct AccessBanner: View {
    @EnvironmentObject var vm: ScanViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("Some system folders couldn't be read")
                    .font(.callout.weight(.semibold))
                Text("Grant Full Disk Access to measure system files instead of lumping them into “System & hidden space”.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Scan as Administrator") { vm.rescanAsAdministrator() }
            Button("Open Settings…") { DiskAccess.openFullDiskAccessSettings() }
            Button {
                vm.dismissAccessBanner()
            } label: { Image(systemName: "xmark") }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.10))
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
