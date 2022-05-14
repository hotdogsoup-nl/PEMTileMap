import Foundation
import SpriteKit

class PEMTmxTileLayer : SKNode {
    private (set) var layerId : String?
    private (set) var layerName : String?
    private (set) var visible = true

    private var coordsInTiles = CGPoint.zero // not supported
    private var sizeInTiles = CGSize.zero
    private var opacity = CGFloat(1)
    private var tintColor : SKColor?
    private var offSetInPoints = CGPoint.zero
    private var parallaxFactorX = CGFloat(1)
    private var parallaxFactorY = CGFloat(1)
    
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

    func renderTiles(tileSizeInPoints: CGSize, mapSizeInTiles: CGSize, tileSets: [PEMTmxTileSet], textureFilteringMode: SKTextureFilteringMode) {
        alpha = opacity
        position = CGPoint(x: offSetInPoints.x, y: -offSetInPoints.y)
        
        for index in tileData.indices {
            let tileGid = tileData[index]
            
            if (tileGid == 0) {
                continue
            }
            
            let tileAttributes = tileAttributes(fromId: tileGid)
        
            if let tileSet = tileSetFor(gid: tileAttributes.id, tileSets: tileSets) {                
                if let tile = tileSet.tileFor(gid: tileAttributes.id) {
                    let x: Int = index % Int(mapSizeInTiles.width)
                    let y: Int = index / Int(mapSizeInTiles.width)
                    
                    tile.coords = CGPoint(x: CGFloat(x), y: CGFloat(y))
                    tile.applyTileFlipping(horizontally: tileAttributes.flippedHorizontally, vertically: tileAttributes.flippedVertically, diagonally: tileAttributes.flippedDiagonally)
                    tile.texture?.filteringMode = textureFilteringMode
                    
                    if tintColor != nil {
                        tile.color = tintColor!
                        tile.colorBlendFactor = 1.0
                    }
                    
                    let mapHeightInPoints = sizeInTiles.height * tileSizeInPoints.height
                    tile.anchorPoint = .zero
                    tile.position = CGPoint(x: tile.coords!.x * tileSizeInPoints.width,
                                            y: mapHeightInPoints - ((tile.coords!.y + 1) * tileSizeInPoints.height))
                                        
                    addChild(tile)
                    
                    if tile.animation != nil {
                        var frameTiles: Dictionary<UInt32, SKTexture> = [:]
                        
                        for animationFrame in tile.animation!.frames {
                            print(animationFrame)
                            
                            if let frameTile = tileSet.tileFor(gid: animationFrame.tileId) {
                                frameTiles[animationFrame.tileId] = frameTile.texture
                            }
                        }
                        
                    }
                } else {
                    #if DEBUG
                    print("PEMTmxTileLayer: no tile found with gid: \(tileGid) in tileSet: \(tileSet)")
                    #endif
                }
            } else {
                #if DEBUG
                print("PEMTmxTileLayer: no tileSet found for tile with gid: \(tileGid)")
                #endif
            }
        }
    }
    
    // MARK: - Private

    private func tileSetFor(gid: UInt32, tileSets: [PEMTmxTileSet]) -> PEMTmxTileSet? {
        let tileAttributes = tileAttributes(fromId: gid)

        for tileSet in tileSets {
            if tileSet.containsTileWith(gid: tileAttributes.id) {
                return tileSet
            }
        }
        return nil
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxTileLayer: \(layerId ?? "-"), (name: \(layerName ?? "-"), zPosition: \(zPosition), tiles:\(children.count))"
    }
    #endif
}
