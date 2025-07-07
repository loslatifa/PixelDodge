//
//  Player.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//

import SpriteKit

class Player: SKSpriteNode {
    init(position: CGPoint) {
        let size = CGSize(width: 32, height: 32)
        super.init(texture: nil, color: .green, size: size)
        self.position = position
        self.texture?.filteringMode = .nearest
        self.name = "player"

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.categoryBitMask = 0x1 << 0
        body.contactTestBitMask = 0x1 << 1
        body.collisionBitMask = 0
        self.physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
