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
- ~~El giro en 3D se ve «aplastado» en el mapa 2D por la inclinación de la cámara (58°)~~. Desde el paso 0b
  (2026-11-10, `docs/PLAN_MUNDO_3D.md`) el 3D es uniforme y en metros: un giro en el editor es el mismo giro en el mapa.

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

## Escala uniforme en metros (paso 0b del paso a 3D, 2026-11-10)
- `mapa/Mundo3D.tscn` se convirtió con `tools/convertir_escala_0b.py` (copia: `mapa/Mundo3D.antes-3d.tscn`). Todo sigue
  en el mismo sitio del pueblo; en 3D el pueblo es ~15 % más corto de norte a sur y todo es ×2,8 más grande (metros).
- Si Godot tenía Mundo3D abierto: cerrar la pestaña **sin guardar** y volver a abrirla.

## Árboles separados en el bosque del Caso I (2026-11-12)
- `tools/esparcir_arboles.gd -- <px> [x1,y1,x2,y2]` quita de «Vegetacion/Arboles» los árboles con el tronco a menos de
  esos px de otro ya conservado (solo dentro del rectángulo; sin él, todo el mapa). Pasado una vez con 24 px en el bosque
  del Caso I (19 quitados). Si Godot tenía Mundo3D abierto: recargar la escena sin guardar.

## Edificios como escenas (2026-11-11, paso 1 de `docs/PLAN_MUNDO_DESDE_EDITOR.md`)
- Los 29 edificios fijos son escenas en `mapa/edificios/<id>.tscn` (mallas y texturas compartidas en `comun/`); en
  Mundo3D → «Edificios» cada pieza es una copia de su escena. Grupos fijos (`scripts/visuals/PartesEdificio3D.gd`):
  **Muros**, **Interior**, **PisoAlto**, **Tejado**, **Muebles** (piezas `mapa/mueble.gd`) y **Marcas** (`Marker3D` con `mapa/marca.gd` e `id_marca`: sitios de la lógica; 279 marcas en 32 escenas a 2026-11-11, lista en `docs/ESTADO_ACTUAL.md`; el código los lee con `Marca.sitio`).
- Para cambiar un edificio por dentro: abrir su escena (doble clic en `mapa/edificios/…`), mover muebles, guardar.
- Lo que se mueve jugando (puerta, postigo, luces de noche, reja de la celda, puertas de cuarto, cuerpos de la morgue)
  lleva una etiqueta (metadato `rol`); el juego lo busca por la etiqueta, no por nombre ni posición.
- El juego (`WorldStageBuildings3D._poner_edificio_de_escena`) cuelga la escena en el centro de la planta, con su giro.
- Las casas de recién llegados (`house_family_lot_<solar>`) son copias de tres **casas modelo**
  (`mapa/edificios/modelo_casita|casa|casona.tscn`, según el `plot` del solar; `mapa/casa_modelo.gd`). Están hechas con
  la puerta al sur; con la puerta al norte el juego las pone con media vuelta (`CasaModelo.giro_de_fabrica`) y su
  planta se lee girada (`Planta.con_media_vuelta`). No tienen pieza en «Edificios»: van con su solar. Camas, mesa y cofre salen de sus
  marcas (`cama_N`, `cama_alta_N` con altillo, `mesa`, `cofre`) respecto al centro del solar. Las casas que se levantan
  jugando no tienen pieza en el valle: usan la casa modelo directamente. Sus muebles no llevan `clave` (sin anclas).
- **Planta y puerta desde la escena** (`mapa/planta.gd`, 2026-11-11): la pieza guarda `planta_m` (ancho × fondo en
  metros) y `puerta_ancho_m`; las marcas `puerta` y `ventana` dan su sitio. `Planta.de_edificio(id)` devuelve
  `size`, `door_dir` (muro más cercano a la marca), `door_width`, `door_offset` y `window_offset` en px del mapa
  original; `VillageManagerBase._construct_solid_building` lo lee solo (las casas modelo pasan `CasaModelo.planta`, con
  media vuelta si el solar mira al norte). Al girar un edificio la ventana gira con él. El dibujo no cambia solo.
- **Tabiques** (`mapa/tabique.gd`, 2026-11-11): grupo «Tabiques» de la escena, una pieza por pared de dentro (`tam_m`
  ancho × fondo en metros, `tapa_vista`). `Planta` los devuelve en `partitions` y `_construct_solid_building` los crea
  y los deja en `vm.interior_walls[id]` (la taberna los apaga al subir de planta). 39 tabiques en 13 edificios.
- **Solares** (`mapa/solar.gd`, carpeta «Solares» de Mundo3D, paso 2, 2026-11-11): 40 piezas con `id_solar`,
  `centro_original` y `terreno_m`. `mapa/anclas.gd` registra un ancla por solar (rectángulo del terreno, giro de 90 en
  90) con la prioridad más baja (`PASADAS`: primero edificios y objetos, dentro o pegados; al final el solar). Un
  edificio sin pieza propia (`EdificioEditor.tiene_pieza`) hereda sitio y giro del ancla de su solar en
  `_construct_solid_building`. Estacas y obra (`rebuild_lots_3d`) se escriben en el mapa original y siguen al solar.
  Los datos del solar (zona, tamaño de casa, lado de la puerta) siguen en `VillageLots.LOTS`: pendiente de pasar.
  El ancla cubre además `SOLAR_LETRERO_PX` (16 px) al norte y al sur del terreno: ahí va el letrero de solar libre
  (`VillageLots.site_work_pos`), que ya no tiene ancla propia en «Objetos».
- **Sitios** (`mapa/sitio.gd`, carpeta «Sitios», paso 3, 2026-11-12): cruces (`Marker3D`) con `id_sitio` para la lógica
  de vecinos fuera de edificios. Su posición es la del mundo: `Sitio.mundo(id)` y `Sitio.serie(nombre)` (`nombre_1`,
  `nombre_2`…) no se traducen. `Sitio.original(id)` (= `Anclas.desmover`) solo para funciones que aún traducen lo que
  reciben (`setup_npc`); desaparece en el paso 4. No son anclas: mover una cruz no arrastra nada más. 86 (grupo 5: mascotas y claro del Caso I; grupo 3: ocio,
  ronda nocturna, mercado, lavadero, caravana, puerta del este, caballo, botín, perista, entradas).
- **Zonas** (`mapa/zona.gd`, carpeta «Zonas», 2026-11-11): `zona_plaza`, `zona_lago`, `zona_cienaga`, con `id_zona`,
  `centro_original` y `terreno_m` (tamaño en el mundo). `mapa/anclas.gd` las registra como anclas que **estiran** ×E
  (no compactas), con la prioridad de un solar. `Anclas.estirar(p)`/`estirar_puntos` (original → mundo, solo miran
  zonas) sustituyen al «× E» en el terreno por código (`estirar_terreno`); `Anclas.desestirar(p)` (mundo → original) lo
  usa el relieve y `Agua.en_lago`; el hueco viejo de una zona movida se lee como su borde. No giran.
- **Puesto del Paso** (tanda 2, 2026-11-11): pieza `solar_puesto_del_paso` (centro original (1593, 47), 242×178 px).
  Camino, estacas, empalizada, sacos, foco y letrero están escritos en el mapa original (`VillageCulture.OUTPOST_*`,
  `rebuild_outpost_3d` con `mover_posiciones`) y van con la pieza.
- Ya no queda dibujo de edificios por código (2026-11-11): un edificio sin escena da un error al arrancar y no se
  dibuja. Las herramientas de conversión (`convertir_edificios.gd`, `guardar_recursos_comunes.gd`) se borraron al
  terminar; un edificio nuevo se hace copiando una escena de `mapa/edificios/` en el editor.
- Las texturas de los muros pueden verse corridas unos centímetros respecto a antes (se pegan al edificio, no al mundo).

## Mapa ×5 (2026-11-11/12)
- Las escenas `mapa/Mundo3D.tscn` y `mapa/EditorMapa.tscn` se convirtieron con `tools/estirar_mapa.py` y
  `estirar_mapa_objetos.py` (copias `*.antes-x5.tscn`). Las piezas siguen la regla de las anclas: edificio a E·centro con
  su tamaño (`mapa/edificio.gd`: `d = ahora − centro·E`), objetos igual (`mapa/objeto.gd` devuelve el número fijo y el
  ancla lo lleva), campo abierto ×E.
- Editor: la maqueta «Vista» de Mundo3D y la «Referencia» de EditorMapa (`mapa/mundo3d.gd`, `mapa/referencia.gd`) estiran
  la referencia del mapa original (caminos, lago, suelo, plantas de los edificios); `rio.gd` dibuja cada paso alargado
  hasta las orillas como hace el juego (no sale rojo sin motivo); rangos de «ancho» del río (hasta 400) y «largo» de
  los cruces (hasta 400) ampliados.
- Guía del usuario reescrita: `docs/EDITOR_MAPA_GUIA.md` (Mundo3D + EditorMapa, medidas ×5).

