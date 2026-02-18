import SpriteKit

/// HUD displaying Score, Time, Best score, and Level
class HUDNode: SKNode {
    
    private let scoreLabel: SKLabelNode
    private let timeLabel: SKLabelNode
    private let bestLabel: SKLabelNode
    private let levelLabel: SKLabelNode
    
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
        
        // Level label (center-top)
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel.fontSize = 28
        levelLabel.fontColor = .black
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.verticalAlignmentMode = .top
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - margin)
        levelLabel.text = "Level 1"
        levelLabel.zPosition = 100
        
        super.init()
        
        addChild(scoreLabel)
        addChild(timeLabel)
        addChild(bestLabel)
        addChild(levelLabel)
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
    
    func updateLevel(_ level: Int) {
        levelLabel.text = "Level \(level)"
    }
    
    func repositionForSize(_ size: CGSize) {
        scoreLabel.position = CGPoint(x: margin, y: size.height - margin)
        timeLabel.position = CGPoint(x: size.width - margin, y: size.height - margin)
        bestLabel.position = CGPoint(x: margin, y: size.height - margin - 30)
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - margin)
    }
}
