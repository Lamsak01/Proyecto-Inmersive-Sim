# Informe de Antigravity — Bloque R2: «La Familia» y Enciclopedia HTML del Vault

**Fecha:** 2026-11-06  
**Estado:** Implementado y verificado en `verify_all.gd` (`Block R2`).

---

## 1. Qué se ha implementado

### A. Bloque R2 — «La Familia» (`scripts/systems/VillageFamilia.gd`)
Se ha creado el módulo `scripts/systems/VillageFamilia.gd` (cargado con `const VillageFamilia = preload("res://scripts/systems/VillageFamilia.gd")` en `VillageManager.gd` y `NPCDialogue.gd`, sin `class_name`) que guarda todo su estado en `VillageNeeds.state(vm)["familia"]` para persistir automáticamente en el archivo de guardado:

1. **Nace sola cuando se dan las condiciones (`active`, `boss_of`, `_can_be_member`, `can_be_boss`, `is_ambitious`, `unscrupulous_score`, `is_unscrupulous`, `persuasion`, `is_persuasive`, `has_boss_motive`, `boss_score`, `try_found`, `found`):**
   - No existe al empezar la partida.
   - En `VillageFamilia.daily(vm)`, si aún no se ha fundado (`not active(vm)`), se evalúa a los vecinos adultos elegibles (`_can_be_member`: excluye guardias, comisario, sacerdote, inquisidor, mercader viajero, niños y forasteros).
   - Para fundarla hace falta ser **ambicioso** (`is_ambitious`: `ambition >= 0.8` o `"Ambicioso"` / `"Sediento de poder"`), **sin escrúpulos** (`is_unscrupulous`: `honesty < 0.0` y `unscrupulous_score >= 0.7`, sin `"Honrado"` ni `"Íntegro"`), **persuasivo** (`is_persuasive`: `persuasion >= 0.45`, por `leadership`, `sociability`, `wit`, `trade` o `"Manipulador"`, `"Líder"`, `"Negociante"`, `"Chantajista"`, `"Astuto"`) y tener **motivo** (`has_boss_motive`: `personal_gold >= 45` ahorrado junto con deuda, deseo de ambición/venganza, rencor/envidia hacia algún vecino o `personal_gold >= 75` con vecinos vulnerables).
   - Si nadie cumple las condiciones, «La Familia» no nace. Cuando alguien las cumple, el mejor candidato la funda y actualiza el bando oculto `"familia"` en `vm.faith_bands` mediante `_update_band(vm)`.

2. **Reclutamiento de 2 a 4 vecinos de uno en uno (`recruit_motive`, `recruit_resistance`, `recruit_chance`, `try_recruit`, `join`, `is_member`, `has_refused`, `member_nodes`, `recruits_count`):**
   - El jefe intenta reclutar de uno en uno (`MIN_RECRUITS = 2`, `MAX_RECRUITS = 4`) entre vecinos adultos que no se hayan negado antes (`has_refused`).
   - Motivos de reclutamiento (`recruit_motive`): `"deuda"` (`_owes_to`), `"miedo"` (`fears_boss`), `"desesperado"` (pobre, mendigo o endeudado) o `"afecto"` (relación `>= 30` o pareja del jefe).
   - El intento puede **fallar** según `recruit_chance(vm, boss, target)`: `try_recruit` devuelve `"joined"`, `"refused"` o `""`. Si el vecino se niega (`"refused"`), se guarda en `refusals`, baja su relación con el jefe (`modify_npc_relationship(boss, -8, ...)`), añade un pensamiento negativo (`add_thought`) y, si no tiene el rasgo `"Discreto"`, corre el rumor por el pueblo con `vm.record_social_event("familia_rumor", boss, target, ...)` (añadido `"familia_rumor"` a `VillageManager.GOSSIP_EVENT_TYPES`).

3. **Reuniones nocturnas en el reservado de la Trattoria y precaución ante guardias (`plan_meeting`, `call_meeting`, `abort_meeting`, `finish_meeting`, `is_meeting_now`, `has_unwanted_witness_near`, `seat_pos`, `on_hour`, `tick`):**
   - Sin calendario fijo: cuando hay al menos 2 miembros, el jefe fija `next_plan_night` según sus planes, reclutamientos o reuniones pospuestas (`postponed`).
   - En las horas nocturnas (`MEET_CALL_HOURS = [22, 23, 0, 1]` en `on_hour(vm, hour)`), si no hay guardias ni extraños cerca (`has_unwanted_witness_near(vm)` comprueba `GUARD_NEAR_PX = 180.0`, `VillageRestaurant.RECT.grow(70.0)` para guardias y `STRANGER_NEAR_PX = 75.0` / `ROOMS["reservado"].grow(40.0)` para desconocidos), `call_meeting(vm)` envía a los miembros disponibles con `start_errand("familia_meet", seat_pos(i, avail.size()))` alrededor de `VillageRestaurant.BACKROOM_TABLE` (`Vector2(1062, 248)`, sala `"reservado"`), entrando por las puertas interiores de `VillageRestaurant.route`.
   - En cada pulso (`VillageNeeds.tick(vm)` → `VillageFamilia.tick(vm)`), si un guardia o un vecino ajeno se acerca al reservado mientras van de camino o están reunidos, `abort_meeting(vm)` cancela el recado de todos (`end_errand()`), marca `meeting_status = "aborted"` y `postponed = true` para dejarlo para otra noche.

4. **Pista del cocinero sin menús mágicos (`cook_line`, `add_dialogue_choices` en `NPCDialogue.gd`) y persistencia (`after_load`):**
   - Al hablar con el cocinero (`TradeRole.RESTAURATEUR`), `VillageFamilia.add_dialogue_choices` añade la opción `«🍷 Preguntar por el reservado del fondo»` (`"familia_cook_ask"`), cuya respuesta (`cook_line(vm)`) varía según haya reunión a puerta cerrada en ese momento (`COOK_LINE_MEETING`), exista ya «La Familia» (`COOK_LINE_ACTIVE`) o el reservado siga tranquilo (`COOK_LINE_QUIET`, documentado en `docs/APORTES_CREATIVOS.md`).
   - Al guardar y cargar (`VillageFamilia.after_load(vm)` llamado desde `VillageManager.load_economy_save_dict`), se conservan `boss`, `members` y `refusals`, se reconstruye el bando `"familia"` en `vm.faith_bands` y se retoman o cierran los recados `"familia_meet"` según la hora cargada.

### B. Enciclopedia del Vault en un único archivo HTML (`tools/export_vault_html.py`)
- Se ha creado `tools/export_vault_html.py`, que recorre `GameVault/` excluyendo `.obsidian/` y `99_Archivo/` (y `Plantillas/` por defecto) y genera un único archivo `.html` 100 % autocontenido (CSS y JS integrados, sin dependencias externas).
- Incluye índice lateral por carpetas, buscador instantáneo arriba (por título y contenido), enlaces internos `[[...]]` funcionando dentro de la misma página y `Tablero.md` limpio como lista de tareas sin bloques de configuración del plugin Kanban.
- Se han generado fuera del repositorio las dos variantes listas para enviar:
  - `/home/lamsaktp/Enciclopedia_LaPlacaDePetri.html` (sin `03_La_Secta/` ni `06_Diario/`, con `--sin-secta-ni-diario`).
  - `/home/lamsaktp/Enciclopedia_LaPlacaDePetri_Completa.html` (con todas las carpetas de `GameVault/`).

### C. Bloque R3 — Negocios discretos de «La Familia» (`scripts/systems/VillageFamilia.gd`)
Se han añadido los tres negocios discretos de «La Familia», todos de suma cero, ejecutados a pie durante el día (`BUSINESS_HOURS = [11, 16]`, recado `"familia_errand"`), con posibilidad de fallo, enfriamiento y comprobación de testigos:
1. **Cobro de «tranquilidad» a comerciantes prósperos (`can_target_merchant`, `protection_chance`, `resolve_protection`, `has_guard_witness_at`):**
   - Si hay un guardia no sobornado a `<= 110 px`, el cobrador disimula y aborta (`"aborted_guard"`).
   - Si el comerciante acepta (`"paid"`), `PROTECTION_FEE = 12` pasa en suma cero de `merchant.personal_gold` al cobrador (`6`) y al jefe (`6`).
   - Si se niega (`"refused"`), entra en enfriamiento (`protection_cooldown`, 4 días), baja su relación y corre el chisme (`"familia_rumor"`).
2. **Préstamos del reservado y cobro al vencer (`can_loan_to`, `give_loan`, `collect_loan`):**
   - El jefe presta `LOAN_AMOUNT = 20` de su propio bolsillo a vecinos apurados (`personal_gold <= 10`, suma cero), fija `LOAN_REPAY = 26` a 4 días y marca `owes_to` hacia el jefe (conectando con el motivo `"deuda"` de reclutamiento).
   - Al vencer, `collect_loan` transfiere los `26` en suma cero al jefe o deja el saldo pendiente si el vecino no llega.
3. **Comprar el silencio de guardias poco honrados (`can_bribe_guard`, `bribe_guard_chance`, `try_bribe_guard`, `is_guard_bribed`):**
   - Si el guardia acepta (`"bribed"`), `BRIBE_AMOUNT = 15` pasa en suma cero del bolsillo del jefe al guardia y durante 5 días (`bribed_guards`) ese guardia hace la vista gorda en `has_unwanted_witness_near(vm)` sin abortar las reuniones nocturnas del reservado; si rechaza (`"refused"`), entra en `bribe_cooldown` y suelta rumor.

### D. Don Vittorio Corvo (jefe desde el Día 0) y Bloque R4 — El jugador descubre «La Familia» e interviene

1. **Jefe mafioso desde el Día 0 (`Don Vittorio Corvo`):**
   - `VillageFamilia.spawn_initial_boss(vm)` crea al arrancar el pueblo a `npc_familia_boss` (**Don Vittorio Corvo**, 46 años, `personal_gold = 120`, instalado en `VillageRestaurant.OWNER_BED2` y `BACKROOM_TABLE`) con 6 rasgos válidos y sin conflicto de `TraitCatalog.gd`: `["Sediento de poder", "Manipulador", "Líder", "Codicioso", "Astuto", "Rencoroso"]` (`ambition >= 2`, `honesty <= -2`, `persuasion >= 1`), dejándolo al frente de «La Familia» desde el Día 0 (`found(vm, boss)`).
2. **Descubrimiento sin menús mágicos (`try_eavesdrop_meeting`, `is_boss_known_to_player`):**
   - Acercarse a `<= 78 px` de `BACKROOM_TABLE` durante una reunión nocturna activa (`is_meeting_now(vm)`) permite escuchar en voz baja quiénes están reunidos (`known_members`), quién manda (`player_knows_boss = true`), sumar prueba (`player_evidence += 1`) y enterarse del próximo comercio objetivo (`known_target`). También se descubre al jefe si el jugador ha oído un `"familia_rumor"` en `social_event_log`.
3. **Tres formas de intervenir (`add_dialogue_choices`, `on_player_action`, `player_collect_protection`):**
   - **Avisar a la víctima (`"familia_warn_target"`):** previene al comerciante amenazado (`protection_cooldown` durante 4 días, desmonta el encargo contra él, `+10` de afinidad con la víctima y `-12` con el jefe).
   - **Delatar ante el Comisario con pruebas (`"familia_report_confirm"` → `"familia_report_sheriff"`):** tras confirmar, el Comisario paga `35` de oro en suma cero desde `town_state["treasury"]`, limpia los sobornos (`bribed_guards`), comercios intimidados (`protected_shops`) y encargos pendientes (`pending_business`), sube `+10` de afinidad con el Comisario y baja `-25` con el jefe.
   - **Trabajar para el jefe (`"familia_ask_work"`, `"familia_player_extort"`, `"familia_deliver_cut"`):** el jefe encarga cobrar a un comerciante; el jugador va en persona (`<= 95 px`), cobra `12` de oro en suma cero del bolsillo del comerciante (abortando con `+1` de búsqueda si mira un guardia no sobornado, o fallando con enfriamiento y rumor si sale mal) y entrega `6` al jefe quedándose `6` limpios y `+8` de afinidad.

- `scripts/systems/VillageFamilia.gd` (nuevo, R2 + R3 + R4 + Don Vittorio Corvo)
- `scripts/systems/VillageManager.gd` (`preload`, `spawn_initial_boss`, `_pick_ambitious_successor`, `GOSSIP_EVENT_TYPES`, `on_hour`, `daily`, `after_load`)
- `scripts/systems/VillageNeeds.gd` (`tick`: recado `"familia_meet"` sin caducar por tiempo en marcha y llamada a `VillageFamilia.tick(vm)`)
- `scripts/enemies/VillageNPC.gd` (`NIGHT_ERRANDS` y `get_activity_description` para `"familia_meet"` y `"familia_errand"`)
- `scripts/enemies/NPCDialogue.gd` (`preload`, `VillageFamilia.add_dialogue_choices` y `VillageFamilia.on_player_action`)
- `tools/export_vault_html.py` (nuevo)
- `tools/tests/verify_all.gd` (`R2.0a–R2.0e`, `Block R2`, `Block R3`, `Block R4`)
- Documentación y Vault: `docs/HANDOFF.md`, `CHANGELOG.md`, `docs/REGISTRO_TRABAJO.md`, `docs/APORTES_CREATIVOS.md`, `docs/INFORME_ANTIGRAVITY.md`, `GameVault/04_Censo_y_Misiones/Trattoria Il Corvo.md`, `GameVault/05_Roadmap_y_Lore/Tablero.md`, `GameVault/06_Diario/2026-11-06.md`.
