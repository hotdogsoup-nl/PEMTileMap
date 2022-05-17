import SpriteKit

class PEMTmxSpriteSheet : NSObject {
    private (set) var firstId = UInt32(0)
    
    var lastId: UInt32 {
        return firstId + UInt32((tilesPerRow * tilesPerColumn)) - 1
    }
    private var idRange: ClosedRange<UInt32> {
        return firstId...lastId
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
    
    init?(tileSizeInPoints : CGSize, marginInPoints : UInt, spacingInPoints : UInt, attributes: Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.width.rawValue] else { return nil }
        guard let height = attributes[ElementAttributes.height.rawValue] else { return nil }
        guard let source = attributes[ElementAttributes.source.rawValue] else { return nil }

        super.init()
        
        self.firstId = 0
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
                print("PEMTmxSpriteSheet: tileset <image> size mismatch: \(source)")
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
    
    func createTileData(id: UInt32) -> PEMTmxTileData? {
        let tileAttributes = tileAttributes(fromId: id)

        if contains(id: tileAttributes.id) {
            return PEMTmxTileData(id: id, textureImageSource: textureImageSource!, tileSizeInPoints: tileSizeInPoints)
        }
        
        return nil
    }

    func generateTextureFor(tileData: PEMTmxTileData) -> SKTexture? {
        let tileAttributes = tileAttributes(fromId: tileData.id)
        
        let spriteSheetCoords = CGPoint(x: Int(rowFrom(id: tileAttributes.id)), y: Int(columnFrom(id: tileAttributes.id)))
        var rowInPoints = (((tileSizeInPoints.height + CGFloat(spacingInPoints)) * spriteSheetCoords.x) + CGFloat(marginInPoints)) / textureImageSize!.height
        let columnInPoints = (((tileSizeInPoints.width + CGFloat(spacingInPoints)) * spriteSheetCoords.y) + CGFloat(marginInPoints)) / textureImageSize!.width
        
        rowInPoints = 1.0 - rowInPoints - tileUnitSize!.height
        
        let rect = CGRect(x: columnInPoints, y: rowInPoints, width: tileUnitSize!.width, height: tileUnitSize!.height)
        
        return SKTexture(rect: rect, in: textureImage!)
    }
    
    // MARK: - Private
    
    private func contains(id: UInt32) -> Bool {
        return idRange ~= id
    }
    
    private func rowFrom(id: UInt32) -> UInt {
        return UInt(id) / tilesPerRow
    }
    
    private func columnFrom(id: UInt32) -> UInt {
        return UInt(id) % tilesPerRow
    }
    
    // MARK: - Debug
        
    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetSpriteSheet: \(textureImageSource ?? "-"), (\(tilesPerColumn), \(tilesPerRow))"
    }
    #endif
}
