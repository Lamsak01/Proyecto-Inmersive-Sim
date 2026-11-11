# Encargo P5b — El perista se deja ver de noche (bloque pequeño, va antes de P6)

> Escrito por Claude Code (supervisor), 2026-11-06. Fallo encontrado por el usuario: el perista
> (`VillageUnderworld.get_fence_npc`) es un vecino cualquiera que **duerme de noche como todos** y nada lo distingue, así
> que el jugador casi nunca puede dar con él ni con nada del hampa. Decisiones **ya tomadas**: no cambies ninguna.
> Si algo no encaja con el código, apúntalo en el informe y pregunta.

## Reglas (orden del usuario)
- Lee solo este encargo, `CLAUDE.md` y las funciones que se nombran aquí.
- No pases pruebas mientras trabajas. Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`). Nada de tipos de clase del juego en las variables del test.
- No toques nada fuera de este encargo.

## 1. Trasnocha y espera en el callejón (22:00–3:00)
- Constante `FENCE_ALLEY_POS`: el **callejón detrás de la taberna**, a unos 40 px de la pared trasera, fuera del
  edificio y fuera de las calzadas por las que pasan los vecinos (parte de `vm._tavern_social_pos`; elige el punto y
  **apúntalo en el informe**). Que sea un rincón con poca luz (lejos de faroles si los hay).
- Cada noche, a las **22:00**, el perista recibe `start_errand("fence_alley", FENCE_ALLEY_POS)` y se queda allí hasta
  las **3:00**; luego vuelve a su cama. Durante ese rato **no duerme** (no entra en `is_sleeping`). Si está herido,
  preso o muerto, no va. Si la guardia lo tiene vigilado (`fence_busted_until > today()`), tampoco va.
- Mientras espera: se apoya en la pared y mira a los lados (usa una animación que ya exista: quieto o agachado). Sin
  frases flotantes, que es discreto.
- **Aspecto:** de noche, mientras está en el callejón, lleva **capa oscura con capucha** (en 3D, tiñe su ropa de un
  gris muy oscuro o ponle la capa si el avatar tiene una; en 2D, oscurece su sprite). De día se viste normal. Si el
  avatar no permite cambiar la ropa, solo el tinte, y dilo en el informe.
- Su letrero de [E] por la noche en el callejón: «Hablar con la figura encapuchada» (no su nombre, hasta que lo
  conozcas: `known_fence`).

## 2. Rumores en la taberna: **sutiles y difíciles de oír** (decisión del usuario: que no rompan la inmersión)
- **Cuándo puede salir:** solo **de tarde-noche (19:00–1:00)**, con el jugador **dentro de la taberna** (a menos de 140 px
  de `vm._tavern_social_pos`), hablando con un vecino adulto que **no sea** el perista, guardia ni cura, y solo mientras
  el jugador no conozca al perista (`known_fence == false`).
- **Quién lo dice:** solo vecinos con algo que ver con el hampa: `TraitCatalog.npc_tendency(n, "malice") >= 0.2`, o a
  los que les hayan robado (si existe un registro de robos a vecinos; si no, solo el primer criterio, y dilo en el
  informe). Los vecinos honrados y sin relación no saben nada.
- **Probabilidad:** **10 %** por charla, una vez al día por vecino y **como mucho un rumor al día en todo el pueblo**.
- **Cómo se dice:** **nunca** como un aviso al jugador ni con el sitio y la hora juntos. Son comentarios de pasada que
  hay que juntar. Se añaden al final del saludo normal, sin emoji ni color especial. Frases (provisionales; apúntalas
  en `docs/APORTES_CREATIVOS.md`):
  - «Anoche volvía tarde y olía a pipa detrás de la taberna. ¿Quién fuma ahí a esas horas?»
  - «Yo, de noche, no paso por el callejón. Manías mías.»
  - «Hay quien paga por lo que no tiene dueño. No me preguntes quién, que no lo sé.»
  - «Lo que se pierde en este pueblo no se pierde: cambia de manos antes del alba.»
  - «Si oyes una puerta trasera pasada la medianoche, mejor no mires.»
- Usa el sitio donde ya se añaden frases al saludo en `NPCDialogue` (búscalo; si no hay ninguno claro, dilo en el
  informe y **no** lo conviertas en una opción de menú: tiene que sonar a conversación, no a botón).

## 3. Lo que no cambia
- Quién es el perista (`get_fence_npc`) y sus tratos siguen igual. Sus opciones de charla siguen saliendo de noche o
  cuando ya lo conoces (`known_fence`).
- P6 (el club de pelea) se apoya en esto: las noches de club, a las 23:00, el perista deja el callejón y baja al sótano.
  No lo hagas aquí; solo deja el recado `fence_alley` fácil de cortar.

## Prueba (una sola, en `verify_all`): bloque «P5b perista»
1. A las 22:00 el perista tiene el recado `fence_alley` y no está dormido; a las 3:00 ya no lo tiene.
2. Con `known_fence == false`, su letrero de [E] en el callejón es «Hablar con la figura encapuchada».
3. Un vecino honrado (malice < 0.2) nunca dice un rumor, aunque se fuerce la probabilidad a 1.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: reescríbelo entero. **Nombra solo funciones que existan**.
2. Commit en español y push a `main`. No subas la carpeta `.claude/`.
