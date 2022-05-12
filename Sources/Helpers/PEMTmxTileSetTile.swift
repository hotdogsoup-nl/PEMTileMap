import SpriteKit

class PEMTmxTileSetTile : NSObject {
    private (set) var gid = UInt32(0)
    private (set) var textureImage : SKTexture?
    private (set) var textureImageSize : CGSize?
    private (set) var type : String?
    private (set) var probability = UInt32(0)
    
    private var textureImageSource : String?
    private var format : String? // unsupported
    private var tileSizeInPoints = CGSize.zero
    private var transparentColor : SKColor? // unsupported

    // MARK: - Init
    
    /// Initialiser used when created from within a PEMTmxTileSet.
    init?(gid: UInt32, attributes: Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return nil }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return nil }

        super.init()
        
        self.gid = gid
        if let tilewidth = attributes[ElementAttributes.TileWidth.rawValue],
           let tileheight = attributes[ElementAttributes.TileHeight.rawValue] {
            tileSizeInPoints = CGSize(width: Int(tilewidth)!, height: Int(tileheight)!)
        }

        if let source = attributes[ElementAttributes.Source.rawValue],
           let path = bundlePathForResource(source) {
            textureImageSource = source
            textureImage = SKTexture(imageNamed: path)
            textureImageSize = textureImage?.size()

            format = attributes[ElementAttributes.Format.rawValue]

            if let value = attributes[ElementAttributes.Trans.rawValue] {
                transparentColor = SKColor.init(hexString: value)
            }
            
            if textureImageSize!.width != CGFloat(Int(width)!) || textureImageSize!.height != CGFloat(Int(height)!) {
                #if DEBUG
                print("PEMTmxTileSetTile: tileset <image> size mismatch: \(source)")
                #endif
            }
        }
    }
    
    /// Initialiser used when created from within a PEMTmxTileSetSpriteSheet.
    init?(gid: UInt32, texture: SKTexture, textureImageSource: String, tileSizeInPoints: CGSize) {
        super.init()

        self.gid = gid
        self.tileSizeInPoints = tileSizeInPoints
        self.textureImageSource = textureImageSource
        textureImage = texture
        textureImageSize = textureImage?.size()
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
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetTile: \(gid), (\(textureImageSource ?? "-"), \(Int(textureImageSize!.width)) x \(Int(textureImageSize!.height)))"
    }
    #endif
}
