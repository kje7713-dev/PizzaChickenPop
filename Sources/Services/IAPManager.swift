import StoreKit

/// Manages the "Remove Ads" in-app purchase
final class IAPManager: NSObject {
    static let shared = IAPManager()

    private let productID = "com.sbd.pizzachicken.removeads"

    var adsRemoved: Bool {
        UserDefaults.standard.bool(forKey: "adsRemoved")
    }

    func purchaseRemoveAds() {
        Task {
            do {
                let products = try await Product.products(for: [productID])
                guard let product = products.first else { return }

                let result = try await product.purchase()

                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .verified(let transaction):
                        UserDefaults.standard.set(true, forKey: "adsRemoved")
                        await transaction.finish()
                    case .unverified:
                        print("Purchase unverified")
                    }
                case .userCancelled:
                    break
                case .pending:
                    break
                @unknown default:
                    break
                }
            } catch {
                print("Purchase failed:", error)
            }
        }
    }
}
