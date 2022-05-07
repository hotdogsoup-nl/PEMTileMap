import Foundation
import SpriteKit

internal enum TileFlags: Int {
    case Diagonal = 0x20000000
    case Vertical = 0x40000000
    case Horizontal = 0x80000000
    case FlippedAll = 0xe0000000
    case FlippedMask = 0x1fffffff
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

class PEMTMXTileSet : NSObject {
    private (set) var firstGid = UInt(0)
    private (set) var source : String?
    private (set) var name : String?
    private (set) var tileSize = CGSize.zero
    private (set) var maxTileSize = CGSize.zero
    private (set) var unitTileSize = CGSize.zero
    private (set) var spacing = UInt(0)
    private (set) var margin = UInt(0)
    private (set) var tileCount = UInt(0)
    private (set) var imageSize = CGSize.zero
    private (set) var objectAlignment = ObjectAlignment.Unspecified
    
    init(gId: UInt, attributes: Dictionary<String, String>) {
        firstGid = gId
        source = attributes[XMLAttributeSource]
        name = attributes[XMLAttributeName]

        let tilewidth = attributes[XMLAttributeTileWidth]!
        let tileheight = attributes[XMLAttributeTileHeight]!

        tileSize = CGSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))

        if let value = attributes[XMLAttributeSpacing] {
            spacing = UInt(value) ?? 0
        }
        
        if let value = attributes[XMLAttributeMargin] {
            margin = UInt(value) ?? 0
        }

        if let value = attributes[XMLAttributeTileCount] {
            tileCount = UInt(value) ?? 0
        }

        super.init()
    }
    
    #if DEBUG
    override var description: String {
        var result : String = ""
        
        result += "\nPEMTMXTileSet --"
        result += "\nfirstGid: \(firstGid)"
        result += "\nsource: \(String(describing: source))"
        result += "\nname: \(String(describing: name))"
        result += "\ntileCount: \(tileCount)"

        return result
    }
    #endif
}
