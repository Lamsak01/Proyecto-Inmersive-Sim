# Convenciones del código y trampas aprendidas

Las reglas generales (tipado, tamaño, arquitectura) están en `CLAUDE.md` §4. Aquí, lo concreto de este proyecto.

## Estilo
- Indentación con **tabs**. Los `.gd` se guardan con saltos de línea mixtos (`.gitattributes: * text=auto`): si editas con
  Python, abre con `newline=''` y conserva el salto que ya tenga el archivo.
- Cabecera de cada archivo: 2–3 líneas `##` en español sencillo diciendo para qué sirve (y fecha/decisión si viene de una).
- Nombres nuevos en español (`Cuerpo3D`, `Vista.ve`, `Suelo.altura_px`); lo antiguo sigue en inglés y se renombra solo al tocarlo.

## Trampas de Godot 4.7 en este proyecto
- **`class_name` nuevo** no se registra en modo headless hasta que el editor reindexa («Identifier not declared»): para
  scripts nuevos usa `const X = preload("res://...")`. Y ponlo **después** de `class_name`/`extends` si el archivo lo tiene.
- **Ciclos de `preload()`** («Could not resolve class …»): los ayudantes que usan muchos scripts no llevan preloads
  (ejemplo: `scripts/fisica/AndarMapa.gd`).
- `obj.get("metodo")` **no llama a métodos**: usa `obj.call("metodo")`; `get` solo para propiedades. Con metas o
  propiedades que pueden no existir compara `== true`, no `bool(...)` (puede ser un Callable).
- Los autoloads no existen en `--check-only`: valida ejecutando (`--headless --quit` o la prueba que toque).
- En pruebas `extends SceneTree`: asigna `current_scene` antes de usar código que busca `UI/UIRoot`.
- En `verify_all.gd` no uses `WorldClock` directo (`root.get_node_or_null("/root/WorldClock")`) ni
  `VillageNPC.ActivityState.*` (enteros 0 WORKING, 1 EATING, 2 SLEEPING, 3 SOCIALIZING): recargas circulares.
- `names_check.gd` comprueba el número exacto de acciones sociales (`SocialDialogueData.ALL_ACTIONS.size()`): actualízalo.
- Modelos `.obj` nuevos: borra las líneas `Ka` del `.mtl` (`sed -i '/^Ka /d'`) o el editor avisa por cada material.
- Mallas con esqueleto (brazos en 1.ª persona): pon `custom_aabb` o el recorte de cámara las hace desaparecer.
- Archivos `.import`/`.uid` siempre en Git. `docs/` y `GameVault/` llevan `.gdignore` (Godot no los mira).

## Reglas del pueblo que el código ya exige
- **Puertas de edificios:** al menos dos personas de ancho (`door_width >= MIN_DUAL_LANE_DOOR_WIDTH`, 34 px; recomendado
  38–44), registradas en `building_footprints`/`building_doors` con su `door_dir`, carriles libres de muebles; lo comprueba
  `vm.check_all_building_doors_and_lanes()` en `verify_all.gd`.
- **Modo demo** (`GameManager.DEMO_MODE_DEFAULT = true`): pausa los sistemas secundarios que estorban al Caso I (crímenes
  espontáneos, hampa, secta, migraciones, gobierno, ecosistema, escuela y mercado) y deja justicia, forense, taberna,
  oficios, misiones, biblioteca, fe y casa de comidas. Para el juego completo: `GameManager.set_demo_mode(false)`.
- Los vecinos se identifican por `get_person_key()` (`person_profile.person_id`). Todo es procedural: nada depende de
  nombres fijos.
- Muros y suelos 2D con `TextureRect`: `expand_mode = EXPAND_IGNORE_SIZE`.
- Distancias de ver/oír/golpear: siempre por `scripts/fisica/Vista.gd` (nunca una distancia plana nueva).
