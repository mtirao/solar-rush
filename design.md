# 🚀 SOLAR RUSH - Documento de Diseño de Nivel
## Campaña: Misión 1 - "Bautismo de Fuego en la Órbita Baja"

---

## 📖 1. TRASFONDO NARRATIVO & CONTEXTO
* **Facción del Jugador:** Chatarreros de Orión.
* **Protagonista:** Cadete Leo Vane.
* **Sinopsis:** La nave nodriza de tu flota se ha quedado sin combustible en los bordes exteriores de un sistema estelar desconocido. Debes tomar el control de una pequeña estación de desguace y asegurar un planeta cercano rico en Polvo Estelar. Sin embargo, una sonda del Nexo Silicato ha detectado tu posición y se dirige a interceptarte. ¡Aprende a dominar las órbitas antes de que sea tarde!

---

## 🗺️ 2. CONFIGURACIÓN DEL TABLERO (MAPA DE APRENDIZAJE)
El mapa está simplificado al máximo para evitar que el jugador se abrume.

* **El Sol (Centro):** Inactivo y bloqueado durante esta misión.
* **Órbita Interna:** 1 Planeta controlado por el Nexo Silicato (IA pasiva, nivel tutorial). 
  * *Guarnición:* 3 Cazas iniciales.
* **Órbita Media:** 1 Planeta Neutral deshabitado (Rico en Polvo Estelar).
  * *Guarnición:* Ninguna.
* **Órbita Externa:** 1 Planeta Inicial (Base del Jugador: "El Asteroide").
  * *Guarnición inicial:* 3 Cazas y 2 Fragatas.

---

## 🧑‍🏫 3. FASES DEL TUTORIAL GUIADO (PASO A PASO)

### Fase 1: La Leyenda de las Órbitas (Movimiento)
* **Objetivo:** Entender que el mapa se mueve constantemente.
* **Mecánica guiada:** El juego inicia en pausa. Una mano animada (Móvil) o cursor parpadeante (PC) señala los anillos concéntricos del mapa y las flechas de dirección. El texto del narrador dice: *"En Solar Rush, el espacio nunca se queda quieto. Cada órbita gira a una velocidad diferente."*
* **Acción requerida:** El juego bloquea todos los botones excepto el de **Fin de Turno** (Barra espaciadora en PC / Botón superior derecho en Móvil). El jugador debe pulsarlo para ver cómo los planetas rotan a sus nuevas posiciones.

### Fase 2: La Cosecha (Recolección y Menú Radial)
* **Objetivo:** Aprender a usar los recursos y la interfaz de construcción.
* **Mecánica guiada:** El mapa se detiene al iniciar el Turno 2. El marcador de Polvo Estelar sube. El narrador dice: *"Tu base ha extraído Polvo Estelar. Vamos a usarlo para reforzar la flota."*
* **Acción requerida:** El jugador debe hacer clic o tocar su planeta base. Se despliega el **Menú Radial Contextual**. Las opciones normales están bloqueadas excepto el *Icono de Martillo (Construcción)*. Al pulsarlo, el tutorial le obliga a seleccionar el **Bombardero** y gastar sus recursos.

### Fase 3: El Lanzamiento Orbital (Navegación Táctica)
* **Objetivo:** Calcular trayectorias utilizando la corriente a favor.
* **Mecánica guiada:** En el Turno 3, el Planeta Neutral de la órbita media se alinea perfectamente por delante de la base del jugador. El narrador dice: *"Los planetas giran. Si lanzas tus naves a favor de la corriente, llegarán mucho más rápido. Conquista ese planeta neutral."*
* **Acción requerida:** El jugador debe mantener pulsado su planeta base y arrastrar el dedo/ratón hacia el Planeta Neutral. La interfaz activa el **Predictor de Órbitas** mostrando una línea **Verde**. Al soltar, la flota viaja instantáneamente en este turno y coloniza el planeta. El límite de planetas del jugador cambia a `2 / 3`.

### Fase 4: Bautismo de Fuego (Combate Automático y Cartas)
* **Objetivo:** Aprender el triángulo de combate (Piedra, Papel o Tijera) y el uso de habilidades.
* **Mecánica guiada:** En el Turno 4, la IA del Nexo Silicato envía sus 3 Cazas a atacar el Planeta Neutral recién conquistado. Tú tienes las 2 Fragatas defendiendo en esa órbita. 
* **Acción requerida:** Se abre la interfaz de **Resolución de Combate**. El juego entra en una breve pausa de 5 segundos. El narrador dice: *"Las Fragatas tienen ventaja blindada contra los Cazas enemigos. Usa esta Carta de Maniobra para asegurar la victoria."* El juego obliga al jugador a arrastrar la carta universal **"Campo de Fuerza Localizado"** sobre sus Fragatas.
* **Resolución:** El combate se ejecuta solo. El escudo absorbe el primer disparo del Nexo, y las dos Fragatas barren a los cazas enemigos en la Ronda 2.

### Fase 5: Contraataque y Aniquilación (Victoria)
* **Objetivo:** Cerrar la partida cumpliendo el objetivo militar.
* **Mecánica guiada:** El narrador dice: *"El Nexo ha quedado indefenso. Envía tu Bombardero a su planeta de la órbita interna para reclamar el sistema."*
* **Acción requerida:** El jugador selecciona su flota (incluyendo el Bombardero construido en la Fase 2) y la arrastra hacia el planeta del Nexo Silicato. En el siguiente turno, el Bombardero reduce los escudos planetarios enemigos a cero.

---

## 🏆 4. CONDICIÓN DE VICTORIA DE LA MISIÓN
* **Victoria:** Capturar el único planeta de la IA del Nexo Silicato (Victoria por Aniquilación).
* **Recompensa:** Desbloqueo de la **Misión 2** y +100 Fragmentos Estelares para la cuenta del jugador.
