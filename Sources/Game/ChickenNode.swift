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
    /// Loads a texture from the bundled resources with graceful fallback
    ///
    /// Resource lookup strategy:
    /// 1. Try Bundle.main with subdirectory path (standard XcodeGen resource bundling)
    /// 2. Try Bundle.main without subdirectory (alternative bundling configuration)
    /// 3. If SwiftPM module bundle is available, try it as well
    /// 4. If all attempts fail, return a safe fallback texture instead of crashing
    ///
    /// - Parameter baseName: The base name of the image file (e.g., "IMG_3731")
    /// - Returns: The loaded SKTexture, or a fallback colored texture if loading fails
    private static func texture(named baseName: String) -> SKTexture {
        let subdirectory = "Resources/Sprites/Chicken"
        let ext = "PNG"
        
        // Try Bundle.main with subdirectory first (standard XcodeGen configuration)
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: subdirectory),
           let image = UIImage(contentsOfFile: url.path) {
            return SKTexture(image: image)
        }
        
        // Try Bundle.main without subdirectory as fallback
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext),
           let image = UIImage(contentsOfFile: url.path) {
            return SKTexture(image: image)
        }
        
        // Try SwiftPM module bundle if available (for package-based builds)
        #if canImport(Foundation)
        // Use Bundle(for:) to get the bundle containing this class, avoiding hardcoded identifiers
        let classBundle = Bundle(for: ChickenNode.self)
        if let url = classBundle.url(forResource: baseName, withExtension: ext, subdirectory: subdirectory),
           let image = UIImage(contentsOfFile: url.path) {
            return SKTexture(image: image)
        }
        #endif
        
        // Graceful fallback: return a colored placeholder texture instead of crashing
        // This ensures the app launches even if texture resources are missing
        print("""
            ⚠️ Warning: Failed to load texture '\(baseName).\(ext)'.
            Attempted locations:
            - Bundle.main: \(subdirectory)/\(baseName).\(ext)
            - Bundle.main root: \(baseName).\(ext)
            - Class bundle: \(subdirectory)/\(baseName).\(ext)
            
            Using fallback placeholder texture. Please ensure the Resources directory is properly bundled.
            """)
        
        // Create a simple colored rectangle as fallback (orange/yellow chicken color)
        return SKTexture(image: Self.createFallbackImage())
    }
    
    /// Creates a fallback placeholder image when texture loading fails
    /// - Returns: A UIImage with a solid color representing a missing texture
    private static func createFallbackImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Use a chicken-like orange/yellow color for the fallback
            UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add a simple border to make it clear this is a placeholder
            UIColor.black.setStroke()
            context.cgContext.setLineWidth(4)
            context.stroke(CGRect(origin: .zero, size: size))
        }
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
