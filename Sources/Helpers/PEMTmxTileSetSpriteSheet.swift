import SpriteKit

class PEMTmxTileSetSpriteSheet : NSObject {
    private var firstGid = UInt32(0)
    var lastGid: UInt32 {
        return firstGid + UInt32((tilesPerRow * tilesPerColumn)) - 1
    }
    
    private var tileSizeInPoints = CGSize.zero
    private var marginInPoints = UInt(0)
    private var spacingInPoints = UInt(0)
    
    private var textureImage : SKTexture?
    private var textureImageSize : CGSize?
    private var textureImageSource : String?
    private var tileUnitSize : CGSize?
    private var tilesPerRow = UInt(0)
    private var tilesPerColumn = UInt(0)
    
    // MARK: - Init
    
    init?(firstGid : UInt32, tileSizeInPoints : CGSize, marginInPoints : UInt, spacingInPoints : UInt, attributes: Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return nil }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return nil }
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return nil }

        super.init()
        
        self.firstGid = firstGid
        self.tileSizeInPoints = tileSizeInPoints
        self.marginInPoints = marginInPoints
        self.spacingInPoints = spacingInPoints
        
        if let path = bundlePathForResource(source) {
            textureImageSource = source
            textureImage = SKTexture(imageNamed: path)
            textureImageSize = textureImage?.size()
            tileUnitSize = CGSize(width: tileSizeInPoints.width / textureImageSize!.width, height: tileSizeInPoints.height / textureImageSize!.height)
            
            tilesPerRow = (UInt(textureImageSize!.width) - marginInPoints * 2 + spacingInPoints) / (UInt(tileSizeInPoints.width) + spacingInPoints)
            tilesPerColumn = (UInt(textureImageSize!.height) - marginInPoints * 2 + spacingInPoints) / (UInt(tileSizeInPoints.height) + spacingInPoints)
            
            if textureImageSize!.width != CGFloat(Int(width)!) || textureImageSize!.height != CGFloat(Int(height)!) {
                #if DEBUG
                print("PEMTmxTileSetSpriteSheet: tileset <image> size mismatch: \(source)")
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
        
    // MARK: - Public
    
    func generateTileSetTiles() -> [PEMTmxTileSetTile]? {
        var result : [PEMTmxTileSetTile] = []
        for gid in firstGid...lastGid {
            if let newTile = createTile(gid: gid) {
                result.append(newTile)
            }
        }
        return result
    }
    
    func generateTextureFor(tileSetTile: PEMTmxTileSetTile) -> SKTexture? {
        let tileAttributes = tileAttributes(fromGid: tileSetTile.gid)
        let textureGid = tileAttributes.gid - firstGid
        
        let spriteSheetCoords = CGPoint(x: Int(rowFrom(gid: textureGid)), y: Int(columnFrom(gid: textureGid)))
        var rowInPoints = (((tileSizeInPoints.height + CGFloat(spacingInPoints)) * spriteSheetCoords.x) + CGFloat(marginInPoints)) / textureImageSize!.height
        let columnInPoints = (((tileSizeInPoints.width + CGFloat(spacingInPoints)) * spriteSheetCoords.y) + CGFloat(marginInPoints)) / textureImageSize!.width
        
        rowInPoints = 1.0 - rowInPoints - tileUnitSize!.height
        
        let rect = CGRect(x: columnInPoints, y: rowInPoints, width: tileUnitSize!.width, height: tileUnitSize!.height)
        
        let texture = SKTexture(rect: rect, in: textureImage!)
        texture.filteringMode = .nearest
        
        return texture
    }
    
    // MARK: - Private
    
    private func createTile(gid: UInt32) -> PEMTmxTileSetTile? {
        return PEMTmxTileSetTile(gid: gid, textureImageSource: textureImageSource!, tileSizeInPoints: tileSizeInPoints)
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
        return "PEMTmxTileSetSpriteSheet: \(textureImageSource ?? "-"), (\(tilesPerColumn), \(tilesPerRow))"
    }
    #endif
}
