import SpriteKit

/// HUD displaying Score, Time, Best score, Level, and Lives
class HUDNode: SKNode {
    
    private let scoreLabel: SKLabelNode
    private let timeLabel: SKLabelNode
    private let bestLabel: SKLabelNode
    private let runScoreLabel: SKLabelNode
    private let levelLabel: SKLabelNode
    private let livesLabel: SKLabelNode
    
    private let margin: CGFloat = 20
    
    init(size: CGSize) {
        // Score label (top-left)
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .black
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: margin, y: size.height - margin)
        scoreLabel.text = "Score: 0"
        scoreLabel.zPosition = 100
        
        // Time label (top-right)
        timeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        timeLabel.fontSize = 24
        timeLabel.fontColor = .black
        timeLabel.horizontalAlignmentMode = .right
        timeLabel.verticalAlignmentMode = .top
        timeLabel.position = CGPoint(x: size.width - margin, y: size.height - margin)
        timeLabel.text = "Time: 30"
        timeLabel.zPosition = 100
        
        // Best label (below score, top-left)
        bestLabel = SKLabelNode(fontNamed: "Helvetica")
        bestLabel.fontSize = 18
        bestLabel.fontColor = .darkGray
        bestLabel.horizontalAlignmentMode = .left
        bestLabel.verticalAlignmentMode = .top
        bestLabel.position = CGPoint(x: margin, y: size.height - margin - 30)
        bestLabel.text = "Best: 0"
        bestLabel.zPosition = 100
        
        // Run score label (below best, top-left)
        runScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        runScoreLabel.fontSize = 18
        runScoreLabel.fontColor = SKColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        runScoreLabel.horizontalAlignmentMode = .left
        runScoreLabel.verticalAlignmentMode = .top
        runScoreLabel.position = CGPoint(x: margin, y: size.height - margin - 55)
        runScoreLabel.text = "Run: 0"
        runScoreLabel.zPosition = 100
        
        // Level label (center-top)
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel.fontSize = 28
        levelLabel.fontColor = .black
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.verticalAlignmentMode = .top
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - margin)
        levelLabel.text = "Level 1"
        levelLabel.zPosition = 100
        
        // Lives label (top-right, below time)
        livesLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        livesLabel.fontSize = 20
        livesLabel.fontColor = .black
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.verticalAlignmentMode = .top
        livesLabel.position = CGPoint(x: size.width - margin, y: size.height - margin - 30)
        livesLabel.text = "Lives: 3"
        livesLabel.zPosition = 100
        
        super.init()
        
        addChild(scoreLabel)
        addChild(timeLabel)
        addChild(bestLabel)
        addChild(runScoreLabel)
        addChild(levelLabel)
        addChild(livesLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateScore(_ score: Int) {
        scoreLabel.text = "Score: \(score)"
    }
    
    func updateTime(_ timeRemaining: Int) {
        timeLabel.text = "Time: \(timeRemaining)"
    }
    
    func updateBest(_ best: Int) {
        bestLabel.text = "Best: \(best)"
    }
    
    func updateRunScore(_ runScore: Int) {
        runScoreLabel.text = "Run: \(runScore)"
    }
    
    func updateLevel(_ level: Int) {
        levelLabel.text = "Level \(level)"
    }
    
    func updateLevelText(_ text: String) {
        levelLabel.text = text
    }
    
    func updateLives(_ livesRemaining: Int) {
        livesLabel.text = "Lives: \(livesRemaining)"
    }
    
    func repositionForSize(_ size: CGSize) {
        scoreLabel.position = CGPoint(x: margin, y: size.height - margin)
        timeLabel.position = CGPoint(x: size.width - margin, y: size.height - margin)
        bestLabel.position = CGPoint(x: margin, y: size.height - margin - 30)
        runScoreLabel.position = CGPoint(x: margin, y: size.height - margin - 55)
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - margin)
        livesLabel.position = CGPoint(x: size.width - margin, y: size.height - margin - 30)
    }
}
