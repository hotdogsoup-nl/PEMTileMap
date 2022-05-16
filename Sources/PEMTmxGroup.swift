import SpriteKit

class PEMTmxGroup : NSObject {
    private var id = UInt32(0)
    private var name : String?
    private var visible = true
    private var offSetInPoints = CGPoint.zero
    private var opacity = CGFloat(1)
    private var tintColor : SKColor?

    private var parentGroup : PEMTmxGroup?

    init?(attributes: Dictionary<String, String>, group: PEMTmxGroup?) {
        guard let value = attributes[ElementAttributes.Id.rawValue] else { return nil }
        super.init()

        id = UInt32(value)!
        parentGroup = group

        name = attributes[ElementAttributes.Name.rawValue]
        
        if let value = attributes[ElementAttributes.Opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.Visible.rawValue] {
            visible = value == "1"
        }
        
        if let value = attributes[ElementAttributes.TintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let dx = attributes[ElementAttributes.OffsetX.rawValue],
           let dy = attributes[ElementAttributes.OffsetY.rawValue] {
            offSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxGroup: \(id), (name: \(name ?? "-"), parent: \(String(describing: parentGroup)))"
    }
    #endif
}
