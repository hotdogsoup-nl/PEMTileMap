import SpriteKit

func CGPointMultiplyScalar(_ point: CGPoint, _ value : CGFloat) -> CGPoint {
    return CGPointFromGLKVector2(GLKVector2MultiplyScalar(GLKVector2FromCGPoint(point), Float(value)))
}

func CGPointFromGLKVector2(_ vector : GLKVector2) -> CGPoint {
    return CGPoint(x: CGFloat(vector.x), y: CGFloat(vector.y))
}

func GLKVector2FromCGPoint(_ point : CGPoint ) -> GLKVector2 {
    return GLKVector2Make(Float(point.x), Float(point.y))
}

func CGPointAdd(_ point1 : CGPoint, _ point2 : CGPoint) -> CGPoint {
    return CGPoint(x: point1.x + point2.x, y: point1.y + point2.y)
}

func CGPointSubtract(_ point1 : CGPoint, _ point2 : CGPoint) -> CGPoint {
    return CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
}
