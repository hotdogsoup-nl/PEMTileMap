import Foundation
import SpriteKit
import zlib
import CoreGraphics

/// Camera zoom mode.
public enum CameraZoomMode {
    case none
    case actualSize
    case aspectFit
    case aspectFill
}

/// Camera view mode.
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

/// TMX Map orientation.
public enum MapOrientation: String {
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
    /// Adds a background node to the map representing the map canvas when set to `true`. Removes the canvas when set to `false`.
    public var showCanvas: Bool {
        set {
            _showCanvas = newValue
            updateCanvas()
        }
        get {
            return _showCanvas
        }
    }
    
    /// Adds a grid node to the map representing the tile grid when set to `true`. Removes the grid when set to `false`.
    public var showGrid: Bool {
        set {
            _showGrid = newValue
            updateGrid()
        }
        get {
            return _showGrid
        }
    }
    
    /// Adds a node to the map containing object labels  when set to `true`. Removes the node when set to `false`.
    public var showObjectLabels: Bool {
        set {
            _showObjectLabels = newValue
            updateObjectLabels()
        }
        get {
            return _showObjectLabels
        }
    }
    
    /// To use camera functions, this variable must be set to the `SKScene` camera.
    public weak var cameraNode: SKCameraNode?

    /// Background color of the map.
    public private (set) var backgroundColor: SKColor?
    
    /// Highest generated ZPosition after rendering the map.
    public private (set) var highestZPosition = CGFloat(0)

    /// Number of seconds that the map took to parse files.
    public private (set) var parseTime = TimeInterval(0)

    /// Number of seconds that the map took to render.
    public private (set) var renderTime = TimeInterval(0)

    /// TMX Map properties.
    private (set) var properties: Dictionary<String, Any>?
    
    /// TMX Map orientation.
    private (set) var orientation: MapOrientation = .unknown

    private var version: String?
    private var mapSource: String?
    private var tiledversion: String?

    private var _showCanvas: Bool = false
    private var _showGrid: Bool = false
    private var _showObjectLabels: Bool = false

    private var coordinateHelper: PEMCoordinateHelper?
    private var hexSideLengthInPoints = Int(0)
    private var parallaxOriginInPoints = CGPoint.zero
    private var infinite = false
    
    private (set) weak var skView: SKView?
    
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
    
    // MARK: - Init
        
    /// Load a **TMX** tilemap file and return a new `PEMTileMap` node. Returns nil if the file could not be read or parsed.
    /// - Parameters:
    ///     - mapName : TMX file name.
    ///     - view : The `SKView` of the `SKScene`.
    ///     - baseZPosition : Optional base zPosition for the node. Default is 0.
    ///     - zPositionLayerDelta : Optional delta for the zPosition of each layer node. Default is 20.
    ///     - textureFilteringMode : Optional texture anti aliasing / filtering mode. Default is Nearest Neighbor
    /// - returns: A `PEMTileMap` node if the TMX file could be parsed succesfully.
    public init?(mapName: String, view: SKView, baseZPosition: CGFloat = 0, zPositionLayerDelta: CGFloat = 20, textureFilteringMode: SKTextureFilteringMode = .nearest) {
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
        
        skView = view
        
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
    
    // MARK: - Coordinates
    
    /// Get the map canvas size (in points) based on the TMX map width and height multiplied by the tile size.
    ///
    /// Note that objects can be placed outside of the map canvas. This function does not include those tiles. To get the map size including any objects outside of the canvas, use `calculateAccumulatedFrame()`.
    /// - Returns: Map size as a `CGSize`.
    public func mapSizeInPoints() -> CGSize {
        guard coordinateHelper != nil else { return .zero }
        return coordinateHelper!.mapSizeInPoints
    }
    
    /// Get the map size (in tiles) based on the TMX map width and height.
    /// - Returns: Map size as a `CGSize`.
    public func mapSizeInTiles() -> CGSize {
        guard coordinateHelper != nil else { return .zero }
        return coordinateHelper!.mapSizeInTiles
    }
    
    /// Get the tile size (in points) based on the TMX map tile width and height.
    /// - Returns: Tile size as a `CGSize`.
    public func tileSizeInPoints() -> CGSize {
        guard coordinateHelper != nil else { return .zero }
        return coordinateHelper!.tileSizeInPoints
    }
    
    /// Get half of the tile size (in points) based on the TMX map tile width and height.
    /// - Returns: Halved tile size as a `CGSize`.
    public func halfTileSizeInPoints() -> CGSize {
        guard coordinateHelper != nil else { return .zero }
        return coordinateHelper!.halfTileSizeInPoints
    }
    
    /// Converts the tile coordinates of a  TMX Map tile to `SpriteKit` coordinates (in points).
    /// - Parameter tileCoords: TMX tile coordinates.
    /// - Parameter centered: If `true`, adjusts the result to the center of the tile rather than the top left point.
    /// - Returns: Position as a `CGPoint`.
    public func position(tileCoords: CGPoint, centered: Bool = false) -> CGPoint {
        guard coordinateHelper != nil else { return .zero }
        var position = coordinateHelper!.position(tileCoords: tileCoords)
        if centered {
            position = position.add(CGPoint(x: tileSizeInPoints().width * 0.5, y:tileSizeInPoints().height * -0.5))
        }
        return position
    }
    
    /// Converts the pixel coordinates of a  TMX Map object to `SpriteKit` coordinates (in points).
    /// - Parameter coordsInPoints: TMX pixel coordinates.
    /// - Returns: Position as a `CGPoint`.
    public func position(coordsInPoints: CGPoint) -> CGPoint {
        guard coordinateHelper != nil else { return .zero }
        return coordinateHelper!.position(coordsInPoints: coordsInPoints)
    }
    
    /// Converts a `SpriteKit` position on the map to TMX Map tile coordinates (in tiles).
    /// - Parameter positionInPoints: TMX pixel coordinates.
    /// - Returns: Tile coordinates as a `CGPoint`.
    public func tileCoords(positionInPoints: CGPoint) -> CGPoint {
        guard coordinateHelper != nil else { return .zero }
        return coordinateHelper!.tileCoords(positionInPoints: positionInPoints)
    }
    
    // MARK: - Layers, tiles, objects
    
    /// Find a TMX Map layer with a specific name.
    /// - Parameter name: The name of the layer to search for.
    /// - Returns: The first layer found on the map which has the specified name.
    public func layerNamed(_ name: String) -> Any? {
        guard name.count > 0 else { return nil }
        
        for layer in layers {
            if layer.name == name {
                return layer
            }
        }
        
        return nil
    }
    
    /// Find a tile with specific coordinates.
    /// - Parameter tileCoords: TMX Map tile coordinates (in tiles).
    /// - Returns: The first tile found on the map which at the specified coordinates. Note that multiple layers may be present on the map with tiles at the same coordinates.
    public func tileAt(tileCoords: CGPoint) -> PEMTile? {
        for layer in layers {
            if let tileLayer = layer as? PEMTileLayer {
                if let tile = tileLayer.tileAt(tileCoords: tileCoords) {
                    return tile
                }
            }
        }
        
        return nil
    }
    
    /// Find a tile with specific coordinates on a specific layer.
    /// - Parameter tileCoords: TMX Map tile coordinates (in tiles).
    /// - Parameter inLayer: The `PEMTileLayer` to find the tile in.
    /// - Returns: The tile found on the specified layer which at the specified coordinates.
    public func tileAt(tileCoords: CGPoint, inLayer tileLayer: PEMTileLayer) -> PEMTile? {
        return tileLayer.tileAt(tileCoords: tileCoords)
    }
        
    // MARK: - Camera
    
    /// Zoom, pan and tilt the camera to predefined positions on the map. Changes the camera scale using the specified `CameraZoomMode` and its position using the specified `CameraViewMode` with optional animation.
    ///
    /// For example in a "Mario" style platform game, when starting a level, the camera will move to the bottom left of the map and zoom in so it fills the screen vertically, leaving the rest of the map outside of the screen to the right.
    ///
    /// This can be achieved by calling **moveCamera** with
    /// * `zoomMode` = **.aspectFill**
    /// * `viewMode` =  **.bottomLeft**
    ///
    /// It is required that an `SKCameraNode` has been added to the `SKScene` and the `cameraNode` var on the map was set to point to it. Both `zoomMode` and `viewMode` can be disabled by using a value of **.none**. This way a camera move can be made without zooming or panning.
    ///
    /// - Parameters:
    ///     - sceneSize : Size of the `SKScene` the map is a child of and in which the camera move will be made.
    ///     - zoomMode : Used to determine the camera zoom scale within the given `sceneSize`.
    ///     - viewMode : Used to determine how the camera position is aligned within the given `sceneSize`.
    ///     - factor : Optional movement factor that limits the move. A value of 1.0 means full motion within the given `sceneSize`.
    ///     - duration : Optional duration (in seconds) to animate the movement. A value of 0 will result in no animation.
    ///     - timingMode: Optional `SKActionTimingMode` for the animation. Defaults to `.linear`.
    ///     - completion : Optional completion block which is called when camera movement has finished.
    public func moveCamera(sceneSize: CGSize, zoomMode: CameraZoomMode, viewMode: CameraViewMode, factor: CGFloat = 1.0, duration: TimeInterval = 0, timingMode: SKActionTimingMode = .linear, completion:@escaping () -> Void = {}) {
        guard cameraNode != nil else { return }
        
        if zoomMode != .none && mapSizeInPoints().width > 0 && mapSizeInPoints().height > 0 {
            let maxWidthScale = sceneSize.width / mapSizeInPoints().width
            let maxHeightScale = sceneSize.height / mapSizeInPoints().height
            var contentScale : CGFloat = 1.0
            
            switch zoomMode {
            case .aspectFit:
                contentScale = (maxWidthScale < maxHeightScale) ? maxWidthScale : maxHeightScale
            case .aspectFill:
                contentScale = (maxWidthScale > maxHeightScale) ? maxWidthScale : maxHeightScale
            case .actualSize:
                contentScale = 1.0
            case .none:
                break
            }
            
            let newScale = (1.0 / contentScale / factor * 100).rounded() / 100
            
            if duration > 0 && viewMode == .none {
                let zoomAction = SKAction.scale(to: newScale, duration: duration)
                zoomAction.timingMode = timingMode
                cameraNode?.run(zoomAction)
            } else {
                cameraNode?.xScale = newScale
                cameraNode?.yScale = newScale
            }
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
                    newPosition.x = sceneSize.width * 0.5 * factor * cameraScale + mapSizeInPoints().width * -0.5
                } else if viewMode == .top || viewMode == .bottom {
                    newPosition.x = 0
                } else if viewMode == .right || viewMode == .topRight || viewMode == .bottomRight {
                    newPosition.x = sceneSize.width * -0.5 * factor * cameraScale + mapSizeInPoints().width * 0.5
                }
                
                if viewMode == .top || viewMode == .topLeft || viewMode == .topRight {
                    newPosition.y = sceneSize.height * -0.5 * factor * cameraScale + mapSizeInPoints().height * 0.5
                } else if viewMode == .left || viewMode == .right {
                    newPosition.y = 0
                } else if viewMode == .bottom || viewMode == .bottomLeft || viewMode == .bottomRight {
                    newPosition.y = sceneSize.height * 0.5 * factor * cameraScale + mapSizeInPoints().height * -0.5
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
            
        }
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
        
        if let mapOrientation = MapOrientation(rawValue: orientationValue) {
            orientation = mapOrientation
        } else {
            #if DEBUG
            print("PEMTileMap: unsupported map orientation: \(String(describing: orientationValue))")
            #endif
        }
        
        let mapSizeInTiles = CGSize(width: Int(width)!, height: Int(height)!)
        let tileSizeInPoints = CGSize(width: Int(tilewidth)!, height: Int(tileheight)!)
        
        coordinateHelper = PEMCoordinateHelper(orientation: orientation, mapSizeInTiles: mapSizeInTiles, tileSizeInPoints: tileSizeInPoints)
        
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
        renderLayers()
    }
    
    private func renderLayers() {
        for layer in layers {
            if let tileLayer = layer as? PEMTileLayer {
                highestZPosition += zPositionLayerDelta

                tileLayer.render(map: self, textureFilteringMode: textureFilteringMode)
                tileLayer.zPosition = highestZPosition
                
                addChild(tileLayer)
                #if DEBUG
                print(layer)
                #endif
                continue
            }

            if let imageLayer = layer as? PEMImageLayer {
                highestZPosition += zPositionLayerDelta
                
                imageLayer.render(mapSizeInPoints: coordinateHelper!.mapSizeInPoints, textureFilteringMode:textureFilteringMode)
                imageLayer.zPosition = highestZPosition
                
                addChild(imageLayer)
                #if DEBUG
                print(layer)
                #endif
                continue
            }

            if let objectLayer = layer as? PEMObjectGroup {
                highestZPosition += zPositionLayerDelta
                
                objectLayer.render(map: self, textureFilteringMode:textureFilteringMode)
                objectLayer.zPosition = highestZPosition
                
                addChild(objectLayer)
                #if DEBUG
                print(layer)
                #endif
                continue
            }
        }
    }
    
    private func updateCanvas() {
        let MapCanvasName = "PEMTileMapCanvas"
        childNode(withName: MapCanvasName)?.removeFromParent()
        
        if _showCanvas {
            guard coordinateHelper != nil else { return }
            
            let canvas = mapCanvas(coordinateHelper: coordinateHelper!, name: MapCanvasName)
            canvas.zPosition = CGFloat.leastNonzeroMagnitude
            addChild(canvas)
        }
    }
    
    private func updateGrid() {
        let MapGridName = "PEMTileMapGrid"
        childNode(withName: MapGridName)?.removeFromParent()
        
        if _showGrid {
            guard coordinateHelper != nil else { return }

            let grid = mapGrid(coordinateHelper: coordinateHelper!, name: MapGridName)
            grid.zPosition = highestZPosition + 1
            grid.alpha = 0.5
            addChild(grid)
        }
    }
    
    private func updateObjectLabels() {
        for layer in layers {
            if let objectLayer = layer as? PEMObjectGroup {
                objectLayer.updateObjectLabels(visible: _showObjectLabels)
            }
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    public override var description: String {
        return "PEMTileMap: \(mapSource ?? "-") (layers: \(layers.count), tileSets: \(tileSets.count))"
    }
    #endif
}
