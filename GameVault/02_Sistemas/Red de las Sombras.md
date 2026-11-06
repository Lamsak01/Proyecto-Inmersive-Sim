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
- 2026-11-06 (Claude Code, Bloque P5): la «protección» se cobra en persona en el local (con riesgo si te ve un guardia: búsqueda +1); si faltas dos sábados seguidos, el local deja de pagarte y te pierde el miedo. El tributo de Jefe del Hampa se recoge hablando con el perista de noche (se acumula hasta 3 semanas).
- 2026-11-06 (Claude Code, Bloque P5b): el perista **se deja ver de noche**: de 22:00 a 3:00 espera despierto en el callejón de detrás de la taberna, con capa oscura y capucha; si no lo conoces, su letrero es «Hablar con la figura encapuchada». En la taberna, de 19:00 a 1:00, algún vecino de dudosa reputación suelta muy de vez en cuando un comentario de pasada (máx. uno al día en el pueblo).
- 2026-11-05 (Antigravity, Bloque FIS2): los **3 objetos de los grandes robos** (`HEIST_TARGETS`) están dentro de sus edificios reales (`sello_noble` en `Vector2(1275, -444)` en el escritorio de la Mansión `solar f1`; `caliz_capilla` en `Vector2(745, 336)` en el altar de la Capilla; `libro_gremial` en `Vector2(764, -444)` en la mesa del Ayuntamiento `solar n4`). Mientras hay un golpe activo sin robar, el objeto aparece en 2D y 3D con `[E] Robar …` y desaparece al robarlo o entregarlo.
- 2026-11-05 (Antigravity, Bloque FIS3): el perista sigue vendiendo la llave de hierro de las alcantarillas (`20` de oro a su bolsillo), pero ya no se exploran por menú de diálogo: ahora usas `[E]` en las **3 rejillas de la calle** para bajar a los túneles subterráneos caminables, abrir los **3 cofres de contrabando** y subir por cualquiera de las **3 escalerillas**.
- 2026-11-05 (Antigravity, Bloque FIS3b): usar `[E]` para bajar por una rejilla o subir por una escalerilla delante de un guardia o del comisario sube en `1` tu búsqueda (`wanted_level`) y muestra un aviso flotante (sin bloquear el paso); si quien te ve es un vecino cualquiera, no hay delito pero recuerda haberte visto y corre el chisme por el pueblo (`record_social_event("player_secret", ...)`).
- 2026-11-05 (Antigravity, Bloque FIS-P1): destilar «polvo de ocaso» (`underworld_cook_dust`) ya no se hace hablando con el perista tras la taberna, sino pulsando `[E]` sobre el **banco de trabajo y alquimia** físico (`"home_workbench"`) dentro de tu casa (-25 de oro en reactivos que van al perista, con comprobación de testigos en la misma planta si no estás a solas o en el sótano).
- 2026-11-06 (Antigravity, Bloque P3): la **caravana nocturna de contrabando** acampa físicamente en el claro noreste al norte de la mansión (`SMUGGLER_CAMP_POS = Vector2(1350, -560)`) de 22:00 a 4:00 las noches de contrabando (`(today() - 1) % 3 == 0`), con «El Encapuchado», su carro (`fantasy_town/cart.glb`) y un farol tenue (`fantasy_town/lantern.glb`). Comprar lotes (con doble `E`) y vender «polvo de ocaso» se hace en el carro (ya no con el perista); si hay un guardia despierto a `< 160 px` con línea de visión sube `wanted_level` y la caravana huye, y al delatarla dos guardias caminan hasta el campamento (`smuggler_bust`) para desmantelarlo.
