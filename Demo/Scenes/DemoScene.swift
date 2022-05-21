import SpriteKit

class DemoScene: SKScene {
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
        backgroundColor = SKColor(named: "Game-background")!
        
        loadMap()
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
    }

    private func touchMovedToPoint(_ pos: CGPoint) {
    }

    private func touchUpAtPoint(_ pos: CGPoint) {
        if buttonClicked {
            buttonClicked = false
            return
        }
    }
}

#if os(iOS) || os(tvOS)
extension DemoScene {
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
extension DemoScene {
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            return
        case 123: // <-
            return
        default:
            return
        }
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 124: // ->
            return
        case 123: // <-
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
