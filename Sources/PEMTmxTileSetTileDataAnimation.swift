import SpriteKit

class PEMTmxTileSetTileDataAnimation : NSObject {
    private (set) var frames : [PEMTmxTileSetTileDataAnimationFrame] = []
    
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
