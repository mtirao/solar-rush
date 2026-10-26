import Foundation

struct SolarCoreControlState {
    var currentControllerFaction: OrbitType? = nil // Tracks which faction is holding (0,0)
    var consecutiveTurnsHeld: Int = 0
    let turnsRequiredToWin: Int = 3
    
    /// Evaluates if the victory conditions have been met strictly
    var isVictoryAchieved: Bool {
        return consecutiveTurnsHeld >= turnsRequiredToWin
    }
}
