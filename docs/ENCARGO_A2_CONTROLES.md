# Encargo A2 — Pantalla de ayuda de controles al empezar (bloque pequeño)

> Escrito por Claude Code (supervisor), 2026-11-06. Fila A2 de `docs/PLAN_ORDENADO.md` (Beta §3.6).
> Decisiones **ya tomadas**: no cambies ninguna. Si algo no encaja con el código, apúntalo en el informe y pregunta.

## Reglas (orden del usuario)
- Lee solo este encargo, `CLAUDE.md` y lo que se nombra aquí (`scenes/ui_root.gd`, `scripts/Player.gd`,
  `scripts/PlayerCombatController.gd`, `scripts/PlayerMovementController.gd`, `scripts/ui/InteractionSelector.gd`).
- No pases pruebas mientras trabajas. Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`). Nada de tipos de clase del juego en las variables del test.
- No toques nada fuera de este encargo. **No cambies ninguna tecla.**

## 1. Qué se ve
- Al empezar una **partida nueva** (no al cargar), aparece un panel en el centro de la pantalla con el título
  «Controles» y dos columnas:
  - **Lo básico** (8 líneas, en este orden): mover (W A S D) · atacar (clic izquierdo, apuntando con el ratón) ·
    usar o hablar (E) · cambiar de objetivo cuando hay varios (G o Mayús + rueda) · rodar (Espacio) · parar un golpe (Q) ·
    sigilo (C) · mochila (I).
  - **Más**: rueda de acciones (Tab) · vecinos (J) · mapa (M) · misiones (L) · herramientas (1–9) · guardar / cargar
    (F5 / F9) · velocidad del tiempo (F1–F4).
- **Comprueba cada tecla en el código** antes de escribirla. Si alguna no hace lo que pone aquí o no existe, **no la
  pongas** y apúntalo en el informe (con la tecla real si la hay). No inventes teclas nuevas.
- Abajo del panel: «Pulsa Esc, Intro o haz clic para empezar». Mientras está abierto, el reloj del juego se para
  (usa la pausa que ya exista, la misma que usan otros paneles de pantalla completa).
- Estilo: el mismo de los otros paneles de `ui_root.gd` (fondo oscuro semitransparente, letra que ya se use). Texto
  en español, sin emojis.

## 2. Volver a verla
- Con la tecla **H** (F1–F4 ya cambian la velocidad), si está libre (búscalo en el código); si H ya hace algo,
  no la cambies: pon un botón «Controles» en el menú de pausa si existe, y dilo en el informe.
- La línea de ayuda de abajo del reloj (`clock_sub_label`) sigue igual; añade al final «· [H] Controles» solo si H
  quedó libre y en uso.

## Prueba (una sola, en `verify_all`): bloque «A2 controles»
1. Al llamar a la función que abre el panel en partida nueva, el panel queda visible y el tiempo parado.
2. Al cerrarlo, el panel se oculta y el tiempo vuelve a correr.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: reescríbelo entero. **Nombra solo funciones que existan**.
2. Commit en español y push a `main` (haz `git pull` antes). No subas la carpeta `.claude/`.
