# Informe de Antigravity para el Supervisor (Claude Code) — Auditoría de Realismo + Prioridad 1 (FIS-P1)

**Fecha:** 2026-11-05  
**Encargo:** `docs/ENCARGO_ANTIGRAVITY.md` §2 — Auditoría de realismo (`docs/AUDITORIA_REALISMO.md`) y primer arreglo (Prioridad 1: Interior físico de tu propia casa)

---

## 1. Qué se hizo

1. **Paso A — Auditoría de Realismo (`docs/AUDITORIA_REALISMO.md`):**
   - Revisados los sistemas de `scripts/systems/` buscando mecánicas que todavía se resuelven por diálogo, tiradas instantáneas o entregas automáticas a medianoche sin presencia física en el mapa.
   - Redactada la tabla ordenada de mayor a menor prioridad en `docs/AUDITORIA_REALISMO.md` con las 11 mecánicas pendientes (interior de tu casa, tu tienda propia y dependiente, carreta de carga `has_cart`, cenas/fiestas/cenas de paz, caravanas de rutas comerciales, caravana nocturna de contrabando, expediciones fuera del valle, club de la pelea y carreras/peleas de animales, cobro de rentas/tributos/alcaldía, saboteadores/rateros nocturnos y recogida de obras maestras), citando únicamente archivos y funciones existentes.

2. **Paso B — Arreglo de la Prioridad 1 (`FIS-P1`: Interior físico de tu propia casa):**
   - **Fin de los objetos mágicos a medianoche (`VillageHousing.daily`):** Eliminada de `VillageHousing.daily(vm)` la inyección automática cada dos días de `bread` y `herbal_poultice` en la mochila del jugador.
   - **Sincronización de los 4 objetos físicos de tu casa (`VillageHousing.sync_home_props`, `VillageHousing.home_prop_pos`):**
     - `VillageHousing.sync_home_props(vm)` crea en las casas construidas del jugador (`VillageHousing.player_lots(vm, true)`) instancias de `WorldInteractableProp` (con dibujo 2D en `WorldInteractableProp._draw_home_workbench_2d`, `_draw_home_stash_2d`, `_draw_home_stairs_2d`, `_draw_home_garden_2d` y modelos 3D sincronizados en `WorldStage3D._sync_home_props_3d()`):
       1. **Huerto doméstico (`"home_garden"`):** `VillageHousing.interact_home_garden(vm, lot_id, player)` y `can_harvest_home_garden(vm, lot_id)` permiten cosechar en persona con `[E]` cada 2 días (`+1 bread` y `+1 herbs`).
       2. **Banco de trabajo y alquimia (`"home_workbench"`):** `VillageHousing.open_home_workbench_menu(vm, speaker, _player)` y `craft_home_poultice(vm, lot_id, inv, player, npc)` permiten preparar cataplasmas (`housing_craft_poultice`, consumiendo `1 herbs` de la mochila) o destilar 2 dosis de «polvo de ocaso» (`underworld_cook_dust` en `VillageUnderworld.on_player_action`, pagando 25 de oro al perista con `vm.pay_into(get_fence_npc(vm), DUST_COOK_COST)` y comprobando testigos conscientes en la misma planta con `vm._find_conscious_witness_near`).
       3. **Escondite bajo las tablas (`"home_stash"`):** `VillageHousing.open_home_stash_menu(vm, speaker, _player)` permite guardar 25 de oro (`housing_stash_put`) o recuperar todo el oro oculto (`housing_stash_take`) directamente en las tablas del suelo de tu casa.
       4. **Escalera al altillo y trampilla al sótano (`"home_stairs"`):** `VillageHousing.interact_home_stairs(vm, _lot_id, speaker, player)` y `get_home_stairs_label(vm, _lot_id)` permiten subir al altillo (`housing_change_level:1`), bajar al sótano (`housing_change_level:-1`), volver a la planta baja (`housing_change_level:0`) o esconderse de una búsqueda menor (`housing_hide_cellar`) pulsando `[E]` en la escalera/trampilla física de tu casa.
   - **Limpieza de menús de diálogo (`VillageHousing.add_dialogue_choices`, `VillageUnderworld.add_dialogue_choices`):**
     - Eliminadas de la charla con el carpintero y vecinos las opciones `housing_stash_put`, `housing_stash_take`, `housing_change_level:*` y `housing_hide_cellar`.
     - Eliminada de la charla con el perista la opción `underworld_cook_dust`.

---

## 2. Archivos tocados

| Archivo | Cambios |
|---|---|
| `docs/AUDITORIA_REALISMO.md` | Nuevo: tabla priorizada de las 11 mecánicas que aún no ocurrían físicamente en el mundo |
| `scripts/obstacles/WorldInteractableProp.gd` | Añadidos los tipos `"home_workbench"`, `"home_stash"`, `"home_stairs"` y `"home_garden"` en `setup_prop`, `_rebuild_visual_and_area`, `_draw_home_workbench_2d`, `_draw_home_stash_2d`, `_draw_home_stairs_2d`, `_draw_home_garden_2d`, `get_interact_label`, `interact` y `on_dialogue_action` |
| `scripts/systems/VillageHousing.gd` | Eliminada entrega automática en `daily`; quitados atajos de diálogo en `add_dialogue_choices`; añadidas `_notify_player`, `home_prop_pos`, `sync_home_props`, `can_harvest_home_garden`, `get_home_garden_label`, `interact_home_garden`, `craft_home_poultice`, `open_home_workbench_menu`, `open_home_stash_menu`, `get_home_stairs_label` e `interact_home_stairs` |
| `scripts/systems/VillageLots.gd` | Llamada a `vm.VillageHousing.sync_home_props(vm)` en `_finish` y `after_load` |
| `scripts/systems/VillageUnderworld.gd` | Quitada `underworld_cook_dust` de `add_dialogue_choices`; soporte en `on_player_action` cuando se invoca desde `"home_workbench"` (`npc == null`), pago a `get_fence_npc(vm)` y comprobación de testigos en la misma planta |
| `scripts/visuals/WorldStage3D.gd` | Añadida `_sync_home_props_3d()` para renderizar en 3D el banco de trabajo y alquimia, las tablas del escondite, la escalera/trampilla y el huerto doméstico |
| `tools/tests/verify_all.gd` | Añadido `Block FIS-P1` verificando los 4 objetos físicos de la casa, el fin de los objetos mágicos a medianoche, la cosecha del huerto, el banco de trabajo, el escondite, la escalera y la ausencia de esas acciones en diálogos con NPCs |
| `docs/HANDOFF.md` | Entrada de `Auditoría de Realismo y Prioridad 1 (Bloque FIS-P1)` en §7 |
| `CHANGELOG.md` | Entrada en lenguaje de jugador para el bloque |
| `docs/REGISTRO_TRABAJO.md` | Fila `FIS-P1` en la tabla del «Bloque FIS» |
| `GameVault/02_Sistemas/Vivienda e Hipotecas.md` | Nota de diseño de `FIS-P1` |
| `GameVault/02_Sistemas/Red de las Sombras.md` | Nota de diseño de `FIS-P1` |
| `GameVault/05_Roadmap_y_Lore/Tablero.md` | Tarjeta marcada en `✅ Hecho` |
| `GameVault/06_Diario/2026-11-05.md` | Entrada en el diario del día |
| `docs/INFORME_ANTIGRAVITY.md` | Reescrito entero para este encargo |

---

## 3. Pruebas ejecutadas y resultado

1. **Arranque headless (`--quit-after 3`):**
   - `timeout 60 flatpak run org.godotengine.Godot --headless --path . --quit-after 3` → **0 `SCRIPT ERROR` / `Parse Error`**.
2. **`names_check.gd`:**
   - `NAMES CHECK PASSED (200 F / 200 M / 200 apellidos + 17 PersonProfile + B0.3 generator + B1.1/B1.2 social + B2.1 hangouts + B3.1-B3.4 romance + B4.1 fights)`.
3. **`dialogue_coverage.gd`:**
   - `COVERAGE DONE npcs=18 actions=629` y **`0` `SCRIPT ERROR`**.
4. **`social_sim.gd`:**
   - `SOCIAL SIM CHECK PASSED (60d metas verificadas en 5 semillas + reemplazos procedurales)`.
5. **`verify_all.gd`:**
   - `Block FIS2 (Physical Terminal, Electric Panel & Heist Targets) OK`
   - `Block FIS3 (Walkable Sewers, Street Grates, Ladders & Contraband Chests) OK`
   - `Block FIS4 (Live Ranch Herd & Player Livestock) OK`
   - `Block FIS-P1 (Physical Home Interior: Garden, Workbench, Stash & Stairs) OK`
   - `ALL RIMWORLD MEDICAL, FOOTPRINTS, 3-PHASE CORPSE REPORT, MULTI-CORPSE FIX, RPG INTERROGATION, PUBLIC TRIAL, DYNAMIC RELATIONSHIPS, MISSING FAMILY SEARCH, SOCIAL GLOSSARY & UNCONSCIOUS REACTION TESTS PASSED!` (código de salida `0`).

---

## 4. Qué quedó pendiente o dudas de diseño

- Ninguna duda de diseño en la Prioridad 1. Quedan en `docs/AUDITORIA_REALISMO.md` las prioridades 2 a 11 (empezando por la Prioridad 2: tu tienda propia «Bazar del Forastero» con su mostrador físico y su dependiente acudiendo a trabajar).

---

## Corrección FIS-P1

Aplicados los 3 puntos de «FIS-P1 (interior de tu casa) — CORRECCIÓN NECESARIA» de `docs/REVISION_SUPERVISOR.md`:

1. **ID de catálogo real (`"herbs"` en `SimpleInventory.CATALOG`):**
   - Sustituido `"medicinal_herb"` por `"herbs"` en `VillageHousing.interact_home_garden(vm, lot_id, player)` y en `VillageHousing.craft_home_poultice(vm, lot_id, inv, player, npc)`, así como en los letreros de `VillageHousing.get_home_garden_label(vm, lot_id)` y `VillageHousing.open_home_workbench_menu(vm, speaker, _player)`. Comprobado con `grep` que no queda ninguna aparición de `"medicinal_herb"` en `scripts/`.
2. **Sin producción de la nada en el banco de trabajo (`VillageHousing.craft_home_poultice`):**
   - Eliminada la producción gratuita cada 2 días sin ingredientes y eliminada la función auxiliar `can_craft_home_poultice`. Ahora `VillageHousing.craft_home_poultice(vm, lot_id, inv, player, npc)` exige siempre `inv.has_item("herbs", 1)`, consume `inv.remove_item("herbs", 1)` y añade `inv.add_item("herbal_poultice", 1)` (si no llevas `"herbs"`, devuelve `false` sin dar nada).
3. **Nombres reales en la fila 11 de `docs/AUDITORIA_REALISMO.md`:**
   - Corregida la fila 11 para referenciar el archivo y funciones reales: `scripts/systems/VillageFame.gd`: `is_master`, `master_info`, `add_dialogue_choices`, `on_player_action` (`fame_buy_masterwork`, `fame_patronize`).
4. **Prueba en `tools/tests/verify_all.gd`:**
   - Actualizado `Block FIS-P1` (`FIS-P1.3a`, `FIS-P1.4a`, `FIS-P1.4b`) para verificar que `home_garden` entrega `"herbs"`, que `home_workbench` consume `1 "herbs"` para dar `+1 "herbal_poultice"` y que sin `"herbs"` en el inventario el banco no produce ninguna cataplasma.

---

## Corrección del campamento

Aplicados los 3 puntos de «Campamento inicial (pedido directo del usuario, commits 6bcac38 y cbbc7fc) — CORRECCIÓN DE REGLAS» de `docs/REVISION_SUPERVISOR.md`:

1. **Suma cero en pagos de oro del campamento (`CampSite._pay_camp_work`, `VillageManager.pay_into`, `VillageManager.role_npc`):**
   - Añadida `CampSite._pay_camp_work(role, gold_amount)` (que obtiene `vm` con `CampSite._get_vm()` y llama a `vm.pay_into(vm.role_npc(role), gold_amount)`):
     - En `CampSite._on_upgrade_house_pressed()` y `CampSite._on_build_camp_farm_pressed()`, el oro pagado va al carpintero (`VillageNPC.TradeRole.CARPENTER`).
     - En `CampSite._on_build_camp_coop_pressed()`, los 30 de oro pagados por el gallinero con 3 gallinas van al ganadero (`VillageNPC.TradeRole.RANCHER`).
     - En `CampSite._on_build_generator_pressed()` y `CampSite._on_build_sprinkler_pressed()`, los 18 y 15 de oro pagados van al arreglador (`VillageNPC.TradeRole.TINKER`).
     - Si no hay vecino vivo con ese oficio, `VillageManager.pay_into` ingresa automáticamente el importe en `town_state["treasury"]`.
2. **Confirmación con doble E al gastar oro (`CampSite._confirm_camp_gold_spend`, `VillageHousing.press_twice`):**
   - Añadida `CampSite._confirm_camp_gold_spend(player, tag, prompt_msg)` que invoca `VillageHousing.press_twice(vm, tag)` antes de cobrar oro en `_on_upgrade_house_pressed` (`"camp_house_up"`), `_on_build_camp_farm_pressed` (`"camp_farm"`), `_on_build_camp_coop_pressed` (`"camp_coop"`), `_on_build_generator_pressed` (`"camp_generator"`) y `_on_build_sprinkler_pressed` (`"camp_sprinkler"`), mostrando el aviso «¿…? Pulsa E otra vez para confirmar.» (`show_hint`, `_spawn_floating_text` y `upgrade_desc_lbl`). Además, `CampSite._unhandled_input(event)` acepta `KEY_E` con el panel abierto para confirmar la acción pendiente. Si la obra se paga únicamente con madera o bobina de cobre, se ejecuta directamente sin pedir segunda pulsación.
3. **Prueba en `tools/tests/verify_all.gd`:**
   - Añadido el bloque `CampRule.0–CampRule.2` al final de `tools/tests/verify_all.gd`, comprobando que pagar el gallinero con oro (`_on_build_camp_coop_pressed`) no construye ni cobra en la primera pulsación y, en la segunda pulsación, construye el gallinero (`camp_coop_built == true`), descuenta 30 de oro al jugador y suma 30 de oro a `vm.role_npc(int(VillageNPC.TradeRole.RANCHER)).personal_gold` (o a `vm.town_state["treasury"]`).
