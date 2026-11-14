# Tareas para Antigravity (en paralelo con Claude Code; actualizado el 2026-11-14 por la noche)

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
   `WorldStageTerrain3D.gd`, `RetroPostFX.gd`, `scripts/systems/AudioManager.gd`, las escenas de `mapa/edificios/` de la
   cantera y el restaurante, y la parte de lluvia de `scripts/World.gd` (`_setup_weather_overlay`, `_draw_weather_overlay`).
4. **No toques** (son de Claude): `scripts/enemies/`, `scripts/fisica/`, `scripts/systems/VillageManager*.gd`,
   `VillageCase1.gd`, `Case1*.gd`, `WorldClock.gd`, `scripts/Player*.gd`, `scripts/ui/InteractionSelector.gd`,
   `scripts/ui/DetectiveUI.gd`, `scenes/World.tscn`, `scenes/dialogue_manager.gd`, `scripts/ui/dialogo/`, ni
   `docs/ESTADO_ACTUAL.md` ni los planes `docs/specs/PLAN_*.md` (si ves algo que falta, dilo en tu línea del CHANGELOG).
5. **Prohibido añadir nada en 2D ni en píxeles.** Lo nuevo va en metros y en nodos 3D. Normas de código de `CLAUDE.md` §4.
6. Di siempre **qué sigue siendo 2D** tras tu cambio. Nunca «terminado» sin el número del contador. Mira fotos de verdad.
7. Dudas de diseño: a `docs/PREGUNTAS_PENDIENTES.md` y sigue con la siguiente tarea.

## Hecho
- ✅ Clientes sentados encima de su silla (restaurante y posada), 2026-11-14.
- ✅ 1. Rendimiento: sombras del sol y geometría junto al río (`perf_zonas` 24–30 → 35–40 fps; `contar_2d.sh` 2.441 → 2.438), 2026-11-14.
- ✅ 2. Lluvia, luz y sonido en 3D (`Clima3D` sin llover bajo techo, día/noche solo con luz 3D sin `CanvasModulate` ni tintes/nieblas 2D en `RetroPostFX`, sonido 3D de pasos, puertas, voces y río; `contar_2d.sh` 2.454 → 2.428), 2026-11-14.
- ✅ 3. El mundo dibujado por código pasa a ser piezas del editor: 0 llamadas `_add_box/cyl/model_2d` en `WorldStageProps3D` y `WorldStageTerrain3D`, 481 matas de pradera en `Vegetacion/MatasPradera`, 33 escenas de objetos/bajo tierra/puesto horneadas y las 416 piezas anónimas del `Decorado` nombradas y agrupadas en 32 objetos (`contar_2d.sh` 2.428 → 2.409), 2026-11-14.

## Tareas
1. ✅ **Rendimiento: sombras del sol** (prioridad 1 de `FALLOS_VISIBLES.md`) y **geometría junto al río**. Abaratar sin que
   el pueblo se vea plano. Sondas `tools/tests/perf_zonas.gd`, `perf_ventana.gd`; fps de antes y después. Coste: medio.
2. ✅ **Lluvia, luz y sonido en 3D** (tanda 8 del plan, la parte que no depende de los cimientos):
   a) lluvia y niebla como efecto 3D del mundo (no un dibujo sobre la pantalla; que no llueva bajo techo);
   b) día y noche solo con la luz 3D (sol, cielo, ambiente): que el juego no dependa del tinte 2D `CanvasModulate`;
   c) sonido con posición 3D (pasos, puertas, voces, río) en `AudioManager.gd`. Fotos de día, noche y lluvia. Coste: medio.
3. ✅ **El mundo dibujado por código pasa a ser piezas del editor** (auditoría B7 y B8): los objetos que `WorldStageProps3D.gd`
   y `WorldStageTerrain3D.gd` levantan con cajas y cilindros (`_add_box_2d`, `_add_cyl_2d`, `_add_model_2d`: ~266 llamadas)
   se hornean una vez a `mapa/Mundo3D.tscn` con herramienta (`tools/hornear_*.gd`), **con nombre que diga qué son**, y se
   borra su código. De paso, poner nombre a las 305 «Caja_N» del decorado (qué es cada una) agrupándolas por objeto.
   Por tandas pequeñas (un tipo de objeto cada vez), con foto de antes y después. Coste: mucho.
4. **Interiores de tamaño real que faltan:** la casa de la cantera y el restaurante (la taberna espera la pregunta 0b del
   usuario: no la toques). Lee antes `docs/specs/REGISTRO_EDITOR_3D.md` y `docs/specs/BOCETOS_EDIFICIOS.md`. Coste: mucho.
5. **Quitar el estirón ×5 y el «mapa original»** de tus archivos y de las formas del mundo (auditoría A5): relieve hecho
   por el juego, forma del lago y de la ciénaga, manchas del mapa del valle (`WorldStageTerrain3D.gd`, `mapa/zona.gd`,
   `scripts/fisica/RioLago.gd` y `Agua.gd` solo en lo que toca a esas formas, `scripts/ui/ValleyMapUI.gd`). Las formas
   pasan a estar escritas una vez en su sitio real del mundo (o en piezas del editor) y se borran `Mapa3D.E`,
   `Zona.estirar/desestirar` y `estirar_terreno`. Avisa en tu línea del CHANGELOG si tocas `RioLago.gd` o `Agua.gd`. Coste: medio.
