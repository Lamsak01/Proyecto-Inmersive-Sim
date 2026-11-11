# Plan: el mundo sale solo del editor (borrador para aprobar, 2026-11-12)

Escrito por Claude Code (portátil) tras hablarlo con el usuario y con la otra sesión de Claude. **Nada empezado.**

## Problema
El mundo se construye con ~5.250 posiciones escritas en el código para el mapa pequeño antiguo; una capa de traducción
(las «anclas», `mapa/anclas.gd`) las estira ×5 y las sigue cuando el usuario mueve piezas. Lo que no pasa por ella sale en
su sitio viejo (iglesia, lavadero, cementerio: `FALLOS_VISIBLES.md`, «Segunda partida»). No se puede saber cuántas faltan
ni garantizar que mover una pieza no deje restos. Afecta al decorado **y a los vecinos**: camas, mesas, puestos de trabajo,
sitios de ocio, rutas y pistas salen del mismo plano viejo.

## Regla final
Nada se coloca con un número del código: todo sale de una pieza o una **marca** (nodo sin dibujo) de `mapa/Mundo3D.tscn`.
Lo de dentro de un edificio va relativo a su edificio. El tamaño actual (×5) queda fijado en el editor; después se ajusta
moviendo piezas, no con un factor.

## Pasos (cada uno deja el juego jugable; se suben a `main` al acabar con su prueba en verde)
0. **Inventario automático.** Prueba nueva que construye el mundo y lista todo lo que aparece (dibujos 2D, piezas 3D,
   choques, zonas de uso) y todos los destinos de los vecinos, diciendo de dónde sale cada uno: pieza del editor o número
   del código. Da la cifra exacta de lo que falta y será la vara de medir de los pasos siguientes. *Jugable: sin cambios.*
1. **Edificios completos en el editor**, por grupos (casas → oficios → públicos: iglesia, ayuntamiento, escuela…): muros,
   puerta, muebles, camas, mesas y puestos de trabajo como marcas dentro de cada edificio; el código las lee en vez de sus
   constantes. *Jugable tras cada grupo.* Prueba: inventario del grupo a 0 + sondeo de edificios movidos.
2. **Exteriores**: cementerio, lavadero, campamento, corrales, huertos, pozos, decorado suelto y grupos hechos por código
   pasan a piezas. *Jugable.* Prueba: inventario de exteriores a 0 + fotos de cada zona.
3. **Sitios de los vecinos fuera de edificios**: oficios al aire libre, ocio, paseos, puntos de ruta, pistas del Caso I →
   marcas. *Jugable.* Pruebas: `partida_caso1.gd` y `atascos_vecinos.gd`.
4. **Quitar la traducción**: se borran las anclas, el factor ×5 y las copias `*.antes-x5`. *Jugable.* Prueba final:
   inventario total a 0, `verify_all.gd`, y una prueba nueva que mueve **cada** pieza del editor al azar y comprueba que
   nada queda en su sitio viejo y que cada cama, mesa y puesto cae dentro de su edificio.
5. **Aparte y con aprobación propia: caminar con navegación 3D** (rutas sacadas del escenario). Cambia cómo encuentran el
   camino y puede crear atascos nuevos; va solo, con su simulación de atascos antes y después.

## Coste y riesgos
- Estimación (supuesta, no medida): paso 0 una sesión; 1 tres o cuatro; 2 una o dos; 3 dos; 4 una; 5 dos o tres.
- Mientras dure, **el usuario no edita el mapa** y solo una sesión de Claude toca el código del mundo, para no pisarse.
- Las partidas guardadas dejarán de valer al acabar el paso 4 (ya pasó con el ×5).
- Lo que no cambia: lógica de los vecinos (necesidades, oficios, rutinas, charlas), Caso I, física 3D, guardado.
