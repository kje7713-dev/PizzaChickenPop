import SpriteKit

/// Game Over overlay with score display and restart prompt
class GameOverOverlay: SKNode {

    private let backgroundNode: SKShapeNode
    private let titleLabel: SKLabelNode
    private let scoreLabel: SKLabelNode
    private let bestLabel: SKLabelNode
    private let gcStatusLabel: SKLabelNode
    private let leaderboardButtonContainer: SKShapeNode
    private let connectGCButtonContainer: SKShapeNode
    private let gcDebugLabel: SKLabelNode
    private let restartButtonContainer: SKShapeNode

    /// Name used for hit-testing the leaderboard button in touchesBegan
    static let leaderboardButtonName = "leaderboardButton"

    /// Name used for hit-testing the connect Game Center button in touchesBegan
    static let connectGameCenterButtonName = "connectGameCenterButton"

    /// Name used for hit-testing the restart button in touchesBegan
    static let restartButtonName = "restartButton"

    // MARK: - Button factory helper

    /// Creates a rounded-rect button container with a centred label child.
    private static func makeButton(
        text: String,
        fontSize: CGFloat,
        textColor: SKColor,
        buttonName: String,
        width: CGFloat = 300,
        height: CGFloat = 50,
        center: CGPoint,
        zPosition: CGFloat
    ) -> SKShapeNode {
        let container = SKShapeNode(
            rectOf: CGSize(width: width, height: height),
            cornerRadius: 10
        )
        container.fillColor = SKColor.black.withAlphaComponent(0.55)
        container.strokeColor = textColor.withAlphaComponent(0.6)
        container.lineWidth = 1.5
        container.position = center
        container.zPosition = zPosition
        container.name = buttonName

        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        container.addChild(label)

        return container
    }

    init(size: CGSize, finalScore: Int, bestScore: Int,
         customMessage: String? = nil,
         gcStatus: String? = nil,
         showLeaderboardButton: Bool = false,
         isGCAuthenticated: Bool = false) {
        let cx = size.width / 2
        let cy = size.height / 2

        // Semi-transparent background
        backgroundNode = SKShapeNode(rectOf: size)
        backgroundNode.fillColor = SKColor.black.withAlphaComponent(0.7)
        backgroundNode.strokeColor = .clear
        backgroundNode.position = CGPoint(x: cx, y: cy)
        backgroundNode.zPosition = 200

        // Title
        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = customMessage ?? "Game Over"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: cx, y: cy + 80)
        titleLabel.zPosition = 201

        // Final score
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.text = "Score: \(finalScore)"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: cx, y: cy + 20)
        scoreLabel.zPosition = 201

        // Best score
        bestLabel = SKLabelNode(fontNamed: "Helvetica")
        bestLabel.text = "Best: \(bestScore)"
        bestLabel.fontSize = 28
        bestLabel.fontColor = .yellow
        bestLabel.position = CGPoint(x: cx, y: cy - 30)
        bestLabel.zPosition = 201

        // Game Center status (small, always visible when provided)
        gcStatusLabel = SKLabelNode(fontNamed: "Helvetica")
        gcStatusLabel.text = gcStatus ?? ""
        gcStatusLabel.fontSize = 16
        gcStatusLabel.fontColor = .lightGray
        gcStatusLabel.position = CGPoint(x: cx, y: cy - 70)
        gcStatusLabel.zPosition = 201

        // LEADERBOARD button container with large hit area
        leaderboardButtonContainer = GameOverOverlay.makeButton(
            text: "LEADERBOARD",
            fontSize: 22,
            textColor: SKColor.orange,
            buttonName: GameOverOverlay.leaderboardButtonName,
            width: 300,
            height: 50,
            center: CGPoint(x: cx, y: cy - 115),  // below gcStatusLabel
            zPosition: 201
        )

        // CONNECT GAME CENTER button container with large hit area
        // Positioned 60 pts below the leaderboard button (50 pt button height + 10 pt gap)
        connectGCButtonContainer = GameOverOverlay.makeButton(
            text: "CONNECT GAME CENTER",
            fontSize: 18,
            textColor: SKColor.cyan,
            buttonName: GameOverOverlay.connectGameCenterButtonName,
            width: 300,
            height: 50,
            center: CGPoint(x: cx, y: cy - 175),
            zPosition: 201
        )

        // Debug auth state line (subtle, small)
        gcDebugLabel = SKLabelNode(fontNamed: "Helvetica")
        gcDebugLabel.text = isGCAuthenticated ? "GC Auth: YES" : "GC Auth: NO"
        gcDebugLabel.fontSize = 13
        gcDebugLabel.fontColor = isGCAuthenticated ? SKColor.green.withAlphaComponent(0.7)
                                                   : SKColor.red.withAlphaComponent(0.7)
        gcDebugLabel.position = CGPoint(x: cx, y: cy - 215)
        gcDebugLabel.zPosition = 201

        // Restart button container with large hit area
        let promptText = customMessage != nil ? "Tap to Continue" : "Tap to Restart"
        restartButtonContainer = GameOverOverlay.makeButton(
            text: promptText,
            fontSize: 24,
            textColor: .lightGray,
            buttonName: GameOverOverlay.restartButtonName,
            width: 300,
            height: 50,
            center: CGPoint(x: cx, y: cy - 260),
            zPosition: 201
        )

        super.init()

        addChild(backgroundNode)
        addChild(titleLabel)
        addChild(scoreLabel)
        addChild(bestLabel)
        addChild(gcStatusLabel)
        if showLeaderboardButton { addChild(leaderboardButtonContainer) }
        if showLeaderboardButton {
            if !isGCAuthenticated { addChild(connectGCButtonContainer) }
            addChild(gcDebugLabel)
        }
        addChild(restartButtonContainer)

        // Animate in
        alpha = 0
        run(SKAction.fadeIn(withDuration: 0.3))

        // Blink restart label inside its container
        if let restartLabel = restartButtonContainer.children.first {
            let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
            let fadeIn  = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
            restartLabel.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
