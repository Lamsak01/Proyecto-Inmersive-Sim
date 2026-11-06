---
tipo: "sistema"
area: "mundo"
estado: "implementado"
codigo: "PO.2"
tags:
  - "sistema"
  - "mundo"
fuente: "Biblia §9.6"
---
# Terminales Lógicas Electromecánicas

Parte de [[Capas Verticales y Alcantarillas]] · Requiere [[Red Eléctrica]]

- **Terminales Lógicas Electromecánicas (`PO.2`):** Presentes junto al **Taller de Reparaciones (Arreglador)**. Permiten consultar o piratear (`hack_terminal`) tres registros antiguos cuando hay corriente eléctrica:
  1. `census_registry` (censo y expedientes ocultos del valle).
  2. `grid_override` (sobrecarga o control remoto de la red eléctrica).
  3. `warrant_archive` (borrado de órdenes de búsqueda policial, compartiendo el **enfriamiento de 7 días** con el sótano secreto y el pasadizo del contrabandista).

## Notas de diseño
- 2026-11-05 (Antigravity, Bloque FIS2): la **Terminal Lógica Electromecánica** es ahora una máquina física real sobre su propia mesa dentro del Taller de Reparaciones (`solar e5`, `Vector2(1188, 122)`), visible en 2D y 3D. Se usa acercándose a la máquina y pulsando `[E] Usar la Terminal Lógica` (retirada del diálogo del chapuzas). Si el chapuzas u otro vecino consciente y despierto te ve manipularla en la misma planta (`_find_conscious_witness_near`), sube `wanted_level + 1` y baja su afinidad.
