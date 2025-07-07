//
//  LevelSelectScene.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//

import SpriteKit

class LevelSelectScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let titleLabel = SKLabelNode(text: "选择关卡")
        titleLabel.fontName = "Menlo-Bold"
        titleLabel.fontSize = 40
        titleLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 80)
        addChild(titleLabel)
        
        let unlockedLevel = UserDefaults.standard.integer(forKey: "UnlockedLevel")
        let maxLevel = max(unlockedLevel, 1)
        
        for i in 1...maxLevel {
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
        backLabel.position = CGPoint(x: frame.midX, y: 60)
        backLabel.name = "back"
        addChild(backLabel)
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = nodes(at: location)
        
        for node in nodes {
            if let nodeName = node.name {
                if nodeName.starts(with: "level") {
                    let levelNumber = Int(nodeName.replacingOccurrences(of: "level", with: "")) ?? 1
                    let gameScene = GameScene(size: self.size)
                    gameScene.level = levelNumber
                    gameScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(gameScene, transition: transition)
                } else if nodeName == "back" {
                    let startScene = StartScene(size: self.size)
                    startScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(startScene, transition: transition)
                }
            }
        }
    }
}
