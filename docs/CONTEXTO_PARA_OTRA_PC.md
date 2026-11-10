# Contexto completo para Claude Code en el ordenador principal

Escrito por Claude Code en el portátil el 2026-11-09, a petición del usuario: «yo quiero que sepa lo mismo que tú
ahora». La memoria personal de Claude no viaja entre ordenadores, así que aquí va lo esencial. Léelo entero antes de
hablar con él y guarda en tu memoria lo que te sirva.

## Quién es el usuario y cómo hablarle
- Habla español. **No programa y no conoce Godot.** Es narrador: escribe la historia y decide el diseño.
- Respuestas **cortas** (10–12 líneas como mucho), sin código ni nombres de archivo salvo que los pida, sin jerga.
  Termina siempre con **una** pregunta clara.
- Pide permiso antes de lanzar pruebas y di cuánto tardan.
- Hoy me dijo que no entendía mi resumen del editor del mapa. **Explícale menos cosas a la vez, con ejemplos de lo que
  verá en pantalla,** y comprueba que lo ha entendido.
- Es directo y se enfada con razón si prometes algo y no lo cumples (ver Antigravity abajo).

## Reglas que dio (siguen vigentes)
1. **Antigravity:** nunca lo lances, relances ni cierres; lo maneja él. El vigilante automático está apagado para
   siempre, porque lo relanzaba sin memoria una y otra vez y gastó su cupo. Solo escribes encargos o revisas su
   trabajo cuando él lo pide.
2. **Foco:** el juego es en primera persona. Todo lo demás está congelado hasta que el **Caso I** («La mujer del
   bosque») se pueda jugar de principio a fin. Solo se permiten arreglos de fallos visibles.
3. No toques:
   - `VillageSect.gd`
   - `GameVault/03_La_Secta/`
   - el «Lore provisional»
   - `GameVault/99_Archivo/`
   - `GameVault/.obsidian/`
   - `.claude/`

   **Nunca inventes lore de la secta, del culto ni de la «antigua fe».**
4. Commit y push a main tras cada bloque.
5. No cierres su editor de Godot si está abierto, y no uses `pkill`/`pgrep -f` con patrones propios.

## Lo que se hizo hoy (2026-11-09) en el portátil
- **Día del juego:** ahora dura 18 minutos reales (antes, unos 2).
- **Rendimiento:**
  - En el portátil pasó de 3–4 fps a 22–45 fps. Él confirmó que «sale mucho mejor».
  - Causa principal: el procesador. Los vecinos hacían cálculos caros contra todos los demás, y el motor encadenaba
    hasta 8 pasos por fotograma.
  - Arreglos: tope de pasos por fotograma, rejilla de vecinos, terreno juntado por zonas y vecinos lejanos
    simplificados (esto último lo activó él).
  - Lo que más pesa ahora: las sombras del sol y la geometría del río.
- **Informe del Caso I:** en la comisaría hay una bandeja donde se entrega el informe y se elige al culpable. Esa
  elección decide el final:

  | Culpable elegido | Final |
  |---|---|
  | El pariente | Malo |
  | Los secuestradores | Bueno |
  | El joven | Perfecto |
  | La alquimista o la doncella | Inocente acusado |

  Las frases del alguacil Vane son provisionales; él puede reescribirlas.
- **Editor del mapa, paso 1:** el río y sus puentes se editan arrastrando puntos en Godot (`mapa/EditorMapa.tscn`).
  Ver `docs/PLAN_EDITOR_MAPA.md` (incluye **cómo enseñárselo paso a paso**) y `docs/EDITOR_MAPA_GUIA.md`.

## Por qué el editor del mapa
Los vecinos se atascan en el río nuevo, y el usuario preguntó si podía construir él mismo el mapa. Elegimos un editor
dentro de Godot. Lo quiere usar en este ordenador principal, donde tiene **muchos recursos gratuitos descargados**
(árboles, casas…). Pregúntale cuáles usar antes de hacer las piezas nuevas.

## Pendiente, en orden
1. **Enseñarle el editor del mapa:** primera sesión guiada (ver el plan). Después, con su permiso:
   - edificios que se puedan mover;
   - bosques pintados;
   - árboles con sus recursos.
2. **Fallos visibles que señaló:**
   - los vecinos se siguen atascando en el río (se arregla con el río nuevo que él dibuje);
   - el molino está a 2 m del cuerpo de la víctima;
   - los árboles del bosque se solapan;
   - el caso empieza nada más llegar el jugador, sin tiempo para enterarse de qué pasa ni adónde ir;
   - hay controles que se pisan (por ejemplo, T y F1–F4 cambian la hora o la velocidad).
3. **Caso I, partes siguientes.** El plan está aprobado por él; confirma cada parte antes de empezarla.
   - **Parte 2 — umbral de dolor como en Rimworld:**
     - con suficiente daño, el vecino cae inconsciente o agonizando y se le puede arrastrar, secuestrar o rematar;
     - las armas contundentes matan menos;
     - el desmayo del jugador queda para más adelante.
   - **Parte 3 — llevar a un herido a la comisaría:** atarlo, curarlo y llevarlo vivo. Si hace falta, acampar una
     noche hasta que despierte y pueda caminar.
   - **Parte 4 — los secuestradores viven en el pueblo como vecinos normales:**
     - en el final malo vuelven y actúan como si nada, pero sueltan indirectas (borrachos en el bar o al hablarles);
     - tú propones esos textos y él los aprueba.
   - **Parte 5 — los tres finales encadenados (estándar, malo e incompetente):**
     - incluyen la detención, la fiesta de los nobles, la muerte fingida del preso, la tumba con la carta y el noqueo;
     - **los textos de la carta, el nombre real y el sargento los escribe él.**
4. **Aprender Godot:** él quiere aprender lo básico.
   - El plan está en `Documentos/Plan_aprender_Godot.docx`.
   - Paso 1, pendiente: cambiar juntos una frase de la doncella en los datos del caso y verla en el juego.
   - Antes, enséñale a guardar una copia de seguridad para poder deshacer.
   - Encaja bien con la primera sesión del editor del mapa.

## Pruebas útiles
Están en la sección 3 de `docs/HANDOFF.md`, y además:

| Qué prueba | Archivo | Duración |
|---|---|---|
| Partida entera del Caso I (hoy pasó 25/25) | `tools/tests/partida_caso1.gd` | ~7 min |
| Río del editor | `tools/tests/rio_editor_juego.gd` | ~30 s |
| Rendimiento por zonas | `tools/tests/perf_zonas.gd` | — |
| Vecinos atascados | `tools/tests/atascos_vecinos.gd` | — |
