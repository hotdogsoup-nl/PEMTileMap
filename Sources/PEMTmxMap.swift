import Foundation
import SpriteKit
import zlib
import CoreGraphics

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

internal enum DataEncoding : String {
    case Base64 = "base64"
    case Csv = "csv"
}

internal enum DataCompression : String {
    case None
    case Gzip = "gzip"
    case Zlib = "zlib"
    case Zstd = "zstd"
}

class PEMTmxMap : SKNode, XMLParserDelegate {
    private (set) var version : String?
    private (set) var tiledversion : String?
    private (set) var compressionLevel = Int(-1)

    private (set) var mapSizeInTiles = CGSize.zero
    private (set) var tileSizeInPoints = CGSize.zero
    private (set) var hexSideLengthInPoints = Int(0)
    private (set) var parallaxOriginInPoints = CGPoint.zero
    
    private (set) var backgroundColor : SKColor?
    private (set) var nextLayerId = UInt(0)
    private (set) var nextObjectId = UInt(0)
    private (set) var infinite = false
    
    private (set) var orientation : Orientation?
    private (set) var renderOrder = MapRenderOrder.RightDown
    private (set) var staggerAxis : MapStaggerAxis?
    private (set) var staggerIndex : MapStaggerIndex?

    private (set) var textureFilteringMode = SKTextureFilteringMode.nearest

    private var backgroundColorNode : SKSpriteNode?
    private var baseZPosition = CGFloat(0)
    private var currentZPosition = CGFloat(0)
    private var zPositionLayerDelta = CGFloat(20)

    internal var tileSets : [PEMTmxTileSet] = []
    internal var tileLayers : [PEMTmxTileLayer] = []

    // TMX Parser
    internal var currentParseString : String = ""
    internal var currentFirstGid = UInt32(0)
    internal var elementPath : [AnyObject] = []
    internal var dataEncoding : DataEncoding?
    internal var dataCompression = DataCompression.None
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        #if DEBUG
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #endif
    }

    /// Load a **TMX** tilemap file and return a new `PEMTmxMap` node. Returns nil if the file could not be read or parsed.
    /// - parameter mapName : TMX file name.
    /// - parameter baseZPosition : Base zPosition for the node. Default is 0.
    /// - parameter zPositionLayerDelta : Delta for the zPosition of each layer node. Default is -20.
    /// - returns: `PEMTmxMap?` tilemap node.
    init?(mapName: String, baseZPosition: CGFloat = 0, zPositionLayerDelta: CGFloat = 20, textureFilteringMode: SKTextureFilteringMode = .nearest) {
        super.init()

        if let path = bundleURLForResource(mapName) {
            if let parser = XMLParser(contentsOf: path) {
                parser.delegate = self
                parser.shouldProcessNamespaces = false
                parser.shouldReportNamespacePrefixes = false
                parser.shouldResolveExternalEntities = false
                if (!parser.parse()) {
                    #if DEBUG
                    print("PEMTmxMap: Error parsing map: ", parser.parserError as Any)
                    #endif
                    return nil
                }                
            }
        }
        
        self.baseZPosition = baseZPosition
        self.zPositionLayerDelta = zPositionLayerDelta
        self.textureFilteringMode = textureFilteringMode
        
        setUp()
        generateMap()
        postProcess()
    }
    
    internal func parseAttributes(_ attributes: Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return }
        guard let tilewidth = attributes[ElementAttributes.TileWidth.rawValue] else { return }
        guard let tileheight = attributes[ElementAttributes.TileHeight.rawValue] else { return }
        guard let orientationValue = attributes[ElementAttributes.Orientation.rawValue] else { return }
                
        version = attributes[ElementAttributes.Version.rawValue]
        tiledversion = attributes[ElementAttributes.TiledVersion.rawValue]
        
        if let mapOrientation = Orientation(rawValue: orientationValue) {
            orientation = mapOrientation
        } else {
            #if DEBUG
            print("PEMTmxMap: unsupported map orientation: \(String(describing: orientationValue))")
            #endif
        }
        
        if let value = attributes[ElementAttributes.RenderOrder.rawValue] {
            if let mapRenderOrder = MapRenderOrder(rawValue: value) {
                renderOrder = mapRenderOrder
            } else {
                #if DEBUG
                print("PEMTmxMap: unsupported map render order: \(String(describing: value))")
                #endif
            }
        }
        
        if let value = attributes[ElementAttributes.CompressionLevel.rawValue] {
            compressionLevel = Int(value)!
        }
        
        mapSizeInTiles = CGSize(width: Int(width)!, height: Int(height)!)
        tileSizeInPoints = CGSize(width: Int(tilewidth)!, height: Int(tileheight)!)
        
        if let value = attributes[ElementAttributes.HexSideLength.rawValue] {
            hexSideLengthInPoints = Int(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.StaggerAxis.rawValue] {
            if let mapStaggerAxis = MapStaggerAxis(rawValue: value) {
                staggerAxis = mapStaggerAxis
            } else {
                #if DEBUG
                print("PEMTmxMap: unsupported map stagger axis: \(String(describing: value))")
                #endif
            }
        }

        if let value = attributes[ElementAttributes.StaggerIndex.rawValue] {
            if let mapStaggerIndex = MapStaggerIndex(rawValue: value) {
                staggerIndex = mapStaggerIndex
            } else {
                #if DEBUG
                print("PEMTmxMap: unsupported map stagger index: \(String(describing: value))")
                #endif
            }
        }
        
        if let value = attributes[ElementAttributes.ParallaxOriginX.rawValue] {
            parallaxOriginInPoints.x = CGFloat(Int(value) ?? 0)
        }

        if let value = attributes[ElementAttributes.ParallaxOriginY.rawValue] {
            parallaxOriginInPoints.y = CGFloat(Int(value) ?? 0)
        }

        if let value = attributes[ElementAttributes.BackgroundColor.rawValue] {
            backgroundColor = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.NextLayerId.rawValue] {
            nextLayerId = UInt(value)!
        }

        if let value = attributes[ElementAttributes.NextObjectId.rawValue] {
            nextObjectId = UInt(value)!
        }

        if let value = attributes[ElementAttributes.Infinite.rawValue] {
            infinite = value == "1"
        }
    }
    
    // MARK: - Map generation
    
    private func setUp() {
    }
        
    private func generateMap() {
        currentZPosition = baseZPosition
        
        // add tile layers
        addLayers()
        
        // add image layers
        
        // add objects
    }
    
    private func addLayers() {
        for tileLayer in tileLayers {
            if tileLayer.visible {
                tileLayer.generateTiles(mapSizeInTiles: mapSizeInTiles, tileSets: tileSets, textureFilteringMode: textureFilteringMode)
                
                tileLayer.position = CGPoint(x: tileLayer.offSetInPoints.dx, y: -tileLayer.offSetInPoints.dy)
                tileLayer.zPosition = currentZPosition
                currentZPosition += zPositionLayerDelta
                
                addChild(tileLayer)
            }
        }
    }
    
    private func postProcess() {
        if backgroundColor != nil {
            let colorNode = SKSpriteNode(color: backgroundColor!, size: calculateAccumulatedFrame().size)
            backgroundColorNode = colorNode
            backgroundColorNode?.anchorPoint = .zero
            backgroundColorNode?.position = .zero
            backgroundColorNode?.zPosition = baseZPosition - zPositionLayerDelta
            addChild(backgroundColorNode!)
        }
    }
}

// MARK: - Helper functions

internal func tileAttributes(fromGid gid: UInt32) -> (gid: UInt32, flippedHorizontally: Bool, flippedVertically: Bool, flippedDiagonally: Bool) {
    let flippedDiagonalFlag: UInt32   = 0x20000000
    let flippedVerticalFlag: UInt32   = 0x40000000
    let flippedHorizontalFlag: UInt32 = 0x80000000

    let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
    let flippedMask = ~(flippedAll)

    let flippedHorizontally: Bool = (gid & flippedHorizontalFlag) != 0
    let flippedVertically: Bool = (gid & flippedVerticalFlag) != 0
    let flippedDiagonally: Bool = (gid & flippedDiagonalFlag) != 0

    let gid = gid & flippedMask
    return (gid, flippedHorizontally, flippedVertically, flippedDiagonally)
}

internal func bundleURLForResource(_ resource: String) -> URL? {
    var fileName = resource
    var fileExtension : String?

    if resource.range(of: ".") != nil {
        fileName = (resource as NSString).deletingPathExtension
        fileExtension = (resource as NSString).pathExtension
    }

    return Bundle.main.url(forResource: fileName, withExtension: fileExtension)
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
