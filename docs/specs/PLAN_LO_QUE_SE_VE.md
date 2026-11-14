# Plan «lo que se ve es lo que se usa» (pedido por el usuario, 2026-11-14)

> Estado: **aprobado como idea, sin empezar**. Lo hace Claude Code (cambio de cimientos, no Antigravity). Antes de la
> fase 1, enseñar al usuario un plan de 6 líneas de esa fase y esperar su «sí».

## Problema
El juego tiene dos fuentes de verdad: **lo que se ve** (muebles y piezas del editor, `mapa/edificios/*.tscn`,
`mapa/Mundo3D.tscn`) y **lo que se usa** (listas escritas en el código). Cada sistema (posada, restaurante, casas,
comisaría, pistas) se hizo aparte y a mano; al mover un mueble, su lista no se entera. Cada fallo se arreglaba donde salía
(sillas de la posada, cama de la comisaría…) y el mismo fallo volvía en otro edificio (clientes sentados en el aire en el
restaurante). El usuario no quiere arreglar cada sistema a mano.

## Regla
Todo lo que sirve para algo es una **pieza del editor que dice qué es y para qué sirve** (sentarse, dormir, comer,
trabajar, examinar, abrir, sacar agua…) y su punto exacto de uso. El código **solo lee** esas piezas; no guarda listas,
radios ni posiciones propias. Vecinos y tecla E preguntan al edificio («dame una silla libre», «qué se puede hacer aquí»).

## Las seis familias de reglas a mano (recuento del 2026-11-14, aproximado)
1. **Dónde se hace algo** (sentarse, dormir, comer, trabajar): listas por edificio (`VillageTavern.gd`, `VillageRestaurant.gd`,
   camas y mesas en `_register_*` de `VillageWorldBuilder.gd`, marcas `cama_1/cama_2/mesa/trabajo`).
2. **Qué hace la E**: dos sistemas en paralelo, la cruz (`scripts/ui/InteractionSelector.gd`, `STATION_LABELS`) y ~27
   comprobaciones de distancia en `VillageManager.interact` (cadena de `distance_squared_to(...) <= N*N`).
3. **Zonas de uso a mano**: ~35 `add_zona_uso_mundo` / `zona_en_edificio` (pozo, tablón, pistas, morgue…).
4. **Choques de muebles por código** (`choque_en_edificio`, `no_pisar_mundo`) además de los de cada mueble.
5. **Objetos dibujados por código** en vez de piezas del editor (`WorldStageProps3D.gd`: ~214 números de sitio/tamaño;
   también `WorldStage3D.gd` y `WorldStageTerrain3D.gd`).
6. **Excepciones**: ~16 `if b_id == "building_..."` y listas por vecino (`URGENT_ERRANDS`, `POST_ERRANDS`, `NIGHT_ERRANDS`).

## Fases (cada una: pieza nueva → los sistemas la leen → se borran las listas viejas → pruebas)
1. **Sillas, bancos y camas** (lo más visible). Los muebles de silla/banco/cama declaran su uso y su punto; posada,
   restaurante, casas, comisaría, capilla, escuela… piden «asiento libre» / «cama» al edificio. Arregla de paso los
   clientes sentados en el aire y la cama compartida de Vane y Rodric (hoy parcheada con `cama_2`).
2. **Puestos de trabajo y mesas de comer.**
3. **La tecla E**: un solo sistema; cada pieza dice su acción y su texto; fuera la cadena de distancias de `interact`.
4. **Zonas de uso y pistas** (pozo, tablón, pistas del Caso I) como piezas del editor con su acción.
5. **Choques**: solo los de cada mueble; fuera los de código.
6. **Objetos dibujados por código** → piezas del editor (con `tools/hornear_*.gd`), por tandas.
7. **Excepciones** por edificio y por vecino: reglas con nombre en datos (Resources), no `if` sueltos.

## Cómo se prueba cada fase
Arranque sin errores, la prueba de la fase y **la partida automática del Caso I** (`tools/tests/partida_caso1.gd`, 25/25)
para no romper el caso; fotos de verdad de lo visible (asientos, camas) antes de darlo por bueno.

## Mientras tanto
- La tarea 1 de Antigravity (clientes sentados en el aire) queda **absorbida por la fase 1**: no la hace él.
- No añadir listas nuevas a mano: si hace falta un sitio de uso, que sea pieza del editor.
