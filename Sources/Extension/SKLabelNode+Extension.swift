import SpriteKit

internal extension SKLabelNode {
    convenience init(text: String,
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
                     vAlign: TextVerticalAlignment = .center,
                     shadowColor: SKColor = .clear,
                     shadowOffset: CGSize = .zero,
                     shadowBlurRadius: CGFloat = 0) {
        var font = Font(name: fontName, size: fontSize)
        if font == nil {
            font = Font.systemFont(ofSize: fontSize)
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
        
        let attributedString = NSAttributedString(string: text,
                                                  font: font!,
                                                  fontColor: fontColor,
                                                  alignment: alignmentHorizontal,
                                                  underline: underline,
                                                  strikeThrough: strikeOut,
                                                  kerning: kerning ? 1 : 0,
                                                  shadowColor: shadowColor,
                                                  shadowOffset: shadowOffset,
                                                  shadowBlurRadius: shadowBlurRadius)
        
        self.init(attributedText: attributedString)
        
        if wordWrapWidth > 0 {
            numberOfLines = 0
            preferredMaxLayoutWidth = wordWrapWidth
        } else {
            numberOfLines = 1
        }
        
        verticalAlignmentMode = alignmentVertical
    }
}
