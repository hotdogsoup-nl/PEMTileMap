import Foundation
import SpriteKit

class PEMTMXTilesetInfo : NSObject {
    private (set) var name : String?
    private (set) var firstGid = UInt(0)
    private (set) var tileSize = CGSize.zero
    private (set) var unitTileSize = CGSize.zero
    private (set) var spacing = UInt(0)
    private (set) var margin = UInt(0)
    private (set) var sourceImage : String?
    private (set) var imageSize = CGSize.zero
    private (set) var atlasTilesPerRow = Int(0)
    private (set) var atlasTilesPerCol = Int(0)
    private (set) var atlasTexture : SKTexture?
    
    private var textureCache : Dictionary<NSNumber, SKTexture>
    
    init(gID: UInt, attributes: Dictionary<String, String>) {
        name = attributes["name"]
        firstGid = gID
        spacing = UInt(attributes["spacing"] ?? "0") ?? 0
        margin = UInt(attributes["margin"] ?? "0") ?? 0
        tileSize = .zero
        tileSize.width = CGFloat((attributes["tilewidth"] as? NSString)?.integerValue ?? 0)
        tileSize.height = CGFloat((attributes["tileheight"] as? NSString)?.integerValue ?? 0)
        textureCache = Dictionary.init()
        super.init()
    }
    
    func setSourceImage(_ image: String) {
        sourceImage = image
        
        #if os(macOS)
        let atlas = NSImage.init(contentsOfFile: sourceImage!)
        #else
        let atlas = UIImage(contentsOfFile: sourceImage!)
        #endif
        
        imageSize = atlas!.size
        
        atlasTexture = SKTexture(imageNamed: sourceImage!)
        
        unitTileSize = CGSize(width: tileSize.width / imageSize.width, height: tileSize.height / imageSize.height)
        
        let imageWidth = (imageSize.width - CGFloat(margin) * 2.0 + CGFloat(spacing))
        let tileWidth = (tileSize.width + CGFloat(spacing))
        atlasTilesPerRow =  Int(imageWidth / tileWidth)

        let imageHeight = (imageSize.height - CGFloat(margin) * 2.0 + CGFloat(spacing))
        let tileHeight = (tileSize.height + CGFloat(spacing))
        atlasTilesPerCol = Int(imageHeight / tileHeight);
    }
    
    func rowFromGid(_ gid : Int) -> Int {
        return gid / atlasTilesPerRow
    }

    func colFromGid(_ gid : Int) -> Int {
        return gid % atlasTilesPerRow
    }

    func textureForGid(_ gid : Int) -> SKTexture? {
        var convertedGid = gid & Int(PEMTMXTileFlags.FlippedMask.rawValue)
        convertedGid = convertedGid - Int(firstGid)

        if let texture = textureCache[NSNumber(value: convertedGid)] {
            return texture
        } else {
            
        }
        return nil
    }
    
    func textureAtPoint(_ point : CGPoint) -> SKTexture {
        let rect = CGRect(x: point.x / atlasTexture!.size().width, y: 1.0 - ((point.y + tileSize.height) / atlasTexture!.size().height), width: unitTileSize.width, height: unitTileSize.height)
        return SKTexture(rect: rect, in: atlasTexture!)
    }
}
