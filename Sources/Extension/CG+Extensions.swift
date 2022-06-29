import SpriteKit

internal extension CGFloat {
    func radians() -> CGFloat {
        return CGFloat(Double.pi) * (self / 180)
    }
}

internal extension CGPoint {
    func with(tileSizeDeviation: CGSize = .zero, offset: CGPoint = .zero) -> CGPoint {
        return CGPoint(x: x + tileSizeDeviation.width * 0.5 + offset.x, y: y + tileSizeDeviation.height * 0.5 - offset.y)
    }
    
    func add(_ point : CGPoint) -> CGPoint {
        return CGPoint(x: x + point.x, y: y + point.y)
    }

    func subtract(_ point : CGPoint) -> CGPoint {
        return CGPoint(x: x - point.x, y: y - point.y)
    }
}

internal extension CGSize {
    func scaled(_ factor: CGFloat) -> CGSize {
        return CGSize(width: self.width * factor, height: self.height * factor)
    }
}
