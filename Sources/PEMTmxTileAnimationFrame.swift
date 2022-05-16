import SpriteKit

class PEMTmxTileAnimationFrame : NSObject {
    private (set) var tileId = UInt32(0)
    private (set) var duration = UInt32(0)
    
    init?(attributes: Dictionary<String, String>) {
        guard let tileId = attributes[ElementAttributes.TileId.rawValue] else { return nil }
        guard let duration = attributes[ElementAttributes.Duration.rawValue] else { return nil }
        
        super.init()

        self.tileId = UInt32(tileId)!
        self.duration = UInt32(duration)!
    }
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(type(of: self))")
        #endif
        #endif
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxTileAnimationFrame: tileId: \(tileId), duration: (\(duration))"
    }
    #endif
}
