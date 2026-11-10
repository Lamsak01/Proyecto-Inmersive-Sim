# Plan «la lógica sigue al mapa» (sitios de los vecinos)

Pedido por el usuario el 2026-11-10: elegir «lo más eficiente a largo plazo» y **dejar registro de todo lo hecho y lo
que falta**. Cualquier Claude, en cualquier ordenador, sigue desde aquí. Actualiza este archivo al cerrar cada paso.

## El problema
El editor del mapa 3D (`mapa/Mundo3D.tscn`) permite mover y girar edificios, muebles y objetos, pero la lógica del juego
usaba puntos fijos del mapa original. Sondeo `tools/tests/sondeo_edificios_movidos.gd` (mueve todos los edificios
(37, 23) sin tocar la escena; con `-- quieto` no mueve; compara los dos volcados en `user://sondeo_*.json`):
**2026-11-10: 0 de 60 sitios de vecinos (cama, mesa, trabajo) seguían al edificio.**

## La idea
- Lo que el código escribe a mano está en «coordenadas del mapa original». `mapa/anclas.gd` ya sabe traducir un punto
  original a su sitio actual: `Anclas.mover(p)` (edificio movido o girado, mueble movido dentro, objeto ancla).
- **Regla:** todo número fijo de posición pasa por `Anclas.mover()` **una sola vez, donde se escribe**. Lo que se calcula
  después a partir de eso (copias, «+ Vector2(14, 8)», distancias) ya está en coordenadas actuales. Nunca traducir dos
  veces: un punto ya traducido que cae dentro de la planta original de un edificio movido se desplazaría otra vez.
- Más adelante (paso 5), cada vecino recordará también **de qué edificio** es cada sitio, para las partidas guardadas y la
  futura plantilla de edificio.

## Pasos
1. [x] **Casas y trabajos** (hecho 2026-11-10, ver registro): cama, mesa y puesto de trabajo de cada vecino al crearlo y cuando cambian (mudanzas, familia,
   iglesia, posada, préstamos, solares). Medida: el sondeo debe dar 60 de 60.
2. [x] **Zonas fijas y sitios de ocio** (hecho 2026-11-10, ver «Cómo está hecho (paso 2)»): 30 comprobaciones «¿está dentro de este rectángulo fijo?» (`*RECT*.has_point`:
   taberna 12, VillageManagerBase 3, Player 2, Justice 2, NPCSocial 2, Restaurant 1, 3D 6) no siguen a un edificio
   movido (p. ej. «¿está en la taberna?»). Traducir el rectángulo con `Anclas.rect_con(Anclas.buscar(centro), RECT)`
   (hacerlo una vez y guardarlo). Variables del gestor en coordenadas originales (`_tavern_social_pos`,
   `_church_altar_pos`, `_hospital_bed_pos`, `_jail_cell_pos`, pozos…): **no se traducen en sitio**; usar
   `vm.sitio(vm._x)` donde se asignan a un vecino o se comparan. Y `VillagePlaces`: `VillagePlaces` (parque, bancos de la plaza, mirador, biblioteca, taberna, terraza), asientos de
   póker de la taberna y del restaurante.
3. [x] **Trabajos al aire libre** (hecho 2026-11-10, ver «Cómo está hecho (paso 3)»): campos, pesca, leña, patrullas de la guardia, recados.
4. [ ] **Caso I:** pistas, claro, molino, puente viejo, zapato, bandeja del informe (`VillageCase1`, `VillageManager`).
5. [ ] **Partidas guardadas:** guardar «edificio + sitio» y no solo el punto, para que una partida vieja siga bien tras
   mover cosas. Base para la plantilla de edificio.
6. [ ] **Plantilla de edificio** (decisión del usuario, después): pieza nueva en el editor que el juego construye con
   puerta, interior y sus sitios.

## Cómo está hecho (paso 1)
- `VillageManagerBase.sitio(p)` y `sitios(lista)`: traducen puntos originales (`Anclas.mover`).
- `VillageNPC.setup_npc(...)`: **recibe coordenadas originales y las traduce** (cama, mesa, trabajo y `tavern_social_pos`) y
  marca al vecino con `sitios_ok`. Al cargar partida, `from_save_dict` pone después lo guardado (ya actual).
- `VillageManager._sitios_repaso()` (dentro de `_anclas_repaso_final`): traduce una vez los sitios de `trade_configs`
  (`work_pos`, `kin_work_pos`, `bed1_pos`, `bed2_pos`, `table_pos`, `stall_pos`; marca `_sitios`) y los vecinos sin marca.
  `_authority_slots` NO se traducen (alimentan a `setup_npc`, que ya traduce).
- Reasignaciones traducidas en origen: albergue y posada El Candil (`VillageCivic`), mudarse a tu casa (`VillageHousing`),
  obra del carpintero (`VillageLots.on_hour`), maestro, pupitres y puerta de la escuela (`VillageFamily`), expósito en la
  capilla (`VillageLineage`), camas de la taberna y de las casas (`VillageMigration.free_tavern_bed`,
  `free_tavern_beds_count`, `move_into_house`: comparan con `vm.sitios(TAVERN_GUEST_BEDS)`).
- `promote_to_trade` usa `trade_configs` (ya traducido): no se toca.

## Cómo está hecho (paso 2)
- **Dos reglas nuevas**, además de la del paso 1:
  - **Comparar con una zona fija** (`RECT.has_point`, `pos.y > -165`, «¿está en la taberna?»): se pasa la posición
    del vecino o del jugador por `Anclas.desmover(p)` (lo contrario de `mover`: del mundo actual al mapa original) y se
    compara con la constante tal cual. Así no hay que traducir cada rectángulo.
  - **Variables del gestor** (`_church_altar_pos`, `_jail_cell_pos`, `_hospital_bed_pos`, `_cemetery_*`,
    `_morgue_table_positions`, `_tavern_*_pos`, `_compost_pos`) **siguen en coordenadas originales**, porque la
    construcción del mapa (2D y 3D) las usa así. Donde se usan como destino, para teletransportar o para medir
    distancias, van envueltas en `vm.sitio(...)`.
- `Anclas.mover_lista(clave, lista)`: traduce una lista de puntos y la guarda mientras no cambien las anclas.
  **Devuelve la lista guardada: no la modifiques** (cópiala con `assign` si hace falta).
- **Asientos:** devuelven sitios actuales: `VillageTavern.dining_seats`, `poker_seats` y `pick_*`; `VillageRestaurant.indoor_seats`,
  `terrace_seats`, `seats` y `pick_*`. `table_center_for_seat` recibe y devuelve sitios actuales (compara con las mesas ya
  traducidas, así también vale si se mueve solo un mueble).
- **Rutas dentro de edificios:** `VillageTavern.route` y `_route_internal_building_partitions` (VillageManagerBase)
  calculan en el mapa original (`_route_original`, `_route_internal_original`) y devuelven el paso traducido.
- `VillagePlaces.place`, `pick_place` y `hangout_spots` entregan el sitio actual. Las escaleras, el camarero, Marta,
  la Familia (reservado del restaurante), la confesión, la misa, la morgue, la celda y las tumbas, igual.
- **Vecinos que llegan a mitad de partida** (arreglo de un fallo del paso 1): `setup_npc(..., p_ya_actuales)` y
  `_spawn_generated_newcomer(..., ya_actuales)`. Usa `true` si los sitios ya están traducidos: copiados de otro vecino
  (hijos), sacados de `trade_configs` (ya traducido) o el claro del Caso I. Si no, se traducirían dos veces.
- `_sitios_repaso` también pone en la lista de pozos (`_well_positions`) los pozos en su sitio actual.
- Sondeo ampliado (prefijo `z.`). Con todo movido (37, 23) siguen al edificio estos sitios: asientos de taberna y
  comedor del restaurante, mesa, póker, ocio de la taberna, altar, celda, cama del hospital y biblioteca. No se mueven
  (igual que su dibujo, porque están fuera de la planta del edificio): la terraza del restaurante, las tumbas, el
  parque, los bancos de la plaza y el mirador del lago.

### Lo que queda fuera del paso 2 (a propósito)
- `VillageSect.gd` línea ~510 devuelve `vm._cemetery_burial_pos` sin traducir: **no se toca ese archivo sin orden del
  usuario**. Solo importa si se mueve el cementerio.
- Las tumbas 3D (`WorldStageProps3D` ~94) y el dibujo 3D de hospital y morgue usan las variables originales: se
  revisará si el usuario mueve el cementerio o el hospital y se ve mal.
- Puntos del Caso I escritos a mano (archivo de la comisaría (934, 180) y (856, 107), puente viejo…): paso 4.
- Construcción del terreno (`WorldStageTerrain3D`, `WorldStageBase3D`): no se toca; dibuja el mapa original.

## Cómo está hecho (paso 3)
- Fuera de los edificios lo que se mueve son las **anclas** del editor 3D: Objetos marcados como ancla y piezas de
  Decorado. `Anclas.mover` ya las tiene en cuenta, así que basta con pasar por `mover` cada punto fijo escrito a mano
  en el momento de usarlo. Si allí no hay nada movido, `mover` deja el punto igual.
- Traducidos al usarlos:
  - jornales de `VillageWork` (granja, rancho, cantera y leñadores: `day_job_pos`) y el lavadero (ir a lavar y la
    charla de después);
  - puestos del mercado (`work_position` del día) y trabajo en la avanzada;
  - puerta de las incursiones y caravanas de rutas (salida, llegada e ida);
  - contrabandista (campamento, carro, compraventa y redada) y callejón del perista;
  - mirador de la pareja que se escapa, paseos nocturnos (`NIGHT_STROLL_SPOTS`) y paseo suelto (`IDLE_STROLL_SPOTS`);
  - sitios del ayuntamiento (alcalde, urna y mesa del despacho);
  - cama de urgencias del hospital (718, 136), morgue (745, 174), denuncia a la comisaría y raíces del cazador
    aficionado.
- Ya iban bien:
  - guardia y alguacil: su ronda es un paseo alrededor de su puesto, que ya se traduce en `setup_npc`;
  - pesca: el pescador sale de `trade_configs` y el río se edita aparte;
  - árboles y vetas: son nodos del editor 3D;
  - pozos y tablón: `mapa/objeto.gd`;
  - la trampilla del club: `VillageClub.TRAPDOOR_POS` ya se pone al día sola.
- **Sin tocar, a propósito:**
  - los objetos que se crean con posición (arcas del ayuntamiento y libro de cuentas en `VillageCollections`), porque
    `_anclas_repaso_final` ya mueve `WorldInteractableProp` y traducirlos aquí los movería dos veces si se crean al
    arrancar;
  - la salida del mapa de los que se van (`exit_pos`), que es el borde del mapa.
- No hay sondeo propio. El sondeo de edificios sigue dando 54/60. Lo del aire libre se comprobó sin errores con
  `atascos_vecinos.gd -- 3` (0 atascos).

## Registro de lo hecho
- 2026-11-10 (portátil): sondeo creado; resultado 0/60. Plan escrito.
- 2026-11-10 (portátil): paso 1. Sondeo: **54/60 siguen al edificio**; los 6 restantes son puestos al aire libre (plaza:
  Aldric, Sora, Darío, guardia Rodric; claro del Caso I: Clara), que van en los pasos 3 y 4. Sin dobles traducciones.
- 2026-11-10: partida del Caso I (`tools/tests/partida_caso1.gd`): **7/25 con y sin este cambio (idéntico)**: el paso 1
  no rompe nada, pero **la partida ya estaba rota antes** (venía 25/25 el 2026-11-09). Falla desde «A2 caminar al claro»
  (el jugador se queda en (213, -796)) y todo lo que depende de eso. Sospecha: el río redibujado por el usuario o los
  árboles/troncos ahora sólidos del editor 3D cierran el paso al claro. **Arreglarlo antes del paso 4.**
- Pendiente de revisar en el paso 1 (no medido por el sondeo, que solo mira el arranque): mudanzas por boda o herencia
  (`VillageFamily` línea ~265 copia el sitio de otro: ya actual, bien), préstamos (`VillageLoans` usa `free_tavern_bed`,
  ya actual), y cualquier `n.bed_position = <constante>` nuevo: buscar con
  `grep -rn "bed_position = \|work_position = \|home_table_pos = " scripts`.
- 2026-11-10 (portátil): **paso 2 hecho.** Sondeo: 54/60 vecinos (igual), 29/29 edificios, asientos reconocidos con
  todo movido, y los sitios de dentro de los edificios siguen (37, 23). Arreglado de paso que los recién llegados
  (contratados, hijos, oficios vacantes) recibían el sitio traducido dos veces.
- 2026-11-10: **cuidado con `atascos_vecinos.gd`, que depende de la velocidad del ordenador**: los asientos se eligen
  con el reloj real (`Time.get_ticks_msec`). Sin mis cambios da 0 atascos en 6 h, y con mis cambios da 5. Pero el
  código de antes, frenado a propósito (300 µs por fotograma en el restaurante), da **el mismo atasco** (Dr. Valen en
  (399, 100) a las 7:47). Son atascos que ya existían y salen o no según la velocidad:
  - un paso estrecho en la plaza, cerca de (399, 100);
  - los cruces del río (Wolfgang, Albrecht).

  Apuntado en FALLOS_VISIBLES.
- 2026-11-10 (portátil): **paso 3 hecho** (ver arriba). Arranque sin errores; 3 h de juego sin errores ni atascos.
