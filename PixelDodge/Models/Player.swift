import SpriteKit

class Player: SKSpriteNode {
    var runTextures: [SKTexture] = []

    init(position: CGPoint) {
        let size = CGSize(width: 32, height: 32)
        let texture = SKTexture(imageNamed: "player_run_right_1")
        texture.filteringMode = .nearest
        super.init(texture: texture, color: .clear, size: size)
        self.position = position
        self.name = "player"

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = 0x1 << 0
        body.contactTestBitMask = 0x1 << 1
        body.collisionBitMask = 0
        self.physicsBody = body

        for i in 1...4 {
            let tex = SKTexture(imageNamed: "player_run_right_\(i)")
            tex.filteringMode = .nearest
            runTextures.append(tex)
        }

        let runAnimation = SKAction.animate(with: runTextures, timePerFrame: 0.12)
        let repeatRun = SKAction.repeatForever(runAnimation)
        self.run(repeatRun, withKey: "runAnimation")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
