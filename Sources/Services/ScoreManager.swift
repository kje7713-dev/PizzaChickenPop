import Foundation

/// Manages local high scores and date recording
class ScoreManager {
    private let defaults = UserDefaults.standard
    private let highScoreKey = "highScore"
    private let highScoreDateKey = "highScoreDate"
    
    var highScore: Int {
        get { defaults.integer(forKey: highScoreKey) }
        set {
            defaults.set(newValue, forKey: highScoreKey)
            defaults.set(Date().timeIntervalSince1970, forKey: highScoreDateKey)
        }
    }
    
    var highScoreDate: Date? {
        let timestamp = defaults.double(forKey: highScoreDateKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    func checkAndUpdateHighScore(_ score: Int) -> Bool {
        if score > highScore {
            highScore = score
            return true
        }
        return false
    }
}
