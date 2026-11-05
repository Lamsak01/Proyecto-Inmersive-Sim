---
tipo: "sistema"
area: "economia"
estado: "implementado"
tags:
  - "economia"
  - "vivienda"
  - "sistema"
fuente: "Biblia §4.1"
---
# Economía de Oferta y Demanda

> Sección original: *Economía Cerrada de Oferta y Demanda*

- **Precios Dinámicos en Vivo:** Cada taller evalúa sus existencias y aplica un multiplicador real:
  - `0.80x` (**Excedente** — almacén lleno)
  - `1.00x` (**Estable**)
  - `1.55x` (**Escasez** — faltan materias primas)
  - `2.25x` (**Crisis / Sabotaje** — taller dañado o desabastecido)
- **Cadena Productiva Física:** De `06:30` a `09:30`, los artesanos y sus ayudantes salen físicamente al bosque, lago o cantera a recolectar insumos, o van al taller vecino a comprar lo que les falta pagando de la caja del negocio (`vault_gold`).
- **Propiedad Híbrida de Negocios:** Con suficiente reputación y oro, el jugador puede convertirse en **Socio al 50%** (reparto diario de dividendos) o **Dueño Único al 100%** (control total de la caja, reposición de materias primas y contratación de ayudantes).

## Notas de diseño
- 2026-11-05 (Claude Code): auditoría Regla 1. Tus negocios ya no ganan una «base» diaria del aire: cada venta la paga un vecino con oro. Abastecer una tienda ajena lo paga su dueño. Apuestas contra el posadero; jornales pagados por un taller con oro.
-
