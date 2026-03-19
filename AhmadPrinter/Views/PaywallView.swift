import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var store = StoreKitManager.shared
    @State private var selectedProductID: String = StoreKitManager.yearlyID

    private let features: [(String, String)] = [
        ("printer.fill",            "Print as much as you need"),
        ("pencil.and.scribble",     "Create, edit and print all in one place"),
        ("globe",                   "Print documents, images, web pages & iCloud files"),
        ("viewfinder",              "Convert scanned documents into printable text"),
        ("doc.plaintext.fill",      "Access all pre-designed templates"),
        ("nosign",                  "No Limits — unlimited prints"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { if !store.isPurchasing { dismiss() } }

            HStack(spacing: 0) {
                // -- Left panel --
                VStack(alignment: .leading, spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.96))
                            .frame(width: 160, height: 160)
                        Image(systemName: "printer.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.9))
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features, id: \.0) { icon, text in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.primaryRed.opacity(0.12)).frame(width: 30, height: 30)
                                    Image(systemName: icon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.primaryRed)
                                }
                                Text(text)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.black.opacity(0.75))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(32)
                .frame(width: 320)
                .background(Color(red: 0.97, green: 0.97, blue: 0.98))

                // -- Right panel --
                VStack(alignment: .leading, spacing: 18) {
                    Text("Unlimited Access to all Features")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)

                    Text("Unlock the full power of Smart Printer Pro — print smarter, faster, and without limits!")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    // Products
                    if store.isLoading {
                        HStack { Spacer(); ProgressView("Loading plans..."); Spacer() }
                            .frame(height: 130)
                    } else if store.products.isEmpty {
                        VStack(spacing: 10) {
                            FallbackPlanRow(title: "Weekly",  price: "$2.99/wk",  badge: "Try It Out",   isSelected: selectedProductID == StoreKitManager.weeklyID)  { selectedProductID = StoreKitManager.weeklyID }
                            FallbackPlanRow(title: "Monthly", price: "$7.99/mo",  badge: nil,            isSelected: selectedProductID == StoreKitManager.monthlyID) { selectedProductID = StoreKitManager.monthlyID }
                            FallbackPlanRow(title: "Yearly",  price: "$39.99/yr", badge: "Best Value",   isSelected: selectedProductID == StoreKitManager.yearlyID)  { selectedProductID = StoreKitManager.yearlyID }
                        }
                    } else {
                        VStack(spacing: 10) {
                            ForEach(store.products) { product in
                                ProductRow(product: product, isSelected: selectedProductID == product.id) {
                                    selectedProductID = product.id
                                }
                            }
                        }
                    }

                    // No commitment note
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.system(size: 15))
                        Text("No Commitment,").font(.system(size: 13, weight: .semibold))
                        Text("Cancel Anytime").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    // Error
                    if let err = store.purchaseError {
                        Text(err).font(.system(size: 12)).foregroundStyle(.red).multilineTextAlignment(.center)
                    }

                    // CTA
                    Button {
                        Task {
                            if let product = store.product(for: selectedProductID) {
                                await store.purchase(product)
                                if store.isPro { dismiss() }
                            }
                        }
                    } label: {
                        Group {
                            if store.isPurchasing {
                                ProgressView().controlSize(.small)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            } else {
                                HStack {
                                    Text("Subscribe Now")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                        }
                        .background(store.isPurchasing ? Color.gray : Color.primaryRed)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isPurchasing)

                    // Footer links - all functional
                    HStack(spacing: 4) {
                        Button("Terms") {
                            NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/internet-services/itunes/")!)
                        }
                        .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 11))

                        Text("|").foregroundStyle(.secondary.opacity(0.5))

                        Button("Privacy Policy") {
                            NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/privacy/")!)
                        }
                        .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 11))

                        Text("|").foregroundStyle(.secondary.opacity(0.5))

                        Button("Restore") {
                            Task { await store.restorePurchases(); if store.isPro { dismiss() } }
                        }
                        .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 11))

                        Text("|").foregroundStyle(.secondary.opacity(0.5))

                        Button("Try free version") { dismiss() }
                            .buttonStyle(.plain).foregroundStyle(.secondary).font(.system(size: 11))
                    }
                    .font(.system(size: 11))
                    .frame(maxWidth: .infinity)
                }
                .padding(32)
                .frame(width: 430)
                .background(Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.25), radius: 40, x: 0, y: 20)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.showPaywall)
        .task { await store.loadProducts() }
    }

    private func dismiss() {
        withAnimation { appState.showPaywall = false }
    }
}

// MARK: - Product Row (real StoreKit product)
struct ProductRow: View {
    let product: Product
    let isSelected: Bool
    var onSelect: () -> Void

    private var badge: String? {
        if product.id == StoreKitManager.yearlyID { return "Best Value" }
        if product.id == StoreKitManager.weeklyID { return "Try It Out" }
        return nil
    }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                radioCircle
                Text(product.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.black)
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(isSelected ? Color.primaryRed : Color.getProOrange)
                        .clipShape(Capsule())
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.primaryRed.opacity(0.06) : Color(red: 0.97, green: 0.97, blue: 0.97)))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primaryRed : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }

    private var radioCircle: some View {
        ZStack {
            Circle().stroke(isSelected ? Color.primaryRed : Color.gray.opacity(0.4), lineWidth: 2).frame(width: 22, height: 22)
            if isSelected { Circle().fill(Color.primaryRed).frame(width: 12, height: 12) }
        }
    }
}

// MARK: - Fallback Row (no StoreKit connection)
struct FallbackPlanRow: View {
    let title: String
    let price: String
    let badge: String?
    let isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                ZStack {
                    Circle().stroke(isSelected ? Color.primaryRed : Color.gray.opacity(0.4), lineWidth: 2).frame(width: 22, height: 22)
                    if isSelected { Circle().fill(Color.primaryRed).frame(width: 12, height: 12) }
                }
                Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(.black)
                if let b = badge {
                    Text(b).font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3).background(Color.primaryRed).clipShape(Capsule())
                }
                Spacer()
                Text(price).font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.primaryRed.opacity(0.06) : Color(red: 0.97, green: 0.97, blue: 0.97)))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primaryRed : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}
