# Encargo para Antigravity (escrito por Claude Code, supervisor) — trabajo de noche

> Fecha: 2026-11-07. El usuario se va a dormir: **trabaja en autónomo, sin pedir permiso ni plan previo**, bloque a
> bloque y en este orden. Dile «Lee `docs/ENCARGO_ANTIGRAVITY.md` y haz lo que pone».

## Reglas
- **Pruebas solo al final de todo (orden del usuario):** mientras escribes los 6 bloques, NO pases pruebas; comprueba
  solo que el juego arranca sin errores de script (`timeout 120 flatpak run org.godotengine.Godot --headless --path .
  --quit-after 300`). Cuando **todo el código** esté hecho y subido, pasa las pruebas **una a una y siempre con
  límite de tiempo** (si se cuelga, se corta sola y sigues con la siguiente; nunca la dejes sin `timeout`):
  1. `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd > /tmp/v.log 2>&1`
  2. `timeout 900 ... -s tools/tests/social_sim.gd`, 3. `timeout 600 ... -s tools/tests/dialogue_coverage.gd`,
  4. `timeout 1200 ... --fixed-fps 60 -s tools/tests/feature_probe.gd -- 5 11`.
  Salida `124` = se cortó por tiempo (casi siempre un assert que falló y dejó la prueba colgada): busca la línea
  `Assertion failed` en el log, arréglalo si es tuyo y repite solo esa prueba (máximo 2 intentos por prueba).
  Pon en el informe qué pasó, qué falló y qué arreglaste.
- **No toques** `scripts/systems/VillageSect.gd`, `GameVault/03_La_Secta/`, el Lore provisional, `GameVault/99_Archivo/`,
  `GameVault/.obsidian/` ni `.claude/`. Nada de rendimiento ni de comprar arte.
- Nada de sistemas aislados ni de menús: todo se ve en el mundo. Las 7 Reglas de las Auditorías: suma cero, nada se
  destripa en menús si el jugador no lo sabe, todo puede fallar y tiene espera, lo arriesgado exige cercanía y testigos
  con línea de visión.
- Al cerrar **cada** bloque: HANDOFF §7, `CHANGELOG.md`, `docs/REGISTRO_TRABAJO.md`, nota del vault afectada, Tablero,
  diario `GameVault/06_Diario/AAAA-MM-DD.md`, textos nuevos en `docs/APORTES_CREATIVOS.md`; **commit y push a `main`**
  (así, si algo falla de madrugada, lo anterior queda guardado). Al final, un informe nuevo en `docs/INFORME_ANTIGRAVITY.md`.
- Trampas: usa `x.get("campo") == true`, nunca `bool(x.get(...))`; los oficios nuevos van al FINAL de `TradeRole`;
  no uses `ui_accept` para acciones del jugador (incluye Espacio).

## Los 6 bloques (orden estricto)

**B1 — Ruido y testigos en combate (cierra C7).** Golpes fuertes, gritos de dolor y disparos emiten ruido en el mapa
(ya existe `AudioManager.emit_noise`). Los guardias despiertos dentro del radio acuden a mirar o intervenir; los vecinos
pacíficos huyen o se asoman a distancia, y solo cuentan como testigos (`known_by` / `sighting_log`) si tienen línea de
visión en la misma planta.

**B2 — Calabozo de verdad.** Si un guardia o el comisario pillan a un vecino en plena falta (sabotaje, robo nocturno,
profanación, pelea grave) o el inquisidor lo condena en juicio, lo llevan a pie a la celda del calabozo de la comisaría
durante su condena (24–48 h de juego) y luego vuelve a su vida. Se le ve tras los barrotes, se puede hablar con él,
pagar su fianza en la comisaría (el dinero va a las arcas) o ayudarle a escapar con ganzúa o llave, con riesgo de
testigos. Aprovecha aquí lo pendiente del Tablero: **delatar a la Familia detiene al jefe** y lo lleva a la celda/juicio.

**B3 — Del campamento del lago al pueblo.** Con casa propia en el pueblo, el jugador puede llevarse a Toby (y su
comedero) y sus animales o gallinero a su solar. El campamento del oeste sigue sirviendo de puesto de pesca, caza y
refugio.

**B4 — Coherencia del ambiente.** (1) La niebla nocturna recorta de madrugada el alcance de la vista de los vecinos,
salvo cerca de farolas o faroles encendidos. (2) Un taller saboteado echa humo o chispas en 2D y 3D hasta que se
repara; si hay fuego fuera, la lluvia ayuda a apagarlo. (3) Quita la etiqueta «(dormida)» de las tendencias ya usadas
en `TraitCatalog.gd` y haz que Noctámbulos, Insomnes y Sonámbulos paseen de noche por las calles.

**B5 — Lo que se ve en la calle.** (1) Dos vecinos con odio fuerte (≤ −50) o en feudo de sangre que se cruzan a menos
de 80 px sueltan un gesto o bocadillo de desprecio o se apartan. (2) Quien prepara un asesinato o venganza ronda de
noche la casa de su víctima los días antes. (3) Bocadillos cortos (1,5 s, sin pausar) cuando un maestro termina una
obra maestra, cuando los niños entran en fila a la escuela a las 9:00 o cuando el ayuntamiento inaugura una mejora.

**B6 — Los 21 vecinos fundadores con historia.** Thoran, Kael, Garrick, Lina, Bram, Mila, Elena, Tomás, Marlo, Nora,
Marta, Aldric, Sora, Darío, Comisario Vane, Guardia Rodric, Vigía del Oeste, Dr. Valen, Hermano Anselmo, Inquisidor
Alistair y Casimir/Valeria: seis rasgos coherentes con su descripción, una red inicial de amistades y rencores y 2–3
secretos cada uno, para que haya tensión desde el día 1. Que no sea todo fijo: deja algo de azar para que cada partida
cambie. Refléjalo en sus notas de `GameVault/04_Censo_y_Misiones/Vecinos/` (créalas desde `GameVault/Plantillas/Vecino.md`
si faltan).

**B7 — Prueba de primera persona (prototipo, después de B6 y antes de las pruebas finales).** El usuario quiere ver si el
juego gana en primera persona (el combate no le convence desde arriba). Es solo una **prueba que se enciende y apaga con
una tecla libre** (p. ej. F8; mira que no la use nadie), sin cambiar nada de la lógica 2D:
- Con la vista 3D activa (`WorldStage3D`, cámara `cam_3d` ortográfica; F9 cambia 2D/3D en `GameManager.gd`), al pulsar
  la tecla la cámara pasa a perspectiva a la altura de los ojos del jugador, mirando hacia donde apunta. El ratón gira la
  vista (captúralo al entrar y suéltalo al salir o al abrir menús) y W/A/S/D se mueve relativo a donde miras.
- El ataque, empujar, parar y usar (E) apuntan hacia el centro de la pantalla: traduce la dirección de la mirada a la
  dirección de apuntado 2D que ya usa el jugador. Una cruz en el centro. Oculta el muñeco del propio jugador (o solo su
  cabeza) para que no tape la cámara.
- Los techos y las paredes que en vista cenital se ocultan/recortan deben verse enteros en primera persona.
- No arregles arte ni animaciones: anota en el informe qué se ve mal de cerca (casas, muñecos, interiores), con
  capturas si puedes (`tools/tests/shot_probe.gd` sirve de ejemplo).
Apúntalo en el Tablero como prueba y en `docs/VISION_Y_FUTURO.md` como idea en evaluación (no decidida).
