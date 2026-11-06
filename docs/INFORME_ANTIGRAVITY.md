# Informe de Trabajo — Antigravity (Bloque P3: Caravanas Comerciales y de Contrabando Hechas Físicas)

**Fecha:** 2026-11-06  
**Encargo:** `docs/ENCARGO_P3_CARAVANAS.md`

---

## 1. Parte A — Caravanas de las 3 rutas comerciales

- **Archivos modificados:**
  - `scripts/systems/VillageCulture.gd`
  - `scripts/systems/VillageManager.gd`
  - `scripts/systems/VillageJustice.gd`
  - `scripts/enemies/VillageNPC.gd`
  - `scripts/enemies/NPCDialogue.gd`
  - `scripts/visuals/AnimalModel3D.gd`
- **Calendario y llegada semanal (`VillageCulture.gd`):**
  - Añadidos `CARAVAN_PLAZA_POS = Vector2(465.0, 48.0)`, `ROUTE_WEEKDAYS = {"high_pass": 0, "river_port": 1, "sun_plain": 3}` y `ROUTE_CARAVAN_NAMES`.
  - Cada ruta en `trade_routes_of(vm)` incluye `"next_caravan_day": -1`. Al abrir una ruta (`open_trade_route` o gasto municipal en `process_municipal_spending`), o al revisar el calendario en `ensure_route_caravan_schedule(vm, force_delay)`, `roll_next_caravan_day(route_id, from_day, force_delay)` calcula el próximo día de llegada con un **70 %** en su día base y un **30 %** de retraso de **+1 día**.
  - **Nota sobre el calendario de mercaderes semanales:** `VillageManager._check_weekly_merchant_arrival` usa `current_day % 7 == 3` (miércoles, `WorldClock.get_weekday() == 2`, Maese Casimir) y `current_day % 7 == 6` (sábado, `get_weekday() == 5`, Valeria la Tratante). Los días base de las 3 rutas (`0` lunes, `1` martes, `3` jueves) no pisan miércoles ni sábado; solo cuando `river_port` (martes `1`) sufre el retraso del 30 % (+1 día) coincide en miércoles con Casimir. Como las caravanas de ruta se buscan por su `merchant_id == route_id` (`get_route_caravan_npc(vm, route_id)`) sin sobrescribir `_active_traveling_merchant`, ambos conviven sin conflicto.
- **Caravanero y mula de carga (`CaravanMule`, `CaravanMuleArea`, `spawn_trade_caravan`, `despawn_trade_caravan`, `update_caravan_merchant_ai`, `caravans_on_hour`):**
  - A las **9:00** del `next_caravan_day` (si `vm.merchant_suspension_days[route_id] <= 0`), `caravans_on_hour(vm, hour)` llama a `spawn_trade_caravan(vm, route_id, false, false)`, que crea al caravanero (`VillageNPC` con `trade_role = TradeRole.TRAVELING_MERCHANT` y `merchant_id = route_id`) y su mula de carga (`CaravanMule` en el grupo `"caravan_mule"`, con `CaravanMuleArea` en el grupo `"interactable"`) en `RAID_GATE_POS = Vector2(1400, 50)`.
  - Si a las **10:00–15:00** del día de llegada aún no estaba en el mapa (o acaba de llegar a `CARAVAN_PLAZA_POS`), queda acampada en `CARAVAN_PLAZA_POS = Vector2(465, 48)`. A las **16:00** emprende el regreso hacia `RAID_GATE_POS` y al llegar al borde se retira con `despawn_trade_caravan(vm, route_id)`.
  - **Modelo 3D y 2D de la mula:** no existe un `.glb` animado de mula/burro en `assests/curated_3d/animals/animated/` (solo `Donkey.obj` estático), por lo que `CaravanMule.setup` usa `AnimalModel3D.attach(self, "animals/animated/Horse.glb", 20.0, 4.0, Color(0.62, 0.52, 0.44))` (más pequeña que el caballo de silla de `25.0` px y teñida de pardo grisáceo mediante `_apply_tint_recursive` en `AnimalModel3D.gd`) junto a un `Sprite2D` 2D provisional.
- **Intercambio entre talleres y remesas del jugador (`process_caravan_route_exchange`, `send_player_shipment`, `interact_caravan_mule`, `get_mule_shipment_label`):**
  - `process_trade_routes(vm)` ya **no** ejecuta a medianoche el intercambio de las rutas con caravana (`ROUTE_WEEKDAYS.has(str(r_id))`).
  - Cuando la caravana llega a la plaza (`spawn_trade_caravan` con `at_plaza = true` o `update_caravan_merchant_ai` al alcanzar `CARAVAN_PLAZA_POS`), `process_caravan_route_exchange(vm, route_id)` ejecuta una sola vez por visita (`last_exchange_day`) el relleno semanal (`ROUTE_WEEKLY_REFILL`, `last_refill_day`), el intercambio entre los talleres del vendedor y comprador locales y el cobro de aranceles a las arcas municipales.
  - Pulsar `[E]` sobre la mula en la plaza (`CaravanMule.interact` → `interact_caravan_mule`) muestra el letrero `get_mule_shipment_label(vm, route_id)` («Cargar tu remesa para %s (−%d %s → +%d %s y +%d oro)») y llama a `send_player_shipment(vm, route_id, inv)` (máx. 1/día/ruta, con +4 de oro si tu carreta está a `< 60 px`). Sin la caravana en la plaza (`not is_route_caravan_at_plaza(vm, route_id)`), `send_player_shipment` devuelve `false`.
  - Eliminado el submenú «📦 Enviar remesa…» del diálogo de los artesanos en `VillageCulture.add_dialogue_choices` (se mantiene «📜 Abrir ruta comercial…»).
- **Muerte del caravanero y suspensión de 7 días:**
  - En `VillageNPC._confirm_true_death`, si muere un `TRAVELING_MERCHANT` con `merchant_id in ["high_pass", "river_port", "sun_plain"]`, fija `vm.merchant_suspension_days[merchant_id] = 7` (también contemplado en `VillageJustice.on_traveling_merchant_murdered` y en la cuenta atrás diaria de `VillageManager._on_day_passed`), dejando el cadáver en el mapa.

---

## 2. Parte B — Caravana nocturna de contrabando

- **Archivos modificados:**
  - `scripts/systems/VillageUnderworld.gd`
  - `scripts/systems/VillageNeeds.gd`
  - `scripts/systems/VillageManager.gd`
  - `scripts/enemies/VillageNPC.gd`
  - `scripts/enemies/NPCDialogue.gd`
  - `scripts/visuals/AnimalModel3D.gd`
- **Coordenada y horario del campamento (`SMUGGLER_CAMP_POS = Vector2(1350.0, -560.0)`, `SMUGGLER_BORDER_POS = Vector2(1386.0, -584.0)`):**
  - Verificado que `Vector2(1350, -560)` cae en claro caminable al norte de la mansión señorial (`solar f1`, cuyo rectángulo termina en `y = -500`), sin pisar edificios ni salirse del mapa.
  - En `VillageUnderworld.on_hour(vm, h)` (invocado desde `VillageManager._on_hour_passed`), las noches con `(today() - 1) % 3 == 0` y `caravan_busted_day != today()`, de **22:00 a 4:00**, `spawn_smuggler_caravan(vm, true)` instala el campamento con el contrabandista forastero «El Encapuchado» (`merchant_id = "smuggler"`), su carro (`SmugglerCampCart`, modelo 3D `fantasy_town/cart.glb`) y su farol tenue (`fantasy_town/lantern.glb` con `dim_omni_light = true` en `AnimalModel3D.gd`). A las **4:00** (o al ser descubierta/desmantelada) se retira con `despawn_smuggler_caravan(vm)`.
- **Trato en el carro (`SmugglerTradeArea`, `caravan_buy`, `caravan_sell`):**
  - El carro expone dos `Area2D` del grupo `"interactable"` (`SmugglerTradeArea`):
    - `"buy"`: «Comprar lote de contrabando (−25 oro → +2 polvo de ocaso)», que llama a `caravan_buy(vm, inv, true, interactor)` exigiendo **doble E** (`VillageHousing.press_twice(vm, "caravana_contrabando")`).
    - `"sell"`: «Vender polvo de ocaso (+35 oro)», que llama a `caravan_sell(vm, inv, interactor)`.
  - Eliminadas del diálogo del perista (`VillageUnderworld.add_dialogue_choices`) las opciones `underworld_caravan_buy` y `underworld_caravan_sell`.
- **Riesgo de guardia testigo (`_find_guard_witness_near`, `_check_and_apply_smuggler_guard_witness`):**
  - Al comprar o vender en el carro, si hay un guardia o comisario despierto y consciente a `< 160 px` con línea de visión (`vm.has_line_of_sight`) y la patrulla no está sobornada esa noche, sube `vm.wanted_level + 1`, se anota en la crónica (`smuggler_caught_live`), se marca `caravan_busted_day = today()` y la caravana huye (`despawn_smuggler_caravan(vm)`).
- **Delatar la caravana a la guardia (`send_guards_to_bust_caravan`, `on_guard_bust_arrived`):**
  - Se mantiene en el diálogo de los guardias «🚨🐪 Avisar a la guardia de la ruta de la caravana de contrabando» (`underworld_caravan_report`), que ahora envía a **dos guardias** andando hacia `SMUGGLER_CAMP_POS` mediante `start_errand("smuggler_bust", SMUGGLER_CAMP_POS)` (con soporte nocturno y en turno en `VillageNPC._is_mandatory_work_hours` y `_update_needs_and_decisions`). Cuando llegan al campamento (`VillageNeeds.tick` → `VillageUnderworld.on_guard_bust_arrived`), el contrabandista huye y se marca `caravan_busted_day = today()`.

---

## 3. Verificación y pruebas

1. **Arranque en modo headless:**
   - Comando: `timeout 60 flatpak run org.godotengine.Godot --headless --path . --quit`
   - Resultado: **OK** (`0` errores de compilación/carga de scripts).
2. **Suite principal `verify_all.gd` (una sola ejecución al cerrar con `timeout 900`):**
   - Comando: `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s res://tools/tests/verify_all.gd`
   - Resultado: **TODOS LOS BLOQUES Y ASERCIONES PASAN (`Block P3 (Physical Trade Route Caravans, Pack Mule & Midnight Smuggler Camp) OK`)**:
     - `P3.1a–P3.1c`: Con `high_pass` activa, a medianoche (`00:00`) no ocurre intercambio mágico; a las `10:00` del día de llegada aparecen el caravanero y su mula en `CARAVAN_PLAZA_POS` y se ejecuta el intercambio entre talleres.
     - `P3.2a–P3.2b`: Interactuar con la mula en la plaza entrega `2 bread` a cambio de `2 iron_ore` y `+8` de oro; tras retirarse la caravana de la plaza, `send_player_shipment` devuelve `false`.
     - `P3.3a–P3.3b`: Matar al caravanero fija `vm.merchant_suspension_days["high_pass"] == 7` y deja el cadáver en el mundo.
     - `P3.4a–P3.4e`: A las `22:00` en noche de contrabando aparecen el contrabandista y su carro en `SMUGGLER_CAMP_POS`, comprar exige doble `E` (`-25` oro → `+2 dusk_dust`), y vender con un guardia despierto a `< 160 px` sube `wanted_level` y marca `caravan_busted_day`.
