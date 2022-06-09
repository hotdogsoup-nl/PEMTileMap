import Foundation

extension TimeInterval {
    func minSecMsRepresentation() -> String {
        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let s = Int(self) % 60
        let min = (Int(self) / 60) % 60
        
        return String(format: "%0.2d'%0.2d\"%0.3d", min, s, ms)
    }
}
