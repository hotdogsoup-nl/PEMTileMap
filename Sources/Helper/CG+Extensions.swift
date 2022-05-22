import SpriteKit

extension CGFloat {
    internal func radians() -> CGFloat {
        return CGFloat(Double.pi) * (self / 180)
    }
}

extension CGPoint {
    func add(_ point : CGPoint) -> CGPoint {
        return CGPoint(x: x + point.x, y: y + point.y)
    }

    func subtract(_ point : CGPoint) -> CGPoint {
        return CGPoint(x: x - point.x, y: y - point.y)
    }

    func multiplyScalar(_ value : CGFloat) -> CGPoint {
        return CGPointFromGLKVector2(GLKVector2MultiplyScalar(GLKVector2FromCGPoint(self), Float(value)))
    }

    private func CGPointFromGLKVector2(_ vector : GLKVector2) -> CGPoint {
        return CGPoint(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }

    private func GLKVector2FromCGPoint(_ point : CGPoint ) -> GLKVector2 {
        return GLKVector2Make(Float(point.x), Float(point.y))
    }
}

extension CGSize {
    internal func scaled(_ factor: CGFloat) -> CGSize {
        return CGSize(width: self.width * factor, height: self.height * factor)
    }
}
