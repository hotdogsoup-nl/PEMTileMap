import SpriteKit

class PEMTmxTileSetTile : NSObject {
    private (set) var gid = UInt32(0)
    private (set) var textureImage : SKTexture?
    private var textureImageSize : CGSize?
    private var textureImageSource : String?
    private var format : String? // unsupported
    private var tileSizeInPoints = CGSize.zero
    private var transparentColor : SKColor? // unsupported

    // MARK: - Init
    
    init?(gid: UInt32, attributes: Dictionary<String, String>) {
        super.init()
        
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return nil }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return nil }
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return nil }
        
        if let path = bundlePathForResource(source) {
            self.gid = gid
            textureImageSource = source
            textureImage = SKTexture(imageNamed: path)
            textureImageSize = textureImage?.size()

            format = attributes[ElementAttributes.Format.rawValue]

            if let tilewidth = attributes[ElementAttributes.TileWidth.rawValue],
               let tileheight = attributes[ElementAttributes.TileHeight.rawValue] {
                tileSizeInPoints = CGSize(width: Int(tilewidth)!, height: Int(tileheight)!)
            }

            if let value = attributes[ElementAttributes.Trans.rawValue] {
                transparentColor = SKColor.init(hexString: value)
            }
            
            if textureImageSize!.width != CGFloat(Int(width)!) || textureImageSize!.height != CGFloat(Int(height)!) {
                #if DEBUG
                print("PEMTmxTileSetTile: tileset <image> size mismatch: \(source)")
                #endif
            }
            
            print (self)
        } else {
            return nil
        }
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
    
    // MARK: - Public
    
    // MARK: - Private

    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetTile: \(gid), (\(textureImageSource ?? "-"), \(Int(textureImageSize!.width)) x \(Int(textureImageSize!.height)))"
    }
    #endif
}
