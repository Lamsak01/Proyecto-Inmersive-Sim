# La Placa de Petri

Immersive sim **3D** en primera persona (solo 1.ª persona: la vista desde arriba ya no cuenta) hecho con **Godot 4.7.2** (GDScript, Flatpak).
Un forastero llega a un valle con ~17 vecinos con rutina propia; el bucle principal es **detective** (Caso I). El usuario
no programa (audita leyendo la lógica general) y trabaja en **dos ordenadores Linux sincronizados por GitHub**.
Este archivo lo leen por igual Claude Code, Gemini y Antigravity (`GEMINI.md` y `AGENTS.md` son enlaces a él).

## 1. Reparto de trabajo (desde 2026-11-11)

- **Claude Code — programador y arquitecto principal (85 %):** escribe el GDScript, diseña componentes desacoplados,
  mantiene limpio el repositorio y GitHub.
- **Gemini / Antigravity — especialista y auditor bajo demanda (15 %):** solo lo abre el usuario para álgebra 3D compleja
  (Transform3D, cuaterniones, conos de visión), shaders (`.gdshader`) o auditar el repositorio si Claude falla dos veces
  en el mismo fallo. **Nadie lanza, relanza ni para a otro agente**; el vigilante nocturno sigue desactivado.
- **Cero intermediarios:** nada de informes largos ni «prompts puente» para el otro agente en tareas rutinarias.
- **TEMPORAL (desde 2026-11-14, pedido por el usuario):** Antigravity trabaja en paralelo con la lista de
  `docs/TAREAS_ANTIGRAVITY.md` (reparto de archivos para no pisarse; sus reglas mandan). Claude lleva los cimientos del
  paso a 3D. Cuando el usuario lo dé por acabado se borran esta línea y ese archivo.

## 2. Protocolo de sesión y cambio de ordenador

1. `git pull` antes de nada. Lee **solo** este archivo y `docs/ESTADO_ACTUAL.md`. No abras `docs/specs/` ni scripts
   hasta saber qué tarea se toca; luego abre **solo** la especificación y los archivos de esa tarea (`docs/INDICE_SISTEMAS.md`
   dice cuál es cada uno). Busca con grep/glob antes de leer; lee por trozos; edita con diffs parciales.
2. Si un cambio toca más de 2 scripts o la arquitectura: plan de máximo 6 líneas y esperar confirmación.
3. **Cierre de tarea:** `godot --headless --quit` sin errores (comando en `docs/specs/PRUEBAS.md`) y **una sola prueba**,
   la que toca lo cambiado; línea en `CHANGELOG.md`; reescribir `docs/ESTADO_ACTUAL.md` (máximo 45 líneas, nunca
   historial); `git pull --rebase`, commit y push a `main`. Resumen al usuario de 3 líneas.
4. **Bóveda de Obsidian (`GameVault/`):** es el espacio del usuario. **Bloqueada por defecto:** no se lee ni se actualiza
   salvo que el usuario lo pida explícitamente (igual `docs/archivo/`, el historial). No tocar nunca `GameVault/03_La_Secta/`,
   el «Lore provisional», `GameVault/99_Archivo/` ni `GameVault/.obsidian/`. La exportación a Obsidian
   (`docs/archivo/Exportar_a_Obsidian.md`) solo bajo petición expresa.
5. Al cerrar un bloque de diseño, apúntalo en `docs/FALLOS_VISIBLES.md` (si era un fallo) o `docs/VISION_Y_FUTURO.md`
   (si era una idea). Las dudas de diseño con el usuario ausente van a `docs/PREGUNTAS_PENDIENTES.md`; lo técnico se decide
   sin preguntar.

## 3. Cómo hablar al usuario (obligatorio en TODOS los mensajes)

1. **Español, corto, sin jerga**; si usas una palabra técnica, explícala en la misma frase con una comparación.
2. **Cero código en los mensajes:** no nombres archivos, funciones, variables ni líneas, salvo que lo pida. Habla del JUEGO.
3. **Cada problema o propuesta:** qué pasa (en palabras de jugador) · qué notaría el jugador (o «no se nota, es para el
   futuro») · qué pasa si no se hace · recomendación (ya / más adelante / no) y coste (poco / medio / mucho).
4. **Máximo 10–12 líneas por mensaje.** Varias cosas: la más importante primero y pregunta si quiere oír el resto.
5. **Permiso antes de cualquier prueba o partida de prueba**, diciendo cuánto tarda.
6. **Cierre:** una sola pregunta clara de lo que necesitas. Evalúa las ideas con honestidad; no des la razón por defecto.
7. Distingue lo probado de lo supuesto. **Una prueba verde no significa que esté bien:** mira capturas de verdad
   (`docs/FALLOS_VISIBLES.md` es la lista del usuario; apunta ahí lo que te cuente).

## 4. Calidad del código (intocable) y economía de tokens

- **Prohibido degradar** arquitectura, tipado, validaciones o legibilidad para ahorrar tokens. El ahorro viene de cero
  relleno conversacional, búsqueda quirúrgica, ediciones parciales y lectura bajo demanda.
- **Godot 4 estricto:** nada de sintaxis de Godot 3. Tipado estático al 100 % (variables, constantes, arrays tipados,
  parámetros y retornos, `-> void`). Evitar ciclos de `preload()` (ayudantes sin preloads, como `scripts/fisica/AndarMapa.gd`).
- **Tamaño:** archivos **nuevos** de 50–150 líneas (si pasan de 180, proponer partirlos); los **existentes** hasta ~600
  (muchos las superan; se parten **solo cuando se tocan** por una tarea, nunca de golpe). Un script = una responsabilidad;
  una función = una tarea; carpetas por tema; cabecera de 2–3 líneas en español sencillo en cada archivo.
- **Arquitectura desacoplada:** composición sobre herencia; `@export` para hijos directos; señales o autoload para hablar
  con otros sistemas; nada de rutas frágiles `get_node("../../..")`; datos de ítems, estados y estadísticas en Resources
  propios (`@export`). Sin código muerto ni repetido.
- **Legibilidad para auditoría humana:** nombres descriptivos, cláusulas de guarda al principio (`return` temprano,
  `is_instance_valid()`), máximo 2 niveles de `if`, cero números mágicos (`const` o `@export_group`), comentarios breves
  en español explicando **por qué** existe cada bloque.
- **Escenas 3D:** se editan con las herramientas del flujo (`tools/hornear_*.gd`, `tools/esparcir_arboles.gd`, el editor
  del mapa en Godot) o con ediciones controladas; prohibido retocar a ciegas coordenadas o subrecursos gigantes de un
  `.tscn` a mano cuando toca hacerlo por código o herramienta. Tras cambiar una escena, `godot --headless --quit`.
- Si el usuario tiene el editor de Godot abierto, no lo cierres; no uses `pkill`/`pgrep -f` con un patrón de tu propio
  comando. Archivos temporales en la carpeta de trabajo del agente, no en `/tmp` compartido.

## 5. Reglas del juego que no se discuten (detalle en `docs/specs/DECISIONES_DISENO.md`)

- **Todo en 3D, nada de 2D (mandato del usuario, 2026-11-14).** Hoy el juego es un **híbrido sin terminar**: lo que se
  ve y la física del jugador son 3D, pero la lógica (vecinos, rutas, sentidos, la tecla E, combate) sigue en un mapa 2D
  en píxeles. Plan y reglas de honestidad en `docs/specs/PLAN_TODO_3D.md`; el avance se mide con
  `bash tools/contar_2d.sh` (2.495 el 2026-11-14; terminado = 0). **Prohibido** decir «migrado» o «terminado» sin ese
  número, y prohibido añadir nada nuevo en 2D o en píxeles. Cómo funciona el híbrido actual: `docs/specs/MUNDO_3D.md`.
- **Solo 1.ª persona (decisión del usuario, 2026-11-14).** La vista desde arriba ([P]) no se desarrolla más: solo
  servía para buscar fallos visuales. **Prohibido** diseñar, probar, arreglar o preguntar nada pensando en ella, y
  prohibido añadir casos especiales para ella (apuntar con el ratón sobre el mapa, rótulos al pasar el ratón…). Se
  puede dejar inactiva o borrar cuando se toque un archivo por otra razón; no se le dedica tiempo propio. Las fotos
  de comprobación se sacan en 1.ª persona.
- **Época definitiva:** tecnofeudal / medieval-balística (`docs/specs/REVISION_EPOCA.md`). Historia principal antigua
  descartada; la nueva se diseña con el usuario. **Nunca inventar lore de la secta.**
- **Foco:** primero fallos visibles y estabilidad; el Caso I jugable después; todo lo demás congelado.
- **Sin emojis en los textos del juego** (usuario, 2026-11-14): se quitan poco a poco, al reescribir cada sistema; no se
  añade ninguno nuevo.
- Texto y lore son provisionales (se pueden reescribir). Controles en `docs/CONTROLES.md` (mírala antes de asignar teclas).
- Mapa editable en `mapa/Mundo3D.tscn` (`docs/specs/REGISTRO_EDITOR_3D.md` antes de tocarlo; guía para el usuario en
  `docs/EDITOR_MAPA_GUIA.md` y `docs/PINCEL_MAPA_GUIA.md`).
- Ideas nuevas del usuario: a `docs/VISION_Y_FUTURO.md`; no borrar ninguna sin que lo pida. Antes de proponer un sistema
  nuevo, plan corto y aprobación; sin refactors grandes ni cambios visibles sin avisar.

## 6. Git

- Rama de trabajo: `main` (ramas aparte solo para cambios grandes, con permiso; se mezclan al acabar con pruebas en verde).
- Nunca `*.import` ni `*.uid` en `.gitignore` (rompen `uid://` en el otro ordenador). `.claude/settings.json` se comparte;
  `settings.local.json` no.
- Respaldo de la reorganización del 2026-11-11: rama `backup-antes-reorg`.
