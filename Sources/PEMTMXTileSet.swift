import Foundation
import SpriteKit

internal enum TileSetType {
    case CollectionOfImages
    case SingleImage
}

internal enum ObjectAlignment: String {
    case Unspecified = "unspecified"
    case TopLeft = "topleft"
    case Top = "top"
    case TopRight = "topright"
    case Left = "left"
    case Center = "center"
    case Right = "right"
    case BottomLeft = "bottomleft"
    case Bottom = "bottom"
    case BottomRight = "bottomright"
}

internal enum TileFlags: Int {
    case Diagonal = 0x20000000
    case Vertical = 0x40000000
    case Horizontal = 0x80000000
    case FlippedAll = 0xe0000000
    case FlippedMask = 0x1fffffff
}

class PEMTMXTileSet : NSObject {
    private (set) var type = TileSetType.CollectionOfImages
    private (set) var firstGid = UInt(0)
    private (set) var externalSource : String?
    private (set) var name : String?
    private (set) var tileSize = CGSize.zero
    private (set) var spacing = UInt(0)
    private (set) var margin = UInt(0)
    private (set) var tileCount = UInt(0)
    private (set) var objectAlignment = ObjectAlignment.Unspecified
    private (set) var tileSetImage : SKTexture?

    init(gId: UInt, attributes: Dictionary<String, String>) {
        firstGid = gId
        externalSource = attributes[ElementAttributes.Source.rawValue]
        name = attributes[ElementAttributes.Name.rawValue]

        let tilewidth = attributes[ElementAttributes.TileWidth.rawValue]!
        let tileheight = attributes[ElementAttributes.TileHeight.rawValue]!

        tileSize = CGSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))

        if let value = attributes[ElementAttributes.Spacing.rawValue] {
            spacing = UInt(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.Margin.rawValue] {
            margin = UInt(value) ?? 0
        }

        if let value = attributes[ElementAttributes.TileCount.rawValue] {
            tileCount = UInt(value) ?? 0
        }

        super.init()
    }
    
    internal func setTileSetImage(attributes : Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return }
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }

        type = .SingleImage
        
        if let path = bundlePathForResource(source) {
            tileSetImage = SKTexture(imageNamed: path)
            
            if tileSetImage?.size().width != CGFloat(Int(width)!) || tileSetImage?.size().height != CGFloat(Int(height)!) {
                #if DEBUG
                print("PEMTMXMap: tileset <image> size mismatch: \(source)")
                #endif
            }
        }
    }
    
    #if DEBUG
    override var description: String {
        var result : String = ""
        
        result += "\nPEMTMXTileSet --"
        result += "\nfirstGid: \(firstGid)"
        result += "\nname: \(String(describing: name))"
        result += "\nexternalSource: \(String(describing: externalSource))"
        result += "\ntileSetImage: \(String(describing: tileSetImage))"
        result += "\ntileCount: \(tileCount)"

        return result
    }
    #endif
}
