import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = DeparturesStore()
    private var mainWindow: NSWindow?
    private var stopPickerWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !launchedAsLoginItem() { showMainWindow() }
    }

    /// Double-clicking the app while it's already running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func showMainWindow() {
        if mainWindow == nil {
            let view = DeparturesView(store: store)
                .padding()
                .frame(minWidth: 340, minHeight: 240, alignment: .top)
            mainWindow = makeWindow(title: "Bus Times", content: view, autosave: "MainWindow")
        }
        present(mainWindow)
        Task { await store.refresh() }
    }

    func showStopPicker() {
        if stopPickerWindow == nil {
            let view = StopPickerView(store: store) { [weak self] in self?.stopPickerWindow?.close() }
            stopPickerWindow = makeWindow(title: "Change Stop", content: view, autosave: "StopPicker")
        }
        present(stopPickerWindow)
    }

    private func makeWindow(title: String, content: some View, autosave: String) -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: content))
        window.title = title
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName(autosave)
        window.center()
        return window
    }

    private func present(_ window: NSWindow?) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func launchedAsLoginItem() -> Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else { return false }
        return event.eventID == kAEOpenApplication
            && event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
