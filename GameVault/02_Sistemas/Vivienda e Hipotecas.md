---
tipo: "sistema"
area: "vivienda"
estado: "implementado"
codigo: "P6"
tags:
  - "economia"
  - "vivienda"
  - "sistema"
fuente: "Biblia §4.4"
---
# Vivienda e Hipotecas

> Sección original: *Vivienda, Hipotecas, Alquileres y el «Bazar del Forastero» (`P6`, `H`)*

- **Compra de Solares e Hipotecas:** El jugador y los vecinos con ahorros compran solares vacíos al contado o mediante **préstamo hipotecario** (`+25%` de interés total, cuota de **3 de oro al día**, desahucio tras **5 impagos**). En el diálogo se exige **doble confirmación** antes de firmar una deuda.
- **Reformas del Carpintero (`P6.4`):** *Estantería, banco de trabajo, cama de roble, cerradura reforzada, sótano secreto, hogar de leña* y *altillo de segunda planta* (`+1` planta vertical y más camas).
- **Vida Doméstica y Terrateniente:** Dormir en tu cama, guardar objetos en el cofre privado, **escondite bajo las tablas del suelo** (`P6.10`, inmune a registros policiales), defender tu puerta de intrusos nocturnos (`P6.5`), mudarte con tu pareja (`P6.6`), organizar **cenas o fiestas en casa** (`P6.9`), reformar casas para revenderlas saldando antes la hipoteca (`P6.2`) o **alquilar casas tuyas a vecinos sin techo** cobrando renta diaria (`P6.7`).
- **Fundar tu Propio Negocio — «Bazar del Forastero» (`P6.12`, físico en `P1`):**
  - En el solar de tu tienda (`player_shop["lot"]`) aparece un **mostrador físico con caja** (`"player_shop_counter"`, 2D y 3D) que se usa pulsando `[E]` para **reponer mercancía** de tu mochila (`goods`, empieza con `stock 0`, hasta 6 artículos por pulsación con `SHOP_STOCK_PER_PRESS = 6`) y **recoger la recaudación** (`till_gold`); esas dos opciones ya no están en conversación con vecinos.
  - Contratar a un **dependiente** (`4 de oro/día` descontados de la caja) y pagar **publicidad** (`10 de oro` por 3 días con más clientela) siguen tratándose hablando con los vecinos.
  - En horario comercial (`8:00–18:00`), el dependiente contratado camina de verdad hasta detrás del mostrador (`"player_shop_clerk"`) y permanece allí; **si no está en el mostrador, la tienda no vende**.
  - Durante el día, vecinos con al menos `precio + 12 de oro` caminan hasta el mostrador (`"player_shop_buy"`) y compran 1 artículo pagando su precio real de mercado desde su propio bolsillo (`personal_gold` → `till_gold`, suma cero), sin ventas automáticas a medianoche.
  - **Riesgo de robo nocturno (`shop_night_theft`):** `18%` de probabilidad cada noche (`7%` si tienes dependiente) de que un ladrón robe la mitad de la caja no recogida, pasando ese oro al vecino más pobre del pueblo.

## Notas de diseño
- 2026-11-06 (Antigravity, Bloque P4): las cenas con vecinos (`"dinner"`, a las 20:00) y las fiestas en tu casa (`"party"`, a las 21:00) ya no ocurren al instante en el diálogo. En tu casa construida aparece una **mesa de comedor** (`"home_table"`, 2D y 3D) con 6 asientos a `14 px` (`set_poker_seating`). Pulsando `[E]` en la mesa puedes **poner comida de tu mochila** (`2` raciones por invitado) o **convocar una fiesta** para esa noche a las 21:00 e ir invitando uno a uno hasta 6 vecinos hablando con ellos; alternativamente, puedes contratar **cáterin** hablando con la posadera (`4` de oro por invitado con doble `[E]`, `pay_into`), quien camina a tu mesa 1 h antes y deja las raciones listas (si no llega a tiempo, el oro vuelve a ti y no empieza). Los invitados caminan a la hora señalada (`start_errand("gathering", seat_pos)`), se sientan durante 2 h charlando cada 20 min y, si estás a `< 90 px` al terminar, se aplican los beneficios sociales; si ven la mesa vacía al llegar o si te marchas antes, se van enfadados (`-5` afinidad).
- 2026-11-06 (Claude Code, Bloque P5): la renta de tus locales ya no salta sola a tu mochila el sábado: se **aparta** y vas a recogerla al taller, con el dueño presente. Se acumula hasta 3 semanas; si no vas, el artesano se la gasta.
- 2026-11-06 (Antigravity, Bloque P1): el «Bazar del Forastero» pasa a ser físico en 2D y 3D. El solar de la tienda tiene un mostrador con caja interactivo con `[E]` (`"player_shop_counter"`) desde donde se repone mercancía de la mochila y se recoge la recaudación (quitado del diálogo con vecinos; publicidad y contratación siguen en conversación). El dependiente camina de verdad al mostrador de 8:00 a 18:00 (`"player_shop_clerk"`, excluido de cuadrillas de jornaleros en `VillageWork.hire`) y sin él en su puesto no hay ventas; los clientes van andando durante el día (`"player_shop_buy"`) y pagan de su propio oro al llegar al mostrador, eliminando las ventas automáticas de medianoche en `VillageHousing.daily`.
- 2026-11-06 (Claude Code): PROVISIONAL, la partida nueva empieza con unos 40 vecinos para probar todos los sistemas (pedido por el usuario). Las casas de los recién llegados ya están levantadas en solares libres; llegan sin oficio, como los que vienen andando. Se apaga poniendo el número a cero.
- 2026-11-06 (Claude Code): paso 2 de la aldea. Las callejas del norte curvan y las casas de cada fila se escalonan; dos solares (u3, e1) pasan a ser el Pozo de la Ronda (sirve de verdad) y un huerto vecinal de adorno. Sin partidas guardadas, se movió todo (dicho por el usuario).
- 2026-11-06 (Claude Code): precio según el tamaño (casita 80, casa 100, casona 140). Cada vecino busca la que puede pagar; la reventa también depende del tamaño. Decidido por el usuario.
- 2026-11-06 (Claude Code): tres tamaños de casa. Cada solar tiene el suyo (casita 2 camas, casa 2, casona 3). Quien
  se hipoteca o a quien paga el pueblo busca casita; quien va justo, casa; quien tiene ahorros de sobra, casona.
  Barrios apartados nuevos: Barrio del Lago (4 solares), Caseríos del Bosque (3) y Molino del Este (2). Los vecinos
  huraños los prefieren; el resto los ocupa cuando el centro se llena. Comprobado que los vecinos llegan andando.
- 2026-11-05 (Antigravity, Bloque FIS-P1): las mejoras de tu propia casa (`VillageHousing.sync_home_props` y `WorldStage3D._sync_home_props_3d`) existen como objetos físicos en 2D y 3D que usas con `[E]` en tu solar: **huerto doméstico** (`"home_garden"`, cosecha `+1 pan` y `+1 hierba medicinal` cada 2 días), **banco de trabajo y alquimia** (`"home_workbench"`, prepara `+1 cataplasma` o destila `2 polvo de ocaso`), **escondite bajo las tablas** (`"home_stash"`, guarda o saca oro oculto en el suelo de tu casa) y **escalera/trampilla** (`"home_stairs"`, sube al altillo `+1`, baja al sótano `-1` o te esconde en el sótano). Ya no caen objetos solos a medianoche en tu mochila ni se usan estas mejoras hablando con el carpintero o los vecinos.

