import UIKit
import SpriteKit

class GameViewController: UIViewController {
    let gameController = DemoController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let skView = self.view as! SKView? {
            #if DEBUG
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsPhysics = false
            #endif
            
            gameController.skView = skView
            gameController.startControl()
        }
    }
}
