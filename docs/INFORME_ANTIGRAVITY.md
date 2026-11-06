# Informe de Antigravity para el Supervisor (Claude Code) — Bloque FIS3b

**Fecha:** 2026-11-05  
**Encargo:** `docs/ENCARGO_ANTIGRAVITY.md` §2 — Bloque FIS3b (Bajar o salir de las alcantarillas a la vista es sospechoso)

---

## 1. Qué se hizo

1. **Comprobación de testigos al bajar por una rejilla (`VillageUnderworld.interact_sewer_grate`):**
   - Antes de trasladar al jugador a la cámara subterránea (`enter_sewer_location`), `interact_sewer_grate(vm, loc_id, player)` llama a `VillageUnderworld._check_sewer_witness(vm, check_pos)` usando la posición del jugador en la calle (`pl.global_position`, nivel `0`).
   - `_check_sewer_witness(vm, check_pos)` consulta `vm._find_conscious_witness_near(check_pos, 120.0, null)` (misma planta y con línea de visión, igual que en el sabotaje del cuadro eléctrico en `VillageCulture.on_player_action`). Si hay tanto un vecino civil como un guardia/comisario conscientes dentro de los `120.0` px con línea de visión en la misma planta, prima la autoridad (`VillageNPC.TradeRole.SHERIFF` / `VillageNPC.TradeRole.GUARD`).
   - El descenso **no se bloquea**: `enter_sewer_location(vm, loc_id, pl)` se ejecuta igualmente y después `_apply_sewer_witness(vm, wit_info, pl)` aplica las consecuencias.

2. **Reacción según quién te vea (`VillageUnderworld._apply_sewer_witness`):**
   - **Si te ve un guardia o el comisario (`VillageNPC.TradeRole.GUARD` o `VillageNPC.TradeRole.SHERIFF`):**
     - Sube en `1` la búsqueda: `vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)`.
     - Muestra el aviso flotante `🚨 ¡X te vio colarte en las alcantarillas! (Búsqueda +1)` tanto sobre el testigo (`wit._spawn_floating_text`) como sobre el jugador (`player._spawn_floating_text`) y en `pl.show_hint(...)`.
     - Añade una entrada en la crónica con `VillageChronicle.add(vm, "sewer_seen", "¡%s te vio colarte en las alcantarillas! (Búsqueda +1)" % w_name, true)`.
   - **Si te ve un vecino cualquiera:**
     - No hay delito (`wanted_level` no sube).
     - Muestra el aviso flotante `👀 ¡X te vio colarte en las alcantarillas!` (`_spawn_floating_text` y `show_hint`).
     - Añade el recuerdo al vecino con `wit.add_thought("Vi al forastero colarse en las alcantarillas (-2)", -2.0)`.
     - Registra el chisme en el sistema existente mediante `vm.record_social_event("player_secret", wit, null, "%s vio al forastero colarse en las alcantarillas" % w_name)` con `ev["known_by"] = {wit.get_person_key(): true}` y `ev["heard_from"] = {}`.

3. **Salir por una escalerilla a la vista (`VillageUnderworld.exit_sewer_ladder`):**
   - Tras subir a la superficie (`exit_sewers_to_surface(vm)`, que devuelve a `vm.set_player_elevation_level(0)`) y colocar al jugador en la rejilla de salida (`SEWER_LOCATIONS[loc_id]["pos"]`), `exit_sewer_ladder(vm, loc_id, player)` ejecuta la misma comprobación `_check_sewer_witness(vm, check_pos)` y `_apply_sewer_witness(vm, wit_info, pl)`.
   - Si sales por `"smuggler_tunnel"` delante de un guardia o del comisario (`seen_by_law == true`), no se aplica la rebaja semanal de búsqueda de `"smuggler_tunnel"` y en su lugar sube `wanted_level` en `1`.

---

## 2. Archivos tocados

| Archivo | Cambios |
|---|---|
| `scripts/systems/VillageUnderworld.gd` | Añadidas `_check_sewer_witness(vm, check_pos)` y `_apply_sewer_witness(vm, wit_info, player)`; conectadas en `interact_sewer_grate(vm, loc_id, player)` y `exit_sewer_ladder(vm, loc_id, player)` |
| `tools/tests/verify_all.gd` | Añadido subbloque `FIS3.8a–FIS3.8f` dentro del `Block 97 (FIS3 / FIS3b)`: sin nadie cerca bajar y subir mantienen `wanted_level == 0`; con un guardia al lado bajar sube `wanted_level` a `1` (sin bloquear el paso) y subir por la escalerilla sube `wanted_level` a `2`; con un vecino cualquiera al lado no sube `wanted_level` y registra el chisme en `vm.social_event_log` |
| `docs/HANDOFF.md` | Entrada de `Bloque FIS3b` arriba en §7 y en la lista de bloques FIS |
| `CHANGELOG.md` | Entrada en lenguaje de jugador para el bloque |
| `docs/REGISTRO_TRABAJO.md` | Fila `FIS3b` en la tabla del «Bloque FIS» |
| `GameVault/02_Sistemas/Capas Verticales y Alcantarillas.md` | Nota de diseño de `FIS3b` |
| `GameVault/02_Sistemas/Red de las Sombras.md` | Nota de diseño de `FIS3b` |
| `GameVault/05_Roadmap_y_Lore/Tablero.md` | Tarjeta marcada en `✅ Hecho` |
| `GameVault/06_Diario/2026-11-05.md` | Línea en el diario del día |
| `docs/INFORME_ANTIGRAVITY.md` | Reescrito entero para el Bloque FIS3b |

---

## 3. Pruebas ejecutadas y resultado

1. **Arranque headless (`--quit-after 3`):**
   - `timeout 60 flatpak run org.godotengine.Godot --headless --path . --quit-after 3` → **0 `SCRIPT ERROR` / `Parse Error`**.
2. **`names_check.gd`:**
   - `NAMES CHECK PASSED (200 F / 200 M / 200 apellidos + 17 PersonProfile + B0.3 generator + B1.1/B1.2 social + B2.1 hangouts + B3.1-B3.4 romance + B4.1 fights)`.
3. **`dialogue_coverage.gd`:**
   - `COVERAGE DONE npcs=18 actions=577` y **`0` `SCRIPT ERROR`**.
4. **`social_sim.gd`:**
   - `SOCIAL SIM CHECK PASSED (60d metas verificadas en 5 semillas + reemplazos procedurales)`.
5. **`verify_all.gd`:**
   - `Block FIS2 (Physical Terminal, Electric Panel & Heist Targets) OK`
   - `Block FIS3 (Walkable Sewers, Street Grates, Ladders & Contraband Chests) OK` (incluyendo `FIS3.8a–FIS3.8f`)
   - `Block FIS4 (Live Ranch Herd & Player Livestock) OK`
   - `ALL RIMWORLD MEDICAL, FOOTPRINTS, 3-PHASE CORPSE REPORT, MULTI-CORPSE FIX, RPG INTERROGATION, PUBLIC TRIAL, DYNAMIC RELATIONSHIPS, MISSING FAMILY SEARCH, SOCIAL GLOSSARY & UNCONSCIOUS REACTION TESTS PASSED!` (código de salida `0`).

---

## 4. Qué quedó pendiente o dudas de diseño

- Ninguna duda pendiente: existía ya el mecanismo de chismes sobre secretos del jugador (`vm.record_social_event("player_secret", wit, null, ...)` con `known_by` y `add_thought`), por lo que cuando te ve un vecino cualquiera queda registrado tanto en su memoria como en el sistema de chismes del pueblo.
