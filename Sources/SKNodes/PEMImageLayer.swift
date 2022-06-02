import Foundation
import SpriteKit

class PEMImageLayer: SKSpriteNode, PEMTileMapPropertiesProtocol {
    private (set) var visible = true
    private (set) var properties: Dictionary<String, Any>?

    private var id = UInt32(0)
    private var textureImageSource: String?
    private var offSetInPoints = CGPoint.zero
    private var imageSizeInPoints = CGSize.zero
    private var opacity = CGFloat(1)
    private var tintColor: SKColor?
    private var parallaxFactorX = CGFloat(1)
    private var parallaxFactorY = CGFloat(1)
    private var repeatX = false
    private var repeatY = false
    
    private var parentGroup: PEMGroup?

    // MARK: - Init

    init(attributes: Dictionary<String, String>, group: PEMGroup?) {
        super.init(texture: nil, color: .clear, size: .zero)
        
        parentGroup = group

        if let value = attributes[ElementAttributes.id.rawValue] {
            id = UInt32(value)!
        }

        name = attributes[ElementAttributes.name.rawValue]
        
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
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(type(of: self))")
        #endif
        #endif
    }
    
    // MARK: - Internal
    
    internal func render(mapSizeInPoints: CGSize, textureFilteringMode: SKTextureFilteringMode) {
        if textureImageSource == nil {
            return
        }

        alpha = opacity
                        
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
    override var description: String {
        return "PEMImageLayer: \(id), (name: \(name ?? "-"), zPosition: \(zPosition), parent: \(String(describing: parentGroup)))"
    }
    #endif
}
