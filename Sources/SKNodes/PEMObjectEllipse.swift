import SpriteKit
import CoreGraphics

/// A TMX ellipse object as an `SKShapeNode`.
class PEMObjectEllipse: SKShapeNode {
    public var properties: Dictionary<String, Any>?
    public var class_: String?

    public private (set) var coordsInPoints: CGPoint?
    public private (set) var sizeInPoints: CGSize?

    public private (set) var id = UInt32(0)
    public private (set) var type: String?

    // MARK: - Init
    
    init?(objectData: PEMObjectData, color: SKColor) {
        if let size = objectData.sizeInPoints {
            super.init()
            
            let rect = CGRect(x: 0, y: -size.height, width: size.width, height: size.height)
            path = CGPath(ellipseIn: rect, transform: .none)

            name = objectData.objectName
            lineWidth = 0.25
            strokeColor = color
            fillColor = color.withAlphaComponent(0.5)
            isAntialiased = true
            
            var rotation: CGFloat!
            rotation = (objectData.rotation != nil) ? objectData.rotation : 0
            zRotation = rotation.radians()
            
            id = objectData.id
            type = objectData.type
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
