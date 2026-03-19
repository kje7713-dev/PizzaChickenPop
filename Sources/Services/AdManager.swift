import GoogleMobileAds
import UIKit

/// Manages rewarded ad loading and presentation
final class AdManager {
    static let shared = AdManager()

    private var rewardedAd: GADRewardedAd?
    private var didInitialize = false

    /// Rewarded ad unit ID sourced from Info.plist (build-setting key GADRewardedAdUnitID).
    private var adUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "GADRewardedAdUnitID") as? String ?? ""
    }

    func initializeIfNeeded() {
        guard !didInitialize else { return }
        didInitialize = true
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    func loadAd() {
        guard !IAPManager.shared.adsRemoved else { return }
        initializeIfNeeded()

        let unitID = adUnitID
        guard !unitID.isEmpty else {
            print("AdManager: GADRewardedAdUnitID is not configured in Info.plist")
            return
        }

        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: unitID, request: request) { ad, error in
            if let error = error {
                print("Ad load failed:", error)
                return
            }
            self.rewardedAd = ad
        }
    }

    func showAd(from vc: UIViewController, onReward: @escaping () -> Void) {
        guard !IAPManager.shared.adsRemoved else { return }
        guard let ad = rewardedAd else {
            print("Ad not ready")
            return
        }

        ad.present(fromRootViewController: vc) {
            print("User earned reward")
            onReward()
        }

        rewardedAd = nil
        loadAd()
    }
}
