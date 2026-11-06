# Informe de Antigravity para el Supervisor (Claude Code) — Bloque P1

> Fecha: 2026-11-06
> Alcance ejecutado: **Bloque P1** (`docs/ENCARGO_ANTIGRAVITY.md` §2: hacer física la tienda propia «Bazar del Forastero» en 2D y 3D con mostrador y caja interactivos con `[E]`, dependiente que camina de verdad al mostrador y clientes reales que van andando a comprar).

---

## 1. Qué se hizo exactamente

### 1.1. Mostrador y caja físicos en 2D y 3D (`player_shop_counter`)
- **En el solar de la tienda (`player_shop["lot"]`):**
  - `VillageHousing.sync_home_props(vm)` instancia un `WorldInteractableProp` (`prop_kind = "player_shop_counter"`, nodo `PlayerShopCounter_<lid>`) dentro del solar donde se abrió el «Bazar del Forastero» (`home_prop_pos(rect, row, "player_shop_counter")` en `c + Vector2(-16.0, -4.0 * m)`, dentro del interior caminable incluso en casitas `small` de `84x62`).
  - Se invoca también en `VillageManager.setup_village()` y `VillageManager.after_load()` para restaurar el mostrador y demás muebles domésticos al iniciar o cargar partida.
  - **2D (`WorldInteractableProp._draw_player_shop_counter_2d()`):** dibuja mostrador de roble con tapete de exposición, fardos/frascos cuando `stock > 0` y arqueta de hierro con brillo de monedas cuando `till_gold > 0`.
  - **3D (`WorldStage3D._sync_home_props_3d()`):** incluye el estado de `player_shop` (`has_shop`, `stock`, `till_gold`) en la firma `_home_props_sig` y construye en el solar de la tienda un mostrador de madera con arqueta de recaudación (y pila de monedas doradas si `till_gold > 0`) más mercancía expuesta cuando `stock > 0`.
- **Interacción con `[E]` (`VillageHousing.open_player_shop_counter_menu`):**
  - Al pulsar `[E]` frente al mostrador se abre el menú del «Bazar del Forastero» con:
    - **«Reponer mercancía (de tu mochila)»** (`stock_player_shop(vm, inv)`), que traslada hasta 6 objetos vendibles de la mochila real del jugador al inventario `goods` del mostrador.
    - **«Recoger la caja (N de oro)»** (`collect_player_shop_till(vm, inv)`), que pasa `till_gold` al bolsillo del jugador y reinicia `till_since_day`.
- **Limpieza del diálogo con vecinos (`VillageHousing.add_dialogue_choices`):**
  - Eliminadas las opciones `"housing_stock_shop"` y `"housing_collect_shop"` de la conversación con vecinos.
  - Se mantienen en conversación `"housing_advertise_shop"` (encargar pregón por 10 de oro durante 3 días) y `"housing_hire_clerk"` (contratar como dependiente al vecino con el que hablas).

### 1.2. Dependiente que camina de verdad (`player_shop_clerk`)
- **Horario comercial (`SHOP_OPEN_HOUR = 8` a `SHOP_CLOSE_HOUR = 18`):**
  - En `VillageHousing.on_hour(vm, hour)` (llamado desde `VillageManager._on_hour_passed`), durante las horas abiertas el vecino contratado (`player_shop["clerk_key"]`) recibe el recado físico `start_errand("player_shop_clerk", player_shop_clerk_pos(vm))` (detrás del mostrador) si está despierto, libre de combate/arresto y no está ya en su puesto; a partir de las 18:00 finaliza su turno (`finish_errand()`).
  - En `VillageNeeds.tick(vm)`, el recado `"player_shop_clerk"` no expira a las 2 horas mientras la tienda sigue abierta, manteniendo al dependiente detrás del mostrador.
  - En `VillageWork.hire(vm)` (7:00 AM), se excluye a `player_shop["clerk_key"]` de la contratación automática como jornalero de campo/rancho/cantera para que no abandone la tienda.
- **Presencia física obligatoria y jornal:**
  - `VillageHousing.is_player_shop_clerk_present(vm)` comprueba que el dependiente exista, no esté muerto/arrestado/dormido/huyendo y se encuentre físicamente a `<= 42 px` (`SHOP_CLERK_RADIUS`) de su puesto detrás del mostrador. **Si el dependiente no está en el mostrador, la tienda no vende.**
  - Su jornal diario (`CLERK_WAGE = 4`) sigue descontándose de `till_gold` en `pay_player_shop_clerk(vm)` al cierre diario (`daily(vm)`); si la caja no alcanza para pagarle, deja el puesto.

### 1.3. Clientes reales andando durante el día (`player_shop_buy`)
- **Eliminación de ventas automáticas a medianoche:**
  - `VillageHousing.daily(vm)` ya no vende artículos en bucle a medianoche: solo liquida el jornal del dependiente (`pay_player_shop_clerk`), aplica el riesgo de `shop_night_theft` sobre la caja que haya quedado sin recoger de días previos (`till_since_day < cur_day`), descuenta `ad_days` y reinicia `buyers_today = 0`.
- **Despacho y compra física en el mostrador:**
  - Cada hora comercial (`on_hour`), si el dependiente está presente en el mostrador y queda `stock > 0`, hasta `max_Send` vecinos elegibles (con `personal_gold >= min_price + 12`, sin recado activo, fuera de combate/arresto; `1` por hora de base o `2` con publicidad activa `ad_days > 0`, hasta el tope diario `2 + (2 si ad_days > 0)`) inician el recado `"player_shop_buy"` caminando hacia `player_shop_customer_pos(vm)` (delante del mostrador).
  - Cuando el vecino llega físicamente al mostrador (`VillageNeeds.tick(vm)` → `VillageHousing.on_customer_arrived(vm, n)`), vuelve a verificarse `is_player_shop_clerk_present(vm)` y que haya `stock > 0`; entonces el cliente compra 1 artículo real de `goods` que pueda permitirse (`personal_gold >= price + 12`), paga `price` de su `personal_gold` a `till_gold` (suma cero), recibe el objeto (`receive_good`) o sacia hambre si es comida, sube satisfacción/ánimo y actualiza el visual del mostrador.

---

## 2. Archivos modificados

| Archivo | Funciones / métodos tocados |
|---|---|
| `scripts/systems/VillageHousing.gd` | `SHOP_OPEN_HOUR`, `SHOP_CLOSE_HOUR`, `SHOP_CLERK_RADIUS`, `hire_player_shop_clerk`, `collect_player_shop_till`, `player_shop_lot`, `player_shop_counter_pos`, `player_shop_clerk_pos`, `player_shop_customer_pos`, `is_player_shop_open_hour`, `get_player_shop_clerk`, `is_player_shop_clerk_present`, `pay_player_shop_clerk`, `on_hour`, `on_customer_arrived`, `_refresh_shop_counter_visual`, `daily`, `add_dialogue_choices`, `on_dialogue_choice`, `sync_home_props`, `home_prop_pos`, `get_player_shop_counter_label`, `open_player_shop_counter_menu` |
| `scripts/obstacles/WorldInteractableProp.gd` | `_ready`, `_draw`, `_draw_player_shop_counter_2d`, `get_interact_label`, `interact` |
| `scripts/visuals/WorldStage3D.gd` | `_sync_home_props_3d` |
| `scripts/systems/VillageNeeds.gd` | `tick` (permanencia de `"player_shop_clerk"` en horario comercial y llegada de `"player_shop_buy"` al mostrador) |
| `scripts/systems/VillageWork.gd` | `hire` (exclusión de `player_shop["clerk_key"]` de cuadrillas de jornaleros) |
| `scripts/systems/VillageManager.gd` | `setup_village`, `_on_hour_passed`, `after_load` |
| `scripts/enemies/VillageNPC.gd` | `get_activity_description` (`"player_shop_clerk"` y `"player_shop_buy"`) |
| `tools/tests/verify_all.gd` | Actualizado `PG.2e` al flujo físico y añadido `Block P1` (`P1.0` a `P1.4`) |
| `docs/HANDOFF.md` | Entrada superior en §7 para el bloque `P1` |
| `CHANGELOG.md` | Entrada en lenguaje de jugador para `P1` |
| `docs/REGISTRO_TRABAJO.md` | Fila `P1` en la tabla del Bloque P |
| `GameVault/02_Sistemas/Vivienda e Hipotecas.md` | Actualizada sección «Bazar del Forastero» y nota de diseño `P1` |
| `GameVault/05_Roadmap_y_Lore/Tablero.md` | Tarjeta completada en `✅ Hecho` y actualizada lista de pendientes físicos |
| `GameVault/06_Diario/2026-11-06.md` | Línea en `✅ Qué hice hoy` |

---

## 3. Pruebas ejecutadas y resultados

Siguiendo la regla del usuario (*al cerrar pasa UNA sola prueba: `verify_all` con `timeout 900`, no las cuatro; mientras trabajas no pases pruebas*), se añadieron los tests del bloque en `tools/tests/verify_all.gd` (`Block P1`):
- **`P1.0`:** el mostrador físico (`player_shop_counter`) existe en el solar de la tienda, y las opciones `"housing_stock_shop"` y `"housing_collect_shop"` ya no aparecen en el diálogo con vecinos (mientras que `"housing_advertise_shop"` y `"housing_hire_clerk"` sí siguen en conversación).
- **`P1.1`:** reponer mercancía en el mostrador saca objetos reales de la mochila del jugador y los coloca en `goods`/`stock` de la tienda.
- **`P1.2`:** sin dependiente físicamente presente en el mostrador (`is_player_shop_clerk_present == false`), ni las horas del día ni la llegada de un cliente ni `daily(vm)` producen ventas.
- **`P1.3`:** en horario comercial (`10:00`), `on_hour` envía al dependiente detrás del mostrador (`player_shop_clerk`) y despacha clientes reales (`player_shop_buy`); al llegar al mostrador, el cliente compra 1 artículo pagando de su `personal_gold` hacia `till_gold` (suma cero).
- **`P1.4`:** recoger la recaudación en el mostrador transfiere `till_gold` al oro del jugador dejando la caja a `0`.

Resultado de `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd`:
- **`Block PG` y `Block P1`:** `OK`
- **Resultado global:** `TESTS PASSED!`, `0` errores de script (`SCRIPT ERROR`), `exit code 0`.

---

## 4. Qué quedó pendiente o anotado

- Nada pendiente dentro del alcance de `P1`.
- Carpeta `.claude/` excluida del commit y del push según instrucciones.
