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
    private (set) var objectType: ObjectType?
    private (set) var visible: Bool?
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

    init?(attributes: Dictionary<String, String>) {
        super.init()
        
        if let value = attributes[ElementAttributes.id.rawValue] {
            id = UInt32(value)!
        }

        externalSource = attributes[ElementAttributes.template.rawValue]
        
        if let value = attributes[ElementAttributes.name.rawValue] {
            objectName = value
        }
        
        if let value = attributes[ElementAttributes.typeAttribute.rawValue] {
            type = value
        }

        if let x = attributes[ElementAttributes.x.rawValue],
           let y = attributes[ElementAttributes.y.rawValue] {
            
            let xString : NSString = x as NSString
            let yString : NSString = y as NSString

            coordsInPoints = CGPoint(x: CGFloat(xString.doubleValue), y: CGFloat(yString.doubleValue))
        }
        
        if let value = attributes[ElementAttributes.gid.rawValue] {
            tileGid = UInt32(value)!
            objectType = .tile
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
        
        if let value = attributes[ElementAttributes.visible.rawValue] {
            visible = value == "1"
        }
    }
    
    // MARK: - Setup
    
    func setObjectType(_ type : ObjectType, attributes: Dictionary<String, String> = [:]) {
        objectType = type
        
        guard attributes.count > 0 else { return }
        
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
                print("PEMObjectData: unsupported horizontal alignment: \(String(describing: value))")
                #endif
            }
        }
        
        if let value = attributes[ElementAttributes.vAlign.rawValue] {
            if let alignment = TextVerticalAlignment(rawValue: value) {
                vAlign = alignment
            } else {
                #if DEBUG
                print("PEMObjectData: unsupported vertical alignment: \(String(describing: value))")
                #endif
            }
        }

        if let pointsString = attributes[ElementAttributes.points.rawValue] {
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
    
    func setText(_ text: String) {
        self.text = text
    }
    
    // MARK: - Setup
        
    func addTemplateAttributes(_ attributes: Dictionary<String, String>) {
        if let value = attributes[ElementAttributes.name.rawValue],
           objectName == nil {
            objectName = value
        }
        
        if let value = attributes[ElementAttributes.typeAttribute.rawValue],
            type == nil {
            type = value
        }

        if let x = attributes[ElementAttributes.x.rawValue],
           let y = attributes[ElementAttributes.y.rawValue],
           coordsInPoints == nil {
            let xString : NSString = x as NSString
            let yString : NSString = y as NSString

            coordsInPoints = CGPoint(x: CGFloat(xString.doubleValue), y: CGFloat(yString.doubleValue))
        }
        
        if let value = attributes[ElementAttributes.gid.rawValue],
           tileGid == nil {
            tileGid = UInt32(value)!
            objectType = .tile
        }
        
        if let width = attributes[ElementAttributes.width.rawValue],
           let height = attributes[ElementAttributes.height.rawValue],
           sizeInPoints == nil {
            
            let widthString : NSString = width as NSString
            let heightString : NSString = height as NSString

            sizeInPoints = CGSize(width: CGFloat(widthString.doubleValue), height: CGFloat(heightString.doubleValue))
        }
        
        if let value = attributes[ElementAttributes.rotation.rawValue],
           rotation == nil {
            let valueString : NSString = value as NSString
            rotation = CGFloat(360.0 - valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.visible.rawValue],
           visible == nil {
            visible = value == "1"
        }
    }
    
    func applyTemplate(_ template: PEMObjectData) {
        if objectType == nil {
            objectType = template.objectType
        }
        
        if visible == nil {
            visible = template.visible
        }
        
        if coordsInPoints == nil {
            coordsInPoints = template.coordsInPoints
        }

        if sizeInPoints == nil {
            sizeInPoints = template.sizeInPoints
        }

        if rotation == nil {
            rotation = template.rotation
        }

        if objectName == nil {
            objectName = template.objectName
        }

        if tileGid == nil {
            tileGid = template.tileGid
        }

        if text == nil {
            text = template.text
        }

        if textColor == nil {
            textColor = template.textColor
        }

        if fontFamily == nil {
            fontFamily = template.fontFamily
        }

        if bold == nil {
            bold = template.bold
        }

        if italic == nil {
            italic = template.italic
        }

        if italic == nil {
            italic = template.italic
        }

        if pixelSize == nil {
            pixelSize = template.pixelSize
        }

        if underline == nil {
            underline = template.underline
        }
        
        if strikeOut == nil {
            strikeOut = template.strikeOut
        }
        
        if kerning == nil {
            kerning = template.kerning
        }

        if hAlign == nil {
            hAlign = template.hAlign
        }

        if vAlign == nil {
            vAlign = template.vAlign
        }

        if wrap == nil {
            wrap = template.wrap
        }

        if type == nil {
            type = template.type
        }

        if externalSource == nil {
            externalSource = template.externalSource
        }

        if properties == nil {
            properties = template.properties
        }

        if polygonPoints == nil {
            polygonPoints = template.polygonPoints
        }
    }
    
    // MARK: - PEMTileMapPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMObjectData: \(id), (name: \(objectName ?? "-"), objectType: \(String(describing: objectType)))"
    }
    #endif
}

