import SpriteKit

/// Player 类定义了游戏中的主角角色，继承自 SKSpriteNode，负责初始化精灵纹理、物理属性和动画效果，支持持续奔跑动画及碰撞检测配置。
class Player: SKSpriteNode {
    var runTextures: [SKTexture] = []

    /// 使用指定位置初始化玩家对象，设置大小、初始纹理、物理体以及奔跑动画
    init(position: CGPoint) {
        // 设置精灵尺寸和初始纹理
        let size = CGSize(width: 32, height: 32)
        let texture = SKTexture(imageNamed: "player_run_right_1")
        texture.filteringMode = .nearest  // 使用最近邻过滤，保持像素风格
        super.init(texture: texture, color: .clear, size: size)

        // 设置初始位置与名称
        self.position = position
        self.name = "player"

        // 配置物理体（矩形包围盒），启用动态、禁用重力和旋转
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false

        // 设置物理体的类别与碰撞规则：仅检测与 BitMask = 0x1 << 1 的对象接触
        body.categoryBitMask = 0x1 << 0        // 玩家自身类别
        body.contactTestBitMask = 0x1 << 1     // 感兴趣的碰撞对象类别（如敌人）
        body.collisionBitMask = 0              // 不参与真实碰撞响应
        self.physicsBody = body

        // 加载连续奔跑帧（4 帧），设置过滤模式为最近邻
        for i in 1...4 {
            let tex = SKTexture(imageNamed: "player_run_right_\(i)")
            tex.filteringMode = .nearest
            runTextures.append(tex)
        }

        // 创建帧动画并设置为永久循环播放
        let runAnimation = SKAction.animate(with: runTextures, timePerFrame: 0.12)
        let repeatRun = SKAction.repeatForever(runAnimation)
        self.run(repeatRun, withKey: "runAnimation")
    }

    /// 不支持通过 NSCoder 初始化（通常用于 Storyboard），强制报错
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
