# Encargo P4 — Cenas, fiestas en tu casa y cenas de paz hechas físicas (borrador listo)

> Escrito por Claude Code (supervisor), 2026-11-06. Decisiones de diseño **ya tomadas por el usuario**: no cambies
> ninguna. Si algo no encaja con el código, **no improvises**: apúntalo en el informe y pregunta.
> Fila 4 de `docs/AUDITORIA_REALISMO.md`.

## Reglas de este bloque (orden del usuario)

- Lee solo lo necesario: este encargo, `CLAUDE.md` y las funciones que se nombran aquí.
- **No pases pruebas mientras trabajas.** Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`). Nada de tipos de clase del juego en las variables del test.
- No toques nada fuera de este encargo. Si ves otra cosa rota, apúntala en el informe.

## Cómo está ahora
- `VillageHousing.on_player_action`: `housing_dinner` (cena con un vecino, −10 de oro a la posada) y `housing_party`
  (fiesta, −20 de oro a la posada, vienen solos 4 vecinos con afinidad ≥ 10). Todo se resuelve al instante en la charla.
- `VillageClans.on_player_action`: `clan_peace:<fk>` (cena de paz, −25 de oro a la posadera o Carisma 2) llama a
  `mediate_clan_peace` al instante.

## Piezas comunes (hazlas una vez y úsalas en las tres)

1. **La mesa de tu casa:** nuevo mueble `home_table` en `sync_home_props` / `home_prop_pos` (como `home_workbench`), en
   2D y 3D, con [E]. Tiene **6 asientos** alrededor (posiciones fijas a 14 px de la mesa).
2. **Sentarse:** los invitados se sientan con la misma mecánica que el póquer de la taberna
   (`VillageNPC.set_poker_seating(true, asiento)` y `set_poker_seating(false)` al acabar). Si la animación de sentado no
   sale con eso, dilo en el informe; no inventes una animación nueva.
3. **Velada:** un «evento» guardado en `state(vm)["gathering"]` con: tipo (`dinner` / `party` / `peace`), sitio
   (tu mesa o la mesa de la posada), hora de inicio, invitados (claves de persona), quién ha llegado, si hay comida.
   Solo puede haber **una velada a la vez**. Se guarda y se carga.
4. **Los invitados van andando:** a la hora de inicio, cada invitado que aceptó recibe `start_errand("gathering",
   asiento)`. Si a la hora de inicio + 2 h no ha llegado (está dormido, herido, preso, lejos), **no cuenta**.
5. **Duración:** la velada dura **2 horas de juego** desde que llega el segundo invitado (o el único, en la cena). El
   efecto social se aplica **al final**, solo a los que estuvieron sentados, y **solo si tú estabas** a menos de 90 px de
   la mesa al acabar. Si te vas antes, la velada se deshace sin efecto y los invitados se enfadan un poco
   (`modify_affinity(-5)`, pensamiento «El forastero nos dejó plantados»).
6. **Charlas:** durante la velada, cada 20 min de juego un invitado al azar dice una frase corta con
   `_spawn_floating_text` (usa frases que ya existan en el juego para charlas de taberna, si las hay; si no, 6 frases
   neutras nuevas y apúntalas en `docs/APORTES_CREATIVOS.md` como provisionales).

## La comida: las dos formas (decisión del usuario)

Hacen falta **2 raciones por invitado** en la mesa antes de que empiece la velada. Dos formas, el jugador elige:

- **A) Tu propia comida:** [E] en la mesa → «Poner comida en la mesa (X/Y raciones)»: pasa de tu mochila a la mesa los
  objetos de comida que ya existen en el juego (los mismos que cuentan como comida en el resto del código: búscalos y
  usa esa lista, no inventes otra). Cada objeto es 1 ración. Se gastan al final de la velada.
- **B) Contratar catering:** en la charla con la **posadera** (`vm._innkeeper_npc`; si no hay, con el cocinero/
  panadero, y dilo en el informe): «Contratar a la posada para cocinar en tu casa (−%d oro)», con precio
  `CATERING_COST_PER_GUEST = 4` × invitados. Pide **doble E** (`press_twice`). El oro va a la posadera
  (`vm.pay_into(vm._innkeeper_npc, oro)`). **La posadera camina de verdad hasta tu mesa** (`start_errand`) una hora
  antes de la velada, «cocina» allí (se queda al lado de la mesa) y, al llegar, aparecen las raciones en la mesa. Si la
  posadera no llega (dormida, herida, presa), no hay comida, la velada no empieza y **se te devuelve el oro** desde ella.
- Sin comida suficiente a la hora de inicio: los invitados llegan, ven la mesa vacía, se van molestos
  (`modify_affinity(-5)`) y no hay efecto.

## 1. Cena con un vecino (en tu casa)
- En la charla: «Invitarle a cenar a tu casa esta noche (a las 20:00)». Mismas condiciones de ahora (cada 3 días,
  afinidad ≥ 10). **Ya no cobra oro en la charla:** la comida sale de A o B.
- El vecino acepta si está libre esa noche (no tiene otra velada ni trabajo nocturno). Respuesta flotante sí/no.
- Al final de la velada: los mismos efectos que ahora (`modify_affinity(14)`, pensamiento +8, `TraitDiscovery`,
  suavizar un rival, crónica).

## 2. Fiesta en tu casa (invitas tú uno a uno, hasta 6) — decisión del usuario
- [E] en tu mesa → «Convocar una fiesta esta noche (a las 21:00)». Solo una al día, como ahora.
- Durante ese día, en la charla con cada vecino adulto: «Invitarle a tu fiesta de esta noche». **Acepta** si
  `affinity >= 10` y está libre; si `affinity` está entre 0 y 9, acepta con un 40 %; si es negativa, no. Máximo **6**
  invitados que acepten.
- Al final: los mismos efectos de ahora para cada asistente (+10 afinidad, pensamiento +10, +8 de relación entre cada
  pareja de asistentes), crónica con el número real de asistentes.

## 3. Cena de paz entre dos familias (en la posada)
- En la charla (como ahora, `clan_peace:<fk>`): «Organizar una cena de paz en la posada mañana a las 20:00». Coste: el
  mismo de ahora (25 de oro a la posadera o Carisma 2); **con doble E** si pagas.
- Sitio: una mesa de la posada (usa la posición de la taberna, `vm._tavern_social_pos`, y los asientos de póquer si
  están allí; si no, 6 asientos alrededor de ese punto). Comida: la pone la posada (ya está pagada).
- Invitados: el **cabeza** (el adulto de más edad) de cada familia y hasta **2 adultos más de cada una** que estén
  libres.
- **Puede salir mal (decisión del usuario):** al final de la velada se tira la probabilidad de bronca:
  `prob = 0.10 + 0.25 × (agresividad media de los asistentes) + 0.02 × (días que dura el feudo, máx. 0.20)`.
  - Si **sale bien**: `mediate_clan_peace(vm, fk, "en una cena de paz en la posada")`.
  - Si **sale mal**: discuten (frases flotantes de enfado), se marchan antes de tiempo, **no hay paz** y la relación
    entre las dos familias baja −5 (`modify_npc_relationship`). **Nunca empieza una pelea por sí sola.** Crónica:
    «La cena de paz entre %s y %s acabó a gritos».
  - Si **falta alguna de las dos familias**: no hay paz ni bronca; crónica «La familia %s no se presentó».

## Prueba (una sola, en `verify_all`): bloque «P4 cenas»
1. Invitar a cenar y poner 2 raciones desde la mochila: a la hora el vecino recibe el recado `gathering`, y al acabar
   (estando el jugador cerca) sube su afinidad.
2. Con catering: el oro pasa a la posadera (suma cero) y no se cobra con una sola E.
3. Sin comida: el invitado se va y su afinidad baja.
4. Cena de paz forzando la bronca (probabilidad 1): el feudo sigue existiendo.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: **reescríbelo entero**. **Nombra solo funciones que existan**.
2. Commit en español y push a `main`. No subas la carpeta `.claude/`.
