//
//  ViewController.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/6.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.skView {
            // 直接使用 GameScene 类而非加载 .sks 文件
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill

            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
}
