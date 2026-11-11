# Encargo P2 — La carreta física (borrador listo; se copia a `ENCARGO_ANTIGRAVITY.md` §2 cuando P1 esté aprobado)

> Escrito por Claude Code (supervisor), 2026-11-06. Decisiones de diseño **ya tomadas por el usuario**: no cambies
> ninguna. Si algo no encaja con el código, **no improvises**: apúntalo en el informe y pregunta.
> Fila 3 de `docs/AUDITORIA_REALISMO.md`.

## Reglas de este bloque (orden del usuario)

- Lee solo lo necesario: este encargo, `CLAUDE.md`, `scripts/obstacles/PlayerHorse.gd` (tu modelo a seguir) y las
  funciones que se nombran aquí. No hace falta releer todo `HANDOFF.md`.
- **No pases pruebas mientras trabajas.** Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`).
- No toques nada fuera de este encargo. Si ves otra cosa rota, apúntala en el informe.

## 0. Arreglo pequeño de P1 (antes de empezar)

`VillageHousing.stock_player_shop` pasa solo 2 objetos por pulsación (`added < 2`). Cámbialo a **6** por pulsación
(constante `SHOP_STOCK_PER_PRESS = 6`). Ajusta el test P1 que lo compruebe si lo hay.

## Cómo está ahora

`VillageCulture.buy_mount(vm, "cart", …)` cobra `CART_COST` (55) al ganadero y pone `mounts_state["has_cart"] = true`.
No hay ninguna carreta en el mapa. Su único efecto es +4 de oro en `send_player_shipment` (línea ~1034).

## Qué hay que hacer

### 1. La carreta existe en el mapa
- Script nuevo `scripts/obstacles/PlayerCart.gd`, **copiando la estructura de `PlayerHorse.gd`**: `Node2D`, grupo
  `player_cart`, `Area2D` del grupo `interactable` con `get_interact_label(player)` e `interact(player)`.
- Función `VillageCulture.sync_player_cart(vm)` igual que `sync_player_horse`: crea o quita la carreta según
  `has_cart`. Llámala en los mismos sitios donde se llama `sync_player_horse` (compra, `after_load`).
- Sitio inicial al comprarla: junto al Rancho del Sur, al lado del caballo: `CART_DEFAULT_POS = Vector2(385, 470)`.
- **3D:** usa el modelo `assests/curated_3d/fantasy_town/cart.glb` (el mismo estilo del pueblo). Escálalo para que
  mida más o menos lo mismo que el caballo de largo. **2D:** dibujo provisional (un rectángulo marrón con dos ruedas
  dibujadas con `draw_*`, o un sprite existente teñido); apúntalo en el informe como provisional.
- La carreta mira hacia donde avanza (gira el modelo 3D con la dirección del movimiento).

### 2. Moverla: a mano o con caballo (decisión del usuario)
- Letreros de [E] junto a la carreta (radio 26 px, como el caballo):
  - Sin enganchar y tú a pie: **«Agarrar la carreta»**. Con ella agarrada: **«Soltar la carreta»**.
  - Sin enganchar y tú montado en tu caballo: **«Enganchar la carreta al caballo»**. Enganchada: **«Desenganchar»**.
- Velocidad (aplícalo en `PlayerMovementController`, junto al `MOUNT_SPEED_MULT` que ya existe):
  - A pie tirando de ella: velocidad ×0,55. Sin correr, sin sigilo y sin rodar (Espacio) mientras la llevas.
  - Enganchada al caballo: la velocidad del caballo ×0,80 (frena un poco). Sin sigilo.
- Cómo sigue al jugador: va **detrás**, a 22 px, siguiendo **el rastro** que deja el jugador (guarda los últimos puntos
  por donde pasó y colócala en el que esté a 22 px). Así no corta esquinas atravesando casas. No le pongas cuerpo de
  choque (no debe atascarse); solo sigue el rastro.
- Se suelta sola, igual que el caballo (`PlayerHorse._physics_process`): al entrar en un edificio se queda en la puerta
  (última posición fuera), al acostarte, si te escolta la guardia o vas a la cárcel. Si bajas del caballo con la carreta
  enganchada, la carreta se queda enganchada al caballo, quieta donde esté.
- No se puede agarrar dentro de un edificio (mismo `_is_inside_building` del caballo).
- Se guarda en `mounts_state`: `cart_x`, `cart_y`, `cart_mode` (`"parked"`, `"hand"`, `"horse"`) y `cart_cargo`.

### 3. La caja de carga (40 unidades)
- Con la carreta **parada** (no agarrada ni en marcha), un segundo letrero de [E]: **«Abrir la caja de carga
  (X/40)»**. Usa la misma ventana de dos columnas que el cofre de casa (mochila ↔ caja) si existe; si no hay ninguna
  reutilizable, haz una sencilla de dos listas con botones «Meter 1» / «Sacar 1» / «Meter todo» y dilo en el informe.
- Capacidad: **40 unidades en total** (sumando todos los objetos; el oro no cabe en la caja).
- La carga viaja con la carreta: nada se teletransporta.

### 4. Riesgo: robo de carga por la noche (decisión del usuario)
- Al pasar la noche (en el mismo ciclo diario donde se llama `shop_night_theft`), si la carreta está **aparcada lejos
  de un lugar seguro** y tiene carga, hay un **12 %** de probabilidad de robo.
- Lugar seguro: a menos de 90 px del centro de un solar tuyo construido (`VillageHousing.player_lots(vm, true)` +
  `VillageLots.lot_def(id)["center"]`) o dentro del corral del Rancho del Sur (`Rect2(310, 400, 87, 140)`).
- Quién roba: el vecino adulto, no forastero, **con menos oro** (el mismo criterio de `shop_night_theft`). Se lleva la
  **mitad de las unidades, redondeando hacia abajo, máximo 10**, eligiendo los objetos al azar.
- **Suma cero:** lo robado pasa a ese vecino. Busca dónde guarda cosas un vecino (despensa o cofre de su familia,
  `family_lot_…`). **Si no hay ningún sitio para objetos de vecinos, no lo inventes:** apúntalo en el informe y deja
  ese paso sin hacer (el supervisor decidirá).
- **Testigo:** usa `vm._find_conscious_witness_near(pos_carreta, 160, ladrón)`. Si hay testigo, la crónica dice quién fue
  («%s vio a %s llevarse carga de tu carreta»); si no, solo «Alguien se llevó carga de tu carreta por la noche».
- Por la mañana, aviso al jugador con `show_hint` diciendo qué falta.

### 5. Quitar lo viejo
- El +4 de oro de `send_player_shipment` solo cuenta si la carreta está **a menos de 60 px del jugador** al enviar la
  remesa (llevar la carreta tiene sentido). Cambia el texto del diálogo de compra: «🛒 Comprar Carreta de Carga (-55 Oro
  al ganadero): la recoges en el rancho; caben 40 cosas».
- La compra sigue siendo en la charla con el ganadero (es un trato con una persona). No hace falta doble E.

### 6. Prueba (una sola, en `verify_all`)
Un bloque «P2 carreta» con estas comprobaciones, **sin poner a mano datos que el juego no crea** y **sin tipos de clase
del juego** en las variables (`var x = …`, nunca `var x: PlayerCart`; eso cuelga la prueba):
1. Comprar la carreta crea un nodo del grupo `player_cart` en `CART_DEFAULT_POS`.
2. Meter 41 troncos en la caja: entran 40, queda 1 en la mochila.
3. Aparcada lejos de casa con carga y forzando el robo (probabilidad 1): el ladrón es el vecino más pobre y el total de
   objetos (carreta + ladrón) no cambia.
4. Tirando de ella a pie, la velocidad es ×0,55.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: **reescríbelo entero** (qué hiciste, archivos, la prueba y su resultado, lo que no
   pudiste hacer y por qué). **Nombra solo funciones que existan** (el supervisor lo comprueba).
2. Commit en español y push a `main`. No subas la carpeta `.claude/`.
