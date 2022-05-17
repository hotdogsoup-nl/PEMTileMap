import Foundation
import SpriteKit

class PEMTmxTileLayer : SKNode, PEMTmxPropertiesProtocol {
    private (set) var visible = true
    private (set) var properties : Dictionary<String, Any>?

    private var id = UInt32(0)
    private var layerName : String?
    private var coordsInTiles = CGPoint.zero // not supported
    private var sizeInTiles = CGSize.zero
    private var opacity = CGFloat(1)
    private var tintColor : SKColor?
    private var offSetInPoints = CGPoint.zero
    private var parallaxFactorX = CGFloat(1)
    private var parallaxFactorY = CGFloat(1)
    
    internal var tileData: [UInt32] = []
    
    private var parentGroup : PEMTmxGroup?
    
    // MARK: - Init

    init?(attributes: Dictionary<String, String>, group: PEMTmxGroup?) {
        guard let layerId = attributes[ElementAttributes.Id.rawValue] else { return nil }
        id = UInt32(layerId)!
        
        super.init()
        
        parentGroup = group
        layerName = attributes[ElementAttributes.Name.rawValue]
        
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
        
        applyParentGroupAttributes()
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

    func render(tileSizeInPoints: CGSize, mapSizeInTiles: CGSize, tileSets: [PEMTmxTileSet], textureFilteringMode: SKTextureFilteringMode) {
        alpha = opacity
        
        position = CGPoint(x: offSetInPoints.x + tileSizeInPoints.width * 0.5, y: -offSetInPoints.y + tileSizeInPoints.height * 0.5)
        
        for index in tileData.indices {
            let tileGid = tileData[index]
            
            if (tileGid == 0) {
                continue
            }
            
            let tileGidAttributes = tileAttributes(fromId: tileGid)
        
            if let tileSet = tileSetFor(gid: tileGidAttributes.id, tileSets: tileSets) {       
                if let tile = tileSet.tileFor(gid: tileGidAttributes.id) {
                    let x: Int = index % Int(mapSizeInTiles.width)
                    let y: Int = index / Int(mapSizeInTiles.width)
                    
                    tile.coords = CGPoint(x: CGFloat(x), y: CGFloat(y))
                    tile.applyTileFlipping(horizontally: tileGidAttributes.flippedHorizontally, vertically: tileGidAttributes.flippedVertically, diagonally: tileGidAttributes.flippedDiagonally)
                    tile.texture?.filteringMode = textureFilteringMode
                    
                    if tintColor != nil {
                        tile.color = tintColor!
                        tile.colorBlendFactor = 1.0
                    }
                    
                    let mapHeightInPoints = sizeInTiles.height * tileSizeInPoints.height
                    let sizeDeviation = CGSize(width: tile.size.width - tileSizeInPoints.width, height: tile.size.height - tileSizeInPoints.height)
                    tile.position = CGPoint(x: (tile.coords!.x * tileSizeInPoints.width) + sizeDeviation.width * 0.5 + tileSet.tileOffSetInPoints.x,
                                            y: mapHeightInPoints - ((tile.coords!.y + 1) * tileSizeInPoints.height) + sizeDeviation.height * 0.5 - tileSet.tileOffSetInPoints.y)
                                        
                    addChild(tile)
                    
                    if tile.animation != nil {
                        var frameTiles: Dictionary<UInt32, SKTexture> = [:]
                        
                        for animationFrame in tile.animation!.frames {
                            if let frameTile = tileSet.tileFor(id: animationFrame.tileId) {
                                frameTile.texture?.filteringMode = textureFilteringMode
                                frameTiles[animationFrame.tileId] = frameTile.texture
                            }
                        }
                        
                        tile.startAnimation(frameTiles: frameTiles)
                    }
                } else {
                    #if DEBUG
                    print("PEMTmxLayer: no tile found with gid: \(tileGid) in tileSet: \(tileSet)")
                    #endif
                }
            } else {
                #if DEBUG
                print("PEMTmxLayer: no tileSet found for tile with gid: \(tileGid)")
                #endif
            }
        }
    }
    
    // MARK: - PEMTmxPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMTmxProperty]) {
        properties = convertProperties(newProperties)
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
    
    private func applyParentGroupAttributes() {
        if parentGroup == nil {
            return
        }

        if let value = parentGroup?.opacity {
            opacity *= CGFloat(value)
        }
                
        if let value = parentGroup?.offSetInPoints {
            offSetInPoints = CGPoint(x: offSetInPoints.x + value.x, y: offSetInPoints.y + value.y)
        }
        
        if let value = parentGroup?.tintColor {
            if tintColor != nil {
                tintColor = tintColor?.multiplyColor(value)
            } else {
                tintColor = value
            }
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxLayer: \(id), (name: \(layerName ?? "-"), zPosition: \(zPosition), parent: \(String(describing: parentGroup)), tiles:\(children.count))"
    }
    #endif
}
