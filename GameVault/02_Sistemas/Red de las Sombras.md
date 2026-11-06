---
tipo: "sistema"
area: "crimen"
estado: "implementado"
codigo: "P7"
tags:
  - "medicina"
  - "crimen"
  - "sistema"
fuente: "Biblia §5.4"
---
# Red de las Sombras

> Sección original: *Bajos Fondos y la «Red de las Sombras» (`P7 Underworld`)*

- **El Perista Nocturno (`P7.1–P7.3`):** Opera de noche (`21:00–04:00`). Compra objetos robados a mitad de precio y vende **ganzúas**, **veneno lento**, **somnífero**, **lejía** y **papeles falsos** para limpiar antecedentes menores.
- **Destilar y Vender «Polvo de Ocaso» (`P7.4`):** Alquimia clandestina con setas nocturnas; da grandes beneficios pero engancha a los compradores y alerta al comisario y al sacerdote.
- **Caravana de Contrabando de Medianoche (`P7.5`):** Llega cada **3 días** de madrugada al borde del mapa con **3 lotes por visita**; comprar y vender exige esperar al siguiente viaje (imposible revender en el mismo turno).
- **Golpes por Encargo (`P7.6`):** El jefe del hampa señala un objetivo real; debes ir físicamente al lugar (`≤ 110 px`) para ejecutar el golpe (con riesgo de testigos) y el botín sale del bolsillo de la víctima.
- **Usura, Extorsión y Red de Carteristas (`P7.7–P7.10`):**
  - Prestar oro con intereses abusivos que vencen a los 4 días.
  - Cobrar «protección» los sábados a un comerciante intimidado (sale de la caja de su tienda y puede negarse y avisar a la guardia).
  - Contratar hasta **3 carteristas** (`15%` de riesgo diario de que pillen a uno y te delate, `+15` de búsqueda).
- **Escrituras Falsas, Timbas, Club de Pelea y Liderazgo (`P7.11–P7.16`):**
  - Falsificar escrituras de un solar vacío por **55 de oro** (`30%` de riesgo de ser descubierto y multado con `+30` de búsqueda).
  - Timbas clandestinas de dados y **Club de pelea nocturno** a puño limpio apostando contra los vecinos más duros.
  - **Dos caminos finales (`P7.15–P7.16`):** Delatar a toda la red ante el Comisario Vane (recompensa de las arcas y enemistad mortal del hampa) o **retar al jefe de la «Red de las Sombras»** para quedarte con el mando de los bajos fondos.

## Notas de diseño
- 2026-11-05 (Antigravity, Bloque FIS2): los **3 objetos de los grandes robos** (`HEIST_TARGETS`) están dentro de sus edificios reales (`sello_noble` en `Vector2(1275, -444)` en el escritorio de la Mansión `solar f1`; `caliz_capilla` en `Vector2(745, 336)` en el altar de la Capilla; `libro_gremial` en `Vector2(764, -444)` en la mesa del Ayuntamiento `solar n4`). Mientras hay un golpe activo sin robar, el objeto aparece en 2D y 3D con `[E] Robar …` y desaparece al robarlo o entregarlo.
- 2026-11-05 (Antigravity, Bloque FIS3): el perista sigue vendiendo la llave de hierro de las alcantarillas (`20` de oro a su bolsillo), pero ya no se exploran por menú de diálogo: ahora usas `[E]` en las **3 rejillas de la calle** para bajar a los túneles subterráneos caminables, abrir los **3 cofres de contrabando** y subir por cualquiera de las **3 escalerillas**.
- 2026-11-05 (Antigravity, Bloque FIS3b): usar `[E]` para bajar por una rejilla o subir por una escalerilla delante de un guardia o del comisario sube en `1` tu búsqueda (`wanted_level`) y muestra un aviso flotante (sin bloquear el paso); si quien te ve es un vecino cualquiera, no hay delito pero recuerda haberte visto y corre el chisme por el pueblo (`record_social_event("player_secret", ...)`).
