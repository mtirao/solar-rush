import Foundation

/// Defines the three asymmetric alien civilizations competing in Solar Rush
enum FactionType {
    case chironSwarm     // Organic, rapid vector movement bonuses
    case silicateNexus   // Computational AI, structural resource alignment multipliers
    case orionScavenger  // Industrial raiders, combat salvage extraction mechanics
}

/// Profile structure tracking active player faction telemetry configurations
struct PlayerProfile {
    let faction: FactionType
    var factionLevel: Int = 1
}
