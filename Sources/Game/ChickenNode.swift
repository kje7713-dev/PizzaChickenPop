import SpriteKit
import UIKit

/// Sprite-based chicken node that displays idle and bite animations
final class ChickenNode: SKSpriteNode {
    
    // MARK: - Textures
    private let idleTexture: SKTexture
    private let biteTextures: [SKTexture]
    
    // MARK: - Animation State
    private var isMunching: Bool = false
    
    // MARK: - Initialization
    init() {
        // Load textures
        idleTexture = Self.texture(named: "IMG_3731")
        biteTextures = [
            Self.texture(named: "IMG_3732"),
            Self.texture(named: "IMG_3733"),
            Self.texture(named: "IMG_3734")
        ]
        
        // Initialize with idle texture
        super.init(texture: idleTexture, color: .clear, size: idleTexture.size())
        
        // Set initial state
        self.name = "chicken"
        setIdle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Texture Loading
    /// Loads a texture from the bundled resources
    /// - Parameter baseName: The base name of the image file (e.g., "IMG_3731")
    /// - Returns: The loaded SKTexture
    private static func texture(named baseName: String) -> SKTexture {
        let subdirectory = "Resources/Sprites/Chicken"
        let ext = "PNG"
        
        // Try Bundle.module first (for SwiftPM resources)
        #if canImport(Foundation)
        if let moduleBundle = Bundle(identifier: "com.Savagebydesign.PizzaChicken"),
           let url = moduleBundle.url(forResource: baseName, withExtension: ext, subdirectory: subdirectory),
           let image = UIImage(contentsOfFile: url.path) {
            return SKTexture(image: image)
        }
        #endif
        
        // Fallback to Bundle.main
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: subdirectory),
           let image = UIImage(contentsOfFile: url.path) {
            return SKTexture(image: image)
        }
        
        // Try without subdirectory as a last resort
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext),
           let image = UIImage(contentsOfFile: url.path) {
            return SKTexture(image: image)
        }
        
        // If all attempts fail, provide a clear error message
        fatalError("""
            Failed to load texture '\(baseName).\(ext)'.
            Attempted locations:
            - Bundle.module: \(subdirectory)/\(baseName).\(ext)
            - Bundle.main: \(subdirectory)/\(baseName).\(ext)
            - Bundle.main root: \(baseName).\(ext)
            
            Please ensure the Resources directory is properly bundled in the Xcode project.
            """)
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
