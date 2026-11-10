# Registro del editor del mapa 3D (para el usuario y cualquier agente)

Escrito por Claude Code (2026-11-10). Detalle técnico en `docs/PLAN_EDITOR_MAPA.md`.

## Qué decidió el usuario (2026-11-10)
- **Demo del Caso I en pausa.** Antigravity se quedó sin cupo y Claude Code tiene poco. Prioridad: que el usuario pueda
  **editar todo el mapa a mano en Godot**, en 3D. «Arreglar la lógica» (vecinos, rutas, pistas, objetos) va **después**.
- El mundo pasa de «generado por código» a **escenas**: mejor para el arte, para una segunda ciudad y para un mapa más
  grande (cargar por zonas). Se hace por partes, subiendo a GitHub cada una.
- Quiere mover **absolutamente todo**. Los recursos que compre van a `mis_recursos/` y se colocan en el editor.
- Ramas («branches»): objeto nuevo que dan los matorrales; el usuario decidirá su uso.

## Cómo se usa
- Abrir `mapa/Mundo3D.tscn` (carpeta «mapa», doble clic) y pulsar «3D». Volar: clic derecho + WASD. Elegir: clic.
  Mover: W y flechas roja/azul. Deshacer: Ctrl+Z. Guardar: Ctrl+S. Probar: ▶ arriba a la derecha.
- Carpetas: **Vegetacion** (Arboles talables, Rocas, Troncos, Plantas, Vetas que se pican), **Decorado** (puentes, muelle,
  vallas, corrales, caminos, bancos… por zonas), **Edificios** (se mueven enteros con su interior), **Objetos** (farolas,
  pozos, tablón y 181 «anclas»: zonas de uso, letreros, casas de animales, setas, pistas fuera de edificios, huertos,
  gallinero, animales de granja con su corral, campamento, muro débil, cajas y carteles, carro y caballo),
  **Decoracion** (lo que coloque el usuario de `mis_recursos/`).
- Complemento «Godot Asset Placer»: activarlo en Project → Project Settings → Plugins.
- Si Godot tenía Mundo3D abierto cuando Claude lo cambió: cerrar la pestaña **sin guardar** y volver a abrirla.

## Cómo sigue la lógica a lo que se mueve («anclas», `mapa/anclas.gd`)
Todo lo que el juego crea en el mapa 2D (dibujos, zonas de uso, paredes invisibles, letreros, polígonos) dentro de la zona
original de un edificio, objeto-ancla u objeto de Decorado que el usuario movió, se crea desplazado lo mismo. Probado:
mover una pista del claro y el molino mueve sus zonas de uso y el interior 3D del molino.

## Giros (hecho el 2026-11-10, sesión 2)
- Girar en el editor (eje vertical; en el Inspector, Transform → Rotation → Y) ahora gira en el juego.
- **Edificios**: de 90 en 90 grados (se redondea al más cercano), porque las paredes del mapa 2D son rectángulos rectos.
  El juego gira la planta, la puerta (sur→este→norte→oeste) y su sitio; el 3D se construye sin girar y se gira entero, con
  el interior dentro. Probado con la casa de la familia Yunque Gris a 90°: puerta al este y muebles girados (captura).
- **Objetos-ancla y Decorado**: cualquier ángulo; lo que les sigue gira alrededor de su sitio original
  (`mapa/anclas.gd`: `matriz`, `aplicar`, `girar_choque`, `rect_con`). Las paredes invisibles giran (aproximadas).
- **Objetos con nombre** (pozos, tablón, farolas): un «ancla de solo giro» en su sitio nuevo gira su dibujo 3D y su pared.
- Vegetación y Decorado ya giraban solos en 3D (la escena guarda el giro); su choque de «forma» sale ya girado.
- El giro en 3D se ve «aplastado» en el mapa 2D por la inclinación de la cámara (58°): `Anclas.matriz(g)` lo traduce.

## Muebles uno a uno (hecho el 2026-11-10, sesión 2)
- Cada edificio de «Edificios» tiene una carpeta **«Muebles»** con una pieza por mueble 3D (290; `mapa/mueble.gd`). Se
  mueven y giran a mano; si se mueve el edificio, van con él (son hijos suyos).
- Las fotos de los edificios (`mapa/edificios_vista/`) se rehicieron **sin muebles** (`tools/hornear_edificios.gd` con
  `WorldStageBase3D.grabar_muebles`), para no verlos dos veces.
- En el juego: `_add_model_2d` reconoce cada mueble por su clave (edificio#piso|modelo|x|y, en coordenadas originales) y
  aplica el cambio; `Anclas.buscar` compone el mueble con su edificio, así su pared invisible y su zona de uso le siguen.
- Probado: una cama de la familia Yunque Gris movida 60 px y girada 90° sale ahí en el juego con su pared girada.
- No son piezas: los cofres (ya siguen a sus anclas) y los detalles hechos con cajas (no modelos), que van en la foto.
- La taberna muestra juntos los muebles de las dos plantas (los del piso 1 llevan «piso1» en el nombre).
- Si se cambia el código de un interior, las claves pueden cambiar: volver a ejecutar la herramienta (solo añade
  carpetas «Muebles» que falten; para rehacer una, bórrala antes en Godot).

## Bajo tierra (hecho el 2026-11-10, sesión 2)
- Carpeta **«BajoTierra»** en Mundo3D (oculta; se ve con el ojo) con la pieza «Alcantarillas» (`mapa/edificio.gd`, id
  `bajo_alcantarillas`, foto `mapa/edificios_vista/bajo_alcantarillas.scn`; `tools/hornear_bajo_tierra.gd`). Moverla mueve
  toda la red: cámaras, pasillos, paredes, escalerillas y cofres (`VillageUnderworld.desp_red`; `SEWER_LOCATIONS` es ahora
  `static var` rellenada en `build_sewers_world` a partir de `SEWER_LOCATIONS_BASE`). Solo se mueve, no gira.
- Las trampillas de la calle siguen a sus anclas y al salir del túnel se aparece en la trampilla movida.
- El club de pelea va con la taberna (`VillageClub.build_world`: trampilla, sótano y escalerilla con el movimiento/giro de
  la taberna; `TRAPDOOR_POS`, `CLUB_CENTER`, `LADDER_POS` son `static var`). El sótano no gira.
- `_anclas_repaso_final` ya no toca lo de bajo tierra ni sus trampillas (se colocan solos).
- Probado: red movida 100 px → escalerillas y cofres +100 px, trampillas en su sitio.
- Fotos: los archivos de `edificios_vista/comun/` y `decorado_comun/` se nombran ahora por su contenido (`_huella`), para
  que volver a hornear no cambie archivos que otras fotos usan. Si Godot estaba abierto al rehacer las fotos, enseña
  texturas cruzadas hasta reiniciarlo (Proyecto → Recargar proyecto actual). La foto de `house_family_lot_m4` es de la
  primera tanda (ese solar no se construyó al rehacerlas) y puede salir con texturas cambiadas.

## Caminos y mapa pequeño (hecho el 2026-11-10, sesión 2)
- Carpeta **«Caminos»** en Mundo3D: 32 tramos (`mapa/camino.gd`, `tools/hornear_caminos.gd`) de las calles rectas de
  siempre (`WorldStageTerrain3D.CALLES_PRINCIPALES` + `VillageLots.ROADS`). Se mueven, giran y estiran con la
  herramienta de escalar (X = largo, Z = ancho). Si hay tramos, el juego deja de dibujar las calles rectas y dibuja los
  tramos pegados al terreno (`_add_tramo_3d`), también en diagonal. Para añadir una calle: duplicar un tramo (Ctrl+D).
- Las callejas curvas del norte y la plaza siguen como estaban (las curvas están en «Decorado» a trozos).
- Mapa pequeño y mapa grande (`ValleyMapUI`): dibujan los tramos y ponen los edificios en su sitio nuevo (anclas).
- Lo que no sigue a los caminos: los dibujos 2D de tierra (ocultos en 3D) y el relieve (no se aplana bajo las calles).

## Pincel para pintar zonas (hecho el 2026-11-10, en el portátil)
- Complemento propio **«Pincel del mapa»** (`addons/pincel_mapa/`, activado en project.godot): panel «Pincel» a la
  derecha. Mezclas en `mapa/pincel_mezclas.gd` (pinos, mixto, sauces, matorrales, hierba, rocas, troncos) o «lo
  seleccionado» (copias de modelos del usuario). Pintar/goma, tamaño y «apretado»; no siembra en río, lago, edificios
  (movidos incluidos) ni caminos; separación mínima entre piezas; Ctrl+Z deshace el trazo. Núcleo en
  `mapa/pincel_nucleo.gd`; prueba sin editor `tools/tests/pincel_mapa.gd` (8/8). Guía: `docs/PINCEL_MAPA_GUIA.md`.
- **Probado dentro del editor de Godot** (portátil, 2026-11-10) con ratón simulado: pinta, borra, Ctrl+Z deshace los
  trazos y la escena no se guarda sola. Prueba: `PINCEL_PRUEBA=1` (ver final de `pincel_plugin.gd`). El panel va en la
  barra de abajo («Pincel del mapa», junto a Output) y se abre solo al abrir Mundo3D. Pendiente menor: no evita suelos
  de adorno del Decorado (terrazas empedradas).
- Aviso aparte: `tools/hornear_decorado.gd` da error al cargar en Godot 4.7.2 del portátil (`PackedByteArray.hash()` no
  existe); solo afecta a esa herramienta.
- Para sumar los modelos del usuario a las mezclas fijas: añadirlos a `pincel_mezclas.gd` (ruta «res://mis_recursos/…»).

## Lo que falta (en orden)
1. ~~Girar~~ (hecho, arriba). Pendiente menor: los muebles 2D sueltos que no pasan por `_add_*` no giran su colisión.
2. ~~Interiores pieza a pieza~~ (hecho, arriba).
3. ~~Bajo tierra~~ (hecho, arriba). Las mascotas de casa van con su dueño.
   (Hecho el 2026-11-10: huertos, gallinero, animales de granja con su corral, campamento, muro débil, cajas, carro y
   caballo siguen a sus anclas mediante `VillageManager._anclas_repaso_final()`.)
4. **Lógica** (después, decisión del usuario): rutas y puestos de trabajo de los vecinos, caminos del mapa pequeño y del suelo
   aplanado (los caminos 3D se mueven pero el minimapa no), pistas del Caso I que el código busca por coordenadas fijas
   (p. ej. distancia al claro en VillageManager), recolocar el Caso I tras mover edificios.
5. Suelo, agua del río y del lago y orillas siguen en código a propósito (el río se edita con `mapa/EditorMapa.tscn`).
