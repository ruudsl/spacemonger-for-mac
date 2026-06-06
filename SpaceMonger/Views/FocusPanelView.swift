import SwiftUI

/// Popover for the focus mask: highlight only files that match name / type /
/// minimum-size criteria; everything else is dimmed and filtered out of the list.
struct FocusPanelView: View {
    @EnvironmentObject var vm: ScanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $vm.focus.enabled) {
                Text("Focus on matching files").font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                field(label: loc("Name"),
                      prompt: loc("contains or glob, e.g. *.mp4"),
                      text: $vm.focus.nameQuery)

                field(label: loc("Type"),
                      prompt: loc("extension, e.g. mov"),
                      text: $vm.focus.fileExtension)

                HStack {
                    Text("Min size").frame(width: 70, alignment: .leading)
                    TextField("0", value: $vm.focus.minSizeMB, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                    Text("MB").foregroundStyle(.secondary)
                }
            }
            .disabled(!vm.focus.enabled)
            .opacity(vm.focus.enabled ? 1 : 0.5)

            Divider()

            HStack {
                Button("Clear") { vm.clearFocus() }
                Spacer()
                if vm.isFocusActive {
                    Text(locf(loc("%lld in focus"), vm.focusMatchIDs.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(width: 300)
    }

    private func field(label: String, prompt: String, text: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 70, alignment: .leading)
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
