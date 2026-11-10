# Plan del editor del mapa (para Claude en cualquier ordenador)

Pedido por el usuario el 2026-11-09: quiere construir el mapa él mismo, con algo intuitivo, en su ordenador
principal (este bloque se hizo en el portátil y se sube a GitHub). Tiene **muchos assets gratuitos descargados en el
ordenador principal**: pregúntale cuáles antes de las piezas nuevas (árboles, rocas, casas) y úsalos.

## Hecho (paso 1: terreno — río y cruces)
- `mapa/EditorMapa.tscn` (escena @tool): `Referencia` (fondo con edificios, caminos, árboles, rocas y lago de hoy,
  leído de `mapa/referencia_mapa.json`), `Rio` (hijos Marker2D `punto_rio.gd` con `ancho`; `curvas_naturales`)
  y `Cruces` (Marker2D `cruce_rio.gd`: nombre, tipo, ancho, largo, altura_arco, id_interno).
- `mapa/rio_forma.gd`: forma del río a partir de los puntos (la usan el editor y el juego).
- `FishingSpot` lee la escena (`river_center_x/half_width/banks_at`, `river_crossings()`, `river_waypoints()`,
  `river_y_start/end()`). **Mientras los puntos sean los originales usa la forma antigua exacta** (con sus ajustes a
  mano junto a edificios); si el usuario cambia algo, manda el editor. Los tramos de agua con choque salen de los cruces.
- Herramientas: `tools/crear_editor_mapa.gd` (crea la escena desde el mapa actual; `-- forzar` la rehace = volver al
  río original), `tools/volcar_referencia_mapa.gd` (rehace el fondo de guía), `tools/tests/rio_editor_juego.gd`
  (`-- mover` prueba un río cambiado), `tools/tests/captura_editor_mapa.gd` (fotos del editor).
- Guía para el usuario: `docs/EDITOR_MAPA_GUIA.md`.

## Pendiente (en este orden, cada paso con permiso del usuario)
1. En el ordenador principal: `git pull`, abrir `mapa/EditorMapa.tscn` con el usuario y que mueva un punto del río
   (aprender Godot, paso 1). Mirar que los vecinos ya no se atascan en el río nuevo.
2. Edificios movibles desde el editor (hoy están escritos en el código: VillageManagerBase/VillageWorldBuilder).
   Arreglaría «el molino a 2 m del cuerpo».
3. Zonas pintadas (bosque, campos, caminos) y árboles colocables, con los assets del usuario. Arreglaría
   «árboles que se solapan en el bosque».
4. Lo que queda escrito a mano para el río original (el molino, el puente viejo, el zapato del Caso I junto al puente)
   sigue sus posiciones fijas: si el usuario mueve mucho el río, revisar el Caso I.
