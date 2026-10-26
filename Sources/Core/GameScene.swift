import SpriteKit
import SwiftUI


// MARK: - Structural Flight Route Data (Task 3)
struct TravelRoute {
    let originPlanetId: UUID
    let destinationPlanetId: UUID
    var estimatedTurns: Int
}

// MARK: - Orbit Type Definitions
enum OrbitType {
    case internalOrbit
    case mediumOrbit
    case externalOrbit
    
    /// Fixed radial distance in screen points from the solar system center
    var radius: CGFloat {
        switch self {
        case .internalOrbit: return 120.0
        case .mediumOrbit:   return 220.0
        case .externalOrbit: return 320.0
        }
    }
    
    /// Angular step advanced per game turn (expressed in radians)
    /// 60° = ~1.047 rad, 30° = ~0.523 rad, 15° = ~0.261 rad
    var turnAngularVelocity: Double {
        switch self {
        case .internalOrbit: return Double.pi / 3      // 60 degrees
        case .mediumOrbit:   return Double.pi / 6      // 30 degrees
        case .externalOrbit: return Double.pi / 12     // 15 degrees
        }
    }
}

// MARK: - Planet Data Structure
struct PlanetData {
    let id: UUID = UUID()
    let name: String
    let orbit: OrbitType
    var angle: Double // Stored in radians
    var shieldHealth: Float = 500.0 // New Task 5 attribute
    var squadron: CombatSquadron?   // New Task 5 attribute
    var stardustYield: Int = 75     // New Task 6 parameter: passive stardust generated per turn
    var ownerFaction: FactionType?  // New Task 12 parameter: identifies current political control
}

// MARK: - Game Turn Lifecycle Protocol (Task 2)
protocol GameTurnDelegate: AnyObject {
    /// Dispatched immediately when the engine begins calculating and animating planetary rotations
    func gameSceneWillAdvanceTurn()
    /// Dispatched once all planetary animations complete, signaling the UI layer to re-enable interaction
    func gameSceneDidFinishAdvanceTurn()
}

// MARK: - Task 13 Campaign Tutorial State Machine
enum TutorialStep {
    case step1Welcome        // Waiting for the player to test the orbital movement rule
    case step2BuildUnit      // Forcing the player to open the menu and build a Bomber
    case step3LaunchFleet    // Forcing an orbital launch along the current direction
    case step4CombatCard     // Interrupting combat to teach maneuver card mechanics
    case step5FreePlay       // Total freedom given to capture the final enemy outpost
}

// MARK: - Core Game Scene Engine
class GameScene: SKScene {
    
    // MARK: - Task 7 Interaction Publisher Properties
    /// Callback mechanism to notify SwiftUI when a planet has been selected with its screen space coordinate position
    var onPlanetSelected: ((PlanetData, CGPoint) -> Void)?
    /// Callback mechanism to deselect when tapping empty space
    var onSpaceTapped: (() -> Void)?
    // MARK: - Task 8 Interaction Publisher Properties
    /// Signals SwiftUI that a battle is starting, passing the active planet's telemetry state data
    var onCombatInitiated: ((PlanetData) -> Void)?
    /// Captures the tactical card selected by the player from SwiftUI before resolving round calculations
    private var activeInjectedModifier: CardEffectType?
    // MARK: - Task 1 Solar Core Victory Publisher Properties
    /// Signals SwiftUI that a faction has achieved absolute victory by holding the core
    var onVictoryAchieved: ((OrbitType) -> Void)?
    /// Signals SwiftUI the current countdown status of the core capture (Faction, current turns, required turns)
    var onCoreCaptureStatusChanged: ((OrbitType?, Int) -> Void)?
    // Task 1 Core System tracker state state variable
    private var solarCoreState = SolarCoreControlState()
    /// Node container inside (0,0) that will handle units tracking for combat resolution
    private var solarCoreSquadron: CombatSquadron? = nil


    // Coordinates anchor for the solar system center (The Sun)
    private let systemCenterCoordinates = CGPoint(x: 0, y: 0)
    
    // Core game state telemetry (Task 1 & 2)
    private var globalTurnCounter: Int = 1
    private var planetsRegistry: [PlanetData] = []
    private var planetNodesMap: [UUID: SKShapeNode] = [:]
    
    // Core synchronization locks & bindings (Task 2)
    weak var turnDelegate: GameTurnDelegate?
    private var isAnimatingTurn: Bool = false
    
    // Active navigation gesture trackers (Task 3 & 4)
    private var selectedOriginPlanet: PlanetData?
    private var visualTrajectoryLineNode: SKShapeNode?
    private var pendingTravelRoutes: [TravelRoute] = []
    private var ghostPlanetNodesMap: [UUID: SKShapeNode] = [:]
    private let maxTravelDistanceThreshold: CGFloat = 450.0 // Cutoff limit for Red state bounds
    

    // MARK: - Task 9 Camera & Zoom Boundaries Telemetry
    private let minCameraScaleThreshold: CGFloat = 0.5  // Maximum Zoom In close-up
    private let maxCameraScaleThreshold: CGFloat = 2.0  // Maximum Zoom Out wide-view
    private var initialPinchDistanceFrame: CGFloat = 0.0
    private var baselineCameraScaleOnPinch: CGFloat = 1.0
    // MARK: - Task 13 Telemetry & Event Closures
    private(set) var currentTutorialStep: TutorialStep = .step1Welcome
    
    /// Publisher pipeline to push text string scripts straight to the SwiftUI narrator bubbles
    var onTutorialDialogTriggered: ((String) -> Void)?

    // MARK: - Task 14 Supernova Telemetry Boundaries
    /// Publisher pipeline to notify SwiftUI that the Supernova has reached critical mass
    var onSupernovaTriggered: (() -> Void)?
    /// Publisher pipeline to notify SwiftUI which specific orbit lane has just collapsed
    var onOrbitCollapsed: ((OrbitType) -> Void)?
    
    private var activeOrbitLanes: [OrbitType] = [.externalOrbit, .mediumOrbit, .internalOrbit]
    private let supernovaTriggerTurnThreshold: Int = 15

    // MARK: - Pass & Play State Publishers
    /// Signals SwiftUI that a commander finished planning, prompting the Pass & Play handoff panel screen
    var onTurnPhaseChanged: ((PlayerID) -> Void)?
    /// Signals SwiftUI that both commanders finished planning, forcing the 30s timer reload clocks
    var onTurnCycleCompleted: (() -> Void)?

    // Pass & Play Core Telemetry Variables
    private(set) var activePlanningCommander: PlayerID = .playerOne
    private var isPlayerOnePlanningComplete: Bool = false
    private var isPlayerTwoPlanningComplete: Bool = false
    private var currentTurn: Int = 0
    
    override func didMove(to view: SKView) {
        // Setup internal scene camera anchor anchored at scene center
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode)
        
        // Task 15 Injection Hook: Populate the canvas matrix background before rendering nodes
        deployStellarBackgroundDrift()

        setupStellarEnvironment()
        initializePlanets()
    }
    
    // MARK: - Environment Setup (Task 1)
    private func dashedCirclePath(radius: CGFloat, dashLength: CGFloat, gapLength: CGFloat, segments: Int = 180) -> CGPath {
        let path = CGMutablePath()
        // Build a polyline approximating the circle and break it into dash/gap segments
        let circumference = 2 * .pi * radius
        // Ensure at least 1 segment
        let totalSegments = max(segments, 1)
        let angleStep = (2 * .pi) / CGFloat(totalSegments)
        
        // Convert dash/gap lengths along arc length into angle units
        let dashAngle = (dashLength / circumference) * 2 * .pi
        let gapAngle = (gapLength / circumference) * 2 * .pi
        
        var angle: CGFloat = 0
        while angle < 2 * .pi {
            // Start of dash
            let startAngle = angle
            let endAngle = min(angle + dashAngle, 2 * .pi)
            
            // Move to start point of this dash
            let sx = radius * cos(startAngle)
            let sy = radius * sin(startAngle)
            path.move(to: CGPoint(x: sx, y: sy))
            
            // Approximate the arc for this dash with small line segments
            var t = startAngle
            while t <= endAngle {
                let x = radius * cos(t)
                let y = radius * sin(t)
                path.addLine(to: CGPoint(x: x, y: y))
                t += angleStep
            }
            // Ensure we end exactly at endAngle
            let ex = radius * cos(endAngle)
            let ey = radius * sin(endAngle)
            path.addLine(to: CGPoint(x: ex, y: ey))
            
            // Advance by gap
            angle = endAngle + gapAngle
        }
        
        return path
    }

    /// Algorithmic function invoked every turn to evaluate army presence at coordinates (0,0)
    private func processSolarCoreVictoryMetrics() {
        // 1. Verify if there is an active squadron stationed exactly over the system center (0,0)
        guard let coreSquad = solarCoreSquadron, coreSquad.ships.count > 0 else {
            // If the center is empty, reset the countdown timer metrics cleanly
            if solarCoreState.currentControllerFaction != nil {
                solarCoreState.currentControllerFaction = nil
                solarCoreState.consecutiveTurnsHeld = 0
                onCoreCaptureStatusChanged?(nil, 0)
                print("☀️ Solar Core: Faction presence lost. Control counter reset to zero.")
            }
            return
        }
        
        // 2. Criterio de Aceptación: Check if the occupying fleet contains at least 1 Bomber class vessel
        let bomberCount = coreSquad.count(of: .bomber)
        guard bomberCount > 0 else {
            print("☀️ Solar Core: Fleet present at center, but lacks Bomber siege unit. Control unverified.")
            return
        }
        
        let currentFactionInCenter = coreSquad.ownerFaction
        
        // 3. Evaluate state shifts or countdown accumulation metrics
        if solarCoreState.currentControllerFaction == currentFactionInCenter {
            // Same faction successfully defended the sector for another consecutive frame turn
            solarCoreState.consecutiveTurnsHeld += 1
            print("☀️ Solar Core: Faction \(currentFactionInCenter) is holding center. Counter: \(solarCoreState.consecutiveTurnsHeld)/3")
        } else {
            // Takeover maneuver executed! Reset data track structures to favor the new invader faction
            solarCoreState.currentControllerFaction = currentFactionInCenter
            solarCoreState.consecutiveTurnsHeld = 1
            print("☀️ Solar Core: Faction \(currentFactionInCenter) executed a takeover maneuver. Countdown started.")
        }
        
        // Notify the UI layer about the current progress state
        onCoreCaptureStatusChanged?(solarCoreState.currentControllerFaction, solarCoreState.consecutiveTurnsHeld)
        
        // 4. Absolute Victory Trigger Check Boundary
        if solarCoreState.isVictoryAchieved {
            print("👑 SOLAR CORE VICTORY: Faction \(currentFactionInCenter) has stabilized the system core matrix!")
            onVictoryAchieved?(currentFactionInCenter)
        }
    }
    
    /// Call this setter via the UI layer bridge once the 5-second countdown ends or a card is dropped
    func injectCombatModifier(_ effect: CardEffectType?) {
        self.activeInjectedModifier = effect
    }


    func createGhostPlanetNode(withId id: UUID, position: CGPoint) {
        let ghostNode = SKShapeNode(circleOfRadius: 18)
        ghostNode.fillColor = .clear
        ghostNode.strokeColor = .white
        ghostNode.lineWidth = 1.5
        ghostNode.path = dashedCirclePath(radius: 18, dashLength: 3, gapLength: 4)
        ghostNode.position = position
        ghostNode.zPosition = 4
        
        addChild(ghostNode)
        ghostPlanetNodesMap[id] = ghostNode
    }
    
    
    private func makeDashedCircle(center: CGPoint, radius: CGFloat, dashLength: CGFloat, gapLength: CGFloat, lineWidth: CGFloat, color: SKColor) -> SKNode {
        let parentNode = SKNode()
        let circumference = 2 * CGFloat.pi * radius
        let count = max(1, Int(circumference / (dashLength + gapLength)))
        
        for i in 0..<count {
            let startAngle = (2 * CGFloat.pi) * (CGFloat(i) / CGFloat(count))
            let endAngle = startAngle + (dashLength / circumference) * 2 * CGFloat.pi
            
            let path = CGMutablePath()
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            
            let dashNode = SKShapeNode(path: path)
            dashNode.strokeColor = color
            dashNode.lineWidth = lineWidth
            dashNode.fillColor = .clear
            dashNode.lineCap = .round
            dashNode.lineJoin = .round
            
            parentNode.addChild(dashNode)
        }
        
        return parentNode
    }
    
    /// Renders the central Sun entity and the dashed geometric orbit guidelines
    private func setupStellarEnvironment() {
        // 1. Instantiate and render the central Sun entity
        let sunNode = SKShapeNode(circleOfRadius: 35)
        sunNode.position = systemCenterCoordinates
        sunNode.fillColor = .orange
        sunNode.strokeColor = .yellow
        sunNode.glowWidth = 5.0
        addChild(sunNode)
        
        // 2. Map and loop through each concentric orbit boundary lane
        let targetOrbits: [OrbitType] = [.internalOrbit, .mediumOrbit, .externalOrbit]
        for orbit in targetOrbits {
            // Set basic dashing layout array bounds to mimic planetary tracks
            let dashedOrbit = makeDashedCircle(
                center: systemCenterCoordinates,
                radius: orbit.radius,
                dashLength: 6,
                gapLength: 8,
                lineWidth: 1.5,
                color: SKColor.white.withAlphaComponent(0.2)
            )
            addChild(dashedOrbit)
        }
    }
    
    private func initializePlanets() {
        // Task 13 Tutorial Sandbox Scripting setups: Config parameters matched to Mission 1 GDD
        var startingPlayerSquad = CombatSquadron(ownerFaction: .externalOrbit)
        startingPlayerSquad.ships = [ShipUnit(type: .fighter), ShipUnit(type: .fighter), ShipUnit(type: .frigate)]
        
        var enemyNexusSquad = CombatSquadron(ownerFaction: .internalOrbit)
        enemyNexusSquad.ships = [ShipUnit(type: .fighter), ShipUnit(type: .fighter), ShipUnit(type: .fighter)]
        
        planetsRegistry = [
            PlanetData(name: "El Asteroide (Base)", orbit: .externalOrbit, angle: 0.0, shieldHealth: 500.0, squadron: startingPlayerSquad, stardustYield: 150, ownerFaction: .orionScavenger),
            PlanetData(name: "Planeta Neutral", orbit: .mediumOrbit, angle: Double.pi / 4, shieldHealth: 300.0, squadron: nil, stardustYield: 75, ownerFaction: nil),
            PlanetData(name: "Avanzada Nexo (Enemigo)", orbit: .internalOrbit, angle: Double.pi, shieldHealth: 200.0, squadron: enemyNexusSquad, stardustYield: 50, ownerFaction: .silicateNexus)
        ]
        
        for planet in planetsRegistry {
            let planetNode = SKShapeNode(circleOfRadius: 18)
            planetNode.fillColor = fetchFactionColor(for: planet.orbit)
            planetNode.strokeColor = .white
            planetNode.lineWidth = 2.0
            
            addChild(planetNode)
            planetNodesMap[planet.id] = planetNode
            
            updateVisualCoordinates(for: planet, targetNode: planetNode, animationDuration: 0.0)
        }
        
        // Dispatch the initial instructional script narrative to the UI layer layout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.onTutorialDialogTriggered?("¡Bienvenido Cadete! En Solar Rush el espacio nunca se queda quieto. Pulsa FIN DE TURNO para ver cómo giran las órbitas.")
        }
    }
    
    // MARK: - Mathematical Vector Conversions & Animation (Task 1 & 2)
    
    /// Translates systemic polar geometry targets into structural Cartesian screen bounds (X = R * cos(θ), Y = R * sin(θ))
    private func updateVisualCoordinates(for planet: PlanetData, targetNode: SKShapeNode, animationDuration: TimeInterval, completion: (() -> Void)? = nil) {
        let computedX = systemCenterCoordinates.x + planet.orbit.radius * CGFloat(cos(planet.angle))
        let computedY = systemCenterCoordinates.y + planet.orbit.radius * CGFloat(sin(planet.angle))
        
        let movementAction = SKAction.move(to: CGPoint(x: computedX, y: computedY), duration: animationDuration)
        movementAction.timingMode = .easeInEaseOut
        
        // Task 16 Verification Hook: If this is an active transit movement (duration > 0), attach engine thruster trails
        if animationDuration > 0, let activeFaction = planet.ownerFaction {
            let engineThrustTrail = createEngineTrailNode(for: activeFaction)
            targetNode.addChild(engineThrustTrail) // Bind emitter transform space directly inside the moving object node
            
            // Calculate dynamic angle orientation so particles always exhaust in the opposite direction of the vector flight path
            let currentPosition = targetNode.position
            let targetPosition = CGPoint(x: computedX, y: computedY)
            let movementAngleVector = atan2(targetPosition.y - currentPosition.y, targetPosition.x - currentPosition.x)
            engineThrustTrail.emissionAngle = movementAngleVector + CGFloat.pi // Invert by 180 degrees
            
            // Sequence wrap: Ensure the emitter stops producing items and gets cleanly removed from RAM memory on arrival
            let completionWrapper = SKAction.sequence([
                SKAction.run {
                    // Turn off generation first to allow lingering particles to fade out naturally
                    engineThrustTrail.particleBirthRate = 0
                },
                SKAction.wait(forDuration: TimeInterval(engineThrustTrail.particleLifetime)),
                SKAction.run {
                    engineThrustTrail.removeFromParent() // Absolute memory purge out of graphics layer
                },
                SKAction.run {
                    completion?()
                }
            ])
            
            targetNode.run(SKAction.group([movementAction, completionWrapper]))
        } else {
            if let completionHandler = completion {
                let sequence = SKAction.sequence([movementAction, SKAction.run(completionHandler)])
                targetNode.run(sequence)
            } else {
                targetNode.run(movementAction)
            }
        }
    }
    
    private func fetchFactionColor(for orbit: OrbitType) -> SKColor {
        switch orbit {
        case .internalOrbit: return .systemGreen  // Swarm Organic Signature
        case .mediumOrbit:   return .systemCyan   // Silicate AI Signature
        case .externalOrbit: return .systemRed    // Scavenger Industrial Signature
        }
    }
    
    private func fetchNodePosition(for planetId: UUID) -> CGPoint? {
        return planetNodesMap[planetId]?.position
    }
    
    // MARK: - Task 4 Predictive Geometry Algorithms
    
    /// Projects where a specific planetary body will sit in the immediate future (+1 Turn)
    private func computeFutureAngle(for planet: PlanetData) -> Double {
        let hypotheticalNextTurn = globalTurnCounter + 1
        
        if planet.orbit == .externalOrbit && hypotheticalNextTurn % 2 != 0 {
            return planet.angle
        }
        
        var projectedAngle = planet.angle + planet.orbit.turnAngularVelocity
        if projectedAngle >= (Double.pi * 2) {
            projectedAngle -= (Double.pi * 2)
        }
        return projectedAngle
    }
    
    private func computeCoordinatesForAngle(_ angle: Double, on orbit: OrbitType) -> CGPoint {
        let projectedX = systemCenterCoordinates.x + orbit.radius * CGFloat(cos(angle))
        let projectedY = systemCenterCoordinates.y + orbit.radius * CGFloat(sin(angle))
        return CGPoint(x: projectedX, y: projectedY)
    }
    
    /// Instantiates and renders translucent duplicate outlines mapping future planetary paths
    private func deployGhostProjections() {
        for planet in planetsRegistry {
            let futureAngle = computeFutureAngle(for: planet)
            let ghostCoordinates = computeCoordinatesForAngle(futureAngle, on: planet.orbit)
            
            createGhostPlanetNode(withId: planet.id, position: ghostCoordinates)
        }
    }
    
    private func clearGhostProjections() {
        for ghostNode in ghostPlanetNodesMap.values {
            ghostNode.removeFromParent()
        }
        ghostPlanetNodesMap.removeAll()
    }
    
    /// Validates spatial layout metrics to colorize lines dynamically based on travel windows
    private func evaluateTrajectoryColor(from origin: CGPoint, to currentTarget: CGPoint, targetPlanet: PlanetData?) -> SKColor {
        let totalLinearDistance = hypot(currentTarget.x - origin.x, currentTarget.y - origin.y)
        

        if totalLinearDistance > maxTravelDistanceThreshold {
            return .systemRed
        }
        
        if let destinationPlanet = targetPlanet, let originPlanet = selectedOriginPlanet {
            let innerLaneIncentive = originPlanet.orbit == .internalOrbit || originPlanet.orbit == .mediumOrbit
            if innerLaneIncentive && destinationPlanet.orbit == .mediumOrbit {
                return .systemGreen
            }
            return .systemYellow
        }

        // Inside your evaluateTrajectoryColor method in GameScene.swift:
        if let destinationPlanet = targetPlanet, let originPlanet = selectedOriginPlanet {
            // Task 12 Chiron Swarm Passive Hook: Check if player belongs to the Organic faction
            let isChironSwarm = originPlanet.ownerFaction == .chironSwarm
            let innerLaneIncentive = originPlanet.orbit == .internalOrbit || originPlanet.orbit == .mediumOrbit
            
            if isChironSwarm {
                // Organic ships ignore standard travel drag penalties if moving inline with orbit clock vectors
                print("🐜 Faction Passive: Chiron Swarm vector acceleration applied. Travel window is Green!")
                return .systemGreen
            }
            
            if innerLaneIncentive && destinationPlanet.orbit == .mediumOrbit {
                return .systemGreen
            }
            return .systemYellow
        }
        
        return .systemCyan
    }
    
    // MARK: - Task 9 Native Hardware Input Adapters
    
    #if os(macOS)
    /// Captures desktop physical mouse scroll wheel interactions to scale the viewport dynamically
    override func scrollWheel(with event: NSEvent) {
        guard let cameraNode = self.camera else { return }
        
        // Read the vertical delta movement step of the scroll wheel wheel
        let mouseScrollDelta = event.deltaY
        let dynamicScaleModifier: CGFloat = 0.05
        
        // Calculate new structural scale targets based on direction of rotation
        var targetCameraScale = cameraNode.xScale - (mouseScrollDelta * dynamicScaleModifier)
        
        // Apply strict boundaries checking to prevent breaking aesthetic proportions
        targetCameraScale = max(minCameraScaleThreshold, min(maxCameraScaleThreshold, targetCameraScale))
        
        // Apply scale matrices uniaxially to keep orthographic proportions intact
        cameraNode.xScale = targetCameraScale
        cameraNode.yScale = targetCameraScale
    }
    #endif

    // MARK: - Touch & Click Gesture Input Pipeline (Task 3 & 4)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        // Task 9 Mobile Pinch Multi-touch capture verification gate
        if touches.count == 2, let cameraNode = self.camera {
            let activeTouchArray = Array(touches)
            let touchPointAlpha = activeTouchArray[0].location(in: self)
            let touchPointBeta = activeTouchArray[1].location(in: self)
            
            // Calculate base hypotenuse scalar values separating input markers
            initialPinchDistanceFrame = hypot(touchPointAlpha.x - touchPointBeta.x, touchPointAlpha.y - touchPointBeta.y)
            baselineCameraScaleOnPinch = cameraNode.xScale
            return // Intercept pipeline downstream tracking to avoid firing navigation links on pinch
        }

        guard !isAnimatingTurn, let initialTouch = touches.first else { return }
        let targetTouchLocation = initialTouch.location(in: self)
        
        if let tappedNode = self.atPoint(targetTouchLocation) as? SKShapeNode,
           let planetId = planetNodesMap.first(where: { $0.value == tappedNode })?.key,
           let identifiedPlanet = planetsRegistry.first(where: { $0.id == planetId }) {
            
            // Task 13 Gesture Restrictor locks: Prevent picking illegal routes or planets out of order
            if currentTutorialStep == .step2BuildUnit && identifiedPlanet.ownerFaction != .orionScavenger {
                print("🛑 Tutorial Restrictor: Select your own home planet to access the construction layout grid.")
                return 
            }
            
            selectedOriginPlanet = identifiedPlanet
            createVisualTrajectoryLine(startingAt: tappedNode.position)
            deployGhostProjections()
            
            if let sceneView = self.view {
                let viewPosition = sceneView.convert(tappedNode.position, from: self)
                onPlanetSelected?(identifiedPlanet, viewPosition)
            }
        } else {
            onSpaceTapped?()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Task 9 Mobile Dynamic Zoom Scaling Tracker execution loop
        if touches.count == 2, let cameraNode = self.camera, initialPinchDistanceFrame > 0 {
            let activeTouchArray = Array(touches)
            let touchPointAlpha = activeTouchArray[0].location(in: self)
            let touchPointBeta = activeTouchArray[1].location(in: self)
            
            let currentPinchDistance = hypot(touchPointAlpha.x - touchPointBeta.x, touchPointAlpha.y - touchPointBeta.y)
            let scaleFactorRatio = initialPinchDistanceFrame / currentPinchDistance
            
            var targetPinchScale = baselineCameraScaleOnPinch * scaleFactorRatio
            targetPinchScale = max(minCameraScaleThreshold, min(maxCameraScaleThreshold, targetPinchScale))
            
            cameraNode.xScale = targetPinchScale
            cameraNode.yScale = targetPinchScale
            return // Halt normal drag route tracing indicators if user is pinching layout frames
        }

        guard !isAnimatingTurn,
              let activeTouch = touches.first,
              let originPlanet = selectedOriginPlanet,
              let targetLineNode = visualTrajectoryLineNode else { return }
        
        let currentTouchLocation = activeTouch.location(in: self)
        let startingPosition = fetchNodePosition(for: originPlanet.id) ?? systemCenterCoordinates
        
        var hoveredPlanetMatch: PlanetData? = nil
        if let underlyingNode = self.atPoint(currentTouchLocation) as? SKShapeNode,
           let planetId = planetNodesMap.first(where: { $0.value == underlyingNode })?.key {
            hoveredPlanetMatch = planetsRegistry.first(where: { $0.id == planetId })
        }
        
        let computedContextColor = evaluateTrajectoryColor(from: startingPosition, to: currentTouchLocation, targetPlanet: hoveredPlanetMatch)
        targetLineNode.strokeColor = computedContextColor
        
        let UIBezierPathFrame = UIBezierPath()
        UIBezierPathFrame.move(to: startingPosition)
        UIBezierPathFrame.addLine(to: currentTouchLocation)
        targetLineNode.path = UIBezierPathFrame.cgPath
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearGhostProjections()
        
        guard !isAnimatingTurn, let originPlanet = selectedOriginPlanet else { return }
        guard let finalTouch = touches.first else {
            clearActiveNavigationTrack()
            return
        }
        
        let releaseTouchLocation = finalTouch.location(in: self)
        
        if let hoveredNode = self.atPoint(releaseTouchLocation) as? SKShapeNode,
           let destinationPlanetId = planetNodesMap.first(where: { $0.value == hoveredNode })?.key,
           let identifiedDestination = planetsRegistry.first(where: { $0.id == destinationPlanetId }) {
            
            let startingPosition = fetchNodePosition(for: originPlanet.id) ?? systemCenterCoordinates
            let targetPosition = hoveredNode.position
            let computedColor = evaluateTrajectoryColor(from: startingPosition, to: targetPosition, targetPlanet: identifiedDestination)
            
            if originPlanet.id != identifiedDestination.id && computedColor != .systemRed {
                let newlyDispatchedRoute = TravelRoute(
                    originPlanetId: originPlanet.id,
                    destinationPlanetId: identifiedDestination.id,
                    estimatedTurns: computedColor == .systemGreen ? 1 : 2
                )
                pendingTravelRoutes.append(newlyDispatchedRoute)
                print("🚀 Verified Route Locked: Flight ETA is \(newlyDispatchedRoute.estimatedTurns) turns.")
            }
        }
        
        clearActiveNavigationTrack()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearGhostProjections()
        clearActiveNavigationTrack()
    }
    
    private func createVisualTrajectoryLine(startingAt position: CGPoint) {
        let initialBezierPath = UIBezierPath()
        initialBezierPath.move(to: position)
        initialBezierPath.addLine(to: position)
        
        let lineNode = SKShapeNode()
        lineNode.path = initialBezierPath.cgPath
        lineNode.strokeColor = SKColor.cyan.withAlphaComponent(0.8)
        lineNode.lineWidth = 3.0
        lineNode.zPosition = 10
        
        addChild(lineNode)
        visualTrajectoryLineNode = lineNode
    }
    
    private func clearActiveNavigationTrack() {
        selectedOriginPlanet = nil
        visualTrajectoryLineNode?.removeFromParent()
        visualTrajectoryLineNode = nil
    }
    
    // MARK: - Turn Execution Pipeline (Task 2 Complete Core)
    
    /// Public pipeline entry called from the main SwiftUI controller view layer button
    func processEndTurn() {
        guard !isAnimatingTurn else { return }
        
        
        if activePlanningCommander == .playerOne {
            isPlayerOnePlanningComplete = true
            // Toggle pointers and notify SwiftUI to prompt the intermediate handoff barrier panel view sheet
            activePlanningCommander = .playerTwo
            onTurnPhaseChanged?(activePlanningCommander)
            print("🛸 Pass & Play: Player 1 Locked instructions. Switching focus to Player 2.")
        } else {
            isPlayerTwoPlanningComplete = true
            
            // CRITICAL SYNC GATE: Both players successfully input their invisible actions matrix
            if isPlayerOnePlanningComplete && isPlayerTwoPlanningComplete {
                executeGlobalSimulationPhase()
            }
        }
        
        // Task 13 Tutorial state evaluation logic restrictions
        if currentTutorialStep == .step1Welcome {
            // Player successfully completed Step 1 objectives! Advance state parameters
            currentTutorialStep = .step2BuildUnit
            onTutorialDialogTriggered?("Excelente. Tu base ha extraído Polvo Estelar. Toca tu planeta y abre el menú del Martillo para construir un Bombardero.")
        } else if currentTutorialStep == .step2BuildUnit {
            print("🛑 Tutorial Alert: You must construct the requested asset before advancing the turn frame clock!")
            return // Rejects execution: Locks the turn pipeline until unit is created
        }

        // 1. Task 6 & 12 Economy Harvest Loop
        let playerControlledPlanets = planetsRegistry.filter { $0.orbit == .internalOrbit || $0.orbit == .mediumOrbit }
        var totalTurnHarvest = 0
        
        // Task 12 Silicate Nexus Passive Data Tracker variables
        var silicatePlanetCoordinates: [CGPoint] = []
        
        for planet in playerControlledPlanets {
            var currentYield = planet.stardustYield
            
            // Track Silicate positions to evaluate linear alignments later
            if planet.ownerFaction == .silicateNexus {
                let planetPos = CGPoint(x: planet.orbit.radius * CGFloat(cos(planet.angle)), 
                                        y: planet.orbit.radius * CGFloat(sin(planet.angle)))
                silicatePlanetCoordinates.append(planetPos)
            }
            
            totalTurnHarvest += currentYield
        }
        
        // Task 12 Silicate Nexus Alignment Verification Check:
        // Mathematically verify if two planets form a straight line crossing the origin (0,0) via cross-product math
        if silicatePlanetCoordinates.count >= 2 {
            let p1 = silicatePlanetCoordinates[0]
            let p2 = silicatePlanetCoordinates[1]
            // Cross product formula checking collinear vectors relative to the Sun center
            let collinearCrossProduct = abs(p1.x * p2.y - p1.y * p2.x)
            
            if collinearCrossProduct < 0.01 { // Math delta tolerance check for float precision
                let alignmentBonusMultiplier = 2
                totalTurnHarvest *= alignmentBonusMultiplier
                print("🤖 Faction Passive: Silicate Nexus geometric solar alignment detected! Stardust harvest doubled to: \(totalTurnHarvest)")
            }
        }

        // Inside your processEndTurn() task pipeline condition validator:
        if currentTurn == self.supernovaTriggerTurnThreshold {
            self.onSupernovaTriggered?()
            print("🚨 WARNING: Star core critical mass threshold breached! Supernova countdown engaged.")
            
            // Task 18: Target the core Sun geometry node and apply an endless instable heartbeat sequence
            if let sunNode = self.childNode(withName: "core_sun_node") as? SKShapeNode {
                let heartbeatAction = SKAction.sequence([
                    SKAction.run { sunNode.fillColor = .red; sunNode.strokeColor = .orange },
                    SKAction.scale(to: 1.15, duration: 0.4),
                    SKAction.run { sunNode.fillColor = .orange; sunNode.strokeColor = .yellow },
                    SKAction.scale(to: 0.95, duration: 0.4)
                ])
                sunNode.run(SKAction.repeatForever(heartbeatAction))
            }
        }


        // Credit the calculated credits to our observed bank instance layer
        StardustManager.shared.creditStardust(amount: totalTurnHarvest)
        
        isAnimatingTurn = true
        turnDelegate?.gameSceneWillAdvanceTurn()
        
        // 2. Task 5 & 12 Core Combat Resolution Hook
        // Capture total financial values operating in the sector before triggering casualties
        let globalCasualtiesValue = calculateRosterCostPriorToCombat()
        
        executePlanetaryOrbitCombats()
        
        // Task 1 Core Victory Hook: Process holding metrics immediately after checking combat casualties
        processSolarCoreVictoryMetrics()
        
        globalTurnCounter += 1


        let postCombatCasualtiesValue = calculateRosterCostPostCombat()
        let totalStardustBrokeInBattle = max(0, globalCasualtiesValue - postCombatCasualtiesValue)
        
        // Task 12 Orion Scavenger Passive Hook: Extract 25% value of any ship destroyed in space
        // Mock Player Check: If local player faction profile is Orion
        let playerIsScavenger = true // Placeholder condition check for setup configurations
        if playerIsScavenger && totalStardustBrokeInBattle > 0 {
            let salvagePayback = Int(Float(totalStardustBrokeInBattle) * 0.25)
            StardustManager.shared.creditStardust(amount: salvagePayback)
            print("🏴‍☠️ Faction Passive: Orion Scavengers extracted \(salvagePayback) Stardust from combat scrap debris fields!")
        }
        
    
        globalTurnCounter += 1
        print("⚡️ Internal Game Loop Clock advanced to Turn: \(globalTurnCounter)")
        
        let animationDuration: TimeInterval = 0.5
        var planetsToAnimateCount = 0
        var completedAnimationsCount = 0
        
        let shiftingIndices = planetsRegistry.enumerated().filter { (_, planet) -> Bool in
            if planet.orbit == .externalOrbit && globalTurnCounter % 2 != 0 {
                return false
            }
            return true
        }.map { $0.offset }
        
        planetsToAnimateCount = shiftingIndices.count
        
        if planetsToAnimateCount == 0 {
            self.finalizeTurnState()
            return
        }
        
        for index in shiftingIndices {
            let currentPlanet = planetsRegistry[index]
            planetsRegistry[index].angle += currentPlanet.orbit.turnAngularVelocity
            
            if planetsRegistry[index].angle >= (Double.pi * 2) {
                planetsRegistry[index].angle -= (Double.pi * 2)
            }
            
            // Inside your processEndTurn() method, locate the planetary animation completion block:
            if let targetVisualNode = planetNodesMap[currentPlanet.id] {
                updateVisualCoordinates(for: planetsRegistry[index], targetNode: targetVisualNode, animationDuration: animationDuration) { [weak self] in
                    completedAnimationsCount += 1
                    if completedAnimationsCount == planetsToAnimateCount {
                        
                        // --- Task 14 Supernova Activation Hook Injection Point ---
                        if let currentTurn = self?.globalTurnCounter {
                            if currentTurn == self?.supernovaTriggerTurnThreshold {
                                // First trigger alert notice to the HUD layer coordinator bindings
                                self?.onSupernovaTriggered?()
                                print("🚨 WARNING: Star core critical mass threshold breached! Supernova countdown engaged.")
                            } else if currentTurn > self?.supernovaTriggerTurnThreshold ?? 0 {
                                // Turn 16, 17, 18 onwards: Systematically purge outer lanes sequentially
                                self?.executeSupernovaOrbitCollapse()
                            }
                        }
                        
                        self?.finalizeTurnState()
                    }
                }
            }
        }
    }
    
    /// Executes combined combats and updates the physical orbital canvas transforms across Metal loops
    private func executeGlobalSimulationPhase() {
        isAnimatingTurn = true
        turnDelegate?.gameSceneWillAdvanceTurn()
        
        // Execute Task 6 passive harvest yields here...
        
        // Execute Task 5 Rock-Paper-Scissors clash metrics matching combined planned fleets actions
        executePlanetaryOrbitCombats()
        
        globalTurnCounter += 1
        print("⚡️ System Loop Clock advanced to Turn: \(globalTurnCounter)")
        
        // ... (Keep your animation loops for shifting nodes foward from the previous tasks intact here)
    }
    
    /// Invoked directly via SwiftUI buttons on the handoff curtain screen once the physical device changes hands
    func startActivePlanningPhase() {
        onTurnCycleCompleted?() // Reloads the 30-second timers safely
    }

    // Update your existing finalizeTurnState helper method to clear local caches cleanly:
    private func finalizeTurnState() {
        isAnimatingTurn = false
        // Clear the dual planning buffers back to default baseline values for the next round cycle
        isPlayerOnePlanningComplete = false
        isPlayerTwoPlanningComplete = false
        activePlanningCommander = .playerOne
        
        turnDelegate?.gameSceneDidFinishAdvanceTurn()
        onTurnPhaseChanged?(activePlanningCommander) // Reset HUD tracker layout nodes
    }
    
    // MARK: - Task 13 UI Interaction Callback Connectors
    
    /// Public pipeline invoked from SwiftUI radial menu interfaces once a vessel construction array index settles
    func notifyUnitBuilt(type: ShipClass) {
        if currentTutorialStep == .step2BuildUnit && type == .bomber {
            currentTutorialStep = .step3LaunchFleet
            onTutorialDialogTriggered?("¡Nave lista! Mantén presionado tu planeta y arrastra una ruta hacia el Planeta Neutral de la órbita media para conquistarlo.")
        }
    }
    
    /// Public pipeline invoked from the SwiftUI drop zone container after confirming a route tracking release target
    func notifyRouteDispatched() {
        if currentTutorialStep == .step3LaunchFleet {
            currentTutorialStep = .step4CombatCard
            onTutorialDialogTriggered?("Flota en camino. En el siguiente turno habrá un combate. Usa tu carta táctica Campo de Fuerza para mitigar daños.")
        }
    }
    
    /// Call this hook inside your executePlanetaryOrbitCombats loop right after resolving card applications
    func notifyCardPlayedInTutorial() {
        if currentTutorialStep == .step4CombatCard {
            currentTutorialStep = .step5FreePlay
            onTutorialDialogTriggered?("¡Bien hecho! Has aprendido las bases. Ahora destruye la Avanzada Nexo enemiga para asegurar la victoria total.")
        }
    }

    /// Public endpoint called directly from SwiftUI views to instantiate physical vessels into game data models
    func spawnShipOnPlanet(id planetId: UUID, type shipClass: ShipClass) {
        guard let registryIndex = planetsRegistry.firstIndex(where: { $0.id == planetId }) else { return }
        
        // 1. Instantiate the targeted new ship object architecture blueprint metrics
        let newlyBuiltShip = ShipUnit(type: shipClass)
        
        // 2. Fetch or create a valid functional squadron structure block container
        var activeSquadron = planetsRegistry[registryIndex].squadron ?? CombatSquadron(ownerFaction: planetsRegistry[registryIndex].orbit)
        activeSquadron.ships.append(newlyBuiltShip)
        
        // --- Task 6/7 Audio Trigger Hook Injection ---
        // Play construction assembly alerts seamlessly across platform environments
        AudioManager.shared.playSFX(named: "sfx_construction_complete", volume: 0.8)

        // 3. Write modified database matrices back onto our primary telemetry data layer
        planetsRegistry[registryIndex].squadron = activeSquadron
        print("🛠️ Factory: Successfully deployed 1x [\(shipClass)] over planet [\(planetsRegistry[registryIndex].name)]. Total fleet size: \(activeSquadron.ships.count)")
        
        // 4. UI Feedback: Trigger a flash effect animation on the physical planet node layout container
        if let targetVisualNode = planetNodesMap[planetId] {
            let corePulseAction = SKAction.sequence([
                SKAction.run { targetVisualNode.strokeColor = .cyan },
                SKAction.scale(to: 1.25, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15),
                SKAction.run { targetVisualNode.strokeColor = .white }
            ])
            targetVisualNode.run(corePulseAction)
        }
    }

    private func applyDamageToClass(_ roster: inout [ShipUnit], targetClass: ShipClass, distributedDamage: Float, planetId: UUID) {
        var runningDamagePool = distributedDamage
        for index in 0..<roster.count where roster[index].type == targetClass && roster[index].currentHealth > 0 {
            if runningDamagePool <= 0 { break }
            let initialHealth = roster[index].currentHealth
            roster[index].currentHealth -= runningDamagePool
            runningDamagePool -= initialHealth
            
            // --- Task 5 Audio Trigger Hook Injection ---
            if roster[index].currentHealth <= 0 {
                // Ship unit destroyed! Fire deep space bomber explosion acoustics
                // Fetch the screen position vectors of the parent planetary body hosting the fight
                if let planetScreenPosition = fetchNodePosition(for: planetId) {
                    // Inject random position offsets slightly so multiple explosions don't stack on the exact same pixel
                    let randomOffsetX = CGFloat.random(in: -15...15)
                    let randomOffsetY = CGFloat.random(in: -15...15)
                    let blastSpawnPoint = CGPoint(x: planetScreenPosition.x + randomOffsetX, 
                                                  y: planetScreenPosition.y + randomOffsetY)
                    
                    // Dispatch the kinetic explosion system frame into Metal loops
                    triggerExplosionAt(position: blastSpawnPoint, unitClass: targetClass)
                }
                AudioManager.shared.playSFX(named: "sfx_bomber_explosion", volume: 0.7)
            } else {
                // Ship damaged but survived, fire laser shield impact acoustics
                AudioManager.shared.playSFX(named: "sfx_laser_impact", volume: 0.4)
            }
        }
    }

    // MARK: - Task 5 Automatic Core Combat Engine
    /// Algorithmic loops resolving rock-paper-scissors ship casualties prior to shifting orbits
    private func executePlanetaryOrbitCombats() {
        for index in 0..<planetsRegistry.count {
            var planet = planetsRegistry[index]
            // Validate if an active squadron exists with functional units
            guard var currentSquad = planet.squadron, currentSquad.ships.count > 0 else { continue }
            
            // --- Task 8 Insertion Check ---
            // Trigger the callback pipeline to pop up the SwiftUI combat overlay canvas view frame
            // Note: In local testing, this executes synchronously; the UI intercept model pauses physics visually
            onCombatInitiated?(planet)

            print("⚔️ Conflict triggered over planetary system: (planet.name)")
            // Sandbox Scenario: Emulate an invader fleet coming into conflict
            var invaderSquad = CombatSquadron(ownerFaction: .externalOrbit)
            invaderSquad.ships = [ShipUnit(type: .bomber), ShipUnit(type: .fighter)]
            // --- ROUND 1: Fighter Anti-Bomber Initiative ---
            let defenderFighterCount = currentSquad.count(of: .fighter)
            let invaderFighterCount = invaderSquad.count(of: .fighter)
            var defenderFighterDamage = Float(defenderFighterCount) * ShipUnit(type: .fighter).attackDamage
            let invaderFighterDamage = Float(invaderFighterCount) * ShipUnit(type: .fighter).attackDamage
            
            // Apply Task 8 Modifier adjustments to Round 1 metrics
            if let appliedModifier = activeInjectedModifier {
                switch appliedModifier {
                case .fighterFrenzy:
                    defenderFighterDamage *= 2.0 // Double fighter tactical damage rating!
                    print("🔥 Maneuver Active: Fighter Damage multiplied by 2x!")
                case .shieldBoost:
                    print("🛡️ Maneuver Active: Shielding absorbed initial Round 1 impacts.")
                default: break
                }
            }
            
            // Apply calculated damages normally
            if activeInjectedModifier != .shieldBoost {
                applyDamageToClass(&invaderSquad.ships, targetClass: .bomber, distributedDamage: defenderFighterDamage, planetId: planet.id)
            }
            
            applyDamageToClass(&currentSquad.ships, targetClass: .bomber, distributedDamage: invaderFighterDamage, planetId: planet.id)
            activeInjectedModifier = nil // Reset the tactical card effect after application
            
            // --- ROUND 2: Frigate Anti-Fighter Counter ---
            let defenderFrigateCount = currentSquad.count(of: .frigate)
            let invaderFrigateCount = invaderSquad.count(of: .frigate)
            let totalDefenderFrigateDamage = Float(defenderFrigateCount) * ShipUnit(type: .frigate).attackDamage
            let totalInvaderFrigateDamage = Float(invaderFrigateCount) * ShipUnit(type: .frigate).attackDamage
            applyDamageToClass(&invaderSquad.ships, targetClass: .fighter, distributedDamage: totalDefenderFrigateDamage, planetId: planet.id)
            applyDamageToClass(&currentSquad.ships, targetClass: .fighter, distributedDamage: totalInvaderFrigateDamage, planetId: planet.id)
            // --- ROUND 3: Bomber Siege Action ---
            let defenderBomberCount = currentSquad.count(of: .bomber)
            let invaderBomberCount = invaderSquad.count(of: .bomber)
            let totalDefenderBomberDamage = Float(defenderBomberCount) * ShipUnit(type: .bomber).attackDamage
            let totalInvaderBomberDamage = Float(invaderBomberCount) * ShipUnit(type: .bomber).attackDamage
            let defenderShipsLeft = currentSquad.ships.filter { $0.currentHealth > 0 }.count
            // If planetary defense is empty, bomber damage impacts the shield metrics directly
            if defenderShipsLeft == 0 && totalInvaderBomberDamage > 0 {
                planet.shieldHealth -= totalInvaderBomberDamage
                print("💥 Structural damage dealt to planetary shields! Remaining Shield: (planet.shieldHealth)")
            } else {
                applyDamageToClass(&invaderSquad.ships, targetClass: .frigate, distributedDamage: totalDefenderBomberDamage, planetId: planet.id)
            }
            applyDamageToClass(&currentSquad.ships, targetClass: .frigate, distributedDamage: totalInvaderBomberDamage, planetId: planet.id)
            // Purge dead assets out of memory arrays
            currentSquad.ships.removeAll { $0.currentHealth <= 0 }
            planetsRegistry[index].squadron = currentSquad
            planetsRegistry[index].shieldHealth = max(0, planet.shieldHealth)
        }
    }

    
    /// Algorithmic function called sequentially during late-game frames to shrink the valid map canvas coordinates
    private func executeSupernovaOrbitCollapse() {
        // Ensure there are still active orbit zones left to destroy
        guard !activeOrbitLanes.isEmpty else { return }
        
        // 1. Target the outermost active ring lane in the collection matrix
        let targetOrbitToDestroy = activeOrbitLanes.removeFirst()
        print("🚨 SUPERNOVA: Orbit track \(targetOrbitToDestroy) is collapsing into stellar fire!")
        
        // Notify the root UI overlay layer to trigger screen shakes or emergency alarms
        onOrbitCollapsed?(targetOrbitToDestroy)
        
        // Task 18 Hook Injection: Trigger the massive expand blast wavefront into Metal loops
        triggerSupernovaShockwave(reaching: targetOrbitToDestroy.radius)
        // Play deep deep space explosion acoustic effect from our Task 6/7 audio sub-engine manager
        AudioManager.shared.playSFX(named: "sfx_bomber_explosion", volume: 1.0) 

        // 2. Scan and query the registry to filter out planetary bodies stationed on the condemned radius
        let planetsInDangerZone = planetsRegistry.filter { $0.orbit == targetOrbitToDestroy }
        
        for planet in planetsInDangerZone {
            if let planetNode = planetNodesMap[planet.id] {
                // Task 18 Particle Fragment attachment: generate fragmentation prior to removal
                let fragmentEmitter = SKEmitterNode()
                fragmentEmitter.particleTexture = generateDotTexture(color: .systemRed, size: CGSize(width: 6, height: 6))
                fragmentEmitter.particleBirthRate = 150
                fragmentEmitter.numParticlesToEmit = 40
                fragmentEmitter.particleSpeed = 60
                fragmentEmitter.emissionAngle = 0
                fragmentEmitter.emissionAngleRange = 2 * CGFloat.pi
                fragmentEmitter.particleLifetime = 0.4
                planetNode.addChild(fragmentEmitter)
                
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.3)
                let scaleDownAction = SKAction.scale(to: 0.1, duration: 0.3)
                let explosionSequence = SKAction.group([fadeOutAction, scaleDownAction])
                
                planetNode.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.2), // Espera que la onda expansiva del sol lo alcance visualmente
                    explosionSequence, 
                    SKAction.removeFromParent()
                ]))
            }
            
            // B. Purge structural indexing markers safely out of our caching dictionary map registries
            planetNodesMap.removeValue(forKey: planet.id)
            ghostPlanetNodesMap.removeValue(forKey: planet.id)
            planetsRegistry.removeAll { $0.orbit == targetOrbitToDestroy }

            print("💀 Environmental Hazard: Planet \(planet.name) was vaporized by the Supernova explosion wavefront.")
        }
        
        // C. Clean up the internal logical collection registers to prevent pointer leakage bugs
        planetsRegistry.removeAll { $0.orbit == targetOrbitToDestroy }
    }
    
    // MARK: - Task 12 Economy Salvage Helper Algorithms

    /// Computes the collective financial Stardust worth of all active ships across the galaxy before combat resolves
    private func calculateRosterCostPriorToCombat() -> Int {
        var totalCumulativeValue = 0
        
        for planet in planetsRegistry {
            // Read the current local squadron state if it exists
            if let activeSquad = planet.squadron {
                for ship in activeSquad.ships where ship.currentHealth > 0 {
                    totalCumulativeValue += fetchUnitResourceCost(type: ship.type)
                }
            }
        }
        
        return totalCumulativeValue
    }

    /// Computes the collective financial Stardust worth of all surviving ships after casualties have been processed
    private func calculateRosterCostPostCombat() -> Int {
        var totalCumulativeValue = 0
        
        for planet in planetsRegistry {
            if let activeSquad = planet.squadron {
                // Only aggregate the value profile parameters of assets that successfully survived with health > 0
                for ship in activeSquad.ships where ship.currentHealth > 0 {
                    totalCumulativeValue += fetchUnitResourceCost(type: ship.type)
                }
            }
        }
        
        return totalCumulativeValue
    }

    /// Helper mapping table to read the blueprint resource weight index per vessel class
    private func fetchUnitResourceCost(type: ShipClass) -> Int {
        switch type {
        case .fighter: return 100
        case .frigate: return 250
        case .bomber:  return 400
        }
    }

        // MARK: - Task 15 Procedural Stellar Background Factory
    
    /// Generates a single dot texture at runtime to feed the particle emitter engine without external file dependencies
    private func generateDotTexture(color: SKColor, size: CGSize) -> SKTexture {
        let rect = CGRect(origin: .zero, size: size)
        #if os(macOS)
        let image = NSImage(size: size)
        image.lockFocus()
        color.set()
        let path = NSBezierPath(ovalIn: rect)
        path.fill()
        image.unlockFocus()
        return SKTexture(image: image)
        #else
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return SKTexture() }
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return SKTexture(image: image ?? UIImage())
        #endif
    }
    
    /// Constructs and injects a layered starfield background to establish depth via parallax anchoring
    private func deployStellarBackgroundDrift() {
        let starTexture = generateDotTexture(color: .white, size: CGSize(width: 8, height: 8))
        
        // --- Layer A: Deep Space Distant Stars (Slow, Small, Low Opacity) ---
        let deepStarfield = SKEmitterNode()
        deepStarfield.particleTexture = starTexture
        deepStarfield.particleBirthRate = 8.0
        deepStarfield.particleLifetime = 35.0
        deepStarfield.particleSpeed = 2.0
        deepStarfield.particleSpeedRange = 1.0
        
        // Scatter distribution boundaries to cover maximum wide zoom limits
        deepStarfield.particlePositionRange = CGVector(dx: 2000, dy: 2000)
        deepStarfield.particleScale = 0.08
        deepStarfield.particleScaleRange = 0.04
        deepStarfield.particleAlpha = 0.15
        deepStarfield.particleAlphaRange = 0.1
        deepStarfield.particleColorBlendFactor = 1.0
        
        // Deep stars drift in a slow constant cosmic sweep direction
        deepStarfield.emissionAngle = CGFloat.pi / 4 // 45 degrees linear drift
        deepStarfield.zPosition = -15 // Absolute deepest graph layer placement
        
        // Fast-forward initial particle state simulation timeline so the map launches pre-populated with stars
        deepStarfield.advanceSimulationTime(35.0)
        addChild(deepStarfield)
        
        // --- Layer B: Mid Space Sector Dust (Slightly faster, Neon Cyan/Yellow tints) ---
        let cosmicDustField = SKEmitterNode()
        cosmicDustField.particleTexture = starTexture
        cosmicDustField.particleBirthRate = 4.0
        cosmicDustField.particleLifetime = 25.0
        cosmicDustField.particleSpeed = 5.0
        cosmicDustField.particlePositionRange = CGVector(dx: 1800, dy: 1800)
        cosmicDustField.particleScale = 0.15
        cosmicDustField.particleScaleRange = 0.08
        cosmicDustField.particleAlpha = 0.3
        cosmicDustField.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0.0, 0.35, 0.0], times: [0.0, 0.2, 1.0])

        
        cosmicDustField.emissionAngle = CGFloat.pi / 3 // 60 degrees drift
        cosmicDustField.zPosition = -12 // Placed just below the orbit line layers
        
        cosmicDustField.advanceSimulationTime(25.0)
        addChild(cosmicDustField)
    }

    /// Generates a customized thrust particle trail dynamically matched to a faction's visual signature
    private func createEngineTrailNode(for faction: FactionType) -> SKEmitterNode {
        let trailEmitter = SKEmitterNode()
        
        // Reutilizamos la textura circular en caché de la Task 15
        let dotTexture = generateDotTexture(color: .white, size: CGSize(width: 6, height: 6))
        trailEmitter.particleTexture = dotTexture
        
        // Parámetros de emisión: Alta tasa de nacimiento, vida muy corta para simular propulsión
        trailEmitter.particleBirthRate = 45.0
        trailEmitter.particleLifetime = 0.35
        trailEmitter.particleSpeed = 12.0
        trailEmitter.particleSpeedRange = 4.0
        
        // Angulación inversa: Las partículas deben salir disparadas hacia atrás del vector de movimiento
        trailEmitter.emissionAngle = CGFloat.pi // 180 grados (atrás)
        trailEmitter.emissionAngleRange = Double.pi / 6  // Pequeña dispersión cónica de 30 grados
        
        // Escala decreciente acelerada: Las partículas se encogen rápidamente hasta desaparecer
        trailEmitter.particleScale = 0.18
        trailEmitter.particleScaleRange = 0.05
        trailEmitter.particleScaleSpeed = -0.4 // Encogimiento constante
        
        // Asignación de Color Neón Asimétrico basado estrictamente en la Task 12
        let trailColor: SKColor
        switch faction {
        case .chironSwarm:
            trailColor = .systemGreen    // Plasma biológico insectoide
        case .silicateNexus:
            trailColor = .systemCyan     // Iónico computacional cristalino
        case .orionScavenger:
            trailColor = .systemOrange   // Combustión industrial chatarrera
        }
        
        trailEmitter.particleColor = trailColor
        trailEmitter.particleColorBlendFactor = 1.0
        trailEmitter.zPosition = 8 // Renderizado justo por debajo del sprite de la nave
        
        return trailEmitter
    }

        // MARK: - Task 17 Procedural Explosion Engine
    
    /// Triggers a localized multi-particle blast ring mapping casualties based on ship sizes
    private func triggerExplosionAt(position: CGPoint, unitClass: ShipClass) {
        let explosionEmitter = SKEmitterNode()
        
        // Reutilizamos la textura circular en caché de las Tareas anteriores
        let fragmentTexture = generateDotTexture(color: .white, size: CGSize(width: 8, height: 8))
        explosionEmitter.particleTexture = fragmentTexture
        
        // Configuración de ráfaga única (One-Shot Blast)
        explosionEmitter.numParticlesToEmit = 0 // Liberado por ráfagas fijas manuales
        explosionEmitter.particleBirthRate = 0  // Apagado para generación continua
        
        // Escalar la intensidad física y el conteo de escombros de acuerdo a la clase destruida
        let particleCount: Int
        let blastSpeed: CGFloat
        let particleColor: SKColor
        
        switch unitClass {
        case .fighter:
            particleCount = 25
            blastSpeed = 80.0
            particleColor = .orange
        case .frigate:
            particleCount = 55
            blastSpeed = 140.0
            particleColor = .yellow
        case .bomber:
            particleCount = 100
            blastSpeed = 220.0
            particleColor = .systemRed
        }
        
        // Parámetros vectoriales radiales: Expansión en 360 grados fijos
        explosionEmitter.emissionAngle = 0.0
        explosionEmitter.emissionAngleRange = 2 * CGFloat.pi
        
        // Cinética de la explosión con amortiguación
        explosionEmitter.particleSpeed = blastSpeed
        explosionEmitter.particleSpeedRange = blastSpeed * 0.4
        explosionEmitter.particleLifetime = 0.6 // Duración muy corta para máxima intensidad
        explosionEmitter.particleLifetimeRange = 0.2
        
        // Desvanecimiento acelerado por código (Scale & Alpha decay)
        explosionEmitter.particleScale = 0.25
        explosionEmitter.particleScaleRange = 0.1
        explosionEmitter.particleScaleSpeed = -0.5
        
        explosionEmitter.particleColor = particleColor
        explosionEmitter.particleColorBlendFactor = 1.0
        explosionEmitter.position = position
        explosionEmitter.zPosition = 12 // Renderizado por encima de todos los elementos estelares
        
        addChild(explosionEmitter)
        
        // Inyectar el número de partículas exactas como ráfaga instantánea
        explosionEmitter.numParticlesToEmit = particleCount
        
        // Programar la autodestrucción del nodo emisor de RAM una vez finalizada la ráfaga
        let cleanUpSequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.8), // Margen de seguridad superior al lifetime
            SKAction.removeFromParent()       // Purga absoluta del árbol de nodos de Metal
        ])
        explosionEmitter.run(cleanUpSequence)
    }

        // MARK: - Task 18 Supernova Shockwave Particle Factory
    
    /// Triggers an expanding ring of solar fire mapping the collapse of an orbit lane
    private func triggerSupernovaShockwave(reaching radius: CGFloat) {
        let shockwaveEmitter = SKEmitterNode()
        
        // Reutilizamos la textura circular en caché de las Tareas anteriores
        let fireTexture = generateDotTexture(color: .white, size: CGSize(width: 10, height: 10))
        shockwaveEmitter.particleTexture = fireTexture
        
        // Configuración de alta densidad perimetral radial (360 grados fijos)
        shockwaveEmitter.particleBirthRate = 300.0
        shockwaveEmitter.particleLifetime = 0.5
        // Las partículas se desplazan hacia afuera desde el centro del emisor
        let calculatedSpeed = radius / 0.5 // Alcanza el radio exacto en el tiempo de vida (0.5s)
        shockwaveEmitter.particleSpeed = calculatedSpeed
        
        shockwaveEmitter.emissionAngle = 0.0
        shockwaveEmitter.emissionAngleRange = 2 * CGFloat.pi
        
        // Configuración cosmética de color fuego incandescente
        shockwaveEmitter.particleColor = .systemOrange
        shockwaveEmitter.particleColorBlendFactor = 1.0
        // Secuencia de degradación cromática: de Naranja Fuego a Rojo Nova y luego Ceniza
        shockwaveEmitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [
            SKColor.yellow,
            SKColor.orange,
            SKColor.red,
            SKColor.darkGray
        ], times: [
            0.0 as NSNumber,
            0.3 as NSNumber,
            0.7 as NSNumber,
            1.0 as NSNumber
        ])

        shockwaveEmitter.particleScale = 0.3
        
        shockwaveEmitter.particleScale = 0.3
        shockwaveEmitter.particleScaleSpeed = -0.4
        shockwaveEmitter.position = systemCenterCoordinates
        shockwaveEmitter.zPosition = 14 // Renderizado por encima de todas las órbitas y naves
        
        addChild(shockwaveEmitter)
        
        // Cronometrar el apagado del emisor y su remoción limpia de la memoria RAM
        let shockwaveSequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { shockwaveEmitter.particleBirthRate = 0 }, // Deja de generar chispas en el límite
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent() // Purga absoluta del árbol gráfico de Metal
        ])
        shockwaveEmitter.run(shockwaveSequence)
    }

}
