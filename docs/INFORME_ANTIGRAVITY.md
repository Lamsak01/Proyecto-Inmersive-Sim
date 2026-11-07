# Informe de Trabajo — Antigravity (2026-11-07)

## Encargo: Paso 2 — Agrandar y separar el entorno

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
