import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Full-window background gradient
            AppBackground()

            VStack(spacing: 0) {
                TopNavigationBar()

                // Thin separator
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 1)

                // Main content area
                Group {
                    switch appState.selectedTab {
                    case .home:
                        HomeView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case .files:
                        FilesView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case .templates:
                        TemplatesView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: appState.selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Paywall overlay
            if appState.showPaywall {
                PaywallView()
                    .zIndex(100)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .frame(minWidth: 900, idealWidth: 1100, minHeight: 640, idealHeight: 760)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.showPaywall)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
