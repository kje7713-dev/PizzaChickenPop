import SpriteKit

/// Main game scene for PizzaChicken
class GameScene: SKScene {
    
    // MARK: - Game Nodes
    private var chickenNode: SKShapeNode!
    private var pizzaNode: SKShapeNode!
    private var scoreLabel: SKLabelNode!
    
    // MARK: - Game State
    private var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    private let maxChickenScale: CGFloat = 2.0
    private let chickenGrowthRate: CGFloat = 0.05
    
    // MARK: - Layout Constants
    private let uiMargin: CGFloat = 20
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Set background color to light sky blue
        backgroundColor = SKColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0)
        
        // Setup game elements
        setupChicken()
        setupScoreLabel()
        spawnPizza()
    }
    
    // MARK: - Setup Methods
    private func setupChicken() {
        // Create chicken as yellow circle with red beak triangle
        let chickenRadius: CGFloat = 50
        chickenNode = SKShapeNode(circleOfRadius: chickenRadius)
        chickenNode.fillColor = .systemYellow
        chickenNode.strokeColor = .orange
        chickenNode.lineWidth = 2
        chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        chickenNode.name = "chicken"
        addChild(chickenNode)
        
        // Add beak (red triangle)
        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: chickenRadius, y: 0))
        beakPath.addLine(to: CGPoint(x: chickenRadius + 15, y: -8))
        beakPath.addLine(to: CGPoint(x: chickenRadius + 15, y: 8))
        beakPath.closeSubpath()
        
        let beak = SKShapeNode(path: beakPath)
        beak.fillColor = .systemRed
        beak.strokeColor = .systemRed
        beak.name = "beak"
        chickenNode.addChild(beak)
    }
    
    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .black
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        
        // Position in top-left (accounting for safe area)
        scoreLabel.position = CGPoint(x: uiMargin, y: size.height - uiMargin)
        scoreLabel.text = "Score: 0"
        scoreLabel.name = "scoreLabel"
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
    }
    
    private func spawnPizza() {
        // Remove existing pizza if any
        pizzaNode?.removeFromParent()
        
        // Create pizza as orange circle with pepperoni dots
        let pizzaRadius: CGFloat = 30
        pizzaNode = SKShapeNode(circleOfRadius: pizzaRadius)
        pizzaNode.fillColor = .systemOrange
        pizzaNode.strokeColor = .brown
        pizzaNode.lineWidth = 2
        pizzaNode.name = "pizza"
        
        // Add pepperoni dots
        let pepperoniPositions: [(CGFloat, CGFloat)] = [
            (10, 10), (-10, 10), (10, -10), (-10, -10), (0, 0)
        ]
        for (x, y) in pepperoniPositions {
            let pepperoni = SKShapeNode(circleOfRadius: 5)
            pepperoni.fillColor = .systemRed
            pepperoni.strokeColor = .systemRed
            pepperoni.position = CGPoint(x: x, y: y)
            pizzaNode.addChild(pepperoni)
        }
        
        // Position pizza at random location
        movePizza()
        
        addChild(pizzaNode)
    }
    
    private func movePizza() {
        // Calculate safe bounds (avoid score label area)
        let margin: CGFloat = 50
        let scoreLabelHeight: CGFloat = 80
        
        let minX = margin
        let maxX = size.width - margin
        let minY = margin
        let maxY = size.height - scoreLabelHeight
        
        let randomX = CGFloat.random(in: minX...maxX)
        let randomY = CGFloat.random(in: minY...maxY)
        
        pizzaNode.position = CGPoint(x: randomX, y: randomY)
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // Check if pizza was tapped
        for node in touchedNodes {
            if node.name == "pizza" || node.parent?.name == "pizza" {
                handlePizzaTap()
                break
            }
        }
    }
    
    private func handlePizzaTap() {
        // Increment score
        score += 1
        
        // Play pizza pop animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let popSequence = SKAction.sequence([scaleUp, scaleDown])
        pizzaNode.run(popSequence)
        
        // Grow chicken
        growChicken()
        
        // Move pizza to new location
        let moveDelay = SKAction.wait(forDuration: 0.2)
        let moveAction = SKAction.run { [weak self] in
            self?.movePizza()
        }
        pizzaNode.run(SKAction.sequence([moveDelay, moveAction]))
    }
    
    private func growChicken() {
        let newScale = chickenNode.xScale + chickenGrowthRate
        
        // Animate chicken growth with bounce
        let scaleAction = SKAction.scale(to: newScale, duration: 0.15)
        scaleAction.timingMode = .easeOut
        chickenNode.run(scaleAction)
        
        // Check if chicken exceeded threshold
        if newScale >= maxChickenScale {
            // Delay explosion slightly
            let delay = SKAction.wait(forDuration: 0.3)
            let explodeAction = SKAction.run { [weak self] in
                self?.explodeChicken()
            }
            chickenNode.run(SKAction.sequence([delay, explodeAction]))
        }
    }
    
    private func explodeChicken() {
        // Create explosion effect (scale up, fade out, shake)
        let scaleUp = SKAction.scale(to: 3.0, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let rotate1 = SKAction.rotate(byAngle: 0.2, duration: 0.05)
        let rotate2 = SKAction.rotate(byAngle: -0.4, duration: 0.05)
        let rotate3 = SKAction.rotate(byAngle: 0.2, duration: 0.05)
        let shake = SKAction.sequence([rotate1, rotate2, rotate3])
        
        let explosion = SKAction.group([scaleUp, fadeOut, shake])
        
        chickenNode.run(explosion) { [weak self] in
            self?.resetGame()
        }
        
        // Add particle burst effect
        createExplosionParticles()
    }
    
    private func createExplosionParticles() {
        // Create simple particle effect
        let particleCount = 20
        let chickenPosition = chickenNode.position
        
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: 5)
            particle.fillColor = .systemYellow
            particle.strokeColor = .orange
            particle.position = chickenPosition
            addChild(particle)
            
            // Random direction for particle
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 50...150)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            
            let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([
                SKAction.group([move, fadeOut]),
                remove
            ]))
        }
    }
    
    private func resetGame() {
        // Reset score
        score = 0
        
        // Reset chicken scale and appearance
        chickenNode.setScale(1.0)
        chickenNode.alpha = 1.0
        chickenNode.zRotation = 0
        
        // Respawn pizza
        spawnPizza()
    }
    
    // MARK: - Layout Updates
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        // Reposition elements on orientation change
        chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        scoreLabel.position = CGPoint(x: uiMargin, y: size.height - uiMargin)
        movePizza()
    }
}
