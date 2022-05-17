import Foundation
import SpriteKit

class PEMTmxTileSet : NSObject, PEMTmxPropertiesProtocol {
    enum ObjectAlignment: String {
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
    
    enum PEMTmxTileSetType {
        case SpriteSheet
        case CollectionOfImages
    }
    
    private (set) var firstGid = UInt32(0)
    private (set) var properties : Dictionary<String, Any>?
    private (set) var tileOffSetInPoints = CGPoint.zero

    private var name : String?
    private var tileSizeInPoints = CGSize.zero
    private var tileCount = UInt(0)
    private var objectAlignment = ObjectAlignment.Unspecified // unsupported
    private var spacingInPoints = UInt(0)
    private var marginInPoints = UInt(0)

    private var externalSource : String?
    private var spriteSheet : PEMTmxSpriteSheet?
    private var tileSetType = PEMTmxTileSetType.CollectionOfImages
    private var firstId = UInt32(0)
    private var lastId = UInt32(0)
    private var idRange: ClosedRange<UInt32> {
        return firstId...lastId
    }
        
    private var tileData : [PEMTmxTileData] = []
    
    // MARK: - Init
    
    init?(attributes: Dictionary<String, String>) {
        guard let firstGid = attributes[ElementAttributes.FirstGid.rawValue] else { return nil }

        super.init()
        self.firstGid = UInt32(firstGid)!
        
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
        
        tileSetType = .SpriteSheet
        
        if bundlePathForResource(source) != nil {
            if let newSpriteSheet = PEMTmxSpriteSheet(tileSizeInPoints: tileSizeInPoints, marginInPoints: marginInPoints, spacingInPoints: spacingInPoints, attributes: attributes) {
                spriteSheet = newSpriteSheet
                lastId = newSpriteSheet.lastId
            }
        }
    }
    
    func addOrUpdateTileData(attributes: Dictionary<String, String>) -> PEMTmxTileData? {
        guard let tileIdValue = attributes[ElementAttributes.Id.rawValue] else { return nil }
        let tileId = UInt32(tileIdValue)!
                
        if let existingTile = tileDataFor(id: tileId) {
            existingTile.addAttributes(attributes)
            return existingTile
        }

        if let newTile = PEMTmxTileData(id: tileId, attributes: attributes) {
            tileData.append(newTile)
            
            if tileSetType == .CollectionOfImages {
                let tileDataWithHighestGid = tileData.max(by: { (a, b) -> Bool in
                    return a.id < b.id
                })
                
                lastId = tileDataWithHighestGid!.id
            }
            return newTile
        }
                
        return nil
    }
    
    func setTileOffset(attributes: Dictionary<String, String>) {
        if let dx = attributes[ElementAttributes.X.rawValue],
           let dy = attributes[ElementAttributes.Y.rawValue] {
            tileOffSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }
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
        return tileFor(id: gid - firstGid)
    }
    
    func tileFor(id: UInt32) -> PEMTmxTile? {
        if let tileData = tileData.filter({ $0.id == id }).first {
            if tileSetType == .SpriteSheet && tileData.texture == nil {
                tileData.texture = spriteSheet?.generateTextureFor(tileData: tileData)
            }
            
            return PEMTmxTile(tileData: tileData)
        }
        
        if let newTileData = spriteSheet?.createTileData(id: id) {
            newTileData.texture = spriteSheet?.generateTextureFor(tileData: newTileData)
            tileData.append(newTileData)
            
            return PEMTmxTile(tileData: newTileData)
        }
        
        return nil
    }
    
    func containsTileWith(gid: UInt32) -> Bool {
        return idRange ~=  gid - firstGid
    }
    
    // MARK: - PEMTmxPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMTmxProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func tileDataFor(id: UInt32) -> PEMTmxTileData? {
        return tileData.filter({ $0.id == id }).first
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxTileSet: \(name ?? "-"), (type: \(tileSetType), file: \(externalSource ?? "-"), firstGid: \(firstGid), firstId: \(firstId), lastId: \(lastId))"
    }
    #endif
}
