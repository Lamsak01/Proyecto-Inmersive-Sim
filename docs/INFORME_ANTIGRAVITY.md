# Informe de Antigravity — Bloque FIS4 (Ganado vivo en el rancho y tus animales de verdad)

**Fecha:** 2026-11-05
**Encargo completado:** Bloque **FIS4** de `docs/ENCARGO_ANTIGRAVITY.md` (§2).

---

## 1. Qué hice

1. **Ganado vivo en el corral del Rancho del Sur (`ranch_herd` → grupo `"ranch_livestock"`):**
   - Creé `scripts/obstacles/LivestockAnimal.gd` (`extends Node2D`) con las funciones `configure_from_entry`, `setup_animal`, `update_from_dict`, `_process`, `get_interact_label` e `interact`.
   - En `scripts/systems/VillageHousing.gd`, añadí `RANCH_PEN_RECT = Rect2(Vector2(318.0, 408.0), Vector2(71.0, 124.0))` (interior de la valla `x = 310..397`, `y = 400..540` del solar `"s3"`) y la función `sync_livestock(vm)` que sincroniza un nodo `LivestockAnimal` en el grupo `"ranch_livestock"` por cada entrada de `VillageHousing.state(vm)["ranch_herd"]`.
   - Cada animal camina despacio dentro de su `pen_rect` (sin atravesar la valla) y ajusta el tamaño de su sprite 2D y su modelo 3D según `stage` (`"chick"`, `"juvenile"`, `"adult"`). Cuando `ranch_herd` cambia en `VillageHousing.daily(vm)` (nace una cría, crece de etapa o se vende una res madura), `sync_livestock(vm)` actualiza los nodos del mapa al instante.
   - En `scripts/systems/VillageTrades.gd` (`build_extras`, caso `"ranch"`), eliminé los 4 dibujos estáticos (`hen`, `pig`), marqué la `Line2D` de la valla en el grupo `"ranch_fence_2d"` y llamé a `VillageHousing.sync_livestock(vm)`.
   - En `scripts/visuals/WorldStage3D.gd` (`_build_static_terrain_3d`), añadí el suelo de tierra y la valla 3D de postes y travesaños del corral del Rancho del Sur (`x = 310..397`, `y = 400..540`) con `_build_fence_run_3d`, y oculté el borde plano `"ranch_fence_2d"` en `_sync_2d_flat_visuals(use_3d)`.

2. **Tus propios animales vivos en el corral (`player_animals` → grupo `"player_livestock"`):**
   - En `VillageHousing.sync_livestock(vm)`, cada entrada de `VillageHousing.state(vm)["player_animals"]` se sincroniza con un nodo `LivestockAnimal` en el grupo `"player_livestock"` dentro del recinto interior del `ChickenCoop` (`_player_pen_rect(vm)` = `Rect2(coop_pos + Vector2(-33.0, -6.0), Vector2(66.0, 31.0))`).
   - En `scripts/obstacles/ChickenCoop.gd`, `has_live_chickens()` comprueba tanto `chickens` como `"player_livestock"`, y las 3 gallinas iniciales (`_spawn_initial_chickens(3)` en `_ready` y `saved.get("chickens", 3)` en `_load_saved_state`) y `status_label` se mantienen intactos.
   - En `scripts/ui/InteractionSelector.gd` (`_refresh`), di prioridad a los nodos en `"player_livestock"` sobre el `CoopInteractArea` general del gallinero.
   - Si un animal del jugador muere por hambre (`unfed >= ANIMAL_STARVE_DAYS`) en `VillageHousing.daily(vm)`, `sync_livestock(vm)` elimina inmediatamente su nodo físico del mapa.

3. **Interacción en persona con `[E]` para alimentar y recoger lana o huevos:**
   - Implementé en `scripts/systems/VillageHousing.gd`:
     - `can_harvest_animal_product(vm, idx: int) -> bool`: comprueba que el animal sea `"adult"` y que hayan pasado al menos `PRODUCT_COOLDOWN_DAYS = 2` días desde `last_product_day`.
     - `get_player_animal_interact_label(vm, idx: int) -> String`: devuelve `"Dar de comer a la oveja"` / `"Dar de comer a la gallina"` para crías, jóvenes o adultos hambrientos, y `"Esquilar la oveja"` / `"Recoger huevos"` (o `" (en espera)"` si está en enfriamiento y ya comió hoy) para adultos listos.
     - `feed_single_player_animal(vm, idx: int, inv, player: Node2D = null) -> bool`: gasta `1` de `"wheat"`, `"bread"` o `"carrot"` de la mochila del jugador y hace avanzar a ese animal (`fed_day = today()`, `age_days += 2`, actualiza `stage` y `power`, y llama a `sync_livestock(vm)`).
     - `harvest_player_animal(vm, idx: int, inv, player: Node2D = null) -> bool`: entrega `+1 "wool"` (si `species == "sheep"`) o `+1 "egg"` (si `species == "rooster"`), registra `last_product_day = today()` (máximo 1 vez cada 2 días por animal) y añade entrada en `VillageChronicle`.
     - `interact_player_animal(vm, idx: int, player: Node2D) -> bool`: punto de entrada llamado por `LivestockAnimal.interact(player)`.
   - **Retirado el `"cooked_meat"` automático:** eliminé de `VillageHousing.daily(vm)` la entrega automática de `"cooked_meat"` cada 2 días.
   - **Retirado `"housing_feed_animals"` del diálogo:** eliminé la opción `"housing_feed_animals"` de `VillageHousing.add_dialogue_choices(vm, npc, diag, ch_arr)` (conservando las opciones `"housing_buy_chick:rooster"` y `"housing_buy_chick:sheep"` para comprar crías al ganadero o al carpintero, y manteniendo la función `feed_player_animals` por compatibilidad con el test antiguo `Block PI`).

4. **Aspecto 3D (`Alpaca.glb` CC0 + gallina procedural) y 2D:**
   - Descargué `assests/curated_3d/animals/animated/Alpaca.glb` del paquete CC0 de Quaternius (vía Poly Pizza, con animaciones `Walk`, `Gallop`, `Idle`, `Idle_2`, `Eating`, `Death`) para `"sheep"` y lo documenté en `assests/curated_3d/animals/animated/LICENCIA.txt`.
   - En `scripts/visuals/AnimalModel3D.gd`, añadí `set_model_config(rel_path: String, h_px: float)` y `_build_procedural_chicken(fit_h: float)` para construir una gallina 3D con primitivas (`model_rel == "procedural:chicken"`: cuerpo, alas, cola, cabeza, pico, cresta y barbilla rojas, patas e inclinación/picoteo animado en `_process`).
   - En 2D (`LivestockAnimal.update_from_dict`), `"sheep"` usa `res://assests/world/harvest/wild_deer.png` teñido de blanco lana y `"rooster"` usa `res://assests/world/camp/chicken.png`, escalados por etapa.

5. **Guardado y carga:**
   - En `scripts/systems/VillageManager.gd`, llamé a `VillageHousing.sync_livestock(self)` tanto en `setup_village` como en `load_economy_save_dict`, restaurando los animales físicos del rancho y del corral al cargar partida.

---

## 2. Archivos tocados

- `assests/curated_3d/animals/animated/Alpaca.glb` y `assests/curated_3d/animals/animated/Alpaca.glb.import` *(nuevos — modelo 3D animado CC0 de Quaternius para la oveja)*
- `assests/curated_3d/animals/animated/LICENCIA.txt` *(documentado `Alpaca.glb` CC0 de Quaternius)*
- `scripts/obstacles/LivestockAnimal.gd` y `scripts/obstacles/LivestockAnimal.gd.uid` *(nuevos — nodo físico de cada animal vivo de `ranch_herd` y `player_animals`)*
- `scripts/visuals/AnimalModel3D.gd` *(`set_model_config`, `_build_procedural_chicken` y animación procedural en `_process`)*
- `scripts/systems/VillageHousing.gd` *(`RANCH_PEN_RECT`, `PRODUCT_COOLDOWN_DAYS`, `_player_pen_rect`, `sync_livestock`, `can_harvest_animal_product`, `get_player_animal_interact_label`, `feed_single_player_animal`, `harvest_player_animal`, `interact_player_animal`, retirada de `"cooked_meat"` automático en `daily` y retirada de `"housing_feed_animals"` en `add_dialogue_choices`)*
- `scripts/systems/VillageTrades.gd` *(eliminados los 4 dibujos fijos de `"ranch"` en `build_extras`, añadido grupo `"ranch_fence_2d"` y llamada a `VillageHousing.sync_livestock`)*
- `scripts/systems/VillageManager.gd` *(`VillageHousing.sync_livestock(self)` en `setup_village` y `load_economy_save_dict`)*
- `scripts/obstacles/ChickenCoop.gd` *(`has_live_chickens` con `"player_livestock"` y separación mutua en `_update_chickens_motion`, conservando `_spawn_initial_chickens(3)`, `saved.get("chickens", 3)` y `status_label`)*
- `scripts/visuals/WorldStage3D.gd` *(valla y suelo 3D del corral del Rancho del Sur en `_build_static_terrain_3d` y ocultación de `"ranch_fence_2d"` en `_sync_2d_flat_visuals`)*
- `scripts/ui/InteractionSelector.gd` *(prioridad en `_refresh` para `"player_livestock"`)*
- `tools/screenshot_3d.gd` *(sitios `"rancho"` y `"corral"`)*
- `tools/tests/verify_all.gd` *(añadido `Block 98: Live Ranch Herd & Player Livestock (FIS4)`)*
- `docs/capturas_fis4/` *(`rancho_12h.png`, `rancho_22h.png`, `corral_12h.png`, `corral_22h.png`)*
- `CHANGELOG.md`, `docs/HANDOFF.md`, `docs/REGISTRO_TRABAJO.md`, `GameVault/02_Sistemas/Cría de Animales y Apuestas.md`, `GameVault/06_Diario/2026-11-05.md`, `docs/INFORME_ANTIGRAVITY.md`

---

## 3. Qué probé y con qué resultado

1. **Arranque headless limpio:**
   - `timeout 45 flatpak run org.godotengine.Godot --headless --path . --quit-after 3` → **OK** (`0` `SCRIPT ERROR`, `0` `Parse Error`).
2. **Suite principal (`verify_all.gd`, incluido `Block FIS4`):**
   - `timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd` → **OK** (`Block FIS4 (Live Ranch Herd & Player Livestock) OK` y todos los bloques previos en verde).
3. **Nombres y generación procedural (`names_check.gd`):**
   - `timeout 60 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/names_check.gd` → **OK** (`NAMES CHECK PASSED`).
4. **Cobertura de diálogos (`dialogue_coverage.gd`):**
   - `timeout 90 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/dialogue_coverage.gd` → **OK** (`COVERAGE DONE npcs=18 actions=603`).
5. **Simulación social de 60 días (`social_sim.gd`):**
   - `timeout 60 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/social_sim.gd` → **OK** (`SOCIAL SIM CHECK PASSED`).
6. **Capturas 3D en ventana real (`screenshot_3d.gd`):**
   - `timeout 90 flatpak run org.godotengine.Godot --path . -s tools/screenshot_3d.gd -- /home/lamsak/Videojuego/docs/capturas_fis4 12,22 rancho,corral` → **OK** (4 capturas verificadas visualmente en `docs/capturas_fis4/`).

---

## 4. Qué no pude hacer o dudas pendientes

- Todo lo pedido en el **Bloque FIS4** quedó implementado, verificado con tests y capturas 3D, documentado y subido a `main`. No quedaron puntos pendientes ni dudas de diseño para `docs/PREGUNTAS_PENDIENTES.md`.

---

## 5. Corrección FIS4

Aplicados los 3 puntos indicados en `docs/REVISION_SUPERVISOR.md`:

1. **Restauradas las 3 gallinas iniciales de `ChickenCoop` (`scripts/obstacles/ChickenCoop.gd`):**
   - En `ChickenCoop._ready`, devolví la llamada a `_spawn_initial_chickens(3)`.
   - En `ChickenCoop._load_saved_state`, devolví el valor por defecto a `clampi(int(saved.get("chickens", 3)), 0, 6)`.
2. **Restaurado el letrero `status_label` del gallinero (`scripts/obstacles/ChickenCoop.gd`):**
   - En `ChickenCoop._process(delta)`, eliminé la condición `and not has_livestock`, de modo que `status_label` sigue mostrándose siempre que `_player_near or mouse_near` sea cierto (el selector de `[E]` en `InteractionSelector._refresh` ya resuelve qué objeto se activa).
3. **Convivencia sin pisarse en el corral (`VillageHousing._player_pen_rect`, `LivestockAnimal._compute_separation_step`, `ChickenCoop._update_chickens_motion`):**
   - Amplié `VillageHousing._player_pen_rect(vm)` a `Rect2(coop_pos + Vector2(-33.0, -6.0), Vector2(66.0, 31.0))` para aprovechar todo el ancho útil del vallado del gallinero (`76 x 60` px) sin invadir la franja norte del comedero y el nido (`y = -16`).
   - Añadí `_compute_separation_step(delta)` en `LivestockAnimal.gd` (llamado desde `LivestockAnimal._process(delta)`) y empuje recíproco en `ChickenCoop._update_chickens_motion(delta)` para que los nodos de `"player_livestock"` y las gallinas de `ChickenCoop.chickens` mantengan distancia entre sí dentro del corral sin superponerse.
   - Verificado en `tools/tests/verify_all.gd` (`FIS4.6a`, `FIS4.6b`, `FIS4.6c`).
