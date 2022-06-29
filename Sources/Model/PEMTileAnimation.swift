import SpriteKit

internal class PEMTileAnimation: NSObject {
    private (set) var frames: Array<PEMTileAnimationFrame> = []
    
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
