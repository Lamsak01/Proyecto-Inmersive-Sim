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
- **Fundar tu Propio Negocio — «Bazar del Forastero» (`P6.12`):**
  - Empieza con `stock 0` y un inventario real de mercancías (`goods`).
  - Cada artículo se vende a su precio real de mercado a vecinos que tengan al menos `precio + 12 de oro`.
  - Puedes contratar a un **dependiente** y pagar **publicidad**.
  - **Riesgo de robo nocturno (`shop_night_theft`):** `18%` de probabilidad cada noche (`7%` si tienes dependiente) de que un ladrón robe la mitad de la caja, pasando ese oro al vecino más pobre del pueblo.

## Notas de diseño
- 2026-11-06 (Claude Code): precio según el tamaño (casita 80, casa 100, casona 140). Cada vecino busca la que puede pagar; la reventa también depende del tamaño. Decidido por el usuario.
- 2026-11-06 (Claude Code): tres tamaños de casa. Cada solar tiene el suyo (casita 2 camas, casa 2, casona 3). Quien
  se hipoteca o a quien paga el pueblo busca casita; quien va justo, casa; quien tiene ahorros de sobra, casona.
  Barrios apartados nuevos: Barrio del Lago (4 solares), Caseríos del Bosque (3) y Molino del Este (2). Los vecinos
  huraños los prefieren; el resto los ocupa cuando el centro se llena. Comprobado que los vecinos llegan andando.
-
