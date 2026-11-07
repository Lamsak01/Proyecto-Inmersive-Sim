---
tipo: "sistema"
area: "economia"
estado: "implementado"
codigo: "F1-F4"
tags:
  - "economia"
  - "vivienda"
  - "sistema"
fuente: "Biblia §4.5"
---
# Casino de la Posada

> Sección original: *El Casino de la Posada «El Jabalí Dorado» (`[F1]`–`[F4]`)*

Al sentarte a una mesa de juego en la posada, **el reloj del mundo se pausa** y los vecinos que están físicamente en la sala se sientan contigo apostando su propio oro:
- **`[F1]` Póker Texas Hold'em:** Evaluador completo de 7 cartas, rondas de apuestas y **gestos psicológicos (*tells*)** según los rasgos del rival (*Nervioso*, *Sereno*, *Tahúr*, *Mentiroso*).
- **`[F2]` Blackjack 21:** Reglas de casino (`S17`, pago `3:2`), doblar y plantarse.
- **`[F3]` Ruleta Europea:** 37 casillas (`0` a `36`), apuestas plenas, colores, docenas y par/impar.
- **`[F4]` Billar 2D:** Mesa con física de bolas, taco apuntado con ratón y control de fuerza.

## Notas de diseño
- **Gran Taberna «El Jabalí Dorado» de 2 plantas (`VillageTavern.gd`, `WorldStage3D.gd`):**
  - **Planta Baja (`Planta 0`, `Rect2(260, -316, 348, 184)`):** dividida en 4 salas: **Gran Salón y Comedor** (chimenea de piedra y 6 mesas con 12 sillas donde los vecinos se sientan a comer y beber), **Barra y Cocina** (con Marta atendiendo detrás del mostrador de caoba, pasa-platos, fogones y toneles), **Sala de Casino y Billar** (mesa de póker con 4 sillas ocupadas por jugadores y mesa de billar 3D de caoba con 6 troneras, paño verde esmeralda, bolas en triángulo y tacos) y **Vestíbulo de Escalera y Bodega** (con la escalera real de 12 peldaños hacia la planta alta y la trampilla secreta al **Club de la Lucha** en `Vector2(516, -286)`, abierta todas las noches de `21:00` a `03:00`).
  - **Primer Piso (`Planta +1`, `h = 22.0`):** galería con barandilla asomada al salón y **5 cuartos de huéspedes** que alojan las **6 camas reales** de la posada.
  - **Camarero (`TradeRole.WAITER` = 26):** recorre las mesas con comensales sentados, toma nota del pedido, acude al pasa-platos de la barra (`PASS_COUNTER_POS`) y sirve jarras y platos calientes en la mesa.
