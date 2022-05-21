import SpriteKit

let LayerNameScreenLayout = "ScreenLayout"
let LayerNameTerrain = "Terrain"
let LayerNameSpawn = "Spawn"

protocol GameSceneDelegate {
    func gameOver()
    func levelCompleted()
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    private enum TileQueryPosition: Int {
        case atCenter
        case above
        case aboveLeft
        case aboveRight
        case below
        case belowLeft
        case belowRight
        case toTheLeft
        case toTheRight
    }
    
    var gameSceneDelegate: GameSceneDelegate?
    private var map: PEMTmxMap?
    private var buttonClicked = false
    private var currentMapNameLabel: SKLabelNode?
    private var currentMapIndex = Int(0)
    private var maps =
    
    // "TestMaps" folder
//    [
//        "level1.tmx",
//        "level2.tmx",
//        "level3.tmx",
//        "level4.tmx",
//        "level5.tmx",
//    ]
    
//    // "Maps" folder
//    [
//        "mylevel1.tmx",
//        "gameart2d-desert.tmx",
//        "jb-32.tmx",
//        "level25.tmx",
//        "MagicLand.tmx",
//    ]
//
    
    // "Roguelike" folder
//    [
//    "sample_map.tmx",
//    "sample_indoor.tmx",
//    ]
    
    // "Tiled Examples" folder
    [
        "sewers.tmx",
        "sandbox.tmx",
        "sandbox2.tmx",
        "island.tmx",
        "forest.tmx",
        "desert.tmx",
        "orthogonal-outside.tmx",
        "hexagonal-mini.tmx",
        "isometric_grass_and_water.tmx",
        "isometric_staggered_grass_and_water.tmx",
        "perspective_walls.tmx",
        "test_hexagonal_tile_60x60x30.tmx",
    ]

    private var player: Player?
    private var previousUpdateTime = TimeInterval(0)
    private var doorOpened = false
    
    private var door: SKSpriteNode?
    private var spawnLayer: PEMTmxTileLayer?
    private var terrainLayer: PEMTmxTileLayer?
    
    // MARK: - Init
    
    override init(size: CGSize) {        
        super.init(size: size)
        
        startControl()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Control

    private func startControl() {
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor(named: "Game-background")!
        
        loadMap()
        initLayers()
        addSpawnObjects()
    }
    
    deinit {
        print("deinit: \(self)")
    }
    
    // MARK: - Map

    private func previousMap() {
        currentMapIndex = currentMapIndex - 1
        if currentMapIndex < 0 {
            currentMapIndex = maps.count - 1
        }
        
        loadMap()
    }

    private func nextMap() {
        currentMapIndex = currentMapIndex + 1
        if currentMapIndex >= maps.count {
            currentMapIndex = 0
        }
        
        loadMap()
    }
    
    private func loadMap() {
        removeHud()
        removeMap()
        
        let mapName = maps[currentMapIndex]

        if let newMap = PEMTmxMap(mapName: mapName, showObjectGroups: true) {
            map = newMap

            if newMap.backgroundColor != nil {
                backgroundColor = newMap.backgroundColor!
            } else {
                backgroundColor = .clear
            }

            camera = newMap.cameraNode
            addChild(newMap.cameraNode)
            
            addHud()
            currentMapNameLabel?.text = mapName

            newMap.position = CGPoint(x: newMap.mapSizeInPoints.width * -0.5, y: newMap.mapSizeInPoints.height * -0.5)
            addChild(newMap)
        }
    }
    
    func removeMap() {
        map?.removeFromParent()
        map = nil
    }
    
    func adjustCamera(buttonIndex: Int) {
        var zoomMode = CameraZoomMode.none
        var viewMode = CameraViewMode.none

        switch buttonIndex {
        case 0:
            zoomMode = .aspectFit
        case 1:
            zoomMode = .aspectFill
        case 2:
            zoomMode = .center
        case 3:
            viewMode = .topLeft
        case 4:
            viewMode = .top
        case 5:
            viewMode = .topRight
        case 6:
            viewMode = .left
        case 7:
            viewMode = .center
        case 8:
            viewMode = .right
        case 9:
            viewMode = .bottomLeft
        case 10:
            viewMode = .bottom
        case 11:
            viewMode = .bottomRight
        default:
            break
        }
        
        map?.moveCamera(sceneSize: size, zoomMode: zoomMode, viewMode: viewMode, factor: 1, duration: 0.5)
    }
    
    // MARK: - HUD
    
    private func addHud() {
        var buttonSize = CGSize(width: 100.0, height: 30.0)

        var newButton = button(name: "previousMapButton", size: buttonSize, text: "Previous", textSize: 14, textColor: .white, fillColor: .red)
        newButton.position = CGPoint(x: buttonSize.width * -0.6, y: size.height * 0.5 - buttonSize.height * 0.5 - 10)
        map?.cameraNode.addChild(newButton)

        newButton = button(name: "nextMapButton", size: buttonSize, text: "Next", textSize: 14, textColor: .white, fillColor: .red)
        newButton.position = CGPoint(x: buttonSize.width * 0.6, y: size.height * 0.5 - buttonSize.height * 0.5 - 10)
        map?.cameraNode.addChild(newButton)
        
        currentMapNameLabel = SKLabelNode(text: "...")
        currentMapNameLabel!.fontSize = 16.0
        currentMapNameLabel!.fontName = "Courier-Bold"
        currentMapNameLabel!.verticalAlignmentMode = .center
        currentMapNameLabel!.position = CGPoint(x: 0, y: newButton.position.y - buttonSize.height - currentMapNameLabel!.calculateAccumulatedFrame().size.height * 0.5)
        map?.cameraNode.addChild(currentMapNameLabel!)
                
        var index = 0
        let buttonTitles = ["Zoom Fit", "Zoom Fill", "No Zoom", "TopLeft", "Top", "TopRight", "Left", "Center", "Right", "BottomLeft", "Bottom", "BottomRight"]
        buttonSize = CGSize(width: 90, height: 20)

        for buttonTitle in buttonTitles {
            var fillColor = SKColor.gray
            
            if index >= 0 && index <= 2 {
                fillColor = .blue
            }
            
            if index == 2 {
                fillColor = .systemBlue
            }
                        
            newButton = button(name: "cameraButton-\(index)", size: buttonSize, text: buttonTitle, textSize: 12, textColor: .white, fillColor: fillColor)
            newButton.position = CGPoint(x: size.width * 0.5 - buttonSize.width * 3 + buttonSize.width * CGFloat(index % 3) + 10 * CGFloat(index % 3), y: size.height * 0.5 - 10 - buttonSize.height * 0.5 - buttonSize.height * CGFloat(index / 3) - 10 * CGFloat(index / 3))
            map?.cameraNode.addChild(newButton)

            index += 1
        }
    }
    
    private func button(name: String?, size: CGSize, text: String, textSize: CGFloat, textColor: SKColor = .white, fillColor: SKColor = .black, strokeColor: SKColor = .white) -> SKShapeNode {
        #if os(iOS)
        let path = UIBezierPath.init(roundedRect: CGRect(origin:CGPoint(x: size.width * -0.5, y: size.height * -0.5), size:size), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: size.height * 0.2, height: size.height * 0.2)).cgPath
        #else
        let path = CGPath.init(roundedRect: CGRect(origin:CGPoint(x: size.width * -0.5, y: size.height * -0.5), size:size), cornerWidth: size.height * 0.2, cornerHeight: size.height * 0.2, transform: nil)
        #endif
        
        let button = SKShapeNode.init(path: path)
        button.name = name
        button.fillColor = fillColor
        button.lineWidth = size.height * 0.05
        button.strokeColor = SKColor.white

        let buttonLabel = SKLabelNode(text: text)
        buttonLabel.name = name
        buttonLabel.fontColor = textColor
        buttonLabel.fontSize = textSize
        buttonLabel.fontName = "Courier"
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = CGPoint.zero
        button.addChild(buttonLabel)
        
        return button
    }
    
    private func removeHud() {
        map?.cameraNode.removeAllChildren()
    }
    
    // MARK: - Layers
    
    private func initLayers() {
        hideScreenLayoutLayer()
//        spawnLayer = tilemapPEM.layerNamed(LayerNameSpawn)
//        terrainLayer = tilemapPEM.layerNamed(LayerNameTerrain)
    }
    
    private func hideScreenLayoutLayer() {
//        let screenLayoutLayer = tilemapJS?.layerNamed(LayerNameScreenLayout)
//        screenLayoutLayer?.isHidden = !SHOW_SCREENLAYOUT_LAYER
    }

    // MARK: - Spawn

    private func addSpawnObjects() {
//        for spawnTile in spawnLayer!.children {
//            print("spawn object: ", spawnTile)
            
//            switch spawnTile.tileData.type {
//            case SpawnTypePlayer:
//                addPlayer(spawnTile)
//                break
//            default:
//                break
//            }
//        }
    }
    
//    private func addPlayer(_ tile : SKTile) {
//        if player != nil {
//            #if DEBUG
//            print("Player already spawned")
//            #endif
//            return
//        }
//
//        let coordinate = tileCoord(tile)
//        let point = tilemap.pointForCoordinate(coord: coordinate)
//
//        player = Player.newPlayer()
//        player?.position = CGPoint(x: point.x, y: point.y + (player!.size.height - tileSize.height) * 0.5)
//        spawnLayer?.addChild(player!)
//
//        _ = spawnLayer?.removeTileAt(coord: coordinate)
//    }
        
    // MARK: - Game cycle
        
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        var delta = currentTime - previousUpdateTime

        if (delta > 0.02) {
            delta = 0.02;
        }

        self.previousUpdateTime = currentTime;
        
        player?.update(delta)
        checkForCollisionsAndMovePlayer()
    }
    
    // MARK: - Collision detection
    
    private func checkForCollisionsAndMovePlayer() {
//        let tileQueryPositions : [TileQueryPosition] = [.Below, .Above, .ToTheLeft, .ToTheRight, .AboveLeft, .AboveRight, .BelowLeft, .BelowRight]
//        
//        for tileQueryPosition in tileQueryPositions {
//            let playerRect = player?.collisionBoundingBox()
//            let playerCoord = tilemap.coordinateForPoint(player!.desiredPosition)
//
//            if playerCoord.y > tilemap.size.height {
//                playerDiedSequence(.FellInRavine)
//                return
//            }
//
//            let tileColumn = tileQueryPosition.rawValue % 3
//            let tileRow = tileQueryPosition.rawValue / 3
//            let tileCoord = CGPoint(x: playerCoord.x + (tileColumn - 1), y: playerCoord.y + (tileRow - 1))
//
//            if let tileFound = tilemap.firstTileAt(coord: tileCoord) {
//                let tileRect = tileFound.frame
//                if playerRect!.intersects(tileRect) {
//                    let intersection = playerRect!.intersection(tileRect)
//
//                    if tileFound.tileData.type == TileTypeWater {
//                        playerDiedSequence(.FellInWater)
//                    }
//
//                    if tileFound.tileData.type == TileTypeTerrain {
//                        switch (tileQueryPosition) {
//                        case .Below:
//                            player?.desiredPosition = CGPoint(x: player!.desiredPosition.x, y: player!.desiredPosition.y + intersection.size.height)
//                            player!.velocity = CGPoint(x: player!.velocity.x, y:0.0)
//                            player?.onGround = true
//                            player?.shouldJump = true
//                        case .Above:
//                            player!.desiredPosition = CGPoint(x: player!.desiredPosition.x, y: player!.desiredPosition.y - intersection.size.height)
//                        case .ToTheLeft:
//                            player!.desiredPosition = CGPoint(x: player!.desiredPosition.x + intersection.size.width, y: player!.desiredPosition.y)
//                        case .ToTheRight:
//                            player!.desiredPosition = CGPoint(x: player!.desiredPosition.x - intersection.size.width, y: player!.desiredPosition.y)
//                        case .AboveLeft:
//                            break
//                        case .AboveRight:
//                            break
//                        case .AtCenter:
//                            break
//                        case .BelowLeft:
//                            break
//                        case .BelowRight:
//                            break
//                        }
//                    }
//                }
//            }
//        }
        
        player?.position = player!.desiredPosition
    }
    
//    func didBegin(_ contact: SKPhysicsContact) {
//        guard let nodeA = contact.bodyA.node else { return }
//        guard let nodeB = contact.bodyB.node else { return }
//
//        var collidedWithNode : SKTile
//
//        print (nodeA)
//        print (nodeB)
//
//
//        if nodeA == player {
//            collidedWithNode = nodeB as! SKTile
//
//            if (contact.bodyB.categoryBitMask & ColliderCategory.Terrain) != 0 {
//                player.didCollideWithTerrain(contact.bodyB.node, direction: contact.contactNormal)
//            }
//        } else {
//            collidedWithNode = nodeA as! SKTile
//
//            if (contact.bodyA.categoryBitMask & ColliderCategory.Terrain) != 0 {
//                player.didCollideWithTerrain(contact.bodyA.node, direction: contact.contactNormal)
//            }
//        }
//        
//        if !doorOpened && collidedWithNode.name == NodeNameDoorKey && contact.contactNormal.dx == 0 && contact.contactNormal.dy > 0 {
//            doorWasOpened(collidedWithNode)
//        }
//
//        if doorOpened && collidedWithNode.name == NodeNameFinish {
//            levelCompletedSequence()
//        }

//        print (collidedWithNode)
//        if !player.isDead && collidedWithNode.tileData.type == TileTypeWater {
//            print("DEAD!")
//            player.isDead = true
//            playerDiedSequence()
//        }
//    }
    
    // MARK: - Game sequence
    
    private func doorWasOpened(_ node: SKSpriteNode?) {
        doorOpened = true
        door?.removeFromParent()
        node?.color = .green
    }
    
    private func levelCompletedSequence() {
        gameSceneDelegate?.levelCompleted()
    }
    
    private func playerDiedSequence() {
        if (player!.isDead) {
            return
        }
        
        player?.isDead = true
                
        run(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.run { 
            self.gameOverSequence()
        }]))
    }
    
    private func gameOverSequence() {
        gameSceneDelegate?.gameOver()
    }
    
    // MARK: - Coords
    
//    func tileCoord(_ tile: SKTile) -> CGPoint {
//        return tilemap.coordinateForPoint(tile.position)
//    }
    
    // MARK: - Tile classes
    
//    override func objectForTileType(named: String?) -> SKTile.Type {
//        switch (named) {
//        case TileTypeTerrain:
//            return TerrainTile.self
//        case TileTypeWater:
//            return WaterTile.self
//        default:
//            return SKTile.self
//        }
//    }

    // MARK: - Input handling

    private func touchDownAtPoint(_ pos: CGPoint) {
        if let node = nodes(at: pos).first {
            let nodeName = node.name ?? ""
            let nodeParentName = node.parent?.name ?? ""
            
            if nodeName == "previousMapButton" || nodeParentName == "previousMapButton" {
                buttonClicked = true
                previousMap()
                return
            }

            if nodeName == "nextMapButton" || nodeParentName == "nextMapButton" {
                buttonClicked = true
                nextMap()
                return
            }

            var touchedNodeName: String?

            if nodeName.hasPrefix("cameraButton-") {
                touchedNodeName = nodeName
            } else if nodeParentName.hasPrefix("cameraButton-") {
                touchedNodeName = nodeParentName
            }
            
            if touchedNodeName != nil {
                let fromIndex = nodeName.index(nodeName.startIndex, offsetBy: 13)
                let number = String(nodeName[fromIndex...])
                
                buttonClicked = true
                adjustCamera(buttonIndex: Int(number)!)
            }
            
        }
        
//        if pos.x > 0 {
//            player!.direction = .right
//        } else {
//            player!.direction = .left
//        }
    }

    private func touchMovedToPoint(_ pos: CGPoint) {
    }

    private func touchUpAtPoint(_ pos: CGPoint) {
        if buttonClicked {
            buttonClicked = false
            return
        }

//        if pos.x > 0 {
//            if player!.direction == .right {
//                player!.direction = .idle
//            }
//        } else {
//            if player!.direction == .left {
//                player!.direction = .idle
//            }
//        }
    }
}

#if os(iOS) || os(tvOS)
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchDownAtPoint(t.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchMovedToPoint(t.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchUpAtPoint(t.location(in: self))
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            touchUpAtPoint(t.location(in: self))
        }
    }
}
#endif

#if os(macOS)
extension GameScene {
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            player!.direction = .right
            return
        case 123: // <-
            player!.direction = .left
            return
        default:
            return
        }
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            if player!.direction == .right {
                player!.direction = .idle
            }
            return
        case 123: // <-
            if player!.direction == .left {
                player!.direction = .idle
            }
            return
        default:
            return
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        touchDownAtPoint(event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        touchMovedToPoint(event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        touchUpAtPoint(event.location(in: self))
    }
}
#endif
