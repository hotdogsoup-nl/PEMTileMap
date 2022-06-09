import SpriteKit

extension SKColor {
    convenience init(hexString: String) {
        func standardiseHexString(_ hexString: String) -> String {
            let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            switch hex.count {
                case 3, 4:
                    let hexStringArray = Array(hex)
                    return zip(hexStringArray, hexStringArray).reduce("") { (result, values) in
                        return result + String(values.0) + String(values.1)
                    }
                default:
                    return hex
            }
        }
        
        let hex = standardiseHexString(hexString)
        var hexNumber = UInt64()
        Scanner(string: hex).scanHexInt64(&hexNumber)
        let a, r, g, b: UInt64
        switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (hexNumber >> 8) * 17, (hexNumber >> 4 & 0xF) * 17, (hexNumber & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, hexNumber >> 16, hexNumber >> 8 & 0xFF, hexNumber & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (hexNumber >> 24 & 0xFF, hexNumber >> 16 & 0xFF, hexNumber >> 8 & 0xFF, hexNumber & 0xFF)
            default:
                (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    func multiplyColor(_ color: SKColor) -> SKColor {
        var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        var (multR, multG, multB, multA) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        color.getRed(&multR, green: &multG, blue: &multB, alpha: &multA)
        
        return SKColor(red: r * multR, green: g * multG, blue: b * multB, alpha: a * multA)
    }
}
