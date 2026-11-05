# Nota para el otro agente (Claude Code → Antigravity/Gemini), 2026-11-04

> Léela entera antes de tocar nada. Resume lo que Claude Code hizo después de tu commit `beb062d` (Bloque PQ).
> Varias de tus mecánicas han cambiado de comportamiento.

## Antes de empezar (obligatorio, cada sesión)

1. `git log --oneline -15` y `git diff beb062d..HEAD --stat`. Si la documentación y git no coinciden, manda git.
2. Lee, en este orden:
   - `docs/AUDITORIA_PF_PQ.md` (la revisión de tus 13 bloques);
   - `docs/LECCIONES_P1_P7.md`;
   - `docs/HANDOFF.md` §7: las entradas «Revisión PF–PQ», «Sonda de mecánicas» y «Asaltos con motivo»;
   - las últimas tablas de `docs/REGISTRO_TRABAJO.md`.
3. No toques `scripts/systems/VillageSect.gd`: el usuario se lo reserva. Se puede leer, pero no modificar.
4. **Bóveda de Obsidian (`GameVault/`):** Ya está integrada dentro del repositorio y versionada en GitHub. Al cerrar cualquier bloque, actualiza también las notas correspondientes en `GameVault/` para que todos los agentes trabajemos sobre la misma fuente de verdad.

## Lo que hice (commits en orden)

### 1) Auditoría (`docs/AUDITORIA_PF_PQ.md`)

Tus 4 tests pasaban, pero había 16 problemas que los tests no veían. Los tests llamaban a las funciones con resultado
forzado y datos puestos a mano; nunca pasaban por el diálogo ni por los testigos.

### 2) `0f796bd` — Fallos graves

- **Pisos y alcantarillas sin testigos.** Nadie llamaba a `set_npc_elevation_level`. Con el jugador en −1/+1,
  `_find_conscious_witness_near(..., null)` filtraba a todos los testigos: el jugador podía robar sin que nadie lo viera.
  Arreglos:
  - `VillageHousing.player_near_home` (90 px de un solar suyo): solo se cambia de piso en casa.
  - `VillageManager.check_elevation_exit`, llamado en `_process`, vuelve a nivel 0 si el jugador se aleja 70 px del
    punto donde cambió de piso (`_elevation_anchor`).
  - `explore_sewer_location` ya no teletransporta ni deja al jugador en −1: es una salida de ida y vuelta.
- **El arcabuz no hacía daño.** `apply_minor_bruise(48, 2.5, …)` usaba 2.5 como suelo, así que el daño era 0. Ahora es 0.10.
  - Quité la opción «Dispararle» del diálogo: es el mismo patrón que el robo desde el diálogo, ya prohibido.
  - El arma solo cuenta en la defensa. Usarlo en combate queda como PENDIENTE en VISION.
- **El capítulo IV no se podía cumplir.** Leía `town_state["mayor_key"]`, que no existe. Ahora usa
  `vm.VillageMayor.is_player_mayor(vm)`.
- **Se podía borrar la búsqueda cada día.** `VillageHousing.can_purge_wanted` / `mark_wanted_purge` imponen 7 días
  compartidos (guardados en `last_hide_day`) entre:
  - el sótano;
  - el pasadizo del contrabandista;
  - `hack_terminal("warrant_archive")`, que si toca esperar devuelve `{"ok": false, "wait": true}` sin gastar el intento
    del día.

### 3) `cd18e1c` — Bucles de dinero

- **Bazar del jugador:**
  - empieza con `stock` a 0 y usa la nueva clave `player_shop.goods` {item: cantidad};
  - cada artículo se vende a su precio (`SHOP_ITEM_PRICES`), y el comprador necesita el precio + 12 de oro;
  - `shop_night_theft`: 18 % de probabilidad (7 % con dependiente) de perder la mitad de la caja; el oro pasa al
    vecino más pobre.
- **Corral:** cada animal tiene `fed_day`. Solo crece y da carne si comió hace `ANIMAL_FED_DAYS` (2) días o menos;
  muere a los `ANIMAL_STARVE_DAYS` (5) sin comer.
- **Pinos:**
  - `can_plant_tree` permite 1 al día, con un tope de `MAX_PLANTED_TREES = 12`;
  - ya no dan semilla extra;
  - nuevas funciones `EcosystemManager.count_planted_pines()` y `plant_sapling(pos, side_effects)`;
  - `VillageCulture.restore_planted_trees`, llamado en `after_load` y en `daily`, vuelve a poner los pinos, que no se
    guardaban.
- **Obra maestra:** `MASTERWORK_COLLECTOR_PRICE = 30`, menos que los 35 del taller, así que revender no da ganancia.
- **Red eléctrica:**
  - `grid.saboteur`: si saboteó el jugador, arreglarlo no se cobra;
  - `repair_grid` pone `electric_grid_active = _generator_on()` (antes encendía la red aunque no hubiera generador);
  - un testigo cercano pilla el sabotaje.
- **Milicia:** tope `MILITIA_MAX_BONUS = 4`. La atalaya del asentamiento ya no toca `militia_bonus`, que se pone a 0
  tras cada incursión; ahora suma +2 fijo en `defense_power`.
- **Terminal:** solo aparece con el TINKER, no con el comisario.

### 4) `604696f` — Textos y veracidad

- **El caballo no hacía nada:** nadie leía `mount_speed_mult`. Ahora lo aplica `PlayerMovementController`, y
  `VillageCulture.after_load` lo repone al cargar.
- **Amputación:** el pensamiento sumaba +8 aunque el texto decía −15. Ahora resta 15, y la prótesis suma 12.
- **Cambio de oficio:** `promote_to_trade` conservaba los días del oficio anterior. Ahora vuelve a la base, y
  `school_bonus_days` solo vale para el primer oficio (se borra al usarlo).
- **Asentamiento:** la documentación dice ahora que es «solo de menús». Quedan PENDIENTES en VISION su lugar en el mapa
  y la amputación del jugador.
- **Tu lore** está en `docs/APORTES_CREATIVOS.md` §13, marcado como provisional e inventado por un agente: los
  capítulos de la historia, «el valle es un experimento cerrado» y los nombres de rutas, alcantarillas, incursiones y
  estilos. **El usuario debe confirmarlo: no construyas encima sin su visto bueno.**

### 5) `5e0314a` — Sonda de mecánicas

`tools/tests/feature_probe.gd -- <días> <semilla>`, con `--fixed-fps 60`. 30 días tardan unos 30 minutos reales.

Resultado con el pueblo solo (sin jugador):

| Mecánica | En 30 días |
|---|---|
| Maestros artesanos | 4, con las existencias llenas: nadie les compra |
| Obsesiones | 1 |
| Incursiones | 4, las 4 perdidas |
| Rebaño del rancho | se estanca el día 6 |
| Graduaciones | 0 |
| Investigación, rutas, pinos, bazar, alcantarillas… | nunca pasan sin el jugador |

El usuario dice que «no ve ninguna de las cosas nuevas funcionando». Tiene razón: casi todo son opciones de menú sin
presencia en el mundo.

### 6) `c456869` — Asaltos con motivo y arreglo de la capilla

- **Amenaza con motivo** (`raid_lure`). Suben la amenaza:
  - las arcas por encima de `RAID_RICH_TREASURY` (300);
  - las rutas activas;
  - el asentamiento.

  La amenaza diaria cambia en atracción − 1 − defensa/3, dentro de 0..100. A partir de `RAID_THREAT_WARN` (40) hay una
  probabilidad diaria de aviso. Ya no hay temporizador fijo.
- **Aviso:** por la mañana, con el motivo (`raid_motive_text`) y un `show_hint` al jugador.
- **`raid_on_hour`:**
  - a las 16 h, la guardia y hasta 3 vecinos con agresividad ≥ 0.35 (`raid_volunteers`) hacen el encargo «raid_defend»
    hacia `RAID_GATE_POS` (camino del este);
  - a las 18 h, `resolve_raid`.
- **Fuerza del asalto:** 3 + amenaza/15 (máx. +4) + incursiones rechazadas (máx. +3).
- **Defensa:** los voluntarios suman a `defense_power`. Si se pierde, los defensores salen heridos.
- **Error del editor en la capilla:** `VillageConfession.buy_indulgence` hacía
  `(sect_state["crisis_events"] as Array).append`, pero ese valor es un número (0..0.4). Ahora suma 0.06 con tope 0.4.
  Era un fallo real en partida: rompía la confesión.

## Tests

- Los 4 pasan en `c456869`.
- Asserts nuevos:
  - PN.1f0, PN.1f2, PN.2c2;
  - PO.1e0, PO.2c2;
  - PP.2b0, PP.2b;
  - PG.1e, PG.2g;
  - PI.1d;
  - PJ.2d2, PJ.2d3;
  - PK.1b, PK.1c;
  - PL.2a2, PL.2e–g;
  - PM.1a2;
  - P4.bula.
- **Trampa:** si un assert falla, Godot no se cierra y espera hasta el `timeout`. Lanza `verify_all` en segundo plano
  y vigila el log buscando «SCRIPT ERROR».

## Por qué fallamos en comunicación (y cómo evitarlo)

Los dos hemos documentado como «hecho» cosas que solo pasaban en un test con datos forzados. A partir de ahora:

1. Antes de escribir «hecho», comprueba dos cosas:
   - que la opción aparece en un diálogo real o que la cosa ocurre sola en la sonda;
   - que hay un test del flujo real, sin poner a mano datos que el juego no crea.
2. Al cerrar cada bloque, añade al final de `docs/REGISTRO_TRABAJO.md` una tabla con lo hecho y una línea
   **«Para el otro agente: …»** con los cambios de comportamiento que el otro debe saber.
3. Si cambias algo que hizo el otro agente, dilo en el commit y en esa línea.
4. Sigue las reglas de LECCIONES:
   - ningún oro sale de la nada;
   - todo reto se puede perder y tiene espera;
   - ninguna opción delata un secreto;
   - no uses `has_method` sobre funciones que no has buscado;
   - nada rígido: sin temporizadores «porque sí».

## Qué hacer ahora

El usuario lo pidió así: nada nuevo; hacer visible lo que ya existe.

- No añadas mecánicas nuevas. Primero, que lo existente se vea y pase solo:
  - que los maestros vendan de verdad en el mercado;
  - el título sale «Maestro Maestro», porque `npc_role` ya empieza por «Maestro…» en `promote_to_master`;
  - que el rebaño del rancho se renueve (venta y sacrificio);
  - por qué `pupil_lessons` queda vacío (no hubo clases);
  - por qué el tesoro supera los 1000 y acumula sin gastar.
- Presenta un plan corto al usuario y espera su sí.
- Pasa la sonda antes y después del cambio.
- Con el usuario:
  - español, sin código ni nombres de archivo;
  - máximo 12 líneas y una pregunta al final;
  - permiso antes de lanzar pruebas, diciendo cuánto tardan.
