import SpriteKit

class PEMTmxTileSetTileData : NSObject {
    var texture : SKTexture?

    private (set) var gid = UInt32(0)
    private (set) var type : String?
    private (set) var probability = UInt32(0)

    private (set) var usesSpriteSheet = false

    private var textureImageSource : String?
    private var tileSizeInPoints = CGSize.zero

    // MARK: - Init
    
    /// Initialiser used when created from within a PEMTmxTileSet.
    init?(gid: UInt32, attributes: Dictionary<String, String>) {
        super.init()
        
        self.gid = gid
        addAttributes(attributes)
        usesSpriteSheet = false
    }
    
    /// Initialiser used when created from within a PEMTmxTileSetSpriteSheet.
    init?(gid: UInt32, textureImageSource: String, tileSizeInPoints: CGSize) {
        super.init()
        
        self.gid = gid
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
        }
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetTile: \(gid), (\(textureImageSource ?? "-"))"
    }
    #endif
}
