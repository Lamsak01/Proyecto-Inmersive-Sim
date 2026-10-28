# Hoja de Ruta Maestra (Roadmap) — Proyecto Immersive Sim 2D ("Placa de Petri")

> **Propósito de este documento:** Mantener registrada de forma permanente la visión de diseño, los referentes, la arquitectura de sistemas y el orden exacto de implementación paso a paso. Cualquier desarrollador o modelo de IA que trabaje en este repositorio debe consultar este documento junto con `REFACTOR_AND_OPTIMIZATION_PLAN.md`.

---

## 1. Visión General y Filosofía del Juego

### El Concepto: "La Placa de Petri"
Un **Immersive Sim / Sandbox de Supervivencia 2D Top-Down Pixel Art** ambientado en una pequeña aldea aislada (máximo **5 casas** con sus residentes/familias, más **tu parcela** como nuevo residente que empieza desde cero y **un rincón de bosque/mina/río**).

El objetivo no es tener un mapa gigante vacío, sino **máxima profundidad sistémica en un espacio reducido**: un ecosistema vivo que se autorregula donde cada NPC, cada recurso y cada acción del jugador (ayudar, comerciar, robar, noquear o matar) tiene consecuencias lógicas y graduales en el tiempo.

### La Combinación de Referentes (El Triángulo de Diseño)
1. **De *Kenshi*:**
   - La crudeza de empezar desde cero sin ser "el elegido".
   - El combate visceral con consecuencias físicas (**sangrado**, pérdida de sangre/debilidad, **aturdimiento/KO** para noquear sin matar o robar).
   - La estética **anacrónica** (costumbres y herramientas tradicionales conviviendo con restos de tecnología antigua/generadores).
   - *Lo que mejoramos respecto a Kenshi:* En vez de NPCs genéricos sin personalidad, aquí los ~10 habitantes del pueblo tienen identidad, historia, diálogos profundos y relaciones reales.
2. **De *RimWorld*:**
   - La simulación lógica de subsistencia: cadenas de producción reales (materia prima $\rightarrow$ trabajo $\rightarrow$ stock en tienda $\rightarrow$ consumo diario).
   - Sucesión orgánica de roles: si el carnicero o el herrero muere o queda incapacitado, el pueblo no colapsa por arte de magia al instante; primero se consume el stock acumulado durante varios días y luego un familiar o sucesor asume el puesto (con su propia habilidad/eficiencia).
3. **De *Stardew Valley*:**
   - El bucle satisfactorio de recolección y vida rural: **tala, minería, forrajeo (hongos, hierbas), caza, pesca, agricultura, crafteo**, construir tu propia casa y forjar relaciones con tus vecinos/aliados.
   - *Lo que cambiamos respecto a Stardew Valley:* Quitamos el límite *family friendly*. Aquí puedes infiltrarte de noche en casa de un vecino, dejarlo inconsciente, sabotear su negocio, o ver cómo el pueblo pasa hambre si arruinas su cadena de suministros.

---

## 2. Orden de Implementación por Fases

Para que el proyecto nunca se vuelva inmanejable, cada fase construye los cimientos técnicos que necesita la siguiente.

---

### FASE 1: Refinamiento de los 4 Pilares Base + Misiones y Destructibles *(COMPLETADA)*
Antes de simular el pueblo o la supervivencia, el control del personaje y la interacción inmediata minuto a minuto deben sentirse impecables y fluidos.

- [x] **1.0. Limpieza de arquitectura y optimización base de FPS** *(Completado en `REFACTOR_AND_OPTIMIZATION_PLAN.md`)*.
- [x] **1.1. Refinamiento del Movimiento y Física (`PlayerMovementController.gd`):**
  - Ajustar aceleración/fricción para que el movimiento sea responsivo y con peso físico.
  - Pulir transición entre Caminar, Sprint (consumo de Stamina; correr cancela el sigilo automáticamente) y Sigilo (velocidad de animación ajustada).
  - Física `MOTION_MODE_FLOATING` sin rebote ni *knockback* molesto al golpear o chocar contra enemigos/NPCs.
  - Mejorar feedback visual de estados alterados (tinte y texto flotante cuando estás débil por sangrado o aturdido).
- [x] **1.2. Refinamiento del Combate Base (`PlayerCombatController.gd`, `HealthComponent.gd`, `StunComponent.gd`):**
  - *(Nota: Sistema de combate funcional y modular, **abierto a ser rediseñado o cambiado más adelante** según evolucione el proyecto).*
  - *Hitboxes* limpias sin empuje/rebote, tiempos de ataque (*windup* / *cooldown*) y consumo de stamina.
  - Sistema de **Sangrado por Acumulación** (estadística `bleed_buildup` en cada arma $\rightarrow$ al llenar la barra se activa el estado `BLEEDING` y pierdes vida poco a poco por segundo en proporción al daño del arma).
  - Sistema de **Stun / KO por Acumulación** (estadística `stun_buildup` en armas contundentes $\rightarrow$ al llenar la barra al máximo, estunea/noquea por varios segundos mientras la barra se vacía).
  - Objetos destructibles del entorno (cajas, barriles, muros débiles según tipo de arma).
- [x] **1.3. Refinamiento del Sigilo e IA (`EnemyAI.gd`, `VisionCone2D.gd`, `AudioManager.gd`):**
  - Pulir detección visual (conos de visión) y acústica dinámica (silencio al estar quieto o en sigilo, radio normal al caminar, radio ampliado al correr que alerta a los enemigos, y ondas de ruido al golpear/destruir objetos con oclusión por paredes).
  - Pulir estados de búsqueda (`IDLE` $\rightarrow$ `ALERT` $\rightarrow$ `CHASE` $\rightarrow$ `SEARCH` con rastro fantasma $\rightarrow$ `RETURN`).
  - Pulir el *Takedown* silencioso por la espalda para que sea un **Noqueo (KO) no letal** de 10 segundos (dejando al enemigo inconsciente en el suelo sin cono de visión, permitiendo rematarlo o escabullirse).
- [x] **1.4. Refinamiento del Sistema de Diálogo, Relaciones Base y Misiones (`dialogue_manager.gd`, `npc.gd`, `ObjectiveManager.gd`):**
  - Reconstruido el panel de diálogo desde cero en `dialogue_manager.gd`: centrado perfecto en pantalla, cabecera con Nombre, Oficio y Estado de Relación/Afinidad en tiempo real, y soporte completo de Teclado (`[1]-[9]`, `W/S` + `Enter/Espacio`, `ESC`) y Ratón.
  - Conectado el diálogo con variables de relación/afinidad (`affinity` de `-100` a `+100`: *Hostil, Desconfiado, Neutral, Amistoso, Aliado*) y acciones contextuales (curar sangrado/vida cuando es amistoso, o pelear si lo provocas/atacas).

---

### FASE 2: El Cimiento Sistémico de "La Placa de Petri" (Tiempo, Aldea y Guardado Nuevo) *(FASE ACTUAL)*
Una vez que los 4 pilares se sienten genial, convertimos el mapa de pruebas en el esqueleto funcional de la aldea de 5 casas.

- [ ] **2.1. Reloj del Mundo (`WorldClock`):**
  - Sistema de horas del día (Mañana, Tarde, Noche, Madrugada) y contador de Días.
  - Iluminación ambiental suave (`CanvasModulate`) que cambie con la hora (haciendo que la noche reduzca la visión de los NPCs para favorecer el sigilo).
- [ ] **2.2. Nuevo Sistema de Inventario Ligero y Guardado desde Cero:**
  - Diseñar un sistema de guardado limpio desde cero (basado en datos/diccionarios limpios por entidad) pensado desde el día 1 para guardar el estado de la aldea.
  - Reintroducir o rediseñar el inventario de forma limpia y rápida para almacenar recursos recolectados.
- [ ] **2.3. Sistema de Puestos de Trabajo (`Workplace`), Stock y Sucesión:**
  - Crear la estructura de las **5 casas/oficios** (ej. Carnicero/Cazador, Herrero/Minero, Carpintero/Leñador, Agricultor/Herborista, Tabernero/Comerciante).
  - Implementar stock real por negocio (`stock`, `produccion_diaria`, `consumo_diario`).
  - Implementar **Sucesión**: lista de herederos/aprendices que asumen el puesto días después si el titular muere o queda incapacitado, afectando la calidad/cantidad de productos en el pueblo.
- [ ] **2.4. Rutinas de NPCs y Relaciones Profundas:**
  - Horarios diarios conectados al `WorldClock` (ir a trabajar, comer, socializar, dormir en su cama).
  - Sistema de relaciones e historial: los aliados recuerdan tus favores, regalos, robos o agresiones, desbloqueando mejores precios, ayuda en combate o enemistad.

---

### FASE 3: Supervivencia y Recolección Primaria (Bosque y Mina)
Con el tiempo y la economía del pueblo funcionando, abrimos el bucle de supervivencia del jugador en el rincón salvaje del mapa.

- [ ] **3.1. Componentes de Supervivencia del Jugador:**
  - Necesidades de **Hambre, Sed y Sueño/Energía** (conectadas a `StaminaComponent` y `HealthComponent`, sin ser tediosas pero dando propósito a la comida y a dormir en tu casa).
- [ ] **3.2. Forrajeo (Estilo *Stardew Valley*):**
  - Nodos de recolección silvestre en el bosque (hongos, bayas, plantas medicinales para vendajes/sangrado) que reaparecen según el paso de los días del `WorldClock`.
- [ ] **3.3. Tala y Minería:**
  - Árboles talables (con hacha) y vetas de mineral/piedra (con pico/martillo) reutilizando la arquitectura de `DestructibleObject` + consumo de stamina + caída de recursos (*drops*).
- [ ] **3.4. Caza Sistémica:**
  - Fauna en el bosque (presas que usan el estado `FLEE` de `EnemyAI` y depredadores que usan `CHASE`/`ATTACK`), permitiendo cazar con sigilo o trampas para obtener carne cruda y cuero.

---

### FASE 4: Asentamiento, Crafteo, Agricultura y Pesca
El jugador pasa de sobrevivir al día a construir su hogar y producir sus propios recursos.

- [ ] **4.1. Construcción de tu Casa y Crafteo:**
  - Parcela propia del jugador donde empezar desde cero (cama rudimentaria, fogata, banco de trabajo) y mejorar la casa con madera y piedra.
  - Recetas de crafteo (herramientas, armas, vendas para el sangrado, cocina).
- [ ] **4.2. Agricultura:**
  - Sistema de celdas de cultivo en tu parcela: arar con azada, sembrar, regar y fases de crecimiento conectadas al cambio de día del `WorldClock`.
- [ ] **4.3. Pesca:**
  - Zonas de pesca en el río/lago con mecánica interactiva y variedades de peces según la hora del día.

---

### FASE 5: Sistemas Avanzados y Expansión Futura
Sistemas de largo plazo para cuando el núcleo del juego esté completo.

- [ ] **5.1. Ganadería:**
  - Cría de animales domésticos en corrales, alimentación y obtención de recursos.
- [ ] **5.2. Breeding (Cruce y Genética de Animales):**
  - Sistema de herencia de estadísticas al cruzar dos animales de la misma especie (mejorar velocidad, resistencia, producción o fuerza generación tras generación).
- [ ] **5.3. Tecnología Anacrónica (Reactivación de `archived_systems/power_system/`):**
  - Integrar generadores antiguos, cables y máquinas reparables para automatizar o electrificar partes de tu asentamiento o de la aldea.
