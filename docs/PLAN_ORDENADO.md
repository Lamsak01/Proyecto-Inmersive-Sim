# Plan ordenado: todo lo que queda pendiente, de fácil a difícil

> Hecho por Claude Code (supervisor), 2026-11-06, a partir de `docs/AUDITORIA_REALISMO.md`, `docs/VISION_Y_FUTURO.md`
> (solo lo marcado 💡 PENDIENTE), `docs/PLAN_BETA_MISTERIO.md`, `docs/COLA_DE_TRABAJO.md` y `docs/PROPUESTA_BETA.md`.
> **Ya encargado y en marcha (no repetido aquí):** P3 caravanas, P4 cenas, P5 rentas, P6 peleas y sabotajes.
> Coste: **poco** (menos de 1 bloque) · **medio** (1 bloque) · **mucho** (2 o más bloques).

## A. Poco (empezar por aquí)

| # | Qué | En palabras de jugador | De dónde sale |
|---|---|---|---|
| A1 | ✅ **Obras maestras en el taller** | La obra maestra se compra en el mostrador del taller, con el maestro allí, no hablando con él en la calle | Auditoría fila 11 |
| A2 | ✅ **Ayuda de controles** | Al empezar, una pantalla con las 8 teclas básicas | Beta §3.6 |
| A3 | **Arcabuz en el combate** | Apuntar y disparar con el ratón, no desde una charla (el disparo ya existe y hace daño) | VISION, PENDIENTE |
| A4 | ✅ **Amputación también para ti** | Si se te gangrena una herida te pueden amputar, y el médico te ofrece la prótesis (ya existe para vecinos) | VISION, PENDIENTE |
| A5 | **Que el usuario vea las animaciones** | Comprobar que los pies ya no patinan al andar y correr | Cola, ANIM-1 |

## B. Medio (un bloque cada uno)

| # | Qué | En palabras de jugador | De dónde sale |
|---|---|---|---|
| B1 | ✅ **Interior de tu casa** (ya hecho en el bloque FIS-P1 del 2026-11-05; comprobado por el supervisor el 2026-11-06) | Huerto, banco de trabajo, escondite bajo las tablas y escaleras de tu casa se usan con [E] dentro de ella, no hablando con vecinos; ya no aparece comida sola cada dos días | Auditoría fila 1 (la más prioritaria de esa lista) |
| B2 | **Peleas de gallos y carreras de animales** | Un corro de verdad y una carrera en el rancho con animales reales, en vez de una tirada en la charla | Auditoría fila 8 (aplazado por el usuario) |
| B3 | ⏸️ **Rendimiento** (medido y aparcado por el usuario el 2026-11-06: en su PC de escritorio va bien; detalle en HANDOFF) | Que el juego vaya fluido en un ordenador modesto (hoy ~10 imágenes por segundo con 40 vecinos en el portátil) | Beta §3.7 |
| B4 | ✅ **Guardar y cargar sin sustos** (2026-11-06) | Una partida larga guardando y cargando a mitad sin que se rompa nada | Beta §3.7 |
| B5 | ⏸️ **Equilibrio de los asaltos** (medido y asaltos en pausa por el usuario el 2026-11-06) | Medir si los asaltos al pueblo son demasiado fáciles o difíciles | Cola, pendiente de medir |
| B6 | ✅ **Exportar para Windows + «Léeme»** (2026-11-06; sin probar en Windows real) | El archivo para pasárselo a tus amigos, con controles y qué se espera | Beta §3.8 |
| B7 | **Pantalla de final con resumen** | Al acabar el caso: qué descubriste, a quién acusaste, si acertaste y lo más llamativo de la crónica; volver a empezar | Beta §3.5 |
| B8 | **Acusación clara** | Una forma explícita de acusar (al inquisidor o en el juicio) con confirmación y resultado | Beta §3.4 |

## C. Mucho (varios bloques)

| # | Qué | En palabras de jugador | De dónde sale |
|---|---|---|---|
| C1 | **El misterio de la beta** | El crimen ya hecho con su cadena de pistas (bosque → alquimista → nobles → criada → casa abandonada) y el reparto elegido entre vecinos reales. **La historia se piensa en casa con el usuario** (es un borrador) | Beta §5 |
| C2 | **Pistas que se tocan en el mundo** | Frascos, cartas, huellas que llevan a una casa… con [E] y letrero | Beta §3.3 (necesario para C1) |
| C3 | **Cuaderno del detective** | El registro de misiones muestra pistas, sospechosos y siguiente paso | Beta §3.2 (necesario para C1) |
| C4 | **Expediciones fuera del valle** | Ir andando al borde del valle (solo o con guía), viajar unas horas o explorar una zona pequeña y volver cargado | Auditoría fila 7 |
| C5 | **Puesto del Paso en el mapa** | El asentamiento fronterizo con casas, colonos y caminos, no solo menús | VISION, PENDIENTE |
| C6 | **Pasada de arte** | Conejo y gato que aún se ven planos, jabalí con aspecto de lobo, oveja con aspecto de alpaca | Propuesta beta §3.7 |
| C7 | 🔄 **Rehacer el combate** (fase 1 hecha el 2026-11-06; plan en `docs/PLAN_COMBATE.md`) | Que pegar se sienta con peso y respuesta (hoy «flojo, sin peso, incompleto, sin feedback», palabras del usuario). Aplazado; plan propio antes de empezar | Usuario, 2026-11-06 |

## D. Ideas que necesitan antes una decisión del usuario (no empezar sin su sí)

- **La secta:** encargos para el jugador, captar al comisario o al alcalde, lugar de reunión propio, varias sectas…
  (VISION). El usuario se reserva la secta: no se toca sin orden expresa.
- **Prostitución:** solo implícita y fuera de cámara, si se hace (VISION). Se puede quitar sin perder nada.

## Orden que recomienda el supervisor

1. Terminar P3 → P6 (en marcha).
2. **A1–A4** (rápidos, uno detrás de otro) y **B1** (interior de tu casa: era la prioridad número 1 de la auditoría).
3. Para la beta: **B8, B7, C2, C3 y C1** cuando la historia esté pensada; luego **B3, B4, B6**.
4. El resto (B2, B5, C4–C6) cuando haya hueco.
