import Foundation
import Observation

@Observable
class StardustManager {
    // Shared singleton instance to access currency safely from any view or scene
    static let shared = StardustManager()
    
    // Player's active financial treasury account bank
    private(set) var currentStardust: Int = 400 // Base starting balance
    
    private init() {}
    
    /// Adds stardust credits to the active player balance bank
    func creditStardust(amount: Int) {
        guard amount > 0 else { return }
        currentStardust += amount
        print("💰 Economy: Credited \(amount) Stardust. New balance: \(currentStardust)")
    }
    
    /// Deducts stardust credits if the player has sufficient funds. Returns success status.
    func debitStardust(amount: Int) -> Bool {
        guard amount > 0, currentStardust >= amount else { return false }
        currentStardust -= amount
        print("💸 Economy: Debited \(amount) Stardust. Remaining balance: \(currentStardust)")
        return true
    }
    
    /// Evaluates if an operation is affordable before executing UI triggers
    func isAffordable(cost: Int) -> Bool {
        return currentStardust >= cost
    }
}
