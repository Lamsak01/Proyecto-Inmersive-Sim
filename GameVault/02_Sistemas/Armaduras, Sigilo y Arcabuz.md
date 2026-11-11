---
tipo: "sistema"
area: "combate"
estado: "parcial"
codigo: "PO.1"
tags:
  - "sistema"
  - "supervivencia"
  - "combate"
  - "ecosistema"
fuente: "Biblia §3.3"
---
# Armaduras, Sigilo y Arcabuz

> Sección original: *Armaduras, Sigilo, Ruido y Armas Especiales*

- **4 Ranuras de Armadura (`[I]`):** `Casco`, `Pecho`, `Piernas` y `Botas` en 3 calidades (`Cuero Curtido`, `Hierro Forjado`, `Acero Maestro`), que reducen daño físico y probabilidad de sangrado/fractura.
- **Sigilo y Percepción:**
  - Agacharse reduce el radio de las ondas de ruido al caminar.
  - Los NPCs sólo ven dentro de su **cono de visión (`VisionCone2D`)** y comprueban **línea de visión real sin muros (`has_line_of_sight`)**.
  - Si un guardia te ve entrar en una zona prohibida y luego doblas una esquina, investiga tu **última posición conocida (*Ghost Search*)** antes de volver a su patrulla.
- **Arcabuz de Chispa (`PO.1`, `#mecanica`):**
  - Se compra en la Herrería por **95 de oro** y utiliza cargas de **pólvora y plomo** (**12 de oro** por 3 disparos en la Botica o con el perista).
  - Suma **`+2` al poder de defensa** del pueblo frente a [[Incursiones y Defensa|incursiones exteriores]]. *(Nota: dispararlo directamente en combate de mundo abierto está reservado como ampliación futura en [[Pendientes e ideas]]; se retiró del diálogo para no permitir ataques desde menús).*
- **Esquiva rodando (`[Espacio]`) y Parada cuerpo a cuerpo (`[Q]`) (`COMBATE-1`, `#mecanica`):**
  - **Rodar (`[Espacio]`):** voltereta corta en la dirección de movimiento (o de mirada si estás quieto) que evita todo daño en su tramo inicial, consume aguante, choca con las paredes, rompe el sigilo y no puede usarse montado a caballo.
  - **Parar (`[Q]`):** abre una ventana breve (`~0,2 s`) que anula cualquier golpe cuerpo a cuerpo enemigo y deja al atacante desequilibrado (`~0,8 s`) sin poder pegar; si estás en sigilo detrás de una víctima, `[Q]` conserva la prioridad para el derribo no letal. Las flechas y balas no se pueden parar con `[Q]`.
  - **Golpes enemigos con aviso (`~0,4 s`):** vecinos hostiles, guardias, asaltantes, perros enfadados y jabalíes avisan durante `~0,4 s` antes de descargar su golpe cuerpo a cuerpo (y solo impactan si sigues a su alcance al terminar el aviso).

## Notas de diseño
- 2026-11-10 (Claude Code, paso a 3D 5a): quién te ve se decide con alturas de verdad: paredes y puertas cerradas tapan, y los suelos altos también (desde el salón de la posada se ve a quien se asoma a la galería, no a quien está justo encima). Bajo tierra nadie te ve desde la calle. El oído (5b): un ruido llega a otro piso a un tercio (por la galería abierta, entero) y entre la calle y bajo tierra a un décimo. Golpes y disparos (5c): los golpes alcanzan a quien está a tu altura; flechas y balas vuelan con altura (en 1.ª persona hacia donde miras) y solo hieren a quien está a esa altura.
- 2026-11-06 (Claude Code): **rehacer el combate, fase 1 «peso y respuesta»** (plan completo en `docs/PLAN_COMBATE.md`). Cada arma tiene preparación, golpe y recuperación propios (martillo lento y pesado, hoz rápida); paso adelante al golpear; andas más despacio y no puedes girar el golpe a medias; el que recibe sale empujado y se tambalea un instante; chispa, sonidos (antes no había ninguno), congelado y temblor según el peso. Al recibir tú: quejido, temblor y empujón. Siguen: rivales con las mismas reglas, cadena de golpes y golpe cargado, consecuencias (zonas, mellas, desarmar).
- 2026-11-06 (Claude Code): **fase 2 «rivales con las mismas reglas»**. Guardias, vecinos, bandidos y jabalíes hacen zumbido al soltar el golpe; tras dar se quedan quietos un instante y tras fallar más rato (ventana para castigarles); su golpe te empuja según el arma (colmillos > porra > puños). El tamaño cuenta: un jabalí pesa como dos personas y media y apenas se mueve; conejos y mascotas salen despedidos.
- 2026-11-06 (Claude Code): **fase 3a**. Espada: pulsar justo al acabar un golpe encadena otro (hasta 3; el 3.º lento y fuerte). Martillo y hacha: mantener el clic carga el golpe (más daño, empuja y tumba; más energía; andas despacio mientras cargas).
- 2026-11-06 (Claude Code): **fase 3b**. Mantener Q tras la parada levanta la guardia (pasa un 30 % del golpe a cambio de energía; sin energía se rompe; no sirve contra disparos). X empuja con el hombro: aparta y desequilibra, casi sin daño, pero es agresión.
- 2026-11-06 (Claude Code): **fase 4 «consecuencias»**. La zona herida depende de la dirección (animales → piernas; por la espalda → espalda y nuca; de lado → ese lado). Las armas del jugador se mellan con el uso (pegan hasta un 35 % menos) y el herrero las arregla por oro. Un golpe fuerte al brazo desarma a guardias (sin porra ni pistola un rato) y bandidos.
- 2026-11-07 (Antigravity, B1): **ruido y testigos en combate (cierra C7)**. Golpes fuertes, gritos de dolor y disparos emiten ruido en el mapa (`AudioManager.emit_noise`); los guardias despiertos dentro del radio acuden a mirar o intervenir, los vecinos pacíficos huyen o se asoman a distancia, y solo cuentan como testigos (`known_by` / `sighting_log`) si tienen línea de visión en la misma planta.
