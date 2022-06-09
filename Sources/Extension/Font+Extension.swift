#if os(macOS)

import AppKit

internal typealias Font = NSFont
internal typealias FontDescriptor = NSFontDescriptor
internal typealias Color = NSColor

#else

import UIKit

internal typealias Font = UIFont
internal typealias FontDescriptor = UIFontDescriptor
internal typealias Color = UIColor

#endif

internal extension Font {
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
