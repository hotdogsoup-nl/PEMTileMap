import Foundation
import SpriteKit
import zlib
import CoreGraphics

enum PEMTMXLayerAttribute: Int {
    case None
    case Base64
    case Gzip
    case Zlib

    var value: UInt8 {
        return UInt8(1 << self.rawValue)
    }
}

enum PEMTMXPropertyType {
    case None
    case Map
    case Layer
    case ObjectGroup
    case Tile
    case ImageLayer
}

enum PEMTMXTileFlags: Int {
    case Diagonal = 0x20000000
    case Vertical = 0x40000000
    case Horizontal = 0x80000000
    case FlippedAll = 0xe0000000
    case FlippedMask = 0x1fffffff
}

enum PEMTMXOrientationStyle {
    case Orthogonal
    case Isometric
}
    
class PEMTMXMap : SKNode, XMLParserDelegate {
    var mapSize = CGSize.zero
    var tileSize = CGSize.zero
    var parentElement = PEMTMXPropertyType.None
    var parentGID = Int(0)
    var orientation : PEMTMXOrientationStyle?

    private (set) var minZPositioning = CGFloat(0)
    private (set) var maxZPositioning = CGFloat(0)
    
    var fileName : String?
    var resourcePath : String?
    var tilesets : Array<Any>? // xxx
    var tileProperties : Dictionary<String, Any>? // xxx
    var properties : Dictionary<String, Any>? // xxx
    var layers : Array<PEMTMXLayerInfo>?
    var imageLayers : Array<PEMTMXImageLayer>?
    var objectGroups : Array<PEMTMXObjectGroup>?
    var gidData : Array<Any>? // xxx
    var cullNodes = false
    
    private var currentString : String?
    private var storingCharacters = false
    private var currentFirstGID = Int(0)
    private var layerAttributes = PEMTMXLayerAttribute.None
    private var lastVisibleRect = CGRect.zero
    private var zOrderCount = Int(1)
    
    override init() {
        currentString = String.init()
        tilesets = Array.init()
        tileProperties = Dictionary.init()
        properties = Dictionary.init()
        layers = Array.init()
        imageLayers = Array.init()
        objectGroups = Array.init()
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cullNodes = false
    }
    
    convenience init? (mapNamed mapName : String) {
        self.init(mapNamed: mapName, baseZPosition: 0, zOrderModifier: -20)
    }

    init? (mapNamed mapName : String, baseZPosition : CGFloat, zOrderModifier : CGFloat) {
        super.init()
        var tmxFileName = mapName
        var tmxFileExtension : String?
        
        if (mapName.range(of: ".") != nil) {
            tmxFileName = (mapName as NSString).deletingPathExtension
            tmxFileExtension = (mapName as NSString).pathExtension
        }
        
        if let path = Bundle.main.url(forResource: tmxFileName, withExtension: tmxFileExtension) {
            fileName = path.absoluteString

            if let parser = XMLParser(contentsOf: path) {
                parser.delegate = self
                parser.shouldProcessNamespaces = false
                parser.shouldReportNamespacePrefixes = false
                parser.shouldResolveExternalEntities = false
                if (!parser.parse()) {
                    #if DEBUG
                    print("Error parsing map: ", parser.parserError as Any)
                    #endif
                    return nil
                }
                
                if (baseZPosition < (baseZPosition + zOrderModifier * CGFloat(zOrderCount + 1))) {
                    minZPositioning = baseZPosition;
                    maxZPositioning = baseZPosition + zOrderModifier * CGFloat(zOrderCount + 1);
                } else {
                    maxZPositioning = baseZPosition;
                    minZPositioning = baseZPosition + zOrderModifier * CGFloat(zOrderCount + 1);
                }
                
                for layerInfo in layers! {
                    if layerInfo.visible {
                        let child = PEMTMXLayer.init(tilesets: tilesets!, layerInfo: layerInfo, mapInfo: self)
                        child?.zPosition = baseZPosition + CGFloat(zOrderCount - layerInfo.zOrderCount) * zOrderModifier
                        addChild(child!)
                    }
                }
                
                for objectGroup in objectGroups! {
                    for obj in objectGroup.objects {
                        if let num = Int(obj["gid"] ?? "0") {
                            if num != 0 {
                                if let tileset = tilesetInfoForGid(num) {
                                    let x = CGFloat(Double(obj["x"] ?? "0")!)
                                    let y = CGFloat(Double(obj["y"] ?? "0")!)
                                    var pt : CGPoint
                                    
                                    if (orientation == .Isometric) {
                                        //these appear to be incorrect for iso maps when used for tile objects! Unsure why the math is different between objects and regular tiles.
                                        let coords = screenCoordToPosition(CGPoint(x: x, y: y))
                                        pt = CGPoint(x: (tileSize.width / 2.0) * (tileSize.width + coords.x - coords.y - 1), y: (tileSize.height / 2.0) * (((tileSize.height * 2) - coords.x - coords.y) - 2))

                                        //    iso zPositioning may not work as expected for maps with irregular tile sizes.  For larger tiles (i.e. a box in front of some floor
                                        //    tiles) We would need each layer to have their tiles ordered lower at the bottom coords and higher at the top coords WITHIN THE LAYER, in
                                        //    addition to the layers being offset as described below. this could potentially be a lot larger than 20 as a default and may take some
                                        //    thinking to fix.
                                        
                                    } else {
                                        pt = CGPoint(x: (x + tileSize.width / 2.0), y: (y + tileSize.height / 2.0))
                                    }
                                    
                                    let texture = tileset.textureForGid(num - Int(tileset.firstGid) + 1)
                                    let sprite = SKSpriteNode(texture: texture)
                                    sprite.position = pt
                                    sprite.zPosition =
                                    baseZPosition + CGFloat(zOrderCount - objectGroup.zOrderCount) * zOrderModifier
                                    
                                    addChild(sprite)
                                    
                                    // This needs to be optimized into tilemap layers like our regular layers above for performance reasons.
                                                        // this could be problematic...  what if a single object group had a bunch of tiles from different tilemaps?  Would this cause zOrder problems if we're adding them all to tilemap layers?
                                }
                            }
                        }
                    }
                }
                
                for imageLayer in imageLayers! {
                    let image = SKSpriteNode(imageNamed: imageLayer.imageSource!)
                    image.position = CGPoint(x: image.size.width / 2.0, y: image.size.height / 2.0)
                    image.zPosition = baseZPosition + CGFloat(zOrderCount - imageLayer.zOrderCount) * zOrderModifier
                    addChild(image)
                    
                    //the positioning is off here, seems to be bottom-left instead of top-left.  Might be off on the rest of the sprites too...?
                }
                
                cullNodes = true // xxx in the original this is set to 1 (while it is a boolean)
            }
        }
    }

    func layerNamed(_ name : String) -> PEMTMXLayer? {
        return nil
    }

    func groupNamed(_ name : String) -> PEMTMXObjectGroup? {
        return nil
    }

    func tilesetInfoForGid(_ gID : Int) -> PEMTMXTilesetInfo? {
        return nil
    }

    func propertiesForGid(_ gID : Int) -> Dictionary<String, Any>? { // xxx
        return nil
    }
    
    func screenCoordToPosition(_ screenCoord : CGPoint) -> CGPoint {
        var returnValue = CGPoint.zero
        returnValue.x = screenCoord.x / tileSize.width
        returnValue.y = screenCoord.y / tileSize.height
        
        return returnValue
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        
    }
}
