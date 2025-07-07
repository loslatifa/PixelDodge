//
//  StartScene.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//
import SpriteKit

class StartScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let titleLabel = SKLabelNode(text: "Pixel Dodge")
        titleLabel.fontName = "Menlo-Bold"
        titleLabel.fontSize = 50
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + 60)
        addChild(titleLabel)
        
        let startLabel = SKLabelNode(text: "点击开始游戏")
        startLabel.fontName = "Menlo-Bold"
        startLabel.fontSize = 30
        startLabel.position = CGPoint(x: frame.midX, y: frame.midY - 20)
        startLabel.name = "startGame"
        addChild(startLabel)
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "startGame" {
                let gameScene = GameScene(size: self.size)
                gameScene.scaleMode = .resizeFill
                let transition = SKTransition.fade(withDuration: 1.0)
                view?.presentScene(gameScene, transition: transition)
            }
        }
    }
}

