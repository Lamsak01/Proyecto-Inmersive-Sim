# Plan y Log de Simplificación y Optimización del Proyecto (Immersive Sim 2D)

Este documento sirve como hoja de ruta y registro de progreso paso a paso. Si la sesión se interrumpe o se cambia de modelo de IA, el siguiente modelo debe leer este archivo, verificar qué pasos están marcados como `[x]` (completados) y continuar desde el primer paso marcado como `[ ]` (pendiente).

---

## Objetivo General
1. **Mantener activos únicamente los sistemas centrales:**
   - **Movimiento:** `Player.gd`, `PlayerMovementController.gd`, `StaminaComponent.gd`.
   - **Combate (con Sangrado y Stun, SIN Armadura):** `PlayerCombatController.gd`, `HealthComponent.gd` (vida + sangrado/debilidad), `StunComponent.gd`, `Hitbox.gd`, `Hurtbox.gd`, `DamageData.gd`, `WeaponData.gd`, `CombatConstants.gd`, `DummyEnemy.gd`.
   - **Sigilo:** `EnemyAI.gd`, `VisionCone2D.gd`, `AlertIndicator.gd`, `DetectionArea.gd`.
   - **Sistema de Diálogo:** `dialogue_manager.gd`, `npc.gd`, UI de diálogo.
   - **Sistema de Misiones / Objetivos:** `ObjectiveManager.gd`, `Objective.gd`, `ObjectiveHUD.gd`, `ObjectiveHUD.tscn`, `resources/objectives/`.
   - **Objetos Destructibles y Persistencia en sesión:** `DestructibleObject.gd`, `Crate.tscn`, `Barrel.tscn`, `WeakWall.tscn`, `GameManager.gd` (solo flags en memoria).

2. **Eliminar el Sistema de Guardado actual:**
   - Eliminar `scripts/systems/GameState.gd` y `scripts/tests/TestPersistence.gd`.
   - Quitar `GameState` de los Autoloads en `project.godot`.
   - Limpiar `GameManager.gd` para que mantenga flags de persistencia en memoria durante la sesión pero sin guardar/cargar archivos JSON en disco (`user://game_flags.json`).

3. **Archivar temporalmente los sistemas secundarios en `archived_systems/` (con `.gdignore` para que Godot no los cargue pero queden intactos para el futuro):**
   - `archived_systems/combat_armor/`: `ArmorComponent.gd`, `EquipmentComponent.gd`.
   - `archived_systems/power_system/`: `addons/powergrid/`, `scripts/power/`, `scenes/power/`, `ConductiveArea.gd`.
   - `archived_systems/grid_inventory/`: `GridInventory.gd`, `InventoryUI.gd`, `InventoryItemUI.gd`, `InventoryItem.gd`, `ItemDatabase.gd`, `InventoryTestHelper.gd`, `scenes/ui/InventoryUI.tscn`, `resources/items/`.
   - `archived_systems/interiors_and_teleporters/`: `SceneTeleporter.gd`, `scenes/Buildings/house_1.tscn`, `scenes/Buildings/House1Interior.tscn`, `House_Test.tscn`, `scenes/world/`, `scripts/world/OverheadFader.gd`, `scenes/key.gd`, `scenes/door_interact_collision.gd`.
   - `archived_systems/unused_assets_and_tools/`: Archivos `.rar`/`.zip` y carpetas duplicadas de `assests/archives/` y `assests/drive-download-20260210T024726Z-1-001/`, además de `scenes/tools/` y `scripts/tools/`.

4. **Optimizar el rendimiento a fondo:**
   - Evitar `queue_redraw()` innecesario en `VisionCone2D.gd` y `DummyEnemy.gd`.
   - Optimizar `EnemyAI.gd` (filtrar distancia antes del raycast auditivo, corregir caché de *Context Steering* usando producto punto en vez de igualdad exacta de vectores, limitar actualizaciones de `NavigationAgent2D` con un timer en vez de cada frame físico, cachear referencia al jugador).
   - Añadir navegación funcional (`scripts/World.gd`) a la escena principal `scenes/World.tscn`.
   - Limpiar `scenes/ui/PlayerHUD.tscn` (que tenía 29,000 líneas de TileSets copiados por error).
   - Cambiar el renderizador en `project.godot` de `Forward Plus` a `gl_compatibility` para máximo rendimiento en 2D Pixel Art.

---

## Lista de Pasos Detallada (Checklist de Progreso)

### PASO 1: Crear estructura de archivo (`archived_systems/`) y eliminar sistema de guardado antiguo
- [x] **1.1.** Crear directorio `archived_systems/` con un archivo `.gdignore` vacío (para que Godot ignore esos recursos al abrir/ejecutar) y un `README.md` explicativo.
- [x] **1.2.** Eliminar `scripts/systems/GameState.gd` (+ `.uid`) y `scripts/tests/TestPersistence.gd` (+ `.uid`).
- [x] **1.3.** Simplificar `scripts/systems/GameManager.gd` para que funcione en memoria (`game_data: Dictionary`) sin lectura/escritura en disco.
- [x] **1.4.** Mover a `archived_systems/` los módulos:
  - Armadura (`ArmorComponent.gd`, `EquipmentComponent.gd`).
  - Energía (`addons/powergrid/`, `scripts/power/`, `scenes/power/`, `ConductiveArea.gd`).
  - Inventario de cuadrícula (`GridInventory.gd`, `InventoryUI.gd`, `InventoryItemUI.gd`, `InventoryItem.gd`, `ItemDatabase.gd`, `InventoryTestHelper.gd`, `scenes/ui/InventoryUI.tscn`, `resources/items/`).
  - Interiores/Teletransporte/Llaves (`SceneTeleporter.gd`, `scenes/Buildings/`, `House_Test.tscn`, `scenes/world/`, `OverheadFader.gd`, `scenes/key.gd`, `scenes/door_interact_collision.gd`).
  - Archivos `.rar`/`.zip` duplicados de `assests/archives/` y `assests/drive-download-20260210T024726Z-1-001/`.

### PASO 2: Actualizar `project.godot` y Autoloads
- [x] **2.1.** En `project.godot`, dejar solo los Autoloads activos necesarios:
  - `AudioManager="*res://scripts/systems/AudioManager.gd"`
  - `GameManager="*res://scripts/systems/GameManager.gd"`
  - `ObjectiveManager="*res://scripts/systems/game_objectives/ObjectiveManager.gd"`
  *(Quitar `PowerManager`, `ItemDatabase`, `GameState`)*.
- [x] **2.2.** Cambiar el método de renderizado a `gl_compatibility` en `project.godot` para optimizar el motor 2D.

### PASO 3: Desacoplar Jugador, Combate, Enemigos, NPC y Armas de los sistemas archivados
- [x] **3.1.** Actualizar `scripts/Player.gd`:
  - Quitar referencias a `GridInventory`, `ArmorComponent`, `EquipmentComponent`, `GameState` y `keys`.
  - Mantener `HealthComponent` (vida + sangrado/debilidad), `StunComponent`, `StaminaComponent`, `Hurtbox`, `PlayerMovementController`, `PlayerCombatController` y diálogo.
  - Permitir equipar armas directamente con las teclas `1` (Espada - `CUT` con probabilidad de sangrado) y `2` (Martillo - `BLUNT` para romper barriles/muros y aplicar stun), y equipar la Espada por defecto al iniciar o al recoger `WeaponPickup`.
- [x] **3.2.** Actualizar `resources/weapons/Sword.tres` para que tenga `bleed_chance = 0.5` (así se puede probar el sangrado en combate) y verificar `Hammer.tres` (`type = 1` BLUNT).
- [x] **3.3.** Simplificar `scenes/items/WeaponPickup.gd` para que al interactuar equipe/desbloquee el arma en el jugador y actualice el objetivo `obj_find_sword` en `ObjectiveManager`, sin depender de `GridInventory` ni `InventoryItem`.
- [x] **3.4.** Actualizar `scripts/enemies/DummyEnemy.gd`, `scenes/enemies/DummyEnemy.tscn` y `scenes/enemies/FastEnemy.tscn`:
  - Quitar `ArmorComponent`.
  - Añadir `StunComponent` (o soporte de stun/sangrado en enemigos) para que el jugador vea el efecto del stun y sangrado en ellos.
- [x] **3.5.** Actualizar `scenes/npc.gd` y `scenes/ui_root.gd`:
  - Quitar `ArmorComponent` de `npc.gd`.
  - Quitar referencias obligatorias a `InventoryUI` en `scenes/ui_root.gd`, y añadir un indicador visual opcional de Sangre/Stun o arma activa en el HUD, además de iniciar los objetivos de prueba (`obj_find_sword` y `obj_kill_frogs`).

### PASO 4: Optimización Profunda de Rendimiento (Scripts)
- [x] **4.1.** Optimizar `scripts/ui/VisionCone2D.gd` y `scripts/enemies/DummyEnemy.gd`:
  - En `VisionCone2D.gd`, usar `is_equal_approx` en los setters de `radius` y `angle_deg` y comparar `color` antes de llamar a `queue_redraw()`.
  - En `DummyEnemy.gd`, cachear la referencia al jugador (`_player_ref`) en lugar de buscar en el árbol cada frame, y actualizar el cono solo cuando cambie el estado de sigilo.
- [x] **4.2.** Optimizar `scripts/systems/ai/EnemyAI.gd`:
  - Cachear la referencia al jugador (`_cached_player`).
  - En `_process_idle`, `_process_search` y `_process_return`, verificar primero `if distance_sq <= hearing_range * hearing_range:` **antes** de lanzar el raycast físico `calculate_auditory_radius(...)`, y añadir un throttle (`hearing_timer`) para no lanzar raycasts de audio cada frame.
  - En `_get_avoidance_direction()`, cambiar `if desired_dir == cached_avoidance_input_dir` por `if desired_dir.dot(cached_avoidance_input_dir) > 0.98 and avoidance_timer > 0:` para que el caché de los 8 raycasts de *Context Steering* funcione realmente cuando el enemigo se mueve.
  - Añadir un `nav_timer` (`0.2s`) en `_set_movement_target()` para no recalcular la ruta de `NavigationAgent2D` a 60 FPS.
- [x] **4.3.** Optimizar `scripts/PlayerCombatController.gd`:
  - Evitar llamar repetidamente a `show_prompt()` en cada frame cuando `new_target == current_prompt_target`, y limitar la comprobación de *stealth takedown* o usar señales/throttling ligero.

### PASO 5: Limpieza de Escenas (`World.tscn`, `Player.tscn`, `PlayerHUD.tscn`) y Verificación
- [x] **5.1.** Limpiar `scenes/World.tscn`:
  - Adjuntar `scripts/World.gd` al nodo raíz `World` para que exista la región de navegación.
  - Eliminar nodos de sistemas archivados (`Systems/PowerSystem`, `Systems/InventoryTestHelper`, `Environment/Door`, `Items/Key`, `Entities/House1`, `Entities/PlayerGood/GridInventory`, `Entities/PlayerGood/ArmorComponent`, `Entities/PlayerGood/EquipmentComponent`, `Entities/Guia/ArmorComponent`, `UI/UIRoot/InventoryUI`).
  - Limpiar `scenes/Entities/Player.tscn` y `scenes/ui/PlayerHUD.tscn` para que no tengan referencias rotas ni TileSets basura incrustados.
- [x] **5.2.** Verificar que no existan referencias rotas a scripts o escenas archivadas en ningún archivo activo del proyecto.
