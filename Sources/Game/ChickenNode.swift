import SpriteKit
import UIKit

/// Sprite-based chicken node that displays idle and bite animations
final class ChickenNode: SKSpriteNode {
    
    // MARK: - Textures
    private let idleTexture: SKTexture
    private let biteTextures: [SKTexture]
    
    // MARK: - Animation State
    private var isMunching: Bool = false
    
    // MARK: - Constants
    /// Expected pixel dimensions of each PNG sprite file
    private static let spriteTextureSize: CGFloat = 1024
    
    // MARK: - Initialization
    init() {
        // Load textures
        idleTexture = Self.texture(named: "IMG_3731")
        biteTextures = [
            Self.texture(named: "IMG_3732"),
            Self.texture(named: "IMG_3733"),
            Self.texture(named: "IMG_3734")
        ]
        
        // Initialize with a fixed size matching the actual PNG dimensions (1024x1024).
        let textureSize = CGSize(width: Self.spriteTextureSize, height: Self.spriteTextureSize)
        super.init(texture: idleTexture, color: .clear, size: textureSize)
        
        // Set initial state
        self.name = "chicken"
        self.zPosition = 1
        setIdle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Texture Loading
    /// Loads a texture from the bundled resources using deterministic Bundle.main URL resolution.
    /// Tries multiple possible subdirectory paths to accommodate different bundle layouts.
    ///
    /// - Parameter baseName: The base name of the image file (e.g., "IMG_3731")
    /// - Returns: The loaded SKTexture, or a colored placeholder if the file cannot be found.
    private static func texture(named baseName: String) -> SKTexture {
        let candidates: [String?] = [
            "Sprites/Chicken",
            "Resources/Sprites/Chicken",
            nil
        ]

        for subdirectory in candidates {
            guard let url = Bundle.main.url(
                forResource: baseName,
                withExtension: "PNG",
                subdirectory: subdirectory
            ) else { continue }

            guard let image = UIImage(contentsOfFile: url.path) else { continue }

            return SKTexture(image: image)
        }

        print("Warning: Missing chicken texture \(baseName).PNG – using placeholder")
        return SKTexture.placeholder(color: .systemPink, size: CGSize(width: spriteTextureSize, height: spriteTextureSize))
    }
    
    // MARK: - Animation Methods
    /// Sets the chicken to idle state
    func setIdle() {
        self.texture = idleTexture
        isMunching = false
    }
    
    /// Plays the bite/munch animation
    func playMunch() {
        // Don't start a new animation if already munching
        guard !isMunching else { return }
        
        isMunching = true
        
        // Create bite animation sequence: 3732 → 3733 → 3734 → 3733 → 3732 → 3731 (idle)
        let timePerFrame: TimeInterval = 0.08
        
        var animationTextures: [SKTexture] = []
        animationTextures.append(biteTextures[0]) // IMG_3732
        animationTextures.append(biteTextures[1]) // IMG_3733
        animationTextures.append(biteTextures[2]) // IMG_3734
        animationTextures.append(biteTextures[1]) // IMG_3733
        animationTextures.append(biteTextures[0]) // IMG_3732
        animationTextures.append(idleTexture)     // IMG_3731 (idle)
        
        let animateAction = SKAction.animate(with: animationTextures, timePerFrame: timePerFrame)
        let resetState = SKAction.run { [weak self] in
            self?.isMunching = false
        }
        
        let sequence = SKAction.sequence([animateAction, resetState])
        self.run(sequence)
    }
}

// MARK: - SKTexture placeholder helper
private extension SKTexture {
    /// Returns a solid-colored placeholder texture of the given size.
    static func placeholder(color: UIColor, size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }
}
