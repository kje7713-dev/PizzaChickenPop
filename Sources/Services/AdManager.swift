import GoogleMobileAds
import UIKit

/// Manages rewarded ad loading and presentation
final class AdManager {
    static let shared = AdManager()

    private var rewardedAd: GADRewardedAd?

    func loadAd() {
        let request = GADRequest()
        GADRewardedAd.load(
            withAdUnitID: "ca-app-pub-3940256099942544/1712485313", // test ID
            request: request
        ) { ad, error in
            if let error = error {
                print("Ad load failed:", error)
                return
            }
            self.rewardedAd = ad
        }
    }

    func showAd(from vc: UIViewController, onReward: @escaping () -> Void) {
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
