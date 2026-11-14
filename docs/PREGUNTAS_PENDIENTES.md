# Preguntas de diseño para el usuario

## Respondidas (2026-11-05)

1. **Bajar a las alcantarillas delante de la gente:** → **sospechoso si te ven.** Si un guardia (o vecino despierto)
   te ve bajar por la rejilla, sube la búsqueda. Encargado a Antigravity (FIS3b).
2. **Modelos de oveja y gallina:** → **dejarlo así por ahora** (oveja = alpaca, gallina de piezas). Se buscarán modelos
   mejores en una futura pasada de arte.

## Para hablar al volver

- **Bucle jugable para la primera beta** (para pasársela a tus amigos): Claude Code dejará preparado un borrador en
  `docs/PROPUESTA_BETA.md` para pensarlo juntos.

## Abiertas

0c. ✅ **(2026-11-13) Arranque del Caso I:** respondido: la carta es solo tu contrato; el asesinato ocurre después de
   llegar; Vane te manda llamar; un guardia custodia la escena; junto al cuerpo hay una tumba a medio cavar; el claro
   más lejos del molino. Detalle en `docs/specs/OBJETIVOS_CASO1.md`.

0b. ✅ **Respondido (2026-11-14): se deja como está** hasta la tanda 3b del plan todo 3D (pisos = alturas de verdad), que
   sustituye a la vez al sistema de la posada y al de las casas; no se rehace antes. Pregunta original:
   **(2026-11-13, noche) Pisos de la taberna con el sistema de las casas de dos plantas:** no se ha tocado. La posada
   tiene su propio sistema (~800 líneas en `VillageTavern.gd`: escalera, galería, losa, alturas, sótano del club; lo
   usan 16 llamadas). Unificar = rehacer la posada como plano de dos plantas (`…_ARRIBA` y `ESCALERA`), pasar sus marcas
   y borrar ese código. Al jugar no se nota; evita que se rompa al tocarla. Coste: mucho. ¿Ahora o tras el Caso I?

1. ✅ **Respondido (2026-11-14): sí**, el herrero vivirá encima de la herrería (planta alta con cama y escalera, con el
   sistema de las casas de dos plantas). **Se hace cuando Antigravity termine su tarea 6** (malla de navegación de cada
   edificio), no antes, para no pisar la misma escena. Pregunta original: **(2026-11-13) Herrero encima de la herrería:** dormir en el piso de arriba de la tienda pide un sistema de pisos
   para cualquier edificio (hoy solo la posada y tu casa tienen piso alto, con código propio en ~20 archivos). Coste:
   mucho. Mientras, la casa de prueba del herrero es su vivienda de siempre, de una planta y por cuartos. ¿Hacemos el
   sistema de pisos ya, o seguimos con casas de una planta y lo dejamos para las casas ricas más adelante?
   *(2026-11-13: el sistema ya existe y lo estrena la casona de los rentistas; poner arriba al herrero es ahora poco
   trabajo si el usuario lo quiere.)*

2. ✅ **(2026-11-14) Flechas en la vista desde arriba:** respondido: **el juego es solo en 1.ª persona**; la vista desde
   arriba no se desarrolla más ni se tiene en cuenta. Quitada la regla especial: la flecha da siempre donde se apunta.
3. ✅ **(2026-11-14) Carpeta `archived_systems/`:** respondido: **se borra**. Borrados los cuatro sistemas viejos de código
   (armaduras, inventario de rejilla, interiores con teletransporte, red eléctrica). **Queda una duda nueva:** dentro había
   también dibujos del usuario de las primeras pruebas (`unused_assets_and_tools/`: kanjis, escopeta, barras, hoja de
   personaje, en .png, .rar y .zip) que no están en ningún otro sitio del proyecto. Respondido (2026-11-14): **se quedan
   donde están**; no se tocan.
4. ✅ **(2026-11-14) La flecha cae por su peso:** respondido: **se queda así** (arco de verdad).
5. ✅ **(2026-11-14) Rótulo de los animales:** respondido: **se queda** saliendo al acercarse a menos de 8 m.
6. ✅ **(2026-11-14) Emojis en los textos:** respondido: **se van quitando poco a poco**, al reescribir cada sistema (sin
   una pasada aparte). Hechos: animales salvajes y mascotas.
