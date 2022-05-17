import Foundation

enum ObjectType {
    case ellipse
    case point
    case polygon
    case polyline
    case rectangle
    case text
    case tile
}

class PEMTmxObjectData : NSObject {
    private (set) var id = UInt32(0)
    private (set) var objectType : ObjectType?

    private var objectName : String?
    private var type : String?
    
    private var coordsInPoints = CGPoint.zero
    private var sizeInPoints = CGSize.zero
    private var rotation = CGFloat(0)

    private var tileGid = UInt32(0)
    private (set) var visible = true

    private (set) var properties : Dictionary<String, Any>?

    init?(attributes: Dictionary<String, String>) {
        guard let objectId = attributes[ElementAttributes.id.rawValue] else { return nil }
        id = UInt32(objectId)!
        
        super.init()

        objectName = attributes[ElementAttributes.name.rawValue]
        type = attributes[ElementAttributes.typeAttribute.rawValue]

        if let x = attributes[ElementAttributes.x.rawValue],
           let y = attributes[ElementAttributes.y.rawValue] {
            
            let xString : NSString = x as NSString
            let yString : NSString = y as NSString

            coordsInPoints = CGPoint(x: CGFloat(xString.doubleValue), y: CGFloat(yString.doubleValue))
        }
        
        if let width = attributes[ElementAttributes.width.rawValue],
           let height = attributes[ElementAttributes.height.rawValue] {
            
            let widthString : NSString = width as NSString
            let heightString : NSString = height as NSString

            sizeInPoints = CGSize(width: CGFloat(widthString.doubleValue), height: CGFloat(heightString.doubleValue))
        }
        
        if let value = attributes[ElementAttributes.opacity.rawValue] {
            let valueString : NSString = value as NSString
            rotation = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.gid.rawValue] {
            tileGid = UInt32(value)!
        }
        
        if let value = attributes[ElementAttributes.visible.rawValue] {
            visible = value == "1"
        }
    }
    
    // MARK: - Setup
    
    func setObjectType(_ type : ObjectType) {
        objectType = type
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxObjectData: \(id), (name: \(objectName ?? "-"))"
    }
    #endif
}

