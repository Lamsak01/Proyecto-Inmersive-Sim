# Informe de Cierre — Bloque A2: Pantalla de ayuda de controles al empezar

**Fecha:** 2026-11-06  
**Encargo:** `docs/ENCARGO_A2_CONTROLES.md`

---

## 1. Archivos tocados y funciones modificadas o creadas

### `scenes/ui_root.gd`
- `_ready()`: construye el panel de controles con `_setup_controls_panel_ui()`, conecta `GameManager.game_loaded` a `_on_game_loaded` y, al iniciar una partida nueva fuera del ejecutor sin ventana (`DisplayServer.get_name() != "headless"` y `GameManager.game_data.is_empty()`), llama a `open_controls_panel()`.
- `_setup_controls_panel_ui()`: crea `controls_panel` centrado en pantalla con el mismo estilo oscuro semitransparente de `ui_root.gd` (`_make_style`), título «Controles», las dos columnas («Lo básico» con 8 líneas en el orden exacto del encargo y «Más» con las 7 líneas indicadas), sin emojis, y el pie «Pulsa Esc, Intro o haz clic para empezar».
- `open_controls_panel()`: muestra `controls_panel` (`controls_panel.visible = true`) y para el reloj del juego mediante `WorldClock.set_activity_pause(true)`.
- `close_controls_panel()`: oculta `controls_panel` (`controls_panel.visible = false`) y reanuda el reloj mediante `WorldClock.set_activity_pause(false)`.
- `_on_game_loaded(_filepath)`: cierra `controls_panel` si estaba abierto al cargar una partida guardada.
- `_input(event)` y `_unhandled_input(event)`: mientras `controls_panel` está visible, pulsar `Esc`, `Intro` o hacer clic izquierdo llama a `close_controls_panel()` y consume el evento (`set_input_as_handled()`) para que el clic no dispare un ataque al empezar.
- `_setup_inventory_ui()`: añade el botón «Controles» en la barra inferior de `inv_panel` (junto a Guardar, Cargar y Cerrar) para volver a abrir `open_controls_panel()`.

### `tools/tests/verify_all.gd`
- Añadido al final de `_initialize()` el bloque de prueba «A2 controles» (`Block A2 (New Game Controls Help Panel & Clock Pause)`):
  1. Llama a `open_controls_panel()` y comprueba que `controls_panel.visible` es `true` y `WorldClock.is_time_frozen()` es `true`.
  2. Llama a `close_controls_panel()` y comprueba que `controls_panel.visible` es `false` y `WorldClock.is_time_frozen()` es `false`.

---

## 2. Comprobación de cada tecla en el código y notas para el supervisor

### A. Verificación de las 15 líneas del panel «Controles»
Todas las teclas indicadas en el encargo para las dos columnas existen y hacen exactamente lo descrito:
1. **Mover (`W A S D`)**: verificado en `project.godot` (`move_up`, `move_down`, `move_left`, `move_right`) y `PlayerMovementController._handle_input`.
2. **Atacar (`clic izquierdo, apuntando con el ratón`)**: verificado en `PlayerCombatController._unhandled_input` (`MOUSE_BUTTON_LEFT` → `attack(true)`) y `PlayerCombatController._update_weapon_visuals`.
3. **Usar o hablar (`E`)**: verificado en `project.godot` (`Interact` = `E`), `Player._unhandled_input` → `_handle_interactions` e `InteractionSelector.use_selected`.
4. **Cambiar de objetivo cuando hay varios (`G o Mayús + rueda`)**: verificado en `InteractionSelector._unhandled_input` (`KEY_G` y `MOUSE_BUTTON_WHEEL_UP` / `MOUSE_BUTTON_WHEEL_DOWN` con `shift_pressed`).
5. **Rodar (`Espacio`)**: verificado en `PlayerMovementController._unhandled_input` (`KEY_SPACE` → `start_roll()`).
6. **Parar un golpe (`Q`)**: verificado en `PlayerCombatController._unhandled_input` (`KEY_Q` → `start_parry()`).
7. **Sigilo (`C`)**: verificado en `PlayerMovementController._unhandled_input` (`KEY_C` alterna `is_stealthing`).
8. **Mochila (`I`)**: verificado en `scenes/ui_root.gd` (`_unhandled_input`, `KEY_I` → `_toggle_inventory()`).
9. **Rueda de acciones (`Tab`)**: verificado en `scenes/ui_root.gd` (`_unhandled_input`, `KEY_TAB` → `tool_wheel.open_wheel()` / `close_wheel()`).
10. **Vecinos (`J`)**: verificado en `scenes/ui_root.gd` (`_unhandled_input`, `KEY_J` → `social_glossary.call("toggle_panel")`).
11. **Mapa (`M`)**: verificado en `scenes/ui_root.gd` (`_unhandled_input`, `KEY_M` → `valley_map.call("toggle_full_map")`).
12. **Misiones (`L`)**: verificado en `scenes/ui_root.gd` (`_unhandled_input`, `KEY_L` → `quest_log.call("open_panel")`).
13. **Herramientas (`1–9`)**: verificado en `Player._unhandled_input` (`KEY_1`..`KEY_9` → `equip_tool_by_index`).
14. **Guardar / cargar (`F5 / F9`)**: verificado en `GameManager._unhandled_input` (`KEY_F5` → `save_game()`, `KEY_F9` → `load_game()`).
15. **Velocidad del tiempo (`F1–F4`)**: verificado en `WorldClock._unhandled_input` (`KEY_F1`..`KEY_F4` → `set_persistent_time_scale`).

### B. Tecla `H` ocupada y botón «Controles»
- **Estado de la tecla `H`:** en `scenes/ui_root.gd` (`_unhandled_input`, `event.physical_keycode == KEY_H`), la tecla `H` **ya está en uso** para abrir y cerrar `medical_panel` («Panel Clínico»).
- Siguiendo la instrucción del encargo (*«si H ya hace algo, no la cambies: pon un botón "Controles" en el menú de pausa si existe, y dilo en el informe. La línea de ayuda de abajo del reloj (`clock_sub_label`) sigue igual; añade al final "· [H] Controles" solo si H quedó libre y en uso»*):
  1. No se ha tocado el atajo `KEY_H` ni se ha modificado `clock_sub_label`.
  2. En el juego no existe un menú de pausa independiente al pulsar `Esc` (`KEY_ESCAPE` en `scenes/ui_root.gd` solo cierra el panel abierto en ese momento), sino que los botones de sistema (`[F5] Guardar`, `[F9] Cargar`, `[H] Panel Clínico`, `[I / ESC] Cerrar`) están en la barra inferior de `inv_panel` (`_setup_inventory_ui`). Se ha colocado ahí el botón «Controles» para que el jugador pueda volver a abrir la ayuda en cualquier momento.

---

## 3. Verificación ejecutada

1. **Arranque sin errores:**
   - `timeout 60 flatpak run org.godotengine.Godot --headless --path . --quit` → código de salida `0`.
2. **Suite completa `verify_all.gd` (una sola ejecución al cierre):**
   - `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s res://tools/tests/verify_all.gd` → código de salida `0`, incluyendo `Block A2 (New Game Controls Help Panel & Clock Pause) OK`.
