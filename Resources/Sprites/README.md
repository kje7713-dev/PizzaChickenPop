# Sprites

This directory contains sprite images for the game.

## Chicken Sprites (✅ Integrated)

The chicken sprites are located in `Chicken/` subdirectory and are fully integrated into the game:

- `IMG_3731.PNG` - Idle chicken sprite (1024x1024)
- `IMG_3732.PNG` - Bite animation frame 1
- `IMG_3733.PNG` - Bite animation frame 2
- `IMG_3734.PNG` - Bite animation frame 3

These sprites are loaded and used by `Sources/Game/ChickenNode.swift`, which displays the chicken with idle and bite animations.

## Pizza Sprites (Not Yet Implemented)

The pizza currently uses a procedural `SKShapeNode` circle. To add a pizza sprite:

1. Add a `pizza.png` file to this directory
2. Update `Sources/Game/GameScene.swift` to load and use the sprite instead of `SKShapeNode`
