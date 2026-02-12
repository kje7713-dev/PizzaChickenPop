//
//  GameState.swift
//  PizzaChicken
//
//  Manages the current game state and transitions
//

import Foundation

enum GameState {
    case menu
    case playing
    case aboutToPop  // Chicken is full and about to explode
    case exploding
    case gameOver
}

class GameStateManager {
    
    // MARK: - Properties
    static let shared = GameStateManager()
    
    private(set) var currentState: GameState = .menu
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - State Management
    func transition(to newState: GameState) {
        let previousState = currentState
        currentState = newState
        
        print("Game state transition: \(previousState) -> \(newState)")
        
        // Handle state-specific logic
        switch newState {
        case .menu:
            break
        case .playing:
            break
        case .aboutToPop:
            // Trigger warning animations/sounds
            break
        case .exploding:
            break
        case .gameOver:
            break
        }
    }
    
    func reset() {
        transition(to: .menu)
    }
}
