# Encargo para Antigravity (escrito por Claude Code, supervisor) — trabajo de noche

> Fecha: 2026-11-07. El usuario se va a dormir: **trabaja en autónomo, sin pedir permiso ni plan previo**, bloque a
> bloque y en este orden. Dile «Lee `docs/ENCARGO_ANTIGRAVITY.md` y haz lo que pone».

## Reglas
- **Pruebas en pausa hasta nuevo aviso (orden del usuario):** no pases `verify_all` ni las otras pruebas. Comprueba
  solo que el juego arranca sin errores de script (`timeout 120 flatpak run org.godotengine.Godot --headless --path .
  --quit-after 300`). Añade su test al final de `verify_all.gd` si quieres, pero no lo ejecutes.
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
