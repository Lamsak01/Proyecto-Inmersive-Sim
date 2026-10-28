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
