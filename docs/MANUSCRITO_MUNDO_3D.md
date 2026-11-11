# Manuscrito del paso a 3D (y de cada reorganización del código)

> Una entrada por bloque, de la más nueva a la más antigua. Para personas: qué cambió en el juego, por qué, qué archivos
> (y de dónde a dónde se movió cada cosa), cómo se probó y cómo deshacerlo. El resumen de una línea va en el Registro de
> `docs/PLAN_MUNDO_3D.md` §10. Rama de trabajo: `mundo-3d`. Copia de seguridad: etiqueta `antes-de-mundo-3d`.

---

## Arreglo 2026-11-11 — Cuerpos de contacto de quien desaparece (Claude Code, portátil)

**Qué pasaba:** si un bandido (o cualquiera con cuerpo de contacto, paso 4b–4c) moría o huía cerca del protagonista y
desaparecía del juego, su cuerpo quedaba apuntado y cada fotograma saltaba un error al intentar soltarlo (2.154 errores
en una prueba). **Arreglo:** `CuerposCercanos3D.actualizar` suelta también a quien ya no existe; `_soltar` acepta
cualquier cosa. Visto en `verify_all` tras el arreglo de los bandidos.

## Paso 5d — Con [E] se llega a lo que está a tu altura (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** lo que puedes usar o con quien puedes hablar con [E] se decide por altura (los pies a menos
de ~1,3 m), no por «mismo piso»: en la escalera de la posada hablas con quien va unos peldaños más arriba; desde el
salón no llegas a quien está en la galería ni a las camas de arriba, y desde la galería no llegas a la mesa de póker ni a
la puerta. Lo demás sigue igual (la cruz en 1.ª persona ya tenía en cuenta hacia dónde miras).

**Por qué:** último trozo del paso 5; además quita listas a mano (qué sitios de la posada valen en cada piso).

**Archivos:**
- `scripts/ui/InteractionSelector.gd`: `refresh` usa `vm.alcanza`; `_nivel_de` da el piso de cada objeto (el suyo si lo
  tiene; los sitios fijos de la posada según estén en la galería o en el salón; lo demás, el tuyo). Fuera las listas
  «tavern_games / tavern_pool / building_door / tavern_bed».
- `tools/tests/fisica_3d.gd`: prueba del paso 5d (3 comprobaciones).

**Cómo se probó:** fisica_3d ✅ · puertas_3d 29/29 · verify_all ✅ (una vez falló su comprobación de vecinos encimados,
dos vecinos a 7,8 px en la calle tras simular a todo el pueblo andando; al repetir pasó. No lo causa este paso, que solo
toca la tecla E; es el azar del pueblo. Si se repite, mirar `_enforce_npc_personal_space`).

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 5c — Golpes, flechas y balas con altura (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** tus golpes y empujones alcanzan a quien tenga los pies a menos de ~1,3 m de los tuyos
(en la escalera de la posada sí; a quien está en la galería desde el salón, no); antes era «mismo piso». Las flechas
y las balas vuelan con altura: salen del pecho y, en 1.ª persona, con la pendiente hacia donde miras (arriba o abajo).
Solo hieren a quien esté a esa altura; si bajan hasta el suelo, la flecha se clava y la bala desaparece; un suelo alto
(la galería) las para. Antes volaban planas y herían a cualquiera que cruzaran, aunque estuviera en otro piso.

**Archivos:**
- `scripts/fisica/Vista.gd`: `alcanza` (golpes por altura de los pies), `altura_pies` (lo usa también `altura_ojos`),
  `tapa_un_suelo` ahora es pública (la usan las flechas); constantes `ALCANCE_VERTICAL_PX` y `ALTO_CUERPO_PX`.
- `scripts/systems/VillageManagerBase.gd`: `alcanza(...)` (atajo, como `ve` y `oye`).
- `scripts/PlayerCombatController.gd`: el empujón y el golpe usan `vm.alcanza` en vez de comparar pisos.
- `scripts/systems/combat/ArrowProjectile.gd`: `altura_px` y `pendiente` (si nadie las pone, el pecho de quien dispara y
  la mirada del protagonista); `_preparar_altura`, `_toca_suelo`, `_a_su_altura`.
- `tools/tests/fisica_3d.gd`: prueba del paso 5c (5 comprobaciones; las flechas, contra un ciervo).
- Sin tocar: los disparos de la policía son instantáneos (sin proyectil) y ya dependen de que te vean (5a).

**Cómo se probó:** fisica_3d ✅ · puertas_3d 29/29 · verify_all ✅.

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 5b — El oído con alturas (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** un ruido (golpe, grito, disparo) ya llega a los vecinos de otro piso, más flojo: a través
de un suelo se oye a un tercio (como a través de una pared); por la galería abierta de la posada, entero; entre la
calle y el club o las alcantarillas, casi nada (un décimo). Antes en otro piso no se oía nada. Y los testigos de un ruido
solo cuentan como testigos si lo ven de verdad (Vista.gd), ya no «si están en el mismo piso».

**Archivos:**
- `scripts/fisica/Vista.gd`: `oye(vm, a, nivel_a, b, nivel_b)` → cuánto llega (1, un tercio o un décimo).
- `scripts/systems/VillageManagerBase.gd`: `oye(...)` (atajo, como `ve`).
- `scripts/systems/AudioManager.gd`: ya no salta a los vecinos de otro piso; multiplica su alcance por `vm.oye`.
- `scripts/enemies/VillageNPCDuties.gd`: `on_noise_heard` ya no descarta por piso (lo decide AudioManager);
  `can_witness_combat_at` usa `vm.ve`.
- `tools/tests/fisica_3d.gd`: prueba del paso 5b.

**Arreglo de paso (cuerpos de contacto, 4b–4c):** la prueba de las puertas falló en la carnicería: un vecino parado
dentro te cerraba el paso del todo. Ahora, andando contra alguien con cuerpo, lo apartas poco a poco hacia el lado en
que ya está (`Cuerpo3D._apartar`, 40 px/s, respetando paredes y muebles con `sanitize_npc_separation_pos`; cada cuerpo
guarda de quién es en su meta «quien»), y los sentados (mesa de póker o silla) no tienen cuerpo: la silla ya estorba.
La prueba del río elige un tramo sin vecinos ni animales cerca (`_alguien_en`): un ciervo en la orilla la hacía fallar.

**Cómo se probó:** fisica_3d ✅ · puertas_3d 29/29 · verify_all ✅.

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 5a — La vista con alturas de verdad (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** quién te ve (testigos, guardias y policías, y los testigos de una pelea) ya se decide con
las alturas de verdad y no con «¿estamos en el mismo piso?». Las paredes y las puertas cerradas tapan como antes; además
los suelos tapan de verdad: desde el salón de la posada se ve a quien está asomado al borde de la galería (y él te ve a
ti), pero no a quien está justo encima de ti. Bajo tierra nadie te ve desde la calle. Donde todavía no hay alturas
conocidas (pisos de las casas, hasta el paso 2e) dos pisos distintos siguen sin verse, como antes. Un policía que te ve
desde otro piso ya te persigue.

**Por qué:** primer trozo del paso 5 (sentidos). Pedido del usuario: código mínimo, eficiente y por funciones.

**Archivos:**
- `scripts/fisica/Vista.gd` (nuevo, ~40 líneas): `ve(vm, a, nivel_a, b, nivel_b)`: bajo tierra → no; sin alturas
  conocidas y pisos distintos → no; paredes y puertas (`vm.has_line_of_sight`, como siempre); y `_tapa_un_suelo`: si
  la recta entre los ojos de uno (`altura_ojos`) y los del otro cruza una losa, no se ven.
- `scripts/fisica/Suelo.gd`: `losas()` (qué suelos altos tapan la vista). `scripts/systems/VillageTavern.gd`:
  `losa_planta_1()` (galería y cuartos; el hueco de la escalera no).
- `scripts/systems/VillageManagerBase.gd`: `ve(...)` (atajo a Vista para que nadie más tenga que cargarla);
  `_find_conscious_witness_near` usa `ve` en vez de «mismo piso + línea de visión».
- `scripts/enemies/VillageNPCDuties.gd` (policía), `scripts/systems/VillageUnderworld.gd` (guardia que vigila la
  reja) y `scripts/systems/VillageSocialLife.gd` (testigos de una pelea): lo mismo.
- `tools/tests/fisica_3d.gd`: prueba del paso 5a (6 comprobaciones).
- Sin tocar: `are_on_same_elevation` sigue para lo que no es ver (alcance de golpes, letreros, charlas).

**Cómo se probó:** fisica_3d ✅ · puertas_3d 29/29 · verify_all ✅. Una vez falló la prueba del paso 1 «cruza la puerta de la taberna» (el protagonista se
quedó en la puerta); al repetir pasó: seguramente un vecino parado en el umbral (cuerpo de contacto del paso 4b).

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 4c — Animales grandes y bandidos también tienen cuerpo (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** como con los vecinos: ya no atraviesas a bandidos, enemigos, jabalíes, ciervos ni al ganado
grande adulto (ovejas, vacas, toros, burros, caballos del corral). Conejos, zorros, mascotas, gallinas y crías se siguen
atravesando (antes se atravesaba a todos a propósito). Tu caballo y tu carro no cambian: ya iban con tu cuerpo 3D.

**Decisión del usuario:** «sí» a cuerpo para los grandes y no para los pequeños.

**Archivos:**
- `scripts/fisica/CuerposVecinos3D.gd` → `scripts/fisica/CuerposCercanos3D.gd` (renombrado: ya no son solo vecinos);
  `tamano()` decide quién tiene cuerpo y de qué tamaño (persona 0,28 × 1,74 m; animal 0,4 × 1,3 m); `GRUPOS`.
- `scripts/fisica/Cuerpo3D.gd`: `vecinos()` → `cercanos()`.
- `tools/tests/fisica_3d.gd`: prueba del paso 4c; la del paso 1 («el cuerpo sigue al protagonista cuando lo cambian
  de sitio») admite 12 px, porque si justo hay alguien de pie ahí su cuerpo lo aparta un poco (fallaba a veces).

**Cómo se probó:** fisica_3d ✅ (ciervo o jabalí con cuerpo y para al protagonista; conejo, gallina y crías sin cuerpo) ·
puertas_3d 29/29 · verify_all ✅.

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 4b — Ya no se atraviesa a los vecinos (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** antes el protagonista atravesaba a los vecinos (salvo si peleaban con él). Ahora los
vecinos que tiene cerca (unos 6 m) tienen un cuerpo 3D «de contacto»: chocas con ellos como con una persona. Un
vecino dormido, muerto o en el suelo no tiene cuerpo (se pasa por encima). El cuerpo va a la altura del suelo del
vecino, así uno que está en la planta de arriba no estorba abajo. Los vecinos siguen andando por sus rutas como antes.

**Decisión del usuario:** opción A ahora (cuerpo de contacto), opción B más adelante (cuerpo completo que choca con
paredes y buscador de caminos 3D). Apuntada en el plan.

**Archivos:**
- `scripts/fisica/CuerposVecinos3D.gd` (nuevo): hasta 16 cuerpos (cápsulas que se mueven solas) que se reparten entre
  los vecinos cercanos cada paso y siguen su sitio del mapa.
- `scripts/fisica/Cuerpo3D.gd`: crea `CuerposVecinos3D` y lo pone al día en cada paso; `vecinos()`.
- `scripts/fisica/ChoquesCercanos3D.gd`: ya no copia el círculo 2D de los vecinos (lo tenían solo los que peleaban).
- `tools/tests/fisica_3d.gd`: prueba del paso 4b.

**Cómo se probó:** fisica_3d ✅ (sin nadie pasa; con un vecino delante choca; dormido se pasa) · puertas_3d 29/29 ·
verify_all ✅. Los vecinos no cambian su forma de andar, así que no se repitió la prueba de atascos.

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 4a — Vecinos por la escalera de la posada (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** casi nada; se comprobó que los vecinos ya subían y bajaban la escalera andando y ganando
altura poco a poco. Arreglo pequeño: cambiaban de planta un poco antes del último peldaño y daban un escalón de
golpe de ~24 cm al pisar la galería; ahora cambian al pisarlo (queda un paso normal de ~15 cm).

**Por qué:** primer trozo del paso 4 aprobado por el usuario (escalera → cuerpo 3D de los cercanos → animales →
quitar empujones viejos).

**Archivos:**
- `scripts/systems/VillageTavern.gd`: `STAIRS_END_TOL` (3 px; antes 10 px fijos en `_route_original`).
- `tools/tests/fisica_3d.gd`: prueba del paso 4a (un vecino va a una cama de arriba andando).

**Cómo se probó:** fisica_3d ✅ (sube a la cama, pisa el suelo alto, cambio de altura máximo por fotograma 1,44 px) ·
atascos_vecinos 6 h: 0 atascos.

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 3a — Nadar en el río y en el lago (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** el agua ya no es una pared: puedes meterte en el río y en el lago. Cerca de la orilla
vadeas (el agua te cubre las piernas y vas algo más lento); donde no haces pie, nadas: vas a menos de la mitad de
velocidad, no puedes correr ni saltar y gastas aguante; si se te acaba, casi no avanzas. Flotas con la cabeza fuera
y sales andando por la otra orilla. El centro del río del pueblo no se hace pie; el arroyo del bosque norte casi
se vadea; el lago es hondo lejos de la orilla. Caer al agua honda (1,5 m o más) no hace daño. Los vecinos siguen
sin meterse en el agua (para ellos el río sigue siendo una pared; se cambiará en el paso 4).

**Por qué:** primer trozo del paso 3 (orden del usuario: «sigue para nadar y bucear»). Bucear va en el 3b.

**Archivos:**
- `scripts/fisica/Agua.gd` (nuevo): dónde hay agua, a qué altura está su superficie (la misma lámina que se dibuja)
  y cuánto cubre en cada punto (`hondura_m`; el fondo aún no se dibuja).
- `scripts/fisica/Cuerpo3D.gd`: en el agua el suelo del cuerpo es el fondo o, si es hondo, la altura a la que flota
  (`_suelo_en_agua`, `FLOTA_M`); estado `en_agua` (seco / vadeando / nadando); nadando no salta; caer al agua honda
  no duele.
- `scripts/PlayerMovementController.gd`: `estado_agua` y `_freno_agua` (más lento y gasta aguante al nadar; sin correr).
- `scripts/fisica/ChoquesCercanos3D.gd`: no copia los choques del agua (grupo «agua_2d»), así el cuerpo 3D entra.
- `scripts/systems/VillageWorldBuilder.gd` y `scripts/obstacles/FishingSpot.gd`: los choques del río y del lago van en
  el grupo «agua_2d» (siguen ahí para los vecinos).
- `scripts/visuals/WorldStageBase3D.gd`: `superficie_rio_px` (la altura del agua del río, ahora en un solo sitio);
  `WorldStageTerrain3D.gd` la usa al dibujar el río.
- `tools/tests/fisica_3d.gd`: prueba del paso 3 (busca un tramo de río sin puente ni rocas y lo cruza nadando; flota
  en el lago con la cabeza fuera; nadando no se salta).

**Cómo se probó:** fisica_3d ✅ · puertas_3d 29/29 · verify_all ✅.

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 2c — Daño por caída (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** si caes desde 3 m o más te haces daño al aterrizar: a 3 m, un 9 % de la vida; a 4 m, un 27 %;
a 8 m, mueres. Además la caída deja una herida en una parte del cuerpo (moratón o fractura), casi siempre en las
piernas; desde 5 m, en las dos; en caídas grandes puede ser el tronco o la cabeza. Un salto normal no hace daño. Las
barandillas de la posada ahora llegan a la cintura (dentro de casa el salto es bajo, así que no se pueden saltar).

**Decisión del usuario:** «realista»; las caídas hieren partes del cuerpo; más adelante habrá mejoras que quiten daño.

**Archivos:**
- `scripts/fisica/Cuerpo3D.gd`: `_vigilar_caida` (apunta lo más alto que llega en el aire y al tocar suelo calcula la
  caída; cambiar de sitio a mano no cuenta), `dano_por_caida`, constantes `CAIDA_*`.
- `scripts/systems/combat/HealthComponent.gd`: `take_fall_damage` y `_zona_de_caida`; `take_damage` acepta la zona herida.
- `scripts/Player.gd`: `recibir_dano_caida` y `reduccion_dano_caida` (0 = todo el daño, 1 = nada; para mejoras futuras).
- `scripts/systems/VillageTavern.gd`: las tres barandillas van en el grupo «barandilla»; `Suelo.es_barandilla`;
  `ChoquesCercanos3D.ALTO_BARANDILLA_M` (cada copia guarda su «banda» de altura).
- `tools/tests/fisica_3d.gd`: prueba del paso 2c.

**Cómo se probó:** fisica_3d ✅ · verify_all ✅.

**Cómo deshacerlo:** `git revert` de este commit.

## Paso 2b — Club de peleas y alcantarillas de verdad bajo tierra (2026-11-10, Claude Code, portátil)

**Qué cambia en el juego:** al bajar por la trampilla del club o por una reja de alcantarilla estás de verdad unos 3,2 m
bajo la calle (antes estabas a la altura de la calle y se escondía lo de arriba). Se ve igual que antes, pero en
1.ª persona hay un techo de roca en lugar de cielo. Se sigue bajando y subiendo con [E].

**Por qué:** segundo trozo del paso 2; deja preparado el sitio para cuevas (un lugar bajo tierra con su entrada).

**Archivos:**
- `scripts/fisica/Suelo.gd`: `PROFUNDIDAD_SOTANO_PX` (−30 px de altura ≈ 3,2 m) y `es_bajo_tierra` (club o alcantarillas,
  mirando a través del pueblo para no atar este archivo a esos sistemas). En la capa −1 fuera de esos sitios (sótano de tu
  casa) el suelo sigue a ras de calle (trozo 2e).
- `scripts/systems/VillageUnderworld.gd`: `zona_alcantarillas()` (lo que ocupa la red; antes el tamaño estaba escrito a
  mano en el dibujo 3D).
- `scripts/visuals/WorldStageProps3D.gd`: el club y las alcantarillas se dibujan bajados; `_add_techo_roca` (solo en
  1.ª persona, desde arriba taparía la sala).
- `scripts/fisica/Cuerpo3D.gd`: bajo tierra los muros se levantan desde el suelo de abajo.
- `Player.gd`, `WorldStage3D.gd`, `CharacterAvatar3D.gd`: «sin cuerpo todavía» pasa a ser NAN (con −1 la cámara creía que
  bajo tierra no había cuerpo y se quedaba en la calle; visto en las fotos).
- `tools/tests/fisica_3d.gd`: prueba del paso 2b. Fotos: `docs/capturas_mundo3d/paso2b/`.

**Cómo se probó:** fisica_3d ✅ · fotos en 1.ª persona comparadas con la versión anterior (iguales salvo el techo) ·
verify_all ✅.

**Cómo deshacerlo:** `git revert` de este commit.

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
