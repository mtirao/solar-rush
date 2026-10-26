import SwiftUI

struct MatchSummaryView: View {
    let victoriousFaction: OrbitType?
    let playerFaction: FactionType
    let matchStats: (planets: Int, kills: Int, turns: Int)
    let onDismiss: () -> Void
    
    @State private var animatedFragments: Int = 0
    @State private var animatedXP: Int = 0
    @State private var isUiAnimated: Bool = false
    
    private var progression = ProgressionManager.shared
    
    var body: some View {
        let isPlayerVictory = checkPlayerVictoryStatus()
        let rewards = progression.calculateMatchRewards(
            planetsCaptured: matchStats.planets,
            enemyShipsVaporized: matchStats.kills,
            turnsResisted: matchStats.turns,
            isVictory: isPlayerVictory
        )
        
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Atmospheric decorative background glow mapping win/loss states
            Circle()
                .fill(isPlayerVictory ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                .frame(width: 450, height: 450)
                .blur(radius: 90)
            
            VStack(spacing: 24) {
                // Main Header Banner Announcement
                VStack(spacing: 6) {
                    Text(isPlayerVictory ? "¡VICTORIA ABSOLUTA!" : "DERROTA EN SECTOR")
                        .font(.system(.title, design: .rounded))
                        .bold()
                        .foregroundColor(isPlayerVictory ? .green : .red)
                        .tracking(2)
                    Text("RESUMEN DE OPERACIÓN TÁCTICA")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
                
                HStack(spacing: 40) {
                    // LEFT COLUMN: Match Telemetry Records Grid
                    VStack(alignment: .leading, spacing: 14) {
                        StatRowItem(label: "Planetas Asegurados", value: "+\(matchStats.planets)", icon: "globe.americas.fill")
                        StatRowItem(label: "Naves Enemigas Vaporizadas", value: "+\(matchStats.kills)", icon: "bolt.shield.fill")
                        StatRowItem(label: "Ciclos Orbitales Resistidos", value: "\(matchStats.turns)", icon: "timer")
                    }
                    .frame(width: 280)
                    
                    // RIGHT COLUMN: Progression Rewards Processing Terminal
                    VStack(spacing: 16) {
                        Text("RECOMPENSAS DEL BUCLE")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        // Star Fragments Count Widget Card
                        HStack(spacing: 12) {
                            Text("☄️")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FRAGMENTOS ESTELARES")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text("+\(animatedFragments)")
                                    .font(.system(.title3, design: .rounded))
                                    .bold()
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white.withAlphaComponent(0.04))
                        .cornerRadius(10)
                        
                        // Level & Account XP Progress Dashboard Section
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("NIVEL DE CUENTA: \(progression.accountLevel)")
                                    .font(.system(size: 11, design: .rounded))
                                    .bold()
                                Spacer()
                                Text("+\(animatedXP) XP")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                            
                            // Visual Account Leveling Progress Slider Gauge bar
                            GeometryReader { barGeo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.withAlphaComponent(0.1))
                                    Capsule().fill(Color.cyan)
                                        .frame(width: barGeo.size.width * CGFloat(Float(progression.currentAccountXP) / 2000.0))
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(12)
                        .background(Color.white.withAlphaComponent(0.04))
                        .cornerRadius(10)
                    }
                    .frame(width: 260)
                }
                
                // Primary Action Release Hook Dismiss Button View Control
                Button(action: {
                    progression.commitEarnedRewards(fragments: rewards.fragments, xp: rewards.xp)
                    onDismiss()
                }) {
                    Text("RECLAMAR CRÉDITOS Y VOLVER")
                        .font(.system(.headline, design: .rounded))
                        .bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(isPlayerVictory ? Color.green : Color.white)
                        .cornerRadius(8)
                }
                .padding(.bottom, 20)
            }
            .padding(16)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.withAlphaComponent(0.08), lineWidth: 1))
            .scaleEffect(isUiAnimated ? 1.0 : 0.9)
            .opacity(isUiAnimated ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isUiAnimated = true
                }
                // Simulate an old arcade count tick score animation up rolling the digits procedurally
                withAnimation(.linear(duration: 1.2).delay(0.2)) {
                    animatedFragments = rewards.fragments
                    animatedXP = rewards.xp
                }
                AudioManager.shared.playSFX(named: "sfx_construction_complete", volume: 0.9)
            }
        }
    }
    
    private func checkPlayerVictoryStatus() -> Bool {
        guard let winner = victoriousFaction else { return false }
        switch playerFaction {
        case .orionScavenger: return winner == .externalOrbit
        case .chironSwarm:     return winner == .internalOrbit
        case .silicateNexus:   return winner == .mediumOrbit
        }
    }
}

// MARK: - Row layout asset helper
struct StatRowItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.withAlphaComponent(0.8))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .bold()
                .foregroundColor(.cyan)
        }
        .padding(10)
        .background(Color.white.withAlphaComponent(0.02))
        .cornerRadius(6)
    }
}
