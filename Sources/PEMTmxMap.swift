import Foundation
import SpriteKit
import zlib
import CoreGraphics

internal enum Orientation: String {
    case hexagonal = "hexagonal"
    case isometric = "isometric"
    case orthogonal = "orthogonal"
    case staggered = "staggered"
}

internal enum MapRenderOrder: String {
    case leftDown = "left-down"
    case leftUp = "left-up"
    case rightDown = "right-down"
    case rightUp = "right-up"
}

internal enum MapStaggerAxis: String {
    case x = "x"
    case y = "y"
}

internal enum MapStaggerIndex: String {
    case even = "even"
    case odd = "odd"
}

class PEMTmxMap: SKNode, PEMTmxPropertiesProtocol {
    private (set) var mapSizeInPoints = CGSize.zero
    private (set) var currentZPosition = CGFloat(0)
    private (set) var backgroundColor: SKColor?
    private (set) var properties: Dictionary<String, Any>?

    private var version: String?
    private var mapSource: String?
    private var tiledversion: String?

    private var mapSizeInTiles = CGSize.zero
    private var tileSizeInPoints = CGSize.zero
    var mapSizeInPointsFromTileSize: CGSize {
        return CGSize(width: mapSizeInTiles.width * tileSizeInPoints.width, height: mapSizeInTiles.height * tileSizeInPoints.height)
    }
    
    private var hexSideLengthInPoints = Int(0)
    private var parallaxOriginInPoints = CGPoint.zero
    private var infinite = false
    
    private var orientation: Orientation?
    private var staggerAxis: MapStaggerAxis?
    private var staggerIndex: MapStaggerIndex?

    private var compressionLevel = Int(-1)
    private var nextLayerId = UInt(0)
    private var nextObjectId = UInt(0)
    
    private var renderOrder = MapRenderOrder.rightDown
    private var textureFilteringMode = SKTextureFilteringMode.nearest
    private var showObjectGroups = false

    private var baseZPosition = CGFloat(0)
    private var zPositionLayerDelta = CGFloat(20)

    internal var tileSets: [PEMTmxTileSet] = []
    internal var layers: [AnyObject] = []
    
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
    init?(mapName: String, baseZPosition: CGFloat = 0, zPositionLayerDelta: CGFloat = 20, textureFilteringMode: SKTextureFilteringMode = .nearest, showObjectGroups: Bool = false) {
        super.init()
        
        #if DEBUG
        let parseStartTime = Date()
        #endif

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
        
        parseExternalFiles()
        
        #if DEBUG
        let parseTimeInterval = -parseStartTime.timeIntervalSinceNow
        #endif

        mapSource = mapName
        self.baseZPosition = baseZPosition
        self.zPositionLayerDelta = zPositionLayerDelta
        self.textureFilteringMode = textureFilteringMode
        self.showObjectGroups = showObjectGroups
        
        #if DEBUG
        let renderStartTime = Date()
        #endif
        
        renderMap()
        
        #if DEBUG
        let renderTimeInterval = -renderStartTime.timeIntervalSinceNow
        
        print("Parsed files in:", parseTimeInterval.stringValue())
        print("Rendered map in:", renderTimeInterval.stringValue())
        #endif
    }
    
    // MARK: - Setup
    
    func addAttributes(_ attributes: Dictionary<String, String>) {
        guard let width = attributes[ElementAttributes.width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.height.rawValue] else { return }
        guard let tilewidth = attributes[ElementAttributes.tileWidth.rawValue] else { return }
        guard let tileheight = attributes[ElementAttributes.tileHeight.rawValue] else { return }
        guard let orientationValue = attributes[ElementAttributes.orientation.rawValue] else { return }
                
        version = attributes[ElementAttributes.version.rawValue]
        tiledversion = attributes[ElementAttributes.tiledVersion.rawValue]
        
        if let mapOrientation = Orientation(rawValue: orientationValue) {
            orientation = mapOrientation
        } else {
            #if DEBUG
            print("PEMTmxMap: unsupported map orientation: \(String(describing: orientationValue))")
            #endif
        }
        
        if let value = attributes[ElementAttributes.renderOrder.rawValue] {
            if let mapRenderOrder = MapRenderOrder(rawValue: value) {
                renderOrder = mapRenderOrder
            } else {
                #if DEBUG
                print("PEMTmxMap: unsupported map render order: \(String(describing: value))")
                #endif
            }
        }
        
        if let value = attributes[ElementAttributes.compressionLevel.rawValue] {
            compressionLevel = Int(value)!
        }
        
        mapSizeInTiles = CGSize(width: Int(width)!, height: Int(height)!)
        tileSizeInPoints = CGSize(width: Int(tilewidth)!, height: Int(tileheight)!)
        
        if let value = attributes[ElementAttributes.hexSideLength.rawValue] {
            hexSideLengthInPoints = Int(value) ?? 0
        }
        
        if let value = attributes[ElementAttributes.staggerAxis.rawValue] {
            if let mapStaggerAxis = MapStaggerAxis(rawValue: value) {
                staggerAxis = mapStaggerAxis
            } else {
                #if DEBUG
                print("PEMTmxMap: unsupported map stagger axis: \(String(describing: value))")
                #endif
            }
        }

        if let value = attributes[ElementAttributes.staggerIndex.rawValue] {
            if let mapStaggerIndex = MapStaggerIndex(rawValue: value) {
                staggerIndex = mapStaggerIndex
            } else {
                #if DEBUG
                print("PEMTmxMap: unsupported map stagger index: \(String(describing: value))")
                #endif
            }
        }
        
        if let value = attributes[ElementAttributes.parallaxOriginX.rawValue] {
            parallaxOriginInPoints.x = CGFloat(Int(value) ?? 0)
        }

        if let value = attributes[ElementAttributes.parallaxOriginY.rawValue] {
            parallaxOriginInPoints.y = CGFloat(Int(value) ?? 0)
        }

        if let value = attributes[ElementAttributes.backgroundColor.rawValue] {
            backgroundColor = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.nextLayerId.rawValue] {
            nextLayerId = UInt(value)!
        }

        if let value = attributes[ElementAttributes.nextObjectId.rawValue] {
            nextObjectId = UInt(value)!
        }

        if let value = attributes[ElementAttributes.infinite.rawValue] {
            infinite = value == "1"
        }
    }
    
    // MARK: - PEMTmxPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMTmxProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Public
        
    func tileSetFor(gid: UInt32) -> PEMTmxTileSet? {
        let tileAttributes = tileAttributes(fromId: gid)

        for tileSet in tileSets {
            if tileSet.containsTileWith(gid: tileAttributes.id) {
                return tileSet
            }
        }
        
        #if DEBUG
        print("PEMTmxMap: no tileSet found for tile with gid: \(gid)")
        #endif

        return nil
    }
    
    // MARK: - Private
    
    private func parseExternalFiles() {
        for tileSet in tileSets {
            tileSet.parseExternalTileSet()
        }
    }
    
    private func renderMap() {
        currentZPosition = baseZPosition

        #if DEBUG
        print (self)
        
        for tileSet in tileSets {
            print(tileSet)
        }
        #endif
        
        renderLayers()

        mapSizeInPoints = calculateAccumulatedFrame().size
        
        if mapSizeInPoints.width < mapSizeInPointsFromTileSize.width {
            mapSizeInPoints.width = mapSizeInPointsFromTileSize.width
        }

        if mapSizeInPoints.height < mapSizeInPointsFromTileSize.height {
            mapSizeInPoints.height = mapSizeInPointsFromTileSize.height
        }
    }
    
    private func renderLayers() {
        for layer in layers {
            if let tileLayer = layer as? PEMTmxTileLayer {
                if tileLayer.visible {
                    currentZPosition += zPositionLayerDelta

                    tileLayer.render(tileSizeInPoints: tileSizeInPoints, mapSizeInTiles: mapSizeInTiles, textureFilteringMode: textureFilteringMode)
                    tileLayer.zPosition = currentZPosition
                    
                    addChild(tileLayer)
                    #if DEBUG
                    print(layer)
                    #endif
                }
                
                continue
            }

            if let imageLayer = layer as? PEMTmxImageLayer {
                if imageLayer.visible {
                    currentZPosition += zPositionLayerDelta
                    
                    imageLayer.render(mapSizeInPoints: mapSizeInPointsFromTileSize, textureFilteringMode:textureFilteringMode)
                    imageLayer.zPosition = currentZPosition
                    
                    addChild(imageLayer)
                    #if DEBUG
                    print(layer)
                    #endif
                }
                continue
            }

            if showObjectGroups {
                if let objectLayer = layer as? PEMTmxObjectGroup {
                    if objectLayer.visible {
                        currentZPosition += zPositionLayerDelta
                        
                        objectLayer.render(tileSizeInPoints: tileSizeInPoints, mapSizeInPoints: mapSizeInPointsFromTileSize, textureFilteringMode:textureFilteringMode)
                        objectLayer.zPosition = currentZPosition
                        
                        addChild(objectLayer)
                        #if DEBUG
                        print(layer)
                        #endif
                    }
                    continue
                }
            }
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxMap: \(mapSource ?? "-") (layers: \(layers.count), tileSets: \(tileSets.count))"
    }
    #endif
}
