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
-
