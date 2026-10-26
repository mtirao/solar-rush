import SwiftUI

struct BuildSheetView: View {
    let planet: PlanetData
    let onShipSelected: (ShipClass) -> Void
    let onDismiss: () -> Void
    
    // Track current stardust balance using our observable instance framework
    private var economy = StardustManager.shared
    
    private let availableUnits: [(type: ShipClass, name: String, cost: Int, icon: String)] = [
        (.fighter, "Caza Ligero", 100, "paperplane.fill"),
        (.frigate, "Fragata Escudo", 250, "shield.hexagon.fill"),
        (.bomber, "Bombardero Asedio", 400, "target")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Avanzada de Producción: \(planet.name)")
                    .font(.system(.caption, design: .rounded))
                    .bold()
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.bottom, 4)
            
            HStack(spacing: 12) {
                ForEach(availableUnits, id: \.name) { unit in
                    // Precompute simple values to help the type-checker
                    let isAffordable: Bool = economy.isAffordable(cost: unit.cost)
                    let strokeColor: Color = {
                        if isAffordable {
                            return Color.cyan.opacity(0.3)
                        } else {
                            return Color.white.opacity(0.1)
                        }
                    }()

                    Button(action: {
                        let didDebit: Bool = economy.debitStardust(amount: unit.cost)
                        if didDebit {
                            onShipSelected(unit.type)
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: unit.icon)
                                .font(.title3)
                                .foregroundColor(isAffordable ? .cyan : .gray)

                            Text(unit.name)
                                .font(.system(size: 11, design: .rounded))
                                .bold()

                            Text("✨ \( .init(unit.cost))")
                                .font(.system(size: 10, design: .monospaced))
                                .bold()
                                .foregroundColor(isAffordable ? .yellow : .red)
                        }
                        .frame(width: 105, height: 100)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(strokeColor, lineWidth: 1)
                        )
                    }
                    .disabled(!isAffordable)
                }
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(radius: 10)
    }
}

