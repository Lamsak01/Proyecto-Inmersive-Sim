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
- 2026-11-05 (decisión del usuario): bajar o subir por una rejilla a la vista de un guardia es sospechoso (sube la búsqueda). Oveja = alpaca y gallina de piezas, provisional hasta una pasada de arte.
- 2026-11-05 (Claude Code): el sótano de tu casa y las alcantarillas comparten el nivel -1, pero ya se distinguen: solo estás en las alcantarillas si entraste por ellas (así no sale la escalerilla en tu sótano ni se ven las alcantarillas en 3D).
- 2026-11-05 (Antigravity, Bloque FIS3): las alcantarillas se recorren a pie de verdad: hay **3 rejillas en la calle** (`SewerGrate_cistern` en `(518, 26)`, `SewerGrate_smuggler_tunnel` en `(398, -118)` y `SewerGrate_flooded_vault` en `(248, -90)`), una red subterránea de **3 cámaras conectadas por galerías** con muros físicos (`SewerTunnelWallsBody` en `y = 1520`, `x = 205..635`), **3 escalerillas de salida** (`SewerLadder_*`, permitiendo entrar por una rejilla y salir por otra; salir por el Pasadizo del Contrabandista rebaja `wanted_level` en 1 una vez por semana) y **3 cofres de contrabando** (`SewerChest_*`, 1/día por cámara, suma cero de `lost_coins_pool`). Retiradas del diálogo del perista las opciones de texto de explorar/subir.
- 2026-11-05 (Antigravity, Bloque FIS3b): bajar por una rejilla (`interact_sewer_grate`) o salir por una escalerilla (`exit_sewer_ladder`) comprueba testigos conscientes en la calle (`vm._find_conscious_witness_near(check_pos, 120.0, null)`). Si te ve un guardia o el comisario, bajas/sales igual pero sube +1 la búsqueda (`wanted_level`) con aviso flotante («¡X te vio colarte en las alcantarillas!»); si te ve un vecino cualquiera, no sube la búsqueda pero queda un chisme (`record_social_event("player_secret", ...)`) y un recuerdo (`add_thought`).
