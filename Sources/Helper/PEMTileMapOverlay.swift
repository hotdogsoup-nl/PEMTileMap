import SpriteKit

internal func mapCanvas(size: CGSize, name: String? = nil) -> SKSpriteNode {
    let canvas = SKSpriteNode(color: .red, size: size)
    canvas.anchorPoint = CGPoint(x: 0, y: 0)
    canvas.name = name
    return canvas
}

internal func mapGrid(sizeInTiles: CGSize, tileSizeInPoints: CGSize, name: String? = nil) -> SKShapeNode {
    let grid = SKShapeNode.init()
    grid.lineWidth = 1.0
    grid.strokeColor = .white
    grid.fillColor = .clear
    grid.isAntialiased = false
    grid.name = name
    
    let path = CGMutablePath();
    let endPoint = CGPoint(x: (sizeInTiles.width + 1) * tileSizeInPoints.width, y: (sizeInTiles.height + 1) * tileSizeInPoints.height)
    
    for x in stride(from: 0, to: endPoint.x, by: tileSizeInPoints.width) {
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: endPoint.y - tileSizeInPoints.height))
    }

    for y in stride(from: 0, to: endPoint.y, by: tileSizeInPoints.height) {
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: endPoint.x - tileSizeInPoints.width, y: y))
    }
    
    grid.path = path
    return grid
}
