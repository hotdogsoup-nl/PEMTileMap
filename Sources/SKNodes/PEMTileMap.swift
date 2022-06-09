import Foundation
import SpriteKit
import zlib
import CoreGraphics

public enum CameraZoomMode {
    case none
    case center
    case aspectFit
    case aspectFill
}

public enum CameraViewMode {
    case none
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
    case unknown
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

public class PEMTileMap: SKNode, PEMTileMapPropertiesProtocol {
    public var showCanvas: Bool {
        set {
            _showCanvas = newValue
            updateCanvas()
        }
        get {
            return _showCanvas
        }
    }
    public var showGrid: Bool {
        set {
            _showGrid = newValue
            updateGrid()
        }
        get {
            return _showGrid
        }
    }
    public weak var cameraNode: SKCameraNode?

    public private (set) var mapSizeInPoints = CGSize.zero
    public private (set) var tileSizeInPoints = CGSize.zero
    public private (set) var mapSizeInTiles = CGSize.zero
    public private (set) var backgroundColor: SKColor?
    public private (set) var highestZPosition = CGFloat(0)
    public private (set) var parseTime = TimeInterval(0)
    public private (set) var renderTime = TimeInterval(0)

    private (set) var properties: Dictionary<String, Any>?
    private (set) var orientation: Orientation = .unknown

    private var version: String?
    private var mapSource: String?
    private var tiledversion: String?

    private var _showCanvas: Bool = false
    private var _showGrid: Bool = false

    private var mapSizeInPointsFromTileSize: CGSize {
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

    private var baseZPosition = CGFloat(0)
    private var zPositionLayerDelta = CGFloat(20)
    
    internal var tileSets: Array<PEMTileSet> = []
    internal var objectTemplates: Dictionary<String, PEMObjectData> = [:]
    internal var layers: Array<AnyObject> = []
    
    private var cameraViewMode = CameraViewMode.none
    private var cameraZoomMode = CameraZoomMode.none

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

    /// Load a **TMX** tilemap file and return a new `PEMTileMap` node. Returns nil if the file could not be read or parsed.
    /// - Parameters:
    ///     - mapName : TMX file name.
    ///     - baseZPosition : Base zPosition for the node. Default is 0.
    ///     - zPositionLayerDelta : Delta for the zPosition of each layer node. Default is 20.
    ///     - textureFilteringMode : Texture anti aliasing / filtering mode. Default is Nearest Neighbor
    /// - returns: A `PEMTileMap` node if the TMX file could be parsed succesfully.
    public init?(mapName: String, baseZPosition: CGFloat = 0, zPositionLayerDelta: CGFloat = 20, textureFilteringMode: SKTextureFilteringMode = .nearest) {
        super.init()
        
        let parseStartTime = Date()

        if let url = bundleURLForResource(mapName),
           let parser = PEMTmxParser(map: self, fileURL: url) {
            if (!parser.parse()) {
                #if DEBUG
                print("PEMTileMap: Error parsing map: ", parser.parserError as Any)
                #endif
                return nil
            }
        } else {
            #if DEBUG
            print("PEMTileMap: Map file not found: \(mapName)")
            #endif
            return nil
        }
        
        parseExternalFiles()
        parseTime = -parseStartTime.timeIntervalSinceNow

        mapSource = mapName
        self.baseZPosition = baseZPosition
        self.zPositionLayerDelta = zPositionLayerDelta
        self.textureFilteringMode = textureFilteringMode
        
        let renderStartTime = Date()
        
        renderMap()
        
        renderTime = -renderStartTime.timeIntervalSinceNow
    }
    
    // MARK: - Setup
    
    internal func addAttributes(_ attributes: Dictionary<String, String>) {
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
            print("PEMTileMap: unsupported map orientation: \(String(describing: orientationValue))")
            #endif
        }
        
        if let value = attributes[ElementAttributes.renderOrder.rawValue] {
            if let mapRenderOrder = MapRenderOrder(rawValue: value) {
                renderOrder = mapRenderOrder
            } else {
                #if DEBUG
                print("PEMTileMap: unsupported map render order: \(String(describing: value))")
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
                print("PEMTileMap: unsupported map stagger axis: \(String(describing: value))")
                #endif
            }
        }

        if let value = attributes[ElementAttributes.staggerIndex.rawValue] {
            if let mapStaggerIndex = MapStaggerIndex(rawValue: value) {
                staggerIndex = mapStaggerIndex
            } else {
                #if DEBUG
                print("PEMTileMap: unsupported map stagger index: \(String(describing: value))")
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
    
    // MARK: - PEMTileMapPropertiesProtocol
    
    internal func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Coordinates
    
    /// Converts the tile coordinates of a  TMX Map tile to `SpriteKit` coordinates (in points).
    /// - Parameter coords: TMX tile coordinates.
    /// - Returns: Position as a `CGPoint`.
    public func position(tileCoords: CGPoint) -> CGPoint {
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
    
    /// Converts the pixel coordinates of a  TMX Map tile to `SpriteKit` coordinates (in points).
    /// - Parameter coordsInPoints: TMX pixel coordinates.
    /// - Returns: Position as a `CGPoint`.
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
    
    // MARK: - Camera
    
    /// Changes the map camera scale using the specified `CameraZoomMode` and its position using the specified `CameraViewMode` with optional animation.
    ///
    /// Makes it possible to zoom, pan and tilt the camera to positions on the map.
    ///
    /// For example in a "Mario" style platform game, when starting a level, the camera will move to the bottom left of the map and zoom in so it fills the screen vertically, leaving the rest of the map outside of the screen to the right.
    ///
    /// This can be achieved by calling **moveCamera** with
    /// * `zoomMode` = **.aspectFill**
    /// * `viewMode` =  **.bottomLeft**
    ///
    /// Both `zoomMode` and `viewMode` can be disabled by using a value of **.none**. This way a camera move can be made without zooming, or vice versa.  (Setting both to **.none** will do nothing.)
    ///
    /// - Parameters:
    ///     - sceneSize : Size of the `SKScene` the map is a child of and in which the camera move is made.
    ///     - zoomMode : Used to determine the camera zoom scale within the given `sceneSize`.
    ///     - viewMode : Used to determine how the camera position is aligned within the given `sceneSize`.
    ///     - factor : Optional movement factor that limits the move. A value of 1.0 means full motion within the given `sceneSize`.
    ///     - duration : Optional duration (in seconds) to animate the movement. A value of 0 will result in no animation.
    ///     - timingMode: Optional SKActionTimingMode for the animation. Defaults to .linear.
    ///     - completion : Optional completion block which is called when camera movement has finished.
    public func moveCamera(sceneSize: CGSize, zoomMode: CameraZoomMode, viewMode: CameraViewMode, factor: CGFloat = 1.0, duration: TimeInterval = 0, timingMode: SKActionTimingMode = .linear, completion:@escaping ()->Void = {}) {
        guard cameraNode != nil else { return }
        
        
        if zoomMode != .none && mapSizeInPoints.width > 0 && mapSizeInPoints.height > 0 {
            let maxWidthScale = sceneSize.width / mapSizeInPoints.width
            let maxHeightScale = sceneSize.height / mapSizeInPoints.height
            var contentScale : CGFloat = 1.0
            
            switch zoomMode {
            case .aspectFit:
                contentScale = (maxWidthScale < maxHeightScale) ? maxWidthScale : maxHeightScale
            case .aspectFill:
                contentScale = (maxWidthScale > maxHeightScale) ? maxWidthScale : maxHeightScale
            case .center:
                break
            case .none:
                break
            }
            
            let newScale = (1.0 / contentScale / factor * 100).rounded() / 100
            
            if duration > 0 {
                let zoomAction = SKAction.scale(to: newScale, duration: duration)
                zoomAction.timingMode = timingMode
                cameraNode?.run(zoomAction)
            } else {
                cameraNode?.xScale = newScale
                cameraNode?.yScale = newScale
            }
            
            cameraZoomMode = zoomMode
        }
        
        if viewMode == .none {
            completion()
            return
        }
        
        if var newPosition = cameraNode?.position {
            let cameraScale = cameraNode!.xScale

            if viewMode == .center {
                newPosition = .zero
            } else {
                if viewMode == .left || viewMode == .topLeft || viewMode == .bottomLeft {
                    newPosition.x = sceneSize.width * 0.5 * factor * cameraScale + mapSizeInPoints.width * -0.5
                } else if viewMode == .top || viewMode == .bottom {
                    newPosition.x = 0
                } else if viewMode == .right || viewMode == .topRight || viewMode == .bottomRight {
                    newPosition.x = sceneSize.width * -0.5 * factor * cameraScale + mapSizeInPoints.width * 0.5
                }
                
                if viewMode == .top || viewMode == .topLeft || viewMode == .topRight {
                    newPosition.y = sceneSize.height * -0.5 * factor * cameraScale + mapSizeInPoints.height * 0.5
                } else if viewMode == .left || viewMode == .right {
                    newPosition.y = 0
                } else if viewMode == .bottom || viewMode == .bottomLeft || viewMode == .bottomRight {
                    newPosition.y = sceneSize.height * 0.5 * factor * cameraScale + mapSizeInPoints.height * -0.5
                }
            }
                    
            if duration > 0 {
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = timingMode
                cameraNode?.run(moveAction, completion: completion)
            } else {
                cameraNode?.position = newPosition
                completion()
            }
            
            cameraViewMode = viewMode
        }
    }
    
    // MARK: - Private
    
    internal func tileSetContaining(gid: UInt32) -> PEMTileSet? {
        for tileSet in tileSets {
            if tileSet.containsTileWith(gid: gid) {
                return tileSet
            }
        }
        
        #if DEBUG
        print("PEMTileMap: no tileSet found for tile with gid: \(gid)")
        #endif

        return nil
    }
    
    private func parseExternalFiles() {
        for tileSet in tileSets {
            tileSet.parseExternalTileSet()
        }
        
        for layer in layers {
            if let objectLayer = layer as? PEMObjectGroup {
                if let newObjectTemplates = objectLayer.parseExternalTemplates(objectTemplates: objectTemplates) {
                    objectTemplates.merge(newObjectTemplates) { (current, _) in current }
                }
            }
        }
    }
    
    private func renderMap() {
        guard orientation != .unknown else {
            #if DEBUG
            print("PEMTileMap: map orientation is unknown")
            #endif
            return
        }
            
        highestZPosition = baseZPosition
        mapSizeInPoints = mapSizeInPointsFromTileSize
        
        renderLayers()
    }
    
    private func renderLayers() {
        for layer in layers {
            if let tileLayer = layer as? PEMTileLayer {
                if tileLayer.visible {
                    highestZPosition += zPositionLayerDelta

                    tileLayer.render(textureFilteringMode)
                    tileLayer.zPosition = highestZPosition
                    
                    addChild(tileLayer)
                    #if DEBUG
                    print(layer)
                    #endif
                }
                
                continue
            }

            if let imageLayer = layer as? PEMImageLayer {
                if imageLayer.visible {
                    highestZPosition += zPositionLayerDelta
                    
                    imageLayer.render(mapSizeInPoints: mapSizeInPointsFromTileSize, textureFilteringMode:textureFilteringMode)
                    imageLayer.zPosition = highestZPosition
                    
                    addChild(imageLayer)
                    #if DEBUG
                    print(layer)
                    #endif
                }
                continue
            }

            if let objectLayer = layer as? PEMObjectGroup {
                if objectLayer.visible {
                    highestZPosition += zPositionLayerDelta
                    
                    objectLayer.render(textureFilteringMode:textureFilteringMode)
                    objectLayer.zPosition = highestZPosition
                    
                    addChild(objectLayer)
                    #if DEBUG
                    print(layer)
                    #endif
                }
                continue
            }
        }
    }
    
    private func updateCanvas() {
        let MapCanvasName = "PEMTileMapCanvas"
        childNode(withName: MapCanvasName)?.removeFromParent()
        
        if _showCanvas {
            let canvas = mapCanvas(size: mapSizeInPoints, name: MapCanvasName)
            canvas.zPosition = CGFloat.leastNonzeroMagnitude
            addChild(canvas)
        }
    }
    
    private func updateGrid() {
        let MapGridName = "PEMTileMapGrid"
        childNode(withName: MapGridName)?.removeFromParent()
        
        if _showGrid {
            let grid = mapGrid(sizeInTiles: mapSizeInTiles, tileSizeInPoints: tileSizeInPoints, name: MapGridName)
            grid.zPosition = highestZPosition + 1
            grid.alpha = 0.5
            addChild(grid)
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    public override var description: String {
        return "PEMTileMap: \(mapSource ?? "-") (layers: \(layers.count), tileSets: \(tileSets.count))"
    }
    #endif
}
