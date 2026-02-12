# Getting Started with PizzaChicken

This repository now has a baseline structure for the PizzaChicken iOS game.

## What's Been Created

✅ **Directory Structure** - Following the specification in README_PizzaChicken_SpriteKit_GameCenter.md

✅ **Swift Source Files** - Starter implementations for:
- GameScene.swift - Main gameplay scene with touch handling and explosion logic
- GameState.swift - State management for game flow
- ScoreManager.swift - Local high score tracking using UserDefaults
- GameCenterManager.swift - Game Center authentication and leaderboard integration
- MenuView.swift - SwiftUI menu view (optional)

✅ **Resource Directories** - With documentation for:
- Sprites (chicken and pizza images)
- Particles (explosion effects)
- Audio (sound effects)

✅ **Project Files**:
- .gitignore - Xcode-specific ignore rules
- LICENSE - MIT license

## Next Steps

### 1. Create the Xcode Project

Open Xcode and create a new project:
1. File → New → Project
2. Choose "iOS" → "Game" template
3. Product Name: "PizzaChicken"
4. Game Technology: "SpriteKit"
5. Save location: Inside the `PizzaChicken/` directory

### 2. Add Source Files to Project

Drag the `Sources/` and `Resources/` folders into your Xcode project.

### 3. Add Graphics and Audio

Create or obtain:
- Sprite images (chicken in various states, pizza)
- Sound effects (chomp, pop)
- Particle effects (feathers, crumbs)

### 4. Configure Game Center

Follow the instructions in README_PizzaChicken_SpriteKit_GameCenter.md:
- Set up leaderboard in App Store Connect
- Enable Game Center capability in Xcode
- Use leaderboard ID: `pizza_chicken_highscore`

### 5. Build and Test

- Build the project in Xcode
- Test on a real device (required for Game Center)
- Use TestFlight for beta testing

## Code Overview

### GameScene.swift
The main gameplay happens here. Key areas to implement:
- Setup chicken and pizza sprites
- Handle tap detection on pizza
- Play animations and sounds
- Trigger explosion when threshold is reached

### ScoreManager.swift
Handles local score persistence:
- Saves high score to UserDefaults
- Records the date of high scores
- Integrates with GameCenterManager for leaderboard submission

### GameCenterManager.swift
Manages Game Center integration:
- Authenticates the player
- Submits scores to leaderboard
- Shows leaderboard UI

### GameState.swift
Tracks game state transitions:
- menu → playing → aboutToPop → exploding → gameOver

## Architecture

The code follows a simple MVC-style architecture:
- **Model**: GameState, ScoreManager
- **View**: MenuView (SwiftUI), GameScene (SpriteKit)
- **Controller**: GameScene (also acts as controller)

## Notes

- All Swift files have TODO comments marking areas that need implementation
- The code is structured to match the specifications in the README
- Game Center features require a real iOS device for testing
- Make sure to update the leaderboard ID if you use a different one in App Store Connect
