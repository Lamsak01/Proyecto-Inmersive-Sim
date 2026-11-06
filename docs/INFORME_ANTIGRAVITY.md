# Informe de Antigravity para el Supervisor (Claude Code) — Bloque ANIM-1

> Fecha: 2026-11-06
> Alcance ejecutado: **Bloque ANIM-1** (`docs/ENCARGO_ANTIGRAVITY.md` §2: calibración de zancada de «walk» y «run» para eliminar el patinado de los pasos en 3D y giro de 180° de armas y herramientas en la mano de jugador y vecinos).

---

## 1. Qué se hizo exactamente

### 1.1. Pasos que patinan — Medición de zancada a escala de escenario y cálculo en `_pick_clip`
- **Medición sobre el esqueleto real (`ual_male.res`, Quaternius UAL1):**
  - Escala del muñeco en el escenario: `CharacterAvatar3D.STAGE_K = 0.40` y `WorldStage3D.WORLD_SCALE = 0.02` (`1` unidad del muñeco = `0.40` unidades 3D = `20.0 px` del mapa 2D), con `RealCharRoot.scale = Vector3(0.88, 0.88, 0.88)` en `CharacterRig3D._rebuild_real_quaternius_character()`.
  - **`"walk"` (`Walk_Loop`, duración `1.333 s`):** excursión anteroposterior del pie (`ball_l`) $\Delta Z = 0.7215\text{ u\_rig}$ $\rightarrow$ zancada de ciclo completo ($2 \times \Delta Z$) = `1.443 u_rig` = **`28.86 px`** (`WALK_CYCLE_PX = 28.86`). A `speed_scale = 1.0`, la velocidad nativa del ciclo es **`WALK_BASE_PX_S = 21.65 px/s`** (`28.86 px / 1.3333 s`).
  - **`"run"` (`Jog_Fwd_Loop`, duración `0.933 s`):** excursión anteroposterior del pie (`ball_l`) $\Delta Z = 1.310\text{ u\_rig}$ $\rightarrow$ zancada de ciclo completo ($2 \times \Delta Z$) = `2.620 u_rig` = **`52.40 px`** (`RUN_CYCLE_PX = 52.40`). A `speed_scale = 1.0`, la velocidad nativa del ciclo es **`RUN_BASE_PX_S = 56.15 px/s`** (`52.40 px / 0.9333 s`).
  - **`"carry"` (`Carry_Walk_Loop`, duración `2.000 s`):** zancada de ciclo completo = `1.437 u_rig` = **`28.74 px`** $\rightarrow$ velocidad nativa **`CARRY_BASE_PX_S = 14.37 px/s`**.
- **Cálculo de la velocidad de reproducción en `CharacterRig3D._pick_clip()`:**
  - A partir de `real_px_s = _speed_ratio * 110.0` y del factor de escala infantil `scale_k = 0.72 if _is_child else 1.0`:
    - Si `_speed_ratio > 1.35`, devuelve `["run", clampf(real_px_s / (RUN_BASE_PX_S * scale_k), 0.6, 4.0)]`.
    - En caso contrario, devuelve `["walk", clampf(real_px_s / (WALK_BASE_PX_S * scale_k), 0.5, 5.5)]`.
    - En `AnimState.CARRY`, devuelve `["carry", clampf(carry_px_s / (CARRY_BASE_PX_S * carry_k), 0.5, 5.5)]`.
  - En `CharacterRig3D.update_pose()`, se rebajó el suelo de `maxf(0.5, spd)` a `maxf(0.15, spd)` al llamar a `update_animation(...)` para no acelerar artificialmente el paso lento/sigilo; y en `CharacterAvatar3D._sync_pose_and_tint()` y `BanditModel3D._process()` se amplió el tope de `speed_ratio` de `1.6` a `2.5` para cubrir el sprint completo (`200 px/s`).

### 1.2. Armas y herramientas al revés — Giro de 180° en `CharacterRig3D._build_real_curated_tools()`
- **Causa raíz:** en el esqueleto Quaternius, el hueso `hand_r` tiene su eje `+Z` apuntando hacia delante y arriba (fuera del puño por el lado del pulgar) y su eje `+Y` a lo largo de los dedos hacia delante/abajo. Sin embargo, `WeaponHolder` tenía `rotation_degrees = Vector3(0.0, 90.0, -90.0)`, cuya matriz (`Ry(90°) * Rz(-90°)`) enviaba el eje `+Y` de los modelos de arma/herramienta (el asta o la hoja desde la empuñadura) hacia **`-Z` de `hand_r`** (180° hacia atrás) y el eje `+X` (el filo o cañón) hacia **`-Y` de `hand_r`**.
- **Corrección aplicada en `CharacterRig3D._build_real_curated_tools()`:**
  - `WeaponHolder.rotation_degrees` pasa de `Vector3(0.0, 90.0, -90.0)` a **`Vector3(0.0, 90.0, 90.0)`**, invirtiendo 180° tanto el eje `+Y` del modelo (que ahora apunta hacia `+Z` de `hand_r`, delante y arriba) como el eje `+X` del modelo (que ahora apunta hacia `+Y` de `hand_r`, en la dirección del golpe o disparo):
    - **Espada y daga (`"sword"`, `"blade"`, `"dagger"`, `"knife"`):** hoja hacia delante y arriba.
    - **Hacha, pico, martillo y hoz (`"axe"`, `"wood_axe"`, `"pickaxe"`, `"hammer"`, `"sledgehammer"`, `"smith_hammer"`, `"scythe"`, `"sickle"`, `"hoe"`):** asta hacia delante/arriba y filo/cabeza hacia el frente de golpeo.
    - **Caña y lanza (`"fishing_rod"`, `"staff"`, `"guard_spear"`, `"spear"`):** asta y punta hacia delante y arriba (incluidos los guardias como Rodric).
    - **Arco (`"bow"`):** añadido `model_node.rotation_degrees = Vector3(0.0, 180.0, 0.0)` para que la madera curva apunte hacia delante y la cuerda hacia el arquero.
    - **Arcabuz / pistola (`"flintlock"`, `"pistol"`, `"arquebus"`):** eliminado el giro extra `Vector3(0.0, 90.0, 0.0)` que desviaba el cañón lateralmente; con `WeaponHolder` en `(0, 90, 90)`, el cañón (`+X` de `Pistol_1.obj`) apunta directo hacia delante al apuntar (`"aim"`/`"shoot"`) y el fogonazo `muzzle_flash_node` queda en la boca del cañón (`Vector3(0.42, 0.14, 0.0)`).
    - **Regadera y farol en mano derecha (`"watering_can"`, `"lantern"`):** girados con `Vector3(0.0, 0.0, 90.0)` y desplazados (`Vector3(0.26..0.28, 0.0, 0.0)`) para que cuelguen derechos desde el asa superior.
  - En la mano izquierda (`hand_l`), `l_holder.rotation_degrees` pasa de `Vector3(0.0, 90.0, 90.0)` a **`Vector3(0.0, -90.0, -90.0)`** (con el escudo `"shield"` mirando hacia fuera del brazo izquierdo, y el `"lantern"` girado `Vector3(0.0, 0.0, -90.0)` con `position = Vector3(-0.28, 0.0, 0.0)` para colgar vertical de la mano).

### 1.3. Capturas comparativas (`docs/capturas_anim1/`)
- Generadas con `tools/screenshot_3d.gd` en el punto `"cerca"` a las `10` h:
  - Antes: `docs/capturas_anim1/cerca_antes_10h.png`
  - Después: `docs/capturas_anim1/cerca_despues_10h.png`

---

## 2. Archivos modificados

| Archivo | Funciones / métodos tocados |
|---|---|
| `scripts/visuals/CharacterRig3D.gd` | `_build_real_curated_tools`, `update_pose`, `_pick_clip` (y constantes `WALK_CYCLE_PX`, `WALK_BASE_PX_S`, `RUN_CYCLE_PX`, `RUN_BASE_PX_S`, `CARRY_BASE_PX_S`) |
| `scripts/visuals/CharacterAvatar3D.gd` | `_sync_pose_and_tint` |
| `scripts/visuals/BanditModel3D.gd` | `_process` |
| `docs/capturas_anim1/cerca_antes_10h.png` | Captura en `"cerca"` antes del cambio |
| `docs/capturas_anim1/cerca_despues_10h.png` | Captura en `"cerca"` después del cambio |
| `docs/HANDOFF.md` | Entrada superior en §7 para el bloque `ANIM-1` |
| `CHANGELOG.md` | Entrada en lenguaje de jugador para `ANIM-1` |
| `docs/REGISTRO_TRABAJO.md` | Fila `ANIM-1` en la tabla del Bloque FIS |
| `GameVault/02_Sistemas/Estética Retro 3D.md` | Nota de diseño `ANIM-1` |
| `GameVault/05_Roadmap_y_Lore/Tablero.md` | Tarjeta completada en `✅ Hecho` |
| `GameVault/06_Diario/2026-11-06.md` | Línea en `✅ Qué hice hoy` |

---

## 3. Pruebas ejecutadas y resultados

Siguiendo la instrucción expresa del encargo (§2: *«Esta mañana NO pases las cuatro pruebas (las pasa el supervisor al final): solo el arranque sin errores (`timeout 120 … --quit-after 3`)»*), se ejecutó únicamente el arranque sin errores con `timeout`:

1. **Arranque sin errores (`timeout 120 flatpak run org.godotengine.Godot --headless --path /home/lamsak/Videojuego --quit-after 3`):**
   - **Resultado:** `exit code 0` en ~6 s, sin errores de script ni de compilación.
2. **Verificación visual (`tools/screenshot_3d.gd` en `"cerca"`):**
   - **Resultado:** `docs/capturas_anim1/cerca_antes_10h.png` y `docs/capturas_anim1/cerca_despues_10h.png` comprobadas visualmente; tanto la espada del jugador como la lanza y el escudo de Guardia Rodric pasan de estar invertidos 180° hacia atrás a sujetarse hacia delante.

---

## 4. Qué no se tocó

- No se ejecutaron las cuatro baterías de pruebas (reservadas al supervisor al cierre según instrucciones).
- No se modificó ningún otro sistema fuera de `ANIM-1`.
