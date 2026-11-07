---
tipo: sistema
area: "crimen"
estado: parcial
codigo: "scripts/systems/VillageRestaurant.gd"
tags:
  - sistema
  - edificios
  - crimen
---
# Trattoria Il Corvo

## Qué hace
- Restaurante italiano al este del pueblo, junto al cementerio. Lo regenta un cocinero recién llegado (oficio vacante que se ocupa solo).
- Vende tallarines y carne estofada al vino; compra trigo a la granja y carne al rancho.
- Es el escenario del crimen dentro del pueblo: su reservado será el sitio de reunión de la Familia (R2).

## Cómo se ve en el mundo (sin abrir menús)
- Seis salas: comedor (mesas con mantel a cuadros, velas, barra, piano), cocina (fogón, campana, fregadero), cámara fría (hielo, carne colgada, luz azul), bodega, cuarto del dueño y reservado (mesa redonda, chimenea, luz roja).
- Terraza con mesas, sombrillas, macetas y guirnalda de bombillas encendida de 17 a 02 h.

## Comprobación con las reglas
- [x] Suma cero: no crea oro de la nada (los platos salen de trigo y carne comprados)
- [x] No destripa secretos desde el menú
- [ ] Se puede fallar y tiene cooldown (llegará con la Familia)
- [x] Ocurre en el mundo físico, con testigos
- [x] El pueblo lo usa por su cuenta (sonda `restaurant_probe.gd`: 6 comidas en 4 días)
- [x] El test prueba el flujo real (`Block R1`)

Ver [[Las 7 Reglas de las Auditorías]]

## Conexiones con otros sistemas
- [[Red de las Sombras]] y [[Justicia y Comisaría]] (la Familia, sus negocios y el soborno al guardia).
- [[Economía de Oferta y Demanda]] (compra de trigo y carne).

## Notas de diseño
- 2026-11-06 (R1b): los vecinos con dinero comen o cenan (13–22 h) en el comedor o la terraza y pagan al cocinero; el cocinero abre de 12 a 23 h y baja a la cámara fría antes de cada estofado. El puesto empieza vacante: en la sonda, el cocinero llegó el día 4.
- 2026-11-06 (R1): edificio y oficio hechos. Fachada 3D aún parece de tablas oscuras.

## Tareas
- [x] R1 Restaurante
- [x] R1b Vida en el restaurante (cenas, cámara fría)
- [ ] R2 La Familia
- [ ] R3 Negocios discretos
- [ ] R4 El jugador se entera e interviene
