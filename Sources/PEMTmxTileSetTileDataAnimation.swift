import SpriteKit

class PEMTmxTileSetTileDataAnimation : NSObject {
    private (set) var frames : [PEMTmxTileSetTileDataAnimationFrame] = []
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(type(of: self))")
        #endif
        #endif
    }
    
    // MARK: - Setup
    
    func addAnimationFrame(attributes: Dictionary<String, String>) {
        if let animationFrame = PEMTmxTileSetTileDataAnimationFrame(attributes: attributes) {
            frames.append(animationFrame)
        }
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileSetTileDataAnimation: frames:\(frames.count))"
    }
    #endif
}
