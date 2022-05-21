import Foundation
import SpriteKit

enum ObjectType {
    case ellipse
    case point
    case polygon
    case polyline
    case rectangle
    case text
    case tile
    case unknown
}

enum TextHorizontalAlignment: String {
    case center
    case justify
    case left
    case right
}

enum TextVerticalAlignment: String {
    case bottom
    case center
    case top
}

class PEMTmxObjectData: NSObject, PEMTmxPropertiesProtocol {
    private (set) var id = UInt32(0)
    private (set) var objectType = ObjectType.unknown
    private (set) var visible = true
    private (set) var coordsInPoints = CGPoint.zero
    private (set) var sizeInPoints = CGSize.zero
    private (set) var rotation = CGFloat(0)
    private (set) var objectName: String?
    private (set) var tileGid = UInt32(0)
    private (set) var text = ""
    private (set) var textColor = SKColor.white
    private (set) var fontFamily = "Arial"
    private (set) var bold = false
    private (set) var italic = false
    private (set) var pixelSize = CGFloat(16)
    private (set) var underline = false
    private (set) var strikeOut = false
    private (set) var kerning = true
    private (set) var hAlign = TextHorizontalAlignment.left
    private (set) var vAlign = TextVerticalAlignment.top
    private (set) var wrap = false

    private var type: String?

    private (set) var properties : Dictionary<String, Any>?
    private (set) var polygonPoints: [CGPoint] = []

    init?(attributes: Dictionary<String, String>) {
        super.init()
        
        if let value = attributes[ElementAttributes.id.rawValue] {
            id = UInt32(value)!
        }

        objectName = attributes[ElementAttributes.name.rawValue]
        type = attributes[ElementAttributes.typeAttribute.rawValue]
        objectType = .rectangle

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
        
        if let value = attributes[ElementAttributes.rotation.rawValue] {
            let valueString : NSString = value as NSString
            rotation = CGFloat(360.0 - valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.gid.rawValue] {
            tileGid = UInt32(value)!
            objectType = .tile
        }
        
        if let value = attributes[ElementAttributes.visible.rawValue] {
            visible = value == "1"
        }
    }
    
    // MARK: - Setup
    
    func setObjectType(_ type : ObjectType, attributes: Dictionary<String, String> = [:]) {
        objectType = type
        
        if attributes.count == 0 {
            return
        }
        
        if let value = attributes[ElementAttributes.fontFamily.rawValue] {
            fontFamily = value
        }
        
        if let value = attributes[ElementAttributes.color.rawValue] {
            textColor = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.pixelSize.rawValue] {
            let valueString : NSString = value as NSString
            pixelSize = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.bold.rawValue] {
            bold = value == "1"
        }
        
        if let value = attributes[ElementAttributes.italic.rawValue] {
            italic = value == "1"
        }
        
        if let value = attributes[ElementAttributes.underline.rawValue] {
            underline = value == "1"
        }
        
        if let value = attributes[ElementAttributes.strikeout.rawValue] {
            strikeOut = value == "1"
        }
        
        if let value = attributes[ElementAttributes.kerning.rawValue] {
            kerning = value == "1"
        }
        
        if let value = attributes[ElementAttributes.wrap.rawValue] {
            wrap = value == "1"
        }
        
        if let value = attributes[ElementAttributes.hAlign.rawValue] {
            if let alignment = TextHorizontalAlignment(rawValue: value) {
                hAlign = alignment
            } else {
                #if DEBUG
                print("PEMTmxObjectData: unsupported horizontal alignment: \(String(describing: value))")
                #endif
            }
        }
        
        if let value = attributes[ElementAttributes.vAlign.rawValue] {
            if let alignment = TextVerticalAlignment(rawValue: value) {
                vAlign = alignment
            } else {
                #if DEBUG
                print("PEMTmxObjectData: unsupported vertical alignment: \(String(describing: value))")
                #endif
            }
        }

        if let pointsString = attributes[ElementAttributes.points.rawValue] {
            let pointsArray = pointsString.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            for point in pointsArray {
                let coordsArray = point.components(separatedBy: ",")
                if let x = Int(coordsArray.first!),
                   let y = Int(coordsArray.last!) {
                    polygonPoints.append(CGPoint(x: x, y: -y))
                }
            }
        }
    }
    
    func setText(_ text: String) {
        self.text = text
    }
    
    // MARK: - PEMTmxPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMTmxProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxObjectData: \(id), (name: \(objectName ?? "-"), objectType: \(objectType))"
    }
    #endif
}

