import Foundation
import SpriteKit
import zlib
import CoreGraphics

enum CameraZoomMode {
    case none
    case aspectFit
    case aspectFill
}

enum CameraViewMode {
    case center
    case left
    case right
    case top
    case bottom
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

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
    private (set) var orientation: Orientation?
    private (set) var cameraNode: SKCameraNode

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
        cameraNode = SKCameraNode()

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
    
    // MARK: - Map objects
        
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
    
    // MARK: - Camera
    
    /// Changes the map camera scale using specified `CameraZoomMode`.
    /// - parameter mode : Aspect fit or fill the view. A value of `.none` means the camera will zoom to the specified `factor`.
    /// - parameter sceneSize : Size of the `SKScene` the map is a child of.
    /// - parameter factor : Optional zoom factor. A value of 1.0 will zoom to 100% of the `sceneSize`. A value of 0.8 for example, will result in a margin of 20%.
    /// - parameter duration : Optional duration to animate the zoom. A value of 0 will result in no animation.
    /// - parameter completion : Optional completion block which is called when zooming has finished.
    func zoomCamera(mode: CameraZoomMode, sceneSize: CGSize, factor: CGFloat = 1.0, duration: CGFloat = 0.0, completion:@escaping ()->Void = {}) {
        if mapSizeInPoints.width == 0 || mapSizeInPoints.height == 0 {
            return
        }
        
        let maxWidthScale = sceneSize.width / mapSizeInPoints.width
        let maxHeightScale = sceneSize.height / mapSizeInPoints.height
        var contentScale : CGFloat = 1.0
        
        switch mode {
        case .none:
            contentScale = factor
        case .aspectFit:
            contentScale = (maxWidthScale < maxHeightScale) ? maxWidthScale : maxHeightScale
        case .aspectFill:
            contentScale = (maxWidthScale > maxHeightScale) ? maxWidthScale : maxHeightScale
        }
        
        let zoomAction = SKAction.scale(to: 1.0 / contentScale / factor, duration: duration)
        cameraNode.run(zoomAction, completion: completion)
    }
    
    /// Changes the map camera position using the specified `CameraViewMode`.
    /// - parameter mode : Used to determine how the camera position is aligned within the given `sceneSize`.
    /// - parameter sceneSize : Size of the `SKScene` the map is a child of.
    /// - parameter factor : Optional movement factor.  Ignored if the `panMode` equals `.center`.
    /// - parameter duration : Optional duration to animate the movement. A value of 0 will result in no animation.
    /// - parameter completion : Optional completion block which is called when movement has finished.
    func moveCamera(mode: CameraViewMode, sceneSize: CGSize, factor: CGFloat = 1.0, duration: TimeInterval = 0, completion:@escaping ()->Void = {}) {
        var newPosition = cameraNode.position

        if mode == .center {
            newPosition = .zero
        } else {
            if mode == .left || mode == .topLeft || mode == .bottomLeft {
                newPosition.x = sceneSize.width * 0.5 * factor + mapSizeInPoints.width * -0.5
            } else if mode == .right || mode == .topRight || mode == .bottomRight {
                newPosition.x = sceneSize.width * -0.5 * factor + mapSizeInPoints.width * 0.5
            }
            
            if mode == .top || mode == .topLeft || mode == .topRight {
                newPosition.y = sceneSize.height * -0.5 * factor + mapSizeInPoints.height * 0.5
            } else if mode == .bottom || mode == .bottomLeft || mode == .bottomRight {
                newPosition.y = sceneSize.height * 0.5 * factor + mapSizeInPoints.height * -0.5
            }
        }
                
        let moveAction = SKAction.move(to: newPosition, duration: duration)
        cameraNode.run(moveAction, completion: completion)
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
        
        cameraNode.zPosition = currentZPosition + 1
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
