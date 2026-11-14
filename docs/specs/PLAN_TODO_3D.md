# Plan «todo en 3D, nada de 2D» (mandato del usuario, 2026-11-14)

> **Mandato:** absolutamente todo el juego pasa a 3D. Nada de 2D en el mundo ni en su lógica. El usuario lo ha pedido
> muchas veces; el estado híbrido («cuerpo en 3D, cerebro en el mapa») **no** cuenta como terminado.
> Detalle de lo que queda: `docs/specs/AUDITORIA_2D_A_3D.md`. Piezas del editor: `docs/specs/PLAN_LO_QUE_SE_VE.md`.

## Qué significa «terminado» (se mide, no se opina)
`bash tools/contar_2d.sh` cuenta los restos 2D (cuerpos, áreas, dibujos, cámara, navegación, píxeles, pisos de mentira,
estirón ×5…). **Punto de partida el 2026-11-14: 2.495. Hoy: 2.454 (con lo de Antigravity). Terminado = 0.** Lo único plano que queda es la interfaz
(menús, HUD, paneles), como en cualquier juego 3D; la vista desde arriba se mantiene como **cámara 3D**.

## Solo 1.ª persona (decisión del usuario, 2026-11-14)
La vista desde arriba ya no cuenta: no se diseña, prueba ni arregla nada para ella. Simplifica el plan: en la tanda 8
(escena raíz 3D) sobran la cámara inclinada, el estirón vertical de los muñecos (`_cos_p`) y el cuadre del 3D con el
mapa plano; en la 7, el apuntado y los rótulos con el ratón sobre el mapa (`Crosshair2D`, familia «Ratón sobre el mapa
2D» del contador) y la rama «desde arriba» del selector de la E (`Tocable3D.cerca`). Se borran al tocar cada archivo.
Quitada ya la «cortina» de la flecha (era solo para esa vista): la flecha da siempre justo donde se apunta.

## Reglas de honestidad (obligatorias para cualquier agente)
1. Nadie escribe «migrado», «terminado» o «3D de verdad» sin dar el número del contador antes y después.
2. Cada cierre de tarea de este plan dice **qué sigue siendo 2D** tras el cambio, sin que el usuario lo pregunte.
3. Prohibido añadir nada nuevo en 2D o en píxeles (ni «de momento»). Si un arreglo urgente lo necesitara, se avisa antes.
4. Los atajos (colocar a un vecino, copiar choques, niveles de piso) se nombran como atajos y se apuntan aquí para quitarlos.

## Estrategia: dar la vuelta a quién manda (decidida al estudiar el código, 2026-11-14)
Hoy manda el mapa plano y el 3D lo copia. Se invierte **por capas**, sin apagar el juego: primero el mundo fijo
(paredes y suelos 3D de verdad), luego los cuerpos (todos en 3D siempre), luego las rutas, los sentidos y la raíz. El
código que aún piensa en plano sigue funcionando a través de un «traductor» mientras se reescribe archivo a archivo; el
traductor se borra cuando el contador de sus usos llega a 0. **Los metros no son una tanda aparte:** cambiar a ciegas
miles de números de píxeles a metros rompería cosas sin ganar nada; cada archivo pasa a metros cuando se reescribe.
**Orden real: 0 ✅ → 3a → 3b (=4) → 5 → 6 → 7 → 8 → 2 y 9 repartidas en las anteriores.** El estirón ×5 que queda
(relieve, lago, ciénaga, mapa del valle) vive sobre todo en archivos de Antigravity: se le encarga a él.

## Tandas (cada una deja el juego jugable y la partida automática del Caso I en verde)
0. ✅ **Limpieza (hecha el 2026-11-14, contador 2.495 → 2.441):** fuera las tres capas de baldosas y la caja de
   diálogo vieja de la escena principal (382 KB → 25 KB) y cuatro escenas sin uso. Los bandidos, el vigía «Guia», la caja,
   el barril, el muro débil y el arma del suelo **no** eran restos: son contenido vivo y se migran en la tanda 4.
   Pendiente menor (archivo de Antigravity): el bucle «ranch_fence_2d» de `WorldStageProps3D.gd` ya no encuentra nada.
1. **Sistemas dormidos** (>10.000 líneas tras el modo demo): **decidido por el usuario el 2026-11-14: se migran ahora
   también**, no se archivan. Cada tanda los incluye (secta, bajos fondos, linaje, migración, clanes, fama, alcalde,
   préstamos, enfermedades, club, trabajos nocturnos, ecosistema…); el contador los cuenta desde el principio.
2. **Un solo espacio, en metros:** las posiciones del juego pasan a ser las de las piezas 3D; fuera el estirón ×5, el
   «mapa original» y las alturas en píxeles.
3. **Paredes, suelos y pisos reales**, en pasos:
   ✅ **3a-0 (2026-11-14):** los edificios ya no crean su suelo y sus muros planos (se creaban y se hacían transparentes).
   ✅ **3a (2026-11-14):** un solo juego de paredes 3D compartido por todos los cuerpos (`fisica/ChoquesMundo3D.gd`, con
   `Prismas3D.gd` y `AlturasChoque3D.gd`), por celdas de ~7 m que se levantan una vez y se repasan cada pocos pasos.
   Borrado `ChoquesCercanos3D.gd` (copias por cuerpo y por paso). Franjas de altura reales (planta baja, planta alta,
   bajo tierra, barandilla) en vez de capas según el piso de quien choca; agua en su capa; lo del destino de un vecino,
   con excepciones de choque. **Contador: 2.441 → 2.457 (sube 16):** el sistema nuevo sigue preguntando al mapa plano
   (cada pared es «gemela» de su choque plano); baja cuando cada fuente dé su choque desde su pieza 3D (paso v del diseño).
   ✅ Tanda 4a hecha sobre esta base (abajo). **Siguiente: 4b** (el personaje ES su cuerpo 3D; fuera su nodo plano).
   **3b:** pisos = altura real (losas 3D de verdad); se borran `Suelo`/`PisosCasas` como reglas y los niveles de piso.
   (Usuario, 2026-11-14: la posada conserva su sistema propio de pisos hasta esta tanda; aquí se unifica con las casas.)
4. **Personajes 3D siempre:** jugador, vecinos, animales y bandidos son cuerpos 3D todo el tiempo (los lejanos, con
   simulación barata pero en 3D). Se borran `CuerposDelPueblo3D`, `CuerposCercanos3D` y los dibujos planos.
   ✅ **4a (2026-11-14):** TODOS llevan su `Cuerpo3D` desde que entran en el juego (`Poblacion3D.gd`: todo
   `CharacterBody2D` y el grupo `con_cuerpo_3d`, sin listas ni distancia; 77–82 cuerpos en una partida). Borrados
   `CuerposDelPueblo3D.gd` (solo 24 cercanos) y `CuerposCercanos3D.gd` (cuerpos de contacto). Ya nadie anda con el paso
   plano: fuera los `move_and_slide`/`move_and_collide` del mapa de vecinos, policía, vigía y empujones de combate
   (`AndarMapa.paso/empujon/ha_chocado`). Tamaños en `TallaCuerpo3D.gd`; los pequeños chocan con paredes pero no
   estorban. Lejos del protagonista (>22 m) el cuerpo que solo sigue a su personaje se pone al día 1 de cada 10 pasos.
   Arreglo de paso: un vecino cambia de piso al ACABAR la escalera (a media rampa la ruta lo mandaba contra la
   barandilla). Contador 2.428 → **2.425** (casi no baja: el cerebro sigue en el mapa plano). Pruebas: `fisica_3d`
   100/100, `aviso_caso1`, partida del Caso I 25/25, `atascos_vecinos` 8 h = 0 atascos (la red actuó 12 veces),
   `puertas_3d` 28/29 (la que falla ya fallaba sin este cambio: banco ante la pescadería). Coste de física sin
   ventana: 3,8 → 4,1 ms por paso (dentro del ruido); **con ventana (fps) no se ha medido**.
   **Sigue siendo 2D tras la 4a:** cada personaje es todavía un nodo del mapa plano (`CharacterBody2D`/`Node2D`) con
   posición en píxeles, y su cuerpo 3D le escribe ahí el resultado; el ganado, los animales lejanos (>500 px) y
   camas/escaleras/recolocaciones mueven la posición plana y el cuerpo les sigue sin chocar; quedan sus dibujos planos
   escondidos, su capa de choque plana (la usan vista, la E y los golpes) y los pisos como número.
   **4b:** el personaje pasa a SER su cuerpo 3D (posición en metros; el nodo plano y sus dibujos se borran). Depende
   de que rutas (5) y sentidos (7) dejen de leer la posición plana: se hace por clases (animales → bandidos → vecinos).
   ✅ **4b-1 (2026-11-14): el ganado del rancho.** `LivestockAnimal.gd` hereda de `fisica/CuerpoBase3D.gd` (nuevo: lo
   común a todo cuerpo 3D: cápsula, talla, capa y altura del suelo; `Cuerpo3D` también lo hereda), vive en el escenario
   3D y en metros (corral, velocidades, separación), sin nodo en el mapa plano; fuera el grupo `con_cuerpo_3d`.
   `AnimalModel3D` sirve a dueños 3D (`poner`, en metros) y aún a los planos (`attach`, en píxeles). Contador
   2.312 → **2.302**. Prueba `fisica_3d` (9 comprobaciones nuevas «4b»). **Sigue siendo 2D:** el sitio del corral y la
   altura del suelo se preguntan al mapa plano (traductores apuntados abajo); el modelo aún mide por dentro en píxeles.
   **4b-2, animales salvajes:** no podían ser un cuerpo 3D mientras los golpes los buscaran en el mapa plano; por eso
   se hizo antes la 7a (abajo). ✅ **Hecho el 2026-11-14.** `WildAnimal` hereda de `CuerpoBase3D`, vive en el escenario
   3D y piensa en metros sobre el suelo (`sitio`, `casa`, `andar`, `paso_m_s`, `huida_m_s`, `alerta_m`). Su archivo de
   1.235 líneas se partió en piezas con nombre de clase, sin preloads entre ellas (`enemies/animales/`: `AnimalAlerta`,
   `AnimalAgenda`, `AnimalComida`, `AnimalCaza`, `AnimalJabali`, `AnimalDespiece`, `AnimalRotulo`, y `VidaAnimal`). Fuera
   su dibujo plano, su choque plano, su rótulo plano (ahora `Label3D`) y el ratón sobre el mapa. `CuerpoBase3D` ya no
   tiene preloads de sistemas (capas en `Capas3D.gd`; suelo, relieve y paredes se cargan al usarlos) y da el paso físico
   (`_paso_fisico`, `_pisar`, `_pedir_paredes`). `Lugar.gd` es el traductor de sitios: `Lugar.de(n)` en metros y
   `Lugar.en_mapa(n)` en píxeles, sea `n` plano o 3D. Contador 2.274 → **2.240**. Pruebas: `animales_3d` (nueva, 22
   comprobaciones, también con el modo demo apagado), `fisica_3d`, partida del Caso I 25/25, fotos. Arreglos de paso:
   empezar la partida ya no da experiencia de caza (los animales de reserva «se despiezaban» al crearse y subían la caza
   a nivel 3); un cadáver ya no estorba el paso. **Sigue siendo 2D:** (la zona para despiezar con [E] dejó de serlo en la 7e-1); el ecosistema guarda nidos y medidas en píxeles y
   los pasa a metros al crear cada animal (`EcosystemManager._spawn_animal_pool`); la orilla del río se pregunta a
   `RioLago` en píxeles (`VidaAnimal._orilla_cercana`); las plantas que comen son nodos planos (`HarvestableNode`);
   quien aún piensa en plano los lee con `Lugar.en_mapa` (cazadores, cepos, perros, mapa del valle, cruz del ratón).
   ✅ **4b-3a (2026-11-14): las mascotas del pueblo.** `DomesticPet` hereda de `CuerpoBase3D`, vive en el escenario
   3D y en metros; se la hiere por su `Diana3D` y se la usa con [E] por su `Tocable3D` (segundo usuario de la E en 3D).
   Su archivo de 627 líneas queda en `DomesticPet.gd` + `enemies/mascotas/` (`MascotaNecesidades`, `MascotaPelea`,
   `MascotaCasa`, `MascotaTrato`). Nuevo `ui/TextoFlotante3D.gd` (texto que sube y se desvanece, en 3D). Fuera su
   dibujo plano, su choque, su área de la E y su rótulo planos; las mascotas se crean tras el escenario 3D. Contador
   2.239 → **2.219**. Pruebas: `mascotas_3d` (nueva, 22 comprobaciones), `animales_3d`, `fisica_3d`, partida del Caso I
   25/25, fotos. **Sigue siendo 2D:** su cama y su cuenco (objetos del mapa plano); para no pasear por dentro de las
   casas pregunta al pueblo en píxeles (`MascotaCasa._sitio_de_paseo`); `EnemyAI` y el aviso de maltrato leen su sitio
   con `Lugar.en_mapa`. No llevan la red contra atascos ni rutas: andan en línea recta cerca de su casa.
   ✅ **4b-3b (2026-11-14): asaltantes y secuestradores.** `Raider` (bandido o jabalí de las incursiones) y
   `MillKidnapper` (los dos forasteros del molino del Caso I) heredan de `CuerpoBase3D` y viven en el escenario 3D, en
   metros; nacen con `Raider.crear(arbol, guion)`. `BanditModel3D` sirve a dueños 3D y aún a los planos (los bandidos
   de la ciénaga). `RaidController` y los defensores los leen con `Lugar.en_mapa`. Contador 2.219 → **2.204**. Pruebas:
   `bandidos_3d` (nueva, 12 comprobaciones), `fisica_3d` (el bandido que huye no atraviesa la pared), partida del
   Caso I 25/25 (los dos secuestradores siguen en el molino), fotos. **Sigue siendo 2D:** la plaza que saquean se lee
   del mapa plano (`Sitio.mundo`); sus objetivos (protagonista y vecinos) son nodos planos; no llevan rutas.
   **Siguiente 4b-3c:** los bandidos de la ciénaga y el vigía (`DummyEnemy`, `scenes/npc.gd`): dependen de `EnemyAI`
   (navegación y vista planas, `NavigationAgent2D`, cono de visión) → van con las tandas 5 y 7. Después, vecinos y
   protagonista (dependen de rutas, pisos y de que la cámara y la escena raíz sean 3D).
5. **Rutas con navegación 3D** (malla de navegación del mundo y de cada edificio). Se borran las rutas y listas de
   puertas a mano y los atajos de «colocar» vecinos (guardia mensajero, custodia).
6. **Piezas que dicen para qué sirven** (`PLAN_LO_QUE_SE_VE.md`, fases 1–4), ya en 3D: sillas, camas, puestos, la E.
7. **Ver, oír, golpear y la E con rayos y áreas 3D.** Se borran `Vista.gd` como reglas planas y el selector por ángulos.
   ✅ **7a-1 (2026-11-14): golpes a personajes en 3D.** Cada personaje que sabe recibir daño lleva una `Diana3D`
   (`systems/combat/Diana3D.gd`, un `Area3D` en su cuerpo, del tamaño del cuerpo más un margen; la pone `CuerpoBase3D`
   sin listas). El tajo del protagonista es una esfera 3D delante de él (`PlayerCombatController._buscar_dianas_del_tajo`)
   y la flecha busca la diana que cruza en cada paso de vuelo (`ArrowProjectile._herir_en_el_tramo`): quien está en otro
   piso queda fuera por su altura de verdad. Borradas `Hurtbox.gd` y `Hitbox.gd` y sus nodos en `World.tscn`,
   `DummyEnemy.tscn` y `FastEnemy.tscn`. Contador 2.302 → **2.286**. Pruebas: `fisica_3d` («7a», 9 nuevas) y partida del
   Caso I 25/25. **Sigue siendo 2D:** la flecha aún vuela como nodo del mapa plano (posición en píxeles + altura) y choca
   con paredes y objetos rompibles del mapa; el tajo aún lleva un área plana solo para los objetos rompibles (cajas,
   barriles: tanda 6); el empujón recorre grupos y pregunta por pisos (`vm.alcanza`); el «dueño» de cada diana sigue
   siendo el nodo plano del personaje.
   ✅ **7a-2 (2026-11-14): la flecha y la bala son proyectiles 3D** (`systems/combat/Flecha3D.gd` y su figura
   `FlechaFigura3D.gd`; borrado `ArrowProjectile.gd`). Viven en el escenario 3D y en metros: la flecha sale del pecho
   con la pendiente de la mirada, cae por su peso (medida para que un tiro recto llegue a su alcance de siempre) y se
   clava donde aterriza: suelo, pared u objeto rompible (este recibe el daño a través de la pared gemela,
   `ChoquesMundo3D.META_ORIGEN`). Ahora se ve en 1.ª persona (antes era un dibujo del mapa plano). Contador
   2.286 → **2.274**. Pruebas: `fisica_3d` («7a-2» y «5c», 3 pasadas seguidas) y foto en 1.ª persona. De paso: un
   cuerpo traído de lejos junto al protagonista llegaba hasta 10 pasos tarde (`Cuerpo3D._seguir`): arreglado.
   **Sigue siendo 2D:** la flecha pide las paredes a `ChoquesMundo3D` con su sitio en el mapa plano y pregunta las losas
   a `Vista.gd` (traductores); `DamageData.shot_distance_px` y `CombatFeel` siguen midiendo en el mapa plano.
   ✅ **7e-1 (2026-11-14): la tecla E ya sabe buscar en el mundo 3D.** `ui/Tocable3D.gd` (un `Area3D` en la capa
   `Capas3D.TOCABLES` con su dueño): `InteractionSelector._candidatas_3d` añade lo que el protagonista tiene al alcance
   del cuerpo (vista desde arriba) o lo que cruza un rayo desde sus ojos (1.ª persona, `Tocable3D.en_la_mira`; las
   paredes lo tapan), a su altura de verdad y sin reglas de ángulos. Primer usuario: el cadáver de un animal salvaje
   (borrada `animales/ZonaDespiece.gd`, el área plana provisional). Contador 2.240 → **2.239**. Pruebas: `animales_3d`
   (27), `apuntar_fp`, `fisica_3d`, partida del Caso I (3 de 4 pasadas limpias; en una salió 1 paso pendiente que no se
   repitió: vigilar, pasándola con `grep "❌"`). **Sigue siendo 2D:** todo lo demás que se usa con E (vecinos, puertas,
   camas, pistas, objetos: áreas «interactable» del mapa plano y sus reglas de ángulos en `_fp_crosshair_score`).
   **Siguiente 7e-2:** que cada cosa que se use con E ponga su `Tocable3D` (por clases: mascotas y vecinos al pasar a 3D;
   puertas y sitios fijos con las piezas de la tanda 6) y borrar el selector por ángulos.
8. **Escena raíz 3D:** el mundo deja de pintarse como imagen dentro de una escena 2D; cámara, luz de día y noche,
   lluvia y sonido en 3D.
9. **Datos fuera del código y objetos gigantes partidos**, según se toque cada sistema (auditoría B y C).

## Diseño de la 3a: choques 3D fijos y compartidos (estudiado el 2026-11-14, sin empezar)
**Qué hay hoy.** Las paredes de verdad son `StaticBody2D`: muros de cada edificio (`_construct_solid_building` desde
`mapa/planta.gd`), tabiques (piezas «Tabiques», metros), muebles (piezas «Muebles» con `tam3`, vía
`_register_furniture_rect`), choques de código (`add_choque_mundo` 16, `choque_en_edificio` 9), puertas (cuerpo que se
apaga al abrir), reja de la celda, agua (grupo `agua_2d`), club y alcantarillas, árboles y rocas. Las escenas de los
edificios **no tienen ningún choque 3D** y sus muros visibles no son los que chocan. Cada cuerpo 3D pregunta al mapa plano
qué tiene cerca y levanta prismas (`ChoquesCercanos3D`): el jugador en cada paso; cada vecino, 1 de cada 3.
**Casos que la copia resuelve y el sistema nuevo debe cubrir:** (1) choques de un solo piso (bandas de altura por grupo
`choques_piso_0/1`, hoy además cambian de capa según el piso del jugador); (2) bajo tierra (nivel −1: otra máscara y otro
suelo); (3) el agua frena a los vecinos y no al jugador; (4) lo que hay en el destino de un vecino no le frena (su
cama, su silla): hacerlo con excepciones de choque por cuerpo; (5) barandillas a la cintura; (6) cosas que se mueven o
se apagan (puertas, carros, árbol talado); (7) altura de base = suelo del sitio del choque, no del cuerpo.
**Pasos.** (i) `ChoquesMundo3D`: un nodo con el juego fijo; las piezas que ya están en metros (tabiques, muebles) entran
directas desde su pieza; el resto entra como gemelo fijo de su choque plano, creado una vez y avisado al cambiar
(atajo, apuntado abajo). (ii) `Cuerpo3D` deja de tener copia propia y usa capas: muros, agua (solo vecinos), bajo tierra.
(iii) fuera `ChoquesCercanos3D`. (iv) con eso barato, todos los personajes llevan cuerpo siempre (tanda 4). (v) después,
fuente a fuente, el choque sale de la pieza 3D y se borra el plano (muros desde las mallas «Muros», naturaleza desde
`Mundo3D.tscn`…). **Pruebas:** `fisica_3d`, `puertas_3d`, `atascos_vecinos`, partida del Caso I, fps antes y después.
**Por qué no se puede «solo paredes» de una vez:** mientras algún personaje ande por el mapa plano (vecinos lejanos,
rutas, vista), sus paredes planas hacen falta; se borran al final de las tandas 4, 5 y 7, no antes.

## Atajos vivos que hay que quitar (apuntar aquí los nuevos)
- Paredes 3D «gemelas» de los choques del mapa plano (`ChoquesMundo3D._levantar`, 2026-11-14) → paso v de la 3a.
- Los parámetros de dibujo plano de `_construct_solid_building` (ya sin uso; 15 llamadas) → se van con el constructor.
- Guardia mensajero y de custodia «colocados» cerca del jugador o en su puesto (`Case1Aviso.gd`, 2026-11-14) → tanda 5.
- ✅ (quitado en la 4a) Cuerpos 3D solo para 24 vecinos a ~8 m.
- Red contra atascos: 5 s queriendo andar sin avanzar → 0,5 s sin chocar con nada (`Cuerpo3D._vigilar_atasco`,
  2026-11-14; 12 veces en 8 h de pueblo) → tanda 5 (rutas 3D). **Medido el 2026-11-14 tras las tandas 4b y 7a
  (`atascos_vecinos`, 4 h, 13 pasadas entre la versión de la mañana, las intermedias y la final, con semillas 11–13):**
  entre 0 y 12 «colados» y entre 0 y 2 atascos por pasada, según el azar; el total de tropiezos no ha subido. Se repiten
  dos sitios donde un mueble queda a medio paso del destino de un vecino: el ala oeste de la mansión (una cama de
  28 × 16 junto a (6447, −2131); se estorban los de la casa, `family_lord`) y junto a (155, −2745). La prueba cuenta
  como atasco 6 s sin avanzar y la red salta a los 5–6 s: quedan justo en el límite. Se arregla con las rutas 3D.
- Los vecinos cambian de piso al acabar la escalera y no a media rampa, porque sus rutas piensan por pisos
  (`Cuerpo3D._nivel_al_acabar_escalera`) → tanda 5.
- Cuerpos que «siguen» sin chocar a quien aún se mueve escribiendo su posición plana: animales a más de
  500 px, camas, escaleras con [E] (`Cuerpo3D._seguir`) → tandas 4b y 5. (El ganado ya no: 4b-1.)
- Traductores de quien ya ES su cuerpo (4b-1): `CuerpoBase3D.suelo_y` (altura del suelo desde el mapa plano → 3b),
  `VillageHousing.ranch_pen_m` (corral desde el sitio plano → cuando el rancho dé su valla desde su pieza) y
  `AnimalModel3D._pos_mapa`/`attach` (el modelo aún mide en píxeles → al pasar a 3D el último animal).
- ✅ (quitada el 2026-11-14: el juego es solo en 1.ª persona) «Cortina» de la flecha para la vista desde arriba.
- `Lugar.gd` (traductor metros ↔ mapa plano, 2026-11-14) y sus usos `Lugar.en_mapa(...)` en código que aún piensa en
  plano → se borra cuando no quede ningún personaje en el mapa plano.
- ✅ (quitado en la 7e-1) `ZonaDespiece.gd`: área del mapa plano para despiezar un animal 3D con [E].
- Tabla de tamaños por grupo y especie en `TallaCuerpo3D.gd` (cada personaje debería decir el suyo) → tanda 6.
- Dibujos 2D escondidos con capas en 1.ª persona (`WorldStage3D._ocultar_2d_tapado`) → tandas 4 y 8.
- Cama `cama_2` de la comisaría puesta a mano; zapato del caso como «Caja_383» con etiqueta → tanda 6.

## Coste honesto
Mucho: son los cimientos (vecino y pueblo suman ~12.000 líneas pensadas en píxeles). Semanas de trabajo por tandas, no
días. Cada tanda se cierra con el número del contador, sus pruebas y lo que queda.
