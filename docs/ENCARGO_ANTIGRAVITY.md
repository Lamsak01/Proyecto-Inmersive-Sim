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

## 2. El encargo actual: bloque P1 — tu tienda propia («Bazar del Forastero») hecha física

> ANIM-1 entregado (pendiente de que el usuario lo vea en movimiento). Fila 2 de `docs/AUDITORIA_REALISMO.md`.

Ahora mismo (`VillageHousing`): abastecer el mostrador (`stock_player_shop`), vaciar la caja (`housing_collect_shop`),
pregonar (`advertise_player_shop`) y contratar dependiente (`housing_hire_clerk`) se hacen **hablando con cualquier
vecino**; el dependiente (`player_shop["clerk_key"]`) nunca va a tu solar y las ventas ocurren en el ciclo diario sin que
nadie entre a comprar.

Hay que:
1. **Mostrador y caja físicos** en el solar de tu tienda (`player_shop["lot"]`), 2D + 3D, con [E]: «Reponer mercancía»
   (lo mismo que `stock_player_shop`, desde tu mochila) y «Recoger la caja» (`till_gold`). Quita esas dos opciones de la
   charla con vecinos.
2. **El dependiente va de verdad:** en horario comercial (el mismo que los demás negocios) el vecino contratado camina
   hasta detrás de tu mostrador (`start_errand` o lo que usen los otros dependientes) y se queda allí; si no está, la
   tienda no vende. Su sueldo (`CLERK_WAGE`) sigue saliendo de la caja.
3. **Clientes de verdad:** durante el día, vecinos con oro se acercan andando a tu mostrador y compran una unidad cada uno
   (pagan de su bolsillo a la caja, suma cero), en vez de ventas hechas solas en el ciclo diario. Pregonar sigue
   atrayendo más clientes durante 3 días.
4. Pregonar y contratar pueden seguir en la charla (son tratos con personas), pero gastar oro pide doble E si se hace en
   el mundo.
5. Pruebas: un test por comportamiento (mostrador repone desde la mochila; la caja se recoge en el mostrador; sin
   dependiente presente no hay ventas; un cliente que compra paga de su bolsillo). Arranque sin errores y **una sola**
   prueba: `verify_all` con `timeout 900`. Nada de las cuatro: se pasan en las rondas de auditoría.

## 3. Al cerrar el bloque

1. `docs/HANDOFF.md` §7: una entrada arriba con lo técnico.
2. `CHANGELOG.md`: entrada en lenguaje de jugador.
3. `docs/REGISTRO_TRABAJO.md`: fila del bloque en el «Bloque FIS».
4. Bóveda: notas de los sistemas tocados («Notas de diseño»), tarjeta en `GameVault/05_Roadmap_y_Lore/Tablero.md` y
   línea en el diario del día (`GameVault/06_Diario/`).
5. Commit con mensaje en español y push a `main`.
6. `docs/INFORME_ANTIGRAVITY.md` para el supervisor (ver §0). **Reescríbelo entero** para este bloque.
7. Al usuario: resumen corto en lenguaje de jugador, sin código, y una sola pregunta al final.
