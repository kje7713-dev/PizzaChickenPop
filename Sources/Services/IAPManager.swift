import StoreKit

extension Notification.Name {
    /// Posted on the main thread whenever `IAPManager.shared.adsRemoved` changes.
    static let iapStateDidChange = Notification.Name("iapStateDidChange")
}

/// Manages the "Remove Ads" in-app purchase
final class IAPManager: NSObject {
    static let shared = IAPManager()

    private let productID = "com.sbd.pizzachicken.removeads"
    private let userDefaultsKey = "adsRemoved"

    /// Whether ads have been removed. Backed by a cached UserDefaults value for
    /// quick reads, but the authoritative source is StoreKit entitlements.
    private(set) var adsRemoved: Bool = false {
        didSet {
            guard adsRemoved != oldValue else { return }
            UserDefaults.standard.set(adsRemoved, forKey: userDefaultsKey)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .iapStateDidChange, object: nil)
            }
        }
    }

    private override init() {
        // Seed from cache so the value is available before the async refresh finishes.
        self.adsRemoved = UserDefaults.standard.bool(forKey: userDefaultsKey)
        super.init()
    }

    // MARK: - Entitlement Refresh

    /// Re-checks StoreKit verified entitlements and updates `adsRemoved`.
    /// Safe to call from any context; notification is always posted on main thread.
    func refreshPurchasedState() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                hasEntitlement = true
                break
            }
        }
        adsRemoved = hasEntitlement
    }

    // MARK: - Purchase

    func purchaseRemoveAds() {
        Task {
            do {
                let products = try await Product.products(for: [productID])
                guard let product = products.first else { return }

                let result = try await product.purchase()

                switch result {
                case .success(let verificationResult):
                    if case .verified(let transaction) = verificationResult {
                        await transaction.finish()
                    }
                case .userCancelled, .pending:
                    break
                @unknown default:
                    break
                }
            } catch {
                print("Purchase failed:", error)
            }
            // Always re-derive state from entitlements after purchase attempt.
            await refreshPurchasedState()
        }
    }

    // MARK: - Restore

    /// Syncs with the App Store and re-checks entitlements.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print("AppStore.sync failed:", error)
        }
        await refreshPurchasedState()
    }
}
