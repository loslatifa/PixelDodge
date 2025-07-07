//
//  GameScene.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/6.
//
// GameScene.swift 最终版（支持存档功能）

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var gameOver = false
    var scoreLabel: SKLabelNode!
    var levelLabel: SKLabelNode!
    var score = 0
    var level = 1
    var spawnInterval: Double = 1.0
    var enemySpeed: Double = 5.0
    let scoreToPass = 20

    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero

        spawnInterval = max(0.5, 1.0 - Double(level - 1) * 0.1)
        enemySpeed = max(3.0, 5.0 - Double(level - 1) * 0.3)

        player = SKSpriteNode(color: .green, size: CGSize(width: 32, height: 32))
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        player.texture?.filteringMode = .nearest
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = 0x1 << 0
        player.physicsBody?.contactTestBitMask = 0x1 << 1
        player.physicsBody?.collisionBitMask = 0
        addChild(player)

        scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: 20, y: size.height - 20)
        scoreLabel.text = "Score: \(score)"
        addChild(scoreLabel)

        levelLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        levelLabel.fontSize = 24
        levelLabel.fontColor = .white
        levelLabel.horizontalAlignmentMode = .right
        levelLabel.verticalAlignmentMode = .top
        levelLabel.position = CGPoint(x: size.width - 20, y: size.height - 20)
        levelLabel.text = "Level: \(level)"
        addChild(levelLabel)

        let spawn = SKAction.run { [weak self] in self?.spawnEnemy() }
        let spawnForever = SKAction.repeatForever(SKAction.sequence([spawn, SKAction.wait(forDuration: spawnInterval)]))
        run(spawnForever, withKey: "spawnEnemies")
    }

    func spawnEnemy() {
        let enemy = SKSpriteNode(color: .red, size: CGSize(width: 16, height: 16))
        enemy.position = CGPoint(x: frame.maxX, y: CGFloat.random(in: 0...size.height))
        enemy.texture?.filteringMode = .nearest
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.categoryBitMask = 0x1 << 1
        enemy.physicsBody?.contactTestBitMask = 0x1 << 0
        enemy.physicsBody?.collisionBitMask = 0
        addChild(enemy)

        let move = SKAction.moveBy(x: -size.width - 20, y: 0, duration: enemySpeed)
        let increment = SKAction.run { [weak self] in self?.incrementScore() }
        let remove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([move, increment, remove]))
    }

    func incrementScore() {
        guard !gameOver else { return }
        score += 1
        scoreLabel.text = "Score: \(score)"
        if score >= scoreToPass {
            proceedToNextLevel()
        }
    }

    func proceedToNextLevel() {
        UserDefaults.standard.set(level + 1, forKey: "UnlockedLevel")
        UserDefaults.standard.set(0, forKey: "SavedScore")
        UserDefaults.standard.set(level + 1, forKey: "SavedLevel")
        let nextLevelScene = GameScene(size: self.size)
        nextLevelScene.level = self.level + 1
        nextLevelScene.scaleMode = .resizeFill
        nextLevelScene.spawnInterval = max(0.3, self.spawnInterval - 0.1)
        nextLevelScene.enemySpeed = max(2.0, self.enemySpeed - 0.3)
        let transition = SKTransition.flipHorizontal(withDuration: 1.0)
        self.view?.presentScene(nextLevelScene, transition: transition)
    }

    override func keyDown(with event: NSEvent) {
        guard !gameOver else { return }
        let moveAmount: CGFloat = 20
        switch event.keyCode {
        case 0x7E: player.position.y += moveAmount
        case 0x7D: player.position.y -= moveAmount
        case 0x7B: player.position.x -= moveAmount
        case 0x7C: player.position.x += moveAmount
        default: break
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if gameOver { return }
        gameOver = true
        removeAction(forKey: "spawnEnemies")

        // 存档当前进度
        UserDefaults.standard.set(level, forKey: "SavedLevel")
        UserDefaults.standard.set(score, forKey: "SavedScore")

        // 更新最高分
        let previousHighScore = UserDefaults.standard.integer(forKey: "HighScore")
        if score > previousHighScore {
            UserDefaults.standard.set(score, forKey: "HighScore")
        }

        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontName = "Menlo-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 40)
        addChild(gameOverLabel)

        let finalScoreLabel = SKLabelNode(text: "Score: \(score)")
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

        let quitLabel = SKLabelNode(text: "退出到主菜单")
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
                    let savedLevel = UserDefaults.standard.integer(forKey: "SavedLevel")
                    let savedScore = UserDefaults.standard.integer(forKey: "SavedScore")
                    let gameScene = GameScene(size: self.size)
                    gameScene.level = savedLevel > 0 ? savedLevel : 1
                    gameScene.score = savedScore
                    gameScene.scaleMode = .resizeFill
                    view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 1.0))
                } else if node.name == "quit" {
                    let startScene = StartScene(size: self.size)
                    startScene.scaleMode = .resizeFill
                    view?.presentScene(startScene, transition: SKTransition.fade(withDuration: 1.0))
                }
            }
        }
    }
}
