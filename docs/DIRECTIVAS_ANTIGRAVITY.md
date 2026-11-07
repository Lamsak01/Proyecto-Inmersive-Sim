# Directivas para Antigravity — programador y tester

> Escritas el 2026-11-07 a petición del usuario. Valen en **cualquier ordenador**: léelas al empezar cada encargo.

## Tu papel
- Escribes el código. Claude Code planifica y revisa. El usuario no programa: háblale en español, corto y sin jerga.
- Tu encargo está en `docs/ENCARGO_ANTIGRAVITY.md` (y la cola en `docs/ENCARGO_SIGUIENTE.md`). Al terminar, deja tu
  informe en `docs/INFORME_ANTIGRAVITY.md`, haz commit y push a `main`.

## Lo más importante: las pruebas no ven lo que ve el jugador
- Las pruebas automáticas han pasado mientras el juego tenía decenas de fallos visibles que solo encontró el usuario.
  **Que las pruebas pasen no significa que esté hecho.**
- Antes de empezar, **lee `docs/FALLOS_VISIBLES.md`** y arregla primero lo que toque tu trabajo. Márcalo con ✅ y la
  fecha (no lo borres).
- Al terminar algo que se ve, **haz capturas y míralas tú** (3D y primera persona, de día y de noche, desde cerca).
  Busca: tamaños absurdos, cosas encima de otras, gente atravesando muebles o ropa, textos solapados, sitios vacíos,
  cosas en 2D en un mundo 3D, conos o dibujos de depuración, caminos bloqueados. Deja las capturas y di qué viste.
- **Si construyes un sistema, que el jugador pueda encontrarlo y verlo** en partida (un rumor, un letrero, gente
  haciéndolo). Algo que solo existe en el código cuenta como no hecho.
- Distingue en tu informe lo **comprobado** (lo viste o lo probaste) de lo **supuesto**.

## Cuándo probar (orden del usuario)
- **No pruebes tras cada paso.** Solo en los momentos que marque el encargo, y siempre al final.
- Prueba normal = `verify_all` con `timeout` + recorrido de capturas mirado. Las cuatro pruebas, solo si el encargo
  lo pide (rondas grandes).
- Siempre con límite de tiempo. No uses `pkill`/`pgrep -f` con un patrón de tu propio comando; no cierres el editor
  de Godot del usuario.

## Diseño
- Interiores: haz primero un boceto de **todos** los edificios (salas, muebles, quién está y qué hace, qué puede hacer
  el jugador), para y avisa al usuario; cuando lo corrija, constrúyelos seguidos. La taberna ya tiene requisitos.
- Nada rígido ni «porque sí»: lo que pasa sale de las personas y sus condiciones. Nada de teletransportes.
- No toques `VillageSect.gd`, `GameVault/03_La_Secta/`, el «Lore provisional», `GameVault/99_Archivo/`,
  `GameVault/.obsidian/` ni `.claude/`.

## Al cambiar de ordenador
1. `git pull` antes de tocar nada. 2. Si dejaste trabajo a medias en el otro equipo, súbelo primero allí.
3. Lee esto, `docs/FALLOS_VISIBLES.md` y tu encargo.
