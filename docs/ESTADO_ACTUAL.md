# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-12, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**PRIORIDAD TOTAL (usuario, 2026-11-12): salir del mapa 2D**; lo demás espera (detención orgánica: `docs/FALLOS_VISIBLES.md`).
Migración «el mundo sale solo del editor» (`docs/PLAN_MUNDO_DESDE_EDITOR.md`); una sola sesión de Claude toca el código
del mundo. Pasos 0 a 3 hechos; **paso 4: puntos 1–5 hechos** (falta el 6, el corte final, con el usuario).

## b) Último avance completado
- Paso 1 (edificios): 32 escenas en `mapa/edificios/` con Muros, Interior, PisoAlto, Tejado, Muebles, **Marcas** (282;
  `mapa/marca.gd`, `Marca.sitio(id, marca)` en el mapa ORIGINAL) y **Tabiques** (39). Planta, puerta y ventana:
  `mapa/planta.gd`. Casas de recién llegados: tres casas modelo (`mapa/casa_modelo.gd`). Nada se dibuja por código.
- Paso 2 (exteriores), cerrado el 2026-11-11:
  - **Solares** (41, `mapa/solar.gd`, con el Puesto del Paso): ancla por solar con prioridad baja; cubre 16 px más al
    norte y al sur para su letrero. Las casas de solar no tienen pieza y heredan sitio y giro de su solar.
  - **Zonas** (3, `mapa/zona.gd`: plaza, lago, ciénaga): trozos de campo abierto que se estiran ×5 pero van con su
    pieza (`Zona.estirar`, `estirar_puntos`, `desestirar`, `rect_mundo`); las usan terreno, relieve, `Agua`, `RioLago`,
    la ciénaga que enferma y el mapa del valle (`scripts/ui/ValleMapaPiezas.gd`: edificios y solares desde sus piezas).
- Paso 3 (2026-11-12): **Sitios** (86, `mapa/sitio.gd`): cruces al aire libre ya en el mundo (`Sitio.mundo(id)`,
  `Sitio.serie(nombre)`; `Sitio.original(id)` solo para funciones que aún traducen). Caso I: 3 marcas de edificio.

## c) Siguiente paso técnico inmediato
Paso 4 por tandas, comparando con `tools/tests/volcado_mundo.gd` (choques, zonas, marcas, vecinos antes/después).
**Hecho (2026-11-12):** edificios, casas de solar, anexos, alcantarillas y mirador van directos a su pieza; los
vecinos nacen ya en el mundo; cementerio, corral y sitios de fuera son cruces; zonas y mapa del valle salen de sus
piezas; río y puentes en `Mundo3D.tscn` («Rio», «Cruces»), editor 2D borrado. Muebles de la taberna sin pieza propia.
**El juego ya no traduce (2026-11-12):** constructor, tabiques, dibujos 3D (`colocar_plano`) y objetos van con su
pieza; solo `Anclas.registrar_edificio` sigue para las pruebas que escriben en el mapa original.
**Siguiente (corte final, con el usuario):** pasar esas pruebas (`M()` de verify_all, `fisica_3d`, `partida_caso1`,
herramientas) a coordenadas del mundo; quitar `anclas.gd`, el ×5 (`Mapa3D.E`, `estirar_terreno`, `Zona.estirar`…) y
`mapa/Mundo3D.antes-x5.tscn`.
**Adiós al 2D (decisión del usuario, 2026-11-12): capas 1 y 2**, no el «cerebro» (vecinos y choques siguen en el mapa
plano). Capa 1 hecha (lista visible 0). Capa 2 casi hecha (tandas 1–7 → marcas invisibles con `tipo_3d`; 2.818 → 44;
sangre, huellas y vagabundos en 3D con `Rastros3D`). Quedan cuerpos de animales, objetos rompibles y espada de `World.tscn`.
**Pesca, huerto, gallinero, campamento, animales de corral del jugador y huerto de casa borrados (usuario, 2026-11-12)**:
se rehacen en 3D tras el Caso I (`docs/VISION_Y_FUTURO.md`, «Jugador»). Río y lago: `scripts/fisica/RioLago.gd` (lee el río del editor 3D).
Red eléctrica: generador del Arreglador; farolas solo de noche. Corte final pedido por el usuario el 2026-11-12.
Pendiente: tamaños (`VillageRestaurant.RECT`, `HOUSE_PLOTS.size`), `OPENINGS` (mal comparados con el mundo); matas que no esquivan una plaza movida; `RIVER_*`; mapa del valle.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla). Igual «No two conscious villagers may overlap» (dos vecinos en la terraza del restaurante; 2 de cada 4 veces, 2026-11-12: arreglar).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-12
  (`docs/INVENTARIO_MUNDO.md`): sigue 5.297, quieto 75 (río, luces, sitios del código que quedan), doble 0, otro
  sitio 123 (ruido entre partidas y sitios al aire libre).
