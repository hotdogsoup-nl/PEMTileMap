import SpriteKit
import CoreGraphics

/// A TMX Polygon or Polyline object.
/// When the first point of a polyline is equal to the last point, it is considered a polygon.
///
/// Documentation: [TMX Polyline](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#polyline)
///
/// Documentation: [TMX Polygon](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#polygon)
public class PEMObjectPoly: SKShapeNode {
    public var properties: Dictionary<String, Any>?
    public var class_: String?

    public private (set) var coordsInPoints: CGPoint?
    public private (set) var sizeInPoints: CGSize?

    public private (set) var id = UInt32(0)

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
            properties = objectData.properties
            class_ = objectData.class_
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
