import SpriteKit

class PEMTmxTile : SKSpriteNode {
    private (set) var id = UInt32(0)
    var coords : CGPoint?
    var flippedHorizontally : Bool = false { didSet { updateFlip() } }
    var flippedVertically : Bool = false { didSet { updateFlip() } }
    var flippedDiagonally : Bool = false { didSet { updateFlip() } }
    // MARK: - Init
    
    init?(tileSetTileData: PEMTmxTileSetTileData) {
        if let texture = tileSetTileData.texture {
            super.init(texture: texture, color: .clear, size: texture.size())
            
            id = tileSetTileData.id
            type = tileSetTileData.type
            probability = tileSetTileData.probability
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
        print("deinit: \(type(of: self))")
        #endif
        #endif
    }
    
    // MARK: - Setup
    
    func updateFlip() {
        if (flippedDiagonally) {
            if (flippedHorizontally && !flippedVertically) {
                zRotation = CGFloat(-Double.pi / 2)
            }

            if (flippedHorizontally && flippedVertically) {
                zRotation = CGFloat(-Double.pi / 2)
                xScale *= -1
            }

            if (!flippedHorizontally && flippedVertically) {
                zRotation = CGFloat(Double.pi / 2)
            }

            if (!flippedHorizontally && !flippedVertically) {
                zRotation = CGFloat(Double.pi / 2)
                xScale *= -1
            }
        } else {
            if (flippedHorizontally == true) {
                xScale *= -1
            }

            if (flippedVertically == true) {
                yScale *= -1
            }
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxTile: \(id), type: \(type ?? "-"), (\(Int(coords?.x ?? 0)), \(Int(coords?.y ?? 0)))"
    }
    #endif
}
