import SpriteKit

internal func mapCanvas(size: CGSize, name: String? = nil) -> SKSpriteNode {
    let canvas = SKSpriteNode(color: .red, size: size)
    canvas.anchorPoint = CGPoint(x: 0, y: 0)
    canvas.name = name
    return canvas
}

internal func mapGrid(coordinateHelper: PEMCoordinateHelper, name: String? = nil) -> SKShapeNode {
    let tileSizeInPoints = coordinateHelper.tileSizeInPoints
    let sizeInTiles = coordinateHelper.mapSizeInTiles
    
    let grid = SKShapeNode.init()
    grid.lineWidth = 1.0
    grid.strokeColor = .white
    grid.fillColor = .clear
    grid.isAntialiased = false
    grid.name = name

    let path = CGMutablePath();
    let startPoint = coordinateHelper.position(tileCoords: CGPoint(x: 0, y: 0))
    let endPoint = coordinateHelper.position(tileCoords: CGPoint(x: sizeInTiles.width + 1, y: sizeInTiles.height + 1))

    for x in stride(from: startPoint.x, to: endPoint.x, by: tileSizeInPoints.width) {
        path.move(to: CGPoint(x: x, y: startPoint.y))
        path.addLine(to: CGPoint(x: x, y: endPoint.y + tileSizeInPoints.height))
    }

    for y in stride(from: startPoint.y, to: endPoint.y, by: -tileSizeInPoints.height) {
        path.move(to: CGPoint(x: startPoint.x, y: y))
        path.addLine(to: CGPoint(x: endPoint.x - tileSizeInPoints.width, y: y))
    }

    grid.path = path
    return grid
}
