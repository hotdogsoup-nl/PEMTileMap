import SpriteKit

let LayerNameScreenLayout = "ScreenLayout"
let LayerNameTerrain = "Terrain"
let LayerNameSpawn = "Spawn"

protocol GameSceneDelegate {
    func gameOver()
    func levelCompleted()
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    private enum CameraViewMode {
        case AspectFit
        case AspectFill
    }
    
    private enum TileQueryPosition : Int {
        case AboveLeft
        case Above
        case AboveRight
        case ToTheLeft
        case AtCenter
        case ToTheRight
        case BelowLeft
        case Below
        case BelowRight
    }
    
    var gameSceneDelegate : GameSceneDelegate?
    private var map : PEMTmxMap?
    private var cameraNode : SKCameraNode?
    
    private var previousMapButton : SKShapeNode?
    private var nextMapButton : SKShapeNode?
    private var currentMapNameLabel : SKLabelNode?
    private var currentMapIndex = Int(0)
    private var maps = [
                        "level2.tmx",
                        "level5.tmx",
                        "level3.tmx",
                        "level4.tmx",
                        "level1.tmx",
    ]

    private var player : Player?
    private var previousUpdateTime = TimeInterval(0)
    private var doorOpened = false
    
    private var door : SKSpriteNode?
    private var spawnLayer : PEMTmxTileLayer?
    private var terrainLayer : PEMTmxTileLayer?
    
    // MARK: - Init
    
    override init(size: CGSize) {
        super.init(size: size)

        cameraNode = SKCameraNode()
        cameraNode?.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)

        addChild(cameraNode!)
        camera = cameraNode
        
        startControl()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Control

    private func startControl() {
        physicsWorld.contactDelegate = self
        backgroundColor = SKColor(named: "Game-background")!
        
        addHud()
        loadMap()
        initLayers()
        addSpawnObjects()
    }
    
    deinit {
        print("deinit: \(self)")
    }
    
    // MARK: - HUD
    
    private func addHud() {
        let buttonSize = CGSize(width: 100.0, height: 30.0)
        
        #if os(iOS)
        let path = UIBezierPath.init(roundedRect: CGRect(origin:CGPoint(x: buttonSize.width * -0.5, y: buttonSize.height * -0.5), size:buttonSize), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: buttonSize.height * 0.2, height: buttonSize.height * 0.2)).cgPath
        #else
        let path = CGPath.init(roundedRect: CGRect(origin:CGPoint(x: buttonSize.width * -0.5, y: buttonSize.height * -0.5), size:buttonSize), cornerWidth: buttonSize.height * 0.2, cornerHeight: buttonSize.height * 0.2, transform: nil)
        #endif
        
        previousMapButton = SKShapeNode.init(path: path)
        previousMapButton?.fillColor = .red
        previousMapButton?.lineWidth = buttonSize.height * 0.05
        previousMapButton?.strokeColor = .white
        previousMapButton?.position = CGPoint(x: buttonSize.width * -0.6, y: size.height * 0.5 - buttonSize.height * 0.5 - 10)
        cameraNode?.addChild(previousMapButton!)

        var buttonLabel = SKLabelNode(text: "Previous")
        buttonLabel.fontSize = 14.0
        buttonLabel.fontName = "Courier"
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = CGPoint.zero
        previousMapButton!.addChild(buttonLabel)
        
        currentMapNameLabel = SKLabelNode(text: "...")
        currentMapNameLabel!.fontSize = 16.0
        currentMapNameLabel!.fontName = "Courier-Bold"
        currentMapNameLabel!.verticalAlignmentMode = .center
        currentMapNameLabel!.position = CGPoint(x: 0, y: previousMapButton!.position.y - buttonSize.height - currentMapNameLabel!.calculateAccumulatedFrame().size.height * 0.5)
        cameraNode?.addChild(currentMapNameLabel!)

        nextMapButton = SKShapeNode.init(path: path)
        nextMapButton?.fillColor = .red
        nextMapButton?.lineWidth = buttonSize.height * 0.05
        nextMapButton?.strokeColor = .white
        nextMapButton?.position = CGPoint(x: buttonSize.width * 0.6, y: size.height * 0.5 - buttonSize.height * 0.5 - 10)
        cameraNode?.addChild(nextMapButton!)

        buttonLabel = SKLabelNode(text: "Next")
        buttonLabel.fontSize = 14.0
        buttonLabel.fontName = "Courier"
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = CGPoint.zero
        nextMapButton!.addChild(buttonLabel)
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
        map?.removeFromParent()
        map = nil
        
        let mapName = maps[currentMapIndex]
        currentMapNameLabel?.text = mapName

        if let newMap = PEMTmxMap(mapName : mapName) {
            if newMap.backgroundColor != nil {
                backgroundColor = newMap.backgroundColor!
            } else {
                backgroundColor = .clear
            }
            
            newMap.position = CGPoint(x: size.width * 0.5 - newMap.mapSizeInPoints.width * 0.5, y: size.height * 0.5 - newMap.mapSizeInPoints.height * 0.5)
            addChild(newMap)
            map = newMap
            
            cameraNode?.zPosition = newMap.currentZPosition + 1
            zoomCamera(viewMode: .AspectFit, factor:0.8)
        }
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
    
    // MARK: - Camera
    
    private func zoomCamera(viewMode: CameraViewMode, factor:CGFloat = 0.8) {
        if (!FIT_SCENE_TO_VIEW) {
            return
        }
        
        if factor <= 0.0 || factor > 1.0 {
            return
        }
                
        if let mapsize = map?.mapSizeInPoints {
            if mapsize.width == 0 || mapsize.height == 0 {
                return
            }
            
            let maxWidthScale = size.width / mapsize.width
            let maxHeightScale = size.height / mapsize.height
            var contentScale : CGFloat = 1.0
            
            switch viewMode {
            case .AspectFit:
                contentScale = (maxWidthScale < maxHeightScale) ? maxWidthScale : maxHeightScale
            case .AspectFill:
                contentScale = (maxWidthScale > maxHeightScale) ? maxWidthScale : maxHeightScale
            }

            camera?.setScale(1.0 / contentScale / factor)
        }
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
        let node = nodes(at: pos).first
        
        if node == previousMapButton || node?.parent == previousMapButton {
            previousMap()
            return
        }
        
        if node == nextMapButton || node?.parent == nextMapButton {
            nextMap()
            return
        }
        
        if pos.x > 0 {
            player!.direction = .Right
        } else {
            player!.direction = .Left
        }
    }

    private func touchMovedToPoint(_ pos: CGPoint) {
    }

    private func touchUpAtPoint(_ pos: CGPoint) {
        let node = nodes(at: pos).first
        
        if node == previousMapButton || node?.parent == previousMapButton {
            return
        }
        
        if node == nextMapButton || node?.parent == nextMapButton {
            return
        }

        if pos.x > 0 {
            if player!.direction == .Right {
                player!.direction = .Idle
            }
        } else {
            if player!.direction == .Left {
                player!.direction = .Idle
            }
        }
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

#if os(OSX)
extension GameScene {
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            player!.direction = .Right
            return
        case 123: // <-
            player!.direction = .Left
            return
        default:
            return
        }
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            if player!.direction == .Right {
                player!.direction = .Idle
            }
            return
        case 123: // <-
            if player!.direction == .Left {
                player!.direction = .Idle
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
