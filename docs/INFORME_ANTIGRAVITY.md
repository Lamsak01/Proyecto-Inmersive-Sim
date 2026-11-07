# Informe de Antigravity — Trabajo Nocturno Autónomo: Bloques B1 a B7 y Batería Completa de Pruebas

**Fecha:** 2026-11-07  
**Estado:** Implementados los 7 bloques (`B1` a `B7`) en orden estricto, documentados y subidos bloque a bloque a `origin/main`, y verificadas las 4 baterías de pruebas finales (`verify_all.gd`, `social_sim.gd`, `dialogue_coverage.gd` y `feature_probe.gd -- 5 11`) con salida `0`.

---

## 1. Resumen de los 7 bloques implementados

### B1 — Ruido y testigos en combate (cierra C7) — Commit `187564f`
- **Emisión física de ruido en combate (`Player.gd`, `VillageNPC.gd`):**
  - Los golpes fuertes del jugador (`attack_heavy`), disparos (`gunshot`), gritos de dolor al recibir daño (`pain_scream` cuando `amount >= 10.0`) y disparos policiales llaman a `AudioManager.emit_noise(global_position, radius, elevation_level, kind)`.
- **Propagación y reacción física (`VillageManager.on_combat_noise_emitted`, `VillageNPC.react_to_combat_noise`, `VillageNPC._process_noise_reaction`):**
  - El radio del ruido se atenúa `0.45x` si hay cambio de planta (`elevation_level != noise_elev`).
  - Los **guardias y comisario** despiertos dentro del radio entran en `_noise_react_mode = "guard_investigate"` y acuden a pie al origen del ruido.
  - Los **vecinos pacíficos** dentro del radio huyen en dirección opuesta (`"civilian_flee"`) si son cobardes o están muy cerca, o se asoman con cautela desde distancia segura (`"civilian_peek"`, curiosos/chismosos/valientes).
- **Testigos con línea de visión en la misma planta (`VillageNPC._try_log_combat_noise_witness`):**
  - Ningún vecino se convierte en testigo solo por oír el ruido: únicamente cuando está en la **misma planta** (`elevation_level == _noise_react_elev`), a `<= 195 px` y con **línea de visión despejada** (`vm.has_line_of_sight`), registra el avistamiento en `sighting_log` y pasa a `known_by` del suceso en `social_event_log`.

### B2 — Calabozo de verdad — Commit `32ee992`
- **Sistema físico de calabozo (`scripts/systems/VillageJustice.gd`):**
  - Tres literas/posiciones reales dentro de la celda de la comisaría (`CELL_SPOTS`: `(934, 152)`, `(956, 152)`, `(978, 152)`), puerta de rejas en `CELL_DOOR_POS = Vector2(920, 152)` y mostrador de fianzas en `DESK_POS = Vector2(886, 132)`.
  - `arrest_npc(vm, npc, officer, reason, hours, bail_gold)` detiene a cualquier vecino pillado in fraganti en trabajos nocturnos (`VillageNightJobs`: robo nocturno, sabotaje, profanación), peleas graves con guardia presente o condena del Inquisidor Real.
  - **Delatar a «La Familia» detiene al jefe:** en `VillageFamilia.on_player_action("familia_report_sheriff")`, el Comisario Vane arresta a **Don Vittorio Corvo** durante `48 h` con `90` de oro de fianza y lo escolta/encierra en la celda.
  - **Vida tras los barrotes e interacción:** durante su condena (`24–48 h`), el vecino permanece tras los barrotes con bocadillo `🔒⛓️ En el calabozo por ...`. El jugador puede hablar con él a través de las rejas, **pagar su fianza** al Comisario/Guardia (suma cero: el oro pasa del bolsillo del jugador a `town_state["treasury"]`, libera al preso y sube `+15` de afinidad) o **forzar la cerradura** a `<= 48 px` con ganzúa (`repair_kit`, puede fallar con 35 % y romper la herramienta) o llave. Si un guardia o testigo con línea de visión en la misma planta lo ve forzar la celda, suma búsqueda policial (`+1★`).
  - Al cumplirse las horas de condena (`on_hour`), el vecino sale libre por su propio pie y retoma su rutina.

### B3 — Del campamento del lago al pueblo — Commit `05c1cfc`
- **Traslado real de Toby y su comedero (`VillagePlayerHome.relocate_toby_to_player_lot`, `LakeCampSetup.gd`, `WildDog.gd`):**
  - Cuando el jugador tiene casa propia construida en un solar del pueblo (`lots_state[lot_id]["stage"] == "built"`), al hablar con Toby domesticado aparece `«🐕🏠 Llevar a Toby y su comedero a mi solar del pueblo»`.
  - Mueve físicamente a Toby (`home_pos`, `patrol_Points`) y el nodo `DogFeeder` al jardín del solar del jugador (`lot["rect"].position + Vector2(18, 52)`), conservando las raciones de carne (`feeder_meat`) y persistiendo en `lots_state["toby_relocated_lot"]`.
- **Traslado real del gallinero y ganado (`VillagePlayerHome.relocate_livestock_to_player_lot`, `VillageRanch.gd`, `NPCDialogue.gd`):**
  - Desde el tablón del solar o hablando con el ganadero teniendo casa propia, `«🐔🏠 Trasladar mi gallinero y animales a mi solar del pueblo»` traslada físicamente el nodo `PlayerCoop` y los animales domésticos del jugador (`in_group("player_livestock")`) a su solar (`lots_state["coop_relocated_lot"]`).
  - El campamento del lago del oeste mantiene intactos su cama/refugio, fogata y puestos de pesca y caza.

### B4 — Coherencia del ambiente — Commit `79fa7de`
- **B4.1 — Niebla de madrugada y faroles (`VillageManager.get_ambient_vision_multiplier_at`, `VillageNPC.is_carrying_lantern`):**
  - Entre las `04:00` y las `07:00` (o con clima de niebla), la niebla recorta el alcance de visión de vecinos y guardias (`0.58x`), **salvo** si el objetivo está a `<= 115 px` de una farola encendida (`STREETLIGHT_SPOTS`, cuando no hay apagón) o de un vecino despierto que lleve farol encendido (`is_carrying_lantern`, activo de `20:00` a `06:00` excepto en recados furtivos o sonambulismo).
- **B4.2 — Humo y chispas en 2D y 3D en talleres saboteados + lluvia apaga fuegos (`VillageManager._update_sabotaged_shops_vfx`, `WorldStage3D._sync_sabotage_3d_markers`, `VillageEvents.on_hour`):**
  - Todo taller con `sabotaged_until_day >= current_day` muestra columnas de humo y chispas de cortocircuito en 2D (`SabotageVFXRoot`) y esferas volumétricas 3D animadas de humo y chispas en `WorldStage3D` hasta que el arreglador (`TINKER`) o el dueño lo reparan.
  - Si se declara un incendio exterior y está lloviendo o diluviando (`Weather.RAIN` / `STORM`), `VillageEvents.on_hour` apaga el fuego automáticamente sin daños y deja constancia en la crónica.
- **B4.3 — Tendencias activas y paseos nocturnos (`TraitCatalog.gd`, `VillageNeeds.on_hour`, `VillageNPC.gd`):**
  - Se ha retirado la etiqueta `«(dormida)»` de las tendencias ya conectadas en `TraitCatalog.gd`.
  - Entre las `23:00` y las `04:00`, los vecinos con rasgo `"Noctámbulo"` o `"Insomne"` salen a dar paseos nocturnos (`errand_kind = "night_stroll"`, con farol), y los `"Sonámbulo"` caminan dormidos por las calles (`errand_kind = "sleepwalk"`, con `is_sleeping = true` y sin farol).

### B5 — Lo que se ve en la calle — Commit `d74706b`
- **B5.1 — Cruces de desprecio en la calle (`VillageNeeds._tick_street_contempt_crossings`):**
  - Cuando dos vecinos conscientes que se odian (`rel <= -50`) o cuyas familias están en **feudo de sangre** (`VillageClans.in_feud`) se cruzan a `< 80 px` con línea de visión en la misma planta, sueltan un bocadillo corto de desprecio (`«¡Aparta de mi vista, ...!»`, `«😤 *Escupe al suelo al cruzarse*»`) y dan un paso lateral para apartarse (con enfriamiento por pareja de 45 s).
- **B5.2 — Acecho nocturno previo a una venganza (`VillageDesires.tick_night_prowling`):**
  - Quien prepara una venganza o asesinato (`desire.kind == "revenge"` activo y no cumplido) sale de madrugada (`00:00–04:00`) los días previos a rondar en sigilo la puerta de la casa de su víctima (`errand_kind = "prowl_victim"`, sin farol y con bocadillo corto al acechar).
- **B5.3 — Bocadillos cortos de 1,5 s sin pausar (`VillageNPC.spawn_short_bubble`):**
  - Al terminar un artesano maestro una **obra maestra** (`VillageFame.try_craft_masterwork`), al entrar los **niños en fila a la escuela a las 09:00** (`VillageSchool.on_hour`) y al **inaugurar el ayuntamiento una mejora** (`VillageMayor`), los protagonistas lanzan bocadillos de `1,5 s` sobre su cabeza sin detener la acción ni abrir paneles.

### B6 — Los 21 vecinos fundadores con historia — Commit `1f156c0`
- **Perfiles de 6 rasgos coherentes, red de amistades/rencores y 2–3 secretos por fundador (`scripts/data/NPCData.gd`, `scripts/systems/VillageSecrets.gd`):**
  - Los **21 vecinos fundadores** (*Thoran, Kael, Garrick, Lina, Bram, Mila, Elena, Tomás, Marlo, Nora, Marta, Aldric, Sora, Darío, Comisario Vane, Guardia Rodric, Vigía del Oeste, Dr. Valen, Hermano Anselmo, Inquisidor Alistair y Maese Casimir / Valeria la Tratante*) cuentan en `INITIAL_PERSON_PROFILES` con **6 rasgos de personalidad** sin conflictos en `TraitCatalog.gd`, variantes de rasgos (`trait_variants`), al menos 3 relaciones iniciales explícitas en `INITIAL_NPC_RELATIONS`, variantes de relación en `FOUNDER_RELATION_VARIANTS` y una bolsa de 4 secretos en `FOUNDER_SECRETS_POOL`.
  - `VillageSecrets.seed_founder_history(vm, seed_val)` sortea entre 2 y 3 secretos activos en `npc.founder_secrets` para cada fundador y aplica variaciones de rasgos y relaciones entre partidas.
- **Documentación completa en `GameVault/04_Censo_y_Misiones/Vecinos/`:**
  - Creadas y actualizadas las 21 fichas individuales de los vecinos fundadores con sus 6 rasgos, amistades, rencores y secretos posibles.

### B7 — Prueba de primera persona (prototipo F6/F8) — Commit `1bb91c4`
- **Prototipo conmutable con `F8` (y respaldo `F6`) sin alterar la lógica 2D (`GameManager.gd`, `WorldStage3D.gd`, `Player.gd`, `BuildingShell3D.gd`):**
  - En `GameManager._unhandled_input`, pulsar **`F8`** (o **`F6`** si el escritorio intercepta `F8`) activa automáticamente la vista 3D si estaba en 2D y conmuta `stage_3d.toggle_first_person_mode()`.
  - `cam_3d` pasa de proyección ortográfica cenital a `PROJECTION_PERSPECTIVE` (`fov = 72°`, `near = 0.05`, `far = 420.0`) situada a la altura de los ojos del jugador (`eye_y = 0.88`), mirando según `_fp_yaw` y `_fp_pitch`.
  - Captura el ratón (`MOUSE_MODE_CAPTURED`) al entrar y lo libera automáticamente (`MOUSE_MODE_VISIBLE`) al salir o cuando se abre cualquier menú, diálogo o inventario (`_is_any_ui_blocking_fp_mouse()`), mostrando una **cruz central** (`FirstPersonCrosshair`) y ocultando el avatar 3D del propio jugador para no tapar la cámara.
  - En `Player.gd`, cuando `first_person_active` está encendido, `W/A/S/D` mueve al jugador relativo a donde mira la cámara (`get_first_person_move_vector`) y atacar, empujar, parar (`parry`) y usar (`[E]`) apuntan hacia el centro de la pantalla (`get_first_person_aim_2d()`).
  - En `BuildingShell3D.gd`, cuando `first_person_mode` está activo, los techos (`roof_node`, `upper_roof_node`) y fachadas (`front_wall_group`, `upper_shell_group`) dejan de recortarse en modo cenital y se muestran enteros.

---

## 2. Resultado de las 4 baterías de pruebas finales

Siguiendo las reglas de `docs/ENCARGO_ANTIGRAVITY.md`, las 4 baterías se ejecutaron al final, una por una y con `timeout`:

1. **`verify_all.gd` (`timeout 900`):**
   - **Incidente detectado en la primera pasada y corrección aplicada:**
     - En la primera ejecución, el chequeo antiguo `B3.2` (línea 741, descripción de quedada de pareja en `get_activity_description()`) falló cuando el test eligió a `Bram` porque el caso anterior `Case 18c` (línea 554) dejaba a `Bram` con `_reacting_unconscious_target` sin limpiar y `seed_founder_history` variaba relaciones al azar antes de los tests deterministas iniciales. Además, en `verify_all.gd` se corrigieron referencias de `SceneTree` (`root.get_node_or_null("AudioManager")`, `get_first_node_in_group`, `vm.lots_state[b3_lot]`).
     - **Solución:** `VillageNPC.assign_hangout()` ahora limpia `_clear_unconscious_reaction_state()`, `_noise_react_timer` se evalúa en la rama por defecto de `get_activity_description()` para no pisar `ActivityState.SOCIALIZING`, y `VillageSecrets.seed_founder_history(vm, seed_val)` mantiene deterministas los rasgos/relaciones base en arranque headless (`seed_val == 0`) mientras ejercita las variaciones con semillas explícitas (`101` y `202`) en `Block B6`.
   - **Resultado tras el ajuste:** **EXIT `0`** (`Block B1 / C7 fase 4d OK`, `Block B2 OK`, `Block B3 OK`, `Block B4 OK`, `Block B5 OK`, `Block B6 OK`, `Block B7 OK`, `ALL ... TESTS PASSED!`).

2. **`social_sim.gd` (`timeout 900`):**
   - **Resultado:** **EXIT `0`** a la primera en 4 s (`SIM 60d` en semillas `101`, `202`, `303`, `404`, `505` -> `SOCIAL SIM CHECK PASSED`).

3. **`dialogue_coverage.gd` (`timeout 600`):**
   - **Resultado:** **EXIT `0`** a la primera (`COVERAGE DONE npcs=19 actions=619`).

4. **`feature_probe.gd -- 5 11` (`timeout 1200`):**
   - **Resultado:** **EXIT `0`** a la primera en 330 s (`START day=1 pop=19` -> `DAY 6 pop=34`, `tesoro=847`, `PROBE DONE days=5 real_seconds=330`).

---

## 3. Evaluación visual del prototipo de Primera Persona (B7)

Se han tomado 3 capturas automáticas con `tools/tests/shot_b7_fp.gd` en `docs/capturas_b7/`:
- `docs/capturas_b7/fp_01_calle_casas.png` — Vista de calle y fachadas mirando hacia la plaza y talleres.
- `docs/capturas_b7/fp_02_vecino_cerca.png` — Primer plano de un vecino (`CharacterAvatar3D`) a distancia de conversación/combate.
- `docs/capturas_b7/fp_03_interior_taberna.png` — Vista del interior de la Taberna «El Jabalí Dorado» bajo techo cerrado.

### Qué funciona bien desde el primer momento
- **Legibilidad espacial de combate y distancias:** a ras de suelo (`eye_y = 0.88`, `FOV 72°`) se percibe de inmediato el alcance real de un puñetazo, parada o empujón frente al rival, y el giro con ratón + movimiento relativo `W/A/S/D` responde sin retardo sobre la física 2D existente.
- **Atmósfera e iluminación:** el cielo físico, la niebla y las luces puntuales de farolas, ventanas y antorchas ganan mucha presencia al mirar hacia el horizonte en perspectiva.

### Qué se ve mal de cerca (para valorar si se adopta en el futuro)
1. **Casas y fachadas (`BuildingShell3D`):**
   - Los muros y tejados están pensados para vista cenital/isométrica con colores planos y geometría de cajas simples (`BoxMesh` / `PrismMesh`); vistos a un metro de los ojos se notan aristas duras sin textura de piedra/madera, zócalos lisos y huecos de puerta sin marco ni hoja batiente 3D.
2. **Muñecos de los vecinos (`CharacterAvatar3D`):**
   - Los avatares 3D están armados con primitivas geométricas sencillas (esferas y cilindros de colores planos pensados para leerse a 45° de altura). En primer plano (`fp_02_vecino_cerca.png`) parecen maniquíes abstractos sin rostro, manos ni articulación fina de brazos al atacar, y los bocadillos/barras pensados para `Node2D` quedan en la capa 2D salvo que se proyecten al espacio 3D.
3. **Interiores (`fp_03_interior_taberna.png`):**
   - Al cerrar los techos a altura de primera planta (`WALL_H`), los interiores carecen de cielo raso detallado con vigas, lámparas colgantes 3D y mobiliario 3D con volumen (muchos muebles e iconos de mostrador existen en la escena 2D pero en 3D solo tienen bloques básicos o quedan planos en el suelo).
   - Además, los techos bajos dan sensación de caja cerrada si no se levanta ligeramente la altura de techo interior (`WALL_H`) o se añaden ventanas practicables con luz interior dedicada.
