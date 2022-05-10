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

class PEMTmxTileSet : NSObject {
    private (set) var type = TileSetType.CollectionOfImages
    private (set) var firstGid = UInt32(0)
    private (set) var externalSource : String?
    private (set) var name : String?
    private (set) var tileSizeInPoints = CGSize.zero
    private (set) var spacingInPoints = UInt(0)
    private (set) var marginInPoints = UInt(0)
    private (set) var tileCount = UInt(0)
    private (set) var objectAlignment = ObjectAlignment.Unspecified
    private (set) var tileAtlasImage : SKTexture?
    private (set) var tileAtlasImageSize : CGSize?
    private (set) var tileSetTileUnitSize : CGSize?
    private (set) var tilesPerRow = UInt(0)
    private (set) var tilesPerColumn = UInt(0)
    
    private var lastPossibleGid: UInt32 {
        return firstGid + UInt32((tilesPerRow * tilesPerColumn)) - 1
    }
    
    var globalRange: ClosedRange<UInt32> {
        return firstGid...lastPossibleGid
    }
    
    /// Uses  **TMX** tileset attributes to create and return a new `PEMTmxTileSet` object.
    /// - parameter attributes : Dictionary containing TMX tileset attributes.
    init(attributes: Dictionary<String, String>) {
        super.init()

        if let value = attributes[ElementAttributes.FirstGid.rawValue] {
            firstGid = UInt32(value)!
        }

        externalSource = attributes[ElementAttributes.Source.rawValue]
        name = attributes[ElementAttributes.Name.rawValue]

        if let tilewidth = attributes[ElementAttributes.TileWidth.rawValue],
           let tileheight = attributes[ElementAttributes.TileHeight.rawValue] {
            tileSizeInPoints = CGSize(width: Int(tilewidth)!, height: Int(tileheight)!)
        }

        if let value = attributes[ElementAttributes.Spacing.rawValue] {
            spacingInPoints = UInt(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.Margin.rawValue] {
            marginInPoints = UInt(value) ?? 0
        }

        if let value = attributes[ElementAttributes.TileCount.rawValue] {
            tileCount = UInt(value) ?? 0
        }
    }
    
    deinit {
        #if DEBUG
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #endif
    }
    
    // MARK: - Setup
    
    internal func setTileAtlasImage(attributes: Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return }
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }

        type = .SingleImage
        
        if let path = bundlePathForResource(source) {
            tileAtlasImage = SKTexture(imageNamed: path)
            tileAtlasImageSize = tileAtlasImage?.size()
            tileSetTileUnitSize = CGSize(width: tileSizeInPoints.width / tileAtlasImageSize!.width, height: tileSizeInPoints.height / tileAtlasImageSize!.height)
            
            tilesPerRow = (UInt(tileAtlasImageSize!.width) - marginInPoints * 2 + spacingInPoints) / (UInt(tileSizeInPoints.width) + spacingInPoints)
            tilesPerColumn = (UInt(tileAtlasImageSize!.height) - marginInPoints * 2 + spacingInPoints) / (UInt(tileSizeInPoints.height) + spacingInPoints)
            
            if tileAtlasImageSize!.width != CGFloat(Int(width)!) || tileAtlasImageSize!.height != CGFloat(Int(height)!) {
                #if DEBUG
                print("PEMTmxMap: tileset <image> size mismatch: \(source)")
                #endif
            }
        }
    }
    
    // MARK: - Public
    
    func tileFor(gid: UInt32) -> PEMTmxTile? {
        let tileAttrs = flippedTileFlags(gid: gid)
        var textureGid = UInt32(tileAttrs.gid)
        textureGid -= firstGid
        
        print (textureGid)
        
        
        let atlasCoords = CGPoint(x: Int(rowFrom(gid: textureGid)), y: Int(columnFrom(gid: textureGid)))
        
        
        print (atlasCoords)

        
        
        var rowInPoints = (((tileSizeInPoints.height + CGFloat(spacingInPoints)) * atlasCoords.x) + CGFloat(marginInPoints)) / tileAtlasImageSize!.height
        let columnInPoints = (((tileSizeInPoints.width + CGFloat(spacingInPoints)) * atlasCoords.y) + CGFloat(marginInPoints)) / tileAtlasImageSize!.width
        
        rowInPoints = 1.0 - rowInPoints - tileSetTileUnitSize!.height
        
        let rect = CGRect(x: columnInPoints, y: rowInPoints, width: tileSetTileUnitSize!.width, height: tileSetTileUnitSize!.height)
        
        let texture = SKTexture(rect: rect, in: tileAtlasImage!)
        texture.filteringMode = .nearest
        
        if let tile = tileWithTexture(texture) {
            return tile
        }
        
        return nil
    }
    
    func contains(globalID gid: UInt32) -> Bool {
        return globalRange ~= gid
    }
        
    // MARK: - Private
    
    private func tileWithTexture(_ texture : SKTexture) -> PEMTmxTile? {
        return PEMTmxTile(texture: texture)
    }
    
    private func rowFrom(gid: UInt32) -> UInt {
        return UInt(gid) / tilesPerRow
    }
    
    private func columnFrom(gid: UInt32) -> UInt {
        return UInt(gid) % tilesPerRow
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        var result : String = ""
        
        result += "\nPEMTmxTileSet --"
        result += "\nfirstGid: \(firstGid)"
        result += "\nname: \(String(describing: name))"
        result += "\nexternalSource: \(String(describing: externalSource))"
        result += "\ntileAtlasImage: \(String(describing: tileAtlasImage))"
        result += "\ntileCount: \(tileCount)"

        return result
    }
    #endif
}
