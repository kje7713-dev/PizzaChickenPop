import UIKit
import SpriteKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create the main window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create and configure the view controller
        let viewController = GameViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
}

class GameViewController: UIViewController {
    
    private var skView: SKView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the SpriteKit view
        if let view = self.view as? SKView {
            skView = view
            
            // Configure view settings
            view.ignoresSiblingOrder = true
            #if DEBUG
            view.showsFPS = true
            view.showsNodeCount = true
            #endif
            
            // Present the scene with proper sizing
            presentGameScene()
        }
    }
    
    override func loadView() {
        self.view = SKView(frame: UIScreen.main.bounds)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Update scene size on orientation change
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateSceneSize(to: size)
        }, completion: nil)
    }
    
    private func presentGameScene() {
        guard let view = skView else { return }
        
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        
        view.presentScene(scene)
    }
    
    private func updateSceneSize(to size: CGSize) {
        guard let view = skView, let scene = view.scene else { return }
        scene.size = size
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
