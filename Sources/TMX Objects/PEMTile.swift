import SpriteKit

/// A TMX Tile object.
///
/// Documentation: [TMX Tile](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tile)
public class PEMTile: SKSpriteNode {
    public var properties: Dictionary<String, Any>?
    public var class_: String?

    public private (set) var id = UInt32(0)
    public internal (set) var coords: CGPoint?

    private (set) var animation: PEMTileAnimation?
    private var probability = CGFloat(0)    

    // MARK: - Init
    
    init?(tileData: PEMTileData, flippedHorizontally: Bool = false, flippedVertically: Bool = false, flippedDiagonally: Bool = false) {
        if let texture = tileData.texture {
            super.init(texture: texture, color: .clear, size: texture.size())
            
            id = tileData.id
            probability = tileData.probability
            animation = tileData.animation
            properties = tileData.properties
            class_ = tileData.class_
                        
            applyTileFlipping(horizontally: flippedHorizontally, vertically: flippedVertically, diagonally: flippedDiagonally)
            return
        }
        
        return nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func applyTileFlipping(horizontally: Bool, vertically: Bool, diagonally: Bool) {
        if diagonally {
            if (horizontally && !vertically) {
                zRotation = CGFloat(-Double.pi / 2)
            }

            if (horizontally && vertically) {
                zRotation = CGFloat(-Double.pi / 2)
                xScale *= -1
            }

            if (!horizontally && vertically) {
                zRotation = CGFloat(Double.pi / 2)
            }

            if (!horizontally && !vertically) {
                zRotation = CGFloat(Double.pi / 2)
                xScale *= -1
            }
        } else {
            if horizontally {
                xScale *= -1
            }

            if vertically {
                yScale *= -1
            }
        }
    }
    
    // MARK: - Public
    
    internal func startAnimation(frameTiles: Dictionary<UInt32, SKTexture>) {
        guard animation != nil, frameTiles.count > 0 else { return }
                
        var actions : Array<SKAction> = []
                
        for frame in animation!.frames {
            if let texture = frameTiles[frame.tileId] {
                actions.append(SKAction.setTexture(texture))
                actions.append(SKAction.wait(forDuration: Double(frame.duration) / 1000))
            }
        }
        
        run(SKAction.repeatForever(SKAction.sequence(actions)))
    }
        
    // MARK: - Debug
    
    #if DEBUG
    public override var description: String {
        return "PEMTile: \(id), class: \(class_ ?? "-"), (\(Int(coords?.x ?? 0)), \(Int(coords?.y ?? 0)))"
    }
    #endif
}
