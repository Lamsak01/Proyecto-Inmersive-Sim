# Encargo P3 — Caravanas comerciales y de contrabando hechas físicas (borrador listo)

> Escrito por Claude Code (supervisor), 2026-11-06. Decisiones de diseño **ya tomadas por el usuario**: no cambies
> ninguna. Si algo no encaja con el código, **no improvises**: apúntalo en el informe y pregunta.
> Filas 5 y 6 de `docs/AUDITORIA_REALISMO.md`.

## Reglas de este bloque (orden del usuario)

- Lee solo lo necesario: este encargo, `CLAUDE.md` y las funciones que se nombran aquí. Tu modelo para un forastero que
  llega andando, se queda y se va es el **mercader ambulante semanal** de `VillageManager`
  (`_check_weekly_merchant_arrival`, `update_traveling_merchant_ai`): reutiliza su forma de aparecer, caminar y marcharse.
- **No pases pruebas mientras trabajas.** Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`). Nada de tipos de clase del juego en las variables del test (`var x = …`), que cuelga la prueba.
- No toques nada fuera de este encargo. Si ves otra cosa rota, apúntala en el informe.

---

## Parte A — Caravanas de las rutas comerciales

### Cómo está ahora
`VillageCulture.process_trade_routes` intercambia mercancía sola a medianoche en cada ruta activa (`trade_routes_of`:
`high_pass`, `river_port`, `sun_plain`), y `send_player_shipment` (tu remesa) se hace en la charla con un artesano.

### Decisión del usuario: **una caravana por ruta y por semana**, con 0–1 días de retraso al azar
- Día de llegada de cada ruta (día de la semana de `WorldClock.get_weekday()`, 0 = lunes), elegidos para no coincidir
  con los mercaderes ambulantes (que vienen los días `current_day % 7 == 3` y `== 6`):
  `high_pass` → lunes (0), `river_port` → martes (1), `sun_plain` → jueves (3 de la semana).
  Si eso choca con los días de los mercaderes en el calendario real del juego, **dilo en el informe** y no lo cambies.
- Retraso: el día de llegada se tira una vez por semana: 70 % llega ese día, 30 % al día siguiente («el camino estaba
  embarrado»). Guarda `next_caravan_day` en la ruta.

### Cómo es la caravana
- **Personajes:** un **mercader forastero** (un `VillageNPC` forastero como el mercader ambulante, con nombre de la
  ruta, p. ej. «Caravanero de Paso Alto») y **una mula de carga** detrás (modelo 3D de animal existente; si no hay mula,
  usa el caballo de `AnimalModel3D` más pequeño y teñido, y dilo en el informe). En 2D, sprite provisional.
- **Recorrido:** aparece a las **9:00** en el camino del este (`VillageCulture.RAID_GATE_POS`, `Vector2(1400, 50)`),
  camina hasta la **plaza** (`Vector2(465, 48)`, la misma que usa `Raider.LOOT_POS`) y se queda allí **de 10:00 a
  16:00**. A las 16:00 vuelve andando por el mismo camino y desaparece al llegar al borde.
- **El intercambio de la ruta ocurre cuando la caravana está en la plaza**, no a medianoche: mueve lo que ahora hace
  `process_trade_routes` para una ruta a la llegada de su caravana a la plaza (una vez por visita). Quita el
  intercambio de medianoche para las rutas que ya tienen caravana. El oro y las mercancías siguen las mismas reglas de
  ahora (suma cero: no cambies cantidades ni a quién se paga).
- La recarga semanal de `balance` (`ROUTE_WEEKLY_REFILL`) pasa a hacerse cuando llega la caravana (trae el dinero del
  pueblo de fuera), no los lunes.

### Tu remesa, en la caravana
- Mientras la caravana está en la plaza, junto a la mula hay un `Area2D` del grupo `interactable` con
  `get_interact_label(player)`: **«Cargar tu remesa para %s (−%d %s → +%d %s y +%d oro)»**, con los mismos números que
  ahora. Al pulsar [E] se llama a `send_player_shipment` (misma regla: una vez por día y ruta, y el +4 de la carreta si
  está a menos de 60 px, como dejó P2).
- **Quita** la opción «📦 Enviar remesa…» del diálogo con artesanos (`add_dialogue_choices`, ~línea 1739). Abrir la
  ruta («📜 Abrir ruta comercial…») **sigue en el diálogo** (es un trato con personas).
- Si matan al caravanero: igual que con el mercader ambulante (`on_traveling_merchant_murdered`): esa ruta queda
  suspendida (usa la misma idea de `merchant_suspension_days`, 7 días) y el cuerpo queda en el mapa.

---

## Parte B — Caravana nocturna de contrabando

### Cómo está ahora
`VillageUnderworld.is_caravan_here(st)` dice que hay caravana las noches en que `(today() - 1) % 3 == 0`, de 21:00 a
4:00, pero no hay nadie en el mapa; compras y vendes hablando con el perista detrás de la taberna.

### Decisión del usuario: **se mantiene el ritmo de cada 3 noches**, pero con el carro de verdad en el mapa
- Las mismas noches que ahora (`is_caravan_here`), de **22:00 a 4:00**, acampa en el **lindero noreste**:
  `SMUGGLER_CAMP_POS = Vector2(1350, -560)`. Si ese punto no es caminable o queda fuera del mapa, muévelo al punto
  caminable más cercano del borde noreste y **apunta en el informe** la posición final.
- **En el campamento:** un **contrabandista** forastero (`VillageNPC`, nombre «El Encapuchado»), su **carro** (el modelo
  `assests/curated_3d/fantasy_town/cart.glb`, el mismo de la carreta de P2) y un **farol apagado** (en 3D, luz muy
  tenue). Llega andando desde el borde a las 22:00 y se va a las 4:00.
- **Comerciar:** junto al carro, `Area2D` del grupo `interactable` con dos letreros, los mismos tratos y precios de
  ahora: «Comprar lote de contrabando (−25 oro → +2 polvo de ocaso)» y «Vender polvo de ocaso (+35 oro)». Reutiliza la
  lógica de `underworld_caravan_buy` / `underworld_caravan_sell` en `on_player_action` (muévela a funciones que se
  llamen desde el carro). Gastar oro pide **doble E** (`VillageHousing.press_twice(vm, "caravana_contrabando")`).
- **Quita** esas dos opciones del diálogo con el perista (~líneas 876–880). La opción «🚨🐪 Avisar a la guardia de la
  ruta de la caravana» **sigue en el diálogo** con la guardia (es un trato con personas).
- **Riesgo real:** si al comprar o vender hay un **guardia despierto** a menos de 160 px que te vea
  (`vm._find_conscious_witness_near(pos, 160, null)` y que sea de la guardia), el trato se hace igual pero **sube la
  búsqueda** (`vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)`, como en el resto de `VillageCulture`), la
  crónica lo apunta y esa caravana se va al instante (`caravan_busted_day = today()`).
- Si avisas a la guardia, en vez de desaparecer la caravana: **dos guardias caminan hasta el campamento**
  (`start_errand`) y, al llegar, el contrabandista se va y queda `caravan_busted_day` como ahora.

---

## Prueba (una sola, en `verify_all`): bloque «P3 caravanas»
1. Forzando el día de llegada de `river_port`, a las 9:00 aparece un caravanero en el camino del este, y al llegar a la
   plaza la ruta hace su intercambio una sola vez (mismo oro total antes y después: suma cero).
2. Con la caravana en la plaza, [E] en la mula envía tu remesa; sin caravana, no hay forma de enviarla.
3. Una noche de contrabando, a las 22:00 hay un nodo de contrabandista cerca de `SMUGGLER_CAMP_POS`; comprar sin
   segunda E no gasta oro.
4. Con un guardia despierto al lado, comprar sube `wanted_level` en 1.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: **reescríbelo entero**. **Nombra solo funciones que existan** (el supervisor lo
   comprueba; en P1 nombraste dos que no existían).
2. Commit en español y push a `main`. No subas la carpeta `.claude/`.
