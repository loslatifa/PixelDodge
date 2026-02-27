import SpriteKit

/// Player 类定义了游戏中的主角角色，继承自 SKSpriteNode，负责初始化精灵纹理、物理属性和动画效果，支持持续奔跑动画及碰撞检测配置。
class Player: SKSpriteNode {
    var runTextures: [SKTexture] = []
    var isDashing = false
    var canTakeDamage = true
    var dashCooldown: TimeInterval = 1.2
    var dashDistance: CGFloat = 90
    var facingRight = true
    var moveSpeed: CGFloat = 200

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

        // 配置物理体（矩形包围盒），略小于视觉尺寸以提升闪避手感
        let hitboxSize = CGSize(width: size.width * 0.72, height: size.height * 0.78)
        let body = SKPhysicsBody(rectangleOf: hitboxSize)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false

        // 设置物理体的类别与碰撞规则：仅检测与 BitMask = 0x1 << 1 和 0x1 << 2 的对象接触
        body.categoryBitMask = 0x1 << 0        // 玩家自身类别
        body.contactTestBitMask = 0x1 << 1 | 0x1 << 2   // 检测敌人、金币等对象
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

    /// 更新角色朝向，供场景中的移动输入与技能逻辑复用
    func updateFacing(isMovingRight: Bool) {
        facingRight = isMovingRight
        xScale = isMovingRight ? abs(xScale) : -abs(xScale)
    }

    /// 根据 moveSpeed 和方向更新玩家位置，供场景调用以实现移动
    func move(direction: CGFloat, deltaTime: TimeInterval) {
        let distance = moveSpeed * CGFloat(deltaTime) * direction
        position.x += distance
        updateFacing(isMovingRight: direction >= 0)
    }

    /// 执行一次 Dash，返回本次位移增量；具体边界限制由场景层处理
    func dashVector() -> CGVector {
        let direction: CGFloat = facingRight ? 1 : -1
        return CGVector(dx: dashDistance * direction, dy: 0)
    }

    /// 开始 Dash 状态，供后续技能系统或场景逻辑调用
    func beginDash() {
        isDashing = true
    }

    /// 结束 Dash 状态
    func endDash() {
        isDashing = false
    }

    /// 设置是否可受伤，并同步角色透明度表现
    func setDamageState(canTakeDamage: Bool) {
        self.canTakeDamage = canTakeDamage
        alpha = canTakeDamage ? 1.0 : 0.75
    }

    /// 不支持通过 NSCoder 初始化（通常用于 Storyboard），强制报错
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
