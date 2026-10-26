import Foundation

/// Defines the three primary ship classifications operating in Solar Rush
enum ShipClass {
    case fighter      // Light, fast anti-bomber escort
    case frigate      // Medium armored fleet defender
    case bomber       // Heavy structural siege vessel
    
    /// Default resource deployment cost in Stardust units
    var stardustCost: Int {
        switch self {
        case .fighter: return 100
        case .frigate: return 250
        case .bomber:  return 400
        }
    }
}

/// Structural entity monitoring current health and attack thresholds per vessel instance
struct ShipUnit {
    let id: UUID = UUID()
    let type: ShipClass
    var currentHealth: Float
    
    init(type: ShipClass) {
        self.type = type
        switch type {
        case .fighter: self.currentHealth = 50.0
        case .frigate: self.currentHealth = 150.0
        case .bomber:  self.currentHealth = 250.0
        }
    }
    
    /// Base damage rating dealt to target parameters per round execution
    var attackDamage: Float {
        switch type {
        case .fighter: return 15.0
        case .frigate: return 35.0
        case .bomber:  return 60.0
        }
    }
}

/// Collection layer keeping telemetry logs of active units stationed over planetary orbits
struct CombatSquadron {
    var ownerFaction: OrbitType // Assigned dynamically based on initial planet track configurations
    var ships: [ShipUnit] = []
    
    /// Utility property mapping total count of functional assets grouped by class
    func count(of shipClass: ShipClass) -> Int {
        return ships.filter { $0.type == shipClass && $0.currentHealth > 0 }.count
    }
}
