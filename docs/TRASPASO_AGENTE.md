# Traspaso: retomar la sesión de casa (2026-11-06)

> Lo escribe Claude Code (supervisor). Se actualiza al cerrar, a las 09:00 del 2026-11-06.

## Mensaje para pegar al agente (en el trabajo o en otro ordenador)

> Retoma la sesión que estaba haciendo en casa. Haz `git pull` en la carpeta del juego y lee, en este orden:
> `CLAUDE.md`, `docs/TRASPASO_AGENTE.md`, `docs/COLA_DE_TRABAJO.md`, `docs/REVISION_SUPERVISOR.md` (lo último) y
> `docs/PREGUNTAS_PENDIENTES.md`. Sigue la cola de trabajo desde el primer bloque que no esté hecho. Tú eres el
> supervisor: Antigravity escribe el código y tú preparas sus encargos, los revisas y los pruebas. Háblame en español,
> breve y sin código, y pregúntame antes de lanzar pruebas.

## Cómo se trabaja ahora (reparto)

- **Antigravity implementa**; **Claude Code supervisa** (encargos en `docs/ENCARGO_ANTIGRAVITY.md`, revisiones en
  `docs/REVISION_SUPERVISOR.md`, informes de Antigravity en `docs/INFORME_ANTIGRAVITY.md`).
- En el PC de casa Antigravity se lanza en una ventana de terminal sin pedir permisos:
  `cd ~/Videojuego && ~/AntigravityTerminal/agy -c --dangerously-skip-permissions -i "<encargo>"`.
  En otro ordenador, la ruta de `agy` puede ser distinta.
- **Lecciones de esta sesión:** (1) Antigravity a veces nombra funciones que no existen en sus informes: compruébalo;
  (2) un test con tipos de clase del juego (`var x: HealthComponent`) rompe la carga del script de pruebas y Godot se
  queda colgado: pruebas **siempre con `timeout`**; (3) vigila que siga avanzando, no solo que suba el resultado.

## Estado al cerrar

(se completa a las 09:00)
