# Encargo para Antigravity (escrito por Claude Code, supervisor)

> Fecha: 2026-11-06. Pega este archivo entero como primer mensaje a Antigravity, o dile: «Lee
> `docs/ENCARGO_ANTIGRAVITY.md` y haz lo que pone».
> Al usuario le queda poca cuota de Claude Code: **trabaja sin pedir permiso** y deja todo bien explicado en el informe.

## 0. Reglas (resumen)

- Tú escribes el código; Claude Code revisa. El usuario no programa: háblale en español, breve, sin código.
- Lee antes `CLAUDE.md`, `docs/HANDOFF.md` (secciones 7 y 8), `docs/VISION_Y_FUTURO.md` (punto «crimen dentro del
  pueblo») y `GameVault/04_Censo_y_Misiones/Trattoria Il Corvo.md`.
- No toques `scripts/systems/VillageSect.gd`, `GameVault/03_La_Secta/`, el Lore provisional, `GameVault/99_Archivo/`,
  `GameVault/.obsidian/` ni `.claude/`.
- Nada rígido: sin temporizadores ni sucesos «porque sí»; todo nace de vecinos con rasgos y condiciones reales.
- Al cerrar cada bloque: test nuevo en `tools/tests/verify_all.gd` (antes de la línea `print("ALL RIMWORLD MEDICAL`),
  una sola pasada de `verify_all` con `timeout 900`, HANDOFF §7, `CHANGELOG.md`, `docs/REGISTRO_TRABAJO.md`, nota del
  vault, Tablero, diario `GameVault/06_Diario/AAAA-MM-DD.md`, textos nuevos en `docs/APORTES_CREATIVOS.md`; commit y push
  a `main`; informe nuevo (reescrito entero) en `docs/INFORME_ANTIGRAVITY.md`.
- Trampas: un assert que falla deja la prueba colgada hasta el timeout (EXIT 124); en pruebas no uses esperas fijas
  (espera en bucle hasta que se cumpla); usa `x.get("campo") == true`, nunca `bool(x.get(...))`; los oficios nuevos se
  añaden al FINAL del enum `TradeRole`.

---

## Bloque R2 — «La Familia» (crimen organizado discreto)

**Contexto:** ya existe la Trattoria «Il Corvo» (`scripts/systems/VillageRestaurant.gd`), con un reservado al fondo
(`BACKROOM_TABLE`, sala `"reservado"`). Plan acordado con el usuario: R2 la Familia → R3 sus negocios → R4 el jugador.
**Haz solo R2.**

**Qué tiene que pasar en el juego:**
1. **Nace sola, no al empezar.** Un vecino adulto **ambicioso, sin escrúpulos y persuasivo** (usa los rasgos y la
   psicología que ya existen; si no hay ninguno así, no nace, y una partida sin Familia es válida) decide montarla
   cuando tiene motivo: dinero ahorrado y frustración (deudas, envidia, rencor) o una oportunidad.
2. **Recluta de 2 a 4 vecinos** de uno en uno, entre quienes le deben algo, le tienen afecto o miedo, o están
   desesperados (pobres, endeudados). Puede fallar: el que se niega lo recuerda y puede contarlo como chisme.
3. **Se reúnen de noche en el reservado** cuando el jefe lo decide según sus planes (no por calendario fijo). Si ven a
   la guardia o a un desconocido cerca, lo dejan para otra noche.
4. **Perfil bajo:** no hacen nada a la vista; de día siguen con sus oficios.
5. **Guardar y cargar:** jefe, miembros y rechazos se guardan con la partida.
6. **Se nota sin menús:** de noche hay gente en el reservado; el cocinero suelta una frase si le preguntas
   (provisional, a `APORTES_CREATIVOS.md`).

**Cómo hacerlo (sugerencia):** módulo nuevo sin `class_name` (`scripts/systems/VillageFamilia.gd`, con `preload`), con
su estado guardado como hacen `VillageNightJobs.gd` o `VillageClub.gd` (copia su patrón de recados nocturnos y de
guardado). Para llegar al reservado ya funciona la ruta interna del restaurante (`VillageRestaurant.route`).

**Test `Block R2`:** con un vecino preparado con los rasgos y condiciones adecuados, comprueba que funda la Familia,
que recluta (y que alguien puede negarse), que de noche los miembros van al reservado, que no se reúnen con un guardia
cerca y que todo sobrevive a guardar y cargar. Sin el vecino adecuado, no nace.

**No hagas** R3 (protección, préstamos, blanqueo, soborno) ni R4: apunta ideas en el informe.

---

## Encargo aparte (pequeño): la enciclopedia del vault en una página

El usuario quiere pasar el vault (`GameVault/`) a alguien que no tiene Obsidian. **Antes pregúntale** si va entera o
sin `03_La_Secta/` y sin los diarios (`06_Diario/`). Luego: script en `tools/` que genere un único `.html` (índice a un
lado, buscador, enlaces `[[...]]` que funcionen, el Tablero como lista), sin `.obsidian/` ni `99_Archivo/`. Déjalo
fuera del repo (no lo subas) y dile al usuario dónde está y que puede mandarlo como archivo.
