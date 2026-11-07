# Encargo para Antigravity (Claude Code, supervisor) — Herramientas del detective

> Fecha: 2026-11-07. Trabaja en autónomo, bloque a bloque y en orden. Es **el eje del bucle jugable** (el usuario
> eligió «detective»): tiene que quedar muy bien. Lee antes `docs/ESTADO_DEL_JUEGO.md` y `docs/PLAN_BETA_MISTERIO.md` §6.

## La referencia visual (obligatoria)
Abre `docs/bocetos/examen_cuerpo.html` en el navegador: es el boceto **aprobado por el usuario** («me encanta»).
Cópialo lo más fiel posible en Godot (colores, tipografías parecidas, libreta de papel a la derecha, fichas con
chincheta abajo, tablero de corcho con hilo rojo). Silueta **plana**, sin líneas interiores ni cara; **dos modelos,
mujer y hombre**, según la víctima; el pelo de la mujer cae detrás de la cabeza.

## Reglas
- No toques `scripts/systems/VillageSect.gd`, `GameVault/03_La_Secta/`, el Lore provisional, `GameVault/99_Archivo/`,
  `GameVault/.obsidian/` ni `.claude/`. Las 7 Reglas de las Auditorías (cercanía física, testigos, todo puede fallar).
- Aprovecha lo que ya existe; no lo dupliques: heridas por zonas y su causa (`HealthComponent`, `wounds`),
  venenos e intoxicaciones, `VillageForensics` (escena, sangre, huellas, lejía), la morgue y la autopsia, testigos y
  chismes (`known_by`, `sighting_log`, `GossipMemory`), interrogatorio y juicio (`VillageJustice`), registro de
  misiones. Lo que ve el jugador sale de los datos reales del muerto, no de textos fijos (salvo en casos guionizados).
- **Pruebas:** no las pases mientras programas; solo comprueba que arranca sin errores de script
  (`timeout 120 flatpak run org.godotengine.Godot --headless --path . --quit-after 300`). Al terminar TODO, pasa una a
  una y siempre con `timeout`: verify_all (900 s), social_sim (900), dialogue_coverage (600), feature_probe -- 5 11 (1200).
  EXIT 124 = colgada por un assert: busca `Assertion failed`, arregla y repite (máx. 2 veces).
- Al cerrar cada bloque: HANDOFF §7, CHANGELOG, REGISTRO_TRABAJO, nota del vault (`Investigación Forense.md`),
  Tablero, diario, APORTES_CREATIVOS para textos nuevos; commit y push a `main`. Al final, informe nuevo en
  `docs/INFORME_ANTIGRAVITY.md` con **capturas** de cada pantalla en `docs/capturas_detective/`.

## Bloques
**D1 — Examen del cuerpo en la escena.** Con E junto a un cadáver se abre la pantalla (pausa el reloj del mundo solo lo
justo; cada acción suma minutos de juego). Zonas: cabeza, cuello, torso, brazos, manos, piernas, bolsillos; acciones
mirar / palpar / oler / lupa (si la llevas) / registrar. Solo lo **superficial** (golpes, cortes, marcas, olores,
objetos, causa obvia); lo interno queda «hace falta la morgue». Las marcas descubiertas se dibujan sobre la silueta.
**Fondo real:** al abrir, saca una imagen desde arriba del sitio del cuerpo con la vista 3D (sin vecinos ni jugador,
como `tools/tests/shot_probe.gd`) y pásala a **esquema** (oscura, casi sin color, bordes marcados tipo plano a tinta,
p. ej. con un shader de posterizado + detección de bordes). Si falla la captura (headless), un fondo liso.

**D2 — Autopsia en la morgue.** Con el cuerpo en la morgue y el forense presente. Pruebas por pasos donde se puede
fallar: sangre (de dónde sacarla, reactivo, leer el color; muestra limitada, el reactivo equivocado gasta), cuello
(corte lento o rápido: el rápido estropea), estómago (guardar o tirar el contenido), piel y rigidez (manchas que
dicen si lo movieron, rigidez rara). Consejo del forense a cambio de tiempo. La **causa real** se va completando.

**D3 — Escena del crimen.** Misma idea de fondo real. A oscuras; las pistas solo se ven bajo el farol del jugador
(el ratón mueve la luz). Pistas reales de `VillageForensics` y del lugar (sangre o su ausencia, arrastre, huellas,
objetos). Testigos cercanos: preguntar y presionar (presionar puede cerrarlos según su carácter y su relación contigo).

**D4 — Cuaderno y tablero del caso.** Todo hallazgo se puede anotar como ficha (cuaderno abajo, como el boceto).
Tablero de corcho (tecla propia libre; dila en el informe) con sospechosos y fichas: arrastrar y unir con hilo rojo,
quitar hilos. Se guarda con la partida. El tablero **no** dice quién es el culpable: solo ordena lo que sabes.

**D5 — Preparado para 10 casos guionizados.** Formato de datos de un caso en su propio archivo (pistas fijas, papeles
que se reparten entre vecinos reales, diálogos y sucesos propios), usado por D1–D4 sin tocar su código. Crea solo el
esqueleto de «La mujer del bosque» con las pistas de los bocetos; los huecos de la trama **no** los inventes: déjalos
marcados como pendientes del usuario.
