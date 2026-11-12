# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-11, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** y el usuario no edita el mapa mientras dure. Pasos 0, 1 y **2 (exteriores) hechos**.
Siguiente: paso 3 (sitios de trabajo al aire libre), con plan corto que debe aprobar el usuario.

## b) Último avance completado
- Paso 1 (edificios): 32 escenas en `mapa/edificios/` con Muros, Interior, PisoAlto, Tejado, Muebles, **Marcas** (279;
  `mapa/marca.gd`, `Marca.sitio(id, marca)` en el mapa ORIGINAL) y **Tabiques** (39). Planta, puerta y ventana:
  `mapa/planta.gd`. Casas de recién llegados: tres casas modelo (`mapa/casa_modelo.gd`). Nada se dibuja por código.
- Paso 2 (exteriores), cerrado el 2026-11-11:
  - **Solares** (41, `mapa/solar.gd`, con el Puesto del Paso): ancla por solar con prioridad baja; cubre 16 px más al
    norte y al sur para su letrero. Las casas de solar no tienen pieza y heredan sitio y giro de su solar.
  - **Mostradores**: `_register_shop_business_stall` recibe la marca en el mapa original.
  - **Zonas** (3, `mapa/zona.gd`: plaza, lago, ciénaga): trozos de campo abierto que se estiran ×5 pero van con su
    pieza (`Anclas.estirar`, `estirar_puntos`, `desestirar`); las usan el terreno por código, el relieve, `Agua`,
    `FishingSpot` y el mapa del valle. Prueba: `tools/tests/sondeo_zonas.gd`.
- Método de cada tanda: herramienta temporal (no se guarda) que pasa lo que hay a piezas → cambiar código y borrar
  números → volcado de sitios antes y después (las casas de solar hay que levantarlas con `build_instant_house`) →
  inventario con todo movido → fotos con `capturas_fijas.gd`.
- Ojo con el inventario: mide cada copia de los lotes de árboles y el centro de las mallas de suelo; no mueve el río.
  Antes de planear una tanda, comprobar que lo «quieto» no es un defecto de la medición (pasó dos veces).

## c) Siguiente paso técnico inmediato
Paso 3: **sitios de trabajo al aire libre** (`al_aire_libre=6` en el sondeo; ~11 `work_position` que varían). Traer
plan corto al usuario.
Pendiente apuntado: muro débil y espada puestos a mano en `scenes/World.tscn` (no siguen al editor); pasar los datos
de `VillageLots.LOTS` a las piezas de solar y borrar la constante y `lot_shift`; `OUTPOST_*` de `VillageCulture` a
marcas del puesto; tamaños que aún usa otra lógica (`VillageTavern.SIZE/RECT`, `VillageRestaurant.RECT`,
`HOUSE_PLOTS.size`), pasos entre salas (`OPENINGS`); matas de `_build_ground_foliage_3d` no esquivan una plaza movida.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-11
  (`docs/INVENTARIO_MUNDO.md`): sigue 5.181, quieto 30 (río, luces, copias ocultas), doble 0, otro sitio 122 (ruido
  entre partidas y sitios al aire libre).
