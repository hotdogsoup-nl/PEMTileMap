import Foundation
import SpriteKit

internal enum ObjectAlignment: String {
    case Unspecified = "unspecified"
    case TopLeft = "topleft"
    case Top = "top"
    case TopRight = "topright"
    case Left = "left"
    case Center = "center"
    case Right = "right"
    case BottomLeft = "bottomleft"
    case Bottom = "bottom"
    case BottomRight = "bottomright"
}

class PEMTmxTileSet : NSObject {
    private (set) var name : String?
    private (set) var tileSizeInPoints = CGSize.zero
    private (set) var spacingInPoints = UInt(0)
    private (set) var marginInPoints = UInt(0)
    private (set) var tileCount = UInt(0)
    private (set) var objectAlignment = ObjectAlignment.Unspecified // unsupported

    private var firstGid = UInt32(0)
    private var externalSource : String?
    private var tileAtlasImage : SKTexture?
    private var tileAtlasImageSize : CGSize?
    private var tileSetTileUnitSize : CGSize?
    private var tilesPerRow = UInt(0)
    private var tilesPerColumn = UInt(0)
    
    private var lastPossibleGid: UInt32 {
        return firstGid + UInt32((tilesPerRow * tilesPerColumn)) - 1
    }
    
    private var globalRange: ClosedRange<UInt32> {
        return firstGid...lastPossibleGid
    }
    
    init(attributes: Dictionary<String, String>) {
        super.init()

        if let value = attributes[ElementAttributes.FirstGid.rawValue] {
            firstGid = UInt32(value)!
        }

        externalSource = attributes[ElementAttributes.Source.rawValue]
        name = attributes[ElementAttributes.Name.rawValue]

        if let tilewidth = attributes[ElementAttributes.TileWidth.rawValue],
           let tileheight = attributes[ElementAttributes.TileHeight.rawValue] {
            tileSizeInPoints = CGSize(width: Int(tilewidth)!, height: Int(tileheight)!)
        }

        if let value = attributes[ElementAttributes.Spacing.rawValue] {
            spacingInPoints = UInt(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.Margin.rawValue] {
            marginInPoints = UInt(value) ?? 0
        }

        if let value = attributes[ElementAttributes.TileCount.rawValue] {
            tileCount = UInt(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.ObjectAlignment.rawValue] {
            if let tileSetObjectAlignment = ObjectAlignment(rawValue: value) {
                objectAlignment = tileSetObjectAlignment
            } else {
                #if DEBUG
                print("PEMTmxMap: unsupported tileset object alignment: \(String(describing: value))")
                #endif
            }
        }
    }
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(type(of: self))")
        #endif
        #endif
    }
    
    // MARK: - Setup
    
    internal func setTileAtlasImage(attributes: Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return }
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }
        
        if let path = bundlePathForResource(source) {
            tileAtlasImage = SKTexture(imageNamed: path)
            tileAtlasImageSize = tileAtlasImage?.size()
            tileSetTileUnitSize = CGSize(width: tileSizeInPoints.width / tileAtlasImageSize!.width, height: tileSizeInPoints.height / tileAtlasImageSize!.height)
            
            tilesPerRow = (UInt(tileAtlasImageSize!.width) - marginInPoints * 2 + spacingInPoints) / (UInt(tileSizeInPoints.width) + spacingInPoints)
            tilesPerColumn = (UInt(tileAtlasImageSize!.height) - marginInPoints * 2 + spacingInPoints) / (UInt(tileSizeInPoints.height) + spacingInPoints)
            
            if tileAtlasImageSize!.width != CGFloat(Int(width)!) || tileAtlasImageSize!.height != CGFloat(Int(height)!) {
                #if DEBUG
                print("PEMTmxMap: tileset <image> size mismatch: \(source)")
                #endif
            }
        }
    }
        
    internal func tileFor(gid: UInt32, textureFilteringMode: SKTextureFilteringMode) -> PEMTmxTile? {
        let tileAttributes = tileAttributes(fromGid: gid)
        let textureGid = tileAttributes.gid - firstGid
        
        let atlasCoords = CGPoint(x: Int(rowFrom(gid: textureGid)), y: Int(columnFrom(gid: textureGid)))
        var rowInPoints = (((tileSizeInPoints.height + CGFloat(spacingInPoints)) * atlasCoords.x) + CGFloat(marginInPoints)) / tileAtlasImageSize!.height
        let columnInPoints = (((tileSizeInPoints.width + CGFloat(spacingInPoints)) * atlasCoords.y) + CGFloat(marginInPoints)) / tileAtlasImageSize!.width
        
        rowInPoints = 1.0 - rowInPoints - tileSetTileUnitSize!.height
        
        let rect = CGRect(x: columnInPoints, y: rowInPoints, width: tileSetTileUnitSize!.width, height: tileSetTileUnitSize!.height)
        
        let texture = SKTexture(rect: rect, in: tileAtlasImage!)
        texture.filteringMode = textureFilteringMode
        
        if let tile = tileWithTexture(texture) {
            return tile
        }
        
        return nil
    }
    
    internal func contains(globalID gid: UInt32) -> Bool {
        return globalRange ~= gid
    }
        
    // MARK: - Private
    
    private func tileWithTexture(_ texture : SKTexture) -> PEMTmxTile? {
        return PEMTmxTile(texture: texture)
    }
    
    private func rowFrom(gid: UInt32) -> UInt {
        return UInt(gid) / tilesPerRow
    }
    
    private func columnFrom(gid: UInt32) -> UInt {
        return UInt(gid) % tilesPerRow
    }
    
    internal func bundlePathForResource(_ resource: String) -> String? {
        var fileName = resource
        var fileExtension : String?

        if resource.range(of: ".") != nil {
            fileName = (resource as NSString).deletingPathExtension
            fileExtension = (resource as NSString).pathExtension
        }

        return Bundle.main.path(forResource: fileName, ofType: fileExtension)
    }
}
