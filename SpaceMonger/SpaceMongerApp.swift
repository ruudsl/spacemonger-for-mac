import SwiftUI
import AppKit

@main
struct SpaceMongerApp: App {
    @StateObject private var vm = ScanViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environmentObject(vm.recentScans)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Scan Folder…") { chooseFolder() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button("Rescan") { vm.rescan() }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(vm.rescanDisabled)
            }
            CommandMenu("View") {
                Picker("Layout", selection: $vm.viewMode) {
                    ForEach(ScanViewModel.ViewMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                Divider()
                Picker("Colour", selection: $vm.colorMode) {
                    ForEach(ScanViewModel.ColorMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
            }
            CommandMenu("Item") {
                Button("Quick Look") { vm.quickLook(vm.selectedNode) }
                    .keyboardShortcut("y", modifiers: [.command])
                    .disabled(vm.selectedNode == nil)
                Button("Open") {
                    if let node = vm.selectedNode { vm.open(node) }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .disabled(vm.selectedNode == nil)
                Button("Reveal in Finder") {
                    if let node = vm.selectedNode { vm.reveal(node) }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(vm.selectedNode == nil)
                Button("Copy Path") {
                    if let node = vm.selectedNode { vm.copyPath(node) }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(vm.selectedNode == nil)
                Divider()
                Button("Add to Collector") {
                    if let node = vm.selectedNode { vm.addToCollector(node) }
                }
                .keyboardShortcut("d", modifiers: [.command])
                .disabled(vm.selectedNode == nil)
                Button("Move to Trash") {
                    if let node = vm.selectedNode { vm.trash(node) }
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(vm.selectedNode == nil)
            }
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
