# Decisiones de diseño ya tomadas (no volver a preguntarlas)

## Mundo y época
- **Mundo 3D de verdad** (2026-11-10): física real, pisos, sótanos, nadar y bucear. Hecho el 2026-11-12; el modo 2D se borró.
  No proponer volver al 2D. Vista desde arriba: se queda por ahora (2026-11-11). Detalle en `MUNDO_3D.md`.
- **Escala uniforme en metros** (2026-11-10). **Daño por caída realista:** duele desde 3 m, mata a 8 m, hiere piernas.
  **Aire bajo el agua:** 30 s; al acabarse pierdes vida hasta morir (2026-11-11).
- **Época DEFINITIVA** (2026-11-08, «100 % seguro»): tecnofeudal / medieval-balística. Sociedad y arquitectura feudales con
  tecnología analógica de los 70/80 y armas de fuego militares, todo tosco (hierro, piedra, madera, hormigón, baquelita).
  Nada de pantallas, móviles, coches modernos ni engranajes victorianos. Ver `REVISION_EPOCA.md`.
- **Historia principal antigua DESCARTADA** (2026-11-08): el «experimento vigilado desde fuera» y sus capítulos no se usan.
  La nueva se diseña con el usuario (probablemente resistencia contra los gobernantes). **Nunca inventar lore de la secta.**
- **Escaleras sin botón** (2026-11-07): se sube andando por los peldaños; barandillas sólidas; nadie flota.
- **Tamaño:** empezar pequeño; objetivo una ciudad de 100+ vecinos y un mapa ~3 veces más grande. Sótanos y pisos con capas
  (tipo Project Zomboid). Todo sistema con distancias pasa por `Vista.gd`.
- **Visión a largo plazo:** pueblo realista con lo bueno y lo malo, profundidad tipo Dwarf Fortress / RimWorld / Song of Syx
  (`docs/VISION_Y_FUTURO.md`). Foco actual: fallos visibles → Caso I jugable; lo demás congelado.

## Vecinos y vida social
- **Rasgos:** ~140, nombres según el género, oscuros pero raros, ejes de opuestos, ~6 por vecino, ocultos al principio;
  un Mentiroso puede contarte rasgos falsos («según X»). Recién llegados se generan solos; las partidas guardadas conservan.
- **Todo procedural:** funciona con vecinos que lleguen más tarde; nada depende de nombres fijos.
- **Parejas:** solo parejas (sin bodas ni hijos por ahora); todos heterosexuales por ahora (campo `orientación` previsto);
  surgen de forma natural, sin plazos; nadie de su mismo hogar; duelo y viudedad. Pareja inicial: Elena y el Dr. Valen.
  Compatibilidad por género, edad, personalidad, gustos, relación previa, rutina y un poco de azar.
- Edades numéricas. Nombres: 200 femeninos + 200 masculinos + apellidos, estilo variado.
- **Peleas:** raras y excepcionales, solo tras enemistad larga; sin muerte; dados por dentro (oficio, edad, salud,
  personalidad); en pantalla discretas (frente a frente, «💢»); guardias intervienen; heridas leves y relación peor.
- **Jugador:** observador, instigador y mediador (Carisma y Sigilo). Se implementa al final.
- **Calibración:** simulaciones de cientos de días; metas a 60 días: 1–3 parejas nuevas, pocas peleas en vivo, ningún
  vecino sin amigos, más de la mitad de las relaciones entre −20 y +40.
- **Arquitectura social:** Director Social central decide la escena; aldeanos ejecutan; 4 medidas (afinidad, familiaridad,
  atracción, tensión); enfriamiento; «narrador» que dosifica; diales en una tabla; aleatoriedad con semilla.
- **Fe y semana:** religión inventada provisional (Fe del Alba); sacerdote propio; fieles van a la capilla; fin de semana.
- **Misiones secundarias:** nacen de los vecinos en persona (nunca del tablón), baja probabilidad, panel propio (tecla L),
  sin fecha límite fija; fallan si pasa algo en el mundo. Tipos: mediación, calumnia, «¿quién va contando eso?»,
  «encuentra a quien lo mató», «averigua qué piensa de mí» (`MISIONES.md`).

## Partida y demo
- **Un día de juego = 18 min reales** (2026-11-09). Demo en modo demo (ver `CONVENCIONES_CODIGO.md`).
- El jugador empieza en las afueras, en el camino de entrada al valle; el campamento inicial ya no está en el pueblo.
- Posada: 3 cuartos en la planta +1 (dueños, huéspedes con 3 camas, el del jugador) (2026-11-11).
- Controles: todas las teclas en `docs/CONTROLES.md`; trucos de tiempo y modo pruebas con Ctrl.
- **Caso I con un día de margen** (2026-11-11): el día 1 llegas y conoces el pueblo; el caso estalla el día 2 al amanecer.
- **Los sapos de la Llanura Salvaje se descartan**: sus puestos los ocupan bandidos (2026-11-11).
- **Pistas en el fondo del agua** (2026-11-11): el mecanismo queda listo pero **no se usa en el Caso I**; será para otros casos.
- Pendiente de decisión del usuario: dónde habrá cuevas.
