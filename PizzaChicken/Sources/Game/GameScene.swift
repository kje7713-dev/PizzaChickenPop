//
//  GameScene.swift
//  PizzaChicken
//
//  Main gameplay scene where the chicken eats pizza and eventually explodes
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    private var chickenSprite: SKSpriteNode?
    private var pizzaSprite: SKSpriteNode?
    private var runScore: Int = 0
    private var biteThreshold: Int = 10 // Number of bites before explosion
    private var currentBites: Int = 0
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupScene()
        setupGameObjects()
    }
    
    private func setupScene() {
        backgroundColor = .white
    }
    
    private func setupGameObjects() {
        // TODO: Initialize chicken and pizza sprites
        // TODO: Position sprites on screen
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if pizza was tapped
        handleBite(at: location)
    }
    
    // MARK: - Game Logic
    private func handleBite(at position: CGPoint) {
        // TODO: Check if tap is on pizza
        // TODO: Increment score
        // TODO: Play chomp sound
        // TODO: Animate bite
        currentBites += 1
        runScore += 1
        
        if currentBites >= biteThreshold {
            explodeChicken()
        }
    }
    
    private func explodeChicken() {
        // TODO: Play explosion sound
        // TODO: Spawn particle effects (feathers + crumbs)
        // TODO: Screen shake effect
        // TODO: Submit score to ScoreManager
        // TODO: Reset game state
        
        print("Chicken exploded! Final score: \(runScore)")
        
        // Reset for next round
        currentBites = 0
        runScore = 0
    }
}
