//
//  Enemy.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//

import SpriteKit

class Enemy: SKSpriteNode {
    init(position: CGPoint, moveDistance: CGFloat, moveDuration: TimeInterval, onPassed: @escaping () -> Void) {
        let size = CGSize(width: 16, height: 16)
        super.init(texture: nil, color: .red, size: size)
        self.position = position
        self.texture?.filteringMode = .nearest
        self.name = "enemy"

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.categoryBitMask = 0x1 << 1
        body.contactTestBitMask = 0x1 << 0
        body.collisionBitMask = 0
        self.physicsBody = body

        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration)
        let increment = SKAction.run { onPassed() }
        let remove = SKAction.removeFromParent()
        self.run(SKAction.sequence([move, increment, remove]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
