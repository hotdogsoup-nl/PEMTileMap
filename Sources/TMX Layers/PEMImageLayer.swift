import Foundation
import SpriteKit

/// A TMX Image layer.
/// A layer consisting of a single image.
///
/// Documentation: [TMX Image layer](https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#imagelayer)
public class PEMImageLayer: SKSpriteNode, PEMTileMapPropertiesProtocol {
    public var parallaxFactorX = CGFloat(1)
    public var parallaxFactorY = CGFloat(1)

    public var properties: Dictionary<String, Any>?

    public private (set) var class_: String?
    public private (set) var id = UInt32(0)
    public private (set) var offSetInPoints = CGPoint.zero
    public private (set) var imageSizeInPoints = CGSize.zero
    public private (set) var opacity = CGFloat(1)
    public private (set) var tintColor: SKColor?
    public private (set) var visible = true
    public private (set) var repeatX = false
    public private (set) var repeatY = false
    
    private var parentGroup: PEMGroupLayer?
    private var textureImageSource: String?

    // MARK: - Init

    init(attributes: Dictionary<String, String>, group: PEMGroupLayer?) {
        super.init(texture: nil, color: .clear, size: .zero)
        
        parentGroup = group

        if let value = attributes[ElementAttributes.id.rawValue] {
            id = UInt32(value)!
        }

        name = attributes[ElementAttributes.name.rawValue]
        class_ = attributes[ElementAttributes.class_.rawValue]

        if let dx = attributes[ElementAttributes.offsetX.rawValue],
           let dy = attributes[ElementAttributes.offsetY.rawValue] {
            offSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }

        if let value = attributes[ElementAttributes.opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.visible.rawValue] {
            visible = value == "1"
        }
        
        if let value = attributes[ElementAttributes.tintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.parallaxX.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorX = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.parallaxY.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorY = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.repeatX.rawValue] {
            repeatX = value == "1"
        }

        if let value = attributes[ElementAttributes.repeatY.rawValue] {
            repeatY = value == "1"
        }
        
        applyParentGroupAttributes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal
    
    internal func render(mapSizeInPoints: CGSize, textureFilteringMode: SKTextureFilteringMode) {
        if textureImageSource == nil {
            return
        }

        alpha = opacity
        isHidden = !visible
                        
        if tintColor != nil {
            color = tintColor!
            colorBlendFactor = 1.0
        }
        
        if let path = bundlePathForResource(textureImageSource!) {
            size = imageSizeInPoints
              
            var atexture = SKTexture(imageNamed: path)
            atexture.filteringMode = textureFilteringMode
            
            if repeatX || repeatY {
                if repeatX {
                    let horCanvas = SKNode()
                    for index in 0...Int(mapSizeInPoints.width / size.width - 0.5) {
                        let tile = SKSpriteNode(texture: atexture, size: size)
                        tile.position = CGPoint(x: index * Int(size.width), y: 0)
                        horCanvas.addChild(tile)
                    }
                    
                    let tempview = SKView()
                    if let combinedTexture = tempview.texture(from: horCanvas) {
                        combinedTexture.filteringMode = textureFilteringMode
                        atexture = combinedTexture
                        size.width = horCanvas.calculateAccumulatedFrame().width
                    }
                }
            
                if repeatY {
                    let verCanvas = SKNode()
                    for index in 0...Int(mapSizeInPoints.height / size.height - 0.5) {
                        let tile = SKSpriteNode(texture: atexture, size: size)
                        tile.position = CGPoint(x: 0, y: index * Int(size.height))
                        verCanvas.addChild(tile)
                    }
                    
                    let tempview = SKView()
                    if let combinedTexture = tempview.texture(from: verCanvas) {
                        combinedTexture.filteringMode = textureFilteringMode
                        atexture = combinedTexture
                        size.height = verCanvas.calculateAccumulatedFrame().height
                    }
                }
            }
            
            texture = atexture
            position = CGPoint(x: size.width * 0.5 + offSetInPoints.x, y: mapSizeInPoints.height - size.height * 0.5 - offSetInPoints.y)
        } else {
            #if DEBUG
            print("PEMImageLayer: Image file not found: \(String(describing: textureImageSource))")
            #endif
        }
    }
    
    internal func setImage(attributes: Dictionary<String, String>) {
        guard let source = attributes[ElementAttributes.source.rawValue] else { return }
        guard let width = attributes[ElementAttributes.width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.height.rawValue] else { return }

        imageSizeInPoints = CGSize(width: Int(width)!, height: Int(height)!)
        textureImageSource = source
    }
    
    // MARK: - PEMTileMapPropertiesProtocol
    
    internal func addProperties(_ newProperties: [PEMProperty]) {
        properties = convertProperties(newProperties)
    }
    
    // MARK: - Private
    
    private func applyParentGroupAttributes() {
        if parentGroup == nil {
            return
        }

        if let value = parentGroup?.opacity {
            opacity *= CGFloat(value)
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
        return "PEMImageLayer: \(id), (name: \(name ?? "-"), class: \(class_ ?? "-"), zPosition: \(zPosition), parent: \(String(describing: parentGroup)))"
    }
    #endif
}
