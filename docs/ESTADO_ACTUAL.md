# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-13, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Interiores de tamaño real (usuario, 2026-11-13)**: casas ×4 de suelo, cuarto por cama, sala, cocina y baño; la casa
marca la clase (niveles 1–4 en `docs/VISION_Y_FUTURO.md`). Hechas las 4 casas de artesano (herrero, carnicero,
carpintero, pescadero), 6 casas-tienda de artesano (con la posada), 2 pobres, el albergue y la acomodada del Arreglador (se gira con «girar»): `tools/casas/` (planos, id, espejo, POR_OFICIO),
`mapa/cuarto.gd`, `scripts/systems/RutaCuartos.gd`. Clases en la visión. Casas de solar: 3 casas modelo con cuartos (`plano_casa_modelo_*`), rutas por `VillageLots.house_route`. Nivel 4: mansión, casona, ayuntamiento, comisaría («REJA»), hospital (morgue) y capilla (bancos «banco_N») hechos; escuela (12 pupitres; filas «solo_ruta») y biblioteca (sala oculta tras el archivo) también.
**Casas de dos plantas** (2026-11-13): campos «…_ARRIBA» y `ESCALERA` en el plano (`planta_alta.gd`); en el juego
`scripts/fisica/PisosCasas.gd`; el trozo alto de los muros va en «PisoAlto» (se esconde desde arriba).

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
sangre, huellas y vagabundos en 3D con `Rastros3D`). Quedan 6 dibujos planos, todos ya con su 3D y el plano apagado o pasajero (caja, barril, muro débil y espada de `World.tscn`; 2 textos): al jugar no se ve nada plano.
**Pesca, huerto, gallinero, campamento, animales de corral del jugador y huerto de casa borrados (usuario, 2026-11-12)**:
se rehacen en 3D tras el Caso I (`docs/VISION_Y_FUTURO.md`, «Jugador»). Río y lago: `scripts/fisica/RioLago.gd` (lee el río del editor 3D).
Red eléctrica: generador del Arreglador (lo dibuja su casa); farolas solo de noche. Mapa del valle: ya sale de las piezas del editor.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla). «No two conscious villagers may overlap» (puerta del restaurante): mejorado el 2026-11-13 (cola en las puertas); con 6 vecinos a la vez aún se juntan algo.
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-12
  (`docs/INVENTARIO_MUNDO.md`): sigue 5.297, quieto 75 (río, luces, sitios del código que quedan), doble 0, otro
  sitio 123 (ruido entre partidas y sitios al aire libre).
