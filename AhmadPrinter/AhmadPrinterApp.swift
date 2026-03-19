import SwiftUI

@main
struct AhmadPrinterApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            // Replace New Item slot with our file commands (avoids a duplicate "File" menu)
            CommandGroup(replacing: .newItem) {
                Button("Import Files…") { appState.selectedTab = .files }
                    .keyboardShortcut("o", modifiers: .command)
                Button("Print…") {}
                    .keyboardShortcut("p", modifiers: .command)
                Divider()
                Button("Open Web Page…") { appState.selectedTab = .home }
            }
            CommandMenu("View") {
                Button("Home")      { appState.selectedTab = .home }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Files")     { appState.selectedTab = .files }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Templates") { appState.selectedTab = .templates }
                    .keyboardShortcut("3", modifiers: .command)
                Divider()
                Button("Settings")  { appState.showSettings = true }
                    .keyboardShortcut(",", modifiers: .command)
                Button("Get Pro…")  { appState.showPaywall = true }
            }
        }
    }
}
