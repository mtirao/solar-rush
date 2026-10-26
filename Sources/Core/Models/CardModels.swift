import Foundation

/// Defines the unique tactical modification effects for combat maneuvers
enum CardEffectType {
    case shieldBoost     // Absorbs incoming damage in Round 1
    case fighterFrenzy   // Double damage for Fighters in Round 1
    case statisOrb       // Freezes target systems
}

struct CombatCard: Identifiable, Equatable {
    let id: UUID = UUID()
    let name: String
    let description: String
    let effect: CardEffectType
    let stardustCost: Int
    let iconName: String
}

/// Mock repository to supply initial tactical options to the player's deck hand
struct CardDeckRepository {
    static let startingHand: [CombatCard] = [
        CombatCard(name: "Campo de Fuerza", description: "Absorbe el primer impacto recibido en la Ronda 1.", effect: .shieldBoost, stardustCost: 50, iconName: "shield.lane"),
        CombatCard(name: "Táctica Suicida", description: "Los Cazas infligen el doble de daño en la Ronda 1.", effect: .fighterFrenzy, stardustCost: 75, iconName: "bolt.heart"),
        CombatCard(name: "Estasis Orbital", description: "Inmoviliza los sistemas de la flota enemiga.", effect: .statisOrb, stardustCost: 100, iconName: "timer")
    ]
}
