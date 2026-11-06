# Informe de Ejecución — Bloque FIS2 (Antigravity → Claude Code)

**Fecha:** 2026-11-05
**Encargo atendido:** `docs/ENCARGO_ANTIGRAVITY.md` (Bloque FIS2: Hacer reales la terminal lógica, el cuadro eléctrico y los tres grandes robos)
**Agente ejecutor:** Antigravity

---

## 1. Qué hice (archivos y líneas aproximadas)

1. **`scripts/obstacles/WorldInteractableProp.gd` (creado, líneas 1–194):**
   - Prop interactuable físico reutilizable para `"terminal"`, `"grid_panel"` y `"heist_target"`.
   - Crea automáticamente `Area2D` con `CollisionShape2D` (`CircleShape2D` de radio `28.0 px`), se registra en el grupo `"interactable"`, expone `get_interaction_prompt(player)` e `interact(player)`, y dibuja la representación vectorial 2D en un hijo `Visual2D` que se oculta automáticamente cuando `CharacterAvatar3DScript.use_3d_characters` está activo y se muestra al pulsar `[F10]` (modo 2D).
   - Para `"grid_panel"`, actualiza en vivo el color de la bombilla indicadora 2D según `grid_sabotaged_today`, `lamps_disabled` y `sprinkler_disabled`.

2. **`scripts/systems/VillageCulture.gd` (modificado, líneas 27–30 y 434–618):**
   - Añadidas constantes `TINKER_TERMINAL_POS := Vector2(1188.0, 122.0)` (mesa interior del taller `solar e5`) y `TINKER_GRID_PANEL_POS := Vector2(1270.0, 90.0)` (pared exterior norte del taller `solar e5`).
   - Añadido `build_tinker_stations(vm)` para instanciar ambos objetos físicos en el taller del Chapuzas.
   - Añadidos `open_terminal_menu(vm, player)` y `open_grid_panel_menu(vm, player)` usando `WorldText.show_choice_menu` al pulsar `[E]` frente a cada aparato.
   - Añadida comprobación de testigos conscientes en `hack_terminal` (`_find_conscious_witness_near(vm, pos, 140.0)`): si hay testigo consciente en `< 140 px`, suma `wanted_level + 1`, aplica `-15` de afinidad y muestra aviso flotante, idéntico a `sabotage_electric_grid`.
   - Eliminadas de `inject_dialogue` del Chapuzas (`tinker`) las opciones de charla que abrían el submenú de la Terminal Lógica (`tinker_open_terminal`) y del Cuadro Eléctrico (`tinker_open_grid`); el Chapuzas ahora solo menciona dónde están físicamente en su taller.
   - En `after_load(vm)`, añadida llamada a `VillageUnderworld.sync_heist_visuals(vm)` para restaurar la visibilidad del objeto de robo activo tras cargar partida.

3. **`scripts/systems/VillageTrades.gd` (modificado, líneas 677–679):**
   - En `build_extras`, al construir el solar `"e5"`, invoca `VillageCulture.build_tinker_stations(vm)`.

4. **`scripts/systems/VillageUnderworld.gd` (modificado, líneas 67–98, 535–605 y 619–676):**
   - Actualizadas las coordenadas de `HEIST_TARGETS` para que cada objetivo esté dentro de su edificio real:
     - `"sello_noble"`: `Vector2(1275.0, -444.0)` (estudio interior de la Mansión Solariega `solar f1`).
     - `"caliz_capilla"`: `Vector2(745.0, 336.0)` (altar interior de la Capilla).
     - `"libro_gremial"`: `Vector2(764.0, -444.0)` (escritorio interior del Ayuntamiento `solar n4`).
   - Añadido `sync_heist_visuals(vm)` que instancia el `WorldInteractableProp` (`"heist_target"`) en `vm.heist_target_prop` mientras exista un encargo activo con `stolen == false`, y lo retira en cuanto pasa a `stolen == true` o se entrega al contacto (`heist_active = {}`).

5. **`scripts/visuals/WorldStage3D.gd` (modificado, líneas 138–140, 224–225, 369–395, 1692–1736, 1785–1797 y 2862–2978):**
   - En `_build_tinker_workshop_props`: añadida la **Terminal Lógica 3D** sobre mesa de roble en `(1188, 122)` (carcasa de latón/acero, visor CRT verde con emisión, rodillos de archivo y palancas) y el **Cuadro Eléctrico 3D** adosado a la fachada norte exterior en `(1270, 90)` (caja de hierro fundido, 3 cuchillas de cobre sobre porcelana, conducto vertical y bombilla indicadora `_grid_panel_bulb_3d` que cambia en vivo entre verde, ámbar y rojo según el estado de la red).
   - En `_build_mansion_study_props`: añadidos escritorio señorial y vitrina/pedestal de terciopelo en `(1275, -444)` (Mansión) y escritorio de registro gremial en `(764, -444)` (Ayuntamiento).
   - Añadido `_sync_heist_target_3d()` (invocado al crear el escenario y cada frame) que muestra el modelo 3D del objeto del robo activo (`sello_noble`, `caliz_capilla` o `libro_gremial`) solo mientras el encargo está activo y `stolen == false`, y lo oculta al robarlo.
   - En los edificios con entrada norte (`door_south == false`, como la Capilla y el Taller del Chapuzas), la parte alta del muro sur cerrado (`11.0..wall_h`) se asocia a `roof_cap` dejando un zócalo de `9.0 px` en `b_root`, de modo que al entrar el jugador y activarse el cutaway del tejado, el altar sur de la Capilla y el interior del taller se ven limpios sin quedar tapados por el muro sur exterior.

6. **`scripts/ui/InteractionSelector.gd` (modificado, líneas 96–101):**
   - Añadida prioridad de desempate (`-120.0` a `distance_squared`) para el objeto de robo (`heist_target_prop`) y las estaciones físicas del taller (`tinker_station`), evitando que los muebles/bancos decorativos adyacentes oculten el letrero `[E]` por defecto.

7. **`tools/screenshot_3d.gd` y `tools/tests/verify_all.gd` (modificados):**
   - En `tools/screenshot_3d.gd` (líneas 29–34 y 111–134): añadidos los sitios `"taller"` y `"robo"`.
   - En `tools/tests/verify_all.gd` (líneas 3539–3612): añadido `Block 96: Block FIS2` con todas las aserciones de existencia física, ausencia de opciones de diálogo en el Chapuzas, detección de testigos al usar la terminal y el cuadro eléctrico, coordenadas interiores de los 3 robos y ciclo de aparición/desaparición del prop de robo.

---

## 2. Reglas comprobadas

- **Regla 0 (Todo es físico):** Cumplida. Ni la Terminal Lógica ni el Cuadro Eléctrico se usan ya hablando con el Chapuzas; ambos son máquinas físicas en el taller (`solar e5`) y los 3 objetos de robo aparecen físicamente en sus edificios.
- **Regla 1 (Oro cerrado):** Cumplida. No se ha alterado ninguna fuente ni sumidero de oro (`gold_conservation_ok()` sigue pasando).
- **Regla 2 (Doble `[E]` para gastar):** Cumplida. Ninguna de estas tres interacciones cobra oro ni se ha quitado ninguna confirmación existente.
- **Regla 3 (Todo objeto nuevo lleva su `[E]`):** Cumplida. Los tres tipos de prop están en el grupo `"interactable"` con `CollisionShape2D` de radio `28 px` y devuelven su texto claro con `get_interaction_prompt(player)`.
- **Regla 4 (Todo objeto nuevo se ve en 2D y en 3D):** Cumplida. Cada objeto tiene dibujo 2D (`Visual2D` con `_draw()`) visible al alternar `[F10]` y modelo 3D (`MeshInstance3D` con materiales PBR) en `WorldStage3D.gd`.
- **No tocar lo que ya está bien:** Cumplido. No se tocaron el caballo/establo (`FIS1`), el sistema fiscal, `[F10]`, ni las fórmulas de consecuencias de `hack_terminal` / `sabotage_electric_grid` / `attempt_heist_steal`.

---

## 3. Pruebas ejecutadas y resultados

1. **Arranque limpio del juego:**
   - Comando: `flatpak run org.godotengine.Godot --headless --path . --quit-after 3`
   - Resultado: **OK** (`exit code 0`, `0` errores de parseo o `SCRIPT ERROR`).
2. **Suite principal (`verify_all.gd`):**
   - Comando: `flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd`
   - Resultado: **OK** (`Block FIS2 (Physical Terminal, Electric Panel & Heist Targets) OK` y `...TESTS PASSED!`, `exit code 0`).
3. **Suite de nombres (`names_check.gd`):**
   - Comando: `flatpak run org.godotengine.Godot --headless --path . -s tools/tests/names_check.gd`
   - Resultado: **OK** (`NAMES CHECK PASSED`, `exit code 0`).
4. **Simulación social de 7 días (`social_sim.gd`):**
   - Comando: `flatpak run org.godotengine.Godot --headless --path . -s tools/tests/social_sim.gd`
   - Resultado: **OK** (`SOCIAL SIM CHECK PASSED`, `exit code 0`).
5. **Cobertura de diálogos (`dialogue_coverage.gd`):**
   - Comando: `flatpak run org.godotengine.Godot --headless --path . -s tools/tests/dialogue_coverage.gd`
   - Resultado: **OK** (`COVERAGE DONE npcs=18 actions=639`, `0` líneas con `SCRIPT ERROR`).

---

## 4. Capturas generadas (`docs/capturas_fis2/`)

Generadas con ventana 3D real mediante:
`flatpak run org.godotengine.Godot --path . -s tools/screenshot_3d.gd -- docs/capturas_fis2 12,22 taller,robo`

- **`docs/capturas_fis2/taller_12h.png` y `docs/capturas_fis2/taller_22h.png`:**
  - Muestran el interior del taller del Chapuzas (`solar e5`) con el tejado recortado al estar el jugador dentro.
  - Se aprecia la **Terminal Lógica 3D** sobre su mesa en `(1188, 122)` con el visor verde encendido, el letrero **`[E] Usar la Terminal Lógica`** en pantalla, y en la pared norte exterior `(1270, 90)` el **Cuadro Eléctrico 3D** con sus tres cuchillas y su bombilla indicadora verde.
- **`docs/capturas_fis2/robo_12h.png` y `docs/capturas_fis2/robo_22h.png`:**
  - Muestran el interior de la Capilla con encargo activo de `"caliz_capilla"` (`stolen = false`).
  - Se aprecia sobre el altar en `(745, 336)` el **Cáliz de Plata 3D** y en pantalla el letrero **`[E] Robar el Cáliz de Plata de la Capilla`**.

---

## 5. Observaciones para el supervisor (cosas vistas pero no tocadas)

- En el altar de la Capilla e interiores con muchos bancos (`ChurchPew` / muebles decorativos), los muebles también pertenecen al grupo `"interactable"`. Para garantizar que el objeto del robo y la terminal/cuadro eléctrico tengan prioridad al acercarse sin alterar el radio ni el comportamiento de los bancos existentes, se ajustó únicamente el desempate en `InteractionSelector.gd` (`-120.0` en `distance_squared` para `heist_target_prop` y `tinker_station`), permitiendo seguir alternando con `G` o `Mayús+rueda` si el jugador desea sentarse en el banco.
- No se modificó ningún otro sistema fuera del alcance del Bloque FIS2.
