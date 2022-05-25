import SpriteKit

class PEMTile: SKSpriteNode {
    var coords: CGPoint?

    private (set) var id = UInt32(0)
    private (set) var animation: PEMTileAnimation?
    private (set) var properties: Dictionary<String, Any>?

    private var type: String?
    private var probability = CGFloat(0)

    // MARK: - Init
    
    init?(tileData: PEMTileData) {
        if let texture = tileData.texture {
            super.init(texture: texture, color: .clear, size: texture.size())
            
            id = tileData.id
            type = tileData.type
            probability = tileData.probability
            animation = tileData.animation
            properties = tileData.properties
            
            return
        }
        
        return nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(Swift.type(of: self))")
        #endif
        #endif
    }
    
    // MARK: - Setup
    
    func applyTileFlipping(horizontally: Bool, vertically: Bool, diagonally: Bool) {
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
    
    func startAnimation(frameTiles: Dictionary<UInt32, SKTexture>) {
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
    override var description: String {
        return "PEMTile: \(id), type: \(type ?? "-"), (\(Int(coords?.x ?? 0)), \(Int(coords?.y ?? 0)))"
    }
    #endif
}
