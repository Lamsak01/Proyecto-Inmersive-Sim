# ⭐ ENCARGO DE HOY — Río, arroyo y molino del Caso I + retoques de interiores
Modo demo activo. No crees sistemas nuevos. **No muevas edificios existentes** (hay ~2.400 posiciones fijas): si el
río choca con algo, que lo rodee; si no se puede, anótalo en el informe para el usuario.

**1. El río (decidido por el usuario):** cruza el pueblo **de norte a sur**, en el mapa actual.
- Agua de verdad en 3D que no se puede caminar (no repetir el fallo de «caminar sobre el agua»); orillas naturales,
  no rectas. Se puede pescar donde tenga sentido.
- **Puente viejo de piedra/madera en el centro del pueblo** (es el «puente viejo» de la nota «V.» del caso) y algún
  vado o puente más donde lo pidan los caminos. Vecinos y jugador cruzan solo por puentes y vados: comprueba que las
  rutas de los vecinos no se rompen ni atraviesan el agua.
- **El arroyo** es el tramo alto del río: sube hacia el **norte, al bosque**. El cuerpo del Caso I aparece en un claro
  junto al arroyo (posición del caso hoy `default_world_pos` en `DetectiveCaseData.gd`: ajústala para que quede en la
  orilla). Junto al claro, el barro de la orilla es **pardo**.
- **El molino viejo abandonado**, río arriba del claro (se llega siguiendo el agua). Orilla de **barro rojo** (arcilla,
  la misma de los ladrillos rojos de algunas casas). Rueda de molino parada, edificio ruinoso que se puede recorrer en
  1.ª persona: **pajar con paja seca, hogar viejo con ceniza de carbón, cordel de cáñamo encerado, una mesa** (ahí irá
  la lista de desaparecidos: deja un papel con el texto provisional «Lista de nombres — texto pendiente del autor»).
  Sin secuestradores ni vecinos dentro todavía.
- Añade al recorrido fijo (`tools/tests/recorrido_fijo.gd`) paradas en el puente viejo, el claro y el molino.

**4. Retoques de interiores (capturas en `docs/capturas_arreglos/interiores/`):**
- Puertas con colores chillones y aspecto de dibujo plano (sobre todo la del **hospital**, turquesa y blanca con cruces
  rojas; también la de la botica): que parezcan de madera/hierro **gastado y oscuro**, como pide la época
  tecnofeudal (tosco, sucio). Una seña pequeña vale (cruz pintada desvaída), no un cartel.
- **Franjas amarillas** en el suelo de biblioteca, botica y capilla: si son error, quítalas; si son alfombras, que se
  vean como alfombras gastadas.

Capturas en 1.ª persona en `docs/capturas_arreglos/rio_molino/` (puente, río en el pueblo, claro, molino fuera y
dentro, barro rojo) y antes/después de las puertas. Commit y push por punto. Al final, `RECORRIDO PASSED`.
Informe arriba de `docs/INFORME_ANTIGRAVITY.md`, máx. 15 líneas. Godot siempre en primer plano con `timeout`.

## Notas del supervisor
(ninguna)
