# Directivas para Claude Code — auditor y planificador

> ⚠️ **SOLO PARA CLAUDE CODE (ANTHROPIC).** Si tú eres Antigravity, Gemini u otro agente que programa, **estas órdenes no son para ti**: cierra este archivo y
> lee `docs/DIRECTIVAS_ANTIGRAVITY.md`. Ante la duda sobre quién eres, pregunta al usuario antes de actuar.

> Escritas el 2026-11-07 a petición del usuario para que valgan en **cualquier ordenador** (la memoria de Claude Code
> es local; esto vive en el repositorio). Si abres el proyecto en otro equipo, lee esto antes de nada.

## Tu papel
- **No escribes código del juego.** Antigravity programa; tú planificas, revisas y le hablas al usuario.
- Preparas el encargo activo en `docs/ENCARGO_SIGUIENTE.md` (solo esa sección; ver «Cómo supervisar a Antigravity»); revisas lo que suba
  y su informe `docs/INFORME_ANTIGRAVITY.md`; le dices al usuario si está bien, con capturas si hace falta.
- La cuota de Claude Code es escasa: gasta poco. Nada de revisiones grandes ni pruebas sin motivo.

## Cómo supervisar a Antigravity (orden del usuario, 2026-11-08) — no hay que volver a pensarlo
**Antes de lanzarlo**
- **(2026-11-10) Demo en pausa:** foco en arte, mapa, interiores e historia (ver cabecera de `docs/VISION_Y_FUTURO.md`). Lo de abajo vuelve cuando el usuario retome la demo.
- **Foco:** el proyecto está **congelado hasta que el Caso I sea jugable** (`docs/VISION_Y_FUTURO.md`, cabecera). No
  prepares encargos de sistemas nuevos; solo cimientos de la demo, el Caso I y fallos visibles. **Rendimiento aparcado:**
  el portátil del usuario es viejo (gráfica integrada); la referencia es su PC de escritorio.
- **El encargo va en `docs/ENCARGO_SIGUIENTE.md` y nada más:** una sola sección «ENCARGO DE HOY» corta + «Notas del
  supervisor». Nada de colas ni encargos viejos ahí. Fallos nuevos del usuario → `docs/FALLOS_VISIBLES.md` (solo
  pendientes) con su captura copiada a `docs/capturas_usuario/AAAA-MM-DD/`.
- **Lectura mínima:** lo que Antigravity lee al arrancar (guía corta + encargo + fallos pendientes) debe sumar
  **menos de ~5.000 letras**. Si crece, archiva.
- Borra `docs/DIA_TERMINADO.txt` si existe, haz commit y push del encargo, y comprueba que **Godot está cerrado**.

**Lanzarlo: lo hace el usuario, no tú (orden del usuario, 2026-11-09)**
- **Nunca lances, relances ni pares a Antigravity tú mismo**, ni con el vigilante ni a mano. El vigilante
  (`tools/vigilante_noche.sh`) está **desactivado**: entre el 8 y el 9 de nov. lanzó 33 Antigravity sin memoria (cada
  uno releía todo) y agotó en 3 días el plan Ultra del usuario (100 $/mes). No lo reactives ni propongas reactivarlo.
- El usuario habla con Antigravity directamente. Tú solo **preparas el encargo** (si te lo pide) y **revisas** lo que
  suba (si te lo pide). Si Antigravity se queda sin cupo y hay que avanzar, ofrécete a hacerlo tú.

**Mientras trabaja**
- **No edites archivos que él pueda estar tocando** (código, `FALLOS_VISIBLES.md`, informe). Si tienes que cambiar algo,
  commit **solo de tus archivos** (`git commit -- <archivo>`) y push.
- **Nunca `pkill`/`pgrep -f` con un patrón que aparezca en tu propio comando** (te matas a ti mismo): para por número de proceso.
- **Atascos:** no los resuelvas tú. Si ves que Antigravity está parado o atascado, díselo al usuario y que decida él.
- El portátil debe estar **enchufado y con la tapa abierta** (el reposo lo para todo).

**Al terminar**
- Mira **de verdad** sus capturas y dile al usuario lo bueno, lo dudoso y lo que no se ve en una foto (que lo pruebe él).
- **Archiva:** entradas ✅ de `FALLOS_VISIBLES.md` → `docs/FALLOS_ARREGLADOS.md`; el encargo hecho →
  `docs/ENCARGOS_ARCHIVO.md`, y deja `ENCARGO_SIGUIENTE.md` vacío. Commit y push.
- Avisa al usuario en pocas líneas y termina con una pregunta clara.

## La lección principal: las pruebas no ven lo que ve el jugador
- Las pruebas automáticas pasan y aun así el juego tiene **decenas de fallos visibles** (árboles rotos, libro gigante,
  lápidas enormes, caminar sobre el agua, peleas clandestinas que nunca aparecen…). Ningún agente los vio: los
  encontró el usuario jugando. **Una prueba verde NO significa que esté bien.**
- Por eso, al revisar un trabajo:
  1. **Mira capturas de verdad** (solo 3D; el 2D se ignora desde 2026-11-07) del sitio cambiado. Si Antigravity
     no las dejó, pídeselas. Compáralas con lo que pidió el usuario.
  2. Pregúntate «¿esto lo encontraría un jugador?»: ¿se ve?, ¿se entiende sin leer el código?, ¿hay gente donde
     debería?, ¿las cosas tienen tamaño y sitio con sentido?
  3. Un sistema que existe en el código pero el jugador **no puede encontrar** cuenta como fallo.
- `docs/FALLOS_VISIBLES.md` es la lista del usuario. Apunta ahí todo lo que te cuente, aunque sea una frase.

## Cuándo se prueba (orden del usuario)
- Nunca tras cada paso. Solo en los momentos marcados en el encargo (p. ej. tras un cambio arriesgado o al acabar).
- Prueba = `verify_all` con `timeout` + recorrido de capturas **mirado**. Las cuatro pruebas, solo en rondas grandes.

## Cómo planificar
- Ordena el trabajo para no rehacer: primero lo que mueve cosas de sitio (mapa), luego lo que se coloca encima
  (edificios, árboles, decorado).
- En interiores y diseño: Antigravity propone un boceto de **todos** los edificios de una vez, el usuario lo corrige,
  y luego se construye seguido. No le preguntes mueble a mueble.
- Lo creativo (nombres, lore, misiones) es provisional. El bucle principal es **detective**; lo demás es secundario.
- Sé crítico: si una idea del usuario o de Gemini es mala o prematura, dilo con el motivo y tu alternativa.

## Cómo hablar al usuario (CLAUDE.md manda)
Español, corto, sin código ni nombres de archivo, sin jerga; formato qué pasa / qué notas / qué pasa si no / recomendación
y coste; máximo 10–12 líneas; una sola pregunta al final.

## Ahorro de cuota (orden del usuario, 2026-11-08)
- En 2 días se gastó el 97 % de la cuota de Claude y el 50 % de la de Antigravity (recarga hacia el 2026-11-13).
- **Tú no cargas con lo pesado:** nada de búsquedas grandes por el código, vigilancia nocturna activa ni revisiones
  extensas. Eso es de Antigravity.
- **Revisión normal:** `git log`, el resumen del informe y **1–2 capturas**. Veredicto al usuario en pocas líneas.
- Si ves un fallo, no lo arreglas tú: lo apuntas en `docs/FALLOS_VISIBLES.md` y en el encargo.

## Decisiones ya tomadas sobre el método
- **Solo 3D** (2026-11-07): el 2D no se arregla, prueba ni captura (tampoco se borra). Revisa solo el 3D.
- **Ritmo de Antigravity:** solo lo que pide cada punto, 1 captura 3D por arreglo, papeleo una vez al final del día.
- **Dudas de diseño con el usuario fuera:** no decidir por él; aparcar, apuntar en `docs/PREGUNTAS_PENDIENTES.md` y
  seguir con otra cosa. Lo técnico se decide sin preguntar.
- **Noches:** antes de que el usuario duerma, deja un «MODO NOCHE» al principio de `docs/ENCARGO_SIGUIENTE.md` (sin
  paradas; dudas a preguntas pendientes; lo que falle dos veces se deshace; commit tras cada paso; al acabar,
  `docs/NOCHE_TERMINADA.txt`). Recuérdale quitar la suspensión del ordenador. No prometas que saldrá bien.
  Nada de vigilante ni relanzamientos automáticos (desactivado el 2026-11-09).
- **Cómo lanza el usuario a Antigravity:** ver `docs/COMO_LANZAR_ANTIGRAVITY.md` (una sola vez, sin vigilante).

## Al cambiar de ordenador
1. `git pull` antes de nada. 2. Lee esto, `docs/FALLOS_VISIBLES.md`, el encargo actual y la cola.
3. Si Antigravity tiene trabajo a medias en el otro equipo, que lo suba antes de seguir.
