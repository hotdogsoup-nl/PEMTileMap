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
    private var spriteSheet : PEMTmxTileSetSpriteSheet?
    private var firstGid = UInt32(0)
    private var lastGid = UInt32(0)
    private var gidRange: ClosedRange<UInt32> {
        return firstGid...lastGid
    }
        
    private var tileData : [PEMTmxTileSetTileData] = []
    
    // MARK: - Init
    
    init?(attributes: Dictionary<String, String>) {
        guard let firstGid = attributes[ElementAttributes.FirstGid.rawValue] else { return nil }

        super.init()

        self.firstGid = UInt32(firstGid)!
        self.lastGid = self.firstGid

        externalSource = attributes[ElementAttributes.Source.rawValue]
        if externalSource == nil {
            addAttributes(attributes)
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
    
    func addAttributes(_ attributes: Dictionary<String, String>) {
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
                print("PEMTmxTileSet: unsupported tileset object alignment: \(String(describing: value))")
                #endif
            }
        }
    }
    
    func setSpriteSheetImage(attributes: Dictionary<String, String>) {
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }
        
        if !tileData.isEmpty {
            #if DEBUG
            print("PEMTmxTileSet: attempt to set a spritesheet on a tileset that already contains <tile> objects: \(self)")
            #endif
            return
        }
        
        if bundlePathForResource(source) != nil {
            if let newSpriteSheet = PEMTmxTileSetSpriteSheet(firstGid: firstGid, tileSizeInPoints: tileSizeInPoints, marginInPoints: marginInPoints, spacingInPoints: spacingInPoints, attributes: attributes) {
                spriteSheet = newSpriteSheet
                lastGid = newSpriteSheet.lastGid
            }
        }
    }
    
    func addOrUpdateTileData(attributes: Dictionary<String, String>) -> PEMTmxTileSetTileData? {
        guard let tileID = attributes[ElementAttributes.Id.rawValue] else { return nil }
        let tileGid = firstGid + UInt32(tileID)!
                
        if let existingTile = tileSetTileDataFor(gid: tileGid) {
            existingTile.addAttributes(attributes)
            return existingTile
        }

        if let newTile = PEMTmxTileSetTileData(gid: tileGid, attributes: attributes) {
            tileData.append(newTile)

            let tileDataWithHighestGid = tileData.max(by: { (a, b) -> Bool in
                return a.gid < b.gid
            })
            
            lastGid = tileDataWithHighestGid!.gid
            return newTile
        }
                
        return nil
    }
    
    // MARK: - Public
    
    func parseExternalTileSet() {
        if externalSource == nil {
            return
        }
        
        if let url = bundleURLForResource(externalSource!),
           let parser = PEMTmxParser(tileSet: self, fileURL: url) {
            if (!parser.parse()) {
                #if DEBUG
                print("PEMTmxTileSet: Error parsing external tileset: ", parser.parserError as Any)
                #endif
                return
            }
        } else {
            #if DEBUG
            print("PEMTmxTileSet: External tileset file not found: \(externalSource ?? "-")")
            #endif
            return
        }
    }

    func tileFor(gid: UInt32) -> PEMTmxTile? {
        if let tilesetTileData = tileData.filter({ $0.gid == gid }).first {
            if tilesetTileData.usesSpriteSheet && tilesetTileData.texture == nil {
                tilesetTileData.texture = spriteSheet?.generateTextureFor(tileSetTileData: tilesetTileData)
            }
            
            return PEMTmxTile(tileSetTileData: tilesetTileData)
        }
        
        if let newTileData = spriteSheet?.createTileSetTileData(gid: gid) {
            newTileData.texture = spriteSheet?.generateTextureFor(tileSetTileData: newTileData)
            tileData.append(newTileData)
            
            return PEMTmxTile(tileSetTileData: newTileData)
        }
        
        return nil
    }
    
    func contains(globalID gid: UInt32) -> Bool {
        return gidRange ~= gid
    }
    
    // MARK: - Private
    
    private func tileSetTileDataFor(gid: UInt32) -> PEMTmxTileSetTileData? {
        return tileData.filter({ $0.gid == gid }).first
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxTileSet: \(name ?? "-"), (file: \(externalSource ?? "-"), firstGid: \(firstGid), lastGid: \(lastGid))"
    }
    #endif
}
