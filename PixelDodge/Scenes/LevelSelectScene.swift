//
//  LevelSelectScene.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//
// LevelSelectScene.swift - 改进版：
// 1) 每行显示 4 个关卡但减少空隙以避免被截断。
// 2) 支持触控板滑动滚动。
// 3) 支持全屏自适应放大显示。

import SpriteKit

class LevelSelectScene: SKScene {
    let contentNode = SKNode()
    var lastTouchPosition: CGPoint?
    var unlockedLevel: Int = 1
    let itemsPerRow = 4
    let paddingX: CGFloat = 40
    let rowSpacing: CGFloat = 60
    var startY: CGFloat = 0
    var statsLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        backgroundColor = .black
        addChild(contentNode)

        unlockedLevel = GameManager.shared.unlockedLevel

        let titleLabel = SKLabelNode(text: "选择关卡")
        titleLabel.fontName = "Menlo-Bold"
        titleLabel.fontSize = 40
        titleLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 80)
        contentNode.addChild(titleLabel)

        statsLabel = SKLabelNode(text: "最高分: \(GameManager.shared.highScore)   最佳阶段: \(GameManager.shared.bestPhase)   累计金币: \(GameManager.shared.totalCoins)")
        statsLabel.fontName = "Menlo"
        statsLabel.fontSize = 16
        statsLabel.fontColor = .lightGray
        statsLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 115)
        contentNode.addChild(statsLabel)

        let spacingX = (frame.width - paddingX * 2) / CGFloat(itemsPerRow - 1)
        startY = frame.maxY - 180

        for i in 0..<unlockedLevel {
            let row = i / itemsPerRow
            let col = i % itemsPerRow
            let x = paddingX + CGFloat(col) * spacingX
            let y = startY - CGFloat(row) * rowSpacing

            let levelLabel = SKLabelNode(text: "关卡 \(i + 1)")
            levelLabel.fontName = "Menlo-Bold"
            levelLabel.fontSize = 25
            levelLabel.position = CGPoint(x: x, y: y)
            levelLabel.name = "level\(i + 1)"
            contentNode.addChild(levelLabel)
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

        let hintLabel = SKLabelNode(text: "滚轮或拖动可滚动页面")
        hintLabel.fontName = "Menlo"
        hintLabel.fontSize = 14
        hintLabel.fontColor = .darkGray
        hintLabel.position = CGPoint(x: frame.midX, y: 115)
        addChild(hintLabel)
    }

    // 支持触控板和鼠标滚轮滑动滚动
    override func scrollWheel(with event: NSEvent) {
        let delta = event.scrollingDeltaY * 1.5 // 放大灵敏度以支持触控板流畅滑动
        adjustContentPosition(by: delta)
    }

    func adjustContentPosition(by delta: CGFloat) {
        let rowCount = max((unlockedLevel + itemsPerRow - 1) / itemsPerRow, 1)
        let contentHeight = 220 + CGFloat(rowCount - 1) * rowSpacing + 80
        let newY = contentNode.position.y + delta
        let maxOffset: CGFloat = 0
        let minOffset = -max(contentHeight - size.height + 140, 0)
        contentNode.position.y = min(max(newY, minOffset), maxOffset)
    }

    override func mouseDown(with event: NSEvent) {
        lastTouchPosition = event.location(in: self)
        let location = event.location(in: self)
        let nodes = nodes(at: location)

        for node in nodes {
            if let nodeName = node.name {
                if nodeName.starts(with: "level") {
                    let levelNumber = Int(nodeName.replacingOccurrences(of: "level", with: "")) ?? 1
                    let manager = GameManager.shared
                    manager.resetRunState()
                    manager.currentLevel = levelNumber
                    manager.saveGame()
                    let gameScene = GameScene(size: self.size)
                    gameScene.scaleMode = .resizeFill // 全屏放大自适应
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

    override func mouseDragged(with event: NSEvent) {
        guard let lastPos = lastTouchPosition else { return }
        let currentPos = event.location(in: self)
        let dy = currentPos.y - lastPos.y
        adjustContentPosition(by: dy)
        lastTouchPosition = currentPos
    }

    override func mouseUp(with event: NSEvent) {
        lastTouchPosition = nil
    }

    override func update(_ currentTime: TimeInterval) {
        statsLabel?.text = "最高分: \(GameManager.shared.highScore)   最佳阶段: \(GameManager.shared.bestPhase)   累计金币: \(GameManager.shared.totalCoins)"
    }
}
