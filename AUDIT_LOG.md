# Registro de Auditoría y Depuración con Rollback (`AUDIT_LOG.md`)

Este archivo registra únicamente **bugs reales de jugabilidad/lógica** detectados durante el bucle de auditoría, junto con el commit previo exacto para permitir un rollback inmediato (`git revert <commit>` o `git reset --hard <commit_previo>`).

---

## Iteración 1 — Commit Base para Rollback: `9c1952c`

### 1. Veredicto del Inquisidor Real sin Testigos y Clave de Coartada en Fallback
- **Archivo y líneas afectadas:** `scripts/systems/VillageManager.gd` (`líneas 5729-5755`)
- **Descripción del fallo real:**
  1. En `_conclude_royal_investigation_with_mandatory_verdict()`, la condición para descartar al jugador sin testigos era `sc <= 15 and kd < 0.0`. Como llevar equipada el arma inicial por defecto (Espada) sumaba `+16` (`score = 26`), si matabas al mercader lejos del pueblo (`> 360 px`) sin ningún testigo ni prueba, todos los aldeanos se descartaban por distancia y el Inquisidor condenaba mágicamente al jugador.
  2. En el bucle de respaldo (`línea 5745`) se consultaba `s_entry.get("alibi", "")` en lugar de la clave real `s_entry.get("mem_alibi_partner", "")`.
- **Solución aplicada:** Exigir `sc < 45 and kd < 0.0` para descartar al jugador cuando no hay testigos ni pruebas físicas/policiales, corregir la clave `"mem_alibi_partner"` en el bucle de respaldo y elegir al aldeano sin coartada más cercano antes de caer en `"Jugador"`.

### 2. Empuje Físico (`push_velocity`) Ignorado en Enemigos de la Llanura y Ranas
- **Archivo y líneas afectadas:** `scripts/enemies/DummyEnemy.gd` (`líneas 62-70, 124-126`)
- **Descripción del fallo real:** `DummyEnemy` define `push_velocity` y recibe `apply_push(force)` al ser golpeado (por ejemplo, con el Martillo), pero `_physics_process(delta)` nunca aplicaba ni desaceleraba `push_velocity`.
- **Solución aplicada:** Aplicar y desacelerar `push_velocity` al inicio de `DummyEnemy._physics_process(delta)` (igual que en `scenes/npc.gd`).

### 3. Pausa de Tiempo (`WorldClock.is_time_frozen()`) Ignorada por Sangrado, Stun, Agonía e IA Enemiga
- **Archivos y líneas afectadas:**
  - `scripts/systems/combat/HealthComponent.gd` (`líneas 30-34`)
  - `scripts/systems/combat/StunComponent.gd` (`líneas 17-19`)
  - `scripts/enemies/VillageNPC.gd` (`línea 704`)
  - `scripts/systems/ai/EnemyAI.gd` (`líneas 103-106`)
- **Descripción del fallo real:** Mientras el reloj del mundo está congelado por jugar Póker/Billar en la Taberna (`WorldClock.is_time_frozen()`), el sangrado activo (`HealthComponent._process`) seguía drenando vida (pudiendo matar al jugador en plena partida de cartas), el temporizador de agonía (`bleedout_timer`) y de aturdimiento (`StunComponent`) seguían corriendo, y `EnemyAI` seguía procesando movimiento/ataques.
- **Solución aplicada:** Pausar el tick en `HealthComponent._process`, `StunComponent._process`, `EnemyAI._physics_process` y el descuento de `bleedout_timer` en `VillageNPC._physics_process` cuando `WorldClock.is_time_frozen()` es `true`.

---

## Iteración 2 — Commit Base para Rollback: `9083cfa`

### 4. Flag `is_raiding_farm` Persistía Activo Cuando `_find_best_food_target()` Elegía un Conejo o Arbusto del Bosque
- **Archivo y líneas afectadas:** `scripts/enemies/WildAnimal.gd` (`líneas 462-466`)
- **Descripción del fallo real:** Detectado por el test de ejecución real en Godot Headless: cuando un zorro (u otro animal) tenía `is_raiding_farm = true` y llamaba a `_find_best_food_target()`, si encontraba un conejo salvaje (`best_node = rab`), no entraba en las ramas `if not best_node`, dejando `is_raiding_farm = true` aunque su objetivo ya no fuera el gallinero ni la granja.
- **Solución aplicada:** Resetear `is_raiding_farm = false` al inicio de `_find_best_food_target()`, de modo que solo valga `true` si el objetivo elegido en esa búsqueda es realmente el gallinero o un cultivo de la granja.

---

## Iteración 3 — Commit Base para Rollback: `9a7d122`

### 5. Error en Consola del Editor de Godot (`Attempt to call a method on a placeholder instance`) en Componentes Instanciados por Scripts `@tool`
- **Archivos y líneas afectadas:**
  - `scripts/systems/combat/HealthComponent.gd` (`líneas 26-34`)
  - `scripts/systems/combat/StunComponent.gd` (`líneas 17-24`)
  - `scripts/systems/combat/SurvivalComponent.gd` (`líneas 23-34`)
  - `scripts/systems/ai/EnemyAI.gd` (`líneas 72-76, 106-110`)
  - `scripts/systems/VillageManager.gd` (`líneas 2078-2081`)
- **Descripción del fallo real:** Como `VillageManager.gd`, `VillageNPC.gd` y `DomesticPet.gd` son scripts `@tool` (para visualizar la aldea en el visor 2D del Editor), al abrir `World.tscn` en el Editor instancian `HealthComponent.new()` y `StunComponent.new()`. Aunque esos componentes no tienen `@tool`, Godot ejecuta su `_process(delta)` dentro del Editor cuando son creados con `.new()`. Como el autoload `WorldClock` no es `@tool`, en el Editor existe como *placeholder instance* y llamar a `WorldClock.is_time_frozen()` lanzaba en bucle: `Invalid call function 'is_time_frozen' in base 'Node (WorldClock.gd)': Attempt to call a method on a placeholder instance`.
- **Solución aplicada:** Desactivar `_process` / `_physics_process` en `_ready()` cuando `Engine.is_editor_hint()` es `true` y añadir la guarda `if Engine.is_editor_hint()` al inicio de `_process` / `_physics_process` en `HealthComponent.gd`, `StunComponent.gd`, `SurvivalComponent.gd`, `EnemyAI.gd` y `VillageManager._update_streetlights_glow()`.

---

## Iteración 4 — Commit Base para Rollback: `74045dc`

### 6. Correcciones Puntuales Finales y Limpieza de 100% de Warnings GDScript (`-d`)
- **Archivos afectados:** `scripts/enemies/DomesticPet.gd`, `scripts/systems/VillageManager.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/obstacles/HarvestableNode.gd`, `scripts/PlayerMovementController.gd`, `scripts/obstacles/CampSite.gd`, `scripts/ui/ValleyMapUI.gd`, `scripts/ui/TavernGamesUI.gd`, `scenes/ui_root.gd`
- **Correcciones aplicadas:**
  1. `DomesticPet.gd`: Firma `func(_dps = 0):` en `bleed_triggered`, desactivación de persecución hostil durante escolta/prisión y reseteo de `is_sleeping = false` + `sprite.scale` al cargar mascota viva (`[F9]`).
  2. `VillageManager.gd` y `VillageNPC.gd`: Bloqueo de interacciones `[E]` y derribos en sigilo durante `player_being_escorted_to_jail`, limpieza de `_reporting_corpse_target` al aturdir/noquear a un testigo, prioridad de comida de Taberna (`not near_tavern`), refresco de mostrador `_refresh_shop_stall_visual`, reseteo de `_craft_progress` al cambiar de receta y persistencia de `mood`/`thoughts`.
  3. Eliminadas las 26 advertencias amarillas del compilador GDScript (`godot --headless -d` ahora reporta **0 errores y 0 warnings**).

---

## Iteración 5 (Paso 1 Simplificación) — Commit Base para Rollback: `b01eb18`

### 7. Simplificación y Compactación Data-Driven en `scripts/enemies/VillageNPC.gd` (-194 líneas netas)
- **Archivo afectado:** `scripts/enemies/VillageNPC.gd` (`4,069` → `3,875` líneas)
- **Cambios aplicados (100% preservación de mecánicas, lore, diálogos y guardado/carga):**
  1. Unificados perfiles iniciales (`ROLE_INITIAL_GOLD`, `ROLE_INITIAL_MATERIALS`, `ROLE_PSYCHOLOGY`, `NPC_LORE_PROFILES`, `ROLE_FALLBACK_LORE`, `ARTISAN_RECIPES`).
  2. Añadidos helpers reutilizables (`is_incapacitated()`, `is_conscious()`, `_stop_crafting_bar()`, `_get_pocket_loot_hint()`, `_spawn_shot_tracer()`, `_make_armor_menu()`).
  3. Unificadas las ramas `buy` y `buy2` en `on_dialogue_action()` y compactadas las lecturas de diccionario en `from_save_dict()`.

---

## Iteración 6 (Paso 2 Simplificación) — Commit Base para Rollback: `4f82bfc`

### 8. Simplificación de Constructores UI, Autoridades y Limpieza de Nodos en `scripts/systems/VillageManager.gd` (-142 líneas netas)
- **Archivo afectado:** `scripts/systems/VillageManager.gd` (`6,306` → `6,164` líneas)
- **Cambios aplicados (100% preservación de mecánicas y compatibilidad de guardado):**
  1. Añadidos los constructores modales `_build_modal_base()` y `_add_modal_btn()` en `_setup_Interactive_modals_ui()` para unificar los 5 paneles interactivos (Morgue, Policía, Tablón, Negocios y Capilla).
  2. Añadido `_register_authority_npc()` para unificar el alta y registro de vacantes del Médico (`Dr. Valen`), Comisario (`Vane`) y Oficial (`Rodric`).
  3. Añadido `_free_transient_npc()` en `load_economy_save_dict()` para eliminar la triplicación del desmontaje de mercaderes/inquisidor al cargar partida.

---

## Iteración 7 (Compactación Integral de Todo el Proyecto) — Commit Base para Rollback: `f20aed7` (Base pre-compactación: `b01eb18`)

### 9. Compactación Profunda de 23 Archivos GDScript (`27,055` → `22,745` líneas totales, `-4,310` líneas eliminadas)
- **Resumen de reducción por archivo (respecto a `b01eb18`):**
  1. `scripts/systems/VillageManager.gd`: `6,306` → `5,155` líneas (**`-1,151` líneas**)
  2. `scripts/enemies/VillageNPC.gd`: `4,069` → `3,226` líneas (**`-843` líneas**)
  3. `scripts/systems/SimpleInventory.gd`: `1,076` → `459` líneas (**`-617` líneas**)
  4. `scripts/obstacles/CampSite.gd`: `1,036` → `810` líneas (**`-226` líneas**)
  5. `scripts/ui/TavernGamesUI.gd`: `1,582` → `1,370` líneas (**`-212` líneas**)
  6. `scripts/systems/ai/EnemyAI.gd`: `746` → `542` líneas (**`-204` líneas**)
  7. `scenes/ui_root.gd`: `734` → `573` líneas (**`-161` líneas**)
  8. `scripts/systems/EcosystemManager.gd`: `594` → `453` líneas (**`-141` líneas**)
  9. `scripts/Player.gd`: `828` → `697` líneas (**`-131` líneas**)
  10. `scripts/enemies/WildAnimal.gd`: `1,295` → `1,189` líneas (**`-106` líneas**)
  11. `scripts/obstacles/FishingSpot.gd`: `466` → `386` líneas (**`-80` líneas**)
  12. `scenes/npc.gd`: `413` → `352` líneas (**`-61` líneas**)
  13. `scripts/obstacles/ChickenCoop.gd`: `666` → `605` líneas (**`-61` líneas**)
  14. `scripts/ui/ToolWheelUI.gd`: `312` → `253` líneas (**`-59` líneas**)
  15. `scripts/PlayerCombatController.gd`: `420` → `373` líneas (**`-47` líneas**)
  16. `scripts/systems/WorldClock.gd`: `383` → `337` líneas (**`-46` líneas**)
  17. `scripts/enemies/DummyEnemy.gd`: `376` → `340` líneas (**`-36` líneas**)
  18. `scripts/enemies/DomesticPet.gd`: `613` → `581` líneas (**`-32` líneas**)
  19. `scenes/dialogue_manager.gd`: `346` → `315` líneas (**`-31` líneas**)
  20. `scripts/obstacles/FarmPlot.gd`: `388` → `361` líneas (**`-27` líneas**)
  21. `scripts/systems/GameManager.gd`: `340` → `321` líneas (**`-19` líneas**)
  22. `scripts/ui/ValleyMapUI.gd`: `398` → `383` líneas (**`-15` líneas**)
  23. `scripts/obstacles/HarvestableNode.gd`: `313` → `309` líneas (**`-4` líneas**)
- **Verificación:** `flatpak run org.godotengine.Godot --headless -d --quit-after 3` → **0 errores y 0 warnings**.
