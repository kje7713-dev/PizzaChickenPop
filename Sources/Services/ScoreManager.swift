import Foundation

/// Manages best score persistence via UserDefaults
class ScoreManager {
    private let defaults = UserDefaults.standard
    private let bestScoreKey = "bestScore"
    
    var bestScore: Int {
        get { defaults.integer(forKey: bestScoreKey) }
        set {
            defaults.set(newValue, forKey: bestScoreKey)
        }
    }
    
    func checkAndUpdateBestScore(_ score: Int) -> Bool {
        if score > bestScore {
            bestScore = score
            return true
        }
        return false
    }
}
