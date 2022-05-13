import SpriteKit

class GameViewController: NSViewController {
    let gameController = GameController()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let skView = self.view as! SKView? {
            #if DEBUG
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsPhysics = false
            #endif
            
            gameController.view = skView
            gameController.startControl()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.aspectRatio = CGSize(width: 1200, height: 800)
    }
}
