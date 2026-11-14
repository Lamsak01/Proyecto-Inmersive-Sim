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
8. **Solo 1.ª persona (usuario, 2026-11-14):** la vista desde arriba ya no cuenta. No diseñes, pruebes ni arregles nada
   para ella; las fotos de antes y después, en 1.ª persona (`CLAUDE.md` §5).

## Hecho
- ✅ Clientes sentados encima de su silla (restaurante y posada), 2026-11-14.
- ✅ 1. Rendimiento: sombras del sol y geometría junto al río (`perf_zonas` 24–30 → 35–40 fps; `contar_2d.sh` 2.441 → 2.438), 2026-11-14.
- ✅ 2. Lluvia, luz y sonido en 3D (`Clima3D` sin llover bajo techo, día/noche solo con luz 3D sin `CanvasModulate` ni tintes/nieblas 2D en `RetroPostFX`, sonido 3D de pasos, puertas, voces y río; `contar_2d.sh` 2.454 → 2.428), 2026-11-14.
- ✅ 3. El mundo dibujado por código pasa a ser piezas del editor: 0 llamadas `_add_box/cyl/model_2d` en `WorldStageProps3D` y `WorldStageTerrain3D`, 481 matas de pradera en `Vegetacion/MatasPradera`, 33 escenas de objetos/bajo tierra/puesto horneadas y las 416 piezas anónimas del `Decorado` nombradas y agrupadas en 32 objetos (`contar_2d.sh` 2.428 → 2.409), 2026-11-14.
- ✅ 4. Interiores de tamaño real de la casa de la cantera (`mixed_family_quarry`, 8,4 × 9,8 m con taller de cantero al este) y del restaurante (`building_restaurant`, 15,4 × 10,64 m con terraza iluminada, comedor, cocina, cámara fría, reservado, bodega y alcoba de dos camas; `contar_2d.sh` 2.406 → 2.407 por una `Texture2D` de material 3D), 2026-11-14.
- ✅ 5. Quitado el estirón ×5 y el «mapa original» del relieve, lago, ciénaga, plaza y mapa cartográfico del valle (`WorldStageBase3D`, `WorldStageTerrain3D`, `mapa/zona.gd`, `mapa/mundo3d.gd`, `RioLago.gd`, `Agua.gd`, `ValleyMapUI.gd` y `ValleMapaPiezas.gd` en coordenadas reales; movido además `Banco_Plaza_Oeste` delante de la pescadería → `puertas_3d` 29/29; `contar_2d.sh` 2.407 → 2.312), 2026-11-14.
- ✅ 5b. Franja de rocas de la cantera y puesto exterior (`VillageTrades.gd`: `yard_pos` y `_build_extras_en_mundo` leen el ancho real de la pieza del edificio en `mapa/planta.gd` sin `+ 70.0` a mano; fotos `2026-11-14_t5b_cantera_{antes,despues}.png`; `contar_2d.sh` 2.240 → 2.240), 2026-11-14.
- ✅ 6. Malla de navegación 3D del valle, edificios y alcantarillas (`tools/hornear_navegacion.gd` + 6 módulos auxiliares, 110 sectores en `Mundo3D.tscn` y 1 `NavigationRegion3D` por edificio en `mapa/navegacion/`, 720 KB; `navegacion_3d`: `588/600` desde la plaza —29/29 puertas, 299/300 marcas, 260/271 sitios— y `9/9` en alcantarillas; horneado completo 267,7 s y 3,7 s un edificio; arranque 27,95 → 35,97 s; fotos en 1.ª persona `2026-11-14_t6_nav_{plaza,puente,casa_2p,alcantarillas}.png`; `contar_2d.sh` 2.201 → 2.201), 2026-11-14.

## Tareas (revisadas las 4 y 5 por Claude el 2026-11-14 con fotos propias, `puertas_3d`, `fisica_3d` y la partida del Caso I)
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
