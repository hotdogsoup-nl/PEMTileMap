#if os(macOS)

import AppKit

typealias Font = NSFont
typealias FontDescriptor = NSFontDescriptor
typealias Color = NSColor

#else

import UIKit

typealias Font = UIFont
typealias FontDescriptor = UIFontDescriptor
typealias Color = UIColor

#endif

extension Font {
    func addTraits(traits:FontDescriptor.SymbolicTraits) -> Font? {
        let existingTraitsWithNewTrait = FontDescriptor.SymbolicTraits(rawValue: fontDescriptor.symbolicTraits.rawValue | traits.rawValue)
        
        #if os(macOS)
        let descriptor = fontDescriptor.withSymbolicTraits(existingTraitsWithNewTrait)
        return Font(descriptor: descriptor, size: 0)
        #else
        if let descriptor = fontDescriptor.withSymbolicTraits(existingTraitsWithNewTrait) {
            return Font(descriptor: descriptor, size: 0)
        }
        return nil
        #endif        
    }
}

func attributedStringWith(string: String,
                          font: Font,
                          fontColor: Color = .white,
                          alignment: NSTextAlignment = .left,
                          underline: Bool = false,
                          strikeThrough: Bool = false,
                          lineHeight: CGFloat = 0,
                          kerning: Float = 0,
                          strokeColor: Color = .clear,
                          strokeWidth: CGFloat = 0,
                          shadowColor: Color = .clear,
                          shadowOffset: CGSize = .zero,
                          shadowBlurRadius: CGFloat = 0) -> NSAttributedString? {
    
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    style.minimumLineHeight = lineHeight
    style.maximumLineHeight = lineHeight
    
    let string = NSMutableAttributedString(string: string)
    string.addAttributes([
        NSAttributedString.Key.font: font,
        NSAttributedString.Key.strikethroughStyle : strikeThrough ? 1 : 0,
        NSAttributedString.Key.underlineStyle: underline ? 1 : 0,
        NSAttributedString.Key.foregroundColor: fontColor,
        NSAttributedString.Key.paragraphStyle: style,
        NSAttributedString.Key.kern: kerning,
        NSAttributedString.Key.strokeColor: strokeColor,
        NSAttributedString.Key.strokeWidth: strokeWidth,
    ], range: NSMakeRange(0, string.length))
    
    if shadowColor != .clear {
        let shadow = NSShadow()
        shadow.shadowColor = shadowColor
        shadow.shadowOffset = shadowOffset
        shadow.shadowBlurRadius = shadowBlurRadius
        
        string.addAttribute(NSAttributedString.Key.shadow, value: shadow, range: NSMakeRange(0, string.length))
    }

    return string
}
