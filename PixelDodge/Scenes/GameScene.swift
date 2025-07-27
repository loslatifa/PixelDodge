//
//  GameScene.swift
//  PixelDodge
//
//  Updated: Integrate player running animation with direction flip and maintain full game functionalities.

import SpriteKit
import GameplayKit

//  GameScene 是主场景类，负责设置游戏界面，包括白色背景、一个蓝色方块作为玩家角色、右上角的分数标签，同时每秒生成一个红色敌人从右侧进入场景向左移动，玩家可点击屏幕控制蓝色方块平滑移动到点击位置。若红色敌人成功越过蓝色方块左侧则判为成功避让，分数加一；敌人和玩家之间没有碰撞逻辑，仅通过位置关系判断得分；场景初始化时构造角色与标签，启动定时器生成敌人；每帧检测所有敌人是否越过玩家位置并更新得分；该实现为基础闪避类游戏框架，适合进一步拓展碰撞检测、失败机制或难度递增等功能。

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: Player!
    var gameOver = false
    var scoreLabel: SKLabelNode!
    var levelLabel: SKLabelNode!
    var healthLabel: SKLabelNode!
    
    // 敌人生成参数与玩家状态控制
    var spawnInterval: Double = 1.0
    var enemySpeed: Double = 5.0
    let scoreToPass = 20
    var playerHealth = 3
    var isPausedGame = false
    var enemyPassCount = 0

    //  didMove(to:) 是场景加载后被系统调用的初始化方法，在此设置黑色背景、关闭重力并启用碰撞委托，读取 GameManager 中保存的当前游戏进度与等级，根据等级动态调整敌人生成频率 spawnInterval 与速度 enemySpeed，创建玩家角色并置于屏幕中心，构建并布局三个 HUD 标签（得分、关卡、生命值）分别居左、中、右显示在顶部，随后启动敌人与金币的周期性生成逻辑 runEnemySpawn() 和 runCoinSpawn()，为游戏开始运行做完整准备。
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        // 加载游戏数据（得分、等级等）
        let manager = GameManager.shared
        manager.loadGame()
        
        // 根据当前关卡调整敌人生成频率与速度（关卡越高越快）
        spawnInterval = max(0.5, 1.0 - Double(manager.currentLevel - 1) * 0.1)
        enemySpeed = max(3.0, 5.0 - Double(manager.currentLevel - 1) * 0.3)

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

        // 添加生命值标签，右上角显示心形和剩余血量
        healthLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        healthLabel.fontSize = 20
        healthLabel.fontColor = .white
        healthLabel.horizontalAlignmentMode = .right
        healthLabel.position = CGPoint(x: size.width - 20, y: size.height - 30)
        healthLabel.text = "❤️ x \(playerHealth)"
        addChild(healthLabel)
        
        // 启动敌人和金币的生成机制
        runEnemySpawn()
        runCoinSpawn()
    }

    func runEnemySpawn() {
        let spawn = SKAction.run { [weak self] in self?.spawnEnemy() }
        let wait = SKAction.wait(forDuration: spawnInterval)
        let spawnForever = SKAction.repeatForever(SKAction.sequence([spawn, wait]))
        run(spawnForever, withKey: "spawnEnemies")
    }

    func runCoinSpawn() {
        let spawn = SKAction.run { [weak self] in self?.spawnCoin() }
        let wait = SKAction.wait(forDuration: 5.0)
        let spawnForever = SKAction.repeatForever(SKAction.sequence([spawn, wait]))
        run(spawnForever, withKey: "spawnCoins")
    }

    func spawnEnemy() {
        let speed = enemySpeed + Double.random(in: -1...1)
        let enemy = Enemy(
            position: CGPoint(x: frame.maxX, y: CGFloat.random(in: 0...size.height)),
            moveDistance: size.width + 40,
            moveDuration: speed,
            onPassed: { [weak self] in self?.incrementScore() }
        )
        addChild(enemy)
    }

    func spawnCoin() {
        let coin = SKSpriteNode(color: .yellow, size: CGSize(width: 20, height: 20))
        coin.name = "coin"
        coin.position = CGPoint(x: CGFloat.random(in: 40...(size.width - 40)), y: CGFloat.random(in: 40...(size.height - 40)))
        coin.zPosition = 1
        addChild(coin)

        let wait = SKAction.wait(forDuration: 6.0)
        let remove = SKAction.removeFromParent()
        coin.run(SKAction.sequence([wait, remove]))
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
        if event.keyCode == 53 { // ESC to pause
            isPausedGame.toggle()
            self.isPaused = isPausedGame
        } else if event.keyCode == 49 { // Space to resume
            isPausedGame = false
            self.isPaused = false
        }

        guard !gameOver else { return }
        let moveAmount: CGFloat = 20
        switch event.keyCode {
        case 0x7E: // Up
            player.position.y += moveAmount
        case 0x7D: // Down
            player.position.y -= moveAmount
        case 0x7B: // Left
            player.position.x -= moveAmount
            player.xScale = -1 // Flip to face left
        case 0x7C: // Right
            player.position.x += moveAmount
            player.xScale = 1 // Face right
        default: break
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if gameOver { return }
        let bodies = [contact.bodyA, contact.bodyB]

        if bodies.contains(where: { $0.node?.name == "coin" }) && bodies.contains(where: { $0.node?.name == "player" }) {
            if let coin = bodies.first(where: { $0.node?.name == "coin" })?.node {
                coin.removeFromParent()
                GameManager.shared.currentScore += 5
                scoreLabel.text = "Score: \(GameManager.shared.currentScore)"
            }
            return
        }

        if bodies.contains(where: { $0.node?.name == "enemy" }) && bodies.contains(where: { $0.node?.name == "player" }) {
            playerHit()
        }
    }

    func playerHit() {
        playerHealth -= 1
        healthLabel.text = "❤️ x \(playerHealth)"

        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        player.run(SKAction.repeat(flash, count: 3))

        if playerHealth <= 0 {
            triggerGameOver()
        }
    }

    func triggerGameOver() {
        gameOver = true
        removeAllActions()
        GameManager.shared.updateHighScoreIfNeeded()
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

        let continueLabel = SKLabelNode(text: "继续游戏")
        continueLabel.fontName = "Menlo-Bold"
        continueLabel.fontSize = 25
        continueLabel.position = CGPoint(x: frame.midX, y: frame.midY - 40)
        continueLabel.name = "continue"
        addChild(continueLabel)

        let quitLabel = SKLabelNode(text: "返回主菜单")
        quitLabel.fontName = "Menlo-Bold"
        quitLabel.fontSize = 25
        quitLabel.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        quitLabel.name = "quit"
        addChild(quitLabel)
    }

    override func mouseDown(with event: NSEvent) {
        if gameOver {
            let location = event.location(in: self)
            let nodes = nodes(at: location)
            for node in nodes {
                if node.name == "continue" {
                    let nextScene = GameScene(size: self.size)
                    nextScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(nextScene, transition: transition)
                } else if node.name == "quit" {
                    let startScene = StartScene(size: self.size)
                    startScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(startScene, transition: transition)
                }
            }
        }
    }
}
