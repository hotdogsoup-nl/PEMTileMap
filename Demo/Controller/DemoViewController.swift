import Foundation
import SpriteKit
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

public class DemoViewController: NSObject {
    weak public var view: SKView?
    private var currentScene : DemoScene?
    
    // MARK: - Life cycle
    
    override public init() {
        super.init()
    }

    public init(view: SKView) {
        super.init()
        self.view = view
    }
    
    // MARK: - Control
    
    public func startControl() {
        loadGameScene()
    }
    
    private func loadGameScene() {
        DispatchQueue.main.async { [unowned self] in
            
            let nextScene = DemoScene(size: view!.bounds.size)
            nextScene.scaleMode = .aspectFill
            
            currentScene = nextScene

            let transition = SKTransition.fade(withDuration: 0.3)
            view!.presentScene(nextScene, transition: transition)
        }
    }
}
