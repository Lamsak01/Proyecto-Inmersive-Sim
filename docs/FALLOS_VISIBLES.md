# Fallos visibles (lista del usuario)

> El usuario apunta aquí lo que ve mal al jugar, aunque sea una frase. **Todo agente empieza cada encargo mirando esta
> lista**: arregla primero lo que toque su trabajo y marca lo arreglado con ✅ y la fecha (no lo borres).
> Formato: `- [ ] Qué se ve mal · dónde · cuándo (hora del juego, 2D/3D/primera persona)`.

## Pendientes
- [ ] **El campamento inicial está en medio del pueblo** (tienda, hoguera y tronco pegados a las casas); las texturas
  se aprietan entre sí · 1.ª persona, de noche.
- [ ] **Todo está demasiado comprimido** (petición grande del usuario): pueblo, campamento, lago, bosque y llanura
  están pegados. Quiere **un mapa unas 3 veces más grande**, con todo más separado y más largo (ver `ENCARGO_SIGUIENTE.md`).
- [ ] **El bosque parece un parque:** demasiado cerca del pueblo, poca vegetación, y su borde (dónde empieza y acaba)
  es recto y mecánico; saca de la inmersión · 3D, de día.
- [ ] **Los animales solo rondan sus nidos/madrigueras** y siempre van todos juntos; no hacen nada más · bosque.
- [ ] **Enemigos todavía en 2D** (los sapos de la Llanura Salvaje) · de día. **Petición:** mantener los sapos, pero con **modelo 3D basado en su
  sprite** (mismo diseño: sapo verde de pie con ropa roja). *(✅ 2026-11-07: ocultados por defecto los conos de visión de depuración en `VisionCone2D.gd` y `DummyEnemy.gd`)*.
- [ ] **«Huerto vecinal» plantado en medio de un camino** (cajones encima del sendero junto a la Residencia Aguas
  Claras): quitarlo de ahí; el usuario no lo quiere en ese sitio · 3D, de día.
- [ ] **Biblioteca: «Leer un rato [E]» no hace nada** (el letrero promete una interacción que no existe) · de noche.
- [ ] **Los edificios antiguos son diminutos y feos:** cuartos de una sala, muebles arrinconados, sprites sin sentido
  (p. ej. la comisaría: rejas verdes gigantes, cajón suelto, cepo). **Petición del usuario:** que TODOS los edificios
  tengan el nivel de detalle de la trattoria (varias salas con sentido, muebles 3D colocados, luces). Es un proyecto
  grande: hacerlo edificio a edificio, empezando por los que pisa el detective (comisaría, morgue/hospital, capilla,
  taberna, biblioteca).
- [x] ✅ (2026-11-07) **Trattoria: quitar la cama** del cuarto del dueño (no pinta nada en un restaurante; que sea un despacho) (`VillageRestaurant.gd` y `WorldStage3D.gd`: renombrada la sala a «Despacho del dueño» y sustituidas las camas por escritorio de madera, sillas, libro de cuentas, candelabro, estantería y alfombra).
- [x] ✅ (2026-11-07) **La ropa atraviesa el cuerpo** de algunos vecinos (al guardia se le sale el hombro por la ropa) · 1.ª persona (`AssetLibrary3D.gd::extract_head_only_mesh` y `CharacterRig3D.gd`: recortados los vértices con `abs(x) <= 0.135` y `y >= 1.45` para que los hombros/brazos en T-pose de la malla base nunca asomen por las mangas).
- [x] ✅ (2026-11-07) **No hay cielo ni textura en el suelo** en primera persona: cielo azul plano y césped liso; todo se ve tosco.
  El usuario quiere **empezar a ambientar el pueblo ya** (cielo con nubes y hora del día, suelo con textura, hierba,
  niebla), aunque más adelante compre arte · 1.ª persona, de día (`WorldStage3D.gd` y `AssetLibrary3D.gd`: añadido cielo dinámico `SKY_CLOUD_SHADER_CODE` con bóveda celeste que cambia según la hora, sol/luna, estrellas nocturnas y 2 capas de nubes volumétricas en movimiento; suelo con shader multiescala `GROUND_TERRAIN_SHADER_CODE` y cientos de matas de hierba, helechos y flores 3D `_build_ground_foliage_3d`; variedad de árboles `CommonTree_1..4`, `BirchTree_1..3` y `PineTree_1..4` por zona; y niebla atmosférica reactiva a la hora y al clima).
- [ ] **Todas las casas comparten la misma puerta**, que a veces no pega con la fachada · 1.ª persona.
- [x] ✅ (2026-11-07) **Árboles 3D raros en todo el pueblo:** copas como bloques arrugados con ramas rosas pegadas por fuera; se
  amontonan y se solapan entre sí y con muros · parque, campamento, lago · 3D, de día (`AssetLibrary3D.gd`: corregido el orden horario CW de triangulación de caras `.obj` que invertía las copas por dentro y ajustados los colores de `Wood`/`Green`/`DarkGreen` en `_parse_mtl_file` para eliminar el tono rosa; `WorldStage3D.gd::_scan_nature_sources`: filtrados los pinos decorativos que solapaban muros de edificios o estaban a `< 18 px` de otro árbol).
- [x] ✅ (2026-11-07) **El parque (junto al campamento del oeste) es ridículamente pequeño:** un cuadrado de césped con muro bajo y un
  banco tapado por los árboles · 3D (`VillagePlaces.gd`, `VillageWorldBuilder.gd`, `WorldStage3D.gd`: ampliado `PARK_RECT` a `Rect2(168, 208, 272, 146)`, retirado el murete bajo perimetral, añadidos paseos en cruz y separados los árboles de las esquinas respecto a los bancos).
- [x] ✅ (2026-11-07) **Lago del Oeste:** (1) ✅ (2026-11-07) ocultado el segundo muelle 2D plano cuando el 3D está activo (`FishingSpot.gd`) y eliminado el segundo embarcadero 3D del sur (`WorldStage3D.gd::_build_barrios_3d`); (2) ✅ (2026-11-07) el **lavadero** se trasladó a `Vector2(215, 145)` junto a la fuente/acequia del pueblo (`VillageWork.gd`, `WorldStage3D.gd`); (3) ✅ (2026-11-07) recolocado el Mirador del Lago sin cachivaches alrededor; (4) ✅ (2026-11-07) **el jugador ya no camina por encima del agua** (`FishingSpot.gd::_build_water_collision` añade colisión física al contorno del lago dejando libre el muelle) · 3D, de día.
- [x] ✅ (2026-11-07) **Parque del Roble (atardecer):** bancos y macetas **se ven a través de los árboles** (se dibujan encima de las
  copas); además el letrero «Parque del Roble» queda tapado por bocadillos · 3D, 19:21 (`VillagePlaces.gd` y `WorldStage3D.gd`: ocultados los sprites 2D de bancos/macetas/pinos en modo 3D, construido el Parque del Roble 3D en `PARK_RECT` real y subido el letrero a `y = 194`).
- [x] ✅ (2026-11-07) **Textos encima de otros:** «Esquilando lana 90 %» se monta sobre el letrero «Rancho del Sur» · 3D (`VillageManager.gd::_construct_solid_building`: subidos los carteles de título de edificio a `-half.y - 36.0`).
- [x] ✅ (2026-11-07) **El Hermano Anselmo y la maestra llevan un libro gigante** en la mano, sin sentido (¿objeto de mano mal
  escalado?) · 3D, de noche junto al Mirador del Lago (`CharacterRig3D.gd` y `CharacterAvatar3D.gd`: ajustada la caja de escala de `Book_5.gltf` a `Vector3(0.18, 0.04, 0.22)` y equipado solo mientras están trabajando de día en su puesto).
- [x] ✅ (2026-11-07) **Cementerio Parroquial del Alba:** lápidas gigantes (del tamaño de camas), el recinto parece una caja vacía de
  tierra · 3D, de día (`VillageWorldBuilder.gd` y `WorldStage3D.gd`: ocultados los rectángulos 2D en modo 3D, reducido el tamaño de túmulos y lápidas 3D a `Vector2(6.8, 3.2)` × `8.8` de alto, y añadidos sendero central y lápidas parroquiales antiguas).
- [x] ✅ (2026-11-07) **La trattoria «Il Corvo» está justo al lado del cementerio:** movida a la Calle Mayor (`Rect2(-255, -206, 275, 190)`), con su puerta y terraza abiertas al camino principal hacia la Plaza Central y a más de 1.100 px del cementerio (`VillageRestaurant.gd`, `WorldStage3D.gd`, `ValleyMapUI.gd`, `verify_all.gd`).
- [x] ✅ (2026-11-07) **Taberna «El Jabalí Dorado» da pena** (2026-11-07): interior vacío, la «mesa de billar» es un tablero con un rectángulo verde y patas de cama, nadie sentado. Rehacerla la primera: mucho más grande, 2 pisos (cuartos de huéspedes arriba), mesas con gente comiendo, póker, tabernero en el mostrador y al menos un camarero (`VillageTavern.gd`, `WorldStage3D.gd`, `VillageNPC.gd`, `VillageNeeds.gd`, `VillagePlaces.gd`, `VillageManager.gd`: edificio ampliado a `Rect2(260, -316, 348, 184)` con 2 plantas reales unidas por escalera física, 6 mesas de comedor con 12 sillas y clientes sentados, mesa de póker con 4 sillas y jugadores en vivo, mesa de billar 3D auténtica con 4 patas torneadas de caoba, 6 troneras, paño verde esmeralda, bolas y tacos, Marta atendiendo detrás del mostrador y nuevo oficio `WAITER` = Camarero sirviendo mesas).
- [ ] **Alcantarillas vacías** (2026-11-07): son un pasillo con 3 cofres sueltos; no se ve el sitio de las peleas clandestinas que se supone que está ahí.
- [x] ✅ (2026-11-07) **Casi todos los vecinos con la misma ropa** (2026-11-07): en `assests/curated_3d/characters/` hay más: campesino y explorador (hombre y mujer), 2 texturas de campesino, 2 de explorador, 5 peinados, barba, y tonos de piel claro/oscuro. Usarlos todos y repartirlos por oficio y por persona (`CharacterRig3D.gd` y `CharacterAvatar3D.gd`).
- [ ] **Tablón de encargos feo y no se lee** (2026-11-07): 3 papeles lisos en una tabla. El usuario quiere leer los encargos desde fuera (texto pequeño en cada papel, uno por encargo real) aunque para aceptarlos haya que abrir el menú.
- [ ] **Rancho casi vacío** (2026-11-07): solo 1 alpaca y 1 pollo. Hay modelos de vaca, toro, caballo, burro, alpaca… Llenarlo con un rebaño creíble (que se crie y venda, no de adorno).

- [x] ✅ (2026-11-07) **Las peleas clandestinas no aparecen en la partida** (2026-11-07): el usuario no las ha visto nunca. En teoría
  existen (club en un sótano, trampilla en el patio trasero de la taberna, noches de día par de 23:00 a 3:00), pero o
  no funcionan o es imposible encontrarlas. Comprobar en partida que abren y que hay gente; hacer la trampilla visible
  para quien sepa buscar (rumores, un vecino que te lo cuente) y, con la taberna nueva, poner el club en su sótano (`VillageClub.gd`, `VillageTavern.gd`, `VillageUnderworld.gd`, `NPCDialogue.gd`, `WorldStage3D.gd`: trasladada la trampilla `TRAPDOOR_POS = Vector2(516, -286)` dentro de la sala trasera de escalera/bodega de la nueva taberna, abierta todas las noches de `21:00` a `03:00` —también el Día 1— y añadidos rumores en la taberna y opción de diálogo con Marta o el Camarero sobre los ruidos del sótano).

- [x] ✅ (2026-11-07) **El examen de un cuerpo que no es de un caso inventa pistas** (2026-11-07): el usuario mató con sigilo al
  carnicero Garrick en el bosque y el examen dijo «dos marcas rojas en las muñecas, como si lo hubieran atado»,
  «fibra de cáñamo encerado», «barro del vestido» (es hombre), «huele a ceniza, no al lodo del arroyo» y una marca en el
  cuello: textos copiados del caso de la mujer del bosque. **Los muertos que no son de un caso deben describir lo que
  pasó de verdad** (heridas reales que guarda el juego: zona, arma, por la espalda, caída, hora, sitio, clima). Sin
  marcas que no existieron; textos según sea hombre o mujer (`VillageNPC.gd::stealth_assassinate` y `DetectiveUI.gd`).

- [ ] **Muchos vecinos siguen trabajando en el sitio antiguo de los edificios** (2026-11-07, tras agrandar el mapa y mover
  la trattoria/la taberna): van a trabajar donde estaba el edificio, no donde está ahora. Probablemente es la misma causa
  que el saboteador nocturno que no llega al taller (`verify_all` P6b.3a). Buscar todas las posiciones de trabajo, recados
  y rutas escritas a mano que no siguieron al edificio.

- [ ] **Las alcantarillas aparecen en medio del bosque** (2026-11-07, tras agrandar el mapa): en 3D no se ven, pero en
  2D sí, y tienen colisión (chocas con algo invisible en 3D). Ponerlas en su sitio (bajo el pueblo, con su entrada) y que
  en 3D se vean igual que en 2D.

## Arreglados
- [x] ✅ (2026-11-07) Fachada de la trattoria «Il Corvo» en 3D: parece de tablas oscuras en vez de estuco/ladrillo claro (`WorldStage3D.gd`: cambiada la textura de muros de `building_restaurant` a `town_textures/wall_brick_sand_center.png` con `uv1_scale = Vector3(2.4, 0.72, 2.4)`, tono claro de estuco/ladrillo cálido `Color(1.0, 0.95, 0.84)`, iluminación cálida de rebote `0.58` en la fachada sur y dintel con el mismo estuco en vez de `rf_planks.png`).
