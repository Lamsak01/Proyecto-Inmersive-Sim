---
tipo: "sistema"
area: "crimen"
estado: "implementado"
codigo: "S1-S6, D1-D6"
tags:
  - "social"
  - "crimen"
  - "clanes"
  - "linaje"
fuente: "Biblia §7.3"
---
# Secretos y Deseos Propios

> Sección original: *Secretos, Deseos Propios y Asesinatos Autónomos (`S1–S6`, `D1–D6`, `V8`)*

- **Secretos y Chantajes (`S1–S6`):** Infidelidades, robos, sabotajes y desfalcos quedan guardados con su lista exacta de conocedores (`known_by`). Un vecino con rasgo *Chantajista* o *Codicioso* exige pagos semanales en oro a cambio de su silencio; la víctima puede pagar, confesar antes de que la delaten o planear deshacerse del chantajista.
- **Deseos Propios (`D1–D6`):** Cada día los vecinos evalúan sus ambiciones y rencores:
  - **Ambición de Taller:** Si muere un maestro sin heredero, los ayudantes y vecinos ambiciosos compiten por quedarse con el negocio.
  - **Venganza y Crimen Pasional:** Un vecino traicionado o lleno de odio (`<= -75`) empieza a seguir a su víctima, compra veneno o ronda su casa de noche (**señales previas visibles** para que el jugador pueda advertir a la víctima o detenerle) y, si nadie interviene, comete un **asesinato real** cuando no hay testigos cerca.

## Notas de diseño
- 2026-11-07 (Antigravity, Bloque B5): cuando un vecino alberga un deseo activo de **venganza o asesinato** (`"revenge"` o `"murder"`), las noches previas (`22:00–04:00`) sale con el recado `"prowl_victim"` a **merodear los alrededores de la casa de su víctima** (`prowl_spot_for_desire`), cambiando de esquina y soltando bocadillos cortos de 1,5 s si pasas cerca para que puedas descubrir sus intenciones sin abrir menús.
