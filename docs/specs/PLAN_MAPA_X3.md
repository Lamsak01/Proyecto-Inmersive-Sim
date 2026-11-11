# Plan: el mapa 3 veces más grande (×3)

> Claude Code, 2026-11-11. Decisión del usuario: **×3** (cada distancia tres veces mayor; «todo más separado y más
> largo»), antes de rehacer los edificios antiguos (`BOCETO_EDIFICIOS_ANTIGUOS.md`, camino B).
> Qué notará el jugador: cruzar el pueblo pasa de 12 s a ~36 s andando; el valle entero, de 1 a 3 min (un día son 18 min).

## 1. Cómo está hecho hoy (lo que condiciona el plan)
- El código escribe **~4.900 números de posición** en «coordenadas del mapa original» (píxeles). No se van a reescribir.
- Desde el 2026-11-10 existe la capa de **anclas** (`mapa/anclas.gd`): todo punto fijo del código pasa UNA vez por
  `Anclas.mover()` (original → sitio actual) y las comparaciones con zonas usan `desmover()`. Las piezas del editor
  (38 edificios, 191 objetos, 23 decorados, 32 caminos) son las anclas.
- El 3D se dibuja a partir de lo mismo: edificios desde sus plantas ya traducidas; terreno, lago, ciénaga, plaza, parque y
  cementerio desde listas fijas; relieve por fórmulas en coordenadas del mapa; árboles y río desde el editor.
- Distancias «humanas» (oír, ver, golpear, cuerpos cercanos 150 px, radios de alerta) están en píxeles y **no deben**
  crecer: a ×3 las cosas quedan más lejos, pero la gente ve y oye igual.

## 2. La idea: estirar por el ancla, no reescribir el mapa
Un **factor de estiramiento E = 3** en la capa de anclas:
- Cada pieza (edificio, objeto, decorado) se coloca en **3× su centro original** pero **conserva su tamaño** (sus muebles,
  puertas y sitios interiores siguen a su centro, como ya hacen). Resultado: todo más separado, nada deformado.
- Los puntos fuera de cualquier pieza (campo abierto, paseos, caza, animales) se multiplican por 3 tal cual.
- `desmover()` hace lo contrario, así «¿está en la taberna?» sigue valiendo sin tocar ningún rectángulo.
- **Zonas de terreno** (lago, ciénaga, plaza, parque, cementerio, campos, corral, claro del Caso I) se estiran ×3 en
  posición **y tamaño** (un lago igual de pequeño a 3× de distancia parecería un charco).
- **Edificios ×1 ahora**: se rehacen más grandes (×2 de huella) uno a uno en el bloque de edificios, ya con sitio.
- Con **E = 1 el juego tiene que quedar idéntico** (todas las pruebas en verde): así el mecanismo se prueba solo antes de
  estirar nada.

## 3. Lo que no pasa por las anclas y hay que hacer a mano (inventario)
| Qué | Cómo | Coste |
|---|---|---|
| Escena del editor `mapa/Mundo3D.tscn` | Herramienta de un solo uso (como `convertir_escala_0b.py`): origen de cada pieza ×3, tamaño igual; copia previa | poco |
| Caminos (32 tramos del editor, mallas) | Rehacer con `hornear_caminos` desde la lista estirada: 3× de largo, ancho ×1,5 | poco |
| Río (`mapa/rio.gd`, puntos del editor) | Puntos ×3, ancho ×1,5; puentes y cruces siguen a sus anclas | poco–medio |
| Relieve del suelo (fórmulas con coordenadas) | Evaluar la fórmula en `p / E` (las lomas se estiran, pendientes más suaves) | poco |
| Malla del suelo (límites −3450..3050 × −1850..3250) | Límites ×3; paso de la rejilla ×1,5 (4× vértices, no 9×) | poco |
| Lago, ciénaga, plaza, parque, cementerio, campos, corral, claro | Listas del 3D y zonas 2D: posición ×3 y tamaño ×3 | medio |
| Árboles y plantas del editor (bosques) | Posición ×3; **repoblar ×3 en número** (no ×9) con más separación, para no hundir el rendimiento | medio |
| Alcantarillas (`desp_red`), club bajo la posada, sótano de tu casa | Siguen a su ancla; comprobar | poco |
| Bandidos de la llanura (`World.tscn`), nidos de animales, secuestradores del molino | Posiciones ×3 (los nidos ya pasan por `mover`) | poco |
| Mapa del valle [M] y minimapa (`ValleyMapUI.WORLD_RECT`, polígonos del bosque, río) | Rectángulo ×3; dibujar con `p / E` | poco |
| Región de navegación de los enemigos y baldosas de obstáculos 2D (`World.tscn`) | Límites ×3; vallas del rancho se rehacen en código | poco |
| Pruebas con posiciones escritas (`partida_caso1`, `puertas_3d`, `capturas_fijas`, `atascos`) | Pasan sus puntos por `mover` (ya lo hacen la mayoría) | poco |
| Partidas guardadas antiguas | No valen (posiciones absolutas): partida nueva (estamos en demo) | — |
| Fotos de referencia | Nueva tanda de referencia tras el estirado | poco |

## 4. Pasos (cada uno con prueba y foto; commit al cerrar)
1. **Mecanismo E** en anclas + `desmover`, con E = 1: sondeo 54/60 y 29/29, `verify_all`, `fisica_3d`, `puertas_3d`, Caso I 25/25 idénticos. *(medio)*
2. **Herramienta de conversión** de la escena y rehacer caminos y río. E = 3. Arranque, fotos desde arriba. *(medio)*
3. **Relieve, malla y zonas de terreno** ×3 (tabla §3). Fotos: plaza, lago, bosque, llanura. *(medio)*
4. **Repoblar bosques y vegetación**, bandidos, animales, alcantarillas, mapa [M]. *(medio)*
5. **Pruebas largas**: atascos 6 h, puertas, Caso I a pie, rendimiento en el portátil (objetivo: no bajar de los 25 fps de la plaza). *(medio)*
6. El usuario juega y **ajusta a mano en el editor** lo que no le guste (ya sabe mover piezas). *(usuario)*
Coste total estimado: **2–3 sesiones de trabajo** (unas 12–18 horas), más los ajustes del usuario.

## 5. Riesgos y cómo se evitan
- **Traducción doble** (un punto ×3 dos veces): regla de siempre (una sola vez, donde se escribe) + sondeo automático.
- **Rendimiento**: 9× de superficie. Árboles ×3 (no ×9), malla ×4 (no ×9), lo lejano ya se dibuja menos. Medir en el portátil.
- **Rutinas de los vecinos**: ir al trabajo tarda 3×. Si el día se queda corto, subir el día de 18 a 24 min (decisión del usuario, después de probar).
- **Edificios minúsculos en solares enormes**: es a propósito, hasta el bloque de edificios (×2 de huella).

## 6. Decisiones ya tomadas por el usuario (2026-11-11)
- ×3, antes que los edificios. Edificios después, más grandes.
- En las tiendas-taller, **la familia duerme encima de su tienda** (piso alto).
- Las 4 «residencias» que quedan libres **no se alquilan**: las ocupan **vecinos nuevos desde el día 1** (más gente en el pueblo). Faltan: qué oficios/familias (se decide en el plan de edificios).

## 7. Pendiente de decidir (puedes contestarlo cuando quieras)
- ¿Río ×1,5 de ancho (propuesto) o igual?
- ¿Día de 18 min o 24 min tras probar el mapa grande?
- Los 4 hogares nuevos para las casas libres: ¿qué oficios? (propuesta: cantero de la cantera, familia de leñadores, costurera viuda con hijo, pastor del rancho).

## 8. Registro de lo hecho (2026-11-11, Claude Code, portátil; rama `mapa-x5`)
- **Decisión del usuario: ×5** (no ×3). El número vive en `Mapa3D.E`; `tools/estirar_mapa.py` convierte las escenas con él.
- Paso 1 (E = 1, idéntico): mecanismo en `mapa/anclas.gd` (`aplicar` estira el campo abierto; cada pieza va a E·c + d con
  su tamaño; `desmover` al revés; índice por celdas; grupos compactos `GRUPOS` (campamento, cementerio, claro, corral);
  la red de alcantarillas es una pieza (BajoTierra); con E = 1 manda la primera ancla registrada, como siempre).
  Sondeo 54/60 y 29/29, física, puertas y fotos idénticas.
- Paso 2 (E = 5): `estirar_mapa.py` (1.320 cambios en Mundo3D, río ×5 y ancho ×2, bandidos ×5; copias `*.antes-x5.tscn`),
  caminos rehechos (`hornear_caminos` con E: largo ×5, ancho ×2), relieve en `p / E`, malla del suelo con límites ×5 y
  paso ×2, zonas del terreno ×5 (plaza, parque, cementerio, lago, ciénaga), baldosas antiguas de choque recolocadas por
  las anclas (`World._estirar_baldosas`), tabiques escritos a mano por las anclas (`_add_solid_wall_segment`), en pausa de
  construcción las anclas no estiran, `desmover` saca del hueco original de las piezas (`_fuera_de_piezas`), mapa del valle
  y minimapa ×E, sonda de edificios con E, prueba del Caso I y fotos fijas por las anclas, secuestradores del molino por
  las anclas, lago en `p / E`.
- Arreglo encontrado por el camino: las copias 3D de paredes de un vecino (p. ej. el agua, que para él es muro) frenaban
  al protagonista → cada cuerpo choca solo con sus propias copias (`Cuerpo3D.CAPA_MUROS_*`).
- Paso 4: `tools/repoblar_bosque.gd -- 3 26`: 699 árboles nuevos junto a los 233 (sin río, edificios ni solapes).
- Después: interiores 3D con coordenadas fijas (posada, comisaría, trattoria) por las anclas (`mover_posiciones`); objetos
  pegados a un edificio vuelven con él (`estirar_mapa_objetos.py`, 79); pistas del Caso I comparadas en el mapa original;
  cama alta sin traducir dos veces; copias de paredes por cuerpo. Resultados: física 0 fallos, puertas 29/29, atascos 3 h = 0,
  Caso I a pie 24/25 → 25/25 (zapato por su sitio real), rendimiento plaza 21 / río 24 / bosque 23 fps (la lógica de los
  vecinos manda, no el 3D). Fotos de referencia nuevas: `docs/capturas_mundo3d/referencia_x5/`.
