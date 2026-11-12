# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** (la que hizo este avance; el usuario lo confirmó el 2026-11-11) y el usuario no edita el mapa
mientras dure. Paso 0 hecho (inventario). **Paso 1 en curso.**

## b) Último avance completado
- 2026-11-11: paso 1, tandas 2 a 8. **196 marcas en 30 edificios** (todos los únicos y los oficios en solares): las 5 familias fundadoras (tiendas, casas y
  botica), casa de comidas, taberna, hospital y morgue, comisaría, capilla, ayuntamiento, albergue, escuela, biblioteca,
  molino
  abandonado, mansión, casa grande, terminales (comisaría, ayuntamiento, taller) y expositor de la herrería. El código las lee y sus números están borrados.
- Cómo funciona: `mapa/marca.gd` (`Marker3D` con `id_marca`, grupo «Marcas» de `mapa/edificios/<id>.tscn`).
  `Marca.sitio(id_edificio, marca)` da el sitio en el mapa ORIGINAL (centro original de la escena + posición local): lo
  que esperan `_add_*` y `setup_npc`, que lo traducen con las anclas. Cambiará al quitar las anclas (paso 4).
- Método de cada tanda: script temporal en `tools/tests/_tmp_*.gd` (no se guarda) que calcula los sitios con el código
  viejo y llama a `guardar()` de `tools/marcar_edificios.gd` (con ventana) → leer la marca → borrar el número →
  comparar un volcado de sitios y de todo `entities_root` antes y después. Ojo: el centro de la escena no siempre es
  el centro del solar (ayuntamiento, biblioteca): restar siempre el `centro_original` de la escena.
- Arreglado de paso (sin probar jugando): jugador rescatado → camilla real; inspector al amanecer → escritorio real;
  aviso del expositor de armas. Medido: sondeo 29/29, viejos 0; `partida_caso1.gd` completa; `fisica_3d.gd` PASSED.

## c) Siguiente paso técnico inmediato
Paso 1, lo que queda: **casas modelo de los solares** (plan aprobado por el usuario el 2026-11-11, en tres trozos, con
`verify_all.gd` al final de cada uno):
1. ✅ Oficios en solares y posada: marcas en sus 8 escenas; `shop_house_layout(solar, edificio)` las lee.
2. **Casas de recién llegados**: tres escenas base (casita 84×62, casa 112×78, casona 124×90) con Muros, Interior,
   Tejado, Muebles y Marcas (`cama_1..`, `mesa`, `cofre`), hechas con puerta al sur; los solares con puerta al norte
   usan la misma girada 180° (aviso dado al usuario: cambia izquierda por derecha). `VillageLots._build_kind("house")`
   y `_house_beds` leen las marcas; ojo al altillo (`upper_floor`: 2 camas más) y al dibujo de `WorldStageProps3D`
   (líneas ~430–520). Las 9 piezas `house_family_lot_*` de Mundo3D pasan a ser copias de la escena base.
3. **Tienda con vivienda base** (128×96) para lo que se levanta en partida; fuera `_shop_house_mold` y el dibujo por
   código que quede en `WorldStageBuildings3D` (`_construir_edificio_por_codigo`, `_populate_building_interior_3d`).
Después: **planta y puerta desde la escena** (tamaño y lado de la puerta como propiedades de la pieza).
Volver a medir con el inventario al cerrar (`docs/specs/PRUEBAS.md`).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración; el inventario aún da 609 cosas en
  el sitio viejo (plantas hechas por código, farolas, solares, suelo) y 137 en otro sitio (pasos 2 y 3).
