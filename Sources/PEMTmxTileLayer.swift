import Foundation
import SpriteKit

class PEMTmxTileLayer : SKNode {
    private (set) var layerId : String?
    private (set) var layerName : String?
    
    private (set) var coordsInTiles = CGPoint.zero
    private (set) var sizeInTiles = CGSize.zero
    private (set) var opacity = CGFloat(1)
    private (set) var visible = true
    private (set) var tintColor : SKColor?
    private (set) var offSetInPoints = CGVector.zero
    private (set) var parallaxFactorX = CGFloat(1)
    private (set) var parallaxFactorY = CGFloat(1)
    
    /**
     Uses  **TMX** tile layer attributes to create and return a new `PEMTmxTileLayer` object.

     - parameter attributes : Dictionary containing TMX tile layer attributes.
     */

    init(attributes: Dictionary<String, String>) {
        super.init()
        
        if let value = attributes[ElementAttributes.Id.rawValue] {
            layerId = value
        }

        if let value = attributes[ElementAttributes.Name.rawValue] {
            layerName = value
        }
        
        if let x = attributes[ElementAttributes.X.rawValue],
           let y = attributes[ElementAttributes.Y.rawValue] {
            coordsInTiles = CGPoint(x: Int(x)!, y: Int(y)!)
        }

        if let width = attributes[ElementAttributes.Width.rawValue],
           let height = attributes[ElementAttributes.Height.rawValue] {
            sizeInTiles = CGSize(width: Int(width)!, height: Int(height)!)
        }
        
        if let value = attributes[ElementAttributes.Opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.Visible.rawValue] {
            visible = value == "1"
        }
        
        if let value = attributes[ElementAttributes.TintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let dx = attributes[ElementAttributes.OffsetX.rawValue],
           let dy = attributes[ElementAttributes.OffsetY.rawValue] {
            offSetInPoints = CGVector(dx: Int(dx)!, dy: Int(dy)!)
        }
        
        if let value = attributes[ElementAttributes.ParallaxX.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorX = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.ParallaxY.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorY = CGFloat(valueString.doubleValue)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        #if DEBUG
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #endif
    }
    
    #if DEBUG
    override var description: String {
        var result : String = ""
        
        result += "\nPEMTmxLayer --"
        result += "\nlayerName: \(String(describing: layerName))"
        result += "\ncoordsInTiles: \(coordsInTiles)"
        result += "\nsizeInTiles: \(sizeInTiles)"

        return result
    }
    #endif
}
