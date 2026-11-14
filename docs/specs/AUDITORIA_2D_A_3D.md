# Auditoría: restos del 2D, reglas a mano, código ineficiente e innecesario (2026-11-14)

> Pedida por el usuario. **Solo lectura**: no se tocó código del juego. Los números salen de búsquedas de texto en
> `scripts/`, `scenes/` y `mapa/` (213 archivos, ~84.500 líneas): son aproximados, sirven para ver el tamaño de cada cosa.
> Acompaña a `docs/specs/PLAN_LO_QUE_SE_VE.md` (el plan de las piezas del editor). Nada de aquí está decidido todavía.

## Resumen en una frase
El juego **no es 3D de verdad**: es el juego 2D de siempre (escena 2D, personajes 2D, distancias en píxeles) con el
mundo 3D **pintado encima** y un cuerpo 3D prestado a quien está cerca del jugador. Casi todo lo que hoy hay que arreglar
a mano (sillas, camas, tablón, guardia que no llega, pisos, pistas) sale de mantener **dos mundos a la vez**.
(`CLAUDE.md` §5 dice «mundo 3D de verdad, ya terminado»; `docs/specs/MUNDO_3D.md` lo describe mejor: «cuerpo en 3D,
cerebro en el mapa».)

## Qué SÍ se migró en la semana del 3D (comprobado en el código)
Lo que se ve y lo que pisa el jugador: terreno, edificios e interiores son escenas 3D de tamaño real editables; el dibujo
2D ya no se ve (pero buena parte se sigue creando y se hace transparente: ver C1); el jugador tiene física 3D (gravedad, salto, caída, agua, buceo, pisos); el mapa
se edita en 3D y los edificios ya no se «traducen» desde el mapa viejo. **Lo que no se migró es el «cerebro»:** fue una
decisión escrita del plan («cuerpo en 3D, cerebro en el mapa», híbrido por rendimiento), no un olvido; pero decir «mundo
3D terminado» (`CLAUDE.md` §5) da a entender más de lo que hay.

## A. Cimientos 2D que siguen mandando (lo más grave)
1. **La escena principal es 2D** (`scenes/World.tscn`, raíz `Node2D`): capas de baldosas (`TileMapLayer`), cámara 2D,
   luz de día/noche con `CanvasModulate`, región de navegación 2D. El mundo 3D se dibuja en un `SubViewport` y se pega
   como una imagen (`WorldStageSprite2D`) dentro de esa escena (`WorldStage3D.gd`).
2. **Todos los personajes son cuerpos 2D en píxeles** (`CharacterBody2D`: jugador, vecinos, animales, bandidos). El cuerpo
   3D (`fisica/Cuerpo3D.gd`) es un espejo: solo lo tienen el jugador y, como mucho, **24 vecinos a menos de ~8 m** de él
   (`CuerposDelPueblo3D.gd`); el resto anda «por el mapa». Si un vecino con cuerpo se atasca 5 s, se le quita el cuerpo.
3. **Las paredes de verdad son las 2D.** Las 3D son copias en forma de prisma que se rehacen alrededor de cada cuerpo en
   cada paso (`ChoquesCercanos3D.gd`, radio 110 px). Además hay choques añadidos por código: 16 `add_choque_mundo`,
   9 `choque_en_edificio`, 6 `no_pisar_mundo`.
4. **La altura no es real.** Los pisos son números (`elevation_level` / `player_elevation_level`: 209 usos); el suelo se
   calcula con reglas (`Suelo.gd`, `PisosCasas.gd`), se «cambia de piso a media escalera» y las alturas van en «píxeles
   de altura» con otra escala distinta de la del suelo (`Mapa3D.ALTO` ≠ `Mapa3D.ESCALA`).
5. **Todo se mide en píxeles del mapa:** 289 nombres con `_px`, 532 cálculos de distancia, 51 comparaciones «N × N» a
   mano, 221 conversiones por `Mapa3D`. Sigue vivo el estirón ×5 (`Mapa3D.E`, `Zona.estirar`, «mapa original»,
   `mapa_viejo.gd`, `pos_original`: ~100 menciones).
6. **Ver, oír y alcanzar** se calculan con segmentos 2D y número de piso (`Vista.gd`, 29 usos), no con rayos 3D
   (solo hay 5 rayos 3D en todo el código, y 7 consultas de física 2D).
7. **La tecla E** no mira qué hay bajo la cruz: usa círculos 2D (`Area2D`) y reglas de ángulo e inclinación
   (`InteractionSelector._fp_crosshair_score`: «si miras menos de 0,18 hacia abajo no vale», alcance en píxeles…).
8. **El combate** es 2D: golpe = círculo 2D delante del jugador (`PlayerCombatController._setup_hitbox`), cajas de daño
   2D; las flechas «simulan» la altura.
9. **Rutas de los vecinos:** hechas a mano en 2D (lista de puertas `building_doors` con 59 usos, cruces del río,
   `RutaCuartos.gd`, edificios y cuartos como rectángulos: 347 `Rect2`). No hay malla de navegación 3D. Por eso el guardia
   de hoy tardaba horas o iba y venía, y se «arregló» colocándolo.
10. **Luz, lluvia y sonido:** día/noche con tinte 2D más 37 luces 3D (dos sistemas); la lluvia es un dibujo sobre la
    pantalla (`World._draw_weather_overlay`), llueve igual bajo techo; el sonido no tiene posición (2 emisores 2D, 0 en 3D).
11. **Cada vecino arrastra su versión 2D:** dibujo plano (`Sprite2D` con su `.png`, 61 usos), etiqueta, barra, dos
    áreas 2D… además del muñeco 3D. Funciones como `_set_sprite_pose`, etiquetas flotantes y 38 `z_index`.
12. **Restos del ratón 2D:** 34 usos de la posición del ratón en el mapa (`_is_near(player, mouse_pos…)`),
    `Crosshair2D.gd`, `MOUSE_PICK_PX`.
13. **El código se bifurca por vista:** 48 ramas «si primera persona», 30 «si sin ventana». Lo que se prueba sin
    ventana no es lo que ve el jugador (por eso varias pruebas verdes no vieron fallos reales).

## B. Reglas y datos puestos a mano (amplía las 6 familias del plan)
1–6. Las del plan: dónde se hace algo, qué hace la E (dos sistemas), ~35 zonas de uso, choques por código, objetos
   dibujados por código, excepciones por edificio y por vecino.
7. **Mundo dibujado por código:** 229 cajas y cilindros (`_add_box_2d`, `_add_cyl_2d`), 37 modelos colocados por código,
   143 materiales creados en el código (`WorldStageProps3D`, `WorldStageTerrain3D`, `WorldStage3D`).
8. **Decorado sin nombre en el mapa:** `mapa/Mundo3D.tscn` (3.375 piezas, 1,1 MB) lleva 305 «Caja_N» horneadas del
   código viejo; no se sabe qué es cada una (el zapato del caso era «Caja_383»; el tablón, «Caja_59»).
9. **Datos dentro del código:** el Caso I entero como diccionarios (`DetectiveCaseData.gd`), oficios y sus puestos
   (`trade_configs`), aspecto por número de oficio (`CharacterAvatar3D`), 115 nombres de edificio escritos a mano,
   873 ramas por oficio, 57 nombres propios de vecinos, 206 precios escritos dentro de frases.
10. **Estado en diccionarios sueltos:** ~3.300 menciones de `Dictionary` y 378 «metas» frente a solo 3 `Resource`.
    Un nombre mal escrito no da error: simplemente no funciona (contradice `CLAUDE.md` §4).
11. **Textos:** ~1.400 emojis dentro de frases del juego; 156 teclas escritas en los textos («[E]») aunque las teclas se
    pueden cambiar (`Teclas.gd`); 187 teclas fijas fuera de `Teclas.gd`.
12. **Interfaz hecha línea a línea:** 1.474 colores y 117 tamaños de letra escritos a mano, sin tema común
    (`DetectiveUI.gd`: 3.528 líneas; `ui_root.gd`: 1.589).

## C. Código ineficiente o frágil
1. **Los dibujos 2D se siguen creando y luego se hacen transparentes** (`WorldStageProps3D._sync_2d_flat_visuals`
   pone a 0 la opacidad de suelos y muros planos de cada edificio, muebles planos, árboles, rocas y objetos; los
   personajes se esconden con un truco de capas). Quitado el 2026-11-14: suelos y muros planos de los edificios
   (`_construct_solid_building`). Quedan: muebles, naturaleza, objetos y personajes planos. La imagen 3D se rehace
   siempre y las piezas hechas por código no comparten malla (prioridad 1 de `FALLOS_VISIBLES.md`).
2. **Llamadas «a ciegas»:** 858 `has_method`, 655 `.call("…")`, 1.160 variables sin tipo, 60 funciones sin tipo de
   retorno. Más lento y esconde errores (el tipado al 100 % de `CLAUDE.md` no se cumple).
3. **Buscar en vez de saber:** 197 `get_first_node_in_group` (103 al jugador, 69 al gestor del pueblo), 167
   `get_nodes_in_group`, 206 rutas de nodo escritas a mano, 89 `load("res://…")` en plena partida.
4. **Objetos gigantes por herencia en cadena:** el pueblo (`VillageManagerBase → Economy → Police → Social → Manager`,
   ~6.100 líneas) y el vecino (`VillageNPCBase → Duties → Social → Work → NPC`, ~6.100). Todo conoce a todo.
5. **Funciones enormes:** 47 de más de 150 líneas (la mayor, 470: `NPCDialogue.on_dialogue_action`), 137 de más de 80;
   555 líneas de más de 200 caracteres; 125 líneas con 7 o más niveles de sangría.
6. **Azar sin control:** 429 tiradas sin semilla → pruebas que fallan «al azar» (la «S2» de `verify_all`).
7. **Sondas de rendimiento dentro del juego** (67 `perf_on`) y comentarios que hacen de historial (199 con fecha, 320
   con claves «Paso 3b / P7 / G3»).

## D. Innecesario o muerto
1. **En la escena principal** (corregido el 2026-11-14 al hacer la tanda 0): estaban muertas las tres capas de baldosas
   (con ~29.000 líneas de datos) y la caja de diálogo vieja → **quitadas**. **No** eran de prueba, sino contenido vivo
   que hay que pasar a 3D: los bandidos de la ciénaga (`DummyEnemy`, `FastEnemy`, 2 `BanditEnemy`), el vigía del oeste
   («Guia», `scenes/npc.gd`), la caja, el barril, el muro débil y el arma del suelo (tienen su dibujo 3D).
2. **Escenas que nadie usaba** (`Mundo3D.antes-3d.tscn`, `WoodenDoor.tscn`, `Playground.tscn`, `Entities/Player.tscn`):
   **borradas** en la tanda 0. Revisar todavía `mapa/pincel_nucleo.gd`.
3. **Sistemas dormidos por el modo demo** (109 comprobaciones): bajos fondos, secta, linaje, migración, clanes, fama,
   alcalde, préstamos, enfermedades, club, trabajos nocturnos, ecosistema… **más de 10.000 líneas** que viajan con el
   juego, cada una con sus posiciones a mano. Decisión del usuario: ¿se archivan hasta después del Caso I o se migran?
4. **Raíz del proyecto desordenada:** `gallina_re4.*` sueltos, carpetas `assests` (1,2 GB, mal escrita) y `assets`,
   `archived_systems` (25 scripts), `protagonista_temporal`, `mis_recursos`, `Documentos`, `ideas sueltas.md`,
   `setup_sword.gd.uid` sin su script.
5. **Herramientas de un solo uso ya pasadas** (`convertir_escala_0b.py`, `hornear_caminos.gd`, `repoblar_bosque.gd`,
   `vigilante_noche.sh`…) y **pruebas:** 88 archivos; `verify_all.gd` (7.364 líneas) está parada en «V4».
6. **Documentos:** `docs/` pesa 262 MB (capturas) y `docs/archivo/` tiene 48 archivos.

## E. Lo que un jugador nota como «raro para un juego 3D»
- La E a veces no coge lo que tienes bajo la cruz, o exige mirar al suelo o apuntar a una esquina.
- Avisos como líneas en una esquina (190 llamadas a avisos de texto) y emojis en un mundo medieval.
- Vecinos lejanos sin cuerpo (pueden atravesar cosas), que tardan horas en llegar o aparecen colocados.
- Pisos «por niveles»: lo de arriba y lo de abajo no se ven ni se oyen de forma natural.
- Llueve bajo techo; el sonido no viene de ningún sitio; de noche hay dos sistemas de luz.
- Textos que dicen «[E]» aunque hayas cambiado la tecla.

## Orden recomendado (para decidir con el usuario; nada empezado)
0. **Limpieza sin riesgo** (D1, D2, D4, D5): poco. No cambia el juego.
1. **Decidir los sistemas dormidos** (D3): archivarlos ahorra migrar >10.000 líneas que hoy no se juegan.
2. **Piezas que dicen para qué sirven** (plan guardado, fases 1–4): es la base de datos que hace falta de todos modos.
3. **Un solo mundo, el 3D** (A1–A5, A9): escena 3D, personajes siempre con cuerpo 3D, paredes y suelos de las propias
   escenas, navegación 3D, metros. Es lo más grande («mucho», por tandas, con la partida automática del Caso I en verde
   en cada tanda). Al acabar se borran `ChoquesCercanos3D`, `CuerposDelPueblo3D`, `Suelo`, los niveles y el ×5.
4. **Sentidos y E con rayos** (A6–A8, A12) y **luz, lluvia y sonido 3D** (A10).
5. **Datos fuera del código** (B9–B12) y **partir los objetos gigantes** (C3–C5), según se toque cada sistema.
