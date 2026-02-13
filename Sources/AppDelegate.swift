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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the SpriteKit view
        if let view = self.view as? SKView {
            // Create and configure the scene
            let scene = GameScene()
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view.presentScene(scene)
            
            // Configure view settings
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    override func loadView() {
        self.view = SKView(frame: UIScreen.main.bounds)
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
