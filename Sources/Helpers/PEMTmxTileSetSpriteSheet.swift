import SpriteKit

class PEMTmxTileSetSpriteSheet : NSObject {
    private var firstGid = UInt32(0)
    private var tileSizeInPoints = CGSize.zero
    private var marginInPoints = UInt(0)
    private var spacingInPoints = UInt(0)
    
    private var lastPossibleGid: UInt32 {
        return firstGid + UInt32((tilesPerRow * tilesPerColumn)) - 1
    }

    var globalRange: ClosedRange<UInt32> {
        return firstGid...lastPossibleGid
    }

    private var spriteSheetImage : SKTexture?
    private var spriteSheetImageSize : CGSize?
    private var spriteSheetImageSource : String?
    private var spriteSheetTileUnitSize : CGSize?
    private var tilesPerRow = UInt(0)
    private var tilesPerColumn = UInt(0)
    
    // MARK: - Init
    
    init?(firstGid : UInt32, tileSizeInPoints : CGSize, marginInPoints : UInt, spacingInPoints : UInt) {
        super.init()
        
        self.firstGid = firstGid
        self.tileSizeInPoints = tileSizeInPoints
        self.marginInPoints = marginInPoints
        self.spacingInPoints = spacingInPoints
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
    
    func parseAttributes(_ attributes: Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return }
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }
        
        if let path = bundlePathForResource(source) {
            spriteSheetImageSource = source
            spriteSheetImage = SKTexture(imageNamed: path)
            spriteSheetImageSize = spriteSheetImage?.size()
            spriteSheetTileUnitSize = CGSize(width: tileSizeInPoints.width / spriteSheetImageSize!.width, height: tileSizeInPoints.height / spriteSheetImageSize!.height)
            
            tilesPerRow = (UInt(spriteSheetImageSize!.width) - marginInPoints * 2 + spacingInPoints) / (UInt(tileSizeInPoints.width) + spacingInPoints)
            tilesPerColumn = (UInt(spriteSheetImageSize!.height) - marginInPoints * 2 + spacingInPoints) / (UInt(tileSizeInPoints.height) + spacingInPoints)
            
            if spriteSheetImageSize!.width != CGFloat(Int(width)!) || spriteSheetImageSize!.height != CGFloat(Int(height)!) {
                #if DEBUG
                print("PEMTmxMap: tileset <image> size mismatch: \(source)")
                #endif
            }
        }
    }
    
    // MARK: - Public
    
    func tileFromSpriteSheetFor(gid: UInt32, textureFilteringMode: SKTextureFilteringMode) -> PEMTmxTile? {
        let tileAttributes = tileAttributes(fromGid: gid)
        let textureGid = tileAttributes.gid - firstGid
        
        let spriteSheetCoords = CGPoint(x: Int(rowFrom(gid: textureGid)), y: Int(columnFrom(gid: textureGid)))
        var rowInPoints = (((tileSizeInPoints.height + CGFloat(spacingInPoints)) * spriteSheetCoords.x) + CGFloat(marginInPoints)) / spriteSheetImageSize!.height
        let columnInPoints = (((tileSizeInPoints.width + CGFloat(spacingInPoints)) * spriteSheetCoords.y) + CGFloat(marginInPoints)) / spriteSheetImageSize!.width
        
        rowInPoints = 1.0 - rowInPoints - spriteSheetTileUnitSize!.height
        
        let rect = CGRect(x: columnInPoints, y: rowInPoints, width: spriteSheetTileUnitSize!.width, height: spriteSheetTileUnitSize!.height)
        
        let texture = SKTexture(rect: rect, in: spriteSheetImage!)
        texture.filteringMode = textureFilteringMode
        
        return PEMTmxTile(texture: texture)
    }
    
    // MARK: - Private
    
    private func rowFrom(gid: UInt32) -> UInt {
        return UInt(gid) / tilesPerRow
    }
    
    private func columnFrom(gid: UInt32) -> UInt {
        return UInt(gid) % tilesPerRow
    }
    
    // MARK: - Debug
        
    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetSpriteSheet: \(spriteSheetImageSource ?? "-"), (\(tilesPerColumn), \(tilesPerRow)"
    }
    #endif
}
