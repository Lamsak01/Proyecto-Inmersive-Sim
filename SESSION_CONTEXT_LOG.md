# 📋 REGISTRO DE CONTEXTO Y BITÁCORA DE DESARROLLO (`SESSION_CONTEXT_LOG.md`)

> **INSTRUCCIONES PARA EL AGENTE / IA EN LA PC DE ESCRITORIO:**
> Si estás leyendo este archivo al abrir el repositorio en la PC de escritorio del usuario, **lee este documento completo junto con `ROADMAP_PROYECTO.md`** antes de realizar cualquier cambio. Aquí está documentada toda la evolución de nuestra conversación, las decisiones de diseño del usuario, la arquitectura exacta de cada sistema implementado hasta el commit actual y los siguientes pasos pendientes.

---

## 1. Filosofía y Visión del Proyecto ("La Placa de Petri")
* **Concepto:** Immersive Sim / Sandbox de Supervivencia 2D Top-Down Pixel Art en Godot 4.7.
* **Referentes clave definidos por el usuario:**
  * ***Kenshi*:** Empezar desde cero, combate visceral con **sangrado (`bleed_buildup`)**, **aturdimiento/KO no letal (`stun_buildup` / Takedown por la espalda)** y estética anacrónica.
  * ***RimWorld* / *The Sims*:** Cadenas de producción con stock real, sucesión orgánica de oficios y NPCs con familias y **necesidades dinámicas (Sub-stats de Hambre, Energía y Socialización)**.
  * ***Stardew Valley* / *Project Zomboid*:** Agricultura ágil pero profunda (`3×3` parcelas, riego, abono orgánico, cosecha con devolución de semillas), ganadería en gallinero, pesca por horarios, forrajeo, tala y minería con eficiencia por herramienta.
  * ***Red Dead Redemption 2*:** Ecosistema salvaje con rutinas animales realistas, caza de zorros con sigilo + salto (`POUNCE`), **Rueda Radial de Herramientas (`[Tab]`)** separada de la **Mochila (`[I]`)**, y **minijuegos de Taberna (Póker Texas Hold'em contra los NPCs, Blackjack 21 y Ruleta)**.

---

## 2. Resumen Cronológico de lo Desarrollado en Esta Sesión

### Bloque A — Reloj del Mundo, Guardado JSON desde Cero e Inventario/Crafteo
1. **`scripts/systems/WorldClock.gd` (Autoload):**
   * Ciclo continuo de 24 horas y contador de Días (`current_day`, `current_hour`, `current_minute`), iluminación ambiental dinámica (`CanvasModulate` en `scripts/World.gd`) y reducción automática del rango de visión de enemigos de noche (`get_vision_multiplier()`).
   * Atajo de prueba: **`[T]` avanza +2 horas**.
2. **`scripts/systems/GameManager.gd` (Autoload):**
   * Guardado y cargado completo en JSON (`user://village_save.json`) con **`[F5]` (Guardar)** y **`[F9]` (Cargar)**.
   * Guarda: hora/día del reloj, posición/vida/sangre/stamina/hambre/sueño/arma/cargas de regadera del jugador, inventario completo (`SimpleInventory`), estado de las 9 parcelas de cultivo (`FarmPlot`), estado del gallinero (`ChickenCoop`), estado de todos los NPCs de la aldea (`VillageNPC`: stock, afinidad, sub-stats, oficio actual, si murió o heredó puesto) y objetos recolectables/destructibles.
3. **`scripts/systems/SimpleInventory.gd` y `scenes/ui_root.gd`:**
   * Inventario ligero con Oro (`gold`), catálogo completo de materiales, semillas, pescados, carnes, platos cocinados y recetas de crafteo.
   * La **Mochila y Taller de Crafteo** se abre exclusivamente con **`[I]`** (separada de la rueda de herramientas en `[Tab]`).

---

### Bloque B — Herramientas (`[1]` a `[8]`), Rueda Radial (`[Tab]`) y Apuntado 360°
1. **`scripts/ui/ToolWheelUI.gd` (`[Tab]`):**
   * **Rueda Radial estilo *Red Dead Redemption*** con los **8 slots de herramientas y armas**:
     * **`[1]` Espada:** Combate de corte y sangrado (`35%` tala improvisada).
     * **`[2]` Martillo:** Combate contundente y KO/Stun (`35%` minería improvisada).
     * **`[3]` Hacha de Leñador:** Especialista en Tala (`180%` eficiencia en árboles).
     * **`[4]` Pico de Minero:** Especialista en Minería (`180%` eficiencia en vetas de roca/hierro).
     * **`[5]` Arco de Caza:** Ataque a distancia silencioso con sistema de tensión (*Hold-to-Draw* manteniendo `Clic Izquierdo` o `[Espacio]`) y flechas balísticas (`scripts/systems/combat/ArrowProjectile.gd`) con sombra y caída parabólica.
     * **`[6]` Hoz de Cosecha:** Otorga **`+1` cultivo extra** al cosechar plantas maduras en el huerto.
     * **`[7]` Regadera Agrícola:** Tiene **`6/6` cargas de agua** para regar el huerto; se recarga al `100%` en el **Pozo de Agua (`(184, 82)`)** o en la orilla del **Lago del Oeste (`(-65, 105)`)**.
     * **`[8]` Caña de Pescar:** Se equipa para pescar en el Lago del Oeste.
2. **`scripts/ui/Crosshair2D.gd` y `scripts/PlayerCombatController.gd`:**
   * Punto de mira híbrido: sigue el ratón 360° en PC de escritorio, y si no se toca el ratón (modo teclado/ThinkPad), acompaña automáticamente la dirección `W/A/S/D` o las Flechas (`↑ ↓ ← →`).

---

### Bloque C — Ecosistema del Bosque Profundo (Sur/Suroeste: `y = 350..1050`)
* **Archivos:** `scripts/systems/EcosystemManager.gd`, `scripts/enemies/WildAnimal.gd`, `scripts/obstacles/HarvestableNode.gd`.
* **Composición:** 20 Pinos talables, 8 Vetas Rocosas minables, 22 Plantas Silvestres (cada una con `2/2` brotes para herbívoros), 3 Madrigueras de Conejos, 2 Claros de Venados y 2 Guaridas de Zorros.
* **Mecánicas estilo *RDR2*:**
  * **Caza del Zorro:** El zorro acecha en sigilo (`STALK_PREY`) y salta (`POUNCE`). La primera vez que atrapa a un conejo, el conejo tiene un **`50%` de probabilidad de zafarse** (`escaped_first_pounce`) y huir a su madriguera.
  * **Saciedad `2/2` y Día de Reserva:** Con `1/2` comida el animal sobrevive el día; con `2/2` queda saciado, gana **1 Día de Reserva** para el día siguiente y busca pareja (`SEEK_MATE`) con otro animal `2/2` de su especie para reproducirse al amanecer.
  * **Desollado (`[E]`):** Al abatir un animal queda su cadáver (`CARCASS`) para desollar y obtener `Carne Cruda`, `Cuero Animal` o `Piel de Zorro` (con arquitectura lista en `get_anatomy_yields()` para huesos, astas, tendones y grasa).

---

### Bloque D — Tu Asentamiento: Huerto (`3×3`), Campamento, Gallinero y Lago de Pesca
1. **Huerto `3×3` (`scripts/obstacles/FarmPlot.gd` en `x = 115..163, y = 75..123`):**
   * 3 cultivos: **Zanahoria** (2 días), **Col** (3 días) y **Trigo** (4 días).
   * Cambia semilla activa con **`[R]`**, planta con **`[E]`**, riega con **`[E]`**, abona con **`[E]`** (`+1` día inmediato y `+1` cosecha) y cosecha con **`[E]`**.
   * Junto al huerto están el **🪣 Pozo de Agua (`(184, 82)`)** y el **♻️ Compostador (`(184, 114)`)**.
2. **Campamento del Jugador (`scripts/obstacles/CampSite.gd` en `Vector2(168, 24)`):**
   * **⛺ Tienda de Campaña:** Solo permite dormir de noche (`20:00 - 06:00`) y abre un cuadro de confirmación **`"¿Quieres ir a dormir?"` (`[1] Sí` / `[2] No`)**.
   * **🍲 Hoguera con Cacerola:** Cocina `Carne Cruda` $\rightarrow$ `Carne Cocida`, `Pescado` $\rightarrow$ `Pescado Asado`, `Verduras` $\rightarrow$ `Verdura Cocida` y `Huevo` $\rightarrow$ `Huevo Cocido`.
   * **🪵 Tronco para Sentarse:** Con área de acción ajustada (`15 px`). Sirve exclusivamente para **sentarse a descansar (modo AFK)** sin dormir, reduciendo un **`85%`** el desgaste de Hambre y Sueño (`SurvivalComponent.gd`).
3. **Gallinero Cuadrado (`scripts/obstacles/ChickenCoop.gd` en `Vector2(42, 99)`):**
   * Comedero de **2 toques con `[E]` (`0/2` $\rightarrow$ `1/2` $\rightarrow$ `2/2`)** y Nido de Huevos (`[E]` recoger `Huevo Fresco`).
   * **Ataque Nocturno de Zorros:** Si un zorro del bosque no comió durante el día, sube de noche al gallinero, muerde la cerca hasta **abrir un agujero (`is_breached = true`)** y roba una gallina. Puedes reparar el agujero con **`[E]`**.
4. **Lago de Pesca del Oeste (`scripts/obstacles/FishingSpot.gd` en `Vector2(-65, 105)`):**
   * Muelle de madera con ondas animadas y minijuego de reacción (`[E]` lanzar caña $\rightarrow$ esperar picada $\rightarrow$ pulsar `[E]` cuando salpica la boya).
   * **De Día (`06:00 - 17:59`):** *Trucha de Río* y *Carpa Dorada*. **De Noche (`18:00 - 05:59`):** *Siluro Nocturno* (`22 Oro`) y *Carpa Dorada*.

---

### Bloque E — La Aldea Viva: 5 Casas Familiares, Horario Laboral (`08:00–18:00`), Sub-stats y Taberna con Casino
* **Archivos:** `scripts/systems/VillageManager.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/ui/TavernGamesUI.gd`.
* **Las 5 Casas Familiares (`x = 335..575`):** Cada casa tiene suelo, paredes con puerta, **2 camas**, **mesa de comedor familiar** y **mostrador del oficio** delante:
  1. **Casa Colmillo (Carnicería — `(335, -45)`):** *Garrick* (Maestro Carnicero) + *Lina* (Esposa y Curtidora).
  2. **Casa Yunque Gris (Herrería — `(455, -45)`):** *Thoran* (Maestro Herrero) + *Kael* (Hijo y Aprendiz).
  3. **Casa Roble Viejo (Carpintería — `(575, -45)`):** *Bram* (Maestro Carpintero) + *Mila* (Hermana y Ebanista).
  4. **Casa Raíz Verde (Herboristería — `(385, 88)`):** *Elena* (Herborista) + *Tomás* (Esposo y Hortelano).
  5. **Casa Aguas Claras (Pescadería — `(515, 88)`):** *Marlo* (Pescador y Molinero) + *Nora* (Hija y Redera).
* **Horario Laboral + Rutinas Dinámicas por Sub-stats (`🍖 Hambre`, `💤 Energía`, `💬 Socialización`):**
  * **De `08:00 AM` a `18:00 (6:00 PM)`:** Horario de trabajo obligatorio (`_is_mandatory_work_hours()`). Ningún trabajador abandona su puesto antes de las `18:00`; sus sub-stats se van desgastando durante la jornada.
  * **A partir de las `18:00`:** Quedan libres y deciden dinámicamente según sus sub-stats si ir a cenar a la mesa de su casa o a la Taberna (`EATING`), buscar a su familia/vecinos para charlar (`SOCIALIZING` con burbujas `💬`) o irse a dormir a su cama (`SLEEPING`).
* **Taberna y Posada *"El Jabalí Dorado"* (`x = 355..540, y = -225..-130`):**
  * Regentada por **Marta (Tabernera)** (turno `08:00 - 23:00`).
  * Tiene **4 camas** (1 de alquiler para el jugador por `8 Oro` + 3 camas donde duermen los **3 Viajeros sin Oficio**: **Aldric, Sora y Darío**).
  * **Sucesión en 2 Niveles:** Si un maestro artesano muere, al día siguiente primero hereda el oficio su **Familiar directo** de la misma casa; si falta toda la familia, uno de los **3 Viajeros sin Oficio de la Taberna** se muda a la casa y asume el puesto.
  * **🎲 Mesa de Juegos y Apuestas (`Vector2(488, -156)` y en el diálogo de Marta):**
    * Abre `TavernGamesUI.gd` con **`[F1]` ♠️ Póker Texas Hold'em contra 2 NPCs de la aldea**, **`[F2]` 🃏 Blackjack 21** y **`[F3]` 🎡 Ruleta de la Posada**.

---

## 3. Reglas Técnicas Importantes para Godot 4.7 en este Repositorio
1. **Tipado Explícito en GDScript:** Godot 4.7 tiene inferencia estricta de tipos. **Nunca usar `:=`** al leer propiedades de un `Variant`, de un `Dictionary` sin tipar o de un `Node` genérico (ej. usar siempre `var d: float = player.global_position.distance_squared_to(...)` con `player: Node2D`).
2. **Pantalla Completa y Cámara (`project.godot` y `scripts/World.gd`):**
   * Configurado con `window/stretch/aspect="expand"`, `window/stretch/scale_mode="fractional"` y `Parallax2D.repeat_size = Vector2.ZERO` para que en pantallas `1080p`/monitores grandes se vea a pantalla completa sin bordes ni recortes.
   * Zoom de cámara en vivo con **Rueda del Ratón** o teclas **`[+]` / `[-]`**, y Pantalla Completa con **`[F11]`**.

---

### Bloque F — Gran Expansión de 10 Bloques (Urbanismo, Herrería/Armaduras, Mejora de Herramientas, Pesca Stardew, Casino Visual + Billar, Psicología RimWorld y Mascotas)
1. **Pantalla Completa por Defecto y Editor 2D (`project.godot`, `scripts/World.gd`):**
   * `window/size/mode=3` en `project.godot` para iniciar siempre en **Pantalla Completa** (`[F11]` alterna ventana/pantalla completa).
   * Activado `@tool` con guardias `Engine.is_editor_hint()` en todos los gestores y nodos del mundo para ver la aldea, granja y bosque directamente en el visor 2D del editor.
2. **Urbanismo Expandido, Separación de Biomas y Hábitats de Fauna (`scripts/systems/VillageManager.gd`, `scripts/systems/EcosystemManager.gd`, `scripts/enemies/WildAnimal.gd`, `scenes/World.tscn`):**
   * **Caminos y Plaza Empedrada:** Red de caminos conectando la Llanura Salvaje del Oeste (`x = -465`) $\rightarrow$ Lago de Pesca (`-65`) $\rightarrow$ Granja (`140`) $\rightarrow$ Plaza Central (`x = 395..535, y = 10..88`) $\rightarrow$ Posada, Tiendas, Barrio Residencial Este y Sendero Largo al Bosque Profundo (`y = 575..1240`).
   * **Bioma Separado al Oeste — 🌾 Llanura Salvaje y Ciénaga de Ranas (`x = -860..-390, y = -210..150`):**
     * Se movieron todos los enemigos hostiles y objetos del prototipo fuera de la aldea hacia la Llanura del Oeste: `Guia` (`(-415, 18)`), `WeaponPickup` (`(-445, 18)`), `Crate` (`(-520, -45)`), `Barrel` (`(-548, -45)`), `WeakWall` (`(-575, -80)`), `DummyEnemy` (`(-615, -75)`), `FastEnemy` (`(-685, -50)`), `FrogEnemy` (`(-565, 78)`), `FrogEnemy2` (`(-645, 92)`) y los `TileMapLayer` antiguos (`Obstacles Small/Large` desplazados a `(-520, -160)`).
   * **Bioma Separado al Sur — 🌲 Bosque Profundo con 3 Hábitats No Mezclados (`y = 575..1240`):**
     * **Oeste del Bosque (`x = -470..-130, y = 600..900`): 🐇 Pradera de Madrigueras y Hierbas** (3 madrigueras + 12 hierbas medicinales).
     * **Centro-Sur del Bosque (`x = -50..320, y = 800..1180`): 🦌 Claros de los Venados y Hongos** (2 claros + 10 hongos silvestres).
     * **Este del Bosque (`x = 460..830, y = 610..960`): 🦊 Cantera de Hierro y Guaridas de Zorros** (2 guaridas + 8 vetas de mineral).
     * En `WildAnimal.gd`, los herbívoros priorizan la flora dentro de `270 px` de su `home_position` y cualquier animal saciado que esté a `> 115 px` de su territorio regresa a su zona (`RETURN_HOME`) para que las especies no se mezclen.
   * **4 Locales Comerciales Cerrados Independientes:**
     * ⚒️ **Herrería y Armería "Yunque Gris"** (`(335, -36)`): Edificio cerrado con fragua ardiente, yunque y mostrador de *Thoran*.
     * 🥩 **Carnicería y Peletería "El Colmillo"** (`(585, -36)`): Local cerrado de *Garrick*.
     * 🪚 **Carpintería y Aserradero "Roble Viejo"** (`(585, 148)`): Local cerrado de *Bram*.
     * 🐟 **Pescadería y Molino "Aguas Claras"** (`(465, 148)`): Local cerrado de *Marlo*.
   * **4 Casas Residenciales Familiares Separadas (`112×78 px`)** en el Barrio Residencial Este (`(745, -195)`, `(905, -195)`, `(745, -36)`, `(905, -36)`).
   * **2 Grandes Edificios Mixtos (Tienda Delante + Dormitorio Detrás):**
     * 🌿 **Botica y Casa-Jardín "Raíz Verde"** (`(325, 155)`, `128×96 px`): *Elena* y *Tomás* atienden delante y duermen en su cuarto trasero.
     * 🍺 **Gran Posada, Taberna y Casino "El Jabalí Dorado"** (`x = 310..570, y = -280..-135`, `260×145 px`): Barra de cocina de *Marta*, comedor, Sala de Casino (Mesa de Póker con 4 sillas + Mesa de Billar), cuarto privado de *Marta* y 4 camas de huéspedes.
3. **Casino Visual, Billar 2D, Congelación del Reloj y Asiento Físico de NPCs (`scripts/ui/TavernGamesUI.gd`, `scripts/systems/WorldClock.gd`):**
   * Al abrir `TavernGamesUI`, se activa `WorldClock.set_activity_pause(true)` congelando el reloj y el drenaje de hambre/sueño del jugador y de los NPCs.
   * Los 2 NPCs rivales se **sientan físicamente en las sillas de la mesa de la Taberna** (`set_poker_seating(true, seat_pos)`) mientras juegas.
   * Añadidos **Retratos Visuales de los NPCs** con sus skins de oficio, rasgos *RimWorld* y reacciones en vivo, **Cartas Gráficas animadas** con `Tween`, y el 4.º minijuego **`[F4]` 🎱 Billar de la Posada** (con física 2D de bolas, troneras, apuntado `[A/D]` o `[1]/[2]` y barra de potencia oscilante `[Espacio]` o `[3]`).
4. **Minijuego de Pesca de Precisión estilo *Stardew Valley* (`scripts/obstacles/FishingSpot.gd`):**
   * Al enganchar un pez con `[E]`, aparece la columna vertical de agua con la **barra verde de captura** (controlada manteniendo `[E]`, `[Espacio]` o `Clic Izquierdo`) y el marcador del pez con movimiento según especie (*Trucha*, *Carpa Dorada*, *Siluro Nocturno*).
5. **Gallinas Interactivas y Atacables (`scripts/obstacles/ChickenCoop.gd`, `scripts/obstacles/CampSite.gd`):**
   * Cada gallina tiene `Hurtbox` (atacable con armas/arco) y al acercarte y pulsar `[E]` abre un menú para **`[1] 🍗 Coger pollo para comer (+1 Pollo Crudo, +1 Pluma)`** o **`[2] ❤️ Acariciar gallina`**. El `Pollo Crudo` se puede cocinar en la Hoguera o en `[I]` para obtener `Pollo Asado Crujiente`.
6. **Iconos Visuales (`16×16`) en Inventario/Crafteo y Sistema de Armaduras en 4 Slots (`scripts/systems/SimpleInventory.gd`, `scenes/ui_root.gd`, `scripts/Player.gd`):**
   * Generados **48 iconos pixel-art `16×16`** (`assests/items/icons/*.png` y `assests/items/armor/*.png`) visibles junto a cada ítem y receta en `[I]`.
   * **4 Slots de Armadura (`🪖 Casco`, `🦺 Pecho`, `👖 Piernas`, `🥾 Botas`)** en 3 Tiers (`Cuero Curtido`, `Hierro Forjado`, `Acero Maestro`), equipables en `[I]` o al comprarlas en la Herrería, aplicando reducción real de daño, sangrado y stun + placeholder visual en el jugador.
7. **Mejora de Armas y Herramientas estilo *Stardew Valley* (`Nv.1` $\rightarrow$ `Nv.2 Hierro` $\rightarrow$ `Nv.3 Acero Maestro`):**
   * En el diálogo de *Thoran* (`TradeRole.BLACKSMITH`) puedes fundir `Lingote de Acero` y mejorar las 8 herramientas/armas (`Espada`, `Martillo`, `Hacha`, `Pico`, `Arco`, `Hoz`, `Regadera`, `Caña de Pescar`), actualizando sus estadísticas y su insignia en `ToolWheelUI.gd`.
8. **Skins de Oficio, Psicología *RimWorld* y Mascotas Domésticas (`scripts/enemies/VillageNPC.gd`, `scripts/enemies/DomesticPet.gd`):**
   * Skins distintivas para *Marta* (Chef con gorro blanco), *Garrick* (Carnicero), *Thoran* (Herrero), *Bram* (Carpintero), *Elena* (Herborista) y *Marlo* (Pescador).
   * Psicología *RimWorld* en cada NPC (`traits`, `favorite_item`, `mood`, `thoughts`).
   * **6 Mascotas Domésticas (`DomesticPet.gd` — 3 Perros y 3 Gatos):** Interactuables con `[E]` para acariciar/alimentar; el perro guardián **🐕 Toby** protege el Gallinero por la noche ahuyentando a los zorros.
9. **Las 4 Mejoras de Cierre (Mapa Cartográfico `[M]`, Guardado 100%, Expediciones Físicas de Artesanos y Botín/Reaparición en la Llanura Salvaje):**
   * **Mapa Cartográfico Interactivo (`[M]`) + Minimapa en Vivo (`scripts/ui/ValleyMapUI.gd`):** Minimapa en esquina superior derecha y Mapa Completo con `[M]` mostrando las 4 regiones, caminos, los 10 edificios, posición del jugador, aldeanos en tiempo real (con inspector de actividad y humor al pasar el ratón), fauna activa del bosque y hostiles de la Llanura.
   * **Expediciones Físicas Matutinas (`06:30–09:30 AM` en `scripts/enemies/VillageNPC.gd`):** Los 5 maestros artesanos caminan físicamente por los senderos cada mañana hacia el Bosque, el Lago o la Cantera para recolectar su materia prima (+2 de stock diario) antes de regresar a abrir sus tiendas.
   * **Botín Único, Cocina y Reaparición en la Llanura Salvaje (`scripts/enemies/DummyEnemy.gd`, `scripts/systems/SimpleInventory.gd`, `scripts/obstacles/CampSite.gd`):** Añadidos `frog_legs` (*Ancas de Rana Crudas*), `fried_frog_legs` (*Ancas de Rana al Ajillo*, `+50 HP, +70 STM, +65 Hambre`) y `bandit_scrap` (*Reliquia y Chatarra de Bandido*) con sus iconos `16×16`, venta en tiendas y reaparición automática de ranas y bandidos cada 2 días.
   * **Persistencia Total en `[F5]` / `[F9]` (`scripts/systems/GameManager.gd`):** Guardado y restauración completa de Huerto (`FarmPlot`), Gallinero (`ChickenCoop`), Ecosistema del Bosque (`EcosystemManager` + `WildAnimal`) y Enemigos de la Llanura (`plains_hostiles`).
10. **Fase 7 — Expansión Integral en 10 Bloques + Rediseño Visual y Físico de Edificios:**
    * **Paredes Sólidas con Colisión (`StaticBody2D`) y Suelos Texturizados en los 12 Edificios (`scripts/systems/VillageManager.gd`):** Todos los edificios tienen suelos en mosaico (`floor_wood_planks.png`, `floor_stone_forge.png`, `floor_hospital_tile.png`), muros texturizados (`wall_timber_h/v.png`, `wall_stone_h/v.png`), colisión física real en capa 1 con puertas abiertas de `40–50 px`, navegación de NPCs por umbrales (`get_navigation_waypoint`) y mobiliario de `Cute_Fantasy`.
    * **Paso 1 — 🏥 Hospital de Urgencias, ⚰️ Morgue Forense y Estado "Agonizando":** Edificio en `Vector2(745, 148)` con el **Dr. Valen**, 2 camas de urgencias y 3 mesas de autopsia. Al caer a `0 HP`, los NPCs entran en estado **`is_downed = true` (`🩸 ¡AGONIZANDO!`)** pudiendo ser salvados con `[E]` o `surgical_kit` (`+25 Oro`, `+40 Afinidad Familiar`). Si mueren, su cuerpo aparece en una mesa de la Morgue con dictamen forense inspeccionable (`[E]`).
    * **Paso 2 — 🚓 Comisaría, 🔒 Cárcel y Testigos Realistas (*"Me vieron entrar a la casa"*):** Edificio en `Vector2(915, 148)` con **Comisario Vane**, **Guardia Rodric** y 2 celdas con barrotes (`jail_bars_h/v.png`). Si entras a un edificio sin Sigilo `[C]` y un vecino consciente te ve, se registra en `sighting_log`; si luego hay un asesinato ahí, la Morgue y la Policía cruzan el registro y emiten orden de arresto (`wanted_level`, `bounty_gold`).
    * **Paso 3 — 🔓 Sigilo Doméstico y Cofres en las Casas (`house_chests`):** 10 cofres privados en casas y tiendas para forzar en sigilo `[C]`.
    * **Paso 4 — 💬 Reputación por Familias (`modify_family_reputation`):** Descuento de `-20%` con Familias Aliadas (`>= 45`) y bloqueo comercial con Familias Agraviadas (`<= -35`, reconciliable pagando compensación).
    * **Paso 5 — 📋 Tablón de Encargos en la Plaza (`Vector2(465, 24)`):** 3 contratos diarios (Gremios, Hospital y Cazarrecompensas).
    * **Paso 6 — 🏡 Construcción de Casa Propia (`CampSite.gd`):** Mejora `Nv.1 Tienda` $\rightarrow$ `Nv.2 Cabaña de Madera` $\rightarrow$ `Nv.3 Casa de Piedra con Cofre Personal` con paredes sólidas y suelo texturizado.
    * **Paso 7 — 🌦️ Clima Dinámico (`WorldClock.gd`, `[F7]`):** `☀️ Despejado`, `🌧️ Lluvia` (riega el huerto y reduce `-35%` ruido de pasos) y `🌫️ Niebla` (`-35%` visión de testigos y fauna).
    * **Paso 8 — 🦴 Despiece Anatómico y Alquimia (`SimpleInventory.gd`, `WildAnimal.gd`):** `bones`, `antlers`, `sinew_viscera`, `animal_fat`, `sleeping_draught` (Somnífero Nocturno que duerme NPCs 40s), `speed_tonic` y `surgical_kit`.
    * **Paso 9 — 🧬 Crianza Selectiva y Genética (`Nv.1 -> Nv.3`):** Herencia genética en animales del bosque y gallinas del corral, produciendo **🥚✨ Huevos Dorados (`golden_egg`)** en Genética Nv.3.
    * **Paso 10 — ⚡ Tecnología Anacrónica (`CampSite.gd`, `VillageManager.gd`):** **Generador Eléctrico Antiguo (`ancient_generator.png`)**, **Aspersor Automático (`auto_sprinkler.png`)** en el centro del huerto 3x3 y **6 Farolas Eléctricas (`lamp-post1.png`)** en las calles del pueblo.

* **28/10/2026 — Correcciones de IA Policial (Negociación -> Pistola y Porra + Captura a 0 HP), Cadáveres Persistentes con Descomposición de Días, Oclusión de Visión por Paredes y Navegación de Puertas:**
  * **Daño Policial, Negociación Previa, Pistola/Porra y Arresto a 0 HP (`VillageNPC.gd`, `VillageManager.gd`, `Player.gd`):**
    * Cuando `wanted_level > 0` y el jugador no se está resistiendo (`not is_resisting_arrest`), el **Comisario Vane** y el **Guardia Rodric** primero se acercan e intentan **negociar** abriendo el modal policial (`[1] Entregarse`, `[2] Pagar fianza`, `[3] Resistirse`).
    * Si el jugador elige `[3] Resistirse` (o ataca a la policía), se activa `is_resisting_arrest = true` y los agentes persiguen al jugador atacando con **Pistola Reglamentaria a distancia (`36 px < dist <= 195 px`, `16 HP` de daño + traza de disparo `Line2D`)** y **Porra Policial cuerpo a cuerpo (`dist <= 36 px`, `14 HP` de daño + aturdimiento)**.
    * Si la salud del jugador cae a `0 HP` frente a la policía, `Player._on_died()` intercepta la muerte, restaura el `50%` de vida y llama a `capture_knocked_out_player_to_jail()`, encerrando al jugador vivo en la **Celda de la Comisaría (`Vector2(886, 172)`)**.
  * **Cadáveres Persistentes en el Lugar, Descomposición de Días y Traslado Físico Natural a la Morgue (`VillageNPC.gd`, `VillageManager.gd`):**
    * Al morir un NPC (`_confirm_true_death()`), el cuerpo **permanece físicamente en el suelo donde murió (`corpse_on_ground = true`)** y ya no se teletransporta al instante a la Morgue.
    * Si nadie entra en la casa o nadie tiene línea de visión hacia el cuerpo, el cadáver permanece allí durante horas o días enteros pudriéndose (`corpse_rot_hours`, cambiando a tono verdoso y mostrando `"🦠🪰 PUDRIÉNDOSE EN EL LUGAR (X días, Yh)"`).
    * Solo cuando otro NPC consciente pasa a `<= 105 px` con **línea de visión directa (`has_line_of_sight`)** durante su rutina natural, descubre el cadáver (`corpse_discovered = true`) y el **Dr. Valen** (o un guardia/vecino) camina físicamente hasta el cuerpo, lo recoge (`corpse_being_carried = true`), lo transporta por las calles hasta la **Morgue del Hospital (`Vector2(745, 174)`)** y registra la autopsia forense.
  * **Oclusión Estricta de Visión por Paredes (`has_line_of_sight` en `VillageManager.gd`):**
    * Todas las paredes sólidas opacas (`_wall_occluder_rects`) bloquean la línea de visión (`has_line_of_sight(from_pos, to_pos)`), impidiendo que guardias o testigos detecten al jugador, crímenes o cadáveres a través de los muros.
  * **Navegación por Pasillos de Puertas y Separación entre NPCs (`get_navigation_waypoint` y `_move_towards_point`):**
    * Corregido el orden de evaluación de edificios (salir primero del edificio actual antes de enrutar al edificio destino), añadido pasillo interior/exterior con carril por NPC (`lane_shift`), soporte para el tabique interior del Hospital (`Urgencias <-> Morgue`), separación suave entre NPCs (`sep_vec`) y desatasco lateral automático (`_stuck_timer`).

* **28/10/2026 — Sistema de Puertas Físicas, Cerrojos (`[B]`), Cerraduras Nocturnas según Nivel de Seguridad/Desconfianza de la Aldea y Ventanas Forzables (`VillageManager.gd`):**
  * **Puertas Físicas Interactivas (`building_doors`):** Todos los edificios cuentan ahora con puerta física (`StaticBody2D` + texturas `door_wood_closed.png`, `door_wood_locked.png`, `door_wood_open.png`).
    * **`[E]` Abrir / Cerrar Puerta:** Al cerrar una puerta, se activa su colisión y su `occluder_rect` bloquea `has_line_of_sight`, impidiendo que los guardias o vecinos en la calle vean lo que ocurre dentro de la casa.
    * **`[B]` Bloquear / Echar Cerrojo (`toggle_bar_door_by_player`):** Permite trancar cualquier puerta desde dentro o fuera (`locked_by_player = true`), impidiendo la entrada de NPCs y bloqueando la visión (si la policía te persigue, tarda `2.2s` en derribar una puerta trancada).
    * **Cierre con Llave según Hora y Nivel de Seguridad/Desconfianza (`get_village_security_level()`, `_apply_hourly_door_security_schedule`):** A medida que suben los crímenes, cadáveres hallados en la Morgue o allanamientos (`recent_breakins_count`), la aldea pasa de `🟢 Tranquila` a `🟡 Desconfiada` y `🔴 Alerta Máxima`: las tiendas echan la llave fuera de horario comercial y las casas cierran con llave más temprano por la noche (o incluso de día si la familia desconfía del jugador).
    * **Forzado de Cerraduras (`[E]` en puerta con llave):** Permite forzar la cerradura (en sigilo `[C]` sin hacer ruido o de pie arriesgándose a ser visto).
    * **Paso Fluido de NPCs con Llave (`npc_pass_timer`):** Los aldeanos abren y cierran automáticamente las puertas al cruzarlas en sus rutinas sin quedarse atascados.
  * **Ventanas Forzables en Fachadas (`building_windows`, `window_glass_open.png` / `window_shutter_closed.png`):** Cada edificio tiene una ventana lateral por la que el jugador puede colarse o escapar con `[E]` (forzando el postigo si está cerrada de noche o por alta desconfianza).
  * **Interacción Activa de NPCs con Puertas y Navegación sin Atascos (`npc_interact_with_door`, `get_navigation_waypoint`, `_route_internal_building_partitions`, `_avoid_outdoor_buildings`):**
    - Los NPCs llaman activamente a `npc_interact_with_door` al acercarse a `<= 24 px` de cualquier puerta cerrada: abren visualmente la hoja de la puerta (`spr_open.visible = true`, burbuja flotante `"🚪"` / `"🔑🚪"`), cruzan el umbral y la puerta vuelve a cerrarse automáticamente tras `1.45s`.
    - Si el jugador tranca una puerta con cerrojo `[B]` (`locked_by_player = true`), los aldeanos se detienen frente a ella tocando la puerta (`"🚪✊ ¡Puerta trancada!"`), mientras que la Policía en persecución la derriba tras `2.0s` (`"🚓💥 ¡Puerta derribada!"`).
    - Se corrigió el enrutamiento de tabiques internos (Gran Posada, Botica-Vivienda Mixta, Hospital/Morgue y Comisaría) y la fusión de manzanas contiguas (`merged_rect`) para que ningún NPC intente atravesar muros traseros ni rendijas entre edificios.
    - Las puertas permanecen cerradas por defecto (`is_open = false`) y `npc_interact_with_door` verifica `crossing_this_door` (`npc_inside != dest_inside`) para que nunca se queden abiertas cuando un NPC está trabajando, comiendo o deambulando en el centro de la habitación.
  * **Temporizador de Recontratación de Policía y Médicos (`_update_authority_rehiring`, `_spawn_authority_replacement`):** Si el jugador mata al Médico/Forense (`DOCTOR`), al Comisario (`SHERIFF`) o al Guardia de Patrulla (`GUARD`), queda una ventana táctica de `75s` (acelerada `+25s` por cada hora de juego) tras la cual el Gremio Médico o la Prefectura contrata un nuevo profesional (`Dra. Valeria`, `Dr. Silvano`, `Comisario Thorne`, `Guardia Kaelen`, etc.) que llega caminando por el camino principal hacia su puesto.


---

## Actualización 2026-10-28 (Parte 5): Escolta Física a Prisión, Avance Orgánico del Tiempo, Puertas con Intención Estricta, Reporte Físico de Cadáveres y Colisión Blanda Jugador-NPC

### Referencias de Diseño en Juegos Existentes y Soluciones Aplicadas
1. **Escolta Física Policial + Estancia Obligatoria en Celda antes del Camastro** (*Kenshi* / *The Escapists* / *Red Dead Redemption 2*):
   - Al entregarse o caer a `0 HP` ante la policía, ya no hay teletransporte instantáneo a la celda: se activa `start_police_escort_to_jail` (`player_being_escorted_to_jail = true`), donde el agente esposa al jugador y camina físicamente con él por las calles y puertas de la Comisaría hasta encerrarlo en `_jail_cell_pos` (`complete_police_escort_to_jail`).
   - Al entrar en la celda se inicia un temporizador obligatorio de reclusión (`JAIL_MANDATORY_STAY_SECONDS = 20.0s`, `jail_mandatory_stay_timer`) antes de que el jugador pueda decidir acostarse en el camastro de la prisión (`[1] / [E]`) para cumplir la condena.
2. **Paso del Tiempo Orgánico en el Mundo sin Time-Skips Artificiales** (*RimWorld* / *Kenshi* / *The Sims*):
   - En `WorldClock.gd`, al dormir en el camastro de la prisión, en la cama de la posada o al usar `[T]`, se reemplazó el salto instantáneo de reloj por `start_organic_fast_forward` (`Engine.time_scale = 14.0`). Así todos los NPCs (leñadores, mineros, huéspedes) y los animales de la granja caminan físicamente, regresan del bosque, comen en sus comederos y cumplen sus rutinas de forma orgánica hasta las `06:00 AM` (pudiendo cancelarse con `[ESC]` fuera de prisión).
3. **Intención Estricta al Abrir Puertas (`npc_interact_with_door` y `clamp_point_outside_buildings`)**:
   - Se eliminó la apertura por proximidad exterior en `VillageManager.npc_interact_with_door`, exigiendo `target_pos != Vector2.INF` y estrictamente `npc_inside != dest_inside` respecto al `building_rect` de ese edificio, además de `clamp_point_outside_buildings` para que los paseos aleatorios de los independientes (`UNEMPLOYED`) y guardias nunca caigan dentro de casas vecinas ni abran puertas al pasar por la acera.
4. **Médico sin Telepatía + Cadena Física de Reporte de Testigos y Reporte Manual de Cadáveres (`[E]`)** (*Hitman* / *Streets of Rogue* / *Among Us*):
   - Se corrigió `VillageNPC._find_downed_npc()` para que el Dr. Valen solo atienda a un NPC agonizando si lo ve directamente con línea de visión (`<= 115 px` + `has_line_of_sight`) o si ya está dentro del Hospital (`Rect2(704, 110, 82, 80)`).
   - En `_process_corpse_state` y `_process_witness_corpse_reporting`, cuando un vecino descubre un cadáver (`corpse_discovered = true`), el médico sigue sin saberlo (`corpse_reported = false`) hasta que ese testigo corre físicamente a avisar a una autoridad viva (`<= 34 px`) o hasta que el propio **Jugador** presiona `[E]` sobre el cadáver (`report_corpse_by_player` / `try_priority_door_or_corpse_interaction`).
5. **Solución de Colisión Isométrica Jugador-NPC en Puertas y Umbrales** (*Stardew Valley* / *RimWorld* / *Baldur's Gate 3*):
   - Se aplicó colisión física blanda en NPCs pacíficos (`body_col.disabled = not is_hostile`, manteniendo activas `Hurtbox` e `InteractArea`), empuje lateral suave al paso del jugador (`_apply_player_and_doorway_yield`), despeje automático de marcos de puerta (`get_doorway_clearance_nudge`) y prioridad de interacción `[E]` sobre puertas cerradas (`try_priority_door_or_corpse_interaction` en `Player.gd`).


---

## Actualización 2026-10-28 (Parte 6): Teclas Separadas (`[E]` vs `[F]`), Salida Natural de Comisaría, Casino con Probabilidades Reales, Recolección Física con Equilibrio Ecológico ($N_{\text{min}}$), Jabalíes Salvajes y Tells Sutiles de Póker

1. **Separación de Teclas: `[E]` Abrir/Cerrar Puerta Normal vs. `[F]` Forzar Cerradura (`project.godot`, `Player.gd`, `VillageManager.gd`):**
   - Se añadió la acción de entrada `Lockpick` asignada a la tecla **`[F]`** (`KEY_F` = `70`).
   - Pulsar **`[E]`** (`Interact`) sobre una puerta desbloqueada la abre o cierra normalmente; si está cerrada con llave, muestra un aviso indicando que requiere **`[F]`** para forzar la cerradura (`try_lockpick_interaction`).
2. **Salida Física Natural de la Comisaría tras Cumplir Condena o Pagar Fianza (`VillageManager.gd`):**
   - Se eliminó el teletransporte artificial a la puerta exterior al salir de prisión (`_on_police_serve_sentence` y `_on_police_pay_fine`).
   - Ahora se abre físicamente la reja de barrotes de la celda (`set_jail_cell_gate_locked(false)`) y se desbloquea la puerta principal de la Comisaría para que el jugador salga caminando por su propio pie.
3. **Casino Realista con Reglas y Probabilidades Reales (`scripts/ui/TavernGamesUI.gd`):**
   - **🎡 Ruleta Europea de 37 Casillas (`0` a `36`, ventaja de la casa exacta del $2.70\%$):** Soporte completo de apuestas internas y externas con sus pagos reales: **Pleno (`35:1`)**, **Caballo / Split (`17:1`)**, **Calle / Street (`11:1`)**, **Esquina / Corner (`8:1`)**, **Seisena / Six Line (`5:1`)**, **Docenas y Columnas (`2:1`)** y **Sencillas (`1:1`: Rojo/Negro, Par/Impar, `1–18`/`19–36`)**.
   - **🃏 Blackjack 21 de Casino (`S17`, pago `3:2`):** Baraja estándar barajada sin sesgos artificiales, Blackjack natural pagado `3:2`, opción de **Doblar (`Double Down`)** y crupier obligado a pedir hasta `16` y plantarse en todo `17` (`S17`).
   - **♠️ Póker Texas Hold'em Real (Mejor mano de 5 entre 7 cartas):** Evaluador combinatorio exacto de las $\binom{7}{5} = 21$ combinaciones de 5 cartas con desempate por *kickers*.
4. **Recolección y Caza Física Matutina de los Artesanos + Equilibrio Ecológico ($N_{\text{min}}$) (`EcosystemManager.gd`, `VillageNPC.gd`):**
   - Durante la expedición matutina (`06:30–09:30 AM`), los maestros artesanos (*Bram*, *Thoran*, *Elena*, *Garrick*) caminan hasta un nodo o presa real del bosque, ejecutan golpes físicos reales (`hit_by_villager(1)`) hasta talar el árbol, picar la veta, recolectar la planta o abatir y desollar la presa (`harvest_carcass()`), dejando 1 recurso menos en el bosque hasta su regeneración natural.
   - **Umbrales Matemáticos de Conservación ($N_{\text{min}}$):** `EcosystemManager` calcula la población viva y bloquea la extracción aldeana si el recurso está en o por debajo del umbral de equilibrio (`MIN_SAFE_TREES = 16`, `MIN_SAFE_ROCKS = 5`, `MIN_SAFE_PLANTS = 16`, `MIN_SAFE_RABBITS = 5`, `MIN_SAFE_DEER = 3`, `MIN_SAFE_FOXES = 2`, `MIN_SAFE_BOARS = 2`), evitando la sobreexplotación del bosque.
5. **🐗 Jabalíes Salvajes en el Bosque (`SpeciesType.BOAR` en `WildAnimal.gd` y `EcosystemManager.gd`):**
   - Nueva especie herbívora pacífica por defecto (3 piaras en el Bosque Profundo con sprite `assests/world/harvest/wild_boar.png`).
   - Si el jugador los ataca, se vuelven agresivos (`CHARGE_ATTACK`), embisten a alta velocidad (`122 px/s`, daño + empuje + aturdimiento) y **aguantan siempre un mínimo de 3 golpes** (`min_hits_required = 3`, `85 HP`) antes de caer abatidos.
6. **Tells Sutiles de Personalidad en el Póker (`_generate_subtle_poker_tell` en `TavernGamesUI.gd`):**
   - Cada aldeano tiene un arquetipo psicológico determinista (`STOIC`, `HABITUAL_TIC`, `VERBOSE`, `CAUTIOUS`) que genera micro-gestos sutiles en la mesa de póker sin revelar de forma obvia si lleva farol o mano fuerte.

---

## Actualización 2026-10-28 (Parte 7): Ataques Sigilosos a Civiles (No Letal y Letal) y Pacificación de Civiles Durante Escolta Policial y en Celda

1. **Ataques Sigilosos por la Espalda a Civiles (`VillageNPC.gd`, `PlayerCombatController.gd`):**
   - Al ir en **Sigilo (`[C]`)** y colocarse detrás de un civil (o junto a un NPC dormido/sedado), aparece el indicador contextual:
     `🕵️ SIGILO POR LA ESPALDA — [E / Q: 💤 Aturdir (No Letal) | Clic Izq. / V: 🗡️ Matar (Letal)]`.
   - **Opción No Letal (`[E]` o `[Q]` $\rightarrow$ `stealth_knockout`):** Deja inconsciente al civil durante **25 segundos** sin matarlo ni alertar a la policía (salvo que un tercer testigo consciente tenga línea de visión directa).
   - **Opción Letal (`[Clic Izq.]` o `[V]` $\rightarrow$ `stealth_assassinate`):** Ejecución silenciosa instantánea (`_confirm_true_death()`) que deja el cadáver persistente en el suelo sin entrar en el estado ruidoso de agonía.
2. **Pacificación Inmediata de Civiles al Intervenir la Policía (`VillageManager.gd`, `VillageNPC.gd`, `Player.gd`):**
   - `VillageManager.clear_police_hostility()` ahora limpia `is_hostile = false`, `_civilian_hostile_timer = 0.0`, `velocity = Vector2.ZERO` y retira del grupo `"enemies"` a **todos** los `VillageNPC` (incluidos los civiles) al iniciar la negociación policial, durante la escolta física a la comisaría y al entrar en la celda.
   - `VillageNPC._process_hostile_combat()` detiene inmediatamente cualquier persecución si `player_being_escorted_to_jail` o `player_in_jail` están activos o si el civil llega al perímetro de la Comisaría (`Rect2(832, 92, 166, 108)`), y `Player.take_damage()` protege al jugador de cualquier daño mientras está esposado o dentro de la celda.

---

## Actualización 2026-10-29 (Fase 8): Economía Dinámica de Oferta y Demanda, Consumo Real de Alimentos, Sabotaje Industrial y Propiedad Híbrida de Negocios

1. **Precios Dinámicos de Oferta y Demanda (`get_trade_market_multiplier`, `_get_dynamic_sell_price`, `_get_dynamic_buy_price` en `VillageManager.gd` y `VillageNPC.gd`):**
   - Cada uno de los 5 gremios (**Herrería**, **Carnicería**, **Carpintería**, **Pescadería**, **Botica**) y la **Posada** calcula su multiplicador de precios en vivo según el inventario real del mostrador (`get_trade_total_stock`) y el estado operativo del taller:
     - `0.80x` (`📉 Excedente -20%`) con $\ge 12$ unidades en stock.
     - `1.00x` (`⚖️ Estable 100%`) con $4\text{–}11$ unidades en stock.
     - `1.55x` (`📈 Escasez +55%`) con $\le 3$ unidades en stock.
     - `2.25x` (`🔥 Crisis +125%`) cuando el stock llega a $0$, el maestro artesano ha muerto/caído o el taller está saboteado.
2. **Consumo Real de Comida del Pueblo (`consume_village_meal_for_npc` en `VillageManager.gd` y `VillageNPC.gd`):**
   - Cuando cualquier aldeano llega a su mesa de comedor o a la Posada para comer (`ActivityState.EATING`), consume `1` unidad real de comida de las tiendas de la aldea (`FISHMONGER`, `BUTCHER`, `HERBALIST` o `INNKEEPER`).
   - Si el jugador es **Socio (`PARTNER`)** o **Dueño Único (`SOLE_OWNER`)** de esa tienda, cada comida comprada por un vecino deposita Oro real en la **Caja Registradora (`vault_gold`)**.
3. **Sabotaje Industrial con `[F]` (`sabotage_shop_stall` en `VillageManager.gd`):**
   - Acercarse al mostrador de cualquiera de los 5 talleres y pulsar **`[F]`** (o el botón `[4]` del panel de gestión) sabotea la maquinaria durante **2 días** (`sabotaged_days = 2`), bloquea la expedición matutina del artesano, reduce el stock un `60%`, entrega `1` material saqueado, dispara los precios del gremio a **`2.25x`** y permite comprar el negocio en **Liquidación por `65 Oro`**.
   - Respeta el sistema de **Sigilo (`[C]`)** y línea de visión (`_find_conscious_witness_near`).
4. **Propiedad Híbrida de Negocios, Abastecimiento de Mostrador y Contratación (`open_business_management_ui` en `VillageManager.gd`):**
   - Accesible pulsando **`[E]`** frente a cualquier mostrador comercial o mediante la opción `"📜 Negocio, Escritura de Propiedad y Caja Registradora"` al hablar con el artesano:
     - **`[1]` Comprar Escritura de Socio (`110 Oro`, o `85 Oro` si eres Aliado Familiar) / Comprar en Liquidación (`65 Oro` si está vacante, sin stock o saboteado) / Recaudar Caja Registradora (`vault_gold`)**.
     - **`[2]` Abastecer Mostrador con tu Mochila:** Deposita productos de tu inventario en el mostrador para su venta automática a los vecinos (o cobro inmediato a precio de mercado).
     - **`[3]` Contratar Nuevo Encargado (`-30 Oro`):** Si el local quedó vacante tras la muerte del maestro, permite contratar a un nuevo encargado desde el mostrador.
     - **`[4]` Sabotear Taller (`[F]`) o Reparar Maquinaria (`-1 Madera` o `-12 Oro`)**.
5. **Persistencia Completa y Mapa Cartográfico (`GameManager.gd`, `ValleyMapUI.gd`):**
   - `GameManager.gd` guarda y carga `vm.get_economy_save_dict()` / `vm.load_economy_save_dict(...)`.
   - `ValleyMapUI.gd` muestra en el censo los `🐗 Jabalíes` y permite inspeccionar al pasar el ratón sobre cualquiera de las 5 tiendas su estado de propiedad, multiplicador de Oferta/Demanda, stock total y oro acumulado en la Caja Registradora.
6. **Corrección de Horario de Puertas con Alerta Baja (`_on_hour_passed` y `_apply_hourly_door_security_schedule` en `VillageManager.gd`):**
   - Corregido el orden de argumentos de `_on_hour_passed(_day: int, new_hour: int)` respecto a `WorldClock.hour_passed(day, hour)`.
   - Cuando `sec_lvl == 0` (**🟢 Tranquila**) y la familia no está enemistada (`fam_aff >= 0`), las puertas de las casas (`house_`) y viviendas mixtas (`mixed_`) permanecen cerradas pero **sin llave** (`is_locked = false`), abriéndose normalmente con **`[E]`**.
7. **Sprites y Retratos Únicos en `64×64` px + Historias Personales Estructuradas para los 17 Aldeanos (`assests/world/village/npcs_64/`, `VillageNPC.gd`, `scenes/dialogue_manager.gd`, `TavernGamesUI.gd`):**
   - Generados **18 sprites de cuerpo completo (`64×64`)** y **18 retratos faciales detallados (`64×64`)** con rasgos únicos para cada habitante (*Thoran*, *Kael*, *Garrick*, *Lina*, *Bram*, *Mila*, *Marlo*, *Nora*, *Elena*, *Tomás*, *Marta*, *Dr. Valen*, *Comisario Vane*, *Guardia Rodric*, *Aldric*, *Sora*, *Darío* y *Guía*).
   - `dialogue_manager.gd` muestra el retrato `64×64` enmarcado a la izquierda junto al contexto narrativo (`character_tagline`), y todos los NPCs incluyen las ramas de conversación **`📖 Conocer la historia personal y el pasado`** (`character_lore`) y **`🔍 Preguntar por lo que calla o ha observado en el valle`** (`character_secret`).

---

## Actualización 2026-10-30 (Fase 9 y 10): Animaciones para los 21 NPCs, Crafteo en Tiempo Real con Compras entre Vecinos, Ítems de las Tierras Reales e IA Deductiva del Inquisidor Real Alistair

1. **Mascotas y Animales Pequeños sin Body-Block (`scripts/enemies/DomesticPet.gd`, `scripts/obstacles/ChickenCoop.gd`, `scripts/enemies/WildAnimal.gd`):**
   - Eliminadas las colisiones sólidas (`collision_layer = 0`, `collision_mask = 0`) en perros, gatos, gallinas y animales salvajes pacíficos para que el jugador y los NPCs puedan atravesarlos con fluidez sin quedar bloqueados en puertas o pasillos.
   - Añadido reflejo suave de *Auto-Step-Aside* en `DomesticPet.gd` y `ChickenCoop.gd` para que las mascotas y gallinas se aparten ligeramente cuando el jugador pasa junto a ellas.
2. **Skins Exclusivas, Retratos `64×64` y Hojas de Animación (`320×64`, 5 frames) para los 21 NPCs (`assests/world/village/npcs_64/`, `scripts/enemies/VillageNPC.gd`):**
   - Creados sprites únicos, retratos `64×64` y hojas de animación de 5 columnas (`Idle 0`, `Idle 1`, `Walk A`, `Walk B`, `Action / Trabajo / Interrogatorio`) para **todos los 21 NPCs** del valle, incluyendo a los mercaderes viajeros **`Maese Casimir`** y **`Valeria la Tratante`** y al **`Inquisidor Real Alistair`**.
   - Motor de animación por frames (`_update_visual_animation` en `VillageNPC.gd`) sincronizado con movimiento, trabajo de taller, conversación e interrogatorios.
3. **Crafteo Artesanal en Tiempo Real con Barra de Progreso y Compras Físicas entre Tiendas Vecinas (`scripts/enemies/VillageNPC.gd`, `scripts/systems/VillageManager.gd`):**
   - Durante su horario laboral en el taller (`WORK`), los 5 maestros artesanos (*Thoran*, *Bram*, *Garrick*, *Marlo*, *Elena*) muestran una barra de progreso visual sobre su cabeza (`🔨 Fabricando ... XX%`) y al llegar al `100%` suman `+1` unidad real del producto refinado al stock de su tienda (`shop_stock`).
   - Cuando un artesano necesita insumos de otro gremio (ej. *Thoran* necesita `wood` de la Carpintería para forjar espadas/picos, o *Bram* necesita `iron_ore` de la Herrería para muebles reforzados), sale caminando físicamente a la tienda vecina (`_start_neighbor_supply_run`), compra el insumo pagando oro real a la caja del vecino (`npc_buy_material_from_shop`) y regresa a su taller para continuar fabricando.
4. **Ítems Exclusivos de las Tierras Reales y Persistencia Completa (`SimpleInventory.gd`, `PlayerCombatController.gd`, `Player.gd`, `VillageManager.gd`, `VillageNPC.gd`):**
   - **`royal_paralytic_venom` (Veneno Paralizante Real):** Imbuye tu arma por 3 golpes, aplicando sedación profunda (`18 s`) en combate o sigilo sin matar a la víctima.
   - **`master_lockpick` (Ganzúa Maestra de Corte):** Abre silenciosamente puertas y cofres cerrados sin romperse (`100%` de éxito).
   - **`ranger_camo_cloak` (Capa de Camuflaje Real):** Reduce un `35%` el radio de detección visual de todos los testigos y guardias al ir en sigilo (`get_stealth_detection_multiplier()`).
   - **`steel_bear_trap` (Cepo de Acero Desplegable):** Coloca una trampa física en el suelo (`deploy_steel_bear_trap`) que inflige `35` de daño de corte, sangrado y aturdimiento al primer animal salvaje o enemigo hostil que la pise.
   - Guardado y carga completos (`get_economy_save_dict` / `load_economy_save_dict`) del estado de los mercaderes viajeros, el embargo comercial (`20–30 días`), la investigación activa del Inquisidor Real Alistair, el historial de arrestos/órdenes de captura y las mascotas domésticas.
5. **Atención Presencial de los NPCs al Hablar con el Jugador o con el Inquisidor (`VillageNPC.gd`):**
   - Cuando el jugador abre diálogo con cualquier NPC (`dialogue_manager.active` y `current_speaker == self`), el NPC se detiene inmediatamente (`velocity = Vector2.ZERO`), pausa su barra de crafteo, gira hacia el jugador y mantiene su animación de conversación hasta que termina la charla.
   - Cuando el `Inquisidor Real Alistair` interroga a un aldeano (`hold_for_interview`), el aldeano también detiene su caminata o trabajo y atiende cara a cara al Inquisidor.
6. **IA Deductiva Multidiaria del Inquisidor Real Alistair Integrada con la Comisaría y la Morgue (`VillageManager.gd`):**
   - **Conexión con el Comisario Vane y la Morgue Forense:** Registro persistente de arrestos y órdenes de captura (`player_arrests_count`, `player_murder_warrants_count`), notificación directa al expediente de Alistair (`_notify_inquisitor_of_police_crime`) y cruce con el Libro de Autopsias (`_cross_check_morgue_and_police_records`).
   - **Distinción entre Testigos Oculares y Sospechosos:** Los aldeanos que presenciaron el crimen o vieron al jugador junto al mercader (`saw_player_near` / `murder_witness_name`) quedan registrados como **Testigos Oculares (`0%` sospecha propia)** en vez de sospechosos, y al ser interrogados declaran contra el jugador (`+38%` sospecha al Jugador). Los aldeanos a `> 360 px` quedan descartados por distancia física (`0%`).
   - **Interrogatorio al Jugador (`INITIAL_PLAYER_INTERVIEW`) y Ritmo de `6+` Entrevistas Físicas por Día:** Tras revisar la escena del crimen y la Morgue en el Día 1 (o de inmediato si el jugador cae preso en la celda de la Comisaría), Alistair acude físicamente a interrogar al jugador. Después interroga cara a cara a todos los habitantes a un ritmo de **`6+` personas por día** (`07:00–20:00`) y, en cuanto termina la lista, pasa directamente a `PLAYER_CHECK` y emite su `VERDICT` sin alargar artificialmente el caso.
7. **Auditoría Integral del Proyecto y Corrección de Errores Críticos, de Guardado/Carga y de Lógica (`CampSite.gd`, `DomesticPet.gd`, `WildAnimal.gd`, `EnemyAI.gd`, `WorldClock.gd`, `GameManager.gd`, `VillageManager.gd`, `VillageNPC.gd`, `TavernGamesUI.gd`, `ui_root.gd`, `npc.gd`):**
   - **Serialización JSON de `crime_pos` (`VillageManager.gd`):** Guardado como `crime_pos_x` / `crime_pos_y` y leído mediante `_get_investigation_crime_pos()` para evitar el *crash* de tipos (`String` vs `Vector2`) tras cargar partida con `JSON.parse_string`.
   - **Último vecino en `interview_queue` (`VillageManager.gd`):** Corregida la condición `queue.is_empty() and cur_target_name == ""` para que el último aldeano de la cola (`18/18`) sea interrogado por completo antes de pasar a `PLAYER_CHECK`.
   - **Campamento del Jugador (`CampSite.gd`):** Reemplazadas las referencias obsoletas `"gold_coin"` y `"wood_bundle"` por `inv.gold` / `inv.add_gold(...)` y `"wood"`, y ajustado `SPRINKLER_OFFSET` al centro real del huerto 3x3 (`Vector2(139, 99)`).
   - **Perro Guardián (`DomesticPet.gd`):** Corregido el detector de zorros (`sp_val == 2`, `is_alive_in_ecosystem()`, `_start_flee_from`) para que ahuyente zorros reales cerca del gallinero.
   - **Compras entre Artesanos Vecinos (`VillageNPC.gd`):** Verificación de stock real y ausencia de sabotaje antes de iniciar el recado, cancelación limpia si el camino está bloqueado tras `24 s` (sin compras a distancia) y refresco real del mostrador (`_refresh_shop_stall_visual`).
   - **Integridad de Guardado/Carga (`GameManager.gd`, `WorldClock.gd`, `VillageNPC.gd`, `VillageManager.gd`):** Restauración limpia sin *fast-forward* residual (`stop_organic_fast_forward(false)`), persistencia de `player_in_jail`, `sighting_log` y claves enteras de `completed_contracts_today`, reconstrucción de tumbas (`_rebuild_cemetery_graves_from_save`), restauración de visibilidad (`sprite.visible = true`) de NPCs revividos al cargar y reconciliación de gremios (`reconcile_npc_registries_after_load`).
8. **Segunda Auditoría Profunda (Línea por Línea) y Corrección de Sistemas Base y Nuevos:**
   - **Deduplicación de Impactos y Flechas (`PlayerCombatController.gd`, `ArrowProjectile.gd`):** Eliminado el daño doble sobre `WildAnimal` (que recibía impacto tanto por `Hurtbox` como por `body_entered`) mediante `_swing_hit_targets` por swing y bloqueo `_is_grounded` inmediato en `ArrowProjectile`; añadido soporte para que las flechas dañen objetos `DestructibleObject`.
   - **Cofre Personal de Casa Nv.3 y Descanso Nocturno (`Player.gd`, `CampSite.gd`, `SurvivalComponent.gd`):** Soporte para `best_area.get_parent().get_parent().interact(self)` al interactuar con el Cofre Personal en `house_root`, y pausa del drenaje de `SurvivalComponent` durante `WorldClock.is_fast_forwarding` para que el jugador no pierda Sueño ni Hambre mientras duerme hasta el amanecer.
   - **Mapa del Valle (`[M]`), Cruceta y Modales (`ValleyMapUI.gd`, `Crosshair2D.gd`, `ui_root.gd`, `World.gd`, `dialogue_manager.gd`):** Corregidos los `TradeRole` de los 5 talleres en `ValleyMapUI.gd` (`BLACKSMITH`, `BUTCHER`, `CARPENTER`, `FISHMONGER`, `HERBALIST`), visibilidad automática del cursor del ratón cuando hay cualquier modal o el mapa completo abierto (`is_any_ui_modal_open()`), bloqueo de solapamiento de paneles/zoom con rueda en modales y navegación con `[W/S]` en diálogos.
   - **Estados de Muerte/Aturdimiento, Hospital, Sigilo, Huerto y Persistencia (`VillageNPC.gd`, `DummyEnemy.gd`, `npc.gd`, `VillageManager.gd`, `TavernGamesUI.gd`, `FarmPlot.gd`, `SimpleInventory.gd`, `ChickenCoop.gd`, `ObjectiveManager.gd`, `ObjectiveHUD.gd`):** Protección en `_on_stunned` y desactivación de `Hurtbox` al morir para que ningún cadáver se ponga de pie ni reciba golpes tras morir; cobro de `10 Oro` y `stop_bleeding()` real en la Cama de Urgencias del Hospital; aplicación de `get_stealth_detection_multiplier()` (`ranger_camo_cloak`) en policía, sabotajes y puertas; exigencia de Regadera `[7]` para regar en `FarmPlot`; protección contra consumo innecesario de botiquines/vendas a `100% HP`; reembolso de apuestas al cambiar de pestaña en `TavernGamesUI` y filtrado de NPCs no válidos en la mesa; y persistencia completa de genética de gallinas, cofres de casas, puertas/ventanas, cepos desplegados y objetivos.
9. **Tercera Auditoría Profunda y Corrección de Pesca, Inquisidor, Policía, Persistencia y Modales (`Player.gd`, `PlayerMovementController.gd`, `FishingSpot.gd`, `DomesticPet.gd`, `GameManager.gd`, `VillageNPC.gd`, `VillageManager.gd`):**
   - **Pesca, Regadera y Movimiento (`Player.gd`, `PlayerMovementController.gd`, `FishingSpot.gd`):** Corregido el estado de bloqueo de input en `Player._unhandled_input` (`state == 3` / `FishState.MINIGAME` en vez de `2` / `BITE_ACTIVE`) para permitir enganchar peces al pulsar `[E]`; corregida la propiedad `"max_water_charges"` en `FishingSpot.interact` para rellenar la Regadera en el Lago Oeste; y bloqueado el movimiento `WASD` durante el minijuego de pesca o al sentarse en el tronco del campamento.
   - **Tiempos y Presencialidad del Inquisidor Real Alistair (`VillageManager.gd`, `VillageNPC.gd`):** Separado el temporizador de caminata (`walk_timer`) del temporizador de interrogatorio presencial (`stage_timer`) en `INITIAL_PLAYER_INTERVIEW`, eliminadas las inspecciones/ejecuciones telepáticas por *timeout* en `PLAYER_CHECK` y `HUNTING_SCAPEGOAT`, añadido filtro de NPCs inconscientes/aturdidos/sedados en `INTERVIEWS`, añadido alias `facing_dir` en `VillageNPC.gd`, y garantizada la transición a `HUNTING_PLAYER` si Alistair es agredido o su reemplazo si cae abatido.
   - **Policía, Hospital, Mascotas y Guardado/Carga (`VillageManager.gd`, `VillageNPC.gd`, `DomesticPet.gd`, `GameManager.gd`):** Protegida la hostilidad policial y la Orden de Captura Real (`HUNTING_PLAYER`) frente a interacciones externas con la celda, corregido `doctor_heal` del Dr. Valen para detener el sangrado (`health.stop_bleeding()`), limpiada la rotación de sueño (`is_sleeping`) cuando un NPC herido acude al Hospital, desactivado el `Hurtbox` de mascotas muertas (`DomesticPet`), cerrado automático de modales/diálogos/`TavernGamesUI` al cargar con `[F9]`, e indexado correcto por `family_id`/`building_id` en el guardado/carga de cofres domésticos, puertas y ventanas.
10. **Auditoría Integral de Cuarta Pasada (Restauración de Entidades en `[F9]`, Texturas de Ventanas, Póker y Cruce Forense Dinámico):**
   - **Texturas y Persistencia de Ventanas/Puertas/Cofres (`VillageManager.gd`):** Corregidas las rutas de texturas de ventanas en `load_economy_save_dict()` (`window_glass_open.png` y `window_shutter_closed.png`), añadido `manual_override_timer` a las ventanas forzadas con `[F]`, e indexado independiente de los 10 cofres (`house_chests`) por `title` (con respaldo a `family_id`).
   - **Limpieza de UI, Pesca y Objetos Destructibles al Cargar `[F9]` (`GameManager.gd`, `FishingSpot.gd`, `DestructibleObject.gd`, `ObjectiveHUD.gd`):** Apuntado `load_game()` a `"UI/UIRoot"`, cierre limpio del Mapa del Valle (`close_full_map()`), Rueda de Herramientas (`close_wheel(false)`), descanso en el tronco (`_stand_up_player()`) y pesca activa (`cancel_fishing()`); añadido `set_destroyed_state(destroyed)` en `DestructibleObject.gd` para restaurar cajas/barriles al cargar partida sin reiniciar; y recreación automática de etiquetas de objetivos en `ObjectiveHUD.gd`.
   - **Restauración Completa de Entidades y NPCs Dinámicos (`Player.gd`, `scenes/npc.gd`, `VillageNPC.gd`, `DomesticPet.gd`, `DummyEnemy.gd`, `WildAnimal.gd`, `VillageManager.gd`):** Limpieza de NPCs dinámicos (`_active_traveling_merchant`, `_royal_investigator_npc`, `NPC_Newcomer_*`, `NPC_Hired_*`) que no existían en el guardado, vaciado previo de `trade_npcs` y `family_npcs` en `reconcile_npc_registries_after_load()`, y reseteo completo de `Hurtbox`, sangrado, aturdimiento, hostilidad y sprites al cargar.
   - **Re-cruce Forense de la Morgue e Historial Policial (`VillageManager.gd`, `DomesticPet.gd`, `TavernGamesUI.gd`, `CampSite.gd`):** Re-ejecución automática de `_cross_check_morgue_and_police_records()` cuando ingresa un nuevo cadáver a la Morgue durante la investigación activa de Alistair; registro en `crime_history` y aviso al Inquisidor en robos de cofres, forzados de ventanas y ataques a mascotas con testigos; reembolso exacto (`poker_player_invested`) y protección de teclas `[F1]`/`[F2]` en la misma pestaña activa en `TavernGamesUI.gd`; y limpieza de `chest_sprite = null` en `CampSite._rebuild_house_visuals()`.
11. **Auditoría Integral de Quinta Pasada (Combate, Recreación de NPCs Dinámicos al Cargar, Hostilidad Policial, Áreas de Interacción Fantasmas y Modales UI):**
   - **Combate del Jugador y Pickups al Cargar `[F9]` (`Player.gd`, `WeaponPickup.gd`):** Corregido el reseteo de `combat_ctrl` en `Player.from_save_dict()` usando `_cancel_bow_draw()`, `attack_timer = 0.0` y `hitbox_shape.set_deferred("disabled", true)` (en lugar de las propiedades inexistentes `_is_attacking` / `_is_drawing_bow`); y reemplazado `queue_free()` en `WeaponPickup.gd` por `_set_picked_state(picked)` conectado a `GameManager.game_loaded`.
   - **Hostilidad Policial, `crime_history`, Orden de Captura y Recreación de NPCs Dinámicos (`GameManager.gd`, `VillageManager.gd`, `VillageNPC.gd`):** Eliminada la llamada posterior a `clear_police_hostility()` en `GameManager.load_game()` que borraba la hostilidad recién cargada; guardado y restaurado `is_resisting_arrest`, `crime_history`, `arrivals_today_count`, `_rehire_counter` y `_authority_slots`; movido `reconcile_npc_registries_after_load()` antes del bucle de `shop_businesses` en `load_economy_save_dict()`; y añadido `spawn_dynamic_npc_from_save()` para recrear NPCs dinámicos (`NPC_Newcomer_*`, `NPC_Hired_*`, `NPC_Traveler_*`, `NPC_Rehired_*`, `NPC_Innkeeper_*`) al cargar partida tras reiniciar el juego.
   - **Áreas de Interacción Fantasmas, Cadáveres y Mascotas (`WildAnimal.gd`, `HarvestableNode.gd`, `VillageNPC.gd`, `DomesticPet.gd`, `DestructibleObject.gd`):** Desactivada la colisión de `butcher_area` en animales vivos (`WildAnimal`) y de `interact_area` en nodos agotados (`HarvestableNode`) para que no eclipsen objetos cercanos al pulsar `[E]`; limpiados los punteros de cadáver/paciente (`corpse_being_carried`, `_carrying_corpse_target`, `_active_downed_patient`) en `VillageNPC.from_save_dict()`; añadido el 3er parámetro opcional `offset_y` a `DomesticPet._spawn_floating_text()`; persistido `offspring_genetics_tier` en `WildAnimal`; y cacheado `_base_modulate` en `DestructibleObject`.
   - **Póker, Sedación, Diálogo de Alistair y Modales UI (`VillageNPC.gd`, `VillageManager.gd`, `GameManager.gd`, `ui_root.gd`, `ValleyMapUI.gd`):** Guardada y restaurada `_pre_poker_pos` al sentarse/levantarse del póker; retirados los NPCs sedados del grupo `"enemies"` y desactivado su `body_col`; excluidos guardias sedados/aturdidos en `_find_nearest_police_officer()`; excluidos `ROYAL_INVESTIGATOR` y `TRAVELING_MERCHANT` del bloqueo de diálogo por duelo familiar (`affinity <= -35`); y bloqueada la apertura de Inventario/Mapa/Rueda sobre modales del mundo (`jail_panel`, `pantry_panel`, etc.).
12. **Auditoría Integral de Sexta Pasada (Saqueo en Sigilo, Reemplazo del Inquisidor Real, Escolta Policial, Crafteo/Recados de Artesanos y Colisiones de Nombres en `[F9]`):**
   - **Saqueo en Sigilo (`[E]`), `stealth_knockout()` y `body_col` (`VillageNPC.gd`):** Excluidos `is_stunned_flag` y `sedated_timer > 0.0` de `can_be_stealth_targeted()` y priorizado `loot_npc_pockets()` en `interact()` para poder saquear bolsillos con `[E]` sin salir del sigilo (`[C]`); limpiado `is_stunned_flag = false` y rotación en `take_damage()` / `_on_died()`; y desactivado `body_col` al quedar aturdido, noqueado o abatido.
   - **Reemplazo del Inquisidor Real Alistair y Prevención de Duplicados/Colisiones en `[F9]` (`VillageManager.gd`, `GameManager.gd`):** Comprobado el reemplazo matutino de Alistair en `_advance_royal_investigation_day()` antes del retorno por `HUNTING_PLAYER` / `HUNTING_SCAPEGOAT`; evitada la duplicación del cadáver de Alistair y el respawn falso de mercaderes muertos en `load_economy_save_dict()`; y renombrados/desacoplados los nodos dinámicos antes de `queue_free()` en el mismo frame.
   - **Escolta Policial, Expediente de Alistair y Bloqueo de `[B]`/`[F]` en Modales (`VillageManager.gd`, `VillageNPC.gd`):** Asignado `player_being_escorted_to_jail = true` antes de `clear_police_hostility()` en `start_police_escort_to_jail()`, permitida la escolta física a la celda por parte de Alistair en `_process_royal_investigator_ai()`, conectado `_notify_inquisitor_of_police_crime()` a asaltos, ataques a mascotas, robos de bolsillos y sabotajes con testigos, y bloqueadas las teclas `[B]` y `[F]` durante modales UI, aturdimiento o escolta.
   - **Artesanos, `WildAnimal`, Guardado `[F5]` y Sprites de Reemplazos (`VillageNPC.gd`, `WildAnimal.gd`, `GameManager.gd`, `VillageManager.gd`):** Ocultada `_craft_bar_root` al caer/morir/ir a la Morgue, persistido `_completed_expedition_day` y reseteados estados transitorios en `from_save_dict()`, exigido `is_at_shop_counter()` y reparto a `vault_gold` en compras entre vecinos, corregido el orden de `_exit_burrow()` en `WildAnimal.from_save_dict()`, cerrado `tavern_games` con reembolso antes de guardar `[F5]`, y asignados sprites/lore por `trade_role` a todos los reemplazos dinámicos.
13. **Auditoría Integral de Séptima Pasada (Cierre de `TavernGamesUI` en `[F5]`, Ciclo Completo de `HUNTING_PLAYER`, Cadáveres Dinámicos en `[F9]`, `workshop_materials` y Mascotas):**
   - **Cierre y Reembolso del Casino en `[F5]` (`GameManager.gd`):** Corregida la invocación en `save_game()` de `close_tavern_games` al método real `close_games()` de `TavernGamesUI.gd` para reembolsar apuestas activas de Póker/Billar y levantar de la mesa a los NPCs antes de serializar el guardado.
   - **Ciclo Completo de `HUNTING_PLAYER` del Inquisidor Real Alistair (`VillageManager.gd`):** Transición automática de `HUNTING_PLAYER` a `DEPARTING` al cumplir la condena en la celda (`release_player_from_jail_after_sentence()`) o al pagar la fianza (`pay_bounty_fine()`); re-activación de la hostilidad de Alistair si el jugador se fuga con `[3]` (`alert_police_to_resist()`); rama dedicada `HUNTING_PLAYER` en `update_royal_investigator_ai()` para que Alistair patrulle la Comisaría mientras el jugador está preso; e inclusión de `ROYAL_INVESTIGATOR` en el bucle primario de `_find_nearest_police_officer()`.
   - **Persistencia de Cadáveres de Mercaderes Viajeros e Inquisidores en `[F9]` (`GameManager.gd`, `VillageManager.gd`):** Añadidos los prefijos `"NPC_Royal_Investigator_"` y `"NPC_Merchant_"` a las listas de limpieza y recreación dinámica de `GameManager.load_game()`, renombrados los mercaderes fallecidos a `"NPC_Merchant_Corpse_..."` en `_check_weekly_merchant_arrival()` para conservar su cadáver cuando llega el otro mercader viajero, y re-vinculados `_royal_investigator_npc` y `_active_traveling_merchant` en `reconcile_npc_registries_after_load()`.
   - **Economía Mayorista, `workshop_materials` y Etiquetas de Bolsillos (`VillageManager.gd`, `VillageNPC.gd`):** Exigido `not is_trade_sabotaged(role_id) and holder.is_at_shop_counter()` en `_merchant_buy_from_local_shop()` con reparto real a `vault_gold` para `SOLE_OWNER` (`100%`) y `PARTNER` (`50%`); sumado `workshop_materials[item_id]` cuando el jugador abastece materias primas por mostrador o se las vende al artesano; y añadido el indicador `[E: 💰 Saquear Bolsillos ...]` sobre NPCs aturdidos o sedados.
   - **Escolta Policial, Mascotas, Rueda de Herramientas, Forrajeo, Lápidas y Cadáveres Cargados (`PlayerMovementController.gd`, `ui_root.gd`, `DomesticPet.gd`, `ToolWheelUI.gd`, `HarvestableNode.gd`, `VillageManager.gd`, `dialogue_manager.gd`, `SimpleInventory.gd`):** Bloqueado el movimiento `WASD` y los atajos de UI durante `player_being_escorted_to_jail`; condicionada la pérdida de reputación familiar en `DomesticPet.take_damage()` a la existencia de testigos con multiplicador climático, añadido chequeo de testigos al desollar mascotas y carga silenciosa `_on_died(true)`; corregido `"max_water_charges"` en `ToolWheelUI.gd`; regenerados los mordiscos parciales de `FORAGE` al amanecer en `HarvestableNode.gd`; renombradas las lápidas antes de `queue_free()` en `_rebuild_cemetery_graves_from_save()`; auto-cerrado el diálogo si el interlocutor cae/muere/se vuelve hostil; y soltado automáticamente el cadáver cargado (`_drop_carried_corpse()`) si el portador es aturdido, sedado, dormido o entra en combate.
