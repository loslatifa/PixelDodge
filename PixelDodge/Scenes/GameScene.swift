//
//  GameScene.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/6.
//

// GameScene.swift for PixelDodge (macOS Pixel Game)
import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var gameOver = false
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        player = SKSpriteNode(color: .green, size: CGSize(width: 32, height: 32))
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        player.texture?.filteringMode = .nearest
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = 0x1 << 0
        player.physicsBody?.contactTestBitMask = 0x1 << 1
        player.physicsBody?.collisionBitMask = 0
        addChild(player)
        
        let spawn = SKAction.run { [weak self] in self?.spawnEnemy() }
        let spawnForever = SKAction.repeatForever(SKAction.sequence([spawn, SKAction.wait(forDuration: 1.0)]))
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
        
        let move = SKAction.moveBy(x: -size.width - 20, y: 0, duration: 5)
        let remove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([move, remove]))
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
        
        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontName = "Menlo-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 20)
        addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(text: "点击重新开始")
        restartLabel.fontName = "Menlo-Bold"
        restartLabel.fontSize = 25
        restartLabel.position = CGPoint(x: frame.midX, y: frame.midY - 30)
        restartLabel.name = "restart"
        addChild(restartLabel)
    }
    
    override func mouseDown(with event: NSEvent) {
        if gameOver {
            let location = event.location(in: self)
            let nodes = nodes(at: location)
            for node in nodes {
                if node.name == "restart" {
                    let newScene = GameScene(size: self.size)
                    newScene.scaleMode = .resizeFill
                    let transition = SKTransition.fade(withDuration: 1.0)
                    view?.presentScene(newScene, transition: transition)
                }
            }
        }
    }
}
