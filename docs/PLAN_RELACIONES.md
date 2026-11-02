# Plan: relaciones de un solo sentido (bloques U)

Estado: **propuesta, pendiente de aprobación del usuario** (2026-11-02). Va después de T5 (medición de rasgos).
Contexto y visión: `docs/VISION_Y_FUTURO.md` (pieza P1 «Persona»).

## Qué existe hoy

- Cada vecino guarda **su propio número** de aprecio hacia cada otro (`VillageNPC.npc_relationships`), pero
  `modify_npc_relationship` suma lo mismo a los dos lados: en la práctica es simétrico.
- `SocialDirector.pair_metrics` guarda por pareja una sola **chispa**, **tensión**, **familiaridad** y **etapa**
  (cortejo, pareja, ex), compartidas. También `last_contact_day` (último encuentro).

## Qué cambia

| Dato | Ahora | Después |
|---|---|---|
| Aprecio (de «le cae fatal» a «mejor amigo») | De cada uno, pero se mueve igual | **De cada uno de verdad** |
| Chispa romántica | Compartida | **De cada uno** |
| Tensión (riña que se calienta hasta la pelea) | Compartida | Compartida (*recomendado*: la riña es cosa de dos; el «le cae mal» unilateral ya lo da el aprecio) |
| Familiaridad (cuánto se conocen) | Compartida | Compartida (es un hecho) |
| Etapa (cortejo, pareja, ex) | Compartida | Compartida (ser pareja exige que quieran los dos) |

## Bloques

- **U1 – Base, sin cambio visible.** Chispa por dirección (`spark_by`: quién → cuánto), funciones únicas
  `get_spark(de, a)` / `add_spark(de, a, n)` y `modify_npc_relationship(..., solo_ida)` para cambiar un solo lado.
  Las partidas viejas copian el valor actual a los dos lados. Todo sigue moviéndose igual que hoy. Test de guardado.
- **U2 – De dónde sale la diferencia.**
  - Charla: cada lado gana según su sociabilidad y sus gustos.
  - Manías: tabla de rasgos que irritan a otros (al Honrado le irrita el Mentiroso y el Chismoso; al Serio el Bromista;
    al Pulcro el Desaliñado; al Trabajador el Holgazán; al Fanático el Escéptico...). Solo baja el lado irritado.
  - Favores e insultos pesan más para quien los recibe.
  - Chispa vista desde cada uno: el Romántico la siente antes, el Desapegado casi nunca; el Coqueto la despierta en otros.
  - Reciprocidad lenta: cada día la diferencia entre los dos lados se acorta un poco (le acaba cayendo mejor
    quien le aprecia), sin llegar a igualarse: los amores no correspondidos pueden durar semanas.
- **U3 – Romance desigual.** El cortejo exige chispa de los dos. Quien se declara sin ser correspondido recibe
  un «no»: disgusto, recuerdo triste y algo de distancia. Celos: si A quiere a B y B se empareja con C, A aprecia menos a C
  (base de los triángulos). La misión «Averigua qué piensa de mí» pasa a leer la chispa real del otro hacia quien pregunta.
- **U4 – Amistad desigual.** Etiquetas por lado (mejor amigo, amigo, conocido, le cae mal). Quien invita a una
  quedada puede recibir excusas si el otro no le aprecia. El Protector solo defiende a quien él aprecia.
- **U5 – Que se vea.** En el menú de opiniones y el glosario: «Lo que Ana siente por Luis» y «lo que Luis siente por Ana»,
  ocultos hasta que preguntes a cada uno (lo que cuenta un tercero sale «según X», como los rasgos). Frases en diálogos y
  textos flotantes («Ana habla maravillas de Luis... Luis ni la menciona»; «💔 Luis ha rechazado a Ana»).
- **U6 – Enfriamiento por distancia.** Si dos vecinos llevan muchos días sin verse (`last_contact_day`), el aprecio y la
  chispa se acercan poco a poco a neutro. Pequeño; usa datos que ya existen.
- **U7 – Medir.** Simulador abstracto + partidas largas. Metas: parejas nuevas parecidas a hoy (2–3 por 60 días),
  peleas raras, ~15–25 % de parejas de vecinos con una diferencia grande (≥ 30 puntos) y pocos amores no correspondidos a la vez.

Fuera de este plan (más adelante, usan esta base): infidelidad (necesita «Secretos»), idolatría / Obsesivo,
degradación de recuerdos concretos.

## Riesgos

- Toca romance, peleas, quedadas, misiones, glosario y partidas guardadas: por eso U1 no cambia nada visible.
- Las parejas y peleas ya calibradas cambiarán: el simulador abstracto también debe usar direcciones, y U7 recalibra.
- Si el jugador no lo ve, no sirve: U5 es obligatorio, no opcional.
- Esfuerzo total: medio-grande (7 bloques pequeños).

## Preguntas para el usuario

1. ¿Tensión compartida (recomendado) o también de cada uno?
2. Reciprocidad: ¿lenta (recomendado: los amores no correspondidos duran semanas) o casi nula (pueden durar siempre)?
3. ¿Los sentimientos de cada uno empiezan ocultos como los rasgos (recomendado) o se ven desde el principio?
