#if os(macOS)

import AppKit

// this should work on an SKTexture.cgImage but unfortunately it doesn't, so we use NSImage.cgImage / UIImage.cgImage

internal extension NSImage {
    func remove(color: NSColor, tolerance: CGFloat = 4) -> NSImage {
        if let ciColor = CIColor(color: color) {
            let maskComponents: [CGFloat] = [ciColor.red, ciColor.green, ciColor.blue].flatMap { value in
                [(value * 255) - tolerance, (value * 255) + tolerance]
            }
            
            guard let masked = cgImage(forProposedRect: nil, context: nil, hints: nil)?.copy(maskingColorComponents: maskComponents) else { return self }
            return NSImage(cgImage: masked, size: size)
        }

        return self
    }
}

#else

import UIKit

internal extension UIImage {
    func remove(color: UIColor, tolerance: CGFloat = 4) -> UIImage {
        let ciColor = CIColor(color: color)
        let maskComponents: [CGFloat] = [ciColor.red, ciColor.green, ciColor.blue].flatMap { value in
            [(value * 255) - tolerance, (value * 255) + tolerance]
        }
        
        guard let masked = cgImage?.copy(maskingColorComponents: maskComponents) else { return self }
        return UIImage(cgImage: masked)
    }
}

#endif
