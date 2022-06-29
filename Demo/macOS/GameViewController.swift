import SpriteKit

class GameViewController: NSViewController, NSWindowDelegate {
    private var gameController = DemoController()
    

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
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.delegate = self
        view.window?.acceptsMouseMovedEvents = true
    }
    
    func windowDidResize(_ notification: Notification) {
        gameController.windowDidResize()
    }
    
    override func scrollWheel(with event: NSEvent) {
        if let skView = self.view as! SKView? {
            skView.scene?.scrollWheel(with: event)
        }
    }
}
