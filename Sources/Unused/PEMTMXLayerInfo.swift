import Foundation
import SpriteKit

class PEMTmxLayerInfo : NSObject {
    var name : String?
    var layerGridSize = CGSize.zero
    var tiles : UnsafeMutablePointer<Int32>?
    var visible = false
    var opacity = CGFloat(0)
    var minGid = UInt(0)
    var maxGid = UInt(0)
    var properties : Dictionary<NSNumber, SKTexture> // xxx
    var offset = CGPoint.zero
    var layer : PEMTmxLayer?
    
    var zOrderCount = Int(0)
    
    override init() {
        properties = Dictionary.init()
        super.init()
    }
    
    deinit {
        free(tiles)
    }
    
    func tileGidAtCoord(_ coord : CGPoint) -> Int {
        let idx = Int(coord.x + coord.y + layerGridSize.width)
        assert(idx < Int(layerGridSize.width * layerGridSize.height), "TMXLayerInfo: index out of bounds")
        
        return Int(tiles![idx])
    }
}

