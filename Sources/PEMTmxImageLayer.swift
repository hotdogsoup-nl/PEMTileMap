import Foundation
import SpriteKit

class PEMTmxImageLayer : SKSpriteNode, PEMTmxPropertiesProtocol {
    private (set) var visible = true
    private (set) var properties : Dictionary<String, Any>?

    private var layerId : String?
    private var layerName : String?
    
    private var textureImageSource : String?
    private var offSetInPoints = CGPoint.zero
    private var imageSizeInPoints = CGSize.zero
    private var opacity = CGFloat(1)
    private var tintColor : SKColor?
    private var parallaxFactorX = CGFloat(1)
    private var parallaxFactorY = CGFloat(1)
    private var repeatX = false
    private var repeatY = false

    // MARK: - Init

    init(attributes: Dictionary<String, String>) {
        super.init(texture: nil, color: .clear, size: .zero)

        if let value = attributes[ElementAttributes.Id.rawValue] {
            layerId = value
        }

        if let value = attributes[ElementAttributes.Name.rawValue] {
            layerName = value
        }
        
        if let dx = attributes[ElementAttributes.OffsetX.rawValue],
           let dy = attributes[ElementAttributes.OffsetY.rawValue] {
            offSetInPoints = CGPoint(x: Int(dx)!, y: Int(dy)!)
        }

        if let value = attributes[ElementAttributes.Opacity.rawValue] {
            let valueString : NSString = value as NSString
            opacity = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.Visible.rawValue] {
            visible = value == "1"
        }
        
        if let value = attributes[ElementAttributes.TintColor.rawValue] {
            tintColor = SKColor.init(hexString: value)
        }
        
        if let value = attributes[ElementAttributes.ParallaxX.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorX = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.ParallaxY.rawValue] {
            let valueString : NSString = value as NSString
            parallaxFactorY = CGFloat(valueString.doubleValue)
        }
        
        if let value = attributes[ElementAttributes.RepeatX.rawValue] {
            repeatX = value == "1"
        }

        if let value = attributes[ElementAttributes.RepeatY.rawValue] {
            repeatY = value == "1"
        }
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
    
    // MARK: - Public
    
    func render(mapSizeInPoints: CGSize, textureFilteringMode: SKTextureFilteringMode) {
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
    
    func setImage(attributes: Dictionary<String, String>) {
        guard let source = attributes[ElementAttributes.Source.rawValue] else { return }
        guard let width = attributes[ElementAttributes.Width.rawValue] else { return }
        guard let height = attributes[ElementAttributes.Height.rawValue] else { return }

        imageSizeInPoints = CGSize(width: Int(width)!, height: Int(height)!)
        textureImageSource = source
    }
    
    // MARK: - PEMTmxPropertiesProtocol
    
    func addProperties(_ newProperties: [PEMTmxProperty]) {
        properties = convertProperties(newProperties)
        print(properties)
    }
    
    // MARK: - Debug
    
    #if DEBUG
    override var description: String {
        return "PEMTmxImageLayer: \(layerId ?? "-"), (name: \(layerName ?? "-"), zPosition: \(zPosition))"
    }
    #endif
}
