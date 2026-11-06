# Informe de entrega — Antigravity (`COMBATE-1`: Rodar con Espacio, parar con Q y golpes enemigos con aviso)

## 1. Archivos tocados y qué se hizo en cada uno

- **`scripts/PlayerMovementController.gd`**:
  - Añadidas las constantes `ROLL_DURATION` (`0.35` s), `ROLL_INVULN_DURATION` (`0.25` s), `ROLL_DISTANCE` (`50.0` px), `ROLL_COOLDOWN` (`0.60` s) y `ROLL_STAMINA_COST` (`18.0`), junto con las variables de estado `roll_timer`, `roll_invuln_timer`, `roll_cooldown_timer` y `roll_direction`.
  - Añadidas las funciones `is_rolling()`, `is_roll_invulnerable()`, `get_roll_progress()` y `start_roll(dir_override: Vector2 = Vector2.ZERO) -> bool`.
  - En `_unhandled_input(event)`, pulsar `KEY_SPACE` invoca `start_roll()`. No permite rodar si el jugador va montado a caballo (`is_mounted`), está aturdido, en diálogo/menú/pesca/tronco o sin energía suficiente en `StaminaComponent.use_stamina(ROLL_STAMINA_COST)`. Al iniciar la rodada rompe el sigilo (`is_stealthing = false`).
  - En `_physics_process(delta)`, mientras `roll_timer > 0.0`, desplaza al jugador en `roll_direction` a `ROLL_DISTANCE / ROLL_DURATION` colisionando con muros mediante `player.move_and_slide()`.

- **`scripts/PlayerCombatController.gd`**:
  - Añadidas las constantes `PARRY_WINDOW` (`0.20` s), `PARRY_COOLDOWN` (`0.50` s) y `PARRY_STAGGER_DURATION` (`0.80` s), junto con `parry_window_timer` y `parry_cooldown_timer`.
  - Añadidas las funciones `_physics_process(delta)`, `is_parrying()`, `start_parry() -> bool` y `resolve_parry_hit(attacker: Node) -> void`.
  - En `_unhandled_input(event)`, se conserva la prioridad del derribo no letal en sigilo con `KEY_Q` cuando `is_instance_valid(current_prompt_target)` es cierto; solo cuando no hay objetivo de sigilo válido, pulsar `KEY_Q` llama a `start_parry()`.
  - Si expira `parry_window_timer` sin haber parado un golpe, entra en `parry_cooldown_timer = PARRY_COOLDOWN` (`0.50` s). Si entra un golpe cuerpo a cuerpo durante la ventana, `resolve_parry_hit(attacker)` limpia la ventana y el enfriamiento e invoca `attacker.call("apply_parry_stagger", PARRY_STAGGER_DURATION)`.

- **`scripts/Player.gd`**:
  - Añadidos los envoltorios `start_roll(dir_override: Vector2 = Vector2.ZERO) -> bool`, `is_rolling() -> bool`, `is_roll_invulnerable() -> bool`, `start_parry() -> bool` y `is_parrying() -> bool`.
  - En `take_damage(data: DamageData)`:
    - Si `is_roll_invulnerable()` es cierto, ignora todo el daño y muestra `"💨 ¡ESQUIVADO!"`.
    - Si `is_parrying()` es cierto y el impacto no es un proyectil a distancia (`not is_ranged_hit`), anula el daño, llama a `combat_ctrl.call("resolve_parry_hit", data.source)` y muestra `"🛡️ ¡PARADA!"`.

- **`scripts/systems/combat/DamageData.gd` y `scripts/systems/combat/ArrowProjectile.gd`**:
  - Añadido `is_ranged_projectile: bool = false` en `DamageData` (copiado en `DamageData.copy()`) y marcado a `true` en `ArrowProjectile._ready()`, `ArrowProjectile._on_area_entered(area)` y `ArrowProjectile._on_body_entered(body)` (así como en `VillageNPC._fire_police_pistol(player)`), de modo que flechas y balas no se pueden parar con `Q`.

- **`scripts/enemies/VillageNPC.gd`**:
  - Añadidas `_melee_windup_timer`, `_police_baton_windup_timer`, `_stagger_timer` y la función `apply_parry_stagger(duration: float = 0.8) -> void`.
  - En `_process_hostile_combat(delta)` y `_process_police_law_enforcement(delta, vm)`, antes de dar cada golpe cuerpo a cuerpo se inicia un aviso de `0.40` s (`_melee_windup_timer = 0.40` / `_police_baton_windup_timer = 0.40`) con destello en `sprite`, texto flotante `"❗"` y `trigger_action_animation(0.45)`. Al terminar los `0.40` s, el daño solo se aplica si el jugador sigue dentro del alcance cuerpo a cuerpo (`<= 34.0` px / `<= 38.0` px).

- **`scripts/enemies/Raider.gd`**:
  - Añadidas `_windup_t`, `stagger_timer` y la función `apply_parry_stagger(duration: float = 0.8) -> void`.
  - En `_physics_process(delta)`, cuando el asaltante está en rango cuerpo a cuerpo (`d <= MELEE_RANGE`) y `_attack_t <= 0.0`, inicia un aviso de `0.40` s (`_windup_t = 0.40`, `attack_anim = 1.0` y destello en `sprite`) y solo ejecuta `_hit(target)` al agotarse `_windup_t` si `target` sigue a `<= MELEE_RANGE + 6.0` px.

- **`scripts/enemies/DomesticPet.gd`**:
  - Añadidas `_bite_windup_timer`, `stagger_timer` y la función `apply_parry_stagger(duration: float = 0.8) -> void`.
  - En `_physics_process(delta)` (bloque `is_hostile and pet_type == PetType.DOG`), antes de morder inicia `_bite_windup_timer = 0.40` con destello y `"❗"`, y al terminar los `0.40` s solo aplica el mordisco si el jugador sigue a `<= 22.0` px.

- **`scripts/enemies/WildAnimal.gd`**:
  - Añadidas `boar_melee_windup`, `stagger_timer` y la función `apply_parry_stagger(duration: float = 0.8) -> void`.
  - En `_start_boar_aggro(attacker)` y `_process_boar_charge_attack(delta)`, tanto la preparación de embestida (`boar_charge_windup = 0.40`) como el golpe cuerpo a cuerpo a corta distancia (`boar_melee_windup = 0.40`) avisan durante `0.40` s con `"🐗❗"` y destello antes de llamar a `_deliver_boar_ram_hit(boar_aggressor)`.

- **`tools/bake_character_animations.gd`, `assests/curated_3d/animations/ual_male.res`, `assests/curated_3d/animations/ual_female.res`, `scripts/visuals/CharacterRig3D.gd`, `scripts/visuals/CharacterAvatar3D.gd` y `scripts/visuals/AnimalModel3D.gd`**:
  - **Animaciones 3D elegidas:** se comprobó que `AL_Standard.fbx` (Quaternius UAL1) incluye la animación `"Roll"` y `UAL2_Standard.glb` (Quaternius UAL2) incluye `"Sword_Block"`. Se añadieron `"roll": [1, "Roll", false]` y `"block": [2, "Sword_Block", false]` al diccionario `PICK` de `tools/bake_character_animations.gd` y se regeneraron `ual_male.res` y `ual_female.res` (30 animaciones por biblioteca). Además, en `CharacterRig3D._apply_skeleton_pose(_delta)` se añadió el respaldo procedural para `AnimState.ROLL` (agachado y giro frontal de 360° en `RealCharRoot`) y `AnimState.BLOCK` (brazos en guardia).
  - En `CharacterAvatar3D._sync_pose_and_tint(delta)` se pasan `is_rolling`, `roll_progress`, `is_parrying` y el progreso del aviso de ataque de los NPC (`_melee_windup_timer` / `_police_baton_windup_timer`) a `CharacterRig3D.update_pose(delta, state_dict)`.
  - En `AnimalModel3D._update_animation(delta, lying, just_shown)`, los animales con modelo `.glb` reproducen su clip `"Attack"` mientras están en su aviso de `0.40` s (`_bite_windup_timer`, `boar_charge_windup`, `boar_melee_windup`, `_windup_t`).

- **`scenes/ui_root.gd`**:
  - En `_on_clock_time_updated(_day, _hour, _minute)`, añadido `[Espacio] Rodar · [Q] Parar` a `clock_sub_label.text`.

- **`tools/tests/verify_all.gd`**:
  - Añadido el bloque `Block COMBATE-1` (`COMBATE-1.1` a `COMBATE-1.6`) que verifica: invulnerabilidad durante la rodada, imposibilidad de rodar sin energía, parada a tiempo con desequilibrio de `~0.8` s al atacante, parada fuera de tiempo (y que las flechas no se pueden parar), golpe enemigo que entra tras los `~0.4` s de aviso y no al instante, y prioridad del derribo no letal en sigilo con `Q` cuando `current_prompt_target` es válido.

- **Documentación**:
  - Actualizados `CHANGELOG.md`, `docs/HANDOFF.md` (§7), `docs/REGISTRO_TRABAJO.md`, `GameVault/02_Sistemas/Armaduras, Sigilo y Arcabuz.md`, `GameVault/05_Roadmap_y_Lore/Tablero.md` y `GameVault/06_Diario/2026-11-06.md`.
