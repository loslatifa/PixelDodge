//
//  Enemy.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//

import SpriteKit

enum EnemyType {
    case basic
    case fast
    case heavy
    case zigzag
}

/// Enemy 类定义了游戏中的敌人对象，继承自 SKSpriteNode。
/// 当前支持基础的敌人类型扩展，用于后续实现敌人多样性、阶段变化与技能系统交互。
class Enemy: SKSpriteNode {
    
    let enemyType: EnemyType
    let scoreValue: Int
    let damage: Int

    init(
        type: EnemyType = .basic,
        position: CGPoint,
        moveDistance: CGFloat,
        moveDuration: TimeInterval,
        onPassed: @escaping () -> Void
    ) {
        self.enemyType = type

        let enemySize: CGSize
        let enemyColor: NSColor
        let scoreValue: Int
        let damage: Int

        switch type {
        case .basic:
            enemySize = CGSize(width: 16, height: 16)
            enemyColor = .red
            scoreValue = 1
            damage = 1
        case .fast:
            enemySize = CGSize(width: 12, height: 12)
            enemyColor = .systemOrange
            scoreValue = 2
            damage = 1
        case .heavy:
            enemySize = CGSize(width: 22, height: 22)
            enemyColor = .systemPurple
            scoreValue = 3
            damage = 2
        case .zigzag:
            enemySize = CGSize(width: 16, height: 16)
            enemyColor = .systemPink
            scoreValue = 2
            damage = 1
        }

        self.scoreValue = scoreValue
        self.damage = damage

        super.init(texture: nil, color: enemyColor, size: enemySize)
        self.position = position
        self.name = "enemy"

        // 配置矩形物理体，参与接触检测但不产生实际碰撞反馈
        let body = SKPhysicsBody(rectangleOf: enemySize)
        body.isDynamic = true
        body.categoryBitMask = 0x1 << 1          // 敌人类别
        body.contactTestBitMask = 0x1 << 0       // 检测与玩家的接触
        body.collisionBitMask = 0                // 不发生实际碰撞
        self.physicsBody = body

        runMovement(moveDistance: moveDistance, moveDuration: moveDuration, onPassed: onPassed)
    }

    /// 根据敌人类型运行不同的移动逻辑，为后续阶段化敌人与技能系统交互预留扩展点
    private func runMovement(moveDistance: CGFloat, moveDuration: TimeInterval, onPassed: @escaping () -> Void) {
        let movement: SKAction

        switch enemyType {
        case .basic:
            movement = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration)

        case .fast:
            movement = SKAction.moveBy(x: -moveDistance, y: 0, duration: max(0.4, moveDuration * 0.7))

        case .heavy:
            movement = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration * 1.2)

        case .zigzag:
            let steps = 6
            let segmentX = -moveDistance / CGFloat(steps)
            let segmentDuration = moveDuration / Double(steps)
            var actions: [SKAction] = []

            for index in 0..<steps {
                let offsetY: CGFloat = index.isMultiple(of: 2) ? 18 : -18
                let move = SKAction.moveBy(x: segmentX, y: offsetY, duration: segmentDuration / 2)
                let recover = SKAction.moveBy(x: 0, y: -offsetY, duration: segmentDuration / 2)
                actions.append(move)
                actions.append(recover)
            }

            movement = SKAction.sequence(actions)
        }

        let passed = SKAction.run { onPassed() }
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([movement, passed, remove]))
    }

    /// 不支持通过 NSCoder 初始化，强制报错（Storyboard 不适用）
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
