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

## 2. El encargo actual: bloque COMBATE-1 — rodar y parar

> Decisiones del usuario (2026-11-06): **Espacio = rodar**, **Q = parar**. Las peleas clandestinas irán en un **sótano de
> la taberna** (bloque aparte, después). Las coberturas para armas de fuego se dejan para cuando haya enemigos que
> disparen. **No hagas nada de eso ahora**, solo esto.

Ahora mismo: no hay esquiva ni parada. Los enemigos pegan al instante, sin aviso (p. ej. `VillageNPC._process_hostile_combat`
pega cada 1 s en cuanto está a ≤30 px; `Raider._hit`; perros hostiles en `DomesticPet`; jabalíes en `WildAnimal`).

Hay que:
1. **Rodar (Espacio):** el jugador rueda en la dirección en que se mueve (si está quieto, hacia donde mira) unos 45–55 px
   en ~0,35 s. Durante ~0,25 s **no recibe daño** (que `Player.take_damage` lo ignore). Gasta aguante
   (`StaminaComponent.use_stamina`; sin aguante no rueda) y tiene una espera corta (~0,6 s). Choca con las paredes como al
   andar. **No** se puede rodar montado a caballo ni dentro de un menú; rodar rompe el sigilo.
2. **Parar (Q):** al pulsar Q se abre una ventana corta (~0,2 s). Si un golpe **cuerpo a cuerpo** llega dentro de esa
   ventana: no hace daño, el atacante queda **tambaleándose** (~0,8 s sin poder pegar; usa el aturdimiento que ya exista si
   encaja) y sale un aviso/destello. Si no llega nada, espera ~0,5 s antes de poder volver a parar. Flechas y balas no se
   paran. **Ojo:** Q ya sirve para el derribo no letal por la espalda cuando hay objetivo de sigilo
   (`PlayerCombatController`, `current_prompt_target`); eso tiene prioridad, la parada solo cuando no hay ese objetivo.
3. **Golpes con aviso (para que parar sea justo):** antes de cada golpe cuerpo a cuerpo, los atacantes hacen un gesto
   visible de ~0,4 s (destello o «!» en 2D y el inicio de la animación de ataque en 3D) y el daño llega al final, solo si
   el jugador sigue a su alcance. Aplícalo a vecinos hostiles y guardias (`VillageNPC._process_hostile_combat`), asaltantes
   (`Raider`), perros hostiles y jabalíes. No cambies cuánto daño hacen.
4. **Animaciones del muñeco 3D:** la biblioteca de animaciones del jugador (`assests/curated_3d/animations/ual_male.res`)
   **no** tiene rodar ni bloquear. Si puedes conseguir esas animaciones de la *Universal Animation Library* de Quaternius
   (CC0) y añadirlas como se hizo con las demás (`tools/bake_character_animations.gd`), mejor; si no, hazlo con movimiento
   del propio muñeco (agacharse y girar al rodar, brazos arriba al parar). Explica en el informe qué elegiste.
5. **Ayuda en pantalla:** añade «[Espacio] Rodar · [Q] Parar» donde se listan los controles.

### 2.1 Pruebas del bloque

- Un test por comportamiento: durante el rodar no se recibe daño; sin aguante no se rueda; una parada a tiempo anula el
  golpe y deja al atacante sin pegar un rato; parar a destiempo no protege; el golpe del enemigo llega tras su aviso, no
  al instante; con objetivo de sigilo, Q sigue haciendo el derribo.
- Arranque sin errores (`--headless --quit-after 3`) y las cuatro pruebas de HANDOFF §3. El usuario ya ha dado permiso.

## 3. Al cerrar el bloque

1. `docs/HANDOFF.md` §7: una entrada arriba con lo técnico.
2. `CHANGELOG.md`: entrada en lenguaje de jugador.
3. `docs/REGISTRO_TRABAJO.md`: fila del bloque en el «Bloque FIS».
4. Bóveda: notas de los sistemas tocados («Notas de diseño»), tarjeta en `GameVault/05_Roadmap_y_Lore/Tablero.md` y
   línea en el diario del día (`GameVault/06_Diario/`).
5. Commit con mensaje en español y push a `main`.
6. `docs/INFORME_ANTIGRAVITY.md` para el supervisor (ver §0). **Reescríbelo entero** para este bloque.
7. Al usuario: resumen corto en lenguaje de jugador, sin código, y una sola pregunta al final.
