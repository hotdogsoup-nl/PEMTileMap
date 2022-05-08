import Foundation
import SpriteKit

class PEMTmxImageLayer : NSObject {
    var name : String?
    var properties : Dictionary<NSNumber, SKTexture> // xxx
    var imageSource : String?
    var zOrderCount = Int(0)
    
    override init() {
        properties = Dictionary.init()
        super.init()
    }
}
