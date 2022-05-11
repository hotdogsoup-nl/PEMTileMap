import Foundation
import SpriteKit

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

class PEMTmxTileSet : NSObject {
    private (set) var name : String?
    private (set) var tileSizeInPoints = CGSize.zero
    private (set) var tileCount = UInt(0)
    private (set) var objectAlignment = ObjectAlignment.Unspecified // unsupported
    private (set) var spacingInPoints = UInt(0)
    private (set) var marginInPoints = UInt(0)

    private var externalSource : String?
    private var firstGid = UInt32(0)
    private var lastGid: UInt32 {
        if spriteSheet != nil {
            return spriteSheet!.lastGid
        }
        return tiles.last?.gid ?? 0
    }
    private var gidRange: ClosedRange<UInt32> {
        return firstGid...lastGid
    }
    
    // spritesheet
    private var spriteSheet : PEMTmxTileSetSpriteSheet?
    
    // tiles as separate images
    private var tiles : [PEMTmxTileSetTile] = []
    
    // MARK: - Init
    
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
        
        if let value = attributes[ElementAttributes.ObjectAlignment.rawValue] {
            if let tileSetObjectAlignment = ObjectAlignment(rawValue: value) {
                objectAlignment = tileSetObjectAlignment
            } else {
                #if DEBUG
                print("PEMTmxMap: unsupported tileset object alignment: \(String(describing: value))")
                #endif
            }
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
    
    func setSpriteSheetImage(attributes: Dictionary<String, String>) {
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }
        
        if bundlePathForResource(source) != nil {
            if let newSpriteSheet = PEMTmxTileSetSpriteSheet(firstGid: firstGid, tileSizeInPoints: tileSizeInPoints, marginInPoints: marginInPoints, spacingInPoints: spacingInPoints) {
                newSpriteSheet.parseAttributes(attributes)
                spriteSheet = newSpriteSheet
            }
        }
    }
    
    func addTileImage(id: UInt32, attributes: Dictionary<String, String>) {
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }

        if bundlePathForResource(source) != nil {
            if let newTile = PEMTmxTileSetTile(gid: firstGid + id, attributes: attributes) {
                tiles.append(newTile)
            }
        }
    }
    
    // MARK: - Public

    func tileFor(gid: UInt32, textureFilteringMode: SKTextureFilteringMode) -> PEMTmxTile? {
        if spriteSheet != nil {
            return spriteSheet!.tileFor(gid: gid, textureFilteringMode: textureFilteringMode)
        }
        
        return tileSetTileFor(gid: gid, textureFilteringMode: textureFilteringMode)
    }
        
    func contains(globalID gid: UInt32) -> Bool {
        return gidRange ~= gid
    }
    
    // MARK: - Private
    
    private func tileSetTileFor(gid: UInt32, textureFilteringMode: SKTextureFilteringMode) -> PEMTmxTile? {
        if let tile = tiles.filter({ $0.gid == gid }).first {
            return PEMTmxTile(texture: tile.textureImage)
        }
        
        return nil
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxTileSet: \(name ?? "-"), (firstGid: \(firstGid), lastGid: \(lastGid))"
    }
    #endif
}
