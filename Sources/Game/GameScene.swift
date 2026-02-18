import SpriteKit

/// Main game scene for PizzaChicken - Timed 30s mode
class GameScene: SKScene {
    
    // MARK: - Game Nodes
    private var chickenNode: SKShapeNode!
    private var pizzaNode: SKShapeNode!
    private var hudNode: HUDNode!
    private var gameOverOverlay: GameOverOverlay?
    
    // MARK: - Game State
    private var gameState: GameState = .ready
    private var score: Int = 0 {
        didSet {
            hudNode?.updateScore(score)
        }
    }
    private var timeRemaining: TimeInterval = 30.0
    private let gameDuration: TimeInterval = 30.0
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Managers
    private let scoreManager = ScoreManager()
    
    // MARK: - Movement
    private var targetPosition: CGPoint?
    private let baseSpeed: CGFloat = 200.0
    private var clickTimestamps: [TimeInterval] = []
    private let clickRateWindow: TimeInterval = 1.0 // Track clicks in last 1 second
    private let speedMultiplierPerClick: CGFloat = 0.3 // 30% speed boost per click/second
    
    // MARK: - Layout Constants
    private let edgeMargin: CGFloat = 80
    private let collisionDistance: CGFloat = 60
    private let stopThreshold: CGFloat = 5
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Set background color to light sky blue
        backgroundColor = SKColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0)
        
        // Setup game elements
        setupChicken()
        setupHUD()
        spawnPizza()
        
        // Load best score
        hudNode.updateBest(scoreManager.bestScore)
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
    
    private func setupHUD() {
        hudNode = HUDNode(size: size)
        addChild(hudNode)
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
        repositionPizza()
        
        addChild(pizzaNode)
    }
    
    private func repositionPizza() {
        guard let pizzaNode = pizzaNode else { return }
        
        // Keep at least 80px away from all edges
        let minX = edgeMargin
        let maxX = size.width - edgeMargin
        let minY = edgeMargin
        let maxY = size.height - edgeMargin
        
        let randomX = CGFloat.random(in: minX...maxX)
        let randomY = CGFloat.random(in: minY...maxY)
        
        pizzaNode.position = CGPoint(x: randomX, y: randomY)
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch gameState {
        case .ready:
            // First tap starts the game
            startGame()
            targetPosition = location
            recordClick()
            
        case .playing:
            // Set target position for chicken to move toward
            targetPosition = location
            recordClick()
            
        case .gameOver:
            // Tap to restart
            restartGame()
        }
    }
    
    // MARK: - Click Rate Tracking
    private func recordClick() {
        let currentTime = Date().timeIntervalSinceReferenceDate
        clickTimestamps.append(currentTime)
    }
    
    private func getCurrentClickRate() -> CGFloat {
        let currentTime = Date().timeIntervalSinceReferenceDate
        let cutoffTime = currentTime - clickRateWindow
        
        // Clean up old clicks outside the tracking window
        clickTimestamps.removeAll { $0 < cutoffTime }
        
        // Return current click count
        return CGFloat(clickTimestamps.count)
    }
    
    private func getCurrentMoveSpeed() -> CGFloat {
        let clickRate = getCurrentClickRate()
        let speedMultiplier = 1.0 + (clickRate * speedMultiplierPerClick)
        return baseSpeed * speedMultiplier
    }
    
    // MARK: - Game Flow
    private func startGame() {
        gameState = .playing
        score = 0
        timeRemaining = gameDuration
        lastUpdateTime = 0
        hudNode.updateTime(Int(ceil(timeRemaining)))
    }
    
    private func endGame() {
        gameState = .gameOver
        targetPosition = nil
        
        // Update best score
        scoreManager.checkAndUpdateBestScore(score)
        hudNode.updateBest(scoreManager.bestScore)
        
        // Show game over overlay
        let overlay = GameOverOverlay(size: size, finalScore: score, bestScore: scoreManager.bestScore)
        gameOverOverlay = overlay
        addChild(overlay)
    }
    
    private func restartGame() {
        // Remove overlay
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        
        // Reset state
        gameState = .ready
        score = 0
        timeRemaining = gameDuration
        hudNode.updateScore(0)
        hudNode.updateTime(Int(ceil(timeRemaining)))
        
        // Reset click tracking
        clickTimestamps.removeAll()
        
        // Reset chicken position
        chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Respawn pizza
        repositionPizza()
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Only update during playing state
        guard gameState == .playing else { return }
        
        // Initialize lastUpdateTime on first frame
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        // Calculate delta time
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update timer
        timeRemaining -= deltaTime
        
        // Clamp to 0
        if timeRemaining <= 0 {
            timeRemaining = 0
            hudNode.updateTime(0)
            endGame()
            return
        }
        
        // Update HUD with ceiling of time
        let displayTime = Int(ceil(timeRemaining))
        hudNode.updateTime(displayTime)
        
        // Move chicken toward target
        if let target = targetPosition {
            moveChickenToward(target, deltaTime: deltaTime)
        }
        
        // Check collision with pizza
        checkPizzaCollision()
    }
    
    private func moveChickenToward(_ target: CGPoint, deltaTime: TimeInterval) {
        let currentPos = chickenNode.position
        let dx = target.x - currentPos.x
        let dy = target.y - currentPos.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Stop if close enough
        if distance < stopThreshold {
            targetPosition = nil
            return
        }
        
        // Move toward target with dynamic speed based on click rate
        let currentSpeed = getCurrentMoveSpeed()
        let speed = currentSpeed * CGFloat(deltaTime)
        let moveDistance = min(speed, distance)
        let angle = atan2(dy, dx)
        
        chickenNode.position = CGPoint(
            x: currentPos.x + cos(angle) * moveDistance,
            y: currentPos.y + sin(angle) * moveDistance
        )
    }
    
    private func checkPizzaCollision() {
        guard let pizza = pizzaNode else { return }
        
        let dx = chickenNode.position.x - pizza.position.x
        let dy = chickenNode.position.y - pizza.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < collisionDistance {
            handlePizzaEat()
        }
    }
    
    private func handlePizzaEat() {
        // Increment score
        score += 1
        
        // Play pizza pop animation
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let popSequence = SKAction.sequence([scaleUp, scaleDown])
        pizzaNode.run(popSequence)
        
        // Respawn pizza at new location
        let delay = SKAction.wait(forDuration: 0.2)
        let reposition = SKAction.run { [weak self] in
            self?.repositionPizza()
        }
        pizzaNode.run(SKAction.sequence([delay, reposition]))
    }
    
    // MARK: - Layout Updates
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        // Reposition HUD
        hudNode?.repositionForSize(size)
        
        // Reposition chicken if in ready state
        if gameState == .ready, let chickenNode = chickenNode {
            chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        }
        
        // Reposition pizza if needed
        if pizzaNode != nil {
            repositionPizza()
        }
    }
}
