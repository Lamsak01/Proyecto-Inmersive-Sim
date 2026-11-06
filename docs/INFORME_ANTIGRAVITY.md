# Informe de Antigravity — Bloque FIS3 (Alcantarillas que se recorren de verdad)

**Fecha:** 2026-11-05  
**Encargo:** `docs/ENCARGO_ANTIGRAVITY.md` §2 (Bloque FIS3) y notas de `docs/REVISION_SUPERVISOR.md`.

---

## 1. Qué hice

### 1.1. Tres trampillas/rejillas en la calle (`sewer_grate`, 2D y 3D)
- Actualicé `VillageUnderworld.SEWER_LOCATIONS` con posiciones de calle fuera de todas las huellas de edificios (`vm.building_footprints`) y fuera de las calzadas principales por donde caminan los vecinos:
  - `"cistern"` («Cisterna Vieja bajo la Plaza»): `Vector2(518.0, 26.0)` (esquina noreste del adoquinado de la Plaza Central).
  - `"smuggler_tunnel"` («Pasadizo del Contrabandista»): `Vector2(398.0, -118.0)` (callejón al sur de la Taberna y al oeste de la calle norte-sur).
  - `"flooded_vault"` («Bóveda Inundada del Antiguo Gremio»): `Vector2(248.0, -90.0)` (entre la calle occidental y la fachada oeste de la Herrería).
- En `VillageUnderworld.build_sewers_world(vm)` se instancian las tres rejillas (`SewerGrate_cistern`, `SewerGrate_smuggler_tunnel`, `SewerGrate_flooded_vault`) usando `scripts/obstacles/WorldInteractableProp.gd` con `prop_kind = "sewer_grate"` (en los grupos `"interactable"`, `"sewer_grate"` y `"sewer_station"`).
- **Sin llave (`sewers_state(vm)["unlocked"] == false`):** `get_interact_label` devuelve `"Cerrada: el perista vende la llave"` y al pulsar `[E]` (`VillageUnderworld.interact_sewer_grate`) muestra el aviso y no baja al jugador.
- **Con llave (`sewers_state(vm)["unlocked"] == true`):** `get_interact_label` devuelve `"Bajar a las alcantarillas (<título>)"` y al pulsar `[E]` llama a `VillageUnderworld.enter_sewer_location(vm, loc_id, player)`, que pone `sewers_state(vm)["current_loc"] = loc_id`, `vm.set_player_elevation_level(-1)`, `vm._elevation_anchor = Vector2.INF` y traslada `pl.global_position` a `SEWER_LOCATIONS[loc_id]["tunnel_pos"]`.
- En `WorldStage3D._build_static_terrain_3d()` las tres rejillas 3D de hierro se colocan exactamente en `VillageUnderworldScript.SEWER_LOCATIONS[loc_id]["pos"]`.

### 1.2. Red de túneles subterráneos caminables con muros físicos (`StaticBody2D`)
- En `VillageUnderworld.build_sewers_world(vm)` construí el nodo `SewersNetwork2D` al sur del mapa (`x = 205..635`, `y = 1480..1560`, centrado en `y = 1520.0`, al sur del Bosque Profundo que termina en `y = 1240` y fuera del alcance de los vecinos de la superficie):
  - Tres cámaras subterráneas conectadas en fila: `"flooded_vault"` en `Vector2(260.0, 1520.0)`, `"smuggler_tunnel"` en `Vector2(420.0, 1520.0)` y `"cistern"` en `Vector2(580.0, 1520.0)`, unidas por dos galerías de paso en `Vector2(340.0, 1520.0)` y `Vector2(500.0, 1520.0)`.
  - Muros físicos reales en `SewerTunnelWallsBody` (`StaticBody2D` con `collision_layer = 1` y 20 `CollisionShape2D` rectangulares) que cierran el perímetro de las tres cámaras y los dos pasillos para que el jugador camine entre ellas sin salirse al vacío.
  - Dibujo 2D en `SewersVisual2D` (grupo `"sewer_visual_2d"`, que `WorldStage3D._sync_2d_flat_visuals` oculta automáticamente en modo 3D).
- En `WorldStage3D._build_sewers_3d()` reconstruí `sewers_root_3d` en las mismas coordenadas `y = 1520.0` con roca subterránea alrededor, suelos de losa y canales de agua turbia para las 3 cámaras y los 2 pasillos conectados, muros de piedra, antorchas de pared con `OmniLight3D`, escalerillas 3D y cofres `props/Prop_Chest_Closed.gltf`.
- En `VillageManager.check_elevation_exit(player)` añadí la guarda `if VillageUnderworld.is_player_in_sewers(self): return` al principio para que caminar por los túneles nunca devuelva automáticamente al jugador al nivel `0`.

### 1.3. Escalerillas de salida (`sewer_ladder`) y purga semanal por el Pasadizo del Contrabandista
- En cada cámara subterránea (`SEWER_LOCATIONS[loc_id]["ladder_pos"]`, en `y = 1490.0`) se instancia una escalerilla (`SewerLadder_cistern`, `SewerLadder_smuggler_tunnel`, `SewerLadder_flooded_vault`) con `prop_kind = "sewer_ladder"`.
- Al pulsar `[E]` (`Subir a la calle (<título>)`), `VillageUnderworld.exit_sewer_ladder(vm, loc_id, player)` llama a `exit_sewers_to_surface(vm)` (`current_loc = ""`, `vm.set_player_elevation_level(0)`) y coloca al jugador en `SEWER_LOCATIONS[loc_id]["pos"]`. Así se puede entrar por una rejilla (p. ej. la Cisterna), caminar bajo tierra hasta otra cámara y salir a la calle por otra rejilla distinta.
- Si se sale por la escalerilla de `"smuggler_tunnel"` y `vm.wanted_level > 0` y `VillageHousing.can_purge_wanted(vm)` es cierto, rebaja `vm.wanted_level` en 1 y llama a `VillageHousing.mark_wanted_purge(vm)` (máximo 1 vez cada 7 días, compartido con el sótano y el archivo policial).

### 1.4. Cofres de contrabando bajo tierra (`sewer_chest`, suma cero) y limpieza del diálogo del perista
- En cada cámara subterránea (`SEWER_LOCATIONS[loc_id]["chest_pos"]`, en `y = 1502.0`) se instancia un cofre (`SewerChest_cistern`, `SewerChest_smuggler_tunnel`, `SewerChest_flooded_vault`) con `prop_kind = "sewer_chest"`.
- Al pulsar `[E]` (`Abrir cofre de contrabando (<título>)`), `VillageUnderworld.interact_sewer_chest` llama a `open_sewer_chest(vm, loc_id, inv)`:
  - Limita la apertura a **1 vez al día por cámara** mediante `sewers_state(vm)["chest_days"][loc_id]`.
  - Si tiene éxito (misma fórmula con bonificación por `"lockpick"` y `"voltaic_capacitors"`), entrega 1 unidad de `loot_item` (`"copper_coil"`, `"bandit_scrap"` o `"ancient_book"`) y hasta 6 monedas descontadas de `sewers_state(vm)["lost_coins_pool"]` (cumpliendo la Regla 1 de suma cero).
  - Si falla, aplica el percance de trampa/aguas negras (`-14.0` a `health_comp.current_health` sin bajar de `1.0` y `-25.0` a `player_hygiene`).
- En `VillageUnderworld.add_dialogue_choices` retiré del diálogo del perista las opciones `"Bajar al nivel -1 y explorar..."` (`underworld_sewer_explore:`) y `"Subir por la escalerilla..."` (`underworld_sewer_surface`), manteniendo únicamente `"Comprar llave de las alcantarillas (20 oro)"` (`underworld_unlock_sewers`) cuando aún no está desbloqueada. Se conserva la función `explore_sewer_location` para compatibilidad con la prueba `PN.2`.

### 1.5. Guardado y carga estando en las alcantarillas + nota de FIS2
- En `VillageManager.get_economy_save_dict()` se guarda `"player_elevation_level": player_elevation_level`, y en `load_economy_save_dict(d)` se restaura `set_player_elevation_level(int(d.get("player_elevation_level", 0)))` y se invoca `VillageUnderworld.after_load(self)` (que mantiene `player_elevation_level = -1` y `_elevation_anchor = Vector2.INF` si `sewers_state(vm)["current_loc"] != ""`).
- Atendiendo la nota de `docs/REVISION_SUPERVISOR.md` sobre FIS2, en `WorldStage3D._build_building_interior_3d` (rama `"mixed_family_tinker"`) sustituí la mesa con objetos pequeños de la Terminal Lógica por una `Table_Large.gltf` con un chasis más grande, bobina de cobre y tubo voltaico luminoso bien reconocibles en 3D, y actualicé `docs/capturas_fis2/taller_12h.png` y `taller_22h.png`.

---

## 2. Qué archivos toqué

- `scripts/obstacles/WorldInteractableProp.gd`: añadidos `sewer_loc_id`, los tipos `"sewer_grate"`, `"sewer_ladder"` y `"sewer_chest"`, sus dibujos 2D (`_draw_sewer_grate_2d`, `_draw_sewer_ladder_2d`, `_draw_sewer_chest_2d`), sus etiquetas en `get_interact_label` y sus acciones en `interact`.
- `scripts/ui/InteractionSelector.gd`: añadido `cand.is_in_group("sewer_station")` al desempate de prioridad en `refresh()`.
- `scripts/systems/VillageUnderworld.gd`: actualizadas las coordenadas de `SEWER_LOCATIONS`; añadidas `interact_sewer_grate`, `exit_sewer_ladder`, `is_sewer_chest_looted_today`, `open_sewer_chest`, `interact_sewer_chest`, `build_sewers_world` y `after_load`; actualizadas `enter_sewer_location` y `exit_sewers_to_surface`; retiradas las opciones de diálogo `underworld_sewer_explore:` y `underworld_sewer_surface` en `add_dialogue_choices`.
- `scripts/systems/VillageManager.gd`: llamada a `VillageUnderworld.build_sewers_world(self)` en `setup_village`; guarda en `check_elevation_exit(player)` cuando `VillageUnderworld.is_player_in_sewers(self)` es verdadero; persistencia de `player_elevation_level` y llamada a `VillageUnderworld.after_load(self)` en `get_economy_save_dict` / `load_economy_save_dict`.
- `scripts/visuals/WorldStage3D.gd`: rejillas 3D de calle en `SEWER_LOCATIONS[loc_id]["pos"]`; reconstrucción de `_build_sewers_3d()` con las 3 cámaras y 2 galerías conectadas en `y = 1520.0`, escalerillas, antorchas y cofres; ocultación del grupo `"sewer_visual_2d"` en `_sync_2d_flat_visuals`; mejora visual de la Terminal Lógica 3D en `"mixed_family_tinker"`.
- `tools/screenshot_3d.gd`: añadidos los sitios `"trampilla"` y `"tunel"` (entrando y saliendo de las alcantarillas en memoria sin tocar la partida guardada).
- `tools/tests/verify_all.gd`: añadido el bloque `Block 97: Walkable Sewers, Street Grates, Ladders & Contraband Chests (FIS3)` y restaurada `pn_pl.global_position` al final del bloque `PN`.
- `docs/capturas_fis3/`: capturas 3D `trampilla_12h.png`, `trampilla_22h.png`, `tunel_12h.png` y `tunel_22h.png` (más actualización de `docs/capturas_fis2/taller_12h.png` y `taller_22h.png`).
- Documentación: `docs/HANDOFF.md`, `CHANGELOG.md`, `docs/REGISTRO_TRABAJO.md`, `GameVault/02_Sistemas/Capas Verticales y Alcantarillas.md`, `GameVault/02_Sistemas/Red de las Sombras.md`, `GameVault/05_Roadmap_y_Lore/Tablero.md`, `GameVault/06_Diario/2026-11-05.md` y este `docs/INFORME_ANTIGRAVITY.md`.

---

## 3. Qué probé y con qué resultado

1. **Comprobación de arranque y compilación GDScript:**
   - Comando: `flatpak run org.godotengine.Godot --headless --path . --quit-after 3`
   - Resultado: **0 `SCRIPT ERROR` y 0 `Parse Error`** (código de salida `0`).
2. **Suite principal (`verify_all.gd`, incluyendo `Block PN`, `Block FIS2` y el nuevo `Block FIS3`):**
   - Comando: `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd > /tmp/t.log 2>&1; grep -c 'TESTS PASSED' /tmp/t.log`
   - Resultado: **`1`** (`ALL ... TESTS PASSED!`, `0` `SCRIPT ERROR`).
3. **Prueba de nombres y perfiles (`names_check.gd`):**
   - Comando: `timeout 60 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/names_check.gd 2>&1 | tail -3`
   - Resultado: **`NAMES CHECK PASSED (200 F / 200 M / 200 apellidos + 17 PersonProfile + B0.3 generator + B1.1/B1.2 social + B2.1 hangouts + B3.1-B3.4 romance + B4.1 fights)`**.
4. **Simulación social de 60 días (`social_sim.gd`):**
   - Comando: `timeout 150 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/social_sim.gd 2>&1 | tail -3`
   - Resultado: **`SOCIAL SIM CHECK PASSED (60d metas verificadas en 5 semillas + reemplazos procedurales)`**.
5. **Cobertura de diálogos (`dialogue_coverage.gd`):**
   - Comando: `timeout 80 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/dialogue_coverage.gd > /tmp/c.log 2>&1; grep 'COVERAGE DONE' /tmp/c.log; grep -c 'SCRIPT ERROR' /tmp/c.log`
   - Resultado: **`COVERAGE DONE npcs=18 actions=669`** y **`0`** `SCRIPT ERROR`.
6. **Capturas 3D (`tools/screenshot_3d.gd`):**
   - Comando: `flatpak run org.godotengine.Godot --path . -s tools/screenshot_3d.gd -- docs/capturas_fis3 12,22 trampilla,tunel`
   - Resultado: generadas y revisadas visualmente `trampilla_12h.png`, `trampilla_22h.png`, `tunel_12h.png` y `tunel_22h.png` en `docs/capturas_fis3/`.

---

## 4. Qué no pude hacer o dudas pendientes

- Todo el bloque FIS3 quedó completado y verificado. No surgió ninguna duda de diseño que requiriera añadir entradas a `docs/PREGUNTAS_PENDIENTES.md`.
