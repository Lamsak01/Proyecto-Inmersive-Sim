# Plan: pasar el mundo a 3D de verdad (física, alturas, agua)

> **Decisión del usuario (2026-11-10):** el juego deja de calcularse sobre un tablero plano. Quiere exploración vertical,
> profundidades, cuevas, lagos y **nadar y bucear** (habrá casos con pistas en el río y el lago). Quiere hacerlo **ya**,
> antes de que el juego crezca. No volver a proponer quedarse en 2D ni «trucos de capas» como solución final.
>
> **Estado (2026-11-10):** plan aprobado por el usuario. **Pasos 0, 0b, 1, 2a–2c, 3a, 4 y 5a hechos** en la rama `mundo-3d` (mundo 3D
> uniforme y en metros; cuerpo 3D; posada de dos plantas; club y alcantarillas bajo tierra; daño por caída; nadar; cuerpos
> de contacto de vecinos y animales; vista con alturas). Aplazados por el usuario: 2d (guardado v4), 2e (casa) y 3b–3c
> (bucear). El paso 4 se hizo como opción A (la B, cuerpos completos y caminos 3D, queda pendiente). Paso 5 hecho. Siguiente: paso 6 (limpieza) o lo aplazado (2e casa, 3b bucear, 4 opción B), según el usuario.
> Autor: Claude Code (portátil). Cualquier agente que siga: lee este documento entero antes de tocar nada y apunta
> cada paso en el **Registro** (§10).

---

## 1. Cómo está hecho hoy (comprobado en el código el 2026-11-10)

- **Lo que se ve es 3D; lo que se calcula es 2D.** El jugador (`Player.gd`) y los vecinos (`VillageNPCBase.gd`) son
  `CharacterBody2D`. Andan, chocan, se ven y se oyen sobre un mapa plano en píxeles. `WorldStage3D` (≈11.400 líneas
  en `scripts/visuals/`) construye una maqueta 3D encima y copia las posiciones 2D a muñecos 3D en cada fotograma.
  En todo el proyecto no hay ni un `CharacterBody3D`.
- **El editor del mapa sí es 3D** (`mapa/Mundo3D.tscn`, desde el 2026-11-09/10). Lo que se mueve allí se traduce al mapa 2D
  con las «anclas» (`mapa/anclas.gd`). El río todavía se edita en el editor 2D (`mapa/EditorMapa.tscn`).
- **Pisos y sótanos son «capas»:** `elevation_level` (−1 sótano/alcantarillas, 0 calle, +1 piso alto), con 146 usos en 27
  archivos. Dos sitios en el mismo (x, y) a distinta altura se distinguen solo por ese número.
- **⚠ El 3D está estirado a propósito.** `WorldStageBase3D.to_3d()`: x = px·0,02; z = px·0,02 / sin 58° (×1,18);
  altura = px·0,02 / cos 58° (×1,89). Se hizo para que la cámara inclinada cuadrara con el mapa 2D. Los muñecos usan escala
  igual en los tres ejes (`STAGE_K = 0,40`). Con física real hay que decidir qué hacer con esto (§5, paso 0).
- **Tamaño:** 171 scripts y unas 87.000 líneas. Lo físico está concentrado; las posiciones de mapa (`Vector2`, 5.284 usos
  en 107 archivos) están por todas partes.

## 2. Idea central: «cuerpo en 3D, cerebro en el mapa»

Reescribir 87.000 líneas para cambiar `Vector2` por `Vector3` rompería el juego durante semanas. No hace falta:

- **Todo lo físico pasa a 3D:** moverse, chocar, gravedad, saltar, caer, escaleras, nadar, rayos de vista y de oído,
  golpes, flechas, puertas, muebles y agua. La autoridad sobre «dónde está y qué toca» es el cuerpo 3D.
- **El cerebro sigue leyendo coordenadas de mapa** (x, z del mundo, en píxeles de mapa como hoy) más una **altura real**.
  Horarios, relaciones, economía, crímenes, casos, diálogos, guardado y paneles no cambian. Es como un GPS: el vecino
  sigue pensando «voy a la panadería (412, 54)», pero quien anda y sube escaleras es el cuerpo 3D.
- **Cómo se consigue con poco código:** un solo componente nuevo, `scripts/fisica/Cuerpo3D.gd`, que cuelga de cada actor
  (jugador, vecino, animal). Lleva un `CharacterBody3D` dentro del escenario 3D, hace `move_and_slide()` en 3D y, después
  de cada paso, copia (x, z) → `global_position` del nodo 2D y la altura → una variable `altura`. Los 1.060 usos de
  `global_position` siguen funcionando sin tocarlos. El nodo 2D se queda como «ficha» invisible sin colisiones propias.
- **Una sola conversión, en un solo sitio:** `scripts/fisica/Mapa3D.gd` (estático): `a_3d(pos_mapa, altura)`,
  `a_mapa(v3)`, `distancia(a, b)` con altura. Hoy hay conversiones repartidas (`to_3d`, `to_3d_flat`, `_a_mapa_2d`,
  `terrain_height_px`, anclas); al final todas llaman a esta.
- **Las capas desaparecen poco a poco:** `elevation_level` pasa a calcularse a partir de la altura real (por ejemplo,
  debajo del suelo = −1). Así los 146 usos siguen funcionando mientras se sustituyen por `distancia()` con altura.

## 3. Inventario completo de lo que depende del plano («que no se olvide nada»)

Marca ☑ cuando esté pasado a 3D y probado. Archivos comprobados con `grep` el 2026-11-10.

| # | Pieza | Hoy (2D) | Archivos | Paso |
|---|---|---|---|---|
| 1 | Jugador: andar, correr, rodar, sigilo, saltar | `CharacterBody2D` + `move_and_slide` | `Player.gd`, `PlayerMovementController.gd` | 1 |
| 2 | Choques con edificios, muros, puertas, muebles | `StaticBody2D` generados | `VillageManagerBase.gd` (513, 567, 1263), `VillageWorldBuilder.gd`, `VillageClub.gd`, `VillageUnderworld.gd` | 1 |
| 3 | Choques con árboles, rocas y decorado del editor | casco convexo 2D de la malla 3D | `WorldStageTerrain3D.gd` (≈1556), `WorldStageProps3D.gd` | 1 |
| 4 | Suelo y desniveles | `terrain_height_px` solo visual | `WorldStageBase3D.gd`, `WorldStageTerrain3D.gd` | 1 |
| 5 | Colisión del río y del lago | `StaticBody2D` (`river_col_body`, `_build_water_collision`) | `VillageWorldBuilder.gd` (659), `FishingSpot.gd` (382) | 3 |
| 6 | Escaleras, pisos altos, sótanos, alcantarillas | `elevation_level` + escaleras «de botón» | 27 archivos (ver §1); `VillageTavern.use_stairs`, `VillageHousing.interact_home_stairs`, `VillageUnderworld.gd` | 2 |
| 7 | Vecinos: movimiento y rutas | `CharacterBody2D`, `_move_towards_point`, `_avoid_outdoor_buildings`, `_route_internal_*`, cruces del río | `VillageNPC*.gd`, `VillageManagerBase.gd` | 4 |
| 8 | Vecinos: separación, empujar fuera de muebles, puertas | `sanitize_npc_separation_pos`, `push_out_of_furniture`, `get_doorway_clearance_nudge`, `_enforce_npc_personal_space` | `VillageManagerBase.gd`, `VillageNPCSocial.gd` | 4 |
| 9 | Animales, mascotas, ganado, caballo, carro, enemigos | `CharacterBody2D` / `Area2D` | `WildAnimal.gd`, `DomesticPet.gd`, `LivestockAnimal.gd`, `PlayerHorse.gd`, `PlayerCart.gd`, `Raider.gd`, `DummyEnemy.gd`, `MillKidnapper.gd`, `EnemyAI.gd`, `scenes/npc.gd` | 4 |
| 10 | Navegación de enemigos | `NavigationAgent2D`, región de navegación 2D en tiempo real | `EnemyAI.gd`, `World.gd` | 4 |
| 11 | Vista (línea de visión) y conos | `intersect_ray` 2D, `VisionCone2D` | `EnemyAI.gd`, `DetectionArea.gd`, `VisionCone2D.gd`, recuerdos visuales de vecinos | 5 |
| 12 | Oído y ruido (sigilo) | rayos 2D de oclusión | `AudioManager.gd` | 5 |
| 13 | Golpes, cuerpo a cuerpo, empujar, bloquear | `Hitbox`/`Hurtbox` `Area2D` | `Hitbox.gd`, `Hurtbox.gd`, `PlayerCombatController.gd`, `CombatFeel.gd` | 5 |
| 14 | Flechas y disparos | `ArrowProjectile` 2D | `ArrowProjectile.gd` | 5 |
| 15 | Interactuar ([E], objetivo bajo la mira) | `Area2D` + proyección | `InteractionSelector.gd`, `interact_area.gd`, `WorldInteractableProp.gd`, `Crosshair2D.gd` | 5 |
| 16 | Objetos del mundo (cosechar, romper, recoger, pescar, huertos, gallinero, campamento) | `Area2D`/`StaticBody2D` | `HarvestableNode.gd`, `DestructibleObject.gd`, `FishingSpot.gd`, `FarmPlot.gd`, `ChickenCoop.gd`, `CampSite.gd`, `WeaponPickup.gd`, `VillageCulture.gd` | 5 |
| 17 | Ratón en el mundo | `get_global_mouse_position` (14 usos, 13 archivos) | combate, selector, vecinos (letrero) | 5 |
| 18 | Huellas y manchas de sangre | posiciones 2D | `update_entity_blood_footprints` (`VillageManager*`) | 5 |
| 19 | Mapa pequeño, mapa grande, escena del crimen del detective | dibujan desde (x, y) | `valley_map`, `DetectiveUI.gd` | 6 (siguen con (x, z)) |
| 20 | Guardar y cargar | posiciones `Vector2` + `elevation_level` | `GameManager.gd` y los `to_save_dict` | cada paso (versión 4 en el paso 2) |
| 21 | Editor del mapa y anclas | 3D → 2D con `_a_mapa_2d` y `anclas.gd` | `mapa/*.gd`, `WorldStageTerrain3D._cargar_decoracion_editor` | 0 y 6 |
| 22 | Río en el editor 2D | `mapa/EditorMapa.tscn`, `rio_forma.gd` | `mapa/` | 6 |
| 23 | Vista 2D, vista cenital 3D y mapa 2D de fondo | `use_3d_characters`, F9, `TileMapLayer`, `Parallax2D` | `World.tscn`, `World.gd`, `WorldStage3D.gd`, `CharacterAvatar3D.gd` | 6 (decide el usuario, §7) |
| 24 | Pruebas automáticas | colocan actores con `Vector2` y miran capas | `tools/tests/verify_all.gd` (7.513 líneas) y las demás | cada paso |
| 25 | Rendimiento | física 2D barata; 44 vecinos | — | cada paso (medir, §6) |

## 4. Reglas de la transición (para cualquier agente)

1. **Rama propia:** todo se hace en la rama `mundo-3d`. `main` sigue jugable. Se mezcla a `main` solo al cerrar un paso con
   todas sus pruebas en verde, con permiso del usuario. Antes de empezar: etiqueta `antes-de-mundo-3d` en `main`.
2. **Nada de funciones nuevas** (casos, sistemas, mapa) en `main` mientras dure, salvo arreglos urgentes: si no, la mezcla se
   complica. Antigravity no debe tocar el movimiento ni la física mientras tanto.
3. **Un paso cada vez**, y cada paso deja el juego jugable de principio a fin.
4. **Código mínimo y en un solo sitio:** toda conversión mapa ↔ 3D va por `Mapa3D.gd`; toda física de actor por `Cuerpo3D.gd`.
   Al pasar una pieza, se **borra** su versión 2D en el mismo paso (nada de dos caminos vivos a la vez, salvo lo indicado).
5. **Formas de choque sencillas:** cajas y cápsulas generadas una vez al construir el mundo, no mallas exactas (rendimiento).
6. **La partida guardada del usuario no se pierde:** cada cambio de formato sube `version` en `GameManager.save_game` y
   `load_game` convierte las partidas viejas.
7. **El mapa editado por el usuario no se pierde:** cualquier cambio de escala convierte `mapa/Mundo3D.tscn` con una
   herramienta y hace copia antes (`mapa/Mundo3D.antes-3d.tscn`).
8. **Ordenar mientras se pasa a 3D (petición del usuario, 2026-11-10):** cada archivo que se toque en la transición se deja
   ordenado **por lo que hace**: carpetas por tema (`scripts/fisica/`, `scripts/vecinos/`…), archivos de menos de ~600
   líneas, una función = una tarea, y al principio de cada archivo dos o tres líneas en español sencillo que digan para qué
   sirve. Se borra el código muerto y lo repetido. **Solo lo que se toca en cada paso** (reordenar todo de golpe rompería
   el juego); lo demás se ordena cuando le toque. Cada reorganización deja el juego igual y pasa las pruebas antes de seguir.
9. **Mapa del código:** `docs/MAPA_DEL_CODIGO.md` (se crea en el paso 0) explica en español sencillo qué hace cada carpeta y
   cada archivo, para que el usuario sepa dónde está lo que quiere arreglar. Se actualiza en cada bloque que mueva archivos.
10. **Manuscrito de cada cambio:** `docs/MANUSCRITO_MUNDO_3D.md`, una entrada por bloque, para personas: qué cambió en el
    juego, por qué, qué archivos (y de dónde a dónde se movió cada cosa), cómo se probó y cómo deshacerlo. El Registro (§10)
    es el resumen de una línea; el manuscrito es el detalle.
11. **Al cerrar cada paso:** pruebas de §6, capturas, entrada en el Registro (§10) y en el manuscrito, `CHANGELOG.md`, `docs/HANDOFF.md`,
   diario de `GameVault/06_Diario/` y commit.

## 5. Pasos

Cada paso: qué se hace, cuándo está terminado y cómo volver atrás. «Volver atrás» siempre es posible con git
(`git checkout antes-paso-N`), porque cada paso empieza con su etiqueta.

### Paso 0 — Preparación (sin cambios visibles)
- Crear `docs/MAPA_DEL_CODIGO.md` y `docs/MANUSCRITO_MUNDO_3D.md` (§4, reglas 9 y 10).
- Rama `mundo-3d` y etiqueta `antes-de-mundo-3d`.
- **Medidas de referencia** guardadas en el Registro: `perf_zonas.gd`, `verify_all.gd`, `atascos_vecinos.gd -- 6`,
  `guardado_largo.gd` y capturas fijas de 6 sitios en 1.ª persona (plaza, río, bosque, molino, mansión, interior con piso alto).
- **Decidir la escala** (con capturas al usuario):
  - Opción A, recomendada: el mundo 3D **se queda como se ve hoy**; las pruebas de física trabajan en ese espacio. Solo
    cambia la fórmula para pasar de mapa a 3D, que queda en un solo sitio. El estiramiento norte-sur (×1,18) se apunta para
    las distancias del cerebro (`Mapa3D.distancia` lo corrige). No se mueve nada del mapa del usuario.
  - Opción B: volver el mundo uniforme (1 unidad = 1 m). Más limpio, pero cambia proporciones de casas y obliga a convertir el
    mapa editado. Solo si las capturas muestran casas deformadas.
- Crear `Mapa3D.gd` y hacer que `to_3d`, `to_3d_flat`, `_a_mapa_2d` y las anclas lo usen (mismo resultado, número a número).
- Prueba nueva `tools/tests/fisica_3d.gd` (vacía al principio; cada paso le añade lo suyo).
- **Terminado cuando:** juego idéntico (capturas iguales), `verify_all` en verde y medidas guardadas.

### Paso 0b — Escala uniforme (decisión del usuario 2026-11-10: opción B)
Objetivo: un mundo 3D con las mismas proporciones en los tres ejes y **1 unidad = 1 metro**. El motor de física está pensado
para metros (gravedad 9,8, márgenes de choque) y hoy una persona mide menos de una unidad, demasiado pequeña para chocar bien.
- **Medida de partida:** la altura de una persona (muñeco actual, ojos a `FP_EYE_HEIGHT_PX`) = 1,75 m. De ahí sale el nuevo
  `Mapa3D.ESCALA` (unidades por píxel). Medir antes de cambiar nada y apuntarlo aquí.
- **Ejes:** z deja de dividirse por sin 58° (el norte-sur se acorta ~15 % y lo redondo queda redondo). Las alturas en
  píxeles se conservan como se ven hoy: su factor queda en `Mapa3D` con nombre propio (una casa no se aplasta).
- **Lo que pasa por `Mapa3D` se ajusta solo.** El resto de números 3D escritos a mano (cámara, brazos, muñecos `STAGE_K`,
  niebla, luces, alcances de vista, sombras, distancias de LOD) se multiplican por el mismo factor, uno a uno, apuntados
  en el manuscrito.
- **Mapa del usuario (`mapa/Mundo3D.tscn`):** copia `mapa/Mundo3D.antes-3d.tscn` y herramienta que convierte cada posición;
  comprobación: cada pieza cae en el **mismo sitio del mapa del pueblo** que antes (las anclas dan las mismas x, y).
- Volver a hornear lo horneado (`tools/hornear_*.gd`).
- **El cerebro no cambia:** posiciones de mapa, guardado y vecinos iguales; el guardado no sube de versión.
- **Terminado cuando:** `fisica_3d` comprueba proporciones (una caja de 10×10 px es cuadrada; una persona mide 1,75 u),
  sondeo de edificios 29/29, `verify_all` verde, fps no peor que la referencia y fotos nuevas revisadas por el usuario
  (ya no serán iguales: se guardan como `referencia_paso0b`).
- Coste estimado: 1–2 sesiones más. Volver atrás: etiqueta `antes-paso-0b`.

### Paso 1 — El protagonista en 3D
- `Cuerpo3D.gd` para el jugador: cápsula 3D, gravedad, saltar de verdad, caer, subir peldaños y rampas.
- **Mundo sólido en 3D:** cajas de choque para paredes, puertas (abiertas/cerradas/atrancadas), muebles, árboles, rocas y
  decorado del editor, generadas desde lo que ya construye `WorldStage3D`. El suelo con desniveles es sólido.
- Se borran los choques 2D que ya no hacen falta para el jugador (siguen los que usan los vecinos hasta el paso 4).
- La 1.ª persona sigue al cuerpo 3D (cámara a la altura de los ojos de verdad).
- **Terminado cuando:** puedes recorrer todo el pueblo, entrar en casas, cruzar puentes y saltar sin atravesar nada ni
  quedarte atascado; los vecinos te siguen viendo y hablando igual; `verify_all` en verde; rendimiento no peor que la referencia.
- **Riesgo:** atascarse en esquinas o puertas estrechas. Se prueba con un recorrido automático por todas las puertas.
- **Cómo se hizo (2026-11-10):** en vez de generar los choques desde el dibujo 3D, se copian en 3D los choques del mapa
  que hay cerca del cuerpo (ya estaban ajustados: huecos de puerta, muebles, puertas que se abren…). El suelo, hasta el
  paso 2, es una losa invisible a la altura de siempre. Detalle en `docs/MANUSCRITO_MUNDO_3D.md` (pasos 1a y 1b).

### Paso 2 — Alturas de verdad: pisos, sótanos y caídas
- Escaleras de verdad en lugar de «capas de botón»; pisos altos y sótanos con suelo físico.
- `elevation_level` pasa a calcularse desde la altura real (compatibilidad); los testigos y el oído usan altura.
- Daño por caída (lo decide el usuario: cuánto).
- Guardado versión 4: se guarda la altura; las partidas viejas se convierten.
- Deja preparado el sitio para **cuevas**: un lugar bajo el suelo con su entrada, igual que un sótano grande.
- **Terminado cuando:** subes y bajas a pie en taberna, casas y alcantarillas; los vecinos de abajo no «ven» lo de arriba;
  guardar/cargar arriba y abajo funciona; pruebas en verde.
- **Trozos (2026-11-10):** 2a posada con dos plantas de verdad (hecho) · 2b club y alcantarillas de verdad bajo
  tierra (hecho) · 2c caídas y daño por caída (hecho: «realista») · 2d guardado versión 4 · 2e piso alto y sótano de tu casa.

### Paso 3 — Agua: nadar y bucear
- Volúmenes de agua 3D para el río y el lago (desde la forma del río que ya existe).
- Nadar en superficie (más lento, gasta aguante), bucear (cámara bajo el agua, aire limitado, ahogarse), salir por la orilla.
- **Pistas en el fondo:** objetos que solo se encuentran buceando (preparado para los casos; el usuario decide cuáles).
- Se borran las colisiones 2D del río y del lago.
- **Trozos:** 3a nadar en superficie (hecho) · 3b bucear (aire, ahogarse) · 3c pistas en el fondo: **aplazados por el usuario** (2026-11-10, «déjalo para luego»;
  falta su decisión sobre cuánto aire y si al acabarse te desmayas o mueres).
  Los choques 2D del agua se quedan hasta el paso 4: el cuerpo 3D ya no los copia, pero frenan a los vecinos.
- **Terminado cuando:** se puede cruzar el río nadando, bucear en el lago y recoger un objeto del fondo; pruebas en verde.

### Paso 4 — Vecinos y animales en 3D
- Vecinos, animales, caballo, carro y enemigos con `Cuerpo3D.gd`. Sus rutas siguen saliendo del cerebro, pero el
  movimiento, las escaleras y los choques son 3D. Navegación 3D (malla de caminos) donde haga falta (enemigos, pisos).
- Se borran `sanitize_npc_separation_pos`, `push_out_of_furniture` y los choques 2D que sustituye la física 3D.
- **Trozos (aprobados por el usuario, 2026-11-10):** 4a vecinos por la escalera de la posada (hecho: ya subían andando;
  arreglado el escalón de golpe al final) · 4b cuerpo 3D solo para los vecinos cercanos al protagonista (los lejanos
  siguen en el mapa) · 4c animales, caballo y carro (hecho: cuerpo de contacto para bandidos y animales grandes,
  decisión del usuario; caballo y carro ya iban con el cuerpo del protagonista) · 4d quitar los empujones viejos cuando no hagan falta.
- **Decisión del usuario (2026-11-10): «A por ahora, pero quiero B luego».** Hallazgo: los vecinos no chocan con nada en
  el mapa (siguen sus rutas como un tren por sus vías y el pueblo los recoloca si se salen) y el protagonista los
  atravesaba. **A (hecho en 4b):** cuerpo 3D «de contacto» para los vecinos cercanos, que sigue al vecino; el
  protagonista ya no los atraviesa. **B (pendiente, obligatorio más adelante):** cuerpos 3D completos que chocan con
  paredes y muebles, con un buscador de caminos 3D (malla de caminos por pisos y escaleras); hará falta para enemigos
  que persigan por pisos. No olvidarlo al cerrar el paso 4.
- **Riesgo alto: atascos y rendimiento** (44 vecinos con física 3D). Se mide en cada sub-bloque; la simulación de los
  lejanos («a ratos») se mantiene.
- **Terminado cuando:** 0 atascos en `atascos_vecinos.gd -- 6`, vida social de 60 días (`social_sim.gd`) sin cambios
  raros, rendimiento no peor que la referencia, `verify_all` en verde.

### Paso 5 — Sentidos, combate e interacción en 3D
- Vista con alturas (una pared o un piso tapan de verdad), oído con oclusión 3D, conos de visión.
- **Trozos (2026-11-10):** 5a vista (hecho: `Vista.gd`; sin rayos 3D: paredes y puertas del mapa + losas de los suelos
  altos, que es lo mínimo y vale mientras el único sitio con dos plantas de verdad sea la posada) · 5b oído (hecho: a través de un suelo un tercio, bajo tierra un décimo) · 5c golpes,
  flechas y balas (hecho: golpes por altura de los pies; flechas y balas con altura y pendiente de la mirada) · 5d interacción con lo que miras (hecho: con [E] se llega a lo que está a tu altura).
- Golpes, empujones, bloqueo, flechas y balas en 3D (se puede disparar hacia arriba o abajo).
- Interacción con lo que está bajo la mira en 3D; recoger, cosechar, pescar, romper; huellas y sangre con altura.
- **Terminado cuando:** sigilo, combate, robo, testigos y el Caso I se comportan como antes (pruebas de bloques de crimen
  y detective de `verify_all` en verde).

### Paso 6 — Limpieza final
- Borrar el tablero 2D sobrante: `TileMapLayer`, fondo `Parallax2D`, colisiones 2D, modo 2D de personajes y, si el usuario
  lo decide, la vista cenital (§7).
- Río y lago editables en el editor 3D (`mapa/Mundo3D.tscn`); retirar el editor 2D del río.
- Mapas y escena del crimen leyendo (x, z).
- Documentación al día (`HANDOFF.md`, `CONTROLES.md`, este plan cerrado) y ronda completa de pruebas.

## 6. Pruebas de cada paso (y cuánto tardan)

| Prueba | Para qué | Tiempo |
|---|---|---|
| `verify_all.gd` | todo el juego | ~15 min |
| `fisica_3d.gd` (nueva) | lo físico de cada paso: recorrido por todas las puertas, escaleras, agua | ~3–5 min |
| `atascos_vecinos.gd -- 6` | vecinos atascados | ~5 min |
| `guardado_largo.gd` | guardar/cargar 7 días | ~5 min |
| `social_sim.gd` | vida social 60 días (pasos 4–5) | ~5 min |
| `perf_zonas.gd` (con ventana) | rendimiento por zonas | ~5 min |
| capturas fijas (con ventana) | que se ve igual o mejor | ~3 min |

## 7. Decisiones que tiene que tomar el usuario (preguntar en su paso, no antes)

1. **Escala** (paso 0): ~~A o B~~ → **B, uniforme** (usuario, 2026-11-10). Ver paso 0b.
2. **Vista desde arriba** (paso 6): ~~¿se mantiene?~~ → **se queda por ahora** (usuario, 2026-11-11).
3. **Daño por caída** (paso 2): ~~cuánto~~ → **realista** (usuario, 2026-11-10): duele desde 3 m, mata a 8 m; además hiere partes del cuerpo (piernas sobre todo); habrá mejoras que lo reduzcan.
4. **Aire bajo el agua** (paso 3): ~~cuánto~~ → **30 segundos; al acabarse pierdes vida hasta morir** (usuario, 2026-11-11).
5. **Cuevas** (después del paso 2): dónde y cuántas; es diseño de mapa, no de esta transición.

6. **Noche del 2026-11-11 (usuario, antes de acostarse):** terminar la conversión sin él: opción B de vecinos (si los 44 con
   cuerpo completo bajan la fluidez, híbrido: cuerpo completo solo los cercanos), piso alto y sótano de su casa (2e),
   bucear (3b) y la limpieza (paso 6) que no necesite decisiones. **Mejorar el rendimiento todo lo posible y dejarlo
   todo anotado.** Nada a `main` hasta que lo pruebe.

## 8. Riesgos y cómo se evitan

| Riesgo | Qué se nota | Cómo se evita |
|---|---|---|
| Se rompe todo a medias | juego injugable | rama `mundo-3d`, un paso cada vez, etiqueta antes de cada paso |
| Atascos en puertas y esquinas | jugador o vecinos bloqueados | cajas de choque sencillas, recorrido automático por todas las puertas, prueba de atascos |
| Más lento | menos fps | medir en cada paso contra la referencia; formas simples; vecinos lejanos «a ratos» |
| Partidas guardadas inservibles | no carga | versión de guardado + conversión, probada con `guardado_largo` |
| Mapa editado por el usuario descolocado | casas movidas fuera de sitio | opción A de escala; si no, herramienta de conversión con copia |
| Pruebas viejas que ya no valen | falsos fallos | se adaptan en el mismo paso, explicando por qué en el Registro |
| Dos sistemas vivos a la vez | errores raros | se borra lo 2D en el mismo paso en que se sustituye |
| Cambio de agente a mitad | trabajo duplicado o perdido | este documento + Registro al día al terminar cada bloque |

## 9. Estimación de tiempo y de coste

Contado en **sesiones de trabajo como la del 2026-11-10** (unas 4–6 horas de Claude Code trabajando, con pruebas).

| Paso | Sesiones | Notas |
|---|---|---|
| 0 Preparación | 0,5–1 | sobre todo medir y decidir la escala |
| 1 Protagonista 3D | 2–3 | lo más visible; generar todo el mundo sólido |
| 2 Alturas | 1,5–2,5 | escaleras, pisos, sótanos, guardado v4 |
| 3 Agua | 1–1,5 | nadar, bucear, pistas en el fondo |
| 4 Vecinos y animales | 3–4 | el más arriesgado (atascos, rendimiento) |
| 5 Sentidos y combate | 2–3 | muchas piezas pequeñas |
| 6 Limpieza | 1–1,5 | borrar lo 2D, río en el editor 3D |
| **Total** | **11–17 sesiones** | con imprevistos, más cerca de 17 |

**Tokens (aproximado):** una sesión larga como la de hoy ronda **15–30 millones de tokens leídos** (la mayoría, contexto
repetido que se cobra más barato por caché) y **0,2–0,4 millones escritos**. Para toda la transición:
**unos 170–500 millones leídos y 3–6 millones escritos.** Depende mucho de cuántas pruebas largas y capturas haga falta repetir.
Es una estimación: se apuntará el gasto real de cada paso en el Registro para corregirla.

## 10. Registro (rellenar al terminar cada bloque: fecha, agente, qué, pruebas, commit)

| Fecha | Agente | Paso / bloque | Qué se hizo | Pruebas | Commit |
|---|---|---|---|---|---|
| 2026-11-10 | Claude Code (portátil) | Plan | Inventario y plan escritos; aprobados por el usuario | — | 031f68a |
| 2026-11-10 | Claude Code (portátil) | Paso 0 | Etiqueta `antes-de-mundo-3d`, rama `mundo-3d`; `scripts/fisica/Mapa3D.gd` (conversión única; ~20 copias fuera); pruebas `fisica_3d.gd` y `capturas_fijas.gd`; fotos de referencia; `MAPA_DEL_CODIGO.md` y `MANUSCRITO_MUNDO_3D.md`; arregladas 3 cosas que ya fallaban antes (`hornear_edificios.gd` no compilaba; pruebas `rio_editor_juego` y `pincel_mapa` anticuadas) | fisica_3d ✅ 7/7 · capturas iguales (peor 0,38 %, ruido 0,8 %) · verify_all ✅ · guardado_largo ✅ · sondeo edificios 29/29 ✅ · río ✅ · pincel ✅ | (este commit) |
| 2026-11-10 | Claude Code (portátil) | Paso 0b | Escala uniforme en metros: `Mapa3D` (ESCALA 0,056, ALTO, K = 2,8, vista de arriba a 62,08° con imagen estirada); escenario, luces, niebla, texturas, partículas y muñecos ajustados; mapa del usuario convertido (`tools/convertir_escala_0b.py`, copia `mapa/Mundo3D.antes-3d.tscn`); fotos de edificios rehechas; arreglo de vecinos encimados en las puertas | fisica_3d ✅ 12/12 (vista de arriba cuadra: 0,14 px) · sondeo 29/29 ✅ · río ✅ · pincel ✅ · verify_all ✅ (falló 2 veces por la puerta; tras el arreglo ✅) · atascos 0 en 6 h ✅ · fps igual que la versión anterior medida a la vez · fotos nuevas en `referencia_paso0b` (desde arriba: 9,9 % distinto, casi igual) | (este commit) |
| 2026-11-10 | Claude Code (portátil) | Paso 1a | Cuerpo 3D del protagonista: `fisica/Cuerpo3D.gd` (cápsula 1,74 m, gravedad, salto), `fisica/ChoquesCercanos3D.gd` (copias 3D de los choques del mapa cercanos), `fisica/Suelo.gd` (altura del suelo, sacada de `CharacterAvatar3D`); el mando del jugador mueve el cuerpo 3D; salto viejo en píxeles fuera. Etiqueta `antes-paso-1` | fisica_3d ✅ (puerta de la taberna, muro, salto 1,14 m, aterrizaje, cambio de sitio) · verify_all ✅ | (este commit) |
| 2026-11-10 | Claude Code (portátil) | Paso 1b | Prueba nueva `tools/tests/puertas_3d.gd` (entrar y salir andando por todas las puertas); `capturas_fijas` dice dónde queda el protagonista; fotos `referencia_paso1` | puertas_3d ✅ 29/29 · atascos 0 en 6 h ✅ · fps igual que en el paso 0b (portátil aún lento: 8/5/5/7/8/8) · el cuerpo cuesta ~1 ms por paso · fotos: 5 de 7 iguales (≤ 1 %); plaza distinta porque el protagonista ya no se queda metido 4 px en un puesto | (este commit) |
| 2026-11-10 | Claude Code (portátil) | Paso 2a | Posada con dos plantas de verdad: el cuerpo pisa el suelo que tiene debajo según su altura (Planta 0, rampa de la escalera, Planta +1) y de ahí sale el piso; choques de un solo piso levantados solo en su piso (capa 20 del mapa); cámara y muñeco sobre el cuerpo 3D; fuera el cambio de piso por posición en `VillageTavern.tick`. Etiqueta `antes-paso-2` | fisica_3d ✅ (sube y baja la escalera andando, galería, barandilla, la barandilla no estorba abajo) · puertas_3d ✅ 29/29 · verify_all ✅ | (este commit) |
| 2026-11-10 | Claude Code (portátil) | Paso 2b | Club de peleas y alcantarillas de verdad bajo tierra (3,2 m, `Suelo.PROFUNDIDAD_SOTANO_PX`): el cuerpo, los muñecos y el dibujo 3D bajan; techo de roca en 1.ª persona; `VillageUnderworld.zona_alcantarillas`; arreglado que la cámara tomara «bajo tierra» por «sin cuerpo» | fisica_3d ✅ (baja y sube por la reja, anda por el túnel) · fotos en 1.ª persona revisadas (`docs/capturas_mundo3d/paso2b/`) · verify_all ✅ | (este commit) |
| 2026-11-10 | Claude Code (portátil) | Paso 2c | Daño por caída «realista» (decisión del usuario): desde 3 m (~9 %) hasta mortal a 8 m; hiere una parte del cuerpo (piernas sobre todo; desde 5 m las dos piernas; en caídas grandes también tronco y cabeza) con el sistema médico que ya había; `Player.reduccion_dano_caida` para mejoras futuras; barandillas de la posada a la cintura | fisica_3d ✅ (tabla de daño, caída de 4 m: −27 y herida, salto normal sin daño, mejora del 50 %) · verify_all ✅ | 38695e2c |
| 2026-11-10 | Claude Code (portátil) | Paso 3a | Nadar: el río y el lago ya no son pared para el protagonista; vadea cerca de la orilla, nada donde no hace pie (más lento, sin correr ni saltar, gasta aguante), flota con la cabeza fuera y sale por la otra orilla; caer al agua honda no duele. Hondura de juego (`Agua.gd`): río del pueblo 2,2 m en el centro, arroyo 0,6 m, lago 3,5 m | fisica_3d ✅ (cruza un tramo del río nadando, flota en el lago, no salta nadando) · puertas_3d 29/29 · verify_all ✅ | 066b3a36 |
| 2026-11-10 | Claude Code (portátil) | Paso 4a | Vecinos por la escalera de la posada: ya subían andando; ahora cambian de planta en el último peldaño (antes un escalón de golpe de ~24 cm) | fisica_3d ✅ · atascos_vecinos 6 h: 0 | a7906cc0 |
| 2026-11-10 | Claude Code (portátil) | Paso 4b | Opción A del usuario: cuerpo 3D «de contacto» para los vecinos cercanos (hasta 16, a ~6 m); ya no se les atraviesa; dormidos, muertos o caídos no estorban; a la altura de su piso. Ellos siguen sus rutas como antes (B, cuerpos completos con buscador de caminos 3D, pendiente) | fisica_3d ✅ · puertas_3d 29/29 · verify_all ✅ | 6fdc0955 |
| 2026-11-10 | Claude Code (portátil) | Paso 4c | Cuerpo de contacto también para bandidos, enemigos, jabalíes, ciervos y ganado grande adulto (decisión del usuario); conejos, zorros, mascotas, gallinas y crías se atraviesan; caballo y carro ya iban con el protagonista. `CuerposVecinos3D` → `CuerposCercanos3D` | fisica_3d ✅ · puertas_3d 29/29 · verify_all ✅ | 01b9d98e |
| 2026-11-10 | Claude Code (portátil) | Paso 5a | Vista con alturas (`Vista.gd`): testigos, policías, guardia de la reja y testigos de peleas ven según paredes, puertas y losas de los suelos altos; desde el salón se ve el borde de la galería y no a quien está encima; bajo tierra no se ve | fisica_3d ✅ (6 comprobaciones) · puertas_3d 29/29 · verify_all ✅ | 545f4734 |
| 2026-11-10 | Claude Code (portátil) | Paso 5b | Oído con alturas (`Vista.oye`): un ruido llega a otro piso a un tercio (galería abierta: entero), entre la calle y bajo tierra a un décimo; antes no llegaba. Los testigos de un ruido solo cuentan si lo ven. De paso: andando contra un vecino con cuerpo lo apartas poco a poco; los sentados no tienen cuerpo | fisica_3d ✅ · puertas_3d 29/29 · verify_all ✅ | 11dae2a9 |
| 2026-11-10 | Claude Code (portátil) | Paso 5c | Golpes y empujones por altura de los pies (`Vista.alcanza`, ~1,3 m); flechas y balas con altura: salen del pecho, en 1.ª persona con la pendiente de la mirada, solo hieren a quien está a esa altura, se clavan al bajar al suelo y un suelo alto las para | fisica_3d ✅ (5 comprobaciones) · puertas_3d 29/29 · verify_all ✅ | adb51221 |
| 2026-11-10 | Claude Code (portátil) | Paso 5d | Con [E] se llega a lo que está a tu altura (`vm.alcanza`), no a lo de tu piso; fuera las listas a mano de sitios de la posada por piso | fisica_3d ✅ (3 comprobaciones) · puertas_3d 29/29 · verify_all ✅ | (este commit) |

### Medidas de referencia (antes del paso 1, portátil, 2026-11-10)
- **fps en 1.ª persona** (`perf_zonas.gd`): afueras 33, plaza 29, río 23, bosque 38, molino 40, mansión 43.
- **Vecinos atascados** (`atascos_vecinos.gd -- 6`): 0 en 6 h. **Guardado largo:** PASSED, +1,6 MB del día 2 al 7.
- **Edificios movidos** (`sondeo_edificios_movidos.gd -- movido`): 29/29; sitios de vecinos 54 bien, 0 viejos, 6 al aire libre.
- **Fotos:** `docs/capturas_mundo3d/referencia_paso0/` (3072×1728; ruido normal entre dos tandas iguales: hasta 0,8 %).
- **Fluidez tras el paso 0b (2026-11-10, portátil en un mal momento: la versión de antes medida a la vez daba lo
  mismo):** afueras 8/8, plaza 5/5, río 5/5, bosque 8/8, molino 8/9, mansión 8/9 (nuevo/anterior). Repetir las medidas
  de referencia con el portátil en buen estado antes del paso 1.
- **Tokens del paso 0:** no se pueden medir desde dentro de la sesión; estimado ~8–12 millones leídos (dentro de lo previsto).
