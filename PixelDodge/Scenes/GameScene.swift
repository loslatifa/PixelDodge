//
//  GameScene.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/6.
//
// GameScene.swift 完整版（已集成模块化 Player/Enemy，使用 GameManager 管理状态）

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: Player!
    var gameOver = false
    var scoreLabel: SKLabelNode!
    var levelLabel: SKLabelNode!
    var spawnInterval: Double = 1.0
    var enemySpeed: Double = 5.0
    let scoreToPass = 20

    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero

        let manager = GameManager.shared
        manager.loadGame()

        spawnInterval = max(0.5, 1.0 - Double(manager.currentLevel - 1) * 0.1)
        enemySpeed = max(3.0, 5.0 - Double(manager.currentLevel - 1) * 0.3)

        player = Player(position: CGPoint(x: frame.midX, y: frame.midY))
        addChild(player)

        scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: 20, y: size.height - 20)
        scoreLabel.text = "Score: \(manager.currentScore)"
        addChild(scoreLabel)

        levelLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        levelLabel.fontSize = 24
        levelLabel.fontColor = .white
        levelLabel.horizontalAlignmentMode = .right
        levelLabel.verticalAlignmentMode = .top
        levelLabel.position = CGPoint(x: size.width - 20, y: size.height - 20)
        levelLabel.text = "Level: \(manager.currentLevel)"
        addChild(levelLabel)

        let spawn = SKAction.run { [weak self] in self?.spawnEnemy() }
        let spawnForever = SKAction.repeatForever(SKAction.sequence([spawn, SKAction.wait(forDuration: spawnInterval)]))
        run(spawnForever, withKey: "spawnEnemies")
    }

    func spawnEnemy() {
        let enemy = Enemy(
            position: CGPoint(x: frame.maxX, y: CGFloat.random(in: 0...size.height)),
            moveDistance: size.width + 20,
            moveDuration: enemySpeed,
            onPassed: { [weak self] in self?.incrementScore() }
        )
        addChild(enemy)
    }

    func incrementScore() {
        guard !gameOver else { return }
        let manager = GameManager.shared
        manager.currentScore += 1
        scoreLabel.text = "Score: \(manager.currentScore)"
        if manager.currentScore >= scoreToPass {
            proceedToNextLevel()
        }
    }

    func proceedToNextLevel() {
        let manager = GameManager.shared
        manager.currentLevel += 1
        manager.currentScore = 0
        manager.unlockNextLevel()
        manager.saveGame()

        let nextLevelScene = GameScene(size: self.size)
        nextLevelScene.scaleMode = .resizeFill
        let transition = SKTransition.flipHorizontal(withDuration: 1.0)
        view?.presentScene(nextLevelScene, transition: transition)
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

        let manager = GameManager.shared
        manager.updateHighScoreIfNeeded()
        manager.saveGame()

        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontName = "Menlo-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 40)
        addChild(gameOverLabel)

        let finalScoreLabel = SKLabelNode(text: "Score: \(manager.currentScore)")
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
