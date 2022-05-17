import SpriteKit

internal enum DrawOrder : String {
    case TopDown = "topdown"
    case Index = "index"
}

class PEMTmxObjectLayer : NSObject, PEMTmxPropertiesProtocol {
    private (set) var properties : Dictionary<String, Any>?
    private (set) var opacity = CGFloat(1.0)
    private (set) var visible = true
    private (set) var offSetInPoints = CGPoint.zero
    private (set) var tintColor : SKColor?
    private (set) var color : SKColor?

    private var id = UInt32(0)
    private var name : String?
    private var drawOrder = DrawOrder.TopDown

    private var parentGroup : PEMTmxGroup?

    init?(attributes: Dictionary<String, String>, group: PEMTmxGroup?) {
        guard let groupId = attributes[ElementAttributes.Id.rawValue] else { return nil }
        super.init()

        id = UInt32(groupId)!
        parentGroup = group

        name = attributes[ElementAttributes.Name.rawValue]
        
        if let value = attributes[ElementAttributes.Opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.Visible.rawValue] {
            visible = value == "1"
        }
                
        if let dx = attributes[ElementAttributes.OffsetX.rawValue],
           let dy = attributes[ElementAttributes.OffsetY.rawValue] {
            offSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }
        
        if let value = attributes[ElementAttributes.TintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.Color.rawValue] {
            color = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.DrawOrder.rawValue] {
            if let groupRenderOrder = DrawOrder(rawValue: value) {
                drawOrder = groupRenderOrder
            } else {
                #if DEBUG
                print("PEMTmxObjectGroup: unsupported draw order: \(String(describing: value))")
                #endif
            }
        }

    
        
        applyParentGroupAttributes()
    }
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(type(of: self))")
        #endif
        #endif
    }
    
    // MARK: - PEMTmxPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMTmxProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func applyParentGroupAttributes() {
        if parentGroup == nil {
            return
        }
        
        if let value = parentGroup?.opacity {
            opacity *= CGFloat(value)
        }
        
        if let value = parentGroup?.visible {
            visible = visible && value
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
    override var description: String {
        return "PEMTmxObjectGroup: \(id), (name: \(name ?? "-"), parent: \(String(describing: parentGroup)))"
    }
    #endif
}
