# ⭐ ENCARGO DE HOY — Cimiento: estabilidad (recorrido fijo + guardar/cargar largo)
Objetivo: saber que el juego aguanta una partida larga sin romperse, antes de montar el Caso I. **No añadas
sistemas ni cambies cómo se juega**; solo detecta y arregla fallos. Modo demo activo (lo pausado sigue pausado).

1. **Recorrido fijo de comprobación** (`tools/tests/recorrido_fijo.gd`, nuevo): en 3D y primera persona, el
   jugador visita siempre los mismos sitios (entrada del pueblo, plaza, taberna por dentro, una casa, comisaría,
   cementerio, bosque, borde del lago). En cada sitio: captura en `docs/capturas_arreglos/recorrido/` y
   comprobación de que no hay errores en consola, que el jugador no cae al vacío ni queda atascado, y que nadie
   está metido en una pared. Debe imprimir «RECORRIDO PASSED» o la lista de fallos. Que tarde menos de 5 min.
2. **Guardar/cargar largo** (`tools/tests/guardado_largo.gd`, nuevo): simula 7 días de juego; al final de cada
   día guarda, carga y compara lo importante (hora y día, posición y dinero del jugador, inventario, vecinos
   vivos y su sitio, estado del caso de detective y del tablero, misiones). Cualquier diferencia o error = fallo.
   Además, tras 7 días: que no se dupliquen vecinos ni objetos y que la memoria no crezca sin parar (anota
   cifras). Debe imprimir «GUARDADO LARGO PASSED». Menos de 10 min.
3. **Arregla** lo que fallen las dos pruebas (cada arreglo, su commit). Si algo es grande o cambia el juego,
   **no lo arregles**: anótalo en el informe para que decida el usuario.
4. **Informe** (arriba del todo de `docs/INFORME_ANTIGRAVITY.md`, máx. 15 líneas): qué falló, qué arreglaste, qué
   queda, cifras de memoria y las capturas del recorrido. Añade las dos pruebas a la sección 3 de `HANDOFF.md`.

Reglas: Godot siempre en primer plano con `timeout`, nunca en segundo plano. Una prueba a la vez.

## Notas del supervisor
(ninguna)
