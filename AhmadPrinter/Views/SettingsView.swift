import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var store = StoreKitManager.shared

    @AppStorage("settings.printerName")     private var selectedPrinterName = PrintManager.shared.defaultPrinterName
    @AppStorage("settings.colorMode")       private var colorMode     = 0
    @AppStorage("settings.paperSize")       private var paperSize     = 0
    @AppStorage("settings.autoPrint")       private var autoPrint     = false
    @AppStorage("settings.showPageNumbers") private var showPageNumbers = true
    @AppStorage("settings.printQuality")    private var printQuality  = 1
    @State private var restoreStatus: String? = nil

    private let colorModes    = ["Color", "Black & White", "Grayscale"]
    private let paperSizes    = ["A4 (210×297mm)", "Letter (8.5×11in)", "Legal (8.5×14in)", "A3 (297×420mm)", "A5 (148×210mm)"]
    private let qualityOptions = ["Draft", "Normal", "High Quality"]

    private var availablePrinters: [String] { NSPrinter.printerNames }

    var body: some View {
        NavigationView {
            List {
                // ── Printer ──────────────────────────────────────
                Section("Default Printer") {
                    if availablePrinters.isEmpty {
                        HStack {
                            Image(systemName: "printer.fill").foregroundStyle(.secondary)
                            Text("No printers found").foregroundStyle(.secondary)
                        }
                    } else {
                        Picker("Printer", selection: $selectedPrinterName) {
                            ForEach(availablePrinters, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .onChange(of: selectedPrinterName) { _, name in
                            PrintManager.shared.setDefaultPrinter(named: name)
                        }
                    }
                }

                // ── Print Settings ────────────────────────────────
                Section("Print Settings") {
                    Picker(selection: $paperSize) {
                        ForEach(paperSizes.indices, id: \.self) { i in Text(paperSizes[i]).tag(i) }
                    } label: { Label("Paper Size", systemImage: "doc.fill") }

                    Picker(selection: $colorMode) {
                        ForEach(colorModes.indices, id: \.self) { i in Text(colorModes[i]).tag(i) }
                    } label: { Label("Color Mode", systemImage: "paintpalette.fill") }

                    Picker(selection: $printQuality) {
                        ForEach(qualityOptions.indices, id: \.self) { i in Text(qualityOptions[i]).tag(i) }
                    } label: { Label("Print Quality", systemImage: "dial.medium.fill") }
                }

                // ── Preferences ───────────────────────────────────
                Section("Preferences") {
                    Toggle(isOn: $autoPrint) {
                        Label("Auto-Print on File Import", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Toggle(isOn: $showPageNumbers) {
                        Label("Show Page Numbers", systemImage: "number")
                    }
                }

                // ── Subscription ──────────────────────────────────
                Section("Subscription") {
                    HStack {
                        Label("Status", systemImage: store.isPro ? "crown.fill" : "crown")
                        Spacer()
                        Text(store.isPro ? "Pro" : "Free")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(store.isPro ? Color.getProOrange : .secondary)
                    }

                    if !store.isPro {
                        Button {
                            appState.showPaywall = true
                        } label: {
                            Label("Upgrade to Pro", systemImage: "crown.fill")
                                .foregroundStyle(Color.getProOrange)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        restoreStatus = nil
                        Task {
                            await store.restorePurchases()
                            restoreStatus = store.isPro ? "Purchases restored!" : "No active purchases found."
                        }
                    } label: {
                        HStack {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                            Spacer()
                            if store.isPurchasing {
                                ProgressView().controlSize(.small)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)

                    if let status = restoreStatus {
                        Text(status).font(.system(size: 12))
                            .foregroundStyle(store.isPro ? .green : .secondary)
                    }

                    if let err = store.purchaseError {
                        Text(err).font(.system(size: 12)).foregroundStyle(.red)
                    }
                }

                // ── About ─────────────────────────────────────────
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary).font(.system(size: 13))
                    }
                    HStack {
                        Label("Bundle ID", systemImage: "barcode")
                        Spacer()
                        Text("printer.ahmad").foregroundStyle(.secondary).font(.system(size: 12))
                    }
                    Button {
                        NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/privacy/")!)
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }.buttonStyle(.plain)

                    Button {
                        NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/internet-services/itunes/")!)
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }.buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .listStyle(.sidebar)
            .frame(minWidth: 340)
        }
        .frame(width: 520, height: 560)
    }
}
