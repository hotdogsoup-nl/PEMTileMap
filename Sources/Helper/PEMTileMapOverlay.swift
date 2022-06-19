import SpriteKit

internal func mapCanvas(coordinateHelper: PEMCoordinateHelper, name: String? = nil) -> SKSpriteNode {
    let canvas = SKSpriteNode(color: .red, size: coordinateHelper.mapSizeInPoints)
    
    switch coordinateHelper.orientation {
    case .unknown:
        canvas.position = .zero
    case .hexagonal:
        break
    case .isometric:
        canvas.position = CGPoint(x: 0, y: -coordinateHelper.tileSizeInPoints.height)
    case .orthogonal:
        canvas.position = .zero
    case .staggered:
        break
    }
    
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
    
    let row = Int(sizeInTiles.height)
    for col in 0 ..< Int(sizeInTiles.width + 1) {
        var startPoint = coordinateHelper.position(tileCoords: CGPoint(x: col, y: 0))
        var endPoint = coordinateHelper.position(tileCoords: CGPoint(x: col, y: row))

        switch coordinateHelper.orientation {
        case .unknown:
            break
        case .hexagonal:
            break
        case .isometric:
            startPoint.x += tileSizeInPoints.width * 0.5
            endPoint.x += tileSizeInPoints.width * 0.5
        case .orthogonal:
            break
        case .staggered:
            break
        }

        path.move(to: startPoint)
        path.addLine(to: endPoint)
    }
    
    let col = Int(sizeInTiles.width)
    for row in 0 ..< Int(sizeInTiles.height + 1) {
        var startPoint = coordinateHelper.position(tileCoords: CGPoint(x: 0, y: row))
        var endPoint = coordinateHelper.position(tileCoords: CGPoint(x: col, y: row))
        
        switch coordinateHelper.orientation {
        case .unknown:
            break
        case .hexagonal:
            break
        case .isometric:
            startPoint.x += tileSizeInPoints.width * 0.5
            endPoint.x += tileSizeInPoints.width * 0.5
        case .orthogonal:
            break
        case .staggered:
            break
        }

        path.move(to: startPoint)
        path.addLine(to: endPoint)
    }

    grid.path = path
    return grid
}
