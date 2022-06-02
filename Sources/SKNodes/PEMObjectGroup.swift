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
    private var drawOrder = DrawOrder.topDown
    
    internal var objects: Array<PEMObjectData> = []
    private var parentGroup: PEMGroup?
    
    weak var map : PEMTileMap!

    init?(attributes: Dictionary<String, String>, map: PEMTileMap, group: PEMGroup?) {
        super.init()

        self.map = map
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
            object.parseAttributes(defaultSize: tileSizeInPoints)
            
            guard object.visible else { continue }
            guard object.coordsInPoints != nil else { continue }

            var node : SKNode?
            
            // TO BE DELETED
            var sizeInPoints: CGSize!
            sizeInPoints = (object.sizeInPoints != nil) ? object.sizeInPoints : tileSizeInPoints
            // -----
            
            let position = objectPosition(coordsInPoints: object.coordsInPoints!)

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
                node = PEMObjectText(objectData: object)
            case .tile:
                var tileGid: UInt32!
                tileGid = (object.tileGid != nil) ? object.tileGid : 0

                let tileGidAttributes = tileAttributes(fromId: tileGid)
                
                if let tileSet = map.tileSetContaining(gid: tileGidAttributes.id) {
                    if let tile = tileSet.tileFor(id: tileGidAttributes.id, flippedHorizontally: tileGidAttributes.flippedHorizontally, flippedVertically: tileGidAttributes.flippedVertically, flippedDiagonally: tileGidAttributes.flippedDiagonally) {
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
                nodeCenter = CGPoint(x: objectNode.frame.midX, y: objectNode.frame.midY)
            }
            
            node?.position = position
                        
            if object.objectName != nil {
                if let label = objectLabel(text: object.objectName ?? "-", fontSize: tileSizeInPoints.height * 0.5, color:color) {
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
    
    private func objectLabel(text: String, fontSize: CGFloat, color: SKColor) -> SKNode? {
        if let texture = highResolutionLabelTexture(text: text, fontName: "Arial", fontSize: fontSize, fontColor: .white, shadowColor: .black, shadowOffset: CGSize(width: 2, height: 2), shadowBlurRadius: 5) {
            
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
    override var description: String {
        return "PEMObjectGroup: \(id), (name: \(name ?? "-"), parent: \(String(describing: parentGroup)), objects: \(objects.count))"
    }
    #endif
}
