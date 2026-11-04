# La Placa de Petri

Immersive sim 2D en pixel art hecho con Godot 4.7.2 (GDScript). El usuario no programa: háblale siempre en español, breve y sin jerga.

## Antes de trabajar

0. Si eres un agente nuevo (Antigravity u otro), empieza por `docs/PROMPT_SIGUIENTE_AGENTE.md`.

1. Lee `docs/HANDOFF.md`: reglas de trabajo, mapa del código, trampas conocidas, estado de los bloques (sección 7) y decisiones de diseño ya tomadas (sección 8). No vuelvas a preguntar lo ya decidido.
2. Comprueba `git status` y `git log --oneline -5`. Si la documentación y git no coinciden, manda git.
3. Si la tarea toca la vida social, lee también `docs/PLAN_VIDA_SOCIAL.md`.
4. Antes de proponer un sistema nuevo, lee `docs/VISION_Y_FUTURO.md`: la aspiración del juego, el orden acordado y el banco de ideas del usuario. Añade ahí las ideas nuevas que proponga; no borres ninguna sin que lo pida.

## Reglas clave

- Evalúa las ideas con honestidad; no des la razón por defecto.
- Antes de una mecánica o sistema nuevo, presenta un plan corto y espera aprobación.
- Trabaja en bloques pequeños. Al cerrar cada uno: marca `docs/HANDOFF.md`, añade una entrada a `CHANGELOG.md`, haz commit y push a `main`.
- Sin refactors grandes ni cambios de comportamiento visible sin avisar.
- Distingue lo probado de lo supuesto.

## Ahorro de tokens

- Mientras trabajas, pasa solo el test afectado.
- Pasa los cuatro tests una sola vez, al cerrar cada bloque, de uno en uno y con `timeout`.
- Un solo test por comportamiento nuevo.
- Nada de comprobaciones repetidas ni revisiones grandes sin avisar antes.
- Resúmenes de 3 líneas por bloque.

## Tests

Los comandos están en la sección 3 de `docs/HANDOFF.md`. Godot se ejecuta con Flatpak (`flatpak run org.godotengine.Godot`).
No uses `pkill` ni `pgrep -f` con un patrón que aparezca en tu propio comando, y no cierres el editor de Godot del usuario si está abierto.
