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
1. [ ] **Casas y trabajos:** cama, mesa y puesto de trabajo de cada vecino al crearlo y cuando cambian (mudanzas, familia,
   iglesia, posada, préstamos, solares). Medida: el sondeo debe dar 60 de 60.
2. [ ] **Sitios de ocio:** `VillagePlaces` (parque, bancos de la plaza, mirador, biblioteca, taberna, terraza), asientos de
   póker de la taberna y del restaurante.
3. [ ] **Trabajos al aire libre:** campos, pesca, leña, patrullas de la guardia, recados.
4. [ ] **Caso I:** pistas, claro, molino, puente viejo, zapato, bandeja del informe (`VillageCase1`, `VillageManager`).
5. [ ] **Partidas guardadas:** guardar «edificio + sitio» y no solo el punto, para que una partida vieja siga bien tras
   mover cosas. Base para la plantilla de edificio.
6. [ ] **Plantilla de edificio** (decisión del usuario, después): pieza nueva en el editor que el juego construye con
   puerta, interior y sus sitios.

## Registro de lo hecho
- 2026-11-10 (portátil): sondeo creado; resultado 0/60. Plan escrito.
