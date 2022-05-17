import SpriteKit

class PEMTmxTileAnimation : NSObject {
    private (set) var frames : [PEMTmxTileAnimationFrame] = []
    
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
        if let animationFrame = PEMTmxTileAnimationFrame(attributes: attributes) {
            frames.append(animationFrame)
        }
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileAnimation: frames:\(frames.count))"
    }
    #endif
}
