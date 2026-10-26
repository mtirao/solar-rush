# 🚀 SOLAR RUSH - Game Design & Development Blueprint

Bienvenido al documento de desarrollo central de **Solar Rush**, un juego de estrategia espacial híbrido diseñado de forma nativa para el ecosistema de Apple (iOS y macOS vía Mac Catalyst) utilizando una arquitectura limpia compuesta por **SpriteKit (Motor de Físicas y Renderizado 2D)** y **SwiftUI (HUD, Interfaces Reactivas y Menús Contextuales)**.

---

## 🧭 1. VISIÓN GENERAL DEL JUEGO
* **Nombre Comercial:** Solar Rush  
* **Eslogan Táctico:** *"Conquista la galaxia. Domina las órbitas. En solo 10 minutos."*  
* **Género:** Micro 4X / Estrategia Espacial Rápida por Turnos.  
* **Plataformas de Lanzamiento:** iOS (Móviles/Tabletas) y macOS (Escritorio vía Mac Catalyst).  
* **Bucle de Juego Principal (Core Loop):**  
  Planificar trayectorias vectoriales a ciegas (30s) -> Resolver Fin de Turno -> Ejecutar Combates por Rondas Automáticas -> Cosechar Recursos (Polvo Estelar) -> Expandir Flotas e Interfaces Radiales.

---

## 🏢 2. ARQUITECTURA TÉCNICA DEL PROYECTO

### 📂 Estructura del Árbol de Directorios
El proyecto se organiza bajo la siguiente jerarquía modular para independizar la lógica de datos del lienzo gráfico del motor:

```text
SolarRush/
├── project.yml                 # Especificación de XcodeGen para compilación multiplataforma
├── setup.sh                    # Script automatizado de instalación de dependencias locales
├── CLAUDE.md                   # Este manifiesto técnico de desarrollo
└── Sources/
    ├── App/
    │   ├── SolarRushApp.swift  # Ciclo de vida y punto de entrada de la aplicación
    │   └── Assets.xcassets     # Catálogo de imágenes, paletas de colores y SFX
    ├── Core/
    │   ├── GameScene.swift     # Núcleo del motor SpriteKit (Órbitas, Gestos e IA)
    │   ├── AudioManager.swift  # Controlador AVFoundation para SFX Concurrentes y BGM
    │   └── Models/
    │       ├── PlayerIdentity.swift # Diferenciación local de Comandantes (Versus)
    │       ├── ShipModels.swift     # Roster de Cazas, Fragatas y Bombarderos (Task 5)
    │       ├── CardModels.swift     # Datos de cartas de habilidad (Task 8)
    │       ├── FactionModels.swift  # Perfil de razas asimétricas (Task 12)
    │       ├── CoreVictoryModel.swift # Telemetría de captura del Sol Central
    │       └── ProgressionManager.swift # Gestor de fragmentos estelares y cuenta XP
    └── UI/
        ├── HUD/
        │   └── PassAndPlayHUD.swift # Temporizador de 30s y cortina de privacidad
        └── Menus/
            ├── FactionSelectionView.swift # Pantalla de pre-partida y selección de raza
            ├── RadialMenuView.swift       # Comandos concéntricos SwiftUI sobre planetas
            ├── BuildSheetView.swift       # Panel del martillo para instanciación de naves
            ├── CombatOverlayView.swift    # Pantalla cinemática de 5s y arrastre de cartas
            └── MatchSummaryView.swift     # Panel de fin de juego y animación de score
```

### ⚙️ Archivo de Configuración de XcodeGen (`project.yml`)
Este archivo automatiza la generación del `.xcodeproj` sin necesidad de rastrear binarios conflictivos en Git:

```yaml
name: SolarRush
options:
  bundleIdPrefix: com.tuusuario
  developmentTeam: "" 
  deploymentTarget:
    iOS: "17.0"
    macOS: "14.0"
settings:
  base:
    SWIFT_VERSION: 5.0
    GENERATE_INFOPLIST_FILE: YES
    MARKETING_VERSION: 1.0.0
    CURRENT_PROJECT_VERSION: 1
targets:
  SolarRush:
    type: application
    platform: [iOS, macOS]
    deploymentTarget:
      iOS: "17.0"
      macOS: "14.0"
    sources:
      - path: Sources
      - path: Sources/App/Assets.xcassets
        type: folder
        buildPhase: resources
    frameworks:
      - sdk: SpriteKit.framework
      - sdk: SwiftUI.framework
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.tuusuario.SolarRush
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
        SUPPORTS_MACCATALYST: YES
        DERIVED_DATA_DIR: Build
      configs:
        Debug:
          MTL_ENABLE_DEBUG_INFO: INCLUDE_SOURCE
        Release:
          MTL_ENABLE_DEBUG_INFO: NO
```

### 🚀 Script de Automatización de Inicialización (`setup.sh`)
```bash
#!/bin/bash
set -e
echo "🛸 Validando dependencias para Solar Rush..."
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew no está instalado. Instálalo en https://brew.sh antes de continuar."
    exit 1
fi
if ! command -v xcodegen &> /dev/null; then
    echo "📥 Instalando XcodeGen vía Homebrew..."
    brew install xcodegen
else
    echo "✅ XcodeGen ya se encuentra instalado."
fi
echo "⚙️ Generando proyecto de Xcode a partir de project.yml..."
xcodegen generate
echo "🎉 ¡Todo listo! Ya puedes abrir SolarRush.xcodeproj y comenzar a programar."
```

---

## 📋 3. BACKLOG DE DESARROLLO TÉCNICO COMPLETO (TICKETS DE GITHUB)

### 🟩 FASE 1: El Núcleo Técnico (MVP Funcional)

#### Task 1: Lógica matemática de las 3 órbitas concéntricas (Sistema de Coordenadas)
* **Descripción:** Implementar el sistema de posicionamiento del mapa basado en coordenadas polares en lugar de una cuadrícula tradicional. Los planetas deben orbitar de manera perfecta alrededor de un centro fijo.
* **Criterios de Aceptación:**
  - [ ] El punto de origen central (`0,0` para el Sol) se encuentra configurado de forma fija en la escena.
  - [ ] Se definen matemáticamente tres radios concéntricos bien diferenciados (Interno, Medio, Externo).
  - [ ] Los planetas solo se instancian y se reposicionan sobre las coordenadas calculadas por dichos carriles.

#### Task 2: Script de rotación automática de planetas al finalizar el turno
* **Descripción:** Crear el motor que gestiona el paso del tiempo físico en el espacio. Al presionar "Fin de Turno", los planetas deben avanzar de posición angular de forma independiente según el carril en el que se encuentren.
* **Criterios de Aceptación:**
  - [ ] Al procesar el fin de turno, los planetas recalculan sus ángulos antes de ejecutar combates.
  - [ ] Las velocidades de rotación angular respetan la proporción estipulada (Interno: 60°/turno, Medio: 30°/turno, Externo: 15°/turno).
  - [ ] Los planetas de la órbita externa solo avanzan en turnos pares, permaneciendo estáticos en los impares.

#### Task 3: Sistema de arrastre táctil/clic para trazar rutas entre planetas
* **Descripción:** Desarrollar el sistema interactivo principal para enviar naves. El jugador debe poder pinchar un planeta de origen y arrastrar un vector táctil o de ratón hacia el planeta que desea atacar o colonizar.
* **Criterios de Aceptación:**
  - [ ] Se renderiza una línea guía punteada en pantalla durante toda la acción de arrastrar.
  - [ ] Al soltar el cursor sobre un planeta destino válido, la orden queda registrada en la lista de acciones pendientes del turno.

#### Task 4: Predictor visual de órbitas (Proyecciones fantasmas antes de mover)
* **Descripción:** Crear una asistencia visual indispensable para que el jugador tome decisiones informadas sin necesidad de calcular trayectorias de forma mental bajo la presión del cronómetro.
* **Criterios de Aceptación:**
  - [ ] Aparecen siluetas fantasma transparentes que marcan las posiciones futuras del siguiente turno al arrastrar una ruta.
  - [ ] El motor altera el color de la línea guía según el cálculo dinámico de turnos de viaje (Verde = 1 turno, Amarillo = 2 turnos, Rojo = Inalcanzable).

---

### 🟨 FASE 2: Combate y Sistemas de Juego

#### Task 5: Motor de combate automático en 3 rondas (Cazas vs Fragatas vs Bombarderos)
* **Descripción:** Desarrollar el sistema algorítmico que resuelve las batallas de forma matemática y balanceada bajo el principio de contrarrestores cíclicos (Piedra, Papel o Tijera).
* **Criterios de Aceptación:**
  - [ ] El combate se ejecuta de forma secuencial: Ronda 1 (Cazas a Bombarderos), Ronda 2 (Fragatas a Cazas), Ronda 3 (Bombarderos a Fragatas/Planeta).
  - [ ] Si una flota resulta victoriosa sin oposición armada, el daño de los bombarderos remanentes afecta directamente los puntos de escudo del planeta.

#### Task 6: Sistema de recolección y balance de recursos (Polvo Estelar)
* **Descripción:** Implementar la infraestructura económica del juego. Controlar la acumulación de divisas y restringir las capacidades de compra de unidades del jugador si no cuenta con fondos suficientes.
* **Criterios de Aceptación:**
  - [ ] Los contadores de recursos suman de manera pasiva el Polvo Estelar de todos los planetas controlados al comenzar la fase de planificación.
  - [ ] El sistema impide la compra de naves o mejora de elementos si los fondos disponibles son inferiores al costo de la operación.

#### Task 7: Programación del Menú Radial Contextual sobre planetas
* **Descripción:** Diseñar la interfaz principal de comandos del juego. Debe ser una interfaz ágil que emerja de forma concéntrica al interactuar con un planeta propio sin necesidad de cambiar de pantalla.
* **Criterios de Aceptación:**
  - [ ] El menú emerge centrado perfectamente sobre el planeta seleccionado mediante coordenadas relativas.
  - [ ] Ofrece tres opciones de interacción claras y diferenciadas por iconos universales (Construir, Mejorar y Mover).
  - [ ] Tocar cualquier zona neutra del espacio exterior cierra la interfaz de manera inmediata de forma suave.

#### Task 8: Integración de Cartas de Maniobra e interfaz de 5 segundos en combate
* **Descripción:** Añadir el factor de decisión táctica de último momento en los combates. El jugador tiene una ventana de tiempo corta para jugar una carta antes de que se simulen los disparos de la batalla.
* **Criterios de Aceptación:**
  - [ ] El juego ejecuta una cuenta atrás ininterrumpida y visible de 5 segundos al dar inicio a la preparación del combate.
  - [ ] El sistema acepta el arrastre de cartas modificando los parámetros de la flota antes de iniciar la ronda de disparos y se descartan tras finalizar la batalla.

# 🟧 FASE 3: Controles Híbridos y Multiplataforma

## 9. Ajustes de control de cámara (Pinch-to-zoom en móvil y rueda del ratón en PC)
* **Descripción:** Asegurar el control ergonómico del mapa táctico. Permitir que los jugadores naveguen e inspeccionen el sistema solar cómodamente sin importar si usan pantalla táctil o periféricos clásicos.
* **Lógica Técnica:**
  * Entrada Enfoque Móvil: En el bucle de actualización, verificar si el conteo de toques activos es igual a dos (`Input.touchCount == 2`). Calcular la distancia vectorial entre el paso actual de ambos dedos y su paso previo. La diferencia de magnitud define el cambio de escala para la proyección ortográfica de la cámara.
  * Entrada Enfoque PC: Capturar el eje de entrada de desplazamiento vertical del ratón (`Input.GetAxis("Mouse ScrollWheel")` o método nativo de eventos de scroll de Mac Catalyst).
  * Aplicar el valor resultante modificando el parámetro `Camera.OrthographicSize` (o `xScale`/`yScale` en SpriteKit), procesando el valor final a través de una función de restricción matemática `Mathf.Clamp` o lógica equivalente utilizando las constantes de umbral `MIN_ZOOM` y `MAX_ZOOM`.
* **UI/Visual:** Movimiento amortiguado de la cámara para simular inercia física agradable al ojo al aproximarse o alejarse del sol central.
* **Criterios de Aceptación:**
  - [ ] El sistema procesa correctamente el gesto de pellizcar con dos dedos en dispositivos táctiles para ajustar el encuadre (Zoom in/out).
  - [ ] La rueda de desplazamiento del ratón realiza la misma acción de alejamiento y acercamiento en plataformas de escritorio de forma nativa.
  - [ ] Se encuentran configurados límites de escala máximos (2.0) y mínimos (0.5) para retener la integridad visual del escenario y evitar que la cámara rompa.

---

## 10. Mapeo de atajos de teclado para PC (Workflow de escritorio)
* **Descripción:** Optimizar los tiempos de respuesta y la comodidad de juego en ordenadores permitiendo gestionar los turnos y la cola de producción mediante comandos de teclado sin necesidad de apuntar con el ratón.
* **Lógica Técnica:**
  * En el método de escucha de entradas global para ordenadores (o mediante modificadores nativos de atajos en los componentes interactivos de SwiftUI), interceptar eventos de pulsación de teclas físicas.
  * Vincular la tecla de la barra espaciadora (`Spacebar`) directamente a la función de validación y ejecución de fin de turno fase.
  * Si el menú radial de construcción o la cuadrícula de un planeta se encuentra en estado activo en pantalla, escuchar las teclas numéricas del bloque superior alfanumérico de forma directa: Tecla `1` ejecuta el botón de Cazas, Tecla `2` ejecuta el botón de Fragatas y Tecla `3` ejecuta el de Bombarderos.
* **UI/Visual:** Mostrar de forma sutil el carácter del atajo de teclado en una esquina de los botones de la interfaz cuando el juego detecte periféricos de escritorio en PC o Mac.
* **Criterios de Aceptación:**
  - [ ] Presionar la barra espaciadora procesa automáticamente el cierre de la fase de planificación del jugador e inicia el procesamiento del turno.
  - [ ] Las teclas numéricas 1, 2 y 3 actúan como accesos rápidos para añadir unidades a la cola de producción si el menú del planeta está abierto.
  - [ ] Los atajos numéricos se bloquean o invalidan automáticamente si el menú radial de interfaz se encuentra cerrado.

---

## 11. UI responsiva para pantallas móviles (Adaptación a muescas/notches)
* **Descripción:** Garantizar que la interfaz gráfica sea totalmente legible y utilizable en cualquier configuración de pantalla moderna, previniendo que elementos vitales queden ocultos detrás de cámaras incrustadas o esquinas redondeadas.
* **Lógica Técnica:**
  * Configurar los contenedores principales de la interfaz (*UI Canvas* o vistas base de SwiftUI) para escalar automáticamente según el tamaño físico de la pantalla utilizando modos de aspecto responsivos coordinados por anclas.
  * Leer mediante la API nativa del motor de interfaces el área segura de renderizado de hardware (`Screen.safeArea` o las variables `safeAreaInsets` de la geometría de vista).
  * Ajustar dinámicamente los bordes, rellenos y márgenes de los paneles del HUD flotante para que se contraigan o expandan respetando los límites de los píxeles útiles informados por el hardware del teléfono.
* **UI/Visual:** Márgenes limpios y proporcionales en los cuatro costados en teléfonos con muescas físicas horizontales mientras el lienzo del motor de juegos corre de fondo de extremo a extremo.
* **Criterios de Aceptación:**
  - [ ] Los elementos críticos del HUD (recursos, turnos) permanecen anclados mediante *anchors* a las esquinas físicas de la pantalla en distintas resoluciones.
  - [ ] Los botones interactivos críticos evitan las zonas físicas muertas de la pantalla ocupadas por muescas (*notches*) o muescas de cámaras frontales.
  - [ ] El redimensionamiento de ventanas en escritorio o la rotación de pantalla en móviles recalcula las insets de seguridad de inmediato sin romper las vistas.

---

# 🟦 FASE 4: Contenido y Pulido

## 12. Programación de habilidades pasivas para las 3 Facciones iniciales
* **Descripción:** Implementar las reglas lógicas asimétricas que le otorgan jugabilidad y personalidad única a cada una de las tres razas espaciales.
* **Lógica Técnica:**
  * Crear una estructura de datos o perfil que asigne una enumeración de facción al identificador de control del jugador.
  * **Lógica Quironita (Enjambre):** En el script de cálculo de trayectorias, verificar si el arco de destino tiene un sentido angular horario concordante con el viaje; de ser así, aplicar un multiplicador de `1.5x` a la velocidad base.
  * **Lógica Silicato (Nexo):** Desarrollar un validador geométrico que calcule el producto cruz vectorial entre las posiciones de dos planetas controlados. Si el resultado es cero (o dentro de una tolerancia decimal), significa que están alineados con el centro del Sol; duplicar de inmediato su producción pasiva de Polvo Estelar.
  * **Lógica Orión (Chatarreros):** Monitorear la salud financiera del inventario de naves global antes y después de cada combate. Al registrar bajas, calcular el costo total destruido en Polvo Estelar y transferir el `25%` de esa suma directamente al inventario del jugador de Orión.
* **UI/Visual:** Destellos de estelas bioluminiscentes para los Quironitas, líneas láser de datos enlazando los planetas del Nexo alineados y animaciones de absorción de chatarra dorada flotante para Orión.
* **Criterios de Aceptación:**
  - [ ] Las flotas del Enjambre se desplazan con velocidad incrementada un 50% si viajan a favor del vector de rotación de la órbita.
  - [ ] El Nexo duplica correctamente la cosecha de Polvo Estelar de sus mundos si detecta una alineación recta colineal con el Sol.
  - [ ] Los Chatarreros recuperan recursos de forma automática en sus reservas tras concluir batallas espaciales donde hubo bajas (25% del coste total).

---

## 13. Implementación de la Misión 1 (Scripting del tutorial y eventos de IA)
* **Descripción:** Ensamblar el escenario introductorio del juego en base al documento de guion diseñado, controlando estrictamente las acciones permitidas al usuario para garantizar el aprendizaje progresivo.
* **Lógica Técnica:**
  * Implementar una máquina de estados para el control secuencial del tutorial (ej. Bienvenido, EsperandoConstruccion, EsperandoAtaque, CombateGuiado, JuegoLibre).
  * Desactivar por completo los colisionadores físicos de planetas neutros o enemigos y congelar botones globales al arrancar el nivel.
  * Monitorear mediante disparadores (*triggers*) si el jugador realiza la acción exacta solicitada por el script de diálogo del narrador. Si es válida, avanzar la máquina de estados y liberar los componentes del menú radial correspondientes a la fase activa.
* **UI/Visual:** Cajas de diálogo con los textos narrativos estilizados flotando en pantalla, acompañados de flechas indicadoras animadas que señalan los botones específicos que deben pulsarse.
* **Criterios de Aceptación:**
  - [ ] El juego arranca con el mapa bloqueado y congela el bucle normal de juego para forzar los textos introductorios del narrador.
  - [ ] Se programan los disparadores (*triggers*) secuenciales: el paso 1 desbloquea solo el botón de turno; el paso 2 desbloquea solo la construcción del menú radial, etc.
  - [ ] La misión despliega la pantalla de victoria únicamente tras comprobar que la facción rival posee 0 planetas y 0 naves de forma estricta.

---

## 14. Lógica de Muerte Súbita (Sistema de la Supernova encogiendo el mapa)
* **Descripción:** Programar el mecanismo de cierre forzado de partidas para evitar enfrentamientos interminables, reduciendo el área habitable del mapa de juego de manera progresiva.
* **Lógica Técnica:**
  * Almacenar un entero persistente de control de tiempo global incrementado en `+1` en cada resolución completa de turnos.
  * Al cumplirse la condición crítica de `Turno >= 15`, activar una bandera booleana global de emergencia de Supernova.
  * Al cierre de cada turno subsecuente (Turno 16, Turno 17, etc.), llamar a una función de destrucción ambiental en cascada: identificar los planetas e índices de flotas cuyo radio coincida con el carril externo en peligro, invocar sus métodos de destrucción física y purgarlos de las tablas hash de memoria. Reducir secuencialmente el carril a remover de afuera hacia adentro.
* **UI/Visual:** El astro solar del centro cambia su color a un rojo incandescente parpadeante en el turno 15. Al avanzar las fases destructivas, una corona de fuego expansiva consume visualmente los carriles externos.
* **Criterios de Aceptación:**
  - [ ] El juego realiza el conteo correcto de turnos y activa las alertas visuales de peligro en la interfaz al alcanzar el turno 15.
  - [ ] El carril exterior del mapa es purgado de la simulación al avanzar cada turno posterior a la fase de muerte súbita (Turno 16+).
  - [ ] Cualquier activo (unidades, flotas o planetas enteros) posicionado sobre el carril afectado es destruido de manera fulminante sin excepción.
  # 🎨 FASE 5: Pulido Estético y Efectos Visuales (Juice Game Design)

## 15. Sistema de Partículas de Polvo Estelar de Fondo (Stellar Background Drift)
* **Descripción:** Implementar un campo estelar dinámico procedimental de fondo utilizando emisores de partículas para dar una sensación real de profundidad (efecto paralaje) y movimiento espacial en el vacío, sin depender de archivos externos `.sks`.
* **Lógica Técnica:**
  * Desarrollar un generador de texturas en memoria (`generateDotTexture`) usando `UIBezierPath` (iOS) o `NSBezierPath` (macOS) que dibuje un punto blanco difuminado sobre un lienzo de bits.
  * Instanciar un nodo emisor de partículas (`SKEmitterNode`) configurado 100% por código en la capa más profunda del árbol gráfico asignando un índice `zPosition = -15` (Capa A: Estrellas lejanas lentas) y otro en `zPosition = -12` (Capa B: Polvo cósmico medio con gradiente de opacidad).
  * Utilizar el método `advanceSimulationTime` pasándole el ciclo de vida de la partícula (`particleLifetime = 35.0`) en el arranque de la escena para pre-poblar el mapa estelar de chispas titilantes antes de que termine la pantalla de carga.
* **UI/Visual:** Estrellas diminutas con variaciones aleatorias de opacidad y escala que flotan suavemente por detrás de las líneas orbitales, simulando un campo de paralaje tridimensional al mover la cámara.
* **Criterios de Aceptación:**
  - [ ] El nodo emisor se posiciona de forma estricta en el fondo de la escena por debajo de todos los planetas y carriles interactivos.
  - [ ] Las partículas cubren todo el campo visual de la cámara en sus límites mínimos y máximos de escala de zoom.
  - [ ] Las partículas se pre-pueblan instantáneamente al arranque evitando que la escena inicie vacía o las estrellas nazcan de golpe en el centro.

---

## 16. Efecto de Estela del Motor para Flotas en Tránsito (Engine Trail Particles)
* **Descripción:** Diseñar una estela visual de partículas de propulsión acoplada a las flotas espaciales cuando viajan entre órbitas, calculando de forma trigonométrica la eyección inversa al vector de movimiento.
* **Lógica Técnica:**
  * Crear un constructor modular de partículas con una alta tasa de nacimiento (`particleBirthRate = 45.0`) y un tiempo de vida corto (`particleLifetime = 0.35`) para emular fuego de propulsor concentrado.
  * Calcular la arcotangente del delta posicional (`atan2`) del nodo en movimiento para identificar el ángulo exacto del trayecto de vuelo en pantalla; inyectar un desfase de 180 grados (`+ CGFloat.pi`) para que las partículas salgan expulsadas hacia atrás.
  * Modificar el método de traslado lineal para que al llegar al destino apague la producción (`particleBirthRate = 0`), espere la extinción de las chispas remanentes y ejecute `.removeFromParent()` para liberar la memoria de texturas de Metal de forma limpia.
* **UI/Visual:** Una estela brillante de chispas o plasma neón cuyo color se adapta de forma asimétrica al perfil de la facción dueña de las naves (Verde = Enjambre, Cian = Nexo, Naranja = Chatarreros).
* **Criterios de Aceptación:**
  - [ ] La estela de partículas sigue de forma milimétrica las coordenadas del nodo de la flota durante todo el trayecto de traslado interplanetario.
  - [ ] El color de la emisión muta y se adapta correctamente según el tipo de facción seleccionado (Verde = Enjambre, Cian = Nexo, Naranja = Chatarreros).
  - [ ] El nodo emisor se destruye y purga de la memoria de texturas de Metal limpiamente tras disolverse las últimas partículas en el destino.

---

## 17. Animación de Explosión de Naves en Combate (Casualty Explosion Blast)
* **Descripción:** Crear una animación de explosión de partículas en la pantalla de combate cuando una unidad es destruida en las fases automatizadas de fuego cruzado, inyectando un offset aleatorio sobre la posición para evitar apilamientos gráficos.
* **Lógica Técnica:**
  * Desarrollar una función constructora de ráfagas expansivas radiales instantáneas (`triggerExplosionAt`) configurando la propiedad `numParticlesToEmit` de forma fija con el conteo de escombros de la baja.
  * Interceptar el pipeline de daño letal en las rondas automáticas; usar la ID del planeta en conflicto para interrogar sus coordenadas cartesianas de pantalla y aplicar un offset de dispersión mediante valores flotantes aleatorios (`CGFloat.random(in: -15...15)`).
  * Enlazar una acción de secuencia (`SKAction.sequence`) que espere una ventana de tiempo de seguridad superior al tiempo de vida de la partícula antes de ejecutar el método `.removeFromParent()`.
* **UI/Visual:** Un destello expansivo circular de fragmentos y chatarra estelar que brota en el foco de la batalla y se desvanece de manera elástica en menos de un segundo (Naranja = Caza, Amarillo = Fragata, Rojo = Bombardero).
* **Criterios de Aceptación:**
  - [ ] El emisor de explosión se dispara exactamente en las coordenadas cartesianas de la baja en combate.
  - [ ] La escala visual y el conteo de fragmentos del destello es de orden proporcional a la clasificación de la unidad destruida (Caza = 25, Fragata = 55, Bombardero = 100).
  - [ ] Las partículas se liberan como una ráfaga única de un solo disparo (*one-shot burst*) apagándose de inmediato el nodo de la simulación.

---

## 18. Efecto de Onda de Choque de la Supernova (Solar Core Collapse Shockwave)
* **Descripción:** Diseñar el efecto visual catastrófico para la Fase de Muerte Súbita. El Sol debe emitir un anillo de fuego expansivo de partículas en el turno 16+ que consuma cronométricamente los carriles externos.
* **Lógica Técnica:**
  * En el turno 15, aplicar una secuencia de acción infinita sobre el nodo central de la estrella (`core_sun_node`) para alternar sus colores de relleno entre rojo y naranja, simulando palpitaciones inestables de masa crítica.
  * Al activarse la purga de órbita en turnos avanzados, calcular la velocidad de partículas dividiendo la métrica del radio fijo por la constante de tiempo de vida (`radius / 0.5`) para forzar un frente de onda expansivo exacto.
  * Sincronizar un retardo de tiempo de espera (`SKAction.wait`) antes de ocultar y destruir los planetas afectados para que el estallido de fragmentación ocurra en el milisegundo exacto en el que el anillo de fuego pasa sobre ellos.
* **UI/Visual:** Corona circular masiva de partículas incandescentes con una secuencia de degradado cromático por interpolación de fotogramas clave que viaja desde el centro consumiendo los planetas periféricos en el mapa estelar.
* **Criterios de Aceptación:**
  - [ ] La animación del Sol inestable se activa mediante una secuencia de palpitación infinita al iniciar la alerta en el Turno 15.
  - [ ] El anillo expansivo de partículas alcanza con precisión matemática y sincronización visual el radio del carril orbital purged.
  - [ ] Los planetas destruidos por la Supernova muestran partículas de fragmentación en el momento exacto de la colisión de la onda de choque.



