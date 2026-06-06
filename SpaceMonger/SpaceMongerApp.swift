import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { vm.checkForUpdates() }
            }
            CommandGroup(replacing: .newItem) {
                Button("Scan Folder…") { chooseFolder() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button("Rescan") { vm.rescan() }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(vm.rescanDisabled)
                Button("Rescan as Administrator") { vm.rescanAsAdministrator() }
                    .keyboardShortcut("r", modifiers: [.command, .option])
                    .disabled(vm.rescanDisabled)
                Divider()
                Button("Open Scan…") { openScan() }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                Button("Save Scan…") { saveScan() }
                    .keyboardShortcut("s", modifiers: [.command])
                    .disabled(!vm.canSaveScan)
                Button("Compare with Saved Scan…") { compareScan() }
                    .disabled(!vm.canSaveScan)
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
            CommandMenu("Tools") {
                Button("Manage Local Snapshots…") { vm.openSnapshots() }
            }
            CommandGroup(replacing: .help) {
                Button("SpaceMonger Help") { vm.showHelp = true }
                    .keyboardShortcut("?", modifiers: [.command])
                Button("SpaceMonger Tech Specs") { vm.showTechSpecs = true }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(vm.excludes)
                .environmentObject(vm.settings)
        }
    }

    // MARK: - Panels

    private var scanType: UTType {
        UTType(filenameExtension: ScanArchive.fileExtension) ?? .json
    }

    private var openableScanTypes: [UTType] {
        [scanType, .json, UTType(filenameExtension: "gpscan") ?? .xml]
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

    private func openScan() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = openableScanTypes
        if panel.runModal() == .OK, let url = panel.url {
            vm.openScan(from: url)
        }
    }

    private func saveScan() {
        guard vm.canSaveScan else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [scanType]
        panel.nameFieldStringValue = vm.suggestedFileName
        if panel.runModal() == .OK, let url = panel.url {
            vm.saveCurrentScan(to: url)
        }
    }

    private func compareScan() {
        guard vm.canSaveScan else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = openableScanTypes
        panel.message = "Choose a saved scan to compare against the current one"
        if panel.runModal() == .OK, let url = panel.url {
            vm.compareWith(url: url)
        }
    }
}
