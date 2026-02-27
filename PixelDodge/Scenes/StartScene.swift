//
//  StartScene.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//
// StartScene.swift
// PixelDodge

// StartScene.swift 使用 GameManager 重构进度和最高分管理

import SpriteKit

//开始场景
class StartScene: SKScene {
    var statsLabel: SKLabelNode!
    override func didMove(to view: SKView) {
        backgroundColor = .black
        GameManager.shared.loadGame()

        let titleLabel = SKLabelNode(text: "Pixel Dodge")
        titleLabel.fontName = "Menlo-Bold"
        titleLabel.fontSize = 50
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        addChild(titleLabel)

        let continueLabel = SKLabelNode(text: "继续游戏")
        continueLabel.fontName = "Menlo-Bold"
        continueLabel.fontSize = 30
        continueLabel.position = CGPoint(x: frame.midX, y: frame.midY + 30)
        continueLabel.name = "continue"
        addChild(continueLabel)

        let startLabel = SKLabelNode(text: "开始新游戏")
        startLabel.fontName = "Menlo-Bold"
        startLabel.fontSize = 30
        startLabel.position = CGPoint(x: frame.midX, y: frame.midY - 30)
        startLabel.name = "start"
        addChild(startLabel)

        let selectLevelLabel = SKLabelNode(text: "选择关卡")
        selectLevelLabel.fontName = "Menlo-Bold"
        selectLevelLabel.fontSize = 30
        selectLevelLabel.position = CGPoint(x: frame.midX, y: frame.midY - 90)
        selectLevelLabel.name = "selectLevel"
        addChild(selectLevelLabel)

        statsLabel = SKLabelNode(text: "最高分: \(GameManager.shared.highScore)   最佳阶段: \(GameManager.shared.bestPhase)   累计金币: \(GameManager.shared.totalCoins)")
        statsLabel.fontName = "Menlo"
        statsLabel.fontSize = 18
        statsLabel.fontColor = .lightGray
        statsLabel.position = CGPoint(x: frame.midX, y: frame.midY - 145)
        statsLabel.name = "statsLabel"
        addChild(statsLabel)
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = nodes(at: location)

        for node in nodes {
            if node.name == "continue" {
                let manager = GameManager.shared
                manager.loadGame()
                let gameScene = GameScene(size: self.size)
                gameScene.scaleMode = .resizeFill
                let transition = SKTransition.fade(withDuration: 1.0)
                view?.presentScene(gameScene, transition: transition)
            } else if node.name == "start" {
                let manager = GameManager.shared
                manager.resetRunState()
                manager.currentLevel = 1
                manager.saveGame()
                let gameScene = GameScene(size: self.size)
                gameScene.scaleMode = .resizeFill
                let transition = SKTransition.fade(withDuration: 1.0)
                view?.presentScene(gameScene, transition: transition)
            } else if node.name == "selectLevel" {
                let levelSelectScene = LevelSelectScene(size: self.size)
                levelSelectScene.scaleMode = .resizeFill
                let transition = SKTransition.fade(withDuration: 1.0)
                view?.presentScene(levelSelectScene, transition: transition)
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        statsLabel?.text = "最高分: \(GameManager.shared.highScore)   最佳阶段: \(GameManager.shared.bestPhase)   累计金币: \(GameManager.shared.totalCoins)"
    }
}
