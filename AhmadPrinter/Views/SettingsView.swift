import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject private var store = StoreKitManager.shared

    @AppStorage("settings.printerName")     private var selectedPrinterName = PrintManager.shared.defaultPrinterName
    @AppStorage("settings.colorMode")       private var colorMode     = 0
    @AppStorage("settings.paperSize")       private var paperSize     = 0
    @AppStorage("settings.autoPrint")       private var autoPrint     = false
    @AppStorage("settings.showPageNumbers") private var showPageNumbers = true
    @AppStorage("settings.printQuality")    private var printQuality  = 1
    @State private var restoreStatus: String? = nil
    @State private var selectedSection: SettingsSection = .general

    private let colorModes    = ["Color", "Black & White", "Grayscale"]
    private let paperSizes    = ["A4 (210x297mm)", "Letter (8.5x11in)", "Legal (8.5x14in)", "A3 (297x420mm)", "A5 (148x210mm)"]
    private let qualityOptions = ["Draft", "Normal", "High Quality"]

    private var availablePrinters: [String] { NSPrinter.printerNames }

    enum SettingsSection: String, CaseIterable, Identifiable {
        case general    = "General"
        case printing   = "Printing"
        case subscription = "Subscription"
        case about      = "About"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general:      return "gearshape.fill"
            case .printing:     return "printer.fill"
            case .subscription: return "crown.fill"
            case .about:        return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebar

            // Divider
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(width: 1)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedSection {
                    case .general:      generalSection
                    case .printing:     printingSection
                    case .subscription: subscriptionSection
                    case .about:        aboutSection
                    }
                }
                .padding(28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .frame(width: 620, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Sidebar
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primaryRed)
                        .frame(width: 36, height: 36)
                    Image(systemName: "printer.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Settings")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                    Text("Smart Printer")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 20)

            // Nav items
            VStack(spacing: 2) {
                ForEach(SettingsSection.allCases) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: section.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(selectedSection == section ? Color.primaryRed : Color.secondary)
                                .frame(width: 20)
                            Text(section.rawValue)
                                .font(.system(size: 13, weight: selectedSection == section ? .semibold : .regular))
                                .foregroundStyle(selectedSection == section ? .black : Color(white: 0.40))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedSection == section ? Color.primaryRed.opacity(0.08) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // Version at bottom
            Text("v1.0.0")
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.70))
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
        }
        .frame(width: 190)
        .background(Color(red: 0.97, green: 0.97, blue: 0.975))
    }

    // MARK: - General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("General", subtitle: "Preferences and behavior")

            // Default Printer
            settingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    settingsRowLabel("Default Printer", icon: "printer.fill", color: .blue)

                    if availablePrinters.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                            Text("No printers found on this Mac")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 2)
                    } else {
                        Picker("", selection: $selectedPrinterName) {
                            ForEach(availablePrinters, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: selectedPrinterName) { _, name in
                            PrintManager.shared.setDefaultPrinter(named: name)
                        }
                    }
                }
            }

            // Preferences
            settingsCard {
                VStack(spacing: 16) {
                    settingsToggleRow(
                        "Auto-Print on File Import",
                        icon: "arrow.triangle.2.circlepath",
                        color: .green,
                        subtitle: "Automatically send files to printer when imported",
                        isOn: $autoPrint
                    )
                    Divider()
                    settingsToggleRow(
                        "Show Page Numbers",
                        icon: "number",
                        color: .indigo,
                        subtitle: "Display page numbers on printed documents",
                        isOn: $showPageNumbers
                    )
                }
            }
        }
    }

    // MARK: - Printing Section
    private var printingSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("Printing", subtitle: "Paper, color, and quality settings")

            settingsCard {
                VStack(spacing: 16) {
                    settingsPickerRow("Paper Size", icon: "doc.fill", color: .orange,
                                      options: paperSizes, selection: $paperSize)
                    Divider()
                    settingsPickerRow("Color Mode", icon: "paintpalette.fill", color: .purple,
                                      options: colorModes, selection: $colorMode)
                    Divider()
                    settingsPickerRow("Print Quality", icon: "dial.medium.fill", color: .teal,
                                      options: qualityOptions, selection: $printQuality)
                }
            }
        }
    }

    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("Subscription", subtitle: "Manage your plan and purchases")

            // Status card
            settingsCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(store.isPro
                                  ? LinearGradient(colors: [Color.getProOrange, Color(red: 0.92, green: 0.50, blue: 0.10)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                  : LinearGradient(colors: [Color(white: 0.88), Color(white: 0.82)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.isPro ? "Pro Plan" : "Free Plan")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                        Text(store.isPro ? "All features unlocked" : "Limited features available")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(store.isPro ? "Active" : "Free")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(store.isPro ? .white : .secondary)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(
                            Capsule().fill(store.isPro ? Color.getProOrange : Color(white: 0.92))
                        )
                }
            }

            // Actions
            if !store.isPro {
                Button {
                    appState.showPaywall = true
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Upgrade to Pro")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.getProOrange, Color(red: 0.90, green: 0.45, blue: 0.10)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            settingsCard {
                VStack(spacing: 14) {
                    Button {
                        restoreStatus = nil
                        Task {
                            await store.restorePurchases()
                            restoreStatus = store.isPro ? "Purchases restored!" : "No active purchases found."
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.primaryRed)
                                .frame(width: 20)
                            Text("Restore Purchases")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.black)
                            Spacer()
                            if store.isPurchasing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if let status = restoreStatus {
                        HStack(spacing: 6) {
                            Image(systemName: store.isPro ? "checkmark.circle.fill" : "info.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(store.isPro ? .green : .secondary)
                            Text(status)
                                .font(.system(size: 12))
                                .foregroundStyle(store.isPro ? .green : .secondary)
                        }
                    }

                    if let err = store.purchaseError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("About", subtitle: "App information and legal")

            // App info card
            settingsCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.primaryRed)
                            .frame(width: 52, height: 52)
                        Image(systemName: "printer.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Smart Printer")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                        Text("Version 1.0.0")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("printer.ahmad")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color(white: 0.60))
                    }

                    Spacer()
                }
            }

            // Legal links
            settingsCard {
                VStack(spacing: 0) {
                    settingsLinkRow("Privacy Policy", icon: "hand.raised.fill", color: .blue) {
                        NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/privacy/")!)
                    }
                    Divider().padding(.leading, 34)
                    settingsLinkRow("Terms of Service", icon: "doc.text.fill", color: .orange) {
                        NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/internet-services/itunes/")!)
                    }
                }
            }
        }
    }

    // MARK: - Reusable Components

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(white: 0.975))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func settingsRowLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
        }
    }

    private func settingsToggleRow(_ title: String, icon: String, color: Color, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.black)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(Color.primaryRed)
        }
    }

    private func settingsPickerRow(_ title: String, icon: String, color: Color, options: [String], selection: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.black)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options.indices, id: \.self) { i in
                    Text(options[i]).tag(i)
                }
            }
            .labelsHidden()
            .frame(width: 160)
        }
    }

    private func settingsLinkRow(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
