# Fallos visibles (lista del usuario)

> El usuario apunta aquí lo que ve mal al jugar, aunque sea una frase. **Todo agente empieza cada encargo mirando esta
> lista**: arregla primero lo que toque su trabajo y marca lo arreglado con ✅ y la fecha (no lo borres).
> Formato: `- [ ] Qué se ve mal · dónde · cuándo (hora del juego, 2D/3D/primera persona)`.

## Pendientes
- [ ] **«Huerto vecinal» plantado en medio de un camino** (cajones encima del sendero junto a la Residencia Aguas
  Claras): quitarlo de ahí; el usuario no lo quiere en ese sitio · 3D, de día.
- [ ] **Biblioteca: «Leer un rato [E]» no hace nada** (el letrero promete una interacción que no existe) · de noche.
- [ ] **Los edificios antiguos son diminutos y feos:** cuartos de una sala, muebles arrinconados, sprites sin sentido
  (p. ej. la comisaría: rejas verdes gigantes, cajón suelto, cepo). **Petición del usuario:** que TODOS los edificios
  tengan el nivel de detalle de la trattoria (varias salas con sentido, muebles 3D colocados, luces). Es un proyecto
  grande: hacerlo edificio a edificio, empezando por los que pisa el detective (comisaría, morgue/hospital, capilla,
  taberna, biblioteca).
- [ ] **Trattoria: quitar la cama** del cuarto del dueño (no pinta nada en un restaurante; que sea un despacho).
- [ ] **La ropa atraviesa el cuerpo** de algunos vecinos (al guardia se le sale el hombro por la ropa) · 1.ª persona.
- [ ] **No hay cielo ni textura en el suelo** en primera persona: cielo azul plano y césped liso; todo se ve tosco.
  El usuario quiere **empezar a ambientar el pueblo ya** (cielo con nubes y hora del día, suelo con textura, hierba,
  niebla), aunque más adelante compre arte · 1.ª persona, de día.
- [ ] **Todas las casas comparten la misma puerta**, que a veces no pega con la fachada · 1.ª persona.
- [ ] **Árboles 3D raros en todo el pueblo:** copas como bloques arrugados con ramas rosas pegadas por fuera; se
  amontonan y se solapan entre sí y con muros · parque, campamento, lago · 3D, de día.
- [ ] **El parque (junto al campamento del oeste) es ridículamente pequeño:** un cuadrado de césped con muro bajo y un
  banco tapado por los árboles · 3D.
- [ ] **Lago del Oeste:** (1) hay **dos muelles**, uno en 2D plano y otro en 3D; (2) el **lavadero** a la orilla de un
  lago no tiene sentido (debería ir junto a un arroyo o fuente del pueblo); (3) un **banco pequeño** con cosas sin
  sentido alrededor; (4) **el jugador camina por encima del agua** (falta que el agua bloquee el paso) · 3D, de día.
- [ ] **Parque del Roble (atardecer):** bancos y macetas **se ven a través de los árboles** (se dibujan encima de las
  copas); además el letrero «Parque del Roble» queda tapado por bocadillos · 3D, 19:21.
- [ ] **Textos encima de otros:** «Esquilando lana 90 %» se monta sobre el letrero «Rancho del Sur» · 3D.
- [ ] **El Hermano Anselmo y la maestra llevan un libro gigante** en la mano, sin sentido (¿objeto de mano mal
  escalado?) · 3D, de noche junto al Mirador del Lago.
- [ ] **Cementerio Parroquial del Alba:** lápidas gigantes (del tamaño de camas), el recinto parece una caja vacía de
  tierra · 3D, de día.
- [ ] **La trattoria «Il Corvo» está justo al lado del cementerio:** no tiene sentido abrir un restaurante ahí.
  Moverla a un sitio con vida (calle principal o plaza). Ojo: es error de Claude Code al elegir el hueco libre.

## Arreglados
- [x] ✅ (2026-11-07) Fachada de la trattoria «Il Corvo» en 3D: parece de tablas oscuras en vez de estuco/ladrillo claro (`WorldStage3D.gd`: cambiada la textura de muros de `building_restaurant` a `town_textures/wall_brick_sand_center.png` con `uv1_scale = Vector3(2.4, 0.72, 2.4)`, tono claro de estuco/ladrillo cálido `Color(1.0, 0.95, 0.84)`, iluminación cálida de rebote `0.58` en la fachada sur y dintel con el mismo estuco en vez de `rf_planks.png`).
