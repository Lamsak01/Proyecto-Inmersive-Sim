---
tipo: sistema
area: "crimen"
estado: parcial
codigo: "scripts/systems/VillageRestaurant.gd, scripts/systems/VillageFamilia.gd"
tags:
  - sistema
  - edificios
  - crimen
---
# Trattoria Il Corvo

## Qué hace
- Restaurante italiano al este del pueblo, junto al cementerio. Lo regenta un cocinero recién llegado (oficio vacante que se ocupa solo).
- Vende tallarines y carne estofada al vino; compra trigo a la granja y carne al rancho.
- Es el escenario del crimen dentro del pueblo: en su reservado se reúne de noche **«La Familia»** (`R2`), que nace sola cuando un vecino ambicioso, sin escrúpulos y persuasivo tiene motivo y ahorros, recluta de uno en uno a entre 2 y 4 vecinos (quien se niega lo recuerda y suelta el chisme) y aborta la reunión si asoma un guardia o un extraño.

## Cómo se ve en el mundo (sin abrir menús)
- Seis salas: comedor (mesas con mantel a cuadros, velas, barra, piano), cocina (fogón, campana, fregadero), cámara fría (hielo, carne colgada, luz azul), bodega, cuarto del dueño y reservado (mesa redonda, chimenea, luz roja).
- Terraza con mesas, sombrillas, macetas y guirnalda de bombillas encendida de 17 a 02 h.
- De noche, cuando el jefe convoca a los suyos, se ve gente cenando a puerta cerrada en el reservado; si le preguntas al cocinero, suelta una indirecta discreta.

## Comprobación con las reglas
- [x] Suma cero: no crea oro de la nada (los platos salen de trigo y carne comprados)
- [x] No destripa secretos desde el menú
- [x] Se puede fallar y tiene cooldown (el reclutamiento de «La Familia» puede fallar y dejar rumor; las reuniones abortan con testigos)
- [x] Ocurre en el mundo físico, con testigos
- [x] El pueblo lo usa por su cuenta (sonda `restaurant_probe.gd`: 6 comidas en 4 días; `VillageFamilia.daily` y `on_hour`)
- [x] El test prueba el flujo real (`Block R1`, `Block R1b`, `Block R2`)

Ver [[Las 7 Reglas de las Auditorías]]

## Conexiones con otros sistemas
- [[Red de las Sombras]] y [[Justicia y Comisaría]] (la Familia, sus negocios y el soborno al guardia).
- [[Economía de Oferta y Demanda]] (compra de trigo y carne).

## Notas de diseño
- 2026-11-06 (Antigravity, R3): **Negocios discretos de «La Familia»** (`VillageFamilia.gd`): de las reuniones del reservado salen recados diurnos a pie (`familia_errand` a las 11:00 y 16:00): (1) cobrar comisión de «tranquilidad» (`12` de oro en suma cero repartidos entre cobrador y jefe) a comerciantes con dinero si no hay un guardia cerca, con enfriamiento y rumor si se niegan; (2) prestar `20` de oro del bolsillo del jefe a vecinos sin blanca (a devolver `26` a los 4 días, dejándolos en deuda `owes_to`); y (3) comprar por `15` de oro el silencio de algún guardia poco honrado durante 5 días para que haga la vista gorda de noche y no aborte las cenas en el reservado.
- 2026-11-06 (Antigravity, R2): **«La Familia»** (`VillageFamilia.gd`) nace sola sin estar al empezar la partida cuando un vecino adulto ambicioso, sin escrúpulos y persuasivo acumula ahorros o frustración (deudas, envidia o rencor). Recluta de uno en uno entre 2 y 4 vecinos por deuda, afecto, miedo o desesperación; quien se niega guarda mal recuerdo y corre el rumor (`familia_rumor`). El jefe elige qué noche reunirse (22:00, 23:00 o 0:00) sin calendario fijo en torno a `BACKROOM_TABLE` dentro del reservado; si hay un guardia o un extraño cerca, abortan y lo dejan para otra noche. El cocinero deja caer una pista si le preguntan por el reservado. Todo persiste al guardar y cargar.
- 2026-11-06 (R1b): los vecinos con dinero comen o cenan (13–22 h) en el comedor o la terraza y pagan al cocinero; el cocinero abre de 12 a 23 h y baja a la cámara fría antes de cada estofado. El puesto empieza vacante: en la sonda, el cocinero llegó el día 4.
- 2026-11-06 (R1): edificio y oficio hechos. Fachada 3D aún parece de tablas oscuras.

## Tareas
- [x] R1 Restaurante
- [x] R1b Vida en el restaurante (cenas, cámara fría)
- [x] R2 La Familia
- [x] R3 Negocios discretos
- [ ] R4 El jugador se entera e interviene
