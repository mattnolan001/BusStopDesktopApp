import SwiftUI

@main
struct BusStopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Buses", systemImage: "bus") {
            MenuContent(store: appDelegate.store, appDelegate: appDelegate)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuContent: View {
    @ObservedObject var store: DeparturesStore
    let appDelegate: AppDelegate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DeparturesView(store: store, maxRows: 12)
            Divider()
            HStack {
                Button("Open Window") { appDelegate.showMainWindow() }
                Button("Change Stop…") { appDelegate.showStopPicker() }
                Spacer()
                Button {
                    store.wake()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .frame(width: 340)
        .onAppear { store.wake() }
    }
}
