#if os(macOS)
import AppKit
#else
import UIKit
#endif

internal extension NSAttributedString {
    convenience init(string: String,
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
                              shadowBlurRadius: CGFloat = 0) {
        
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
        
        self.init(attributedString: string)
    }
}
