import GameKit
import UIKit

/// Manages Game Center authentication and leaderboard submission
final class GameCenterManager: NSObject {
    static let shared = GameCenterManager()
    private override init() {}

    private let leaderboardID = "pizza_chicken_highscore"
    private(set) var isAuthenticated = false

    func authenticate() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            if let error = error {
                print("[GameCenter] Authentication error: \(error.localizedDescription)")
                return
            }
            if let vc = viewController {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true)
                }
            } else if localPlayer.isAuthenticated {
                self?.isAuthenticated = true
                print("[GameCenter] Authenticated as \(localPlayer.displayName)")
            } else {
                self?.isAuthenticated = false
                print("[GameCenter] Not authenticated")
            }
        }
    }

    func submitScore(_ score: Int) {
        guard isAuthenticated else {
            print("[GameCenter] Skipping score submission – not authenticated")
            return
        }
        if #available(iOS 14.0, *) {
            // context 0 = default, no per-submission metadata needed
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                      leaderboardIDs: [leaderboardID]) { error in
                if let error = error {
                    print("[GameCenter] Score submission error: \(error.localizedDescription)")
                } else {
                    print("[GameCenter] Score \(score) submitted to leaderboard")
                }
            }
        } else {
            let scoreReporter = GKScore(leaderboardIdentifier: leaderboardID)
            scoreReporter.value = Int64(score)
            GKScore.report([scoreReporter]) { error in
                if let error = error {
                    print("[GameCenter] Score submission error: \(error.localizedDescription)")
                } else {
                    print("[GameCenter] Score \(score) submitted to leaderboard")
                }
            }
        }
    }

    func showLeaderboard() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let gcVC = GKGameCenterViewController(leaderboardID: leaderboardID,
                                              playerScope: .global,
                                              timeScope: .allTime)
        gcVC.gameCenterDelegate = self
        rootVC.present(gcVC, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
