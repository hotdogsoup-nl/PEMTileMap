import SpriteKit
import CoreGraphics

class PEMObjectEllipse: SKShapeNode {
    private (set) var coordsInPoints: CGPoint?
    private (set) var sizeInPoints: CGSize?

    private (set) var id = UInt32(0)
    private (set) var properties: Dictionary<String, Any>?
    private (set) var type: String?

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
