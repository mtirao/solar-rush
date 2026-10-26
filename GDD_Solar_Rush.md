# Documento de Diseño de Juego (GDD): Solar Rush

**Eslogan:** "Conquista la galaxia. Domina las órbitas. En solo 10 minutos."
**Plataformas:** Dispositivos Móviles (Android/iOS) y Ordenadores (PC).
**Género:** Estrategia Espacial Rápida / Micro-4X.
**Modelo de Negocio:** Free-to-Play con monetización 100% cosmética.

---

## 1. Visión General del Juego
**Solar Rush** es un juego de estrategia espacial diseñado para partidas intensas de 10 a 15 minutos. El tablero no es estático: los planetas giran constantemente en órbitas concéntricas alrededor de un Sol central. Los jugadores deben gestionar flotas y recursos con una sola mano en móviles o mediante controles optimizados en PC, adaptándose a un mapa que cambia drásticamente en cada turno.

### Pilares de Diseño
* **Accesibilidad Dinámica:** Controles contextuales e interfaces limpias mediante menús radiales.
* **Profundidad Asimétrica:** Facciones con estilos de juego radicalmente opuestos.
* **Ritmo Ágil:** Eliminación de la microgestión lenta; las partidas se cierran por objetivos dinámicos o mediante un sistema de muerte súbita (*Supernova*).

---

## 2. Core Loop (Bucle de Juego)
1. **Planificar (Fase de Turno Oculto):** El jugador gasta *Polvo Estelar* para construir naves, mejorar escudos, trazar trayectorias de movimiento o seleccionar una *Carta de Maniobra*. Ambas facciones envían sus órdenes simultáneamente (Temporizador de 30s).
2. **Resolver (Fase de Choque):** Los planetas avanzan en sus órbitas y las flotas que coinciden en el espacio entran en un combate cinemático automático de 3 rondas basado en ventajas de tipo.
3. **Progresar:** Al terminar la partida, el jugador gana experiencia para sus facciones y recursos para desbloquear personalizaciones visuales en *La Forja*.

---

## 3. Mecánicas Principales

### A. La Regla de los 3 Planetas
Cada jugador puede colonizar y controlar un **máximo de 3 planetas simultáneamente**. Si desea expandirse a un cuarto mundo, se ve obligado a abandonar o desmantelar uno de sus bastiones actuales.

### B. El Sistema de Órbitas y Movimiento
El mapa se divide en tres niveles de anillos concéntricos que giran alrededor de la estrella central:
* **Órbita Interna:** Movimiento rápido (2 posiciones por turno). Zona caótica de alta exposición.
* **Órbita Media:** Movimiento estándar (1 posición por turno). Concentración de recursos estables.
* **Órbita Externa:** Movimiento lento (1 posición cada 2 turnos). Ideal para fortificaciones defensivas.

*Lanzamiento Orbital:* Las naves viajan hacia la posición futura proyectada del planeta destino. Viajar a favor de la rotación orbital otorga un beneficio de velocidad (-1 turno de viaje); viajar en contra penaliza la llegada (+1 turno de viaje).

### C. Recurso Único: Polvo Estelar
Sustituye toda gestión compleja de múltiples recursos. Se utiliza para:
1. Clonar tripulación (Construir naves).
2. Potenciar defensas (Mejorar escudos planetarios).
3. Activar habilidades tácticas (Jugar Cartas de Maniobra).

---

## 4. Facciones
El juego cuenta con tres facciones iniciales completamente asimétricas:

1. **El Enjambre Quironita (Expansión / Orgánica):**
   * *Habilidad Pasiva:* Sin penalizaciones al abandonar planetas. Velocidad incrementada un 50% al viajar a favor de la corriente orbital.
   * *Desventaja:* Escudos de planetas estructuralmente más débiles.

2. **El Nexo Silicato (Tecnología / Defensiva):**
   * *Habilidad Pasiva:* Genera el doble de Polvo Estelar si alinea dos planetas con el Sol central. Capacidad de sobrecargar escudos un nivel por encima del límite común.
   * *Desventaja:* Naves caras de construir y con menor velocidad de desplazamiento.

3. **Los Chatarreros de Orión (Agresión / Oportunista):**
   * *Habilidad Pasiva:* Recuperan instantáneamente el 25% del coste en Polvo Estelar de cualquier estructura o nave que destruyan. Pueden saquear planetas neutrales sin colonizarlos.
   * *Desventaja:* Producción pasiva de recursos severamente reducida.

---

## 5. Sistema de Naves y Combate
El combate se rige por un triángulo de prioridades ("Piedra, Papel o Tijera") y se resuelve en tres rondas automáticas al colisionar las flotas:

| Clase de Nave | Coste/Velocidad | Objetivo Prioritario | Rol Táctico |
| :--- | :--- | :--- | :--- |
| **Cazas (Ligeras)** | Barato / Rápido | Bombarderos | Destrucción de unidades de asedio en la Ronda 1. |
| **Fragatas (Medianas)** | Estándar / Medio | Cazas | Cobertura aliada y limpieza de naves ligeras en la Ronda 2. |
| **Bombarderos (Pesadas)** | Caro / Lento | Fragatas y Planetas | Asedio pesado y daño a escudos planetarios en la Ronda 3. |

### Cartas de Maniobra
Los jugadores equipan un mazo de 3 cartas y pueden activar una por combate durante los primeros 5 segundos de la resolución para alterar las estadísticas de la batalla (ej. *Campo de Fuerza Localizado*, *Estasis Orbital*, *Imán de Chatarra*).

---

## 6. Interfaz de Usuario (UI)
* **HUD Minimalista:** Información crítica relegada a las esquinas para mantener el espacio de juego libre de obstrucciones visuales.
* **Menú Radial:** Al pulsar o hacer clic sobre un planeta, brota un menú circular interactivo con opciones de *Construcción (Martillo)*, *Mejora (Escudo)* y *Movimiento (Flecha)*.
* **Proyección Fantasma:** Al arrastrar una ruta de ataque, la interfaz proyecta siluetas traslúcidas mostrando la posición futura de los cuerpos celestes en los turnos venideros.

---

## 7. Condiciones de Victoria y Muerte Súbita
Una partida de *Solar Rush* se gana de forma inmediata al cumplir cualquiera de los siguientes hitos:
1. **Supremacía:** Capturar y defender la estrella central durante 3 turnos consecutivos.
2. **Tecnología:** Acumular un fondo neto de 10,000 unidades de Polvo Estelar simultáneamente.
3. **Aniquilación:** Capturar todos los planetas habitados y eliminar las flotas de los rivales.

**Muerte Súbita (La Supernova):** Si tras 15 turnos no hay un ganador, el Sol central colapsa. En cada turno subsiguiente, las órbitas exteriores se queman y desaparecen secuencialmente, forzando a los supervivientes a un enfrentamiento directo en el centro del mapa.
