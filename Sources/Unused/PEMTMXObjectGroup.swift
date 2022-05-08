import Foundation
import SpriteKit

class PEMTmxObjectGroup : NSObject {
    var groupName : String?
    var positionOffset = CGPoint.zero
    var objects : Array<Dictionary<String, String>>
    var properties : Dictionary<NSNumber, SKTexture> // xxx
    var zOrderCount = Int(0)

    override init() {
        objects = Array.init()
        properties = Dictionary.init()
        super.init()
    }
    
    func objectNamed(_ objectName : String) -> Dictionary<String, Any>? {
        // xxx todo
        return nil
    }
    
    func objectsNamed(_ objectName : String) -> Array<String>? {
        // xxx todo
        return nil
    }
    
    func propertyNamed(_ propertyName : String) -> NSObject? { // xxx
        // xxx todo

        return nil
    }
}
