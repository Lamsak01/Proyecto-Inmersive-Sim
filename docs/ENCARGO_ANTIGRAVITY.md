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

## 2. El encargo actual: AUDITORÍA DE REALISMO + primer arreglo

> FIS3b aprobado. Ya hechos físicos: caballo, asaltos, terminal y cuadro eléctrico, objetos de los robos,
> alcantarillas, ganado, rejilla vigilada. Pedido del usuario: revisar si quedan mecánicas que no funcionan de forma
> realista y empezar a corregirlas.

### 2.1 Paso A — auditoría (sin tocar código)

Revisa todo el juego (`scripts/`) buscando mecánicas que **no ocurren de verdad en el mundo**. Señales típicas:
- se resuelven desde una opción de charla o un menú, sin ir al sitio ni usar el objeto;
- tiradas de dados instantáneas que sustituyen algo que debería verse (un viaje, una pelea, una obra, una reunión);
- objetos, dinero o comida que aparecen en la mochila o en una caja a medianoche sin que nadie los produzca o los traiga;
- personas que «trabajan», «van» o «se reúnen» solo en los datos, sin moverse en el mapa;
- cosas que solo existen como un número o un sí/no y nunca se ven en 2D ni en 3D;
- oro que nace o desaparece (Regla 1), gastos sin doble E (Regla 3), acciones de riesgo sin testigos (Regla 4).

Ya sabemos que faltan (inclúyelas en la lista, no hace falta volver a demostrarlo): tu tienda propia y las mejoras de
casa (dependiente que no va, huerto y banco de trabajo que dan cosas solos), caravanas de las rutas comerciales,
expediciones fuera del valle, cenas/fiestas/banquete de paz, la carreta.

Escribe `docs/AUDITORIA_REALISMO.md` con una tabla: **mecánica · qué pasa ahora (en palabras de jugador) · dónde está
en el código (archivo y función que EXISTAN) · cómo debería ser · coste (poco/medio/mucho) · prioridad (1 = se nota
mucho al jugar)**. Ordena por prioridad. Sé honesto: si algo ya es físico, no lo metas.

### 2.2 Paso B — arreglar SOLO la primera de la lista

- Arregla únicamente la mecánica de prioridad 1 (si es de coste «mucho», trocéala y haz solo la primera parte).
- Mismas reglas de siempre (§0, §1): todo físico, suma cero, doble E, testigos, letrero de [E], 2D y 3D.
- Si para decidir cómo debe ser hace falta una decisión de **diseño**, no la inventes: apúntala en
  `docs/PREGUNTAS_PENDIENTES.md` (sección «Abiertas») y pasa a la siguiente de la lista que no la necesite.
- Pruebas: un test por comportamiento nuevo, arranque sin errores (`--headless --quit-after 3`) y las cuatro pruebas.
- Después: documentación (§3), commit y push, y **para** (no sigas con la segunda). El supervisor revisará y te mandará
  la siguiente.

## 3. Al cerrar el bloque

1. `docs/HANDOFF.md` §7: una entrada arriba con lo técnico.
2. `CHANGELOG.md`: entrada en lenguaje de jugador.
3. `docs/REGISTRO_TRABAJO.md`: fila del bloque en el «Bloque FIS».
4. Bóveda: notas de los sistemas tocados («Notas de diseño»), tarjeta en `GameVault/05_Roadmap_y_Lore/Tablero.md` y
   línea en el diario del día (`GameVault/06_Diario/`).
5. Commit con mensaje en español y push a `main`.
6. `docs/INFORME_ANTIGRAVITY.md` para el supervisor (ver §0). **Reescríbelo entero** para este bloque.
7. Al usuario: resumen corto en lenguaje de jugador, sin código, y una sola pregunta al final.
