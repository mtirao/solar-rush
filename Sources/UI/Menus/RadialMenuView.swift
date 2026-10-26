import SwiftUI

struct RadialMenuView: View {
    let planet: PlanetData
    let screenPosition: CGPoint
    let onActionSelected: (String) -> Void
    
    @State private var isAnimated: Bool = false
    private let menuRadius: CGFloat = 80.0 // Distance of buttons from the center point
    
    var body: some View {
        ZStack {
            // Sector 1: North Button - Build Fleet (Hammer Icon bound to key '1')
            RadialMenuButton(icon: "hammer.fill", color: .orange) {
                onActionSelected("BUILD")
            }
            .offset(x: 0, y: isAnimated ? -menuRadius : 0)
            .keyboardShortcut("1", modifiers: []) // Task 10 Acceleration hook
            
            // Sector 2: East Button - Upgrade Defenses (Shield Icon bound to key '2')
            RadialMenuButton(icon: "shield.fill", color: .green) {
                onActionSelected("UPGRADE")
            }
            .offset(x: isAnimated ? menuRadius : 0, y: 0)
            .keyboardShortcut("2", modifiers: []) // Task 10 Acceleration hook
            
            // Sector 3: West Button - Dispatch Fleet (Arrow Icon bound to key '3')
            RadialMenuButton(icon: "arrow.right.forward.to.line", color: .purple) {
                onActionSelected("MOVE")
            }
            .offset(x: isAnimated ? -menuRadius : 0, y: 0)
            .keyboardShortcut("3", modifiers: []) // Task 10 Acceleration hook
        }
        .position(screenPosition)
        .opacity(isAnimated ? 1.0 : 0.0)
        .scaleEffect(isAnimated ? 1.0 : 0.2)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Subview Circular Button Layout Asset
struct RadialMenuButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
        }
    }
}
