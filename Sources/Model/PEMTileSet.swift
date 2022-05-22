import Foundation
import SpriteKit

class PEMTileSet: NSObject, PEMTileMapPropertiesProtocol {
    enum ObjectAlignment: String {
        case bottom = "bottom"
        case bottomLeft = "bottomleft"
        case bottomRight = "bottomright"
        case center = "center"
        case left = "left"
        case right = "right"
        case top = "top"
        case topLeft = "topleft"
        case topRight = "topright"
        case unspecified = "unspecified"
    }
    
    enum PEMTileSetType {
        case collectionOfImages
        case spriteSheet
    }
    
    private (set) var firstGid = UInt32(0)
    private (set) var properties: Dictionary<String, Any>?
    private (set) var tileOffSetInPoints = CGPoint.zero

    private var name: String?
    private var tileSizeInPoints = CGSize.zero
    private var tileCount = UInt(0)
    private var objectAlignment = ObjectAlignment.unspecified // unsupported
    private var spacingInPoints = UInt(0)
    private var marginInPoints = UInt(0)

    private var externalSource: String?
    private var spriteSheet: PEMSpriteSheet?
    private var tileSetType = PEMTileSetType.collectionOfImages
    private var firstId = UInt32(0)
    private var lastId = UInt32(0)
    private var idRange: ClosedRange<UInt32> {
        return firstId...lastId
    }
        
    private var tileData: [PEMTileData] = []
    
    // MARK: - Init
    
    init?(attributes: Dictionary<String, String>) {
        guard let firstGid = attributes[ElementAttributes.firstGid.rawValue] else { return nil }

        super.init()
        self.firstGid = UInt32(firstGid)!
        
        externalSource = attributes[ElementAttributes.source.rawValue]
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
        name = attributes[ElementAttributes.name.rawValue]

        if let tilewidth = attributes[ElementAttributes.tileWidth.rawValue],
           let tileheight = attributes[ElementAttributes.tileHeight.rawValue] {
            tileSizeInPoints = CGSize(width: Int(tilewidth)!, height: Int(tileheight)!)
        }

        if let value = attributes[ElementAttributes.spacing.rawValue] {
            spacingInPoints = UInt(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.margin.rawValue] {
            marginInPoints = UInt(value) ?? 0
        }

        if let value = attributes[ElementAttributes.tileCount.rawValue] {
            tileCount = UInt(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.objectAlignment.rawValue] {
            if let tileSetObjectAlignment = ObjectAlignment(rawValue: value) {
                objectAlignment = tileSetObjectAlignment
            } else {
                #if DEBUG
                print("PEMTileSet: unsupported tileset object alignment: \(String(describing: value))")
                #endif
            }
        }
    }
    
    func setSpriteSheetImage(attributes: Dictionary<String, String>) {
        guard let source = attributes[ElementAttributes.source.rawValue] else { return }
        
        if !tileData.isEmpty {
            #if DEBUG
            print("PEMTileSet: attempt to set a spritesheet on a tileset that already contains <tile> objects: \(self)")
            #endif
            return
        }
        
        tileSetType = .spriteSheet
        
        if bundlePathForResource(source) != nil {
            if let newSpriteSheet = PEMSpriteSheet(tileSizeInPoints: tileSizeInPoints, marginInPoints: marginInPoints, spacingInPoints: spacingInPoints, attributes: attributes) {
                spriteSheet = newSpriteSheet
                lastId = newSpriteSheet.lastId
            }
        }
    }
    
    func addOrUpdateTileData(attributes: Dictionary<String, String>) -> PEMTileData? {
        guard let tileIdValue = attributes[ElementAttributes.id.rawValue] else { return nil }
        let tileId = UInt32(tileIdValue)!
                
        if let existingTile = tileDataFor(id: tileId) {
            existingTile.addAttributes(attributes)
            return existingTile
        }

        if let newTile = PEMTileData(id: tileId, attributes: attributes) {
            tileData.append(newTile)
            
            if tileSetType == .collectionOfImages {
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
        if let dx = attributes[ElementAttributes.x.rawValue],
           let dy = attributes[ElementAttributes.y.rawValue] {
            tileOffSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }
    }
    
    // MARK: - Public
    
    func parseExternalTileSet() {
        guard externalSource != nil else { return }
        
        if let url = bundleURLForResource(externalSource!),
           let parser = PEMTmxParser(tileSet: self, fileURL: url) {
            if (!parser.parse()) {
                #if DEBUG
                print("PEMTileSet: Error parsing external tileset: ", parser.parserError as Any)
                #endif
                return
            }
        } else {
            #if DEBUG
            print("PEMTileSet: External tileset file not found: \(externalSource ?? "-")")
            #endif
            return
        }
    }

    func tileFor(gid: UInt32) -> PEMTile? {
        return tileFor(id: gid - firstGid)
    }
    
    func tileFor(id: UInt32) -> PEMTile? {
        if let tileData = tileData.filter({ $0.id == id }).first {
            if tileSetType == .spriteSheet && tileData.texture == nil {
                tileData.texture = spriteSheet?.generateTextureFor(tileData: tileData)
            }
            
            return PEMTile(tileData: tileData)
        }
        
        if let newTileData = spriteSheet?.createTileData(id: id) {
            newTileData.texture = spriteSheet?.generateTextureFor(tileData: newTileData)
            tileData.append(newTileData)
            
            return PEMTile(tileData: newTileData)
        }
        
        #if DEBUG
        print("PEMTileSet: no tile found with id: \(id) in tileSet: \(self)")
        #endif
        
        return nil
    }
    
    func containsTileWith(gid: UInt32) -> Bool {
        return idRange ~=  gid - firstGid
    }
    
    // MARK: - PEMTileMapPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func tileDataFor(id: UInt32) -> PEMTileData? {
        return tileData.filter({ $0.id == id }).first
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTileSet: \(name ?? "-"), (type: \(tileSetType), file: \(externalSource ?? "-"), firstGid: \(firstGid), firstId: \(firstId), lastId: \(lastId))"
    }
    #endif
}
