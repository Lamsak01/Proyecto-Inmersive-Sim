# Plan: crónica del pueblo (bloques C)

Estado: **propuesta, pendiente de aprobación del usuario** (2026-11-02).
Contexto: `docs/VISION_Y_FUTURO.md`, paso 2 del orden («hace visible lo que pasa y ayuda a detectar fallos»).

## Qué existe hoy

- `VillageManager.social_event_log`: registro de sucesos sociales (parejas, rupturas, peleas, rechazos, celos, calumnias,
  quedadas, llegadas, viudedad...). **Solo guarda los 80 últimos**: sirve para los chismes, no como historia.
- Muertes, veredictos de juicios y misiones viven en otros sistemas y no dejan rastro histórico.

## Qué propongo

Un libro de historia del pueblo que se escribe solo y se consulta con una tecla.
Ejemplo de línea: «Día 12, 18:30 — 💔 Ana se declaró a Luis y le dijo que no.»

**Regla clave: la crónica solo cuenta lo que tú podrías saber.** Lo público (parejas, llegadas, muertes ya
descubiertas, veredictos) entra al momento; lo secreto (una calumnia anónima, un rechazo a solas, un crimen sin
descubrir) solo aparece cuando te enteras (porque lo viste, te lo contaron o se descubrió). Así no destripa misterios.
Para mí habrá un modo «todo» oculto, útil para medir partidas largas.

## Bloques

- **C1 – Registro permanente.** Lista aparte que no se borra (tope alto, unas 3000 entradas), guardada con la partida.
  Cada suceso de `record_social_event` entra también aquí, marcado como público o secreto. Las partidas viejas
  empiezan la crónica con lo que quede en el registro de 80. Test de guardado y de «secreto hasta que te enteras».
- **C2 – Panel.** Tecla nueva (propuesta: **C**, de Crónica; hoy está libre). Lista por días, lo más nuevo arriba, con
  filtros: Todo · Amor · Peleas y roces · Muertes y crímenes · Llegadas y marchas · Tú.
- **C3 – Sucesos que hoy no se apuntan.** Muertes (cuando se descubren), veredictos de juicios, casos archivados,
  misiones cumplidas o fallidas y lo que haces tú a la vista de otros (mediar, emparejar, que te pillen calumniando).
- **C4 – Uso para medir.** La sonda de partidas largas lee la crónica en modo «todo»: resúmenes más fiables y baratos.

## Riesgos

- Destripar secretos: por eso la regla de «solo lo que sabes» y un test que lo vigile.
- Tamaño de la partida guardada: con el tope, unos cientos de KB como mucho.
- Esfuerzo: medio (4 bloques pequeños). No cambia el comportamiento de los vecinos.

## Preguntas para el usuario

1. ¿Tecla **C** para abrirla (recomendado) u otra?
2. ¿Solo lo que podrías saber (recomendado) o todo lo que pasa en el pueblo?
