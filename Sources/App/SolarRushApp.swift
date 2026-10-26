import SpriteKit
import SwiftUI


@main
struct SolarRushApp: App {
    
    // Core states to control screen navigation flows (Fase de interfaces)
    @State private var userSelectedFaction: FactionType? = nil

    // Instanciamos la escena central de SpriteKit compartida
    // Definimos un tamaño base nativo de 1024x768 (proporción ideal para estrategia 2D)
    @State private var mainGameScene: GameScene = {
        let scene = GameScene()
        scene.size = CGSize(width: 1024, height: 768)
        scene.scaleMode = .resizeFill
        // Centramos el punto de anclaje para que las coordenadas polares del Sol arranquen en (0,0)
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return scene
    }()
    
    var body: some Scene {

        WindowGroup {
            Group {
                if let faction = userSelectedFaction {
                    // Game Screen matches target selections cleanly
                    ContentView(gameScene: mainGameScene)
                        .onAppear {
                            // Task 12 Injection: Pass player faction settings down into the graphics scene
                            // mainGameScene.setPlayerLocalFaction(faction) // Production method link
                        }
                } else {
                    // App launches on selection screen dashboard directly
                    FactionSelectionView { chosenFaction in
                        withAnimation(.easeInOut(duration: 0.4)) {
                            self.userSelectedFaction = chosenFaction
                        }
                    }
                }
            }
            #if targetEnvironment(macCatalyst)
            .frame(minWidth: 1024, minHeight: 768)
            .onAppear {
                configureMacWindow()
            }
            #endif
        }
    }
    
    #if targetEnvironment(macCatalyst)
    /// Optimiza el comportamiento de la ventana cuando el juego corre en ordenadores Mac
    private func configureMacWindow() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let windowManager = scene.sizeRestrictions else { return }
        
        // Definimos un tamaño mínimo y máximo para que la UI de estrategia no se rompa al redimensionar
        windowManager.minimumSize = CGSize(width: 1024, height: 768)
        windowManager.maximumSize = CGSize(width: 3840, height: 2160) // Soporte hasta pantallas 4K
        
        // Habilitamos el botón de maximizar pantalla completa en la barra superior de macOS
        scene.titlebar?.titleVisibility = .hidden
    }
    #endif
}

// MARK: - Root Content View (Updated for Task 11 Responsive Layout Control)
struct ContentView: View {
    var gameScene: GameScene
    private var economyManager = StardustManager.shared
    
    @State private var isInterfaceInteractionDisabled: Bool = false
    @State private var activeDisplayTurn: Int = 1
    @State private var activeSelectedPlanet: PlanetData? = nil
    @State private var radialMenuScreenCoordinates: CGPoint = .zero
    @State private var combatTargetPlanet: PlanetData? = nil
    @State private var planetTargetingBuildSheet: PlanetData? = nil

    // MARK: - Task 14 Supernova Active UI States
    @State private var isSupernovaImminent: Bool = false
    @State private var collapsedOrbitLanes: Set<OrbitType> = []
    @State private var triggerVignetteFlash: Bool = false

    // MARK: - Pass & Play Active State Parameters (Added Missing Variables)
    /// Tracks which commander profile currently has active planning input rights
    @State private var currentTurnCommander: PlayerID = .playerOne
    /// Visibility flag to intercept layouts with the private handoff screen block
    @State private var isShowingHandoffCurtain: Bool = false
    /// Unique identity hash token used to force swift programmatic re-initialization of the 30s timers
    @State private var reloadTimerToggleToken: Bool = false
    
    // Add these active state tracking parameters inside your ContentView struct variables:
    @State private var coreControllerFaction: OrbitType? = nil
    @State private var coreTurnsHeldCounter: Int = 0
    @State private var victoriousFaction: OrbitType? = nil

    // Add this active state view flag inside your ContentView struct variables:
    @State private var isShowingSummaryDashboard: Bool = false


    var body: some View {
        // Task 11: GeometryReader measures the strict hardware screen layout boundaries
        GeometryReader { geometry in
            ZStack {
                // LAYER 1: Core Engine Graph (Renders edge-to-edge for total immersion)
                SpriteView(scene: gameScene)
                    .edgesIgnoringSafeArea(.all)
                
                // Task 14: Emergency Red Screen Vignette Overlay when Star reaches critical threshold
                if isSupernovaImminent {
                    RadialGradient(colors: [Color.clear, Color.red.opacity(triggerVignetteFlash ? 0.35 : 0.15)],
                                   center: .center,
                                   startRadius: 200,
                                   endRadius: 600)
                        .edgesIgnoringSafeArea(.all)
                        .blendMode(.screen)
                        .onAppear {
                            // Instantiate an endless structural heartbeat animation loop to mimic a hazard alarm pulsar
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                triggerVignetteFlash = true
                            }
                        }
                }

                // LAYER 2: Floating Radial Menu Context Layer Injection
                if let activePlanet = activeSelectedPlanet {
                    RadialMenuView(planet: activePlanet, screenPosition: radialMenuScreenCoordinates) { selectedAction in
                        
                        if selectedAction == "BUILD" {
                            // Transfer target reference context definitions onto the production panel sheet view
                            self.planetTargetingBuildSheet = activePlanet
                        } else if selectedAction == "UPGRADE" {
                            if StardustManager.shared.debitStardust(amount: 150) {
                                // Shield upgrade execution logic goes here
                            }
                        }
                        activeSelectedPlanet = nil
                    }
                }

                // Subview Component: Floating Production Grid Overlay Panel
                if let buildPlanet = planetTargetingBuildSheet {
                    BuildSheetView(planet: buildPlanet, onShipSelected: { chosenShipClass in
                        // Inyectar la nueva unidad directamente en el motor físico de SpriteKit
                        gameScene.spawnShipOnPlanet(id: buildPlanet.id, type: chosenShipClass)
                        // Task 13 Tutorial Hook callback check wrapper
                        gameScene.notifyUnitBuilt(type: chosenShipClass)
                        
                        self.planetTargetingBuildSheet = nil
                    }, onDismiss: {
                        self.planetTargetingBuildSheet = nil
                    })
                    .position(x: radialMenuScreenCoordinates.x, y: radialMenuScreenCoordinates.y + 110) // Render offset slightly lower
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Task 1: Persistent Center Floating Indicator Mapping Solar Core Progress
                if let coreFaction = coreControllerFaction {
                    VStack(spacing: 2) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                        Text("NÚCLEO CAPTURADO: T-\(3 - coreTurnsHeldCounter)")
                            .font(.system(size: 10, design: .monospaced))
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.85))
                            .cornerRadius(4)
                    }
                    // Force coordinate placement directly over the geometric center frame point of screen space
                    .position(x: geometry.size.width / 2, y: (geometry.size.height / 2) - 60)
                    .transition(.scale.combined(with: .opacity))
                }

                // LAYER 3: Responsive Top HUD Dashboard (Safe Area Constraints Applied)
                VStack {
                    HStack {
                        // Resource Tracker Layout Panel
                        HStack(spacing: 8) {
                            Text("✨")
                            Text("POLVO ESTELAR: \(economyManager.currentStardust)")
                                .font(.system(.subheadline, design: .monospaced))
                                .bold()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                        )
                        
                        Spacer()
                        
                        // Dynamic Danger Alert Banner displayed during Supernova Phase
                        if isSupernovaImminent {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                Text("NÚCLEO SOLAR INESTABLE: COLAPSO EN CURSO")
                                    .font(.system(.caption, design: .rounded))
                                    .bold()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.red))
                            .shadow(color: .red.opacity(0.5), radius: 6, x: 0, y: 3)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        Spacer()

                        // Task 10/14: Pass & Play Interactive Progress Timer Bar HUD Widget
                        if !isInterfaceInteractionDisabled && !isShowingHandoffCurtain {
                            PassAndPlayHUD(activePlayer: currentTurnCommander, onTimerExpired: {
                                gameScene.processEndTurn() // Force auto-lock instructions when 30s expire
                            })
                            .id(reloadTimerToggleToken) // Identity hash token forcing swift view reset bindings on refresh
                        }

                        Spacer()

                        // Input trigger to end current phase
                        Button(action: {
                            activeSelectedPlanet = nil
                            gameScene.processEndTurn()
                        }) {
                            Text(isInterfaceInteractionDisabled ? "ORBITANDO..." : "FIN DE TURNO 🚀")
                                .font(.system(.headline, design: .rounded))
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    isInterfaceInteractionDisabled ? 
                                    LinearGradient(colors: [Color.gray, Color.secondary], startPoint: .top, endPoint: .bottom) :
                                    LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(10)
                        }
                        .disabled(isInterfaceInteractionDisabled)
                        .keyboardShortcut(.space, modifiers: [])
                    }
                    // Task 11 Adaptive Padding: Reads hardware safe inset constraints dynamically in real-time
                    .padding(.leading, max(geometry.safeAreaInsets.leading, 24))
                    .padding(.trailing, max(geometry.safeAreaInsets.trailing, 24))
                    .padding(.top, max(geometry.safeAreaInsets.top, 16))
                    
                    Spacer() // Keeps HUD anchored to the safe upper margins
                }
                
                // LAYER 4: Cinematic Combat Drop Overlay Interface Canvas
                if let activeBattlePlanet = combatTargetPlanet {
                    CombatOverlayView(targetPlanet: activeBattlePlanet) { chosenEffect in
                        gameScene.injectCombatModifier(chosenEffect)
                        withAnimation {
                            self.combatTargetPlanet = nil
                        }
                    }
                    .transition(.opacity)
                }

                // LAYER 5: Absolute Game Over Victory Screen Panel Sheet overlay
                if isShowingHandoffCurtain {
                    CurtainHandoffView(targetCommander: currentTurnCommander) {
                        gameScene.startActivePlanningPhase()
                        withAnimation(.easeInOut) {
                            self.isShowingHandoffCurtain = false
                        }
                    }
                    .transition(.move(edge: .bottom))
                }
                
                if let winner = victoriousFaction {
                    if isShowingSummaryDashboard {
                        // Render the advanced progressive progression yield tracker terminal view layer sheet
                        MatchSummaryView(
                            victoriousFaction: winner,
                            playerFaction: .orionScavenger, // Target profile configuration link parameter matching Task 12
                            matchStats: (planets: 2, kills: 6, turns: activeDisplayTurn), // Collect telemetry records from game state
                            onDismiss: {
                                // Fully clean up and purge variables back to baseline profiles to restart app states
                                self.victoriousFaction = nil
                                self.activeSelectedPlanet = nil
                                self.isShowingSummaryDashboard = false
                                // Trigger router state back to main screen selectors
                                NotificationCenter.default.post(name: NSNotification.Name("ResetToMainSelection"), object: nil)
                            }
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                    } else {
                        ZStack {
                            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
                            
                            VStack(spacing: 24) {
                                Text("👑 VICTORIA GALÁCTICA COMPLETA 👑")
                                    .font(.system(.title, design: .rounded))
                                    .bold()
                                    .foregroundColor(.yellow)
                                
                                Text("La Facción [\(String(describing: winner))] ha estabilizado el Núcleo Solar y reclama la supremacía total del sistema.")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 60)
                                
                                Button(action: {
                                    // Logic stub layout to reset scene nodes maps and variables back to baseline values
                                    self.victoriousFaction = nil
                                    self.coreControllerFaction = nil
                                    self.coreTurnsHeldCounter = 0
                                    // Trigger scene reload actions...
                                }) {
                                    Text("VOLVER AL MENÚ PRINCIPAL")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 14)
                                        .background(Color.yellow)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            NotificationCoordinator.shared.setup(scene: gameScene, view: self)
            
            // Audio Initialization Hook: Launch the sci-fi background track instantly
            AudioManager.shared.playBGM(named: "bgm_solar_rush_theme", volume: 0.4)

            gameScene.onPlanetSelected = { planet, viewPosition in
                self.radialMenuScreenCoordinates = viewPosition
                self.activeSelectedPlanet = planet
            }
            
            gameScene.onSpaceTapped = {
                withAnimation {
                    self.activeSelectedPlanet = nil
                }
            }
            
            gameScene.onCombatInitiated = { battlePlanetData in
                withAnimation {
                    self.combatTargetPlanet = battlePlanetData
                }
            }
            
            // Capture critical mass notification trigger from SpriteKit physics thread clock
            gameScene.onSupernovaTriggered = {
                withAnimation(.spring()) {
                    self.isSupernovaImminent = true
                }
            }
            
            // Track collapsed lanes sequentially to seal interface input pipelines
            gameScene.onOrbitCollapsed = { destroyedOrbitLane in
                withAnimation {
                    self.collapsedOrbitLanes.insert(destroyedOrbitLane)
                    // If the active selected planet was on the vaporized track, dismiss its radial window instantly
                    if let openPlanet = self.activeSelectedPlanet, openPlanet.orbit == destroyedOrbitLane {
                        self.activeSelectedPlanet = nil
                    }
                }
            }

        }
    }
    
    fileprivate func setInterfaceLockState(isLocked: Bool) {
        self.isInterfaceInteractionDisabled = isLocked
    }
    
    fileprivate func incrementActiveTurnCount() {
        self.activeDisplayTurn += 1
    }
}


// MARK: - Technical Bridge Coordinator
/// Intermediary structural class designed to adapt reference-type class pointers into value-type SwiftUI states
private class NotificationCoordinator: GameTurnDelegate {
    static let shared = NotificationCoordinator()
    
    private var targetViewReference: ContentView?
    
    func setup(scene: GameScene, view: ContentView) {
        scene.turnDelegate = self
        self.targetViewReference = view
    }
    
    func gameSceneWillAdvanceTurn() {
        DispatchQueue.main.async {
            self.targetViewReference?.setInterfaceLockState(isLocked: true)
        }
    }
    
    func gameSceneDidFinishAdvanceTurn() {
        DispatchQueue.main.async {
            self.targetViewReference?.setInterfaceLockState(isLocked: false)
            self.targetViewReference?.incrementActiveTurnCount()
        }
    }
}

