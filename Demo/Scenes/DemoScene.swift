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
    
    private var map: PEMTileMap?
    private var currentMapIndex = Int(20)
    private var currentMapNameLabel: SKLabelNode?
    private var renderTimeLabel: SKLabelNode?
    private var externalLinkButton: SKSpriteNode?

    private var buttonTapped = false

    private var maps: Array<Dictionary<String, String>> = []
    
    private var previousUpdateTime = TimeInterval(0)
    private var cameraNode: SKCameraNode!
    private var previousCameraScale = CGFloat(1.0)
    private var initalTouchLocation = CGPoint.zero
    
    private var rendering = false
    
    #if os(iOS)
    private var pinch: UIPinchGestureRecognizer!
    private var pan: UIPanGestureRecognizer!
    #endif
    
    // MARK: - Init
    
    init(view: SKView, size: CGSize) {
        super.init(size: size)
        
        cameraNode = SKCameraNode()
        
        if let url = bundleURLForResource("maps.plist") {
            maps = NSArray(contentsOf: url) as! [Dictionary<String, String>]
        }
        
        #if os(iOS)
        pinch = UIPinchGestureRecognizer(target: self, action: #selector(scenePinched(_:)))
        pinch.delegate = self
        pan = UIPanGestureRecognizer(target: self, action: #selector(scenePanned(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(pan)
        #endif

        startControl()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit: \(self)")
    }
    
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
        let mapURL = mapInfo["url"]
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
        let mapName = mapInfo["filename"]
        let mapTitle = mapInfo["title"]
        let mapAuthor = mapInfo["author"]
        
        let textSize = size.width * 0.015
        currentMapNameLabel?.attributedText = attributedString(String(format: "%@ - \"%@\" - %@", mapName!, mapTitle!, mapAuthor!), fontName: "Courier-Bold", textSize: textSize)
        currentMapNameLabel?.position = CGPoint(x: 0, y: currentMapNameLabel!.calculateAccumulatedFrame().size.height * -0.5)

        if let newMap = PEMTileMap(mapName: mapName!) {
            map = newMap
            map?.showCanvas = true

            if newMap.backgroundColor != nil {
                backgroundColor = newMap.backgroundColor!
            } else {
                backgroundColor = .clear
            }

            cameraNode.zPosition = newMap.highestZPosition + 20
            newMap.cameraNode = cameraNode

            renderTimeLabel?.attributedText = attributedString(String("parse time: \(newMap.parseTime.stringValue())\nrender time: \(newMap.renderTime.stringValue())"), fontName: "Courier", textSize: textSize)

            newMap.position = CGPoint(x: newMap.mapSizeInPoints.width * -0.5, y: newMap.mapSizeInPoints.height * -0.5)
            addChild(newMap)
            rendering = false
        }
    }
    
    func removeMap() {
        let textSize = size.width * 0.015

        cameraNode.position = .zero
        cameraNode.xScale = 1
        cameraNode.yScale = 1
        
        currentMapNameLabel?.attributedText = attributedString(" ... ", fontName: "Courier-Bold", textSize: textSize)
        currentMapNameLabel?.position = CGPoint(x: 0, y: currentMapNameLabel!.calculateAccumulatedFrame().size.height * -0.5)
        renderTimeLabel?.attributedText = attributedString(" Rendering... ", fontName: "Courier", textSize: textSize)

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
        
        map?.moveCamera(sceneSize: size, zoomMode: zoomMode, viewMode: viewMode, factor: 1, duration: 0.5, timingMode: .easeInEaseOut)
    }
    
    private func attributedString(_ string: String, fontName:String, textSize: CGFloat ) -> NSAttributedString {
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
        var textSize = size.width * 0.0175

        logoNode.size = logoNode.size.scaled(scale)
        logoNode.position = CGPoint(x: size.width * -0.5 + logoNode.size.width * 0.5 + horizontalMargin, y: size.height * 0.5 - buttonSize.height * 0.5 - verticalMargin)
        cameraNode.addChild(logoNode)
        
        var newButton = button(name: "previousMapButton", buttonSize: buttonSize, text: "Previous", textSize: textSize, textColor: .white, fillColor: .red)
        newButton.position = CGPoint(x: buttonSize.width * -0.6, y: size.height * 0.5 - buttonSize.height * 0.5 - verticalMargin)
        cameraNode.addChild(newButton)

        newButton = button(name: "nextMapButton", buttonSize: buttonSize, text: "Next", textSize: textSize, textColor: .white, fillColor: .red)
        newButton.position = CGPoint(x: buttonSize.width * 0.6, y: size.height * 0.5 - buttonSize.height * 0.5 - verticalMargin)
        cameraNode.addChild(newButton)
        
        renderTimeLabel = SKLabelNode(attributedText: attributedString(" ... ", fontName: "Courier", textSize: textSize))
        renderTimeLabel?.numberOfLines = 0
        renderTimeLabel?.position = CGPoint(x: 0, y: newButton.position.y - newButton.calculateAccumulatedFrame().size.height * 1.4 - verticalMargin)
        cameraNode.addChild(renderTimeLabel!)
        
        let roundedBox = roundedBox(size: CGSize(width: size.width * 0.8, height: textSize * 2.0), fillColor: SKColor(white: 0, alpha: 0.5))
        roundedBox.position = CGPoint(x: 0, y: size.height * -0.5 + roundedBox.calculateAccumulatedFrame().size.height + verticalMargin)
        cameraNode.addChild(roundedBox)
        
        currentMapNameLabel = SKLabelNode(attributedText: attributedString(" ... ", fontName: "Courier-Bold", textSize: textSize))
        currentMapNameLabel?.numberOfLines = 0
        currentMapNameLabel?.position = CGPoint(x: 0, y: currentMapNameLabel!.calculateAccumulatedFrame().size.height * -0.5)
        roundedBox.addChild(currentMapNameLabel!)
        
        externalLinkButton = SKSpriteNode(texture: SKTexture(imageNamed: "link-icon"))
        externalLinkButton?.size = CGSize(width: textSize * 1.25, height: textSize * 1.25)
        externalLinkButton?.name = "externalLinkButton"
        externalLinkButton?.position = CGPoint(x: roundedBox.calculateAccumulatedFrame().size.width * 0.5 - externalLinkButton!.size.width, y:0)
        roundedBox.addChild(externalLinkButton!)
                                
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

            newButton = button(name: "cameraButton-\(index)", buttonSize: buttonSize, text: buttonTitle, textSize: textSize, textColor: .white, fillColor: fillColor, strokeColor: strokeColor)
            newButton.position = CGPoint(x: size.width * 0.5 - (buttonSize.width + horizontalMargin) * 3 + buttonSize.width * CGFloat(index % 3) + horizontalMargin * CGFloat(index % 3), y: size.height * 0.5 - verticalMargin - buttonSize.height * 0.5 - buttonSize.height * CGFloat(index / 3) - verticalMargin * CGFloat(index / 3))
            cameraNode.addChild(newButton)
            
            if index == 1 {
                let cameraLabel = SKLabelNode(attributedText: attributedString("Camera Alignment", fontName: "Courier", textSize: textSize * 0.8))
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

            textSize = size.width * 0.03
            let smallButtonSize = CGSize(width: textSize, height: textSize)

            newButton = button(name: "cameraButton-\(index)", buttonSize: smallButtonSize, text: buttonTitle, textSize: textSize, textColor: .white, fillColor: fillColor, strokeColor: strokeColor)
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

            var touchedNodeName: String?

            if nodeName.hasPrefix("cameraButton-") {
                touchedNodeName = nodeName
            } else if nodeParentName.hasPrefix("cameraButton-") {
                touchedNodeName = nodeParentName
            }
            
            if touchedNodeName != nil {
                let fromIndex = nodeName.index(nodeName.startIndex, offsetBy: 13)
                let number = String(nodeName[fromIndex...])
                
                buttonTapped = true
                adjustCamera(buttonIndex: Int(number)!)
            }
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
    }
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
