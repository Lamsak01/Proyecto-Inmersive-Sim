# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-12, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**PRIORIDAD TOTAL (usuario, 2026-11-12): salir del mapa 2D**. Detención sin atajos hecha (2026-11-13,
`scripts/systems/EscoltaPolicial.gd`, prueba `tools/tests/escolta_organica.gd`); cola en las puertas hecha; cementerio, lavadero, corral, 2 huertos y valla del lago juntados;
siguiente: revisar los grupos del río (75, 31 y 26 piezas) con `tools/juntar_decorado.py` (FALLOS punto 5).
Migración «el mundo sale solo del editor» (`docs/PLAN_MUNDO_DESDE_EDITOR.md`); una sola sesión de Claude toca el código
del mundo. Pasos 0 a 4 hechos (corte final 2026-11-12: sin capa de anclas). Queda el paso 5 del plan.

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
  `Sitio.serie(nombre)`). Caso I: 3 marcas de edificio.
- Paso 4 (2026-11-12): el juego ya no traduce. Cada pieza guarda su sitio del mundo y lo de dentro va con ella
  (`EdificioEditor.a_mundo`, `Solar.a_mundo`, `colocar_plano`); río y puentes en `Mundo3D.tscn` («Rio», «Cruces»).
  Borrados `mapa/anclas.gd`, la copia `Mundo3D.antes-x5.tscn` y las herramientas de estirar. Las pruebas que escriben
  sitios en el mapa original usan `tools/tests/mapa_viejo.gd`.

## c) Siguiente paso técnico inmediato
**×5 que queda (decidir con el usuario si se quita):** `Mapa3D.E` solo estira lo que aún está escrito en medidas del
mapa original: relieve hecho por el juego, forma del lago y la ciénaga, manchas del mapa del valle (`mapa/zona.gd`).
No se ve al jugar; quitarlo es mucho trabajo y arriesgado.
**Adiós al 2D (decisión del usuario, 2026-11-12): capas 1 y 2**, no el «cerebro» (vecinos y choques siguen en el mapa
plano). Capa 1 hecha (lista visible 0). Capa 2 casi hecha (tandas 1–7 → marcas invisibles con `tipo_3d`; 2.818 → 44;
sangre, huellas y vagabundos en 3D con `Rastros3D`). Quedan 6 dibujos planos (caja, barril, muro débil y espada de `World.tscn`, ya con 3D; textos pasajeros).
**Pesca, huerto, gallinero, campamento, animales de corral del jugador y huerto de casa borrados (usuario, 2026-11-12)**:
se rehacen en 3D tras el Caso I (`docs/VISION_Y_FUTURO.md`, «Jugador»). Río y lago: `scripts/fisica/RioLago.gd` (lee el río del editor 3D).
Red eléctrica: generador del Arreglador; farolas solo de noche.
Pendiente: tamaños (`VillageRestaurant.RECT`, `HOUSE_PLOTS.size`), `OPENINGS` (mal comparados con el mundo); matas que no esquivan una plaza movida; `RIVER_*`; mapa del valle.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla). «No two conscious villagers may overlap» (puerta del restaurante): mejorado el 2026-11-13 (cola en las puertas); con 6 vecinos a la vez aún se juntan algo.
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-12
  (`docs/INVENTARIO_MUNDO.md`): sigue 5.297, quieto 75 (río, luces, sitios del código que quedan), doble 0, otro
  sitio 123 (ruido entre partidas y sitios al aire libre).
