# Estado actual (máximo 45 líneas; se reescribe al avanzar, nunca es historial)

> Última actualización: 2026-11-12, Claude Code. Historial: `CHANGELOG.md` y `git log`.

## a) Tarea activa
**Migración «el mundo sale solo del editor»** (`docs/PLAN_MUNDO_DESDE_EDITOR.md`, aprobado). **Una sola sesión de Claude
toca el código del mundo** y el usuario no edita el mapa mientras dure. Pasos 0 a 3 hechos; **paso 4 en curso** por trozos.

## b) Último avance completado
- Paso 1 (edificios): 32 escenas en `mapa/edificios/` con Muros, Interior, PisoAlto, Tejado, Muebles, **Marcas** (282;
  `mapa/marca.gd`, `Marca.sitio(id, marca)` en el mapa ORIGINAL) y **Tabiques** (39). Planta, puerta y ventana:
  `mapa/planta.gd`. Casas de recién llegados: tres casas modelo (`mapa/casa_modelo.gd`). Nada se dibuja por código.
- Paso 2 (exteriores), cerrado el 2026-11-11:
  - **Solares** (41, `mapa/solar.gd`, con el Puesto del Paso): ancla por solar con prioridad baja; cubre 16 px más al
    norte y al sur para su letrero. Las casas de solar no tienen pieza y heredan sitio y giro de su solar.
  - **Mostradores**: `_register_shop_business_stall` recibe la marca en el mapa original.
  - **Zonas** (3, `mapa/zona.gd`: plaza, lago, ciénaga): trozos de campo abierto que se estiran ×5 pero van con su
    pieza (`Anclas.estirar`, `estirar_puntos`, `desestirar`); las usan terreno, relieve, `Agua`, `RioLago` y mapa del valle.
- Solares con sus datos y marcas en la pieza (`Solar.marca`): `VillageLots.LOTS` y `OUTPOST_*` borrados.
- Paso 3 (2026-11-12): **Sitios** (86, `mapa/sitio.gd`): cruces al aire libre ya en el mundo (`Sitio.mundo(id)`,
  `Sitio.serie(nombre)`; `Sitio.original(id)` solo para funciones que aún traducen). Caso I: 3 marcas de edificio.
- Método de cada tanda: herramienta temporal (no se guarda) que pasa lo que hay a piezas → cambiar código y borrar
  números → volcado de sitios antes y después (las casas de solar hay que levantarlas con `build_instant_house`) →
  inventario con todo movido → fotos con `capturas_fijas.gd`. Las cruces se miden con la partida arrancada
  (hay casas que se colocan al arrancar).
- Ojo con el inventario: mide cada copia de los lotes de árboles y el centro de las mallas de suelo; no mueve el río.

## c) Siguiente paso técnico inmediato
Paso 4, trozos seguros (decorado del código → piezas), comparando árbol 3D y lógica antes y después. Hechos: terreno,
constructor, taberna, restaurante, solares. Siguen: `VillagePlaces`, `VillageManagerSocial`…, `EcosystemManager`.
**Adiós al 2D (decisión del usuario, 2026-11-12): capas 1 y 2**, no el «cerebro» (vecinos y choques siguen en el mapa
plano). Capa 1 hecha (lista visible 0). Capa 2 casi hecha (tandas 1–7 → marcas invisibles con `tipo_3d`; 2.818 → 44;
sangre, huellas y vagabundos en 3D con `Rastros3D`). Quedan cuerpos de animales, objetos rompibles y espada de `World.tscn`.
**Pesca, huerto, gallinero, campamento, animales de corral del jugador y huerto de casa borrados (usuario, 2026-11-12)**:
se rehacen en 3D tras el Caso I (`docs/VISION_Y_FUTURO.md`, «Jugador»). Río y lago: `scripts/fisica/RioLago.gd`.
Red eléctrica: generador del Arreglador; farolas solo de noche; 47 nuevas = Sitios `farola_calle_N` (+6 Objetos viejos).
Corte final (anclas y ×5) solo con el usuario.
Pendiente apuntado: tamaños (`VillageTavern.SIZE/RECT`, `VillageRestaurant.RECT`, `HOUSE_PLOTS.size`), `OPENINGS`; matas de
`_build_ground_foliage_3d` no esquivan una plaza movida; `FOREST_POLY` y `RIVER_*` sin pieza.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla). Igual «No two conscious villagers may overlap» (dos vecinos en la terraza del restaurante; 2 de cada 4 veces, 2026-11-12: arreglar).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-12
  (`docs/INVENTARIO_MUNDO.md`): sigue 5.297, quieto 75 (río, luces, sitios del código que quedan), doble 0, otro
  sitio 123 (ruido entre partidas y sitios al aire libre).
