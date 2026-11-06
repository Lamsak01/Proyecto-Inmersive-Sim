# Encargo para Antigravity (escrito por Claude Code, supervisor)

> Fecha: 2026-11-05. Pega este archivo entero como primer mensaje a Antigravity, o dile: «Lee
> `docs/ENCARGO_ANTIGRAVITY.md` y haz lo que pone».

---

## 0. Las cosas han cambiado: nuevo reparto de trabajo

Desde hoy (2026-11-05), por decisión del usuario:

- **Antigravity (tú) escribe el código** del juego.
- **Claude Code es el supervisor**: prepara los encargos (como este), revisa lo que subas a GitHub (cambios, pruebas,
  reglas del proyecto) y le dice al usuario si está bien o qué hay que corregir.
- **El usuario** decide el diseño y aprueba. No programa: háblale siempre en español, breve y sin código.

Cómo trabajamos a partir de ahora:

1. Haces **solo** lo que pide el encargo. Si ves otra cosa rota, apúntala en tu informe; no la arregles por tu cuenta.
2. Trabajas en bloques pequeños. Al cerrar el bloque: pruebas, documentación, commit y push a `main` (ver §3).
3. Al terminar, deja un **informe para el supervisor** en `docs/INFORME_ANTIGRAVITY.md` (qué hiciste, qué archivos
   tocaste, qué probaste y con qué resultado, qué no pudiste hacer). Claude Code lo leerá y revisará tu commit.
4. Si algo del encargo no te cuadra o el código no es como dice aquí, **no lo inventes**: escríbelo en el informe y
   pregunta. Si el encargo y `git` no coinciden, manda `git`.

---

## 1. Antes de tocar nada (lectura obligatoria)

- `CLAUDE.md` (reglas de comunicación y de trabajo; valen también para ti).
- `docs/HANDOFF.md` §3 (cómo pasar las pruebas) y §7 (estado; arriba del todo están los cambios de hoy).
- `GameVault/01_Vision_y_Reglas/Las 7 Reglas de las Auditorías.md`.
- Notas de la bóveda de los sistemas que toques: `GameVault/02_Sistemas/Red Eléctrica.md`,
  `Terminales Lógicas Electromecánicas.md`, `Red de las Sombras.md`.
- `git log --oneline -15` para ver lo último.

Reglas que el supervisor va a comprobar sí o sí:

- **Todo es físico:** nada se resuelve desde un menú de conversación ni con contadores invisibles. Las acciones de
  riesgo ocurren junto al objeto, con testigos reales (vecinos despiertos cerca, en la misma planta).
- **Suma cero:** ningún oro nace ni desaparece. Usa las ayudas `pay_into`, `take_from_treasury`, `role_npc` de
  `VillageManager` (ver HANDOFF §7).
- **Doble E** para gastar oro en el mundo (`VillageHousing.press_twice`).
- **Todo reto se puede perder y tiene espera** (1 vez al día como ya está).
- **La tecla E:** cualquier objeto nuevo con el que se interactúe debe ser una `Area2D` del grupo `interactable` y
  tener `get_interact_label(player)` para que salga su letrero «[E] …» (`scripts/ui/InteractionSelector.gd`).
- **Vista 2D y 3D:** todo objeto nuevo debe verse en 2D y en 3D (`WorldStage3D.gd`). F10 cambia de vista (F9 es cargar).
- Ya decidido, no lo cambies: velocidad del caballo ×1,45; impuestos por tramos 0/15/30 %.

---

## 2. El encargo: bloque FIS2

Contexto: el usuario quiere que todos los sistemas «en papel» pasen a ocurrir en el mundo. El bloque FIS1 (asaltos con
atacantes reales) ya está hecho por Claude Code. Este es el siguiente.

### 2.1 Terminal Lógica como máquina de verdad

Ahora mismo: se hackea hablando con el arreglador (opción «Hackear en sigilo la Terminal Lógica…» en
`VillageCulture.add_dialogue_choices`, rol TINKER).

Hay que:
1. Poner la **Terminal Lógica** como objeto dentro del Taller del Arreglador (solar `e5`), sobre una mesa: dibujo 2D y
   modelo 3D (puedes usar un mueble/caja de `assests/curated_3d/props/` o piezas sencillas en `WorldStage3D.gd`).
2. Con **[E]** junto a ella se abre un menú con las 3 opciones actuales (registro fiscal, archivo policial,
   controlador de red), que usan la función que ya existe (`hack_terminal`). Mantén la espera de 1 vez al día.
3. **Testigos en el momento de hackear:** si el arreglador u otro vecino despierto te ve (cerca, misma planta), es
   delito (igual que ya hace el sabotaje con `_find_conscious_witness_near`). De noche, con el taller vacío, es más
   fácil.
4. **Quita** esas opciones de la conversación con el arreglador.

### 2.2 Cuadro eléctrico como objeto de verdad

Ahora mismo: se sabotea hablando con el arreglador («Manipular a escondidas el cuadro eléctrico…»).

Hay que:
1. Poner el **cuadro eléctrico** en la pared exterior del Taller del Arreglador: dibujo 2D y modelo 3D.
2. Con **[E]** se abre el menú de los 3 interruptores actuales (farolas, riego, apagón), usando `sabotage_grid`. Misma
   espera de 1 al día y misma comprobación de testigos que ya existe.
3. **Quita** esas opciones de la conversación con el arreglador.

### 2.3 Que se vean los objetos de los 3 grandes robos

Ahora mismo: el robo ya se hace en persona (`VillageUnderworld.try_interact`: hay que ir al sitio, de noche o con
ganzúa, con testigos), pero **no se ve ningún objeto**. Los sitios están en `HEIST_TARGETS`.

Hay que:
1. Mientras haya un encargo de robo activo, dibujar el objeto en su sitio (sello de lacre, cáliz de plata, libro
   mayor) en 2D y 3D, con su `Area2D` interactiva y letrero «[E] Robar …». Al robarlo, desaparece.
2. **Comprueba los sitios:** el sello tiene que estar dentro de la mansión, el cáliz en el altar de la capilla y el
   libro dentro del ayuntamiento. Sospecho que el libro (465, 24) cae en mitad de la plaza: si es así, muévelo dentro
   del edificio correcto y dilo en el informe.

### 2.4 Pruebas del bloque

- Un test por comportamiento nuevo en `tools/tests/verify_all.gd` (por ejemplo: la terminal ya no sale en la charla
  del arreglador; usar la terminal con un testigo delante sube la búsqueda; el objeto del robo existe mientras hay
  encargo y desaparece al robarlo).
- Fotos con `tools/screenshot_3d.gd` (añade sitios «taller» y «robo»), con ventana, guardadas dentro del proyecto.
- Las cuatro pruebas de HANDOFF §3, de una en una, con `timeout`, y además
  `flatpak run org.godotengine.Godot --headless --path . --quit-after 3` sin ningún «SCRIPT ERROR».
- **Pide permiso al usuario antes de lanzar las pruebas** y dile cuánto tardan (unos 12 minutos las cuatro).

---

## 3. Al cerrar el bloque

1. `docs/HANDOFF.md` §7: una entrada arriba con lo técnico.
2. `CHANGELOG.md`: entrada en lenguaje de jugador.
3. `docs/REGISTRO_TRABAJO.md`: fila FIS2 en el «Bloque FIS».
4. Bóveda: notas de los sistemas tocados («Notas de diseño»), tarjeta en `GameVault/05_Roadmap_y_Lore/Tablero.md` y
   línea en el diario del día (`GameVault/06_Diario/`).
5. Commit con mensaje en español y push a `main`.
6. `docs/INFORME_ANTIGRAVITY.md` para el supervisor (ver §0).
7. Al usuario: resumen corto en lenguaje de jugador, sin código, y una sola pregunta al final.
