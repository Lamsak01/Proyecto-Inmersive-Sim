# Encargo A4 — Amputación también para el jugador (bloque pequeño)

> Escrito por Claude Code (supervisor), 2026-11-06. Fila A4 de `docs/PLAN_ORDENADO.md`.
> Decisiones **ya tomadas por el usuario** (opción A): el médico te avisa y **eliges tú**; si te niegas, la infección
> sigue su curso y puedes morir. No cambies ninguna. Si algo no encaja con el código, apúntalo en el informe y pregunta.

## Reglas (orden del usuario)
- Lee solo este encargo, `CLAUDE.md` y lo que se nombra aquí (`scripts/systems/VillageIllness.gd`,
  `scripts/systems/combat/HealthComponent.gd`, `scripts/visuals/CharacterAvatar3D.gd` ~líneas 350–375).
- No pases pruebas mientras trabajas. Al cerrar: arranque sin errores y **una sola** prueba (`verify_all` con
  `timeout 900`). Nada de tipos de clase del juego en las variables del test.
- No toques nada fuera de este encargo.

## Lo que ya existe (no lo rehagas)
- `VillageIllness.amputate(vm, key, limb, reason)` e `install_prosthetic(vm, key, …)` **ya aceptan `key == "player"`**:
  ponen `region_hp[limb]` a 0 (o a 40/45 con prótesis). `HealthComponent.get_moving_capacity()` y
  `get_manipulation_capacity()` salen de `region_hp`, así que **sin pierna ya andas más despacio** (lo aplica
  `PlayerMovementController`) y **sin brazo ya golpeas más lento** (lo aplica `PlayerCombatController.attack`).
  Comprueba en el informe, con números, cuánto bajan las dos capacidades al amputar y con prótesis.
- La opción del médico «Implantar prótesis…» para ti (`illness_prosthetic_self`) ya existe.
- Una herida con la infección al 100 % ya mata por sepsis (`HealthComponent`, ~línea 258).
- Los vecinos se amputan solos en la ronda diaria del médico (`VillageIllness`, ~línea 218), con el umbral
  `infection >= 65` en una herida de brazo o pierna (`LIMB_LABELS`). **Eso no cambia.**

## 1. Aviso del médico (una vez por herida)
- En esa misma ronda diaria, si una herida **tuya** de brazo o pierna tiene `infection >= 65` y no tienes ya ese
  miembro amputado: **no amputes**. Guarda el aviso en el estado (`VillageNeeds.state(vm)["player_gangrene"]` con
  `{limb, limb_label, day}`) y avisa al jugador **una sola vez** con el aviso en pantalla que ya use el juego para
  avisos matinales (`show_hint` o el que uses en P2 para el robo de la carreta):
  «El médico ha oído que tu herida del %s se ha gangrenado. Ve al hospital antes de que sea tarde.»
- Si la infección de esa herida baja de 65 (te curas solo), borra el aviso.

## 2. Elegir en el hospital
- En la charla con el médico (`VillageIllness.add_dialogue_choices`), con el aviso activo, dos opciones arriba del todo:
  - «🪚 Amputar el %s gangrenado (te salva la vida)» → `amputate(vm, "player", limb, "gangrena por infección")`,
    borra el aviso, crónica «El médico amputó el %s del forastero», y el médico dice una frase corta. **Gratis** (es
    salvarte la vida; el usuario no pidió precio).
  - «No, me la quedo» → no pasa nada; el aviso sigue (puedes volver a decidir). Frase del médico:
    «Tú sabrás. Si la fiebre sube, ya no habrá nada que cortar.»
- La amputación **no pide doble E** (no es un gasto).

## 3. Que se vea
- Comprueba que tu muñeco 3D muestra el miembro amputado / la prótesis con lo que ya hace `CharacterAvatar3D` para los
  vecinos (lee `needs_state["amputations"]`): si para el jugador no funciona, haz que use la clave `"player"`; si no se
  puede, dilo en el informe. No hagas modelos nuevos.

## Prueba (una sola, en `verify_all`): bloque «A4 amputación»
1. Con una herida tuya de pierna al 70 % de infección, la ronda diaria **no** te amputa y deja el aviso.
2. Elegir «Amputar» en la charla con el médico: queda la amputación de esa pierna y `get_moving_capacity()` baja.
3. Con la prótesis instalada, `get_moving_capacity()` sube respecto a sin prótesis.

## Al cerrar el bloque
Lo mismo que en `ENCARGO_ANTIGRAVITY.md` §3 (HANDOFF, CHANGELOG, registro, bóveda y diario), y además:
1. `docs/INFORME_ANTIGRAVITY.md`: reescríbelo entero. **Nombra solo funciones que existan**.
2. Commit en español y push a `main` (haz `git pull` antes). No subas la carpeta `.claude/`.
