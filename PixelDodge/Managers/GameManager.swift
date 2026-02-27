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
    var currentCoins: Int = 0
    var totalCoins: Int = 0
    var bestPhase: Int = 1
    
    // MARK: - 存档 Keys
    private let savedLevelKey = "SavedLevel"
    private let savedScoreKey = "SavedScore"
    private let highScoreKey = "HighScore"
    private let unlockedLevelKey = "UnlockedLevel"
    private let currentCoinsKey = "CurrentCoins"
    private let totalCoinsKey = "TotalCoins"
    private let bestPhaseKey = "BestPhase"
    
    // MARK: - 存档与加载
    func saveGame() {
        UserDefaults.standard.set(currentLevel, forKey: savedLevelKey)
        UserDefaults.standard.set(currentScore, forKey: savedScoreKey)
        UserDefaults.standard.set(highScore, forKey: highScoreKey)
        UserDefaults.standard.set(unlockedLevel, forKey: unlockedLevelKey)
        UserDefaults.standard.set(currentCoins, forKey: currentCoinsKey)
        UserDefaults.standard.set(totalCoins, forKey: totalCoinsKey)
        UserDefaults.standard.set(bestPhase, forKey: bestPhaseKey)
    }
    
    func loadGame() {
        currentLevel = UserDefaults.standard.integer(forKey: savedLevelKey)
        if currentLevel == 0 { currentLevel = 1 } // 首次运行修正
        currentScore = UserDefaults.standard.integer(forKey: savedScoreKey)
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
        unlockedLevel = max(UserDefaults.standard.integer(forKey: unlockedLevelKey), 1)
        currentCoins = max(UserDefaults.standard.integer(forKey: currentCoinsKey), 0)
        totalCoins = max(UserDefaults.standard.integer(forKey: totalCoinsKey), 0)
        bestPhase = max(UserDefaults.standard.integer(forKey: bestPhaseKey), 1)
    }
    
    func clearSave() {
        UserDefaults.standard.removeObject(forKey: savedLevelKey)
        UserDefaults.standard.removeObject(forKey: savedScoreKey)
        UserDefaults.standard.removeObject(forKey: highScoreKey)
        UserDefaults.standard.removeObject(forKey: unlockedLevelKey)
        UserDefaults.standard.removeObject(forKey: currentCoinsKey)
        UserDefaults.standard.removeObject(forKey: totalCoinsKey)
        UserDefaults.standard.removeObject(forKey: bestPhaseKey)

        currentLevel = 1
        currentScore = 0
        highScore = 0
        unlockedLevel = 1
        currentCoins = 0
        totalCoins = 0
        bestPhase = 1
        saveGame()
    }
    
    // MARK: - 高分检查
    func updateHighScoreIfNeeded() {
        if currentScore > highScore {
            highScore = currentScore
            UserDefaults.standard.set(highScore, forKey: highScoreKey)
        }
    }
    
    // MARK: - 阶段记录
    func updateBestPhaseIfNeeded(_ phase: Int) {
        if phase > bestPhase {
            bestPhase = phase
            UserDefaults.standard.set(bestPhase, forKey: bestPhaseKey)
        }
    }

    // MARK: - 金币记录
    func collectCoin(amount: Int = 1) {
        guard amount > 0 else { return }
        currentCoins += amount
        totalCoins += amount
        UserDefaults.standard.set(currentCoins, forKey: currentCoinsKey)
        UserDefaults.standard.set(totalCoins, forKey: totalCoinsKey)
    }

    func spendCoins(amount: Int) -> Bool {
        guard amount > 0, currentCoins >= amount else { return false }
        currentCoins -= amount
        UserDefaults.standard.set(currentCoins, forKey: currentCoinsKey)
        return true
    }

    func resetRunState() {
        currentScore = 0
        currentCoins = 0
        currentLevel = 1
    }
    
    // MARK: - 解锁关卡
    func unlockNextLevel() {
        unlockedLevel = max(unlockedLevel, currentLevel + 1)
        UserDefaults.standard.set(unlockedLevel, forKey: unlockedLevelKey)
    }
}
