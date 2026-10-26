import SwiftUI

struct FactionSelectionView: View {
    // Callback to notify the parent app layer when the game officially starts with a chosen faction
    let onGameStarted: (FactionType) -> Void
    
    @State private var selectedFaction: FactionType = .orionScavenger
    
    private struct FactionInfo: Identifiable {
        let id = UUID()
        let type: FactionType
        let name: String
        let description: String
        let passive: String
        let icon: String
        let color: Color
    }
    
    private let factions: [FactionInfo] = [
        FactionInfo(type: .orionScavenger,
                    name: "Chatarreros de Orión",
                    description: "Piratas industriales y asaltantes de chatarra.",
                    passive: "Rapiña: Recupera un 25% del coste en Polvo Estelar de cualquier nave destruida en combate.",
                    icon: "shippinglabel.fill",
                    color: Color.red),
        FactionInfo(type: .chironSwarm,
                    name: "Enjambre Quironita",
                    description: "Organismos bioluminiscentes veloces y masivos.",
                    passive: "Impulso Orgánico: Tus flotas ganan un 50% de velocidad si viajan a favor del giro orbital.",
                    icon: "ant.fill",
                    color: Color.green),
        FactionInfo(type: .silicateNexus,
                    name: "Nexo Silicato",
                    description: "Inteligencia artificial cristalina hipercalculadora.",
                    passive: "Alineación Solar: Duplica la cosecha de Polvo Estelar si dos o más planetas se alinean con el Sol.",
                    icon: "cpu",
                    color: Color.cyan)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark cosmic background theme
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Subtle ambient glow corresponding to the selected faction color
                Circle()
                    .fill(currentFactionColor().opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                VStack(spacing: 24) {
                    // Header Screen Title text
                    VStack(spacing: 6) {
                        Text("SOLAR RUSH")
                            .font(.system(.largeTitle, design: .rounded))
                            .bold()
                            .foregroundColor(.white)
                            .tracking(4)
                        Text("SELECCIONA TU CIVILIZACIÓN")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .tracking(2)
                    }
                    .padding(.top, 40)
                    
                    // Main layout split container row
                    HStack(spacing: 32) {
                        // Left Column: Faction Cards Checklist Handlers
                        VStack(spacing: 16) {
                            ForEach(factions, id: \.id) { faction in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        self.selectedFaction = faction.type
                                    }
                                    // Play feedback sound from Task 6/7 audio submodule
                                    AudioManager.shared.playSFX(named: "sfx_laser_impact", volume: 0.5)
                                }) {
                                    HStack(spacing: 16) {
                                        let iconColor: Color = (selectedFaction == faction.type) ? faction.color : Color.gray
                                        Image(systemName: faction.icon)
                                            .font(.title2)
                                            .foregroundStyle(iconColor)
                                            .frame(width: 50, height: 50)
                                            .background(Color.white.opacity(0.05))
                                            .clipShape(Circle())
            
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(faction.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(faction.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                    }
                                    .padding(16)
                                    .frame(width: 380)
                                    .background(selectedFaction == faction.type ? Color.white.opacity(0.08) : Color.black)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedFaction == faction.type ? faction.color : Color.white.opacity(0.1), lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Right Column: Passive Ability Dashboard details panel
                        if let activeData = factions.first(where: { $0.type == selectedFaction }) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("HABILIDAD PASIVA DE FACCION")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(activeData.color)
                                    .bold()
                                
                                Text(activeData.passive)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                                
                                // Primary Action Battle deployment button launcher
                                Button(action: {
                                    AudioManager.shared.playSFX(named: "sfx_construction_complete", volume: 1.0)
                                    onGameStarted(selectedFaction)
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("INICIAR INVASIÓN 🚀")
                                            .font(.system(.headline, design: .rounded))
                                            .bold()
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .background(activeData.color)
                                    .cornerRadius(10)
                                    .shadow(color: activeData.color.opacity(0.4), radius: 8, x: 0, y: 4)
                                }
                            }
                            .padding(24)
                            .frame(width: 320, height: 260)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity))
                        }
                    }
                    .padding(.horizontal, max(geometry.safeAreaInsets.leading, 24))
                    .padding(.horizontal, max(geometry.safeAreaInsets.trailing, 24))
                    
                    Spacer()
                }
            }
        }
    }
    
    private func currentFactionColor() -> Color {
        switch selectedFaction {
        case .orionScavenger: return Color.red
        case .chironSwarm:     return Color.green
        case .silicateNexus:   return Color.cyan
        }
    }
}
