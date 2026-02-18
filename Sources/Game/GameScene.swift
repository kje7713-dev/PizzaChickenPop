import SpriteKit

/// Main game scene for PizzaChicken - Timed 30s mode
class GameScene: SKScene {
    
    // MARK: - Game Nodes
    private var chickenNode: SKShapeNode!
    private var pizzaNode: SKShapeNode!
    private var spicyWingNode: SKShapeNode?
    private var hudNode: HUDNode!
    private var gameOverOverlay: GameOverOverlay?
    
    // MARK: - Game State
    private var gameState: GameState = .ready
    private var currentLevel: Int = 1
    private var score: Int = 0 {
        didSet {
            hudNode?.updateScore(score)
            checkLevelComplete()
        }
    }
    private var spicyWingHits: Int = 0
    private var timeRemaining: TimeInterval = 30.0
    private var gameDuration: TimeInterval = 30.0
    private var lastUpdateTime: TimeInterval = 0
    private var pizzaMoveTimer: TimeInterval = 0
    private let pizzaMoveInterval: TimeInterval = 2.0
    
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
    
    // MARK: - Spicy Wing Constants
    private var spicyWingSpawnChance: Double {
        switch currentLevel {
        case 1:
            return 0.3 // 30% chance
        case 2:
            return 0.5 // 50% chance - increased for level 2
        case 3:
            return 0.7 // 70% chance - increased for level 3
        default:
            return 0.3
        }
    }
    private var spicyWingRadius: CGFloat {
        switch currentLevel {
        case 1:
            return 25
        case 2:
            return 35 // Larger for level 2
        case 3:
            return 45 // Even larger for level 3
        default:
            return 25
        }
    }
    private let maxSpicyWingHits: Int = 3
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Set background color to light sky blue
        backgroundColor = SKColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0)
        
        // Setup game elements
        setupChicken()
        setupHUD()
        spawnPizza()
        
        // Load best score and set initial level
        hudNode.updateBest(scoreManager.bestScore)
        hudNode.updateLevel(currentLevel)
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
        
        // Create pizza with size based on level
        let pizzaRadius: CGFloat = currentLevel == 3 ? 20 : 30 // Smaller pizzas in level 3
        pizzaNode = SKShapeNode(circleOfRadius: pizzaRadius)
        pizzaNode.fillColor = .systemOrange
        pizzaNode.strokeColor = .brown
        pizzaNode.lineWidth = 2
        pizzaNode.name = "pizza"
        
        // Add pepperoni dots (scale with pizza size)
        let pepperoniScale: CGFloat = currentLevel == 3 ? 0.7 : 1.0
        let pepperoniPositions: [(CGFloat, CGFloat)] = [
            (10, 10), (-10, 10), (10, -10), (-10, -10), (0, 0)
        ]
        for (x, y) in pepperoniPositions {
            let pepperoni = SKShapeNode(circleOfRadius: 5 * pepperoniScale)
            pepperoni.fillColor = .systemRed
            pepperoni.strokeColor = .systemRed
            pepperoni.position = CGPoint(x: x * pepperoniScale, y: y * pepperoniScale)
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
    
    private func spawnSpicyWing() {
        // Remove existing spicy wing if any
        spicyWingNode?.removeFromParent()
        
        // Create spicy wing with size based on level
        let wingRadius = spicyWingRadius
        spicyWingNode = SKShapeNode(circleOfRadius: wingRadius)
        spicyWingNode?.fillColor = .systemRed
        spicyWingNode?.strokeColor = .orange
        spicyWingNode?.lineWidth = 3
        spicyWingNode?.name = "spicyWing"
        
        // Add flame-like accent (small triangles to indicate spiciness)
        let flameScale = wingRadius / 25.0 // Scale flames based on wing size
        let flamePositions: [(CGFloat, CGFloat, CGFloat)] = [
            (15, 15, 0.7), (-15, 15, 0.7), (15, -15, 0.7), (-15, -15, 0.7)
        ]
        for (x, y, scale) in flamePositions {
            let flamePath = CGMutablePath()
            flamePath.move(to: CGPoint(x: 0, y: -8))
            flamePath.addLine(to: CGPoint(x: -6, y: 0))
            flamePath.addLine(to: CGPoint(x: 6, y: 0))
            flamePath.closeSubpath()
            
            let flame = SKShapeNode(path: flamePath)
            flame.fillColor = .yellow
            flame.strokeColor = .yellow
            flame.position = CGPoint(x: x * flameScale, y: y * flameScale)
            flame.setScale(scale * flameScale)
            spicyWingNode?.addChild(flame)
        }
        
        // Position at random location
        repositionSpicyWing()
        
        addChild(spicyWingNode!)
    }
    
    private func repositionSpicyWing() {
        guard let spicyWingNode = spicyWingNode else { return }
        
        // Keep at least 80px away from all edges
        let minX = edgeMargin
        let maxX = size.width - edgeMargin
        let minY = edgeMargin
        let maxY = size.height - edgeMargin
        
        let randomX = CGFloat.random(in: minX...maxX)
        let randomY = CGFloat.random(in: minY...maxY)
        
        spicyWingNode.position = CGPoint(x: randomX, y: randomY)
    }
    
    private func removeSpicyWing() {
        spicyWingNode?.removeFromParent()
        spicyWingNode = nil
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
            
        case .levelComplete:
            // Tap to continue to next level
            advanceToNextLevel()
            
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
        
        // Set time based on level
        gameDuration = currentLevel == 1 ? 30.0 : 25.0
        timeRemaining = gameDuration
        
        lastUpdateTime = 0
        pizzaMoveTimer = 0
        hudNode.updateTime(Int(ceil(timeRemaining)))
        hudNode.updateLevel(currentLevel)
    }
    
    private func checkLevelComplete() {
        guard gameState == .playing else { return }
        
        let requiredScore: Int
        switch currentLevel {
        case 1:
            requiredScore = 150
        case 2:
            requiredScore = 150 // Same requirement for level 2
        case 3:
            requiredScore = 150 // Same requirement for level 3
        default:
            return
        }
        
        if score >= requiredScore {
            levelComplete()
        }
    }
    
    private func levelComplete() {
        gameState = .levelComplete
        targetPosition = nil
        
        // Show level complete overlay
        let messageText = currentLevel == 3 ? "Game Complete!" : "Level \(currentLevel) Complete!"
        let overlay = GameOverOverlay(size: size, finalScore: score, bestScore: scoreManager.bestScore, customMessage: messageText)
        gameOverOverlay = overlay
        addChild(overlay)
    }
    
    private func advanceToNextLevel() {
        // Remove overlay
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        
        if currentLevel >= 3 {
            // Game complete, show final game over
            endGame()
        } else {
            // Advance to next level
            currentLevel += 1
            
            // Reset state for new level
            gameState = .ready
            score = 0
            spicyWingHits = 0
            
            // Set time based on level
            gameDuration = currentLevel == 1 ? 30.0 : 25.0
            timeRemaining = gameDuration
            
            hudNode.updateScore(0)
            hudNode.updateTime(Int(ceil(timeRemaining)))
            hudNode.updateLevel(currentLevel)
            
            // Reset click tracking
            clickTimestamps.removeAll()
            
            // Reset chicken position and visibility
            chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
            chickenNode.alpha = 1.0
            chickenNode.setScale(1.0)
            
            // Remove any spicy wing
            removeSpicyWing()
            
            // Respawn pizza
            spawnPizza()
        }
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
        
        // Reset state to level 1
        currentLevel = 1
        gameState = .ready
        score = 0
        spicyWingHits = 0
        
        gameDuration = 30.0
        timeRemaining = gameDuration
        
        hudNode.updateScore(0)
        hudNode.updateTime(Int(ceil(timeRemaining)))
        hudNode.updateLevel(currentLevel)
        
        // Reset click tracking
        clickTimestamps.removeAll()
        
        // Reset chicken position and visibility
        chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        chickenNode.alpha = 1.0
        chickenNode.setScale(1.0)
        
        // Remove any spicy wing
        removeSpicyWing()
        
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
        
        // Check collision with spicy wing
        checkSpicyWingCollision()
        
        // Move pizza every 2 seconds in level 3
        if currentLevel == 3 {
            pizzaMoveTimer += deltaTime
            if pizzaMoveTimer >= pizzaMoveInterval {
                pizzaMoveTimer = 0
                repositionPizza()
            }
        }
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
        
        // Randomly spawn a spicy wing
        if Double.random(in: 0...1) < spicyWingSpawnChance {
            let wingDelay = SKAction.wait(forDuration: 0.3)
            let spawn = SKAction.run { [weak self] in
                self?.spawnSpicyWing()
            }
            run(SKAction.sequence([wingDelay, spawn]))
        }
    }
    
    private func checkSpicyWingCollision() {
        guard let wing = spicyWingNode else { return }
        
        let dx = chickenNode.position.x - wing.position.x
        let dy = chickenNode.position.y - wing.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance < collisionDistance {
            handleSpicyWingHit()
        }
    }
    
    private func handleSpicyWingHit() {
        // Increment hit counter
        spicyWingHits += 1
        
        // Remove the spicy wing
        removeSpicyWing()
        
        // Shake chicken animation to show hit
        let shakeLeft = SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        let shakeRight = SKAction.moveBy(x: 20, y: 0, duration: 0.05)
        let shakeBack = SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        let shakeSequence = SKAction.sequence([shakeLeft, shakeRight, shakeBack])
        chickenNode.run(shakeSequence)
        
        // Check if reached max hits
        if spicyWingHits >= maxSpicyWingHits {
            explodeChicken()
        }
    }
    
    private func explodeChicken() {
        // Play explosion animation
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let explosionSequence = SKAction.group([scaleUp, fadeOut])
        
        chickenNode.run(explosionSequence) { [weak self] in
            // End the game after explosion
            self?.endGame()
        }
        
        // Create simple particle effect (feathers)
        for _ in 0..<20 {
            let feather = SKShapeNode(circleOfRadius: 5)
            feather.fillColor = .systemYellow
            feather.strokeColor = .orange
            feather.position = chickenNode.position
            feather.zPosition = -1
            addChild(feather)
            
            let randomAngle = CGFloat.random(in: 0...(2 * .pi))
            let randomDistance = CGFloat.random(in: 50...150)
            let dx = cos(randomAngle) * randomDistance
            let dy = sin(randomAngle) * randomDistance
            
            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([SKAction.group([move, fade]), remove])
            feather.run(sequence)
        }
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
