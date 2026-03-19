import SwiftUI

struct TopNavigationBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            // Logo
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.primaryRed)
                        .frame(width: 44, height: 44)
                    Image(systemName: "printer.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("Smart Printer")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
            }
            .padding(.leading, 24)

            Spacer()

            // Tab buttons
            HStack(spacing: 8) {
                NavTabButton(tab: .home, icon: "house.fill")
                NavTabButton(tab: .files, icon: "folder.fill")
                NavTabButton(tab: .templates, icon: "doc.text.fill")
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.7))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1))

            Spacer()

            // Right actions
            HStack(spacing: 10) {
                if !appState.isPro {
                Button {
                    appState.showPaywall = true
                } label: {
                    Text("Get Pro")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.96, green: 0.65, blue: 0.2), Color(red: 0.90, green: 0.45, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                }

                Button {
                    appState.showSettings.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 42, height: 42)
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 24)
        }
        .frame(height: 72)
        .background(Color.clear)
    }
}

struct NavTabButton: View {
    @EnvironmentObject var appState: AppState
    let tab: NavigationTab
    let icon: String

    private var isSelected: Bool { appState.selectedTab == tab }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                appState.selectedTab = tab
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.primaryRed : Color.pillBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .black.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}
