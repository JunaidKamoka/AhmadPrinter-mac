import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var store = StoreKitManager.shared
    @State private var selectedProductID: String = StoreKitManager.yearlyID

    private let featureItems: [(icon: String, text: String)] = [
        ("printer",                   "Print as much as you need"),
        ("pencil.and.list.clipboard", "Create, edit and print all in one place"),
        ("globe",                     "Print documents, image, web page & iCloud files with ease"),
        ("doc.viewfinder",            "Convert scanned documents into printable text"),
        ("rectangle.grid.2x2",        "Choose from a variety of pre designed templates"),
        ("infinity",                  "No Limits"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { if !store.isPurchasing { dismiss() } }

            HStack(spacing: 0) {
                leftPanel
                rightPanel
            }
            .frame(height: 580)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.30), radius: 60, x: 0, y: 24)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: appState.showPaywall)
        .task { await store.loadProducts() }
    }

    // MARK: - Left Panel
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 0) {

            Spacer()

            // Printer illustration — layered circles with colored printer graphic
            ZStack {
                // Subtle outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.84), Color(white: 0.88)],
                            center: .center,
                            startRadius: 60,
                            endRadius: 100
                        )
                    )
                    .frame(width: 190, height: 190)

                // Inner white circle
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 145, height: 145)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)

                // Printer body — multi-part illustration
                VStack(spacing: 0) {
                    // Paper tray top
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.50, green: 0.65, blue: 0.98))
                        .frame(width: 52, height: 8)
                        .offset(y: 4)

                    // Main body
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.42, green: 0.60, blue: 0.98),
                                             Color(red: 0.32, green: 0.48, blue: 0.92)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 72, height: 40)

                        // Paper slot
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 48, height: 3)
                            .offset(y: -6)

                        // Status dots
                        HStack(spacing: 4) {
                            Circle().fill(Color(red: 0.95, green: 0.35, blue: 0.30)).frame(width: 5, height: 5)
                            Circle().fill(Color(red: 0.95, green: 0.70, blue: 0.25)).frame(width: 5, height: 5)
                            Circle().fill(Color(red: 0.30, green: 0.80, blue: 0.45)).frame(width: 5, height: 5)
                        }
                        .offset(y: 8)
                    }

                    // Output tray with paper
                    ZStack(alignment: .top) {
                        // Tray
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.48, green: 0.63, blue: 0.96).opacity(0.6))
                            .frame(width: 64, height: 12)

                        // Paper coming out
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: 46, height: 30)
                                .shadow(color: Color.black.opacity(0.08), radius: 3, y: 2)
                                .overlay(
                                    VStack(spacing: 3) {
                                        ForEach(0..<3, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(Color(white: 0.82))
                                                .frame(width: 30, height: 2)
                                        }
                                    }
                                )
                        }
                        .offset(y: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(height: 32)

            // Feature list
            VStack(alignment: .leading, spacing: 16) {
                ForEach(featureItems, id: \.text) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primaryRed)
                            .frame(width: 18, alignment: .center)
                            .padding(.top, 1)
                        Text(item.text)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(white: 0.20))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .frame(width: 370)
        .background(Color(red: 0.955, green: 0.955, blue: 0.965))
    }

    // MARK: - Right Panel
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Headline
            (Text("Unlimited Access to all\n").font(.system(size: 28, weight: .bold)) +
             Text("Features").font(.system(size: 28, weight: .bold)))
                .foregroundStyle(.black)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 10)

            Text("Unlock the full power of Premium — print smarter, faster, and without limits!")
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.46))
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: 24)

            // Plans
            if store.isLoading {
                HStack { Spacer(); ProgressView("Loading plans...").tint(Color.primaryRed); Spacer() }
                    .frame(height: 180)
            } else if store.products.isEmpty {
                VStack(spacing: 10) {
                    PaywallPlanRow(
                        title: "Monthly Subscription", price: "$9.99",
                        subtitle: nil, badge: nil,
                        isSelected: selectedProductID == StoreKitManager.monthlyID
                    ) { selectedProductID = StoreKitManager.monthlyID }

                    PaywallPlanRow(
                        title: "Yearly Subscription", price: "$29.99",
                        subtitle: nil, badge: "3-Days Free trial",
                        isSelected: selectedProductID == StoreKitManager.yearlyID
                    ) { selectedProductID = StoreKitManager.yearlyID }

                    PaywallPlanRow(
                        title: "One-Time Purchase", price: "$59.99",
                        subtitle: nil, badge: nil,
                        isSelected: selectedProductID == StoreKitManager.weeklyID
                    ) { selectedProductID = StoreKitManager.weeklyID }
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

            Spacer().frame(height: 20)

            // Guarantee row
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.16, green: 0.72, blue: 0.44))
                (Text("No Commitment, ").fontWeight(.bold).foregroundColor(.black) +
                 Text("Cancel Anytime").foregroundColor(Color(white: 0.46)))
                    .font(.system(size: 13))
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer().frame(height: 20)

            // Error
            if let err = store.purchaseError {
                Text(err)
                    .font(.system(size: 12)).foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }

            // CTA Button
            Button {
                Task {
                    if let product = store.product(for: selectedProductID) {
                        await store.purchase(product)
                        if store.isPro { dismiss() }
                    }
                }
            } label: {
                ZStack {
                    if store.isPurchasing {
                        ProgressView().controlSize(.regular).tint(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                    } else {
                        HStack {
                            Text(ctaLabel)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity).frame(height: 54)
                    }
                }
                .background(
                    store.isPurchasing
                        ? AnyShapeStyle(Color.gray.opacity(0.5))
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.primaryRed, Color(red: 0.75, green: 0.18, blue: 0.18)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.primaryRed.opacity(store.isPurchasing ? 0 : 0.30), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing)

            Spacer().frame(height: 18)

            // Footer links
            HStack(spacing: 0) {
                Spacer()
                footerBtn("Terms & Condition") {
                    NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/internet-services/itunes/")!)
                }
                footerSep
                footerBtn("Restore") {
                    Task { await store.restorePurchases(); if store.isPro { dismiss() } }
                }
                footerSep
                footerBtn("Privacy Policy") {
                    NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/privacy/")!)
                }
                footerSep
                footerBtn("Try free version") { dismiss() }
                Spacer()
            }
        }
        .padding(32)
        .frame(width: 400)
        .background(Color.white)
    }

    private var footerSep: some View {
        Text("|")
            .font(.system(size: 11))
            .foregroundStyle(Color(white: 0.75))
            .padding(.horizontal, 6)
    }

    private func footerBtn(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(Color(white: 0.52))
    }

    /// Dynamic CTA label based on selected product's trial info
    private var ctaLabel: String {
        if let product = store.product(for: selectedProductID),
           let sub = product.subscription,
           let intro = sub.introductoryOffer,
           intro.paymentMode == .freeTrial {
            let days = intro.period.value
            let unit = intro.period.unit == .day ? (days == 1 ? "Day" : "Days")
                     : intro.period.unit == .week ? (days == 1 ? "Week" : "Weeks")
                     : intro.period.unit == .month ? (days == 1 ? "Month" : "Months")
                     : "Year"
            return "Start \(days)-\(unit) Free Trial"
        }
        if let product = store.product(for: selectedProductID) {
            return "Subscribe — \(product.displayPrice)"
        }
        return "Continue For Free"
    }

    private func dismiss() {
        withAnimation { appState.showPaywall = false }
    }
}

// MARK: - Paywall Plan Row (fallback / no StoreKit)
private struct PaywallPlanRow: View {
    let title: String
    let price: String
    let subtitle: String?
    let badge: String?
    let isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Radio / checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.primaryRed : Color(white: 0.82), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Circle()
                            .fill(Color.primaryRed)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(0.3)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.primaryRed)
                                .clipShape(Capsule())
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(price)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.primaryRed.opacity(0.04) : Color(white: 0.98))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.primaryRed.opacity(0.55) : Color(white: 0.91), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Product Row (real StoreKit)
struct ProductRow: View {
    let product: Product
    let isSelected: Bool
    var onSelect: () -> Void

    private var badge: String? {
        if product.id == StoreKitManager.yearlyID { return "3-Days Free trial" }
        return nil
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.primaryRed : Color(white: 0.82), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Circle()
                            .fill(Color.primaryRed)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(0.3)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.primaryRed)
                                .clipShape(Capsule())
                        }
                    }
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.primaryRed.opacity(0.04) : Color(white: 0.98))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.primaryRed.opacity(0.55) : Color(white: 0.91), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}
