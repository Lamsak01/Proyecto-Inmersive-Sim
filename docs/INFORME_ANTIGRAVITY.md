# Informe de Trabajo — Antigravity (2026-11-07)

## Encargo: Corrección de puestos de trabajo, recados nocturnos (`P6b.3a`) y alcantarillas tras los Pasos 2 y 3

### 1. Qué edificios, lugares y vecinos seguían usando coordenadas antiguas (2D y 3D) y se corrigieron
- **Aprendices y ayudantes familiares de los talleres (`scripts/systems/VillageWorldBuilder.gd`):**
  - **Kael** (aprendiz de herrero en *Forja de Thoran*), **Lina** (aprendiz de carnicero en *Carnicería de Garrick*), **Mila** (hija carpintera en *Aserradero de Bram*) y **Nora** (hermana pescadora en *Pescadería de Corin*) tenían `kin_work_pos = hc + ...` (su casa residencial) en lugar de `sc + ...` (el centro real de su taller comercial). Ahora derivan de `sc` (el taller real).
- **Posada «El Jabalí Dorado» y sus trabajadores/huéspedes (`scripts/systems/VillageManager.gd`, `scripts/systems/VillageMigration.gd`, `scripts/systems/VillageWorldBuilder.gd`):**
  - En `VillageManager.gd` seguían escritas a mano las coordenadas de la posada antigua: `_tavern_bed_pos` (`Vector2(548, -264)` → `VillageTavern.PLAYER_BED_POS`), `_tavern_social_pos` (`Vector2(476, -214)` → `VillageTavern.SOCIAL_POS`), `_tavern_games_pos` (`Vector2(552, -206)` → `VillageTavern.GAMES_POS`), `_tavern_pool_pos` (`Vector2(382, -210)` → `VillageTavern.POOL_POS`) y `_tavern_well_pos` (`Vector2(440, -308)` → `VillageTavern.WELL_POS`).
  - Los **3 huéspedes desempleados iniciales** (`_spawn_unemployed_tavern_guests`) y la **sustituta de la posadera Marta** (`_process_daily_map_edge_arrivals`) usaban las camas y mostrador antiguos (`y = -268`, `(445, -242)`) en lugar de `VillageTavern.GUEST_BEDS` y `VillageTavern.INNKEEPER_WORK_POS` / `MARTA_BED_POS`.
  - En `VillageMigration.gd`, `TAVERN_DAY_SPOTS` seguía apuntando a `(462..508, -214..-198)` en vez del salón real de `VillageTavern`.
  - En `VillageWorldBuilder.gd`, el empedrado del pozo de la taberna seguía en `Rect2(414, -326, 52, 46)` (dentro del salón de la nueva posada) y se creaba un segundo `TavernWaterWellArea` duplicado; ahora usa `Rect2(202, -250, 52, 46)` alrededor de `VillageTavern.WELL_POS = Vector2(228, -224)`.
- **Pescador Corin, Leñador, Herrero Thoran, Herborista Elena y Carnicero Garrick en sus expediciones y puestos (`scripts/enemies/VillageNPC.gd`, `scripts/systems/VillageWork.gd`):**
  - En `VillageNPC.EXPEDITION_TARGETS`, **Corin (`FISHMONGER`)** seguía yendo a pescar a `Vector2(-62, 145)` (donde estaba el lago antes del Paso 2, ahora pradera vacía) en vez de la orilla real del Lago del Oeste (`Vector2(-497, 105)`).
  - **Bram (`CARPENTER`)**, **Thoran (`BLACKSMITH`)**, **Elena (`HERBALIST`)** y **Garrick (`BUTCHER`)** seguían saliendo de expedición a `y = 338..362` (antiguo borde del bosque, hoy ocupado por el Rancho/Granja del Sur) en vez del nuevo Bosque Profundo (`y = 785..810`), y el punto de recolección `fallback_spot` seguía en `Vector2(88, 350)` en vez de `Vector2(88, 785)`.
  - En `VillageWork.gd`, el **Leñador (`WOODCUTTER`)** seguía trabajando en `[Vector2(-350, 560), Vector2(-280, 580)]` (dentro de la Granja del Sur ampliada) en vez del lindero del bosque junto a su serrería (`[Vector2(-470, 625), Vector2(-390, 635)]`).
  - En `VillageNPC.IDLE_STROLL_SPOTS`, los paseos al **Parque del Roble**, **Mirador del Lago** y **Lavadero** conservaban las coordenadas anteriores al Paso 2.
- **Ayuntamiento (`n4`), Biblioteca (`n5`), Mansión Noble (`f1`) y Trattoria «Il Corvo» (`scripts/systems/VillagePlaces.gd`, `scripts/systems/VillageUnderworld.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/ui/DetectiveUI.gd`, `tools/tests/verify_all.gd`):**
  - En `VillagePlaces.gd`, el destino de ocio de la **Biblioteca (`n5`)** seguía en `Vector2(890, -445)` en vez de `Vector2(906, -451)`.
  - En `VillageUnderworld.HEIST_TARGETS`, el `"libro_gremial"` del **Ayuntamiento (`n4`)** seguía en `Vector2(764, -444)` en vez de `Vector2(764, -449)`.
  - En `WorldStage3D.gd`, el escritorio 3D de la **Mansión Noble (`f1`)** seguía con offset fijo `c + Vector2(-28, -16)` (solapando la cama) en vez de `VillageNobility.study_pos(b["id"], c)`.
  - En `DetectiveUI.gd`, `_get_corpse_site_kind` y `_describe_world_site` seguían buscando la **Trattoria «Il Corvo»** en `x > 1000, y > 190` y el **Lago del Oeste** en `x < -60, y > 30`, actualizados ahora a la Calle Mayor (`Rect2(-255, -206, 275, 190)`) y al nuevo lago (`x < -280, y = -130..260`). En `verify_all.gd` (`R2.12`), el paso del comedor al reservado se calculó desde `r1_rs.BASE` en lugar del antiguo `(1150, 350)`.

### 2. Fallo de `verify_all.gd` en `P6b.3a` (saboteador contratado a la 01:00)
- **Causa real:** al registrar `TradeRole.WAITER` (`26`) en `vm.trade_configs` antes de que un camarero titular estuviera asignado en `vm.trade_npcs`, `underworld_hire_saboteur` podía elegir un oficio sin dueño vivo en `trade_npcs`, y `VillageNightJobs.target_pos(vm, job)` devolvía `Vector2.ZERO` cuando `vm.trade_npcs.get(r_id)` era `null`, abortando `on_hour` a la `01:00` antes de asignar `night_job`.
- **Solución (`scripts/systems/VillageNightJobs.gd`, `scripts/systems/VillageUnderworld.gd`):**
  - `VillageNightJobs.target_pos` para `"sabotage"` y `"clan_sabotage"` recurre ahora a `vm.shop_businesses[r_id]["stall_pos"] + Vector2(0, 10)` o `vm.trade_configs[r_id]["work_pos"] + Vector2(0, 10)` si el artesano titular no está en `trade_npcs`.
  - `VillageUnderworld.underworld_hire_saboteur` prioriza negocios con titular vivo en `vm.trade_npcs`.

### 3. Alcantarillas en medio del bosque, invisibles en 3D y con colisión en superficie
- **Causa real:** las cámaras de las alcantarillas (`build_sewers_world` y `_build_sewers_3d`) estaban construidas en `y = 1520` (que tras agrandar el bosque en el Paso 2 quedó en mitad del Bosque Profundo). En 2D su `SewersVisual2D` se veía siempre sobre la hierba del bosque, y en 3D `sewers_root_3d` se ocultaba en superficie (`player_elevation_level != -1`) pero el `StaticBody2D` `SewerTunnelWallsBody` mantenía `collision_layer = 1`, haciendo chocar al jugador contra muros invisibles en el bosque (y lo mismo ocurría con `FightClubWallsBody`).
- **Solución (`scripts/systems/VillageUnderworld.gd`, `scripts/systems/VillageClub.gd`, `scripts/obstacles/WorldInteractableProp.gd`, `scripts/systems/VillageManager.gd`, `scripts/visuals/WorldStage3D.gd`):**
  - Las alcantarillas se trasladaron bajo el centro del pueblo en `SEWER_Y = 63.0` (`x = 260, 420, 580`), justo debajo de sus 3 rejillas de entrada (`(248, -90)`, `(398, -118)`, `(518, 26)`), y el sótano del Club de la Lucha se colocó en `Vector2(165, -224)` bajo el patio oeste de la taberna.
  - `VillageUnderworld.sync_sewer_visibility(vm)` y `VillageClub.sync_club_visibility(vm)` desactivan `collision_layer` (`0`) y ocultan `SewersVisual2D` / `FightClubVisual2D` e iconos de escalerillas/cofres cuando el jugador está en la superficie (`player_elevation_level == 0`), y al bajar (`player_elevation_level == -1`) activan la colisión y muestran las alcantarillas o el club tanto en 2D como en 3D (ocultando los edificios y árboles de la superficie en `WorldStage3D._sync_dynamic_props_3d` para que se vean limpiamente bajo el pueblo).

### 4. Verificación ejecutada
- **Arranque limpio:** `flatpak run org.godotengine.Godot --headless --quit-after 3` → `EXIT_CODE=0`, sin errores de script.
- **Suite completa `verify_all.gd`:** `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd` → **`EXIT_CODE=0`** (`ALL ... TESTS PASSED!`, incluidos `P6b`, `FIS3`, `R1`, `R2`, `B1–B7` y `D1–D5`).
- Los edificios de `docs/BOCETOS_EDIFICIOS.md` (Paso 5) no se han tocado, a la espera de revisión del usuario.

---

## Encargo anterior: ⛔ Paso 5 (bocetos previos) — Bocetos de todos los edificios y espacios pendientes (`docs/BOCETOS_EDIFICIOS.md`)

### Qué se hizo en este bloque
- **Redacción completa de `docs/BOCETOS_EDIFICIOS.md` antes de construir ningún edificio del Paso 5 (siguiendo la parada obligatoria ⛔ de `docs/ENCARGO_ANTIGRAVITY.md`):**
  - **1. Comisaría y Cárcel Municipal:** 5 estancias (recepción con mostrador de denuncias, despacho del Comisario con caja fuerte y expedientes, sala de interrogatorios, calabozos con 2 celdas de barrotes reales de suelo a techo con camastro y cubo —eliminando las rejas verdes gigantes sueltas y el cajón sin sentido—, y armero de guardia; el cepo pasa al exterior junto a la fachada).
  - **2. Hospital de Caridad y Morgue Forense:** 4 estancias (recepción y consulta del Dr. Valen, sala de hospitalización con 4 camas y biombos, sala de autopsias con mesa forense de drenaje, instrumental y estantes de reactivos conectada al bloque `D2`, y cámara refrigerada de cuerpos con 3 bandejas y bloques de hielo).
  - **3. Capilla de la Fe del Alba:** 4 zonas (nave central con dos filas de bancos y vitrales, altar mayor elevado con el Cáliz, confesionario lateral de madera con celosía y sacristía con el Libro de Defunciones y subida al campanario, sin tocar nada de la secta).
  - **4. Biblioteca y Archivo Municipal (con «Leer un rato `[E]`» funcional):** 4 estancias (vestíbulo de préstamo, gran sala de lectura con mesas y lámparas, sección de ciencias/medicina/herbario y archivo histórico/catastro) y diseño de la mecánica real para **`[E] Leer un rato (30 min)`** con 4 materias útiles para los casos y el personaje (*Tratado de Toxicología y Forense*, *Crónicas y Linajes de las Familias*, *Herbario y Fauna* y *Planos Catastrales y Alcantarillado*).
  - **5. Alcantarillas Ampliadas y Sótano del Club de la Lucha:** diseño diferenciado del sótano clandestino bajo la bodega de la taberna (foso con 4 postes y cuerdas, bancos de público, mesa del corredor de apuestas, abierto de `21:00` a `03:00`) y de la red de alcantarillas ampliada bajo las calles (bóvedas de ladrillo, canal de agua con pasarelas y puentes, 3 escalerillas y escondites de contrabando/pruebas).
  - **6. Rancho del Sur y Gran Corral de Ganado:** casa-establo dividida en 3 salas (venta/aperos, lechería/esquila y vivienda del ganadero) + gran corral vallado exterior poblado con modelos 3D reales de vacas (`Cow.glb`), toro (`Bull.glb`), caballos (`Horse.glb` / `Horse_White.glb`), burro (`Donkey.glb`), alpacas/ovejas (`Alpaca.glb`) y gallinas, integrados con la economía del pueblo.
  - **7. Tablón de Encargos Legible en la Plaza Central:** estructura techada con farol donde cada encargo activo muestra su hoja de pergamino física con título y firmante legibles al acercarse, abriendo el menú con `[E]`.
  - **8. Resto de edificios del pueblo y Tabla de Puertas según fachada:** bocetos de salas, muebles, ocupantes e interacciones para el **Ayuntamiento**, **Escuela**, **Salón «El Candil»**, **Mansiones Nobles**, **Casas de vecinos** y **Talleres/Tiendas con trastienda**, más la tabla de **11 estilos de puertas exteriores distintas** según la fachada de cada edificio.

### Qué queda sin comprobar / pendiente
- **En espera de revisión del usuario (`ESPERANDO_USUARIO`):** tal como ordena el Paso 5 (⛔), no se ha construido aún ninguno de estos edificios en el código para que el usuario revise primero `docs/BOCETOS_EDIFICIOS.md` y dé el visto bueno o indique correcciones antes de construirlos todos seguidos.
- Siguen pendientes de comprobar en Godot (al regreso del usuario) los bloques visuales de los Pasos 1 a 4 realizados hoy sin abrir Godot ni lanzar pruebas por indicación expresa.

---

## Encargo anterior: Paso 4 — Ambiente: cielo con nubes y hora, suelo con textura, árboles nuevos, niebla

### Qué se hizo en este bloque
- **Cielo dinámico con nubes en movimiento, sol/luna y estrellas según la hora (`scripts/visuals/WorldStage3D.gd::SKY_CLOUD_SHADER_CODE`, `setup_stage`, `_update_roof_cutaways_and_lighting`):**
  - En primera persona se sustituyó el fondo azul plano (`Environment.BG_COLOR`) por un recurso `Sky` con el shader `SKY_CLOUD_SHADER_CODE` (`Environment.BG_SKY`).
  - La bóveda celeste interpola de forma continua con la hora y los minutos de `WorldClock` (`hour_f = hour + minute / 60.0`): amanecer rosado-dorado (`05:30–08:00`), día azul celeste con horizonte brumoso (`08:00–17:00`), atardecer ámbar-violeta (`17:00–19:48`) y noche azul índigo con estrellas parpadeantes y luna plateada.
  - Dibuja el disco solar/lunar con su halo atmosférico, mueve la dirección e inclinación de `sun_light` a lo largo del arco diurno y proyecta **dos capas de nubes en movimiento** con ligero pixelado retro e iluminación cálida en sus bordes.
- **Suelo con textura multiescala y matas de hierba y flores silvestres 3D (`scripts/visuals/WorldStage3D.gd::GROUND_TERRAIN_SHADER_CODE`, `_make_ground_shader_mat`, `_build_ground_3d`, `_build_ground_foliage_3d`):**
  - El suelo de pradera (`m_grass`), bosque (`m_forest`) y llanura (`m_plains`) usa ahora el shader `GROUND_TERRAIN_SHADER_CODE`, que combina `floor_ground_grass.png`, `floor_ground_grass_overlay.png` y `floor_ground_dirt.png` en coordenadas de mundo a **3 escalas distintas** (manchas de pradera, baldosa media y brizna nítida a ras de suelo en 1.ª persona), añadiendo briznas claras/oscuras, florecillas y calvas naturales de tierra húmeda.
  - `_build_ground_foliage_3d()` reparte cientos de matas de hierba, tréboles, helechos, espigas y flores silvestres 3D (`nature/Plant_1..3.obj`, `Flowers.obj`, `Wheat.obj`) por las praderas, cunetas, campamento, orilla del lago y linde del bosque (respetando caminos, plaza y edificios y agrupándolos en `MultiMeshInstance3D` mediante `_absorb_into_batches`).
- **Árboles variados por zona y colores de materiales corregidos (`scripts/visuals/WorldStage3D.gd::_make_nature_3d`, `_build_tree_3d`, `scripts/visuals/AssetLibrary3D.gd::_parse_mtl_file`):**
  - `_make_nature_3d` y `_build_tree_3d` alternan ahora robles y hayas frondosos (`CommonTree_1..4.obj`), abedules de corteza blanca (`BirchTree_1..3.obj`) y pinos altos (`PineTree_1..4.obj`) según la zona del valle, en vez de repetir únicamente pinos en todo el mapa.
  - `AssetLibrary3D._parse_mtl_file` normaliza los materiales con sufijo `.001` (`Green.001`, `DarkGreen.001`, `White.001`, `Black.001` en `BirchTree_2.mtl`) y `Leaves` para que todos los abedules y árboles frondosos luzcan con corteza y follaje naturales.
- **Niebla atmosférica según la hora del día y el clima (`scripts/visuals/WorldStage3D.gd::_update_roof_cutaways_and_lighting`):**
  - Configurada la niebla atmosférica (`fog_light_color`, `fog_sun_scatter`, `fog_sky_affect`, `fog_density`) reactiva a la hora (bruma matinal al amanecer, bruma cálida al atardecer, niebla nocturna azulada y bruma suave de horizonte al mediodía) y al clima de `WorldClock` (`"fog"`, `"rain"`, `"storm"` duplican la densidad de niebla y aumentan la cobertura de nubes), desactivándose automáticamente al entrar bajo techo (`pl_indoors`) para mantener nítidos los interiores.

### Qué queda sin comprobar (por orden expresa del usuario hoy)
- **Pendiente de comprobar al regreso del usuario** (siguiendo la instrucción *«HOY NO PASES NINGUNA PRUEBA, NI ARRANQUES GODOT, NI HAGAS CAPTURAS: el usuario las hará al volver»*):
  1. Arranque de Godot y revisión visual en 1.ª persona (`[F6]`/`[F8]`) y en vista 3D a distintas horas del día (amanecer, mediodía, atardecer, noche y día de niebla/lluvia) para comprobar el cielo con nubes en movimiento, el suelo texturizado con matas de hierba y flores 3D, la variedad de robles/abedules/pinos y la niebla atmosférica.

---

## Encargo anterior: Paso 3 — La taberna «El Jabalí Dorado» (2 pisos)

### Qué se hizo en este bloque
- **Edificio mucho más grande y primer edificio de 2 plantas reales (`scripts/systems/VillageTavern.gd`, `scripts/systems/VillageWorldBuilder.gd`, `scripts/systems/VillageManager.gd`, `scripts/obstacles/WorldInteractableProp.gd`, `scripts/visuals/CharacterAvatar3D.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/ui/ValleyMapUI.gd`):**
  - Se amplió la huella de la taberna a `Rect2(Vector2(260, -316), Vector2(348, 184))` con muros de 2 plantas (`wall_h = 44.0`, `22.0 px` por piso).
  - **Planta Baja (`Planta 0`, `elevation_level = 0`):** dividida por tabiques interiores con dinteles en 4 salas comunicadas: **Gran Salón y Comedor** (`salon`, con chimenea de piedra y brasas, 6 mesas de roble con 12 sillas, platos, jarras y 2 arañas de techo), **Barra y Cocina** (`barra_cocina`, con gran mostrador de caoba y latón, 4 taburetes, tiradores de cerveza, estantería de licores, toneles de roble, fogones con caldero y encimera), **Sala de Casino y Billar** (`casino`, con alfombra carmesí, mesa de póker y mesa de billar) y **Vestíbulo de Escalera y Bodega** (`escalera_bodega`).
  - **Primer Piso (`Planta +1`, `elevation_level = 1`, `FLOOR_1_H = 22.0`):** galería alta con barandilla de madera asomada al salón, pasillo alfombrado y **5 cuartos de huéspedes** con puertas y tabiques que alojan las **6 camas reales de la posada** (`(342, -252)` de alquiler + `(400, -252)`, `(435, -252)`, `(468, -252)`, `(502, -252)`, `(538, -252)` para vecinos/viajeros), con mesillas, cofres y alfombras.
  - **Escalera física real (`STAIRS_BOTTOM_POS = Vector2(576, -284)` ↔ `STAIRS_TOP_POS = Vector2(576, -202)`):** 12 peldaños macizos de roble con barandillas en 3D y objeto interactivo `"tavern_stairs"` (`[E] Subir al primer piso (+1: Habitaciones)` / `[E] Bajar a la planta baja (0: Salón)`). El enrutador `VillageTavern.route(...)` guía automáticamente tanto a los vecinos que suben a dormir o bajan por la mañana como entre cualquier sala de ambas plantas, y `CharacterAvatar3D` / `WorldStage3D._update_fp_camera_transform` interpolan suavemente la altura 3D al subir o bajar los peldaños.
- **Mesas con gente sentada comiendo, partida de póker en vivo, Marta tras la barra y Camarero (`scripts/systems/VillageTavern.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/systems/VillagePlaces.gd`, `scripts/systems/VillageNeeds.gd`, `scripts/data/PersonProfile.gd`, `scripts/ui/SocialGlossaryUI.gd`, `scripts/enemies/NPCDialogue.gd`):**
  - **Marta detrás del mostrador:** `INNKEEPER_WORK_POS = Vector2(338, -248)` coloca a la posadera detrás del mostrador de caoba (`BAR_COUNTER_POS = Vector2(338, -234)`) atendiendo la barra.
  - **Nuevo oficio `TradeRole.WAITER` (Camarero, índice 26):** añadido al final de `enum TradeRole` y registrado en `vm.trade_configs` para cubrirse como cualquier oficio vacante (y creado al inicio de la partida). En su horario (`10:00–23:00`), `VillageTavern.tick_waiter` hace que recorra las mesas con comensales sentados, tome nota del pedido, camine al pasa-platos de la barra (`PASS_COUNTER_POS = Vector2(396, -246)`) a recoger las jarras/platos y los sirva en la mesa.
  - **Comensales sentados y jugadores de póker:** los vecinos que comen en la posada o acuden por ocio (`"tavern"`, `"tavern_hall"`, `"tavern_poker"`, o recados `"drink"` / `"gamble"`) eligen una silla libre de las 6 mesas del salón (`DINING_TABLES`) o de las 4 sillas de la mesa de póker (`POKER_CHAIRS`), se sientan mirando a la mesa (`set_poker_seating`) y conversan o comentan las jugadas en vivo (`VillageTavern.tick`). Además, `seed_initial_patrons` sienta comensales y jugadores de póker desde el arranque de la partida para que la taberna nunca se vea vacía.
- **Sótano con el Club de la Lucha Clandestino (`scripts/systems/VillageClub.gd`, `scripts/systems/VillageUnderworld.gd`, `scripts/enemies/NPCDialogue.gd`, `scripts/visuals/WorldStage3D.gd`):**
  - La trampilla `VillageClub.TRAPDOOR_POS = Vector2(516, -286)` está ahora **dentro de la sala trasera de escalera y bodega de la taberna** (entre toneles y bajo un farol cálido, sobre la losa del suelo en `h = 2.5`).
  - El club abre **todas las noches de `21:00` a `03:00`** (`OPEN_FROM = 21`, incluidas las noches impares como la primera noche de partida, salvo cierre policial tras una redada) y es fácil de descubrir preguntando a Marta o al Camarero (`"ask_club_rumor"`: *«¿Qué son esos golpes que se oyen bajo el suelo de la bodega?»*) o mediante los rumores nocturnos de taberna (`FENCE_RUMORS`).
- **Mesa de billar auténtica en 3D (`scripts/visuals/WorldStage3D.gd::_build_billiard_table_3d`):**
  - Eliminado el uso de `Table_Large.gltf` con un rectángulo verde encima. La nueva mesa de billar en `POOL_POS = Vector2(574, -178)` se construye con geometría 3D propia: 4 patas torneadas de caoba con casquillos de latón, faldón perimetral de caoba, pizarra de paño verde esmeralda con línea blanca de saque, 4 bandas elevadas de caoba partidas en el centro, 6 troneras con herrajes de latón y hueco oscuro, bola blanca + triángulo de bolas de colores (amarilla, azul, roja y bola 8 negra) y 2 tacos de madera con virola de tiza azul apoyados sobre las bandas.

### Qué queda sin comprobar (por orden expresa del usuario hoy)
- **Pendiente de comprobar al regreso del usuario** (siguiendo la instrucción *«HOY NO PASES NINGUNA PRUEBA, NI ARRANQUES GODOT, NI HAGAS CAPTURAS: el usuario las hará al volver»*):
  1. Ejecución de `tools/tests/verify_all.gd` (comprobación de rutas, camas de la posada en Planta `+1`, oficio `WAITER` y trampilla del Club de la Lucha).
  2. Arranque de Godot y revisión visual en 3D y 1.ª persona de:
     - La nueva taberna de 2 pisos («El Jabalí Dorado»), la subida/bajada por la escalera física a los 5 cuartos de huéspedes con las 6 camas en Planta `+1`, y el cambio de altura suave de cámara/avatares en los peldaños.
     - Marta atendiendo tras el mostrador, el Camarero yendo de las mesas al pasa-platos de la barra, los vecinos sentados en las 6 mesas de comedor y en las 4 sillas de la mesa de póker, la mesa de billar 3D con troneras, bolas y tacos, y la bajada al Club de la Lucha desde la trampilla de la bodega entre las `21:00` y las `03:00`.

---

## Encargo anterior: Paso 2 — Agrandar y separar el entorno

### Qué se hizo en este bloque
- **Campamento inicial y Lago del Oeste alejados del pueblo (`scripts/World.gd`, `scenes/World.tscn`, `scripts/obstacles/FishingSpot.gd`, `scripts/systems/VillageManager.gd`, `scripts/systems/VillageWorldBuilder.gd`, `scripts/visuals/WorldStage3D.gd`):**
  - El campamento inicial del jugador (`PlayerCampSite` en `Vector2(-532, -96)`), el huerto de 3×3 parcelas (`Vector2(-585, -45)`), el gallinero (`Vector2(-658, -21)`), la aparición inicial del jugador (`Vector2(-489, -56)`) y el perro guardián **Toby** (`Vector2(-495, -52)`, antes suelto en mitad del pueblo) quedan ahora fuera de la aldea, junto al **Lago del Oeste** (`LAKE_NODE_POS = Vector2(-525, 105)`), unidos al pueblo por un camino largo.
  - Se eliminó el segundo embarcadero 3D del sur del lago en `WorldStage3D._build_barrios_3d()`, dejando un único muelle de pesca en la orilla este.
- **Lavadero trasladado al pueblo, Parque del Roble ampliado y retirada del «Huerto vecinal» del camino (`scripts/systems/VillageWork.gd`, `scripts/systems/VillagePlaces.gd`, `scripts/systems/VillageLots.gd`, `scripts/visuals/WorldStage3D.gd`):**
  - El **Lavadero Municipal** (`VillageWork.LAVADERO_POS`) se movió de la orilla del lago a `Vector2(215, 145)` en el pueblo (al oeste de la Botica y al norte del Parque del Roble), registrándose también como fuente de agua en `VillageManager.is_position_near_water_source`.
  - El **Parque del Roble** (`VillagePlaces.PARK_RECT`) se amplió a `Rect2(Vector2(168, 208), Vector2(272, 146))` (casi el doble de superficie), sin el murete bajo que lo encerraba, con paseos en cruz y con los árboles en las esquinas lejos de los bancos.
  - Se retiró de `VillageLots.GAP_POCKETS` el `"garden"` («🥬 Huerto vecinal» en `Vector2(1090, -40)`) que estaba plantado en mitad del camino del este junto a la Residencia Aguas Claras.
- **Trattoria «Il Corvo» trasladada de junto al cementerio a la Calle Mayor (`scripts/systems/VillageRestaurant.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/ui/ValleyMapUI.gd`, `tools/tests/verify_all.gd`):**
  - Se reubicó `VillageRestaurant.BASE` a `Vector2(-255, -206)` (`RECT = Rect2(-255, -206, 275, 190)`), con su puerta sur y su terraza abiertas directamente a la Calle Mayor que entra a la Plaza Central, a más de `1.100 px` del Cementerio Parroquial y sin solapar ningún solar ni camino.
- **Llanura Salvaje y Ciénaga de las Ranas separadas y más amplias (`scripts/systems/VillageWorldBuilder.gd`, `scripts/visuals/WorldStage3D.gd`, `scenes/World.tscn`, `scripts/Player.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/systems/VillageManager.gd`):**
  - La **Llanura Salvaje** ocupa ahora una meseta amplia e irregular al **noroeste** (`x = -2060..-1080, y = -560..-20`, con ruinas de bandidos, cajas y enemigos), separada al otro lado del camino respecto a la **Ciénaga de las Ranas** al **suroeste** (`x = -2020..-1100, y = 110..560`, con laguna pantanosa amplia, sauces, juncos, troncos caídos y sapos).
- **Bosque Profundo ~3,5 veces más grande, más al sur, con borde orgánico, árboles 3D corregidos y fauna que deambula (`scripts/systems/EcosystemManager.gd`, `scripts/enemies/WildAnimal.gd`, `scripts/visuals/AssetLibrary3D.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/ui/ValleyMapUI.gd`):**
  - **Árboles 3D corregidos (`AssetLibrary3D.gd`, `WorldStage3D.gd`):** el cargador `load_obj_mesh` triangulaba las caras `.obj` en orden antihorario (haciendo que Godot descartara las caras frontales y mostrara las copas huecas por dentro como «bloques arrugados») y `_parse_mtl_file` convertía el material `Wood` de los árboles en un tono rosado. Se corrigió la triangulación a orden horario CW, se activó `CULL_DISABLED` y se normalizaron `Wood`, `DarkWood`, `Green` y `DarkGreen` a marrón corteza y verdes naturales; además, `_scan_nature_sources()` descarta cualquier árbol decorativo que solape edificios o quede a `< 18 px` de otro árbol.
  - **Bosque ~3,5× mayor y con borde irregular (`EcosystemManager.FOREST_POLY`):** alejado al sur (`x ≈ -1360..1640, y ≈ 730..2390`), sin línea perimetral recta, con 60 árboles talables formando claros naturales, 14 vetas de mineral, 42 plantas silvestres, 32 arbustos (`Bush_1/2.obj`, `BushBerries_1/2.obj`) y 12 troncos caídos (`WoodLog.obj`).
  - **Fauna que deambula y se dispersa (`WildAnimal.gd`):** ampliado el radio de pastoreo/exploración de `90..135 px` a `380..450 px`, eliminado el imán constante hacia el centro de la manada/madriguera y añadida una fuerza de separación suave entre animales cercanos para que se repartan por todo el bosque.

### Qué queda sin comprobar (por orden expresa del usuario hoy)
- **Pendiente de comprobar al regreso del usuario** (siguiendo la instrucción *«HOY NO PASES NINGUNA PRUEBA, NI ARRANQUES GODOT, NI HAGAS CAPTURAS: el usuario las hará al volver»*):
  1. Ejecución de `tools/tests/verify_all.gd` (incluyendo las aserciones de navegación de `VillageRestaurant` actualizadas a `r1_rs.BASE`).
  2. Arranque de Godot y revisión visual en partida de:
     - El campamento inicial, huerto 3×3, gallinero, Toby y Lago del Oeste con un único muelle y camino largo hasta la aldea.
     - El Lavadero en el pueblo (`Vector2(215, 145)`), el Parque del Roble ampliado sin murete bajo, la ausencia del «Huerto vecinal» en el camino del este y la Trattoria «Il Corvo» en la Calle Mayor.
     - La Llanura Salvaje (noroeste) separada de la Ciénaga de las Ranas (suroeste), el Bosque Profundo ~3,5× más grande con borde orgánico, los árboles 3D con copas y ramas de color natural y los animales deambulando repartidos por el bosque.

---

## Encargo anterior: Paso 1 — Arreglos rápidos (`1a`, `1b`, `1c`)

### Qué se hizo en este bloque
- **1a. Examen de muertos que no son de un caso (`scripts/enemies/VillageNPC.gd`, `scripts/ui/DetectiveUI.gd`, `tools/tests/verify_all.gd`):**
  - `VillageNPC.stealth_assassinate(player)` ahora inspecciona el arma equipada del jugador (hacha, martillo, pico, hoz, arco o espada), guarda un `last_hit_weapon_name` real (p. ej. `"Hachazo furtivo por la espalda"`) y registra la herida letal correspondiente en `HealthComponent.wounds`.
  - `DetectiveUI.gd` (`_build_case_from_corpse`, `_describe_zone_wounds`, `_do_zone_action`, `_get_default_morgue_tests`, `_build_scene_data_for_corpse`, `_build_board_suspects_for_corpse`) construye el examen del cuerpo (D1), las pruebas de autopsia (D2), las pistas/testigos de la escena (D3) y los sospechosos del tablero (D4) **únicamente a partir del estado real del cadáver** (`HealthComponent.wounds`, `last_hit_weapon_name`, `corpse_rot_hours`, `death_world_pos`, `person_profile.gender`, `VillageForensics`, bolsillos reales). Si una zona no presenta heridas, responde `"nada fuera de lo normal"`. Ningún texto del Caso I («La mujer del bosque»: muñecas atadas, cáñamo, vestido, ceniza) se reutiliza en muertos que no pertenecen a un caso guionizado.
  - Añadido el test `D1.4a–D1.4e` en `tools/tests/verify_all.gd` (asesinato furtivo del carnicero con hacha por la espalda y verificación del examen).
- **1b. Revisión de Claude a D1–D5 (`scripts/ui/DetectiveUI.gd`, `docs/INFORME_ANTIGRAVITY.md`):**
  - **Fondo del examen y de la escena:** desactivada la captura cenital 3D con filtro Sobel de bordes (`set_detective_topdown` / `SKETCH_SHADER_CODE`) que producía ruido ilegible y mostraba suelos/tejados de edificios; sustituida por un **esquema limpio de pocas líneas del sitio real** (`_draw_body_site_schematic` en `SilhouetteCanvas` y `CrimeSceneCanvas`, adaptándose según el lugar a claro del arroyo/bosque, morgue, orilla del lago, calle empedrada o rancho).
  - **Tablero de corcho (`CorkboardCanvas`):** los hilos rojos (`StringsOverlay`, `z_index = 1`) pasan por detrás del cuerpo de las fichas (`z_index = 4`) para no tapar nunca el texto, las chinchetas (`PinsOverlay`, `z_index = 10`) se dibujan encima en el centro superior de cada tarjeta (`pos + Vector2(84, 2)`), y las posiciones iniciales de las fichas se escalonan en altura para evitar cruces sobre otras tarjetas.
  - **Barra de deterioro y corrección de este informe:** añadida en la columna derecha de `1 · Examen del cuerpo` la **barra visual de estado del cadáver en 4 fases** (`1 · Reciente`, `2 · Enfriándose`, `3 · Rígido`, `4 · Deteriorado`, actualizada en `_update_decay_bar()` según las horas transcurridas), y corregida más abajo la sección de D1–D5 para reflejar las **4 pestañas reales**, sin retrato estilizado y con el esqueleto del Caso I + 9 huecos (`case_02`..`case_10`).
- **1c. Fallos visibles pequeños (`AssetLibrary3D.gd`, `CharacterRig3D.gd`, `CharacterAvatar3D.gd`, `VisionCone2D.gd`, `DummyEnemy.gd`, `FishingSpot.gd`, `VillageRestaurant.gd`, `VillageManager.gd`, `VillagePlaces.gd`, `VillageWorldBuilder.gd`, `WorldStage3D.gd`, `docs/FALLOS_VISIBLES.md`):**
  - **Ropa que atraviesa el cuerpo:** `AssetLibrary3D.extract_head_only_mesh` recorta ahora los vértices laterales (`absf(v.x) <= 0.135`, caché `_v2_`) para eliminar los hombros y brazos en T-pose del modelo desnudo bajo la ropa.
  - **Libro gigante y variedad de vecinos:** reducida la escala de `props/Book_5.gltf` a `Vector3(0.18, 0.04, 0.22)` (`-1.0`) y limitado a horario lectivo/culto cerca de `work_position`; repartidos de forma determinista por persona los modelos `peasant`/`ranger` masculinos y femeninos, sus variantes de textura (`T_Peasant_2`, `T_Ranger_3`), los 5 peinados (`Hair_Buns`, `Hair_Long`, `Hair_BuzzedFemale`, `Hair_SimpleParted`, `Hair_Buzzed`), `T_Hair_2`, barba (`Hair_Beard`) y piel clara/oscura.
  - **Conos de depuración de los sapos:** ocultos por defecto en `VisionCone2D.gd` y `DummyEnemy.gd`.
  - **No andar sobre el agua y muelle único:** añadida colisión física (`StaticBody2D` + `CollisionPolygon2D`) al contorno de `LAKE_WATER_WORLD` en `FishingSpot.gd` dejando libre la pasarela del muelle de madera, y ocultado el muelle 2D duplicado en modo 3D.
  - **Cama de la trattoria → Despacho del dueño:** renombrada la estancia `"dueno"` a `"Despacho del dueño"` en `VillageRestaurant.gd` y sustituidas las camas en 2D y 3D por escritorio de madera, sillón del jefe, sillas de confidentes, libro de cuentas, candelabro, estantería y alfombra.
  - **Letreros encimados, Parque del Roble en 3D y lápidas del cementerio:** subidos los títulos de edificios a `-half.y - 36.0` (evitando que `"Esquilando lana 90 %"` pise `"Rancho del Sur"`), subido el cartel `"🌳 Parque del Roble"` a `y = 194`, ocultados en 3D los polígonos y sprites 2D del parque y del cementerio, construido el `Parque del Roble` 3D en su `PARK_RECT` real y reducidas las tumbas/lápidas 3D a proporción humana (`6.8 × 3.2 px` de túmulo y `8.8 px` de lápida).

### Qué queda sin comprobar (por orden expresa del usuario hoy)
- **Pendiente de comprobar al regreso del usuario** (siguiendo la instrucción *«HOY NO PASES NINGUNA PRUEBA, NI ARRANQUES GODOT, NI HAGAS CAPTURAS: el usuario las hará al volver»*):
  1. Ejecución de `tools/tests/verify_all.gd` (incluyendo el nuevo test `D1.4a–D1.4e` de examen de cadáver fuera de caso).
  2. Arranque de Godot y revisión visual en partida / capturas de pantalla (`docs/capturas_paso1/`) de:
     - Examen de un vecino muerto fuera de caso (p. ej. el carnicero asesinado con sigilo) frente al cadáver del Caso I.
     - Esquema limpio de pocas líneas en `1 · Examen del cuerpo` y `3 · Escena del crimen`, y barra de 4 fases de deterioro del cadáver.
     - Tablero de corcho (`[N]`) con los hilos rojos pasando por detrás de las tarjetas hasta las chinchetas superiores.
     - Vecinos con variedad de ropa/peinados/barba/piel, libro pequeño en mano de Anselmo/maestra, hombros del guardia sin atravesar la ropa, sapos sin cono de visión, colisión del agua del lago con muelle único caminable, despacho del dueño en «Il Corvo», letreros del Rancho del Sur y Parque del Roble sin solaparse, y lápidas del cementerio a escala reducida.

---

## Encargo anterior: Herramientas del Detective (Bloques D1, D2, D3, D4 y D5)

Se implementaron los cinco bloques de **Herramientas del Detective** (`D1`–`D5`) siguiendo `docs/PLAN_BETA_MISTERIO.md` (§§5–6) y el boceto visual `docs/bocetos/examen_cuerpo.html`, además de corregir la fachada de la trattoria en `docs/FALLOS_VISIBLES.md`.

> **Atajo de teclado clave:** La **`Tecla N`** (`[N] Tablero`) abre y cierra en cualquier momento el **Tablero del caso** (tablero de corcho del detective), también accesible desde la pestaña `4 · Tablero del caso` dentro de la interfaz forense.

---

## 1. Resumen por Bloque (D1–D5)

### Bloque D1 — Examen de cuerpo (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- **Vista de examen forense basada en `docs/bocetos/examen_cuerpo.html`:**
  - Cabecera oscura con el título del expediente, subtítulo contextual (lugar, hora estimada y estado del cuerpo), barra de **4 pestañas** (`1 · Examen del cuerpo`, `2 · Autopsia en la morgue`, `3 · Escena del crimen`, `4 · Tablero del caso`) y botón `Cerrar [Esc]`.
  - **Columna izquierda (Lienzo de silueta + esquema cenital del lugar):**
    - Fondo con esquema limpio de pocas líneas del lugar real del hallazgo (arroyo y pinos en el claro del bosque, losa clínica en la morgue, orilla y muelle en el lago, empedrado en el pueblo o valla en el rancho) y marcador numérico `[1]`.
    - Silueta anatómica plana dibujada con `_draw()` sin rasgos faciales en dos variantes según el género de la víctima: **femenina** (hombros más estrechos, cintura marcada, caderas suaves y melena oscura dibujada *detrás* de la cabeza) y **masculina** (hombros más anchos y torso recto).
    - **7 zonas clicables (`cabeza`, `cuello`, `torso`, `brazos`, `manos`, `piernas`, `bolsillos`):** muestran marcas anatómicas únicamente para las heridas o hallazgos realmente descubiertos.
  - **Columna derecha (Observación y acciones):**
    - **Barra de deterioro del cadáver en 4 fases** (`1 · Reciente`, `2 · Enfriándose`, `3 · Rígido`, `4 · Deteriorado`) según las horas transcurridas a la intemperie.
    - Botones de acción superficial (`Mirar de cerca`, `Palpar`, `Oler`, `Usar lupa` si llevas `magnifying_glass`, `Vaciar bolsillos`) que suman minutos al reloj del mundo, lista de lo descubierto en la zona con botón `Anote` para pasarlo al cuaderno, y bloque de «Causa aparente» frente a «Causa real».
  - **Tira inferior (`Cuaderno del caso`):** muestra las fichas clavadas manualmente por el jugador.

### Bloque D2 — Autopsia en la morgue con el Dr. Valen (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- Con el cuerpo en la morgue y el médico forense disponible, se habilita la pestaña `2 · Autopsia en la morgue`.
- **4 pruebas internas por pasos con riesgo de fallo:** `Sangre` (`2 / 2` tubos de muestra, elección corazón/brazo, reactivos y tabla de 4 colores), `Garganta y hueso hioides` (corte lento vs. corte rápido que rompe el hueso), `Contenido del estómago` (guardar en frasco sellado vs. tirar) y `Lividez y rigor mortis`.
- Botón `Preguntar al Dr. Valen (+5 min)` en los pasos delicados y actualización progresiva de `Causa real`.

### Bloque D3 — Escena del crimen a oscuras con linterna (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- Vista `3 · Escena del crimen` con el esquema cenital del lugar cubierto por oscuridad nocturna y **círculo de luz cálida del farol** centrado en el cursor del ratón, iluminando solo los indicios dentro de su radio.
- Panel derecho con el detalle del indicio seleccionado (y botón para anotarlo en el cuaderno) más los **testigos cercanos** con acciones `Preguntar (10 min)` y `Presionar (puede cerrarse)`.

### Bloque D4 — Tablero de corcho con chinchetas e hilos rojos (`scripts/ui/DetectiveUI.gd`, `scripts/systems/VillageForensics.gd`)
- Accesible en cualquier momento con la **`Tecla N`** o desde la pestaña `4 · Tablero del caso`.
- Tablero de corcho con **fichas arrastrables** de sospechosos y pistas anotadas a mano, con chincheta superior centrada y **hilos rojos** que van de chincheta a chincheta por detrás del cuerpo de las tarjetas para no tapar el texto.

### Bloque D5 — Estructura de datos para los 10 casos + Fachada de la Trattoria (`scripts/systems/DetectiveCaseData.gd`, `scripts/visuals/WorldStage3D.gd`)
- **Estructura `CASES` (`case_01_forest_woman`..`case_10`) en `DetectiveCaseData.gd`:** contiene el esqueleto completo del **Caso I («La mujer del bosque»)** según `docs/PLAN_BETA_MISTERIO.md` §5 y los **9 huecos estructurados (`case_02`..`case_10`)** con marcas `PENDIENTE_DECISION_USUARIO` en los elementos de trama pendientes de decisión del usuario.
- **Vinculación con NPCs reales (`assign_case_roles`):** vincula los papeles del caso con vecinos vivos sin matar a ningún NPC al iniciar el juego.
- **Corrección de `docs/FALLOS_VISIBLES.md`:** fachada 3D de la trattoria «Il Corvo» con acabado de estuco crema cálido y ladrillo claro.

---

## 2. Verificación Automática (`verify_all.gd`)

Se ejecutó la suite integral `tools/tests/verify_all.gd` en modo headless:

```bash
timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd > /tmp/v.log 2>&1
```

- **Resultado:** `EXIT_CODE=0` — **100 % de los tests en verde**, incluyendo los nuevos bloques de pruebas `D5.1a–D5.1c`, `D1.0–D1.3`, `D2.1a–D2.4`, `D3.1a–D3.2c` y `D4.1a–D4.5`.

---

## 3. Tour Visual de Capturas (`docs/capturas_detective/`)

Todas las capturas fueron generadas con el motor en ejecución real y revisadas visualmente una por una:

| Archivo | Contenido verificado |
| :--- | :--- |
| `docs/capturas_detective/d1_examen_mujer.png` | Vista `1 · Examen del cuerpo` con silueta femenina (melena detrás de la cabeza), marcas anatómicas reveladas, boceto 3D top-down y cuaderno de campo con `"✓ Anotado en el cuaderno"`. |
| `docs/capturas_detective/d1_examen_hombre.png` | Vista `1 · Examen del cuerpo` con silueta masculina (Caso 1, Aldric Vane), zonas reveladas y cuaderno de campo. |
| `docs/capturas_detective/d2_autopsia_morgue.png` | Vista `2 · Autopsia (morgue)` con mesa clínica, frascos de muestras (`2/2`), consejo del Dr. Valen, gráfico de 4 barras de color y causa aparente vs. causa real. |
| `docs/capturas_detective/d3_escena_crimen.png` | Vista `3 · Escena del crimen` a oscuras con el haz cálido de la linterna centrado en el cursor e iluminando las pruebas, más testigos a la derecha. |
| `docs/capturas_detective/d4_tablero_corcho.png` | Vista `4 · Tablero del caso` (`Tecla N`) con tarjetas de víctima, sospechosos y pistas separadas sobre el corcho e hilos rojos tensados por encima de las tarjetas. |
| `docs/capturas_detective/mundo_plaza_dia.png` | Vista general de la plaza central de día con vecinos y edificios. |
| `docs/capturas_detective/mundo_plaza_noche.png` | Vista general de la plaza central de noche con iluminación de farolas. |
| `docs/capturas_detective/mundo_trattoria_dia.png` | Fachada 3D de la Trattoria «Il Corvo» corregida con estuco crema cálido y ladrillo terracota claro. |
| `docs/capturas_detective/mundo_morgue_dia.png` | Exterior del Hospital / Morgue del Dr. Valen y Comisaría de día. |
| `docs/capturas_detective/mundo_bosque_noche.png` | Vista nocturna del bosque periférico. |
