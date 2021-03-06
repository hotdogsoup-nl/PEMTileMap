import Foundation
import SpriteKit

/// A TMX Tile layer.
/// A layer that contains tiles.
///
/// Documentation: [TMX Tile layer](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#layer)
public class PEMTileLayer: SKNode, PEMTileMapPropertiesProtocol {
    public var parallaxFactorX = CGFloat(1)
    public var parallaxFactorY = CGFloat(1)

    public var properties: Dictionary<String, Any>?
    
    public private (set) var class_: String?
    public private (set) var id = UInt32(0)
    public private (set) var offSetInPoints = CGPoint.zero
    public private (set) var coordsInTiles = CGPoint.zero
    public private (set) var sizeInTiles = CGSize.zero
    public private (set) var opacity = CGFloat(1)
    public private (set) var tintColor: SKColor?
    public private (set) var visible = true

    private var parentGroup: PEMGroupLayer?
    internal var tileData: Array<UInt32> = []
        
    // MARK: - Init

    init?(attributes: Dictionary<String, String>, group: PEMGroupLayer?) {
        super.init()
        
        parentGroup = group
        name = attributes[ElementAttributes.name.rawValue]
        class_ = attributes[ElementAttributes.class_.rawValue]
        
        if let value = attributes[ElementAttributes.id.rawValue] {
            id = UInt32(value)!
        }
        
        if let x = attributes[ElementAttributes.x.rawValue],
           let y = attributes[ElementAttributes.y.rawValue] {
            coordsInTiles = CGPoint(x: Int(x)!, y: Int(y)!)
        }

        if let width = attributes[ElementAttributes.width.rawValue],
           let height = attributes[ElementAttributes.height.rawValue] {
            sizeInTiles = CGSize(width: Int(width)!, height: Int(height)!)
        }
        
        if let value = attributes[ElementAttributes.opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.visible.rawValue] {
            visible = value == "1"
        }
        
        if let value = attributes[ElementAttributes.tintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let dx = attributes[ElementAttributes.offsetX.rawValue],
           let dy = attributes[ElementAttributes.offsetY.rawValue] {
            offSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }
        
        if let value = attributes[ElementAttributes.parallaxX.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorX = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.parallaxY.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorY = CGFloat(valueString.doubleValue)
        }
        
        applyParentGroupAttributes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public

    internal func render(map: PEMTileMap, textureFilteringMode: SKTextureFilteringMode) {
        let tileSizeInPoints = map.tileSizeInPoints()
        let mapSizeInTiles = map.mapSizeInTiles()

        alpha = opacity
        isHidden = !visible
        position = CGPoint(x: offSetInPoints.x, y: -offSetInPoints.y)
        
        for index in tileData.indices {
            let tileGid = tileData[index]
            
            if (tileGid == 0) {
                continue
            }
                    
            if let tileSet = map.tileSetContaining(gid: tileGid) {
                if let tile = tileSet.tileFor(gid: tileGid) {
                    let x: Int = index % Int(mapSizeInTiles.width)
                    let y: Int = index / Int(mapSizeInTiles.width)
                    
                    tile.coords = CGPoint(x: CGFloat(x), y: CGFloat(y))
                    tile.texture?.filteringMode = textureFilteringMode
                    
                    if tintColor != nil {
                        tile.color = tintColor!
                        tile.colorBlendFactor = 1.0
                    }
                    
                    let sizeDeviation = CGSize(width: tile.size.width - tileSizeInPoints.width, height: tile.size.height - tileSizeInPoints.height)
                    tile.position = map.position(tileCoords: tile.coords!, centered: true).with(tileSizeDeviation: sizeDeviation, offset: tileSet.tileOffSetInPoints)

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
                }
            }
        }
    }
    
    // MARK: - PEMTileMapPropertiesProtocol
    
    internal func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func applyParentGroupAttributes() {
        guard parentGroup != nil else { return }

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
    
    internal func tileAt(tileCoords: CGPoint) -> PEMTile? {
        for child in children {
            if let tile = child as? PEMTile {
                if tile.coords == tileCoords {
                    return tile
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Debug
    
    #if DEBUG
    public override var description: String {
        return "PEMTileLayer: \(id), (name: \(name ?? "-"), class: \(class_ ?? "-"), zPosition: \(zPosition), parent: \(String(describing: parentGroup)), tiles: \(children.count))"
    }
    #endif
}
