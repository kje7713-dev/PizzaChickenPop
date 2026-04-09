import SpriteKit

/// Game Over overlay with score display and restart prompt
class GameOverOverlay: SKNode {
    
    private let backgroundNode: SKShapeNode
    private let titleLabel: SKLabelNode
    private let scoreLabel: SKLabelNode
    private let bestLabel: SKLabelNode
    private let gcStatusLabel: SKLabelNode
    private let leaderboardButton: SKLabelNode
    private let removeAdsButton: SKLabelNode
    private let restorePurchasesButton: SKLabelNode
    /// Small label shown below the IAP buttons to communicate purchase/restore status.
    private let purchaseStatusLabel: SKLabelNode
    private let restartLabel: SKLabelNode

    /// Name used for hit-testing the leaderboard button in touchesBegan
    static let leaderboardButtonName = "leaderboardButton"

    /// Name used for hit-testing the remove-ads button in touchesBegan
    static let removeAdsButtonName = "removeAdsButton"

    /// Name used for hit-testing the restore purchases button in touchesBegan
    static let restorePurchasesButtonName = "restorePurchasesButton"

    /// The default title text for the remove-ads button (idle state).
    private static let removeAdsButtonTitle = "REMOVE ADS - $0.99"

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

        // REMOVE ADS button
        removeAdsButton = SKLabelNode(fontNamed: "Helvetica-Bold")
        removeAdsButton.text = GameOverOverlay.removeAdsButtonTitle
        removeAdsButton.fontSize = 20
        removeAdsButton.fontColor = SKColor.green
        removeAdsButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 155)
        removeAdsButton.zPosition = 201
        removeAdsButton.name = GameOverOverlay.removeAdsButtonName

        // RESTORE PURCHASES button
        restorePurchasesButton = SKLabelNode(fontNamed: "Helvetica")
        restorePurchasesButton.text = "Restore Purchases"
        restorePurchasesButton.fontSize = 18
        restorePurchasesButton.fontColor = SKColor.cyan
        restorePurchasesButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 190)
        restorePurchasesButton.zPosition = 201
        restorePurchasesButton.name = GameOverOverlay.restorePurchasesButtonName

        // Purchase status label (shown below IAP buttons)
        purchaseStatusLabel = SKLabelNode(fontNamed: "Helvetica")
        purchaseStatusLabel.text = ""
        purchaseStatusLabel.fontSize = 16
        purchaseStatusLabel.fontColor = .white
        purchaseStatusLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 220)
        purchaseStatusLabel.zPosition = 201

        // Restart prompt
        restartLabel = SKLabelNode(fontNamed: "Helvetica")
        let promptText = customMessage != nil ? "Tap to Continue" : "Tap to Restart"
        restartLabel.text = promptText
        restartLabel.fontSize = 24
        restartLabel.fontColor = .lightGray
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 260)
        restartLabel.zPosition = 201

        super.init()

        addChild(backgroundNode)
        addChild(titleLabel)
        addChild(scoreLabel)
        addChild(bestLabel)
        addChild(gcStatusLabel)
        if showLeaderboardButton { addChild(leaderboardButton) }
        if !IAPManager.shared.adsRemoved {
            addChild(removeAdsButton)
            addChild(restorePurchasesButton)
            addChild(purchaseStatusLabel)
        }
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

    // MARK: - Purchase Status

    /// Updates the status label and button appearance to reflect the current purchase state.
    /// Call from the main thread.
    func updatePurchaseStatus(_ status: PurchaseStatus) {
        switch status {
        case .idle:
            purchaseStatusLabel.text = ""
            removeAdsButton.text = GameOverOverlay.removeAdsButtonTitle
            removeAdsButton.fontColor = SKColor.green
            removeAdsButton.alpha = 1.0
            restorePurchasesButton.alpha = 1.0
        case .loading(let message):
            purchaseStatusLabel.text = message
            purchaseStatusLabel.fontColor = .white
            removeAdsButton.text = "PROCESSING…"
            removeAdsButton.fontColor = SKColor.gray
            removeAdsButton.alpha = 0.6
            restorePurchasesButton.alpha = 0.4
        case .success(let message):
            purchaseStatusLabel.text = message
            purchaseStatusLabel.fontColor = SKColor.green
            removeAdsButton.text = GameOverOverlay.removeAdsButtonTitle
            removeAdsButton.fontColor = SKColor.green
            removeAdsButton.alpha = 1.0
            restorePurchasesButton.alpha = 1.0
        case .failure(let message):
            purchaseStatusLabel.text = message
            purchaseStatusLabel.fontColor = SKColor.red
            removeAdsButton.text = GameOverOverlay.removeAdsButtonTitle
            removeAdsButton.fontColor = SKColor.green
            removeAdsButton.alpha = 1.0
            restorePurchasesButton.alpha = 1.0
        }
    }
}
