import StoreKit

// MARK: - Purchase Status

/// Represents the current state of an in-app purchase or restore operation.
enum PurchaseStatus {
    case idle
    case loading(String)
    case success(String)
    case failure(String)
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted on the main thread whenever `IAPManager.shared.adsRemoved` changes.
    static let iapStateDidChange = Notification.Name("iapStateDidChange")
    /// Posted on the main thread whenever `IAPManager.shared.purchaseStatus` changes.
    static let iapPurchaseStatusDidChange = Notification.Name("iapPurchaseStatusDidChange")
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

    /// Current purchase/restore operation status. Always updated on the main thread.
    private(set) var purchaseStatus: PurchaseStatus = .idle {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .iapPurchaseStatusDidChange, object: nil)
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
            await MainActor.run { purchaseStatus = .loading("Connecting to App Store…") }
            do {
                let products = try await Product.products(for: [productID])
                guard let product = products.first else {
                    await MainActor.run {
                        purchaseStatus = .failure("Purchase unavailable. Please try again.")
                    }
                    return
                }

                let result = try await product.purchase()

                switch result {
                case .success(let verificationResult):
                    if case .verified(let transaction) = verificationResult {
                        await transaction.finish()
                    }
                    await refreshPurchasedState()
                    await MainActor.run {
                        purchaseStatus = adsRemoved ? .success("Ads removed. Thank you!") : .failure("Purchase could not be verified.")
                    }
                case .userCancelled:
                    await MainActor.run { purchaseStatus = .idle }
                    return
                case .pending:
                    await MainActor.run { purchaseStatus = .failure("Purchase is pending approval.") }
                    return
                @unknown default:
                    await MainActor.run { purchaseStatus = .idle }
                    return
                }
            } catch {
                await MainActor.run {
                    purchaseStatus = .failure("Purchase failed. Please try again.")
                }
            }
        }
    }

    // MARK: - Restore

    /// Syncs with the App Store and re-checks entitlements.
    func restorePurchases() async {
        await MainActor.run { purchaseStatus = .loading("Restoring purchases…") }
        do {
            try await AppStore.sync()
        } catch {
            await MainActor.run {
                purchaseStatus = .failure("Restore failed. Please try again.")
            }
            return
        }
        await refreshPurchasedState()
        await MainActor.run {
            purchaseStatus = adsRemoved ? .success("Purchases restored.") : .failure("No purchases found to restore.")
        }
    }
}
