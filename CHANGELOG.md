# Registro de cambios

Cambios del juego, del más nuevo al más antiguo. Añade una entrada al cerrar cada bloque, en lenguaje sencillo.
El historial completo está en `git log`. Lo anterior al 2026-11-09 está en `docs/archivo/CHANGELOG_hasta_2026-11-08.md`.


## 2026-11-13 — Adiós al parón de varios segundos cada hora desde las 12:00 (Claude Code)
- El restaurante, al buscar sitio a sus clientes, volvía a añadir los asientos de la terraza a su lista guardada cada
  vez que la miraba: tras unas horas tenía casi 4.000 asientos y elegir mesa congelaba el juego 4–15 s cada hora.
  Ahora la lista se hace nueva y las guardadas quedan bloqueadas contra cambios.
- Los vecinos que solo cambian lo que llevan en la mano (herramienta, farol) ya no rehacen el cuerpo entero.
- Probado con ventana de 11:00 a 19:00: el peor fotograma, 24 ms (antes paradas de 1–15 s).

## 2026-11-13 — La partida automática del Caso I, otra vez entera (Claude Code)
- La prueba andaba a puntos del mapa viejo y, con los edificios agrandados, ya no llegaba a las pistas del claro, la
  comisaría, la biblioteca, la morgue, la botica, la mansión ni la bandeja del informe. Ahora va al portón por fuera,
  lo abre y entra por la misma ruta que los vecinos hasta las marcas de cada pista; se para delante para mirarla.
- Probado: 25 de 25 pasos en verde (antes 9).

## 2026-11-13 — El Molino Viejo Abandonado, de tamaño real (Claude Code)
- De 6,9 × 5,2 m a 14 × 9,8 m. El muro del portón y el del oeste siguen donde estaban (la rueda, el canal y el barro rojo
  no se mueven); crece al norte y al este. Ruina de piedra, tablas rotas y techo de paja, sin más luz que una vela.
- Sala: foso del sótano con su reja (dos barrotes doblados) junto al muro de la rueda, banco con el cordel, mesa con la
  hoja de papel, dos muelas de piedra rotas. Granero, por un hueco del tabique: pajar, hogar frío con ceniza y leña, y
  la paja donde esperan los dos forasteros. El barro rojo de fuera, que iba pegado al edificio viejo, vuelve a su sitio.
- Arreglo del Caso I: pulsar E en la reja, el cordel o el papel daba otra vez el barro rojo (su radio, de campo abierto,
  llegaba dentro del molino). Ahora se miran antes las pistas de dentro.
- Probado: rutas de los forasteros sin choques, fotos, y la partida automática del Caso I con los 7 pasos del molino en
  verde (antes fallaban 5). Sus otros fallos (claro, comisaría, biblioteca, morgue, botica, mansión) ya estaban.

## 2026-11-13 — Las cuatro tiendas de artesano, de tamaño real (Claude Code)
- Herrería, carnicería, carpintería y pescadería: de 6,5 × 4,3 m a 9,8 × 6,4 m, crecen por detrás (el muro de la
  puerta no se mueve, la plaza de delante queda igual). Tienda con mostrador de dos tramos y un hueco para pasar,
  trastienda con el sitio del maestro, taller del oficio (forja y yunque, tajo, banco de carpintero, tina) y almacén.
- El mercader espera delante del mostrador (marca nueva «cliente») en vez de en un punto fijo del plano viejo.
  Fuera paredes invisibles sobrantes de la botica y un adorno plano de la herrería.
- Rutas: un hueco puede pedir cruzarse más a fondo antes de girar (el del mostrador); los vecinos ya no lo rozan.
  Sillas corregidas en escuela, biblioteca y hospital (metidas en su mesa o al revés).
- Probado: rutas de las 4 tiendas y de 10 edificios más sin choques, 29 puertas, escolta a la celda y fotos.

## 2026-11-13 — La Biblioteca, de tamaño real (Claude Code)
- De 7,2 × 5,4 m a 14 × 9,8 m (madera y teja gris, puerta al sur como siempre): sala de lectura con estanterías por
  las paredes, dos filas de mesas con velas y seis sillas, mostrador junto a la puerta; al este, el archivo.
- La sala oculta del Caso I sigue al noreste: se entra desde el archivo por una estantería abierta como una puerta;
  dentro, la mesa con el cuaderno de firmas y el tomo de venenos. Fuera sus choques fijos del plano viejo.
- Probado: rutas de los lectores sin choques, 29 puertas y fotos. Sin ver: las tres pistas del Caso I en partida.

## 2026-11-13 — La Escuela, de tamaño real (Claude Code)
- De 7,2 × 5,4 m a 14 × 12,6 m (ladrillo arenisca y teja gris, puerta al sur como siempre): aula con seis filas de
  pupitres a cada lado del pasillo, pizarra, mesa del maestro, estufa, librerías y colgador junto a la puerta; detrás,
  el despacho del maestro y un baño con tres retretes y dos lavabos. Caben doce alumnos (antes seis). Solar ensanchado.
- Los niños se atascaban de pie en el pasillo, pegados a los pupitres: ahora cada uno entra de lado por su fila y se
  sienta en su banqueta (cada fila es un trozo de cuarto solo para las rutas).
- Probado: rutas de los niños y del maestro sin choques, 29 puertas y fotos. Sin ver: una clase con niños de verdad.

## 2026-11-13 — La Capilla del Alba, de tamaño real (Claude Code)
- De 7,4 × 5,2 m a 14 × 9,8 m (de piedra, sin luz eléctrica, puerta al norte como siempre): un atrio junto a la puerta
  y, por un arco, la nave con seis filas de bancos a cada lado del pasillo, alfombra, altar con candelabros y atril; a
  un lado la sacristía y al otro la casa del sacerdote (su cama, la del niño expósito si lo hay, y su mesa).
- Los fieles del Oficio se colocan junto a su banco y el expósito duerme y come en casa del sacerdote, sin números fijos
  del plano viejo. Un árbol que quedaba dentro, apartado.
- Probado: rutas de los vecinos sin choques, 29 puertas y fotos. Sin ver: un Oficio de domingo con todos sentados.

## 2026-11-13 — El Hospital y Morgue, de tamaño real (Claude Code)
- De 7,7 × 5,4 m a 14 × 9,8 m (nivel 4, de piedra, puerta al norte como siempre): pasillo con el mostrador de entrada;
  morgue con tres mesas de autopsias de acero (los cuerpos bajo la sábana aparecen cuando hay muertos); urgencias con
  la camilla y una segunda cama; consulta del médico con teléfono; su dormitorio con la mesa donde cena; botica de
  frascos. Farola, una caja y dos sitios de espera apartados.
- Fuera los números fijos del hospital viejo (ruta a mano, zonas sin pisar y una mesa invisible que estorbaba).
- Probado: rutas de los vecinos sin choques, 29 puertas y fotos. Sin ver: los cuerpos de la morgue (solo salen con
  muertos de verdad).

## 2026-11-13 — Código ordenado tras las casas grandes (Claude Code)
- No se nota al jugar: la altura del piso de arriba se calcula en un solo sitio (antes en cuatro) y fuera seis valores
  apuntados que nada usaba (posada y casas). Probado: la casona sale idéntica y la prueba de física pasa.

## 2026-11-13 — La Comisaría y Cárcel, de tamaño real (Claude Code)
- De 8 × 5,4 m a 14 × 9,8 m (nivel 4, de piedra, con la puerta al norte como siempre): sala de guardia con el
  mostrador junto a la puerta (donde se entrega el informe del Caso I); al fondo el calabozo con su reja corredera de
  hierro, catre, cubo y taburete; despacho del comisario con teléfono y terminal; archivo de pruebas con la denuncia;
  dormitorio de guardia, comedor y armería. Sacos terreros y foco recolocados ante la fachada nueva; farola apartada.
- El juego ya no guarda la reja, el catre ni el sitio ante la celda con números fijos: salen de las marcas del edificio.
- Probado: rutas de los vecinos sin choques, escolta del preso hasta la celda (la reja cerrada lo retiene), 29
  puertas y fotos (también con la reja cerrada).

## 2026-11-13 — El Ayuntamiento, de tamaño real (Claude Code)
- De 7,2 × 5,4 m a 14 × 9,8 m (nivel 4, de piedra y teja roja, con luz de la red oficial): vestíbulo de punta a punta
  con alfombra, bancos, urna y el mostrador del fondo con el Libro Mayor de los Gremios; despacho del alcalde con
  teléfono y su terminal; archivo de legajos; tesorería con las arcas; sala de juntas. Los cables de la fachada los
  trae ahora la casa. Apartados dos adornos y un punto de paseo. Probado: rutas de los vecinos sin choques, 29
  puertas y fotos.

## 2026-11-13 — Casas de dos plantas, vista desde arriba (Claude Code)
- Desde arriba, estando en la planta baja de la casona, ya se ve entera: el trozo alto de los muros va con la planta
  alta y se esconde con ella. Desde fuera, arriba o en primera persona la casa se ve completa. Probado con fotos.

## 2026-11-13 — Casas de dos plantas: la Casa Grande de los Rentistas (Claude Code)
- Primera casa con piso de arriba de verdad: de 8,4 × 5,8 m a 11,2 × 8,4 m por planta, de arenisca y teja roja, con
  generador propio. Abajo: recibidor con la escalera, cuarto de cobro de rentas (mesa con teléfono, archivo y cofre),
  comedor con vitrina, cocina con nevera y despensa. Arriba: las alcobas de los dos rentistas, salita con gramola y
  radio, baño completo y vestidor. Los rentistas suben andando a dormir y bajan por la mañana; el protagonista sube y
  baja igual y arriba los ojos van a su altura. Sirve para cualquier casa: basta poner la planta alta en su plano.
- Probado: trayectos de la calle y de cada cuarto a las dos camas de arriba (y vuelta) sin chocar, subida y bajada del
  protagonista (prueba de física), 29 puertas y fotos de las dos plantas.

## 2026-11-13 — La mansión del Señor del Valle, de tamaño real (Claude Code)
- Primera casa de nivel 4: de 10,1 × 6,7 m a 19,6 × 14 m, de piedra y teja roja, con generador diésel propio y su
  cable hasta el cuadro de la puerta. Gran salón de punta a punta (recibidor con teléfono y, al fondo, chimenea, retratos
  y mesa de banquete con candelabros y lámpara de techo); alcobas del señor y de la señora, despacho (escritorio con
  teléfono, terminal verde, librerías y sitio libre para el gabinete del Caso I), cocina con nevera, cuarto de la
  criada, baño completo y cuarto del heredero. Objetos nuevos del nivel 4: teléfono de baquelita, nevera, lámpara de
  techo, chimenea labrada, candelabro y retrato. Quitada la mesa plana que el juego ponía encima. Sin piso de arriba
  (el juego no tiene pisos en las casas). Probado: rutas de los vecinos por dentro sin choques, fotos y puertas 29/0.

## 2026-11-13 — Casas de los recién llegados, de tamaño real (Claude Code)
- Las tres casas que se levantan en los solares crecen y se hacen por cuartos (nivel pobre): casita de 9,2 × 6,4 m,
  casa de 11,2 × 8,4 m y casona de 12,6 × 9 m, con sala-cocina con lumbre, dormitorio por cama, aseo con tina,
  despensa y letrina. Los vecinos cruzan por las puertas de los cuartos; los muebles de tu casa (mesa, escalera,
  escondite, banco, mostrador) van a sitios de la sala; altillo y sótano miden lo que la casa. Terreno de 25 solares
  agrandado; apartados un punto de paseo y un cartel. Probado: 5 casas levantadas (los 3 tamaños, puerta al sur y al
  norte) sin choques de la calle a camas y mesa, y 29 puertas.

## 2026-11-13 — El Albergue del Alba, de tamaño real (Claude Code)
- De 6,3 × 4,4 m a 11,2 × 8,4 m (pobre): comedor con lumbre, caldero de gachas y mesa larga; dormitorios de hombres y
  de mujeres con dos camas cada uno; aseo con tina, despensa de sacos y letrina fuera; tejado de chapa. Probado: 29
  puertas y los trayectos de la puerta a las cuatro camas sin chocar.
- El camino que pasaba por debajo del albergue hasta la calle del sur ahora acaba en su puerta.

## 2026-11-13 — La casa-taller del Arreglador, de tamaño real (Claude Code)
- Primera casa acomodada (nivel 3): 14 × 10 m con sala, dos dormitorios, baño con retrete, lavabo y bañera, cocina con
  fregadero de grifo y taller con la terminal verde; bombilla en cada cuarto, ventilador, gramola y radio. El generador
  diésel y su cable por la fachada hasta el cuadro van con la casa (se quitó un cable suelto que cruzaba el interior y un
  segundo generador). Probado: 29 puertas y los trayectos de dentro sin chocar.

## 2026-11-13 — La posada de los Candil, de tamaño real (Claude Code)
- Misma casa-taller de artesano, con el cuarto del fondo hecho alcoba de huéspedes (dos camas, mesilla y arcón). Los
  Candil pasan a artesanos («Posada Humilde»). Probado: 29 puertas y 72 trayectos dentro sin chocar.

## 2026-11-13 — Casas-tienda de artesano: panadería, sastrería, herbolaria, granja y rancho (Claude Code)
- Las cinco pasan a 12,6 × 9 m: sala-cocina con estufa, bomba de agua, mesa, radio y el mostrador junto a la puerta;
  dos dormitorios con quinqué; taller con bombilla y lo de cada oficio (horno de pan, maniquí, caldero de hierbas,
  cajas de verdura, cubos); aseo con bañera de cinc; letrina fuera. Dos de ellas al revés.
- Apartados adornos, cajas y sitios de paseo que caían dentro; el árbol de la herbolaria deja libre la puerta.
  Probado: 29 puertas y 210 trayectos dentro de las 5 casas sin chocar ni atascarse.

## 2026-11-13 — Casas pobres de tamaño real: el leñador y la cantera (Claude Code)
- Casa-taller de 11,2 × 8,4 m: sala con lumbre de piedra, mesa con vela y barril de agua; dos dormitorios con vela;
  taller con banco, tajo y leña; aseo con tina de madera; letrina fuera. Su poco de técnica: linterna de dinamo,
  radio de galena y tejado de chapa ondulada. Probado: 29 puertas y 112 trayectos dentro sin chocar ni atascarse.
- Reparto de clases por familia apuntado en la visión (pobres, artesanos, acomodados, señores).

## 2026-11-13 — Las cuatro casas de artesano, ya de tamaño real (Claude Code)
- Carnicero, carpintero y pescadero estrenan la misma casa que el herrero; dos de ellas al revés (dormitorios al otro
  lado) para que las vecinas no sean calcadas. Probado: 29 puertas sin atascos y 80 trayectos dentro de las 4 casas.

## 2026-11-13 — Casa de prueba de los interiores de tamaño real: la del herrero (Claude Code)
- La casa de Thoran y Kael pasa de una sola habitación de 6 × 4 m a una casa de 12,6 × 9 m: sala con mesa, radio de
  válvulas y bombilla; un dormitorio para cada uno; cocina con estufa de hierro y bomba de agua; aseo con bañera de
  cinc; letrina en el patio. Los vecinos cruzan de cuarto a cuarto por las puertas (que se abren solas).
- Nuevo constructor de casas: cada casa sale de un plano con sus cuartos, tabiques, ventanas y muebles; las paredes se
  juntan en una sola malla para no cargar el portátil. Probado: 29 puertas sin atascos; 8 trayectos dentro de la casa.

## 2026-11-13 — Terraza del restaurante, camas de mascota y puentes de orilla a orilla (Claude Code)
- Las macetas, postes, losa y bombillas de la terraza del restaurante se habían quedado a 39 m (×5 dentro de su malla):
  vuelven delante de la puerta. Las camas de Sultán, Pelusa y Sombra salen de la plaza y vuelven junto a su tienda.
- Los tres puentes del río se alargan hasta pisar las dos orillas (antes 4–6 m sobre 7–8 m de agua).

## 2026-11-13 — Línea blanca del molino y altar de la capilla en el prado (Claude Code)
- Al mover los edificios con el ×5, algunos vértices de sus mallas horneadas se quedaron en el sitio viejo: 2 del molino
  (un triángulo finísimo hasta el cielo: la «línea blanca») y 6.242 del interior de la capilla (altar, velas y cálices
  junto al puente central), más una luz. Devueltos a su edificio; las 84 mallas revisadas.

## 2026-11-13 — Puentes del río recompuestos y editor del mapa más fiel (Claude Code)
- Los 3 puentes del río (centro, norte y sur): barandillas, postes y estribos estaban separados metros del tablero; juntados
  con su forma original (`tools/juntar_decorado.py`).
- Pincel del mapa: ya no siembra dentro de los edificios (miraba la planta del mapa pequeño, a decenas de metros del
  sitio real) ni encima de bancos, puentes, terrazas y demás piezas del «Decorado».
- Matas de hierba y flores: esquivan la plaza donde esté su pieza y las casas en su sitio real (comparaban su sitio
  del mapa pequeño con las casas del mundo ×5 y no esquivaban ninguna).
- Pincel del mapa: alcanza el suelo hasta 2,5 km de la cámara (antes 600 m; con el mapa ×5 no pintaba mirando de lejos).
- Vista desde arriba: se puede alejar más (zoom mínimo 1,4 → 1,0). Sin medir aún el rendimiento con la cámara tan lejos.
- Sol más alto a mediodía (70° en vez de 56°): sombras de las casas más cortas a esas horas; amanecer y tarde igual.
- Pasos interiores de la posada y el restaurante: el aviso de «mueble que tapa un paso» los miraba en el plano del local
  contra muebles del mundo y nunca saltaba; ahora los compara en el mundo (como el hospital y la comisaría).
- Igual con la terraza del restaurante al esconder los dibujos planos: ahora se pasa al mundo con el local movido o girado.
- Mercaderes ambulantes (Casimir y el otro): iban a las tiendas con las coordenadas del mapa pequeño (un prado vacío
  cerca del centro) y nunca compraban; ahora caminan al mostrador de cada tienda donde esté, a la plaza y salen por las entradas del valle.
- Inquisidor Real Alistair: su cama (ahora la marca de su cama en la posada), el juicio en la plaza y su salida del valle
  usaban puntos del mapa pequeño; ahora van a su sitio en el mundo ×5. Mercaderes, Inquisidor y vecinos que emigran salen
  por las mismas cruces de «Sitios» por las que se llega (entrada oeste y este), movibles en el editor.
- «Junto al agua» (lavarse, beber): la charca de la ciénaga se miraba en el mapa pequeño; ahora en el mundo, con su pieza.
- Sitios de reserva en la plaza (vecino sin puesto de trabajo, lugar del crimen por defecto, deseos sin jugador): del mapa
  pequeño al mundo ×5.
- Vista del editor: sin caminos fantasma (los viejos de la referencia ×5) cuando hay tramos en «Caminos»; solo la plaza.

## 2026-11-13 — Lavadero, corral, huertos y valla del lago recompuestos (Claude Code)
- Mismo arreglo que el cementerio con `tools/juntar_decorado.py`: lavadero (tejado otra vez sobre sus postes), corral del
  rancho, los dos huertos del sur (surcos sueltos a 30 m) y la valla con banco junto al lago. Fotos en `docs/capturas_arreglos/`.

## 2026-11-13 — Cementerio recompuesto (Claude Code)
- Las 39 piezas del cementerio en el «Decorado» del editor y sus 26 cruces de «Sitios» se habían estirado ×5 una a una
  (muros en trozos sueltos, tumbas a 8 m). Juntadas con la forma original alrededor de su centro (`E·c + (p − c)`).
- Fotos en `docs/capturas_arreglos/2026-11-13_cementerio_despues_*.png`. Quedan ~40 grupos parecidos en el decorado
  (pista en `docs/FALLOS_VISIBLES.md`, punto 5).

## 2026-11-13 — Restos planos: animales del rancho, caja y barril (Claude Code)
- Animales del corral del rancho: fuera su dibujo plano (ya tenían modelo 3D). Dibujos planos 14 → 6 (y 2 son textos
  pasajeros).
- La caja y el barril rompibles de la escena del mundo no tenían modelo 3D (su imagen no estaba en la tabla) y chocaban
  sin verse: ahora salen en 3D y su dibujo plano se apaga.

## 2026-11-13 — Vecinos que se encimaban en la puerta del restaurante (Claude Code)
- Cola en las puertas (`VillageNPCSocial._esperar_turno_en_puerta`): quien va a cruzar un umbral espera fuera si otro
  ya lo cruza en su mismo sentido.
- En el umbral, el apartarse de otro vecino ya no mete al vecino 8 px hacia dentro de golpe (`sanitize_npc_separation_pos`,
  nuevo `_cruza_muro`).
- Simulación de 3–6 vecinos entrando o saliendo a la vez: pares encimados de cientos a casi ninguno (con 6, aún algunos).
  Sin atascos nuevos (2 h de comida y de cena); verify_all en verde.

## 2026-11-13 — Detención sin atajos (Claude Code)
- Nueva `scripts/systems/EscoltaPolicial.gd`: el guardia viene andando y esposa; el preso pisa sus pasos (velocidad y
  choques de verdad, nada de colocarlo); ante la reja el guardia se aparta y el preso entra andando.
- Quitados los 6 atajos: guardia que aparecía al lado, preso pegado a su espalda, tope de tiempo, centrado en la celda,
  devolución a la celda con la reja abierta, y preso que iba solo si el guardia caía (ahora queda libre).
- Prueba nueva `tools/tests/escolta_organica.gd` (plaza → celda en 42 s, paso máximo 1,6 px, la reja retiene).

## 2026-11-12 — Corte final: adiós a la capa de anclas (Claude Code)
- Borrados `mapa/anclas.gd`, la copia `mapa/Mundo3D.antes-x5.tscn` y las herramientas de un solo uso del ×5.
- Edificios y solares guardan su sitio del mundo leído de la pieza (sin `centro·E + desplazamiento`).
- Muebles: fuera el lector de anclas. Pruebas y herramientas usan `tools/tests/mapa_viejo.gd` para sus sitios escritos
  en el mapa original. Volcado del mundo igual que antes (diferencia máxima 0,0001 px).
- El ×5 solo queda en `mapa/zona.gd` (relieve, lago, ciénaga y mapa del valle aún escritos en medidas viejas).
- Fotos fijas (`capturas_fijas.gd`) con sitios en coordenadas del mundo: antes/después del corte iguales (<0,5 %, salvo
  la capilla, donde un mueble empuja al jugador unos píxeles, y el letrero de la mascota en la plaza).

## 2026-11-12 — El juego ya no traduce nada con las anclas (Claude Code)
- Constructor de edificios: se levanta con la función de su pieza (`EdificioEditor.a_mundo`) o de su solar
  (`Solar.a_mundo`, nuevo `Solar.con_punto`/`giro`); tabiques girados con su edificio, sin anclas ni «pausa».
- Dibujos 3D en el plano de una pieza (obras de solares, Puesto del Paso, generador y cables, muebles de casa):
  `colocar_plano` con la función de su pieza en vez de `mover_posiciones`.
- Borrados los envoltorios que traducían (`sitio`, `sitios`, `_add_station_area`, `_spawn_decor_prop`,
  `_spawn_house_chest`, `_add_prop_collider`, `_add_marca_3d`, `_add_poly`, `_register_shop_business_stall`,
  `register_no_stand_furniture`, `Sitio.original`) y preloads sin uso.
- **Arreglos:** un repaso final movía otra vez ×5 lo que ya estaba en el mundo (terminales del taller y de la
  comisaría, cuadro eléctrico, armero y animales del rancho acababan fuera del mapa): borrado. Los troncos del editor
  traducían su choque dos veces. Pared invisible suelta del «Molino del Este» (sin pieza 3D) y 84 baldosas-pared del
  campamento borrado: fuera. Estacas de dos solares, sacos y foco del Puesto del Paso siguen ya a su propia pieza.
- Solo queda `Anclas.registrar_edificio` para las pruebas que aún escriben en el mapa original (`M()` de verify_all,
  `fisica_3d`, `partida_caso1`…); se pasan en el corte final.

## 2026-11-12 — Borrada la copia vieja del mundo (Claude Code)
- `scenes/World.antes-x5.tscn` tenía el mismo uid que `World.tscn` (aviso de Godot): el juego podía cargar la copia
  de antes del ×5. Sigue en el historial de git.

## 2026-11-12 — El río y sus puentes, al editor 3D; adiós al editor 2D (Claude Code)
- Los 28 puntos del río y los 6 puentes y vados están en `mapa/Mundo3D.tscn` (carpetas «Rio» y «Cruces»), con el
  ancho en metros. Al moverlos, el agua de la maqueta se rehace sola. Comprobado: río idéntico punto por punto.
- Borrados el editor 2D (`mapa/EditorMapa.tscn` y su copia, `editor_mapa.gd`, `referencia.gd`, sus herramientas) y el
  río «de fábrica» que ya no se usaba (`RIVER_WAYPOINTS`, `RIVER_CROSSINGS`, `_antiguo_*`).
- Guía del usuario al día (`docs/EDITOR_MAPA_GUIA.md`, apartado 4).

## 2026-11-12 — Mudanza al editor: plaza, lago, ciénaga, mapa del valle (Claude Code)
- Las cuentas de las zonas (plaza, lago, ciénaga) salen de su propia pieza (`mapa/zona.gd`: `estirar`,
  `estirar_puntos`, `desestirar`, `rect_mundo`), ya no del traductor (`anclas.gd` solo las lee para lo que hay encima).
- La ciénaga que enferma al jugador y a los vecinos es la de su pieza (antes, un rectángulo viejo traducido).
- Mapa del valle: dibuja los 30 edificios, solares, cementerio, plaza y agua desde las piezas del editor
  (`scripts/ui/ValleMapaPiezas.gd`); antes pintaba 15 con una lista vieja. Cementerio = lo que abarcan sus tumbas
  (`Sitio.cementerio()`), también para abrir el registro de la capilla. El molino que corta el río, por su pieza.
- Comprobado: volcado del mundo idéntico al anterior; sondeo de zonas movidas en verde.

## 2026-11-12 — Mudanza al editor: cementerio, corral y sitios de fuera como cruces (Claude Code)
- 40 cruces nuevas en «Sitios» (donde el juego ya los ponía): `tumba_1…24`, `entierro`, `plaza_espera`,
  `puesto_guardia`, `puesto_inquisidor`, `reconstruccion_inquisidor`, `rincon_plaza`, caravanas y llegadas de Casimir
  y Valeria, `forrajeo`, `pista_claro`, tres `trampilla_*` y `corral_rancho`. El código las lee con `Sitio.mundo/serie`.
- Arreglado: las tumbas de los enterrados se dibujaban en el sitio del mapa viejo; los mercaderes aparecían en un
  punto sin traducir; el hueco de paso del hospital quitaba la pared de la mesa 2 de la morgue (`PASO_INTERIOR_TAM`).


## 2026-11-12 — La escolta a la celda llega andando (Claude Code)
- Fallo del usuario: el guardia andaba un trecho y te teletransportaba a la celda. El tope fijo de 9,5 s (pueblo de
  antes del ×5) pasa a ser según la distancia (`_escort_limite_s`, `ESCOLTA_*`), y el preso va detrás del guardia según
  hacia dónde anda (pegado a un lado fijo lo atascaba al girar dentro de la comisaría).
- Sitios de la comisaría que seguían con números del mapa viejo: reja vigilada al escapar, delante de la celda
  (inquisidor), catre de la celda (detención por el comisario, cenas), pasos de hospital y comisaría que no se tapan.


## 2026-11-12 — Mudanza al editor: los vecinos nacen ya en su sitio (Claude Code)
- `setup_npc` ya no traduce: todo el que crea un vecino le da casa, mesa y trabajo en el mundo (marcas con
  `Marca.mundo`, fichas de oficio con `VillageLots.shop_house_layout_mundo`, camas de huésped con
  `VillageTavern.al_mundo`, cruces con `Sitio.mundo`). `vm._tavern_*_pos` y las camas, despacho y mesa de los nobles,
  en el mundo. Borrados `_sitios_cfg`, `sitios_traducir_npc`, `SITIOS_CAMPOS_*` y el parámetro «ya traducido».
- Volcado del pueblo idéntico antes y después. Arreglado: Alistair dormía en la cama del huésped Aldric; al cargar
  partida, maestra, jefe de La Familia, posadera y nobles recibían sitios del mapa viejo; la cena de paz en la posada
  y la vigilancia nocturna del inquisidor usaban la mesa del mapa viejo.


## 2026-11-12 — Mudanza al editor: casas de los solares, anexos, alcantarillas y mirador (Claude Code)
- Los solares saben ir solos al mundo (`Solar.a_mundo`, `Solar.giro_plano`); con eso salen ya en su sitio la mesa y el
  cofre de cada casa, el cartel de solar libre, las cajas de obra, la tienda del jugador, camas y mesa de quien se muda,
  el puesto del carpintero y del puesto del paso. Los anexos (cantera, heno, troncos) siguen a su edificio
  (`EdificioEditor.con_centro`); el terreno, a su solar. Red de alcantarillas, objetivo del golpe del perista, cofre de
  la taberna, sacos terreros y mirador del lago, también directos.
- Arreglado: tres carteles de solar libre estaban en el solar de al lado; dos cofres de tienda (granja y leñador) y dos
  rocas de la cantera estaban fuera de su terreno; la barandilla del mirador no estaba delante de su banco.


## 2026-11-12 — Mudanza al editor: celda, urgencias, mansión del Caso I y escuela (Claude Code)
- La celda (`VillageJustice.en_celda`), la cama de urgencias y la entrega de la morgue, la comisaría como zona, el
  armario y el informe del Caso I, el secuestrador, el pupitre y la maestra de la escuela y la silla de la biblioteca
  salen ya del mundo (`Marca.mundo` / `EdificioEditor.a_mundo`), sin pasar por las anclas.
- Arreglado: los muebles del Caso I en la mansión se dibujaban fuera de su sitio.


## 2026-11-12 — Mudanza al editor: casa de comidas, hospital, comisaría, capilla, molino, biblioteca, taller y ayuntamiento (Claude Code)
- Lo de dentro de estos edificios se escribe en su plano y va directo a su pieza (`EdificioEditor.a_mundo`), sin la
  capa de anclas: `Marca.mundo(id, marca, desfase)`, y en VillageManagerBase `choque_en_edificio`, `zona_en_edificio`,
  `cofre_en_edificio`, `adorno_en_edificio`, `cofre_mundo`, `adorno_mundo`; en Economy `mostrador_mundo`. Las rutas por
  dentro de todos los edificios se calculan en su plano.
- Camilla, morgue, altar y celda (`vm._hospital_bed_pos`…) ya están en el mundo; también terminales, cuadro eléctrico,
  expositor de armas, sitios de la biblioteca y del ayuntamiento, camas del albergue y de El Candil, pistas del Caso I
  dentro de la comisaría, el molino y la biblioteca.
- Arreglado: 4 macetas de la terraza tenían su pared invisible en medio del campo; en las misas los vecinos iban a
  bancos del mapa viejo; la terraza y los asientos se reconocían mal desde fuera del local.


## 2026-11-12 — Mudanza al editor: la posada sale ya en su sitio (Claude Code)
- La posada calcula sola dónde está cada cosa suya: `mapa/edificio.gd` gana `a_mundo` / `a_plano` (plano de fábrica
  del edificio ↔ mundo, con su sitio y giro del editor) y `VillageTavern` los usa con `al_mundo`, `al_plano`,
  `dentro()` y `mundo(marca)`. Barra, chimenea, fogones, toneles, póker y billar, barandillas y tabiques de arriba,
  zonas de uso, asientos, camas, escalera, rutas y alturas ya no pasan por la capa de anclas.
- Arreglado: el camarero nunca atendía a nadie (miraba las salas de fábrica con sitios del mundo) y la mesa de cartas
  sentaba a los rivales en sillas del mapa viejo. Las losas que tapan la vista se miran con `Suelo.en_losa`.
- `volcado_mundo.gd` ahora también apunta a los vecinos y dónde trabajan, duermen y comen (antes miraba un grupo
  equivocado). Volcado antes/después idéntico; `fisica_3d` y `verify_all` en verde.


## 2026-11-12 — Mudanza al editor: zonas de uso al aire libre y barandillas de los puentes (Claude Code)
- Puerta del cementerio, barro rojo del molino y pozo de la ronda son cruces de «Sitios» (`puerta_cementerio`,
  `barro_rojo_molino`, `pozo_ronda`); el claro del Caso I y el zapato del puente ya no se traducen. Borradas las 5
  últimas anclas de zonas de «Objetos» (quedan solo los 10 objetos con uso: farolas, pozos y tablón).
- Arreglado: las barandillas invisibles de los 3 puentes se traducían dos veces y estaban lejos del puente (paredes
  invisibles sueltas por el mapa, y el puente sin pretil). Ahora están a los lados de cada puente.

## 2026-11-12 — Mudanza al editor: 17 anclas de letreros viejos borradas (Claude Code)
- Las anclas de «Objetos» de los letreros flotantes que ya no existen (cementerio, puente, claro, molino, solares
  libres, campos, mirador, lavadero), las de 4 vetas de hierro y una cama suelta no movían nada: borradas.
  Comprobado: 1.659 cosas del pueblo idénticas; el 3D no las usaba.

## 2026-11-12 — Compostador del campamento borrado (Claude Code)
- Era del huerto del campamento (borrado por el usuario): ya estaba apagado pero dejaba una pared invisible en el sitio
  del campamento. Borrados el compostador, su [E], su dibujo 3D y su ancla del editor. El abono sigue en recetas y oficios.

## 2026-11-12 — Mudanza al editor: pozos, tablón y farolas leen su pieza (Claude Code)
- Los 3 pozos, el tablón de encargos y las 6 farolas de la plaza toman su sitio (y giro) directamente de su pieza de
  «Objetos», ya en el mundo; sin traducir. Borrada la herramienta vieja que creaba esas piezas.
- Arreglado: el choque de las 47 farolas de las calles no caía bajo la farola (se traducía dos veces); ahora sí.
- Arreglado: la pieza del tablón estaba a 2 m de su dibujo; puesta encima. Los vecinos que charlan junto a los pozos y
  el tablón se ponen a su lado (antes, a unos 6 m).

## 2026-11-12 — Mudanza al editor: postes indicadores (Claude Code)
- Los 6 postes de los caminos son cruces «poste_N» de «Sitios» (se mueven y se giran en el editor); su texto sigue
  en el código, en el mismo orden. Borradas sus 12 anclas viejas de «Objetos». Comprobado: 1.662 cosas, idénticas.

## 2026-11-12 — Mudanza al editor: anclas viejas del bosque borradas (Claude Code)
- 89 «anclas» de «Objetos» (setas, hierbas, madrigueras, guaridas, claros, hozaderos y letreros del bosque) ya no
  mandaban nada desde que el bosque sale de «Sitios»: borradas. Comprobado: 1.662 cosas del pueblo, idénticas.

## 2026-11-12 — Mudanza al editor: árboles de adorno (Claude Code, paso 4 del plan del mundo)
- Los árboles del parque y del cementerio eran marcas del código con una bolita en el editor; ahora son 8 piezas de
  «Decorado» (`Arbol_adorno_N`) con su modelo y su choque: se ven y se mueven en el editor. Los 3 que el juego escondía
  (pisaban otro árbol) ya no dejan una pared invisible. Borradas sus 11 anclas de «Objetos». Fotos antes/después iguales.

## 2026-11-12 — Mudanza al editor: el decorado trae su choque (Claude Code, paso 4 del plan del mundo)
- 41 piezas de «Decorado» llevan su pared invisible en sus datos (`choque`, y si hace falta `choque_giro` y
  `choque_desplaz`): 4 bancos del parque y la plaza, la verja del cementerio (5 tramos), sus 24 tumbas y los 8 troncos
  del claro del Caso I. Borrados esos números del código. Comprobado: los 406 choques del pueblo, idénticos.

## 2026-11-12 — Mudanza al editor: los muebles traen su choque (Claude Code, paso 4 del plan del mundo)
- 69 muebles de 23 edificios (taberna, restaurante, capilla, comisaría, biblioteca, ayuntamiento, tiendas y casas) llevan
  su pared invisible en la pieza (campo «Choque»): si el usuario mueve o gira el mueble, el choque va con él. Borrados
  esos números del código. Comprobado: los mismos 406 choques en el pueblo (alguno 2–4 px más centrado en su mueble).
- Arreglado: los sitios donde un vecino no puede quedarse de pie (encima de mesas, altares, mostradores) se apuntaban en
  el mapa sin estirar y no servían; ahora se apuntan donde está el mueble.

## 2026-11-12 — Mudanza al editor: el bosque (Claude Code, paso 4 del plan del mundo)
- Madrigueras, guaridas, claros, hozaderos, hierbas, setas, carteles y el borde del bosque salen de 90 cruces del mapa
  («Sitios»), ya colocadas en el mundo; borrados sus números del código y las listas viejas de árboles y vetas (ya salían
  de la escena). Mismo resultado comprobado: 20 hierbas, 21 setas, 5 carteles, 1.042 objetos destruibles.
- Quitado del mapa del valle el letrero «Campamento y Huerto» (sistemas borrados).

## 2026-11-12 — Farolas que alumbran de verdad (Claude Code, pedido del usuario)
- 47 farolas nuevas por las calles del pueblo y alrededor de la plaza (antes 6 para todo el mapa ×5). Son cruces del
  editor (`farola_calle_N` en «Sitios»): se mueven con el ratón y la farola va con ellas.
- El farol brilla y un foco hacia abajo deja un charco de luz en el suelo; las luces lejanas se apagan solas por el
  rendimiento (unas 30 imágenes por segundo con farolas, 32 sin ellas).
- Después, a petición del usuario: farolas un 20 % más altas y con un 50 % más de luz (charco más ancho).

## 2026-11-12 — La red eléctrica la mueve el generador del Arreglador (Claude Code, decisión del usuario)
- Antes la corriente del pueblo salía del generador de tu campamento (borrado) y el pueblo se quedó sin ella. Ahora la
  da el generador diésel del Taller del Arreglador: hay corriente desde el principio y sabotearlo deja el pueblo a oscuras.
- Fuera la bomba de riego del cuadro (era del huerto borrado) y la luz amarilla «sin corriente» de las farolas.
- Arreglado: con corriente, las farolas seguían encendidas de día; ahora solo de noche.

## 2026-11-12 — Borrados también los animales de corral del jugador y el huerto de casa (Claude Code, usuario)
- Fuera comprar crías, darles de comer, esquilar, recoger huevos, trasladar el corral al solar y el huerto de tu casa.
  Las carreras y peleas de animales siguen, con la misma suerte para todos (antes tus animales daban ventaja).
- El ganado del Rancho del Sur sigue igual. La cataplasma de casa necesita hierbas compradas o recogidas.

## 2026-11-12 — Borrados pesca, huerto, gallinero y campamento (Claude Code, decisión del usuario)
- Estaban pensados para el mapa plano (letreros flotantes, barra de pesca dibujada en el mapa) y en primera persona no se
  veían. Se rehacen de cero en 3D después del Caso I. Fuera también la caña, la regadera, las semillas iniciales y la
  tecla R de semillas; la rueda de herramientas pasa a 6. Zorros y herbívoros ya no asaltan granja ni gallinero.
- La forma del río y del lago sale a `scripts/fisica/RioLago.gd` (antes dentro de la pesca); el lago sigue chocando.
- Quedan: lago, río, muelle, animales de corral del jugador y peces/verduras/semillas como mercancía del pueblo.
- Probado: partida arrancada sin errores con foto del muelle; verify_all adaptado (quitadas sus comprobaciones).

## 2026-11-12 — Madrigueras, guaridas y lago de pesca sin dibujo plano (Claude Code)
- Madrigueras de conejo y guaridas de zorro son marcas invisibles con `tipo_3d`; el lago, la arena, el muelle y las
  ondas planos de la pesca, borrados (el 3D del lago sale del terreno). Quedan la boya, el sedal y el aviso del minijuego.
- Sprites 30 → 16; dibujos planos 64 → 44. Fotos: madriguera, guarida, lago con muelle; verify_all.

## 2026-11-12 — Huerto, gallinero y campamento sin dibujo plano (Claude Code)
- Parcelas, comedero, nido y piezas del campamento son marcas invisibles con `tipo_3d` y, si cambian de aspecto,
  `variante_3d` (tierra seca/mojada, brote/crece/madura, comedero vacío/medio/lleno, nido con huevos). El 3D ya no
  lee nombres de dibujos. Fuera suelo, muros, cama y cofre planos de la casa del jugador (su 3D sale del nivel).
- Sprites 57 → 30. Fotos: zanahoria madura en tierra mojada, gallinero con huevos, campamento completo; verify_all.

## 2026-11-12 — Objetos quietos sin dibujo plano: marcas invisibles (Claude Code)
- Nuevo `_add_marca_3d(tipo, pos)` en `VillageManagerBase` (sustituye a `_add_sprite_prop`): un `Node2D` con
  `tipo_3d` (+ choque por tipo) que el 3D convierte en pozo, poste con texto, compostera, pino de adorno o roca.
- Puestos, mostradores, tablón, farolas y camillas: solo su choque (su 3D ya salía de otros datos). Farolas guardan
  su sitio del mundo en `streetlights[i]["pos"]`. Fuera tintes y texturas planas de puestos y cadáveres.
- Sprites 134 → 57; lista visible igual. Fotos de poste, pozo, pino del parque, farola y roca; verify_all.

## 2026-11-12 — Fuera el dibujo plano de puertas, ventanas y cofres (Claude Code)
- Las puertas, postigos y cofres 3D ya leían su estado de los datos (abierta, cerrada con llave, postigo, saqueado);
  se borran sus 141 dibujos planos y el código que les cambiaba la imagen. Sprites 275 → 134; lista visible igual.
- Fotos de puerta cerrada/abierta y ventana con postigo; verify_all.

## 2026-11-12 — Fuera el dibujo plano de árboles, rocas y plantas que se recogen (Claude Code)
- `HarvestableNode` ya no crea su `Sprite2D` (~1.050 dibujos ocultos): el 3D sale del propio nodo, su tipo y si está
  agotado. `setup_visuals(...)` pasa a `setup_collision(radio)`; fuera texturas, temblor y encogido planos (no se veían).
- Dibujos planos 1.367 → 309 (sprites 1.330 → 275); lista visible sin cambios. Fotos de pino, veta y hierba; verify_all.

## 2026-11-12 — Sangre, huellas y campamentos de vagabundos en 3D (Claude Code)
- Solo existían en el plano y en primera persona no se veían. Nuevo `scripts/visuals/Rastros3D.gd` (lo llama
  `_sync_dynamic_props_3d`): charco irregular de sangre oscura, huellas que se aclaran al alejarse y campamento
  (lona, petate y hoguera); se rehace solo cuando cambian los datos.
- Las huellas ya son datos (`blood_puddles[i]["footprints"]`: pos, ángulo, alfa) en vez de polígonos; fuera el
  dibujo plano del charco, de las huellas y del campamento. Visto en foto; verify_all.

## 2026-11-12 — Capa 2, tanda 2: fuera los polígonos planos (Claude Code)
- El 3D no leía ningún polígono plano (solo los escondía): borrados umbrales de puertas, escritorio, urna, biblioteca,
  sala oculta, pupitres, pizarra, mercado (`_draw_market`), parque, mirador, campos/corral/cantera, camas de mascota,
  brillo de farolas (`_update_streetlights_glow`), suelo del bosque, alcantarillas y club (suelos y paredes pintadas;
  sus choques siguen) y los dibujos apagados de las piezas con [E] (`WorldInteractableProp`, 17 `_draw_*_2d`).
- Inventario: 1.629 → 1.367 dibujos planos; polígonos 268 → 9 (pesca y gallinero). Lista visible: 0.
- Sin 3D todavía (no se borran; hay que hacerles versión 3D): charcos de sangre y huellas, campamento de vagabundos.

## 2026-11-12 — Capa 2, tanda 1: fuera los letreros planos (Claude Code)
- Borrados ~1.190 letreros planos que nunca se veían en primera persona: el de cada árbol, roca y planta
  (`HarvestableNode.prompt_label`), los de puertas, ventanas, cofres, mostradores, pozos, posada, hospital, morgue,
  celda, altar, cementerio, tablón y compostador (`_make_station_label` y sus 13 variables), y las lápidas planas
  (`_spawn_physical_grave_marker`; las tumbas 3D salen de `buried_graves`). El aviso de [E] lo da la interfaz 3D.
- Inventario de dibujos planos (herramienta temporal): 2.818 → 1.629; quedan 21 letreros (huertos, campamento,
  gallinero, pesca), 268 polígonos, 10 líneas y 1.330 dibujos (casi todos, plano del 3D). Lista visible: 0. verify_all.

## 2026-11-12 — Capa 1 del adiós al 2D: nada plano a la vista desde arriba (Claude Code)
- Decisión del usuario: quitar todo lo plano que se ve o se edita (capas 1 y 2); el «cerebro» plano de los vecinos se queda.
- Los muebles y adornos de código (`_spawn_decor_prop`, 43 llamadas) ya no se dibujan: solo dejan su choque; su 3D está
  en las escenas de los edificios o en piezas. Borradas las flores del parque y la gallina del huerto (no hacían nada más).
- Borradas las camas planas (casas, solares, botica, albergue, posada de solar, mansiones, hospital, comisaría, capilla,
  piso alto de la taberna), las rejas planas de la celda, el lavadero plano y todo el dibujo plano del Puesto del Paso
  (`sync_outpost_visuals` solo rehace el 3D).
- Las rocas de la cantera, que no existían en 3D, son rocas 3D (marca `tipo_3d` en el dibujo, `WorldStageProps3D`).
- Comprobado: lista de lo visible desde arriba 21 → 0; fotos en 1.ª persona y desde arriba de terraza, puesto,
  lavadero, comisaría, solar y cantera (el 3D igual); verify_all en verde a la segunda (la primera falló al azar
  el solape de dos vecinos en la terraza; apuntado en el estado).

## 2026-11-12 — Los textos de los caminos, pintados en sus postes (Claude Code)
- Los 6 postes de los caminos y los 5 avisos del bosque llevan su texto pintado en la tabla (letras claras por las dos
  caras; `Cartel.letras`/`escribir`, meta `texto_cartel`, `_escribir_poste` en `WorldStageProps3D`). Los avisos del
  bosque ya son postes de verdad (antes, palos y letrero planos solo visibles desde arriba).
- Borrados los nombres flotantes de la pesca («Lago del Oeste», «Ribera de Pesca del Río»); quedan las instrucciones
  del minijuego de pesca, que siguen siendo texto plano (pendiente de revisar).
- Comprobado: fotos de los 11 postes en primera persona; lista de lo visible desde arriba (38 → 21, solo se van los
  textos de pesca y los postes planos del bosque); verify_all.

## 2026-11-12 — Fuera los nombres flotantes sobre el mapa (Claude Code)
- Decisión del usuario: nada de texto flotante; el nombre va en el cartel de la puerta y lo demás lo cuenta el mundo.
  Borrados los 63 títulos (edificios, «Solar libre», parque, mirador, lavadero, urna, mercado, puesto del paso,
  campamento de vagabundos, «Leer un rato», escuela, obras) con `_add_title_label`, `_declutter_title_labels`,
  `_title_text_rect`, `TITLE_SHOW_RADIUS` y el color de título de `_construct_solid_building` (15 llamadas).
- Obras y escuela sin texto: los andamios crecen con la obra y los alumnos se sientan en los pupitres con el maestro.
  `verify_all`: fuera la comprobación del letrero de la escuela.
- Comprobado: 0 títulos en partida; lo visible desde arriba, igual; `verify_all`.

## 2026-11-12 — Carteles de madera con el nombre junto a la puerta de cada edificio (Claude Code)
- Pedido del usuario: el nombre del edificio en un cartel de madera al lado de la puerta, no flotando. Pieza nueva
  `mapa/cartel.gd` («Cartel» en las 32 escenas de `mapa/edificios/`, incluidas las tres casas modelo): tabla clara con
  el título del edificio que pone el juego (`WorldStageBuildings3D`). Se mueve en el editor; «Ancho m» editable.
- Colocados una vez con `tools/poner_carteles.gd`: lado sin ventana, apartado de los postes del porche; en paredes
  cortas más estrecho (11 de 1,2 m); en la casita, encima de la puerta. `edificio.gd` usa `Cartel.sin_emojis`.
- Comprobado: fotos en 1.ª persona de 9 edificios y una casa de solar; `verify_all`.

## 2026-11-12 — Los letreros de los sitios vuelven a salir en la vista desde arriba (Claude Code)
- La distancia a la que se enseña el letrero de un sitio (`TITLE_SHOW_RADIUS`) se quedó en la medida de antes del mapa
  ×5: solo salían con el protagonista pegado (~1,5 m). Ahora es ×E (~8 m). Medido: a 5 m salen 57 de 63 (antes 0).
- Visto en fotos: «Solar libre» se lee. Los de edificios quedan encima del tejado, en el lado contrario a la puerta:
  con el protagonista en la puerta caen bajo el reloj de arriba (pendiente de decidir con el usuario).
- `PRUEBAS.md`: el arranque rápido solo carga el menú y no ve errores de los scripts del pueblo (pasó aquí con un
  `Mapa3D` repetido en `VillageManagerSocial`). Comprobado: `verify_all`.

## 2026-11-12 — Paso 4, trozo 5: fuera el suelo plano de calles y solares (Claude Code)
- `VillageLots` ya no dibuja en plano las calles hacia los solares, las callejas curvas ni el suelo de solar libre o en
  obra (84 polígonos por debajo de la imagen 3D). Borrados `_road`, `_rect_pts` y el huerto (ya no estaba en la lista).
  Los letreros de solar se quedan: hoy no salen nunca (como los 63 de título); pendiente de mirarlo con el usuario.
- Comprobado: escena 3D idéntica; lo visible desde arriba, igual; fotos desde arriba de calle norte, calleja, pozo de
  la ronda, Molino del Este y enlace; `verify_all`.

## 2026-11-12 — Paso 4, trozo 4: fuera el dibujo plano de la casa de comidas (Claude Code)
- `VillageRestaurant` ya no dibuja en plano suelos de sala, manteles, hielo y carne de la cámara, losas, sendero y
  sillas de la terraza (37 polígonos ocultos). Borradas `_build_room_floors` y `PATH_RECT`. Muebles que pasan a 3D, igual.
- Comprobado: escena 3D idéntica; lo visible desde arriba, igual; fotos desde arriba de comedor, cocina y terraza
  (solo cambian los vecinos que pasan); `verify_all`.

## 2026-11-12 — Paso 4, trozo 3: fuera los muebles planos de la posada (Claude Code)
- `VillageTavern` ya no dibuja en plano la barra, chimenea, fogones, toneles, mesas, sillas, póker, billar, alfombra
  y escalera (44 polígonos que el juego ocultaba siempre). Se quedan choques, zonas, sprites y letreros.
- Corrección: el mapa plano SÍ se ve en la vista desde arriba (P) si está visible, opaco y por encima de la imagen 3D.
  Hoy cumplen eso 38 cosas (letreros de pesca y del bosque, sus postes, estacas del Puesto del Paso…). Los letreros
  de título los apaga el juego (0 de 63 visibles). Fotos desde arriba del trozo 2 revisadas: sin cambios.
- Comprobado: escena 3D idéntica; solo faltan 44 polígonos; lo visible desde arriba, igual; fotos fijas; `verify_all`.

## 2026-11-12 — Paso 4, trozo 2: fuera el dibujo plano invisible del constructor del pueblo (Claude Code)
- `VillageWorldBuilder` ya no dibuja el mapa 2D antiguo (la imagen 3D lo tapa y ni se pinta): caminos, plaza, llanura, ciénaga, sendero, orillas, barro y agua del río, puentes y vados, alfombras, bancos y altar de la capilla, cementerio (suelo, caminos, verja y 24 tumbas), rueda e interior del molino, y los letreros planos de postes, cementerio, Puente Viejo y claro. Borradas `_add_road_rect` y `_add_cobble_rect`.
- Se quedan los choques, las zonas de interacción, el agua para la física, los dibujos que pasan a 3D (postes, camas, mostradores) y los letreros que el juego actualiza. El texto de cada poste queda como comentario: hoy el poste 3D no lo muestra.
- Comprobado: escena 3D fija idéntica; en el mapa plano solo faltan 361 polígonos, 9 letreros, 2 rayas y 5 suelos (choques, zonas y dibujos, iguales); `verify_all`.

## 2026-11-12 — Paso 4, trozo 1: el código deja de dibujar el decorado del terreno (Claude Code)
- `WorldStageTerrain3D` ya solo dibuja suelo, caminos, plaza empedrada y agua (lago, ciénaga y río con sus orillas). Borrado el dibujo de bancos, tablón de encargos, campos, corral, parque, lavadero, cementerio, sauces, matorral y troncos del bosque, trampillas de alcantarilla, muelle, sendero, piedras y juncos del río, bosque del arroyo, Puente Viejo, puentes y vados, molino del este y leñeros (~690 líneas): todo eso es pieza de «Decorado» en el editor y el código lo creaba y lo tiraba en cada arranque.
- Borrados `tools/hornear_decorado.gd` (de un solo uso y roto en el portátil), el modo `grabar_decorado` y las funciones `_build_barrios_3d`, `_build_tree_3d`, `_build_bench_3d`. Se queda el choque de los troncos del claro del Caso I (`CLARO_TRONCOS`).
- La madera de los adornos (`prop_wood`, `prop_dark_wood`) toma los mismos valores que antes le llegaban del terreno.
- Comprobado: escena 3D de terreno, decorado y vegetación idéntica antes y después (6.807 piezas), volcado de la lógica idéntico, fotos fijas iguales (mirado el lago a ojo), física y `verify_all`.

## 2026-11-12 — Marcas en los solares: Puesto del Paso; cuadro y generador del taller (Claude Code)
- Las piezas de «Solares» admiten un grupo «Marcas» (cruces de `mapa/marca.gd`) que van con el solar: `Solar.marca(id_solar, marca)`, en el mapa original como las de los edificios.
- Puesto del Paso: marcas `centro`, `puerta`, `trabajo_1…3`; borrados `OUTPOST_CENTER`, `OUTPOST_GATE_POS`, `OUTPOST_WORK_SPOTS` (ahora `outpost_center()`, `outpost_gate_pos()`, `outpost_work_spot(i)`).
- Taller de Reparaciones: marcas `cuadro_electrico` y `generador` en su escena; borrados `TINKER_GRID_PANEL_POS` y `TINKER_GENERATOR_POS`.
- Comprobado: volcado idéntico, inventario con todo movido, sondeos, `verify_all`.

## 2026-11-12 — Los solares salen de sus piezas del editor (Claude Code)
- Cada pieza de «Solares» guarda ahora su zona, barrio, tamaño de casa, lado de la puerta y cuánto se aparta el edificio (`mapa/solar.gd`, `Solar.lista()`). El juego lee de ahí la lista de solares.
- Borrados `VillageLots.LOTS` (40 solares escritos a mano) y `lot_shift` (los desplazamientos calculados: cada pieza ya estaba en su sitio). Una herramienta temporal comprobó que los 40 coincidían exactamente.
- Aún no se crean solares duplicando una pieza (la copia comparte «centro original»): será en el paso 4.
- Comprobado: volcado idéntico, sondeos, física, inventario con todo movido (quietas 91 → 75, doble 0), `verify_all`.

## 2026-11-12 — Paso 3: 17 cruces de «Sitios» recolocadas (Claude Code)
- `paseo_12…18`, `espera_11…14`, `espera_16`, `espera_17`, `jornal_quarry_1`, `jornal_woodcutter_1`, `_2` y `callejon_perista` se habían medido sin la partida arrancada; las casas de solar que se colocan al arrancar las movían, y antes el juego mandaba a los vecinos a ese sitio movido. Ahora la cruz está donde iban de verdad.
- Revisadas las 86 cruces con la partida arrancada: el resto cuadra. Comprobado: sondeos, `atascos_vecinos`, `verify_all`.

## 2026-11-12 — Paso 3, grupo 5: mascotas, claro del Caso I y reservas (Claude Code)
- Cruces nuevas en «Sitios»: `mascota_toby`, `_sultan`, `_canela`, `_michi`, `_pelusa`, `_sombra`, `claro_caso1`, `cuerpo_caso1`. Borrados los `pos` de las mascotas, `FishingSpot.CASE1_CLEARING_POS` y el número del cuerpo.
- Reservas con número fuera: quien busca a la policía sin policía a mano va al escritorio de la comisaría (marca); quien visita una tumba sin pueblo se queda donde está.
- **Fallos arreglados:** esas dos reservas y el aviso del cuadro eléctrico sin jugador usaban números del mapa viejo como si fueran del mundo.
- Lección: las cruces deben medirse con la partida arrancada (la carpintería y la posada se colocan al arrancar); dos camas de mascota se corrigieron por eso.
- Comprobado: volcado de sitios idéntico, sondeos, física, `partida_caso1` (25 ✅), `verify_all`.

## 2026-11-12 — Paso 3, grupo 4: sitios dentro de edificios a marcas (Claude Code)
- Marcas nuevas: comisaría `celda_puerta` y `celda_salida`; ayuntamiento `libro_gremial`; casa de comidas `terraza` y `comedor`; biblioteca `silla_lectura_1…6`. La taberna usa sus marcas `poker` y `mesa_central`, la mansión su `despacho`.
- Borrados `CELL_RECT`, `CELL_GATE_POS`, `CELL_OUTSIDE_POS` (el calabozo es un rectángulo alrededor de la marca «celda»), los `pos` de `HEIST_TARGETS`, los de taberna y comedor en `VillagePlaces` y las sillas de la biblioteca.
- **Fallo arreglado:** los testigos que vigilan si fuerzas el calabozo miraban a la reja en el mapa viejo, y el ruido sonaba allí.
- Comprobado: volcado de sitios idéntico, sondeos de edificios y zonas, `verify_all`.

## 2026-11-12 — Paso 3, grupo 3: 22 cruces más en «Sitios» (ocio, mercado, lavadero, caravana…) (Claude Code)
- Cruces nuevas: `ocio_park_lawn`, `ocio_park_bench`, `ocio_plaza_benches`, `ocio_lake_view`, `ronda_noche_1…6`, `mercado_1…4`, `lavadero`, `caravana_plaza`, `puerta_este`, `caballo`, `botin_plaza`, `callejon_perista`, `entrada_oeste`, `entrada_este`. La biblioteca usa su marca `lectura`.
- Borrados `pos` de `VillagePlaces.PLACES` (salvo taberna y comedor, que van con su edificio), `NIGHT_STROLL_SPOTS`, `LAVADERO_POS`, `CARAVAN_PLAZA_POS`, `RAID_GATE_POS`, `HORSE_DEFAULT_POS`, `MARKET_SPOTS`, `Raider.LOOT_POS`, `FENCE_ALLEY_POS` y los números de las entradas y de los forasteros de la taberna.
- **Fallos arreglados:** los asaltantes iban a saquear la plaza en su sitio del mapa viejo; quien llegaba andando de fuera aparecía en el borde del mapa viejo; el caballo sin dueño también; los bancos del parque, de la plaza y el mirador del lago se dibujaban traducidos dos veces (lejísimos).
- Comprobado: volcado de sitios idéntico salvo esos tres dibujos (ahora en su sitio), sondeos de edificios y zonas, física, `verify_all`, `atascos_vecinos`.

## 2026-11-12 — Paso 3, grupo 2: carpeta «Sitios» con 56 cruces al aire libre (Claude Code)
- Carpeta nueva «Sitios» en `mapa/Mundo3D.tscn` (`mapa/sitio.gd`): cruces con nombre cuya posición es **ya la del mundo** (`Sitio.mundo(id)`, `Sitio.serie("paseo")`; nadie las traduce). 56: `paseo_1…18`, `espera_1…18`, `expedicion_<oficio>` (5), `jornal_<oficio>_<n>` (10), `asalto_entrada`, `carro`, `mirador`, `contrabando_campamento`, `contrabando_frontera`.
- Borrados `IDLE_STROLL_SPOTS`, `TAVERN_DAY_SPOTS`, `EXPEDITION_TARGETS`, los `spots` de `VillageWork.PLACES` (ahora `VillageWork.spots(key)`), `SPAWN_POS`, `CART_DEFAULT_POS`, `MIRADOR_POS`, `SMUGGLER_CAMP_POS` y `SMUGGLER_BORDER_POS`.
- **Dos fallos arreglados:** los artesanos salían por la mañana (a pescar, talar, cazar…) hacia posiciones del mapa sin estirar, y los recién llegados sin casa se colocaban el primer día también en posiciones sin estirar. Ahora van a su cruz.
- `Sitio.original(id)` queda para quien crea vecinos con funciones que aún traducen (contrabandista, recién llegados); se irá en el paso 4.
- Comprobado: volcado idéntico, `verify_all`, `atascos_vecinos` (4 h desde las 6).

## 2026-11-12 — Paso 3 empezado: Caso I y medición de los sitios del código (Claude Code)
- Caso I: los dos forasteros del molino y la bandeja de informes de la comisaría son cruces de sus edificios (`secuestrador_young`, `secuestrador_driver`, `informe`; 282 marcas). Fuera `REPORT_POS` y las posiciones de `MILL_KIDNAPPERS`; `VillageCase1.report_pos()`.
- Medición: `tools/tests/inventario_constantes.gd` anota a dónde lleva la traducción cada punto escrito en las constantes de `scripts/systems`, `enemies` y `obstacles`. De 325 puntos, 264 siguen a la pieza que tienen cerca y 61 a ninguna: bosque (`FOREST_POLY`, 24), río (`RIVER_*`, 17, sin uso con el río del editor) y unos 17 sitios de vecinos (`TAVERN_DAY_SPOTS`, `EXPEDITION_TARGETS`, `IDLE_STROLL_SPOTS`, `VillageWork.PLACES`, `MIRADOR_POS`, contrabandistas, carro, asalto). No mide los números escritos dentro de funciones.
- Comprobado: `partida_caso1.gd` completa (25 ✅).

## 2026-11-11 — Paso 2 cerrado: plaza, lago y ciénaga son piezas del editor (Claude Code)
- Carpeta nueva «Zonas» en `mapa/Mundo3D.tscn` con tres piezas (`mapa/zona.gd`): `zona_plaza`, `zona_lago`, `zona_cienaga`. Al mover una, van con ella su suelo o agua, la hondonada del terreno, el muelle, dónde se nada y se pesca, las ranas de la ciénaga y su dibujo en el mapa del valle. No giran ni cambian de forma.
- `mapa/anclas.gd`: zonas de terreno (`estirar`, `estirar_puntos`, `desestirar`), con la prioridad más baja; el terreno hecho por código y el relieve (`terrain_height_px`) pasan por ellas en vez de multiplicar por 5 a mano. En el sitio viejo de una zona movida el relieve queda llano.
- Prueba nueva `tools/tests/sondeo_zonas.gd` (sin ventana, segundos): mueve las tres zonas y comprueba agua, hondonada y muelle. Foto fija nueva `lago`.
- Comprobado: sin mover nada todo queda idéntico (volcado y fotos); con todo movido, las 6 mallas de plaza, lago y ciénaga siguen al editor. Inventario: sigue 5.181, quieto 30 (río y luces, que la medición no mueve), doble 0.

## 2026-11-11 — Paso 2: suelo y agua medidos de verdad (Claude Code)
- `tools/tests/inventario_mundo.gd` mide las mallas de suelo por el centro de lo que dibujan (su nodo está en el origen). De 42 piezas de `Terrain3D`, 29 siguen al editor (calles de «Caminos»); 4 son el río (sale del editor, la medición no lo mueve); quedan **6 zonas hechas con números del código**: plaza, lago (2), ciénaga y dos junto al claro del norte.
- Inventario: sigue 5.181, quieto 34, doble 0, otro sitio 118. Sin cambios en el juego.

## 2026-11-11 — Paso 2, tanda 4: las «434 plantas quietas» eran un error de medición (Claude Code)
- Los 434 «lotes» de `Nature3D` son paquetes de dibujo (un nodo fijo que junta muchas copias de un árbol o roca): el inventario miraba el paquete, no las copias. `tools/tests/inventario_mundo.gd` anota ahora cada copia. Resultado: de 1.102 árboles y rocas, 1.063 siguen al editor, 14 son copias ocultas y 25 varían entre partidas. **No hubo que tocar el juego.**
- Inventario real: sigue 5.147, quieto 66 (42 de suelo y agua, 14 copias ocultas, luces del cielo, muro débil y espada de `scenes/World.tscn`), doble 0, otro sitio 120. La zona del zapato del Puente Viejo sale «quieta» porque sigue al río del editor y la medición no mueve el río.

## 2026-11-11 — Paso 2, tanda 3: los mostradores de las tiendas (Claude Code)
- **Fallo arreglado:** la zona de uso y el letrero «gestionar negocio» de los 15 mostradores se traducían dos veces y acababan a kilómetros del mostrador. `_register_shop_business_stall` recibe ahora el sitio en el mapa original (la marca `puesto`) y guarda en la ficha el sitio real; sus cinco llamadas pasan la marca.
- Sin hacer: el muro débil y la espada sueltos no son del código del mundo, están puestos a mano en `scenes/World.tscn`; se tratarán con el resto de esa escena.
- Comprobado: sitios de vecinos idénticos; inventario sigue 4.068 → 4.087, otro sitio 111 → 92 (los 15 mostradores siguen al editor); `verify_all`.

## 2026-11-11 — Paso 2, tanda 2: el Puesto del Paso es una pieza y los letreros van con su solar (Claude Code)
- Lo que el inventario llamaba «farolas y cables quietos» era el **Puesto del Paso** (dos barreras de sacos, un foco y el propio puesto): no tenía pieza. Pieza nueva `solar_puesto_del_paso` en «Solares» (41 piezas); camino, estacas, empalizada, sacos, foco, sitios de trabajo y letrero van con ella. `rebuild_outpost_3d` se escribe en el mapa original y sigue a la pieza.
- **Fallo visible arreglado:** el dibujo 3D del puesto salía en medio del pueblo (en coordenadas sin estirar) y su lógica en la frontera, cinco veces más grande. Ahora dibujo y lógica coinciden en la frontera este, a su tamaño.
- Fuera de «Objetos» 46 anclas (45 letreros de solar vacío y la del puesto): el ancla de cada solar cubre una franja de 16 px al norte y al sur (`SOLAR_LETRERO_PX`), así el letrero «solar libre» va con su solar. Cambio visible: esos letreros quedan pegados a su solar (antes, a unos 13 m).
- Comprobado: sitios de vecinos idénticos; inventario sigue 4.006 → 4.068, quieto 553 → 486; sondeo 29 de 29; fotos (sitio nuevo `puesto_paso`); `verify_all`.

## 2026-11-11 — Paso 2, tanda 1: los solares son piezas del editor (Claude Code)
- Carpeta nueva «Solares» en `mapa/Mundo3D.tscn` con 40 piezas (`mapa/solar.gd`). Lo que el juego crea en el terreno de un solar (estacas, obra, letrero, campos, la casa que se construya) va con su pieza; los edificios y objetos con pieza propia mandan sobre el solar.
- Las 9 piezas de casa de recién llegados de «Edificios» se quitan: una casa de solar no tiene pieza, hereda sitio y giro de su solar (también las que se construyen jugando). Fuera `giro_de_fabrica` de `mapa/edificio.gd`.
- Cambio visible: las estacas de un solar vacío marcan ahora el terreno a su tamaño real (antes, cinco veces más separadas).
- Comprobado: sitios idénticos (solo se recolocan dos letreros de solar vacío); en la medición con todo movido las 10 casas de solar y 52 de 56 piezas de solar siguen al editor (lo que no, es una casa que solo se construyó en una de las dos partidas). Inventario: quieto 609 → 553. Sondeo 29/29; `verify_all.gd` en verde.

## 2026-11-11 — Las paredes de dentro de los edificios salen del editor (Claude Code)
- Pieza nueva `mapa/tabique.gd` (grupo «Tabiques» de cada escena, caja roja translúcida en el editor, con tamaño y «tapa vista»): 39 tabiques en 13 edificios (taberna 7, casa de comidas 9, comisaría 3 rejas, hospital 2, botica 2 y 2 en cada tienda de solar y la posada). `_construct_solid_building` los crea al levantar el edificio.
- Borrados sus números: tabiques de taberna, casa de comidas, hospital, botica y rejas de la celda; las marcas `tabique_1|2` del trozo anterior pasan a ser piezas.
- Comprobado: los 9.377 objetos y todos los muros (sitio, tamaño, grupos y capa) idénticos; sondeo 29/29; `partida_caso1.gd` 25/25; `verify_all.gd` en verde. Total: 279 marcas y 39 tabiques en 32 escenas.

## 2026-11-11 — Planta, puerta y ventana de cada edificio salen del editor (Claude Code)
- Cada escena de edificio (32) guarda su planta («Planta m»), el ancho de la puerta y dos marcas nuevas, `puerta` y `ventana`. `mapa/planta.gd` lo lee y `_construct_solid_building` ya no recibe tamaño, lado, ancho ni desvío de puerta: borrados de sus 15 llamadas (y los restos `shop_door_south`, `DOOR_W`, `DOOR_X`).
- La ventana que usa el juego sale de su marca y gira con el edificio (antes se calculaba «a la izquierda de la puerta» y al girar no coincidía con la dibujada).
- Comprobado: plantas, puertas, ventanas, sitios y cosas idénticos antes y después; sondeo 29/29; `partida_caso1.gd` 25/25; `verify_all.gd` en verde. Total: 295 marcas en 32 escenas.

## 2026-11-11 — Casas modelo, trozo 3: ya no se dibuja ningún edificio por código (Claude Code)
- Las tiendas con vivienda de los solares y la posada leen también sus dos tabiques de marcas (`tabique_1`, `tabique_2`; 16 marcas nuevas en 8 escenas). Borrado el molde de números de `VillageLots`. No hizo falta una «tienda modelo»: el juego nunca levanta una tienda que no tenga ya su escena.
- Borrado todo el dibujo de edificios por código de `WorldStageBuildings3D` (muros, puerta, ventana, tejado, interior genérico, estilos; de 531 a 266 líneas), sus interruptores en `WorldStageBase3D`, los ajustes de mueble por clave y las herramientas `convertir_edificios.gd` y `guardar_recursos_comunes.gd`. Un edificio sin escena da error y no se dibuja.
- La casona tiene ya su tercera cama dibujada (antes tenía la plaza pero no la cama).
- Comprobado: sitios y cosas idénticos antes y después; sondeo 29/29; `verify_all.gd` en verde. Total: 231 marcas en 32 escenas.

## 2026-11-11 — Casas modelo, trozo 2: las casas de recién llegados salen de tres casas modelo (Claude Code)
- Tres escenas nuevas (`mapa/edificios/modelo_casita`, `modelo_casa`, `modelo_casona`) con muros, tejado, muebles y marcas (`cama_1..`, `cama_alta_1..2` para el altillo, `mesa`, `cofre`). Cada casa de solar, las 9 del valle y las que se construyan jugando, es una copia de la de su tamaño (`mapa/casa_modelo.gd`). Con la puerta al norte, la misma casa con media vuelta: en esas casas camas, ventana y muebles cambian de lado.
- Borrado: los números de camas, mesa y cofre de `VillageLots`, el dibujo por código del interior de las casas y las 9 «fotos» de `mapa/edificios_vista/`. Todas las casas del mismo tamaño tienen ahora la misma altura de muro.
- Comprobado: sitios idénticos en casas con puerta al sur y girados media vuelta en las del norte; fotos antes/después iguales; sondeo 29/29; `verify_all.gd` en verde. Total: 215 marcas en 32 escenas. Fotos fijas nuevas de casas en `capturas_fijas.gd`.

## 2026-11-11 — Casas modelo, trozo 1: oficios en solares y posada con marcas (Claude Code)
- 58 marcas nuevas en 8 edificios: panadería, sastrería, granja, rancho, cantera, cabaña del leñador, taller y posada (`trabajo`, `trabajo_familiar`, `cama_1`, `cama_2`, `mesa`, `puesto`, `cofre`; la posada además `cama_huesped_1..2`). `VillageLots.shop_house_layout(solar, edificio)` lee las marcas si el edificio tiene escena; el molde de números (`_shop_house_mold`) queda solo para las tiendas que se levantan durante la partida, hasta el trozo 3.
- Siguen como números: el sitio de trabajo al aire libre del cantero, granjero, ganadero y leñador (campo, corral, roca, troncos) y las dos paredes interiores.
- Comprobado: 188 sitios y 9.143 cosas idénticos; sondeo 29/29; `verify_all.gd` en verde (118 bloques). Total: 196 marcas en 30 edificios.

## 2026-11-11 — Capilla: los muebles vuelven dentro (Claude Code)
- El altar, el atril, la mesilla, la mesa, la silla y la cama del sacerdote estaban guardados en la escena a unos 170 m de la capilla (se apuntaron con coordenadas del mapa sin agrandar). Recolocados dentro, en el mismo sitio que sus marcas. Visto en dos fotos nuevas de `capturas_fijas.gd` (`capilla_altar`, `capilla_fondo`).
- Inventario vuelto a medir tras las marcas: sigue 4.161, quieto 609, doble 0, otro sitio 138 (igual que antes: las marcas no cambian qué sale del editor).

## 2026-11-11 — Prueba del juego entero en verde tras las marcas (Claude Code)
- `verify_all.gd` pasa entera (118 bloques, «TESTS PASSED») por primera vez desde que empezó el paso 1. Hizo falta ajustar dos comprobaciones de la propia prueba que leían números ya borrados (el cáliz de la capilla y la celda); el juego no fallaba. Nuevo `VillageUnderworld.heist_target_pos()` para saber dónde está el objeto de un encargo.

## 2026-11-11 — Paso 1, octava tanda: la taberna con marcas (Claude Code)
- 22 marcas en la taberna: `barra`, `trabajo`, `pasaplatos`, `toneles`, `fogones`, `mesa_corte`, `chimenea`, `mesa_central`, `poker`, `billar`, `mesa_1..6` y las seis camas de arriba (`cama_marta`, `cama_alistair`, `cama_huesped_1..3`, `cama_jugador`). `VillageTavern` las lee con `sitio(M_…)`, `dining_tables()`, `guest_beds()`, `all_upper_beds()` y `poker_chairs()`; números borrados (también en `VillageManager*`, `VillageMigration` y pruebas).
- Comprobado: 189 sitios y 9.143 cosas del mapa idénticos; sondeo 29/29; física 3D PASSED. Total: 138 marcas en 22 edificios. Ya no quedan edificios únicos sin marcas.
- Siguen como números a propósito: salas, pasos, tabiques, escalera, pozo del patio, sillas (pegadas a su mesa) y paredes invisibles de muebles.

## 2026-11-11 — Paso 1, séptima tanda: molino, mansión y casa grande con marcas (Claude Code)
- 17 marcas nuevas: molino abandonado (`pajar`, `hogar`, `cordel`, `mesa_papel`, `sotano`: las pistas del Caso I), mansión (`cama_1..3`, `despacho`, `mesa`, `cofre`, `gabinete`) y casa grande (`cama_1..2`, `despacho`, `mesa`, `cofre`). Números borrados en `VillageWorldBuilder`, `VillageNobility`, `VillageCase1`, `VillageManager` y `partida_caso1.gd`.
- Comprobado: sitios y 9.143 cosas del mapa idénticos; sondeo 29/29; partida automática del Caso I completa (25 pasos). Total: 116 marcas en 21 edificios. De los edificios únicos solo falta la taberna.

## 2026-11-11 — Paso 1, quinta y sexta tanda: ayuntamiento, albergue, escuela, biblioteca y máquinas con marcas (Claude Code)
- 23 marcas nuevas: ayuntamiento (`mesa`, `urna`, `cofre`, `alcalde`, `terminal`), albergue (`cama_1..4`), escuela (`pupitre_1..6`, `maestro`), biblioteca (`lectura`, `palanca`, `libro_mayor`, `libro_roto`), `terminal` de la comisaría y del taller, y `expositor` de la herrería. Sus números están borrados (`VillageCivic`, `VillageFamily`, `VillageCulture`, `VillageManager`, pruebas).
- Biblioteca (Caso I): la palanca y los dos libros tenían dos números distintos (el del objeto y otro, 11 px más allá, para comprobar el [E]); ahora hay uno solo, la marca. La palanca acepta además lo que el jugador tiene seleccionado, como ya hacían los libros.
- Arreglo: el aviso de «estás junto al expositor de armas» comparaba con un punto del mapa sin agrandar.
- Comprobado: sitios y 9.143 cosas del mapa idénticos; sondeo 29/29; partida automática del Caso I completa (25 pasos). Total: 99 marcas en 18 edificios.

## 2026-11-11 — Paso 1, cuarta tanda: hospital, comisaría y capilla con marcas (Claude Code)
- 17 marcas nuevas: hospital (`camilla`, `cama_1`, `mesa`, `trabajo`, `mesa_morgue_1..3`), comisaría (`celda`, `cama_1`, `cama_celda`, `mesa`, `trabajo`, `archivo`, `escritorio`) y capilla (`altar`, `cama_1`, `mesa`). El pueblo las lee al arrancar y sus números están borrados (también los repetidos en `VillageJustice`, `VillageUnderworld`, `VillageNPCDuties`, `VillageNPC` y `partida_caso1.gd`).
- Dos fallos arreglados de paso: al caer inconsciente, el jugador aparecía en el sitio del hospital de antes de agrandar el mapa (ahora en la camilla de verdad); y el inspector, al amanecer, iba a repasar el expediente a un punto del mapa viejo (ahora al escritorio de la comisaría). Sin probar jugando.
- Comprobado: sitios de vecinos y autoridades y las 9.143 cosas del mapa idénticos antes y después; sondeo 29/29, viejos 0.

## 2026-11-11 — Paso 1, tercera tanda: los sitios de la casa de comidas son marcas (Claude Code)
- La casa de comidas tiene 20 marcas en su escena: fogones, encimera, colgadero, barra (`puesto`), piano, mesa del reservado, botellero, las dos camas, el cofre, 5 mesas del comedor y 5 de la terraza. `VillageRestaurant` las lee con `sitio(M_…)`, `dining_tables()` y `terrace_tables()`; sus números están borrados (también en `VillageFamilia`, `VillageManager` y `verify_all.gd`).
- Comprobado: sitios de vecinos, asientos y las 2.702 cosas colocadas en el mapa idénticos antes y después; sondeo 29/29, viejos 0. No se nota jugando.
- Decisión: los oficios de los solares y la posada esperan a la «casa modelo» de los solares (comparten molde con las tiendas que se construyen durante la partida).

## 2026-11-11 — Paso 1, segunda tanda: los sitios de las familias fundadoras son marcas (Claude Code)
- Las 5 familias de oficio fundadoras (herrero, carnicero, carpintero, pescadero y botica: 9 edificios) tienen en su escena, grupo «Marcas», 39 marcas (`mapa/marca.gd`): `trabajo`, `trabajo_familiar`, `cama_1`, `cama_2`, `mesa`, `puesto` y `cofre`. Las creó `tools/marcar_edificios.gd` copiando dónde estaba cada sitio.
- `VillageWorldBuilder` lee esas marcas (`Marca.sitio`) y se borraron los números que decían esos sitios. Los 173 sitios de vecinos, puestos y cofres quedan idénticos (comparado antes y después); sondeo de edificios movidos 29/29, sitios bien 54, viejos 0.
- No se nota jugando. Pendiente: marcas de los oficios en solares, posada, casa de comidas, hospital, comisaría; paredes invisibles de los muebles.

## 2026-11-11 — Paso 1, primera tanda: los 29 edificios fijos son escenas propias (Claude Code)
- Cada edificio fijo (posada, casa de comidas, hospital, comisaría, iglesia, molino, tiendas, casas de oficio…) es ahora una escena, `mapa/edificios/<id>.tscn`, con sus grupos Muros, Interior, PisoAlto, Tejado, Muebles y Marcas en metros respecto al edificio. El juego la carga donde esté su pieza del editor; jugando se ve igual (51 fotos de antes y después comparadas a ojo).
- Borrado el código que los dibujaba con números (`WorldStageBuildings3D.gd`: de 2.720 a 540 líneas); queda solo el dibujo genérico de las casas de recién llegados y de lo que se levante en un solar. Borradas las «fotos» viejas de esos 29 edificios y `tools/hornear_edificios.gd` (la sustituye `tools/convertir_edificios.gd`).
- Inventario: las piezas «traducidas dos veces» bajan de 885 a 0 (mover un edificio ya no descoloca su interior). Pruebas: puertas 29/29, sondeo de edificios movidos 29/29.
- Pendiente del paso 1: sitios de los vecinos como marcas (camas, mesas, puestos), muebles de la capilla fuera de sitio y casas de recién llegados con una escena base.

## 2026-11-11 — Plan aprobado: el mundo sale solo del editor; paso 0 (Claude Code, sobremesa)
- Aprobado el plan para dejar de construir el mundo con el plano 2D viejo y su traductor (`docs/PLAN_MUNDO_DESDE_EDITOR.md`), con las reglas de un profesional consultado por el usuario. Lo hace solo la sesión del sobremesa.
- Paso 0: inventario automático que mueve todas las piezas del editor y mira qué las sigue (`tools/tests/inventario_mundo.gd` → `docs/INVENTARIO_MUNDO.md`). De 6.783 cosas: 5.098 siguen al editor, 697 se quedan en el sitio viejo, 885 se mueven el doble (interiores de 8 edificios) y 103 acaban en otro sitio; 14 muebles de la capilla están hoy fuera de todo edificio. El juego no cambia.

## 2026-11-11 — Editor del mapa 3D más claro (Claude Code, sobremesa)
- La maqueta del editor tiene su propio sol y cielo (antes todo se veía oscuro y plano); solo en el editor, el juego no cambia.
- Fuera los aros de colores sobre los edificios (eran las luces interiores de sus fotos).
- Cada edificio lleva su nombre flotando encima (tamaño fijo en el mundo; se esconden a más de 700 m). Las casas de recién llegados salen como «Casa del solar N0», etc.
- Apuntados en `docs/FALLOS_VISIBLES.md` los 9 fallos de la segunda partida del usuario en 1.ª persona (pendientes).

## 2026-11-11 — Mapa ×5 (Claude Code, portátil; rama `mapa-x5`)
- El valle es cinco veces más grande: pueblo, campamento, lago, bosque y llanura separados; río el doble de ancho; bosques repoblados. Las partidas guardadas anteriores no valen (partida nueva). Rendimiento en el portátil: plaza 21 fps, río 24, bosque 23.
- Más sitios fijos al mundo ×5: cofres, terminales, hospital, molino, estudio de la mansión, generador y cables en 3D; cantera, campos, corral y troncos pegados a su edificio; barro del lago y la ciénaga y bandas del bosque en su sitio.
- Editor del mapa puesto al día con el ×5 (maqueta, referencia, avisos del río, rangos) y guía del usuario reescrita (`docs/EDITOR_MAPA_GUIA.md`). Sondeo de edificios movidos: 29/29.
- Partida del usuario (2.ª tanda): los puentes y vados abarcan el río de orilla a orilla (los vecinos ya no se amontonan en la orilla); el lago con el contorno redondeado, su zona de pesca y su muelle en la orilla de verdad.
- Partida del usuario: los muebles 2D (chimeneas, barriles, piano…) seguían sobre la hierba en los sitios antiguos y Sora dormía donde estaba la sastrería; ahora todo sigue a su edificio y los oficios de los recién llegados se reparten con las fichas ya traducidas. Mascotas, terminales, verja de la celda y ribera de pesca también.
- Repaso de sitios fijos que seguían en el mapa antiguo: pozos, tablón, solares, camas del albergue, de El Candil y de las casas nuevas, arcas y libro del ayuntamiento, casa del jugador (mostrador, clientes, dependiente, Toby, gallinero, mesa de las cenas, piso alto y sótano), biblioteca, estudio de los señores, celda de la comisaría, caravana, contrabandista, cámara fría, lavadero, carro, objetivo del golpe, terminales del taller, cama del hospital y ciénaga. Las pruebas colocan a los vecinos a distancias (no en sitios fijos).

## 2026-11-11 — Alcantarillas: reñidero en la Cisterna (Claude Code, portátil; `main`)
- La cámara este de las alcantarillas tiene un cuadrilátero de cuerdas, bancos, la mesa del apostador con pizarra y una pintada que señala al club de peleas del sótano de la posada.

## 2026-11-11 — Animales con vida propia en modo demo (Claude Code, portátil; `main`)
- Ciervos, conejos, zorros y jabalíes ya no se quedan clavados junto al nido: cada uno pasta por su rincón, va a beber al río, descansa y huye de ti. Caza y cría siguen en pausa en la demo.

## 2026-11-11 — Césped sin dibujo repetido (Claude Code, portátil; `main`)
- La hierba tiene manchas irregulares (seca y espesa) y briznas de cerca; de lejos se funde. Sin cuadrícula ni rombos.

## 2026-11-11 — Caso I con un día de margen (Claude Code, portátil; `main`)
- El día 1 llegas, lees la carta (texto provisional) y conoces el pueblo; el caso estalla el día 2 al amanecer con un aviso en pantalla. Los forasteros del molino cuentan sus días desde entonces.

## 2026-11-11 — Llanura Salvaje: los sapos son ahora bandidos (Claude Code, portátil; `main`)
- Los 4 enemigos de la llanura y la ciénaga son bandidos (muñeco 3D de asaltante, botín de chatarra y oro); el letrero de la ciénaga avisa de ellos. Arreglado además que los bandidos quedaban enterrados en terreno alto.

## 2026-11-11 — Posada: puertas en los cuartos y camas de adulto (Claude Code, portátil; `main`)
- Los 3 cuartos de la planta alta tienen puerta de madera que se abre al acercarte y se cierra al irte; las 6 camas miden lo que una cama de verdad.

## 2026-11-11 — Reorganización del repositorio y nuevo reparto de trabajo (Claude Code, portátil; `main`)
- Claude Code pasa a programar; Gemini/Antigravity queda como especialista y auditor bajo demanda. Nuevo `CLAUDE.md` maestro
  (también `GEMINI.md` y `AGENTS.md`), `docs/ESTADO_ACTUAL.md` (45 líneas máx.) sustituye a los traspasos largos,
  `docs/INDICE_SISTEMAS.md` y `docs/specs/` (una especificación por sistema). Historial en `docs/archivo/` (bloqueado a los
  agentes), bóveda de Obsidian bloqueada salvo petición. Filtros de IA (`.claude/settings.json`, `.geminiignore`,
  `.antigravityignore`). Rama de respaldo `backup-antes-reorg`.

## 2026-11-12 — Bosque del Caso I: árboles separados (Claude Code, portátil; rama `mundo-3d`)
- En el bosque del claro ya no hay árboles metidos unos dentro de otros: se quitaron 19 que tenían el tronco pegado a otro. El molino sigue escondido entre los árboles.

## 2026-11-12 — Limpieza: fuera el modo 2D antiguo (Claude Code, portátil; rama `mundo-3d`)
- Ya no existe el tablero plano de baldosas y sprites ([F9] sin Mayús); la vista desde arriba en 3D y la 1.ª persona siguen igual.

## 2026-11-12 — Paso a 3D: sitios en el fondo del agua (Claude Code, portátil; rama `mundo-3d`)
- Preparado para pistas en el fondo del río o del lago: solo se alcanzan buceando. Falta decidir cuáles.

## 2026-11-12 — Paso a 3D, opción B (2): animales grandes, mascotas, bandidos y enemigos con cuerpo completo (Claude Code, portátil; rama `mundo-3d`)
- Cerca de ti, ciervos, jabalíes, perros, bandidos y sapos chocan con paredes y muebles en 3D y contigo; los pequeños siguen igual.

## 2026-11-11 (noche) — Más fluido (Claude Code, portátil; rama `mundo-3d`)
- Plaza 20 → 25 fps, río 18 → 21: el relieve del terreno se recuerda en vez de recalcularse, y los vecinos y animales lejanos se ponen al día menos a menudo.

## 2026-11-11 (noche) — Paso a 3D: bucear (Claude Code, portátil; rama `mundo-3d`)
- Nadando, agacharse te hunde: buceas por el fondo con 30 s de aire (barra 🫧); sin aire pierdes vida hasta morir. Vista verde-azul bajo el agua.

## 2026-11-11 (noche) — Paso a 3D: piso alto y sótano de tu casa de verdad (Claude Code, portátil; rama `mundo-3d`)
- El piso alto de tu casa está de verdad arriba y el sótano bajo tierra; con [E] cambias sin caerte.

## 2026-11-11 (noche) — Paso a 3D, opción B: los vecinos cercanos con cuerpo 3D completo (Claude Code, portátil; rama `mundo-3d`)
- Los vecinos que tienes cerca chocan con paredes, muebles y puertas, suben escaleras y cambian de piso solos; chocan contigo (puedes apartarlos). Los lejanos siguen como antes.

## 2026-11-11 — Arreglos de la partida del usuario, 7b: manos de verdad en 1.ª persona (Claude Code, portátil; rama `mundo-3d`)
- Las manos en 1.ª persona son ahora los brazos del muñeco de los aldeanos (piel y manga), en vez de bolas de color carne.

## 2026-11-11 — Arreglos de la partida del usuario, 7a: el agua se mueve (Claude Code, portátil; rama `mundo-3d`)
- El río y el lago tienen corriente y brillos que ondulan (efecto propio, sin descargar nada).

## 2026-11-11 — Arreglos de la partida del usuario, 6: los cuartos de la posada (Claude Code, portátil; rama `mundo-3d`)
- La planta alta de la posada pasa de 5 cuartos minúsculos a 3 amplios: el de los dueños, el de huéspedes (3 camas) y el tuyo.
- De paso: un bandido muerto o huido cerca de ti dejaba un error repetido cada fotograma (su cuerpo de contacto no se soltaba).

## 2026-11-11 — Arreglos de la partida del usuario, 5: vecinos corriendo en el sitio (Claude Code, portátil; rama `mundo-3d`)
- Un vecino empujado atrás y adelante (por otro vecino parado o por ti en una puerta) ya se da cuenta al segundo y rodea por un lado.
- La simulación de atascos puede empezar a la hora que quieras, contratar un cocinero y dejarte parado en una puerta.

## 2026-11-11 — Arreglos de la partida del usuario, 4: bandidos (Claude Code, portátil; rama `mundo-3d`)
- Los bandidos y jabalíes de las incursiones chocan con paredes y muebles; si huyendo se quedan contra un muro, se dan por huidos.

## 2026-11-10 — Arreglos de la partida del usuario, 3: el cocinero (Claude Code, portátil; rama `mundo-3d`)
- El cocinero salía vestido de vigía con espada y daba hachazos sobre la olla (un número de oficio equivocado). Ahora lleva delantal y remueve la olla.

## 2026-11-10 — Arreglos de la partida del usuario, 2: agacharse en el agua (Claude Code, portátil; rama `mundo-3d`)
- En el agua ya no te agachas (la cámara se hundía bajo la superficie). Hasta que haya buceo.

## 2026-11-10 — Arreglos de la partida del usuario, 1: la pizarra de la escuela (Claude Code, portátil; rama `mundo-3d`)
- La pizarra estaba pegada a la puerta; ahora está en la pared de enfrente, con los pupitres en medio.

## 2026-11-10 — Paso a 3D de verdad: paso 5d, con [E] llegas a lo que está a tu altura (Claude Code, portátil; rama `mundo-3d`)
- En la escalera hablas con quien va unos peldaños más arriba; desde el salón no llegas a la galería ni a las camas de arriba.

## 2026-11-10 — Paso a 3D de verdad: paso 5c, golpes, flechas y balas con altura (Claude Code, portátil; rama `mundo-3d`)
- Los golpes alcanzan a quien está a tu altura (en la escalera sí; en la galería desde abajo no).
- Flechas y balas vuelan con altura: en 1.ª persona van hacia donde miras, solo hieren a quien está a esa altura y se clavan al bajar al suelo.

## 2026-11-10 — Paso a 3D de verdad: paso 5b, el oído con alturas (Claude Code, portátil; rama `mundo-3d`)
- Un ruido llega a los vecinos de otro piso más flojo (a través del suelo, un tercio; bajo tierra, casi nada). Antes no llegaba.
- De paso: si andas contra un vecino, lo apartas poco a poco (antes te cerraba el paso); los sentados no estorban.

## 2026-11-10 — Paso a 3D de verdad: paso 5a, la vista con alturas (Claude Code, portátil; rama `mundo-3d`)
- Testigos, policías y guardias te ven según paredes, puertas y suelos de verdad: desde el salón de la posada se ve a quien se asoma a la galería, no a quien está encima de ti.

## 2026-11-10 — Paso a 3D de verdad: paso 4c, animales grandes y bandidos (Claude Code, portátil; rama `mundo-3d`)
- Ya no atraviesas a bandidos, jabalíes, ciervos ni al ganado grande; conejos, zorros, mascotas, gallinas y crías sí.

## 2026-11-10 — Paso a 3D de verdad: paso 4b, ya no atraviesas a los vecinos (Claude Code, portátil; rama `mundo-3d`)
- Los vecinos cercanos tienen un cuerpo de contacto: chocas con ellos. Dormidos o caídos no estorban.
- Decisión del usuario: esto ahora; más adelante cuerpos completos que choquen con paredes y busquen caminos en 3D.

## 2026-11-10 — Paso a 3D de verdad: paso 4a, vecinos por la escalera (Claude Code, portátil; rama `mundo-3d`)
- Comprobado que los vecinos suben y bajan la escalera de la posada andando; quitado un escalón de golpe al llegar arriba.

## 2026-11-10 — Paso a 3D de verdad: paso 3a, nadar (Claude Code, portátil; rama `mundo-3d`)
- El río y el lago ya no son una pared: vadeas en la orilla y nadas donde no haces pie (lento, sin correr ni saltar, gasta aguante).
- Flotas con la cabeza fuera y sales por la otra orilla; caer al agua honda no duele. Los vecinos aún no entran al agua.

## 2026-11-10 — Paso a 3D de verdad: paso 2c, daño por caída (Claude Code, portátil; rama `mundo-3d`)
- Decisión del usuario: realista. Desde 3 m duele, a 8 m mata, y la caída hiere una parte del cuerpo (sobre todo piernas).
- Preparado para mejoras futuras que reduzcan el daño por caída. Barandillas de la posada a la cintura.

## 2026-11-10 — Paso a 3D de verdad: paso 2b, club y alcantarillas bajo tierra (Claude Code, portátil; rama `mundo-3d`)
- El club de peleas y las alcantarillas están de verdad unos 3 m bajo la calle; en 1.ª persona hay techo de roca.

## 2026-11-10 — Paso a 3D de verdad: paso 2a, la posada con dos plantas de verdad (Claude Code, portátil; rama `mundo-3d`)
- Al subir la escalera de la posada andando estás de verdad más alto; tu piso sale de tu altura.
- Abajo no estorban las barandillas de arriba, ni arriba los muebles de abajo. La cámara va sobre tu cuerpo.

## 2026-11-10 — Paso a 3D de verdad: paso 1b, recorrido por todas las puertas (Claude Code, portátil; rama `mundo-3d`)
- Prueba nueva: el protagonista entra y sale andando por las 29 puertas del pueblo; todas bien. Vecinos atascados: 0.
- Fluidez igual que antes del cuerpo 3D. Paso 1 terminado; falta que el usuario lo juegue un rato.

## 2026-11-10 — Paso a 3D de verdad: paso 1a, el protagonista tiene cuerpo 3D (Claude Code, portátil; rama `mundo-3d`)
- El protagonista anda, choca, cae y salta con un cuerpo 3D de verdad; el resto del juego sigue viéndolo en el mapa como siempre.
- Las paredes del pueblo no se rehacen: se copian en 3D las que hay cerca. El salto usa gravedad 3D (~1,1 m).

## 2026-11-10 — Paso a 3D de verdad: paso 0b, mundo en metros (Claude Code, portátil; rama `mundo-3d`)
- Decisión del usuario: escala uniforme. El mundo 3D mide en metros (una persona, 1,74 m) y tiene las mismas proporciones
  en todas direcciones; en 3D el pueblo es un 15 % más corto de norte a sur. En el mapa del pueblo no se mueve nada.
- Mapa editado por el usuario convertido (copia en `mapa/Mundo3D.antes-3d.tscn`); fotos de edificios rehechas.
- La vista desde arriba sigue cuadrando con el mapa (cámara a 62°, imagen estirada).
- Arreglado: dos vecinos podían quedarse encimados en una puerta (ahora guardan un mínimo de distancia).

## 2026-11-10 — Paso a 3D de verdad: paso 0, preparación (Claude Code, portátil; rama `mundo-3d`)
- Nada cambia al jugar. Copia de seguridad del juego (etiqueta `antes-de-mundo-3d`) y trabajo en una rama aparte.
- La fórmula que pasa del mapa al 3D estaba copiada en unos 20 sitios; ahora hay una sola (`scripts/fisica/Mapa3D.gd`). Fotos antes y después: iguales.
- Nuevas: prueba del paso a 3D, fotos fijas para comparar, mapa del código (`docs/MAPA_DEL_CODIGO.md`) y manuscrito de cambios (`docs/MANUSCRITO_MUNDO_3D.md`).
- Arreglado de paso: una herramienta del editor que no arrancaba y dos pruebas del editor que se quedaron anticuadas cuando el usuario editó el río.

## 2026-11-10 — Más fluido en 1.ª persona (Claude Code, portátil; pedido por el usuario)
- El pueblo dibujado en plano se seguía pintando detrás de la vista en primera persona, a la resolución de la pantalla, aunque no se viera. Ya no.
- Los vecinos a media distancia (unos 14–36 m) piensan y se mueven la mitad de veces, recorriendo lo mismo; los cercanos siguen al detalle.
- En primera persona, los objetos pequeños dejan de dibujarse a más de 25 m y los muebles a más de 50 m (a esa distancia son unos pocos puntos).
- Medido en el portátil (imágenes por segundo): afueras 27→33, plaza 22→29, río 18→23, bosque 27→38, molino 32→40, mansión 35→43.
- Si aún va justo: Ajustes → Gráficos → Sombras «Sin sombras» quita unos 4 ms más por imagen.

## 2026-11-10 — Menú principal, pausa, ajustes y créditos (Claude Code, portátil; pedido por el usuario)
- El juego arranca en un menú principal: Nueva partida, Continuar (la última guardada), Cargar, Ajustes, Créditos y Salir.
- Esc en la partida (sin nada abierto) abre la pausa: seguir, guardar, cargar, ajustes y salir al menú. El pueblo se para mientras está abierta.
- Tres huecos de partida, más el guardado rápido (F5) y un autoguardado al empezar cada día de juego. Cada hueco enseña el día, la hora del juego y la fecha real en que se guardó.
- Ajustes que se recuerdan entre sesiones: pantalla completa o ventana, sincronización vertical, límite de fotogramas, sombras (no / bajas / altas), nitidez de la imagen 3D, suavizado de bordes, sensibilidad del ratón, campo de visión, invertir el ratón y volumen general, de música y de efectos.
- Todas las teclas de juego se pueden cambiar; si eliges una que ya se usaba, las dos se intercambian.
- Créditos provisionales con los autores de los recursos (Quaternius, Kenney, packs comprados, sonidos y Godot). Los autores que no se saben van marcados «por confirmar».
- Salir al menú reinicia el juego para que el pueblo siguiente empiece limpio.

## 2026-11-10 — Controles sin choques (Claude Code, portátil; aprobado por el usuario)
- Los trucos de prueba piden Ctrl para no saltar en una partida normal: Ctrl+T adelanta 2 horas, Ctrl+F1–F4 cambian la velocidad del reloj, Ctrl+F7 el tiempo atmosférico y Ctrl+º el modo pruebas. Ya no salen en la ayuda (H).
- + y − solo hacen zoom (antes también cambiaban la velocidad del reloj).
- Fuera las teclas repetidas: F6 (era igual que P), F8 (igual que º) y F10 (igual que F9). Lista completa en `docs/CONTROLES.md`.
- Dos comprobaciones de la prueba general que fallaban a veces, según cómo fuera la partida de prueba, ahora ponen al vecino en un estado neutro antes de comprobar.

## 2026-11-10 — Menos vecinos atascados y arranque más limpio (Claude Code, portátil)
- Los vecinos ya no se meten en el hueco estrecho entre la herboristería y la pescadería (ni en el del albergue con el hojalatero): rodean la manzana.
- Antes de la pasarela del norte del río siguen la orilla en vez de meterse en el agua donde el río hace curva.
- Prueba de 6 horas de juego: de 1–5 vecinos atascados a 0, sin errores. La prueba ahora da siempre el mismo resultado (antes dependía de la velocidad del ordenador).
- Quitados tres avisos que salían al arrancar el juego, y arreglada la herramienta que pasa el decorado al editor del mapa (no arrancaba).
- Ronda completa de pruebas, todas bien: general (118 bloques), nombres, vida social (60 días), diálogos (568 acciones sin errores) y guardar/cargar 7 días. Tres comprobaciones de la prueba general estaban desfasadas por los cambios del mapa (un punto «seco» junto al río nuevo, un testigo pegado a la casa movida, Toby ausente desde el nuevo inicio en las afueras): ahora buscan su sitio solas. No eran fallos del juego.

## 2026-11-10 — Los trabajos al aire libre siguen a lo movido (Claude Code, portátil)
- Si mueves en el editor del mapa 3D el lavadero, los campos, el rancho, la cantera, el mercado, el mirador, el campamento del contrabandista u otras piezas del exterior, los vecinos van a trabajar, lavar, pasear o comerciar al sitio nuevo. También la cama de urgencias y la morgue del hospital.

## 2026-11-10 — Taberna, restaurante, iglesia y comisaría siguen a su edificio movido (Claude Code, portátil)
- Si mueves la taberna, el restaurante, la iglesia, el hospital o la comisaría en el editor del mapa 3D, los vecinos se sientan en las sillas nuevas, el camarero hace su ronda donde están las mesas, el cura da misa en el altar nuevo y la celda, la morgue y las escaleras funcionan en el sitio nuevo. También el parque, la biblioteca y los otros sitios de ocio, si se mueven.
- Arreglado: los que llegan a mitad de partida (contratados, hijos, oficios vacantes) podían acabar con la casa desplazada el doble.
- Aviso: hay un atasco que ya existía en un paso estrecho de la plaza; queda apuntado.

## 2026-11-10 — Los vecinos siguen a sus casas movidas (Claude Code, portátil)
- Si mueves o giras una casa, una tienda o sus muebles en el editor del mapa 3D, sus vecinos duermen, comen y trabajan en el sitio nuevo (antes iban al hueco viejo). Prueba: 54 de 60 sitios siguen al edificio; los 6 restantes están al aire libre y van en el siguiente paso. Plan y registro: `docs/PLAN_SITIOS.md`.
- Aviso: la partida de prueba del Caso I falla desde antes de este cambio (el jugador no llega al claro); queda apuntado.

## 2026-11-10 — Pincel del mapa (Claude Code, portátil)
- Nuevo panel **Pincel** en el editor del mapa 3D: pinta bosques, rocas, hierba, matorrales o troncos arrastrando el ratón, o copias de tus propios modelos. Goma para borrar, tamaño y «apretado». No siembra en el río, el lago, los edificios ni los caminos. Cada cosa pintada se puede mover luego una a una. Guía: `docs/PINCEL_MAPA_GUIA.md`.

## 2026-11-09 (noche) — Editor del mapa, paso 1: el río y sus puentes (Claude Code)
- Nueva escena **mapa/EditorMapa** para Godot: el valle visto desde arriba con edificios, caminos y árboles de guía. El río se mueve arrastrando sus puntos (y se ensancha en el Inspector); los puentes y vados también. Avisa en rojo si el agua pisa un edificio o un puente no llega de orilla a orilla. El juego usa lo que haya ahí (agua, orillas, choque, vecinos y río 3D). Con los puntos originales el río es idéntico al de antes. Guía: `docs/EDITOR_MAPA_GUIA.md`; plan: `docs/PLAN_EDITOR_MAPA.md`.

## 2026-11-09 (tarde) — Rendimiento, vecinos atascados e informe del Caso I (Claude Code)
- **Rendimiento:** el juego iba lento por el procesador, no por la gráfica. Los vecinos hacían comprobaciones caras (puertas, muros, edificios) contra todos los demás en cada instante, y el motor encadenaba hasta 8 pasos por fotograma para ponerse al día. Ahora lo barato va primero, las huellas de edificios están en caché y hay un tope de 3 pasos a velocidad normal. Portátil: de 3–4 a 12–17 fps. Luego: rejilla de vecinos por paso (cada uno mira solo su zona) y terreno quieto juntado por zonas → 14–21 fps; afueras de 8.400 a 5.300 llamadas de dibujo. Por último, vecinos lejanos simplificados (activado por el usuario) con el muñeco 3D suavizado: 22–45 fps según la zona.
- **Vecinos atascados:** se deslizan por el borde de edificios y orillas en vez de congelarse; 9 → 2 atascos en 4 h de juego.
- **Día de 18 minutos** (antes 6).
- **Informe del Caso I** en la comisaría (bandeja junto a la entrada): pruebas del cuaderno + a quién culpas; queda guardado para el final. Las pistas del caso a las que apuntas ganan a una puerta cercana.
- Partida de prueba del Caso I: 25 ✅ / 0 ❌.

## 2026-11-09 — Caso I: piezas que faltaban para cerrarlo (Claude Code, sin la acusación)
- **El boticario, la criada y el familiar hablan del caso:** cuando ya has hecho la autopsia, vaciado el bolsillo del cuerpo o encontrado la hoja arrancada, aparece una opción nueva al hablarles; lo que cuentan se apunta en el cuaderno.
- **Gabinete forzado en el estudio de la mansión** (cerradura doblada, virutas y el hueco del frasco en el terciopelo) y **hoja arrancada con dosis corregidas** a los pies de la cama del familiar.
- **Reparto del caso entre vecinos reales** al empezar (boticario, criada de la casa del señor, familiar y el vecino de la lana azul, con manga rota y arañazos). Se guarda en la partida.
- **Dos secuestradores forasteros escondidos en el molino:** atacan si te acercas sin sigilo, huyen malheridos y se marchan si tardas más de tres días.
- El vigilante de Antigravity se para solo si a Antigravity se le acaba el cupo.

