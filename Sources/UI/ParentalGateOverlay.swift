import SpriteKit

/// A non-bypassable parental gate overlay that must be dismissed before
/// commerce-related actions (Remove Ads, Restore Purchases) are executed.
///
/// Usage:
/// ```swift
/// let gate = ParentalGateOverlay(sceneSize: size) { [weak self] in
///     // called only on correct answer
///     IAPManager.shared.purchaseRemoveAds()
/// }
/// addChild(gate)
/// ```
///
/// The overlay covers the full scene, blocks all underlying touches, and
/// cannot be disabled.  Tapping the wrong answer or Cancel dismisses the
/// overlay without taking any commerce action.
class ParentalGateOverlay: SKNode {

    // MARK: - Node names (used for hit-testing in GameScene)
    static let cancelButtonName  = "pgCancel"
    static let answerButtonPrefix = "pgAnswer_"   // appended with 0, 1, 2

    // MARK: - Private state
    private let correctIndex: Int   // which button index holds the correct answer

    // MARK: - Callbacks
    /// Called on the main thread when the user answers correctly.
    var onSuccess: (() -> Void)?
    /// Called on the main thread when the gate is dismissed (cancel or wrong answer).
    var onDismiss: (() -> Void)?

    // MARK: - Init

    init(sceneSize: CGSize) {
        // Build arithmetic challenge
        let a = Int.random(in: 2...12)
        let b = Int.random(in: 2...12)
        let correct = a + b

        // Two plausible wrong answers – pick two distinct offsets from a fixed set
        let candidateDeltas = [-4, -3, -2, -1, 1, 2, 3, 4].shuffled()
        let delta0 = candidateDeltas[0]
        let delta1 = candidateDeltas[1]
        let answers: [Int] = [correct, correct + delta0, correct + delta1]
            .shuffled()

        correctIndex = answers.firstIndex(of: correct)!

        super.init()
        isUserInteractionEnabled = false   // GameScene routes touches via name-based hit test

        // ── Full-screen blocker (intercepts all touches that fall through) ──
        let blocker = SKShapeNode(rectOf: sceneSize)
        blocker.fillColor   = SKColor.black.withAlphaComponent(0.55)
        blocker.strokeColor = .clear
        blocker.position    = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        blocker.zPosition   = 300
        blocker.name        = "pgBlocker"
        addChild(blocker)

        // ── Dialog box ──
        let boxW: CGFloat = min(sceneSize.width - 60, 340)
        let boxH: CGFloat = 300
        let boxOrigin = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)

        let box = SKShapeNode(rectOf: CGSize(width: boxW, height: boxH), cornerRadius: 16)
        box.fillColor   = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 0.97)
        box.strokeColor = SKColor.white.withAlphaComponent(0.25)
        box.lineWidth   = 1.5
        box.position    = boxOrigin
        box.zPosition   = 301
        addChild(box)

        // ── "Parents Only" title ──
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text      = "Parents Only"
        title.fontSize  = 22
        title.fontColor = .white
        title.position  = CGPoint(x: boxOrigin.x, y: boxOrigin.y + 118)
        title.zPosition = 302
        addChild(title)

        // ── Separator line ──
        let sep = SKShapeNode(rectOf: CGSize(width: boxW - 24, height: 1))
        sep.fillColor   = SKColor.white.withAlphaComponent(0.2)
        sep.strokeColor = .clear
        sep.position    = CGPoint(x: boxOrigin.x, y: boxOrigin.y + 95)
        sep.zPosition   = 302
        addChild(sep)

        // ── Question ──
        let question = SKLabelNode(fontNamed: "Helvetica")
        question.text      = "What is \(a) + \(b)?"
        question.fontSize  = 26
        question.fontColor = SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0)
        question.position  = CGPoint(x: boxOrigin.x, y: boxOrigin.y + 48)
        question.zPosition = 302
        addChild(question)

        // ── Answer buttons ──
        let answerYPositions: [CGFloat] = [-14, -62, -110]
        for (idx, ans) in answers.enumerated() {
            let btn = makeButton(
                text:      "\(ans)",
                position:  CGPoint(x: boxOrigin.x, y: boxOrigin.y + answerYPositions[idx]),
                name:      ParentalGateOverlay.answerButtonPrefix + "\(idx)",
                zPosition: 302
            )
            addChild(btn)
        }

        // ── Cancel button ──
        let cancelLabel = SKLabelNode(fontNamed: "Helvetica")
        cancelLabel.text      = "Cancel"
        cancelLabel.fontSize  = 16
        cancelLabel.fontColor = SKColor.lightGray
        cancelLabel.position  = CGPoint(x: boxOrigin.x, y: boxOrigin.y - 128)
        cancelLabel.zPosition = 302
        cancelLabel.name      = ParentalGateOverlay.cancelButtonName
        addChild(cancelLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Touch Routing

    /// Called by GameScene's touchesBegan when this overlay is visible.
    /// Always returns `true` – the gate absorbs all touches.
    @discardableResult
    func handleTouch(at location: CGPoint, scene: SKScene) -> Bool {
        let tapped = scene.nodes(at: location)

        // Cancel → dismiss without action
        if tapped.contains(where: { $0.name == ParentalGateOverlay.cancelButtonName }) {
            dismiss()
            onDismiss?()
            return true
        }

        // Answer buttons
        for i in 0...2 {
            let name = ParentalGateOverlay.answerButtonPrefix + "\(i)"
            if tapped.contains(where: { $0.name == name }) {
                if i == correctIndex {
                    dismiss()
                    onSuccess?()
                } else {
                    dismiss()   // wrong answer → dismiss without action
                    onDismiss?()
                }
                return true
            }
        }

        // All other taps on the overlay are absorbed silently.
        return true
    }

    // MARK: - Private helpers

    private func dismiss() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
    }

    private func makeButton(text: String, position: CGPoint, name: String, zPosition: CGFloat) -> SKNode {
        let container = SKNode()
        container.position  = position
        container.zPosition = zPosition
        container.name      = name

        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 34), cornerRadius: 8)
        bg.fillColor   = SKColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.85)
        bg.strokeColor = SKColor.white.withAlphaComponent(0.35)
        bg.lineWidth   = 1
        bg.name        = name   // propagate name so nodes(at:) finds it

        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text              = text
        label.fontSize          = 18
        label.fontColor         = .white
        label.verticalAlignmentMode = .center
        label.name              = name   // propagate name

        container.addChild(bg)
        container.addChild(label)
        return container
    }
}
