import SpriteKit

internal enum DrawOrder: String {
    case index = "index"
    case topDown = "topdown"
}

class PEMObjectGroup: SKNode, PEMTileMapPropertiesProtocol {
    private (set) var properties: Dictionary<String, Any>?
    private (set) var opacity = CGFloat(1.0)
    private (set) var visible = true
    private (set) var offSetInPoints = CGPoint.zero
    private (set) var tintColor: SKColor?
    private (set) var color = SKColor.lightGray

    private var id = UInt32(0)
    private var groupName: String?
    private var drawOrder = DrawOrder.topDown
    
    internal var objects: Array<PEMObjectData> = []
    private var parentGroup: PEMGroup?
    
    weak var map : PEMTileMap!

    init?(attributes: Dictionary<String, String>, map: PEMTileMap, group: PEMGroup?) {
        super.init()

        self.map = map
        parentGroup = group
        groupName = attributes[ElementAttributes.name.rawValue]
        
        if let value = attributes[ElementAttributes.id.rawValue] {
            id = UInt32(value)!
        }
        
        if let value = attributes[ElementAttributes.opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.visible.rawValue] {
            visible = value == "1"
        }
                
        if let dx = attributes[ElementAttributes.offsetX.rawValue],
           let dy = attributes[ElementAttributes.offsetY.rawValue] {
            offSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }
        
        if let value = attributes[ElementAttributes.tintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.color.rawValue] {
            color = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.drawOrder.rawValue] {
            if let groupRenderOrder = DrawOrder(rawValue: value) {
                drawOrder = groupRenderOrder
            } else {
                #if DEBUG
                print("PEMObjectGroup: unsupported draw order: \(String(describing: value))")
                #endif
            }
        }
        
        applyParentGroupAttributes()
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
    
    // MARK: - Setup
        
    internal func addObjectData(attributes: Dictionary<String, String>) -> PEMObjectData? {
        if let objectData = PEMObjectData(attributes: attributes) {
            objects.append(objectData)
            return objectData
        }
        
        return nil
    }
    
    // MARK: - Internal
    
    internal func parseExternalTemplates(objectTemplates: Dictionary<String, PEMObjectData>) -> Dictionary<String, PEMObjectData>? {
        var result: Dictionary<String, PEMObjectData> = [:]
        
        for object in objects {
            if let externalSource = object.externalSource {
                if let templateObjectData = objectTemplates[externalSource] {
                    object.setObjectType(templateObjectData.objectType)
                    object.addAttributes(templateObjectData.attributes)
                } else {
                    if let url = bundleURLForResource(object.externalSource!) {
                        if let templateObjectData = PEMObjectData(attributes: nil) {
                            if let parser = PEMTmxParser(objectData: templateObjectData, fileURL: url) {
                                if (parser.parse()) {
                                    result[externalSource] = templateObjectData
                                    object.setObjectType(templateObjectData.objectType)
                                    object.addAttributes(templateObjectData.attributes)
                                } else {
                                    #if DEBUG
                                    print("PEMObjectData: Error parsing external template: ", parser.parserError as Any)
                                    #endif
                                }
                            }
                        }
                    } else {
                        #if DEBUG
                        print("PEMObjectData: External template file not found: \(object.externalSource ?? "-")")
                        #endif
                    }
                }
            }
        }
        
        return (result.count > 0) ? result : nil
    }

    internal func render(textureFilteringMode: SKTextureFilteringMode) {
        let tileSizeInPoints = map.tileSizeInPoints

        alpha = opacity
        position = CGPoint(x: offSetInPoints.x + tileSizeInPoints.width * 0.5, y: -offSetInPoints.y + tileSizeInPoints.height * 0.5)
                
        for object in objects {
            object.parseAttributes()
            
            if !object.visible {
                continue
            }

            var node : SKNode?
            var sizeInPoints: CGSize!
            sizeInPoints = (object.sizeInPoints != nil) ? object.sizeInPoints : tileSizeInPoints
            
            var objectCoordsInPoints = CGPoint.zero
            
            if let coords = object.coordsInPoints {
                objectCoordsInPoints = coords
            } else {
                objectCoordsInPoints = .zero
            }
            
            var position = objectPosition(coordsInPoints: objectCoordsInPoints)

            switch object.objectType {
            case .ellipse:
                node = SKShapeNode(ellipseIn: CGRect(x: 0, y: -sizeInPoints.height, width: sizeInPoints.width, height: sizeInPoints.height))
            case .point:
                sizeInPoints = CGSize(width: tileSizeInPoints.width * 0.25, height: tileSizeInPoints.height * 0.25)
                node = SKShapeNode(ellipseIn: CGRect(x: 0, y: -sizeInPoints.height, width: sizeInPoints.width, height: sizeInPoints.height))
                position = CGPoint(x: position.x - sizeInPoints.width * 0.5, y: position.y + sizeInPoints.height * 0.5)
            case .polygon, .polyline:
                if var points = object.polygonPoints {
                    node = SKShapeNode(points: &points, count: points.count)
                    sizeInPoints = node!.calculateAccumulatedFrame().size
                }
            case .rectangle:
                node = SKShapeNode(rect: CGRect(x: 0, y: -sizeInPoints.height, width: sizeInPoints.width, height: sizeInPoints.height))
            case .text:
                var text: String!
                text = (object.text != nil) ? object.text : ""

                var fontFamily: String!
                fontFamily = (object.fontFamily != nil) ? object.fontFamily : "Arial"

                var pixelSize: CGFloat!
                pixelSize = (object.pixelSize != nil) ? object.pixelSize : 16

                var textColor: SKColor!
                textColor = (object.textColor != nil) ? object.textColor : .white

                var bold: Bool!
                bold = (object.bold != nil) ? object.bold : false

                var italic: Bool!
                italic = (object.italic != nil) ? object.italic : false

                var underline: Bool!
                underline = (object.underline != nil) ? object.underline : false

                var strikeOut: Bool!
                strikeOut = (object.strikeOut != nil) ? object.strikeOut : false

                var kerning: Bool!
                kerning = (object.kerning != nil) ? object.kerning : false

                var wrap: Bool!
                wrap = (object.wrap != nil) ? object.wrap : false

                var hAlign: TextHorizontalAlignment!
                hAlign = (object.hAlign != nil) ? object.hAlign : .left
                
                var vAlign: TextVerticalAlignment!
                vAlign = (object.vAlign != nil) ? object.vAlign : .top

                let textLabel = highResolutionLabel(text: text,
                                                    fontName: fontFamily,
                                                    fontSize: pixelSize,
                                                    fontColor: textColor,
                                                    bold: bold,
                                                    italic: italic,
                                                    underline: underline,
                                                    strikeOut: strikeOut,
                                                    kerning: kerning,
                                                    wordWrapWidth: (wrap) ? sizeInPoints.width : 0,
                                                    hAlign: hAlign,
                                                    vAlign: vAlign)
                textLabel.anchorPoint = CGPoint(x: 0.0, y: 1.0)
                node = textLabel
            case .tile:
                var tileGid: UInt32!
                tileGid = (object.tileGid != nil) ? object.tileGid : 0

                let tileGidAttributes = tileAttributes(fromId: tileGid)
                
                if let tileSet = map.tileSetContaining(gid: tileGidAttributes.id) {
                    if let tile = tileSet.tileFor(gid: tileGidAttributes.id) {
                        tile.applyTileFlipping(horizontally: tileGidAttributes.flippedHorizontally, vertically: tileGidAttributes.flippedVertically, diagonally: tileGidAttributes.flippedDiagonally)
                        tile.texture?.filteringMode = textureFilteringMode
                        
                        if tintColor != nil {
                            tile.color = tintColor!
                            tile.colorBlendFactor = 1.0
                        }
                        
                        tile.size = sizeInPoints
                        
                        let sizeDeviation = CGSize(width: tile.size.width - tileSizeInPoints.width, height: tile.size.height - tileSizeInPoints.height)
                        
                        tile.position = CGPoint(x: tileSizeInPoints.width * 0.5 + sizeDeviation.width * 0.5, y: tileSizeInPoints.height * 0.5 + sizeDeviation.height * 0.5)
                        
                        node = SKNode()
                        node?.addChild(tile)
                        
                        if tile.animation != nil {
                            var frameTiles: Dictionary<UInt32, SKTexture> = [:]
                            
                            for animationFrame in tile.animation!.frames {
                                if let frameTile = tileSet.tileFor(id: animationFrame.tileId) {
                                    frameTile.texture?.filteringMode = textureFilteringMode
                                    frameTiles[animationFrame.tileId] = frameTile.texture
                                }
                            }
                            
                            tile.startAnimation(frameTiles: frameTiles)
                        }
                    }
                }
            }
            
            if node == nil {
                continue
            }
            
            var nodeCenter = CGPoint.zero
            
            if let objectNode = node as? SKShapeNode {
                objectNode.lineWidth = 0.25
                objectNode.strokeColor = color
                if object.objectType != .polyline {
                    objectNode.fillColor = color.withAlphaComponent(0.5)
                }
                objectNode.isAntialiased = true
                
                nodeCenter = CGPoint(x: objectNode.frame.midX, y: objectNode.frame.midY)
            }
            
            node?.position = position
            
            var rotation: CGFloat!
            rotation = (object.rotation != nil) ? object.rotation : 0
            node?.zRotation = rotation.radians()
            
            if object.objectName != nil {
                let label = objectLabel(text: object.objectName ?? "-", fontSize: tileSizeInPoints.height * 0.25, color:color)
                let labelSize = label.calculateAccumulatedFrame().size
                
                if object.objectType == .tile {
                    label.position = CGPoint(x: sizeInPoints.width * 0.5, y: sizeInPoints.height +  labelSize.height * 0.7)
                } else if object.objectType == .polygon || object.objectType == .polyline {
                    label.position = CGPoint(x: nodeCenter.x, y: nodeCenter.y + sizeInPoints.height * 0.5 + labelSize.height * 0.7)
                } else {
                    label.position = CGPoint(x: sizeInPoints.width * 0.5, y: labelSize.height * 0.7)
                }
                
                label.zRotation = -node!.zRotation
                label.zPosition = node!.zPosition + 1
                node?.addChild(label)
            }
            
            addChild(node!)

        }
    }
        
    // MARK: - PEMTileMapPropertiesProtocol
    
    internal func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func objectPosition(coordsInPoints: CGPoint, sizeDeviation: CGSize = .zero) -> CGPoint {
        return map.position(coordsInPoints: coordsInPoints).with(tileSizeDeviation: sizeDeviation)
    }
    
    private func objectLabel(text: String, fontSize: CGFloat, color: SKColor) -> SKNode {
        let spriteLabel = highResolutionLabel(text: text, fontName: "Arial", fontSize: fontSize, fontColor: .white, shadowColor: .black, shadowOffset: CGSize(width: 2, height: 2), shadowBlurRadius: 5)
        var size = spriteLabel.calculateAccumulatedFrame().size
        size = CGSize(width: size.width * 1.1, height: size.height * 1.5)
        let shape = SKShapeNode(rectOf: size, cornerRadius: size.height * 0.2)
        shape.fillColor = color
        shape.strokeColor = color
        
        shape.addChild(spriteLabel)
        return shape
    }
    
    private func applyParentGroupAttributes() {
        guard parentGroup != nil else { return }
        
        if let value = parentGroup?.opacity {
            opacity *= CGFloat(value)
        }
        
        if let value = parentGroup?.visible {
            visible = visible && value
        }
        
        if let value = parentGroup?.offSetInPoints {
            offSetInPoints = CGPoint(x: offSetInPoints.x + value.x, y: offSetInPoints.y + value.y)
        }
        
        if let value = parentGroup?.tintColor {
            if tintColor != nil {
                tintColor = tintColor?.multiplyColor(value)
            } else {
                tintColor = value
            }
        }
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMObjectGroup: \(id), (name: \(groupName ?? "-"), parent: \(String(describing: parentGroup)), objects: \(objects.count))"
    }
    #endif
}
