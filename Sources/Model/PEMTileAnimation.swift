import SpriteKit

class PEMTileAnimation: NSObject {
    private (set) var frames: [PEMTileAnimationFrame] = []
    
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
        if let animationFrame = PEMTileAnimationFrame(attributes: attributes) {
            frames.append(animationFrame)
        }
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTileAnimation: frames:\(frames.count))"
    }
    #endif
}
