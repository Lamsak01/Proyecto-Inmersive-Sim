# La Placa de Petri

Immersive sim 2D en pixel art hecho con Godot 4.7.2 (GDScript). El usuario no programa: háblale siempre en español, breve y sin jerga.

## Reparto de trabajo (desde 2026-11-05)

- **Antigravity escribe el código**; **Claude Code supervisa**: prepara el encargo en `docs/ENCARGO_SIGUIENTE.md` (cómo supervisar: `docs/DIRECTIVAS_CLAUDE.md`, «Cómo supervisar a Antigravity»),
  revisa lo que Antigravity suba (y su informe en `docs/INFORME_ANTIGRAVITY.md`) y le dice al usuario si está bien.

## Antes de trabajar

**Directivas por papel (valen en cualquier ordenador):** Claude Code lee `docs/DIRECTIVAS_CLAUDE.md`; Antigravity lee `docs/DIRECTIVAS_ANTIGRAVITY.md`. Las pruebas automáticas no ven los fallos visibles: mira capturas y `docs/FALLOS_VISIBLES.md`.

0. Si eres un agente nuevo (Antigravity u otro), empieza por `docs/PROMPT_SIGUIENTE_AGENTE.md`. Si ya trabajaste aquí, lee antes `docs/NOTA_PARA_OTRO_AGENTE.md`.
   - **Base de datos de Obsidian (`GameVault/`):** Dentro del repositorio vive la bóveda de Obsidian del proyecto (`GameVault/00_MOC/La Placa de Petri.md` y subcarpetas `01_Vision_y_Reglas` a `06_Diario`). Cualquier agente de IA (Claude Code, Antigravity u otro futuro) debe consultarla y **mantenerla actualizada y sincronizada en GitHub** en cada bloque que modifique sistemas, misiones, censo, pendientes o el diario.

1. Lee `docs/HANDOFF.md`: reglas de trabajo, mapa del código, trampas conocidas, estado de los bloques (sección 7) y decisiones de diseño ya tomadas (sección 8). No vuelvas a preguntar lo ya decidido.
2. Comprueba `git status` y `git log --oneline -5`. Si la documentación y git no coinciden, manda git.
3. Si la tarea toca la vida social, lee también `docs/PLAN_VIDA_SOCIAL.md`.
4. Antes de proponer un sistema nuevo, lee `docs/VISION_Y_FUTURO.md`: la aspiración del juego, el orden acordado y el banco de ideas del usuario. Añade ahí las ideas nuevas que proponga; no borres ninguna sin que lo pida.

## Vault de diseño (Obsidian) — `GameVault/`

El usuario organiza el diseño en Obsidian. Reparto: el vault es su espacio de diseño; `docs/` sigue siendo la guía técnica de los agentes. Si se contradicen, pregunta al usuario.

- **Antes de diseñar o tocar un sistema:** lee su nota en `GameVault/02_Sistemas/` (o `03_La_Secta/`, `04_Censo_y_Misiones/`) y `GameVault/01_Vision_y_Reglas/Las 7 Reglas de las Auditorías.md`.
- **Al cerrar cada bloque**, además de lo de siempre:
  1. Actualiza la nota del sistema afectado (`estado`: idea / parcial / implementado; añade lo nuevo en «Notas de diseño»).
  2. Mueve o marca la tarjeta en `GameVault/05_Roadmap_y_Lore/Tablero.md` (formato del plugin Kanban: no cambies su cabecera ni el bloque final de ajustes).
  3. Añade una línea al diario del día en `GameVault/06_Diario/AAAA-MM-DD.md` (créalo con la estructura de `GameVault/Plantillas/Diario.md` si no existe).
- **Sistemas o vecinos nuevos:** crea su nota a partir de `GameVault/Plantillas/`.
- Respeta el frontmatter (`tipo`, `area`, `estado`, `codigo`): lo usan las tablas del panel.
- **No modifiques** `GameVault/03_La_Secta/` ni el `Lore provisional` sin orden expresa, ni `GameVault/99_Archivo/` (copia histórica).
- No toques `GameVault/.obsidian/`.

## Reglas clave de comunicación (obligatorias en TODOS los mensajes)

1. **Cero código en los mensajes:** nunca nombres archivos, funciones, variables ni líneas de código, salvo que el usuario lo pida. Habla del JUEGO (vecinos, tiendas, misiones, la cantera, el mapa...).
2. **Formato de cada problema o propuesta (pocas líneas):**
   - Qué pasa (en palabras de jugador).
   - Qué notaría el jugador en el juego (o «no se nota, es para el futuro»).
   - Qué pasa si no lo hacemos.
   - Recomendación: hacerlo ya / más adelante / no hacerlo, y cuánto cuesta (poco / medio / mucho).
3. **Máximo 10–12 líneas por mensaje.** Si hay varias cosas, empieza por la más importante y pregunta si quiere oír el resto.
4. **Sin jerga:** si usas una palabra técnica, explícala en la misma frase con una comparación sencilla.
5. **Permiso antes de cualquier prueba:** pregunta SIEMPRE antes de lanzar pruebas o partidas de prueba, diciendo cuánto tardan.
6. **Cierre claro:** termina cada mensaje con lo que necesitas del usuario, en una sola pregunta clara.

## Reglas de trabajo

- Evalúa las ideas con honestidad; no des la razón por defecto.
- Antes de una mecánica o sistema nuevo, presenta un plan corto y espera aprobación.
- Trabaja en bloques pequeños. Al cerrar cada uno: marca `docs/HANDOFF.md`, añade una entrada a `CHANGELOG.md`, haz commit y push a `main`.
- Sin refactors grandes ni cambios de comportamiento visible sin avisar.
- Distingue lo probado de lo supuesto.

## Ahorro de tokens

- Mientras trabajas, pasa solo el test afectado.
- **Una sola prueba por bloque** (orden del usuario, 2026-11-06): al cerrar el bloque, arranque sin errores y **solo la prueba
  que toca lo cambiado**, con `timeout`. Las cuatro pruebas se pasan solo en las **rondas de auditoría** que pide el usuario.
- Un solo test por comportamiento nuevo.
- Nada de comprobaciones repetidas ni revisiones grandes sin avisar antes.
- Resúmenes de 3 líneas por bloque.

## Tests

Los comandos están en la sección 3 de `docs/HANDOFF.md`. Godot se ejecuta con Flatpak (`flatpak run org.godotengine.Godot`).
No uses `pkill` ni `pgrep -f` con un patrón que aparezca en tu propio comando, y no cierres el editor de Godot del usuario si está abierto.
