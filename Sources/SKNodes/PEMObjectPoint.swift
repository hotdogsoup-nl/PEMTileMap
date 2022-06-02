import SpriteKit
import CoreGraphics

class PEMObjectPoint: SKShapeNode {
    private (set) var coordsInPoints: CGPoint?
    private (set) var sizeInPoints: CGSize?

    private (set) var id = UInt32(0)
    private (set) var properties: Dictionary<String, Any>?
    private (set) var type: String?

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
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(Swift.type(of: self))")
        #endif
        #endif
    }
}
