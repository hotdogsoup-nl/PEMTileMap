import Foundation
import SpriteKit
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

public class DemoController: NSObject {
    weak public var skView: SKView!
    private var currentScene : DemoScene?
    
    // MARK: - Life cycle
    
    override public init() {
        super.init()
    }

    public init(view: SKView) {
        super.init()
        skView = view
    }
    
    // MARK: - Control
    
    public func startControl() {
        loadGameScene()
    }
    
    private func loadGameScene() {
        DispatchQueue.main.async { [unowned self] in
            
            let nextScene = DemoScene(view: skView, size: skView.bounds.size)
            nextScene.scaleMode = .aspectFill
            
            currentScene = nextScene

            let transition = SKTransition.fade(withDuration: 0.3)
            skView.presentScene(nextScene, transition: transition)
        }
    }
    
    // MARK: - View
    
    #if os(macOS)

    public func windowDidResize() {
        currentScene?.didChangeSize()
    }

    #endif
}
