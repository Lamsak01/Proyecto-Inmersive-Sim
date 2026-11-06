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

## 2. El encargo actual: bloque FIS4 — ganado vivo en el rancho y tus animales de verdad

> FIS3 (alcantarillas) revisado y **aprobado** por el supervisor. Esta vez el informe era fiel: bien.

Ahora mismo:
- El corral del Rancho del Sur (`VillageTrades.build_extras`, caso `"ranch"`) pinta **4 dibujos quietos** (gallina y
  jabalí) que no tienen nada que ver con el rebaño real (`VillageHousing.state(vm)["ranch_herd"]`: ovejas y gallos que
  crecen, se venden y se renuevan cada día).
- Tus animales (`player_animals`, se compran al ganadero o al carpintero) son **solo datos**: no existen en el mapa, se
  alimentan desde una charla (`housing_feed_animals`) y, cuando son adultos, **te meten carne cocinada en la mochila cada
  dos días sin hacer nada** (en el ciclo diario de `VillageHousing`). Eso incumple «todo es físico».

Hay que:
1. **Rebaño del rancho vivo:** un animal en el mapa por cada entrada de `ranch_herd`, paseando despacio dentro de la
   valla del corral (no salen), con su tamaño según la etapa (cría / joven / adulto). Cuando el rebaño cambia (nace,
   se vende), el mapa cambia igual. Quita los 4 dibujos quietos.
2. **Tus animales vivos:** cada entrada de `player_animals` existe en el mapa dentro del corral de tu gallinero
   (`ChickenCoop`, el vallado junto a tu campamento), paseando dentro de la valla. Si muere de hambre, desaparece.
3. **Con [E] junto a uno de tus animales** (letrero «[E] Dar de comer a …», `get_interact_label`):
   - darle de comer gasta 1 trigo o pan de tu mochila (lo mismo que hace ahora `feed_player_animals`, pero a ese animal);
   - si es adulto: **recoger su producto en persona** («[E] Esquilar la oveja» → lana; «[E] Recoger huevos» → huevo),
     como mucho una vez cada 2 días por animal. **Quita** la carne que entraba sola en la mochila.
   - Quita la opción de alimentarlos desde la charla con el ganadero/carpintero (comprar crías sí se queda en la charla:
     es una compra a una persona).
4. **Aspecto (provisional):** no hay modelos de oveja ni de gallina de nuestro estilo. Usa por ahora
   `animals/animated/Alpaca.glb` para la oveja (bájalo de poly.pizza, Quaternius, CC0, igual que los otros; apúntalo en
   `assests/curated_3d/animals/animated/LICENCIA.txt`) y una gallina sencilla hecha con piezas en 3D (como hiciste con la
   terminal). En 2D, los dibujos que ya hay. Con `AnimalModel3D.attach` para lo que tenga `.glb`.
5. Guardar y cargar: al cargar, los animales vuelven a aparecer según los datos guardados.

### 2.1 Pruebas del bloque

- Un test por comportamiento: hay tantos animales en el corral del rancho como en `ranch_herd`; tus animales aparecen
  en tu corral; [E] da de comer y gasta 1 trigo/pan; un adulto da su producto una vez cada 2 días; ya no entra carne
  sola en la mochila; la charla ya no ofrece alimentar.
- Fotos con `tools/screenshot_3d.gd` (sitios «rancho» y «corral»).
- Arranque sin errores (`--headless --quit-after 3`) y las cuatro pruebas de HANDOFF §3, de una en una con `timeout`.
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
