# HANDOFF — Traspaso del proyecto "La Placa de Petri" (Godot 4.7.2)

> Documento para el siguiente agente de IA (o persona) que continúe el proyecto. **Léelo entero antes de tocar nada.**
> Última actualización: 2026-11-03, tras cerrar el bloque M (25 tipos de misión). Traspaso a otro agente: `docs/PROMPT_SIGUIENTE_AGENTE.md`.

---

## 0. PROMPT LISTO PARA PEGAR AL SIGUIENTE AGENTE

**Cambio de ordenador (2026-11-05):** cómo bajar el proyecto, qué no viaja con git y qué toca hacer ahora, en
**`docs/CONTINUAR_EN_OTRO_PC.md`**.

El prompt completo y actualizado (2026-11-03) está en **`docs/PROMPT_SIGUIENTE_AGENTE.md`**: cómo comunicarse con el
usuario (crítico, sin darle la razón por defecto), reglas de trabajo, pruebas, preferencias, lo hecho, lo pendiente y
recomendaciones. Pégalo entero como primer mensaje al cambiar de agente.

- **Bóveda de Obsidian compartida (`GameVault/`):** Toda la base de conocimiento del proyecto está integrada en la carpeta `GameVault/` de la raíz del repositorio (con `.gdignore` para que Godot no la importe). Tanto Claude Code como Antigravity o cualquier agente futuro deben leerla y actualizar las notas correspondientes (`02_Sistemas/`, `04_Censo_y_Misiones/`, `05_Roadmap_y_Lore/`, `06_Diario/`) al cerrar cada bloque, subiéndola a `main` junto con el código.

---

## 1. Qué es el proyecto

- Immersive sim 2D en pixel art ("La Placa de Petri"): un forastero llega a un valle con ~17 aldeanos con rutina propia.
- Sistemas ya hechos: combate, sigilo, supervivencia, **medicina anatómica estilo RimWorld**, economía y tiendas, justicia
  (cadáveres, testigos, detective, interrogatorio con rueda de diálogo, juicio público), **relaciones entre vecinos**,
  **glosario social `[J]`**, **habilidades RPG `[K]`**, reacciones a vecinos inconscientes.
- El texto del juego y el lore son **provisionales** (el usuario lo confirmó): se puede reescribir libremente.

## 2. Reglas de trabajo con el usuario (importante)

- Idioma: **español**. Conciso. Explica el "qué" y el "por qué" sin jerga.
- **Nunca nombres archivos, funciones, variables ni líneas de código** en tus mensajes al usuario, salvo que él lo pida. Habla siempre del juego (vecinos, tiendas, misiones, la cantera, el mapa...).
- **Formato para cada problema o propuesta:** 1) Qué pasa (en palabras de jugador), 2) Qué notaría en el juego (o «no se nota, es para el futuro»), 3) Qué pasa si no lo hacemos, 4) Recomendación (hacerlo ya / más adelante / no hacerlo) y coste (poco / medio / mucho).
- **Máximo 10–12 líneas por mensaje.** Si hay varias cosas, empieza por la más importante y pregunta si quiere oír el resto.
- **Pregunta SIEMPRE antes de lanzar pruebas o partidas de prueba**, diciendo cuánto tardan.
- **Termina cada mensaje con una sola pregunta clara** de lo que necesitas del usuario.
- El usuario **no programa**; prefiere que decidas lo técnico y le preguntes lo de diseño con opciones claras.
- Le preocupan los **tokens**: bloques pequeños, bien documentados, siempre dejando el repositorio en estado limpio y commiteado.
- Le gusta: planificar antes, probar jugando y reportar lo que ve.
- Preferencias de diseño ya decididas: ver sección 8.

## 3. Entorno y cómo probar

- Motor: **Godot 4.7.2** vía Flatpak. No hay editor abierto para ti; todo se verifica en modo headless.
- Desde la raíz del proyecto:

```bash
# Test completo (debe imprimir "...TESTS PASSED!" y salir con código 0). Hoy tarda varios minutos: usa timeout 900.
timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd > /tmp/t.log 2>&1; grep -c 'TESTS PASSED' /tmp/t.log

# Test de nombres (rápido, ~2 s; debe imprimir "NAMES CHECK PASSED"):
timeout 60 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/names_check.gd 2>&1 | tail -3

# Simulador social de 60 días (debe imprimir "SOCIAL SIM CHECK PASSED"):
timeout 150 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/social_sim.gd 2>&1 | tail -3

# Cobertura de diálogos: ejecuta todas las acciones de diálogo de todos los NPC. Debe dar 0 "SCRIPT ERROR".
timeout 80 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/dialogue_coverage.gd > /tmp/c.log 2>&1; grep 'COVERAGE DONE' /tmp/c.log; grep -c 'SCRIPT ERROR' /tmp/c.log
```

- **Un fallo intermitente conocido** en `verify_all.gd` (sección "reporte de cadáveres", "witness must transition to Phase 2"):
  salía a veces porque un guardia en patrulla pasaba cerca de la testigo. Se mitigó apartando a otros NPC en el test.
  Si vuelve a salir, repite 2–3 veces antes de investigar; si falla de forma consistente, es real.
- **Lanza los tests de uno en uno** (no en paralelo) y **no uses `pkill -f` con un patrón que aparezca en tu propio comando** (te mata a ti mismo).
- Las pruebas de comportamiento largas conviene ejecutarlas en segundo plano con `timeout`.
- Los avisos amarillos de Godot (panel de errores) solo los ve el usuario en el editor. Pídele captura con **archivo y línea**.

## 4. Convenciones de código y trampas aprendidas

- Indentación con **tabs**. Los archivos `.gd` se guardan con saltos de línea mixtos según `.gitattributes (* text=auto)`.
  Si editas con Python, abre con `newline=''` y conserva el salto de línea que ya tenga el archivo.
- **`class_name` nuevo + caché**: un `class_name` recién creado no se registra hasta que el editor reindexa; en tests headless da
  "Identifier not declared". Solución usada: **`const X = preload("res://...")`** en vez de `class_name` para scripts nuevos
  (ejemplos: `SkillCatalog`, `NPCData`, `NPCDialogue`).
- **`obj.get("metodo")` no llama a métodos.** Para métodos usa `obj.call("metodo")`. Para propiedades `obj.get("propiedad")` está bien.
  Ejemplo de error real: `dm.get("is_active")` (es un método) → usar `dm.call("is_active")`.
- Los autoloads (`WorldClock`, `GameManager`) **no existen** en `--check-only`; no uses `--check-only` para validar scripts que los usen.
  Valida ejecutando los tests.
- En scripts de test `extends SceneTree`: asigna `current_scene = main_inst` justo antes de usar código que busca `UI/UIRoot` desde la escena actual.
- En `tools/tests/verify_all.gd`: NO uses `WorldClock` como identificador directo (usa `wc_speed = root.get_node_or_null("/root/WorldClock")`) ni `VillageNPC.ActivityState.*` (usa los enteros `0`=WORKING, `1`=EATING, `2`=SLEEPING, `3`=SOCIALIZING) para evitar recargas circulares de `VillageNPC.gd` en modo headless.
- En `tools/tests/names_check.gd`: la línea 111 comprueba el tamaño exacto de `SocialDialogueData.ALL_ACTIONS.size()` (actualmente `11`); actualízalo si añades nuevas acciones sociales.
- En `VillageManager.gd` y `CampSite.gd`: cualquier `TextureRect` de muro o suelo debe llevar `expand_mode = TextureRect.EXPAND_IGNORE_SIZE` para que las texturas de 128 px no sobresalgan de los tramos cortos.
- Los Nodos NPC se identifican por `get_person_key()` (`person_profile.person_id`).
- Modelos `.obj` nuevos: borra las líneas `Ka` de su `.mtl` (`sed -i '/^Ka /d'`) o el editor saca un aviso «Ambient light … ignored in PBR» por material.
- `VillageNPC.gd` (~4.150 líneas) sigue siendo grande. Intentos de partirlo más: ver nota en sección 6.

## 5. Mapa del código (lo imprescindible)

| Archivo | Rol |
|---|---|
| `scripts/enemies/VillageNPC.gd` | **Aldeano**: estado, necesidades, rutinas, reportes de cadáver, reacciones a inconscientes, relaciones entre vecinos |
| `scripts/enemies/NPCDialogue.gd` | Menús y acciones de diálogo (funciones `static` que reciben `npc`); `VillageNPC` mantiene envoltorios con los mismos nombres |
| `scripts/data/NPCData.gd` | Tablas de datos: alias, perfiles de lore, relaciones iniciales entre vecinos |
| `scripts/systems/VillageManager.gd` | Mundo del pueblo (4.700 líneas): tiendas, puertas, justicia, llegadas de NPC nuevos (`_process_daily_map_edge_arrivals`), guardado |
| `scripts/systems/VillageWorldBuilder.gd` | Construcción inicial del pueblo (caminos, edificios y mobiliario) |
| `scripts/systems/VillageLots.gd` | Solares (V4): dónde se puede construir, obras del carpintero, casas nuevas y sus camas |
| `scripts/systems/VillageSocialLife.gd` | Quedadas, peleas en vivo y chismes aplicados al mundo |
| `scripts/systems/VillageJustice.gd` | Investigaciones del Comisario y del Inquisidor, interrogatorios, veredictos y juicio público |
| `scripts/systems/SkillCatalog.gd` | Catálogo de habilidades (datos) |
| `scripts/Player.gd` | Jugador; habilidades (`add_skill_xp`, `get_skill_level`, `get_skill_bonus`), guardado |
| `scripts/ui/SocialGlossaryUI.gd` | Glosario social `[J]` (nodos reutilizados, relleno repartido en frames) |
| `scripts/ui/SkillsPanelUI.gd` | Panel de habilidades `[K]` |
| `scenes/ui_root.gd` | Registra paneles y teclas (I, H, M, J, K, Tab, Esc) |
| `scenes/dialogue_manager.gd` | Rueda de diálogo |
| `scripts/systems/SocialDirector.gd` | Director Social: diales, medidas por par, romance, quedadas, peleas e influencia del jugador |
| `tools/tests/` | `verify_all.gd`, `names_check.gd`, `social_sim.gd`, `dialogue_coverage.gd` |

Otros documentos antiguos en la raíz: `ROADMAP_PROYECTO.md`, `AUDIT_LOG.md`, `SESSION_CONTEXT_LOG.md` (contexto histórico).

## 6. Hallazgos y riesgos relevantes para la vida social

1. **Los vecinos nuevos se crean en 5 sitios distintos** de `VillageManager.gd`: reemplazo de autoridades (`_spawn_authority_replacement`),
   posadera nueva, artesano nuevo, viajeros (`_process_daily_map_edge_arrivals`) y `spawn_dynamic_npc_from_save`. No hay un paso común.
2. **Las listas de nombres son de 5 elementos y rotan con `_rehire_counter`** → se repetirán. Las relaciones están indexadas **por nombre**
   (`npc_relationships`, `npc_relationship_notes` en `VillageNPC.gd`), así que nombres repetidos mezclarían relaciones y un recién llegado
   podría heredar las de un muerto. **Prioridad máxima del Bloque 0.**
3. Los **rasgos** (`traits`) hoy salen del **oficio** (`ROLE_PSYCHOLOGY`) o de un pool de 7; no son por persona.
4. Los sprites, retratos y animaciones de los 20 NPCs (`assests/world/village/npcs_64/` y `villager_*.png`), así como todos los suelos, muros, puertas, ventanas, camas, cofres, pozos y mobiliario (`assests/world/village/`), utilizan exclusivamente los assets comprados del usuario en `assests/Comprados/Epic RPG World - The Village V2.1` y `Epic RPG World - Village(interiors) V1.3` (no generar texturas procedurales propias).
5. Reparto actual: **6 mujeres / 11 hombres** entre los 17 vecinos residentes (visitantes aparte). Solo heterosexuales por ahora.
6. Partir `VillageNPC.gd` más allá de lo hecho es arriesgado (funciones muy entrelazadas con decenas de variables). El usuario aceptó parar ahí.
   Si hace falta, extraer módulos nuevos **como clases aparte con `npc` tipado** (técnica usada en `NPCDialogue.gd`) y comprobar con `dialogue_coverage.gd`.
7. Aviso: `get_nodes_in_group("village_npcs")` se llama en ~50 sitios. Con ~17 NPC es aceptable; cuida el rendimiento al añadir sistemas.

## 7. Estado y siguiente bloque

- [x] **Asaltos físicos (Claude Code, 2026-11-05)**: a `RAID_ATTACK_HOUR` `VillageCulture.spawn_raid_attackers` crea un
  `RaidController` (grupo `raid_controller`) que crea `Raider` (grupo `raiders`, Hurtbox capa 4) en `SPAWN_POS`
  (1760, 50). Los defensores (`raid_defenders`) persiguen al más cercano (`errand_pos`) y le pegan a ≤24 px. Resultado:
  todos caídos/huidos → `resolve_raid(..., 1)`; uno en la plaza → `-1`; 23:00 → se retiran. Bandido 3D = `BanditModel3D`
  (CharacterRig3D con capucha y espada); jabalí = lobo. `culture_lead_defense` ya no resuelve.
- [x] **Letreros del mapa (Claude Code, 2026-11-05)**: todo `_add_title_label` entra en el grupo `world_title_label`;
  `VillageManager._declutter_title_labels` (cada 0,25 s) deja ver solo los que están a ≤`TITLE_SHOW_RADIUS` (150 px)
  del jugador o bajo el ratón y, si se pisan (por el ancho real del texto), el más cercano. Usa `modulate.a`, no `visible`.
- [x] **Ficha de vecino al pasar el ratón (Claude Code, 2026-11-05)**: `VillageNPC._update_hover_label` solo la
  enseña el dueño de `static var _hover_owner` (el más cercano al ratón, ≤22 px), corta; con Alt la completa. Ya no
  sale por cercanía al jugador. Los letreros de sigilo y aturdido siguen igual.
- [x] **Selector de E (Claude Code, 2026-11-05)**: `scripts/ui/InteractionSelector.gd` (hijo del jugador). Junta las
  Area2D «interactable» que solapan con el `InteractArea` del jugador, las ordena por distancia, elige la que está bajo
  el ratón (≤16 px, si el ratón está a ≤55 px del jugador) o la elegida con Mayús+rueda / G, y pinta «[E] …».
  `Player._handle_interactions` llama primero a `use_selected()`; si no hay nada, sigue el camino antiguo.
  Estaciones de VillageManager (meta `village_station`): puerta, ventana, cofre y mostrador se usan directamente; el
  resto pasa por `vm.interact`. Para un letrero propio, añade `get_interact_label(player)` al nodo.
- [x] **Caballo físico (Claude Code, 2026-11-05)**: `scripts/obstacles/PlayerHorse.gd` (grupo `player_horse`, Area2D
  «interactable» → `interact` monta/desmonta). `VillageCulture.sync_player_horse(vm)` lo crea/recoloca desde
  `mounts_state` (`pos_x`, `pos_y`, `is_mounted`) al comprar y en `after_load`; sin caballo lo borra. `Player.is_mounted`;
  `PlayerMovementController.MOUNT_SPEED_MULT`=1.45 solo montado y bloquea C. Ya no existe `mount_speed_mult`.
  Jinete: `CharacterAvatar3D.MOUNT_SEAT_PX` y `AnimState.MOUNTED` («sit»), mirando con `horse.get_facing_2d()`.
  2D provisional: sprite del ciervo teñido. Capturas: `tools/screenshot_3d.gd` sitios `caballo,montado`.
- [x] **Impuesto sobre la renta (Claude Code, 2026-11-05)**: `personal_gold` de VillageNPC tiene un setter que suma
  cada subida a `income_week` (solo si `_track_income`; se activa en `VillageTown.daily` al día siguiente de llegar; se
  guarda en la partida). El sábado `collect_taxes` cobra `income_tax_for(income_week)` (tramos `INCOME_*`) y pone
  `income_week = 0`. Ya no hay impuesto sobre los ahorros; la caja de los negocios sigue pagando `SHOP_TAX`.
  OJO: cualquier `personal_gold = x` mayor que el actual cuenta como ingreso (también robos y préstamos).
- [x] **Ingresos de las arcas (Claude Code, 2026-11-05)**: puestos del mercado pagan `MARKET_STALL_FEE`=4; cada
  intercambio de ruta (y remesa del jugador) paga `ROUTE_TOWN_TARIFF`=4 del fondo de la ruta a las arcas; el comprador
  paga 1/unidad importada al fondo; el fondo de cada ruta se repone +20 cada lunes hasta 90 (excepción consciente a la
  suma cero: es oro del exterior, aprobado por el usuario como «dinero que viene de fuera»).
- [x] **Auditoría 2026-11-05, Regla 1 (Claude Code)**: los 22 puntos de oro mágico cerrados. Ayudas nuevas en
  VillageManager: `pay_into(npc, oro)` (al vecino vivo o a las arcas), `take_from_treasury(oro)` (nunca deja negativo),
  `role_npc(oficio)`, `_find_paying_customer(precio, excluir)`, `_take_family_savings(familia, oro)`. Úsalas en código
  nuevo. Ventas diarias de negocios del jugador: sin «ganancia base»; cada unidad la paga un vecino.
- [x] **Auditoría 2026-11-05, bugs (Claude Code)**: ver `docs/REGISTRO_TRABAJO.md` bloque AUD. Tecla 2D/3D = **F10**
  (F9 = cargar). `VillageUnderworld.is_player_in_sewers(vm)` distingue alcantarillas (current_loc) del sótano propio.
  `Player.is_carrying_lantern` (getter por hora 20–6). Farolas: `is_lamps_powered(vm) and (noche or red)`.
- [x] **Jabalí = lobo animado provisional (Claude Code, 2026-11-05)**: `SpeciesType.BOAR` usa
  `animals/animated/Wolf.glb` (Quaternius, CC0). Solo visual. Los zips del usuario en `assests/Assets 3d/` (Bird, Deer,
  Fox, Roe, Squirrel, Wolf: FBX con textura, origen y licencia sin confirmar) NO traen animaciones (4 con esqueleto
  sin clips, ardilla y pájaro sin esqueleto): no se usan. Conejo y gato siguen en 2D.
- [x] **Animales 3D animados (Claude Code, 2026-11-05)**: ciervo, zorro y perro usan `animals/animated/*.glb`
  (Quaternius Ultimate Animated Animals, CC0, bajados de poly.pizza porque Google Drive daba «cuota superada»).
  `AnimalModel3D` busca el `AnimationPlayer`: Walk/Gallop según la velocidad suavizada (umbrales `walk_px_s`,
  `run_px_s`), Idle/Eating parado, Death al tumbarse el sprite (si ya estaba tumbado al entrar en cámara, salta al final).
  El AnimationPlayer se apaga fuera de cámara. Los .obj quietos quedan como alternativa (se tumban de lado).
- [x] **Animales 3D, paso 1 (Claude Code, 2026-11-05)** (`scripts/visuals/AnimalModel3D.gd`, se engancha en
  `WildAnimal.setup_animal` y en el sprite de `DomesticPet`): modelo OBJ quieto en `Characters3D` del escenario para
  ciervo (`Deer.obj`), zorro (`Fox.obj`) y perro (`ShibaInu.obj`); sigue la posición, gira hacia el movimiento, se
  tumba si el sprite 2D está rotado >45°, esconde el sprite con `self_modulate.a` y se oculta fuera de cámara. No hace
  nada en headless. Faltan modelos de conejo, jabalí, gato y gallina. Vacas y caballos no existen como entidades.
  Capturas: `tools/screenshot_3d.gd` con sitios `ciervo,zorro,perro`.
- [x] **Edificios: mallas quietas juntadas (Claude Code, 2026-11-06)** (`WorldStage3D._merge_building_meshes` al final
  de `rebuild_buildings_3d`, solo con ventana: `SurfaceTool.append_from` por material + formato + sombra en cada
  `B3D_*`, y aparte en `roof_cap` y `loft_root`; excluye puertas, ventanas, postigos, morgue y reja; deja los nodos con
  `mesh = null`). Mallas dibujadas 2.317 → 1.409, llamadas de dibujo ~1.230 → ~1.100, fps casi igual. Medido antes:
  proceso ~25–30 ms y física ~16 ms por fotograma (vecinos quietos → física 4 ms). El cuello de botella es la CPU
  (lógica y movimiento de los vecinos), no la tarjeta. Siguiente: medir qué parte del vecino cuesta y abaratarla SIN
  cambiar su comportamiento (el usuario no quiere simulación «a ratos»).

- [x] **Rendimiento: lotes de árboles y rocas + casas iniciales en barrios (Claude Code, 2026-11-06)**
  (`WorldStage3D.gd`: `_absorb_into_batches` pasa las mallas sin material propio de `_make_nature_3d` a un
  MultiMeshInstance3D por malla y zona de `BATCH_CHUNK_PX`; `_set_vis3d` + `_flush_batches` sustituyen a `.visible`
  (talar/roca agotada escala la copia a cero). `seed_start_population`: una de cada dos casas con `remote = true`.)
  Medido en Intel UHD 620 a 3072×1728: 2.317 mallas 3D, de ellas Buildings3D 1.481, Characters3D 362, Nature3D 199,
  Terrain3D 157 → el siguiente candidato es juntar piezas quietas de los edificios (muebles, muros, suelos). El usuario
  NO quiere que los vecinos lejanos se simulen a ratos.

- [x] **Arranque con 40 vecinos, PROVISIONAL (Claude Code, 2026-11-06)** (`VillageMigration.gd`: `START_POPULATION = 40`
  (0 = arranque normal), `seed_start_population` levanta casas al instante con `VillageLots.build_instant_house` cuando
  quedan menos de 2 camas libres y llama a `try_arrival(vm, true)` (sin avisos) poniendo `arrivals_today_count = 0` en
  cada vuelta. Se llama en `setup_village` solo si no es editor ni headless: las pruebas siguen con los 18 de siempre.
  Al cargar partida, GameManager borra los NPC_Traveler_ y los restaura del guardado (sin duplicados). Sonda: 43
  vecinos (las familias traen hijos), 8 casas nuevas, ~27 fps frente a ~31 fps con 18.

- [x] **Ampliar la aldea, paso 2 (Claude Code, 2026-11-06)** (`VillageLots.gd`: `CURVED_ROADS`, `street_wave`,
  `curved_road_points`, `lot_shift` (fijo por id; n: hacia atrás, m/u: siguen la curva), `lot_def` devuelve el centro
  desplazado con caché `_def_cache` (`reset_layout` al montar el pueblo); ROADS sin las rectas de m y u; lotes u3 y e1
  quitados → `GAP_POCKETS` (pozo funcional en `_well_positions` + cartel en `vm._extra_station_labels`; huerto de
  adorno con sprites soil_dry). Usos directos de `l["center"]` cambiados a `lot_def(id)` (free_house_bed, Housing,
  ValleyMapUI, WorldStage3D). 3D: tramos girados por segmento. Test PQ.1b sin u3. El usuario confirmó que no hay
  partidas guardadas: no hay compatibilidad con partidas antiguas de este cambio.

- [x] **Casa mejorada del jugador y gallinero en 3D (Claude Code, 2026-11-06)** (`WorldStage3D.gd`:
  `_sync_player_house_3d` copia la planta de `CampSite._rebuild_house_visuals`, se rehace al cambiar `house_tier` y su
  tejado se abre en `_update_roof_cutaways_and_lighting`; `_sync_coop_3d` + `_build_fence_run_3d`, tramo sur central
  ligado a `is_breached`; tipos "feeder"/"nest" por imagen; `_extra_hidden_2d` esconde suelos, muros y cercas 2D y
  `_sync_2d_flat_visuals` los devuelve con F9). `tools/screenshot_3d.gd`: sitio «casa_jugador». Gallinas aún 2D.

- [x] **Precio por tamaño de casa (Claude Code, 2026-11-06)**: `HOUSE_PLOTS[*].cost` (80/100/140) y
  `VillageLots.house_cost(id)`; `request_build` cobra eso para "house". `maybe_order_house` decide la riqueza por
  ahorros (≥ coste casona + 20 → rich; ≥ casa + 20 → mid) antes de elegir solar. `VillageHousing`: contado, hipoteca,
  cartel, opción del carpintero y `house_sale_price` usan `house_cost`; `HOUSE_CASH_COST` queda como precio de la casa
  mediana. Test 5.22a ajustado (n0 es casita: compara con la base de su tamaño).

- [x] **Ampliar la aldea, pasos 1 y 3 (Claude Code, 2026-11-06)** (`VillageLots.gd`: `plot` en LOTS, `HOUSE_PLOTS`,
  `plot_of`, `pick_house_lot(vm, wealth, remote)`, zona `"barrio"` con lotes l1–l4, c1–c3, o1–o2, ROADS nuevas,
  `EAST_MILL_POS`; `VillageMigration.maybe_order_house` elige por riqueza y sociabilidad ≤ -0.3; Mayor y Housing usan
  `pick_house_lot`; `VillageHousing.try_interact` acepta zona barrio; `WorldStage3D._build_barrios_3d`: molino,
  leñeros, embarcadero). Casona = 3 camas, mismo coste. El terreno de los solares del borde no cambia. Sonda de
  andar: 6 vecinos llegaron a su cama en l1, l4, c2, c3, o1 y o2. Arreglado `_sync_props_3d`/`_sync_nature_3d`:
  asignar a variable tipada un nodo ya liberado daba SCRIPT ERROR (cartel de solar al construirse).
  `tools/screenshot_3d.gd`: sitios barrio_lago, caserios, molino. Pendiente: paso 2 (romper filas) y paso 4.

- [x] **Niebla nocturna (Claude Code, 2026-11-06)** (`shaders/retro_post_fx.gdshader`: `vnoise`, uniformes `player_px`,
  `world_origin_px`, `px_per_world`, `fog_clear`/`fog_full`/`fog_max`/`fog_color`; `RetroPostFX.gd` los rellena cada
  fotograma). Distancia al jugador en px del mundo; ruido anclado al mundo; `lit` la aclara y la tiñe. Entra con
  `smoothstep(0.35, 1.0, night)`. Solo visual (no toca la percepción de los NPC). No existe en headless.

- [x] **Objetos quietos 2D → 3D (Claude Code, 2026-11-06)** (`WorldStage3D.gd`: `PROP_KIND_BY_TEXTURE`, `_scan_props_sources`,
  `_sync_props_3d`, `_build_prop_3d`, `_build_crop_3d`; `tools/screenshot_3d.gd` sitio «campamento»). Reconoce el dibujo
  por el nombre de su imagen (hijos de `entities_root`, `CampSite` salvo `PlayerHouseRoot`, `FarmPlot`); "hide" = ya tiene
  3D propio (tablón, farolas). Se reconstruye si cambia la imagen (tierra seca/mojada, fase del cultivo). Los pozos
  fijos de `_build_static_terrain_3d` se quitaron. `_sync_2d_flat_visuals(false)` devuelve el alfa a pinos, rocas y
  objetos al pasar a 2D. Solo corre con ventana (en headless `_process` sale antes). Pendiente: casa mejorada del
  jugador y gallinero.

**Estado del código:** vida social completa (Fases 0 a 6) y subida a `main`; los cuatro tests pasan. Refuerzo del código (R1–R5) terminado. M1 (móvil social en investigaciones), Q1 (panel de misiones) Q1–Q4 hechos (5 tipos de misión, con estructura lista para muchos más). T1, T3 y T4 (rasgos: catálogo, descubrimiento y efectos) hechos. T2 hecho: 140 rasgos (`docs/RASGOS_BORRADOR.md`). Misiones: 25 tipos hechos (`docs/MISIONES.md`, bloque M). Historial en `CHANGELOG.md`.

**Bloques P1–P7 auditados (2026-11-04):** ver `docs/AUDITORIA_P1_P7.md`. [x] PA: arreglados los puntos 1 (el misterio
no se destripa) y 2 (oro infinito). [x] PB: arreglados los puntos 3–7 y los fallos medios (queda solo el riesgo bajo de
cambiar nombres a niños). [x] PD: revisadas las 29 mecánicas de PC (2 errores, 2 destripes y 6 fuentes de oro
fácil arreglados; ver REGISTRO_TRABAJO). Regla nueva: **pulsar E nunca compra ni decide nada de golpe** (la primera E avisa, la segunda
confirma). Regla nueva para cualquier
mecánica: **ninguna opción de menú puede nombrar a un culpable que el jugador aún no ha averiguado, y ningún oro se crea
de la nada** (sale del bolsillo de alguien o de una caja).

### Bloques del sistema de Vida Social (marca [x] al terminar y commitea)

**Fase 0 — Cimientos**
- [x] **B0.1** HECHO. `scripts/data/NPCNames.gd`: 200 nombres femeninos, 200 masculinos y 200 apellidos (variedad latina/europea/americana). API: `pick_first_name(gender, rng, used_names)`, `pick_surname(rng)`, `make_person_name(gender, rng, used_names)`; género `"F"`/`"M"`; reproducible con semilla. Test: `tools/tests/names_check.gd`. Aún NO está conectado al juego (eso es B0.3).
- [x] **B0.2** HECHO. `scripts/data/PersonProfile.gd` (`person_id`, `gender`, `orientation`, `age`, `personality` de 3 rasgos, `likes`/`dislikes`, `favorite_item`, `romance_status`, `partner_id`) y tabla `INITIAL_PERSON_PROFILES` en `scripts/data/NPCData.gd` para los 17 vecinos (6 F / 11 M) + 3 visitantes. Conectado en `VillageNPC._init_person_profile()`. Lore de Lina y Tomás ajustado a hermanos de hogar/taller.
- [x] **B0.3** HECHO. Generador `PersonProfile.generate_newcomer(...)` (nombre y `person_id` únicos, género equilibrado según vivos, edad y gustos por oficio, 3 rasgos sin opuestos, reproducible con semilla) y unificación de los 5 puntos de creación de vecinos nuevos en `VillageManager._spawn_generated_newcomer(...)`.
- [x] **B0.4** HECHO. Relaciones (`npc_relationships` y `npc_relationship_notes`) migradas a claves únicas (`person_id`), migración automática de claves antiguas por nombre (`_migrate_legacy_relationship_keys`), limpieza al morir (`purge_deceased_relationship`) y bloqueo de fallecidos en `ensure_npc_relationships_initialized`.
- [x] **B0.5** HECHO. Guardado y carga de `person_profile`, `npc_id`, relaciones por `person_id` y registros del generador (`used_first_names`, `used_person_ids`, `newcomer_rng_state`), con fallback y migración automática para partidas antiguas.
- [x] **B0.6** HECHO. Registro de eventos sociales (`social_event_log` con tope `MAX_SOCIAL_EVENT_LOG = 80`, `record_social_event` y `get_recent_social_events`) en `VillageManager.gd`, conectado a llegadas, reconciliaciones y rupturas de amistad, y persistido en guardado/carga.
- [x] **B0.7** HECHO. Esqueleto de `scripts/systems/SocialDirector.gd` con tabla única `DIALS` (`max_concurrent_scenes = 3`), 4 medidas por par (`affinity`, `familiarity`, `spark`, `tension`), enfriamiento diario sin contacto, cálculo de compatibilidad y conexión con `VillageManager` y guardado/carga.
- [x] **B0.8** HECHO. Pareja inicial **Elena y el Dr. Valen** (`romance_status = "partnered"`, `partner_id` cruzado, relación `+78`, etapa `"couple"` en `SocialDirector`), paso automático a viudo/a (`"widowed"`) si muere la pareja y visualización en el Glosario Social `[J]`.
- [x] **B0.9** HECHO. Simulador headless de 60 días (`tools/tests/social_sim.gd`) y paso diario `SocialDirector.simulate_social_day(...)`, calibrado sobre 5 semillas + reemplazos procedurales cumpliendo todas las metas (1–3 parejas nuevas, 2–6 peleas con máx. 2 por par, 0 vecinos sin amigos y ~77% de relaciones entre −20 y +40).

**Fase 1 — Conversaciones con frases**
- [x] **B1.1** HECHO. Catálogo procedural `scripts/data/SocialDialogueData.gd` con 8 tipos de acciones sociales (`small_talk`, `shared_taste`, `compliment`, `vent`, `joke`, `friction`, `taste_clash`, `apology`), etiquetas naturales para los 16 gustos y generador de intercambios de 2 turnos (`build_exchange`) adaptado a rasgos y gustos. Verificado en `tools/tests/names_check.gd`.
- [x] **B1.2** HECHO. Selección y resolución de conversaciones en vivo (`resolve_live_conversation`) en `SocialDirector.gd`, actualizando las 4 métricas del par (`affinity`, `familiarity`, `spark`, `tension`), relación vecinal y memoria corta respetando `max_concurrent_scenes = 3`. Verificado en `tools/tests/names_check.gd`.
- [x] **B1.3** HECHO. Escena en vivo de 2 turnos en `VillageNPC.gd` (burbuja de apertura de A → respuesta diferida ~1.8 s de B con actualización de relación y nota) y test automático #21 en `tools/tests/verify_all.gd`.

**Fase 2 — Pasar tiempo juntos**
- [x] **B2.1** HECHO. Lógica de quedadas en `SocialDirector.gd` (sin física): `is_social_hour` (12h y 18-21h), `should_avoid`/`get_avoid_ids` (rivales: afinidad ≤ −25 o tensión ≥ 30), `get_hangout_score`, `pick_hangout_partner` (ponderado, solo amigos/chispa/coqueteo, libres y con cupo de 1 quedada/día), `pick_shared_hangout_spot` (spots `{id,pos,kind}` del mundo: taberna por la tarde, plaza/pozo de día, banco/fogata para parejas; penaliza distancia y descarta ocupados), `start_hangout`/`try_plan_hangout`, `mark_hangout_arrival` (viaje → juntos), caducidad por viaje (60 s), bono suave al completar (45 s juntos) y `pop_finished_hangouts()`. Máx. 2 quedadas simultáneas; cupo diario guardado en partida. Diales en `DIALS`. Verificado en `tools/tests/names_check.gd`.
- [x] **B2.2** HECHO. Ejecución física: `VillageManager._update_social_hangouts()` (cada 5–8 s en hora social elige a un vecino que esté socializando, sincroniza afinidades reales y pide `try_plan_hangout`; puntos: Taberna, Pozo de la Plaza, Plaza Central, Pozo de la Granja vía `get_hangout_spots()`), seguimiento de llegadas, cancelación si alguien se duerme/ataca/cambia de actividad, y al completar: `modify_npc_relationship`, pensamiento de humor +6, +20 social, burbuja "☕ Buen rato" y evento `hangout` en el registro social. En `VillageNPC.gd`: `assign_hangout`/`clear_hangout`/`get_person_key`, objetivo social = punto de encuentro (cada uno a un lado), no abandona la quedada por social lleno, descripción "🚶 Ha quedado con…" / "☕ Pasando el rato con…", y `_find_best_social_partner` ignora rivales (`should_avoid`) y a quien ya está en una quedada. Test #22 en `verify_all.gd`.

**Fase 3 — Parejas**
- [x] **B3.1** HECHO. Etapas en vivo en `SocialDirector.advance_live_romance_day()` (Interés 14 → Coqueteo 28 → Citas 44 → Pareja 60 de chispa + afinidad ≥ 24), solo si hubo contacto hoy/ayer, ambos solteros, distinta familia y compatibilidad ≥ 40; probabilidad diaria `live_stage_advance_chance` × compat/50, sin plazos. Cortejo que se apaga si la chispa < 8. Tope diario de chispa por par (`spark_daily_gain_cap = 10`) en charlas y quedadas. `VillageManager._advance_live_romances()` (al pasar el día): fichas cruzadas, relación ≥ 68, pensamientos, burbuja 💑 y eventos `couple` / `romance_*` / `romance_fizzle`. Glosario `[J]` muestra "💘 Coqueteo con X" y la etapa en cada fila. Tests en `names_check.gd` y #23 en `verify_all.gd`. (La simulación de 60 días aún usa su propio paso; se recalibra en B3.5.)
- [x] **B3.2** HECHO. Comportamiento por etapa en `SocialDialogueData.gd` (`ACTION_FLIRT` 💘 y `ACTION_AFFECTION` 💑), selección en `SocialDirector.resolve_live_conversation()` y mayor peso de quedadas para etapas románticas, preferencia de compañero romántico y descripciones (`💑 Pasando la tarde con…` / `💞 En una cita con…`) en `VillageNPC.gd`, y citas/tardes en pareja con evento `date` en `VillageManager.gd`. Verificado en `names_check.gd` y Test #24 en `verify_all.gd`.
- [x] **B3.3** HECHO. Celos (`ACTION_JEALOUSY` 💢💔 en `SocialDialogueData.gd` y `trigger_jealousy_if_any()` en `SocialDirector.gd` cuando alguien con pareja queda con un tercero compatible), rupturas (`stage` vuelve a `"none"`, `ex_couple = true`, ambos vuelven a `"single"` con evento `breakup`) y reconciliación de ex-parejas (`couple_reconciled`) en `SocialDirector.advance_live_romance_day()` y `VillageManager.gd`. Verificado en `names_check.gd` y Test #25 en `verify_all.gd`.
- [x] **B3.4** HECHO. Duelo y viudedad mejorados: `bereavement_days_left` (5 días) y `deceased_partner_name` en `PersonProfile.gd`, pensamiento diario de luto y fin de duelo (`bereavement_ended`) en `VillageManager._advance_live_romances()`, visitas al Cementerio Parroquial (`get_grave_pos_for_victim`, `is_visiting_grave`, `"🪦 Visitando la tumba de X"`, `"🕯️ «No te olvido, X...»"`) en `VillageNPC.gd`, y estado en Glosario `[J]`. Verificado en `names_check.gd` y Test #26 en `verify_all.gd`.
- [x] **B3.5** HECHO. Unificado `SocialDirector.simulate_social_day()` con `_add_spark_capped()` y `advance_live_romance_day()`, y recalibrado `tools/tests/social_sim.gd` (60 días en 5 semillas + reemplazos procedurales cumpliendo todas las metas).


**Fase 4 — Peleas discretas por dados**
- [x] **B4.1** HECHO. Resolución por dados en `SocialDirector.gd` (`compute_fight_power`, `can_pair_fight`, `try_resolve_live_fight` con poder ponderado por oficio, edad, salud y personalidad; tirada interna con ganador/perdedor, alivio de tensión, caída de relación y respeto a `drama_cooldown_days` y `max_fights_per_pair = 2`). Verificado en `names_check.gd`.
- [x] **B4.2** HECHO. Peleas en vivo: `VillageManager._update_live_fights()` busca cada 3,5–6 s pares con tensión ≥ `live_fight_tension_threshold` (28) a ≤ 72 px y lanza `try_resolve_live_fight` (una tirada por par y día). Escena de 3,5 s en `VillageNPC.gd` (temblor y "💢"), moratón con `HealthComponent.apply_minor_bruise()` (sin órganos, fracturas ni sangrado; suelo del 35 %), relación −14, pensamientos y hasta 3 testigos a ≤ 110 px, evento `fight`. Un guardia a ≤ 140 px los separa a los 1,6 s, sin herida. Test #27 en `verify_all.gd`. Peleas raras: enemistad con relación ≤ −30 (`rival_friction_max_rel`), 10 días distintos de roce al cruzarse (`live_fight_min_enmity_days`), 15 % diario (`live_fight_daily_chance`) y 12 días entre peleas del pueblo (`live_fight_cooldown_days`). Medido en el juego real sin pantalla, una partida de 60 días.

**Fase 5 — Tu papel** (reglas: un solo vecino influido por día, efectos pequeños; hablar mal no fabrica peleas, siguen haciendo falta los 10 días de roce)
- [x] **B5.1** HECHO. Observador: menú "🗣️ Preguntar qué opina de los vecinos" (`NPCDialogue._add_neighbor_opinions`, 6 vecinos con sentimiento más fuerte; el motivo solo con afinidad ≥ 35 o Carisma ≥ 2; con afinidad < 0 no cuenta nada) y escucha a escondidas (`VillageNPC._try_player_overhear`: en sigilo a ≤ 96 px, +12 px por nivel de Sigilo, +3 XP). Test #28 en `verify_all.gd`.
- [x] **B5.2** HECHO. Desde la opinión sobre un vecino: "👍 Hablar bien" / "👎 Hablar mal" (`NPCDialogue._player_gossip`, `SocialDirector.resolve_player_gossip`). Una sola influencia al día (`player_influence_day`, guardado). Probabilidad por Carisma y afinidad, −20 % si contradice lo que el vecino siente. Éxito: relación ±4–8 entre ambos, tensión ±3, evento `player_gossip`, +4 XP. Fallo: −6 afinidad con el oyente (−4 con el aludido si hablabas mal), +1 XP. Test #29 en `verify_all.gd`.
- [x] **B5.3** HECHO. Mediador: "🕊️ Pedirle que haga las paces" si la relación es ≤ −15 (gasta la influencia del día; `resolve_player_mediation`: relación +4–8, tensión −11, enemistad −4 días, evento `player_mediation`). "✋ Separar" al hablar con un vecino en plena pelea (`player_stop_live_fight`, sin heridas, +3 afinidad, +5 XP; la pelea espera mientras el diálogo está abierto). Test #30 en `verify_all.gd`; la espera con diálogo abierto no tiene test automático.
- [x] **B5.4** HECHO. Casamentero: "💘 Animarle a acercarse" si ambos están solteros y son compatibles (`can_matchmake`, `resolve_player_matchmaking`): gasta la influencia del día, suma chispa 6–10 con tope diario, relación +4–8 y evento `player_matchmaking`; no salta etapas. Solo se ofrece para los 6 vecinos que aparecen en el menú de opiniones. Test #31 en `verify_all.gd`.

**Fase 6 — Chismes y pulido** (regla: los chismes son información y no mueven relaciones entre vecinos)
- [x] **B6.1** HECHO. Eventos de `GOSSIP_EVENT_TYPES` con `known_by` en `social_event_log` (se guarda con la partida). Al acabar una conversación, 50 % de que se cuente la novedad más reciente que el otro ignora (`spread_gossip`, máximo 10 días de antigüedad). "🗞️ Preguntar si hay alguna novedad" en el diálogo. `player_slander`: al enterarse el aludido, −5 de afinidad con el jugador. Test #32 en `verify_all.gd`.
- [x] **B6.2** HECHO. "🗞️ NOTICIAS DEL PUEBLO" en el tablón de la plaza (`get_public_news`): hasta 4 novedades que conozcan al menos 3 vecinos, sin comentarios del jugador. Las muertes no se publican, para no estropear la investigación de crímenes.
- [x] **B6.3** HECHO, sin cambiar valores en este bloque. Dos partidas reales de 60 días, sin pantalla y sin jugador activo (semillas 101 y 202): 4 peleas, 3 parejas nuevas, 17 vivos, 0 aislados, 68–69 % de relaciones entre −20 y +40, noticias 30–35 días en cada partida. Sin errores. Solo 4–8 quedadas y 1–2 citas completadas por partida (causa y ajuste en B6.4).
- [x] **B6.4** HECHO. Quedadas: en 12 días medidos, 9 de 11 se cancelaban al irse a dormir a las 22h. Ahora duran 22 s (~1,5 h de juego), no se planifican después de las 20:15 y no hay en las 21h. Revisión del código de las Fases 4–6, 9 correcciones: "widowed" fuera de chismes (revelaba muertes), `refund_live_fight`, peleas limpias al cargar, enemistad que se reinicia y exige relación actual ≤ −30, guardia consciente, sin quedadas en plena pelea, testigos y guardia en `known_by`, sin peleas cargando un cadáver, y la influencia del jugador actualiza `pe["affinity"]`.
  Sin medir: la partida de 60 días tras estos cambios se detuvo en el día 16 a petición del usuario, así que el efecto en quedadas y parejas no está comprobado (más quedadas pueden subir las 3 parejas nuevas por partida). Corregido después (2026-11-02): una escolta o emergencia de uno de los luchadores corta la pelea al momento y no cuenta (test #44).
Cada fase se dividirá en bloques pequeños cuando se llegue a ella (detalle en `docs/PLAN_VIDA_SOCIAL.md`).

**Refuerzo del código** (aprobado; mover temas a archivos nuevos dejando llamadas finas, como `NPCDialogue.gd`, sin cambios visibles)
- [x] **R1** HECHO. Test #33 en `verify_all.gd`: ciclo real con `GameManager` de guardar en archivo, cambiar el mundo y cargar (día, medidas por par, Director, relaciones, ficha, salud, delito, oro, chismes y pelea en marcha). No encontró errores; el juego no cambió.
- [x] **R2** HECHO. 16 funciones de construcción (494 líneas) movidas a `scripts/systems/VillageWorldBuilder.gd` (`@tool`, estático, primer parámetro `vm`). Comprobado con una foto de los 2.203 objetos y datos del mundo antes y después: idéntica salvo identificadores internos.
- [x] **R3** HECHO. 13 funciones (308 líneas) de quedadas, peleas y chismes movidas a `scripts/systems/VillageSocialLife.gd`. `VillageManager.gd` conserva llamadas finas con los mismos nombres y el estado (`_live_fights`, temporizadores, constantes). `_advance_live_romances` sigue en `VillageManager.gd`.
- [x] **R4** HECHO. 24 funciones (unas 1.500 líneas) de investigación, interrogatorios, veredictos y juicio movidas a `scripts/systems/VillageJustice.gd`. `VillageManager.gd` conserva llamadas finas con los mismos nombres y el estado de los casos.
- [x] **R5** HECHO. `VillageManager.gd` bajó de 6.911 a unas 4.700 líneas, pero conserva 115 variables. `VillageNPC._physics_process` pasó de 211 a 25 líneas en 8 pasos con nombre (mismo orden, dentro del mismo archivo). Decisión: no partir más `VillageNPC.gd` salvo que un problema concreto lo justifique.

### Vida social conectada con misiones e investigaciones
- [x] **M1** HECHO. Móvil social en `VillageJustice.gd`: al abrir el caso, quien se peleó con la víctima o tiene una enemistad larga con ella (relación ≤ −30 y ≥10 días de roce) suma +10 de sospecha y una pista; las calumnias del jugador sobre la víctima que conocen ≥3 vecinos le dan móvil a él. En el interrogatorio, un testigo que conozca una pelea, enemistad, ruptura o calumnia con la víctima la cuenta (+8). Un solo móvil por sospechoso; nunca decide solo (la coartada sigue mandando). Test #34.
- [x] **M2** Sustituido por las misiones personales (bloques Q). El tablón no se toca.
- [x] **Q1** HECHO. Autoload `QuestManager` (`scripts/systems/QuestManager.gd`): misiones con categoría `side`/`main` y estado `active`/`completed`/`failed`, notas y `data` libre; se guarda en la partida (clave `quests`). Panel `scripts/ui/QuestLogUI.gd` con la tecla **L** (la J es el glosario), pestañas Secundarias y Principal. `ObjectiveManager` (objetivos antiguos) no se toca. Test #35.
- [x] **Q2** HECHO. `scripts/systems/VillageQuests.gd` (funciones estáticas con `vm`). Cada día (`VillageManager._on_day_passed`), un vecino con enemistad (relación ≤ −30 y ≥5 días de roce o alguna pelea) tiene un 12 % de pedir ayuda; máximo 3 ofertas+misiones de vecinos a la vez; la oferta caduca en 4 días; tras rechazar/cobrar/fallar el vecino espera 10 días. El tipo depende de su carácter: rencoroso → «Ensúciale el nombre» (relación ≤ −40; hablar mal del rival a 2 vecinos distintos), pacífico → «Haz las paces por mí» (mediar con el rival hasta que vea al otro en ≥ −15 o mejore 12). Ofertas y esperas viven en `QuestManager.offers`/`giver_cooldowns` (se guardan). ❗ = nodo `QuestMarker` sobre el vecino. Se acepta, abandona y cobra hablando con quien lo pidió (acciones `quest_*` en `NPCDialogue`). Falla si muere quien la pidió o el rival. Test #36.
- [x] **Q3** HECHO. Tipos 4 y 5 (test #37). «Encuentra a quien lo mató» (`justice`): al construir un caso (`VillageJustice._build_investigation_case_dict`) el vecino más cercano a la víctima (relación ≥ 40) tiene un 60 % de pedirlo, una sola vez por víctima; se resuelve en `VillageManager._mark_morgue_case_resolved`: veredicto contra un vecino → cobrar 40; contra el jugador o archivado → falla. «Averigua qué piensa de mí» (`opinion`): vecino soltero con chispa ≥ 14 hacia otro soltero sin cortejo avanzado; se cumple al abrir la opinión de ese vecino en el menú de opiniones (acción `quest_opinion_seen:<clave>`; el que pidió ayuda sale siempre en la lista); al volver eliges contar la verdad o mentir: una respuesta negativa resta 6 de chispa, nunca la suma. Tipo 3 «¿Quién va contando eso de mí?» (`rumor`, test #38): los vecinos Rencorosos o Chismosos, al acabar una charla sin chisme que contar, tienen un 10 % de hablar mal de su peor rival (relación ≤ −40) a quien tienen delante (evento `npc_slander`, el oyente baja 3 su relación con el rival). Cada evento de chisme guarda `heard_from` (quién se lo contó a cada uno). Si la calumnia llega al afectado por quien la oyó del autor, sabe quién fue (jugador: −5 afinidad; vecino: −6 relación); si llega de segunda mano, no lo sabe y con un 50 % pide la misión. Se pregunta «¿quién te contó…?» a quien lo sabe (`quest_rumor_ask:<id>`); el autor se pone nervioso. Al volver, se señala a alguien de la cadena (−15 de relación del afectado con él, +25 de oro, sea verdad o no) o se confiesa (−10 de afinidad, sin pago). `npc_slander` también cuenta como móvil en M1 y no sale en el tablón.
- [x] **Q4** HECHO. Medición con partidas reales sin jugador (semillas 101 y 202, 39 días; semilla 303, 25 días). Se vio que una oferta caducada se repetía al día siguiente (ahora el vecino espera 10 días) y que los vecinos nunca calumniaban (ahora: 25 % por charla, enemigo ≤ −30, intento independiente del chisme). Tras el ajuste (semilla 303): 7 ofertas en 25 días (5 de paz, 2 de calumnia), máximo 3 a la vez, 1 calumnia entre vecinos, 2 peleas, 76 % de relaciones entre −20 y +40. Además, reorganización para crecer hasta 25+ tipos: base `scripts/systems/quests/QuestType.gd`, un archivo por tipo en `quests/types/` (más `_PLANTILLA.gd`), catálogo `QuestRegistry.gd`; `VillageQuests.gd` solo tiene las reglas comunes. Guía y tabla de tipos en `docs/MISIONES.md`. Test #39 (catálogo).

- Refuerzo: test #43 de guardar en archivo y cargar misiones activas, ofertas (❗), esperas y rasgos descubiertos. No encontró errores.
- Limpieza de 14 avisos amarillos del editor (sin cambiar el juego): parámetros sin usar con `_`, variable `tr` del bucle renombrada a `t_name` (tapaba `tr()`), divisiones enteras explícitas en `SocialDirector.get_pair_entry` (mismo resultado), y `@warning_ignore` en 6 variables de `VillageManager` que Godot creía sin usar pero se usan desde `VillageWorldBuilder`/`VillageSocialLife` como `vm._x`. Ojo: los tests no muestran estos avisos; se comprueban en el editor.
- Revisión del código del día: un fallo real. Al contar de segunda mano una calumnia (`npc_slander`/`player_slander`), el texto flotante y el menú de novedades nombraban al autor. Ahora pasa por `VillageSocialLife.gossip_text(ev, oyente)` (envoltorio en `VillageManager`), que la anonimiza («Andan diciendo cosas feas de X.» / «de ti.»). Test #38 ampliado.

### Rasgos de personalidad (bloques T)
- [x] **T1** HECHO. `scripts/data/TraitCatalog.gd`: los 18 rasgos actuales con descripción y «tendencias» (malice, grudge, gossip, aggression, honesty, trust, diligence, generosity, sociability); la tendencia de un vecino es la suma de sus rasgos. Calumnias entre vecinos: probabilidad por charla = 0,15 × malicia (máx. 45 %; sin malicia, nunca). Sustituye a la regla fija «solo Rencoroso/Chismoso al 25 %». Test #40.
- [x] **T2** HECHO. `TraitCatalog.TRAITS`: 140 rasgos aprobados (118 en 51 ejes + 22 sueltos, 17 raros), cada uno con `axis`, `tone` (k/n/h), `rare`, `desc` y `tend`; 23 tendencias nuevas «dormidas» para sistemas futuros (fe, vicio, ley, fama...). `roll_balanced`: 6 rasgos, difíciles al azar (0–3, casi siempre 1–2) compensados con amables, máx. 1 raro (25 %). `PersonProfile`: sin `PERSONALITY_TRAITS`/`OPPOSITE_TRAITS`; `complete_personality()` en `from_dict` completa a 6 de forma determinista (fichas fijas de `NPCData` con 3 y partidas viejas; nunca quita los que tenía). Compatibilidad por ejes (`are_opposed`) con peso ×0,5 por haber el doble de rasgos. Nombres en femenino con `TraitCatalog.display/npc_display` (-o→-a, -or→-ora, -ón→-ona, -án→-ana). Arreglado: las investigaciones miraban `npc.traits` (rasgos viejos de oficio) en vez de la personalidad; ahora `person_profile.personality`. Simulador: 2–3 parejas y 5 peleas en 60 días (igual que antes). Test #45.
- [x] **T2b** HECHO. Lo que cuenta otro vecino ya no va a `known_traits`: queda en `VillageNPC.rumored_traits` (id → quien lo dijo; se guarda) y se muestra «Se dice: X (según Y)». `TraitDiscovery.would_lie_about`: miente quien tiene honestidad ≤ −0,5 o malicia ≥ 0,8 y relación ≤ −30 con el otro, en el 60 % de las parejas (fijo por pareja); el bulo es un rasgo difícil no raro que no tiene. Al descubrir un rasgo por tu cuenta se borra su rumor y los del mismo eje; al conocer todos, se borran los falsos. Test #46 (y #41 ajustado).
- [x] **T3** HECHO (antes que T2, que espera la revisión del usuario). `scripts/systems/TraitDiscovery.gd`; lo conocido vive en `VillageNPC.known_traits` (+ `trait_trust_tier`, `trait_first_impression_done`, `trait_lore_done`), guardado con la partida. Se revela: 1 rasgo por cada umbral de afinidad 20/40/60/80; 1 con «Conocer la historia personal» (acción `trait_lore`); 1 con Carisma ≥ 3 al hablar por primera vez; 1 al espiar en sigilo; el rasgo que explica la conducta al ver calumniar (malicia) o pelear (agresividad) a ≤170 px; y en el menú de opiniones, un vecino que confía en ti (afinidad ≥ 35 o Carisma ≥ 2) cuenta un rasgo del otro. Glosario, mapa y taberna muestran «Rasgo, ❓, ❓» (`get_known_traits_text`). Partidas guardadas antes de T3: todos los rasgos empiezan ocultos. Test #41.
- [x] **T4** HECHO. Tendencias conectadas: agresividad (+laboriosidad) → fuerza en peleas (`SocialDirector.compute_fight_power`); agresividad y rencor → tensión al cruzarse rivales (×0,5–1,6); confianza del oyente → éxito al hablarle bien/mal, mediar o emparejar (±0,08 por punto; el rencor resta al mediar); honestidad → le cuesta más darte coartada y puede rechazar sobornos (0,35 × honestidad); chismorreo → probabilidad de contar novedades (0,5 + 0,25 × chismorreo); malicia y agresividad (− honestidad) → rasgo sospechoso en investigaciones (Sanguinario, Avaricioso y Cruel siguen por nombre hasta T2); malicia → paz o calumnia en misiones (≤ −0,3 / ≥ 0,5); generosidad → pago de misiones (±25 %). Sociabilidad → tiempo entre charlas (`get_social_cooldown_mult`, ×0,6–1,5) y peso para proponer quedadas (`VillageSocialLife.pick_hangout_initiator`, 0,3–2); laboriosidad → rendimiento en el oficio (`get_diligence_mult`, ×0,75–1,15; el tope de eficiencia sube a 115 %). Simulador abstracto tras el cambio: 3 parejas y 5 peleas por 60 días en 5 semillas. Test #42.
- [x] **T5** HECHO (medición, tras T2/T2b/U1; sin U2–U3). Partida real semilla 303, 25 días: 9 ofertas (6 paz, 2 calumnia, 1 opinión), máx. 3 abiertas, **7 calumnias entre vecinos** (antes de T2: 1), 2 peleas (igual), parejas 1 → 2, 75 % de relaciones entre −20 y +40, 1,12 rasgos difíciles de media, 0 errores. Las calumnias suben porque con 6 rasgos la malicia suma más; el usuario pidió bajarlas a la mitad: `NPC_SLANDER_PER_MALICE` 0,15 → 0,075 y tope 0,45 → 0,25 (se esperan ~3–4 cada 25 días; sin medir en partida larga). Sonda temporal `tools/tests/t5_probe.gd` (sin subir).

### Relaciones de un solo sentido (bloques U)
- [x] **U1** HECHO. Sin cambio visible. `SocialDirector`: `spark_by` por pareja (id → chispa hacia el otro), `get_spark(de, a)`, `add_spark_one_way(de, a, n)`; `spark` sigue siendo la chispa mutua (= la menor) que usan las etapas; `_add_spark_capped` suma a los dos lados; si código antiguo escribe `spark` a mano se toma para los dos; partidas viejas lo crean al usarlo. `VillageNPC.modify_npc_relationship(..., one_way)` cambia solo un lado (sin avisos de reconciliación/ruptura). Test #47. Nota: el número de acciones de `dialogue_coverage` varía entre ejecuciones (484→474 sin tocar diálogos): es azar, no un fallo.
- [x] **U2** HECHO. Charlas en vivo: `SocialDirector.side_delta(yo, otro, d)` (lo bueno ×(1+0,15·sociabilidad); con manías `TraitCatalog.IRRITATES` ×0,5 −2 por manía; lo malo ×(1+0,3·manías)×rencor); `VillageNPC` aplica la parte común a los dos (con avisos de reconciliación/ruptura) y el resto por su lado. Chispa: `_apply_spark_bias` (Romántico +, Desapegado −, el Coqueto la despierta en otros) en charlas en vivo y en el simulador abstracto; emparejar (B5.4) solo ilusiona a quien escucha. De un solo lado: lo que el jugador cuenta, celos, enterarse de una calumnia, misión de rumor, sospecha de robo; los rescates dan +8 al rescatado y +3 al rescatador. Reciprocidad lenta diaria: aprecio −5 % de la diferencia (1–2 puntos, `VillageSocialLife.daily_reciprocity`), chispa +1 al día si se vieron en 3 días (`_spark_reciprocity`). El simulador abstracto aún usa aprecio compartido (U7). Test #48.
- [x] **U3** HECHO. Cortejo: ya exigía la chispa mutua (= la menor). Declaración no correspondida en `advance_live_romance_day`: solteros sin cortejo, vistos hace poco, uno con chispa ≥ 28 y el otro < 14 → 25 % al día (dial `rejection_daily_chance`) → resultado `rejections`; −15 de chispa al que se declara y 20 días sin repetir (`rejected_day`). `VillageSocialLife.on_rejection`: −5 de aprecio del que se declara, −2 del otro, pensamiento triste, evento `rejection` (se cuenta como chisme). `on_new_couple_jealousy`: quien tenía chispa ≥ 28 por alguien que se empareja aprecia −10 a la nueva pareja (evento `jealousy`). Misión de opinión: la oferta usa la chispa de quien pregunta y la respuesta la chispa real del otro («Le gustas, y mucho» / «un poco» / «solo como amigo/a»...); una respuesta sin chispa desilusiona solo a quien preguntó. Test #49 (y #37 ajustado).
- [x] **U4** HECHO. `VillageSocialLife.try_hangout_excuse`: si quien invita aprecia ≥ 35 y el invitado < 15 (sin cortejo ni pareja), 70 % de excusa («Hoy no me viene bien...»), se cancela la quedada y quien invitó se apena (−3 de ánimo, −1 de aprecio). `feeling_phrase(rel, otro)`: frases de un solo lado con género («es mi mejor amiga», «ni fu ni fa», «no lo soporto»). Test #50.
- [x] **U5** HECHO. `VillageNPC.known_feelings` (+ `feelings_all_known` para partidas de antes de U5, que lo siguen viendo todo); pareja y familia se ven siempre (`knows_feeling_toward`). Se descubre al elegir a alguien en «qué opina de los vecinos» (`quest_opinion_seen`). El menú habla en primera persona y, si ya sabes lo que siente el otro y la diferencia es ≥ 30, lo señala. Glosario: lo desconocido sale «❓ No sabes qué siente por él/ella» (y no cuenta para mejores amigos/enemigos); lo conocido añade «↩ lo que siente el otro». Pendiente menor: los sentimientos contados por terceros («según X») no están hechos. Test #51 (y #28 ajustado).
- [x] **U6** HECHO. `VillageSocialLife.daily_distance_cooling`: tras 7 días sin cruzarse, cada lado se acerca 1 punto al día a neutro sin pasar de ±10 (no parejas ni familia). La chispa ahora se enfría por cada lado sin igualarse (`SocialDirector._change_spark_both`, también en rupturas); antes el enfriamiento diario borraba los amores no correspondidos. Test #52.
- [x] **U7** HECHO. Tres partidas reales (semilla 303, 25 días, sin jugador). 1ª: 0/136 parejas con diferencia ≥ 30, 0 amores no correspondidos. Ajustes: «química» fija de cada uno hacia cada otro (`SocialDirector.chemistry`, ±35 % en lo bueno), sociabilidad ×2 en `side_delta` (0,4–1,8), reciprocidad solo desde 20 puntos de diferencia (`RECIPROCITY_MIN_GAP`), enfriamiento por distancia proporcional (3 %/día, `COOL_RATE`). 3ª: 2 parejas con diferencia ≥ 15 (máx. 43), 4 parejas con chispa (máx. diferencia de chispa 32), 4 calumnias, 0 peleas, parejas 1 → 2, 79 % de relaciones en la franja media, 0 errores. **Conclusión**: el sistema funciona (tests #47–#52), pero sin jugador, en 25 días y con 17 vecinos, muy pocas parejas tratan lo bastante como para separarse; las diferencias grandes saldrán sobre todo de lo que haga el jugador (cizaña, favores, emparejar) y de partidas más largas. La meta del plan (15–25 %) era optimista; no se fuerza más para no inventar dramas. Sonda: `tools/tests/t5_probe.gd` (sin subir). en `docs/PLAN_RELACIONES.md` (tensión compartida, reciprocidad lenta, sentimientos ocultos al principio).

### Crónica del pueblo (bloques C)
- [x] **C1–C4** Hecho (plan en `docs/PLAN_CRONICA.md`). `scripts/systems/VillageChronicle.gd` + `scripts/ui/ChronicleUI.gd`, tecla **O**
  (la C ya era sigilo). Guarda los 160 últimos sucesos en `VillageManager.chronicle` (se guarda con la partida; las viejas
  empiezan con el registro social). Cada línea lleva `known`: público, del jugador o visto a ≤170 px; lo secreto se revela con
  `learn_event` (al preguntar por novedades). `SHOW_ALL_DEBUG = true` mientras estamos en pruebas: se ve todo y lo secreto
  lleva 🔒; **ponerlo en false para la versión final**. También apunta muertes descubiertas, casos cerrados y misiones
  cumplidas o fallidas. Test #53. La sonda imprime una línea CHRONICLE.
- [x] **C5** (revisión tras probarla el usuario: en una semana no salía nada de los vecinos). Tope subido a **500**. Ahora
  también apunta quedadas (`hangout`), chismes (`on_gossip`, desde `spread_gossip`; si el jugador está cerca se entera del
  suceso) y cambios de escalón de amistad, de un solo sentido (`daily_friendship_scan`, una vez al día; escalones 65/35/−30/−60
  con margen de 5; guardado en `VillageManager.chronicle_tiers`; secreto salvo que el jugador conozca ese sentimiento).
  Pestañas nuevas Amistad y Chismes, nombres cortos para que quepan. Las charlas normales no se apuntan.
  Arreglo tras probarlo el usuario: el panel abría en la última pestaña usada y no se refrescaba estando abierto
  (parecía vacío). Ahora abre siempre en «Todo» y se repinta solo cada 0,5 s si hay líneas nuevas (`_signature`).
  Pulido: lo apuntado durante el cambio de día (`VillageManager.chronicle_daily`) va al día anterior como «Durante el día»
  en vez de «00:00»; el panel ocupa la pantalla con `top_level` para salir centrado (el `ui_root` es más pequeño que la
  pantalla; el diario de misiones tiene el mismo problema, sin tocar); «salió peor parada/Magullada» según el género.

### Recuerdos que se degradan (bloques R)
- [x] **R1–R4** Hecho (plan en `docs/PLAN_RECUERDOS.md`). `scripts/systems/GossipMemory.gd`: por chisme y vecino,
  fuerza del recuerdo (`ev["mem"]`, 100 protagonistas / 80 testigos / 70 al oírlo, −8 al día; protagonistas −1,5; tendencia
  `memory` despierta: Memorioso/Estudioso/Nostálgico más lento, Olvidadizo más rápido; contarlo +10). A 0 lo olvida
  (`ev["forgot"]`; sigue en `known_by` para no romper `heard_from`). `knows()` sustituye a `known_by.has()` en chismes,
  novedades y motivos que cuenta un testigo al investigador. Tope de edad `GOSSIP_MAX_AGE_DAYS` 10 → 20.
  Deformación al contar (`ev["ver"][clave]`: exagerar hasta 2 niveles o cambiar a una persona; se hereda de boca en boca;
  más si miente, lo recuerda mal o no es protagonista, tope 40 %). `gossip_text(ev, listener, ver_key)` dice la versión.
  Crónica: «❓ X te contó: …» con «[deformado]» en modo pruebas. Las versiones aún no cambian relaciones (va con Secretos).
  Test #54. La sonda imprime MEMORY.

### Secretos: infidelidad y chantaje (bloques S)
- [x] **S1–S6** Hecho (plan en `docs/PLAN_SECRETOS.md`). `scripts/systems/VillageSecrets.gd`, datos en
  `VillageManager.secrets` / `secret_uid` (se guardan). S1: cada día, alguien con pareja puede empezar una aventura si hay
  chispa en los dos sentidos (≥35 / ≥20), contacto reciente y no son familia; probabilidad `AFFAIR_DAILY` × tentación
  (Fiel 0, normal 0,25, Infiel 0,55); una a la vez y 30 días de descanso. Al quedar, el infiel elige al amante la mitad de
  las veces. S2: en cada encuentro, vecinos a ≤170 px (50 %) y el jugador los pillan; el testigo crea el chisme «affair»
  (los amantes no lo cuentan; al deformarse solo cambia el amante, `swap_only`). S3: quien lo oye −4 al infiel y −2 a quien
  cree amante (puede ser un inocente); la pareja −30/−20, tensión +40 y 70 % de ruptura. S4: un vecino malicioso que lo sabe
  chantajea (paga la mitad de su oro, hasta 30, o se niega y se lo cuenta a la pareja). S5: diálogo «🤫 Sé lo tuyo con…»
  (pedir oro / prometer callar) y «💔 Tengo algo que contarte» a la pareja; si el rumor que oíste señalaba a otra persona,
  lo niega. Test #55. La sonda imprime SECRETS.
  Medido antes de S: los chismes circulaban muy poco (25 días: 1 chisme contado).
- [x] **R5** Más ritmo de chismes (pedido por el usuario): `GOSSIP_EVENT_TYPES` suma citas, coqueteos, noviazgos, celos,
  llegadas, marchas y perdones de infidelidad; en cada charla también puede contar novedades quien contesta
  (`VillageNPC`, «¿Y sabes qué? …»). Exageraciones propias para lo romántico. Sonda (semilla 303, 25 días): 12 chismes, 61 personas los
  sabían, 38 veces contados, 10 olvidos, 6 versiones deformadas (antes: 3 / 8 / 1 / 0 / 0). Calumnias 3, peleas 2, parejas
  1 → 2, 0 aventuras (con solo 1–2 parejas es lo esperable: raro y orgánico). Sin errores.

### Deseos propios (bloques D)
- [x] **D1–D6** Hecho (plan y decisiones en `docs/PLAN_DESEOS.md`). `scripts/systems/VillageDesires.gd`; datos en
  `VillageManager.desires`, `desire_uid`, `desire_hate_since`, `npc_murders`, `last_npc_murder_day` (se guardan). Un deseo
  activo por vecino, pasos cada 2–4 días, 10 días de descanso entre deseos. D2 venganza (odio ≤ −50; 10 %/día × rencor):
  hablar mal → contar su aventura a la pareja → sabotear su puesto → buscar pelea (tensión +30) → satisfecho; se acaba si
  el odio baja de −30 o pasan 20 + 15×rencor días. D3 ambición (Ambicioso, Sediento de poder, Envidioso, Codicioso; 5 %/día;
  abierta): ahorrar, hablar mal del más rico, sabotearle. D4 contra el jugador (afinidad ≤ −50 durante 7 días; 20 %/día):
  ir diciendo que no eres de fiar (−2 de afinidad a quien lo oye), negarse a venderte (`filter_dialogue` quita compras),
  denunciarte (multa +15 si tienes antecedentes; +10 inventada si es mentiroso), contar tus secretos (chantajes; −3).
  D5 asesinato: desde una venganza de ≥10 días con odio ≤ −80, oscuridad (malicia+agresividad−honestidad) ≥ 1,5, 5 %/día,
  máximo uno al mes en el pueblo; 3–5 días de preparación con señales (35 %/día, quien está cerca se entera; el chisme
  `murder_threat` no lo cuenta el asesino; si llega a la víctima, 50 % de que se ponga en guardia). Solo actúa de noche si
  nadie despierto está cerca de la víctima (si no, otra noche). Nunca contra el comisario ni el inquisidor. El caso del
  comisario suma +30 de sospecha al asesino, sin coartada y con pista. Descubrir deseos: «💭 ¿Qué le ronda la cabeza?»
  (abiertos con afinidad ≥ 10, secretos ≥ 50; los de asesinato nunca, solo una pista con ≥ 60), por chismes
  (`desire_rumor`) o porque los abiertos los cuenta el propio vecino. Con lo que sabes: convencerle de que lo deje (afinidad
  ≥ 40, 50 %), avisar a la víctima o denunciar el plan al comisario o un guardia. Test #56. La sonda imprime DESIRES.
  Sonda (semilla 303, 25 días, sin jugador): 7 deseos (5 venganzas, 2 ambiciones; 3 cumplidos, 1 olvidado, 3 en curso),
  2 sabotajes, 0 asesinatos, calumnias 5 (antes 3), peleas 2, 17 vivos, 76 % de relaciones en la franja media. Sin errores.

### Grupos y fe (bloques G)
- [x] **G1–G7** Hecho (plan y decisiones en `docs/PLAN_GRUPOS_FE.md`). `scripts/systems/VillageFaith.gd`; datos en
  `VillageManager.faith_state` (se guarda: reputación por grupo `rep`, fe vista `seen`, contadores de Oficios) y
  `faith_bands` (se recalcula cada día). G1 **Fe del Alba** (provisional, parecida al cristianismo sin nombres reales):
  el Hacedor, el Libro del Alba, el círculo del sol naciente. Grado por la tendencia `faith` de los rasgos: ≥1 fervoroso,
  ≥0,4 creyente, ≤−0,5 escéptico, si no tibio. La capilla pasa a llamarse **Capilla del Alba** (antes «San Cipriano»).
  G2 `WorldClock`: `get_weekday`, `is_weekend` (sábado y domingo), `is_rite_day` (domingo); el reloj muestra el día de la
  semana. Fin de semana (`VillageNPC._is_mandatory_work_hours`): oficios y familias trabajan el sábado de 9 a 13 y
  descansan el domingo; tabernera, autoridades y sacerdote, igual que siempre; el fin de semana salen a socializar antes
  (umbral 90 en vez de 78). Oficio el domingo: a las 8, 9 y 10 `VillageFaith.call_to_rite` llama (fervorosos siempre,
  creyentes 85 %, tibios 30 %, escépticos nunca; fijo por semana) y `npc.join_rite(pos)` les hace caminar de verdad a los
  bancos (`rite_pos`, primero en `_get_social_target_pos`; no se van salvo hambre < 30 o energía ≤ 12). Comisario y guardia
  no van (de servicio). A las 11 `finish_rite`: cuentan los que están a ≤ 40 px; +2 entre asistentes (+3 si los dos
  creen), 6 intentos de chisme entre ellos, el fervoroso apunta −2 a cada creyente que faltó, y si estás a ≤ 150 px del
  altar los creyentes te dan +3 y ves su fe. Roces diarios (10 %): fervoroso y escéptico −2; dos creyentes +1.
  G3 sacerdote **Hermano Anselmo** (`TradeRole.PRIEST`, nodo `NPC_Priest_Anselmo`, cama y mesa en la capilla, sprite
  provisional `guia`); usa los huecos de autoridad, así que si muere llega un sustituto; `ensure_priest_faith` le da
  Devoto si no tiene fe. Sermón: si odia a alguien (≤ −40), los asistentes −3 hacia él. G4 bandos: familias (≥ 2 vivos),
  pandillas (≥ 3 que se aprecian ≥ 50 entre todos) y seguidores de un Líder (≥ 2). En `record_social_event` de pelea,
  calumnia o chantaje, cada miembro que aprecia al dañado (≥ 30) coge −4 al agresor (una vez por suceso; nada si el
  agresor es del mismo bando). En la charla, +15 % de contar chismes dentro del bando. G5 reputación: creyentes,
  escépticos y cada bando (cambios de afinidad ≥ 3 con un miembro cuentan ¼); se ve en el glosario (J). G6 diálogo:
  al sacerdote, «☀️ Preguntar por la Fe del Alba» → donar 10 de oro o burlarte (−12 con él, −4 con creyentes cerca, +2 con
  escépticos); a los demás, «¿Vas al Oficio?» (te lo dicen si te aprecian ≥ 0). Crónica: pestaña «☀️ Fe» (`rite`) y tipos
  `faith_mock`, `faith_donation`, `band_defend`. Test #57. La sonda imprime FAITH.
  Sonda (semilla 303, 25 días, sin jugador, 18 vecinos): 3 Oficios con 8 asistentes de media; bandos solo familias (6),
  ninguna pandilla ni seguidores; 2 defensas de bando; chismes 16 sucesos / 98 que los saben (antes 73), 22 olvidos,
  29 versiones deformadas (antes 6: vigilar); calumnias 7, peleas 1, 18 vivos, 78 % de relaciones en la franja media.

### Economía y necesidades ampliadas (bloques E)
- [x] **E1–E7** Hecho (plan y decisiones en `docs/PLAN_ECONOMIA_NECESIDADES.md`). Módulos `VillageNeeds.gd` (higiene,
  posición, vicios, limosna, diálogo), `VillageIllness.gd` (enfermedades) y `VillageCrime.gd` (robos); estado en
  `VillageManager.needs_state` (se guarda: `addict`, `drunk`, `ill`, `immune`, `thefts`, `smell_day`, `craving`, contadores).
  Vecino: `need_hygiene` (guardada), `sick_level`, y **encargos a pie** `start_errand(kind, pos)` / `end_errand()`
  (`errand_kind`: wash, drink, gamble, beg; van segundos después de `rite_pos` en `_get_social_target_pos`, no se
  interrumpen salvo hambre/cansancio/noche, caducan a las 3 h salvo pedir). `VillageNeeds.tick` (cada segundo real desde
  `VillageManager._process`) los termina al llegar; `on_hour` y `daily` desde los relojes del VM.
  E1 higiene: −1,4/h (×1,5 carnicero y herrero; Pulcro más lento, Desaliñado más rápido); a las 7, 8, 18, 19 y 20 h, si
  está libre y por debajo de 45 (+15 × tendencia), va al pozo más cercano o a casa. Por debajo de 20: −5 de humor y dos
  vecinos −1 («Huele mal»). Jugador: `SurvivalComponent.current_hygiene` (−0,04/s, guardada, barra 🧼 en el HUD); se lava
  en los pozos (`_use_water_well`) o al lavarse junto al agua (`wash_bloodstains`); por debajo de 25 cada vecino con el que
  hablas te baja 1 de afinidad una vez al día. E2: resfriado (3–5 días, contagio 6 %/h a ≤ 60 px, leve) y fiebre gris
  (6–10 días, 4 %/h, guarda cama `sick_level` 2, sin tratar desde el día 5 muere un 4 %/día). Inicio diario 0,6 % (+3 %
  si higiene < 30, +0,6 % con lluvia; miasma → fiebre). Tope 2 contagios/día, inmunidad 20 días. El médico trata 3 al día
  (graves primero; acorta a la mitad). Jugador: se contagia; enfermo, el aguante se queda en 65/40; la fiebre sin tratar
  le baja 12 de vida al día **sin matarle** (mínimo 5); el médico te cura por 8 de oro. E3: rico ≥ 160, acomodado ≥ 70,
  humilde ≥ 20, pobre, mendigo (campamento o parado con < 5). Los ricos comen en la taberna más (35 %); envidia pequeña;
  los mendigos piden en la plaza de 9 a 18 y los que pasan dan 1–2 de oro. E4: un robo por noche como mucho; ganas
  según pobreza, mono sin oro y Cleptómano, por (1 − 0,6 × honradez − 0,4 × ley); con honradez ≥ 1 nunca (salvo
  Cleptómano). Víctima: otro vecino (no de su familia ni bando), la caja de un puesto o tú (25 %); se lleva el 20 %
  (máx. 25). Testigo cercano o un 25 % de que alguien lo viera de lejos: si es honrado y no es de su bando, lo denuncia
  y el comisario le obliga a devolverlo con multa (`theft_caught`, público); si no, chisme `theft` (el ladrón calla).
  La víctima −40 hacia él (puede volverse venganza). Tú: denunciar al comisario o guardia lo que sepas, decirle al
  ladrón que lo sabes (callar, +8; o exigir tu oro). E5: a las 19 y 20 h van a beber (3 de oro a la tabernera) o a
  jugar (apuesta 8, gana el 45 %) según Bebedor/Tahúr/vicio y su enganche (+8 por vez, −3/día; enganchado ≥ 50);
  sin oro y enganchados: mono (−6 y más ganas de robar). Borrachos 3 h: el 50 % de las veces cuentan lo que callaban
  (`VillageSecrets.keeps_quiet`). E6: limosna (3) y regalar oro (10) a pobres; invitar a una ronda en la taberna (4):
  te cuenta novedades y un rasgo. Glosario (J): higiene, posición, vicios y enfermedad. Crónica: theft, theft_caught,
  illness, illness_death, player_alms. Test #58. La sonda imprime NEEDS. No hay adicción para el jugador.

### Instituciones y corrupción (bloques I)
- [x] **I1–I6** Hecho por mi cuenta (el usuario pidió terminar hasta el paso 7 sin él; decisiones mías en
  `docs/PLAN_INSTITUCIONES.md`). `scripts/systems/VillageTown.gd`; estado en `VillageManager.town_state` (se guarda:
  `mayor`, `mayor_name`, `next_election`, `treasury`, `pledges`, `banned`, `history`, contadores). I2 alcalde: elecciones
  el primer día y cada 28; candidatos los 3 elegibles (no autoridades, sacerdote, forasteros ni acampados) con más
  2×mando + ambición + oro/100; cada uno se vota a sí mismo; los demás votan por relación (+15 si es de su bando, +5×mando)
  o por la promesa que les pediste. I1 impuestos cada sábado (`get_weekday() == 5`): 5 % del oro por encima de 20 (ricos
  8 %) y 5 % de la caja de cada negocio; el alcalde cobra 5 y reparte 10 a cada pobre o mendigo mientras haya. Sueldos de
  autoridades: siguen saliendo de la Corona. I3 `corruptibility` (Íntegro 0; Sobornable +0,3; honradez, ley, ambición,
  generosidad); corrupto ≥ 0,5. Alcalde corrupto: se queda 30–60 % de cada cobro; 25 % de que alguien lo note (chisme
  `embezzle`, el alcalde calla); con 5 que lo sepan o si lo denuncias al comisario (no corrupto), `expose`: devuelve lo del
  mandato, todos −10 hacia él y elecciones anticipadas sin él (`banned`). Comisario corrupto: el ladrón denunciado le paga
  hasta 15 y se libra (`police_bribe`, estado del robo `bribed`; el testigo −10 al comisario). I5: sobornar al comisario o
  guardia (máx(20, 1,5 × multa); si no es corrupto, multa +10), pedir el voto (afinidad ≥ 30, o 10 de oro a un corrupto),
  denunciar al alcalde. Fama `law` (denunciar +, sobornar −). I4 nobles aplazado al paso 9. Glosario (J): línea del pueblo.
  Crónica: election, taxes, embezzle, embezzle_exposed, police_bribe, player_bribe. Test #59. La sonda imprime TOWN.
  Sonda E+I (semilla 303, 25 días, sin jugador): sin errores, 18 vivos; higiene media 59; 18 contagios y 0 muertes
  (demasiados: bajé el contagio a 6 %/4 % y el tope a 2/día); posiciones 7 ricos, 3 humildes, 7 pobres, 1 mendigo
  (los sueldos de la Corona enriquecen a las autoridades: vigilar); 4 robos, ninguno pillado; 2 enganchados;
  alcaldesa Marta (no corrupta), 448 de impuestos y 348 sin gastar en las arcas (subí la ayuda a 10 por pobre);
  3 Oficios (23 asistentes); calumnias 5, peleas 1, 82 % de relaciones en la franja media. Ajustes sin volver a medir.

### La secta secreta (bloques O)
- [x] **O1–O7** Hecho con las decisiones recomendadas (el usuario delegó lo creativo; ver `docs/PLAN_SECTA.md`). Nombre,
  lore y rangos provisionales, apuntados en `docs/APORTES_CREATIVOS.md`. `scripts/systems/VillageSect.gd`; estado en
  `VillageManager.sect_state` (se guarda). O1 funda (día 3–6) el vecino con más `founder_score` ≥ 0,3 (Místico, Fanático,
  Manipulador, Cruel, ambición, mando, malicia; nunca autoridades, sacerdote, forasteros ni menores de 16). O2 cada miembro,
  1/7 al día, intenta captar al más vulnerable que aprecie (pobre, mendigo, adicto, sin amigos, con un rencor fuerte,
  enfermo sin tratar, Místico) contra su resistencia (fe, Íntegro, honradez); tope 5. Quien se niega y es creyente u honrado
  suelta el chisme `sect_rumor`. O3 reunión viernes (`get_weekday() == 4`) a las 0–1 h en `_cemetery_burial_pos`, fin a
  las 3; el vecino usa `join_rite(spot, "sect")` (`rite_kind`); al salir de la cama, 20 % de que alguien de su familia lo
  note (`sect_night`). O4 diezmo (máx 3) y ayuda de 5 a los pobres de la secta; −2 al sacerdote; profanación (30 % con ≥ 3,
  cartel «sol negro» 3 días); la secta es un **bando oculto** en `faith_bands` (kind "sect", `hidden`), así que se
  encubren en robos, se defienden y se votan; `VillageTown.candidates` mete a un miembro entre los candidatos; van al
  Oficio al 40 %. Rito de sangre: con ≥ 4 miembros, 21 días de secta, fundador oscuro (malicia + agresividad − honradez ≥ 1,
  o Cruel o Fanático) y 10 días sin asesinatos: 25 % por reunión de elegir víctima; señales (`sect_rumor` del miembro con
  más reparos, 30 % diario); a la reunión siguiente la víctima acude engañada (`sect_lure`) y muere; queda en
  `vm.npc_murders` para el comisario. O5 sospecha 0–100 (rechazos, salidas de noche, profanaciones, señales, ritos; −2 al
  día); a 100 el sacerdote los señala → `expose`: todos −15 hacia cada miembro, multa al fundador, la caja va a las arcas
  y se disuelve; renace a los 30 días con otro fundador. O6 jugador: verla en el cementerio, enterarse por chismes,
  chantajear, sonsacar nombres, denunciar ante el comisario (si no está comprado) o el sacerdote, avisar a la víctima, unirse
  (te invita un miembro con afinidad ≥ 45 si tu fama de fe ≤ 10, o lo pides si sabes que es miembro) y dejarla. Rangos por
  asistencia (0/3/6). Sin encargos (evitamos misiones). Glosario (J): línea 🌑 solo si conoces la secta. Crónica: sect_found,
  sect_join, sect_meeting, sect_profane, sect_plan, sect_rite, sect_exposed, sect_player. Test #60. La sonda imprime SECT.
  Sonda (semilla 303, 25 días): con el umbral 0,8 no nacía (el máximo del reparto es 0,42); bajado a 0,3. Segunda
  sonda: fundó Aldric, 4 captados (lleno a 5), 3 rechazos, 3 reuniones, sin profanación ni rito, sin destapar; 18 vivos.
  Salieron 12 errores al mirar adicciones (`int` sobre un diccionario), ya corregido.
- [x] **O8** Rediseño pedido por el usuario: **nada programado por fecha** (ver `docs/PLAN_SECTA.md`, última sección).
  Sin `found_day` ni renacer a los 30 días. Nace con `try_found` cada día: `FOUND_BASE` × crisis del pueblo
  (`town_crisis`: media de `crisis_of` + `crisis_events`, que suben con muertes, robos, escándalos y contagios y se
  olvidan un 6 % al día) o aburrimiento de los ricos (`town_boredom`, `boredom_of`) × labia del líder (`persuasion`
  ≥ 0,45) × su `motive`. Dos clases (`kind`): desperate (cementerio, 0–3 h) y rich (casa del líder, 20–23 h, solo ricos y
  acomodados). El líder elige `meet_day`. Captación: un intento al día como mucho (12 % + 1,5 % por miembro), más difícil
  cuanto más grande; techo 13. Se van despacio los que ya no lo necesitan (`LEAVE_CHANCE` 0,8 %, menos si son veteranos).
  Fundador destapado: `discredited` (−0,6 de labia). Test #60 ampliado (sin crisis o sin líder no nace).
  Sonda (303, 25 días): la crisis subió de 0,02 a 0,27 (umbral 0,18) y el aburrimiento máximo fue 0,19, pero **no nació
  ninguna secta**: con el reparto actual la labia máxima es 0,29 (Mila); nadie llega a 0,45. Nacería si llega un vecino
  nuevo con Líder, Manipulador o Místico, o si alguien gana mucho aprecio del pueblo.
  Después, a petición del usuario, **Aldric es Manipulador** (`NPCData`, 4 rasgos fijos; al completarse a 6 cambian sus
  2 rasgos de relleno: ahora Cumplidor y Mentor en vez de Humilde, Permisivo y Disciplinado). Manipulador y Codicioso
  dan motivo 0,4 (el oportunista). Labia de Aldric 0,54; probabilidad de fundar: 0,3 % al día con crisis 0,27 y 0,8 %
  con 0,40. Las partidas guardadas conservan sus rasgos de antes. Sin sonda nueva.

### Crecer el pueblo (bloques V, `docs/PLAN_CRECER_PUEBLO.md`)
- [x] **V1** Medición: `tools/tests/perf_probe.gd -- 18,30,50,70` (con `--fixed-fps 60`; sin pantalla, solo lógica).
  Mide ms por fotograma, coste de una hora y de un día, y el de cada sistema diario por separado. Hallazgo: el cambio de
  día costaba 0,45 s con 18 vecinos, 1,3 s con 50 y 3,6 s con 70 (tirón a medianoche), porque
  `get_relationship_with_npc` recorría el pueblo dos veces en cada consulta (`_migrate_legacy_relationship_keys` +
  `resolve_person_id_key`) y `modify_npc_relationship` llamaba siempre a `ensure_npc_relationships_initialized`.
  Arreglo: camino rápido si la clave ya está guardada por id; inicializar o migrar solo si falta la clave o hay una
  clave antigua por nombre. Ahora el cambio de día cuesta 80 ms con 50 y 157 ms con 70; el primero tras una llegada masiva
  de gente, ~0,5 s (inicializa sus relaciones). Por fotograma: vecinos 0,9 ms (18), 2,6–3 ms (50), 6,3 ms (70); la hora,
  ~1 ms. Lo más caro del día con 50: bandos de Fe (26 ms), secta (21 ms) y misiones (16 ms).
- [x] **V2** Simulación simplificada (`VillageNPC._lod_far`, `LOD_DIST` 360, `LOD_STEP` 4): el vecino a más de 360 px del
  jugador (fuera de pantalla con margen) solo ejecuta `_physics_process` 1 de cada 4 fotogramas, con el tiempo acumulado
  (contador propio `_lod_tick`, no el del motor, porque los tests llaman a `_physics_process` a mano). En ese paso
  `_lod_k` multiplica la velocidad en `_finish_frame_movement` para recorrer la distancia de los 4 fotogramas; fuera de él
  vale 1 (si no, quien llama con pasos largos a mano, como el testigo de un cadáver, se teletransporta). Nunca se
  simplifica a hostiles, peleas, quien habla contigo ni autoridades/médico. Lo social va por horas y días, sin cambios.
  Medido con 50: jugador en el borde, 11,3 → 7,9 ms por fotograma. **Sin resolver**: con el jugador en la plaza junto a
  la multitud cuesta 16–19 ms con o sin LOD (no es el código del jugador; con los vecinos apagados baja a 1,4 ms). La
  sonda los amontona en la plaza; se vuelve a medir tras ampliar el mapa (V4–V5).
- [x] **V8** Pendientes cortos: panel de misiones (L) centrado (`QuestLogUI._fit_to_screen`, como la crónica). Negocio
  vacante: `VillageManager._pick_ambitious_successor` elige entre parados y familiares con ambición ≥ 0,5 (puntúa
  ambición, diligencia y oro) antes de traer a un forastero; los rivales le cogen algo de manía y sale en la crónica
  (`ambition_business`). Celos: al descubrir una infidelidad, `VillageSecrets._maybe_passion_revenge` puede crear una
  venganza «pasional» (15 % + Celoso, rencor y agresividad; máx. 60 %) contra el infiel o el amante; ese deseo puede
  volverse plan de asesinato con umbral propio (relación ≤ −60, oscuridad 0,9, 5 días) y las señales y pistas de siempre.
- [x] **V4** Solares (`scripts/systems/VillageLots.gd`, estado en `vm.lots_state`, guardado). 16 solares en `LOTS`:
  10 de «borde» (5 en una calle norte nueva detrás de la posada, 5 en el camino del este alargado hasta x 1480),
  4 de «afueras» (3 campos al sur entre el pueblo y el bosque, 1 en la ladera del noroeste) y 2 «apartados» (lomas
  del este y del norte, para mansiones), con sendas hasta cada uno; comprobado con números que no pisan edificios,
  caminos, ruinas, lago ni bosque. `request_build(vm, lote, clase, quien_paga|null=arcas)`: cobra en el acto
  (`KINDS`: de momento solo «house», 60 de oro, 24 h de trabajo, 2 camas; el 40 % al carpintero) y solo hay una obra a
  la vez. Cada hora (`on_hour`) el puesto de trabajo del carpintero pasa a ser la obra y solo avanza si está allí
  trabajando (0,7 + 0,6·diligencia por hora); al terminar vuelve a su taller (`trade_configs[CARPINTERO].work_pos`).
  Sin carpintero vivo la obra se queda parada. Dibujo: cartel de solar libre, obra con cajas y porcentaje, o la casa de
  verdad (`_construct_solid_building`: puertas, ventanas, cofre, camas). Lo que dibuja cada solar se apunta
  (`vm._lot_visuals`: nodos y entradas de las listas de edificios, puertas, ventanas, muros y cofres) para quitarlo al
  cargar otra partida; `after_load` recalcula las camas y redibuja. `free_house_bed` / `add_resident` quedan para V3,
  que decidirá cuándo hace falta una casa y quién la paga. Crónica: tipo público «construction».
- [x] **V5a** Panadería y sastrería (`scripts/systems/VillageTrades.gd`). Oficios nuevos al final del enum
  (`BAKER` 14, `TAILOR` 15) y lista común `VillageNPC.SHOP_ROLES` (sustituye listas repetidas: horario de fin de semana,
  taller, mostrador en el diálogo y en la ficha, reidentificar oficios al cargar). Edificio nuevo de solar
  «shop_house» (tienda con vivienda como la Botica, con la puerta hacia la calle; `VillageLots.shop_house_layout`).
  Los dos están en pie desde el principio en los solares n2 y n3 (calle norte) y **empiezan vacantes**: los ocupa la
  regla de siempre (ambicioso del pueblo, viajero sin oficio o forastero del borde; en las pruebas llegan el día 1).
  Panadero: horno de 6 a 16 h; pan con «harina» (pan del molino) o leña; es la primera tienda de comida que miran los
  vecinos. Sastre: «Ropa de Lana» (objeto nuevo `clothes`) con cuero del carnicero; cada día los rico/acomodado/humilde
  con dinero de sobra (≥ 52) pueden estrenar ropa (10 %, 5 %, 2 %, × gasto y fama de sus rasgos): +8 de humor.
  Diálogos de compra y venta propios. `VillageLots`: al redibujar un solar conserva los datos del negocio (dueño, caja,
  sabotaje) y no redibuja si nada cambió; `after_load` llama a `VillageTrades.ensure_lots`, así las partidas de antes
  de V5 también tienen las dos tiendas. Mapa del valle (`ValleyMapUI`): más grande (llega al norte y al este) y dibuja
  solares, obras, casas nuevas y calles nuevas. **Sin probar en juego:** que el panadero y el sastre lleguen andando
  a su mostrador y horneen y cosan de verdad (el test comprueba el negocio, la llegada y las compras de ropa).
  El usuario lo ha visto en juego: «parecen funcionar bien».
- [x] **V5b** Ayuntamiento, albergue y segunda posada (`scripts/systems/VillageCivic.gd`), en pie desde el principio
  (`ensure_lots`, también al cargar partidas antiguas). Clases de solar «civic», «shelter» e «inn» (las dibuja
  `VillageCivic.build`). **Ayuntamiento** (n4): cuando tocan elecciones normales, `VillageTown.daily` llama a
  `open_voting` en vez de votar al instante; de 9 a 20 h los vecinos libres (`VillageNeeds.is_free`: no en horas de
  trabajo, no enfermos) van con el encargo «vote» a la urna (más por la tarde; los Desconfiados, menos) y a las 21 h
  `close_voting` llama a `hold_election(vm, "", votantes)`: solo cuenta quien fue (si nadie fue, vota todo el pueblo).
  La primera elección y las anticipadas siguen siendo al instante. El sábado a las 14 h el alcalde va a «cuadrar las
  cuentas» (encargo «mayor_office»). El cofre «Arcas del Pueblo» (familia «town_hall») da el oro de las arcas de
  verdad (`rob_coffers`, 25–60 o lo que quede); al día siguiente sale en la crónica, el alcalde se lleva −10 de humor
  y algunos le cogen manía. Los encargos nuevos los termina `VillageNeeds.tick` → `VillageCivic.on_errand_arrived`.
  **Albergue del Alba** (e4, 4 camas): `evict_npc_to_vagrant_camp` intenta primero `try_shelter` (variable nueva
  `in_shelter`, guardada). Sigue contando como mendigo (`is_vagrant_camper`), pero duerme sin el tope de la intemperie,
  sin campamento, con −3 de humor en vez de −10, su desesperación para la secta baja de 0,25 a 0,15 y cada día gana +2
  con el sacerdote. **El Candil** (e2): oficio nuevo `LODGEKEEPER` (16, en `SHOP_ROLES`), puesto vacante al empezar;
  guisa estofado con carne del carnicero; 3 camas de huésped a 3 de oro (`lodging` = «candil», guardado). En el cobro
  nocturno, `nightly_guest` aloja allí al viajero que no llega a los 6 de El Jabalí; si no llega ni a 3, la regla de
  siempre (albergue o calle). El tope de 3 viajeros sigue igual: lo cambiará V3. **Sin probar en juego:** que la gente
  llegue andando a votar dentro del plazo del encargo (3 h) y que el posadero se instale bien.
- [x] **V5c** Terceros espacios (`scripts/systems/VillagePlaces.gd`, contadores en `vm.places_state`, guardado): el
  Parque del Roble (x 184–424, y 216–300, entre la Botica y la senda sur: césped, pinos de adorno sin colisión, flores
  y dos bancos), dos bancos más en la plaza y el Mirador del Lago (orilla sur, barandilla y banco). Cada hora de ocio
  (entre semana 17–21; fin de semana 10–21, salvo el domingo por la mañana del Oficio) cada vecino libre
  (`VillageNeeds.is_free`) puede salir con el encargo «leisure»: 8 % + 12 %·sociabilidad, +10 % si se siente solo,
  ×0,6 si está muy decaído, ×0,15 con lluvia, ×0,5 si es mendigo (máx. 50 %). Elige sitio por cercanía con algo de azar
  (el mirador atrae a quien tiene pareja o es Melancólico). Al llegar se queda (`leisure_since`); cada hora, a partir de
  la primera, se va con un 50 %, y siempre al acabar el ocio, con lluvia o a las 3 h del encargo. Quienes coinciden a
  menos de 46 px charlan por parejas: +2 de relación, +12 de compañía y 50 % de contarse un chisme
  (`VillageSocialLife.spread_gossip`); si se llevan a −40 o peor, −2. Las quedadas del SocialDirector usan los cuatro
  sitios nuevos (clases «park» y «overlook» con su propia puntuación).
- [x] **V5d** Afueras. Cuatro oficios más en `VillageTrades.CONFIG` (enum: `FARMER` 17, `RANCHER` 18, `QUARRYMAN` 19,
  `WOODCUTTER` 20; ojo, `PRIEST` es 13, así que `BAKER` es 14, `TAILOR` 15 y `LODGEKEEPER` 16: en los tests usa
  `VillageTrades.role_of(...)` / `VillageCivic.lodge_role()`, nunca números). Granja del Sur (solar s1; sus campos
  ocupan también s2, clase «fields»), Rancho (s3), Cantera (w1) y Cabaña del Leñador (solar nuevo «fw», linde del
  bosque, con su tramo de camino). En los solares grandes el edificio va a un lado (`offset`,
  `VillageLots.building_center`) y `VillageTrades.build_extras` dibuja campos con surcos, corral con animales (sprites de
  gallina y jabalí de momento), roca de cantera o troncos. Empiezan vacantes. Recetas propias (trigo con abono, lana y
  carne con pienso, piedra y madera con herramientas del herrero) y una receta más en los oficios de siempre que
  compra a los nuevos: panadero trigo, sastre lana, carnicero carne del rancho, carpintero troncos, herrero piedra (si
  el proveedor falta, fabrican más despacio, como siempre). Diálogo genérico de compra y venta desde `goods`
  (`VillageTrades.shop_dialogue`). **Jornaleros** (`scripts/systems/VillageWork.gd`, `vm.work_state`): a las 7 h
  (no en domingo) cada dueño con oro para un día contrata a parados (`UNEMPLOYED`) por sus huecos (granja 4, resto 2),
  primero los más pobres; aceptan un 90 % si tienen menos de 30 de oro (45 % si no; + diligencia). Marcas
  `day_job` / `day_job_pos` (no se guardan: al cargar se cancelan los jornales del día). Con jornal tienen horario de
  8 a 18 (`_is_mandatory_work_hours`) y deambulan en su sitio. Cada hora en su sitio y trabajando cuenta y produce
  (granja 0,25 trigo + 0,08 zanahoria; rancho 0,15 lana + 0,1 carne; cantera 0,3 piedra; leñador 0,35 madera; tope
  14). A las 18 h cobran 1 de oro por hora; si el dueño no llega, −8 de humor y −6 con él. **Lavadero** (−140, 105):
  un 30 % de los que van a lavarse (a menos de 700 px) van allí; al terminar charlan con quien esté (+1 y un chisme).
  **Sin probar en juego:** caminos hasta las afueras, que los jornaleros lleguen a tiempo y el equilibrio del dinero.
- [x] **V5e** Biblioteca, escuela, mercado y arreglos (`scripts/systems/VillageCulture.gd`, `vm.culture_state`, se
  guarda). Biblioteca en el solar n5 y escuela en e3 (clases de solar «library» y «school», edificio construido por
  `VillageCulture.build`). La biblioteca es un sitio más de `VillagePlaces` con `indoor: true`: con lluvia solo se elige
  ella (la lluvia ahora multiplica las ganas por 0,3 en vez de 0,15) y quien está dentro no se va por la lluvia; los
  «Curioso» la prefieren (+1,2), el resto un poco menos (−0,8). Cada llegada suma `readings` (para la escuela y la secta
  más adelante). El jugador lee en la mesa (E, `try_interact`, enganchado tras los cofres en la función de interacción
  de VillageManager) una vez al día: +12 de experiencia en cocina, alquimia, medicina, animales u oficio, al azar. La
  escuela tiene pupitres y pizarra y el cartel «Esperando alumnos»: el maestro llega con los niños (V9). **Mercado**
  (miércoles, `get_weekday() == 2`): a las 8 h las tiendas sanas con algún género ≥ 8 (las más lejanas primero, hasta 4)
  mueven su `work_position` a un puesto de la plaza; el original se guarda en `market_sellers` y se devuelve a las 13 h
  o al cargar. Cada hora (8–11) los vecinos libres con ≥ 6 de oro van un 25 % de las veces (encargo «market»), compran
  una pieza a 5 de oro al puesto más cercano (si es comida, +1 a la despensa de su casa) y +2 con el vendedor. Sin
  género de sobra no hay mercado. **Taller de Reparaciones** (solar e5, oficio `TINKER` 21 en `SHOP_ROLES`, receta kit
  de reparación con hierro del herrero): cada día, hasta 2 negocios saboteados cuyo dueño tenga 8 de oro pagan, el
  arreglador gasta un kit y les quita un día de avería. **Sin probar en juego:** que los vendedores lleguen a la plaza
  y vuelvan, la afluencia del mercado y de la biblioteca, y el precio de los arreglos.
- [x] **V3** Llegadas y marchas (`scripts/systems/VillageMigration.gd`, `vm.migration_state`, se guarda). Sustituye a la
  «Prioridad 4» de `_process_daily_map_edge_arrivals` (siempre 3 viajeros): ahora `VillageMigration.daily` (justo
  después) calcula el **atractivo** = 0,4·trabajo + 0,3·vivienda + pobreza + seguridad + comida. Trabajo: (tiendas
  vacantes·2 + huecos de jornal con dueño − parados) / 6, entre −1 y 1. Vivienda: camas libres en casas + 1 si queda
  cama de huésped en El Jabalí, /3 (−0,3 si no hay ninguna). Pobreza: −1,5 · proporción de mendigos. Seguridad: crónica
  sabida de los últimos 7 días (asesinato y muerto hallado −0,25, muerte por enfermedad −0,1, pelea −0,05; tope −1).
  Comida: −0,4 con escasez. Si el atractivo pasa de 0,05, llega alguien con probabilidad atractivo·0,8 (tope 0,6; a
  veces dos si pasa de 0,5), solo si hay cama (casa o El Jabalí) y menos de 50 vecinos (`POP_CAP`), respetando
  `MAX_DAILY_ARRIVALS`. Tipos: jornalero (8–25 de oro), artesano (70–130) o pareja (40–70 cada uno, +60 de relación;
  solo si hay casa con 2 camas). Siguen siendo `UNEMPLOYED` (jornales, sucesiones). **Casas**: `assign_houses` mete en
  las camas libres primero a quien pagó la casa, luego a quien duerme en la calle o el albergue, luego a los huéspedes
  (`lodging` = «house:<solar>», nueva familia `family_lot_<solar>`); en casa no pagan posada (`nightly`), salvo 2 de oro
  a las arcas en las casas del pueblo. `maybe_order_house`: sin camas libres en casas, con gente sin casa y atractivo
  ≥ 0,1 (o alguien en la calle), el carpintero levanta una casa en un solar libre del borde: la paga el más rico sin casa
  si tiene 80, si no las arcas si tienen 100. **Marchas** (como mucho una al día): solo parados sin casa, sin pareja y
  con menos de 2 amigos (relación ≥ 40), si el atractivo baja de 0,2; probabilidad (0,2 − atractivo)·0,5 si duerme en la
  calle o el albergue, ·0,15 si no (tope 0,3). Van andando al borde (encargo «leave», meta `leaving`, se reanuda cada
  hora) y allí desaparecen (`_free_transient_npc`, crónica «departure»). Dos solares nuevos para casas: n0 (190, −420),
  con la calle norte alargada, y e6 (1400, 140). **Ojo:** con los solares libres que quedan (n0, n1, e1, e6) caben unas
  8 personas más en casas; para llegar a 50 hará falta más sitio (más solares o casas más grandes). **Sin probar en
  juego:** el ritmo real de llegadas y marchas y que el pueblo no se vacíe ni se llene de golpe.
- [x] **V6** Nobles (`scripts/systems/VillageNobility.gd`, `vm.nobility_state`, se guarda). Probado (test #70). Oficio nuevo `NOBLE` (22, fuera de `SHOP_ROLES`): horario 10–13 h entre
  semana en su escritorio («Administrando sus tierras»), el resto libre. Mansión en f1 (clase «mansion», 180×120, 3
  camas, familia `family_lord`) con el **señor**, su pareja (casados: `partner_id` y `ROMANCE_PARTNERED`) y el heredero;
  casa grande en f2 (clase «manor», 2 camas, `family_rentiers`) con dos rentistas. Aparecen una vez en la primera hora
  de juego (`spawn_households`, también en partidas viejas). Oro 140–460: son «rico» (secta de ricos aburridos,
  impuestos de rico). **Rentas** los lunes (`collect_rents`): los dueños de la granja y el rancho pagan el 10 % de su
  oro (3–20); quien paga −2 con el señor, quien no puede −3 y el señor −5 con él. Si el señor muere o se va, manda el
  mayor de la mansión (`lord_of`). **Elecciones**: `VillageTown.vote_of` suma `VillageNobility.sway` (+25 al favorito
  del señor) a los arrendatarios y a sus jornaleros.
- [x] **Solares para crecer** (probado: sin solapes, test #69): fila m1–m5 en y −580 (x 330…910, puerta al sur) con una calleja
  nueva (y −526) y su enlace con la calle norte en x 980. Con n0, n1, e1, e6 quedan 9 solares de casa (18 camas).
- [x] **V9** Hijos (`scripts/systems/VillageFamily.gd`, `vm.family_state`, se guarda). Probado (test #71). Oficios nuevos `CHILD` (23) y `TEACHER` (24). Cada día una pareja (ella 18–42, él ≥ 18, con casa, sin ser de
  fuera, relación media ≥ 30, menos de 3 hijos, 40 días desde el último) puede esperar un hijo: 1,2 % × relación ×
  dinero × humor × edad × hijos (tope 5 %). Embarazo de 9 días; el bebé nace en casa con el apellido del padre y un
  rasgo de cada progenitor (`roll_balanced`), +80 con sus padres y +40 con sus hermanos; dibujo de adulto a escala
  0,55–1. Crecen un año cada 4 días (`CHILD_YEAR_DAYS`, decidido por el usuario) contando desde `born`; a los 16 pasan a
  `UNEMPLOYED`, `lodging` = «family» (siguen en casa sin pagar posada; VillageMigration los puede mudar a una casa
  libre) y sus padres les dan 10 de oro. **Escuela**: con 2 niños de 6+ y sin maestro, se hace maestro el vecino sin
  oficio de 20+ más curioso/paciente/diligente o, si no hay, llega uno; cobra 5 al día de las arcas (si no hay, se
  queja). Los niños apuntados (`school_pos`, no se guarda: se recalcula a diario y al cargar) van de 9 a 14 h entre
  semana a su pupitre; a las 14 h cuentan `lessons`. Filtros de edad: sin romance (<18, `compute_compatibility`), sin
  peleas (<16), no votan ni se presentan (<16, también al mandar a votar), la secta ya tenía `MIN_AGE`. Crónica:
  «pregnancy», «birth», «grown_up», «teacher». El cartel de la escuela ya dice si está abierta, quién enseña y cuántos
  alumnos hay (bloque B). **Sin probar en juego:** nada de esto (solo los tests).
- [x] **V7** Medición (`tools/tests/growth_probe.gd -- <días> <semilla>`, con `--fixed-fps 60`). Ejecutada en el
  bloque D (resultados en `docs/REGISTRO_TRABAJO.md`). Fase 1: deja correr la partida y apunta cada día población, llegadas,
  marchas, casas, embarazos, nacimientos, niños, maestro y atractivo. Fase 2: completa hasta 50 vecinos con casas y
  recién llegados y mide el fotograma (plaza y lejos) y el coste de una hora de juego.
- [x] **UI1** Menú del diálogo ordenado (`NPCDialogue._organize_start`, al final de `_inject_character_lore_into_dialogue`).
  Arriba lo del momento (comercio, encargos, juicio, avisos…); se agrupan por `next`/`action` (no por el texto)
  «🗣️ Charlar…» (`TALK_NEXT`), «🎁 Invitar o regalar…» (`GIFT_ACTIONS` y `gift_*`) y «🕵️ Lo turbio…» (`SHADY_NEXT`; si un
  grupo tiene una sola opción, queda suelta); luego «📋 Ver ficha» (`npc_ficha`: la línea de estado completa y la red
  social) y Salir. La cabecera cambia la línea de estado larga por `_short_status` (actividad, humor y mostrador). «Manipular
  testigo» solo sale con un caso abierto (`_case_open`: investigación del comisario o del inquisidor, o el vecino va a
  denunciar un cuerpo); el aviso urgente «🚨 ¡Detener reporte!» sigue arriba. Nobles y niños ya no muestran «Dominio».
- [x] **Bloque B/C/D** (trabajo autónomo, detalle paso a paso en `docs/REGISTRO_TRABAJO.md`; probado: tests #73, #74 y la
  sonda). Solares n6 y m6 añadidos (11 de casa en total; con todos construidos se llega a 50). Con 50 vecinos: 5,7 ms
  por fotograma en la plaza, peor 22 ms.
- [x] **Bloque F** (test #76). `VillageWork.hire`: el dueño se guarda 20 de oro (`OWNER_FOOD_RESERVE`) y solo contrata
  los jornaleros que llenan el hueco del producto principal (`workers_needed`); antes se arruinaba contratando con el
  almacén lleno. El diagnóstico de comidas fallidas distingue `sin_oro`, `agotado` y `caro_o_cerrado`.
- [x] **Bloque G** (test #77). `VillageFamily.pay_helpers`: el ayudante de negocio familiar con menos de 15 de oro
  recibe 6 al día del dueño de su familia (si al dueño le quedan 20). La sonda apunta además la hora de cada comida
  «cara o cerrada». Comidas fallidas en 12 días: de 58 a 16.
- [x] **Bloque H** Casas a plazos (test #78; `scripts/systems/VillageLoans.gd`). Casa 100 de oro. Con 15 de entrada (con
  la pareja) se pide el resto a las arcas (si les quedan 40) o al noble más rico (si le quedan 50); se devuelve +25 % a 3
  al día. Impago: +1 de recargo, −6 de humor, el noble −4; a los 5 seguidos, la casa pasa al prestamista y los moradores
  van a la posada o a la calle. El préstamo vive en `lots_state[id]["loan"]`. Casa de otro: el alquiler de 2 va a su
  dueño. Ficha («🏦 Debe…») y crónica (`loan`, `loan_paid`, `eviction`). Sonda: 2 casas a plazos en 12 días.
- [x] **Bloque I** Mapa grande: ocupa casi toda la pantalla, nombres sin pisarse (fondo, versión corta, debajo u
  omitido) y el cursor da el nombre completo de cualquier edificio. Sin probar en juego.
- [x] **Bloque J** (test #79). Caza: el cazador prefiere ciervos y conejos (`EcosystemManager.find_sustainable_hunt_prey`);
  con un jabalí embistiendo y salud ≤ 50 % se retira (`VillageNPC.should_flee_boar` / `flee_from_boar`, el jabalí se calma
  en 2 s); el jabalí no embiste a quien está en el suelo. Heridas con nombre (`death_cause_for_source`); hambre, animal y
  enfermedad (`is_natural_death_cause`) no abren caso: crónica «Hallaron el cuerpo sin vida de X: lo mató un jabalí» y
  registro de morgue resuelto. Arcas de partida nueva: 1000 (`VillageTown.STARTING_TREASURY`). Gachas del albergue
  (`VillageCivic.cook_shelter_rations` a las 6 h, `take_shelter_ration` como último recurso de la comida). Sonda: 0 comidas
  fallidas y 0 muertes en 12 días.
- [x] **Bloque K** (test #80). Cantero: trabaja fuera, en la roca (`VillageTrades.yard_pos`, `fix_quarry_post` cada día);
  cada obra compra 3 de piedra al cantero y 3 troncos al leñador (`VillageLots.buy_materials`, 20 % del coste cada uno).
  Misiones sobre un vecino: hablar con el objetivo pone primero a quien la pidió y un atajo «📜 Encargo»
  (`NPCDialogue`); aviso «⏳ Hoy ya has intercedido» y pista si te tiene en negativo.
- [x] **Bloque M, tanda 1** (test #81). 10 tipos de misión nuevos en `scripts/systems/quests/types/` (tabla en
  `docs/MISIONES.md`). La oferta diaria sortea entre todos los tipos que encajan (`VillageQuests`). Ayudas nuevas en
  `QuestType` (`charge_player`, `charisma`…). `VillageFaith.wants_attend` respeta `rite_invited_week`; `finish_rite` guarda
  `last_attendees`. Tanda 2 pendiente.
- [x] **Bloque M, tanda 2** (test #81 ampliado). Otros 10 tipos (tabla en `docs/MISIONES.md`): 25 en total. Marcas nuevas
  que leen las misiones (`evicted_day/lot` en VillageLoans.evict, `inherited_day/from/family` en `VillageManager._note_inheritance`,
  `read_day` en VillageCulture.on_read, `arrived_day` en `VillageMigration._spawn_one`, `rite_invited_week` y `new_clothes_day`)
  guardadas en `VillageNPC.to_save_dict` / `from_save_dict` (`quest_marks`). Veto de taberna: `VillageNeeds.state.no_serve`
  (sí se guarda; `do_vice` no sirve).
- [x] **Bloque N — Guardado de marcas y revisión de las 13 misiones en 🟡** (test #81 ampliado con las 25 misiones y K2).
  1) Guardadas en `VillageNPC` las marcas de desahucio, herencia, lectura, llegada, invitación al Oficio y ropa nueva.
  2) `NPCDialogue` (K2): el atajo «📜 Encargo: hablarle de…» ahora funciona también al hablar con terceros en misiones de
  calumnia (`slander`, poniendo al rival primero) y deja de salir por error en encargos que no usan el menú de opiniones.
  3) `QuestAffairDoubt`: solo se ofrece si al menos un vecino vio la aventura (`known_by` no vacío).
  4) `QuestLoanTrouble`: no rompe el diálogo si hablas con el deudor el mismo día del desahucio; corregido texto «a al alcalde».
  5) `QuestHomeless`: darle los 18 de oro para la posada le devuelve cama bajo techo en el acto (antes seguía acampado hasta medianoche y si cenaba perdía el umbral).
  6) `QuestStrangeNewcomer`: descubrir rasgos del recién llegado por cualquier vía también cuenta para cumplir el encargo.
  7) Limpiados los 19 avisos amarillos del editor (divisiones enteras, ternarios heterogéneos y parámetros sin usar) más 7 divisiones enteras en los encargos de vecinos.
  8) `scenes/dialogue_manager.gd`: el cuadro de conversación lleva ahora barra de desplazamiento para las opciones (`_choices_scroll`, hasta 6 visibles a la vez), recorte con puntos suspensivos en botones largos y tope de líneas en cabecera y cuerpo, de modo que nunca se sale por los bordes de la pantalla.
  9) `scenes/ui_root.gd` y `scripts/ui/ObjectiveHUD.gd`: ocultado el viejo `ObjectiveHUD` en inglés («Eliminate Frogs» / «Find the Iron Sword») que asomaba cortado encima del minimapa.
  10) `scenes/ui_root.gd`: barras de estado más finas y cortas (`108×12`, solo icono y porcentaje/valor) y dinámicas: Hambre, Sueño e Higiene se ocultan cuando están al 75 % o más y solo aparecen cuando bajan.
- [x] **Bloques P1–P7 — Clanes, forense, linaje, confesión, alcaldía, vivienda e inframundo** (test #82; auditado en `docs/AUDITORIA_P1_P7.md`, arreglos en PA/PB + 29 mecánicas adicionales en Tandas 1–6):
  1) **P1 (`scripts/systems/VillageClans.gd`)**: estado en `vm.family_state["clans"]`. Heredar enemistades al morir (`on_npc_death`), feudos de sangre (`feuds`, `declare_blood_feud`), boicot comercial y sobreprecios (`player_price_mult`, `is_boycotting_player`), amores prohibidos entre clanes rivales (`romeo_pairs`), venganza de huérfanos al cumplir 16 (`orphan_killers`, `on_child_grown_up`), paz entre clanes (`mediate_clan_peace`), desheredar ovejas negras (`disowned`), deuda de honor (`grant_honor_debt`), testamentos disputados (`wills`), tumbas profanadas (`desecrated_graves`), patriarca/matriarca del clan (`patriarch_of`, `clan_patriarch_sway`) y sabotajes nocturnos entre talleres de clanes enemistados (`_daily_clan_sabotage`, `clan_inspect_sabotage`, `clan_report_sabotage`).
  2) **P2 (`scripts/systems/VillageForensics.gd`)**: estado en `vm.town_state["forensics"]`. Pistas plantadas (`planted`), coartadas falsas de familia/pareja/secta (`alibis`), testigos intimidados (`tampered`), crímenes por encargo y contrato al jugador (`hitmen`, `player_contracts`), veneno lento que simula muerte natural hasta la autopsia (`poisoned`), incriminar vecinos (`forensic_frame`), cadáver movido de noche (`moved`), confesiones ebrio o con fiebre (`slips`), chivo expiatorio (`scapegoats`), emboscadas nocturnas (`forensic_ambush`), fregar la escena con lejía (`bleach_crime_scene`, `try_interact` con doble E), sobornar al médico para falsear la autopsia (`forensic_bribe_autopsy`), pólizas de seguro de vida sospechosas (`insurance`, `forensic_check_insurance`, `forensic_expose_insurance`), trucar la hora de la muerte (`tampered_time`, `forensic_check_rigor`), limpiador nocturno de cadáveres (`forensic_hire_cleaner`), crímenes por imitación (`copycats`, `forensic_debunk_copycat`) y forzar confesión falsa con chantaje (`has_known_dirt_on`, `forensic_force_confession`).
  3) **P3 (`scripts/systems/VillageLineage.gd`)**: estado en `vm.family_state["lineage"]`. Hijos secretos de aventuras (`secret_preg`, `bastards`, `on_child_born`), rumor por parecido a los 6 años, chantaje o revelación de paternidad (`reveal_paternity`, `rename_child` sincronizando registros por nombre), manutención los lunes, expósitos en la capilla (`foundlings`, `leave_foundling_at_chapel`), adopción por parejas o por el jugador (`adopt_child_by_couple`, `adopt_child_by_player`), rivalidad de hermanastros a los 16 asignando `FAMILY_MEMBER` del taller (`sibling_rivalries`), cazafortunas (`gold_diggers`), deudas del pasado (`estranged_past`), interceptar cartas de amantes (`love_letters`, `lineage_intercept_letter`, `lineage_deliver_letter`, `lineage_expose_letter`), bodas concertadas con dote (`arranged_marriages`, `lineage_arrange_wed`, `lineage_arrange_refuse`), padrinos de bautizo (`godparents`, `lineage_become_godparent`), enseñar un oficio a un niño (`mentored_kids`, `lineage_mentor_child`) y escapadas nocturnas de jóvenes al mirador (`send_lovers_to_mirador`, `lineage_catch_mirador`).
  4) **P4 (`scripts/systems/VillageConfession.gd`)**: estado en `vm.faith_state["confession"]`. Confesión martes y jueves (`on_hour`), espiar tras la celosía, sacerdote corrupto que vende secretos, penitencias al día siguiente (`penances`), excomunión (`excommunicated`, `is_excommunicated`), confesarse el jugador, bulas de indulgencia (`indulgences`), sermón dominical con indirectas (`apply_sunday_indirect_sermon`), crisis de fe del sacerdote (`priest_doubt`), derecho de santuario en la capilla (`sanctuary_day`), disfrazarse con el hábito del cura en el confesionario (`faith_impersonate_priest`) y fingir un milagro en el altar (`faith_stage_miracle`).
  5) **P5 (`scripts/systems/VillageMayor.gd`)**: estado en `vm.town_state`. Candidatura del jugador (`player_candidate`, `VillageTown.hold_election`), promesas de campaña (`promise`), discursos (`speech_done`), debates públicos entre candidatos (`town_debate`) y trapos sucios (`smeared`), nivel de impuestos (`tax_mode`, `tax_multiplier`), decretos (`toggle_decree`: `dry_law`, `curfew`, `market_subsidy`, `peace_tax` con multa de `apply_peace_tax` en `VillageSocialLife._finish_live_fight`), indultar acusados y rehabilitar repudiados (`town_pardon`), obras públicas con las arcas, nombrar comisario (`appoint_new_sheriff`), desfalco y maquillar libros (`player_embezzle_risk`), alcalde títere (`puppet_mayor`) y moción de destitución con firmas y espera de 30 días (`recall_sigs`, `last_recall_day`).
  6) **P6 (`scripts/systems/VillageHousing.gd`)**: estado en `vm.lots_state` y `vm.town_state["housing"]`. Compra de solar al contado o con hipoteca (`buy_house_cash`, `buy_house_loan`, doble E para confirmar) y reventa según atractivo y mejoras (`house_sale_price`, `housing_sell_house`), cama propia nocturna (`sleep_until_morning`) y cofre privado (`is_player_family_chest`), mejoras con el carpintero (`upgrades`: `bookshelf`, `workbench`, `oak_bed`, `strong_lock`, `hidden_cellar` con `housing_hide_cellar`, `hearth` con `rest_by_hearth`), defender la puerta de intrusos nocturnos (`intruder_attempt`, `housing_repel_intruder`), mudanza de pareja (`move_into_player_home`), ser casero y cobrar alquiler (`VillageMigration.nightly`), subir/perdonar renta y desahuciar, huerto casero (`has_garden`), cenas (`last_dinner_day`) y fiestas en casa (`last_party_day`, `housing_party`), escondite bajo las tablas (`has_stash`, `stash_gold`) y escrituras de locales (`commercial_deeds`).
  7) **P7 (`scripts/systems/VillageUnderworld.gd`)**: estado en `VillageNeeds.state(vm)["underworld"]`. Perista nocturno (`get_fence_npc`), compra de herramientas ilegales (`lockpick`, `slow_poison` con efecto al día siguiente y riesgo de testigos, `sleeping_draught`, `false_papers`), destilar y vender «polvo de ocaso» (`dusk_dust`), caravana de contrabando de medianoche (`caravan_gold`, `underworld_caravan_buy`, `underworld_caravan_sell`, `underworld_caravan_report`), encargos de robo en el lugar (`active_heist`, `try_interact`), usura (`usury_loans`), cobro de «protección» los sábados (`rackets`), saboteadores y ladrones a sueldo (`hired_jobs`), red de carteristas (`pickpockets`, `underworld_recruit_pickpocket`, `run_pickpocket_network`), falsificar escrituras municipales (`forged_deed`, `underworld_forge_deed`), timbas clandestinas de dados (`play_dice_bet`, `underworld_dice_bet`), club de pelea clandestino a medianoche, soborno de patrulla (`is_guard_bribed_tonight`), delatar al perista y retar cara a cara al jefe de la «Red de las Sombras» (`underworld_challenge_boss`, `underworld_takeover_boss`).
- [x] **Bloque PF — Fama de los vecinos y Maestros Artesanos con estilo propio** (`scripts/systems/VillageFame.gd`, test #83):
  estado en `vm.culture_state["fame"]`. Puntuación de fama/infamia individual (`-100..100`, `fame_of`, `tier_label`, `add_fame`) conectada a peleas (`VillageSocialLife._finish_live_fight`), robos descubiertos (`VillageCrime.catch`), infidelidades destapadas (`VillageSecrets.partner_reaction`), asesinatos resueltos (`VillageClans.on_murder_resolved`), mercado (`VillageCulture.on_market_arrived`) y alcaldía; ascenso a Maestro Artesano con estilo de autor propio de cada gremio (`STYLE_BY_ROLE`, `promote_to_master`, `is_master`) despertando las tendencias `fame`, `craft` y `trade` en `TraitCatalog.gd`; elaboración periódica de Obras Maestras firmadas (`masterwork_piece` en `SimpleInventory.gd`) compradas por ricos/nobles de su bolsillo (`personal_gold`) o por el jugador (`fame_buy_masterwork`, `fame_sell_masterwork`, `fame_gift_masterwork`, `fame_patronize`, `fame_praise`, `fame_tarnish`); visible en `SocialGlossaryUI.gd` y `NPCDialogue.gd`.
- [x] **Bloque PG — Graduación escolar con ventaja de oficio y Negocio propio del jugador con publicidad** (`scripts/systems/VillageFamily.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/systems/VillageHousing.gd`, test #84):
  1) Asistencia individual a clase a las 14:00 (`pupil_lessons` en `VillageFamily.state`); al cumplir los 16 años (`grow_up`), el alumno graduado recibe `school_bonus_days` (`1..4` días de dominio según clases asistidas, guardado en `SAVED_INT_METAS`), que se suma a `days_in_role` al estrenarse en cualquier oficio (`VillageNPC.promote_to_trade`).
  2) Fundar tu propio negocio desde cero en un solar construido (`found_player_shop`, `housing_found_shop`, 65 de oro al carpintero), abastecer el mostrador con artículos reales de la mochila (`stock_player_shop`, `housing_stock_shop`), contratar a un vecino sin oficio como dependiente (`housing_hire_clerk`, cobra 4 de oro al día de la caja), hacer publicidad por el pueblo (`advertise_player_shop`, `housing_advertise_shop`, 12 de oro a las arcas con espera de 3 días) y recaudar las ventas diarias que los vecinos pagan de su bolsillo (`housing_collect_shop`).
- [x] **Bloque PH — Idolatría / obsesión por un personaje y Acompañantes del jugador** (`scripts/systems/VillageFame.gd`, `scripts/enemies/VillageNPC.gd`, test #85):
  1) Idolatría / obsesión muy rara (`obsessions` en `VillageFame.state`, `try_spawn_obsession`): un vecino solitario se obsesiona con alguien de alta fama (`>= 35`), le envía regalos anónimos pagados de su bolsillo (`OBSESSION_GIFT_COST`), le sigue (`obsession_follow`) y siente celos extremos (`-8` relación) hacia quienes se le acercan; el jugador puede tantear a cualquier adulto una vez al día (`fame_probe_obsession`, sin destripar en el menú quién es), hacerle entrar en razón (`fame_calm_obsessed`) o avisar al afectado a cambio de una recompensa de su bolsillo (`fame_warn_idol`).
  2) Acompañantes del jugador (`companion` en `VillageFame.state`, `is_companion`, `companion_npc`): un amigo leal (`affinity >= 55`, `fame_companion_invite`) o un escolta contratado (`15` de oro al día de tu bolsa a su bolsillo, `fame_companion_hire`) camina junto al jugador (`VillageNPC._process_duties`), le respalda ante otros vecinos una vez al día con tirada de riesgo (`fame_companion_backup`) y puede ser despedido en cualquier momento (`fame_companion_dismiss`).
- [x] **Bloque PI — Animales con etapas de crecimiento y crianza y Carreras / peleas de animales con apuestas** (`scripts/systems/VillageHousing.gd`, `scripts/systems/VillageUnderworld.gd`, test #86):
  1) Cría y crecimiento (`ranch_herd` y `player_animals` en `VillageHousing.state`, `animal_stage_for_days`, `buy_young_animal`, `feed_player_animals`): las crías pasan por `chick` (0–2 días) → `juvenile` (3–5 días) → `adult` (6+ días), aportando lana/carne al rancho o carne y vigor competitivo al corral del jugador (`housing_buy_chick`, `housing_feed_animals`).
  2) Carreras de animales (`run_animal_race`, `underworld_animal_race`, 12 de oro contra el bolsillo del vecino, 1/día) y peleas clandestinas de gallos/perros (`run_cockfight`, `underworld_cockfight`, 15 de oro contra el bolsillo del vecino, 1/día, con riesgo del 15 % de alerta policial), bonificadas por el vigor de los animales adultos criados (`best_adult_animal_power`).
- [x] **Bloque PJ — Amputaciones e implantes / prótesis médicas y Sabotaje lógico de la red eléctrica** (`scripts/systems/VillageIllness.gd`, `scripts/systems/VillageCulture.gd`, `scripts/systems/VillageManager.gd`, `scripts/obstacles/FarmPlot.gd`, test #87):
  1) Amputaciones e implantes protésicos (`amputations` en `VillageNeeds.state`, `amputate`, `install_prosthetic`): el médico amputa de urgencia extremidades con gangrena (`infection >= 65.0`), poniendo `region_hp` a `0.0` y curando la herida; las prótesis articuladas de hierro y cuero (`PROSTHETIC_COST = 25`, `illness_prosthetic_self`, `illness_prosthetic_npc`) o compradas automáticamente por vecinos con fondos reparten el pago entre el médico (`15`) y el arreglador (`10`), consumen `1` `repair_kit` y restauran el miembro.
  2) Red eléctrica lógica con circuitos independientes (`grid` en `VillageCulture.state`, `is_lamps_powered`, `is_sprinkler_powered`, `sabotage_grid`, `repair_grid`): permite sabotear por separado el circuito de farolas (`lamps`), el de riego (`sprinkler`) o el generador general (`all`) con tirada de riesgo (`culture_sabotage_grid`), y repararlo con `1` `copper_coil` cobrando de las arcas (`culture_repair_grid`) o mediante la reparación diaria del arreglador pagada por el ayuntamiento.
- [x] **Bloque PK — Sembrar árboles que influyan en el ecosistema y Rutas de comercio con otros lugares** (`scripts/systems/EcosystemManager.gd`, `scripts/systems/VillageCulture.gd`, test #88):
  1) Reforestación y suelo vivo (`plant_sapling`, `count_live_trees` en `EcosystemManager.gd`; `forest_state`, `plant_forest_tree`, `culture_plant_tree`, `culture_buy_sapling` en `VillageCulture.gd`): plantar un pino joven añade un nodo `HarvestableNode` (`LOGGING`) real al bosque, regenera flora silvestre agotada, atrae fauna (`deer_pool` / `rabbit_pool`) y eleva `soil_fertility`, que en el ciclo diario aporta madera extra al leñador y trigo extra a la granja.
  2) Rutas de comercio exteriores (`trade_routes_of`, `open_trade_route`, `process_trade_routes`, `send_player_shipment`, `culture_open_route`, `culture_ship_route` en `VillageCulture.gd`): tres rutas («Paso Alto», «Puerto Fluvial del Este», «Vega del Sol») que se abren pagando `25` de oro a las arcas municipales, intercambian a diario excedentes de los talleres por suministros importados pagando del fondo de la ruta al artesano y al ayuntamiento, y permiten al jugador enviar una remesa diaria de su mochila.
- [x] **Bloque PL — Árbol de investigación tecnológica e Incursiones organizadas contra el pueblo** (`scripts/systems/VillageCulture.gd`, test #89):
  1) Árbol de investigación (`TECH_TREE`, `research_state`, `has_tech`, `start_research`, `advance_research`, `culture_start_tech`, `culture_boost_tech`): tres tecnologías encadenadas («Engranajes Hidráulicos», «Cerraduras y Empalizadas de Precisión», «Condensadores Voltaicos») financiadas al ingeniero, aceleradas con lecturas de la biblioteca o con `bandit_scrap`, que otorgan mejoras permanentes al pueblo.
  2) Incursiones organizadas contra el pueblo (`raids_state`, `start_raid_warning`, `defense_power`, `resolve_raid`, `culture_fund_militia`, `culture_lead_defense`): aviso previo de asalto, financiación de barricadas y milicia (`15` de oro a las arcas, `+2` defensa), resolución ponderada por comisario, guardias, tecnología y milicia, con recompensa de las arcas si se repele o saqueo de las arcas y daños si fracasa la defensa.
- [x] **Bloque PM — Expediciones de exploración y hallazgos arqueológicos y Caballos / Carretas de carga en el rancho** (`scripts/systems/VillageCulture.gd`, test #90):
  1) Monturas y carretas de época en el Rancho (`mounts_state`, `has_horse`, `has_cart`, `buy_mount`, `culture_buy_horse`, `culture_buy_cart`): el Caballo de Silla (`45` de oro al ganadero) aumenta la velocidad y suma `+15 %` de éxito en expediciones; la Carreta de Carga (`55` de oro al ganadero) suma `+4` de oro extra del fondo de ruta por cada remesa comercial enviada (`send_player_shipment`).
  2) Expediciones de exploración (`EXPLORATION_SITES`, `exploration_state`, `run_expedition`, `culture_expedition`): tres enclaves («Ruinas de Cobre del Oeste», «Grutas de Cristal del Norte», «Atalaya Hundida del Pantano»), 1/día pagando `12` de oro en víveres al guía, con tirada de riesgo que puede fallar o aportar reliquias (`copper_coil`, `iron_ore`, `herbs`) y `+2` lecturas a la biblioteca.
- [x] **Bloque PN — Niveles verticales por capas (`elevation_level`) y Alcantarillas con localizaciones subterráneas** (`scripts/enemies/VillageNPC.gd`, `scripts/systems/VillageManager.gd`, `scripts/systems/VillageHousing.gd`, `scripts/systems/VillageUnderworld.gd`, test #91):
  1) Sistema de niveles verticales por capas en las mismas coordenadas (`elevation_level` en `VillageNPC`, `player_elevation_level`, `are_on_same_elevation`, `distance_on_same_level`, `set_player_elevation_level`, `set_npc_elevation_level` en `VillageManager.gd`): filtra automáticamente `_find_conscious_witness_near` por nivel (`-1` sótano/alcantarillas, `0` calle, `1` primer piso), atenúa visualmente a los vecinos de otros niveles y añade la mejora `"upper_floor"` (`50` de oro al carpintero) y `housing_change_level:*`.
  2) Red de alcantarillas bajo el pueblo (`SEWER_LOCATIONS`, `sewers_state`, `unlock_sewers`, `explore_sewer_location`, `underworld_unlock_sewers`, `underworld_sewer_explore:*`, `underworld_sewer_surface`): tres localizaciones en el nivel `-1` («Cisterna Vieja bajo la Plaza», «Pasadizo del Contrabandista» que además rebaja `wanted_level`, y «Bóveda Inundada del Antiguo Gremio»), con exploración 1/día con riesgo de aguas negras/ratas y saldo finito de monedas caídas (`lost_coins_pool`, nutrido de monedas extraviadas por vecinos solventes).
- [x] **Bloque PO — Armas de fuego de chispa y Terminales lógicas / Hackeo electromecánico** (`scripts/systems/SimpleInventory.gd`, `scripts/systems/VillageCulture.gd`, test #92):
  1) Armas de fuego (`flintlock_pistol`, `powder_charge` en `SimpleInventory.gd`; `buy_firearm`, `buy_powder_pack`, `has_loaded_firearm`, `fire_flintlock_shot` en `VillageCulture.gd`): requiere `"reinforced_locks"`, cuesta `60` de oro al herrero/arreglador (`14` por `2` cargas de pólvora), añade `+3` a `defense_power` frente a incursiones y permite disparar consumiendo `1` `powder_charge` con alerta por estruendo en `260` px.
  2) Terminales lógicas electromecánicas y hackeo (`terminal_state`, `hack_terminal`, `culture_hack_terminal:*` en `VillageCulture.gd`): 1/día con tirada de riesgo (bonificada por `"voltaic_capacitors"` y `"copper_coil"`), permite desviar hasta `18` de oro reales de `town_state["treasury"]` (`census_ledger`), purgar `1` nivel de `wanted_level` y `25` de `bounty_gold` (`warrant_archive`) o reparar la red y extraer `+2` lecturas (`grid_controller`), o sufrir descarga y alarma policial si falla.
- [x] **Bloque PP — Crear tu propio asentamiento fronterizo («Puesto del Paso») e Historia Principal en 4 capítulos (panel `[L]`)** (`scripts/systems/VillageCulture.gd`, `scripts/systems/QuestManager.gd`, test #93):
  1) Asentamiento fronterizo del jugador (`outpost_state`, `found_outpost`, `recruit_outpost_settler`, `upgrade_outpost`, `process_outpost_daily`, `collect_outpost_treasury`): fundación por `90` de oro (`70` a las arcas municipales + `20` de fondo inicial del puesto) y `2` de madera + `2` de piedra, reclutamiento de hasta `3` colonos desempleados (`15` de oro de adelanto a su bolsillo y jornal diario de `3` de oro), mejoras (`sawmill`, `granary`, `watchtower` por `35` de oro al artesano) y recaudación del excedente real de peajes comerciales dejando reserva de jornales.
  2) Historia Principal en 4 capítulos (`MAIN_STORY_CHAPTERS`, `main_story_state`, `sync_main_story`, `culture_sync_main_story` en categoría `"main"` de `QuestManager`): cuatro capítulos encadenados («I. Las Raíces del Valle», «II. El Pulso Bajo la Piedra», «III. La Máquina de Cobre», «IV. La Placa de Petri») visibles en la pestaña «👑 Principal» del panel `[L]` con recompensas reales abonadas por las arcas municipales.
- [x] **Bloque PQ — Escalado de población a 100+ vecinos, solares de la ronda norte (`u0..u6`), casas ampliables a 4 camas con altillo y LOD multi-nivel** (`scripts/systems/VillageMigration.gd`, `scripts/systems/VillageLots.gd`, `scripts/systems/VillageHousing.gd`, `scripts/enemies/VillageNPC.gd`, test #94):
  1) Techo de población ampliado (`POP_CAP = 100` en `VillageMigration.gd`), nueva ronda norte de 7 solares residenciales (`u0..u6` en `VillageLots.LOTS`) y ampliación vertical de casas ya construidas con altillo (`expand_house_upper_floor`, `_house_beds(id, true)` con 4 camas por casa, activada automáticamente en `VillageMigration.maybe_order_house` cuando se agotan los solares libres o al instalar `"upper_floor"` en `VillageHousing.gd`).
  2) Simulación simplificada multi-nivel y de larga distancia (`_lod_far()` y `_lod_step_for_npc()` en `VillageNPC.gd`): los vecinos que se encuentran en otra capa vertical (`elevation_level != vm.player_elevation_level`) o muy alejados pasan a paso simplificado doble (`LOD_STEP * 2 = 8` fotogramas), manteniendo el desplazamiento exacto mediante `_lod_k`.
- [x] **3D de verdad (Claude Code, 2ª noche, 2026-11-06)** (`CharacterAvatar3D.gd`, `WorldStage3D.gd`, `FishingSpot.gd`, `VillageWork.gd`, `EcosystemManager.gd`/`VillageManager._load_tex`). Registro en `docs/REGISTRO_ESTETICA_3D.md`, «Segunda noche».
  1) **Muñecos en el escenario.** Con ventana, `CharacterAvatar3D` mete el rig en `WorldStage3D.stage_root_3d/Characters3D`
     dentro de un `_holder` con escala `(K, K/cos_p, K)`, `STAGE_K = 0.40`, y pies a `FOOT_OFFSET_PX`. Si el escenario se
     libera, `_process_in_stage` reconstruye el rig. El modo antiguo de SubViewport queda en `_setup_own_viewport`, que
     no se usa. Corregido allí que el SubViewport del jugador no se reactivaba tras F9.
  2) **Escenario:**
     - `VIEWPORT 1280×720`, sombras del sol (`SHADOW_ORTHOGONAL`, máx. 140) y `stage_sprite.z_index = -2`. Los objetos
       2D con z = -1 (huertos, pozos, camas) quedan por encima; los decorados con z ≤ -3 quedan tapados por el suelo 3D
       (`_build_ground_3d`);
     - `_sync_2d_flat_visuals` oculta también los sprites, TextureRect y Polygon2D con z ≤ 0 dentro de las huellas de
       edificios, y se repite cada 4 s;
     - **naturaleza:** `_scan_nature_sources` (grupo `destructible` con `harvest_type` 1 o 2, y sprites con textura de
       pino, que se reconoce por `resource_path` o la meta `src_path`, puesta ahora por `_load_tex`) y
       `_sync_nature_3d`;
     - **tejados:** `_add_prism_2d` y `_add_pyramid_2d`, con la variación por `b_id.hash()`.
  3) **Lago:** `FishingSpot.LAKE_WATER_WORLD` y `lake_scaled()`, usados por el 2D y por `WorldStage3D._build_lake_3d`.
     `VillageWork.LAVADERO_POS` pasa a `(-140, 84)`.
  4) **Quitados** los adornos de `_build_static_terrain_3d`: animales, carro, cajas, compostador 3D y el lago falso en
     (-250, -140).
  5) **Trampa:** `stage_sprite` en z = -2 deja por encima todo lo 2D con z ≥ -1. Si un objeto 2D nuevo «flota» sobre
     el 3D, súbelo o bájalo de z, o añádelo a `_sync_2d_flat_visuals`.
- [x] **Estética retro 3D (Claude Code, 2026-11-05): animaciones reales, texturas pixeladas, pixelado global y día/noche** (`scripts/visuals/CharacterRig3D.gd`, `CharacterAvatar3D.gd`, `WorldStage3D.gd`, `AssetLibrary3D.gd`, `RetroPostFX.gd`, `shaders/retro_post_fx.gdshader`, `scripts/World.gd`, `scripts/systems/WorldClock.gd`, `tools/bake_character_animations.gd`, `tools/screenshot_3d.gd`). Registro paso a paso en `docs/REGISTRO_ESTETICA_3D.md`.
  1) **Animaciones:** Quaternius UAL 1+2 (CC0). `tools/bake_character_animations.gd` las adapta al esqueleto con
     reposo_personaje · inverso(reposo_animación) · rotación. Solo la pelvis conserva su posición, escalada. Salen
     `assests/curated_3d/animations/ual_{male,female}.res` (28 clips). `CharacterRig3D._setup_anim_player` /
     `_pick_clip` / `_apply_real_animation` los usan; si falta la librería, vuelve a `_apply_skeleton_pose`.
  2) **Texturas:** se cambiaron las `village/T_*` que borró Gemini por `town_textures/` (Kenney Retro Textures Fantasy,
     64 px) con `RETRO_TRIPLANAR_SCALE = 0.78`. `_style_for_building` elige muro, tejado y suelo por tipo.
     - Puertas y ventanas: `_make_texture_panel` + `_panel_mat`.
     - Chimeneas: `fantasy_town/chimney.glb`.
     - Valla del cementerio: `graveyard/iron-fence.glb`.
     - Carro: `props/Stall_Cart_Empty.gltf`.
  3) **Pixelado:**
     - el escenario se renderiza a 640×360 y los avatares a `AVATAR_RES = 64`, sin MSAA y con filtro NEAREST;
     - `AssetLibrary3D.make_retro` pone los materiales en NEAREST, sin normal map, mates y con poco metal;
     - `load_texture` reduce a `RETRO_MAX_TEX = 256` salvo `characters/`, `colormap` y `_Normal`.
  4) **Tejados:** un vecino dentro solo abre el tejado si el jugador está a menos de 150 px del edificio. Antes
     cualquiera lo abría y casi no se veían tejados.
  5) **Día y noche:** `RetroPostFX` (CanvasLayer 1, colocado justo antes de `UI`; no se crea en headless) calcula
     `night_factor` y `dusk_factor` y hasta 24 luces en pantalla: jugador, farolas encendidas y ventanas sin postigo.
     El shader hace el etalonaje, la viñeta, el grano y la paleta de 15 bits con tramado Bayer a tamaño de píxel del
     juego. `WorldClock.get_ambient_color` es más suave con ventana; en headless se mantienen los colores antiguos.
  6) **Contorno de personajes:** `shaders/pixel_outline.gdshader` sobre `Avatar3DSprite`. Pasa `COLOR` del vértice
     (modulate) a un varying, para no perder los destellos de daño ni la transparencia.
  7) **Trampa:** Flatpak no ve `/tmp`. Las capturas de `tools/screenshot_3d.gd` deben ir dentro del proyecto (p. ej.
     `.godot/capturas/`).
- [x] **Transición 3D — Fase 1: Maquetas 3D articuladas de personajes, equipo, prótesis, arcabuz en mano `[9]`, Visor 3D `[F8]` y alternancia 3D/2D `[F9]`** (`scripts/visuals/CharacterRig3D.gd`, `scripts/visuals/CharacterAvatar3D.gd`, `scripts/ui/CharacterShowcase3DUI.gd`, `scripts/Player.gd`, `scripts/PlayerCombatController.gd`, `scripts/enemies/VillageNPC.gd`, `scenes/ui_root.gd`, probado en juego por el usuario; copia de seguridad 2D intacta en rama `backup-2d-original` y tag `v2d-backup-original`):
  1) Muñeco 3D articulado por piezas (`CharacterRig3D.gd`) con cabeza, ojos/cejas, peinado/barba, torso, delantal, capa, falda, armaduras por nivel (1–3), brazos/piernas articulados, prótesis mecánicas de hierro y cobre o muñón con muleta, y modelos 3D de armas/herramientas/sombreros.
  2) Puente en vivo (`CharacterAvatar3D.gd`) sincronizado con `Player` y `VillageNPC`, con suspensión fuera de cámara y en modo headless, alternable en caliente con `[F9]` sin borrar ningún nodo 2D original.
  3) Arcabuz de chispa empuñable y disparable en tiempo real con la tecla `[9]` (`flintlock_weapon`, proyectil real, fogonazo/humo 3D y alerta sonora a testigos en 260 px).
  4) Visor de Maquetas 3D en primer plano (`[F8]`, `CharacterShowcase3DUI.gd`) con 8 arquetipos del valle y controles de armas, armaduras, prótesis y animaciones.
- [x] **Transición 3D — Fase 2: Escenario 3D del valle, edificios con tejados que se abren al entrar, interiores 3D, alturas `-1/0/+1` y «Puesto del Paso» en el mapa** (`scripts/visuals/WorldStage3D.gd`, `scripts/systems/VillageCulture.gd`, `scripts/systems/VillageNeeds.gd`, `scripts/systems/VillageLots.gd`, `scripts/systems/VillageManager.gd`):
  1) Escenario 3D completo (`WorldStage3D.gd`) en `SubViewport` con cámara ortogonal a `-58°` y proyección exacta 1:1 (`to_3d(pos_2d, h_px)`), con caminos, plaza adoquinada, pozos, bancos, tablón, compostera, Parque del Robledal, Lavadero, Mirador del Lago, Ciénaga del Oeste, Cementerio Parroquial con lápidas dinámicas (`buried_graves`) y solares en obras (`Lots3D`).
  2) Edificios 3D para cada huella en `building_footprints` con puertas 3D abatibles, ventanas con contraventanas, apertura automática del tejado (`RoofCap_*`) al entrar o acercar el ratón, e interiores 3D completos (camas, mesas, mostradores, cofres, fragua, camillas de morgue con cuerpos, celda con rejas, capilla, biblioteca y escuela).
  3) Altillos `+1` (`Loft3D_*`), cámaras subterráneas `-1` de las alcantarillas (`Sewers3D`) y farolas 3D con `OmniLight3D` sincronizadas con el reloj y `electric_grid_active`.
  4) Presencia física 2D y 3D para el asentamiento fronterizo «Puesto del Paso» en `Vector2(1615, 50)` con empalizada, carta interactiva (`[E]` en `OUTPOST_GATE_POS`), aserradero, granero, atalaya y turnos de trabajo reales (`08:00–17:00`) para los colonos reclutados.
  5) La tecla `[F9]` alterna en vivo tanto el mundo/edificios 3D como los personajes 3D, dejando intactos los nodos 2D originales (`self_modulate.a`).
- [x] **Bloque PR — Vida propia sin jugador, gasto municipal de arcas y Auditoría Completa del Proyecto** (`scripts/systems/VillageFame.gd`, `scripts/systems/VillageCulture.gd`, `scripts/systems/VillageHousing.gd`, `scripts/systems/VillageFamily.gd`, `scripts/systems/VillageMigration.gd`, `scripts/systems/VillageTown.gd`, `scripts/systems/VillageManager.gd`, `scripts/systems/VillageForensics.gd`, `scripts/systems/VillageUnderworld.gd`, `scripts/systems/VillageMayor.gd`, `scripts/systems/VillageLineage.gd`, `docs/AUDITORIA_PROYECTO_COMPLETA.md`, test #95):
  1) `VillageFame`: corregido el título duplicado `"Maestro Maestro"` en `promote_to_master` (recortando `"Maestro "` / `"Maestra "` de `npc.npc_role` y saneando en `daily`); las compras de Obras Maestras por vecinos solventes ocurren antes de fabricar y no se repone el mismo día de una venta (`last_sale_day`), además de venderse en el mercado de los miércoles (`VillageCulture.on_market_arrived`).
  2) `VillageHousing`: el rebaño del rancho (`ranch_herd`) se renueva al llegar a `age_days >= ADULT_ANIMAL_DAYS + 3` (9 días), vendiendo el ejemplar maduro al carnicero (`8` de oro reales de su bolsillo al ganadero y `+1 raw_meat` / `+1 wool`) y reponiendo una cría (`"chick"`), con entrada `"animal_bred"` en la crónica.
  3) `VillageFamily` y `VillageMigration`: `MIN_PUPILS_FOR_TEACHER = 1`; las familias migrantes pueden alojarse inicialmente en camas libres de la posada (`free_tavern_beds_count`), se prioriza `"familia"` cuando no hay alumnos, el primer hijo nace con `12..14` años para asistir a clase y graduarse a los 16, y entre semana se encamina a los alumnos a `school_pos` a las `10:00–12:00` registrando su asistencia diaria sin duplicarla a las `14:00`.
  4) `VillageCulture`, `VillageTown` y `VillageManager`: `process_municipal_spending(vm)` invierte el superávit de las arcas (`treasury > 350`) en defensa comunal (`militia_bonus`), becas de investigación tecnológica (`TECH_TREE`, pagando al ingeniero) y apertura de rutas comerciales (`ROUTE_CHARTER_COST` al fondo de la ruta); además, con `treasury >= 250`, las arcas subvencionan `8` de oro del jornal diario de las autoridades.
  5) Auditoría completa del proyecto (`docs/AUDITORIA_PROYECTO_COMPLETA.md`): cerrados los últimos casos de oro sin origen o pagos sin destinatario en `VillageForensics` (`forensic_expose_hitman`, `forensic_contract_report`, `forensic_slip`, `forensic_ambush`, `forensic_frame`), `VillageUnderworld` (`underworld_bet_fight`, `underworld_join_brawl`, `underworld_report_fence`), `VillageMayor` (`town_smear`, `town_cook_books`) y `VillageLineage` (`lineage_adopt`, `lineage_past_help`), y añadida tirada con fallo posible a `town_speech`.
- [x] **Asaltos con motivo** (`VillageCulture`, test #89 ampliado):
  1) `raid_lure`: arcas por encima de `RAID_RICH_TREASURY`, rutas activas y asentamiento. Amenaza diaria = atracción − 1 − defensa/3. A partir de `RAID_THREAT_WARN` hay una probabilidad diaria de aviso.
  2) `raid_on_hour`: a las 16 h `raid_defend` lleva a los defensores a `RAID_GATE_POS`; a las 18 h `resolve_raid`.
  3) `raid_volunteers`: hasta 3 adultos con agresividad ≥ 0.35, que suman a `defense_power`.
  4) La fuerza depende de la amenaza y de las incursiones ya rechazadas.
  Además, `VillageConfession.buy_indulgence` trataba `sect_state.crisis_events` (un número) como una lista.
- [x] **Sonda de mecánicas** (`tools/tests/feature_probe.gd -- <días> <semilla>`, con `--fixed-fps 60`; 30 días tardan unos 30 min). Cuenta lo que pasa solo en la crónica y en el estado. Resultados en `docs/REGISTRO_TRABAJO.md`.
- [x] **Revisión PF–PQ, textos** (puntos 12–16; tests #84 y #90 ampliados):
  1) `PlayerMovementController` aplica la meta `mount_speed_mult`; `VillageCulture.after_load` la repone si `has_horse`.
  2) Pensamientos de amputación −15 y de prótesis +12 en `VillageIllness`.
  3) `promote_to_trade` vuelve a poner los días a la base y gasta `school_bonus_days`, que solo vale para el primer oficio.
  4) Lore de PF–PQ en `docs/APORTES_CREATIVOS.md` §13.
  5) Pendientes en VISION: un lugar en el mapa para el asentamiento y la amputación del jugador.
- [x] **Revisión PF–PQ, economía** (puntos 5–11 del informe; tests #83, #84, #86, #87, #88, #89 ampliados):
  1) Bazar: `player_shop.goods`, precios `SHOP_ITEM_PRICES`, sin stock inicial, `shop_night_theft` (18 %, o 7 % con dependiente; el oro pasa al vecino más pobre).
  2) Corral: `fed_day`; solo crecen o dan carne con ≤ `ANIMAL_FED_DAYS`; mueren a `ANIMAL_STARVE_DAYS`.
  3) Pinos: `can_plant_tree` (1/día, `MAX_PLANTED_TREES = 12`), sin semilla extra, `restore_planted_trees` en `after_load` y en el ciclo diario (`EcosystemManager.plant_sapling(pos, false)`).
  4) `MASTERWORK_COLLECTOR_PRICE = 30`.
  5) Red: `grid.saboteur`; `repair_grid` usa `_generator_on()`; testigos al sabotear.
  6) Milicia: tope `MILITIA_MAX_BONUS = 4`; la atalaya cuenta en `defense_power`; fuerza de la incursión = 4 + rechazadas (máx. +6).
  7) Terminal solo con el TINKER.
  Siguen pendientes los puntos 12–16 (textos y veracidad).
- [x] **Revisión PF–PQ** (`docs/AUDITORIA_PF_PQ.md`, tests #91–#93 ampliados). Arreglados los 4 fallos graves:
  1) Pisos: `VillageHousing.player_near_home` (90 px de un solar tuyo) para subir o bajar. `VillageManager.check_elevation_exit` devuelve a nivel 0 al alejarse 70 px del punto donde se cambió de piso. `explore_sewer_location` ya no deja al jugador en −1.
  2) `fire_flintlock_shot` usaba un suelo de 2.5 en `apply_minor_bruise` (daño 0); ahora 0.10. Retirada la opción «Dispararle» del diálogo.
  3) El capítulo IV leía `town_state["mayor_key"]`, que no existe; ahora `VillageMayor.is_player_mayor`.
  4) `VillageHousing.can_purge_wanted` / `mark_wanted_purge`: 7 días compartidos entre el sótano, el pasadizo del contrabandista y `warrant_archive`.
  Pendientes de economía y textos: puntos 5–16 del informe.
- [x] **Bloque E** (probado, test #75; detalle en `docs/REGISTRO_TRABAJO.md`). Diagnóstico de comidas fallidas
  (`migration_state.meal_fails`, «motivo/oficio»); casas: la pareja junta ahorros y, si alguien duerme al raso, el
  pueblo paga sin reserva; camas de posada sin repetir (cuenta a quien tenga oficio y duerma allí); U5 «según X»
  (`VillageNPC.heard_feelings`, `NPCDialogue._hearsay_feeling`, se ve en la red social). Test #75. Cartel de la escuela vivo (`vm` meta `school_sign`). Llegan **familias** con 1–2 hijos de 2–12
  años (`VillageMigration` tipo «familia», casados con `VillageFamily.marry`; niños con `VillageFamily.spawn_child`).
  Un hijo que cumple 16 en una casa con negocio sin ayudante pasa a `FAMILY_MEMBER` de ese oficio (lo heredará). Los
  niños salen a jugar entre semana de 14 a 20 h (`VillagePlaces.is_leisure_hour(hour, n)`). Paga diaria de 6 de oro a
  los niños (`give_allowances`). Historias propias para niños, nobles y maestro. **Fallos arreglados:** al cargar
  partida se perdían nobles y niños (GameManager solo recuperaba ciertos prefijos de nombre: añadidos `NPC_Noble_` y
  `NPC_Child_`; test #74); el atractivo de V3 tomaba el total de comidas fallidas (que nunca baja) como hambre actual
  (ahora cuenta las del último día, `food_seen`).

### Interfaz
- [x] **HUD1** Barras de estado (`scenes/ui_root.gd`, `_create_stats_box` / `_create_fallback_bar`): recuadro oscuro arriba a
  la izquierda, barras finas con relleno de color y texto blanco (antes `modulate` teñía también el texto). Se ven
  Resistencia, ⚡ Aguante, Hambre y Sueño. Sangre (BLD) y aturdimiento (STN) ocultas por petición del usuario (siguen
  existiendo y actualizándose por dentro).

## 8. Decisiones de diseño ya tomadas (no volver a preguntarlas)

- **Tamaño y niveles**: empezar pequeño, objetivo final una ciudad de 100+ vecinos. Habrá sótanos (mapa aparte debajo del principal) y varios pisos con un sistema de capas tipo Project Zomboid, el mismo para sótanos y pisos (`docs/VISION_Y_FUTURO.md` §6; construir más adelante). Los sistemas nuevos que usen distancias (testigos, oír, ver) deben pasar por una función común para poder añadir «mismo nivel» después.
- **Visión a largo plazo**: pueblo realista con lo bueno y lo malo, profundidad tipo Dwarf Fortress / RimWorld / Song of Syx, construida con 6 piezas comunes y en el orden de `docs/VISION_Y_FUTURO.md` (siguiente tras T2: relaciones de un solo sentido). Las ideas nuevas del usuario se añaden a ese documento.
- **Rasgos**: unos 140 (más de 100; la cifra era orientativa), nombres según el género, oscuros pero raros, un vecino malicioso o Mentiroso puede contarte rasgos falsos («según X»), con ejes de opuestos (no puede ser Trabajador y Holgazán a la vez), unos 6 por vecino, ocultos al principio y descubiertos al interactuar. Los recién llegados tras una muerte se generan solos con el catálogo; las partidas guardadas conservan sus rasgos y se completan.
- **Todo procedural**: el sistema debe funcionar con NPC que lleguen más tarde, no depender de nombres fijos.
- **Solo parejas** (sin bodas ni hijos por ahora). **Todos heterosexuales** por ahora; dejar el campo `orientación` previsto.
- Compatibilidad por: género, edad cercana, personalidad, gustos, relación previa, cercanía por rutina y un poco de azar ("chispa").
- Las parejas **surgen de forma natural, sin plazos ni fechas límite**; nadie "busca pareja". Puede que no surja ninguna en una partida.
- Nadie se empareja con alguien de su mismo hogar/familia. Duelo y viudedad cuando muere la pareja.
- Pareja inicial: **Elena y el Dr. Valen**; resto solteros.
- Edades **numéricas**. Nombres: **200 femeninos + 200 masculinos + apellidos**, estilo variado (latino, europeo, americano).
- **Peleas**: sin muerte; simuladas con dados por dentro (ponderados por oficio, edad, salud, personalidad); en pantalla algo **discreto**
  (dos vecinos frente a frente, movimientos sutiles, algún "💢"); guardias pueden intervenir; consecuencias: heridas leves y relación peor.
  Son **raras y excepcionales**: solo tras una enemistad cultivada durante mucho tiempo, nunca la norma. Una partida larga sin peleas es válida; el pueblo no debe vivir peleándose.
- Jugador: **observador, instigador y mediador** (apoyado en Carisma y Sigilo). Se implementa al final.
- **Calibración**: simulaciones automáticas de cientos de días. Metas de ejemplo para 60 días: 1–3 parejas nuevas; 2–6 peleas en el simulador abstracto, pero en vivo pocas o ninguna (ninguna pareja de
  vecinos pelea >2 veces); ningún vecino sin amigos; más de la mitad de las relaciones entre −20 y +40.
- Arquitectura: **Director Social central** (decide la escena), aldeanos solo ejecutan; relaciones con 4 medidas (afinidad, familiaridad, atracción, tensión),
  enfriamiento sin contacto, "narrador" que dosifica el drama, todos los ajustes en una única tabla de diales, aleatoriedad con semilla.

- **Fe y semana**: religión inventada provisional (Fe del Alba, parecida al cristianismo sin nombres reales); el sacerdote es un personaje propio; los fieles caminan a la capilla de verdad; fin de semana con menos trabajo; los bandos defienden a los suyos con efecto pequeño.
- **Misiones secundarias**: nacen de los vecinos en persona (nunca del tablón), con baja probabilidad, y se ven en un panel propio (tecla L) que tendrá también la historia principal. Sin fecha límite fija; fallan si pasa algo en el mundo (p. ej. muere quien la pidió).
  Tipos aprobados: 1) «Haz las paces por mí» (mediación), 2) «Ensúciale el nombre» (calumnia; da móvil en investigaciones), 3) «¿Quién va contando eso de mí?» (puedes mentir si fuiste tú),
  4) «Encuentra a quien lo mató» (se resuelve con el veredicto), 5) «Averigua qué piensa de mí» (solo información, no fuerza parejas).

## 9. Cómo cerrar una sesión

1. Ejecuta los dos tests. 2. Actualiza la sección 7 (marca bloques). 3. `git add -A && git commit`. 4. Resume al usuario en pocas líneas: hecho, verificado, pendiente.
