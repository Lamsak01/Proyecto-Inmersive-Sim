# Tareas para Antigravity (en paralelo con Claude Code; actualizado el 2026-11-14 a mediodía: tareas 6–8)

> **Mandato del usuario: TODO el juego en 3D, nada de 2D.** Lee antes `docs/specs/PLAN_TODO_3D.md` (plan y reglas de
> honestidad) y `docs/specs/AUDITORIA_2D_A_3D.md` (qué queda). Claude Code lleva los cimientos (vecinos, pueblo, física,
> rutas, la tecla E); tú llevas lo que **no pisa esos archivos**. Haz las tareas de una en una y en este orden.

## Reglas para no pisarse
1. Trabaja en **tu propia copia** del proyecto (otra máquina u otra carpeta clonada).
2. Antes de cada tarea `git pull --rebase`. Al acabarla: arranque sin errores y su prueba (`docs/specs/PRUEBAS.md`),
   **`bash tools/contar_2d.sh` antes y después** (el número va en tu línea del `CHANGELOG.md`, que empieza por
   «(Antigravity)»), marca en `docs/FALLOS_VISIBLES.md` si era un fallo, `git pull --rebase`, commit y push a `main`.
   Si hay choque al subir, resuélvelo conservando lo de los dos.
3. **Tuyos este fin de semana** (Claude no los toca): `mapa/Mundo3D.tscn`, `scripts/visuals/WorldStageProps3D.gd`,
   `WorldStageTerrain3D.gd`, `WorldStageBase3D.gd`, `RetroPostFX.gd`, `scripts/systems/AudioManager.gd`, las escenas de
   `mapa/edificios/` (solo para añadirles navegación y marcas; no cambies muros ni muebles salvo cantera y restaurante),
   la carpeta nueva `mapa/navegacion/`, y los sistemas dormidos `VillageUnderworld.gd`, `VillageClub.gd`,
   `VillageCulture.gd`, `VillageJustice.gd` y `VillageCollections.gd`.
4. **No toques** (son de Claude): `scripts/enemies/`, `scripts/fisica/`, `scripts/systems/VillageManager*.gd`,
   `VillageCase1.gd`, `Case1*.gd`, `WorldClock.gd`, `scripts/Player*.gd`, `scripts/ui/InteractionSelector.gd`,
   `scripts/ui/DetectiveUI.gd`, `scenes/World.tscn`, `scenes/dialogue_manager.gd`, `scripts/ui/dialogo/`, los personajes
   (`scripts/visuals/WorldStage3D.gd`, `CharacterAvatar3D.gd`, `AnimalModel3D.gd`, `BanditModel3D.gd`,
   `scripts/systems/EcosystemManager.gd`, `scripts/obstacles/`), `VillageTavern.gd` (espera la pregunta 0b), ni
   `docs/ESTADO_ACTUAL.md` ni los planes `docs/specs/PLAN_*.md` (si ves algo que falta, dilo en tu línea del CHANGELOG).
5. **Prohibido añadir nada en 2D ni en píxeles.** Lo nuevo va en metros y en nodos 3D. Normas de código de `CLAUDE.md` §4.
6. Di siempre **qué sigue siendo 2D** tras tu cambio. Nunca «terminado» sin el número del contador. Mira fotos de verdad.
7. Dudas de diseño: a `docs/PREGUNTAS_PENDIENTES.md` y sigue con la siguiente tarea.

## Hecho
- ✅ Clientes sentados encima de su silla (restaurante y posada), 2026-11-14.
- ✅ 1. Rendimiento: sombras del sol y geometría junto al río (`perf_zonas` 24–30 → 35–40 fps; `contar_2d.sh` 2.441 → 2.438), 2026-11-14.
- ✅ 2. Lluvia, luz y sonido en 3D (`Clima3D` sin llover bajo techo, día/noche solo con luz 3D sin `CanvasModulate` ni tintes/nieblas 2D en `RetroPostFX`, sonido 3D de pasos, puertas, voces y río; `contar_2d.sh` 2.454 → 2.428), 2026-11-14.
- ✅ 3. El mundo dibujado por código pasa a ser piezas del editor: 0 llamadas `_add_box/cyl/model_2d` en `WorldStageProps3D` y `WorldStageTerrain3D`, 481 matas de pradera en `Vegetacion/MatasPradera`, 33 escenas de objetos/bajo tierra/puesto horneadas y las 416 piezas anónimas del `Decorado` nombradas y agrupadas en 32 objetos (`contar_2d.sh` 2.428 → 2.409), 2026-11-14.
- ✅ 4. Interiores de tamaño real de la casa de la cantera (`mixed_family_quarry`, 8,4 × 9,8 m con taller de cantero al este) y del restaurante (`building_restaurant`, 15,4 × 10,64 m con terraza iluminada, comedor, cocina, cámara fría, reservado, bodega y alcoba de dos camas; `contar_2d.sh` 2.406 → 2.407 por una `Texture2D` de material 3D), 2026-11-14.
- ✅ 5. Quitado el estirón ×5 y el «mapa original» del relieve, lago, ciénaga, plaza y mapa cartográfico del valle (`WorldStageBase3D`, `WorldStageTerrain3D`, `mapa/zona.gd`, `mapa/mundo3d.gd`, `RioLago.gd`, `Agua.gd`, `ValleyMapUI.gd` y `ValleMapaPiezas.gd` en coordenadas reales; movido además `Banco_Plaza_Oeste` delante de la pescadería → `puertas_3d` 29/29; `contar_2d.sh` 2.407 → 2.312), 2026-11-14.

## Tareas (revisadas las 4 y 5 por Claude el 2026-11-14 con fotos propias, `puertas_3d`, `fisica_3d` y la partida del Caso I)
5b. **Resto de tu tarea 4 (poco):** las rocas de la cantera siguen colocándose con el ancho viejo del edificio
   (`VillageTrades.gd`, `yard_pos` y `_build_extras_en_mundo`: `+ 70.0`) y dos quedan pegadas al muro este. Que la franja
   de rocas salga del ancho real de la pieza del edificio (sin número a mano). Foto desde arriba de antes y después.

6. **Malla de navegación 3D del mundo y de cada edificio** (prepara la tanda 5 del plan; Claude la conectará a los
   vecinos, tú NO toques vecinos ni rutas). Hoy no hay ninguna `NavigationRegion3D` en el proyecto.
   a) Herramienta `tools/hornear_navegacion.gd` que hornea la malla UNA vez y la guarda como recurso en `mapa/navegacion/`
      (nada de hornear al arrancar el juego). Por trozos: el campo abierto en sectores y **una región por edificio**
      dentro de su escena, para poder rehacer un edificio sin rehacer el valle. Las regiones se unen en las puertas.
   b) Medidas del caminante: radio 0,28 m y alto 1,74 m (las de `TallaCuerpo3D.PERSONA`; solo lectura).
   c) Tiene que cubrir: calles y campo, los puentes y cruces del río (el agua honda no es pisable), el hueco de cada
      puerta (una puerta cerrada NO corta la malla: abrirla es cosa del vecino), los cuartos separados por tabiques,
      las escaleras y la planta alta de las casas de dos plantas, la posada tal como está y las alcantarillas.
      Los muebles sí cortan la malla; las marcas de uso (cama, silla, puesto) deben quedar alcanzables.
   d) Prueba nueva `tools/tests/navegacion_3d.gd` (sin ventana): desde la plaza pide camino a las 29 puertas, a todas
      las marcas de edificio (282) y a todos los sitios (86); imprime «NAVEGACION 3D: n/N» y la lista de lo que no se
      alcanza o queda a más de 0,5 m. Añádela a `docs/specs/PRUEBAS.md`.
   e) Entrega: el n/N, la lista de inalcanzables con su porqué, fotos de la malla (plaza, un puente, una casa de dos
      plantas por dentro, alcantarillas), tiempo de horneado y **tiempo de arranque del juego antes y después**.
   El contador no debe subir. Coste: medio.

7. **Dejar de crear los dibujos planos que luego se esconden** (auditoría C1). Hoy `_sync_2d_flat_visuals`
   (`WorldStageProps3D.gd`) pone transparentes los dibujos 2D de muebles, árboles, rocas, objetos y fachadas, que se
   siguen creando. Sigue cada dibujo hasta quien lo crea y haz que no se cree.
   - **Solo el dibujo** (`Sprite2D`, `Polygon2D`, `TextureRect`, `ColorRect`). **No toques sus choques planos**
     (`StaticBody2D`, `CollisionShape2D`, `Area2D`) ni sus `meta`: la vista, la E, las rutas y los golpes aún los leen.
   - Si quien lo crea está en un archivo de Claude (regla 4), no lo toques: apunta archivo y función en tu línea del
     `CHANGELOG.md`. Los personajes (vecinos, animales, bandidos) NO entran: son de la tanda 4b.
   - Por tandas pequeñas (naturaleza → objetos → muebles → fachadas), con `capturas_fijas` antes y después (peor < 1 %)
     y, al final, `puertas_3d`, `fisica_3d` y `partida_caso1`. Objetivo: borrar `_sync_2d_flat_visuals` o dejarlo solo
     con lo que sea de Claude. Da el contador («Dibujos 2D del mundo», hoy 74) y fps de `perf_zonas` antes y después.
   Coste: medio.

8. **Sistemas dormidos: sus lugares escritos a mano pasan a marcas y sitios del mapa** (tanda 1 del plan, auditoría B1).
   En `VillageUnderworld.gd` (42 posiciones `Vector2(n, n)`), `VillageClub.gd` (12), `VillageCulture.gd` (9),
   `VillageJustice.gd` (6) y `VillageCollections.gd` (3): cada posición fija pasa a ser una **marca** dentro de la escena
   de su edificio o un **sitio** en `Mundo3D.tscn`, con nombre que diga para qué sirve, y el código la lee con
   `Marca.sitio(...)` / `Sitio.mundo(...)` como ya hacen el Caso I y los oficios. Sin números de posición en el código.
   - No cambies qué hace cada sistema ni lo despiertes (siguen tras el modo demo); solo de dónde saca sus lugares.
   - Comprueba con `tools/tests/inventario_mundo.gd` (quieto / movido / comparar) que al mover la pieza en el editor
     el lugar va con ella. Un sistema por commit, en el orden de arriba. Di cuántas posiciones a mano quedan en cada uno.
   Coste: mucho.
