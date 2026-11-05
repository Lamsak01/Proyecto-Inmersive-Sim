---
tipo: "sistema"
area: "mundo"
estado: "implementado"
codigo: "PJ.1"
tags:
  - "mecanica"
  - "mundo"
  - "sistema"
fuente: "Biblia §9.2"
---
# Red Eléctrica

> Sección original: *Red Eléctrica Lógica de 3 Circuitos (`PJ.1`)*

El valle conserva una instalación electromecánica alimentada por el **Generador Antiguo**:
1. **Circuito de Farolas (`streetlights`):** Ilumina las calles de noche, reduciendo los robos nocturnos y mejorando la visión.
2. **Circuito de Riego (`irrigation`):** Alimenta las bombas de agua y los aspersores automáticos de los huertos.
3. **Circuito del Generador y Talleres (`generator`):** Da potencia a las máquinas de precisión y a las [[Terminales Lógicas Electromecánicas]].
- **Sabotaje y Reparación (`cd18e1c`):** Cualquier circuito puede sufrir averías o ser saboteado (si un testigo cercano te ve sabotearlo, te denuncia; y si lo saboteaste tú mismo, arreglarlo después no te paga recompensa). Reparar la red requiere que el generador principal esté encendido (`_generator_on()`).

## Notas de diseño
-
