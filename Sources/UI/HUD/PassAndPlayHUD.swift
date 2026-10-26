import SwiftUI

struct PassAndPlayHUD: View {
    let activePlayer: PlayerID
    let onTimerExpired: () -> Void
    
    @State private var secondsRemaining: Double = 30.0
    private let clockTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            // Player Identity Active Tag Indicator Panel
            HStack(spacing: 6) {
                Circle()
                    .fill(activePlayer == .playerOne ? Color.blue : Color.red)
                    .frame(width: 8, height: 8)
                Text(activePlayer.rawValue)
                    .font(.system(.caption, design: .rounded))
                    .bold()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
            .cornerRadius(6)
            
            // ⏰ 30-Second Countdown Clock Widget Frame
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .foregroundColor(secondsRemaining < 5.0 ? .red : .orange)
                Text(String(format: "%.1fs", secondsRemaining))
                    .font(.system(.subheadline, design: .monospaced))
                    .bold()
                    .foregroundColor(secondsRemaining < 5.0 ? .red : .white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
            .cornerRadius(6)
            .onReceive(clockTimer) { _ in
                if secondsRemaining > 0 {
                    secondsRemaining -= 0.1
                } else {
                    clockTimer.upstream.connect().cancel()
                    onTimerExpired() // Automatically triggers force end turn sequence
                }
            }
        }
    }
}

// MARK: - Intermediate Blind Handoff Curtain Overlay Panel Sheet View
struct CurtainHandoffView: View {
    let targetCommander: PlayerID
    let onCurtainDismissed: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("PASAR DISPOSITIVO 📱")
                    .font(.system(.title2, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
                    .tracking(2)
                
                Text("Cediendo mando táctico al **\(targetCommander.rawValue)**.\nOcultando planos de órbitas secretos para evitar espionaje.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: onCurtainDismissed) {
                    Text("ESTOY LISTO, TOMAR EL CONTROL 🚀")
                        .font(.system(.headline, design: .rounded))
                        .bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(targetCommander == .playerOne ? Color.blue : Color.red)
                        .cornerRadius(10)
                }
            }
        }
    }
}
