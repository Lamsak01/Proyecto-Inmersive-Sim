# Pruebas y comandos de Godot

Godot 4.7.2 por Flatpak, desde la raíz del proyecto. **Una sola prueba por tarea** (la que toca lo cambiado); las grandes
solo en rondas de auditoría que pida el usuario. Lanzar de una en una, con `timeout`; las largas en segundo plano.
Pide permiso al usuario antes de cualquier prueba, diciendo cuánto tarda.

```bash
# Arranque sin errores (tras editar código o escenas; ~20 s). Los autoloads no existen en --check-only: no lo uses.
timeout 120 flatpak run org.godotengine.Godot --headless --path . --quit 2>&1 | grep -c "SCRIPT ERROR"
# OJO: ese arranque solo carga el menú; un error de un script del pueblo (VillageManager*) NO sale. Si tocas uno, pasa
# también --check-only sobre él y sus hijos y busca «Parse Error» (los «Identifier not found» de autoloads son normales):
timeout 120 flatpak run org.godotengine.Godot --headless --path . --check-only -s scripts/systems/VillageManagerSocial.gd 2>&1 | grep "Parse Error"

# Física 3D (cuerpos, pisos, agua, buceo, vista; ~2 min) → «FISICA 3D: PASSED»
timeout 300 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/fisica_3d.gd 2>&1 | grep "FISICA 3D"
# Entrar y salir por las 29 puertas (~2 min) → «PUERTAS 3D: PASSED»
timeout 600 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/puertas_3d.gd 2>&1 | grep "PUERTAS 3D"
# Todo el juego (~8–15 min) → «...TESTS PASSED!». La sección «S2: un testigo convierte la infidelidad en chisme» falla al azar: repite.
timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd 2>&1 | grep -c "TESTS PASSED"
# Fotos fijas con ventana (~2 min) y comparación con una carpeta de referencia → «CAPTURAS_FIN peor=…%» (ruido normal < 1 %)
flatpak run org.godotengine.Godot --path . -s tools/tests/capturas_fijas.gd -- <carpeta_salida> [carpeta_referencia]
# Vecinos atascados: simulación de N horas (~1 min por hora) → «ATASCOS: 0»
flatpak run org.godotengine.Godot --headless --path . -s tools/tests/atascos_vecinos.gd -- [horas] [hora_inicio] [cocinero] [jugador:x,y|jugador:puerta:<id>]
# Menú, ajustes, teclas, guardado y pausa (~2 min) → «MENU PROBE: PASSED»
timeout 300 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/menu_probe.gd 2>&1 | grep "MENU PROBE"
# Charla en primera persona: el reloj se para y la frase sale entera (~1 min) → «PAUSA DIALOGO: PASSED»
timeout 180 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/pausa_dialogo.gd 2>&1 | grep "PAUSA DIALOGO"
# Caso I, día 2: el guardia te encuentra y te habla antes de las 07:00 (~1 min) → «AVISO CASO1: PASSED»
timeout 240 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/aviso_caso1.gd 2>&1 | grep "AVISO CASO1"
# Dormir: quieto hasta el alba y un golpe te despierta (~40 s) → «DORMIR QUIETO: PASSED»
timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/dormir_quieto.gd 2>&1 | grep "DORMIR QUIETO"
# 1.ª persona: apuntar al centro del tablón y a una trampilla a 1,6 m (~40 s) → «APUNTAR FP: PASSED»
timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/apuntar_fp.gd 2>&1 | grep "APUNTAR FP"
# Caso I: el día 1 el zapato del puente ni se ve ni se examina; el día 2 sí (~1 min) → «PISTAS DIA1: PASSED»
timeout 150 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/pistas_dia1.gd 2>&1 | grep "PISTAS DIA1"
# Nombres (~2 s) → «NAMES CHECK PASSED» · Simulador social de 60 días → «SOCIAL SIM CHECK PASSED»
timeout 60 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/names_check.gd 2>&1 | tail -3
timeout 150 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/social_sim.gd 2>&1 | tail -3
# Cobertura de diálogos (0 «SCRIPT ERROR») · Guardado y carga 7 días (<10 min) → «GUARDADO LARGO PASSED»
timeout 80 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/dialogue_coverage.gd 2>&1 | grep -c "SCRIPT ERROR"
timeout 540 flatpak run org.godotengine.Godot --headless --path . --fixed-fps 60 -s tools/tests/guardado_largo.gd 2>&1 | tail -2
# Inventario del mundo (con ventana, ~25 s cada una): qué sigue a las piezas del editor → docs/INVENTARIO_MUNDO.md
flatpak run org.godotengine.Godot --path . -s tools/tests/inventario_mundo.gd -- quieto   # y luego -- movido
timeout 120 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/inventario_mundo.gd -- comparar
# Rendimiento con ventana: tools/tests/perf_fisica.gd, perf_zonas.gd. Fotos sueltas: tools/screenshot_3d.gd
```

- Las pruebas automáticas **no ven los fallos visibles**: mira las fotos de verdad y pregúntate «¿esto lo encontraría un
  jugador?». Un sistema que existe pero el jugador no puede encontrar cuenta como fallo.
- Fotos de referencia del mundo 3D en `docs/capturas_mundo3d/` (mapa ×5: `referencia_x5/`); fotos de arreglos en `docs/capturas_arreglos/`
  (`AAAA-MM-DD_tema_antes/despues.png`); capturas del usuario en `docs/capturas_usuario/AAAA-MM-DD/`.
- Avisos amarillos del editor solo los ve el usuario: pídele captura con archivo y línea.
- Nunca `pkill`/`pgrep -f` con un patrón que aparezca en tu propio comando; no cierres el editor del usuario.
