# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, **215 marcas en 33 escenas**: todos los edificios únicos, los oficios en solares y las tres casas
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
- Conocido: la casona tiene 3 plazas (`cama_3`) pero solo 2 camas dibujadas (ya era así); el usuario puede añadir la
  tercera cama en `modelo_casona`.

## c) Siguiente paso técnico inmediato
Paso 1, último trozo de las **casas modelo** (plan aprobado por el usuario el 2026-11-11):
3. **Tienda con vivienda base** (128×96) para lo que se levanta en partida, igual que las casas modelo; fuera
   `_shop_house_mold` y el dibujo por código que quede en `WorldStageBuildings3D` (`_construir_edificio_por_codigo`,
   `_muros_3d`, `_puerta_y_ventana_3d`, `_tejado_3d`, `_populate_building_interior_3d`). Ojo: mirar antes qué otros
   edificios levantados en partida (cívicos, escuela, mansión…) pasan aún por ese dibujo. `verify_all.gd` al final.
Después: **planta y puerta desde la escena** (tamaño y lado de la puerta como propiedades de la pieza).
Volver a medir con el inventario al cerrar (`docs/specs/PRUEBAS.md`).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración; el inventario aún da 609 cosas en
  el sitio viejo (plantas hechas por código, farolas, solares, suelo) y 137 en otro sitio (pasos 2 y 3).
