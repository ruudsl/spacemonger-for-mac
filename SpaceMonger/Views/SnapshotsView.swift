import SwiftUI

/// Sheet to review and remove local APFS snapshots and reclaim purgeable space —
/// the controllable part of "System & hidden space".
struct SnapshotsView: View {
    @EnvironmentObject var vm: ScanViewModel
    @State private var selection: Set<String> = []
    @State private var confirmDelete = false
    @State private var confirmThin = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 520, height: 460)
        .confirmationDialog(locf(loc("Delete %lld snapshots?"), selection.count),
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(loc("Delete"), role: .destructive) {
                vm.deleteSnapshots(Array(selection)); selection = []
            }
            Button(loc("Cancel"), role: .cancel) {}
        } message: {
            Text("Local snapshots are extra copies kept by Time Machine. Deleting them is safe and frees space.")
        }
        .confirmationDialog("Free up purgeable space?",
                            isPresented: $confirmThin, titleVisibility: .visible) {
            Button("Free Up Space", role: .destructive) { vm.thinSnapshots() }
            Button(loc("Cancel"), role: .cancel) {}
        } message: {
            Text("macOS will thin local snapshots to reclaim as much space as it can.")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Snapshots & Purgeable Space").font(.title3.weight(.semibold))
                Text(locf(loc("Purgeable: about %@"), Formatting.bytes(vm.purgeableBytes)))
                    .font(.caption).foregroundStyle(.secondary)
                Text("macOS doesn't report a size per snapshot; use Free Up Space to reclaim as much as possible.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(loc("Done")) { vm.showSnapshots = false }
                .keyboardShortcut(.defaultAction)
        }
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        if vm.isWorkingSnapshots {
            VStack(spacing: 10) {
                ProgressView()
                Text("Working…").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.snapshots.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(.secondary)
                Text("No local snapshots").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(vm.snapshots, selection: $selection) { snapshot in
                HStack {
                    Image(systemName: "clock.arrow.circlepath").foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayDate(snapshot))
                        Text(snapshot.dateString).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button(role: .destructive) { confirmThin = true } label: {
                Label("Free Up Space", systemImage: "sparkles")
            }
            .disabled(vm.isWorkingSnapshots)
            Spacer()
            Button(role: .destructive) { confirmDelete = true } label: {
                Label(locf(loc("Delete %lld"), selection.count), systemImage: "trash")
            }
            .disabled(selection.isEmpty || vm.isWorkingSnapshots)
        }
        .padding()
    }

    private func displayDate(_ snapshot: SnapshotManager.LocalSnapshot) -> String {
        guard let date = snapshot.date else { return snapshot.dateString }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
