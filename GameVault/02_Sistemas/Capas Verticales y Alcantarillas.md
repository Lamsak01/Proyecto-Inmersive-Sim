---
tipo: "sistema"
area: "mundo"
estado: "parcial"
codigo: "PN"
tags:
  - "mecanica"
  - "mundo"
  - "sistema"
fuente: "Biblia §9.6"
---
# Capas Verticales y Alcantarillas

> Sección original: *Niveles Verticales (`-1 / 0 / +1`), Alcantarillas y Terminales (`PN`, `PO.2`)*

- **Capas Verticales estilo *Project Zomboid* (`PN.1`, `0f796bd`):**
  - Nivel `0` (calle y planta baja), Nivel `+1` (segunda planta / altillo de casas ampliadas) y Nivel `-1` (sótanos y red de alcantarillas).
  - Sólo se puede cambiar de planta estando **dentro de casa (`≤ 90 px` de un solar propio)**, y si el jugador se aleja más de **70 px** del punto de escalera (`_elevation_anchor`), vuelve automáticamente al nivel `0` para que nadie pueda usar los pisos como invisibilidad ante los testigos de la calle.
- **Alcantarillas bajo el Pueblo (`PN.2`):** Red subterránea con accesos en rejillas, escondites de contrabandistas y hallazgos perdidos.
- Ver [[Terminales Lógicas Electromecánicas]].

## Notas de diseño
-
