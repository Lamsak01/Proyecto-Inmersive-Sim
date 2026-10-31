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
