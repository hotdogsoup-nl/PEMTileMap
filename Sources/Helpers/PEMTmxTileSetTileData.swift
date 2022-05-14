import SpriteKit

class PEMTmxTileSetTileDataAnimation : NSObject {
    private (set) var frames : [PEMTmxTileSetTileDataAnimationFrame] = []
    
    func addAnimationFrame(attributes: Dictionary<String, String>) {
        if let animationFrame = PEMTmxTileSetTileDataAnimationFrame(attributes: attributes) {
            frames.append(animationFrame)
        }
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetTileDataAnimation: frames:\(frames.count))"
    }
    #endif
}

class PEMTmxTileSetTileDataAnimationFrame : NSObject {
    private (set) var tileId = UInt32(0)
    private (set) var duration = UInt32(0)
    
    init?(attributes: Dictionary<String, String>) {
        guard let tileId = attributes[ElementAttributes.TileId.rawValue] else { return nil }
        guard let duration = attributes[ElementAttributes.Duration.rawValue] else { return nil }
        
        super.init()

        self.tileId = UInt32(tileId)!
        self.duration = UInt32(duration)!
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetTileDataAnimationFrame: tileId: \(tileId), duration: (\(duration))"
    }
    #endif
}

class PEMTmxTileSetTileData : NSObject {
    var texture : SKTexture?

    private (set) var id = UInt32(0)
    private (set) var type : String?
    private (set) var probability = UInt32(0)

    private (set) var usesSpriteSheet = false
    private (set) var animation : PEMTmxTileSetTileDataAnimation?

    private var textureImageSource : String?
    private var tileSizeInPoints = CGSize.zero

    // MARK: - Init
    
    /// Initialiser used when created from within a PEMTmxTileSet.
    init?(id: UInt32, attributes: Dictionary<String, String>) {
        super.init()
        
        self.id = id
        addAttributes(attributes)
        usesSpriteSheet = false
    }
    
    /// Initialiser used when created from within a PEMTmxTileSetSpriteSheet.
    init?(id: UInt32, textureImageSource: String, tileSizeInPoints: CGSize) {
        super.init()
        
        self.id = id
        self.tileSizeInPoints = tileSizeInPoints
        self.textureImageSource = textureImageSource
        usesSpriteSheet = true
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
        if let value = attributes[ElementAttributes.TypeAttribute.rawValue] {
            type = value
        }

        if let value = attributes[ElementAttributes.Probability.rawValue] {
            probability = UInt32(value)!
        }
    }
    
    func addTileImage(attributes: Dictionary<String, String>) {
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return }

        tileSizeInPoints = CGSize(width: Int(width)!, height: Int(height)!)
        
        if let path = bundlePathForResource(source) {
            textureImageSource = source
            texture = SKTexture(imageNamed: path)
        } else {
            #if DEBUG
            print("PEMTmxTileSetTileData: image file \(source) not found for tile with id: \(id)")
            #endif
        }
    }
    
    func addAnimation() -> PEMTmxTileSetTileDataAnimation? {
        animation = PEMTmxTileSetTileDataAnimation()
        
        return animation
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetTileData: \(id), (\(textureImageSource ?? "-"))"
    }
    #endif
}
