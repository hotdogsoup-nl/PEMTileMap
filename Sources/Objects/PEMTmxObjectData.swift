import Foundation

class PEMTmxObjectData : NSObject {
    private (set) var id = UInt32(0)

    private var objectName : String?
    private var type : String?
    
    private var coordsInPoints = CGPoint.zero
    private var sizeInPoints = CGSize.zero
    private var rotation = CGFloat(0)

    private var tileGid = UInt32(0)
    private (set) var visible = true

    private (set) var properties : Dictionary<String, Any>?

    init?(attributes: Dictionary<String, String>) {
        guard let objectId = attributes[ElementAttributes.Id.rawValue] else { return nil }
        id = UInt32(objectId)!
        
        super.init()

        objectName = attributes[ElementAttributes.Name.rawValue]
        type = attributes[ElementAttributes.TypeAttribute.rawValue]

        if let x = attributes[ElementAttributes.X.rawValue],
           let y = attributes[ElementAttributes.Y.rawValue] {
            
            let xString : NSString = x as NSString
            let yString : NSString = y as NSString

            coordsInPoints = CGPoint(x: CGFloat(xString.doubleValue), y: CGFloat(yString.doubleValue))
        }
        
        if let width = attributes[ElementAttributes.Width.rawValue],
           let height = attributes[ElementAttributes.Height.rawValue] {
            sizeInPoints = CGSize(width: Int(width)!, height: Int(height)!)
        }
        
        if let value = attributes[ElementAttributes.Opacity.rawValue] {
            let valueString : NSString = value as NSString
            rotation = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.Gid.rawValue] {
            tileGid = UInt32(value)!
        }
        
        if let value = attributes[ElementAttributes.Visible.rawValue] {
            visible = value == "1"
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxObjectData: \(id), (name: \(objectName ?? "-"))"
    }
    #endif
}

