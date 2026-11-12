# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** y el usuario no edita el mapa mientras dure. Pasos 0 y 1 hechos. **Paso 2 (exteriores) en
curso**, plan en cuatro tandas aprobado por el usuario el 2026-11-11: solares ✅ → Puesto del Paso y letreros de
solar ✅ → mostradores ✅ → plantas ✅ (eran un error de medición: ya seguían al editor). Queda **suelo y agua**.

## b) Último avance completado
- Paso 1 (edificios), cerrado el 2026-11-11: 32 escenas en `mapa/edificios/` con Muros, Interior, PisoAlto, Tejado,
  Muebles, **Marcas** (279; `mapa/marca.gd`, `Marca.sitio(id, marca)` en el mapa ORIGINAL) y **Tabiques** (39;
  `mapa/tabique.gd`). Planta, puerta y ventana: `mapa/planta.gd`. Casas de recién llegados: tres casas modelo
  (`mapa/casa_modelo.gd`). Ningún edificio se dibuja por código. Detalle en `docs/specs/REGISTRO_EDITOR_3D.md`.
- Paso 2, tanda 1 (2026-11-11): **solares como piezas** (`mapa/solar.gd`, carpeta «Solares» de Mundo3D, 40). Ancla
  por solar en `mapa/anclas.gd` con la prioridad más baja; las casas de solar no tienen pieza y heredan sitio y giro
  de su solar (`EdificioEditor.tiene_pieza`, `_construct_solid_building`).
- Paso 2, tanda 2 (2026-11-11): pieza `solar_puesto_del_paso` (41 solares); el puesto (dibujo y lógica) va con ella.
  El ancla de solar cubre además 16 px al norte y al sur (`SOLAR_LETRERO_PX`): su letrero va con él; 46 anclas de
  «Objetos» borradas.
- Paso 2, tanda 3 (2026-11-11): los 15 mostradores (`_register_shop_business_stall` recibe la marca en el mapa
  original; antes zona y letrero se traducían dos veces).
- Método de cada tanda: herramienta temporal (no se guarda) que pasa lo que hay a piezas → cambiar código y borrar
  números → comparar un volcado de sitios, muros y todo `entities_root` antes y después (las casas de solar hay que
  levantarlas con `build_instant_house`) → inventario con todo movido → fotos con `capturas_fijas.gd`.
- Ojo con el inventario: las casas que se construyen solas al arrancar no son las mismas en dos partidas; salen como
  «otro sitio» sin serlo (mirar `inventario_quieto|movido.json` en la carpeta de datos del juego).

## c) Siguiente paso técnico inmediato
Paso 2, último trozo: **suelo y agua** (42 mallas de `Terrain3D` quietas). Antes de tocar nada, comprobar cuántas
salen ya del editor: el inventario no mueve el río ni sus cruces (la zona del zapato del Puente Viejo sale «quieta»
por eso). Si casi todo sale del editor, cerrar el paso 2 y traer al usuario el plan del paso 3.
Pendiente apuntado: muro débil y espada puestos a mano en `scenes/World.tscn` (no siguen al editor); pasar los datos
de `VillageLots.LOTS` a las piezas de solar y borrar la constante y `lot_shift`; `OUTPOST_*` de `VillageCulture` a
marcas del puesto; tamaños que aún usa otra lógica (`VillageTavern.SIZE/RECT`, `VillageRestaurant.RECT`,
`HOUSE_PLOTS.size`), pasos entre salas (`OPENINGS`), sitios de trabajo al aire libre (paso 3).

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-11
  (`docs/INVENTARIO_MUNDO.md`, ya cuenta cada árbol de los lotes): sigue 5.147, quieto 66 (42 suelo y agua), doble 0,
  otro sitio 120 (sitios al aire libre, ruido de casas y de árboles que varían entre partidas).
