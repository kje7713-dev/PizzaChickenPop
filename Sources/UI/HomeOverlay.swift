import SpriteKit

/// Home overlay shown before gameplay begins.
final class HomeOverlay: SKNode {

    static let playButtonName = "playButton"
    static let leaderboardButtonName = "leaderboardButton"
    static let connectGameCenterButtonName = "connectGameCenterButton"

    private let backgroundNode: SKShapeNode
    private let panelNode: SKShapeNode
    private let titleLabel: SKLabelNode
    private let statusLabel: SKLabelNode
    private let authDebugLabel: SKLabelNode
    private let accountLabel: SKLabelNode
    private let playButtonContainer: SKShapeNode
    private let leaderboardButtonContainer: SKShapeNode
    private let connectGameCenterButtonContainer: SKShapeNode

    private static func makeButton(
        text: String,
        buttonName: String,
        textColor: SKColor,
        width: CGFloat,
        height: CGFloat,
        center: CGPoint
    ) -> SKShapeNode {
        let container = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 14)
        container.fillColor = SKColor.black.withAlphaComponent(0.65)
        container.strokeColor = textColor.withAlphaComponent(0.9)
        container.lineWidth = 2
        container.position = center
        container.zPosition = 301
        container.name = buttonName

        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = text
        label.fontSize = 22
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        container.addChild(label)

        return container
    }

    init(size: CGSize, title: String, statusText: String, isGCAuthenticated: Bool, accountName: String?) {
        let cx = size.width / 2
        let cy = size.height / 2
        let panelWidth = min(size.width - 8, 360)
        let buttonWidth = min(320, panelWidth - 12)
        let buttonHeight: CGFloat = 56
        let panelHeight: CGFloat = accountName == nil ? 370 : 398

        backgroundNode = SKShapeNode(rectOf: size)
        backgroundNode.fillColor = SKColor.black.withAlphaComponent(0.28)
        backgroundNode.strokeColor = .clear
        backgroundNode.position = CGPoint(x: cx, y: cy)
        backgroundNode.zPosition = 300

        panelNode = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 24)
        panelNode.fillColor = SKColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 0.82)
        panelNode.strokeColor = SKColor.white.withAlphaComponent(0.2)
        panelNode.lineWidth = 2
        panelNode.position = CGPoint(x: cx, y: cy)
        panelNode.zPosition = 300

        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = title
        titleLabel.fontSize = 34
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: cx, y: cy + 125)
        titleLabel.zPosition = 301

        statusLabel = SKLabelNode(fontNamed: "Helvetica")
        statusLabel.text = statusText
        statusLabel.fontSize = 14
        statusLabel.fontColor = .white
        statusLabel.position = CGPoint(x: cx, y: cy + 76)
        statusLabel.zPosition = 301

        authDebugLabel = SKLabelNode(fontNamed: "Helvetica")
        authDebugLabel.text = isGCAuthenticated ? "GC Auth: YES" : "GC Auth: NO"
        authDebugLabel.fontSize = 13
        authDebugLabel.fontColor = isGCAuthenticated
            ? SKColor.green.withAlphaComponent(0.8)
            : SKColor.red.withAlphaComponent(0.8)
        authDebugLabel.position = CGPoint(x: cx, y: cy + 48)
        authDebugLabel.zPosition = 301

        accountLabel = SKLabelNode(fontNamed: "Helvetica")
        accountLabel.text = accountName.map { "Connected as \($0)" } ?? ""
        accountLabel.fontSize = 14
        accountLabel.fontColor = SKColor.cyan.withAlphaComponent(0.85)
        accountLabel.position = CGPoint(x: cx, y: cy + 24)
        accountLabel.zPosition = 301

        playButtonContainer = HomeOverlay.makeButton(
            text: "PLAY",
            buttonName: HomeOverlay.playButtonName,
            textColor: .systemGreen,
            width: buttonWidth,
            height: buttonHeight,
            center: CGPoint(x: cx, y: cy - 30)
        )

        leaderboardButtonContainer = HomeOverlay.makeButton(
            text: "LEADERBOARD",
            buttonName: HomeOverlay.leaderboardButtonName,
            textColor: .orange,
            width: buttonWidth,
            height: buttonHeight,
            center: CGPoint(x: cx, y: cy - 100)
        )

        connectGameCenterButtonContainer = HomeOverlay.makeButton(
            text: "CONNECT GAME CENTER",
            buttonName: HomeOverlay.connectGameCenterButtonName,
            textColor: .cyan,
            width: buttonWidth,
            height: buttonHeight,
            center: CGPoint(x: cx, y: cy - 170)
        )

        super.init()

        addChild(backgroundNode)
        addChild(panelNode)
        addChild(titleLabel)
        addChild(statusLabel)
        addChild(authDebugLabel)
        if accountName != nil {
            addChild(accountLabel)
        }
        addChild(playButtonContainer)
        addChild(leaderboardButtonContainer)
        if !isGCAuthenticated {
            addChild(connectGameCenterButtonContainer)
        }

        alpha = 0
        run(SKAction.fadeIn(withDuration: 0.25))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
