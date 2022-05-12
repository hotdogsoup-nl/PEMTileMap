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

class PEMTmxMap : SKNode {
    private (set) var version : String?
    private (set) var mapSource : String?
    private (set) var tiledversion : String?

    private (set) var mapSizeInTiles = CGSize.zero
    private (set) var mapSizeInPoints = CGSize.zero
    private (set) var tileSizeInPoints = CGSize.zero
    private (set) var hexSideLengthInPoints = Int(0)
    private (set) var parallaxOriginInPoints = CGPoint.zero
    private (set) var currentZPosition = CGFloat(0)

    private (set) var backgroundColor : SKColor?
    private (set) var infinite = false
    
    private (set) var orientation : Orientation?
    private (set) var staggerAxis : MapStaggerAxis?
    private (set) var staggerIndex : MapStaggerIndex?

    private var compressionLevel = Int(-1)
    private var nextLayerId = UInt(0)
    private var nextObjectId = UInt(0)
    private var renderOrder = MapRenderOrder.RightDown
    private var textureFilteringMode = SKTextureFilteringMode.nearest

    private var baseZPosition = CGFloat(0)
    private var zPositionLayerDelta = CGFloat(20)

    internal var tileSets : [PEMTmxTileSet] = []
    internal var tileLayers : [PEMTmxTileLayer] = []
    
    // MARK: - Init
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    /// Load a **TMX** tilemap file and return a new `PEMTmxMap` node. Returns nil if the file could not be read or parsed.
    /// - parameter mapName : TMX file name.
    /// - parameter baseZPosition : Base zPosition for the node. Default is 0.
    /// - parameter zPositionLayerDelta : Delta for the zPosition of each layer node. Default is 20.
    /// - parameter textureFilteringMode : Texture anti aliasing / filtering mode. Default is Nearest Neighbor
    /// - returns: `PEMTmxMap?` tilemap node.
    init?(mapName: String, baseZPosition: CGFloat = 0, zPositionLayerDelta: CGFloat = 20, textureFilteringMode: SKTextureFilteringMode = .nearest) {
        super.init()

        if let url = bundleURLForResource(mapName),
           let parser = PEMTmxParser(map: self, fileURL: url) {
                if (!parser.parse()) {
                    #if DEBUG
                    print("PEMTmxMap: Error parsing map: ", parser.parserError as Any)
                    #endif
                    return nil
                }
        } else {
            #if DEBUG
            print("PEMTmxMap: Map file not found: \(mapName)")
            #endif
            return nil
        }
        
        mapSource = mapName
        self.baseZPosition = baseZPosition
        self.zPositionLayerDelta = zPositionLayerDelta
        self.textureFilteringMode = textureFilteringMode
        
        renderMap()
    }
    
    // MARK: - Setup
    
    func addAttributes(_ attributes: Dictionary<String, String>) {
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
    
    // MARK: - Public
    
    private func renderMap() {
        currentZPosition = baseZPosition

        #if DEBUG
        print (self)
        
        for tileSet in tileSets {
            print(tileSet)
        }
        #endif
        
        // add tile layers
        addLayers()
        
        // add image layers
        
        // add objects
        
        mapSizeInPoints = calculateAccumulatedFrame().size
    }
    
    private func addLayers() {
        for tileLayer in tileLayers {
            if tileLayer.visible {
                currentZPosition += zPositionLayerDelta

                tileLayer.generateTiles(mapSizeInTiles: mapSizeInTiles, tileSets: tileSets, textureFilteringMode: textureFilteringMode)
                tileLayer.zPosition = currentZPosition
                
                addChild(tileLayer)
                
                #if DEBUG
                print (tileLayer)
                #endif
            }
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxMap: \(mapSource ?? "-") (layers: \(tileLayers.count), tileSets: \(tileSets.count))"
    }
    #endif
}
