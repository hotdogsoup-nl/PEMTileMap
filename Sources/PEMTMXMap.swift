import Foundation
import SpriteKit
import zlib
import CoreGraphics

//enum LayerAttribute: Int {
//    case None
//    case Base64
//    case Gzip
//    case Zlib
//
//    var value: UInt8 {
//        return UInt8(1 << self.rawValue)
//    }
//}
//
//enum PropertyType {
//    case None
//    case Map
//    case Layer
//    case ObjectGroup
//    case Tile
//    case ImageLayer
//}
//

internal enum Orientation : String {
    case Orthogonal = "orthogonal"
    case Isometric = "isometric"
    case Staggered = "staggered"
    case Hexagonal = "hexagonal"
}

internal enum MapRenderOrder : String {
    case RightDown = "right-down"
    case RightUp = "right-up"
    case LeftDown = "left-down"
    case LeftUp = "left-up"
}

internal enum MapStaggerAxis : String {
    case X = "x"
    case Y = "y"
}

internal enum MapStaggerIndex : String {
    case Even = "even"
    case Odd = "odd"
}

class PEMTMXMap : SKNode, XMLParserDelegate {
    var mapSize = CGSize.zero
    var tileSize = CGSize.zero
    var hexSideLength = Int(0)
    var parallaxOrigin = CGPoint.zero
    
    var backgroundColor : SKColor?
    var infinite = false
    
    var orientation : Orientation?
    var renderOrder : MapRenderOrder?
    var staggerAxis : MapStaggerAxis?
    var staggerIndex : MapStaggerIndex?

    private var backgroundColorNode : SKSpriteNode?

    internal var tileSets : [PEMTMXTileSet] = []
    
    // XML Parser
    internal var currentParseString : String = ""
    internal var currentFirstGid = UInt(0)
    internal var currentMapElement = MapElements.None
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        #if DEBUG
        print("deinit: PEMTMXMap")
        #endif
    }

    /**
     Load a **TMX** tilemap file and return a new `PEMTMXMap` node. Returns nil if the file could not be read or parsed.

     - parameter mapName : TMX file name.
     - parameter baseZPosition : Base zPosition for the node. Default is 0.
     - parameter zPositionLayerDelta : Delta for the zPosition of each layer node. Default is -20.
     - returns: `PEMTMXMap?` tilemap node.
     */

    init?(mapName : String, baseZPosition : CGFloat = 0, zPositionLayerDelta : CGFloat = 20) {
        super.init()

        if let path = bundleURLForResource(mapName) {
            if let parser = XMLParser(contentsOf: path) {
                parser.delegate = self
                parser.shouldProcessNamespaces = false
                parser.shouldReportNamespacePrefixes = false
                parser.shouldResolveExternalEntities = false
                if (!parser.parse()) {
                    #if DEBUG
                    print("PEMTMXMap: Error parsing map: ", parser.parserError as Any)
                    #endif
                    return nil
                }
            }
        }
        
        if backgroundColor != nil {
            let colorNode = SKSpriteNode(color: backgroundColor!, size: mapSizePoints())
            backgroundColorNode = colorNode
            backgroundColorNode?.anchorPoint = .zero
            backgroundColorNode?.position = .zero
            addChild(backgroundColorNode!)
        }
        
        #if DEBUG
        print (self)
        #endif
    }
    
    internal func getAttributes(_ attributes : Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return }
        guard let tilewidth = attributes[ElementAttributes.TileWidth.rawValue] else { return }
        guard let tileheight = attributes[ElementAttributes.TileHeight.rawValue] else { return }
        guard let orientationValue = attributes[ElementAttributes.Orientation.rawValue] else { return }
                
        tileSize = CGSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        mapSize = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))
        
        if let mapOrientation = Orientation(rawValue: orientationValue) {
            orientation = mapOrientation
        } else {
            #if DEBUG
            print("PEMTMXMap: unsupported map orientation: \(String(describing: orientationValue))")
            #endif
        }
        
        if let value = attributes[ElementAttributes.RenderOrder.rawValue] {
            if let mapRenderOrder = MapRenderOrder(rawValue: value) {
                renderOrder = mapRenderOrder
            } else {
                #if DEBUG
                print("PEMTMXMap: unsupported map render order: \(String(describing: value))")
                #endif
            }
        }
        
        if let value = attributes[ElementAttributes.HexSideLength.rawValue] {
            hexSideLength = Int(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.StaggerAxis.rawValue] {
            if let mapStaggerAxis = MapStaggerAxis(rawValue: value) {
                staggerAxis = mapStaggerAxis
            } else {
                #if DEBUG
                print("PEMTMXMap: unsupported map stagger axis: \(String(describing: value))")
                #endif
            }
        }

        if let value = attributes[ElementAttributes.StaggerIndex.rawValue] {
            if let mapStaggerIndex = MapStaggerIndex(rawValue: value) {
                staggerIndex = mapStaggerIndex
            } else {
                #if DEBUG
                print("PEMTMXMap: unsupported map stagger index: \(String(describing: value))")
                #endif
            }
        }
        
        if let value = attributes[ElementAttributes.ParallaxOriginX.rawValue] {
            parallaxOrigin.x = CGFloat(Int(value) ?? 0)
        }

        if let value = attributes[ElementAttributes.ParallaxOriginY.rawValue] {
            parallaxOrigin.y = CGFloat(Int(value) ?? 0)
        }

        if let value = attributes[ElementAttributes.BackgroundColor.rawValue] {
            backgroundColor = SKColor.init(hexString: value)
        }

        if let value = attributes[ElementAttributes.Infinite.rawValue] {
            infinite = value == "1"
        }
    }
    
    private func mapSizePoints() -> CGSize {
        return CGSize(width: mapSize.width * tileSize.width, height: mapSize.height * tileSize.height)
    }
    
    #if DEBUG
    override var description: String {
        var result : String = ""
        
        result += "\nPEMTMXMap --"
        result += "\norientation: \(String(describing: orientation))"
        result += "\nmapSize: \(mapSize)"
        result += "\ntileSize: \(tileSize)"
        
        for tileSet in tileSets {
            result += "\n\(tileSet)"
        }
    
        return result
    }
    #endif
}

// MARK: - Helper functions

func bundleURLForResource(_ resource : String) -> URL? {
    var fileName = resource
    var fileExtension : String?

    if resource.range(of: ".") != nil {
        fileName = (resource as NSString).deletingPathExtension
        fileExtension = (resource as NSString).pathExtension
    }

    return Bundle.main.url(forResource: fileName, withExtension: fileExtension)
}

func bundlePathForResource(_ resource : String) -> String? {
    var fileName = resource
    var fileExtension : String?

    if resource.range(of: ".") != nil {
        fileName = (resource as NSString).deletingPathExtension
        fileExtension = (resource as NSString).pathExtension
    }

    return Bundle.main.path(forResource: fileName, ofType: fileExtension)
}
