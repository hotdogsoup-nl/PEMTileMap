import Foundation
import SpriteKit

class PEMTmxTileLayer : SKNode {
    private (set) var layerId : String?
    private (set) var layerName : String?
    
    private (set) var coordsInTiles = CGPoint.zero // not supported
    private (set) var sizeInTiles = CGSize.zero
    private (set) var opacity = CGFloat(1)
    private (set) var visible = true
    private (set) var tintColor : SKColor?
    private (set) var offSetInPoints = CGPoint.zero
    private (set) var parallaxFactorX = CGFloat(1)
    private (set) var parallaxFactorY = CGFloat(1)
    
    internal var tileData: [UInt32] = []
    
    // MARK: - Init

    init(attributes: Dictionary<String, String>) {
        super.init()
        
        if let value = attributes[ElementAttributes.Id.rawValue] {
            layerId = value
        }

        if let value = attributes[ElementAttributes.Name.rawValue] {
            layerName = value
        }
        
        if let x = attributes[ElementAttributes.X.rawValue],
           let y = attributes[ElementAttributes.Y.rawValue] {
            coordsInTiles = CGPoint(x: Int(x)!, y: Int(y)!)
        }

        if let width = attributes[ElementAttributes.Width.rawValue],
           let height = attributes[ElementAttributes.Height.rawValue] {
            sizeInTiles = CGSize(width: Int(width)!, height: Int(height)!)
        }
        
        if let value = attributes[ElementAttributes.Opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.Visible.rawValue] {
            visible = value == "1"
        }
        
        if let value = attributes[ElementAttributes.TintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let dx = attributes[ElementAttributes.OffsetX.rawValue],
           let dy = attributes[ElementAttributes.OffsetY.rawValue] {
            offSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }
        
        if let value = attributes[ElementAttributes.ParallaxX.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorX = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.ParallaxY.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorY = CGFloat(valueString.doubleValue)
        }        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func generateTiles(mapSizeInTiles: CGSize, tileSets: [PEMTmxTileSet], textureFilteringMode: SKTextureFilteringMode) {
        alpha = opacity
        position = CGPoint(x: offSetInPoints.x, y: -offSetInPoints.y)
        
        for index in tileData.indices {
            let tileIdFromData = tileData[index]
            
            if (tileIdFromData == 0) {
                continue
            }
            
            let tileAttributes = tileAttributes(fromGid: tileIdFromData)
        
            if let tileSet = tileSetFor(gid: tileAttributes.gid, tileSets: tileSets) {
                if let tile = tileSet.tileFor(gid: tileAttributes.gid) {
                    let x: Int = index % Int(mapSizeInTiles.width)
                    let y: Int = index / Int(mapSizeInTiles.width)
                    
                    tile.gid = tileAttributes.gid
                    tile.coords = CGPoint(x: CGFloat(x), y: CGFloat(y))
                    tile.flippedHorizontally = tileAttributes.flippedHorizontally
                    tile.flippedVertically = tileAttributes.flippedVertically
                    tile.flippedDiagonally = tileAttributes.flippedDiagonally
                                        
                    addTile(tile)
                } else {
                    #if DEBUG
                    print("PEMTmxTileLayer: no tile found with gid: \(tileAttributes.gid) in tileSet: \(tileSet)")
                    #endif
                }
            } else {
                #if DEBUG
                print("PEMTmxTileLayer: no tileSet found for tile with gid: \(tileAttributes.gid)")
                #endif
            }
        }
    }
    
    // MARK: - Private

    private func tileSetFor(gid: UInt32, tileSets: [PEMTmxTileSet]) -> PEMTmxTileSet? {
        for tileSet in tileSets {
            if tileSet.contains(globalID: gid) {
                return tileSet
            }
        }
        return nil
    }
    
    private func addTile(_ tile: PEMTmxTile) {
        if tintColor != nil {
            tile.color = tintColor!
            tile.colorBlendFactor = 1.0
        }
        
        let mapHeightInPoints = sizeInTiles.height * tile.size.height
        tile.position = CGPoint(x: tile.coords!.x * tile.size.width + tile.size.width * 0.5,
                                y: mapHeightInPoints - (tile.coords!.y * tile.size.height + tile.size.height * 0.5))
        addChild(tile)
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxTileLayer: \(layerId ?? "-"), (name: \(layerName ?? "-"), zPosition: \(zPosition))"
    }
    #endif
}
