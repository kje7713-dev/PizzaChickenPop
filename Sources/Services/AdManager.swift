import GoogleMobileAds
import UIKit

/// Manages rewarded ad loading and presentation
final class AdManager: NSObject {
    static let shared = AdManager()

    private var rewardedAd: GADRewardedAd?
    private var didInitialize = false
    private var isLoading = false

    // Deferred show: if showAd is called before the ad is ready, store the context
    // and present the ad as soon as it finishes loading.
    private weak var pendingViewController: UIViewController?
    private var pendingRewardCallback: (() -> Void)?

    /// Returns true when the value looks like an unfilled placeholder (contains "REPLACE_ME" or is empty).
    private static func isPlaceholder(_ value: String) -> Bool {
        value.isEmpty || value.contains("REPLACE_ME")
    }

    /// AdMob app ID sourced from Info.plist (build-setting key GAD_APPLICATION_IDENTIFIER).
    private var appID: String {
        Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
    }

    /// Rewarded ad unit ID sourced from Info.plist (build-setting key GADRewardedAdUnitID).
    private var adUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "GADRewardedAdUnitID") as? String ?? ""
    }

    func initializeIfNeeded() {
        guard !didInitialize else { return }
        didInitialize = true
        guard !AdManager.isPlaceholder(appID) else {
            print("AdManager: GADApplicationIdentifier is not configured – skipping SDK init")
            return
        }
        GADMobileAds.sharedInstance().start { _ in
            print("AdManager: SDK initialized")
        }
    }

    func loadAd() {
        guard !IAPManager.shared.adsRemoved else { return }
        guard !isLoading else { return }
        initializeIfNeeded()

        let unitID = adUnitID
        guard !AdManager.isPlaceholder(unitID) else {
            print("AdManager: GADRewardedAdUnitID is not configured – skipping ad load")
            return
        }

        isLoading = true
        print("AdManager: requesting rewarded ad load")
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: unitID, request: request) { [weak self] ad, error in
            guard let self else { return }
            self.isLoading = false
            if let error = error {
                print("AdManager: rewarded ad failed to load: \(error.localizedDescription)")
                return
            }
            ad?.fullScreenContentDelegate = self
            self.rewardedAd = ad
            print("AdManager: rewarded ad loaded")

            // Present immediately if showAd was called while the ad was still loading.
            if let vc = self.pendingViewController, let cb = self.pendingRewardCallback {
                self.pendingViewController = nil
                self.pendingRewardCallback = nil
                self.showAd(from: vc, onReward: cb)
            }
        }
    }

    func showAd(from vc: UIViewController, onReward: @escaping () -> Void) {
        guard !IAPManager.shared.adsRemoved else { return }
        guard let ad = rewardedAd else {
            print("AdManager: show requested but ad not ready - scheduling deferred show")
            pendingViewController = vc
            pendingRewardCallback = onReward
            loadAd()
            return
        }

        print("AdManager: presenting rewarded ad")
        ad.present(fromRootViewController: vc) {
            print("AdManager: user earned reward")
            onReward()
        }
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdManager: GADFullScreenContentDelegate {
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("AdManager: ad presented full screen content")
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AdManager: ad failed to present – \(error.localizedDescription)")
        rewardedAd = nil
        loadAd()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("AdManager: ad dismissed – preloading next")
        rewardedAd = nil
        loadAd()
    }
}
