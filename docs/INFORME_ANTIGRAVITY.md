# Informe de Antigravity — Bloque P2: La carreta física (+ arreglo de P1)

**Fecha:** 2026-11-06  
**Encargo:** `docs/ENCARGO_P2_CARRETA.md` (Fila 3 de `docs/AUDITORIA_REALISMO.md`, más el ajuste de la sección 0).

---

## 0. Arreglo pequeño de P1 (`SHOP_STOCK_PER_PRESS = 6`)
- En `scripts/systems/VillageHousing.gd`:
  - Añadida la constante `SHOP_STOCK_PER_PRESS: int = 6`.
  - En `VillageHousing.stock_player_shop(vm, inv)`: cambiado el tope de artículos transferidos por pulsación de `2` a `SHOP_STOCK_PER_PRESS` (`6`).
- En `tools/tests/verify_all.gd`:
  - Ajustada la comprobación `P1.1b` (y el stock restante en `P1.2a`, `P1.2c` y `P1.3b`) para verificar que con 7 panes en la mochila una pulsación en el mostrador pasa exactamente 6 y deja 1 en la mochila.

---

## 1. La carreta existe en el mapa
- **Script nuevo `scripts/obstacles/PlayerCart.gd`:**
  - Extiende `Node2D`, se añade al grupo `"player_cart"` y sigue la estructura de `scripts/obstacles/PlayerHorse.gd`.
  - Tiene `interact_area: Area2D` en el grupo `"interactable"` (radio `22.0` px y comprobación de alcance `CART_RANGE = 26.0` px) con `get_interact_label(player)` e `interact(player)`.
  - **Modelo 3D:** adjunta `assests/curated_3d/fantasy_town/cart.glb` mediante `AnimalModel3D.attach(self, "fantasy_town/cart.glb", 10.5, 4.0)`, escalado para medir ~26 px de largo (equivalente al caballo) y girando automáticamente en la dirección del movimiento.
  - **Dibujo 2D (provisional):** clase interna `CartSprite2D` (`Node2D`) que dibuja con `draw_rect` un carro marrón de madera con varales y dos ruedas oscuras, visible al alternar a vista 2D con `[F10]` y oculto en vista 3D (`_process`). Se deja apuntado como provisional.
- **Sincronización y estado en `scripts/systems/VillageCulture.gd`:**
  - `CART_DEFAULT_POS: Vector2 = Vector2(385, 470)` (junto al Rancho del Sur, al lado de `HORSE_DEFAULT_POS`).
  - `VillageCulture.mounts_state(vm)` inicializa y persiste `"cart_x"`, `"cart_y"`, `"cart_mode"` (`"parked"`, `"hand"`, `"horse"`) y `"cart_cargo"` (`Dictionary`).
  - `VillageCulture.sync_player_cart(vm)` crea, recoloca o elimina el nodo del grupo `"player_cart"` según `has_cart(vm)` y restaura el modo al cargar. Se llama en `buy_mount(vm, "cart", seller, inv)` y en `after_load(vm)` (igual que `sync_player_horse`).

---

## 2. Moverla: a mano o con caballo
- **Letreros e interacción en `PlayerCart.gd`:**
  - `get_interact_label(player)`:
    - Con `cart_mode == "parked"` y a pie: `«Agarrar la carreta»`.
    - Con `cart_mode == "hand"`: `«Soltar la carreta»`.
    - Con `cart_mode == "parked"` y montado (`player.is_mounted`): `«Enganchar la carreta al caballo»`.
    - Con `cart_mode == "horse"`: `«Desenganchar»`.
  - `grab_by_hand(player)`, `release_cart(player, stay_at, custom_msg)`, `hitch_to_horse(player)` y `unhitch_from_horse(player, stay_at, custom_msg)` actualizan `player.is_pulling_cart`, `player.is_cart_hitched` y `mounts_state(vm)["cart_mode"]`.
  - En `scripts/ui/InteractionSelector.gd` (`refresh`): cuando la carreta ya va agarrada o enganchada en marcha, su prioridad de `[E]` se sitúa detrás de puertas y vecinos cercanos (igual que `"player_horse"` montado) para no estorbar al abrir puertas o hablar.
- **Velocidades y restricciones en `scripts/PlayerMovementController.gd` y `scripts/Player.gd`:**
  - Constantes `CART_HAND_SPEED_MULT: float = 0.55` y `CART_HORSE_SPEED_MULT: float = 0.80` junto a `MOUNT_SPEED_MULT`.
  - A pie tirando de la carreta (`is_pulling_cart`): velocidad `×0,55`, sin correr (`wants_sprint = false`), sin sigilo (`is_stealthing = false`, bloqueada tecla `C` en `_unhandled_input`) y sin rodar (`start_roll` devuelve `false` con aviso).
  - Enganchada al caballo (`is_mounted` + `is_cart_hitched`): velocidad del caballo `×0,80` (`MOUNT_SPEED_MULT * CART_HORSE_SPEED_MULT`) y sin sigilo.
- **Seguimiento por rastro y suelta automática (`PlayerCart._place_behind_leader`, `PlayerCart._physics_process`):**
  - Guarda los puntos por donde pasa el jugador en `_trail` (cada `TRAIL_STEP = 2.0` px) y coloca la carreta sobre la polilínea del rastro a `TRAIL_DIST = 22.0` px detrás del jugador, sin `CollisionShape2D` de choque físico para no atascarse ni cortar esquinas atravesando edificios.
  - No se puede agarrar ni enganchar dentro de un edificio (`_is_inside_building`).
  - Al entrar en un edificio, acostarse (`is_resting_in_bed`) o ir escoltado/preso (`player_being_escorted_to_jail` / `player_in_jail`), si ibas tirando a mano se suelta sola en `_last_outside_pos` (junto a la puerta). Si bajas del caballo con la carreta enganchada (`cart_mode == "horse"` y `not player.is_mounted`), la carreta permanece enganchada al caballo y quieta donde esté.

---

## 3. La caja de carga (40 unidades)
- **Nota sobre la ventana existente:** en el código no existía ninguna ventana reutilizable de dos columnas para cofres (el cofre del campamento en `CampSite._setup_chest_ui` y el escondite en `VillageHousing.open_home_stash_menu` solo guardan/sacan oro mediante botones simples, y `VillageManager._interact_house_chest` en cofres propios solo muestra un texto flotante). Tal como indica el encargo, se ha construido una ventana sencilla de dos listas en `PlayerCart._setup_cargo_ui()`.
- **Implementación en `PlayerCart.gd` y `Player.gd`:**
  - Segundo `Area2D` (`cargo_area`, clase interna `CartCargoArea` en el grupo `"interactable"`) que, cuando la carreta está parada (`is_stopped`), ofrece el segundo letrero `[E] Abrir la caja de carga (X/40)` (`get_cargo_interact_label`). En marcha o agarrada devuelve `""` para no mostrarse.
  - Capacidad máxima `CARGO_CAPACITY = 40` unidades sumando todos los objetos (`get_cargo_total()`); el oro no cabe (`put_item` rechaza `"gold"`).
  - Funciones `put_item(inv, item_id, qty)`, `put_all_from_inventory(inv, item_id)` y `take_item(inv, item_id, qty)` conectadas a los botones `«Meter 1»`, `«Meter todo»` y `«Sacar 1»` de la ventana `cargo_panel`.
  - `Player.is_any_ui_modal_open()` comprueba `cart.cargo_panel.visible` para bloquear el movimiento mientras la ventana de carga está abierta.

---

## 4. Riesgo: robo de carga por la noche
- **Implementación en `VillageCulture.cart_night_theft(vm, chance)` y `VillageCulture.is_cart_in_safe_place(vm, pos)` (llamado en `VillageHousing.daily(vm)` junto a `shop_night_theft`):**
  - Comprueba que la carreta esté aparcada (`cart_mode == "parked"`), tenga carga y esté fuera de un lugar seguro: a `>= 90.0` px del centro de todos los solares construidos del jugador (`VillageHousing.player_lots(vm, true)` + `VillageLots.lot_def(lid)["center"]`) y fuera del corral del Rancho del Sur (`RANCH_CORRAL_RECT = Rect2(310, 400, 87, 140)`).
  - Probabilidad `CART_THEFT_CHANCE = 0.12` (12 %).
  - **Ladrón y cantidad:** elige al vecino vivo adulto (`trade_role != CHILD`) y no forastero (`not VillageNeeds.is_outsider(n)`) con menos `personal_gold`. Se lleva la mitad de las unidades redondeando hacia abajo, máximo 10 (`mini(10, int(floor(float(units.size()) / 2.0)))`), elegidas al azar.
  - **Suma cero (dónde guarda cosas un vecino):** `house_chests` solo guarda metadatos (`looted_day`, `planted_evidence`) y `house_pantry` solo guarda un entero de raciones de comida por familia, pero cada `VillageNPC` ya tiene su diccionario persistente de objetos `pocket_items` y el método `add_pocket_item(item_id, count)` (usado también en P1 cuando un cliente compra en el mostrador). Los objetos robados de `cart_cargo` pasan directamente a `thief.add_pocket_item(it_id, 1)`, conservando exactamente el total de objetos (carreta + ladrón).
  - **Testigo y aviso:** consulta `vm._find_conscious_witness_near(cart_pos, 160.0, thief)`. Si hay testigo, añade a la crónica `«%s vio a %s llevarse carga de tu carreta»`; si no, `«Alguien se llevó carga de tu carreta por la noche»`. Muestra aviso matinal al jugador con `pl.show_hint(...)` detallando qué objetos faltan.

---

## 5. Quitar lo viejo
- En `VillageCulture.send_player_shipment(vm, route_id, inv)`: el bono de `+4` de oro solo se suma si `VillageCulture.is_cart_near_player(vm, 60.0)` es cierto (la carreta está a menos de 60 px del jugador).
- En `VillageCulture.add_dialogue_choices`: el texto de compra al ganadero es ahora `«🛒 Comprar Carreta de Carga (-55 Oro al ganadero): la recoges en el rancho; caben 40 cosas»`.

---

## 6. Archivos tocados
1. `scripts/obstacles/PlayerCart.gd` (nuevo)
2. `scripts/systems/VillageCulture.gd`
3. `scripts/systems/VillageHousing.gd`
4. `scripts/PlayerMovementController.gd`
5. `scripts/Player.gd`
6. `scripts/ui/InteractionSelector.gd`
7. `tools/tests/verify_all.gd`
8. `CHANGELOG.md`, `docs/HANDOFF.md`, `docs/REGISTRO_TRABAJO.md`, `docs/INFORME_ANTIGRAVITY.md`, `GameVault/02_Sistemas/Caballos y Expediciones.md`, `GameVault/02_Sistemas/Vivienda e Hipotecas.md`, `GameVault/05_Roadmap_y_Lore/Tablero.md`, `GameVault/06_Diario/2026-11-06.md`

---

## 7. Prueba ejecutada (`verify_all`)
- Comando: `timeout 900 flatpak run org.godotengine.Godot --headless --path . --script tools/tests/verify_all.gd`
- Estado: en ejecución (se actualizará al terminar la tarea en segundo plano).
