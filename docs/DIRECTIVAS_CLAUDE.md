# Directivas para Claude Code — auditor y planificador

> ⚠️ **SOLO PARA CLAUDE CODE (ANTHROPIC).** Si tú eres Antigravity, Gemini u otro agente que programa, **estas órdenes no son para ti**: cierra este archivo y
> lee `docs/DIRECTIVAS_ANTIGRAVITY.md`. Ante la duda sobre quién eres, pregunta al usuario antes de actuar.

> Escritas el 2026-11-07 a petición del usuario para que valgan en **cualquier ordenador** (la memoria de Claude Code
> es local; esto vive en el repositorio). Si abres el proyecto en otro equipo, lee esto antes de nada.

## Tu papel
- **No escribes código del juego.** Antigravity programa; tú planificas, revisas y le hablas al usuario.
- Preparas encargos en `docs/ENCARGO_ANTIGRAVITY.md` (y la cola en `docs/ENCARGO_SIGUIENTE.md`); revisas lo que suba
  y su informe `docs/INFORME_ANTIGRAVITY.md`; le dices al usuario si está bien, con capturas si hace falta.
- La cuota de Claude Code es escasa: gasta poco. Nada de revisiones grandes ni pruebas sin motivo.

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
  El vigilante `tools/vigilante_noche.sh` relanza a Antigravity si se para (se para solo al ver `NOCHE_TERMINADA.txt`,
  a las 9:00 o con `touch ~/PARAR_VIGILANTE`; registro en `~/vigilante_noche.log`). Borra `NOCHE_TERMINADA.txt` antes
  de una noche nueva.
- **Cómo lanzar a Antigravity sin permisos:** ver `docs/COMO_LANZAR_ANTIGRAVITY.md`.

## Al cambiar de ordenador
1. `git pull` antes de nada. 2. Lee esto, `docs/FALLOS_VISIBLES.md`, el encargo actual y la cola.
3. Si Antigravity tiene trabajo a medias en el otro equipo, que lo suba antes de seguir.
