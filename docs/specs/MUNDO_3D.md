# Mundo 3D: cómo funciona la física y qué reglas tiene

Conversión terminada el 2026-11-12 (etiqueta `fin-paso-a-3d`). Plan, manuscrito y registro completos en
`docs/archivo/PLAN_MUNDO_3D.md` y `docs/archivo/MANUSCRITO_MUNDO_3D.md` (solo si el usuario pide historia).

## Idea central: «cuerpo en 3D, cerebro en el mapa»
- El **mapa 2D** (píxeles) sigue siendo donde piensan los vecinos: rutas, sitios, puertas, choques. **La física** ocurre en
  3D y escribe su resultado en el mapa. `scripts/fisica/Mapa3D.gd` es el **único** sitio que convierte mapa ↔ metros
  (1 unidad = 1 m; `ESCALA` m/px, `ALTO` m/px de altura).
- `Cuerpo3D.gd`: cuerpo genérico (protagonista y vecinos cercanos). Flota sin losa de suelo: se le fija una altura mínima
  de suelo (`_suelo_y`) y se le mueve en 3D; cambia de piso solo (`_nivel_visto`). Los saltos de más de 8 px del mapa se
  tratan como teletransporte; los menores, como paso. Capas: protagonista 1 (choca con 1 y 2), vecinos 2 (chocan con 1).
- `ChoquesCercanos3D.gd`: copia como prismas los choques del mapa cercanos a un cuerpo (salta el agua si el actor la
  cruza, los vecinos, el jugador y el destino del actor). `CuerposDelPueblo3D.gd`: da cuerpo completo a los vecinos,
  animales grandes, mascotas, bandidos y enemigos a menos de 150 px del protagonista (máximo 24) y lo quita al alejarse;
  si un vecino lleva 5 s atascado, se le quita el cuerpo 10 s. `CuerposCercanos3D.gd`: cápsulas de contacto para los que
  no tienen cuerpo completo (los sentados no tienen). `AndarMapa.paso(actor, delta)`: el paso de animales y bandidos.
- `Suelo.gd`: altura del suelo en cada punto (tarimas, plaza, puentes), losas de pisos altos (posada: planta +1 solo
  dentro de su rectángulo; altillo y sótano de tu casa; casas de dos plantas), de qué piso es cada choque (grupos
  `choques_piso_0` / `choques_piso_1`). `PisosCasas.gd`: casas con escalera (marcas `escalera_pie` y `escalera_cima`
  en su escena; las hace `tools/casas/planta_alta.gd` desde los campos «…_ARRIBA» del plano): suelos, losa, qué marcas
  son de arriba y la ruta de los vecinos, que cambian de piso a media escalera. El muro bajo la cima no choca (en 3D
  pararía al que sube). `Agua.gd`: dónde hay agua y cuánto
  cubre (río hondo 2,2 m). `Vista.gd`: ¿ve, cuánto oye, llega a golpear? (paredes y puertas del mapa + losas; bajo tierra
  nunca se ve desde la calle; a través de un suelo se oye a un tercio).
- Relieve del suelo (`WorldStageBase3D.terrain_height_px`) cacheado por celdas de 4 px; olvidar la caché al cambiar el río.

## Reglas para cualquier agente
1. Toda conversión mapa ↔ 3D pasa por `Mapa3D.gd`; toda física de actor por `Cuerpo3D.gd`. Nada de caminos dobles.
2. Formas de choque sencillas (cajas y cápsulas) generadas al construir el mundo, no mallas exactas.
3. Toda distancia de ver/oír/golpear nueva pasa por `Vista.gd` (`vm.ve/oye/alcanza`).
4. La partida guardada no se pierde: cada cambio de formato sube `version` en `GameManager.save_game` y `load_game` convierte.
5. El mapa editado por el usuario (`mapa/Mundo3D.tscn`) no se pierde: cambios de escala con herramienta y copia previa.
6. Rendimiento: muñecos lejanos (>240 px) se actualizan 1 de cada 3 cuadros; muros de los vecinos 1/3; cuerpos de
   contacto 1/2; reparto de cuerpos 1/6. Referencia en el portátil: plaza ~25 fps, río ~21.
7. Al tocar esto: prueba `fisica_3d.gd` (y `puertas_3d.gd` si cambian edificios o puertas), foto del sitio, `CHANGELOG`.

## Jugador
- Agacharse no se permite en el agua. Nadar en el agua honda; bucear con la tecla de agacharse estando nadando: 30 s de
  aire (barra 🫧), recupera 6 s por segundo fuera; sin aire, 8 de vida por segundo («Ahogamiento»). Niebla bajo el agua.
- Manos en 1.ª persona: brazos del modelo de aldeano (`characters/Male_Peasant.gltf`), solo la malla «arms».
- Daño por caída realista (3 m duele, 8 m mata). Flechas con altura y pendiente de la cámara.

## Mapa ×5 (2026-11-11)
- `Mapa3D.E` = 5: todo punto fijo del código sigue en el mapa original y la capa de anclas (`mapa/anclas.gd`) lo lleva al
  mundo estirado (`mover`; `desmover` al revés). Reglas en `PLAN_MAPA_X3.md` §2–§3. Lo que viene del editor o de un nodo
  ya es del mundo: **nunca** pasarlo por `mover` (traducción doble); lo que se compara con una constante del código se
  pasa por `desmover`. Interiores 3D con coordenadas fijas: `WorldStageBase3D.mover_posiciones`; terreno: `estirar_terreno`.
- Herramientas de un solo uso ya pasadas: `hornear_caminos.gd`, `repoblar_bosque.gd`.

## Mapa editable (`mapa/Mundo3D.tscn`)
- Carpetas «Vegetacion» (árboles, rocas, plantas, troncos, vetas horneados del código, editables a mano) y «Decorado».
  Lo que está en la escena manda sobre la lista del código (el código no lo coloca si ya existe en la escena).
- Herramientas: `tools/hornear_*.gd` (una sola vez), `tools/esparcir_arboles.gd -- <px> [x1,y1,x2,y2]` (quita árboles con
  el tronco pegado). Si el usuario tiene la escena abierta en Godot: recargar sin guardar. Detalle: `REGISTRO_EDITOR_3D.md`.
