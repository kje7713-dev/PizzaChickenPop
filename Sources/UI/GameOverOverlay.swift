import SpriteKit

/// Game Over overlay with score display and restart prompt
class GameOverOverlay: SKNode {
    
    private let backgroundNode: SKShapeNode
    private let titleLabel: SKLabelNode
    private let scoreLabel: SKLabelNode
    private let bestLabel: SKLabelNode
    private let restartLabel: SKLabelNode
    
    init(size: CGSize, finalScore: Int, bestScore: Int) {
        // Semi-transparent background
        backgroundNode = SKShapeNode(rectOf: size)
        backgroundNode.fillColor = SKColor.black.withAlphaComponent(0.7)
        backgroundNode.strokeColor = .clear
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = 200
        
        // Title
        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "Game Over"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        titleLabel.zPosition = 201
        
        // Final score
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.text = "Score: \(finalScore)"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        scoreLabel.zPosition = 201
        
        // Best score
        bestLabel = SKLabelNode(fontNamed: "Helvetica")
        bestLabel.text = "Best: \(bestScore)"
        bestLabel.fontSize = 28
        bestLabel.fontColor = .yellow
        bestLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        bestLabel.zPosition = 201
        
        // Restart prompt
        restartLabel = SKLabelNode(fontNamed: "Helvetica")
        restartLabel.text = "Tap to Restart"
        restartLabel.fontSize = 24
        restartLabel.fontColor = .lightGray
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        restartLabel.zPosition = 201
        
        super.init()
        
        addChild(backgroundNode)
        addChild(titleLabel)
        addChild(scoreLabel)
        addChild(bestLabel)
        addChild(restartLabel)
        
        // Animate in
        alpha = 0
        run(SKAction.fadeIn(withDuration: 0.3))
        
        // Blink restart label
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        let blink = SKAction.sequence([fadeOut, fadeIn])
        restartLabel.run(SKAction.repeatForever(blink))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
