# Informe de Cierre — Bloque P4: Cenas, fiestas en tu casa y cenas de paz hechas físicas

**Fecha:** 2026-11-06  
**Encargo:** `docs/ENCARGO_P4_CENAS.md`

---

## 1. Archivos tocados y funciones modificadas o creadas

### `scripts/enemies/VillageNPC.gd`
- `NIGHT_ERRANDS`: añadidos `"gathering"` y `"catering"` a la constante `["fence_alley", "smuggler_bust", "gathering", "catering"]` para que ni los invitados ni la posadera cancelen su recado nocturno a las 21:00.
- `_is_mandatory_work_hours()`: devuelve `false` si `errand_kind in NIGHT_ERRANDS`, evitando que la rutina laboral o de descanso corte el trayecto hacia una cena, fiesta, reparto de comida o cena de paz.

### `scripts/systems/VillageNeeds.gd`
- `tick(vm)`:
  - Eximidos `"gathering"` y `"catering"` del corte por tiempo máximo de recado (`20.0` s) junto con `"player_shop_clerk"`, `"fence_alley"` y `"smuggler_bust"`.
  - Al llegar al destino (`arrived`), `"catering"` invoca `vm.VillageHousing.on_caterer_arrived(vm, n)` y `"gathering"` invoca `vm.VillageHousing.on_gathering_guest_arrived(vm, n)`.
  - Al final de `tick(vm)`, se invoca `vm.VillageHousing.tick_gathering(vm)` para procesar el temporizador de 2 horas de juego, las frases de sobremesa cada 20 minutos, la hora tope de llegada (`+2 h`) y la detección de plantón si el jugador se aleja a `>= 90 px`.

### `scripts/systems/VillageUnderworld.gd`
- `fence_on_hour(vm, hour)`: añadido `or f.is_at_poker_table` a la guarda de estado ocupado del perista para que, si ya está sentado en una cena o fiesta a las 22:00, no se levante a mitad de velada para ir al callejón.

### `scripts/obstacles/WorldInteractableProp.gd`
- `setup(cfg)`: añadida rama `"home_table"` con colisión circular (`8.0` px).
- `_draw()`: añadida llamada a `_draw_home_table_2d()`.
- `_draw_home_table_2d()`: dibuja el tablero de madera de la mesa de comedor, sus 6 taburetes alrededor y, cuando `VillageHousing.state(vm)["table_rations"] > 0`, los platos servidos encima.
- `get_interact_label()`: delega `"home_table"` en `VillageHousing.get_home_table_label(vm)`.
- `interact(interactor)`: delega `"home_table"` en `VillageHousing.open_home_table_menu(vm, self)`.

### `scripts/visuals/WorldStage3D.gd`
- `_sync_home_props_3d()`: añadida rama `"home_table"` que construye la mesa de comedor 3D (tablero y cuatro patas de madera con `_make_box`) y muestra hasta 6 platos con comida sobre el tablero cuando `table_rations > 0`.

### `scripts/systems/VillageClans.gd`
- `add_dialogue_choices(vm, npc, player_inv)`: actualizada la etiqueta de `"clan_peace:"` para reflejar que convoca la cena para mañana a las 20:00 en la posada y que el pago (25 de oro si Carisma < 2) va a la posadera.
- `on_player_action(vm, npc, action_id, player_inv)`: en `"clan_peace:"`, si el jugador no tiene Carisma >= 2, exige doble pulsación con `vm.VillageHousing.press_twice(vm, "clan_peace:" + arg, ...)` y transfiere 25 de oro del jugador a `innk.personal_gold` (`vm.VillageHousing.caterer_npc_of(vm)`). En lugar de aplicar la paz al instante, llama a `vm.VillageHousing.schedule_peace_dinner(vm, arg)`.

### `scripts/systems/VillageHousing.gd`
- Constantes y estado:
  - `HOME_PROP_FURNITURE`: añadido `"home_table": true`.
  - `FOOD_ITEMS`, `RATIONS_PER_GUEST = 2`, `CATERING_COST_PER_GUEST = 4`, `DINNER_START_HOUR = 20`, `PARTY_START_HOUR = 21`, `PEACE_START_HOUR = 20`, `GATHERING_DURATION_MINUTES = 120`, `GATHERING_CHAT_INTERVAL_MINUTES = 20`, `GATHERING_HOST_MAX_DIST = 90.0`, `TABLE_SEAT_OFFSETS` (6 asientos a `14 px`), `GATHERING_CHAT_PHRASES` (6 frases de sobremesa).
  - `state(vm)`: añadidos `"table_rations"` (`0`) y `"gathering"` (`{}`).
- Mueble y asientos:
  - `home_prop_pos(vm, kind)`: posición de `"home_table"` en `center + Vector2(-4, 2)`.
  - `sync_home_props(vm)`: instancia `"home_table"` automáticamente al tener casa construida (`s["built"]`).
  - `table_seats(center_pos)`: devuelve las 6 posiciones alrededor de `center_pos` a `14 px`.
  - `get_home_table_label(vm)` y `open_home_table_menu(vm, prop_node)`: letrero e interfaz con `[E]` en la mesa de casa para poner comida (`housing_put_food`), convocar fiesta a las 21:00 (`housing_party_call`, 1/día) o ver el estado de la cita.
  - `put_food_on_home_table(vm, player_inv)`: pasa hasta `RATIONS_PER_GUEST` unidades de comida desde la mochila del jugador a `s["table_rations"]`.
- Convocatorias, comida por encargo y ciclo de vida de la reunión:
  - `total_minutes(vm)`, `has_active_gathering(vm)`, `caterer_npc_of(vm)`, `can_walk_to_gathering(npc)`, `is_free_for_night_gathering(vm, npc)`.
  - `schedule_dinner(vm, npc)`: cita a las 20:00 (hoy si `< 20`, mañana si `>= 20`) en tu casa con 1 vecino adulto (`affinity >= 10`, cada 3 días, sin cobrar oro en el diálogo).
  - `convoke_house_party(vm)` e `invite_to_house_party(vm, npc)`: convoca la fiesta en la mesa para las 21:00 e invita vecinos uno a uno en diálogo (`"housing_party_invite"`, hasta 6). Se retiró `"housing_party"` de `add_dialogue_choices` (dejando su rama en `on_player_action` únicamente por compatibilidad con la prueba antigua de Tanda 4.20).
  - `hire_catering(vm, player_inv)`: en conversación con `caterer_npc_of(vm)` (`"housing_catering"`), cobra `4 * invitados` con doble pulsación (`press_twice`) y transfiere el oro del jugador a `caterer.personal_gold` (suma cero).
  - `_dispatch_caterer_if_ready(vm, g)` y `on_caterer_arrived(vm, npc)`: envía a la posadera 1 hora antes con `start_errand("catering", table_pos)` y al llegar rellena `s["table_rations"]`.
  - `_refund_catering_and_cancel(vm, g)`: si a `start_hour` la posadera no llegó a dejar la comida, devuelve `catering_paid` desde `caterer.personal_gold` al jugador y cancela la reunión.
  - `schedule_peace_dinner(vm, fk)`: convoca para mañana a las 20:00 en `vm._tavern_social_pos` al cabeza de familia y hasta 2 adultos libres de cada familia enfrentada (máx. 6).
  - `on_hour(vm)`: despacha el recado `"catering"` una hora antes, verifica su entrega a `start_hour` y envía a los invitados libres con `start_errand("gathering", seat_pos)`.
  - `_min_guests_to_start(g)` y `on_gathering_guest_arrived(vm, npc)`: al llegar a su asiento, si es en casa y `table_rations < 2`, aplica `npc.modify_affinity(-5)`, pensamiento `"Me invitaron a cenar y la mesa estaba vacía"` y el invitado se marcha; si hay comida, resta `2` raciones, sienta al invitado con `npc.set_poker_seating(true, seat_pos)` y arranca el contador de `120` minutos al sentarse el único invitado (`"dinner"`) o el segundo (`"party"` / `"peace"`).
  - `tick_gathering(vm)`, `_abandon_gathering(vm, g)`, `_complete_gathering(vm, g)` y `_cleanup_gathering_all(vm, g)`: gestionan la charla cada `20` minutos, el plantón si el jugador se aleja de `90 px` una vez presente o si no está a `< 90 px` al cumplirse las 2 horas (`modify_affinity(-5)` y pensamiento `"El forastero nos dejó plantados"`), el cierre por inasistencia a `start_hour + 2 h` (con devolución del oro de la posadera si pagó encargo) y el desenlace social solo para quienes llegaron a sentarse (cena: `+10` afinidad, `+6` ánimo y nota en diario; fiesta: `+6` afinidad a cada asistente, `+1` reputación si `>= 2` y pensamiento positivo; cena de paz: crónica si falta una familia, o tirada `prob = 0.10 + 0.25 * avg_agg + minf(0.20, 0.02 * feud_days)` entre `VillageClans.mediate_clan_peace(vm, fk, "en una cena de paz en la posada")` y discusión a gritos con `-5` de relación entre clanes y crónica).

### `tools/tests/verify_all.gd`
- Añadido el bloque `"Block P4 (Physical Dinners, House Parties, Innkeeper Catering & Peace Dinners)"` al final de `_initialize()` con las 4 verificaciones pedidas:
  - `P4.1`: cena con comida en la mesa (`put_food_on_home_table`, `schedule_dinner`, `on_gathering_guest_arrived`, `tick_gathering` tras 120 min con el jugador a `< 90 px` → `+10` de afinidad y `table_rations == 0`).
  - `P4.2`: cena sin comida (`table_rations == 0` → al llegar el invitado recibe `-5` de afinidad y no se sienta).
  - `P4.3`: encargo a la posadera (`hire_catering` con doble pulsación, transferencia de `8` de oro a `innkeeper.personal_gold`, recado `"catering"` a las 19:00 y `on_caterer_arrived` dejando `table_rations >= 2`).
  - `P4.4`: cena de paz (`VillageClans.on_player_action` con doble pulsación, `-25` de oro del jugador a la posadera, llamada a las 20:00 del día siguiente en `vm._tavern_social_pos`, llegada y asiento de ambas familias y desenlace tras 120 min con reconciliación o bronca a gritos en la crónica).

---

## 2. Comprobaciones y notas de diseño solicitadas en el encargo

1. **Postura de sentado en 3D con `set_poker_seating(true, seat_pos)`:**
   - Al llamar a `npc.set_poker_seating(true, seat_pos)`, el vecino queda anclado en su coordenada de asiento (`poker_seat_pos`) con `is_at_poker_table = true` y mira hacia el centro de la mesa.
   - **Nota sobre la animación 3D:** En `scripts/visuals/CharacterAvatar3D.gd` (`_sync_pose_and_tint`), el estado `CharacterRig3D.AnimState.MOUNTED` (que reproduce el clip `"sit"` en `CharacterRig3D._pick_clip`) solo se activa cuando el actor va montado a caballo (`is_mounted_now`), y no comprueba `is_at_poker_table`. Por tanto, tanto en el póker de la taberna como en las cenas/fiestas de P4, los vecinos mantienen la postura de pie (`"idle"`) alrededor de la mesa en 3D. Siguiendo la instrucción expresa del encargo (*«Apunta en el informe si la postura de sentado sale con eso; no inventes una animación nueva»*), no se ha tocado `CharacterAvatar3D.gd` ni `CharacterRig3D.gd`.
2. **Respaldo de posadera (`vm._innkeeper_npc`) para el encargo de comida y la cena de paz:**
   - `VillageHousing.caterer_npc_of(vm)` devuelve `vm._innkeeper_npc` si existe y está viva; como respaldo por si en algún escenario hubiera muerto o no estuviera asignada, busca al panadero vivo (`TradeRole.BAKER`) en `vm.all_npcs`.
3. **Frases de sobremesa (`GATHERING_CHAT_PHRASES`):**
   - Se han dejado anotadas como texto provisional en `docs/APORTES_CREATIVOS.md` las 6 frases de charla de mesa y los pensamientos asociados al plantón y a la mesa vacía.

---

## 3. Verificación ejecutada

1. **Arranque sin errores de compilación:**
   - `timeout 60 flatpak run org.godotengine.Godot --headless --path . --quit` → código de salida `0`, sin errores de GDScript.
2. **Suite completa `verify_all.gd` (una sola ejecución al cierre):**
   - `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s res://tools/tests/verify_all.gd` → código de salida `0`, pasando todas las tandas previas y `Block P4 (Physical Dinners, House Parties, Innkeeper Catering & Peace Dinners) OK`.
