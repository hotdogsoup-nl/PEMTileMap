import SpriteKit

internal class PEMTileAnimationFrame: NSObject {
    private (set) var tileId = UInt32(0)
    private (set) var duration = UInt32(0)
    
    init?(attributes: Dictionary<String, String>) {
        guard let tileId = attributes[ElementAttributes.tileId.rawValue] else { return nil }
        guard let duration = attributes[ElementAttributes.duration.rawValue] else { return nil }
        
        super.init()

        self.tileId = UInt32(tileId)!
        self.duration = UInt32(duration)!
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTileAnimationFrame: tileId: \(tileId), duration: (\(duration))"
    }
    #endif
}
