# Informe de Cierre — Bloque A4: Amputación también para el jugador

**Fecha:** 2026-11-06  
**Encargo:** `docs/ENCARGO_A4_AMPUTACION.md`

---

## 1. Archivos tocados y funciones modificadas o creadas

### `scripts/systems/VillageIllness.gd`
- `player_gangrene(vm)`: devuelve el diccionario activo en `VillageNeeds.state(vm)["player_gangrene"]` (o `{}` si no hay aviso).
- `_check_player_gangrene(vm, notify_hint)`: revisa las heridas de `_health_comp_of(vm, "player")` en busca de alguna herida en un miembro de `LIMB_LABELS` con `infection >= 65.0` que no esté ya amputado (`get_amputation(vm, "player")`). Si no hay ninguna (o la infección bajó de 65), borra `"player_gangrene"` del estado. Si la hay y no estaba ya avisada para ese miembro, guarda `{limb, limb_label, day}` en `VillageNeeds.state(vm)["player_gangrene"]` y avisa una sola vez con `show_hint("El médico ha oído que tu herida del %s se ha gangrenado. Ve al hospital antes de que sea tarde." % limb_lbl)`.
- `daily(vm)`: llama a `_check_player_gangrene(vm, true)` en la ronda diaria sin amputar automáticamente al jugador.
- `add_dialogue_choices(vm, npc, _diag, ch_arr)`: actualiza el estado con `_check_player_gangrene(vm, false)` y, si `player_gangrene(vm)` está activo, inserta arriba del todo (`insert(0, ...)`) las dos opciones:
  1. `«🪚 Amputar el %s gangrenado (te salva la vida)»` (`action`: `"illness_amputate_self"`).
  2. `«No, me la quedo»` (`action`: `"illness_refuse_amputate"`).
- `on_player_action(vm, npc, action_id, inv)`:
  - `"illness_amputate_self"`: llama a `amputate(vm, "player", limb_key, "gangrena por infección")` (gratis y sin doble `E`), borra `"player_gangrene"`, añade a la crónica con `VillageChronicle.add` `«El médico amputó el %s del forastero»` y muestra la frase corta del médico.
  - `"illness_refuse_amputate"`: mantiene `"player_gangrene"` activo y el médico responde `«Tú sabrás. Si la fiebre sube, ya no habrá nada que cortar.»`.
- `amputate(vm, key, limb_id, reason)` e `install_prosthetic(vm, key, prosthetic_name)`: cuando `key == "player"`, marcan `pl.avatar_3d.mark_appearance_dirty()` para refrescar al instante el muñeco 3D del jugador.

### `scripts/visuals/CharacterAvatar3D.gd`
- `_resolve_entity_limb_states(ent)`: corregida la lectura de `vm.needs_state["amputations"][k]` para usar las claves reales que guardan `VillageIllness.amputate` e `install_prosthetic` (`rec.get("limb", ...)` y `str(rec.get("prosthetic", "")) != ""`), ya que antes buscaba `"region"` y `"has_prosthetic"` y por eso siempre caía por defecto en `"left_leg"` sin detectar brazos ni prótesis instaladas.

### `tools/tests/verify_all.gd`
- Añadido al final de `_initialize()` el bloque «A4 amputación» (`Block A4 (Player Gangrene Warning, Doctor Amputation Choice & Prosthetic Capacity Recovery)`):
  1. Con una herida del jugador en `"left_leg"` al `70 %` de infección, `VillageIllness.daily(vm)` no amputa al jugador y deja activo `VillageIllness.player_gangrene(vm)`.
  2. Al elegir `"illness_amputate_self"` en `VillageIllness.on_player_action`, queda registrada la amputación de `"left_leg"`, se borra el aviso y `get_moving_capacity()` baja.
  3. Al llamar a `VillageIllness.install_prosthetic(vm, "player")`, `get_moving_capacity()` sube respecto al valor sin prótesis.

---

## 2. Comprobación numérica de capacidades (`HealthComponent`) y visualización 3D

### A. Cuánto bajan `get_moving_capacity()` y `get_manipulation_capacity()` al amputar y con prótesis
En `scripts/systems/combat/HealthComponent.gd` (`get_capacities`, `get_moving_capacity`, `get_manipulation_capacity`, `get_region_ratio`):
- **Topes sanos (`REGION_DEFS`):**
  - Piernas (`left_leg`, `right_leg`): `max_hp = 45.0` cada una (`get_region_ratio` = `1.0`).
  - Brazos (`left_arm`, `right_arm`): `max_hp = 40.0` cada uno (`get_region_ratio` = `1.0`).
- **1. Sano (sin dolor, fiebre ni fracturas):**
  - `get_moving_capacity()` = `((1.0 + 1.0) * 0.5)` = **`1.00` (100 %)** → velocidad normal al caminar (`120.0` px/s en `PlayerMovementController._handle_input`).
  - `get_manipulation_capacity()` = `((1.0 + 1.0) * 0.5)` = **`1.00` (100 %)** → cadencia normal de golpe (`attack_timer = 0.36 / 1.00 = 0.36` s en `PlayerCombatController.attack`).
- **2. Con un miembro amputado (`VillageIllness.amputate` → `region_hp[limb] = 0.0` y se eliminan las heridas de ese miembro):**
  - **Pierna amputada** (`0.0 / 45.0 = 0.0`, la otra pierna en `1.0`):
    - `get_moving_capacity()` baja de `1.00` a **`0.50` (50 %)** (con suelo mínimo de `0.32` si además hay dolor o fiebre de otras heridas).
    - Efecto real: `PlayerMovementController._handle_input` multiplica `current_speed *= mov_cap`, pasando de `120.0` px/s a **`60.0` px/s** al caminar (y de `200.0` a `100.0` px/s al correr).
  - **Brazo amputado** (`0.0 / 40.0 = 0.0`, el otro brazo en `1.0`):
    - `get_manipulation_capacity()` baja de `1.00` a **`0.50` (50 %)** (con suelo mínimo de `0.35`).
    - Efecto real: `PlayerCombatController.attack` calcula `attack_timer = 0.36 / maxf(0.35, manip_atk)`, pasando de `0.36` s a **`0.72` s** entre ataques (golpeas a la mitad de velocidad; con arco, `0.25 / 0.50 = 0.50` s y la tensión efectiva se multiplica por `0.50`).
- **3. Con prótesis instalada (`VillageIllness.install_prosthetic`):**
  - `install_prosthetic` fija `hc.region_hp[limb_key] = 40.0 if limb_key.ends_with("arm") else 45.0`, que equivale al `100 %` del `max_hp` de la región (`40.0 / 40.0 = 1.0` en brazo y `45.0 / 45.0 = 1.0` en pierna).
  - Por tanto, con la prótesis instalada:
    - `get_moving_capacity()` sube de **`0.50` (50 %)** de vuelta a **`1.00` (100 %)**.
    - `get_manipulation_capacity()` sube de **`0.50` (50 %)** de vuelta a **`1.00` (100 %)**.

### B. Visualización en el muñeco 3D (`CharacterAvatar3D`)
- `CharacterAvatar3D._resolve_entity_limb_states` ya incluía la clave `"player"` cuando `is_player_avatar == true`, pero leía `rec.get("region")` y `rec.get("has_prosthetic")` en vez de `"limb"` y `"prosthetic"`. Tras corregirlo en `_resolve_entity_limb_states`, tanto el jugador como los vecinos pasan el estado `"amputated"` o `"prosthetic"` del miembro exacto (`left_arm_state`, `right_arm_state`, `left_leg_state`, `right_leg_state`) a `CharacterRig3D.apply_character_appearance`.

---

## 3. Verificación ejecutada

1. **Arranque sin errores:**
   - `timeout 60 flatpak run org.godotengine.Godot --headless --path . --quit` → código de salida `0`.
2. **Suite completa `verify_all.gd` (una sola ejecución al cierre):**
   - `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s res://tools/tests/verify_all.gd` → código de salida `0`, incluyendo `Block A4 (Player Gangrene Warning, Doctor Amputation Choice & Prosthetic Capacity Recovery) OK`.
