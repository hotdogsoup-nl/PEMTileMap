import SpriteKit
import CoreGraphics

/// A TMX polygon object as an `SKShapeNode`.
class PEMObjectPoly: SKShapeNode {
    public var properties: Dictionary<String, Any>?

    private (set) var coordsInPoints: CGPoint?
    private (set) var sizeInPoints: CGSize?

    private (set) var id = UInt32(0)
    private (set) var type: String?

    // MARK: - Init
    
    init?(objectData: PEMObjectData, color: SKColor, isPolygon: Bool) {
        if let points = objectData.polygonPoints {
            super.init()

            if (points.count > 0) {
                self.path = polygonPath(points, closed: isPolygon)
            }

            name = objectData.objectName
            lineWidth = 0.25
            strokeColor = color
            fillColor = (isPolygon ? color.withAlphaComponent(0.5) : .clear)
            isAntialiased = true
            
            var rotation: CGFloat!
            rotation = (objectData.rotation != nil) ? objectData.rotation : 0
            zRotation = rotation.radians()
            
            id = objectData.id
            type = objectData.type
            properties = objectData.properties
            coordsInPoints = objectData.coordsInPoints
            sizeInPoints = calculateAccumulatedFrame().size
            return
        }
        
        return nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
