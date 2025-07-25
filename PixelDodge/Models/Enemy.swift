//
//  Enemy.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//

import SpriteKit

/// Enemy 类定义了游戏中的敌人对象，继承自 SKSpriteNode，包含基本红色外观、物理碰撞属性与自动移动逻辑；敌人从右向左移动一定距离，移动完成后执行得分回调并自移除。
class Enemy: SKSpriteNode {
    
    /// 初始化敌人对象，设置位置、尺寸、碰撞体、左向移动动画、移动结束回调（用于计分）与自动销毁
    init(position: CGPoint, moveDistance: CGFloat, moveDuration: TimeInterval, onPassed: @escaping () -> Void) {
        // 设置尺寸与初始颜色，无纹理（可扩展为贴图）
        let size = CGSize(width: 16, height: 16)
        super.init(texture: nil, color: .red, size: size)
        self.position = position
        self.texture?.filteringMode = .nearest  // 若后续添加纹理，仍保持像素风格
        self.name = "enemy"

        // 配置矩形物理体，参与碰撞但无物理响应
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.categoryBitMask = 0x1 << 1          // 敌人类别
        body.contactTestBitMask = 0x1 << 0       // 可检测与玩家的接触
        body.collisionBitMask = 0                // 不发生实际碰撞
        self.physicsBody = body

        // 定义敌人移动行为：向左移动指定距离
        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration)
        
        // 移动完成后执行回调（通常用于计分）
        let increment = SKAction.run { onPassed() }

        // 最终从场景中移除敌人
        let remove = SKAction.removeFromParent()

        // 运行完整行为序列：移动 → 回调 → 移除
        self.run(SKAction.sequence([move, increment, remove]))
    }

    /// 不支持通过 NSCoder 初始化，强制报错（Storyboard 不适用）
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
