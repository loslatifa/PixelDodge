//
//  GameScene.swift
//  PixelDodge
//
//  Updated: Integrate player running animation with direction flip and maintain full game functionalities.


import SpriteKit
import GameplayKit

// 升级类型，三选一升级系统用
enum UpgradeType: String, CaseIterable {
    case dashCooldown
    case dashDistance
    case heal
    case moveSpeed
    case nearMissBoost
    case coinBonus

    var title: String {
        switch self {
        case .dashCooldown: return "Dash 冷却降低"
        case .dashDistance: return "Dash 距离提升"
        case .heal: return "恢复 1 点生命"
        case .moveSpeed: return "移动速度提升"
        case .nearMissBoost: return "Near Miss 强化"
        case .coinBonus: return "金币奖励提升"
        }
    }
}

// 阶段事件类型
enum PhaseEventType: String {
    case none
    case enemyRush
    case coinShower
    case heavyWave
    case precisionWindow

    var title: String {
        switch self {
        case .none: return "Normal"
        case .enemyRush: return "Enemy Rush"
        case .coinShower: return "Coin Shower"
        case .heavyWave: return "Heavy Wave"
        case .precisionWindow: return "Precision Window"
        }
    }
}

// 被动技能类型
enum PassiveType: String, CaseIterable {
    case agile
    case survivor
    case collector
    case daring

    var title: String {
        switch self {
        case .agile: return "Agile"
        case .survivor: return "Survivor"
        case .collector: return "Collector"
        case .daring: return "Daring"
        }
    }
}

//  GameScene 是主场景类，负责设置游戏界面，包括白色背景、一个蓝色方块作为玩家角色、右上角的分数标签，同时每秒生成一个红色敌人从右侧进入场景向左移动，玩家可点击屏幕控制蓝色方块平滑移动到点击位置。若红色敌人成功越过蓝色方块左侧则判为成功避让，分数加一；敌人和玩家之间没有碰撞逻辑，仅通过位置关系判断得分；场景初始化时构造角色与标签，启动定时器生成敌人；每帧检测所有敌人是否越过玩家位置并更新得分；该实现为基础闪避类游戏框架，适合进一步拓展碰撞检测、失败机制或难度递增等功能。

class GameScene: SKScene, SKPhysicsContactDelegate {
    // 玩家与状态
    var player: Player!
    var gameOver = false
    var playerHealth = 3
    var isInvulnerable = false
    var isPausedGame = false
    var lastUpdateTime: TimeInterval = 0
    var lastDashTime: TimeInterval = -10
    var dashWasReadyLastFrame = true
    var nearMissCooldownUntil: TimeInterval = 0
    var lastMoveDirection = CGVector(dx: 1, dy: 0)
    let dashInvulnerabilityDuration: TimeInterval = 0.18
    let dashEffectColor = NSColor.systemCyan
    var moveStep: CGFloat = 20

    // 暂停覆盖层相关
    var pauseOverlay: SKShapeNode?
    var pauseTitleLabel: SKLabelNode?
    var pauseHintLabel: SKLabelNode?

    // 标签与 HUD
    var scoreLabel: SKLabelNode!
    var levelLabel: SKLabelNode!
    var healthLabel: SKLabelNode!
    var coinLabel: SKLabelNode!
    var dashLabel: SKLabelNode!
    var nearMissLabel: SKLabelNode!
    var eventLabel: SKLabelNode!
    var passiveLabel: SKLabelNode!
    var phaseLabel: SKLabelNode!

    // 敌人生成与阶段
    var spawnInterval: Double = 1.0
    var enemySpeed: Double = 5.0
    let scoreToPass = 50
    var enemyPassCount = 0
    var phaseTimerKey = "phaseTimer"
    var currentPhase = 1

    // 事件系统
    var currentEvent: PhaseEventType = .none
    var eventEndTime: TimeInterval = 0

    // 被动技能
    var currentPassive: PassiveType = .agile

    // 升级&奖励
    var nearMissScoreBonus = 1
    var nearMissDashReduction: TimeInterval = 0.25
    var coinScoreBonus = 0
    // 升级三选一相关变量
    var upgradeOverlay: SKShapeNode?
    var upgradeTitleLabel: SKLabelNode?
    var upgradeOptionLabels: [SKLabelNode] = []
    var pendingUpgradeOptions: [UpgradeType] = []
    var isUpgradeSelectionActive = false

    //  didMove(to:) 是场景加载后被系统调用的初始化方法，在此设置黑色背景、关闭重力并启用碰撞委托，读取 GameManager 中保存的当前游戏进度与等级，根据等级动态调整敌人生成频率 spawnInterval 与速度 enemySpeed，创建玩家角色并置于屏幕中心，构建并布局三个 HUD 标签（得分、关卡、生命值）分别居左、中、右显示在顶部，随后启动敌人与金币的周期性生成逻辑 runEnemySpawn() 和 runCoinSpawn()，为游戏开始运行做完整准备。
    // 场景初始化
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        // 加载游戏数据（得分、等级等）
        let manager = GameManager.shared
        manager.loadGame()
        
        // 根据当前关卡调整敌人生成频率与速度（关卡越高越快）
        currentPhase = max(1, manager.currentLevel)
        spawnInterval = max(0.4, 1.0 - Double(manager.currentLevel - 1) * 0.08)
        enemySpeed = max(2.5, 5.0 - Double(manager.currentLevel - 1) * 0.25)

        // 初始化玩家角色并放置在屏幕中心
        player = Player(position: CGPoint(x: frame.midX, y: frame.midY))
        addChild(player)
        
        // 添加得分标签，固定在左上角
        scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: size.height - 30)
        scoreLabel.text = "Score: \(manager.currentScore)"
        addChild(scoreLabel)

        // 添加等级标签，居中显示在顶部
        levelLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        levelLabel.fontSize = 20
        levelLabel.fontColor = .white
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 30)
        levelLabel.text = "Level: \(manager.currentLevel)"
        addChild(levelLabel)

        // 添加阶段标签，显示当前难度阶段
        phaseLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        phaseLabel.fontSize = 16
        phaseLabel.fontColor = .lightGray
        phaseLabel.horizontalAlignmentMode = .center
        phaseLabel.position = CGPoint(x: size.width / 2, y: size.height - 55)
        phaseLabel.text = "Phase: \(currentPhase)"
        addChild(phaseLabel)

        // 添加生命值标签，右上角显示心形和剩余血量
        healthLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        healthLabel.fontSize = 20
        healthLabel.fontColor = .white
        healthLabel.horizontalAlignmentMode = .right
        healthLabel.position = CGPoint(x: size.width - 20, y: size.height - 30)
        healthLabel.text = "❤️ x \(playerHealth)"
        addChild(healthLabel)
        
        // 添加金币标签，显示本局已收集金币数
        coinLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        coinLabel.fontSize = 18
        coinLabel.fontColor = .yellow
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.position = CGPoint(x: 20, y: size.height - 55)
        coinLabel.text = "Coins: \(manager.currentCoins)"
        addChild(coinLabel)

        // 添加 Dash 技能标签，显示冷却状态
        dashLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        dashLabel.fontSize = 18
        dashLabel.fontColor = .cyan
        dashLabel.horizontalAlignmentMode = .right
        dashLabel.position = CGPoint(x: size.width - 20, y: size.height - 55)
        dashLabel.text = "Dash: Ready"
        addChild(dashLabel)

        nearMissLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        nearMissLabel.fontSize = 18
        nearMissLabel.fontColor = .systemMint
        nearMissLabel.horizontalAlignmentMode = .center
        nearMissLabel.position = CGPoint(x: size.width / 2, y: size.height - 85)
        nearMissLabel.alpha = 0
        nearMissLabel.text = "Near Miss +1"
        addChild(nearMissLabel)

        // 添加事件标签
        eventLabel = SKLabelNode(fontNamed: "Menlo")
        eventLabel.fontSize = 15
        eventLabel.fontColor = .systemOrange
        eventLabel.position = CGPoint(x: size.width / 2, y: size.height - 105)
        eventLabel.text = "Event: Normal"
        addChild(eventLabel)

        // 添加被动标签
        passiveLabel = SKLabelNode(fontNamed: "Menlo")
        passiveLabel.fontSize = 15
        passiveLabel.fontColor = .systemTeal
        passiveLabel.position = CGPoint(x: size.width / 2, y: size.height - 125)
        addChild(passiveLabel)

        // 初始化本局运行状态
        manager.currentScore = 0
        manager.currentCoins = 0
        scoreLabel.text = "Score: \(manager.currentScore)"
        coinLabel.text = "Coins: \(manager.currentCoins)"
        dashWasReadyLastFrame = true
        nearMissCooldownUntil = 0
        nearMissScoreBonus = 1
        nearMissDashReduction = 0.25
        coinScoreBonus = 0
        moveStep = 20
        currentEvent = .none
        eventEndTime = 0
        // 随机初始化本局被动技能
        currentPassive = PassiveType.allCases.randomElement() ?? .agile
        applyPassive()
        updatePassiveHUD()

        // 启动敌人和金币的生成机制
        runEnemySpawn()
        runCoinSpawn()
        startPhaseTimer()
    }

    func startPhaseTimer() {
        removeAction(forKey: phaseTimerKey)
        let wait = SKAction.wait(forDuration: 15.0)
        let upgrade = SKAction.run { [weak self] in
            self?.advancePhase()
        }
        let loop = SKAction.repeatForever(SKAction.sequence([wait, upgrade]))
        run(loop, withKey: phaseTimerKey)
    }

    // 进入新阶段，提升难度，触发事件，三选一升级
    func advancePhase() {
        guard !gameOver else { return }
        currentPhase += 1
        phaseLabel.text = "Phase: \(currentPhase)"
        GameManager.shared.currentLevel = currentPhase

        // 难度提升：敌人生成更快，速度更快
        spawnInterval = max(0.25, spawnInterval - 0.08)
        enemySpeed = max(1.8, enemySpeed - 0.2)

        removeAction(forKey: "spawnEnemies")
        runEnemySpawn()

        let pulseUp = SKAction.scale(to: 1.15, duration: 0.12)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.12)
        phaseLabel.run(SKAction.sequence([pulseUp, pulseDown]))

        // 启用新事件
        startPhaseEvent()
        // 三选一升级
        presentUpgradeSelection()
    }

    // 随机事件
    func startPhaseEvent() {
        let events: [PhaseEventType] = [.enemyRush, .coinShower, .heavyWave, .precisionWindow]
        currentEvent = events.randomElement() ?? .none
        eventEndTime = lastUpdateTime + 10.0
        eventLabel.text = "Event: \(currentEvent.title)"
        // 重启金币生成以适应事件
        removeAction(forKey: "spawnCoins")
        runCoinSpawn()
    }

    func clampPlayerPosition() {
        let halfWidth = player.frame.width / 2
        let halfHeight = player.frame.height / 2
        let minX = halfWidth
        let maxX = size.width - halfWidth
        let minY: CGFloat = halfHeight
        let maxY = size.height - halfHeight

        player.position.x = min(max(player.position.x, minX), maxX)
        player.position.y = min(max(player.position.y, minY), maxY)
    }

    // 敌人生成逻辑
    func runEnemySpawn() {
        let spawn = SKAction.run { [weak self] in self?.spawnEnemy() }
        let wait = SKAction.wait(forDuration: spawnInterval)
        let spawnForever = SKAction.repeatForever(SKAction.sequence([spawn, wait]))
        run(spawnForever, withKey: "spawnEnemies")
    }

    // 金币生成逻辑，事件期间更快
    func runCoinSpawn() {
        let duration = (currentEvent == PhaseEventType.coinShower) ? 2.2 : 5.0
        let spawn = SKAction.run { [weak self] in self?.spawnCoin() }
        let wait = SKAction.wait(forDuration: duration)
        let spawnForever = SKAction.repeatForever(SKAction.sequence([spawn, wait]))
        run(spawnForever, withKey: "spawnCoins")
    }

    // 敌人生成，加入新敌人类型
    func spawnEnemy() {
        var speed = enemySpeed + Double.random(in: -1...1)
        if currentEvent == PhaseEventType.enemyRush {
            speed = max(1.2, speed * 0.72)
        }
        let enemyType: EnemyType
        if currentEvent == PhaseEventType.heavyWave {
            let options: [EnemyType] = [.heavy, .heavy, .basic]
            enemyType = options.randomElement() ?? .heavy
        } else {
            switch currentPhase {
            case 1:
                enemyType = .basic
            case 2:
                enemyType = Bool.random() ? .basic : .fast
            case 3:
                let options: [EnemyType] = [.basic, .fast, .zigzag]
                enemyType = options.randomElement() ?? .basic
            default:
                let options: [EnemyType] = [.basic, .fast, .zigzag, .heavy]
                // 以后可以增加更多新类型
                enemyType = options.randomElement() ?? .basic
            }
        }

        let enemy = Enemy(
            type: enemyType,
            position: CGPoint(x: frame.maxX + 20, y: CGFloat.random(in: 40...(size.height - 40))),
            moveDistance: size.width + 40,
            moveDuration: speed,
            onPassed: { [weak self] in self?.incrementScore() }
        )
        addChild(enemy)
    }

    // 金币生成，加入高风险金币
    func spawnCoin() {
        // 高风险金币更值钱，靠近敌人时更常出现
        let isRiskyCoin = Bool.random()
        let isLargeCoin = Bool.random() || currentEvent == PhaseEventType.coinShower

        let coinSize: CGFloat = isLargeCoin ? 24 : 20
        let coin = SKSpriteNode(color: isRiskyCoin ? .systemOrange : .yellow, size: CGSize(width: coinSize, height: coinSize))
        coin.name = "coin"
        coin.position = CGPoint(x: CGFloat.random(in: 40...(size.width - 40)), y: CGFloat.random(in: 40...(size.height - 40)))
        coin.zPosition = 1

        let body = SKPhysicsBody(circleOfRadius: coinSize / 2)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = 0x1 << 2
        body.contactTestBitMask = 0x1 << 0
        body.collisionBitMask = 0
        coin.physicsBody = body

        // 设置分值
        let scoreValue = isLargeCoin ? 10 : 5
        let coinValue = isLargeCoin ? 2 : 1
        coin.userData = [
            "scoreValue": scoreValue,
            "coinValue": coinValue
        ]

        addChild(coin)

        let pulseUp = SKAction.scale(to: 1.15, duration: 0.4)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.4)
        let pulse = SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown]))
        coin.run(pulse, withKey: "coinPulse")

        let wait = SKAction.wait(forDuration: isRiskyCoin ? 4.0 : 6.0)
        let remove = SKAction.removeFromParent()
        coin.run(SKAction.sequence([wait, remove]))
    }
    // 应用被动技能效果
    func applyPassive() {
        // 重置为基础数值
        nearMissScoreBonus = 1
        nearMissDashReduction = 0.25
        coinScoreBonus = 0
        moveStep = 20
        player.dashCooldown = 1.0
        player.dashDistance = 110
        player.moveSpeed = 220
        switch currentPassive {
        case .agile:
            moveStep = 30
            player.moveSpeed = 300
        case .survivor:
            playerHealth += 1
        case .collector:
            coinScoreBonus = 3
        case .daring:
            nearMissScoreBonus = 2
            nearMissDashReduction = 0.33
        }
        healthLabel?.text = "❤️ x \(playerHealth)"
        updatePassiveHUD()
    }

    // 被动技能标签刷新
    func updatePassiveHUD() {
        passiveLabel?.text = "Passive: \(currentPassive.title)"
    }

    // 三选一升级面板
    func presentUpgradeSelection() {
        guard !isUpgradeSelectionActive else { return }
        isUpgradeSelectionActive = true
        self.isPaused = true

        // 随机三项升级
        var all = UpgradeType.allCases.shuffled()
        pendingUpgradeOptions = Array(all.prefix(3))

        // 覆盖层
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 0.7, height: size.height * 0.52), cornerRadius: 18)
        overlay.fillColor = .black
        overlay.alpha = 0.93
        overlay.strokeColor = .systemTeal
        overlay.lineWidth = 3
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 99
        addChild(overlay)

        upgradeOverlay = overlay

        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "选择一项升级"
        title.fontSize = 30
        title.fontColor = .systemTeal
        title.position = CGPoint(x: 0, y: overlay.frame.height * 0.28)
        overlay.addChild(title)

        upgradeOptionLabels.removeAll()
        for (i, upgrade) in pendingUpgradeOptions.enumerated() {
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = upgrade.title
            label.fontSize = 24
            label.fontColor = .white
            label.position = CGPoint(x: 0, y: overlay.frame.height * 0.08 - CGFloat(i) * 54)
            label.name = "upgrade_\(i)"
            label.zPosition = 100
            overlay.addChild(label)
            upgradeOptionLabels.append(label)
        }

        let tip = SKLabelNode(fontNamed: "Menlo")
        tip.text = "点击选择升级"
        tip.fontSize = 18
        tip.fontColor = .gray
        tip.position = CGPoint(x: 0, y: -overlay.frame.height * 0.28)
        overlay.addChild(tip)

        upgradeTitleLabel = title
    }

    // 处理升级选择
    override func mouseDown(with event: NSEvent) {
        if isUpgradeSelectionActive, let overlay = upgradeOverlay {
            let location = event.location(in: overlay)
            for (i, label) in upgradeOptionLabels.enumerated() {
                if label.contains(location) {
                    let selected = pendingUpgradeOptions[i]
                    applyUpgrade(selected)
                    dismissUpgradeSelection()
                    return
                }
            }
            return
        }
        if gameOver {
            let location = event.location(in: self)
            let nodes = nodes(at: location)
            for node in nodes {
                if node.name == "continue" {
                    GameManager.shared.resetRunState()
                    let nextScene = GameScene(size: self.size)
                    nextScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(nextScene, transition: transition)
                } else if node.name == "quit" {
                    GameManager.shared.saveGame()
                    let startScene = StartScene(size: self.size)
                    startScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(startScene, transition: transition)
                }
            }
        }
    }

    // 应用升级效果
    func applyUpgrade(_ upgrade: UpgradeType) {
        switch upgrade {
        case .dashCooldown:
            player.dashCooldown = max(0.5, player.dashCooldown - 0.18)
        case .dashDistance:
            player.dashDistance += 30
        case .heal:
            playerHealth += 1
            healthLabel?.text = "❤️ x \(playerHealth)"
        case .moveSpeed:
            moveStep += 6
            player.moveSpeed += 38
        case .nearMissBoost:
            nearMissScoreBonus += 1
            nearMissDashReduction += 0.10
        case .coinBonus:
            coinScoreBonus += 2
        }
    }

    func incrementScore() {
        guard !gameOver else { return }
        enemyPassCount += 1
        if enemyPassCount % 2 == 0 {
            let manager = GameManager.shared
            manager.currentScore += 1
            scoreLabel.text = "Score: \(manager.currentScore)"

            if manager.currentScore >= scoreToPass {
                proceedToNextLevel()
            }
        }
    }

    func proceedToNextLevel() {
        let manager = GameManager.shared
        manager.currentLevel += 1
        manager.currentScore = 0
        manager.unlockNextLevel()
        manager.saveGame()

        let nextScene = GameScene(size: size)
        nextScene.scaleMode = .resizeFill
        let transition = SKTransition.flipHorizontal(withDuration: 1.0)
        view?.presentScene(nextScene, transition: transition)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC to pause / resume
            togglePauseState()
            return
        } else if event.keyCode == 49, isPausedGame { // Space to resume when paused
            togglePauseState(forceResume: true)
            return
        }

        guard !gameOver, !isPausedGame else { return }

        if event.keyCode == 40 || event.keyCode == 56 || event.keyCode == 60 { // K / Shift
            tryDash()
            return
        }

        let moveAmount = moveStep
        switch event.keyCode {
        case 0x7E, 13: // Up / W
            player.position.y += moveAmount
            lastMoveDirection = CGVector(dx: 0, dy: 1)
        case 0x7D, 1: // Down / S
            player.position.y -= moveAmount
            lastMoveDirection = CGVector(dx: 0, dy: -1)
        case 0x7B, 0: // Left / A
            player.position.x -= moveAmount
            player.updateFacing(isMovingRight: false)
            lastMoveDirection = CGVector(dx: -1, dy: 0)
        case 0x7C, 2: // Right / D
            player.position.x += moveAmount
            player.updateFacing(isMovingRight: true)
            lastMoveDirection = CGVector(dx: 1, dy: 0)
        default:
            break
        }
        clampPlayerPosition()
    }

    func tryDash() {
        guard !player.isDashing else { return }
        let elapsed = lastUpdateTime - lastDashTime
        guard elapsed >= player.dashCooldown else {
            showDashCooldownFeedback()
            return
        }

        lastDashTime = lastUpdateTime
        player.beginDash()
        isInvulnerable = true
        player.setDamageState(canTakeDamage: false)

        showDashFlash()
        spawnDashAfterimages()

        let dash = dashVector()
        player.position = CGPoint(x: player.position.x + dash.dx, y: player.position.y + dash.dy)
        clampPlayerPosition()

        let dashOut = SKAction.scale(to: 1.15, duration: 0.06)
        let dashBack = SKAction.scale(to: 1.0, duration: 0.08)
        let dashFinish = SKAction.run { [weak self] in
            self?.player.endDash()
        }
        player.run(SKAction.sequence([dashOut, dashBack, dashFinish]))

        let recover = SKAction.sequence([
            SKAction.wait(forDuration: dashInvulnerabilityDuration),
            SKAction.run { [weak self] in
                self?.isInvulnerable = false
                self?.player.setDamageState(canTakeDamage: true)
            }
        ])
        run(recover)
    }

    func updateDashHUD() {
        let remaining = max(0, player.dashCooldown - (lastUpdateTime - lastDashTime))
        let isReady = remaining <= 0.01

        if isReady {
            dashLabel.text = "Dash: Ready"
            dashLabel.fontColor = .cyan

            if !dashWasReadyLastFrame {
                let popUp = SKAction.scale(to: 1.16, duration: 0.08)
                let popDown = SKAction.scale(to: 1.0, duration: 0.10)
                let brighten = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
                dashLabel.alpha = 0.85
                dashLabel.run(SKAction.group([
                    SKAction.sequence([popUp, popDown]),
                    brighten
                ]))
            }
        } else {
            dashLabel.text = String(format: "Dash: %.1fs", remaining)
            dashLabel.fontColor = .gray
        }

        dashWasReadyLastFrame = isReady
    }

    func showDashFlash() {
        let flash = SKShapeNode(circleOfRadius: max(player.size.width, player.size.height) * 0.8)
        flash.position = player.position
        flash.fillColor = dashEffectColor
        flash.strokeColor = .clear
        flash.alpha = 0.32
        flash.zPosition = player.zPosition - 1
        addChild(flash)

        let expand = SKAction.scale(to: 1.8, duration: 0.10)
        let fade = SKAction.fadeOut(withDuration: 0.12)
        let group = SKAction.group([expand, fade])
        let remove = SKAction.removeFromParent()
        flash.run(SKAction.sequence([group, remove]))
    }

    func spawnDashAfterimages() {
        let steps = 3
        let dash = dashVector()

        for index in 0..<steps {
            let progress = CGFloat(index + 1) / CGFloat(steps + 1)
            let ghost = SKSpriteNode(texture: player.texture, color: .clear, size: player.size)
            ghost.position = CGPoint(
                x: player.position.x + dash.dx * progress,
                y: player.position.y + dash.dy * progress
            )
            ghost.xScale = player.xScale
            ghost.yScale = player.yScale
            ghost.alpha = 0.26 - CGFloat(index) * 0.06
            ghost.zPosition = player.zPosition - 0.5
            ghost.colorBlendFactor = 0
            ghost.name = "dashGhost"
            addChild(ghost)

            let fade = SKAction.fadeOut(withDuration: 0.16)
            let shrink = SKAction.scale(to: 0.88, duration: 0.16)
            let group = SKAction.group([fade, shrink])
            let remove = SKAction.removeFromParent()
            ghost.run(SKAction.sequence([group, remove]))
        }
    }

    func dashVector() -> CGVector {
        let dx = lastMoveDirection.dx
        let dy = lastMoveDirection.dy
        let length = sqrt(dx * dx + dy * dy)

        guard length > 0.001 else {
            return CGVector(dx: player.dashDistance, dy: 0)
        }

        return CGVector(
            dx: player.dashDistance * dx / length,
            dy: player.dashDistance * dy / length
        )
    }

    func showDashCooldownFeedback() {
        dashLabel.removeAllActions()
        dashLabel.fontColor = .systemRed

        let left = SKAction.moveBy(x: -5, y: 0, duration: 0.03)
        let right = SKAction.moveBy(x: 10, y: 0, duration: 0.06)
        let center = SKAction.moveBy(x: -5, y: 0, duration: 0.03)
        let shake = SKAction.sequence([left, right, center])
        let tintBack = SKAction.run { [weak self] in
            self?.updateDashHUD()
        }
        dashLabel.run(SKAction.sequence([shake, tintBack]))
    }

    func showNearMissFeedback() {
        nearMissLabel.removeAllActions()
        nearMissLabel.text = "Near Miss +\(nearMissScoreBonus)"
        nearMissLabel.alpha = 1.0
        nearMissLabel.position = CGPoint(x: size.width / 2, y: size.height - 85)
        nearMissLabel.setScale(0.95)

        let rise = SKAction.moveBy(x: 0, y: 14, duration: 0.25)
        let fade = SKAction.fadeOut(withDuration: 0.28)
        let pop = SKAction.scale(to: 1.05, duration: 0.10)
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        nearMissLabel.run(SKAction.group([
            SKAction.sequence([pop, settle]),
            rise,
            fade
        ]))
    }

    func checkNearMisses() {
        guard lastUpdateTime >= nearMissCooldownUntil, !gameOver, !isPausedGame else { return }

        let nearDistance: CGFloat = currentEvent == PhaseEventType.precisionWindow ? 54 : 42
        var triggered = false

        enumerateChildNodes(withName: "enemy") { [weak self] node, stop in
            guard let self, let enemy = node as? Enemy else { return }
            let distance = hypot(enemy.position.x - self.player.position.x, enemy.position.y - self.player.position.y)
            let collisionDistance = max(enemy.frame.width, enemy.frame.height) * 0.45 + max(self.player.frame.width, self.player.frame.height) * 0.32

            if distance > collisionDistance && distance <= nearDistance {
                triggered = true
                stop.pointee = true
            }
        }

        if triggered {
            nearMissCooldownUntil = lastUpdateTime + 0.8
            GameManager.shared.currentScore += nearMissScoreBonus
            scoreLabel.text = "Score: \(GameManager.shared.currentScore)"
            lastDashTime -= nearMissDashReduction
            showNearMissFeedback()
        }
    }

    func togglePauseState(forceResume: Bool = false) {
        if forceResume {
            isPausedGame = false
        } else {
            isPausedGame.toggle()
        }

        self.isPaused = isPausedGame

        if isPausedGame {
            showPauseOverlay()
        } else {
            hidePauseOverlay()
        }
    }

    func showPauseOverlay() {
        hidePauseOverlay()

        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = .black
        overlay.alpha = 0.55
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 90
        overlay.isPaused = false
        addChild(overlay)

        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "Paused"
        title.fontSize = 34
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 20)
        title.zPosition = 91
        title.isPaused = false
        overlay.addChild(title)

        let hint = SKLabelNode(fontNamed: "Menlo")
        hint.text = "Press Space to Resume"
        hint.fontSize = 18
        hint.fontColor = .lightGray
        hint.position = CGPoint(x: 0, y: -20)
        hint.zPosition = 91
        hint.isPaused = false
        overlay.addChild(hint)

        pauseOverlay = overlay
        pauseTitleLabel = title
        pauseHintLabel = hint
    }

    func hidePauseOverlay() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        pauseTitleLabel = nil
        pauseHintLabel = nil
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if gameOver { return }
        let bodies = [contact.bodyA, contact.bodyB]

        if bodies.contains(where: { $0.node?.name == "coin" }) && bodies.contains(where: { $0.node?.name == "player" }) {
            if let coin = bodies.first(where: { $0.node?.name == "coin" })?.node {
                let scoreValue = coin.userData?["scoreValue"] as? Int ?? 5
                let coinValue = coin.userData?["coinValue"] as? Int ?? 1
                coin.removeFromParent()
                let manager = GameManager.shared
                manager.currentScore += scoreValue + coinScoreBonus
                manager.collectCoin(amount: coinValue)
                scoreLabel.text = "Score: \(manager.currentScore)"
                coinLabel.text = "Coins: \(manager.currentCoins)"
            }
            return
        }

        if bodies.contains(where: { $0.node?.name == "enemy" }) && bodies.contains(where: { $0.node?.name == "player" }) {
            if !isInvulnerable,
               let enemyNode = bodies.first(where: { $0.node?.name == "enemy" })?.node as? Enemy {
                playerHit(damage: enemyNode.damage)
            }
        }
    }

    func playerHit(damage: Int) {
        guard !isInvulnerable else { return }
        isInvulnerable = true
        player.setDamageState(canTakeDamage: false)

        playerHealth -= max(1, damage)
        healthLabel.text = "❤️ x \(max(playerHealth, 0))"

        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        let flashing = SKAction.repeat(flash, count: 6)
        let recover = SKAction.run { [weak self] in
            self?.isInvulnerable = false
            self?.player.setDamageState(canTakeDamage: true)
            self?.player.alpha = 1.0
        }
        player.run(SKAction.sequence([flashing, recover]))

        if playerHealth <= 0 {
            triggerGameOver()
        }
    }

    func triggerGameOver() {
        gameOver = true
        isPausedGame = false
        hidePauseOverlay()
        removeAllActions()
        GameManager.shared.updateHighScoreIfNeeded()
        GameManager.shared.updateBestPhaseIfNeeded(currentPhase)
        GameManager.shared.saveGame()

        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontName = "Menlo-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 40)
        addChild(gameOverLabel)

        let finalScoreLabel = SKLabelNode(text: "Score: \(GameManager.shared.currentScore)")
        finalScoreLabel.fontName = "Menlo-Bold"
        finalScoreLabel.fontSize = 30
        finalScoreLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(finalScoreLabel)

        let phaseSummaryLabel = SKLabelNode(text: "Reached Phase: \(currentPhase)")
        phaseSummaryLabel.fontName = "Menlo-Bold"
        phaseSummaryLabel.fontSize = 22
        phaseSummaryLabel.position = CGPoint(x: frame.midX, y: frame.midY - 35)
        addChild(phaseSummaryLabel)

        let continueLabel = SKLabelNode(text: "继续游戏")
        continueLabel.fontName = "Menlo-Bold"
        continueLabel.fontSize = 25
        continueLabel.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        continueLabel.name = "continue"
        addChild(continueLabel)

        let quitLabel = SKLabelNode(text: "返回主菜单")
        quitLabel.fontName = "Menlo-Bold"
        quitLabel.fontSize = 25
        quitLabel.position = CGPoint(x: frame.midX, y: frame.midY - 120)
        quitLabel.name = "quit"
        addChild(quitLabel)
    }


    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        } else {
            lastUpdateTime = currentTime
        }

        guard !gameOver else { return }
        clampPlayerPosition()
        updateDashHUD()
        checkNearMisses()
    }
    // 升级三选一面板消失
    func dismissUpgradeSelection() {
        upgradeOverlay?.removeFromParent()
        upgradeOverlay = nil
        upgradeTitleLabel = nil
        upgradeOptionLabels.removeAll()
        pendingUpgradeOptions.removeAll()
        isUpgradeSelectionActive = false
        self.isPaused = false
    }
}
