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
- [ ] **No hay cielo ni textura en el suelo** en primera persona: cielo azul plano y césped liso; todo se ve tosco.
  El usuario quiere **empezar a ambientar el pueblo ya** (cielo con nubes y hora del día, suelo con textura, hierba,
  niebla), aunque más adelante compre arte · 1.ª persona, de día.
- [ ] **Todas las casas comparten la misma puerta**, que a veces no pega con la fachada · 1.ª persona.
- [ ] **Árboles 3D raros en todo el pueblo:** copas como bloques arrugados con ramas rosas pegadas por fuera; se
  amontonan y se solapan entre sí y con muros · parque, campamento, lago · 3D, de día.
- [ ] **El parque (junto al campamento del oeste) es ridículamente pequeño:** un cuadrado de césped con muro bajo y un
  banco tapado por los árboles · 3D.
- [ ] **Lago del Oeste:** (1) ✅ (2026-11-07) ocultado el segundo muelle 2D plano cuando el 3D está activo (`FishingSpot.gd`); (2) el **lavadero** a la orilla de un
  lago no tiene sentido (debería ir junto a un arroyo o fuente del pueblo); (3) un **banco pequeño** con cosas sin
  sentido alrededor; (4) ✅ (2026-11-07) **el jugador ya no camina por encima del agua** (`FishingSpot.gd::_build_water_collision` añade colisión física al contorno del lago dejando libre el muelle) · 3D, de día.
- [x] ✅ (2026-11-07) **Parque del Roble (atardecer):** bancos y macetas **se ven a través de los árboles** (se dibujan encima de las
  copas); además el letrero «Parque del Roble» queda tapado por bocadillos · 3D, 19:21 (`VillagePlaces.gd` y `WorldStage3D.gd`: ocultados los sprites 2D de bancos/macetas/pinos en modo 3D, construido el Parque del Roble 3D en `PARK_RECT` real y subido el letrero a `y = 194`).
- [x] ✅ (2026-11-07) **Textos encima de otros:** «Esquilando lana 90 %» se monta sobre el letrero «Rancho del Sur» · 3D (`VillageManager.gd::_construct_solid_building`: subidos los carteles de título de edificio a `-half.y - 36.0`).
- [x] ✅ (2026-11-07) **El Hermano Anselmo y la maestra llevan un libro gigante** en la mano, sin sentido (¿objeto de mano mal
  escalado?) · 3D, de noche junto al Mirador del Lago (`CharacterRig3D.gd` y `CharacterAvatar3D.gd`: ajustada la caja de escala de `Book_5.gltf` a `Vector3(0.18, 0.04, 0.22)` y equipado solo mientras están trabajando de día en su puesto).
- [x] ✅ (2026-11-07) **Cementerio Parroquial del Alba:** lápidas gigantes (del tamaño de camas), el recinto parece una caja vacía de
  tierra · 3D, de día (`VillageWorldBuilder.gd` y `WorldStage3D.gd`: ocultados los rectángulos 2D en modo 3D, reducido el tamaño de túmulos y lápidas 3D a `Vector2(6.8, 3.2)` × `8.8` de alto, y añadidos sendero central y lápidas parroquiales antiguas).
- [ ] **La trattoria «Il Corvo» está justo al lado del cementerio:** no tiene sentido abrir un restaurante ahí.
  Moverla a un sitio con vida (calle principal o plaza). Ojo: es error de Claude Code al elegir el hueco libre.
- [ ] **Taberna «El Jabalí Dorado» da pena** (2026-11-07): interior vacío, la «mesa de billar» es un tablero con un rectángulo verde y patas de cama, nadie sentado. Rehacerla la primera: mucho más grande, 2 pisos (cuartos de huéspedes arriba), mesas con gente comiendo, póker, tabernero en el mostrador y al menos un camarero.
- [ ] **Alcantarillas vacías** (2026-11-07): son un pasillo con 3 cofres sueltos; no se ve el sitio de las peleas clandestinas que se supone que está ahí.
- [x] ✅ (2026-11-07) **Casi todos los vecinos con la misma ropa** (2026-11-07): en `assests/curated_3d/characters/` hay más: campesino y explorador (hombre y mujer), 2 texturas de campesino, 2 de explorador, 5 peinados, barba, y tonos de piel claro/oscuro. Usarlos todos y repartirlos por oficio y por persona (`CharacterRig3D.gd` y `CharacterAvatar3D.gd`).
- [ ] **Tablón de encargos feo y no se lee** (2026-11-07): 3 papeles lisos en una tabla. El usuario quiere leer los encargos desde fuera (texto pequeño en cada papel, uno por encargo real) aunque para aceptarlos haya que abrir el menú.
- [ ] **Rancho casi vacío** (2026-11-07): solo 1 alpaca y 1 pollo. Hay modelos de vaca, toro, caballo, burro, alpaca… Llenarlo con un rebaño creíble (que se crie y venda, no de adorno).

- [ ] **Las peleas clandestinas no aparecen en la partida** (2026-11-07): el usuario no las ha visto nunca. En teoría
  existen (club en un sótano, trampilla en el patio trasero de la taberna, noches de día par de 23:00 a 3:00), pero o
  no funcionan o es imposible encontrarlas. Comprobar en partida que abren y que hay gente; hacer la trampilla visible
  para quien sepa buscar (rumores, un vecino que te lo cuente) y, con la taberna nueva, poner el club en su sótano.

- [x] ✅ (2026-11-07) **El examen de un cuerpo que no es de un caso inventa pistas** (2026-11-07): el usuario mató con sigilo al
  carnicero Garrick en el bosque y el examen dijo «dos marcas rojas en las muñecas, como si lo hubieran atado»,
  «fibra de cáñamo encerado», «barro del vestido» (es hombre), «huele a ceniza, no al lodo del arroyo» y una marca en el
  cuello: textos copiados del caso de la mujer del bosque. **Los muertos que no son de un caso deben describir lo que
  pasó de verdad** (heridas reales que guarda el juego: zona, arma, por la espalda, caída, hora, sitio, clima). Sin
  marcas que no existieron; textos según sea hombre o mujer (`VillageNPC.gd::stealth_assassinate` y `DetectiveUI.gd`).

## Arreglados
- [x] ✅ (2026-11-07) Fachada de la trattoria «Il Corvo» en 3D: parece de tablas oscuras en vez de estuco/ladrillo claro (`WorldStage3D.gd`: cambiada la textura de muros de `building_restaurant` a `town_textures/wall_brick_sand_center.png` con `uv1_scale = Vector3(2.4, 0.72, 2.4)`, tono claro de estuco/ladrillo cálido `Color(1.0, 0.95, 0.84)`, iluminación cálida de rebote `0.58` en la fachada sur y dintel con el mismo estuco en vez de `rf_planks.png`).
