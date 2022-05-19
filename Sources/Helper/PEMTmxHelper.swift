import SpriteKit

// MARK: - Sprites

func highResolutionLabel(text: String,
                         fontName: String,
                         fontSize: CGFloat,
                         fontColor: SKColor,
                         bold: Bool = false,
                         italic: Bool = false,
                         underline: Bool = false,
                         strikeOut: Bool = false,
                         kerning: Bool = false,
                         wordWrapWidth: CGFloat = 0,
                         hAlign: TextHorizontalAlignment = .left,
                         vAlign: TextVerticalAlignment = .center) -> SKSpriteNode {
    
    let scaleFactor = 5.0
    
    var font = Font(name: fontName, size: fontSize * scaleFactor)
    if font == nil {
        font = Font.systemFont(ofSize: fontSize * scaleFactor)
    }
    
    if bold {
        #if os(macOS)
        font = font?.addTraits(traits: .bold)
        #else
        font = font?.addTraits(traits: .traitBold)
        #endif
    }
    
    if italic {
        #if os(macOS)
        font = font?.addTraits(traits: .italic)
        #else
        font = font?.addTraits(traits: .traitItalic)
        #endif
    }

    var alignmentHorizontal: NSTextAlignment
    switch hAlign {
    case .center:
        alignmentHorizontal = .center
    case .justify:
        alignmentHorizontal = .justified
    case .left:
        alignmentHorizontal = .left
    case .right:
        alignmentHorizontal = .right
    }
    
    var alignmentVertical: SKLabelVerticalAlignmentMode
    switch vAlign {
    case .bottom:
        alignmentVertical = .bottom
    case .center:
        alignmentVertical = .center
    case .top:
        alignmentVertical = .top
    }
    
    let attributedString = attributedStringWith(string: text,
                                                font: font!,
                                                fontColor: fontColor,
                                                alignment: alignmentHorizontal,
                                                underline: underline,
                                                strikeThrough: strikeOut,
                                                kerning: kerning ? 1 : 0)
    
    let label = SKLabelNode(attributedText: attributedString)
    if wordWrapWidth > 0 {
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = wordWrapWidth * scaleFactor
    } else {
        label.numberOfLines = 1
    }
    label.verticalAlignmentMode = alignmentVertical

    let spriteText = SKSpriteNode(texture: SKView().texture(from: label))
    spriteText.xScale = 1 / scaleFactor
    spriteText.yScale = 1 / scaleFactor
    return spriteText
}

// MARK: - Properties

func convertProperties(_ newProperties: [PEMTmxProperty]) -> Dictionary<String, Any>? {
    var properties: Dictionary<String, Any>? = [:]
    for property in newProperties {
        if let value = property.value {

            switch property.type {
            
            case .bool:
                properties?[property.name] = Bool(value)
            case .color:
                properties?[property.name] = SKColor.init(hexString: value)
            case .int:
                properties?[property.name] = Int(value)!
            case .file:
                properties?[property.name] = value
            case .float:
                let valueString : NSString = value as NSString
                properties?[property.name] = CGFloat(valueString.doubleValue)
            case .object:
                properties?[property.name] = UInt32(value)!
            case .string:
                properties?[property.name] = value
            }
        }
    }
    
    if properties?.count == 0 {
        properties = nil
    }
    
    return properties
}

// MARK: - Flipping attributes

func tileAttributes(fromId id: UInt32) -> (id: UInt32, flippedHorizontally: Bool, flippedVertically: Bool, flippedDiagonally: Bool) {
    let flippedDiagonalFlag: UInt32   = 0x20000000
    let flippedVerticalFlag: UInt32   = 0x40000000
    let flippedHorizontalFlag: UInt32 = 0x80000000

    let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
    let flippedMask = ~(flippedAll)

    let flippedHorizontally: Bool = (id & flippedHorizontalFlag) != 0
    let flippedVertically: Bool = (id & flippedVerticalFlag) != 0
    let flippedDiagonally: Bool = (id & flippedDiagonalFlag) != 0

    let id = id & flippedMask
    return (id, flippedHorizontally, flippedVertically, flippedDiagonally)
}

// MARK: - Files

func bundlePathForResource(_ resource: String) -> String? {
    var fileName = resource
    var fileExtension: String?

    if resource.range(of: ".") != nil {
        fileName = (resource as NSString).deletingPathExtension
        fileExtension = (resource as NSString).pathExtension
    }

    return Bundle.main.path(forResource: fileName, ofType: fileExtension)
}

func bundleURLForResource(_ resource: String) -> URL? {
    var fileName = resource
    var fileExtension: String?

    if resource.range(of: ".") != nil {
        fileName = (resource as NSString).deletingPathExtension
        fileExtension = (resource as NSString).pathExtension
    }

    return Bundle.main.url(forResource: fileName, withExtension: fileExtension)
}
