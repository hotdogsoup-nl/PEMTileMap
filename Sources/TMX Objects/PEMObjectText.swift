import SpriteKit
import CoreGraphics

/// A TMX Text object.
///
/// Documentation: [TMX Text](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#text)
public class PEMObjectText: SKSpriteNode {
    public var properties: Dictionary<String, Any>?
    public var class_: String?

    public private (set) var coordsInPoints: CGPoint?
    public private (set) var sizeInPoints: CGSize?

    public private (set) var id = UInt32(0)

    // MARK: - Init
    
    init?(map: PEMTileMap, objectData: PEMObjectData) {
        if let size = objectData.sizeInPoints {
            super.init(texture: nil, color: .green, size: size)

            var text: String!
            text = (objectData.text != nil) ? objectData.text : ""

            var fontFamily: String!
            fontFamily = (objectData.fontFamily != nil) ? objectData.fontFamily : "Arial"

            var pixelSize: CGFloat!
            pixelSize = (objectData.pixelSize != nil) ? objectData.pixelSize : 16

            var textColor: SKColor!
            textColor = (objectData.textColor != nil) ? objectData.textColor : .white

            var bold: Bool!
            bold = (objectData.bold != nil) ? objectData.bold : false

            var italic: Bool!
            italic = (objectData.italic != nil) ? objectData.italic : false

            var underline: Bool!
            underline = (objectData.underline != nil) ? objectData.underline : false

            var strikeOut: Bool!
            strikeOut = (objectData.strikeOut != nil) ? objectData.strikeOut : false

            var kerning: Bool!
            kerning = (objectData.kerning != nil) ? objectData.kerning : false

            var wrap: Bool!
            wrap = (objectData.wrap != nil) ? objectData.wrap : false

            var hAlign: TextHorizontalAlignment!
            hAlign = (objectData.hAlign != nil) ? objectData.hAlign : .left
            
            var vAlign: TextVerticalAlignment!
            vAlign = (objectData.vAlign != nil) ? objectData.vAlign : .top

            let scaleFactor = 15.0 // scale up to increase text render quality
            let label = SKLabelNode(text: text,
                                    fontName: fontFamily,
                                    fontSize: pixelSize * scaleFactor,
                                    fontColor: textColor,
                                    bold: bold,
                                    italic: italic,
                                    underline: underline,
                                    strikeOut: strikeOut,
                                    kerning: kerning,
                                    wordWrapWidth: (wrap) ? size.width * scaleFactor : 0,
                                    hAlign: hAlign,
                                    vAlign: vAlign)
             
            texture = map.skView!.texture(from: label)
            
            name = objectData.objectName
            anchorPoint = CGPoint(x: 0.0, y: 1.0)
            
            var rotation: CGFloat!
            rotation = (objectData.rotation != nil) ? objectData.rotation : 0
            zRotation = rotation.radians()
            
            id = objectData.id
            properties = objectData.properties
            class_ = objectData.class_
            coordsInPoints = objectData.coordsInPoints
            sizeInPoints = objectData.sizeInPoints
            return
        }
        
        return nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
