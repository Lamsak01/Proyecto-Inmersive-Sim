# Encargo P6 — Club de pelea en el sótano de la taberna y sabotajes nocturnos de verdad (borrador listo)

> Escrito por Claude Code (supervisor), 2026-11-06. Decisiones de diseño **ya tomadas por el usuario**: no cambies
> ninguna. Si algo no encaja con el código, **no improvises**: apúntalo en el informe y pregunta.
> Filas 8 y 10 de `docs/AUDITORIA_REALISMO.md`. **Fuera de este bloque** (van más adelante, decisión del usuario):
> peleas de gallos/perros (`run_cockfight`), carreras de animales (`run_animal_race`) y expediciones. No las toques.

## Reglas de este bloque (orden del usuario)

- Lee solo lo necesario: este encargo, `CLAUDE.md` y las funciones que se nombran aquí. Para el sótano, tu modelo son
  las **alcantarillas caminables** de `VillageUnderworld` (`SEWER_LOCATIONS`, `enter_sewer_location`,
  `exit_sewers_to_surface`, `is_player_in_sewers`, la escalerilla y la rejilla de `WorldInteractableProp`).
- **No pases pruebas mientras trabajas.** Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`). Nada de tipos de clase del juego en las variables del test.
- No toques nada fuera de este encargo. Si ves otra cosa rota, apúntala en el informe.

---

## Parte A — El club de pelea en un sótano de verdad (decisión del usuario)

### Cómo está ahora
En la charla con el perista: `underworld_bet_fight` (apostar 15, 50 % de ganar) y `underworld_join_brawl` (pelear tú:
tirada según tu vida). Todo es un número al azar; no hay corro ni golpes.

### El sótano
- **Trampilla** en el patio trasero de la taberna (cerca de `vm._tavern_social_pos`, fuera del edificio y fuera de las
  calzadas; elige un punto así y **apunta en el informe** la posición). [E]: «Bajar al sótano» (de noche) / «La
  trampilla está cerrada» (de día).
- **Sala:** una cámara pequeña **como las de las alcantarillas**: en la franja de túneles del sur del mapa (`y ≈ 1520`),
  en un hueco libre que no pise ninguna cámara de `SEWER_LOCATIONS` (por ejemplo `x ≈ 1150`; compruébalo y dilo en el
  informe). Nivel −1 (`vm.set_player_elevation_level(-1)`), con su escalerilla para subir a la trampilla. 2D y 3D:
  suelo de tierra, paredes de piedra, faroles, y un **círculo de cuerda** en el centro (radio 40 px).
- **Horario:** abierto **de 23:00 a 3:00**, una noche sí y otra no (días pares). Fuera de horario la trampilla está
  cerrada.

### El público (vecinos de verdad)
- Las noches de club, a las 23:00, el **perista** y entre **3 y 6 vecinos** adultos van andando a la trampilla y bajan
  (`start_errand` hasta la trampilla; al llegar, colócalos en la sala alrededor del círculo y ponles nivel −1 con
  `vm.set_npc_elevation_level(npc, -1)`; al acabar, a las 3:00, vuelven a la trampilla con nivel 0). Elige a los que
  tengan **agresividad ≥ 0.35 o «malice» ≥ 0.3** (`TraitCatalog.npc_tendency`) y estén despiertos y libres. Nada de
  guardias.
- Mientras hay público, frases cortas de ánimo cada rato (`_spawn_floating_text`).

### Pelear tú (puño limpio, no letal)
- Junto al círculo, [E] al perista o un letrero en el círculo: **«Pelear por la bolsa (entrada 10 oro)»** con **doble
  E** (`press_twice`). La entrada va al perista (`vm.pay_into(perista, 10)`).
- **Rival:** el asistente con más agresividad que no seas tú. Entra al círculo y pelea con el **combate de vecinos
  hostiles que ya existe** (el de COMBATE-1: golpes con aviso, puedes rodar con Espacio y parar con Q).
- **Reglas del combate:** sin armas (si llevas una en la mano, el letrero dice «Aquí se pelea a puño limpio: guarda el
  arma»). **Nadie muere:** cuando alguien baja al **20 % de vida**, se rinde y se acaba. Si sales del círculo, pierdes.
- **Premio:** si ganas, la bolsa: **la suma de las entradas y apuestas de esa noche**, máximo 35, pagada por el perista
  (`personal_gold`, suma cero; si no tiene, cobras lo que tenga). Si pierdes, te quedas con la vida que te dejó el
  rival y sin bolsa. Una pelea por noche para ti.

### Apostar (combate entre dos vecinos)
- Si no peleas tú, a las 0:00 **dos asistentes pelean entre ellos** en el círculo (los dos más agresivos). Antes, [E]
  al perista: **«Apostar 15 oro por %s»** o **«por %s»** (doble E). La apuesta va al perista.
- El combate entre vecinos se ve (se mueven y se golpean con el combate que ya existe) y también se acaba al 20 % de
  vida. Gana quien quede en pie; la probabilidad la decide el combate, **no una tirada aparte**. Si aciertas: cobras
  **30** del perista (o lo que tenga). Los que pelearon quedan heridos de verdad (su vida baja y no la recuperan al
  instante).

### Riesgo: la guardia
- Si un guardia despierto ve a alguien **bajar o subir por la trampilla** de noche (a menos de 160 px,
  `_find_conscious_witness_near` y que sea de la guardia), sospecha: la noche siguiente el club **no abre**
  («La guardia ronda la taberna»), y si eras tú el que bajaba, **sube la búsqueda** en 1.
- Quita `underworld_bet_fight` y `underworld_join_brawl` de la charla (`add_dialogue_choices`, ~líneas 868–870).

---

## Parte B — Sabotajes y robos nocturnos que se pueden pillar (decisión del usuario: puede delatarte)

### Cómo está ahora
`underworld_hire_saboteur` / `underworld_hire_thief` apuntan un trabajo en `hired_jobs` y al día siguiente
`VillageUnderworld.daily` (~líneas 729–766) aplica el efecto. Igual con `VillageClans._daily_clan_sabotage` y
`_daily_grave_desecration`. Nadie camina.

### Lo nuevo: **alguien de verdad camina de noche hasta el objetivo**
- **Quién va:**
  - Saboteador o ratero a sueldo: un vecino adulto con «malice» ≥ 0.3 (el más alto que esté libre esa noche; si no
    hay ninguno, el propio perista). Apúntalo en el trabajo (`agent_key`).
  - Sabotaje entre clanes: el `saboteur` que ya elige `_daily_clan_sabotage`.
  - Profanar una tumba: el `culprit` que ya elige `_daily_grave_desecration`.
- **Cuándo y adónde:** a la **1:00** de la noche siguiente, `start_errand` hacia el objetivo:
  - sabotaje: la puerta del taller (`work_position` del dueño o el puesto del negocio);
  - robo: la casa del vecino (su cama o la mesa de su casa);
  - tumba: la lápida (busca su posición en `vm.buried_graves`).
- **El efecto solo ocurre si llega** y se queda allí **20 minutos de juego** sin que lo pillen. Al acabar, vuelve a su
  cama. El efecto es **el mismo de ahora** (no cambies cantidades ni quién cobra).
- **Pillado in fraganti:** mientras camina o actúa, si un **guardia despierto** lo ve a menos de 160 px, o **el
  jugador** está a menos de 60 px y pulsa [E] sobre él («¡Te he visto! ¿Qué haces aquí?»), queda pillado: no hay
  efecto, la crónica lo apunta y, si fue un guardia, lo detienen como a cualquier sospechoso de delito (usa la
  detención que ya exista; si no sabes cuál, dilo en el informe).
- **Puede delatarte (decisión del usuario):** si lo pillan y el trabajo lo **pagaste tú**, confiesa quién le pagó con
  probabilidad `0.6 − 0.4 × lealtad`, donde lealtad = `clampf(affinity_contigo / 100, 0, 1)`; si **te teme** (lo
  amenazaste o le cobras «protección») resta 0.2 más. Mínimo 0.05. Si confiesa: **sube la búsqueda** en 1 y la crónica
  dice «%s confesó que lo pagaste tú». No devuelve el dinero.
- **Tú también puedes ir:** si estás cerca cuando ocurre, lo ves de verdad (el agente se agacha junto a la puerta o la
  lápida con la animación de rezar/agacharse que ya existe).

---

## Prueba (una sola, en `verify_all`): bloque «P6 peleas y sabotajes»
1. Una noche de club, a las 23:00 hay al menos 3 vecinos con recado hacia la trampilla y, ya abajo, nivel −1.
2. Pelea tuya: cuando el rival llega al 20 % de vida, el combate acaba, nadie muere y la bolsa sale del perista
   (suma cero).
3. Sabotaje encargado: a la 1:00 el agente tiene recado hacia el taller; con un guardia al lado, queda pillado y el
   taller **no** queda saboteado.
4. Forzando la confesión (probabilidad 1): `wanted_level` sube en 1.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: **reescríbelo entero**. **Nombra solo funciones que existan**.
2. Commit en español y push a `main`. No subas la carpeta `.claude/`.
