import CoreGraphics

extension CGFloat {
    internal func radians() -> CGFloat {
        return CGFloat(Double.pi) * (self / 180)
    }
}

extension CGSize {
    internal func scaled(_ factor: CGFloat) -> CGSize {
        return CGSize(width: self.width * factor, height: self.height * factor)
    }
}
