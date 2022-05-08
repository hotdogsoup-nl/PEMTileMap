import Foundation
import SpriteKit

class PEMTmxLayer : SKNode {
    var layerInfo : PEMTmxLayerInfo?
    var tileInfo : Set<PEMTmxTilesetInfo>?
    var mapTileSize = CGSize.zero
//        weak var map : PEMTmxMap? // xxx
    
    private var tilesByColumnRow : Dictionary<String, Any>? // xxx
    
    init?(tilesets : Array<Any>, layerInfo: PEMTmxLayerInfo, mapInfo: PEMTmxMap) {
        // xxx todo
        return nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pointForCoord(_ coord : CGPoint) -> CGPoint {
        return CGPoint(x: coord.x * mapTileSize.width + mapTileSize.width / 2.0, y: layerHeight() - (coord.y * mapTileSize.height + mapTileSize.height / 2.0))
    }

    func coordForPoint(_ point : CGPoint) -> CGPoint {
        var inPoint = point
        inPoint.y = layerHeight() - inPoint.y
        
        let x = Int(inPoint.x / mapTileSize.height)
        let y = Int(inPoint.y / mapTileSize.width)
        return CGPoint(x: x, y: y)
    }
    
    func removeTileAt(coord : CGPoint) {
        if (layerInfo?.tileGidAtCoord(coord)) != nil { // xxx is this correct?
            let z = Int(coord.x + coord.y * (layerInfo?.layerGridSize.width)!)
            
            layerInfo?.tiles?[z] = 0
        }
    }
    
    func setTileAt(coord : CGPoint) {
        // xxx to do
    }
    
    func tileAt(point : CGPoint) -> SKSpriteNode? {
        return tileAt(coord: coordForPoint(point))
    }

    func tileAt(coord : CGPoint) -> SKSpriteNode? {
        // xxx todo
//            let indexes = [Int(coord.x), Int(coord.y)]
//            let indexPath = NSIndexPath(indexes: indexes, length: 2)
//            return tilesByColumnRow?[indexPath] // xxx
        return nil
    }
    
    func tileGidAt(point : CGPoint) -> Int {
        let pt = coordForPoint(point)
        let idx = Int(pt.x + (pt.y * (layerInfo?.layerGridSize.width)!))
        
        if (idx > Int(((layerInfo?.layerGridSize.width)! * (layerInfo?.layerGridSize.height)!)) || (idx < 0)) {
            assert(true, "TMXLayerInfo: index out of bounds")
            return 0
        }
        return Int((layerInfo?.tiles?[idx])!)
    }
    
    func propertyWithName(_ name : String) -> NSObject? { // xxx
        // xxx todo
        return nil
    }
    
    func properties() -> Dictionary<NSNumber, SKTexture> {
        return layerInfo!.properties
    }
    
    func layerWidth() -> CGFloat {
        return (layerInfo?.layerGridSize.width)! * mapTileSize.width
    }

    func layerHeight() -> CGFloat {
        return (layerInfo?.layerGridSize.height)! * mapTileSize.height
    }
}
