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
    private var tileSizeInPoints = CGSize.zero
    
    internal var objects: [PEMObjectData] = []
    private var parentGroup: PEMGroup?
    
    weak var map : PEMTileMap?

    init?(attributes: Dictionary<String, String>, map: PEMTileMap, group: PEMGroup?) {
        super.init()

        self.map = map
        parentGroup = group
        groupName = attributes[ElementAttributes.name.rawValue]
        tileSizeInPoints = map.tileSizeInPoints
        
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
        
    func addObjectData(attributes: Dictionary<String, String>) -> PEMObjectData? {
        if let objectData = PEMObjectData(attributes: attributes) {
            objects.append(objectData)
            return objectData
        }
        
        return nil
    }
    
    // MARK: - Public
    
    func parseExternalTemplates() {
        for object in objects {
            object.parseExternalTemplate()
        }
    }

    func render(tileSizeInPoints: CGSize, mapSizeInPoints: CGSize, textureFilteringMode: SKTextureFilteringMode) {
        
        alpha = opacity
        position = CGPoint(x: offSetInPoints.x + tileSizeInPoints.width * 0.5, y: -offSetInPoints.y + tileSizeInPoints.height * 0.5)
                
        for object in objects {
            var node : SKNode?
            var sizeInPoints: CGSize!

            if object.objectType == .unknown {
                sizeInPoints = tileSizeInPoints
            } else {
                sizeInPoints = object.sizeInPoints != nil ? object.sizeInPoints : tileSizeInPoints
            }
            
            if object.objectType == .unknown {
                sizeInPoints = tileSizeInPoints
            }
            
            var objectCoordsInPoints: CGPoint!
            objectCoordsInPoints = object.coordsInPoints != nil ? object.coordsInPoints : .zero

            var position = CGPoint(x: objectCoordsInPoints.x - tileSizeInPoints.width * 0.5, y: mapSizeInPoints.height - objectCoordsInPoints.y - tileSizeInPoints.height * 0.5)

            switch object.objectType {
            case .ellipse:
                node = SKShapeNode(ellipseIn: CGRect(x: 0, y: -sizeInPoints.height, width: sizeInPoints.width, height: sizeInPoints.height))
            case .point:
                sizeInPoints = CGSize(width: tileSizeInPoints.width * 0.25, height: tileSizeInPoints.height * 0.25)
                node = SKShapeNode(ellipseIn: CGRect(x: 0, y: -sizeInPoints.height, width: sizeInPoints.width, height: sizeInPoints.height))
                position = CGPoint(x: position.x - sizeInPoints.width * 0.5, y: position.y + sizeInPoints.height * 0.5)
            case .polygon, .polyline:
                var points = object.polygonPoints
                node = SKShapeNode(points: &points, count: points.count)
                sizeInPoints = node!.calculateAccumulatedFrame().size
            case .rectangle, .unknown:
                node = SKShapeNode(rect: CGRect(x: 0, y: -sizeInPoints.height, width: sizeInPoints.width, height: sizeInPoints.height))
            case .text:
                let text = highResolutionLabel(text: object.text,
                                           fontName: object.fontFamily,
                                           fontSize: object.pixelSize,
                                           fontColor: object.textColor,
                                           bold: object.bold,
                                           italic: object.italic,
                                           underline: object.underline,
                                           strikeOut: object.strikeOut,
                                           kerning: object.kerning,
                                           wordWrapWidth: object.wrap ? sizeInPoints.width : 0,
                                           hAlign: object.hAlign,
                                           vAlign: object.vAlign)
                text.anchorPoint = CGPoint(x: 0.0, y: 1.0)
                node = text
            case .tile:
                var tileGid: UInt32!
                tileGid = object.tileGid != nil ? object.tileGid : 0

                let tileGidAttributes = tileAttributes(fromId: tileGid)
                
                if let tileSet = map?.tileSetFor(gid: tileGidAttributes.id) {
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
            rotation = object.rotation != nil ? object.rotation : 0
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
    
    func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
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
