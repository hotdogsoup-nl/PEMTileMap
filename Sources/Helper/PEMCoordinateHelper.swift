import Foundation

internal class PEMCoordinateHelper: NSObject {
    private (set) var orientation: MapOrientation
    private (set) var tileSizeInPoints = CGSize.zero
    private (set) var mapSizeInTiles = CGSize.zero
    private (set) var mapSizeInPoints = CGSize.zero

    init(orientation: MapOrientation, mapSizeInTiles: CGSize, tileSizeInPoints: CGSize) {
        self.orientation = orientation
        self.mapSizeInTiles = mapSizeInTiles
        self.tileSizeInPoints = tileSizeInPoints
        
        super.init()
        mapSizeInPoints = calculateMapSizeInPoints()
    }
    
    private func calculateMapSizeInPoints() -> CGSize {
        var size = CGSize.zero
        
        switch orientation {
        case .unknown, .orthogonal:
            size = CGSize(width: mapSizeInTiles.width * tileSizeInPoints.width, height: mapSizeInTiles.height * tileSizeInPoints.height)
        case .hexagonal:
            break
        case .isometric:
            let sideLength = mapSizeInTiles.width + mapSizeInTiles.height
            size = CGSize(width: sideLength * tileSizeInPoints.width * 0.5, height: sideLength * tileSizeInPoints.height * 0.5)
        case .staggered:
            break
        }
        return size
    }
    
    func position(tileCoords: CGPoint) -> CGPoint {
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        switch orientation {
        case .unknown:
            break
        case .hexagonal:
            break
        case .isometric:
            x = (tileCoords.x - tileCoords.y) * tileSizeInPoints.width * 0.5 + (mapSizeInTiles.height - 1) * tileSizeInPoints.width * 0.5
            y = mapSizeInPoints.height - (tileCoords.x + tileCoords.y) * tileSizeInPoints.height * 0.5 - tileSizeInPoints.height
        case .orthogonal:
            x = (tileCoords.x * tileSizeInPoints.width)
            y = mapSizeInPoints.height - ((tileCoords.y + 1) * tileSizeInPoints.height)
        case .staggered:
            break
        }

        return CGPoint(x: x, y: y)
    }
    
    func position(coordsInPoints: CGPoint) -> CGPoint {
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        switch orientation {
        case .unknown:
            break
        case .hexagonal:
            break
        case .isometric:
            x = (coordsInPoints.x - coordsInPoints.y) + (mapSizeInTiles.height - 1) * tileSizeInPoints.width * 0.5
            y = mapSizeInPoints.height - (coordsInPoints.x + coordsInPoints.y) * 0.5 - tileSizeInPoints.height * 0.5
        case .orthogonal:
            x = coordsInPoints.x - tileSizeInPoints.width * 0.5
            y = mapSizeInPoints.height - coordsInPoints.y - tileSizeInPoints.height * 0.5
        case .staggered:
            break
        }

        return CGPoint(x: x, y: y)
    }
    
}
