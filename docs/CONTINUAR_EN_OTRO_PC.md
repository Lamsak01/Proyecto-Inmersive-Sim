# Cómo seguir el proyecto en otro ordenador (actualizado 2026-11-06, paso al PC de escritorio)

## 1. Bajar el proyecto
1. Abre una terminal en la carpeta del juego del otro ordenador y ejecuta `git pull` (rama `main`).
   Si aún no lo tienes: `git clone <url del repositorio>`.
2. Abre el proyecto con **Godot 4.7.2** (renderizador Compatibility). La primera vez tarda un poco porque Godot
   importa de nuevo texturas y modelos. Es normal.
3. Pulsa **F10** en el juego para cambiar entre la vista 2D y la 3D (F9 es cargar partida).

## 2. Qué NO viaja con git (y no hace falta)
- `assests/Assets 3d/` (≈114 MB): solo son los paquetes descargados en bruto. El juego no los usa: los modelos
  buenos ya están copiados en `assests/curated_3d/` y las animaciones ya preparadas en
  `assests/curated_3d/animations/ual_male.res` y `ual_female.res` (sí están en git).
  Solo harían falta para **volver a preparar las animaciones** con `tools/bake_character_animations.gd`; en ese caso
  hay que bajar otra vez la *Universal Animation Library 1 y 2 (Standard)* de Quaternius (CC0) y los
  *Universal Base Characters*, y descomprimirlos en `assests/Assets 3d/descargas_claude/x/`.
- La carpeta `.godot/` (caché de Godot): se regenera sola.

## 3. Comprobar que todo funciona
Las cuatro pruebas de `docs/HANDOFF.md` §3 (de una en una). Deben salir NAMES CHECK PASSED, COVERAGE DONE con 0
SCRIPT ERROR, SOCIAL SIM CHECK PASSED y TESTS PASSED.
Para capturas del pueblo: `tools/screenshot_3d.gd` (instrucciones dentro del archivo; con Flatpak, guardar dentro
del proyecto, no en /tmp).

## 4. Dónde nos quedamos (2026-11-06) y lo siguiente

### Hecho en la última sesión (portátil)
- Objetos quietos, casa mejorada del jugador y gallinero en 3D; niebla nocturna (solo visual).
- Aldea ampliada, pasos 1–3 de `docs/PLAN_AMPLIAR_ALDEA.md`: tres tamaños de casa con precio 80/100/140, callejas
  curvas, Pozo de la Ronda, huerto vecinal y barrios del Lago, Caseríos del Bosque y Molino del Este.
- **PROVISIONAL: la partida nueva empieza con ~40 vecinos** (`START_POPULATION` en `VillageMigration.gd`; 0 = arranque
  normal). La mitad de sus casas salen en los barrios apartados. Las pruebas (headless) no lo usan.
- Rendimiento, sin cambiar nada visible: árboles y rocas dibujados por lotes y piezas quietas de los edificios
  juntadas. Las cuatro pruebas pasan (último commit `d214d20`).

### Lo siguiente, en este orden
0. **(2026-11-05) Arcas en números rojos:** tras cerrar las fugas de oro, una partida sola de 15 días deja las arcas
   en 75 (antes 472). Gastan ~60/día (sueldos enteros, inversiones) y los impuestos del sábado traen ~190/semana. El oro
   se acumula en los bolsillos de los vecinos (~3.800). Decisión pendiente del usuario: subir impuestos o bajar sueldos.
1. **Rendimiento de los vecinos (lo pendiente más importante).** En el portátil (Intel UHD 620) el usuario veía
   ~10 fps con 40 vecinos. Medido: la tarjeta no es el freno; lo es la CPU, que calcula ~25–30 ms de lógica y
   ~16 ms de física por fotograma; con los vecinos quietos la física baja a 4 ms. Paso siguiente acordado: **medir
   qué parte del vecino cuesta más (solo medir, ~5 min, pidiendo permiso) y luego abaratarla sin cambiar lo que
   hace**. El usuario **NO quiere** que los vecinos lejanos se simulen «a ratos».
   - En el PC de escritorio conviene medir primero cuántos fps salen: si va bien, puede que esto baje de prioridad.
   - **2026-11-05: el usuario confirma que en el PC de escritorio va bien con 40 vecinos.** Baja de prioridad;
     se pasa a los animales 3D. Retomar si vuelve a ir lento (portátil o más vecinos).
2. **Animales en 3D** — hecho (2026-11-05): ciervo, zorro y perro animados; jabalí = lobo animado provisional.
   Falta: conejo, gato, gallina (no hay modelos animados del mismo estilo; ver «Assets de pago» en la bóveda).
   Antes: (gallinas, vacas, caballos y los del bosque): estaba parado por falta de internet; ahora ya
   se pueden buscar modelos con textura (CC0, p. ej. Quaternius). Presentar el plan antes.
3. Pendientes menores: paso 4 de la aldea (casas en L, «más adelante»); decidir si la niebla quita vista a los
   vecinos; sauces del lago, carteles flotantes, personajes con más estilo («Assets de pago» en la bóveda).
4. Cuando el usuario termine de probar con 40 vecinos: poner `START_POPULATION = 0`.

### Herramientas útiles que dejé
- Capturas: `tools/screenshot_3d.gd` (sitios: plaza, iglesia, lago, cementerio, cerca, campamento, barrio_lago,
  caserios, molino, casa_jugador, norte).
- Las sondas de medición se escriben en `.godot/` (lo ignora git), se lanzan con
  `flatpak run org.godotengine.Godot --path . -s res://.godot/sonda.gd` y se borran al terminar. Con ventana (sin
  `--headless`) para que arranquen los 40 vecinos y el 3D. Medir con `Performance.get_monitor` (TIME_PROCESS,
  TIME_PHYSICS_PROCESS, RENDER_TOTAL_DRAW_CALLS_IN_FRAME) y la vsync apagada.

## 5. Dónde está todo lo escrito
- Registro de la estética 3D, paso a paso: `docs/REGISTRO_ESTETICA_3D.md`.
- Estado general y reglas: `docs/HANDOFF.md` (§7) y `CHANGELOG.md`.
- Bóveda de Obsidian: `GameVault/` → `02_Sistemas/Estética Retro 3D.md`, `05_Roadmap_y_Lore/Tablero.md`,
  `05_Roadmap_y_Lore/Assets de pago.md`, diario `06_Diario/`.
- Reglas para el agente: `CLAUDE.md` (español, breve, sin código en los mensajes, una pregunta al final).

## 6. Mensaje para pegar al agente en el otro ordenador
> Lee `CLAUDE.md`, `docs/HANDOFF.md` y `docs/CONTINUAR_EN_OTRO_PC.md`. Seguimos con el punto 4: el rendimiento de
> los vecinos. Primero dime cuántos fps da este ordenador con los 40 vecinos y luego propón qué medir, en pocas
> líneas. Pide permiso antes de lanzar nada.
