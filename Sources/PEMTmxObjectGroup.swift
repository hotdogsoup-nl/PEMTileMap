import SpriteKit

internal enum DrawOrder: String {
    case index = "index"
    case topDown = "topdown"
}

class PEMTmxObjectGroup: SKNode, PEMTmxPropertiesProtocol {
    private (set) var properties: Dictionary<String, Any>?
    private (set) var opacity = CGFloat(1.0)
    private (set) var visible = true
    private (set) var offSetInPoints = CGPoint.zero
    private (set) var tintColor: SKColor?
    private (set) var color = SKColor.clear

    private var id = UInt32(0)
    private var groupName: String?
    private var drawOrder = DrawOrder.topDown
    
    internal var objects: [PEMTmxObjectData] = []

    private var parentGroup: PEMTmxGroup?

    init?(attributes: Dictionary<String, String>, group: PEMTmxGroup?) {
        guard let groupId = attributes[ElementAttributes.id.rawValue] else { return nil }
        super.init()

        id = UInt32(groupId)!
        parentGroup = group

        groupName = attributes[ElementAttributes.name.rawValue]
        
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
                print("PEMTmxObjectGroup: unsupported draw order: \(String(describing: value))")
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
        
    func addObjectData(attributes: Dictionary<String, String>) -> PEMTmxObjectData? {
        if let objectData = PEMTmxObjectData(attributes: attributes) {
            objects.append(objectData)
            return objectData
        }
        
        return nil
    }
    
    // MARK: - Public

    func render(tileSizeInPoints: CGSize, mapSizeInPoints: CGSize, textureFilteringMode: SKTextureFilteringMode) {
        alpha = opacity
        
        
        
        
        
        position = CGPoint(x: offSetInPoints.x + tileSizeInPoints.width * 0.5, y: -offSetInPoints.y + tileSizeInPoints.height * 0.5)
                
        for object in objects {
            var node : SKNode?
            
            print(object)
            
            
            var objectSize = object.sizeInPoints
            if objectSize == .zero {
                if object.objectType == .point {
                    objectSize = CGSize(width: tileSizeInPoints.width * 0.25, height: tileSizeInPoints.height * 0.25)
                } else {
                    objectSize = tileSizeInPoints
                }
            }
            

            switch object.objectType {
            case .ellipse:
                node = SKShapeNode(ellipseIn: CGRect(x: 0, y: -objectSize.height, width: objectSize.width, height: objectSize.height))
            case .point:
                node = SKShapeNode(ellipseIn: CGRect(x: 0, y: -objectSize.height, width: objectSize.width, height: objectSize.height))
            case .polygon:
                break
            case .polyline:
                break
            case .rectangle:
                node = SKShapeNode(rect: CGRect(x: 0, y: -objectSize.height, width: objectSize.width, height: objectSize.height))
            case .text:
                node = highResolutionLabel(text: object.text,
                                           fontName: object.fontFamily,
                                           fontSize: object.pixelSize,
                                           fontColor: object.textColor,
                                           bold: object.bold,
                                           italic: object.italic,
                                           underline: object.underline,
                                           strikeOut: object.strikeOut,
                                           kerning: object.kerning,
                                           wordWrapWidth: object.wrap ? objectSize.width : 0,
                                           hAlign: object.hAlign,
                                           vAlign: object.vAlign)
            case .tile:
                break
            case .unknown:
                break
            }
            
            if node == nil {
                continue
            }
            
            if let objectNode = node as? SKShapeNode {
                objectNode.lineWidth = 0.25
                objectNode.strokeColor = color
                objectNode.fillColor = color.withAlphaComponent(0.5)
                objectNode.isAntialiased = true
            }
            
            if let objectNode = node as? SKSpriteNode {
                if tintColor != nil {
                    objectNode.color = tintColor!
                    objectNode.colorBlendFactor = 1.0
                }
            }
            
            var position = CGPoint(x: object.coordsInPoints.x - tileSizeInPoints.width * 0.5, y: mapSizeInPoints.height - object.coordsInPoints.y - tileSizeInPoints.height * 0.5)
            
            if object.objectType == .point {
                position = CGPoint(x: position.x - objectSize.width * 0.5, y: position.y + objectSize.height * 0.5)
            }

            node?.position = position
            node?.zRotation = object.rotation.radians()
            addChild(node!)
            
            let label = objectLabel(text: object.objectName ?? "-", fontSize: tileSizeInPoints.height * 0.25, color:color)
            label.position = CGPoint(x: objectSize.width * 0.5, y: label.calculateAccumulatedFrame().size.height * 0.7)
            label.zRotation = -node!.zRotation
            node?.addChild(label)
        }
    }
    
    // MARK: - PEMTmxPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMTmxProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func objectLabel(text: String, fontSize: CGFloat, color: SKColor) -> SKNode {
        let spriteLabel = highResolutionLabel(text: text, fontName: "Arial", fontSize: fontSize, fontColor: .white)
        var size = spriteLabel.calculateAccumulatedFrame().size
        size = CGSize(width: size.width * 1.1, height: size.height * 1.5)
        let shape = SKShapeNode(rectOf: size, cornerRadius: size.height * 0.2)
        shape.fillColor = color
        shape.strokeColor = color
        
        shape.addChild(spriteLabel)
        return shape
    }
    
    private func applyParentGroupAttributes() {
        if parentGroup == nil {
            return
        }
        
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
        return "PEMTmxObjectGroup: \(id), (name: \(groupName ?? "-"), parent: \(String(describing: parentGroup)), objects: \(objects.count))"
    }
    #endif
}
