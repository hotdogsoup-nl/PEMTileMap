import SpriteKit

class PEMTmxTile : SKSpriteNode {
    var coords : CGPoint?
    var flippedHorizontally : Bool = false { didSet { updateFlip() } }
    var flippedVertically : Bool = false { didSet { updateFlip() } }
    var flippedDiagonally : Bool = false { didSet { updateFlip() } }
    
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
}
