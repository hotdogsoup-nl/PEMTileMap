import SpriteKit

public class PEMGroupLayer: NSObject, PEMTileMapPropertiesProtocol {
    private (set) var properties: Dictionary<String, Any>?
    private (set) var class_: String?

    private (set) var opacity = CGFloat(1.0)
    private (set) var visible = true
    private (set) var offSetInPoints = CGPoint.zero
    private (set) var tintColor: SKColor?

    private var id = UInt32(0)
    private var name: String?

    private var parentGroup: PEMGroupLayer?

    init?(attributes: Dictionary<String, String>, group: PEMGroupLayer?) {
        guard let groupId = attributes[ElementAttributes.id.rawValue] else { return nil }
        super.init()

        id = UInt32(groupId)!
        parentGroup = group

        name = attributes[ElementAttributes.name.rawValue]
        class_ = attributes[ElementAttributes.class_.rawValue]

        if let value = attributes[ElementAttributes.opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.visible.rawValue] {
            visible = value == "1"
        }
                
        if let dx = attributes[ElementAttributes.offsetX.rawValue],
           let dy = attributes[ElementAttributes.offsetY.rawValue] {
            offSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }
        
        if let value = attributes[ElementAttributes.tintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        applyParentGroupAttributes()
    }
    
    // MARK: - PEMTileMapPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func applyParentGroupAttributes() {
        guard parentGroup != nil else { return }
        
        if let value = parentGroup?.opacity {
            opacity *= CGFloat(value)
        }
                
        if let value = parentGroup?.offSetInPoints {
            offSetInPoints = CGPoint(x: offSetInPoints.x + value.x, y: offSetInPoints.y + value.y)
        }
        
        if let value = parentGroup?.tintColor {
            if tintColor != nil {
                tintColor = tintColor?.multiplyColor(value)
            } else {
                tintColor = value
            }
        }
    }
    
    // MARK: - Debug

    #if DEBUG
    public override var description: String {
        return "PEMGroupLayer: \(id), (name: \(name ?? "-"), class: \(class_ ?? "-"), parent: \(String(describing: parentGroup)))"
    }
    #endif
}
