import Foundation

extension TimeInterval {
    func stringValue() -> String {
        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let s = Int(self) % 60
        let mn = (Int(self) / 60) % 60
        
        return String(format: "%0.2d'%0.2d\"%0.3d", mn, s, ms)
    }
}
