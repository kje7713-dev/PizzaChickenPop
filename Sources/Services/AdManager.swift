import GoogleMobileAds
import UIKit

/// Manages interstitial ad loading and presentation
final class AdManager: NSObject {
    static let shared = AdManager()

    private var interstitialAd: GADInterstitialAd?
    private var didInitialize = false
    private var isLoading = false

    // Deferred show: if showAd is called before the ad is ready, store the view controller
    // and present the ad as soon as it finishes loading.
    private weak var pendingViewController: UIViewController?

    /// Returns true when the value looks like an unfilled placeholder (contains "REPLACE_ME" or is empty).
    private static func isPlaceholder(_ value: String) -> Bool {
        value.isEmpty || value.contains("REPLACE_ME")
    }

    /// AdMob app ID sourced from Info.plist (build-setting key GAD_APPLICATION_IDENTIFIER).
    private var appID: String {
        Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
    }

    /// Interstitial ad unit ID sourced from Info.plist (build-setting key GAD_INTERSTITIAL_AD_UNIT_ID).
    private var adUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "GADInterstitialAdUnitID") as? String ?? ""
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
        guard !isLoading else { return }
        initializeIfNeeded()

        let unitID = adUnitID
        guard !AdManager.isPlaceholder(unitID) else {
            print("AdManager: GADInterstitialAdUnitID is not configured – skipping ad load")
            return
        }

        isLoading = true
        print("AdManager: requesting interstitial ad load")
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: unitID, request: request) { [weak self] ad, error in
            guard let self else { return }
            self.isLoading = false
            if let error = error {
                print("AdManager: interstitial ad failed to load: \(error.localizedDescription)")
                return
            }
            ad?.fullScreenContentDelegate = self
            self.interstitialAd = ad
            print("AdManager: interstitial ad loaded")

            // Present immediately if showAd was called while the ad was still loading.
            if let vc = self.pendingViewController {
                self.pendingViewController = nil
                self.showAd(from: vc)
            }
        }
    }

    func showAd(from vc: UIViewController) {
        guard let ad = interstitialAd else {
            print("AdManager: show requested but ad not ready – scheduling deferred show")
            pendingViewController = vc
            loadAd()
            return
        }

        print("AdManager: presenting interstitial ad")
        ad.present(fromRootViewController: vc)
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdManager: GADFullScreenContentDelegate {
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AdManager: ad failed to present – \(error.localizedDescription)")
        interstitialAd = nil
        loadAd()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("AdManager: ad dismissed – preloading next")
        interstitialAd = nil
        loadAd()
    }
}
