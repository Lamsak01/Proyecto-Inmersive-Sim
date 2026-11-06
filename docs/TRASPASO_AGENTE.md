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

## Estado al cerrar (mañana del 2026-11-06)

**Hecho, revisado y probado** (arranque sin errores y las cuatro pruebas pasan al final de la mañana):
- COMBATE-1: rodar (Espacio) con invulnerabilidad breve y gasto de aguante; parar (Q) con ventana corta que anula el
  golpe y deja al atacante tambaleándose; golpes enemigos con aviso de 0,4 s (vecinos hostiles, guardias, asaltantes,
  perros, jabalíes). Q sigue siendo derribo en sigilo si hay objetivo.
- ANIM-1: pasos calibrados con la zancada real de las animaciones (andar/correr/cargar) y armas giradas en la mano.
  **Falta que el usuario lo vea en movimiento** (en una foto quieta no se puede juzgar si aún patina).

**Siguiente:** bloque P1 (tu tienda propia hecha física). El encargo ya está escrito en `docs/ENCARGO_ANTIGRAVITY.md`
§2: solo hay que mandárselo a Antigravity. Después, P2 a P6 y el inventario ordenado (ver `docs/COLA_DE_TRABAJO.md`).

**Beta:** el usuario decidió misterio, con final y resumen, 1–2 h, Windows. Plan borrador en
`docs/PLAN_BETA_MISTERIO.md` (el usuario lo retocará). Aún no hay encargos de la beta.

**Pendiente de medir:** equilibrio de los asaltos; rendimiento en ordenadores modestos.
