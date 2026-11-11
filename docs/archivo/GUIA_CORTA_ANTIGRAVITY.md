# Guía corta para Antigravity (léela en vez del HANDOFF completo)

- **Juego:** simulador inmersivo en Godot 4 (GDScript). **Solo 3D en primera persona**; el 2D se ignora (no se borra).
- **Época:** tecnofeudal / medieval-balística (feudalismo + tecnología analógica de los 70/80 + armas de fuego).
- **Papeles:** tú programas; Claude Code supervisa. El usuario no programa: háblale en español, corto, sin jerga.
- **Tu trabajo:** `docs/ENCARGO_SIGUIENTE.md` (cola, en orden) y `docs/FALLOS_VISIBLES.md` (fallos que ve el usuario).
  Reglas: «Ahorro de tokens» y «Ritmo y alcance» de `docs/DIRECTIVAS_ANTIGRAVITY.md`.
- **Hacer solo lo pedido**, sin rehacer partes enteras. Una captura 3D por arreglo; mírala de verdad.
- **Pruebas:** arranque `timeout 120 flatpak run org.godotengine.Godot --headless --path . --quit-after 300`. Siempre
  con `timeout`; nunca abras ni cierres el editor del usuario; nada de `pkill`/`pgrep -f` con tu propio patrón.
  EXIT 124 = colgada: busca `Assertion failed`.
- **Al cerrar cada paso:** ✅ en `FALLOS_VISIBLES.md`, 2–3 líneas en `docs/INFORME_ANTIGRAVITY.md`, commit y push a
  `main`. El papeleo grande (HANDOFF, CHANGELOG, vault, Tablero, diario) una vez al final del día.
- **No toques:** `scripts/systems/VillageSect.gd`, `GameVault/03_La_Secta/`, «Lore provisional»,
  `GameVault/99_Archivo/`, `GameVault/.obsidian/`, `.claude/`.
- **Decisiones ya tomadas** (no preguntar): `docs/HANDOFF.md` §8 (lee solo esa sección si dudas).
- **Archivos enormes:** `VillageManager.gd`, `VillageNPC.gd`, `WorldStage3D.gd`: busca con `grep -n`, no los leas enteros.
- **Godot siempre en primer plano** (con `timeout`, esperando su salida en el mismo comando), **nunca como tarea en segundo plano**: te quedas esperando para siempre.
- **Lectura mínima (orden del usuario, 2026-11-08):** lee solo esta guía, la sección de tu encargo y las entradas de fallos que te toquen. Nada de repasar el proyecto entero: el resto, solo la sección exacta que necesites.
