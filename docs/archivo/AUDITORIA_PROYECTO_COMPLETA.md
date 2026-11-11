# Auditoría Completa del Proyecto (`La Placa de Petri`)

Fecha: 2026-11-04  
Rama: `main`

---

## 1. Alcance y metodología

Se ha realizado una auditoría integral de extremo a extremo sobre el código actual del proyecto:
- **36 módulos de simulación** en `scripts/systems/` (economía, necesidades, justicia, forense, clanes, linaje, confesión, alcaldía, vivienda, bajos fondos, fama, cultura, migración, familia, préstamos, nobles, rasgos, memoria de chismes, secretos y deseos). *(Nota: `scripts/systems/VillageSect.gd` se ha leído sin modificarse por estar reservado al usuario).*
- **25 tipos de misión** en `scripts/systems/quests/types/` y su registro en `QuestRegistry.gd` / `QuestManager.gd`.
- **Entidades y diálogo**: `scripts/enemies/VillageNPC.gd`, `scripts/systems/NPCDialogue.gd`, `scripts/components/PlayerMovementController.gd` y `scripts/systems/GameManager.gd`.
- **Criterios de verificación**:
  1. Las 6 reglas obligatorias de `docs/LECCIONES_P1_P7.md` (existencia real de campos/métodos, cero destripes en menús, economía cerrada sin oro de la nada, retos con posibilidad de fallo, testigos en acciones físicas y tests sobre estado real).
  2. Los 16 puntos de `docs/AUDITORIA_PF_PQ.md` y el diagnóstico de vida autónoma de `tools/tests/feature_probe.gd`.

---

## 2. Vida autónoma y visibilidad sin intervención del jugador (Bloque PR)

A partir de los resultados de la sonda autónoma (`tools/tests/feature_probe.gd`), se corrigieron los 5 cuellos de botella que impedían que varias mecánicas se vieran moverse por sí solas en el mundo:

| # | Problema detectado en la sonda | Causa raíz | Solución implementada |
|---|---|---|---|
| 1 | Título duplicado `«Maestro Maestro»` | `VillageFame.promote_to_master` anteponía `"Maestro "` a `npc.npc_role`, que ya empezaba por `"Maestro "` / `"Maestra "`. | Se recorta cualquier prefijo `"Maestro "` / `"Maestra "` antes de construir el título y se sanean en `VillageFame.daily(vm)` los títulos ya guardados. |
| 2 | Maestros con stock congelado en `[2, 2, 2, 2]` | En `VillageFame.daily(vm)` se fabricaba antes de vender (o se reponía el mismo día de la venta) y el mercado de los miércoles (`VillageCulture.on_market_arrived`) solo descontaba `shop_stock` normal. | Las compras de vecinos solventes (`personal_gold >= 38` de clase acomodada/rica/noble o `>= 48`, cuando `cur_day > since_day`) ocurren antes de fabricar, el taller no repone el mismo día de una venta (`last_sale_day`), y comprar en el puesto de un Maestro en el mercado del miércoles descuenta también `m["stock"]`. |
| 3 | Rebaño del rancho congelado en `["adult", "adult", "adult", "adult"]` desde el día 6 | `VillageHousing.daily(vm)` hacía crecer los animales de `ranch_herd` hasta `"adult"` pero nunca los vendía ni renovaba por crías nuevas. | Al alcanzar `age_days >= ADULT_ANIMAL_DAYS + 3` (9 días), el ganadero vende el ejemplar maduro al carnicero (transferencia real de `8` de oro si el carnicero tiene fondos, `+1 raw_meat` y `+1 wool` al stock del rancho) y lo reemplaza por una cría (`"chick"`, `age_days: 0`), apuntando `"animal_bred"` en la crónica. |
| 4 | `pupil_lessons = {}` y `0` graduaciones escolares | `MIN_PUPILS_FOR_TEACHER` exigía 2 alumnos, las familias con niños solo llegaban si sobraban 2 camas en casas ya construidas, los niños llegaban demasiado pequeños para cumplir 16 años en el horizonte de prueba y la asistencia solo se miraba en el instante de las `14:00`. | `MIN_PUPILS_FOR_TEACHER` baja a `1`; `VillageMigration` permite que familias recién llegadas usen camas libres de la posada (`free_tavern_beds_count`), prioriza el tipo `"familia"` cuando no hay escolares, genera al primer hijo con `12..14` años (para que asista a clase y se gradúe a los 16 en ~12–16 días) y sincroniza la casa de los hijos cuando los padres se mudan; `VillageFamily.on_hour` guía a los alumnos a `school_pos` a las `10:00–12:00` y registra su lección diaria sin duplicarla a las `14:00`. |
| 5 | Arcas municipales acumulando `> 1000` de oro sin gasto | Los impuestos, aranceles y multas entraban en `town_state["treasury"]`, pero salvo obras puntuales y raciones del albergue el ayuntamiento no reinvertía su superávit. | `VillageCulture.process_municipal_spending(vm)` (llamado desde `VillageTown.daily`) invierte el superávit cuando `treasury > 350` en: defensa comunal (`militia_bonus`), becas de investigación tecnológica del taller (`TECH_TREE`, pagando al ingeniero) y apertura de rutas comerciales (`ROUTE_CHARTER_COST` al fondo de la ruta). Además, con `treasury >= 250`, el ayuntamiento subvenciona `8` de oro del salario diario de cada autoridad (`VillageManager._process_morning_salaries_and_inter_guild_circulation`). |

---

## 3. Auditoría de reglas de diseño (`docs/LECCIONES_P1_P7.md`)

### 3.1. Economía cerrada («Ningún oro sale de la nada ni se esfuma»)
Durante la revisión línea por línea de los módulos de diálogo y acciones del jugador se detectaron y corrigieron los últimos casos donde una recompensa o un pago no tenía contrapartida en el bolsillo de un vecino o en las arcas municipales:

1. **`scripts/systems/VillageForensics.gd`:**
   - `forensic_expose_hitman`: la recompensa de `35` de oro ahora se cobra primero confiscando del bolsillo del autor intelectual (`mm_hm.personal_gold`) y el resto de `town_state["treasury"]`.
   - `forensic_contract_report`: la multa de hasta `40` de oro al instigador cubre los `30` de recompensa (completados por las arcas si el instigador tiene menos de `30`), y los `10` restantes de la multa ingresan en `town_state["treasury"]` en vez de perderse.
   - `forensic_slip`: la recompensa de `35` de oro por delatar la confesión ebria/febril se cobra de la multa al culpable y/o de `town_state["treasury"]`.
   - `forensic_ambush`: la recompensa (`AMBUSH_REWARD = 40`) se financia con la multa incautada al asesino (`killer.personal_gold`) y `town_state["treasury"]`.
   - `forensic_frame`: los `15` de oro (`FRAME_COST`) pagados por el jugador pasan al bolsillo del vecino (`npc.personal_gold`).
2. **`scripts/systems/VillageUnderworld.gd`:**
   - `underworld_bet_fight`: la apuesta de `15` de oro del jugador entra en `npc.personal_gold` y, si gana, el premio (`30` de oro) sale de `npc.personal_gold`.
   - `underworld_join_brawl`: la bolsa de `35` de oro al ganar en el círculo clandestino sale de `npc.personal_gold`.
   - `underworld_report_fence`: la recompensa de `45` de oro al delatar el mercado negro se financia confiscando hasta `45` del bolsillo del perista (`fence.personal_gold`) y el resto de `town_state["treasury"]`.
3. **`scripts/systems/VillageMayor.gd`:**
   - `town_smear`: los `15` de oro (`SMEAR_COST`) pasan al bolsillo del vecino con el que difundes el escándalo (`npc.personal_gold`).
   - `town_cook_books`: los `15` de oro (`COOK_BOOKS_COST`) pasan al bolsillo del interlocutor que ayuda a cuadrar las cuentas (`npc.personal_gold`).
4. **`scripts/systems/VillageLineage.gd`:**
   - `lineage_adopt`: los `15` de oro del ajuar se ingresan en `kid.personal_gold`.
   - `lineage_past_help`: los `25` de oro (`PAST_DEBT_GOLD`) para saldar la vieja deuda familiar ingresan en `town_state["treasury"]`.

### 3.2. Retos con riesgo («Todo reto se puede perder»)
- **`scripts/systems/VillageMayor.gd` (`town_speech`):** era la única acción de campaña que siempre tenía éxito automático (`+8 + cha * 4`). Ahora realiza una tirada ponderada por Carisma (`0.45 + 0.15 * cha`, entre `25 %` y `90 %`): si falla, el candidato se traba ante la plaza, pierde `-4` de `campaign_bonus` y queda registrado en la crónica (`campaign_speech_flop`).
- Todos los demás retos del juego (`town_debate`, `town_recall`, `underworld_challenge_boss`, `underworld_bet_fight`, `underworld_join_brawl`, `underworld_animal_race`, `underworld_cockfight`, `fame_praise`, `fame_tarnish`, `fame_calm_obsessed`, `fame_companion_backup`, `culture_sabotage_grid`, `culture_expedition`, `underworld_sewer_explore`, `culture_hack_terminal`, `lineage_search_pocket`, `housing_deed` con escritura falsa) cuentan con tirada de fallo, testigos o penalización verificada.

### 3.3. Preservación del misterio («Ninguna opción delata un secreto solo por aparecer»)
- **Comisaría y forense (`VillageForensics.gd`):** el menú del comisario (`forensic_menu`) no muestra el nombre del asesino real; las opciones de rastro, chivo expiatorio, testigo intimidado y coartada falsa solo aparecen al hablar con la persona implicada; las pólizas de seguro (`forensic_check_insurance`) se pueden consultar sobre cualquier víctima por `10` de oro e incluyen pólizas inocentes entre familiares; al asesino ebrio o febril hay que escucharle primero en persona (`forensic_listen_slip`) antes de poder delatarle (`forensic_slip`).
- **Cartas de amantes (`VillageLineage.gd`):** `lineage_search_pocket` se ofrece ante cualquier vecino adulto (1 vez al día, con riesgo de ser visto por testigos o descubierto por la víctima) y dice que no lleva nada si no hay carta.
- **Admirador obsesivo (`VillageFame.gd`):** `fame_probe_obsession` se ofrece con cualquier adulto cuando hay un rumor en el pueblo (1 vez al día) sin señalar quién es el acosador hasta dar con él.

### 3.4. Testigos, capas verticales y acciones en el mundo
- Los cambios de planta (`+1` altillo / `-1` sótano) exigen estar a `<= 90` px de una vivienda del jugador (`VillageHousing.player_near_home`) y `VillageManager.check_elevation_exit` devuelve automáticamente al jugador al nivel `0` al alejarse `> 70` px del punto de acceso.
- Las alcantarillas (`explore_sewer_location`) funcionan como incursión de ida y vuelta sin dejar al jugador en nivel `-1` por las calles.
- Fregar sangre con lejía (`bleach_crime_scene`), robar el encargo del perista (`try_steal_heist_on_site`), limpiar lápidas profanadas y sabotear la red eléctrica comprueban testigos conscientes en el mismo nivel mediante `_find_conscious_witness_near`.

### 3.5. Persistencia (`save/load`) y salud de referencias
- Verificada la serialización de todos los estados en `VillageManager.gd` y `GameManager.gd` (incluyendo prefijos `NPC_Noble_` y `NPC_Child_`, metas de `VillageNPC` en `SAVED_INT_METAS` y `SAVED_STR_METAS`, `restore_planted_trees` y `mount_speed_mult` en `VillageCulture.after_load`).
- Verificada la migración completa de claves por nombre al cambiar el apellido de un niño (`VillageLineage.rename_child`).

---

## 4. Elementos que quedan conscientemente como PENDIENTES en `docs/VISION_Y_FUTURO.md`

De acuerdo con `docs/AUDITORIA_PF_PQ.md` y `docs/VISION_Y_FUTURO.md`, los siguientes tres puntos no son errores sino ampliaciones futuras ya anotadas como `PENDIENTE`:
1. **Uso del arcabuz en combate directo:** actualmente cuenta en la defensa del pueblo frente a incursiones (`+3`) y tiene función de disparo con daño real, pero falta integrarlo como arma empuñable en combate en tiempo real.
2. **Lugar físico en el mapa para el asentamiento «Puesto del Paso»:** actualmente se funda y gestiona desde los menús del ayuntamiento/taller y participa en las rutas e incursiones.
3. **Amputación del propio jugador:** actualmente las amputaciones por gangrena ocurren en vecinos y las prótesis funcionan tanto para vecinos como para el jugador.
4. **Revisión por el usuario del lore provisional** recogido en `docs/APORTES_CREATIVOS.md` §13.

---

## 5. Batería de pruebas ejecutada

| Suite | Resultado | Detalle |
|---|---|---|
| `tools/tests/names_check.gd` | ✅ PASA | 400 nombres y apellidos sin colisiones, tildes y concordancia correctas |
| `tools/tests/social_sim.gd` | ✅ PASA | Simulador abstracto de 60 días dentro de las metas de parejas, peleas y distribución |
| `tools/tests/dialogue_coverage.gd` | ✅ PASA | ~591 acciones de diálogo recorridas en 18 vecinos sin errores de ejecución |
| `tools/tests/verify_all.gd` | ✅ PASA | 95 bloques de pruebas integrales (incluyendo Bloque PR #95 de vida autónoma y gasto municipal) |
| `tools/tests/feature_probe.gd` | ✅ PASA | Sonda autónoma (`-- 16 11`, 871 s reales): 4 maestros sin título duplicado (`«Maestro Herrero»`) y con ventas reales (`stock=[0, 1, 1, 0]`), 4 renovaciones del rancho (`animal_bred=4`, `rebaño=["adult", "adult", "chick", "chick"]`), escuela activa (`teacher=1`, `clases_por_alumno={"npc_13_eulalia": 10, "npc_14_beatriz": 11}`), 3 inventos completados (`tech_unlocked=3`), 2 rutas comerciales abiertas (`trade_route=2`), 2 entrenamientos de milicia (`militia_trained=2`) y arcas saneadas (`tesoro=245`, población `18 → 36`) |
