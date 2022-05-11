import SpriteKit

class PEMTmxTile : SKSpriteNode {
    var coords : CGPoint?
    var gid = UInt32(0)
    var flippedHorizontally : Bool = false { didSet { updateFlip() } }
    var flippedVertically : Bool = false { didSet { updateFlip() } }
    var flippedDiagonally : Bool = false { didSet { updateFlip() } }
    
    // MARK: - Init
    
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
        return "PEMTmxTile: \(gid), (\(Int(coords!.x)), \(Int(coords!.y)))"
    }
    #endif
}
