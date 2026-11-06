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

## 2. Rumores en la taberna (para encontrarlo investigando)
- Cuando el jugador habla en la taberna (a menos de 140 px de `vm._tavern_social_pos`) con un vecino adulto que
  **no sea** el perista, guardia ni cura, y aún no conoce al perista (`known_fence == false`), con un **25 %** el
  vecino añade una frase de rumor al final de su saludo (una vez al día por vecino):
  - «Si buscas algo que no se vende en las tiendas, ronda el callejón de la taberna pasada la medianoche.»
  - «Dicen que de noche hay alguien con capucha detrás de la taberna. Yo no me acercaría.»
  - «Las cosas que desaparecen en este pueblo siempre acaban en el mismo callejón.»
  Apunta estas frases en `docs/APORTES_CREATIVOS.md` como provisionales.
- Usa el sitio donde ya se añaden frases al saludo en `NPCDialogue` (búscalo; si no hay ninguno claro, añádelo como una
  opción de charla «¿Algún rumor?» y dilo en el informe).

## 3. Lo que no cambia
- Quién es el perista (`get_fence_npc`) y sus tratos siguen igual. Sus opciones de charla siguen saliendo de noche o
  cuando ya lo conoces (`known_fence`).
- P6 (el club de pelea) se apoya en esto: las noches de club, a las 23:00, el perista deja el callejón y baja al sótano.
  No lo hagas aquí; solo deja el recado `fence_alley` fácil de cortar.

## Prueba (una sola, en `verify_all`): bloque «P5b perista»
1. A las 22:00 el perista tiene el recado `fence_alley` y no está dormido; a las 3:00 ya no lo tiene.
2. Con `known_fence == false`, su letrero de [E] en el callejón es «Hablar con la figura encapuchada».

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: reescríbelo entero. **Nombra solo funciones que existan**.
2. Commit en español y push a `main`. No subas la carpeta `.claude/`.
