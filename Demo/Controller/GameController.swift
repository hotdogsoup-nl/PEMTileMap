import Foundation
import SpriteKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif

public class GameController: NSObject, GameSceneDelegate {
    weak public var view: SKView?
    private var currentScene : GameScene?
    
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
            currentScene?.gameSceneDelegate = nil
            
            let nextScene = GameScene(size: view!.bounds.size)
            nextScene.scaleMode = .aspectFill
            nextScene.gameSceneDelegate = self
            
            currentScene = nextScene

            let transition = SKTransition.doorsOpenVertical(withDuration: 0.3)
            view!.presentScene(nextScene, transition: transition)

//            if let cameraNode = nextScene.camera, let tilemap = nextScene.tilemapJS {
//                self.fitSceneToView(tilemap: tilemap, cameraNode: cameraNode, newSize: self.view!.bounds.size)
//            }
        }
    }
    
    // MARK: - GameSceneDelegate
    
    func gameOver() {
    }
    
    func levelCompleted() {
    }
    
    // MARK: - View
    
    private func fitSceneToView(tilemap : JSTileMap, cameraNode: SKCameraNode, newSize: CGSize, portrait: Bool = false, transition: TimeInterval = 0) {
        if (!FIT_SCENE_TO_VIEW) {
            return
        }
                
        let mapsize = tilemap.mapSize
        let maxWidthScale = newSize.width / mapsize.width
        let maxHeightScale = newSize.height / mapsize.height
        var contentScale : CGFloat = 1.0
        
        if portrait {
            contentScale = (maxWidthScale < maxHeightScale) ? maxWidthScale : maxHeightScale
        } else {
            contentScale = (maxWidthScale > maxHeightScale) ? maxWidthScale : maxHeightScale
        }

        cameraNode.setScale(contentScale)
    }
}
