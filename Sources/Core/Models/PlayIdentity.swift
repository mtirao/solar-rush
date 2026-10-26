//
//  PlayIdentity.swift
//  SolarRush
//
//  Created by Marcos Tirao on 26/10/2026.
//

import Foundation

/// Differentiates active rival commanders locally competing on the screen
enum PlayerID: String {
    case playerOne = "JUGADOR 1"
    case playerTwo = "JUGADOR 2"
    
    /// Returns the opposing tactical competitor profile ID
    var opponent: PlayerID {
        return self == .playerOne ? .playerTwo : .playerOne
    }
}
