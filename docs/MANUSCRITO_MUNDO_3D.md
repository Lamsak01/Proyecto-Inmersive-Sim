# Manuscrito del paso a 3D (y de cada reorganización del código)

> Una entrada por bloque, de la más nueva a la más antigua. Para personas: qué cambió en el juego, por qué, qué archivos
> (y de dónde a dónde se movió cada cosa), cómo se probó y cómo deshacerlo. El resumen de una línea va en el Registro de
> `docs/PLAN_MUNDO_3D.md` §10. Rama de trabajo: `mundo-3d`. Copia de seguridad: etiqueta `antes-de-mundo-3d`.

---

## Paso 2a — La posada con dos plantas de verdad (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** en la posada, al subir la escalera andando estás de verdad más alto (3,3 m); el piso (Planta 0
o +1) sale de la altura de tu cuerpo, no de una raya en el mapa. Abajo no estorban las barandillas y tabiques de arriba
y arriba no estorban los muebles de abajo. La cámara en 1.ª persona y tu muñeco van donde está tu cuerpo 3D. La [E] de la
escalera sigue funcionando (te lleva arriba o abajo de golpe).

**Por qué:** primer trozo del paso 2 (alturas de verdad). Antes los pisos eran «capas» que se cambiaban al cruzar una
raya a mitad de la escalera.

**Cómo funciona (para personas):**
- La posada dice qué suelos hay en cada punto (Planta 0; en el hueco de la escalera, la rampa; en el resto, también la
  Planta +1). El cuerpo pisa el más alto al que llega subiendo como mucho un peldaño (45 cm); si no, cae al de abajo.
- Los choques de un solo piso llevan siempre una marca (capa 20 del mapa), aunque estén «apagados» para el mapa porque
  estás en el otro piso. El cuerpo 3D los ve todos y los levanta solo a la altura de su piso.
- Sótanos, club de peleas, alcantarillas y los pisos de tu casa siguen siendo «capas» (trozos 2b y 2e).

**Archivos:**
- `scripts/systems/VillageTavern.gd`: nuevos `floor_heights_at`, `STAIRS_WELL_RECT` (hueco de la escalera),
  `GALLERY_EDGE_Y`, `FLOOR_0_SURFACE_H`, `FLOOR_1_SURFACE_H`. **Quitado** de `tick` el cambio de piso del protagonista por
  posición (y la «seguridad» que lo bajaba si salía del suelo alto): ahora lo hace el cuerpo.
- `scripts/fisica/Suelo.gd`: `pisos_en`, `elegir`, `nivel_de`, `capa`, `piso_de_choque`, `CAPA_PISOS`.
- `scripts/fisica/Cuerpo3D.gd`: elige el suelo por altura, avisa del piso al pueblo, `altura_pies_px`; los muros se
  levantan desde el suelo de abajo (`_calle_y`).
- `scripts/fisica/ChoquesCercanos3D.gd`: altura de cada copia según su piso (`_banda`); los muros normales suben 9 m.
- `VillageManagerBase.gd`, `VillageClub.gd`: los choques de un piso usan `Suelo.capa(...)` al crearse y al cambiar de piso.
- `PlayerMovementController.gd` y `Player.gd`: `altura_pies_px` / `get_altura_pies_px`.
- `CharacterAvatar3D.gd` y `WorldStage3D.gd`: el muñeco del protagonista y los ojos en 1.ª persona van sobre el cuerpo 3D
  (sin cuerpo aún, como antes). En la posada el techo de la cámara es el de dos plantas en los dos pisos.
- `tools/tests/fisica_3d.gd`: prueba del paso 2.

**Cómo se probó:** fisica_3d ✅ · puertas_3d ✅ 29/29 · verify_all ✅.

**Cómo deshacerlo:** `git revert` de este commit, o volver a la etiqueta `antes-paso-2`.

## Paso 1b — Recorrido por todas las puertas y cierre del paso 1 (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** nada; son comprobaciones.

**Archivos:**
- Nuevo `tools/tests/puertas_3d.gd`: el protagonista entra y sale andando, recto y a paso normal, por las 29 puertas de
  edificio del pueblo (abiertas). Falla si no llega 10 px más allá de la puerta.
- `tools/tests/capturas_fijas.gd`: cada foto dice dónde quedó el protagonista (para entender diferencias).
- Fotos nuevas de referencia: `docs/capturas_mundo3d/referencia_paso1/`.

**Resultados:**
- Puertas: 29/29 entra y sale. Vecinos atascados: 0 en 6 h.
- Fluidez: igual que en el paso 0b medida con el portátil igual de lento (afueras 8, plaza 5, río 5, bosque 7, molino 8,
  mansión 8). El cuerpo 3D cuesta ~1 ms por paso de física (10–16 choques copiados alrededor).
- Fotos: río, bosque, molino, mansión y dentro de la taberna iguales (≤ 1 %). La plaza cambia: el sitio de la foto
  toca un puesto y el cuerpo 3D empuja al protagonista 4 px fuera (antes se quedaba metido); desde tan cerca, eso
  cambia media imagen. La foto desde arriba cambia por lo mismo.

**Pendiente para más adelante:** si en el portátil bueno el cuerpo pesa, preguntar al mapa por los choques cada pocos
pasos en vez de en cada uno.

 El protagonista tiene cuerpo 3D (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** casi nada a la vista. El protagonista ya no choca, cae ni salta en el mapa plano: lo hace un
cuerpo 3D de verdad (cápsula de 1,74 m) que anda por el mundo 3D y después escribe su sitio en el mapa, así el resto del
juego (vecinos, misiones, guardado, cámara) sigue igual. El salto es ahora un salto con gravedad 3D (~1,1–1,2 m).

**Por qué:** es la primera pieza de «cuerpo en 3D, cerebro en el mapa» (plan §4, paso 1). Sin esto no hay cuevas,
escaleras de verdad ni nadar.

**Cómo funciona (para personas):**
- El mando del jugador sigue calculando a qué velocidad quiere ir en el mapa; en vez de moverse él, se lo pasa al cuerpo 3D.
- Las paredes no se rehacen: cada paso se pregunta al mapa qué choques hay a 110 px (unos 6 m) y se mantiene una copia
  3D de cada uno, levantada 4 m como un muro. Puertas que se abren, vecinos que se mueven o muros solo de planta alta se
  copian solos.
- Hasta el paso 2 el suelo es una losa invisible que va bajo los pies a la altura de siempre (tarima de edificios,
  plaza, puentes, planta alta de la taberna).
- Si el juego cambia al protagonista de sitio a mano (cama, escaleras, cárcel, cargar partida), el cuerpo salta ahí.
- El protagonista sigue en el mapa como obstáculo para los vecinos; solo deja de chocar él en el mapa.

**Archivos:**
- Nuevos en `scripts/fisica/`: `Cuerpo3D.gd` (el cuerpo), `ChoquesCercanos3D.gd` (copias 3D de los choques del mapa),
  `Suelo.gd` (a qué altura está el suelo; antes este cálculo estaba dentro de `CharacterAvatar3D.gd`, ahora lo comparten
  el cuerpo y los muñecos).
- `PlayerMovementController.gd`: fuera el salto «de mentira» (altura y gravedad en píxeles y su bucle); cada
  `move_and_slide` pasa por `_mover()` → cuerpo 3D. Nuevo `parar_salto()`.
- `CharacterAvatar3D.gd`: usa `Suelo.altura_px`.
- Pruebas: `fisica_3d.gd` (paso 1: tiene cuerpo, cruza la puerta de la taberna, un muro lo para, salta ~1,1 m, aterriza,
  sigue un cambio de sitio); `verify_all.gd` (la prueba del salto ya no mira la altura vieja en píxeles).

**Cómo se probó:** fisica_3d ✅ (20 choques copiados junto a la taberna, salto 1,14 m) · verify_all ✅.

**Cómo deshacerlo:** `git revert` de este commit, o volver a la etiqueta `antes-paso-1`.

## Paso 0b — Escala uniforme en metros (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** el mundo 3D tiene las mismas proporciones en todas direcciones y se mide en metros
(1 unidad = 1 m; una persona mide 1,74 m). El pueblo es un 15 % más corto de norte a sur que antes **en 3D** (en el mapa
del pueblo nada se mueve: vecinos, casas, rutas y partidas siguen igual). Lo redondo ya no sale ovalado. Las casas tienen la
misma altura que antes. La vista desde arriba sigue cuadrando con el mapa.

**Por qué:** decisión del usuario (opción B). Con el mundo estirado y diminuto (una persona medía 0,6 unidades) la física
3D del paso 1 no habría chocado bien; el motor está pensado para metros.

**Qué se hizo:**
1. `scripts/fisica/Mapa3D.gd`: `ESCALA` = 0,056 m por píxel de suelo, igual en x y z (ya no se divide por sin 58°).
   `ALTO` = 0,1057 m por píxel de altura (las alturas se ven como antes). Nuevos: `K` (= 2,8, cuánto ha crecido el
   mundo), `INCLINACION_GRADOS` = 62,08° y `ESTIRA_VERTICAL` (vista desde arriba), `dir_a_3d`. Fuera `SIN` y `COS`.
2. Escenario (`scripts/visuals/`):
   - `WorldStageBase3D.gd`: fuera `_sin_p`; `_cos_p` = ESCALA/ALTO (para estirar muñecos en la vista de arriba);
     alturas con `Mapa3D.alto_a_3d`; texturas del suelo y de edificios repetidas igual que antes (`/ K`); función nueva
     `_particulas_a_metros` (humo, chispas, fuego, polvo × K); temblor de cámara × K.
   - `WorldStage3D.gd`: cámara de arriba a 62,08° con la imagen más baja y estirada (`_ajustar_alto_imagen_3d`, nueva);
     distancias de cámara, sombras, linternas, niebla (÷ K) y alcance de objetos pequeños en metros
     (`TAM_PEQUENO`/`TAM_MEDIANO` 0,56/1,68 m; `ALCANCE_PEQUENO`/`MEDIANO` 14/28 m; antes se creía que 1 u = 5 m: era
     2,8 m); chispas de golpe × K.
   - `WorldStageBuildings3D.gd`, `WorldStageProps3D.gd`, `WorldStageTerrain3D.gd`: fuera las divisiones por sin 58°
     escritas a mano (edificios movidos, alcantarillas, rueda del molino, pasillos); luces × K; letreros 3D × K; choque
     de los troncos caídos con su largo real.
   - `CharacterAvatar3D.gd`: `STAGE_K` × K (los bandidos lo heredan). `AnimalModel3D.gd`: su luz × K (el tamaño ya
     salía de `ESCALA`).
3. Editor del mapa: `mapa/anclas.gd` → `matriz()` es un giro normal (el 3D ya no está aplastado); `mapa/mundo3d.gd`
   letreros × K; `tools/hornear_edificios.gd` hace la foto sin el movimiento del usuario (antes la foto de un edificio
   movido salía desplazada dos veces).
4. **Mapa del usuario convertido** con `tools/convertir_escala_0b.py` (nuevo, de un solo uso): copia en
   `mapa/Mundo3D.antes-3d.tscn`; 2.845 piezas; cada una en el mismo sitio del mapa del pueblo (diferencia 0,0000 px).
   Vegetación, objetos y edificios solo mueven su origen (su modelo se rehace solo); muebles en local; Decorado y
   Caminos cambian de forma entera (sus mallas guardadas estaban en la escala vieja).
5. Fotos de los edificios rehechas (`tools/hornear_edificios.gd`, `tools/hornear_bajo_tierra.gd`); la de
   `house_family_lot_m4` (solar que el juego no construyó en esa partida) se reescaló a mano con la misma regla.
6. **Arreglo de paso (vecinos encimados en las puertas):** con el mundo en metros, las rocas y matorrales del mapa ocupan
   su largo real de norte a sur (un 18 % más que antes en el mapa del pueblo), los vecinos toman caminos algo distintos y
   la prueba grande destapó un fallo que ya existía: en el umbral de una puerta los vecinos dejaban de guardar distancia
   y dos podían quedarse encimados (puerta del restaurante). `scripts/enemies/VillageNPCSocial.gd`
   (`_enforce_npc_personal_space`): en la puerta la distancia mínima baja a `SEP_EN_PUERTA` = 10 px (caben dos de
   frente) en vez de desaparecer. Comprobado que lo demás del mapa del pueblo es idéntico (todas las paredes invisibles
   comparadas una a una con la versión anterior: solo cambian las de rocas y matorrales).
7. Pruebas: `fisica_3d.gd` comprueba proporciones, altura de una persona, ojos y que la vista de arriba cuadra con el mapa
   (cuenta exacta); `capturas_fijas.gd` añade una foto desde arriba; `pincel_mapa.gd` usa `Mapa3D`.

**Cómo se probó:** ver Registro (§10) del plan.

**Cómo deshacerlo:** `git checkout antes-paso-0b` (la rama tal como acabó el paso 0); para el mapa sólo:
`mapa/Mundo3D.antes-3d.tscn` → `mapa/Mundo3D.tscn` (y volver a las fotos viejas de `mapa/edificios_vista/` con git).

---

## Paso 0 — Preparación (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** nada visible. Es la base para lo demás.

**Por qué:** antes de dar física 3D al mundo hacía falta (1) poder volver atrás, (2) medir cómo está todo hoy para
comparar después y (3) que la fórmula que pasa del mapa al 3D esté en un solo sitio, porque la física la va a usar en todas
partes y había unas 20 copias repartidas.

**Qué se hizo:**
1. **Copia de seguridad y rama aparte.** Etiqueta `antes-de-mundo-3d` en `main` y rama `mundo-3d` (subidas a GitHub).
2. **Conversión única:** archivo nuevo `scripts/fisica/Mapa3D.gd` con `a_3d`, `a_mapa`, `alto_a_3d`, `alto_a_px` y
   `tam_a_3d`. Los mismos números que antes (comprobado con 2.000 puntos al azar).
   - `scripts/visuals/WorldStageBase3D.gd`: `WORLD_SCALE`, `PITCH_DEG`, `_sin_p` y `_cos_p` salen de `Mapa3D`;
     `to_3d`, `to_3d_flat` y `size_3d` llaman a `Mapa3D` (de 20 líneas a 6).
   - `scripts/visuals/WorldStageTerrain3D.gd`: `_a_mapa_2d` llama a `Mapa3D.a_mapa`.
   - `scripts/visuals/AnimalModel3D.gd`: su `WORLD_SCALE` sale de `Mapa3D`.
   - Editor del mapa (`mapa/anclas.gd`, `camino.gd`, `edificio.gd`, `mueble.gd`, `objeto.gd`, `pieza.gd`, `mundo3d.gd`,
     `pincel_nucleo.gd`) y `addons/pincel_mapa/pincel_plugin.gd`: fuera sus constantes `WORLD_SCALE`/`PITCH_DEG` y sus
     senos/cosenos propios; usan `Mapa3D`.
   - Herramientas `tools/hornear_*.gd` (vegetación, edificios, objetos, decorado, caminos, bajo tierra): igual.
3. **Arreglos de paso (fallaban ya antes de este trabajo; comprobado en la copia `antes-de-mundo-3d`):**
   - `tools/hornear_edificios.gd` no compilaba (`.hash()` sobre bytes); ahora usa `hash(...)` como la herramienta del decorado.
   - `tools/tests/rio_editor_juego.gd` esperaba el río original; el usuario ya lo editó (6 cruces, 7 tramos de agua). Ahora
     comprueba que el juego usa el río del editor y que hay un tramo de agua más que cruces.
   - `tools/tests/pincel_mapa.gd` cargaba sus piezas antes de que existieran los autoloads (no compilaba); ahora las carga
     al arrancar.
4. **Pruebas nuevas:**
   - `tools/tests/fisica_3d.gd`: prueba del paso a 3D; de momento comprueba que la conversión única da lo mismo que la
     antigua y que el escenario la usa.
   - `tools/tests/capturas_fijas.gd`: 6 fotos siempre iguales (plaza, río, bosque, molino, mansión, dentro de la taberna;
     mediodía, sin personajes) y comparación con una carpeta de referencia (% de píxeles distintos).
   - Fotos de referencia en `docs/capturas_mundo3d/referencia_paso0/` (hechas en el portátil, 3072×1728; en otro
     ordenador hay que hacer las suyas antes de comparar).
5. **Documentos nuevos:** `docs/MAPA_DEL_CODIGO.md` (qué hace cada carpeta y archivo) y este manuscrito.

**Cómo se probó:** `fisica_3d.gd` 7/7; fotos fijas iguales a la referencia (peor 0,38 %; el ruido entre dos tandas sin
cambios llega a 0,8 %); `verify_all.gd` ✅; `guardado_largo.gd` ✅; `sondeo_edificios_movidos.gd -- movido` 29/29;
`rio_editor_juego.gd` (normal y «mover») ✅; `pincel_mapa.gd` ✅; todos los scripts del editor y las herramientas cargan.

**Cómo deshacerlo:** `git checkout antes-de-mundo-3d` (todo el juego como estaba) o revertir el commit de este paso en la
rama `mundo-3d`.
