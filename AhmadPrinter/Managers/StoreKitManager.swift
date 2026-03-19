import StoreKit
import SwiftUI

@MainActor
final class StoreKitManager: ObservableObject {

    static let shared = StoreKitManager()

    // MARK: - Product IDs
    static let weeklyID  = "printer.ahmad.weekly"
    static let monthlyID = "printer.ahmad.monthly"
    static let yearlyID  = "printer.ahmad.yearly"

    static let allIDs: [String] = [weeklyID, monthlyID, yearlyID]

    // MARK: - Published State
    @Published var products: [Product] = []
    @Published var purchasedIDs: Set<String> = []
    @Published var isLoading = false
    @Published var purchaseError: String? = nil
    @Published var isPurchasing = false

    var isPro: Bool { !purchasedIDs.isEmpty }

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshPurchasedStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        purchaseError = nil
        do {
            let fetched = try await Product.products(for: Self.allIDs)
            // Sort: weekly, monthly, yearly
            products = fetched.sorted { a, b in
                let order: [String] = [Self.weeklyID, Self.monthlyID, Self.yearlyID]
                let ai = order.firstIndex(of: a.id) ?? 99
                let bi = order.firstIndex(of: b.id) ?? 99
                return ai < bi
            }
        } catch {
            purchaseError = "Could not load plans: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshPurchasedStatus()
                case .unverified(_, let error):
                    purchaseError = "Verification failed: \(error.localizedDescription)"
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    // MARK: - Restore
    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        do {
            try await AppStore.sync()
            await refreshPurchasedStatus()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    // MARK: - Refresh Status
    func refreshPurchasedStatus() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.revocationDate == nil {
                active.insert(tx.productID)
            }
        }
        purchasedIDs = active
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let tx) = result else { continue }
                await tx.finish()
                await self?.refreshPurchasedStatus()
            }
        }
    }

    // MARK: - Helpers
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    var weeklyProduct:  Product? { product(for: Self.weeklyID) }
    var monthlyProduct: Product? { product(for: Self.monthlyID) }
    var yearlyProduct:  Product? { product(for: Self.yearlyID) }
}
