import SpriteKit

/// Game Over overlay with score display and restart prompt
class GameOverOverlay: SKNode {
    
    private let backgroundNode: SKShapeNode
    private let titleLabel: SKLabelNode
    private let scoreLabel: SKLabelNode
    private let bestLabel: SKLabelNode
    private let gcStatusLabel: SKLabelNode
    private let leaderboardButton: SKLabelNode
    private let restartLabel: SKLabelNode

    /// Name used for hit-testing the leaderboard button in touchesBegan
    static let leaderboardButtonName = "leaderboardButton"

    init(size: CGSize, finalScore: Int, bestScore: Int,
         customMessage: String? = nil,
         gcStatus: String? = nil,
         showLeaderboardButton: Bool = false) {
        // Semi-transparent background
        backgroundNode = SKShapeNode(rectOf: size)
        backgroundNode.fillColor = SKColor.black.withAlphaComponent(0.7)
        backgroundNode.strokeColor = .clear
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = 200

        // Title
        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = customMessage ?? "Game Over"
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

        // Game Center status (small, always visible when provided)
        gcStatusLabel = SKLabelNode(fontNamed: "Helvetica")
        gcStatusLabel.text = gcStatus ?? ""
        gcStatusLabel.fontSize = 16
        gcStatusLabel.fontColor = .lightGray
        gcStatusLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 70)
        gcStatusLabel.zPosition = 201

        // LEADERBOARD button (only shown on true game-over screen)
        leaderboardButton = SKLabelNode(fontNamed: "Helvetica-Bold")
        leaderboardButton.text = "LEADERBOARD"
        leaderboardButton.fontSize = 22
        leaderboardButton.fontColor = SKColor.orange
        leaderboardButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 115)
        leaderboardButton.zPosition = 201
        leaderboardButton.name = GameOverOverlay.leaderboardButtonName

        // Restart prompt
        restartLabel = SKLabelNode(fontNamed: "Helvetica")
        let promptText = customMessage != nil ? "Tap to Continue" : "Tap to Restart"
        restartLabel.text = promptText
        restartLabel.fontSize = 24
        restartLabel.fontColor = .lightGray
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 165)
        restartLabel.zPosition = 201

        super.init()

        addChild(backgroundNode)
        addChild(titleLabel)
        addChild(scoreLabel)
        addChild(bestLabel)
        addChild(gcStatusLabel)
        if showLeaderboardButton { addChild(leaderboardButton) }
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
