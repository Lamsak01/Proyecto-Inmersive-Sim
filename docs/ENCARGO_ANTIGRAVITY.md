# Encargo para Antigravity (escrito por Claude Code, supervisor)

> Fecha: 2026-11-05. Pega este archivo entero como primer mensaje a Antigravity, o dile: «Lee
> `docs/ENCARGO_ANTIGRAVITY.md` y haz lo que pone».

---

## 0. Las cosas han cambiado: nuevo reparto de trabajo

Desde hoy (2026-11-05), por decisión del usuario:

- **Antigravity (tú) escribe el código** del juego.
- **Claude Code es el supervisor**: prepara los encargos (como este), revisa lo que subas a GitHub (cambios, pruebas,
  reglas del proyecto) y le dice al usuario si está bien o qué hay que corregir.
- **El usuario** decide el diseño y aprueba. No programa: háblale siempre en español, breve y sin código.

Cómo trabajamos a partir de ahora:

1. Haces **solo** lo que pide el encargo. Si ves otra cosa rota, apúntala en tu informe; no la arregles por tu cuenta.
2. Trabajas en bloques pequeños. Al cerrar el bloque: pruebas, documentación, commit y push a `main` (ver §3).
3. Al terminar, deja un **informe para el supervisor** en `docs/INFORME_ANTIGRAVITY.md` (qué hiciste, qué archivos
   tocaste, qué probaste y con qué resultado, qué no pudiste hacer). Claude Code lo leerá y revisará tu commit.
4. Si algo del encargo no te cuadra o el código no es como dice aquí, **no lo inventes**: escríbelo en el informe y
   pregunta. Si el encargo y `git` no coinciden, manda `git`.

---

## 1. Antes de tocar nada (lectura obligatoria)

- `CLAUDE.md` (reglas de comunicación y de trabajo; valen también para ti).
- `docs/HANDOFF.md` §3 (cómo pasar las pruebas) y §7 (estado; arriba del todo están los cambios de hoy).
- `GameVault/01_Vision_y_Reglas/Las 7 Reglas de las Auditorías.md`.
- Notas de la bóveda de los sistemas que toques: `GameVault/02_Sistemas/Red Eléctrica.md`,
  `Terminales Lógicas Electromecánicas.md`, `Red de las Sombras.md`.
- `git log --oneline -15` para ver lo último.

Reglas que el supervisor va a comprobar sí o sí:

- **Todo es físico:** nada se resuelve desde un menú de conversación ni con contadores invisibles. Las acciones de
  riesgo ocurren junto al objeto, con testigos reales (vecinos despiertos cerca, en la misma planta).
- **Suma cero:** ningún oro nace ni desaparece. Usa las ayudas `pay_into`, `take_from_treasury`, `role_npc` de
  `VillageManager` (ver HANDOFF §7).
- **Doble E** para gastar oro en el mundo (`VillageHousing.press_twice`).
- **Todo reto se puede perder y tiene espera** (1 vez al día como ya está).
- **La tecla E:** cualquier objeto nuevo con el que se interactúe debe ser una `Area2D` del grupo `interactable` y
  tener `get_interact_label(player)` para que salga su letrero «[E] …» (`scripts/ui/InteractionSelector.gd`).
- **Vista 2D y 3D:** todo objeto nuevo debe verse en 2D y en 3D (`WorldStage3D.gd`). F10 cambia de vista (F9 es cargar).
- Ya decidido, no lo cambies: velocidad del caballo ×1,45; impuestos por tramos 0/15/30 %.

---

## 2. El encargo actual: bloque FIS3 — alcantarillas que se recorren de verdad

> FIS2 (terminal, cuadro eléctrico y objetos de los robos) está revisado y aprobado por el supervisor. Ojo: en tu
> informe de FIS2 citabas funciones que no existen (`WorldText.show_choice_menu`, `inject_dialogue`,
> `gold_conservation_ok`, `sabotage_electric_grid`, `attempt_heist_steal`, «social_sim de 7 días»). El código estaba
> bien, pero **el informe debe describir lo que hay de verdad**: nombra solo funciones que existan y resultados que
> hayas visto en pantalla.

Ahora mismo: las alcantarillas se «exploran» desde una opción de charla con el perista
(`underworld_sewer_explore:` → `VillageUnderworld.explore_sewer_location`, una tirada de dados que te devuelve a la calle).
`WorldStage3D._build_sewers_3d` dibuja 3 cámaras en 3D, pero no se puede bajar ni andar por ellas. Además, el nivel −1
vuelve solo a la calle al alejarte 70 px (`VillageManager.check_elevation_exit`, regla de las capas verticales).

Hay que:
1. **Tres trampillas/rejillas en la calle** (dibujo 2D + modelo 3D, `Area2D` «interactable», letrero «[E] …»), una por
   cada sitio de `SEWER_LOCATIONS` (cisterna bajo la plaza, pasadizo del contrabandista, bóveda inundada). Colócalas en
   la calle junto a esos puntos, no dentro de un edificio ni encima de un camino de paso de los vecinos.
2. **Bajar con [E]** si tienes la llave del perista (`sewers_state.unlocked`; la llave se sigue comprando al perista
   como ahora). Sin llave: letrero «Cerrada: el perista vende la llave».
3. **Una red de túneles que se camina de verdad.** Recomendación técnica (decídelo tú, pero justifícalo en el informe):
   construir los túneles en una zona del mapa **fuera del pueblo** (por ejemplo, muy al sur, donde no hay nada), con
   paredes que bloqueen, porque bajo el pueblo real chocarías con las paredes de los edificios de la superficie. Cada
   trampilla de arriba lleva a su boca de túnel abajo; los tres túneles están conectados.
4. **Escalerillas de salida** abajo, junto a cada boca: [E] sube a la trampilla correspondiente de la calle. Así puedes
   entrar por una y salir por otra.
5. Mientras estás abajo: nivel −1, **no** debe saltar la vuelta automática a la calle de `check_elevation_exit`, la
   guardia de la superficie no te ve (los testigos ya miran la planta), y la vista 3D enseña los túneles
   (`sewers_root_3d`; usa `VillageUnderworld.is_player_in_sewers`).
6. **Cofres de contrabando** abajo (uno por cámara, [E], 1 vez al día cada uno) con el botín que ya define cada sitio
   (`loot_item`) y monedas del pozo `lost_coins_pool` (suma cero: salen de ese pozo, no del aire). Puede salir mal: agua
   sucia o una trampa → baja la higiene y algo de salud, como hace ahora el fallo. Mantén la ventaja actual del
   pasadizo del contrabandista: salir por él baja 1 nivel de búsqueda, como mucho una vez por semana
   (`VillageHousing.can_purge_wanted` / `mark_wanted_purge`).
7. **Quita** del perista la opción «Bajar al nivel −1 y explorar…» y la opción «Subir por la escalerilla…». La
   exploración por tirada (`explore_sewer_location`) deja de usarse en el juego (puedes dejar la función si los tests la
   necesitan, pero que ningún menú la llame).
8. Guardar y cargar: si guardas estando abajo, al cargar sigues abajo en el mismo sitio.

### 2.1 Pruebas del bloque

- Un test por comportamiento: sin llave no se baja; con llave [E] en la trampilla te pone abajo (nivel −1 y dentro de los
  túneles); andar abajo no te devuelve solo a la calle; salir por otra escalerilla te deja en otra trampilla de la calle;
  el cofre da su botín una vez al día y saca las monedas del pozo; el perista ya no ofrece explorar.
- Fotos con `tools/screenshot_3d.gd` (sitios «trampilla» y «tunel»).
- Arranque sin errores (`--headless --quit-after 3`), y las cuatro pruebas de HANDOFF §3, de una en una con `timeout`.
  El usuario ya ha dado permiso para pasarlas sin preguntar.

## 3. Al cerrar el bloque

1. `docs/HANDOFF.md` §7: una entrada arriba con lo técnico.
2. `CHANGELOG.md`: entrada en lenguaje de jugador.
3. `docs/REGISTRO_TRABAJO.md`: fila del bloque en el «Bloque FIS».
4. Bóveda: notas de los sistemas tocados («Notas de diseño»), tarjeta en `GameVault/05_Roadmap_y_Lore/Tablero.md` y
   línea en el diario del día (`GameVault/06_Diario/`).
5. Commit con mensaje en español y push a `main`.
6. `docs/INFORME_ANTIGRAVITY.md` para el supervisor (ver §0). **Reescríbelo entero** para este bloque.
7. Al usuario: resumen corto en lenguaje de jugador, sin código, y una sola pregunta al final.
