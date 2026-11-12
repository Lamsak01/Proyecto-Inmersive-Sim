# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, **295 marcas en 32 escenas**: todos los edificios únicos, los oficios en solares y las tres casas
  modelo. El código las lee y sus números están borrados.
- Marcas: `mapa/marca.gd` (`Marker3D` con `id_marca`, grupo «Marcas» de `mapa/edificios/<id>.tscn`).
  `Marca.sitio(id_edificio, marca)` da el sitio en el mapa ORIGINAL (centro original de la escena + posición local): lo
  que esperan `_add_*` y `setup_npc`, que lo traducen con las anclas. Cambiará al quitar las anclas (paso 4).
- **Casas de recién llegados** (trozo 2 de las casas modelo, hecho): `mapa/casa_modelo.gd` y tres escenas
  (`modelo_casita|casa|casona.tscn`, puerta al sur). `house_family_lot_<solar>` = copia de la de su tamaño; puerta al
  norte = media vuelta (`giro_de_fabrica` en `mapa/edificio.gd`; ventana lógica al otro lado con `window_on_right`).
  `VillageLots._house_beds` y `house_site` leen `cama_N`, `cama_alta_N` (altillo), `mesa`, `cofre`. Las 9 piezas del
  valle son copias; las casas levantadas en partida usan la casa modelo sin pieza. Detalle en `REGISTRO_EDITOR_3D.md`.
- Método de cada tanda: script temporal `tools/tests/_tmp_*.gd` (no se guarda) → cambiar código → comparar un volcado
  de sitios y de todo `entities_root` antes y después (para casas de solar hay que levantarlas con
  `build_instant_house`: al arrancar no hay ninguna) + fotos con `capturas_fijas.gd` (sitios `casa_*`).
- **Sin dibujo por código** (trozo 3, hecho): `WorldStageBuildings3D` solo carga escenas; un edificio sin escena da
  error. Tiendas de solar y posada: todo de marcas, también los tabiques (`tabique_1|2`, `VillageLots.shop_house_layout`).
  Borradas las herramientas de conversión. La casona ya tiene su tercera cama.

## c) Siguiente paso técnico inmediato
Hecho el 2026-11-11: **planta, puerta y ventana desde la escena** (`mapa/planta.gd`; `planta_m`, `puerta_ancho_m` y
marcas `puerta`/`ventana`; `_construct_solid_building(id, título, centro, texturas, color[, planta])`).
Lo que queda para cerrar el paso 1 (proponer al usuario, tanda aparte): **tabiques interiores** como marcas (unos 25
`_add_solid_wall_segment` en `VillageManagerBase`, `VillageWorldBuilder`, `VillageRestaurant`, `VillageTavern`).
Siguen como números (apuntado): tamaños que aún usa otra lógica (`VillageTavern.SIZE/RECT`, `VillageRestaurant.RECT`,
`HOUSE_PLOTS.size`, `FishingSpot.ABANDONED_MILL_SIZE`, `ValleyMapUI`), `door_south` de los solares (mejoras de la
casa del jugador), sitios de trabajo al aire libre, rejas y bancos sueltos de `VillageWorldBuilder`.
Después: volver a medir con el inventario (`docs/specs/PRUEBAS.md`, con ventana, ~1 min) y pasar al paso 2.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración; el inventario aún da 609 cosas en
  el sitio viejo (plantas hechas por código, farolas, solares, suelo) y 137 en otro sitio (pasos 2 y 3).
