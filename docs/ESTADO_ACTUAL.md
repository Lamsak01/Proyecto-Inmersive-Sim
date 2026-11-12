# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, **231 marcas en 33 escenas**: todos los edificios únicos, los oficios en solares y las tres casas
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
Cierre del paso 1: **planta y puerta desde la escena** (tamaño de la planta, lado y ancho de la puerta y sitio de la
ventana como propiedades o marcas de la pieza, en vez de los números de cada `_construct_solid_building`: 15 llamadas
en `VillageWorldBuilder`, `VillageLots`, `VillageCivic`, `VillageCulture`, `VillageNobility`, `VillageTavern`,
`VillageRestaurant`). Toca más de 2 scripts: plan corto y confirmación del usuario antes de empezar.
Siguen como números (apuntado): sitios de trabajo al aire libre (cantero, granjero, ganadero, leñador), muebles de
mejoras de la casa del jugador (`VillageHousing.home_prop_pos`), rejas y bancos sueltos de `VillageWorldBuilder`.
Volver a medir con el inventario al cerrar (`docs/specs/PRUEBAS.md`), con ventana (~1 min).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración; el inventario aún da 609 cosas en
  el sitio viejo (plantas hechas por código, farolas, solares, suelo) y 137 en otro sitio (pasos 2 y 3).
