import SwiftUI
import StoreKit

@MainActor
@Observable
class StoreManager {
    // MARK: - Product IDs
    static let monthlyID = "fudai.subscription.monthly"
    static let yearlyID = "fudai.subscription.yearly"

    private static let allProductIDs: Set<String> = [monthlyID, yearlyID]

    // MARK: - StoreKit State
    var products: [Product] = []
    var isSubscribed = false {
        didSet { AIAccessSettings.setActivePlusEntitlement(isSubscribed) }
    }
    var currentSubscriptionProductID: String?

    // MARK: - Scan Tracking (UserDefaults-backed)
    var freeScansUsed: Int {
        didSet { UserDefaults.standard.set(freeScansUsed, forKey: "freeScansUsed") }
    }
    var dailyScansUsed: Int {
        didSet { UserDefaults.standard.set(dailyScansUsed, forKey: "dailyScansUsed") }
    }
    var lastScanDate: Date? {
        didSet { UserDefaults.standard.set(lastScanDate, forKey: "lastScanDate") }
    }

    // MARK: - Loading / Error
    var hasCheckedEntitlements = false
    var isPurchasing = false
    var purchaseError: String?

    // MARK: - Transaction listener
    private var transactionListener: Task<Void, Never>?

    // MARK: - Computed
    var canScan: Bool {
        if isSubscribed {
            resetDailyCounterIfNeeded()
            return dailyScansUsed < AIAccessSettings.paidFoodDailyRequestLimit
        }
        return freeScansUsed < 4
    }

    var canUseApp: Bool {
        return isSubscribed || freeScansUsed < 4
    }

    var remainingScans: Int {
        if isSubscribed {
            resetDailyCounterIfNeeded()
            return max(0, AIAccessSettings.paidFoodDailyRequestLimit - dailyScansUsed)
        }
        return max(0, 3 - freeScansUsed)
    }

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyID }
    }

    var currentPlanName: String {
        guard let id = currentSubscriptionProductID else { return "Free" }
        switch id {
        case Self.monthlyID: return "Monthly"
        case Self.yearlyID: return "Yearly"
        default: return "Premium"
        }
    }

    // MARK: - Init
    init() {
        freeScansUsed = UserDefaults.standard.integer(forKey: "freeScansUsed")
        dailyScansUsed = UserDefaults.standard.integer(forKey: "dailyScansUsed")
        lastScanDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date

        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }

    // MARK: - Load Products
    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.allProductIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = extractTransaction(verification)
                let purchasedPlusSubscription = isActivePlusTransaction(transaction)
                if purchasedPlusSubscription {
                    applySubscriptionState(isSubscribed: true, productID: transaction.productID)
                }
                await transaction.finish()
                await checkEntitlements(fallbackActiveProductID: purchasedPlusSubscription ? transaction.productID : nil)
                return purchasedPlusSubscription || isSubscribed
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        return false
    }

    // MARK: - Restore
    @discardableResult
    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await checkEntitlements()
            return isSubscribed
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Entitlements
    func checkEntitlements(fallbackActiveProductID: String? = nil) async {
        var subscribed = false
        var activeProductID: String?

        for await result in Transaction.currentEntitlements {
            let transaction = extractTransaction(result)
            if isActivePlusTransaction(transaction) {
                subscribed = true
                activeProductID = transaction.productID
            }
        }

        if !subscribed, let fallbackActiveProductID {
            subscribed = true
            activeProductID = fallbackActiveProductID
        }

        applySubscriptionState(isSubscribed: subscribed, productID: activeProductID)
        hasCheckedEntitlements = true
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                let transaction = self.extractTransaction(result)
                if self.isActivePlusTransaction(transaction) {
                    self.applySubscriptionState(isSubscribed: true, productID: transaction.productID)
                }
                await transaction.finish()
                await self.checkEntitlements()
            }
        }
    }

    // MARK: - Verification
    nonisolated private func extractTransaction<T>(_ result: VerificationResult<T>) -> T {
        switch result {
        case .unverified(let payload, _):
            return payload
        case .verified(let safe):
            return safe
        }
    }

    private func isActivePlusTransaction(_ transaction: StoreKit.Transaction) -> Bool {
        guard Self.allProductIDs.contains(transaction.productID),
              transaction.productType == .autoRenewable,
              transaction.revocationDate == nil else {
            return false
        }

        if let expirationDate = transaction.expirationDate {
            return expirationDate > .now
        }

        return true
    }

    private func applySubscriptionState(isSubscribed subscribed: Bool, productID: String?) {
        isSubscribed = subscribed
        currentSubscriptionProductID = productID
    }

    // MARK: - Scan Recording
    func recordScan() {
        if isSubscribed {
            resetDailyCounterIfNeeded()
            dailyScansUsed += 1
        } else {
            freeScansUsed += 1
        }
    }

    func resetDailyCounterIfNeeded() {
        guard let lastDate = lastScanDate else {
            lastScanDate = .now
            return
        }
        if !Calendar.current.isDateInToday(lastDate) {
            dailyScansUsed = 0
            lastScanDate = .now
        }
    }
}
