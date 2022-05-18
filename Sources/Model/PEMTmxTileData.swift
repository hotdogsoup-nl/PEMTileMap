import SpriteKit

class PEMTmxTileData: NSObject, PEMTmxPropertiesProtocol {
    var texture: SKTexture?

    private (set) var id = UInt32(0)
    private (set) var type: String?
    private (set) var probability = UInt32(0)
    private (set) var properties: Dictionary<String, Any>?
    private (set) var animation: PEMTmxTileAnimation?

    private var textureImageSource : String?
    private var tileSizeInPoints = CGSize.zero

    // MARK: - Init
    
    /// Initialiser used when created from within a PEMTmxTileSet.
    init?(id: UInt32, attributes: Dictionary<String, String>) {
        super.init()
        
        self.id = id
        addAttributes(attributes)
    }
    
    /// Initialiser used when created from within a PEMTmxSpriteSheet.
    init?(id: UInt32, textureImageSource: String, tileSizeInPoints: CGSize) {
        super.init()
        
        self.id = id
        self.tileSizeInPoints = tileSizeInPoints
        self.textureImageSource = textureImageSource
    }
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(type(of: self))")
        #endif
        #endif
    }

    // MARK: - Setup
    
    func addAttributes(_ attributes: Dictionary<String, String>) {
        if let value = attributes[ElementAttributes.typeAttribute.rawValue] {
            type = value
        }

        if let value = attributes[ElementAttributes.probability.rawValue] {
            probability = UInt32(value)!
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
            print("PEMTmxTileData: image file \(source) not found for tile with id: \(id)")
            #endif
        }
    }
    
    func addAnimation() -> PEMTmxTileAnimation? {
        animation = PEMTmxTileAnimation()
        
        return animation
    }
    
    // MARK: - PEMTmxPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMTmxProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileData: \(id), (\(textureImageSource ?? "-"))"
    }
    #endif
}
