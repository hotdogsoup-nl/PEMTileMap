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
