# Tareas para Antigravity (fin de semana 2026-11-14/15, en paralelo con Claude Code)

> Lista temporal pedida por el usuario. Claude Code sigue con el **Caso I y los diálogos**; Antigravity hace estas tareas,
> **de una en una y en este orden**. Al acabar el fin de semana se borra este archivo y la regla temporal de `CLAUDE.md`.

## Reglas para no pisarse
1. Trabaja en **tu propia copia** del proyecto (el otro ordenador o otra carpeta clonada), nunca en la misma carpeta que
   Claude Code a la vez.
2. Antes de cada tarea: `git pull --rebase`. Al acabarla: arranque sin errores y su prueba (`docs/specs/PRUEBAS.md`),
   una línea en `CHANGELOG.md` que empiece por «(Antigravity)», marca ✅ en `docs/FALLOS_VISIBLES.md`, `git pull --rebase`,
   commit y push a `main`. Si hay choque al subir, resuélvelo conservando lo de los dos.
3. **No toques** (son de Claude Code este fin de semana): `scripts/systems/VillageCase1.gd`, `Case1*.gd`,
   `scenes/dialogue_manager.gd`, `scripts/ui/dialogo/`, `scripts/enemies/NPCMenuDialogo.gd`, `scripts/enemies/NPCCharla.gd`,
   `scripts/systems/WorldClock.gd` ni `docs/ESTADO_ACTUAL.md` (ese lo reescribe solo Claude; deja lo tuyo en el CHANGELOG).
4. Normas de código de `CLAUDE.md` §4 (tipado estático, sin números mágicos, cabecera en español…). Escenas 3D con las
   herramientas del flujo (`tools/hornear_*.gd`), no a mano. Mira capturas de verdad antes de dar algo por bueno.
5. Si dudas de diseño, apúntala en `docs/PREGUNTAS_PENDIENTES.md` y pasa a la siguiente tarea.

## Tareas
1. **Clientes sentados en el aire** (fallo del usuario, 3 capturas, 2026-11-14): en «El Fogón del Valle» (terraza y
   comedor) los vecinos se sientan al lado de la silla y no encima. Mira dónde se calculan los asientos del restaurante
   (y de la posada, por si pasa igual) frente a dónde están las sillas de su escena. Prueba: fotos en 1.ª persona a las
   12:30 en la terraza y el comedor. Coste: poco–medio.
2. **Rendimiento: sombras del sol** (prioridad 1 de `FALLOS_VISIBLES.md`): duplican las llamadas de dibujo. Busca cómo
   abaratarlas sin que el pueblo se vea plano (distancia, cascadas, qué objetos proyectan sombra, vegetación lejana).
   Sondas: `tools/tests/perf_zonas.gd`, `perf_ventana.gd`. Apunta los fps de antes y después. Coste: medio.
3. **Geometría junto al río** (el otro pendiente de rendimiento de la misma entrada): misma forma de medir. Coste: medio.
4. **Interiores de tamaño real que faltan**: la casa de la cantera y el restaurante (la taberna espera la pregunta 0b
   del usuario: no la toques). Lee antes `docs/specs/REGISTRO_EDITOR_3D.md` y `docs/specs/BOCETOS_EDIFICIOS.md`.
   Coste: mucho.
