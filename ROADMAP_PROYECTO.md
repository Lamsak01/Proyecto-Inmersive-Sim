# Hoja de Ruta Maestra (Roadmap) — Proyecto Immersive Sim 2D ("Placa de Petri")

> **Propósito de este documento:** Mantener registrada de forma permanente la visión de diseño, los referentes, la arquitectura de sistemas y el orden exacto de implementación paso a paso. Cualquier desarrollador o modelo de IA que trabaje en este repositorio debe consultar este documento junto con `SESSION_CONTEXT_LOG.md` y `REFACTOR_AND_OPTIMIZATION_PLAN.md`.

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
  - *(Nota: Sistema de combate y animaciones de herramientas/armas abiertos a ser rediseñados más adelante para que combinen visualmente con la skin definitiva del personaje; por ahora las herramientas solo se muestran durante el swing/disparo con sprites pixel-art 16x16 limpios).*
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

- [x] **2.1. Reloj del Mundo (`WorldClock`):**
  - Sistema de horas del día (Mañana, Tarde, Atardecer, Noche, Madrugada) y contador de Días en `scripts/systems/WorldClock.gd` (con atajo `[T]` para avanzar +2h en pruebas y widget centrado arriba en `scenes/ui_root.gd`).
  - Iluminación ambiental suave (`CanvasModulate` en `scripts/World.gd`) que cambia con la hora, reduciendo automáticamente el rango de visión de los conos e IA enemiga por la noche (`get_effective_detection_range()` en `EnemyAI.gd` y `DummyEnemy.gd`).
- [x] **2.2. Nuevo Sistema de Inventario Ligero y Guardado desde Cero:**
  - Diseñado e implementado el sistema de guardado JSON limpio desde cero en `scripts/systems/GameManager.gd` (`user://village_save.json` con atajos `[F5]` Guardar / `[F9]` Cargar), guardando Reloj del Mundo, posición/vida/sangrado/arma del Jugador, Inventario, estado/afinidad de NPCs y persistencia de objetos destruidos.
  - Creado el inventario ligero `scripts/systems/SimpleInventory.gd` con oro, catálogo de materiales/consumibles, obtención de recursos al destruir cajas/barriles/muros (`DestructibleObject.gd`), comercio básico en diálogo (`scenes/npc.gd`) e interfaz modal en `scenes/ui_root.gd` (`[I]` o `[Tab]`).
  - *(Ideas guardadas para expansión futura del inventario:*
    1. ***Rueda de Herramientas y Armas estilo Red Dead Redemption (`Tool Wheel`):** Separar por completo las herramientas/armas (Espada, Martillo, Hacha, Pico, Arco, Pala, Hoz, Regadera) en una **Rueda Radial** al mantener presionado `Tab` (o con teclas numéricas), dejando la **Mochila/Bolsa (`[I]`)** exclusivamente para materiales, cosechas, pieles y consumibles.*
    2. ***Sistema de Mochilas estilo Kenshi/Outward:** Empezar con una bolsa pequeña y comprar/craftear mochilas de cuero de distintos tamaños para ampliar la capacidad máxima, mostrando el sprite de la mochila en la espalda).*
- [x] **2.3. Sistema de Casas Familiares, Puestos de Trabajo (`VillageManager.gd`, `VillageNPC.gd`), Stock, Taberna Aparte y Sucesión en 2 Niveles:**
  - Creadas las **5 Casas Familiares** completas (suelo, paredes con puerta abierta, 2 camas, mesa de comedor familiar y taller delantero) para las 5 familias de artesanos:
    1. **Familia Colmillo (Carnicería):** *Garrick* (Maestro Carnicero) + *Lina* (Esposa y Curtidora).
    2. **Familia Yunque Gris (Herrería):** *Thoran* (Maestro Herrero) + *Kael* (Hijo y Aprendiz de Forja).
    3. **Familia Roble Viejo (Carpintería):** *Bram* (Maestro Carpintero) + *Mila* (Hermana y Ebanista).
    4. **Familia Raíz Verde (Herboristería):** *Elena* (Herborista y Agricultora) + *Tomás* (Esposo y Hortelano).
    5. **Familia Aguas Claras (Pescadería y Molino):** *Marlo* (Pescador y Molinero) + *Nora* (Hija y Redera).
  - Creada la **Taberna y Posada "El Jabalí Dorado"** aparte de las 5 casas, con comedor social, *Marta* (Tabernera), 1 cama de alquiler para el jugador y 3 camas para los **3 Viajeros sin Oficio** (*Aldric*, *Sora*, *Darío*).
  - **Sucesión Orgánica en 2 Niveles:** Si un maestro muere, primero hereda el oficio su **Familiar directo** (`Herencia Familiar`); si falta toda la familia, uno de los viajeros sin oficio de la Taberna se muda a la casa y asume el puesto.
- [x] **2.4. Sub-stats de Necesidades y Rutinas Dinámicas de IA de Utilidad (`VillageNPC.gd`):**
  - En lugar de horarios fijos rígidos, cada NPC tiene **3 Sub-stats dinámicos (`0%` a `100%`)** con ritmos metabólicos individuales: **🍖 Hambre (`need_hunger`)**, **💤 Energía/Descanso (`need_energy`)** y **💬 Socialización (`need_social`)**.
  - Los NPCs toman decisiones autónomas en tiempo real (`WORKING`, `EATING`, `SOCIALIZING`, `SLEEPING`): dejan el taller para ir a comer a la mesa de su casa o a la Taberna cuando tienen hambre, buscan a su familia o vecinos para charlar (`💬`) cuando necesitan socializar, y van a su cama cuando se agota su energía.

---

### FASE 3: Supervivencia y Recolección Primaria (Bosque y Mina)
Con el tiempo y la economía del pueblo funcionando, abrimos el bucle de supervivencia del jugador en el rincón salvaje del mapa.

- [x] **3.1. Componentes de Supervivencia del Jugador (`SurvivalComponent.gd`, `scenes/ui_root.gd`):**
  - Necesidades de **Hambre (`🍖 Hambre`)** y **Sueño/Descanso (`💤 Sueño`)** integradas en el HUD, guardadas en JSON y conectadas a la comida y al descanso junto a la hoguera.
- [x] **3.2. Forrajeo (Estilo *Stardew Valley*):**
  - Nodos de recolección silvestre en el bosque (`scripts/obstacles/HarvestableNode.gd`: Hierbas Medicinales y Hongos Silvestres que se recogen con `[E]`) que se regeneran automáticamente según el paso de los días del `WorldClock` y persisten al guardar/cargar.
- [x] **3.3. Tala y Minería con Eficiencia de Herramientas:**
  - Teclas `[1]` a `[4]`: Aunque puedes cortar madera con la `[1]` Espada (`35%` eficiencia) o picar piedra con el `[2]` Martillo (`35%` eficiencia), el **`[3]` Hacha de Leñador** (`180%` eficiencia en Tala) y el **`[4]` Pico de Minero** (`180%` eficiencia en Minería) extraen recursos en cada golpe y derriban el nodo mucho más rápido.
- [x] **3.4. Caza Sistémica, Balística de Flechas y Desollado (`WildAnimal.gd`, `ArrowProjectile.gd`):**
  - **`[5]` Arco de Caza con Punto de Mira (`Crosshair2D.gd`) y Sistema de Tensión:** Mantener presionado `Clic Izquierdo` tensa el arco (cerrando la retícula y llenando la barra de tensión) y al soltar dispara flechas el doble de largas (`1.1x`) con alcance proporcional a la tensión (hasta `330 px`), arco parabólico, sombra en el suelo y caída realista.
  - **Sistema de Cadáver y Desollado (`[E] Desollar`):** Al abatir un animal, cae tumbado en el sitio (`CARCASS`). Debes acercarte y presionar `[E]` para desollarlo.
  - **Arquitectura Anatómica Modular (`get_anatomy_yields()` en `WildAnimal.gd` y `SimpleInventory.gd`):** Entrega `Carne Cruda` y `Cuero Animal` (o `Piel de Zorro` en depredadores), y tiene preparada en código la estructura para extraer **Huesos**, **Astas/Cuernos**, **Vísceras y Tendones** y **Grasa Animal**.
- [x] **3.5. Ecosistema del Bosque, Rutinas estilo *RDR2* y Cadena Trófica (`EcosystemManager.gd`, `WildAnimal.gd`):**
  - **Bosque Profundo Alejado de la Zona Inicial:** Ubicado al Sur/Suroeste de la aldea (`y = 350..1050`), con **20 Pinos**, **8 Vetas Rocosas**, **22 Plantas Silvestres** (cada planta con `2` brotes/bocados para los animales = `44` raciones), **3 Madrigueras de Conejos**, **2 Claros de Venados** y **2 Guaridas de Zorro**.
  - **Caza del Zorro con Sigilo + Salto de Takedown (`POUNCE`) y `50%` de Escape Inicial:** Los conejos corren más rápido en campo abierto (`134` vs `122`), pero el zorro se acerca agachado en sigilo (`STALK_PREY`) y lanza un salto parabólico (`POUNCE`, `245 px/s`) para atrapar al conejo. La primera vez que un conejo es atrapado tiene un **`50%` de probabilidad de zafarse** (`escaped_first_pounce`) y huir a su madriguera; si falla el escape (o lo atrapan por segunda vez), es un *Takedown* letal.
  - **Saciedad de 2 Niveles (`2/2`), Día de Reserva y Reproducción por Parejas (`SEEK_MATE`):**
    - Con **1 comida (`1/2`)** el animal cubre su supervivencia del día.
    - Al comer **2 veces (`2/2`)** queda `Saciado`, deja de comer/cazar por el resto del día y gana **1 Día de Reserva** completo al día siguiente sin necesidad de comer (permitiendo que las plantas rebroten y las presas descansen).
    - **Reproducción Realista:** Solo cuando **dos animales de la misma especie han comido 2 veces (`2/2`) el mismo día**, se buscan mutuamente (`SEEK_MATE`), se juntan (`[Cortejo ♥]`) y tienen probabilidad (`75%`) de engendrar una cría al amanecer.
  - **Presión Ecológica e Incursiones a la Granja:** Conectado con grupos `"farm_crops"` y `"livestock_prey"` para futuras incursiones a cultivos y gallineros cuando escasea la comida en el bosque.

---

### FASE 4: Asentamiento, Crafteo, Agricultura y Pesca
El jugador pasa de sobrevivir al día a construir su hogar y producir sus propios recursos.

- [x] **4.1a. Sistema de Crafteo Base (`SimpleInventory.gd`, `scenes/ui_root.gd`):**
  - Interfaz de dos columnas en `[I]` (Mochila + Taller de Crafteo) con recetas de Vendaje Limpio, Cataplasma Curativa, Hongos Asados, Carne Asada y Tablones Reforzados.
- [x] **4.1b. Campamento Inicial del Jugador (`CampSite.gd`):**
  - **⛺ Tienda de Campaña (`[E] Ir a dormir`):** Exclusiva para dormir por la noche (`20:00 - 06:00`). Al pulsar `[E]` abre un cuadro de confirmación (`"¿Quieres ir a dormir?"` con opciones `[Sí]` y `[No]`).
  - **🍲 Hoguera con Cacerola (`[E] Cocinar`):** Permite cocinar directamente `Carne Cruda` $\rightarrow$ `Carne Cocida`, `Verduras (Zanahoria/Col/Hongo)` $\rightarrow$ `Verdura Cocida` y `Huevo Fresco` $\rightarrow$ `Huevo Cocido` (preparado para sistema de recetas de cocina avanzado en el futuro).
  - **🪵 Tronco para Sentarse (`[E] Sentarse a descansar`):** Con área de acción reducida (`15 px`). Sirve únicamente para sentarse (modo descanso/AFK donde el tiempo corre normal pero tus barras de Hambre y Sueño bajan un `85%` más lento).
- [x] **4.2. Agricultura y Huerto (Estilo *Project Zomboid* Ágil — `FarmPlot.gd`):**
  - **Huerto de `3×3` parcelas (`FarmPlot.gd`):** Ubicado junto a la zona inicial (`x = 115..163, y = 75..123`).
  - **3 Cultivos con distintos tiempos y rendimientos:**
    - **🥕 Zanahoria (`carrot_seeds` $\rightarrow$ `carrot`):** Crece en **2 días** (o **1 día** con abono).
    - **🥬 Col de Huerta (`cabbage_seeds` $\rightarrow$ `cabbage`):** Crece en **3 días** (o **2 días** con abono).
    - **🌾 Trigo (`wheat_seeds` $\rightarrow$ `wheat`):** Crece en **4 días** (o **3 días** con abono); permite hornear Pan en `[I]`.
  - **Bucle de Cuidado (`[E]` y `[R]`):** Alterna semilla activa con **`[R]`** (o en `[I]`), planta con **`[E]`**, riega la tierra seca con **`[E]`**, abona con **Abono Orgánico (`fertilizer`)** con **`[E]`** (`+1 día` inmediato y `+1 cosecha extra`) y cosecha con **`[E]`** (recuperando además semillas para replantar). Conectado al grupo `"farm_crops"` para incursiones de fauna del bosque.
  - *(Expansión futura preparada en código con `require_farming_tools`: **Herramientas Agrícolas dedicadas** — **Regadera** con recarga de agua en pozo/río, **Hoz / Guadaña** para cosechar más rápido y **Compostador / Saco de Abono** para almacenar y fermentar abono en el huerto).*
- [x] **4.3. Pesca e Hidrología (`FishingSpot.gd`):**
  - **Lago del Oeste (`WestFishingLake` en `Vector2(-65, 105)`):** Cuenta con muelle de madera, ondas animadas y minijuego interactivo de picada (`[E]` para lanzar la caña y `[E]` cuando pica el pez).
  - **Especies Diurnas y Nocturnas:** De día (`06:00 - 17:59`) pican **Truchas de Río (`river_trout`)** y **Carpas Doradas (`golden_carp`)**; al atardecer y noche (`18:00 - 05:59`) aparece el **Siluro Nocturno (`night_catfish`)**. Pueden cocinarse en la Hoguera (`cooked_fish`) o venderse a *Marlo*.
- [x] **4.4. Rueda Radial de Herramientas estilo *Red Dead Redemption* (`ToolWheelUI.gd`) y Herramientas Agrícolas:**
  - **`[Tab]` Rueda Radial Independiente:** Separa las **8 herramientas y armas** (`[1]` Espada, `[2]` Martillo, `[3]` Hacha, `[4]` Pico, `[5]` Arco, `[6]` Hoz, `[7]` Regadera con `6/6` cargas de agua, `[8]` Caña de Pescar) de la **Mochila de Recursos (`[I]`)**.
  - **Pozo de Agua (`WaterWell`) y Compostador (`CompostBin`):** Ubicados junto al huerto (`x = 184`) para recargar la Regadera al `100%` y fermentar Abono Orgánico con hierbas/hongos.

---

### FASE 5: Sistemas Avanzados y Expansión Futura
Sistemas de largo plazo para cuando el núcleo del juego esté completo.

- [x] **5.1. Ganadería Básica — El Gallinero y Ataques Nocturnos de Zorros (`ChickenCoop.gd`, `WildAnimal.gd`):**
  - **Cercado Cuadrado con Gallinas (`ChickenCoop.gd`):** Incluye un **Comedero de 2 toques (`[E]` `0/2` $\rightarrow$ `1/2` $\rightarrow$ `2/2`)** y un **Nido de Huevos (`[E]` Recoger `Huevo Fresco`)**. Las gallinas alimentadas ponen huevos cada mañana y se reproducen hasta llenar el gallinero.
  - **Incursión Nocturna de Zorros Hambrientos:** Si un zorro del bosque no consiguió comer durante el día, sube de noche al Gallinero, muerde la cerca hasta **abrir un agujero (`is_breached = true`)**, entra y se lleva una gallina. El jugador recibe avisos y puede ahuyentar/cazar al zorro o **reparar el agujero con `[E]`**.
- [ ] **5.2. Breeding (Cruce y Genética de Animales):**
  - Sistema de herencia de estadísticas al cruzar dos animales de la misma especie (mejorar velocidad, resistencia, producción o fuerza generación tras generación).
- [ ] **5.3. Tecnología Anacrónica (Reactivación de `archived_systems/power_system/`):**
  - Integrar generadores antiguos, cables y máquinas reparables para automatizar o electrificar partes de tu asentamiento o de la aldea.
