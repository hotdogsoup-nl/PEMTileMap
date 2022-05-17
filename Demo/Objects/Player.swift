import SpriteKit
import CoreGraphics

let SpawnTypePlayer = "Player"

enum MovementDirection {
    case idle
    case left
    case right
}

class Player : SKSpriteNode {
    var isDead = false
    var onGround = false
    var shouldJump = false
    var direction = MovementDirection.idle
    var desiredPosition = CGPoint.zero
    var velocity = CGPoint.zero

    private let jumpForce = CGPoint(x: 0, y: gameTileSize.height * 15)
    private let movementForce = CGFloat(playerSize.width * 10)
    private let movementDecelerationFactor = CGFloat(0.9)

    private var texture_0 : SKTexture?
    private var texture_1 : SKTexture?

    class func newPlayer() -> Player {
        let newPlayer = Player(color: .red, size: playerSize)
        
        if (!SHOW_PLAYER_AS_BOX) {
            newPlayer.texture_0 = SKTexture(imageNamed: "Player_0")
            newPlayer.texture_0?.filteringMode = .nearest

            newPlayer.texture_1 = SKTexture(imageNamed: "Player_1")
            newPlayer.texture_1?.filteringMode = .nearest
        }
        
        newPlayer.texture = newPlayer.texture_0
        newPlayer.zPosition = 1000

        return newPlayer
    }
    
    func update(_ delta: TimeInterval) {
        let gravityStep = CGPointMultiplyScalar(gravity, delta)
        velocity = CGPointAdd(velocity, gravityStep)
        
        if isDead {
            velocity = CGPoint(x: velocity.x * movementDecelerationFactor, y: velocity.y)
        }

        if shouldJump && onGround {
            if !isDead {
                velocity = CGPointAdd(velocity, jumpForce)
                onGround = false
            } else {
                velocity = CGPoint(x: velocity.x, y: 0)
            }
        }
                
        if !isDead {
            switch direction {
            case .idle:
                velocity = CGPoint(x: 0, y: velocity.y)
                break
            case .left:
                velocity = CGPoint(x: -movementForce, y: velocity.y)
                xScale = -1.0
                break
            case .right:
                velocity = CGPoint(x: movementForce, y: velocity.y)
                xScale = 1.0
                break
            }
        }
                
        if velocity.y > 0 {
            texture = texture_1
        } else {
            texture = texture_0
        }
        
        let velocityStep = CGPointMultiplyScalar(velocity, delta)
        desiredPosition = CGPointAdd(position, velocityStep)
    }
    
    func collisionBoundingBox() -> CGRect {
        let offset = CGPoint(x: 2.0, y: 2.0)
        let clippingHeight = gameTileSize.height - size.height
        let boundingBox = CGRect(x: frame.origin.x + offset.x * 0.5, y: frame.origin.y - clippingHeight * 0.25 - offset.y, width: size.width - offset.x, height: size.height + clippingHeight)
        let diff = CGPointSubtract(desiredPosition, position);
        return boundingBox.offsetBy(dx: diff.x, dy: diff.y);
    }
    
}
