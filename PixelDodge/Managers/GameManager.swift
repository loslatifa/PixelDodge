//
//  GameManager.swift
//  PixelDodge
//
//  Created by Kirsch Garrix on 2025/7/7.
//

// GameManager.swift
// 管理 PixelDodge 全局状态与存档

import Foundation

class GameManager {
    static let shared = GameManager()
    
    private init() {
        loadGame()
    }
    
    // MARK: - 状态属性
    var currentLevel: Int = 1
    var currentScore: Int = 0
    var highScore: Int = 0
    var unlockedLevel: Int = 1
    
    // MARK: - 存档 Keys
    private let savedLevelKey = "SavedLevel"
    private let savedScoreKey = "SavedScore"
    private let highScoreKey = "HighScore"
    private let unlockedLevelKey = "UnlockedLevel"
    
    // MARK: - 存档与加载
    func saveGame() {
        UserDefaults.standard.set(currentLevel, forKey: savedLevelKey)
        UserDefaults.standard.set(currentScore, forKey: savedScoreKey)
        UserDefaults.standard.set(highScore, forKey: highScoreKey)
        UserDefaults.standard.set(unlockedLevel, forKey: unlockedLevelKey)
    }
    
    func loadGame() {
        currentLevel = UserDefaults.standard.integer(forKey: savedLevelKey)
        if currentLevel == 0 { currentLevel = 1 } // 首次运行修正
        currentScore = UserDefaults.standard.integer(forKey: savedScoreKey)
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
        unlockedLevel = max(UserDefaults.standard.integer(forKey: unlockedLevelKey), 1)
    }
    
    func clearSave() {
        UserDefaults.standard.removeObject(forKey: savedLevelKey)
        UserDefaults.standard.removeObject(forKey: savedScoreKey)
        currentLevel = 1
        currentScore = 0
        saveGame()
    }
    
    // MARK: - 高分检查
    func updateHighScoreIfNeeded() {
        if currentScore > highScore {
            highScore = currentScore
            UserDefaults.standard.set(highScore, forKey: highScoreKey)
        }
    }
    
    // MARK: - 解锁关卡
    func unlockNextLevel() {
        unlockedLevel = max(unlockedLevel, currentLevel + 1)
        UserDefaults.standard.set(unlockedLevel, forKey: unlockedLevelKey)
    }
}
