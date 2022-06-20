import CoreGraphics

internal func polygonPath(_ points: [CGPoint], closed: Bool = true) -> CGPath {
    let path = CGMutablePath();

    let startPoint = points[0]
    path.move(to: startPoint)
    
    for index in 1 ..< points.count {
        let p = points[index]
        path.addLine(to: p)
    }
    
    if (closed) {
        path.closeSubpath()
    }
    
    return path
}
