import SpriteKit
import CoreGraphics

/// A TMX Point object.
///
/// Documentation: [TMX Point](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#point)
class PEMObjectPoint: SKShapeNode {
    public var properties: Dictionary<String, Any>?
    public var class_: String?

    public private (set) var coordsInPoints: CGPoint?
    public private (set) var sizeInPoints: CGSize?

    public private (set) var id = UInt32(0)

    // MARK: - Init
    
    init?(objectData: PEMObjectData, color: SKColor) {
        if let size = objectData.sizeInPoints {
            super.init()
            
            let adjustedSize = size.scaled(0.25)
            let rect = CGRect(x: -adjustedSize.width * 0.5, y: -adjustedSize.height * 0.5, width: adjustedSize.width, height: adjustedSize.height)
            path = CGPath(ellipseIn: rect, transform: .none)

            name = objectData.objectName
            lineWidth = 0.25
            strokeColor = color
            fillColor = color.withAlphaComponent(0.5)
            isAntialiased = true
            
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
