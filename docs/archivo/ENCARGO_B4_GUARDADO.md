# Encargo B4 — Guardar y cargar sin sustos (bloque medio)

> Escrito por Claude Code (supervisor), 2026-11-06. Fila B4 de `docs/PLAN_ORDENADO.md` (Beta §3.7).
> Las decisiones de diseño **ya están tomadas** (abajo, §2). No cambies ninguna. Si algo no encaja con el código,
> apúntalo en el informe y pregunta. **No cambies el formato del archivo de guardado salvo para añadir claves nuevas**
> (las partidas viejas tienen que seguir cargando).

## Reglas (orden del usuario)
- Lee solo este encargo, `CLAUDE.md` y lo que se nombra aquí.
- No pases pruebas mientras trabajas. Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`). Nada de tipos de clase del juego en las variables del test (usa `load(...).new()` o variables sin tipo).
- No toques `scripts/systems/VillageSect.gd` ni `GameVault/03_La_Secta/`.
- No hagas refactors: arreglos pequeños y localizados, uno por problema.

## Cómo se guarda hoy (ya existe, no lo rehagas)
- `GameManager.save_game` / `load_game` (`scripts/systems/GameManager.gd`, JSON en `user://village_save.json`).
- El pueblo: `VillageManager.get_economy_save_dict` / `load_economy_save_dict` (~línea 4700–4830). Todo lo que vive en
  `needs_state`, `town_state`, `lots_state`, `family_state`, etc. se guarda entero con `duplicate(true)`.
- Cada vecino: `VillageNPC.to_save_dict` / `from_save_dict` (~4780–5050); **los recados en marcha (`errand`) no se
  guardan**. Jugador: `Player.to_save_dict` (~874). La salud va en `HealthComponent.to_medical_dict`.
- Ojo con JSON: un `Vector2` se convierte en texto `"(x, y)"` y las claves numéricas en texto. Si encuentras alguno de
  estos en un estado guardado, arréglalo al cargar (no cambies cómo se guarda).

## 1. Qué hay que revisar (lista cerrada)
Para cada cosa: guárdala **a medias**, carga, y mira si queda bien. Son las que se han añadido o tocado desde el último
repaso de guardado:
1. **Sabotajes y recados nocturnos** (`VillageNightJobs`, lista `needs_state["night_jobs"]`): un trabajo con el vecino
   ya caminando hacia el objetivo.
2. **Club de pelea** (`VillageClub`, `needs_state["club"]`): noche abierta con vecinos sentados; jugador **abajo** en el
   club (altura y posición); combate en marcha (meta `club_bout` en el rival); apuesta hecha.
3. **Cobros pendientes** (`VillageCollections`, `needs_state["pending_collections"]`) y el libro de cuentas amañado.
4. **Cenas, fiestas y cenas de paz** (`VillageHousing`, `hs["gathering"]`): convocada sin empezar y en marcha.
5. **Robo de la carreta del jugador** (P2, `PlayerCart`) y el perista con `fence_busted_until`.
6. **Amputación y prótesis** (jugador y vecino): el tope del miembro (`HealthComponent.region_max_override`, ya se
   guarda) y el aviso de gangrena (`needs_state["player_gangrene"]`).
7. **Mostradores de Obras Maestras** y **tu casa por dentro** (huerto, banco, escondite con oro, escaleras +1/−1):
   que los objetos vuelvan a aparecer y el oro del escondite siga igual.
8. **Jugador en el sótano o el altillo** (`player_elevation_level`).

## 2. Regla para lo que estaba a medias (decisión ya tomada)
- **Si se puede retomar, se retoma:** un recado nocturno, una cena convocada o un cobro pendiente siguen tras cargar
  (el vecino vuelve a echar a andar, la cena sigue a su hora, el cobro sigue en su sitio).
- **Si no se puede retomar limpio, se cancela limpio:** un combate del club en marcha se da por **terminado sin
  ganador**: las apuestas se devuelven, nadie queda con `club_bout` puesto, y el rival vuelve a su rutina. Un vecino
  que se quedó «a mitad de algo» vuelve a su rutina normal.
- **Nunca** puede quedar nada colgado para siempre (un trabajo que no acaba nunca, un vecino quieto esperando, un
  jugador bajo tierra sin escalera, oro perdido).
- Si el jugador estaba abajo en el club, al cargar sigue abajo y la escalera funciona.

## 3. Cómo arreglar
- Pon los arreglos en las funciones `after_load` que ya existen o, si el sistema no tiene, añade una pequeña
  `after_load(vm)` en ese módulo y llámala desde `load_economy_save_dict`, junto a las demás.
- Apunta en el informe, por cada uno de los 8 puntos: «bien sin tocar» o «fallaba así → arreglado así».

## Prueba (una sola, en `verify_all`): bloque «B4 guardado»
Guarda en un archivo temporal (`user://b4_test_save.json`, bórralo al final) con `GameManager.save_game(ruta)` y
carga con `load_game(ruta)`. Monta antes, a la vez: un recado nocturno con el agente caminando, un combate del club en
marcha con una apuesta, un cobro pendiente, una cena convocada, el jugador con una prótesis sencilla y 30 de oro en el
escondite. Comprueba tras cargar:
1. El recado nocturno sigue en la lista y su agente vuelve a tener el recado (o acaba en una hora de juego).
2. No queda ningún vecino con `club_bout` y el oro de la apuesta ha vuelto.
3. El cobro pendiente y la cena siguen ahí.
4. El miembro con prótesis sigue al 50 % y el escondite sigue con 30.
5. Cero errores de script durante guardar y cargar.
Deja el juego como estaba al acabar el bloque de prueba.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: reescríbelo entero con los 8 puntos. **Nombra solo funciones que existan**.
2. Commit en español y push a `main` (haz `git pull` antes). No subas la carpeta `.claude/`.
