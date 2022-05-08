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

    var tileData: [UInt32] = []

    /// Uses  **TMX** tile layer attributes to create and return a new `PEMTmxTileLayer` object.
    /// - parameter attributes : Dictionary containing TMX tile layer attributes.
    init(attributes: Dictionary<String, String>) {
        super.init()
        
        if let value = attributes[MapElementAttributes.Id.rawValue] {
            layerId = value
        }

        if let value = attributes[MapElementAttributes.Name.rawValue] {
            layerName = value
        }
        
        if let x = attributes[MapElementAttributes.X.rawValue],
           let y = attributes[MapElementAttributes.Y.rawValue] {
            coordsInTiles = CGPoint(x: Int(x)!, y: Int(y)!)
        }

        if let width = attributes[MapElementAttributes.Width.rawValue],
           let height = attributes[MapElementAttributes.Height.rawValue] {
            sizeInTiles = CGSize(width: Int(width)!, height: Int(height)!)
        }
        
        if let value = attributes[MapElementAttributes.Opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[MapElementAttributes.Visible.rawValue] {
            visible = value == "1"
        }
        
        if let value = attributes[MapElementAttributes.TintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let dx = attributes[MapElementAttributes.OffsetX.rawValue],
           let dy = attributes[MapElementAttributes.OffsetY.rawValue] {
            offSetInPoints = CGVector(dx: Int(dx)!, dy: Int(dy)!)
        }
        
        if let value = attributes[MapElementAttributes.ParallaxX.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorX = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[MapElementAttributes.ParallaxY.rawValue] {
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
    
    // MARK: - Map generation

    func generateTiles() {
        
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        var result : String = ""
        
        result += "\nPEMTmxLayer --"
        result += "\nlayerId: \(String(describing: layerId))"
        result += "\nlayerName: \(String(describing: layerName))"
        result += "\ncoordsInTiles: \(coordsInTiles)"
        result += "\nsizeInTiles: \(sizeInTiles)"
        result += "\ntileData: \(tileData)"

        return result
    }
    #endif
}
