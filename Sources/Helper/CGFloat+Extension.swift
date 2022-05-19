import SpriteKit

extension CGFloat {
    internal func radians() -> CGFloat {
        return CGFloat(Double.pi) * (self / 180)
    }
}
