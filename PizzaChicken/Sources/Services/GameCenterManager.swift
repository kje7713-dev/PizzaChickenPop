//
//  GameCenterManager.swift
//  PizzaChicken
//
//  Manages Game Center authentication and leaderboard submissions
//

import Foundation
import GameKit

class GameCenterManager: NSObject {
    
    // MARK: - Properties
    static let shared = GameCenterManager()
    
    // Leaderboard ID (must match App Store Connect configuration)
    private let leaderboardID = "pizza_chicken_highscore"
    
    private(set) var isAuthenticated = false
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Authentication
    func authenticatePlayer(completion: @escaping (Bool) -> Void) {
        guard GKLocalPlayer.local.isAuthenticated == false else {
            isAuthenticated = true
            completion(true)
            return
        }
        
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let error = error {
                print("Game Center authentication error: \(error.localizedDescription)")
                self.isAuthenticated = false
                completion(false)
                return
            }
            
            if let viewController = viewController {
                // Present authentication view controller
                // Note: In a real app, this would be presented from the root view controller
                print("Game Center requires authentication UI")
                completion(false)
                return
            }
            
            if GKLocalPlayer.local.isAuthenticated {
                print("Game Center authenticated successfully")
                self.isAuthenticated = true
                completion(true)
            } else {
                print("Game Center authentication failed")
                self.isAuthenticated = false
                completion(false)
            }
        }
    }
    
    // MARK: - Score Submission
    func submitScore(_ score: Int) {
        guard isAuthenticated else {
            print("Cannot submit score: Not authenticated with Game Center")
            return
        }
        
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Error submitting score to Game Center: \(error.localizedDescription)")
            } else {
                print("Score submitted to Game Center: \(score)")
            }
        }
    }
    
    // MARK: - Leaderboard Display
    func showLeaderboard(from viewController: UIViewController) {
        guard isAuthenticated else {
            print("Cannot show leaderboard: Not authenticated with Game Center")
            return
        }
        
        let gameCenterVC = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        gameCenterVC.gameCenterDelegate = self
        viewController.present(gameCenterVC, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
