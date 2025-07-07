//
//  ViewController.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/6.
//
// ViewController.swift - 立即适配全屏，自动重载当前场景

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {
    @IBOutlet var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.skView {
            let scene = StartScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            view.presentScene(scene)

            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: nil
        )
    }

    @objc func windowDidResize(notification: Notification) {
        if let skView = self.skView, let currentScene = skView.scene {
            let sceneType = type(of: currentScene)
            let newScene = sceneType.init(size: skView.bounds.size)
            newScene.scaleMode = .resizeFill
            skView.presentScene(newScene)
        }
    }
}
