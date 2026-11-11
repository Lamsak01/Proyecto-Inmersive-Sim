# Auditoría de los bloques PF–PQ (commits 08399d0..beb062d)

Revisión de Claude Code, 2026-11-04. Reglas de referencia: `docs/LECCIONES_P1_P7.md`.

## Pruebas

Las cuatro pasan, de una en una y con `timeout`:

- `verify_all`: TESTS PASSED, 0 SCRIPT ERROR (Tests #83–#94 OK).
- `names_check`: superado.
- `social_sim`: superado (5 semillas).
- `dialogue_coverage`: 632 acciones, 0 errores.

`VillageSect.gd` no se ha tocado en este rango.

**Calidad de los tests:** llaman a las funciones directamente, con el resultado forzado y con datos puestos a mano:

- el solar se marca como construido a mano;
- `known_by_player = true` se fuerza;
- los oficios se cambian a mano en `trade_npcs`.

No prueban:

- que la opción aparezca en el diálogo;
- los testigos cuando hay pisos distintos;
- que el arcabuz haga daño;
- el capítulo 4 por la alcaldía.

Por eso no detectaron los fallos graves.

## Graves (rompen el juego) — ✅ arreglados en la revisión posterior

1. **Pisos y alcantarillas sin testigos (PN).** Los vecinos nunca cambian de nivel; nadie llama a `set_npc_elevation_level`.
   - Si el jugador sube al altillo, baja al sótano o explora las alcantarillas, se queda en −1/+1 hasta que elija volver en un diálogo.
   - Mientras tanto, todos los testigos de robos, allanamientos y robos en puestos se filtran. Esas llamadas pasan `null` a `_find_conscious_witness_near` y usan el nivel del jugador.
   - **Truco:** subir al altillo y salir a robar sin testigos.
   - Además, todo el pueblo se ve al 35 % de opacidad y se simula a medio ritmo.
2. **El arcabuz no hace daño (PO).** `apply_minor_bruise(48.0, 2.5, …)` usa 2.5 como suelo (250 % de la vida), así que el daño es 0. El texto dice «Heriste a…».
   - Además se dispara desde el menú de conversación a cualquier vecino. Es el mismo patrón que «robar desde el diálogo», que ya se quitó.
3. **El capítulo 4 por la alcaldía nunca se cumple (PP).** El código lee `town_state["mayor_key"] == "player"`, una clave que nadie escribe; el alcalde está en `VillageTown.state(vm)["mayor"]`.
4. **Borrar la búsqueda cada día.** Repite el fallo del sótano, que ya se limitó a una vez por semana:
   - Pasadizo del Contrabandista: −1 de búsqueda al tener éxito, una vez al día.
   - Terminal, «Archivo policial»: −1 de búsqueda y −25 de recompensa, una vez al día.

## Economía (oro o cosas de la nada, ingresos sin riesgo) — ✅ arreglados en la revisión posterior

5. **Negocio propio (PG): ingreso pasivo sin riesgo.**
   - Empieza con 2 artículos de existencias gratis.
   - Cualquier objeto cuenta como 1 artículo (1 madera = 10 de oro).
   - Vende cada día a todo vecino con 18 de oro o más.
   - No hay robos ni pérdidas.
   - Tampoco se construye ningún mostrador visible, aunque la documentación lo dice.
6. **Pinos (PK).**
   - No hay espera: `last_plant_day` se guarda pero nunca se comprueba.
   - Cada pino da 3 de madera y 1 semilla cada 2 días, así que la semilla gastada vuelve.
   - Cada siembra trae un venado o un conejo.
   - Todos los pinos se colocan en una rejilla fija.
   - **No se guardan:** desaparecen al cargar la partida.
   - Junto con el negocio forman un bucle de oro sin fin a costa de los bolsillos de los vecinos.
7. **Corral (PI).**
   - Los animales adultos dan carne cocinada gratis cada 2 días y una cría gratis cada 4.
   - Crecen sin comer.
   - No pueden morir ni enfermar.
8. **Obras maestras (PF).** Se compran a 35 y se venden a 50 a los coleccionistas, sin riesgo.
9. **Red eléctrica (PJ).**
   - Bucle: sabotear (70 % de que no te pillen) y reparar tú mismo cobra 12 de las arcas cada día.
   - `repair_grid` pone `electric_grid_active = true` aunque el jugador nunca haya construido el generador, así que da electricidad gratis.
   - El sabotaje se hace delante del arreglador y sin comprobar testigos.
10. **Incursiones (PL/PP).**
    - La milicia se puede pagar sin límite (+2 por cada 15 de oro), así que con dos pagos se gana siempre.
    - `resolve_raid` pone `militia_bonus = 0`, así que la Atalaya del asentamiento (+2) se pierde para siempre tras la primera incursión.
11. **Terminal en la comisaría (PO).** Se hackea hablando con el propio comisario.

## Veracidad (documentado pero no funciona del todo) — ✅ corregido (el asentamiento en el mapa y la amputación del jugador quedan como pendientes en VISION)

12. **Caballo:** se documenta que «mejora tu desplazamiento», pero nadie lee `mount_speed_mult`. Solo da +15 % de éxito en las expediciones.
13. **Asentamiento «Puesto del Paso»:** solo existe en menús; no hay ningún lugar en el mapa. Gobernarlo consiste en 3 mejoras, 3 colonos y una caja.
14. **Amputación:**
    - El pensamiento dice «(-15)», pero suma +8: el vecino se pone contento al perder un brazo. La prótesis dice «+12» y suma +8.
    - El jugador nunca puede ser amputado (la revisión diaria solo mira vecinos), así que su opción de prótesis no aparece nunca.
15. **Historia principal:** introduce lore («el valle es un experimento cerrado») que no está anotado en `docs/APORTES_CREATIVOS.md`. Lo creativo es provisional y debe apuntarse.
16. **Cambio de oficio:** `promote_to_trade` ya no pone a 0 los días de oficio, así que quien cambia de oficio conserva la experiencia del anterior. Es un cambio de comportamiento que no se avisó.

## Está bien

- **Misterio:**
  - «Tantear» la obsesión se ofrece a cualquier adulto, una vez al día; preguntar a un inocente no revela nada.
  - Avisar al ídolo solo aparece después de descubrir al acosador.
  - La medalla «Obsesionado» solo se ve si el jugador ya lo sabe.
- **Oro de bolsillos reales:** las apuestas, el acompañante, el patrocinio, las prótesis, el caballo, la carreta, la llave de las alcantarillas, los colonos y la investigación.
  - Las monedas de las alcantarillas salen de un fondo finito que se llena con monedas que pierden los vecinos.
  - Las rutas tienen un saldo finito de 90.
  - Las recompensas de la historia salen de las arcas.
- **Riesgo y espera:**
  - Las carreras y peleas de animales se pueden perder y son una vez al día; la pelea de gallos tiene riesgo de guardia.
  - El hackeo puede hacer saltar la alarma (búsqueda +1 y −12 de vida).
  - Las expediciones pueden fallar.
  - La caravana viene de noche cada 3 días con 2 lotes.
  - La escritura falsa tiene un 30 % de riesgo.
  - Elogiar o difamar a un vecino comparte una espera de 3 días.
- **Errores ocultos:** no se encontraron campos ni funciones inexistentes fuera de los señalados (`mayor_key` y `mount_speed_mult`).

## Recomendación (orden)

1. Arreglar los graves 1–4. Coste: medio, un bloque.
   - El nivel vuelve a 0 al salir de casa o de las alcantarillas.
   - La búsqueda de testigos usa el nivel de cada vecino.
   - El arcabuz hace daño de verdad y se usa fuera del diálogo, o se quita del menú.
   - Leer el alcalde real.
   - Espera semanal para borrar la búsqueda.
2. Cerrar los bucles de dinero 5–10. Coste: poco o medio.
   - Espera para los pinos y guardarlos en la partida.
   - El negocio vende según el valor del objeto y con riesgo de robo.
   - El corral consume comida.
   - Tope para la milicia.
   - La reparación no enciende la red sin generador.
3. Corregir los textos y la documentación 12–16. Coste: poco.
4. Añadir tests que pasen por el diálogo y por los testigos, no solo por funciones con datos puestos a mano.
