import SpriteKit

/// Main game scene for PizzaChicken - Timed 30s mode
class GameScene: SKScene {
    
    // MARK: - Game Nodes
    private var chickenNode: ChickenNode!
    private var pizzaNode: SKSpriteNode!
    private var spicyWingNodes: [SKSpriteNode] = []
    private var hudNode: HUDNode!
    private var gameOverOverlay: GameOverOverlay?

    // MARK: - Sound Actions
    private let chompSound = SoundManager.shared.soundAction(name: "chomp")
    private let mommySound = SoundManager.shared.soundAction(name: "mommy")
    private let scoreSound = SoundManager.shared.soundAction(name: "score")
    private let explodeSound = SoundManager.shared.soundAction(name: "explode")
    private let levelWinSound = SoundManager.shared.soundAction(name: "level_win")
    
    // MARK: - Game State
    private var gameState: GameState = .ready
    private var currentLevel: Int = 1
    private var score: Int = 0 {
        didSet {
            hudNode?.updateScore(score)
            checkLevelComplete()
        }
    }
    private var runScore: Int = 0
    private var isBonusRound: Bool = false
    private var spicyWingHits: Int = 0
    private var timeRemaining: TimeInterval = 30.0
    private var gameDuration: TimeInterval = 30.0
    private var lastUpdateTime: TimeInterval = 0
    private var lastChompSoundTime: TimeInterval = -999
    private var lastMommySoundTime: TimeInterval = -999
    private let chompSoundCooldown: TimeInterval = 0.15
    private let mommySoundCooldown: TimeInterval = 0.30
    private var pizzaVelocity: CGVector = .zero
    
    // MARK: - Level Configuration
    private let requiredScorePerLevel: Int = 150
    private var levelDuration: TimeInterval {
        return currentLevel == 1 ? 30.0 : 25.0
    }
    
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

    // MARK: - Scoring Constants
    private let bonusRoundPizzaPoints: Int = 5
    private let spicyWingRunScorePenalty: Int = 10
    private let normalPizzaSpeed: CGFloat = 120
    private let bonusRoundPizzaSpeed: CGFloat = 340
    private let bonusRoundDuration: TimeInterval = 15.0

    // MARK: - Pizza Constants
    private static let pizzaImageName = "Pizza"
    private let pizzaSizeDefault: CGFloat = 80
    private let pizzaSizeLevel3: CGFloat = 60
    
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
            return baseSpicyWingRadius
        case 2:
            return 35 // Larger for level 2
        case 3:
            return baseSpicyWingRadius * 3 // 200% bigger than base for level 3
        default:
            return baseSpicyWingRadius
        }
    }
    private let maxSpicyWingHits: Int = 3
    private let baseSpicyWingRadius: CGFloat = 25
    private var spicyWingSpawnTimes: [TimeInterval] = []
    private let spicyWingGracePeriod: TimeInterval = 0.25
    private let wingSpacingMultiplier: CGFloat = 3
    
    private var livesRemaining: Int {
        return maxSpicyWingHits - spicyWingHits
    }
    
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
        hudNode.updateLives(livesRemaining)
        
        // Start looping background music
        SoundManager.shared.startBackgroundMusic()

        // Authenticate with Game Center using this scene's view controller as the presentation context
        if let vc = view.window?.rootViewController {
            GameCenterManager.shared.authenticate(from: vc)
        }

        // Observe IAP state changes so the overlay stays current
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIAPStateChange),
            name: .iapStateDidChange,
            object: nil
        )
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        SoundManager.shared.stopBackgroundMusic()
        NotificationCenter.default.removeObserver(self, name: .iapStateDidChange, object: nil)
    }

    /// Called on the main thread when IAPManager.adsRemoved changes.
    @objc private func handleIAPStateChange() {
        guard gameState == .gameOver || gameState == .levelComplete,
              let overlay = gameOverOverlay else { return }
        // Rebuild the overlay to reflect the new purchase state.
        let isGameOver = gameState == .gameOver
        let customMsg: String? = isGameOver ? nil : (currentLevel == 3 ? "Game Complete!" : "Level \(currentLevel) Complete!")
        let newOverlay = GameOverOverlay(
            size: size,
            finalScore: isGameOver ? runScore : score,
            bestScore: scoreManager.bestScore,
            customMessage: customMsg,
            gcStatus: isGameOver ? GameCenterManager.shared.lastSubmissionMessage : nil,
            showLeaderboardButton: isGameOver
        )
        overlay.removeFromParent()
        gameOverOverlay = newOverlay
        addChild(newOverlay)
    }

    // MARK: - Setup Methods
    private func setupChicken() {
        // Create sprite-based chicken
        chickenNode = ChickenNode()
        chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Scale chicken sprite appropriately
        // Original sprites are 1024x1024, scale to ~200 pixels (visible but not overwhelming)
        chickenNode.setScale(0.20)
        
        addChild(chickenNode)
    }
    
    private func setupHUD() {
        hudNode = HUDNode(size: size)
        addChild(hudNode)
    }

    private func spawnPizza() {
        // Remove existing pizza if any
        pizzaNode?.removeFromParent()
        
        // Create pizza sprite using asset catalog image
        let pizzaSize: CGFloat = currentLevel == 3 ? pizzaSizeLevel3 : pizzaSizeDefault
        let texture = SKTexture(imageNamed: GameScene.pizzaImageName)
        pizzaNode = SKSpriteNode(texture: texture, size: CGSize(width: pizzaSize, height: pizzaSize))
        pizzaNode.name = "pizza"
        
        // Position pizza at random location
        repositionPizza()
        
        addChild(pizzaNode)
        
        // Start continuous movement for level 3
        if currentLevel == 3 {
            initPizzaVelocity()
        }
    }
    
    private func repositionPizza() {
        guard let pizzaNode = pizzaNode else { return }
        
        let minX = edgeMargin
        let maxX = size.width - edgeMargin
        let minY = edgeMargin
        let maxY = size.height - edgeMargin
        
        let chickenRadius = max(chickenNode.frame.width, chickenNode.frame.height) * 0.5
        let pizzaRadius: CGFloat = currentLevel == 3 ? 20 : 30
        let safeDistance = collisionDistance + chickenRadius + pizzaRadius + 10
        
        for _ in 0..<30 {
            let x = CGFloat.random(in: minX...maxX)
            let y = CGFloat.random(in: minY...maxY)
            let candidate = CGPoint(x: x, y: y)
            
            let dx = candidate.x - chickenNode.position.x
            let dy = candidate.y - chickenNode.position.y
            let d = sqrt(dx * dx + dy * dy)
            
            if d > safeDistance {
                pizzaNode.position = candidate
                return
            }
        }
        
        // Fallback: corner farthest from chicken
        pizzaNode.position = CGPoint(x: maxX, y: maxY)
    }
    
    private func spawnSpicyWing() {
        // Remove existing spicy wings
        removeSpicyWing()
        
        // Determine how many wings to spawn
        let wingCount = currentLevel == 3 ? 3 : 1
        
        for _ in 0..<wingCount {
            // Create spicy wing sprite using asset catalog image
            let wingDiameter = spicyWingRadius * 2
            let texture = SKTexture(imageNamed: "SpicyWing")
            let wingNode = SKSpriteNode(texture: texture, size: CGSize(width: wingDiameter, height: wingDiameter))
            wingNode.name = "spicyWing"
            
            spicyWingNodes.append(wingNode)
            addChild(wingNode)
            spicyWingSpawnTimes.append(lastUpdateTime)
        }
        
        // Position all wings safely away from chicken and each other
        repositionAllSpicyWings()
    }
    
    private func repositionAllSpicyWings() {
        let minX = edgeMargin
        let maxX = size.width - edgeMargin
        let minY = edgeMargin
        let maxY = size.height - edgeMargin
        let chickenRadius = max(chickenNode.frame.width, chickenNode.frame.height) * 0.5
        let wingRadius = spicyWingRadius
        let safeDistance = collisionDistance + chickenRadius + wingRadius + 10
        
        var placedPositions: [CGPoint] = []
        
        for wingNode in spicyWingNodes {
            var placed = false
            for _ in 0..<30 {
                let x = CGFloat.random(in: minX...maxX)
                let y = CGFloat.random(in: minY...maxY)
                let candidate = CGPoint(x: x, y: y)
                
                let dx = candidate.x - chickenNode.position.x
                let dy = candidate.y - chickenNode.position.y
                let d = sqrt(dx * dx + dy * dy)
                
                // Check distance from chicken
                guard d > safeDistance else { continue }
                
                // Check distance from already-placed wings
                let tooCloseToOther = placedPositions.contains { other in
                    let odx = candidate.x - other.x
                    let ody = candidate.y - other.y
                    return sqrt(odx * odx + ody * ody) < wingRadius * wingSpacingMultiplier
                }
                guard !tooCloseToOther else { continue }
                
                wingNode.position = candidate
                placedPositions.append(candidate)
                placed = true
                break
            }
            if !placed {
                // Fallback: corner farthest from chicken
                wingNode.position = CGPoint(x: maxX, y: maxY)
                placedPositions.append(wingNode.position)
            }
        }
    }
    
    private func removeSpicyWing() {
        spicyWingNodes.forEach { $0.removeFromParent() }
        spicyWingNodes.removeAll()
        spicyWingSpawnTimes.removeAll()
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
            // Check if the leaderboard button was tapped
            let tappedNodes = nodes(at: location)
            if tappedNodes.contains(where: { $0.name == GameOverOverlay.leaderboardButtonName }) {
                if let vc = view?.window?.rootViewController {
                    GameCenterManager.shared.showLeaderboard(from: vc)
                }
            } else if tappedNodes.contains(where: { $0.name == GameOverOverlay.removeAdsButtonName }) {
                IAPManager.shared.purchaseRemoveAds()
            } else if tappedNodes.contains(where: { $0.name == GameOverOverlay.restorePurchasesButtonName }) {
                Task {
                    await IAPManager.shared.restorePurchases()
                }
            } else {
                restartGame()
            }
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
        spicyWingHits = 0
        
        // Set time based on level
        gameDuration = levelDuration
        timeRemaining = gameDuration
        
        lastUpdateTime = 0
        hudNode.updateTime(Int(ceil(timeRemaining)))
        hudNode.updateLevel(currentLevel)
        hudNode.updateLives(livesRemaining)
        
        // Start continuous pizza movement for level 3
        if currentLevel == 3 {
            initPizzaVelocity()
        }

        // Preload rewarded ad now that the game is starting
        AdManager.shared.loadAd()
    }
    
    private func checkLevelComplete() {
        guard gameState == .playing, !isBonusRound else { return }
        
        if score >= requiredScorePerLevel {
            levelComplete()
        }
    }
    
    private func levelComplete() {
        awardLevelTimeBonus()
        gameState = .levelComplete
        targetPosition = nil
        
        // Play level win sound
        if let levelWinSound { run(levelWinSound) }
        
        // Show level complete overlay
        let messageText = currentLevel == 3 ? "Level 3 Complete!" : "Level \(currentLevel) Complete!"
        let overlay = GameOverOverlay(size: size, finalScore: score, bestScore: scoreManager.bestScore, customMessage: messageText)
        gameOverOverlay = overlay
        addChild(overlay)
    }
    
    private func awardLevelTimeBonus() {
        let multiplier: Int
        switch currentLevel {
        case 1: multiplier = 1
        case 2: multiplier = 2
        case 3: multiplier = 3
        default: multiplier = 1
        }
        let bonus = max(0, Int(ceil(timeRemaining))) * multiplier
        runScore += bonus
        hudNode.updateRunScore(runScore)
    }
    
    private func advanceToNextLevel() {
        // Remove overlay
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        
        if currentLevel >= 3 {
            // Level 3 cleared – enter bonus round instead of ending immediately
            startBonusRound()
        } else {
            // Advance to next level
            currentLevel += 1
            
            // Reset state for new level
            gameState = .ready
            score = 0
            spicyWingHits = 0
            
            // Set time based on level
            gameDuration = levelDuration
            timeRemaining = gameDuration
            
            hudNode.updateScore(0)
            hudNode.updateTime(Int(ceil(timeRemaining)))
            hudNode.updateLevel(currentLevel)
            hudNode.updateLives(livesRemaining)
            
            // Reset click tracking
            clickTimestamps.removeAll()
            
            // Reset chicken position and visibility
            chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
            chickenNode.alpha = 1.0
            chickenNode.setScale(0.20)
            
            // Remove any spicy wing
            removeSpicyWing()
            
            // Respawn pizza
            spawnPizza()
        }
    }
    
    private func startBonusRound() {
        isBonusRound = true
        gameState = .playing
        
        // Clear target and enemies
        targetPosition = nil
        removeSpicyWing()
        
        // Reset per-level score (bonus round has no progression gate; only runScore matters)
        score = 0
        
        // Set bonus round timer
        timeRemaining = bonusRoundDuration
        gameDuration = bonusRoundDuration
        lastUpdateTime = 0
        
        hudNode.updateTime(Int(bonusRoundDuration))
        hudNode.updateLevelText("BONUS!")
        hudNode.updateRunScore(runScore)
        
        // Reset click tracking
        clickTimestamps.removeAll()
        
        // Reset chicken position and visibility
        chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        chickenNode.alpha = 1.0
        chickenNode.setScale(0.20)
        
        // Respawn pizza – initPizzaVelocity will use bonus speed since isBonusRound is true
        spawnPizza()
        
        // Show brief bonus round announcement
        let bonusLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bonusLabel.text = "BONUS ROUND!"
        bonusLabel.fontSize = 48
        bonusLabel.fontColor = .yellow
        bonusLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        bonusLabel.zPosition = 150
        addChild(bonusLabel)
        
        let subLabel = SKLabelNode(fontNamed: "Helvetica")
        subLabel.text = "15 SECONDS - PIZZA FRENZY"
        subLabel.fontSize = 24
        subLabel.fontColor = .white
        subLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        subLabel.zPosition = 150
        addChild(subLabel)
        
        let fadeSeq = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        bonusLabel.run(fadeSeq)
        subLabel.run(fadeSeq)
    }
    
    private func endGame() {
        gameState = .gameOver
        targetPosition = nil
        isBonusRound = false

        // Update best score using total run score
        scoreManager.checkAndUpdateBestScore(runScore)
        hudNode.updateBest(scoreManager.bestScore)

        // Submit total run score to Game Center leaderboard
        GameCenterManager.shared.submitScore(runScore)

        // Show rewarded ad if ads have not been removed
        if !IAPManager.shared.adsRemoved,
           let sceneView = self.view,
           let vc = sceneView.window?.rootViewController {
            AdManager.shared.showAd(from: vc) {
                print("reward granted")
            }
        }

        // Show game over overlay with total run score, Game Center status, and leaderboard button
        let overlay = GameOverOverlay(
            size: size,
            finalScore: runScore,
            bestScore: scoreManager.bestScore,
            gcStatus: GameCenterManager.shared.lastSubmissionMessage,
            showLeaderboardButton: true
        )
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
        runScore = 0
        isBonusRound = false
        spicyWingHits = 0
        
        gameDuration = 30.0
        timeRemaining = gameDuration
        
        hudNode.updateScore(0)
        hudNode.updateRunScore(0)
        hudNode.updateTime(Int(ceil(timeRemaining)))
        hudNode.updateLevel(currentLevel)
        hudNode.updateLives(livesRemaining)
        
        // Reset click tracking
        clickTimestamps.removeAll()
        
        // Reset chicken position and visibility
        chickenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        chickenNode.alpha = 1.0
        chickenNode.setScale(0.20)
        
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
        
        // Continuously move pizza in level 3
        if currentLevel == 3 {
            updatePizzaMovement(deltaTime: deltaTime)
        }
    }
    
    private func initPizzaVelocity() {
        let speed: CGFloat = isBonusRound ? bonusRoundPizzaSpeed : normalPizzaSpeed
        let angle = CGFloat.random(in: 0...(2 * .pi))
        pizzaVelocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }
    
    private func updatePizzaMovement(deltaTime: TimeInterval) {
        guard let pizza = pizzaNode else { return }
        let minX = edgeMargin
        let maxX = size.width - edgeMargin
        let minY = edgeMargin
        let maxY = size.height - edgeMargin
        
        var pos = pizza.position
        pos.x += pizzaVelocity.dx * CGFloat(deltaTime)
        pos.y += pizzaVelocity.dy * CGFloat(deltaTime)
        
        // Bounce off edges
        if pos.x < minX { pos.x = minX; pizzaVelocity.dx = abs(pizzaVelocity.dx) }
        if pos.x > maxX { pos.x = maxX; pizzaVelocity.dx = -abs(pizzaVelocity.dx) }
        if pos.y < minY { pos.y = minY; pizzaVelocity.dy = abs(pizzaVelocity.dy) }
        if pos.y > maxY { pos.y = maxY; pizzaVelocity.dy = -abs(pizzaVelocity.dy) }
        
        pizza.position = pos
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
    
    private func playChompSoundIfReady() {
        guard lastUpdateTime - lastChompSoundTime >= chompSoundCooldown else { return }
        lastChompSoundTime = lastUpdateTime
        if let chompSound { run(chompSound) }
    }

    private func playMommySoundIfReady() {
        guard lastUpdateTime - lastMommySoundTime >= mommySoundCooldown else { return }
        lastMommySoundTime = lastUpdateTime
        if let mommySound { run(mommySound) }
    }

    private func handlePizzaEat() {
        if isBonusRound {
            // Bonus round: award extra run-score points; do not advance level progress
            runScore += bonusRoundPizzaPoints
            hudNode.updateRunScore(runScore)
        } else {
            // Normal play: advance per-level progress and total run score
            score += 1
            runScore += 1
            hudNode.updateRunScore(runScore)
        }
        
        // Play bite sound with cooldown
        playChompSoundIfReady()
        
        // Play chicken bite animation
        chickenNode.playMunch()
        
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
        for (index, wing) in spicyWingNodes.enumerated() {
            let spawnTime = index < spicyWingSpawnTimes.count ? spicyWingSpawnTimes[index] : 0
            if lastUpdateTime - spawnTime < spicyWingGracePeriod { continue }
            
            let dx = chickenNode.position.x - wing.position.x
            let dy = chickenNode.position.y - wing.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < collisionDistance + spicyWingRadius - baseSpicyWingRadius {
                handleSpicyWingHit()
                return
            }
        }
    }
    
    private func handleSpicyWingHit() {
        // Increment hit counter
        spicyWingHits += 1
        hudNode.updateLives(livesRemaining)
        
        // Penalise total run score for sloppy play
        runScore = max(0, runScore - spicyWingRunScorePenalty)
        hudNode.updateRunScore(runScore)
        
        // Play mommy sound with cooldown
        playMommySoundIfReady()
        
        // Remove the spicy wing
        removeSpicyWing()
        
        // Shake chicken animation to show hit
        let shakeLeft = SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        let shakeRight = SKAction.moveBy(x: 20, y: 0, duration: 0.05)
        let shakeBack = SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        let shakeSequence = SKAction.sequence([shakeLeft, shakeRight, shakeBack])
        chickenNode.run(shakeSequence)
        
        // Flash the wing-hit graphic on the chicken for 2 seconds
        chickenNode.playWingHitFlash()
        
        // Check if reached max hits
        if spicyWingHits >= maxSpicyWingHits {
            explodeChicken()
        }
    }
    
    private func explodeChicken() {
        // Play explosion sound
        if let explodeSound { run(explodeSound) }
        
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
