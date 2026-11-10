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

## Cómo explicárselo al usuario (OBLIGATORIO, pedido por él el 2026-11-09)
El usuario no programa y **no conoce Godot**. Le costó entender el resumen del portátil. En el ordenador principal:
1. **Un solo paso por mensaje.** Di exactamente qué tiene que hacer (qué tecla, dónde hacer clic) y espera a que diga
   «hecho» antes del siguiente. Nada de listas largas.
2. **Di dónde está cada cosa en la pantalla** con palabras de sitio: «arriba a la izquierda», «la lista de la
   derecha». No des por sabido qué es «Inspector», «nodo» o «escena»: explícalo con una comparación la primera vez
   (p. ej. «la lista de la izquierda es como las carpetas del mapa: Rio, Cruces…»).
3. **Antes de empezar, comprueba tú** que todo funciona: `git pull`, que existe `mapa/EditorMapa.tscn` y que el juego
   arranca. Si algo falla, arréglalo tú; no le pidas al usuario que lo arregle.
4. **Primera sesión, en este orden:** (a) abrir Godot y el proyecto; (b) abrir el mapa (doble clic en «EditorMapa»
   dentro de la carpeta «mapa», abajo a la izquierda); (c) moverse por el mapa (rueda del ratón = acercar/alejar,
   botón central o espacio + arrastrar = desplazarse); (d) elegir un punto del río y arrastrarlo; (e) guardar
   (Ctrl+S) y jugar (F5) para ver el cambio. Celebra que lo haya hecho y pregunta si quiere seguir.
5. **Si se pierde:** pídele una captura de pantalla y guíale desde lo que ve.
6. **Si rompe el río:** Ctrl+Z, o rehaz el original con `tools/crear_editor_mapa.gd -- forzar`. Tranquilízale: nada se
   pierde, todo está guardado en GitHub.
