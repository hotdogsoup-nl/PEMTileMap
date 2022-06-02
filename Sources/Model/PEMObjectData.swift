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

class PEMObjectData: NSObject, PEMTileMapPropertiesProtocol {
    private (set) var id = UInt32(0)
    private (set) var objectType = ObjectType.rectangle
    private (set) var visible = true
    private (set) var coordsInPoints: CGPoint?
    private (set) var sizeInPoints: CGSize?
    private (set) var rotation: CGFloat?
    private (set) var objectName: String?
    private (set) var tileGid: UInt32?
    private (set) var text: String?
    private (set) var textColor: SKColor?
    private (set) var fontFamily: String?
    private (set) var bold: Bool?
    private (set) var italic: Bool?
    private (set) var pixelSize: CGFloat?
    private (set) var underline: Bool?
    private (set) var strikeOut: Bool?
    private (set) var kerning: Bool?
    private (set) var hAlign: TextHorizontalAlignment?
    private (set) var vAlign: TextVerticalAlignment?
    private (set) var wrap: Bool?
    private (set) var type: String?
    private (set) var externalSource: String?
    
    private (set) var properties: Dictionary<String, Any>?
    private (set) var polygonPoints: Array<CGPoint>?
    
    private (set) var attributes: Dictionary<String, String>?
    private var attributesParsed = false

    private var tileSetSource: String? // as yet unused because a tile object's gid is used to find the corresponding tileSet.

    init?(attributes: Dictionary<String, String>?) {
        super.init()
        
        if let currentAttributes = attributes {
            if let value = currentAttributes[ElementAttributes.id.rawValue] {
                id = UInt32(value)!
            }
            
            externalSource = currentAttributes[ElementAttributes.template.rawValue]
        }

        self.attributes = attributes
    }
    
    // MARK: - Setup
    
    internal func parseAttributes(defaultSize: CGSize) {
        guard !attributesParsed else { return }
        attributesParsed = true
        
        if let currentAttributes = attributes {
            if let value = currentAttributes[ElementAttributes.name.rawValue] {
                objectName = value
            }
            
            if let value = currentAttributes[ElementAttributes.typeAttribute.rawValue] {
                type = value
            }

            if let x = currentAttributes[ElementAttributes.x.rawValue],
               let y = currentAttributes[ElementAttributes.y.rawValue] {
                
                let xString : NSString = x as NSString
                let yString : NSString = y as NSString

                coordsInPoints = CGPoint(x: CGFloat(xString.doubleValue), y: CGFloat(yString.doubleValue))
            }
            
            if let value = currentAttributes[ElementAttributes.gid.rawValue] {
                tileGid = UInt32(value)!
                objectType = .tile
            }
            
            if let width = currentAttributes[ElementAttributes.width.rawValue],
               let height = currentAttributes[ElementAttributes.height.rawValue] {
                
                let widthString : NSString = width as NSString
                let heightString : NSString = height as NSString

                sizeInPoints = CGSize(width: CGFloat(widthString.doubleValue), height: CGFloat(heightString.doubleValue))
            } else {
                sizeInPoints = defaultSize
            }
            
            if let value = currentAttributes[ElementAttributes.rotation.rawValue] {
                let valueString : NSString = value as NSString
                rotation = CGFloat(360.0 - valueString.doubleValue)
            }
            
            if let value = currentAttributes[ElementAttributes.visible.rawValue] {
                visible = value == "1"
            }

            if let value = currentAttributes[ElementAttributes.fontFamily.rawValue] {
                fontFamily = value
            }
            
            if let value = currentAttributes[ElementAttributes.color.rawValue] {
                textColor = SKColor.init(hexString: value)
            }
            
            if let value = currentAttributes[ElementAttributes.pixelSize.rawValue] {
                let valueString : NSString = value as NSString
                pixelSize = CGFloat(valueString.doubleValue)
            }
            
            if let value = currentAttributes[ElementAttributes.bold.rawValue] {
                bold = value == "1"
            }
            
            if let value = currentAttributes[ElementAttributes.italic.rawValue] {
                italic = value == "1"
            }
            
            if let value = currentAttributes[ElementAttributes.underline.rawValue] {
                underline = value == "1"
            }
            
            if let value = currentAttributes[ElementAttributes.strikeout.rawValue] {
                strikeOut = value == "1"
            }
            
            if let value = currentAttributes[ElementAttributes.kerning.rawValue] {
                kerning = value == "1"
            }
            
            if let value = currentAttributes[ElementAttributes.wrap.rawValue] {
                wrap = value == "1"
            }
            
            if let value = currentAttributes[ElementAttributes.hAlign.rawValue] {
                if let alignment = TextHorizontalAlignment(rawValue: value) {
                    hAlign = alignment
                } else {
                    #if DEBUG
                    print("PEMObjectData: unsupported horizontal alignment: \(String(describing: value))")
                    #endif
                }
            }
            
            if let value = currentAttributes[ElementAttributes.vAlign.rawValue] {
                if let alignment = TextVerticalAlignment(rawValue: value) {
                    vAlign = alignment
                } else {
                    #if DEBUG
                    print("PEMObjectData: unsupported vertical alignment: \(String(describing: value))")
                    #endif
                }
            }

            if let pointsString = currentAttributes[ElementAttributes.points.rawValue] {
                let pointsArray = pointsString.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                for point in pointsArray {
                    let coordsArray = point.components(separatedBy: ",")
                    if let x = Int(coordsArray.first!),
                       let y = Int(coordsArray.last!) {
                        if polygonPoints == nil {
                            polygonPoints = []
                        }
                        polygonPoints!.append(CGPoint(x: x, y: -y))
                    }
                }
            }
        }
    }
    
    internal func setObjectType(_ objectType : ObjectType) {
        self.objectType = objectType
    }
    
    internal func setTileSet(_ attributes: Dictionary<String, String>?) {
        if let currentAttributes = attributes {
            if let value = currentAttributes[ElementAttributes.source.rawValue] {
                tileSetSource = value
            }
        }
    }
    
    internal func setText(_ text: String) {
        self.text = text
    }
            
    internal func addAttributes(_ attributes: Dictionary<String, String>?) {
        if self.attributes == nil {
            self.attributes = attributes
            return
        }

        if let newAttributes = attributes {
            self.attributes!.merge(newAttributes) { (current, _) in current }
        }
    }
    
    // MARK: - PEMTileMapPropertiesProtocol
    
    internal func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMObjectData: \(id), (name: \(objectName ?? "-"), objectType: \(String(describing: objectType)))"
    }
    #endif
}

