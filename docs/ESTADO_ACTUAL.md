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
    pieza (`Anclas.estirar`, `estirar_puntos`, `desestirar`); las usan el terreno por código, el relieve, `Agua`,
    `FishingSpot` y el mapa del valle. Prueba: `tools/tests/sondeo_zonas.gd`.
- Solares con sus datos en la pieza (zona, barrio, casa, puerta, apartado) y marcas propias (`Solar.marca`; Puesto
  del Paso): `VillageLots.LOTS` y `OUTPOST_*` borrados (2026-11-12).
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
plano). Capa 1 hecha (lista visible 0). Capa 2 en curso (tandas 1–4: letreros, polígonos, árboles/rocas/plantas, puertas/ventanas/cofres, 2.818 → 168; sangre, huellas y vagabundos en 3D con `Rastros3D`; quedan 134 sprites: postes, puestos, pinos de adorno, animales, granja…): los dibujos planos ocultos que hacen
de plano del 3D (`_add_rect_poly`/`_add_poly`, sprites fuente de `WorldStageProps3D`, etiquetas de estación) → piezas o
borrar. Comprobar cada tanda con la lista de lo visible y fotos. Pesca: instrucciones del minijuego planas (sin revisar).
Corte final (anclas y ×5) solo con el usuario.
Pendiente apuntado: muro débil y espada de `scenes/World.tscn`; tamaños (`VillageTavern.SIZE/RECT`, `VillageRestaurant.RECT`, `HOUSE_PLOTS.size`), `OPENINGS`; matas de
`_build_ground_foliage_3d` no esquivan una plaza movida; `FOREST_POLY` y `RIVER_*` sin pieza.

## d) Bloqueos activos
- Prueba `verify_all.gd`, sección «S2: un testigo convierte la infidelidad en chisme»: falla al azar (repetir si falla). Igual «No two conscious villagers may overlap» (dos vecinos en la terraza del restaurante; 2 de cada 4 veces, 2026-11-12: arreglar).
- Fallos de las partidas ×5 (`docs/FALLOS_VISIBLES.md`): se resuelven con la migración. Inventario 2026-11-12
  (`docs/INVENTARIO_MUNDO.md`): sigue 5.297, quieto 75 (río, luces, sitios del código que quedan), doble 0, otro
  sitio 123 (ruido entre partidas y sitios al aire libre).
