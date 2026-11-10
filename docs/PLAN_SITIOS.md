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
2. [ ] **Zonas fijas y sitios de ocio:** 30 comprobaciones «¿está dentro de este rectángulo fijo?» (`*RECT*.has_point`:
   taberna 12, VillageManagerBase 3, Player 2, Justice 2, NPCSocial 2, Restaurant 1, 3D 6) no siguen a un edificio
   movido (p. ej. «¿está en la taberna?»). Traducir el rectángulo con `Anclas.rect_con(Anclas.buscar(centro), RECT)`
   (hacerlo una vez y guardarlo). Variables del gestor en coordenadas originales (`_tavern_social_pos`,
   `_church_altar_pos`, `_hospital_bed_pos`, `_jail_cell_pos`, pozos…): **no se traducen en sitio**; usar
   `vm.sitio(vm._x)` donde se asignan a un vecino o se comparan. Y `VillagePlaces`: `VillagePlaces` (parque, bancos de la plaza, mirador, biblioteca, taberna, terraza), asientos de
   póker de la taberna y del restaurante.
3. [ ] **Trabajos al aire libre:** campos, pesca, leña, patrullas de la guardia, recados.
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
