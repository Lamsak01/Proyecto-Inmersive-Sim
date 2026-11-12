# Plan: el mundo sale solo del editor (APROBADO por el usuario el 2026-11-11)

Escrito por Claude Code (portátil) tras hablarlo con el usuario y con la otra sesión de Claude. Revisado por un profesional
externo consultado por el usuario (sus respuestas, resumidas en «Reglas acordadas»).
**Lo ejecuta SOLO la sesión del sobremesa.** El portátil no toca el código del mundo ni el mapa mientras dure (solo lee).

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

## Reglas acordadas (2026-11-11, usuario + profesional + las dos sesiones)
1. **Una pieza por edificio**: cada edificio es una sub-escena con sus muros, puerta, muebles y marcas como hijos; en
   el valle se instancia. Edificios únicos con escena propia; casas repetidas con una escena base y `@export` del dueño.
   Estructura fija de hijos (Muros, Tejado, Interior, Marcas) para no romper el ocultado de techos de la vista cenital.
2. **Sitios = nodos `Marker3D`** (script de marca con `id_marca`) dentro de su edificio o grupo. Nunca posiciones
   guardadas en un Resource aparte (sería otra vez dos fuentes). Los Resources solo para reglas (horarios, animaciones).
3. **Interiores en coordenadas locales ×1** respecto a su edificio (sin el estirado del campo abierto).
4. **Exteriores sueltos y rutas**: al convertir, cada número pasa UNA vez por `Anclas.mover()` y se escribe ya colocado.
5. **Grupos desperdigados por el ×5** (cementerio, lavadero, campamento, corral…): un nodo raíz del grupo en su sitio
   ×5 y sus piezas como hijas a escala ×1, sin copiar las posiciones rotas.
6. **Árboles talables y plantas recolectables, nodos sueltos** (se talan uno a uno y se guardan); `MultiMeshInstance3D`
   solo para hierba decorativa sin uso. Ocultar a distancia con `visibility_range_end`.
7. **Conversores por herramienta** (`PackedScene` + `ResourceSaver.save()`), no escenas escritas a mano por la IA.
8. **Sin puentes**: los números viejos de un bloque se borran en el mismo cambio que lo pasa a la escena.
9. **No rediseñar tamaños** (casas ×1, vacío del ×5) hasta cerrar el paso 4. La navegación 3D y el suelo editable,
   después del paso 4. Suelo: decidir entonces entre Terrain3D y malla de Blender.
10. **Comprobación por paso**: arranque sin errores + la prueba de ese paso + fotos de lo tocado. Caso I y atascos en el
    paso 3; la batería completa en el paso 4.
11. El editor guarda las piezas YA en su sitio ×5: quitar las anclas no encoge el mapa si los números del código se
    convierten a ese mismo tamaño.

## Pasos (cada uno deja el juego jugable; se suben a `main` al acabar con su prueba en verde)
0. ✅ (2026-11-11, sobremesa) **Inventario automático.** Resultado en `docs/INVENTARIO_MUNDO.md`
   (`tools/tests/inventario_mundo.gd`, ver «Cómo medir»). Era: Prueba nueva que construye el mundo y lista todo lo que aparece (dibujos 2D, piezas 3D,
   choques, zonas de uso) y todos los destinos de los vecinos, diciendo de dónde sale cada uno: pieza del editor o número
   del código. Da la cifra exacta de lo que falta y será la vara de medir de los pasos siguientes. *Jugable: sin cambios.*
1. ✅ (2026-11-11, cerrado) Hecho: los 29 edificios fijos son escenas (`mapa/edificios/<id>.tscn`, creadas con
   `tools/convertir_edificios.gd`) y el juego las carga; su código de dibujo está borrado; «dobles» del inventario 885 → 0.
   Hecho también: marcas de las 5 familias fundadoras (`mapa/marca.gd`, `tools/marcar_edificios.gd`).
   Falta: el resto de marcas para la lógica (camas, mesas, puestos, salas: `VillageTavern`, `VillageRestaurant`, `VillageWorldBuilder`…),
   solo medir de nuevo el inventario. Hecho ya: todas las marcas de sitios (279 con puertas y ventanas), muebles de
   la capilla, casas modelo, borrado todo el dibujo de edificios por código, y planta, puerta, ventana y tabiques
   leídos de la escena (`mapa/planta.gd`, `mapa/tabique.gd`). Era:
   **Edificios completos en el editor**, por grupos (casas → oficios → públicos: iglesia, ayuntamiento, escuela…): muros,
   puerta, muebles, camas, mesas y puestos de trabajo como marcas dentro de cada edificio; el código las lee en vez de sus
   constantes. *Jugable tras cada grupo.* Prueba: inventario del grupo a 0 + sondeo de edificios movidos.
2. ✅ (2026-11-11, cerrado: solares y Puesto del Paso, mostradores, y plaza, lago y ciénaga como «Zonas»; detalle en
   `CHANGELOG.md`) **Exteriores**: cementerio, lavadero, campamento, corrales, huertos, pozos, decorado suelto y grupos hechos por código
   pasan a piezas. *Jugable.* Prueba: inventario de exteriores a 0 + fotos de cada zona.
3. **Sitios de los vecinos fuera de edificios**: oficios al aire libre, ocio, paseos, puntos de ruta, pistas del Caso I →
   marcas. *Jugable.* Pruebas: `partida_caso1.gd` y `atascos_vecinos.gd`.
4. **Quitar la traducción**: se borran las anclas, el factor ×5 y las copias `*.antes-x5`. *Jugable.* Prueba final:
   inventario total a 0, `verify_all.gd`, y una prueba nueva que mueve **cada** pieza del editor al azar y comprueba que
   nada queda en su sitio viejo y que cada cama, mesa y puesto cae dentro de su edificio.
5. **Aparte y con aprobación propia: caminar con navegación 3D** (rutas sacadas del escenario). Cambia cómo encuentran el
   camino y puede crear atascos nuevos; va solo, con su simulación de atascos antes y después.

## Coste y riesgos
- Estimación (supuesta, no medida): paso 0 una sesión; 1 tres o cuatro; 2 una o dos; 3 dos; 4 una; 5 dos o tres;
  suelo editable dos. Total realista según el profesional: **15–20 sesiones** (10–12 solo los pasos 0–4).
- Mientras dure, **el usuario no edita el mapa** y solo una sesión de Claude toca el código del mundo, para no pisarse.
- Las partidas guardadas dejarán de valer al acabar el paso 4 (ya pasó con el ×5).
- Lo que no cambia: lógica de los vecinos (necesidades, oficios, rutinas, charlas), Caso I, física 3D, guardado.

## Cómo medir (paso 0, 2026-11-11)
Tres órdenes (~25 s cada partida, con ventana: sin ella el juego no crea los modelos 3D):
```
flatpak run org.godotengine.Godot --path . -s tools/tests/inventario_mundo.gd -- quieto
flatpak run org.godotengine.Godot --path . -s tools/tests/inventario_mundo.gd -- movido
flatpak run org.godotengine.Godot --headless --path . -s tools/tests/inventario_mundo.gd -- comparar
```
«movido» mueve en memoria TODAS las piezas del editor (373, 241) px y arranca el juego; lo que sale del editor se mueve
con ellas. Se emparejan por familia y posición (las piezas sin nombre no se llaman igual en las dos partidas).

**Primera medida (2026-11-11):** de 6.783 cosas quietas del mundo (sin vecinos, animales ni el jugador):
| | Cosas | Qué es sobre todo |
|---|---:|---|
| Sigue al editor | 5.098 | vegetación, decorado, edificios y la mayoría de muebles |
| Se queda en el sitio viejo | 697 | 434 lotes de plantas hechas por código, 58 farolas/cables, 56 solares, 42 suelo y agua, 36 casas de recién llegados |
| Se mueve el doble | 885 | interiores de 8 edificios (taberna, comedor, molino, hospital, comisaría, taller, ayuntamiento…): traducidos dos veces |
| Acaba en otro sitio | 103 | 15 puestos del mercado, ~22 sitios de vecinos (cama, mesa, trabajo), piezas del molino y la biblioteca |
| Muebles fuera de todo edificio HOY | 14 | los de la capilla (altar, candelabros, atril, cáliz, cama, mesa, silla): fallo visible de la 2.ª partida |
Código: 1.830 puntos (≥ 100 px) y 103 rectángulos fijos; 162 llamadas a la traducción. La mitad, en 4 archivos
(`WorldStageTerrain3D`, `VillageWorldBuilder`, `WorldStageBuildings3D`, `EcosystemManager`).

**Lo que esta medida aún no ve:** piezas de un mismo grupo separadas entre sí hoy (cementerio, tejado del lavadero): se
mueven bien juntas, pero ya están mal colocadas. Los pasos 2 y 4 añaden esa comprobación (cada pieza dentro de su grupo).
