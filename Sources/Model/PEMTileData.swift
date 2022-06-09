import SpriteKit

internal class PEMTileData: NSObject, PEMTileMapPropertiesProtocol {
    var texture: SKTexture?

    private (set) var id = UInt32(0)
    private (set) var type: String?
    private (set) var probability = CGFloat(0)
    private (set) var properties: Dictionary<String, Any>?
    private (set) var animation: PEMTileAnimation?

    private var textureImageSource : String?
    private var tileSizeInPoints = CGSize.zero

    // MARK: - Init
    
    /// Initialiser used when created from within a PEMTileSet.
    init?(id: UInt32, attributes: Dictionary<String, String>) {
        super.init()
        
        self.id = id
        addAttributes(attributes)
    }
    
    /// Initialiser used when created from within a PEMSpriteSheet.
    init?(id: UInt32, textureImageSource: String, tileSizeInPoints: CGSize) {
        super.init()
        
        self.id = id
        self.tileSizeInPoints = tileSizeInPoints
        self.textureImageSource = textureImageSource
    }

    // MARK: - Setup
    
    func addAttributes(_ attributes: Dictionary<String, String>) {
        if let value = attributes[ElementAttributes.typeAttribute.rawValue] {
            type = value
        }

        if let value = attributes[ElementAttributes.probability.rawValue] {
            let valueString : NSString = value as NSString
            probability = CGFloat(valueString.doubleValue)
        }
    }
    
    func addTileImage(attributes: Dictionary<String, String>) {
        guard let source = attributes[ElementAttributes.source.rawValue] else { return }
        guard let width = attributes[ElementAttributes.width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.height.rawValue] else { return }

        tileSizeInPoints = CGSize(width: Int(width)!, height: Int(height)!)
        
        if let path = bundlePathForResource(source) {
            textureImageSource = source
            texture = SKTexture(imageNamed: path)
        } else {
            #if DEBUG
            print("PEMTileData: image file \(source) not found for tile with id: \(id)")
            #endif
        }
    }
    
    func addAnimation() -> PEMTileAnimation? {
        animation = PEMTileAnimation()
        
        return animation
    }
    
    // MARK: - PEMTileMapPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTileData: \(id), (\(textureImageSource ?? "-"))"
    }
    #endif
}
