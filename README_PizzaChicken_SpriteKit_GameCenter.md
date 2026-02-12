# Pizza Chicken (SpriteKit) – Game Center Leaderboard (iOS)

A tiny iOS tap game concept:
**The chicken eats pizza. Each bite increases “fullness.” Eventually the chicken explodes.**
Score is recorded locally and (optionally) submitted to **Game Center Leaderboards**.

This repo is intended to be a clean, native iOS implementation using:
- **Swift**
- **SpriteKit**
- **Xcode**
- **TestFlight** (distribution/testing)
- **Game Center** (leaderboards)

---

## Game Concept

### Core Loop
1. Player taps or double-taps the pizza.
2. Each successful “bite”:
   - increments score (bites, pizzas eaten, or combo)
   - plays a chomp sound + small animation
3. Once a threshold is reached:
   - chicken enters “about to pop” state (shake/puff)
   - chicken **explodes** (particles: feathers + crumbs)
   - run ends, score is finalized, and game resets

### Scoring (recommended)
- `runScore` increments each bite (or each pizza completed)
- On explosion:
  - update local high score if `runScore` is higher
  - submit `runScore` to Game Center leaderboard (if enabled/authenticated)

---

## Tech Stack

### Why SpriteKit
SpriteKit is Apple’s native 2D game framework. It’s ideal for:
- 2D sprites (chicken/pizza)
- scaling/animations (pizza grows, chicken puffs)
- touch input
- particle effects (explosion)
- simple physics if needed

### Components
- `GameScene` (SpriteKit scene): main gameplay
- `SKSpriteNode`: chicken, pizza
- `touchesBegan` handling: tap/double-tap bites
- `explodeChicken()`:
  - play sound
  - spawn particles
  - screen shake
  - reset game state
- `ScoreManager`:
  - local high score + date (UserDefaults)
  - optional Game Center score submit

---

## Local Score + Date Recording (UserDefaults)

Record:
- `highScore` (Int)
- `highScoreDate` (timestamp Double)

Suggested keys:
- `highScore`
- `highScoreDate`

When a run ends (chicken explodes):
1. Compare `runScore` to `highScore`
2. If higher:
   - update `highScore = runScore`
   - update `highScoreDate = now`

---

## Game Center Leaderboard Setup

Game Center lets Apple host your leaderboard so you don’t run a server.

### 1) App Store Connect: Create the leaderboard
1. App Store Connect → **Your App**
2. **Game Center** → **Leaderboards** → **Add Leaderboard**
3. Create a Leaderboard ID (use a stable string you’ll keep forever)

Recommended ID:
- `pizza_chicken_highscore`

> Important: the **Leaderboard ID** must match exactly what you use in code.

### 2) Xcode: Enable Game Center capability
1. Xcode → Target → **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Game Center**

### 3) Authenticate the player
You must authenticate before submitting scores or showing leaderboards.

Typical flow:
- On app launch / scene load:
  - call Game Center auth
  - if Apple presents login UI, show it

### 4) Submit score on run end
When the chicken explodes, submit `runScore` to the leaderboard ID.

### 5) Show leaderboard UI
Present `GKGameCenterViewController` and open the leaderboard view.

---

## Common Gotchas

- **Signed into Game Center?** Device must be logged into Game Center.
- **Leaderboard ID mismatch:** One character off = no scores.
- **Propagation/review weirdness:** Some Game Center features can behave inconsistently until the app has been reviewed at least once.
- **TestFlight vs local:** Always test leaderboard submission on a real device (not simulator).

---

## Suggested Project Structure

```
PizzaChicken/
  PizzaChicken.xcodeproj
  Sources/
    Game/
      GameScene.swift
      GameState.swift
    Services/
      ScoreManager.swift
      GameCenterManager.swift
    UI/
      MenuView.swift (optional)
  Resources/
    Sprites/
      chicken_normal.png
      chicken_stuffed.png
      chicken_about_to_pop.png
      pizza.png
    Particles/
      FeatherExplosion.sks
      CrumbBurst.sks
    Audio/
      chomp.wav
      pop.wav
```

---

## Implementation Notes

### Double-tap vs fast taps
You can interpret “double-clicking pizzas” as:
- true double-tap detection (tap-count within a time window), or
- just rapid taps that count as bites

For a kid game, **rapid taps** is often more fun and less fussy.

### Explosion (App Store-friendly)
Keep it cartoony:
- feathers + crumbs particles
- screen shake
- comedic sound
- no gore/body horror

---

## Roadmap (Optional “nice-to-haves”)
- Difficulty ramp (threshold lowers or bite value increases over time)
- Combo meter (fast bites increase score multiplier)
- Unlockables (new chicken skins, pizza toppings, goofy hats)
- Game Center Achievements (first explosion, 100 bites, etc.)
- iCloud score sync (if you want cross-device local score)

---

## Requirements
- macOS with **Xcode** installed
- iOS device recommended for Game Center testing
- Apple Developer account (for TestFlight / App Store Connect / Game Center configuration)

---

## License
Pick one (MIT is typical) and add a `LICENSE` file.
