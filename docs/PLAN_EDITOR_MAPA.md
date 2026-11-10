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

## Hecho (paso 2, 2026-11-10: editor 3D y recursos propios)
- `mapa/Mundo3D.tscn` (script `mapa/mundo3d.gd`): al abrirla en Godot construye una **maqueta 3D** del mundo («Vista»: suelo
  con relieve y choque, río, lago, caminos, edificios con nombre, árboles y rocas de `referencia_mapa.json`). No se guarda.
  La casilla «Regenerar» del Inspector la rehace. Lo que se pone en **«Decoracion»** sale en el juego en el mismo sitio y es
  sólido (rectángulo visto desde arriba; metadata `atravesable = true` para que no choque). Lo carga
  `WorldStageTerrain3D._cargar_decoracion_editor()`. Probado: una caja puesta ahí aparece en el juego y bloquea el paso.
- Carpeta `mis_recursos/`: el usuario copia ahí los modelos que compre o descargue; Godot los importa solo.
- Complemento **Godot Asset Placer** 1.6.0 (MIT, levinzonr) en `addons/asset_placer/`: panel con miniaturas para colocar
  modelos con clic. Se activa en Proyecto → Configuración del proyecto → Complementos (Plugins).
- Para repartir bosques pintando, más adelante: World Brush o Proton Scatter (gratis). Terreno: Terrain3D (no compensa ahora).

## Hecho (paso 3, 2026-11-10: el mundo pasa a escena, parte 1 — vegetación)
- Los 589 árboles, rocas, plantas, matas y troncos que colocaba el código del terreno están ahora en `mapa/Mundo3D.tscn` →
  «Vegetacion» (Arboles, Rocas, Troncos, Plantas). Cada uno es una **pieza** (`mapa/pieza.gd`: modelo, alto, tam, choque)
  que dibuja su modelo con el mismo lector del juego. Se mueven, giran, duplican o borran a mano en Godot.
- Con piezas en «Vegetacion», el código deja de colocar esos modelos (`vegetacion_en_escena`). Choque en el juego según la
  pieza: árboles solo el tronco (7×7), rocas, troncos y tocones lo que ocupan, plantas nada. **Antes los árboles de adorno no
  eran sólidos; ahora sí.**
- Se hizo con `tools/hornear_vegetacion.gd` (una vez; no rehace si ya hay piezas salvo `-- forzar`, que pisaría cambios a mano).
- **Todos los árboles de la escena son talables** (2026-11-10): `WorldStageTerrain3D._crear_talables_pendientes()` crea un
  HarvestableNode «Árbol del Valle» (3 de madera + semillas, vuelve en 2 días) por cada pieza con choque «tronco» y usa su
  modelo como dibujo (se oculta al talarlo y sale el tocón). Los 65 talables de EcosystemManager se hornearon a la escena
  (`hornear_vegetacion.gd -- talables`, nodos `Talable_*`) y EcosystemManager ya no los crea si hay árboles en la escena.
  Probado: 252 talables, ninguno duplicado; talar uno oculta el árbol y muestra el tocón.
- Siguen en código: vetas de mineral (EcosystemManager), setas y hierbas, puentes, el tronco-puente, los troncos de caja
  del claro y todo lo de los edificios.

## Pendiente (en este orden, cada paso con permiso del usuario)
1. En el ordenador principal: `git pull`, abrir `mapa/EditorMapa.tscn` con el usuario y que mueva un punto del río
   (aprender Godot, paso 1). Mirar que los vecinos ya no se atascan en el río nuevo.
2. Edificios movibles desde el editor (hoy están escritos en el código: VillageManagerBase/VillageWorldBuilder).
   Arreglaría «el molino a 2 m del cuerpo».
3. **Ríos nuevos y arroyos (pedido del usuario, 2026-11-09):** el lago del pueblo debe recibir agua del río principal,
   de forma realista: un arroyo de entrada que sale del río aguas arriba (al norte) y baja al lago, y uno de salida que
   vuelve al río más al sur, con vados o puentecillos. Requiere varios ríos o ramas y quitar la limitación de que el
   río solo vaya de norte a sur (hoy los puntos se ordenan por altura en el mapa; los arroyos irían de este a oeste).
   El usuario quiere dibujarlos él mismo, igual que el río.
4. Zonas pintadas (bosque, campos, caminos) y árboles colocables, con los assets del usuario. Arreglaría
   «árboles que se solapan en el bosque».
5. Después (deseo del usuario, 2026-11-09: «editarlo todo a mano, sin programar»): calles, sitios donde salen los
   recursos, tamaño y reparto de los objetos del mundo, e interiores de cada edificio decorados a su gusto.
6. Lo que queda escrito a mano para el río original (el molino, el puente viejo, el zapato del Caso I junto al puente)
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
