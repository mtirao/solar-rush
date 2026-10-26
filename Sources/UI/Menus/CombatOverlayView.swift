import SwiftUI

struct CombatOverlayView: View {
    let targetPlanet: PlanetData
    let onManeuverCompleted: (CardEffectType?) -> Void
    
    @State private var timeRemaining: Double = 5.0
    @State private var playerHand: [CombatCard] = CardDeckRepository.startingHand
    @State private var draggedCard: CombatCard? = nil
    @State private var isTargetHovered: Bool = false
    
    private let countdownTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Darkened dramatic cinematic background overlay vignette bounds
            Color.black.opacity(0.75).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Battle header metadata parameters panel
                VStack(spacing: 4) {
                    Text("¡ALERTA DE COMBATE EN ORBITA!")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundColor(.red)
                    Text("Sistema: \(targetPlanet.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Task 8: 5-Second Linear Countdown Timer Progress HUD bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.2))
                        Capsule().fill(Color.orange)
                            .frame(width: geo.size.width * CGFloat(timeRemaining / 5.0))
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 80)
                .onReceive(countdownTimer) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 0.1
                    } else {
                        // Timer expired, auto-resolve with no actions selected
                        countdownTimer.upstream.connect().cancel()
                        onManeuverCompleted(nil)
                    }
                }
                
                Spacer()
                
                // TARGET ZONE: Large dynamic bounding drop destination frame box
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isTargetHovered ? Color.cyan : Color.white.opacity(0.3),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8]))
                        .background(isTargetHovered ? Color.cyan.opacity(0.1) : Color.white.opacity(0.05))
                    
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title)
                        Text(isTargetHovered ? "¡SUELTA LA CARTA AQUÍ!" : "ARRASTRA UNA MANIOBRA TÁCTICA")
                            .font(.system(.subheadline, design: .rounded))
                            .bold()
                    }
                    .foregroundColor(isTargetHovered ? .cyan : .secondary)
                }
                .frame(width: 320, height: 160)
                
                Spacer()
                
                // CARDS HAND: Render structural inventory items at the bottom layout layer
                HStack(spacing: 16) {
                    ForEach(playerHand) { card in
                        CardViewAsset(card: card)
                            .onDrag {
                                self.draggedCard = card
                                return NSItemProvider(object: card.name as NSString)
                            }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        // Inject structural drop configuration target handlers compatible with iOS and macOS Catalyst
        .onDrop(of: ["public.text"], isTargeted: $isTargetHovered) { providers in
            guard let cardToPlay = draggedCard else { return false }
            
            // Economy Validation Check: Ensure player has enough funds before consuming card index asset
            if StardustManager.shared.isAffordable(cost: cardToPlay.stardustCost) {
                _ = StardustManager.shared.debitStardust(amount: cardToPlay.stardustCost)
                countdownTimer.upstream.connect().cancel()
                onManeuverCompleted(cardToPlay.effect)
                return true
            }
            return false
        }
    }
}

// MARK: - Individual UI Layout Card Model Frame Component
struct CardViewAsset: View {
    let card: CombatCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.name)
                .font(.system(.caption, design: .rounded))
                .bold()
                .foregroundColor(.cyan)
            Text(card.description)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
            Spacer()
            HStack {
                Text("✨ \(card.stardustCost)")
                    .font(.system(size: 10, design: .monospaced))
                    .bold()
                Spacer()
            }
        }
        .padding(12)
        .frame(width: 130, height: 160)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    // Mapping placeholder variable to bypass formatting compile glitches from text macro bindings
    init(card: CombatCard) { self.card = card }
}
