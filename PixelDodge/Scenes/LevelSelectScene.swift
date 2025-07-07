//
//  LevelSelectScene.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//

// LevelSelectScene.swift 使用 GameManager 重构并添加“清除存档”按钮

import SpriteKit

class LevelSelectScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .black

        let titleLabel = SKLabelNode(text: "选择关卡")
        titleLabel.fontName = "Menlo-Bold"
        titleLabel.fontSize = 40
        titleLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 80)
        addChild(titleLabel)

        let unlockedLevel = GameManager.shared.unlockedLevel

        for i in 1...unlockedLevel {
            let levelLabel = SKLabelNode(text: "关卡 \(i)")
            levelLabel.fontName = "Menlo-Bold"
            levelLabel.fontSize = 30
            levelLabel.position = CGPoint(x: frame.midX, y: frame.maxY - CGFloat(150 + i * 50))
            levelLabel.name = "level\(i)"
            addChild(levelLabel)
        }

        let backLabel = SKLabelNode(text: "返回主菜单")
        backLabel.fontName = "Menlo-Bold"
        backLabel.fontSize = 25
        backLabel.position = CGPoint(x: frame.midX, y: 80)
        backLabel.name = "back"
        addChild(backLabel)

        let clearSaveLabel = SKLabelNode(text: "清除存档")
        clearSaveLabel.fontName = "Menlo-Bold"
        clearSaveLabel.fontSize = 25
        clearSaveLabel.position = CGPoint(x: frame.midX, y: 40)
        clearSaveLabel.name = "clearSave"
        addChild(clearSaveLabel)
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = nodes(at: location)

        for node in nodes {
            if let nodeName = node.name {
                if nodeName.starts(with: "level") {
                    let levelNumber = Int(nodeName.replacingOccurrences(of: "level", with: "")) ?? 1
                    let manager = GameManager.shared
                    manager.currentLevel = levelNumber
                    manager.currentScore = 0
                    manager.saveGame()

                    let gameScene = GameScene(size: self.size)
                    gameScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(gameScene, transition: transition)
                } else if nodeName == "back" {
                    let startScene = StartScene(size: self.size)
                    startScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(startScene, transition: transition)
                } else if nodeName == "clearSave" {
                    GameManager.shared.clearSave()
                    let refreshedScene = LevelSelectScene(size: self.size)
                    refreshedScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 0.5)
                    view?.presentScene(refreshedScene, transition: transition)
                }
            }
        }
    }
}
