import SpriteKit

class DemoScene: SKScene {
    private let DefaultsKeyShowCanvas = "ShowCanvas"
    private let DefaultsKeyShowGrid = "ShowGrid"
    private let DefaultsKeyShowObjectLabels = "ShowObjectLabels"
    
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
    
    private weak var skView: SKView?
    private var map: PEMTileMap?
    private var currentMapIndex = Int(0)
    
    private let textSizeRegular: CGFloat
    private let textSizeSmall: CGFloat
    private var currentMapNameLabel: SKLabelNode?
    private var renderTimeLabel: SKLabelNode?
    private var tileCoordsLabel: SKLabelNode?

    private var maps: Array<Dictionary<String, Any>> = []
    
    private var previousUpdateTime = TimeInterval(0)
    private var cameraNode: SKCameraNode!
    private var previousCameraScale = CGFloat(1.0)
    private var initalTouchLocation = CGPoint.zero
    
    private var buttonTapped = false
    private var rendering = false
    private var showCanvas = false
    private var showGrid = false
    private var showObjectLabels = false

    #if os(iOS)
    private var pinch: UIPinchGestureRecognizer!
    private var pan: UIPanGestureRecognizer!
    #endif
    
    // MARK: - Init
    
    init(view: SKView, size: CGSize) {
        textSizeRegular = size.width * 0.0175
        textSizeSmall = size.width * 0.015
        
        super.init(size: size)
        
        skView = view
        showCanvas = UserDefaults.standard.bool(forKey: DefaultsKeyShowCanvas)
        showGrid = UserDefaults.standard.bool(forKey: DefaultsKeyShowGrid)
        showObjectLabels = UserDefaults.standard.bool(forKey: DefaultsKeyShowObjectLabels)

        cameraNode = SKCameraNode()
        
        if let url = bundleURLForResource("maps.plist") {
            maps = NSArray(contentsOf: url) as! [Dictionary<String, Any>]
            
            maps = maps.filter { item in
                if let itemEnabled = item["enabled"] as? Bool {
                    return itemEnabled == true
                }
                return false
            }
        }
        
        #if os(iOS)
        initGestures()
        #endif

        startControl()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if os(iOS)
    private func initGestures() {
        pinch = UIPinchGestureRecognizer(target: self, action: #selector(scenePinched(_:)))
        pinch.delegate = self
        pan = UIPanGestureRecognizer(target: self, action: #selector(scenePanned(_:)))
        pan.delegate = self
        skView?.addGestureRecognizer(pinch)
        skView?.addGestureRecognizer(pan)
    }
    #endif

    // MARK: - Control

    private func startControl() {
        backgroundColor = SKColor(named: "Game-background")!
        camera = cameraNode
        addChild(cameraNode)

        addHud()
        loadMap()
    }
    
    private func openExternalMapLink() {
        let mapInfo = maps[currentMapIndex]
        let mapURL = mapInfo["url"] as? String
        if let URL = URL(string: mapURL!) {
            #if os(macOS)
            NSWorkspace.shared.open(URL)
            #else
            UIApplication.shared.open(URL)
            #endif
        }
    }
        
    // MARK: - Map

    private func previousMap() {
        if rendering {
            return
        }
            
        currentMapIndex = currentMapIndex - 1
        if currentMapIndex < 0 {
            currentMapIndex = maps.count - 1
        }
        
        loadMap()
    }

    private func nextMap() {
        if rendering {
            return
        }

        currentMapIndex = currentMapIndex + 1
        if currentMapIndex >= maps.count {
            currentMapIndex = 0
        }
        
        loadMap()
    }
    
    private func loadMap() {
        rendering = true
        
        let removeMapAction = SKAction.run {
            self.removeMap()
        }
        
        let renderMapAction = SKAction.run {
            self.renderMap()
        }
        
        run(SKAction.sequence([removeMapAction, renderMapAction]))
    }
    
    private func renderMap() {
        let mapInfo = maps[currentMapIndex]
        let mapName = mapInfo["filename"] as? String
        let mapTitle = mapInfo["title"] as? String
        let mapAuthor = mapInfo["author"] as? String
        
        currentMapNameLabel?.attributedText = attributedString(String(format: "%@ - \"%@\" - %@", mapName!, mapTitle!, mapAuthor!), fontName: "Courier-Bold", textSize: textSizeSmall)
        currentMapNameLabel?.position = CGPoint(x: 0, y: currentMapNameLabel!.calculateAccumulatedFrame().size.height * -0.5)

        if let newMap = PEMTileMap(mapName: mapName!, view: skView!) {
            map = newMap
            
            canvasButton(showCanvas)
            gridButton(showGrid)
            objectLabelsButton(showObjectLabels)

            if newMap.backgroundColor != nil {
                backgroundColor = newMap.backgroundColor!
            } else {
                backgroundColor = .clear
            }

            cameraNode.zPosition = newMap.highestZPosition + 20
            newMap.cameraNode = cameraNode

            renderTimeLabel?.attributedText = attributedString(String("parse time: \(newMap.parseTime.minSecMsRepresentation())\nrender time: \(newMap.renderTime.minSecMsRepresentation())"), fontName: "Courier", textSize: textSizeSmall)

            newMap.position = CGPoint(x: newMap.mapSizeInPoints().width * -0.5, y: newMap.mapSizeInPoints().height * -0.5)
            addChild(newMap)
            rendering = false
        }
    }
    
    private func removeMap() {
        cameraNode.position = .zero
        cameraNode.xScale = 1
        cameraNode.yScale = 1
        
        currentMapNameLabel?.attributedText = attributedString(" ... ", fontName: "Courier-Bold", textSize: textSizeSmall)
        currentMapNameLabel?.position = CGPoint(x: 0, y: currentMapNameLabel!.calculateAccumulatedFrame().size.height * -0.5)
        renderTimeLabel?.attributedText = attributedString(" Rendering... ", fontName: "Courier", textSize: textSizeSmall)

        map?.removeFromParent()
        map = nil
    }
    
    private func canvasButton(_ enabled: Bool) {
        showCanvas = enabled
        map?.showCanvas = showCanvas
        
        UserDefaults.standard.set(enabled, forKey: DefaultsKeyShowCanvas)
        
        if let button = cameraNode.childNode(withName: "canvasButton"),
           let label = button.childNode(withName: button.name!) as? SKLabelNode {
            label.text = (enabled ? "Canvas ✓" : "Canvas")
        }
    }
    
    private func gridButton(_ enabled: Bool) {
        showGrid = enabled
        map?.showGrid = showGrid

        UserDefaults.standard.set(enabled, forKey: DefaultsKeyShowGrid)

        if let button = cameraNode.childNode(withName: "gridButton"),
           let label = button.childNode(withName: button.name!) as? SKLabelNode {
            label.text = (enabled ? "Grid ✓" : "Grid")
        }
    }
    
    private func objectLabelsButton(_ enabled: Bool) {
        showObjectLabels = enabled
        map?.showObjectLabels = showObjectLabels

        UserDefaults.standard.set(enabled, forKey: DefaultsKeyShowObjectLabels)

        if let button = cameraNode.childNode(withName: "objectLabelsButton"),
           let label = button.childNode(withName: button.name!) as? SKLabelNode {
            label.text = (enabled ? "Labels ✓" : "Labels")
        }
    }
    
    private func updateTileCoords(_ position: CGPoint?) {
        if let currentPosition = position {
            let tileCoords = map!.tileCoords(positionInPoints: currentPosition)
            tileCoordsLabel?.attributedText = attributedString(String(format:"tile coords\n(%ld, %ld)", Int(tileCoords.x), Int(tileCoords.y)), fontName: "Courier", textSize: textSizeSmall)
            return
        }
        
        tileCoordsLabel?.attributedText = attributedString("tile coords\n ", fontName: "Courier", textSize: textSizeSmall)
    }
    
    private func adjustCamera(buttonIndex: Int) {
        var zoomMode = CameraZoomMode.none
        var viewMode = CameraViewMode.none

        switch buttonIndex {
        case 0:
            zoomMode = .aspectFit
        case 1:
            zoomMode = .aspectFill
        case 2:
            zoomMode = .actualSize
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
        
        map?.moveCamera(sceneSize: size, zoomMode: zoomMode, viewMode: viewMode, factor: 1, duration: 0.5, timingMode: .easeInEaseOut)
    }
    
    private func attributedString(_ string: String, fontName:String, textSize: CGFloat ) -> NSAttributedString? {
        guard string.count > 0 else { return nil }
        
        let attrString = NSMutableAttributedString(string: string)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let range = NSRange(location: 0, length: string.count)
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)
        
        #if os(macOS)
        attrString.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.font: NSFont(name: fontName, size: textSize) as Any], range: range)
        #else
        attrString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: fontName, size: textSize) as Any], range: range)
        #endif
        
        return attrString
    }
    
    // MARK: - HUD
        
    private func addHud() {
        let logoNode = SKSpriteNode(imageNamed: "logo")
        let scale = size.width * 0.15 / logoNode.size.width
        var verticalMargin = size.height * 0.03
        var horizontalMargin = size.width * 0.02

        var buttonSize = CGSize(width: size.width * 0.1, height: size.width * 0.03)

        logoNode.size = logoNode.size.scaled(scale)
        logoNode.position = CGPoint(x: size.width * -0.5 + logoNode.size.width * 0.5 + horizontalMargin, y: size.height * 0.5 - buttonSize.height * 0.5 - verticalMargin)
        cameraNode.addChild(logoNode)
        
        var newButton = button(name: "previousMapButton", buttonSize: buttonSize, text: "Previous", textSize: textSizeRegular, textColor: .white, fillColor: .red)
        newButton.position = CGPoint(x: buttonSize.width * -0.6, y: size.height * 0.5 - buttonSize.height * 0.5 - verticalMargin)
        cameraNode.addChild(newButton)

        newButton = button(name: "nextMapButton", buttonSize: buttonSize, text: "Next", textSize: textSizeRegular, textColor: .white, fillColor: .red)
        newButton.position = CGPoint(x: buttonSize.width * 0.6, y: size.height * 0.5 - buttonSize.height * 0.5 - verticalMargin)
        cameraNode.addChild(newButton)
        
        renderTimeLabel = SKLabelNode(attributedText: attributedString(" ... ", fontName: "Courier", textSize: textSizeSmall))
        renderTimeLabel?.numberOfLines = 0
        renderTimeLabel?.position = CGPoint(x: 0, y: newButton.position.y - newButton.calculateAccumulatedFrame().size.height * 1.4 - verticalMargin)
        cameraNode.addChild(renderTimeLabel!)
        
        newButton = button(name: "canvasButton", buttonSize: buttonSize, text: "Canvas", textSize: textSizeRegular, textColor: .white, fillColor: .blue)
        newButton.position = CGPoint(x: size.width * -0.5 + newButton.calculateAccumulatedFrame().size.width * 0.5 + horizontalMargin, y: logoNode.position.y - buttonSize.height * 1.25 - verticalMargin)
        cameraNode.addChild(newButton)
        
        newButton = button(name: "gridButton", buttonSize: buttonSize, text: "Grid", textSize: textSizeRegular, textColor: .white, fillColor: .blue)
        newButton.position = CGPoint(x: size.width * -0.5 + newButton.calculateAccumulatedFrame().size.width * 0.5 + horizontalMargin, y: logoNode.position.y - buttonSize.height * 2 - verticalMargin * 2)
        cameraNode.addChild(newButton)
        
        newButton = button(name: "objectLabelsButton", buttonSize: buttonSize, text: "Labels", textSize: textSizeRegular, textColor: .white, fillColor: .blue)
        newButton.position = CGPoint(x: size.width * -0.5 + newButton.calculateAccumulatedFrame().size.width * 0.5 + horizontalMargin, y: logoNode.position.y - buttonSize.height * 3 - verticalMargin * 3)
        cameraNode.addChild(newButton)
        
        tileCoordsLabel = SKLabelNode(attributedText: attributedString("tile coords\n ", fontName: "Courier", textSize: textSizeSmall))
        tileCoordsLabel?.numberOfLines = 0
        tileCoordsLabel?.position = CGPoint(x: newButton.position.x, y: newButton.position.y - newButton.calculateAccumulatedFrame().size.height * 0.5 - verticalMargin - tileCoordsLabel!.calculateAccumulatedFrame().size.height * 0.75)
        cameraNode.addChild(tileCoordsLabel!)
        
        let roundedBox = roundedBox(size: CGSize(width: size.width * 0.8, height: textSizeRegular * 2.0), fillColor: SKColor(white: 0, alpha: 0.5))
        roundedBox.position = CGPoint(x: 0, y: size.height * -0.5 + roundedBox.calculateAccumulatedFrame().size.height + verticalMargin)
        cameraNode.addChild(roundedBox)
        
        currentMapNameLabel = SKLabelNode(attributedText: attributedString(" ... ", fontName: "Courier-Bold", textSize: textSizeSmall))
        currentMapNameLabel?.numberOfLines = 0
        currentMapNameLabel?.position = CGPoint(x: 0, y: currentMapNameLabel!.calculateAccumulatedFrame().size.height * -0.5)
        roundedBox.addChild(currentMapNameLabel!)
        
        let externalLinkButton = SKSpriteNode(texture: SKTexture(imageNamed: "link-icon"))
        externalLinkButton.size = CGSize(width: textSizeRegular * 1.25, height: textSizeRegular * 1.25)
        externalLinkButton.name = "externalLinkButton"
        externalLinkButton.position = CGPoint(x: roundedBox.calculateAccumulatedFrame().size.width * 0.5 - externalLinkButton.size.width, y:0)
        roundedBox.addChild(externalLinkButton)
                                
        var index = 0
        var buttonTitles = ["Fit", "Fill", "1:1"]
        buttonSize = CGSize(width: size.width * 0.05, height: size.width * 0.03)
        verticalMargin = size.height * 0.025
        horizontalMargin = size.width * 0.01
                
        for buttonTitle in buttonTitles {
            var fillColor = SKColor.blue
            let strokeColor = SKColor.white
            
            if index == 2 {
                fillColor = .systemBlue
            }

            newButton = button(name: "cameraButton-\(index)", buttonSize: buttonSize, text: buttonTitle, textSize: textSizeRegular, textColor: .white, fillColor: fillColor, strokeColor: strokeColor)
            newButton.position = CGPoint(x: size.width * 0.5 - (buttonSize.width + horizontalMargin) * 3 + buttonSize.width * CGFloat(index % 3) + horizontalMargin * CGFloat(index % 3), y: size.height * 0.5 - verticalMargin - buttonSize.height * 0.5 - buttonSize.height * CGFloat(index / 3) - verticalMargin * CGFloat(index / 3))
            cameraNode.addChild(newButton)
            
            if index == 1 {
                let cameraLabel = SKLabelNode(attributedText: attributedString("Camera Alignment", fontName: "Courier", textSize: textSizeSmall))
                cameraLabel.numberOfLines = 0
                cameraLabel.position = CGPoint(x: newButton.position.x, y: newButton.position.y - buttonSize.height - cameraLabel.calculateAccumulatedFrame().size.height * 0.5)
                cameraNode.addChild(cameraLabel)
            }

            index += 1
        }

        buttonTitles = ["↖️", "⬆️", "↗️", "⬅️", "⏺", "➡️", "↙️", "⬇️", "↘️"]

        for buttonTitle in buttonTitles {
            let fillColor = SKColor.clear
            let strokeColor = SKColor.clear
            let smallButtonSize = CGSize(width: textSizeRegular, height: textSizeRegular)

            newButton = button(name: "cameraButton-\(index)", buttonSize: smallButtonSize, text: buttonTitle, textSize: textSizeRegular * 1.5, textColor: .white, fillColor: fillColor, strokeColor: strokeColor)
            newButton.position = CGPoint(x: size.width * 0.5 - (buttonSize.width + horizontalMargin) * 3 + buttonSize.width * CGFloat(index % 3) + horizontalMargin * CGFloat(index % 3), y: size.height * 0.5 - verticalMargin - buttonSize.height * 1.25 - buttonSize.height * CGFloat(index / 3) - verticalMargin * CGFloat(index / 3))
            cameraNode.addChild(newButton)

            index += 1
        }
    }
    
    private func button(name: String?, buttonSize: CGSize, text: String, textSize: CGFloat, textColor: SKColor = .white, fillColor: SKColor = .black, strokeColor: SKColor = .white) -> SKShapeNode {
        #if os(iOS)
        let path = UIBezierPath.init(roundedRect: CGRect(origin:CGPoint(x: buttonSize.width * -0.5, y: buttonSize.height * -0.5), size:buttonSize), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: buttonSize.height * 0.2, height: buttonSize.height * 0.2)).cgPath
        #else
        let path = CGPath.init(roundedRect: CGRect(origin:CGPoint(x: buttonSize.width * -0.5, y: buttonSize.height * -0.5), size:buttonSize), cornerWidth: buttonSize.height * 0.2, cornerHeight: buttonSize.height * 0.2, transform: nil)
        #endif
        
        let button = SKShapeNode.init(path: path)
        button.name = name
        button.fillColor = fillColor
        button.lineWidth = buttonSize.height * 0.05
        button.strokeColor = strokeColor

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
    
    private func roundedBox(size: CGSize, fillColor: SKColor = .black) -> SKShapeNode {
        #if os(iOS)
        let path = UIBezierPath.init(roundedRect: CGRect(origin:CGPoint(x: size.width * -0.5, y: size.height * -0.5), size:size), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: size.height * 0.1, height: size.height * 0.1)).cgPath
        #else
        let path = CGPath.init(roundedRect: CGRect(origin:CGPoint(x: size.width * -0.5, y: size.height * -0.5), size:size), cornerWidth: size.height * 0.1, cornerHeight: size.height * 0.1, transform: nil)
        #endif
        
        let box = SKShapeNode.init(path: path)
        box.name = name
        box.fillColor = fillColor
        box.lineWidth = 0
        box.strokeColor = .clear
        
        return box
    }

    // MARK: - Input handling

    private func touchDownAtPoint(_ pos: CGPoint) {
        if let node = nodes(at: pos).first {
            let nodeName = node.name ?? ""
            let nodeParentName = node.parent?.name ?? ""
            
            if nodeName == "previousMapButton" || nodeParentName == "previousMapButton" {
                buttonTapped = true
                previousMap()
                return
            }

            if nodeName == "nextMapButton" || nodeParentName == "nextMapButton" {
                buttonTapped = true
                nextMap()
                return
            }
            
            if nodeName == "externalLinkButton" {
                buttonTapped = true
                openExternalMapLink()
                return
            }
            
            if nodeName == "canvasButton" {
                buttonTapped = true
                canvasButton(!showCanvas)
                return
            }

            if nodeName == "gridButton" {
                buttonTapped = true
                gridButton(!showGrid)
                return
            }

            if nodeName == "objectLabelsButton" {
                buttonTapped = true
                objectLabelsButton(!showObjectLabels)
                return
            }
            
            var touchedCameraButtonName: String?

            if nodeName.hasPrefix("cameraButton-") {
                touchedCameraButtonName = nodeName
            } else if nodeParentName.hasPrefix("cameraButton-") {
                touchedCameraButtonName = nodeParentName
            }
            
            if touchedCameraButtonName != nil {
                let fromIndex = nodeName.index(nodeName.startIndex, offsetBy: 13)
                let number = String(nodeName[fromIndex...])
                
                buttonTapped = true
                adjustCamera(buttonIndex: Int(number)!)
                return
            }
            
#if os(iOS) || os(tvOS)
            if map != nil {
                let location = convert(pos, to: map!)
                updateTileCoords(location)
            }
#endif
            
        }
        
        #if os(macOS)
        initalTouchLocation = pos
        #endif
    }

    private func touchMovedToPoint(_ pos: CGPoint) {
        guard !buttonTapped else { return }

        #if os(macOS)
        let delta = initalTouchLocation.subtract(pos)
        cameraNode.position = cameraNode.position.add(delta)
        #endif
    }

    private func touchUpAtPoint(_ pos: CGPoint) {
        guard !buttonTapped else {
            buttonTapped = false
            return
        }
        
#if os(iOS) || os(tvOS)
            if map != nil {
                updateTileCoords(nil)
            }
#endif

    }
    
#if os(macOS)
    private func mouseMovedToPoint(_ pos: CGPoint) {
        guard map != nil else { return }
        let location = convert(pos, to: map!)
        updateTileCoords(location)
    }
#endif
}

#if os(iOS) || os(tvOS)

extension DemoScene: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for t in touches {
            touchDownAtPoint(t.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        for t in touches {
            touchMovedToPoint(t.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        for t in touches {
            touchUpAtPoint(t.location(in: self))
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        for t in touches {
            touchUpAtPoint(t.location(in: self))
        }
    }
    
    #if os(iOS)

    @objc public func scenePinched(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .began {
           previousCameraScale = cameraNode.xScale
         }
        
        if recognizer.state == .changed {
            cameraNode.setScale(previousCameraScale * 1 / recognizer.scale)
        }
    }
    
    @objc public func scenePanned(_ recognizer: UIPanGestureRecognizer) {
        let pos = recognizer.translation(in: self.view)

        if recognizer.state == .began {
            initalTouchLocation = cameraNode.position
        }
        
        if recognizer.state == .changed {
            let translation = pos
            let newPosition = CGPoint(
                x: initalTouchLocation.x + translation.x * -1 * cameraNode.xScale,
                y: initalTouchLocation.y + translation.y * cameraNode.yScale
            )
            
            cameraNode.position = newPosition
        }
    }

    #endif
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
    
    override func mouseMoved(with event: NSEvent) {
        mouseMovedToPoint(event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        touchMovedToPoint(event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        touchUpAtPoint(event.location(in: self))
    }
        
    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.shift) {
            guard event.scrollingDeltaY > 1 || event.scrollingDeltaY < -1 else { return }

            var newScale = cameraNode.xScale + event.scrollingDeltaY * 0.00625
            newScale = max(0.1, min(newScale, 20))
            cameraNode.xScale = newScale
            cameraNode.yScale = newScale

            return
        }
        
        let positionDelta = CGPoint(x: -event.scrollingDeltaX, y: event.scrollingDeltaY)
        cameraNode.position = cameraNode.position.add(positionDelta)
    }
    
    // MARK: - View
        
    #if os(macOS)
    
    public func didChangeSize() {
    }
    
    #endif
}

#endif
