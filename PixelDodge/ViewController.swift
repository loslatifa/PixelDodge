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
            let scene = StartScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill

            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
}
