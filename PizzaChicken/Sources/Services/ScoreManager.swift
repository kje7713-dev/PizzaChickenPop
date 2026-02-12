//
//  ScoreManager.swift
//  PizzaChicken
//
//  Manages local high scores using UserDefaults
//

import Foundation

class ScoreManager {
    
    // MARK: - Properties
    static let shared = ScoreManager()
    
    private let highScoreKey = "highScore"
    private let highScoreDateKey = "highScoreDate"
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - High Score Management
    var highScore: Int {
        get {
            return UserDefaults.standard.integer(forKey: highScoreKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: highScoreKey)
        }
    }
    
    var highScoreDate: Date? {
        get {
            let timestamp = UserDefaults.standard.double(forKey: highScoreDateKey)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: highScoreDateKey)
            } else {
                UserDefaults.standard.removeObject(forKey: highScoreDateKey)
            }
        }
    }
    
    // MARK: - Score Submission
    func submitScore(_ score: Int) {
        // Check if this is a new high score
        if score > highScore {
            highScore = score
            highScoreDate = Date()
            print("New high score! \(score)")
            
            // Submit to Game Center if authenticated
            GameCenterManager.shared.submitScore(score)
        } else {
            print("Score: \(score) (High score: \(highScore))")
        }
    }
    
    func resetHighScore() {
        highScore = 0
        highScoreDate = nil
    }
}
