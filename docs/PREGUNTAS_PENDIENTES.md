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
