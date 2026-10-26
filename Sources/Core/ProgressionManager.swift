import Foundation
import Observation

@Observable
class ProgressionManager {
    static let shared = ProgressionManager()
    
    // Persistent profile statistics tracking
    private(set) var totalStardustTokens: Int = 250 // Account lifetime Star Fragments balance
    private(set) var currentAccountXP: Int = 1200
    private(set) var accountLevel: Int = 1
    
    private let xpPerLevelThreshold: Int = 2000
    
    private init() {}
    
    /// Algorithmic reward matrix calculating yields based on match performance telemetry
    func calculateMatchRewards(planetsCaptured: Int, enemyShipsVaporized: Int, turnsResisted: Int, isVictory: Bool) -> (fragments: Int, xp: Int) {
        let baseFragments = isVictory ? 150 : 50
        let baseXP = isVictory ? 500 : 150
        
        // Performance multiplier gains
        let planetBonus = planetsCaptured * 35
        let combatBonus = enemyShipsVaporized * 15
        let survivalBonus = turnsResisted * 10
        
        let calculatedFragments = baseFragments + planetBonus + combatBonus
        let calculatedXP = baseXP + planetBonus + combatBonus + survivalBonus
        
        return (calculatedFragments, calculatedXP)
    }
    
    /// Commits the newly earned resources into the profile database structures
    func commitEarnedRewards(fragments: Int, xp: Int) {
        self.totalStardustTokens += fragments
        self.currentAccountXP += xp
        
        // Level Up evaluation loop wrapper
        while self.currentAccountXP >= xpPerLevelThreshold {
            self.currentAccountXP -= xpPerLevelThreshold
            self.accountLevel += 1
            print("🎉 Account Level Up! New Level: \(accountLevel)")
        }
    }
}
