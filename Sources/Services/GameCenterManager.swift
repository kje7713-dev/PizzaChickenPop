import Foundation
import GameKit
import UIKit

/// Manages Game Center authentication and leaderboard submission
final class GameCenterManager: NSObject {
    static let shared = GameCenterManager()
    private override init() {}

    private let leaderboardID = "pizza_chicken_highscore"
    private(set) var isAuthenticated = false
    private(set) var lastSubmissionSucceeded = false
    private(set) var lastSubmissionMessage = "Game Center not checked yet"

    func authenticate(from viewController: UIViewController?) {
        let localPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = { [weak self] gcVC, error in
            guard let self = self else { return }

            if let gcVC = gcVC {
                print("Presenting Game Center login UI")

                viewController?.present(gcVC, animated: true)

                self.lastSubmissionMessage = "Signing into Game Center..."
                return
            }

            if let error = error {
                print("Game Center auth error:", error.localizedDescription)
                self.isAuthenticated = false
                self.lastSubmissionMessage = "Game Center unavailable"
                return
            }

            self.isAuthenticated = localPlayer.isAuthenticated

            if self.isAuthenticated {
                self.lastSubmissionMessage = "Game Center connected"
            } else {
                self.lastSubmissionMessage = "Game Center not connected"
            }

            print("Game Center authenticated:", self.isAuthenticated)
        }
    }

    func submitScore(_ score: Int) {
        guard isAuthenticated else {
            lastSubmissionSucceeded = false
            lastSubmissionMessage = "Score not submitted: Game Center not connected"
            print("[GameCenter] Skipping score submission – not authenticated")
            return
        }
        if #available(iOS 14.0, *) {
            // context 0 = default, no per-submission metadata needed
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                      leaderboardIDs: [leaderboardID]) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.lastSubmissionSucceeded = false
                        self?.lastSubmissionMessage = "Score submission failed"
                        print("[GameCenter] Score submission error: \(error.localizedDescription)")
                    } else {
                        self?.lastSubmissionSucceeded = true
                        self?.lastSubmissionMessage = "Score submitted"
                        print("[GameCenter] Score \(score) submitted to leaderboard")
                    }
                }
            }
        } else {
            let scoreReporter = GKScore(leaderboardIdentifier: leaderboardID)
            scoreReporter.value = Int64(score)
            GKScore.report([scoreReporter]) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.lastSubmissionSucceeded = false
                        self?.lastSubmissionMessage = "Score submission failed"
                        print("[GameCenter] Score submission error: \(error.localizedDescription)")
                    } else {
                        self?.lastSubmissionSucceeded = true
                        self?.lastSubmissionMessage = "Score submitted"
                        print("[GameCenter] Score \(score) submitted to leaderboard")
                    }
                }
            }
        }
    }

    func showLeaderboard(from viewController: UIViewController) {
        guard isAuthenticated else {
            lastSubmissionMessage = "Cannot open leaderboard: Game Center not connected"
            print("[GameCenter] Cannot show leaderboard – not authenticated")
            return
        }
        let gcVC = GKGameCenterViewController(leaderboardID: leaderboardID,
                                              playerScope: .global,
                                              timeScope: .allTime)
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
