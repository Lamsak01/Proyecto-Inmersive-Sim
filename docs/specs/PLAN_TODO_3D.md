# Plan «todo en 3D, nada de 2D» (mandato del usuario, 2026-11-14)

> **Mandato:** absolutamente todo el juego pasa a 3D. Nada de 2D en el mundo ni en su lógica. El usuario lo ha pedido
> muchas veces; el estado híbrido («cuerpo en 3D, cerebro en el mapa») **no** cuenta como terminado.
> Detalle de lo que queda: `docs/specs/AUDITORIA_2D_A_3D.md`. Piezas del editor: `docs/specs/PLAN_LO_QUE_SE_VE.md`.

## Qué significa «terminado» (se mide, no se opina)
`bash tools/contar_2d.sh` cuenta los restos 2D (cuerpos, áreas, dibujos, cámara, navegación, píxeles, pisos de mentira,
estirón ×5…). **Punto de partida el 2026-11-14: 2.495. Hoy: 2.457. Terminado = 0.** Lo único plano que queda es la interfaz
(menús, HUD, paneles), como en cualquier juego 3D; la vista desde arriba se mantiene como **cámara 3D**.

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
   **Siguiente: tanda 4** (todos los personajes con cuerpo 3D siempre), que esto ya permite sin coste por cuerpo.
   **3b:** pisos = altura real (losas 3D de verdad); se borran `Suelo`/`PisosCasas` como reglas y los niveles de piso.
4. **Personajes 3D siempre:** jugador, vecinos, animales y bandidos son cuerpos 3D todo el tiempo (los lejanos, con
   simulación barata pero en 3D). Se borran `CuerposDelPueblo3D`, `CuerposCercanos3D` y los dibujos planos.
5. **Rutas con navegación 3D** (malla de navegación del mundo y de cada edificio). Se borran las rutas y listas de
   puertas a mano y los atajos de «colocar» vecinos (guardia mensajero, custodia).
6. **Piezas que dicen para qué sirven** (`PLAN_LO_QUE_SE_VE.md`, fases 1–4), ya en 3D: sillas, camas, puestos, la E.
7. **Ver, oír, golpear y la E con rayos y áreas 3D.** Se borran `Vista.gd` como reglas planas y el selector por ángulos.
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
- Cuerpos 3D solo para 24 vecinos a ~8 m; se les quita si se atascan (`CuerposDelPueblo3D.gd`) → tanda 4.
- Dibujos 2D escondidos con capas en 1.ª persona (`WorldStage3D._ocultar_2d_tapado`) → tandas 4 y 8.
- Cama `cama_2` de la comisaría puesta a mano; zapato del caso como «Caja_383» con etiqueta → tanda 6.

## Coste honesto
Mucho: son los cimientos (vecino y pueblo suman ~12.000 líneas pensadas en píxeles). Semanas de trabajo por tandas, no
días. Cada tanda se cierra con el número del contador, sus pruebas y lo que queda.
