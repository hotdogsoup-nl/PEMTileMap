import SpriteKit

internal enum DrawOrder: String {
    case index = "index"
    case topDown = "topdown"
}

public class PEMObjectGroup: SKNode, PEMTileMapPropertiesProtocol {
    private (set) var properties: Dictionary<String, Any>?
    private (set) var opacity = CGFloat(1.0)
    private (set) var visible = true
    private (set) var offSetInPoints = CGPoint.zero
    private (set) var tintColor: SKColor?
    private (set) var color = SKColor.lightGray

    private var id = UInt32(0)
    private var drawOrder = DrawOrder.topDown
    
    internal var objects: Array<PEMObjectData> = []
    private var parentGroup: PEMGroup?
        
    init?(attributes: Dictionary<String, String>, group: PEMGroup?) {
        super.init()

        parentGroup = group
        name = attributes[ElementAttributes.name.rawValue]
        
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

    internal func render(map: PEMTileMap, textureFilteringMode: SKTextureFilteringMode) {
        let tileSizeInPoints = map.tileSizeInPoints()
        let halfTileSizeInPoints = map.halfTileSizeInPoints()
        let showObjectLabels = map.showObjectLabels

        alpha = opacity
        isHidden = !visible
        position = CGPoint(x: offSetInPoints.x, y: -offSetInPoints.y)
                
        for object in objects {
            object.parseAttributes(defaultSize: tileSizeInPoints)
            
            guard object.coordsInPoints != nil else { continue }

            var node : SKNode?

            switch object.objectType {
            case .ellipse:
                node = PEMObjectEllipse(objectData: object, color: color)
            case .rectangle:
                node = PEMObjectRectangle(objectData: object, color: color)
            case .point:
                node = PEMObjectPoint(objectData: object, color: color)
            case .polygon, .polyline:
                node = PEMObjectPoly(objectData: object, color: color, isPolygon: (object.objectType == .polygon))
            case .text:
                node = PEMObjectText(map: map, objectData: object)
            case .tile:
                var tileGid: UInt32!
                tileGid = (object.tileGid != nil) ? object.tileGid : 0
                
                if let tileSet = map.tileSetContaining(gid: tileGid) {
                    if let tile = tileSet.tileFor(gid: tileGid) {
                        let sizeInPoints = (object.sizeInPoints != nil) ? object.sizeInPoints : tileSizeInPoints

                        tile.texture?.filteringMode = textureFilteringMode
                        tile.size = sizeInPoints!

                        if tintColor != nil {
                            tile.color = tintColor!
                            tile.colorBlendFactor = 1.0
                        }
                                                
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
                        
                        node = SKNode() // we add the tile to an extra node so we can rotate it around the lop left corner without changing the anchorpoint
                        var rotation: CGFloat!
                        rotation = (object.rotation != nil) ? object.rotation : 0
                        node?.zRotation = rotation.radians()
                        
                        let sizeDeviation = CGSize(width: tile.size.width - tileSizeInPoints.width, height: tile.size.height - tileSizeInPoints.height)
                        tile.position = CGPoint(x: tileSizeInPoints.width * 0.5 + sizeDeviation.width * 0.5, y: tileSizeInPoints.height * 0.5 + sizeDeviation.height * 0.5).with(tileSizeDeviation: sizeDeviation)
                        node?.addChild(tile)
                    }
                }
            }
            
            guard node != nil else { continue }
           
            node?.name = object.objectName
            node?.position = map.position(coordsInPoints: object.coordsInPoints!).add(CGPoint(x: halfTileSizeInPoints.width, y: halfTileSizeInPoints.height))
            node?.isHidden = !object.visible
                        
            addChild(node!)
            
            addObjectLabel(node!, map: map, fontSize: tileSizeInPoints.height * 0.25, visible: showObjectLabels)
        }
    }
    
    internal func updateObjectLabels(visible: Bool) {
        for child in children  {
            if child.name == "PEMObjectLabel" {
                child.isHidden = !visible
            }
        }
    }
            
    // MARK: - PEMTileMapPropertiesProtocol
    
    internal func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func addObjectLabel(_ node: SKNode, map: PEMTileMap, fontSize: CGFloat, visible: Bool) {
        guard node.name != nil else { return }
        
        let nodeRect = node.calculateAccumulatedFrame()
        let nodeCenter = CGPoint(x: nodeRect.midX, y: nodeRect.midY)
        
        if let label = objectLabel(map: map, text: node.name!, fontSize: fontSize, color:color) {
            let labelSize = label.calculateAccumulatedFrame().size
            label.position = CGPoint(x: nodeCenter.x, y: nodeCenter.y + nodeRect.size.height * 0.5 + labelSize.height * 0.6)
            label.zPosition = node.zPosition + 1
            label.name = "PEMObjectLabel"
            label.isHidden = !visible
            addChild(label)
        }
    }
        
    private func objectLabel(map: PEMTileMap, text: String, fontSize: CGFloat, color: SKColor) -> SKNode? {
        let scaleFactor = 15.0 // scale up to increase text render quality
        let label = SKLabelNode(text: text, fontName: "Arial", fontSize: fontSize * scaleFactor, fontColor: .white, shadowColor: .black, shadowOffset: CGSize(width: 2, height: 2), shadowBlurRadius: 5)
        
        if let skView = map.skView,
            let texture = skView.texture(from: label) {
            let scale = fontSize / texture.size().height
            var size = texture.size().scaled(scale)
            let spriteLabel = SKSpriteNode(texture: texture, size: size)
            
            size = CGSize(width: size.width * 1.1, height: size.height * 1.5)
            let shape = SKShapeNode(rectOf: size, cornerRadius: size.height * 0.2)
            shape.fillColor = color
            shape.strokeColor = color
            
            shape.addChild(spriteLabel)
            return shape
        }
        
        return nil
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
    public override var description: String {
        return "PEMObjectGroup: \(id), (name: \(name ?? "-"), parent: \(String(describing: parentGroup)), objects: \(objects.count))"
    }
    #endif
}
