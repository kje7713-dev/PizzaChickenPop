import Foundation
import GameKit
import UIKit

/// Posted on the main queue whenever Game Center auth or visible status changes.
extension Notification.Name {
    static let gameCenterAuthDidChange = Notification.Name("GameCenterAuthDidChange")
}

/// Manages Game Center authentication and leaderboard submission
final class GameCenterManager: NSObject {
    static let shared = GameCenterManager()
    private override init() {}

    private let leaderboardID = "ABC123"
    private(set) var isAuthenticated = false
    private(set) var playerDisplayName: String?
    private(set) var lastSubmissionSucceeded = false
    private(set) var lastSubmissionMessage = "Game Center auth not started"

    /// Prevents re-registering the authenticate handler on every call unless a
    /// manual reconnect is explicitly requested.
    private var hasConfiguredAuthenticateHandler = false

    // MARK: - Authentication

    private func postStateChangeNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .gameCenterAuthDidChange, object: nil)
        }
    }

    func authenticate(from viewController: UIViewController?) {
        print("[GameCenter] authenticate() called – hasConfiguredHandler=\(hasConfiguredAuthenticateHandler)")
        guard !hasConfiguredAuthenticateHandler else {
            print("[GameCenter] authenticate() skipped – handler already configured")
            return
        }
        hasConfiguredAuthenticateHandler = true
        lastSubmissionMessage = "Game Center sign-in required"
        postStateChangeNotification()

        let localPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = { [weak self] gcVC, error in
            guard let self = self else { return }

            if let gcVC = gcVC {
                print("[GameCenter] Sign-in UI returned – attempting to present")
                self.lastSubmissionMessage = "Presenting Game Center sign-in"
                self.postStateChangeNotification()
                if let vc = viewController {
                    vc.present(gcVC, animated: true)
                    print("[GameCenter] Sign-in UI presented")
                } else {
                    print("[GameCenter] Sign-in UI returned but viewController is nil – cannot present")
                    self.isAuthenticated = false
                    self.playerDisplayName = nil
                    self.lastSubmissionMessage = "Game Center sign-in incomplete"
                    self.postStateChangeNotification()
                }
                return
            }

            if let error = error {
                print("[GameCenter] Auth error: \(error.localizedDescription)")
                self.isAuthenticated = false
                self.playerDisplayName = nil
                self.lastSubmissionMessage = "Game Center unavailable"
                self.postStateChangeNotification()
                return
            }

            let authenticated = localPlayer.isAuthenticated
            print("[GameCenter] localPlayer.isAuthenticated=\(authenticated)")
            self.isAuthenticated = authenticated

            if authenticated {
                self.playerDisplayName = localPlayer.displayName
                self.lastSubmissionMessage = "Game Center connected"
                print("[GameCenter] Auth succeeded – player: \(localPlayer.displayName)")
            } else {
                self.playerDisplayName = nil
                self.lastSubmissionMessage = "Game Center sign-in incomplete"
                print("[GameCenter] Auth callback completed but player is not authenticated")
            }

            self.postStateChangeNotification()
        }
    }

    /// Resets the handler guard and re-runs authentication so the user can
    /// manually trigger the Game Center sign-in UI from the home or game-over screen.
    func forceReconnect(from viewController: UIViewController?) {
        print("[GameCenter] forceReconnect() called – resetting handler flag")
        hasConfiguredAuthenticateHandler = false
        lastSubmissionMessage = "Game Center sign-in required"
        postStateChangeNotification()
        authenticate(from: viewController)
    }

    // MARK: - Score Submission

    func submitScore(_ score: Int) {
        print("[GameCenter] submitScore(\(score)) called – isAuthenticated=\(isAuthenticated)")
        guard isAuthenticated else {
            lastSubmissionSucceeded = false
            lastSubmissionMessage = "Score not submitted: Game Center not connected"
            print("[GameCenter] Skipping score submission – not authenticated")
            postStateChangeNotification()
            return
        }
        print("[GameCenter] Submitting score \(score) to leaderboard '\(leaderboardID)'")
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
                        print("[GameCenter] Score \(score) submitted successfully")
                    }
                    self?.postStateChangeNotification()
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
                        print("[GameCenter] Score \(score) submitted successfully (legacy)")
                    }
                    self?.postStateChangeNotification()
                }
            }
        }
    }

    // MARK: - Leaderboard Presentation

    func showLeaderboard(from viewController: UIViewController) {
        print("[GameCenter] showLeaderboard() called – isAuthenticated=\(isAuthenticated)")
        guard isAuthenticated else {
            lastSubmissionMessage = "Cannot open leaderboard: Game Center not connected"
            print("[GameCenter] Cannot show leaderboard – not authenticated")
            postStateChangeNotification()
            return
        }
        print("[GameCenter] Presenting leaderboard UI")
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
