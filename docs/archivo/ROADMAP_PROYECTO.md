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
  - **Gallinas Interactivas y Atacables (`Hurtbox` + Modal `[E]`):** Cada gallina cuenta con su propia `Hurtbox` (puedes atacarla con armas o arco) y un menú contextual al acercarte y pulsar `[E]` (`[1] Coger pollo para comer (+1 Pollo Crudo, +1 Pluma)` o `[2] Acariciar gallina`). El `Pollo Crudo` se puede asar en la Hoguera o en `[I]` para obtener `Pollo Asado Crujiente`.
  - **Incursión Nocturna de Zorros Hambrientos:** Si un zorro del bosque no consiguió comer durante el día, sube de noche al Gallinero, muerde la cerca hasta **abrir un agujero (`is_breached = true`)**, entra y se lleva una gallina. El jugador recibe avisos y puede ahuyentar/cazar al zorro o **reparar el agujero con `[E]`**.

---

### FASE 6: Gran Expansión de Urbanismo, Herrería/Armaduras, Mejora de Herramientas, Psicología *RimWorld*, Mascotas y Casino Visual *(COMPLETADA)*

- [x] **6.1. Pantalla Completa por Defecto y Vista en Editor 2D (`@tool`):**
  - El juego arranca directamente en **Pantalla Completa (`window/size/mode=3`)** con `[F11]` para alternar modo ventana.
  - Todos los sistemas procedurales (`World.gd`, `VillageManager.gd`, `EcosystemManager.gd`, `FarmPlot.gd`, `CampSite.gd`, `ChickenCoop.gd`, `FishingSpot.gd`, `DomesticPet.gd`) cuentan con `@tool` para previsualizarse directamente en el visor 2D de Godot Editor.
- [x] **6.2. Urbanismo Expandido, Biomas Separados y Hábitats de Fauna (`VillageManager.gd`, `EcosystemManager.gd`, `WildAnimal.gd`, `World.tscn`):**
  - **Red de Caminos de Tierra y Plaza Central Empedrada** conectando la Llanura Salvaje del Oeste, el Lago de Pesca, la Granja del Jugador, la Plaza Central, la Gran Posada, el Distrito Comercial, el Barrio Residencial Este y el Sendero Largo al Bosque Profundo (`y = 575..1240`).
  - **Bioma Separado al Oeste — 🌾 Llanura Salvaje y Ciénaga de Ranas (`x = -860..-390, y = -210..150`):**
    - Conectada por el camino del Oeste y custodiada en la entrada por el Vigía (`Guia` en `(-415, 18)`).
    - Reúne todos los enemigos hostiles y props de combate fuera de la aldea: **Campamento/Ruinas Hostiles al Noroeste** (`DummyEnemy`, `FastEnemy`, `Crate`, `Barrel`, `WeakWall`, `Obstacles Small/Large`) y **Ciénaga de Ranas al Suroeste** (`FrogEnemy` y `FrogEnemy2` sobre su propia charca pantanosa).
  - **Bioma Separado al Sur — 🌲 Bosque Profundo con 3 Hábitats de Especies No Mezclados (`y = 575..1240`):**
    - Conectado por un largo sendero desde la Plaza Central y la Granja con carteles direccionales y cruce de caminos en `y = 606..630`.
    - **Hábitat 1 (Oeste del Bosque, `x = -470..-130, y = 600..900`): 🐇 Pradera de Madrigueras y Hierbas Medicinales** (3 madrigueras + 12 hierbas locales para que los conejos pasten en su propia pradera).
    - **Hábitat 2 (Centro-Sur del Bosque, `x = -50..320, y = 800..1180`): 🦌 Claros de Pinos y Hongos Silvestres** (2 claros de manada + 10 hongos locales para que los venados vivan separados).
    - **Hábitat 3 (Este del Bosque, `x = 460..830, y = 610..960`): 🦊 Cantera de Hierro y Guaridas de Zorros** (2 guaridas + 8 vetas de mineral; los zorros patrullan su cantera y regresan a su territorio tras cazar).
  - **4 Locales Comerciales Cerrados Independientes:**
    1. ⚒️ **Herrería y Armería "Yunque Gris"** (con fragua encendida y yunque interior).
    2. 🥩 **Carnicería y Peletería "El Colmillo"**.
    3. 🪚 **Carpintería y Aserradero "Roble Viejo"**.
    4. 🐟 **Pescadería y Molino "Aguas Claras"**.
  - **4 Casas Residenciales Familiares Separadas (`112×78 px`)** en el Barrio Residencial del Este (con 2 camas, mesa de comedor y alfombra para cada familia).
  - **2 Grandes Edificios Mixtos (Tienda Pública + Vivienda Privada):**
    1. 🌿 **Botica y Casa-Jardín "Raíz Verde"** (Elena y Tomás viven en la parte trasera separada por tabique interior y atienden la botica delante).
    2. 🍺 **Gran Posada, Taberna y Casino "El Jabalí Dorado" (`260×145 px`)** con barra de cocina, comedor, sala de casino con mesa de Póker y mesa de Billar, cuarto privado de Marta y 4 camas en el ala de huéspedes.
- [x] **6.3. Casino Visual, Billar 2D, Pausa de Tiempo y Asiento Físico de NPCs (`TavernGamesUI.gd`, `WorldClock.gd`):**
  - Al abrir la mesa de juegos, **el reloj del mundo y el drenaje de hambre/sueño se congelan (`WorldClock.set_activity_pause(true)`)** para no alterar ninguna rutina de la IA.
  - Los 2 NPCs rivales se **sientan físicamente en las sillas de la mesa de la Taberna** mientras dura la partida.
  - Interfaz con **Retratos Visuales de los NPCs**, insignias de rasgos, expresiones en vivo, **Cartas Gráficas animadas** y el 4.º juego **`[F4]` 🎱 Billar de la Posada** con física de bolas 2D, ángulo de taco y barra de potencia.
- [x] **6.4. Minijuego de Pesca de Precisión estilo *Stardew Valley* (`FishingSpot.gd`):**
  - Barra vertical de precisión donde controlas el rectángulo verde manteniendo **`[E]` / `[Espacio]` / `Clic Izquierdo`** para seguir el movimiento único de cada especie (*Trucha de Río* suave, *Carpa Dorada* saltarina, *Siluro Nocturno* agresivo) hasta llenar el `100%` de captura.
- [x] **6.5. Iconos Visuales (`16×16`) en Inventario/Crafteo y Sistema de Armaduras en 4 Slots (`SimpleInventory.gd`, `scenes/ui_root.gd`, `Player.gd`):**
  - Todos los objetos y recetas muestran su **icono pixel-art `16×16`** en la Mochila (`[I]`).
  - **4 Slots de Armadura (`🪖 Casco`, `🦺 Pecho`, `👖 Piernas`, `🥾 Botas`)** en 3 Tiers (**Cuero Curtido**, **Hierro Forjado**, **Acero Maestro**), comprables en la Herrería o fabricables en `[I]`, que otorgan reducción real de daño físico (`armor_defense`), resistencia al sangrado (`armor_bleed_resistance`), resistencia al stun (`armor_stun_resistance`) y overlay visual modular sobre el personaje.
- [x] **6.6. Mejora de Armas y Herramientas por Niveles (`Nv.1 Básico` $\rightarrow$ `Nv.2 Hierro` $\rightarrow$ `Nv.3 Acero Maestro`):**
  - En el diálogo de *Thoran* (Maestro Herrero) puedes fundir `Lingotes de Acero` y mejorar las **8 herramientas y armas** con Oro + Materiales, subiendo su daño, eficiencia de tala/minería (`180%` $\rightarrow$ `270%` $\rightarrow$ `380%`), bono de cosecha de la Hoz (`+1` $\rightarrow$ `+2` $\rightarrow$ `+3`), capacidad de la Regadera (`6` $\rightarrow$ `12` $\rightarrow$ `20`) y tamaño de la barra de pesca (`100%` $\rightarrow$ `128%` $\rightarrow$ `155%`).
- [x] **6.7. Skins de Oficio Personalizadas, Psicología estilo *RimWorld* y Mascotas Domésticas (`VillageNPC.gd`, `DomesticPet.gd`):**
  - Skins pixel-art distintivas por oficio (Marta con gorro blanco de Chef y delantal, Garrick con delantal de carnicero, Thoran con gafas de forja y delantal de cuero, etc.).
  - Cada NPC posee **Rasgos de Personalidad (`traits`)**, **Objeto Favorito (`favorite_item`)**, **Humor (`mood 0–100%`)** y **Registro de Pensamientos (`thoughts`)** visibles al pasar el ratón y al conversar.
  - **6 Mascotas Domésticas (`DomesticPet.gd` — 3 Perros y 3 Gatos):** Interactuables con `[E]` para acariciar o alimentar. El perro guardián **🐕 Toby** vigila el Gallinero por la noche y ahuyenta a ladridos a los zorros hambrientos antes de que rompan la cerca.
- [x] **6.8. Mapa Cartográfico Interactivo (`[M]`) + Minimapa en Vivo (`ValleyMapUI.gd`):**
  - Minimapa siempre visible en la esquina superior derecha y **Mapa Completo del Valle (`[M]`)** con las 4 regiones coloreadas, los 10 edificios con nombre, caminos, posición pulsante del jugador, puntos en vivo de todos los aldeanos (con inspector al pasar el ratón), fauna activa del bosque y hostiles de la Llanura.
- [x] **6.9. Expediciones Físicas Matutinas de los 5 Maestros Artesanos (`06:30–09:30 AM` en `VillageNPC.gd`):**
  - Cada mañana entre las `06:30` y las `09:30 AM`, los 5 maestros artesanos caminan físicamente por los senderos hasta el bosque, el lago o la cantera para recolectar su materia prima antes de regresar a abrir su local comercial.
- [x] **6.10. Botín Único, Cocina y Reaparición en la Llanura Salvaje + Guardado Total (`[F5]/[F9]`):**
  - Nuevos ítems con iconos `16×16`: **`frog_legs` (*Ancas de Rana Crudas*)**, **`fried_frog_legs` (*Ancas de Rana al Ajillo*, `+50 HP, +70 STM, +65 Hambre`)** y **`bandit_scrap` (*Reliquia y Chatarra de Bandido*)**.
  - Las ranas y bandidos de la Llanura sueltan botín + oro al morir y **reaparecen cada 2 días** (`DummyEnemy.gd`).
  - `GameManager.gd` guarda y restaura el 100% del mundo: parcelas del Huerto (`FarmPlot`), Gallinero (`ChickenCoop`), Ecosistema completo (`EcosystemManager` + `WildAnimal`) y enemigos de la Llanura (`plains_hostiles`).

---

### FASE 7: Expansión Integral en 10 Bloques + Rediseño Visual y Físico de Edificios (Completada ✅)
- [x] **7.0. Paredes Sólidas con Colisión (`StaticBody2D`), Suelos Texturizados en Mosaico y Mobiliario (`VillageManager.gd`):**
  - Todos los **12 edificios de la aldea** dejaron de ser simples polígonos planos con líneas y ahora se construyen mediante `_construct_solid_building(...)` con **suelos texturizados en mosaico (`floor_wood_planks.png`, `floor_stone_forge.png`, `floor_hospital_tile.png`)**, **muros texturizados (`wall_timber_h/v.png`, `wall_stone_h/v.png`)**, **colisiones físicas reales (`StaticBody2D` en capa 1)** con **puertas de `40–50 px`**, navegación por umbrales (`get_navigation_waypoint`) y mobiliario decorativo de `assests/Comprados/ Packs/Cute_Fantasy/`.
- [x] **7.1. 🏥 Hospital de Urgencias, ⚰️ Morgue Forense y Estado "Agonizando" (`VillageManager.gd`, `VillageNPC.gd`):**
  - Edificio clínico (`Vector2(745, 148)`) dirigido por el **Dr. Valen (`TradeRole.DOCTOR`)** con **2 Camas de Urgencias** delante y **3 Mesas de Autopsia en la Morgue Forense** detrás.
  - Cuando un `VillageNPC` cae a `0 HP`, entra primero en estado **`is_downed = true` (`🩸 ¡AGONIZANDO!`)** con una cuenta atrás (`34s` corte/espada, `58s` normal, `90s` contundente). El jugador o el Dr. Valen pueden salvarle la vida pulsando `[E]` o usando un `Botiquín Quirúrgico` (`+25 Oro` y `+40` Afinidad Familiar).
  - Si el tiempo se agota o es rematado, el cuerpo pasa a una **Mesa de Autopsia de la Morgue Forense** con un dictamen forense inspeccionable (`[E]`): víctima, hora exacta, escena del crimen, causa de la herida y cruce con testigos.
- [x] **7.2. 🚓 Comisaría, 🔒 Cárcel y Sistema Realista de Testigos (*"Me vieron entrar a la casa"*) (`VillageManager.gd`, `VillageNPC.gd`):**
  - Edificio fortificado (`Vector2(915, 148)`) con el **Comisario Vane (`TradeRole.SHERIFF`)**, el **Guardia Rodric (`TradeRole.GUARD`)** y **2 Celdas con Rejas de Hierro (`jail_bars_h/v.png`)**.
  - **Registro de Testigos de Entrada (`sighting_log`):** Si entras o sales de un edificio sin usar Sigilo (`[C]`) y un vecino consciente está dentro del rango visual, recuerda tu entrada y la hora. Si luego aparece un cadáver en la Morgue de ese edificio, la policía cruza el registro con la autopsia y emite una **Orden de Arresto (`wanted_level`, `bounty_gold`)**. Si entraste en Sigilo (`[C]`) sin testigos, el caso queda como *"Sospechoso Desconocido (Caso sin resolver)"*.
  - Al ser interceptado por la guardia o acudir a la Comisaría puedes **`[1]` Entregarte y cumplir condena en la Celda hasta las 06:00 AM**, **`[2]` Pagar Fianza/Multa en Oro** o **`[3]` Forzar los barrotes para fugarte**.
- [x] **7.3. 🔓 Sigilo Doméstico, Cerraduras y Cofres en las Casas (`house_chests` en `VillageManager.gd`):**
  - Cofres privados (`house_chest_closed.png`) dentro de las casas residenciales y tiendas. Abrirlos en sigilo sin testigos otorga Oro y objetos raros; ser visto dispara alarma de robo y caída de reputación familiar.
- [x] **7.4. 💬 Memoria Social, Rumores y Reputación por Familias (`modify_family_reputation`):**
  - Salvar o ayudar a un miembro sube la afinidad de toda su familia (`affinity >= 45` desbloquea **`-20%` de descuento de Aliado Familiar** en su tienda). Agraviar o robar a una familia (`affinity <= -35`) bloquea su comercio hasta pagar una **Compensación Familiar (`-20 Oro`)**.
- [x] **7.5. 📋 Tablón de Encargos, Urgencias Médicas y Cazarrecompensas en la Plaza (`Vector2(465, 24)`):**
  - Tablón interactivo (`questboard_1.png`) en la Plaza Central con 3 contratos diarios renovables: **Encargo de Gremios**, **Urgencia del Hospital** y **Recompensa Policial**.
- [x] **7.6. 🏡 Construcción y Expansión de la Casa Propia del Jugador (`CampSite.gd`):**
  - Mejora tu vivienda desde **Nv.1 Tienda de Campaña** $\rightarrow$ **Nv.2 Cabaña de Madera Propia** $\rightarrow$ **Nv.3 Casa de Piedra con Cofre Personal** (con paredes sólidas, suelo en mosaico, cama interior y cofre privado para guardar Oro protegido de multas), disponible hablando con *Bram* en la Carpintería o desde la **Mesa de Obras** de tu campamento.
- [x] **7.7. 🌦️ Clima Dinámico y Eventos del Valle (`WorldClock.gd`, `World.gd`, `FarmPlot.gd`):**
  - Clima diario (**`☀️ Despejado`**, **`🌧️ Lluvia`**, **`🌫️ Niebla`**, alternable al instante con **`[F7]`**): la lluvia riega automáticamente todo el huerto 3x3 y amortigua el ruido de tus pasos un `35%`, mientras que la niebla reduce un `35%` el rango de visión de testigos, guardias y fauna.
- [x] **7.8. 🦴 Despiece Anatómico Avanzado y Alquimia/Somníferos en la Botica (`WildAnimal.gd`, `SimpleInventory.gd`):**
  - Activado el despiece anatómico (`bones`, `antlers`, `sinew_viscera`, `animal_fat`) y añadidas recetas de Alquimia en `[I]` y en la Botica de *Elena*: **🧪 Somnífero Nocturno (`sleeping_draught`, duerme a un NPC 40s sin matarlo)**, **⚡ Tónico de Ligereza (`speed_tonic`, `+30%` velocidad)** y **🩺 Botiquín Quirúrgico (`surgical_kit`, revive agonizantes o cura `+85 HP`)**.
- [x] **7.9. 🧬 Crianza Selectiva y Genética de Animales (`WildAnimal.gd`, `EcosystemManager.gd`, `ChickenCoop.gd`):**
  - Cuando animales o gallinas bien alimentados se reproducen, su descendencia hereda **`Genética Nv.1 -> Nv.2 -> Nv.3`**, otorgando más carne/pieles y **🥚✨ Huevos Dorados (`golden_egg`)** en el Gallinero.
- [x] **7.10. ⚡ Tecnología Anacrónica: Electricidad, Generador, Farolas Eléctricas y Aspersor Automático (`CampSite.gd`, `VillageManager.gd`):**
  - **Generador Eléctrico Antiguo (`ancient_generator.png`)** y **Aspersor Automático (`auto_sprinkler.png`)** en el centro del Huerto 3x3 (`Vector2(139, 99)`), además de **6 Farolas Eléctricas (`lamp-post1.png`)** que iluminan las calles de la aldea por la noche.

---

### FASE 8: Economía Dinámica de Oferta y Demanda, Consumo Real de Alimentos, Sabotaje Industrial y Propiedad Híbrida de Negocios (Completada ✅)
- [x] **8.1. 📊 Precios Dinámicos de Oferta y Demanda en Tiempo Real (`VillageManager.gd`, `VillageNPC.gd`):**
  - El multiplicador de mercado (`get_trade_market_multiplier`) de cada uno de los 5 gremios (**Herrería**, **Carnicería**, **Carpintería**, **Pescadería** y **Botica**) + **Posada** fluctúa en vivo según el stock real del mostrador y el estado de producción:
    - **`📉 Excedente (-20%, 0.80x)`** cuando el mostrador acumula $\ge 12$ unidades.
    - **`⚖️ Estable (100%, 1.00x)`** en condiciones normales de abastecimiento ($4\text{–}11$ unidades).
    - **`📈 Escasez (+55%, 1.55x)`** cuando quedan $\le 3$ unidades en el mostrador.
    - **`🔥 Crisis de Suministro (+125%, 2.25x)`** cuando el stock cae a $0$, el maestro artesano está muerto/incapacitado o el taller ha sido saboteado.
- [x] **8.2. 🍽️ Consumo Real de Comida del Pueblo (`consume_village_meal_for_npc`):**
  - Cada vez que un aldeano se sienta a comer en su mesa familiar o en la Posada (`ActivityState.EATING`), consume **1 ración real de comida** del stock de las tiendas de alimentación del valle (Pescadería/Molino, Carnicería, Botica o Posada).
  - Si el jugador es **Socio** o **Dueño Único** de esa tienda, las compras diarias de los vecinos ingresan **Oro real automáticamente en la Caja Registradora (`vault_gold`)**. Si todas las tiendas se quedan sin comida, los aldeanos sufren pensamientos negativos de escasez (`"¡Escasez de comida en el pueblo! (-12)"`) y el precio de los alimentos se dispara a `2.25x`.
- [x] **8.3. 💣 Sabotaje Industrial de Talleres con `[F]` (`sabotage_shop_stall`):**
  - Acercarse al mostrador/taller de cualquiera de los 5 comercios y pulsar **`[F]`** (o el botón `[4]` del modal del negocio) permite **sabotear la maquinaria del taller**:
    - Bloquea la expedición matutina y la producción del maestro artesano durante **2 días** (`sabotaged_days = 2`), reduce el stock del local un `60%`, otorga `1` material saqueado y dispara el precio de sus mercancías a **`2.25x` (Crisis)**.
    - Además, pone el negocio en estado de **Liquidación**, reduciendo el precio de compra de su escritura al contado a **`65 Oro`**.
    - Si lo haces en **Sigilo (`[C]`)** sin testigos con línea de visión (`has_line_of_sight`), es un crimen perfecto; si un vecino te ve, sube tu `wanted_level`, añade `+35 Oro` de multa policial y baja `-40` la reputación con esa familia.
- [x] **8.4. 📜 Modelo Híbrido de Propiedad de Negocios, Abastecimiento y Contratación (`open_business_management_ui`):**
  - Interactuar con **`[E]`** en el mostrador de cualquier negocio o elegir `"📜 Negocio, Escritura de Propiedad y Caja Registradora"` en el diálogo del artesano abre el **Panel de Gestión Comercial**:
    - **`[1]` Compra Híbrida de Escritura / Recaudación:**
      - **Comprar Acciones de Socio (`110 Oro`, o `85 Oro` si eres Aliado Familiar):** Conservas al artesano trabajando, obtienes **`-30%` de descuento permanente** en la tienda y cobras dividendos diarios + comisión por ventas en la **Caja Registradora (`vault_gold`)**.
      - **Comprar Escritura en Liquidación (`65 Oro` si el local está vacante, sin stock o saboteado) o Adquirir el 100% (`+55 Oro` desde Socio):** Te conviertes en **Dueño Único (`SOLE_OWNER`)**, recibiendo el `100%` de las ventas vecinales en la Caja Registradora.
    - **`[2]` Abastecer Mostrador desde tu Mochila:** Coloca tus propios recursos cosechados/cazados/forjados directamente en el mostrador para que se vendan automáticamente a los aldeanos (o cóbralos al contado a precio de escasez si el local aún no es tuyo).
    - **`[3]` Contratar Nuevo Encargado (`-30 Oro`):** Si el maestro artesano murió y el negocio quedó vacante, puedes contratar a un nuevo encargado desde el propio mostrador para reanudar las expediciones matutinas y la producción diaria.
    - **`[4]` Sabotear Taller (`[F]`) o Reparar Maquinaria Saboteada (`-1 Madera` o `-12 Oro`):** Permite sabotear a la competencia o reparar tu propio taller tras adquirirlo en liquidación.
