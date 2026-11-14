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

0b. **(2026-11-13, noche) Pisos de la taberna con el sistema de las casas de dos plantas:** no se ha tocado. La posada
   tiene su propio sistema (~800 líneas en `VillageTavern.gd`: escalera, galería, losa, alturas, sótano del club; lo
   usan 16 llamadas). Unificar = rehacer la posada como plano de dos plantas (`…_ARRIBA` y `ESCALERA`), pasar sus marcas
   y borrar ese código. Al jugar no se nota; evita que se rompa al tocarla. Coste: mucho. ¿Ahora o tras el Caso I?

1. **(2026-11-13) Herrero encima de la herrería:** dormir en el piso de arriba de la tienda pide un sistema de pisos
   para cualquier edificio (hoy solo la posada y tu casa tienen piso alto, con código propio en ~20 archivos). Coste:
   mucho. Mientras, la casa de prueba del herrero es su vivienda de siempre, de una planta y por cuartos. ¿Hacemos el
   sistema de pisos ya, o seguimos con casas de una planta y lo dejamos para las casas ricas más adelante?
   *(2026-11-13: el sistema ya existe y lo estrena la casona de los rentistas; poner arriba al herrero es ahora poco
   trabajo si el usuario lo quiere.)*

2. **(2026-11-14, golpes en 3D) Flechas en la vista desde arriba:** en 1.ª persona la flecha ya da justo donde apuntas
   (a un conejo hay que apuntarle abajo). En la vista desde arriba no se puede apuntar en vertical, así que ahí la flecha
   alcanza también lo que tiene debajo (como antes). ¿Se queda así, o la caza con arco pasa a ser solo de 1.ª persona?
   Decidido de momento: se queda así. De paso: las dianas miden ahora lo que el cuerpo (un conejo es más difícil que antes).
3. **(2026-11-14) Carpeta `archived_systems/`:** guarda escenas viejas en 2D (interiores con teletransporte, red eléctrica)
   que el juego no usa; una apunta a un archivo de golpes que ya no existe. ¿Se borra la carpeta (queda en el historial de
   GitHub) o la quieres conservar? No se ha tocado.
4. **(2026-11-14) La flecha cae por su peso:** ahora vuela en arco de verdad. Un tiro recto llega igual de lejos que
   antes, pero apuntando algo hacia arriba (1.ª persona) llega más lejos, y apuntando abajo, menos. ¿Te gusta así
   («balística» de verdad) o prefieres que el alcance sea fijo como antes? Decidido de momento: arco de verdad.
