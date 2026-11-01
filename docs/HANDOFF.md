# HANDOFF — Traspaso del proyecto "La Placa de Petri" (Godot 4.7.2)

> Documento para el siguiente agente de IA (o persona) que continúe el proyecto. **Léelo entero antes de tocar nada.**
> Última actualización: tras el commit `d07afa3` + bloque de traspaso. Plan detallado en `docs/PLAN_VIDA_SOCIAL.md`.

---

## 0. PROMPT LISTO PARA PEGAR AL SIGUIENTE AGENTE

```
Eres el asistente técnico principal del proyecto "La Placa de Petri": un Immersive Sim / sandbox 2D top-down en pixel art hecho en Godot 4.7.2 (GDScript). La carpeta es /home/lamsaktp/Proyecto-Inmersive-Sim. Yo NO sé programar y mi PC es antigua. Háblame siempre en español.

ANTES DE HACER NADA:
1. Lee completo docs/HANDOFF.md y docs/PLAN_VIDA_SOCIAL.md.
2. Ejecuta `git log --oneline | head` y `git status`. Último commit esperado: "B0.1: add NPCNames data..." (97126d6), repositorio limpio.
3. Ejecuta los tests de tools/tests/ con los comandos de HANDOFF.md (sección 3) y confirma que pasan ANTES de tocar nada. Si algo falla, avísame primero.

TU PAPEL: NO eres un asistente complaciente. Eres mi guía técnico y debes protegerme de malas decisiones.
- No me des la razón por defecto. Evalúa cada idea con honestidad y dime claramente si es poco realista, exagerada, arriesgada o prematura. Puedo pedir cosas desproporcionadas porque no sé programar.
- Clasifica lo que te pida: AHORA (viable y útil), ANTES (requiere un requisito previo que debemos hacer primero), DESPUÉS (buena idea pero prematura) o NO (no lo recomiendo, con el motivo). Estima esfuerzo (pequeño / medio / grande) y riesgo.
- Si insisto en algo que consideras mala idea, mantén tu criterio y explícame el porqué. Cambia de opinión solo ante argumentos nuevos, no porque yo insista.
- Si lo que pido contradice decisiones ya tomadas (sección 8 de HANDOFF.md) o rompería algo, dímelo antes de hacerlo.
- Propón siempre el alcance mínimo que funcione y deja lo demás para después. Nunca prometas lo que no puedes verificar. Distingue lo que probaste ejecutando tests de lo que solo supones.
- Señala riesgos, deuda técnica y problemas de rendimiento aunque no te los pregunte.

PLAN ANTES DE IMPLEMENTAR (obligatorio):
- Antes de implementar cualquier mecánica o sistema nuevo, preséntame un plan corto: qué se hará, por qué, en qué bloques pequeños, riesgos, cómo se probará y qué veré yo en el juego. Espera mi aprobación antes de escribir código.
- Excepción: arreglar errores pequeños o ejecutar el siguiente bloque ya aprobado en HANDOFF.md.
- Si te digo "no escribas código", no lo escribas hasta que lo apruebe.

AHORRO DE TOKENS (comunicación y código):
- Conmigo: respuestas cortas y directas, con listas. Sin repetir lo que ya sé, sin resúmenes largos ni florituras. Si basta una frase, usa una frase.
- Código: cambios mínimos y localizados (parches), nunca reescribir archivos enteros sin necesidad. No leas archivos grandes completos: busca con grep y lee solo los rangos necesarios. No repitas salidas largas de comandos: resume lo importante.
- Ejecuta tests solo cuando toque (al cerrar un bloque o ante una duda real), de uno en uno y con `timeout`.
- Reutiliza lo que ya existe (tablas de datos, tests, helpers) en lugar de crear cosas nuevas.

FORMA DE TRABAJO:
- Avanza en BLOQUES PEQUEÑOS (una idea verificable cada uno). Tras cada bloque: prueba, commit y un resumen de 3 líneas (hecho / verificado / pendiente).
- Nada de refactors grandes sin pedírmelo. No cambies comportamiento visible sin avisarme.
- Cuando necesites datos que solo veo yo (por ejemplo avisos del panel de errores de Godot), pídeme captura con archivo y línea.
- Al terminar cada sesión, marca los bloques hechos en la sección 7 de docs/HANDOFF.md y haz commit.

TAREA ACTUAL: sistema de VIDA SOCIAL procedural de los aldeanos (parejas que surgen de forma natural, conversaciones, peleas discretas sin muerte, y mi papel de observador/instigador/mediador), según las decisiones de la sección 8 de HANDOFF.md. No me preguntes de nuevo lo ya decidido. El bloque B0.1 (nombres) está hecho. Continúa por el siguiente bloque sin marcar: B0.2 (ficha de persona con id único, género, edad numérica, personalidad de 3 rasgos, gustos y estado sentimental, y su tabla para los 17 vecinos actuales). Antes de implementar, dame el plan corto de ese bloque y, si me parece bien, procede.
```

---

## 1. Qué es el proyecto

- Immersive sim 2D en pixel art ("La Placa de Petri"): un forastero llega a un valle con ~17 aldeanos con rutina propia.
- Sistemas ya hechos: combate, sigilo, supervivencia, **medicina anatómica estilo RimWorld**, economía y tiendas, justicia
  (cadáveres, testigos, detective, interrogatorio con rueda de diálogo, juicio público), **relaciones entre vecinos**,
  **glosario social `[J]`**, **habilidades RPG `[K]`**, reacciones a vecinos inconscientes.
- El texto del juego y el lore son **provisionales** (el usuario lo confirmó): se puede reescribir libremente.

## 2. Reglas de trabajo con el usuario (importante)

- Idioma: **español**. Conciso. Explica el "qué" y el "por qué" sin jerga.
- El usuario **no programa**; prefiere que decidas lo técnico y le preguntes lo de diseño con opciones claras.
- Le preocupan los **tokens**: bloques pequeños, bien documentados, siempre dejando el repositorio en estado limpio y commiteado.
- Le gusta: planificar antes, probar jugando y reportar lo que ve. Su PC es **antigua**: cuida el rendimiento.
- Preferencias de diseño ya decididas: ver sección 8.

## 3. Entorno y cómo probar

- Motor: **Godot 4.7.2** vía Flatpak. No hay editor abierto para ti; todo se verifica en modo headless.
- Desde la raíz del proyecto:

```bash
# Test completo (debe imprimir "...TESTS PASSED!" y salir con código 0). Tarda ~15 s.
timeout 80 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd > /tmp/t.log 2>&1; grep -c 'TESTS PASSED' /tmp/t.log

# Test de nombres (rápido, ~2 s; debe imprimir "NAMES CHECK PASSED"):
timeout 60 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/names_check.gd 2>&1 | tail -3

# Cobertura de diálogos: ejecuta todas las acciones de diálogo de todos los NPC. Debe dar 0 "SCRIPT ERROR".
timeout 80 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/dialogue_coverage.gd > /tmp/c.log 2>&1; grep 'COVERAGE DONE' /tmp/c.log; grep -c 'SCRIPT ERROR' /tmp/c.log
```

- **Un fallo intermitente conocido** en `verify_all.gd` (sección "reporte de cadáveres", "witness must transition to Phase 2"):
  salía a veces porque un guardia en patrulla pasaba cerca de la testigo. Se mitigó apartando a otros NPC en el test.
  Si vuelve a salir, repite 2–3 veces antes de investigar; si falla de forma consistente, es real.
- **Lanza los tests de uno en uno** (no en paralelo) y **no uses `pkill -f` con un patrón que aparezca en tu propio comando** (te mata a ti mismo).
- Las pruebas de comportamiento largas conviene ejecutarlas en segundo plano con `timeout`.
- Los avisos amarillos de Godot (panel de errores) solo los ve el usuario en el editor. Pídele captura con **archivo y línea**.

## 4. Convenciones de código y trampas aprendidas

- Indentación con **tabs**. Los archivos `.gd` se guardan con saltos de línea mixtos según `.gitattributes (* text=auto)`.
  Si editas con Python, abre con `newline=''` y conserva el salto de línea que ya tenga el archivo.
- **`class_name` nuevo + caché**: un `class_name` recién creado no se registra hasta que el editor reindexa; en tests headless da
  "Identifier not declared". Solución usada: **`const X = preload("res://...")`** en vez de `class_name` para scripts nuevos
  (ejemplos: `SkillCatalog`, `NPCData`, `NPCDialogue`).
- **`obj.get("metodo")` no llama a métodos.** Para métodos usa `obj.call("metodo")`. Para propiedades `obj.get("propiedad")` está bien.
  Ejemplo de error real: `dm.get("is_active")` (es un método) → usar `dm.call("is_active")`.
- Los autoloads (`WorldClock`, `GameManager`) **no existen** en `--check-only`; no uses `--check-only` para validar scripts que los usen.
  Valida ejecutando los tests.
- En scripts de test `extends SceneTree`: asigna `current_scene = main_inst` justo antes de usar código que busca `UI/UIRoot` desde la escena actual.
- Los Nodos NPC se identifican hoy por `npc_name` (ver riesgo en sección 6).
- `VillageNPC.gd` (~4.150 líneas) sigue siendo grande. Intentos de partirlo más: ver nota en sección 6.

## 5. Mapa del código (lo imprescindible)

| Archivo | Rol |
|---|---|
| `scripts/enemies/VillageNPC.gd` | **Aldeano**: estado, necesidades, rutinas, reportes de cadáver, reacciones a inconscientes, relaciones entre vecinos |
| `scripts/enemies/NPCDialogue.gd` | Menús y acciones de diálogo (funciones `static` que reciben `npc`); `VillageNPC` mantiene envoltorios con los mismos nombres |
| `scripts/data/NPCData.gd` | Tablas de datos: alias, perfiles de lore, relaciones iniciales entre vecinos |
| `scripts/systems/VillageManager.gd` | Mundo del pueblo (6.200 líneas): tiendas, puertas, justicia, llegadas de NPC nuevos (`_process_daily_map_edge_arrivals`), guardado |
| `scripts/systems/SkillCatalog.gd` | Catálogo de habilidades (datos) |
| `scripts/Player.gd` | Jugador; habilidades (`add_skill_xp`, `get_skill_level`, `get_skill_bonus`), guardado |
| `scripts/ui/SocialGlossaryUI.gd` | Glosario social `[J]` (nodos reutilizados, relleno repartido en frames) |
| `scripts/ui/SkillsPanelUI.gd` | Panel de habilidades `[K]` |
| `scenes/ui_root.gd` | Registra paneles y teclas (I, H, M, J, K, Tab, Esc) |
| `scenes/dialogue_manager.gd` | Rueda de diálogo |
| `tools/tests/` | `verify_all.gd`, `dialogue_coverage.gd` |

Otros documentos antiguos en la raíz: `ROADMAP_PROYECTO.md`, `AUDIT_LOG.md`, `SESSION_CONTEXT_LOG.md` (contexto histórico).

## 6. Hallazgos y riesgos relevantes para la vida social

1. **Los vecinos nuevos se crean en 5 sitios distintos** de `VillageManager.gd`: reemplazo de autoridades (`_spawn_authority_replacement`),
   posadera nueva, artesano nuevo, viajeros (`_process_daily_map_edge_arrivals`) y `spawn_dynamic_npc_from_save`. No hay un paso común.
2. **Las listas de nombres son de 5 elementos y rotan con `_rehire_counter`** → se repetirán. Las relaciones están indexadas **por nombre**
   (`npc_relationships`, `npc_relationship_notes` en `VillageNPC.gd`), así que nombres repetidos mezclarían relaciones y un recién llegado
   podría heredar las de un muerto. **Prioridad máxima del Bloque 0.**
3. Los **rasgos** (`traits`) hoy salen del **oficio** (`ROLE_PSYCHOLOGY`) o de un pool de 7; no son por persona.
4. Los sprites, retratos y animaciones de los 20 NPCs (`assests/world/village/npcs_64/` y `villager_*.png`), así como todos los suelos, muros, puertas, ventanas, camas, cofres, pozos y mobiliario (`assests/world/village/`), utilizan exclusivamente los assets comprados del usuario en `assests/Comprados/Epic RPG World - The Village V2.1` y `Epic RPG World - Village(interiors) V1.3` (no generar texturas procedurales propias).
5. Reparto actual: **6 mujeres / 11 hombres** entre los 17 vecinos residentes (visitantes aparte). Solo heterosexuales por ahora.
6. Partir `VillageNPC.gd` más allá de lo hecho es arriesgado (funciones muy entrelazadas con decenas de variables). El usuario aceptó parar ahí.
   Si hace falta, extraer módulos nuevos **como clases aparte con `npc` tipado** (técnica usada en `NPCDialogue.gd`) y comprobar con `dialogue_coverage.gd`.
7. Aviso: `get_nodes_in_group("village_npcs")` se llama en ~50 sitios. Con ~17 NPC es aceptable; cuida el rendimiento al añadir sistemas.

## 7. Estado y siguiente bloque

**Estado del código:** limpio, todo commiteado, tests pasando (`verify_all.gd`, `dialogue_coverage.gd`).

### Bloques del sistema de Vida Social (marca [x] al terminar y commitea)

**Fase 0 — Cimientos**
- [x] **B0.1** HECHO. `scripts/data/NPCNames.gd`: 200 nombres femeninos, 200 masculinos y 200 apellidos (variedad latina/europea/americana). API: `pick_first_name(gender, rng, used_names)`, `pick_surname(rng)`, `make_person_name(gender, rng, used_names)`; género `"F"`/`"M"`; reproducible con semilla. Test: `tools/tests/names_check.gd`. Aún NO está conectado al juego (eso es B0.3).
- [x] **B0.2** HECHO. `scripts/data/PersonProfile.gd` (`person_id`, `gender`, `orientation`, `age`, `personality` de 3 rasgos, `likes`/`dislikes`, `favorite_item`, `romance_status`, `partner_id`) y tabla `INITIAL_PERSON_PROFILES` en `scripts/data/NPCData.gd` para los 17 vecinos (6 F / 11 M) + 3 visitantes. Conectado en `VillageNPC._init_person_profile()`. Lore de Lina y Tomás ajustado a hermanos de hogar/taller.
- [x] **B0.3** HECHO. Generador `PersonProfile.generate_newcomer(...)` (nombre y `person_id` únicos, género equilibrado según vivos, edad y gustos por oficio, 3 rasgos sin opuestos, reproducible con semilla) y unificación de los 5 puntos de creación de vecinos nuevos en `VillageManager._spawn_generated_newcomer(...)`.
- [x] **B0.4** HECHO. Relaciones (`npc_relationships` y `npc_relationship_notes`) migradas a claves únicas (`person_id`), migración automática de claves antiguas por nombre (`_migrate_legacy_relationship_keys`), limpieza al morir (`purge_deceased_relationship`) y bloqueo de fallecidos en `ensure_npc_relationships_initialized`.
- [x] **B0.5** HECHO. Guardado y carga de `person_profile`, `npc_id`, relaciones por `person_id` y registros del generador (`used_first_names`, `used_person_ids`, `newcomer_rng_state`), con fallback y migración automática para partidas antiguas.
- [x] **B0.6** HECHO. Registro de eventos sociales (`social_event_log` con tope `MAX_SOCIAL_EVENT_LOG = 80`, `record_social_event` y `get_recent_social_events`) en `VillageManager.gd`, conectado a llegadas, reconciliaciones y rupturas de amistad, y persistido en guardado/carga.
- [x] **B0.7** HECHO. Esqueleto de `scripts/systems/SocialDirector.gd` con tabla única `DIALS` (`max_concurrent_scenes = 3`), 4 medidas por par (`affinity`, `familiarity`, `spark`, `tension`), enfriamiento diario sin contacto, cálculo de compatibilidad y conexión con `VillageManager` y guardado/carga.
- [x] **B0.8** HECHO. Pareja inicial **Elena y el Dr. Valen** (`romance_status = "partnered"`, `partner_id` cruzado, relación `+78`, etapa `"couple"` en `SocialDirector`), paso automático a viudo/a (`"widowed"`) si muere la pareja y visualización en el Glosario Social `[J]`.
- [x] **B0.9** HECHO. Simulador headless de 60 días (`tools/tests/social_sim.gd`) y paso diario `SocialDirector.simulate_social_day(...)`, calibrado sobre 5 semillas + reemplazos procedurales cumpliendo todas las metas (1–3 parejas nuevas, 2–6 peleas con máx. 2 por par, 0 vecinos sin amigos y ~77% de relaciones entre −20 y +40).

**Fase 1 — Conversaciones con frases**
- [x] **B1.1** HECHO. Catálogo procedural `scripts/data/SocialDialogueData.gd` con 8 tipos de acciones sociales (`small_talk`, `shared_taste`, `compliment`, `vent`, `joke`, `friction`, `taste_clash`, `apology`), etiquetas naturales para los 16 gustos y generador de intercambios de 2 turnos (`build_exchange`) adaptado a rasgos y gustos. Verificado en `tools/tests/names_check.gd`.
- [x] **B1.2** HECHO. Selección y resolución de conversaciones en vivo (`resolve_live_conversation`) en `SocialDirector.gd`, actualizando las 4 métricas del par (`affinity`, `familiarity`, `spark`, `tension`), relación vecinal y memoria corta respetando `max_concurrent_scenes = 3`. Verificado en `tools/tests/names_check.gd`.
- [x] **B1.3** HECHO. Escena en vivo de 2 turnos en `VillageNPC.gd` (burbuja de apertura de A → respuesta diferida ~1.8 s de B con actualización de relación y nota) y test automático #21 en `tools/tests/verify_all.gd`.

**Fase 2 — Pasar tiempo juntos**
- [x] **B2.1** HECHO. Lógica de quedadas en `SocialDirector.gd` (sin física): `is_social_hour` (12h y 18-21h), `should_avoid`/`get_avoid_ids` (rivales: afinidad ≤ −25 o tensión ≥ 30), `get_hangout_score`, `pick_hangout_partner` (ponderado, solo amigos/chispa/coqueteo, libres y con cupo de 1 quedada/día), `pick_shared_hangout_spot` (spots `{id,pos,kind}` del mundo: taberna por la tarde, plaza/pozo de día, banco/fogata para parejas; penaliza distancia y descarta ocupados), `start_hangout`/`try_plan_hangout`, `mark_hangout_arrival` (viaje → juntos), caducidad por viaje (60 s), bono suave al completar (45 s juntos) y `pop_finished_hangouts()`. Máx. 2 quedadas simultáneas; cupo diario guardado en partida. Diales en `DIALS`. Verificado en `tools/tests/names_check.gd`.
- [x] **B2.2** HECHO. Ejecución física: `VillageManager._update_social_hangouts()` (cada 5–8 s en hora social elige a un vecino que esté socializando, sincroniza afinidades reales y pide `try_plan_hangout`; puntos: Taberna, Pozo de la Plaza, Plaza Central, Pozo de la Granja vía `get_hangout_spots()`), seguimiento de llegadas, cancelación si alguien se duerme/ataca/cambia de actividad, y al completar: `modify_npc_relationship`, pensamiento de humor +6, +20 social, burbuja "☕ Buen rato" y evento `hangout` en el registro social. En `VillageNPC.gd`: `assign_hangout`/`clear_hangout`/`get_person_key`, objetivo social = punto de encuentro (cada uno a un lado), no abandona la quedada por social lleno, descripción "🚶 Ha quedado con…" / "☕ Pasando el rato con…", y `_find_best_social_partner` ignora rivales (`should_avoid`) y a quien ya está en una quedada. Test #22 en `verify_all.gd`.

**Fase 3 — Parejas**
- [x] **B3.1** HECHO. Etapas en vivo en `SocialDirector.advance_live_romance_day()` (Interés 14 → Coqueteo 28 → Citas 44 → Pareja 60 de chispa + afinidad ≥ 24), solo si hubo contacto hoy/ayer, ambos solteros, distinta familia y compatibilidad ≥ 40; probabilidad diaria `live_stage_advance_chance` × compat/50, sin plazos. Cortejo que se apaga si la chispa < 8. Tope diario de chispa por par (`spark_daily_gain_cap = 10`) en charlas y quedadas. `VillageManager._advance_live_romances()` (al pasar el día): fichas cruzadas, relación ≥ 68, pensamientos, burbuja 💑 y eventos `couple` / `romance_*` / `romance_fizzle`. Glosario `[J]` muestra "💘 Coqueteo con X" y la etapa en cada fila. Tests en `names_check.gd` y #23 en `verify_all.gd`. (La simulación de 60 días aún usa su propio paso; se recalibra en B3.5.)
- [x] **B3.2** HECHO. Comportamiento por etapa en `SocialDialogueData.gd` (`ACTION_FLIRT` 💘 y `ACTION_AFFECTION` 💑), selección en `SocialDirector.resolve_live_conversation()` y mayor peso de quedadas para etapas románticas, preferencia de compañero romántico y descripciones (`💑 Pasando la tarde con…` / `💞 En una cita con…`) en `VillageNPC.gd`, y citas/tardes en pareja con evento `date` en `VillageManager.gd`. Verificado en `names_check.gd` y Test #24 en `verify_all.gd`.
- [ ] **B3.3** Celos, rupturas y reconciliación.
- [ ] **B3.4** Duelo y viudedad mejorados (humor bajo varios días, visitas a la tumba).
- [ ] **B3.5** Recalibrar `social_sim.gd` con el sistema en vivo.


**Fase 4** Peleas discretas por dados · **Fase 5** Rol del jugador (observador/instigador/mediador) · **Fase 6** Chismes, noticias y pulido.
Cada fase se dividirá en bloques pequeños cuando se llegue a ella (detalle en `docs/PLAN_VIDA_SOCIAL.md`).

## 8. Decisiones de diseño ya tomadas (no volver a preguntarlas)

- **Todo procedural**: el sistema debe funcionar con NPC que lleguen más tarde, no depender de nombres fijos.
- **Solo parejas** (sin bodas ni hijos por ahora). **Todos heterosexuales** por ahora; dejar el campo `orientación` previsto.
- Compatibilidad por: género, edad cercana, personalidad, gustos, relación previa, cercanía por rutina y un poco de azar ("chispa").
- Las parejas **surgen de forma natural, sin plazos ni fechas límite**; nadie "busca pareja". Puede que no surja ninguna en una partida.
- Nadie se empareja con alguien de su mismo hogar/familia. Duelo y viudedad cuando muere la pareja.
- Pareja inicial: **Elena y el Dr. Valen**; resto solteros.
- Edades **numéricas**. Nombres: **200 femeninos + 200 masculinos + apellidos**, estilo variado (latino, europeo, americano).
- **Peleas**: sin muerte; simuladas con dados por dentro (ponderados por oficio, edad, salud, personalidad); en pantalla algo **discreto**
  (dos vecinos frente a frente, movimientos sutiles, algún "💢"); guardias pueden intervenir; consecuencias: heridas leves y relación peor.
- Jugador: **observador, instigador y mediador** (apoyado en Carisma y Sigilo). Se implementa al final.
- **Calibración**: simulaciones automáticas de cientos de días. Metas de ejemplo para 60 días: 1–3 parejas nuevas; 2–6 peleas (ninguna pareja de
  vecinos pelea >2 veces); ningún vecino sin amigos; más de la mitad de las relaciones entre −20 y +40.
- Arquitectura: **Director Social central** (decide la escena), aldeanos solo ejecutan; relaciones con 4 medidas (afinidad, familiaridad, atracción, tensión),
  enfriamiento sin contacto, "narrador" que dosifica el drama, todos los ajustes en una única tabla de diales, aleatoriedad con semilla.

## 9. Cómo cerrar una sesión

1. Ejecuta los dos tests. 2. Actualiza la sección 7 (marca bloques). 3. `git add -A && git commit`. 4. Resume al usuario en pocas líneas: hecho, verificado, pendiente.
