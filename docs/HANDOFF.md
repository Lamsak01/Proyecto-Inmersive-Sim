# HANDOFF — Traspaso del proyecto "La Placa de Petri" (Godot 4.7.2)

> Documento para el siguiente agente de IA (o persona) que continúe el proyecto. **Léelo entero antes de tocar nada.**
> Última actualización: 2026-11-02, tras cerrar B6.4 (vida social completa). Plan detallado en `docs/PLAN_VIDA_SOCIAL.md`.

---

## 0. PROMPT LISTO PARA PEGAR AL SIGUIENTE AGENTE

```
Eres el asistente técnico principal del proyecto "La Placa de Petri": un Immersive Sim / sandbox 2D top-down en pixel art hecho en Godot 4.7.2 (GDScript). La carpeta es /home/lamsaktp/Proyecto-Inmersive-Sim. Yo NO sé programar. Háblame siempre en español.

ANTES DE HACER NADA:
1. Lee completo docs/HANDOFF.md y docs/PLAN_VIDA_SOCIAL.md. Antes de proponer sistemas nuevos, lee docs/VISION_Y_FUTURO.md (visión a largo plazo, orden acordado y banco de ideas).
2. Ejecuta `git log --oneline | head` y `git status`. El repositorio debe estar limpio en `main`; si esto no coincide con git, manda git.
3. Si el trabajo anterior no terminó limpio, ejecuta los tests de tools/tests/ con los comandos de la sección 3 antes de tocar nada. Si algo falla, avísame primero.

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
- Mientras trabajes, pasa solo el test afectado. Pasa los cuatro una sola vez, al cerrar cada bloque, de uno en uno y con `timeout`.
- Usa un solo test por comportamiento nuevo.
- Nada de comprobaciones repetidas ni revisiones grandes sin avisarme antes.
- Dame resúmenes de 3 líneas por bloque.
- Reutiliza lo que ya existe (tablas de datos, tests, helpers) en lugar de crear cosas nuevas.

FORMA DE TRABAJO:
- Avanza en BLOQUES PEQUEÑOS (una idea verificable cada uno). Tras cada bloque: prueba, commit y un resumen de 3 líneas (hecho / verificado / pendiente).
- Nada de refactors grandes sin pedírmelo. No cambies comportamiento visible sin avisarme.
- Cuando necesites datos que solo veo yo (por ejemplo avisos del panel de errores de Godot), pídeme captura con archivo y línea.
- Al cerrar cada bloque, márcalo en la sección 7 de docs/HANDOFF.md, añade una entrada a CHANGELOG.md, haz commit y push a `main`.

TAREA ACTUAL: la vida social (Fases 0 a 6) y el refuerzo del código (R1 a R5) están terminados. No hay tarea aprobada: pregúntame qué quiero hacer antes de empezar.
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
- Le gusta: planificar antes, probar jugando y reportar lo que ve.
- Preferencias de diseño ya decididas: ver sección 8.

## 3. Entorno y cómo probar

- Motor: **Godot 4.7.2** vía Flatpak. No hay editor abierto para ti; todo se verifica en modo headless.
- Desde la raíz del proyecto:

```bash
# Test completo (debe imprimir "...TESTS PASSED!" y salir con código 0). Tarda ~15 s.
timeout 80 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd > /tmp/t.log 2>&1; grep -c 'TESTS PASSED' /tmp/t.log

# Test de nombres (rápido, ~2 s; debe imprimir "NAMES CHECK PASSED"):
timeout 60 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/names_check.gd 2>&1 | tail -3

# Simulador social de 60 días (debe imprimir "SOCIAL SIM CHECK PASSED"):
timeout 150 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/social_sim.gd 2>&1 | tail -3

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
- En `tools/tests/verify_all.gd`: NO uses `WorldClock` como identificador directo (usa `wc_speed = root.get_node_or_null("/root/WorldClock")`) ni `VillageNPC.ActivityState.*` (usa los enteros `0`=WORKING, `1`=EATING, `2`=SLEEPING, `3`=SOCIALIZING) para evitar recargas circulares de `VillageNPC.gd` en modo headless.
- En `tools/tests/names_check.gd`: la línea 111 comprueba el tamaño exacto de `SocialDialogueData.ALL_ACTIONS.size()` (actualmente `11`); actualízalo si añades nuevas acciones sociales.
- En `VillageManager.gd` y `CampSite.gd`: cualquier `TextureRect` de muro o suelo debe llevar `expand_mode = TextureRect.EXPAND_IGNORE_SIZE` para que las texturas de 128 px no sobresalgan de los tramos cortos.
- Los Nodos NPC se identifican por `get_person_key()` (`person_profile.person_id`).
- `VillageNPC.gd` (~4.150 líneas) sigue siendo grande. Intentos de partirlo más: ver nota en sección 6.

## 5. Mapa del código (lo imprescindible)

| Archivo | Rol |
|---|---|
| `scripts/enemies/VillageNPC.gd` | **Aldeano**: estado, necesidades, rutinas, reportes de cadáver, reacciones a inconscientes, relaciones entre vecinos |
| `scripts/enemies/NPCDialogue.gd` | Menús y acciones de diálogo (funciones `static` que reciben `npc`); `VillageNPC` mantiene envoltorios con los mismos nombres |
| `scripts/data/NPCData.gd` | Tablas de datos: alias, perfiles de lore, relaciones iniciales entre vecinos |
| `scripts/systems/VillageManager.gd` | Mundo del pueblo (4.700 líneas): tiendas, puertas, justicia, llegadas de NPC nuevos (`_process_daily_map_edge_arrivals`), guardado |
| `scripts/systems/VillageWorldBuilder.gd` | Construcción inicial del pueblo (caminos, edificios y mobiliario) |
| `scripts/systems/VillageSocialLife.gd` | Quedadas, peleas en vivo y chismes aplicados al mundo |
| `scripts/systems/VillageJustice.gd` | Investigaciones del Comisario y del Inquisidor, interrogatorios, veredictos y juicio público |
| `scripts/systems/SkillCatalog.gd` | Catálogo de habilidades (datos) |
| `scripts/Player.gd` | Jugador; habilidades (`add_skill_xp`, `get_skill_level`, `get_skill_bonus`), guardado |
| `scripts/ui/SocialGlossaryUI.gd` | Glosario social `[J]` (nodos reutilizados, relleno repartido en frames) |
| `scripts/ui/SkillsPanelUI.gd` | Panel de habilidades `[K]` |
| `scenes/ui_root.gd` | Registra paneles y teclas (I, H, M, J, K, Tab, Esc) |
| `scenes/dialogue_manager.gd` | Rueda de diálogo |
| `scripts/systems/SocialDirector.gd` | Director Social: diales, medidas por par, romance, quedadas, peleas e influencia del jugador |
| `tools/tests/` | `verify_all.gd`, `names_check.gd`, `social_sim.gd`, `dialogue_coverage.gd` |

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

**Estado del código:** vida social completa (Fases 0 a 6) y subida a `main`; los cuatro tests pasan. Refuerzo del código (R1–R5) terminado. M1 (móvil social en investigaciones), Q1 (panel de misiones) Q1–Q4 hechos (5 tipos de misión, con estructura lista para muchos más). T1, T3 y T4 (rasgos: catálogo, descubrimiento y efectos) hechos. **Siguiente:** que el usuario revise `docs/RASGOS_BORRADOR.md` (100 rasgos) antes de T2. Pendiente aparte: diseñar con el usuario los tipos de misión hasta 25 (`docs/MISIONES.md`). Historial en `CHANGELOG.md`.

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
- [x] **B3.3** HECHO. Celos (`ACTION_JEALOUSY` 💢💔 en `SocialDialogueData.gd` y `trigger_jealousy_if_any()` en `SocialDirector.gd` cuando alguien con pareja queda con un tercero compatible), rupturas (`stage` vuelve a `"none"`, `ex_couple = true`, ambos vuelven a `"single"` con evento `breakup`) y reconciliación de ex-parejas (`couple_reconciled`) en `SocialDirector.advance_live_romance_day()` y `VillageManager.gd`. Verificado en `names_check.gd` y Test #25 en `verify_all.gd`.
- [x] **B3.4** HECHO. Duelo y viudedad mejorados: `bereavement_days_left` (5 días) y `deceased_partner_name` en `PersonProfile.gd`, pensamiento diario de luto y fin de duelo (`bereavement_ended`) en `VillageManager._advance_live_romances()`, visitas al Cementerio Parroquial (`get_grave_pos_for_victim`, `is_visiting_grave`, `"🪦 Visitando la tumba de X"`, `"🕯️ «No te olvido, X...»"`) en `VillageNPC.gd`, y estado en Glosario `[J]`. Verificado en `names_check.gd` y Test #26 en `verify_all.gd`.
- [x] **B3.5** HECHO. Unificado `SocialDirector.simulate_social_day()` con `_add_spark_capped()` y `advance_live_romance_day()`, y recalibrado `tools/tests/social_sim.gd` (60 días en 5 semillas + reemplazos procedurales cumpliendo todas las metas).


**Fase 4 — Peleas discretas por dados**
- [x] **B4.1** HECHO. Resolución por dados en `SocialDirector.gd` (`compute_fight_power`, `can_pair_fight`, `try_resolve_live_fight` con poder ponderado por oficio, edad, salud y personalidad; tirada interna con ganador/perdedor, alivio de tensión, caída de relación y respeto a `drama_cooldown_days` y `max_fights_per_pair = 2`). Verificado en `names_check.gd`.
- [x] **B4.2** HECHO. Peleas en vivo: `VillageManager._update_live_fights()` busca cada 3,5–6 s pares con tensión ≥ `live_fight_tension_threshold` (28) a ≤ 72 px y lanza `try_resolve_live_fight` (una tirada por par y día). Escena de 3,5 s en `VillageNPC.gd` (temblor y "💢"), moratón con `HealthComponent.apply_minor_bruise()` (sin órganos, fracturas ni sangrado; suelo del 35 %), relación −14, pensamientos y hasta 3 testigos a ≤ 110 px, evento `fight`. Un guardia a ≤ 140 px los separa a los 1,6 s, sin herida. Test #27 en `verify_all.gd`. Peleas raras: enemistad con relación ≤ −30 (`rival_friction_max_rel`), 10 días distintos de roce al cruzarse (`live_fight_min_enmity_days`), 15 % diario (`live_fight_daily_chance`) y 12 días entre peleas del pueblo (`live_fight_cooldown_days`). Medido en el juego real sin pantalla, una partida de 60 días.

**Fase 5 — Tu papel** (reglas: un solo vecino influido por día, efectos pequeños; hablar mal no fabrica peleas, siguen haciendo falta los 10 días de roce)
- [x] **B5.1** HECHO. Observador: menú "🗣️ Preguntar qué opina de los vecinos" (`NPCDialogue._add_neighbor_opinions`, 6 vecinos con sentimiento más fuerte; el motivo solo con afinidad ≥ 35 o Carisma ≥ 2; con afinidad < 0 no cuenta nada) y escucha a escondidas (`VillageNPC._try_player_overhear`: en sigilo a ≤ 96 px, +12 px por nivel de Sigilo, +3 XP). Test #28 en `verify_all.gd`.
- [x] **B5.2** HECHO. Desde la opinión sobre un vecino: "👍 Hablar bien" / "👎 Hablar mal" (`NPCDialogue._player_gossip`, `SocialDirector.resolve_player_gossip`). Una sola influencia al día (`player_influence_day`, guardado). Probabilidad por Carisma y afinidad, −20 % si contradice lo que el vecino siente. Éxito: relación ±4–8 entre ambos, tensión ±3, evento `player_gossip`, +4 XP. Fallo: −6 afinidad con el oyente (−4 con el aludido si hablabas mal), +1 XP. Test #29 en `verify_all.gd`.
- [x] **B5.3** HECHO. Mediador: "🕊️ Pedirle que haga las paces" si la relación es ≤ −15 (gasta la influencia del día; `resolve_player_mediation`: relación +4–8, tensión −11, enemistad −4 días, evento `player_mediation`). "✋ Separar" al hablar con un vecino en plena pelea (`player_stop_live_fight`, sin heridas, +3 afinidad, +5 XP; la pelea espera mientras el diálogo está abierto). Test #30 en `verify_all.gd`; la espera con diálogo abierto no tiene test automático.
- [x] **B5.4** HECHO. Casamentero: "💘 Animarle a acercarse" si ambos están solteros y son compatibles (`can_matchmake`, `resolve_player_matchmaking`): gasta la influencia del día, suma chispa 6–10 con tope diario, relación +4–8 y evento `player_matchmaking`; no salta etapas. Solo se ofrece para los 6 vecinos que aparecen en el menú de opiniones. Test #31 en `verify_all.gd`.

**Fase 6 — Chismes y pulido** (regla: los chismes son información y no mueven relaciones entre vecinos)
- [x] **B6.1** HECHO. Eventos de `GOSSIP_EVENT_TYPES` con `known_by` en `social_event_log` (se guarda con la partida). Al acabar una conversación, 50 % de que se cuente la novedad más reciente que el otro ignora (`spread_gossip`, máximo 10 días de antigüedad). "🗞️ Preguntar si hay alguna novedad" en el diálogo. `player_slander`: al enterarse el aludido, −5 de afinidad con el jugador. Test #32 en `verify_all.gd`.
- [x] **B6.2** HECHO. "🗞️ NOTICIAS DEL PUEBLO" en el tablón de la plaza (`get_public_news`): hasta 4 novedades que conozcan al menos 3 vecinos, sin comentarios del jugador. Las muertes no se publican, para no estropear la investigación de crímenes.
- [x] **B6.3** HECHO, sin cambiar valores en este bloque. Dos partidas reales de 60 días, sin pantalla y sin jugador activo (semillas 101 y 202): 4 peleas, 3 parejas nuevas, 17 vivos, 0 aislados, 68–69 % de relaciones entre −20 y +40, noticias 30–35 días en cada partida. Sin errores. Solo 4–8 quedadas y 1–2 citas completadas por partida (causa y ajuste en B6.4).
- [x] **B6.4** HECHO. Quedadas: en 12 días medidos, 9 de 11 se cancelaban al irse a dormir a las 22h. Ahora duran 22 s (~1,5 h de juego), no se planifican después de las 20:15 y no hay en las 21h. Revisión del código de las Fases 4–6, 9 correcciones: "widowed" fuera de chismes (revelaba muertes), `refund_live_fight`, peleas limpias al cargar, enemistad que se reinicia y exige relación actual ≤ −30, guardia consciente, sin quedadas en plena pelea, testigos y guardia en `known_by`, sin peleas cargando un cadáver, y la influencia del jugador actualiza `pe["affinity"]`.
  Sin medir: la partida de 60 días tras estos cambios se detuvo en el día 16 a petición del usuario, así que el efecto en quedadas y parejas no está comprobado (más quedadas pueden subir las 3 parejas nuevas por partida). Corregido después (2026-11-02): una escolta o emergencia de uno de los luchadores corta la pelea al momento y no cuenta (test #44).
Cada fase se dividirá en bloques pequeños cuando se llegue a ella (detalle en `docs/PLAN_VIDA_SOCIAL.md`).

**Refuerzo del código** (aprobado; mover temas a archivos nuevos dejando llamadas finas, como `NPCDialogue.gd`, sin cambios visibles)
- [x] **R1** HECHO. Test #33 en `verify_all.gd`: ciclo real con `GameManager` de guardar en archivo, cambiar el mundo y cargar (día, medidas por par, Director, relaciones, ficha, salud, delito, oro, chismes y pelea en marcha). No encontró errores; el juego no cambió.
- [x] **R2** HECHO. 16 funciones de construcción (494 líneas) movidas a `scripts/systems/VillageWorldBuilder.gd` (`@tool`, estático, primer parámetro `vm`). Comprobado con una foto de los 2.203 objetos y datos del mundo antes y después: idéntica salvo identificadores internos.
- [x] **R3** HECHO. 13 funciones (308 líneas) de quedadas, peleas y chismes movidas a `scripts/systems/VillageSocialLife.gd`. `VillageManager.gd` conserva llamadas finas con los mismos nombres y el estado (`_live_fights`, temporizadores, constantes). `_advance_live_romances` sigue en `VillageManager.gd`.
- [x] **R4** HECHO. 24 funciones (unas 1.500 líneas) de investigación, interrogatorios, veredictos y juicio movidas a `scripts/systems/VillageJustice.gd`. `VillageManager.gd` conserva llamadas finas con los mismos nombres y el estado de los casos.
- [x] **R5** HECHO. `VillageManager.gd` bajó de 6.911 a unas 4.700 líneas, pero conserva 115 variables. `VillageNPC._physics_process` pasó de 211 a 25 líneas en 8 pasos con nombre (mismo orden, dentro del mismo archivo). Decisión: no partir más `VillageNPC.gd` salvo que un problema concreto lo justifique.

### Vida social conectada con misiones e investigaciones
- [x] **M1** HECHO. Móvil social en `VillageJustice.gd`: al abrir el caso, quien se peleó con la víctima o tiene una enemistad larga con ella (relación ≤ −30 y ≥10 días de roce) suma +10 de sospecha y una pista; las calumnias del jugador sobre la víctima que conocen ≥3 vecinos le dan móvil a él. En el interrogatorio, un testigo que conozca una pelea, enemistad, ruptura o calumnia con la víctima la cuenta (+8). Un solo móvil por sospechoso; nunca decide solo (la coartada sigue mandando). Test #34.
- [x] **M2** Sustituido por las misiones personales (bloques Q). El tablón no se toca.
- [x] **Q1** HECHO. Autoload `QuestManager` (`scripts/systems/QuestManager.gd`): misiones con categoría `side`/`main` y estado `active`/`completed`/`failed`, notas y `data` libre; se guarda en la partida (clave `quests`). Panel `scripts/ui/QuestLogUI.gd` con la tecla **L** (la J es el glosario), pestañas Secundarias y Principal. `ObjectiveManager` (objetivos antiguos) no se toca. Test #35.
- [x] **Q2** HECHO. `scripts/systems/VillageQuests.gd` (funciones estáticas con `vm`). Cada día (`VillageManager._on_day_passed`), un vecino con enemistad (relación ≤ −30 y ≥5 días de roce o alguna pelea) tiene un 12 % de pedir ayuda; máximo 3 ofertas+misiones de vecinos a la vez; la oferta caduca en 4 días; tras rechazar/cobrar/fallar el vecino espera 10 días. El tipo depende de su carácter: rencoroso → «Ensúciale el nombre» (relación ≤ −40; hablar mal del rival a 2 vecinos distintos), pacífico → «Haz las paces por mí» (mediar con el rival hasta que vea al otro en ≥ −15 o mejore 12). Ofertas y esperas viven en `QuestManager.offers`/`giver_cooldowns` (se guardan). ❗ = nodo `QuestMarker` sobre el vecino. Se acepta, abandona y cobra hablando con quien lo pidió (acciones `quest_*` en `NPCDialogue`). Falla si muere quien la pidió o el rival. Test #36.
- [x] **Q3** HECHO. Tipos 4 y 5 (test #37). «Encuentra a quien lo mató» (`justice`): al construir un caso (`VillageJustice._build_investigation_case_dict`) el vecino más cercano a la víctima (relación ≥ 40) tiene un 60 % de pedirlo, una sola vez por víctima; se resuelve en `VillageManager._mark_morgue_case_resolved`: veredicto contra un vecino → cobrar 40; contra el jugador o archivado → falla. «Averigua qué piensa de mí» (`opinion`): vecino soltero con chispa ≥ 14 hacia otro soltero sin cortejo avanzado; se cumple al abrir la opinión de ese vecino en el menú de opiniones (acción `quest_opinion_seen:<clave>`; el que pidió ayuda sale siempre en la lista); al volver eliges contar la verdad o mentir: una respuesta negativa resta 6 de chispa, nunca la suma. Tipo 3 «¿Quién va contando eso de mí?» (`rumor`, test #38): los vecinos Rencorosos o Chismosos, al acabar una charla sin chisme que contar, tienen un 10 % de hablar mal de su peor rival (relación ≤ −40) a quien tienen delante (evento `npc_slander`, el oyente baja 3 su relación con el rival). Cada evento de chisme guarda `heard_from` (quién se lo contó a cada uno). Si la calumnia llega al afectado por quien la oyó del autor, sabe quién fue (jugador: −5 afinidad; vecino: −6 relación); si llega de segunda mano, no lo sabe y con un 50 % pide la misión. Se pregunta «¿quién te contó…?» a quien lo sabe (`quest_rumor_ask:<id>`); el autor se pone nervioso. Al volver, se señala a alguien de la cadena (−15 de relación del afectado con él, +25 de oro, sea verdad o no) o se confiesa (−10 de afinidad, sin pago). `npc_slander` también cuenta como móvil en M1 y no sale en el tablón.
- [x] **Q4** HECHO. Medición con partidas reales sin jugador (semillas 101 y 202, 39 días; semilla 303, 25 días). Se vio que una oferta caducada se repetía al día siguiente (ahora el vecino espera 10 días) y que los vecinos nunca calumniaban (ahora: 25 % por charla, enemigo ≤ −30, intento independiente del chisme). Tras el ajuste (semilla 303): 7 ofertas en 25 días (5 de paz, 2 de calumnia), máximo 3 a la vez, 1 calumnia entre vecinos, 2 peleas, 76 % de relaciones entre −20 y +40. Además, reorganización para crecer hasta 25+ tipos: base `scripts/systems/quests/QuestType.gd`, un archivo por tipo en `quests/types/` (más `_PLANTILLA.gd`), catálogo `QuestRegistry.gd`; `VillageQuests.gd` solo tiene las reglas comunes. Guía y tabla de tipos en `docs/MISIONES.md`. Test #39 (catálogo).

- Refuerzo: test #43 de guardar en archivo y cargar misiones activas, ofertas (❗), esperas y rasgos descubiertos. No encontró errores.
- Limpieza de 14 avisos amarillos del editor (sin cambiar el juego): parámetros sin usar con `_`, variable `tr` del bucle renombrada a `t_name` (tapaba `tr()`), divisiones enteras explícitas en `SocialDirector.get_pair_entry` (mismo resultado), y `@warning_ignore` en 6 variables de `VillageManager` que Godot creía sin usar pero se usan desde `VillageWorldBuilder`/`VillageSocialLife` como `vm._x`. Ojo: los tests no muestran estos avisos; se comprueban en el editor.
- Revisión del código del día: un fallo real. Al contar de segunda mano una calumnia (`npc_slander`/`player_slander`), el texto flotante y el menú de novedades nombraban al autor. Ahora pasa por `VillageSocialLife.gossip_text(ev, oyente)` (envoltorio en `VillageManager`), que la anonimiza («Andan diciendo cosas feas de X.» / «de ti.»). Test #38 ampliado.

### Rasgos de personalidad (bloques T)
- [x] **T1** HECHO. `scripts/data/TraitCatalog.gd`: los 18 rasgos actuales con descripción y «tendencias» (malice, grudge, gossip, aggression, honesty, trust, diligence, generosity, sociability); la tendencia de un vecino es la suma de sus rasgos. Calumnias entre vecinos: probabilidad por charla = 0,15 × malicia (máx. 45 %; sin malicia, nunca). Sustituye a la regla fija «solo Rencoroso/Chismoso al 25 %». Test #40.
- [x] **T2** HECHO. `TraitCatalog.TRAITS`: 140 rasgos aprobados (118 en 51 ejes + 22 sueltos, 17 raros), cada uno con `axis`, `tone` (k/n/h), `rare`, `desc` y `tend`; 23 tendencias nuevas «dormidas» para sistemas futuros (fe, vicio, ley, fama...). `roll_balanced`: 6 rasgos, difíciles al azar (0–3, casi siempre 1–2) compensados con amables, máx. 1 raro (25 %). `PersonProfile`: sin `PERSONALITY_TRAITS`/`OPPOSITE_TRAITS`; `complete_personality()` en `from_dict` completa a 6 de forma determinista (fichas fijas de `NPCData` con 3 y partidas viejas; nunca quita los que tenía). Compatibilidad por ejes (`are_opposed`) con peso ×0,5 por haber el doble de rasgos. Nombres en femenino con `TraitCatalog.display/npc_display` (-o→-a, -or→-ora, -ón→-ona, -án→-ana). Arreglado: las investigaciones miraban `npc.traits` (rasgos viejos de oficio) en vez de la personalidad; ahora `person_profile.personality`. Simulador: 2–3 parejas y 5 peleas en 60 días (igual que antes). Test #45.
- [x] **T2b** HECHO. Lo que cuenta otro vecino ya no va a `known_traits`: queda en `VillageNPC.rumored_traits` (id → quien lo dijo; se guarda) y se muestra «Se dice: X (según Y)». `TraitDiscovery.would_lie_about`: miente quien tiene honestidad ≤ −0,5 o malicia ≥ 0,8 y relación ≤ −30 con el otro, en el 60 % de las parejas (fijo por pareja); el bulo es un rasgo difícil no raro que no tiene. Al descubrir un rasgo por tu cuenta se borra su rumor y los del mismo eje; al conocer todos, se borran los falsos. Test #46 (y #41 ajustado).
- [x] **T3** HECHO (antes que T2, que espera la revisión del usuario). `scripts/systems/TraitDiscovery.gd`; lo conocido vive en `VillageNPC.known_traits` (+ `trait_trust_tier`, `trait_first_impression_done`, `trait_lore_done`), guardado con la partida. Se revela: 1 rasgo por cada umbral de afinidad 20/40/60/80; 1 con «Conocer la historia personal» (acción `trait_lore`); 1 con Carisma ≥ 3 al hablar por primera vez; 1 al espiar en sigilo; el rasgo que explica la conducta al ver calumniar (malicia) o pelear (agresividad) a ≤170 px; y en el menú de opiniones, un vecino que confía en ti (afinidad ≥ 35 o Carisma ≥ 2) cuenta un rasgo del otro. Glosario, mapa y taberna muestran «Rasgo, ❓, ❓» (`get_known_traits_text`). Partidas guardadas antes de T3: todos los rasgos empiezan ocultos. Test #41.
- [x] **T4** HECHO. Tendencias conectadas: agresividad (+laboriosidad) → fuerza en peleas (`SocialDirector.compute_fight_power`); agresividad y rencor → tensión al cruzarse rivales (×0,5–1,6); confianza del oyente → éxito al hablarle bien/mal, mediar o emparejar (±0,08 por punto; el rencor resta al mediar); honestidad → le cuesta más darte coartada y puede rechazar sobornos (0,35 × honestidad); chismorreo → probabilidad de contar novedades (0,5 + 0,25 × chismorreo); malicia y agresividad (− honestidad) → rasgo sospechoso en investigaciones (Sanguinario, Avaricioso y Cruel siguen por nombre hasta T2); malicia → paz o calumnia en misiones (≤ −0,3 / ≥ 0,5); generosidad → pago de misiones (±25 %). Sociabilidad → tiempo entre charlas (`get_social_cooldown_mult`, ×0,6–1,5) y peso para proponer quedadas (`VillageSocialLife.pick_hangout_initiator`, 0,3–2); laboriosidad → rendimiento en el oficio (`get_diligence_mult`, ×0,75–1,15; el tope de eficiencia sube a 115 %). Simulador abstracto tras el cambio: 3 parejas y 5 peleas por 60 días en 5 semillas. Test #42.
- [x] **T5** HECHO (medición, tras T2/T2b/U1; sin U2–U3). Partida real semilla 303, 25 días: 9 ofertas (6 paz, 2 calumnia, 1 opinión), máx. 3 abiertas, **7 calumnias entre vecinos** (antes de T2: 1), 2 peleas (igual), parejas 1 → 2, 75 % de relaciones entre −20 y +40, 1,12 rasgos difíciles de media, 0 errores. Las calumnias suben porque con 6 rasgos la malicia suma más; el usuario pidió bajarlas a la mitad: `NPC_SLANDER_PER_MALICE` 0,15 → 0,075 y tope 0,45 → 0,25 (se esperan ~3–4 cada 25 días; sin medir en partida larga). Sonda temporal `tools/tests/t5_probe.gd` (sin subir).

### Relaciones de un solo sentido (bloques U)
- [x] **U1** HECHO. Sin cambio visible. `SocialDirector`: `spark_by` por pareja (id → chispa hacia el otro), `get_spark(de, a)`, `add_spark_one_way(de, a, n)`; `spark` sigue siendo la chispa mutua (= la menor) que usan las etapas; `_add_spark_capped` suma a los dos lados; si código antiguo escribe `spark` a mano se toma para los dos; partidas viejas lo crean al usarlo. `VillageNPC.modify_npc_relationship(..., one_way)` cambia solo un lado (sin avisos de reconciliación/ruptura). Test #47. Nota: el número de acciones de `dialogue_coverage` varía entre ejecuciones (484→474 sin tocar diálogos): es azar, no un fallo.
- [x] **U2** HECHO. Charlas en vivo: `SocialDirector.side_delta(yo, otro, d)` (lo bueno ×(1+0,15·sociabilidad); con manías `TraitCatalog.IRRITATES` ×0,5 −2 por manía; lo malo ×(1+0,3·manías)×rencor); `VillageNPC` aplica la parte común a los dos (con avisos de reconciliación/ruptura) y el resto por su lado. Chispa: `_apply_spark_bias` (Romántico +, Desapegado −, el Coqueto la despierta en otros) en charlas en vivo y en el simulador abstracto; emparejar (B5.4) solo ilusiona a quien escucha. De un solo lado: lo que el jugador cuenta, celos, enterarse de una calumnia, misión de rumor, sospecha de robo; los rescates dan +8 al rescatado y +3 al rescatador. Reciprocidad lenta diaria: aprecio −5 % de la diferencia (1–2 puntos, `VillageSocialLife.daily_reciprocity`), chispa +1 al día si se vieron en 3 días (`_spark_reciprocity`). El simulador abstracto aún usa aprecio compartido (U7). Test #48.
- [x] **U3** HECHO. Cortejo: ya exigía la chispa mutua (= la menor). Declaración no correspondida en `advance_live_romance_day`: solteros sin cortejo, vistos hace poco, uno con chispa ≥ 28 y el otro < 14 → 25 % al día (dial `rejection_daily_chance`) → resultado `rejections`; −15 de chispa al que se declara y 20 días sin repetir (`rejected_day`). `VillageSocialLife.on_rejection`: −5 de aprecio del que se declara, −2 del otro, pensamiento triste, evento `rejection` (se cuenta como chisme). `on_new_couple_jealousy`: quien tenía chispa ≥ 28 por alguien que se empareja aprecia −10 a la nueva pareja (evento `jealousy`). Misión de opinión: la oferta usa la chispa de quien pregunta y la respuesta la chispa real del otro («Le gustas, y mucho» / «un poco» / «solo como amigo/a»...); una respuesta sin chispa desilusiona solo a quien preguntó. Test #49 (y #37 ajustado).
- [x] **U4** HECHO. `VillageSocialLife.try_hangout_excuse`: si quien invita aprecia ≥ 35 y el invitado < 15 (sin cortejo ni pareja), 70 % de excusa («Hoy no me viene bien...»), se cancela la quedada y quien invitó se apena (−3 de ánimo, −1 de aprecio). `feeling_phrase(rel, otro)`: frases de un solo lado con género («es mi mejor amiga», «ni fu ni fa», «no lo soporto»). Test #50.
- [x] **U5** HECHO. `VillageNPC.known_feelings` (+ `feelings_all_known` para partidas de antes de U5, que lo siguen viendo todo); pareja y familia se ven siempre (`knows_feeling_toward`). Se descubre al elegir a alguien en «qué opina de los vecinos» (`quest_opinion_seen`). El menú habla en primera persona y, si ya sabes lo que siente el otro y la diferencia es ≥ 30, lo señala. Glosario: lo desconocido sale «❓ No sabes qué siente por él/ella» (y no cuenta para mejores amigos/enemigos); lo conocido añade «↩ lo que siente el otro». Pendiente menor: los sentimientos contados por terceros («según X») no están hechos. Test #51 (y #28 ajustado).
- [x] **U6** HECHO. `VillageSocialLife.daily_distance_cooling`: tras 7 días sin cruzarse, cada lado se acerca 1 punto al día a neutro sin pasar de ±10 (no parejas ni familia). La chispa ahora se enfría por cada lado sin igualarse (`SocialDirector._change_spark_both`, también en rupturas); antes el enfriamiento diario borraba los amores no correspondidos. Test #52.
- [x] **U7** HECHO. Tres partidas reales (semilla 303, 25 días, sin jugador). 1ª: 0/136 parejas con diferencia ≥ 30, 0 amores no correspondidos. Ajustes: «química» fija de cada uno hacia cada otro (`SocialDirector.chemistry`, ±35 % en lo bueno), sociabilidad ×2 en `side_delta` (0,4–1,8), reciprocidad solo desde 20 puntos de diferencia (`RECIPROCITY_MIN_GAP`), enfriamiento por distancia proporcional (3 %/día, `COOL_RATE`). 3ª: 2 parejas con diferencia ≥ 15 (máx. 43), 4 parejas con chispa (máx. diferencia de chispa 32), 4 calumnias, 0 peleas, parejas 1 → 2, 79 % de relaciones en la franja media, 0 errores. **Conclusión**: el sistema funciona (tests #47–#52), pero sin jugador, en 25 días y con 17 vecinos, muy pocas parejas tratan lo bastante como para separarse; las diferencias grandes saldrán sobre todo de lo que haga el jugador (cizaña, favores, emparejar) y de partidas más largas. La meta del plan (15–25 %) era optimista; no se fuerza más para no inventar dramas. Sonda: `tools/tests/t5_probe.gd` (sin subir). en `docs/PLAN_RELACIONES.md` (tensión compartida, reciprocidad lenta, sentimientos ocultos al principio).

### Crónica del pueblo (bloques C)
- [x] **C1–C4** Hecho (plan en `docs/PLAN_CRONICA.md`). `scripts/systems/VillageChronicle.gd` + `scripts/ui/ChronicleUI.gd`, tecla **O**
  (la C ya era sigilo). Guarda los 160 últimos sucesos en `VillageManager.chronicle` (se guarda con la partida; las viejas
  empiezan con el registro social). Cada línea lleva `known`: público, del jugador o visto a ≤170 px; lo secreto se revela con
  `learn_event` (al preguntar por novedades). `SHOW_ALL_DEBUG = true` mientras estamos en pruebas: se ve todo y lo secreto
  lleva 🔒; **ponerlo en false para la versión final**. También apunta muertes descubiertas, casos cerrados y misiones
  cumplidas o fallidas. Test #53. La sonda imprime una línea CHRONICLE.
- [x] **C5** (revisión tras probarla el usuario: en una semana no salía nada de los vecinos). Tope subido a **500**. Ahora
  también apunta quedadas (`hangout`), chismes (`on_gossip`, desde `spread_gossip`; si el jugador está cerca se entera del
  suceso) y cambios de escalón de amistad, de un solo sentido (`daily_friendship_scan`, una vez al día; escalones 65/35/−30/−60
  con margen de 5; guardado en `VillageManager.chronicle_tiers`; secreto salvo que el jugador conozca ese sentimiento).
  Pestañas nuevas Amistad y Chismes, nombres cortos para que quepan. Las charlas normales no se apuntan.
  Arreglo tras probarlo el usuario: el panel abría en la última pestaña usada y no se refrescaba estando abierto
  (parecía vacío). Ahora abre siempre en «Todo» y se repinta solo cada 0,5 s si hay líneas nuevas (`_signature`).
  Pulido: lo apuntado durante el cambio de día (`VillageManager.chronicle_daily`) va al día anterior como «Durante el día»
  en vez de «00:00»; el panel ocupa la pantalla con `top_level` para salir centrado (el `ui_root` es más pequeño que la
  pantalla; el diario de misiones tiene el mismo problema, sin tocar); «salió peor parada/Magullada» según el género.

### Recuerdos que se degradan (bloques R)
- [x] **R1–R4** Hecho (plan en `docs/PLAN_RECUERDOS.md`). `scripts/systems/GossipMemory.gd`: por chisme y vecino,
  fuerza del recuerdo (`ev["mem"]`, 100 protagonistas / 80 testigos / 70 al oírlo, −8 al día; protagonistas −1,5; tendencia
  `memory` despierta: Memorioso/Estudioso/Nostálgico más lento, Olvidadizo más rápido; contarlo +10). A 0 lo olvida
  (`ev["forgot"]`; sigue en `known_by` para no romper `heard_from`). `knows()` sustituye a `known_by.has()` en chismes,
  novedades y motivos que cuenta un testigo al investigador. Tope de edad `GOSSIP_MAX_AGE_DAYS` 10 → 20.
  Deformación al contar (`ev["ver"][clave]`: exagerar hasta 2 niveles o cambiar a una persona; se hereda de boca en boca;
  más si miente, lo recuerda mal o no es protagonista, tope 40 %). `gossip_text(ev, listener, ver_key)` dice la versión.
  Crónica: «❓ X te contó: …» con «[deformado]» en modo pruebas. Las versiones aún no cambian relaciones (va con Secretos).
  Test #54. La sonda imprime MEMORY.

### Secretos: infidelidad y chantaje (bloques S)
- [x] **S1–S6** Hecho (plan en `docs/PLAN_SECRETOS.md`). `scripts/systems/VillageSecrets.gd`, datos en
  `VillageManager.secrets` / `secret_uid` (se guardan). S1: cada día, alguien con pareja puede empezar una aventura si hay
  chispa en los dos sentidos (≥35 / ≥20), contacto reciente y no son familia; probabilidad `AFFAIR_DAILY` × tentación
  (Fiel 0, normal 0,25, Infiel 0,55); una a la vez y 30 días de descanso. Al quedar, el infiel elige al amante la mitad de
  las veces. S2: en cada encuentro, vecinos a ≤170 px (50 %) y el jugador los pillan; el testigo crea el chisme «affair»
  (los amantes no lo cuentan; al deformarse solo cambia el amante, `swap_only`). S3: quien lo oye −4 al infiel y −2 a quien
  cree amante (puede ser un inocente); la pareja −30/−20, tensión +40 y 70 % de ruptura. S4: un vecino malicioso que lo sabe
  chantajea (paga la mitad de su oro, hasta 30, o se niega y se lo cuenta a la pareja). S5: diálogo «🤫 Sé lo tuyo con…»
  (pedir oro / prometer callar) y «💔 Tengo algo que contarte» a la pareja; si el rumor que oíste señalaba a otra persona,
  lo niega. Test #55. La sonda imprime SECRETS.
  Medido antes de S: los chismes circulaban muy poco (25 días: 1 chisme contado).
- [x] **R5** Más ritmo de chismes (pedido por el usuario): `GOSSIP_EVENT_TYPES` suma citas, coqueteos, noviazgos, celos,
  llegadas, marchas y perdones de infidelidad; en cada charla también puede contar novedades quien contesta
  (`VillageNPC`, «¿Y sabes qué? …»). Exageraciones propias para lo romántico. Sonda (semilla 303, 25 días): 12 chismes, 61 personas los
  sabían, 38 veces contados, 10 olvidos, 6 versiones deformadas (antes: 3 / 8 / 1 / 0 / 0). Calumnias 3, peleas 2, parejas
  1 → 2, 0 aventuras (con solo 1–2 parejas es lo esperable: raro y orgánico). Sin errores.

### Deseos propios (bloques D)
- [x] **D1–D6** Hecho (plan y decisiones en `docs/PLAN_DESEOS.md`). `scripts/systems/VillageDesires.gd`; datos en
  `VillageManager.desires`, `desire_uid`, `desire_hate_since`, `npc_murders`, `last_npc_murder_day` (se guardan). Un deseo
  activo por vecino, pasos cada 2–4 días, 10 días de descanso entre deseos. D2 venganza (odio ≤ −50; 10 %/día × rencor):
  hablar mal → contar su aventura a la pareja → sabotear su puesto → buscar pelea (tensión +30) → satisfecho; se acaba si
  el odio baja de −30 o pasan 20 + 15×rencor días. D3 ambición (Ambicioso, Sediento de poder, Envidioso, Codicioso; 5 %/día;
  abierta): ahorrar, hablar mal del más rico, sabotearle. D4 contra el jugador (afinidad ≤ −50 durante 7 días; 20 %/día):
  ir diciendo que no eres de fiar (−2 de afinidad a quien lo oye), negarse a venderte (`filter_dialogue` quita compras),
  denunciarte (multa +15 si tienes antecedentes; +10 inventada si es mentiroso), contar tus secretos (chantajes; −3).
  D5 asesinato: desde una venganza de ≥10 días con odio ≤ −80, oscuridad (malicia+agresividad−honestidad) ≥ 1,5, 5 %/día,
  máximo uno al mes en el pueblo; 3–5 días de preparación con señales (35 %/día, quien está cerca se entera; el chisme
  `murder_threat` no lo cuenta el asesino; si llega a la víctima, 50 % de que se ponga en guardia). Solo actúa de noche si
  nadie despierto está cerca de la víctima (si no, otra noche). Nunca contra el comisario ni el inquisidor. El caso del
  comisario suma +30 de sospecha al asesino, sin coartada y con pista. Descubrir deseos: «💭 ¿Qué le ronda la cabeza?»
  (abiertos con afinidad ≥ 10, secretos ≥ 50; los de asesinato nunca, solo una pista con ≥ 60), por chismes
  (`desire_rumor`) o porque los abiertos los cuenta el propio vecino. Con lo que sabes: convencerle de que lo deje (afinidad
  ≥ 40, 50 %), avisar a la víctima o denunciar el plan al comisario o un guardia. Test #56. La sonda imprime DESIRES.
  Sonda (semilla 303, 25 días, sin jugador): 7 deseos (5 venganzas, 2 ambiciones; 3 cumplidos, 1 olvidado, 3 en curso),
  2 sabotajes, 0 asesinatos, calumnias 5 (antes 3), peleas 2, 17 vivos, 76 % de relaciones en la franja media. Sin errores.

### Grupos y fe (bloques G)
- [x] **G1–G7** Hecho (plan y decisiones en `docs/PLAN_GRUPOS_FE.md`). `scripts/systems/VillageFaith.gd`; datos en
  `VillageManager.faith_state` (se guarda: reputación por grupo `rep`, fe vista `seen`, contadores de Oficios) y
  `faith_bands` (se recalcula cada día). G1 **Fe del Alba** (provisional, parecida al cristianismo sin nombres reales):
  el Hacedor, el Libro del Alba, el círculo del sol naciente. Grado por la tendencia `faith` de los rasgos: ≥1 fervoroso,
  ≥0,4 creyente, ≤−0,5 escéptico, si no tibio. La capilla pasa a llamarse **Capilla del Alba** (antes «San Cipriano»).
  G2 `WorldClock`: `get_weekday`, `is_weekend` (sábado y domingo), `is_rite_day` (domingo); el reloj muestra el día de la
  semana. Fin de semana (`VillageNPC._is_mandatory_work_hours`): oficios y familias trabajan el sábado de 9 a 13 y
  descansan el domingo; tabernera, autoridades y sacerdote, igual que siempre; el fin de semana salen a socializar antes
  (umbral 90 en vez de 78). Oficio el domingo: a las 8, 9 y 10 `VillageFaith.call_to_rite` llama (fervorosos siempre,
  creyentes 85 %, tibios 30 %, escépticos nunca; fijo por semana) y `npc.join_rite(pos)` les hace caminar de verdad a los
  bancos (`rite_pos`, primero en `_get_social_target_pos`; no se van salvo hambre < 30 o energía ≤ 12). Comisario y guardia
  no van (de servicio). A las 11 `finish_rite`: cuentan los que están a ≤ 40 px; +2 entre asistentes (+3 si los dos
  creen), 6 intentos de chisme entre ellos, el fervoroso apunta −2 a cada creyente que faltó, y si estás a ≤ 150 px del
  altar los creyentes te dan +3 y ves su fe. Roces diarios (10 %): fervoroso y escéptico −2; dos creyentes +1.
  G3 sacerdote **Hermano Anselmo** (`TradeRole.PRIEST`, nodo `NPC_Priest_Anselmo`, cama y mesa en la capilla, sprite
  provisional `guia`); usa los huecos de autoridad, así que si muere llega un sustituto; `ensure_priest_faith` le da
  Devoto si no tiene fe. Sermón: si odia a alguien (≤ −40), los asistentes −3 hacia él. G4 bandos: familias (≥ 2 vivos),
  pandillas (≥ 3 que se aprecian ≥ 50 entre todos) y seguidores de un Líder (≥ 2). En `record_social_event` de pelea,
  calumnia o chantaje, cada miembro que aprecia al dañado (≥ 30) coge −4 al agresor (una vez por suceso; nada si el
  agresor es del mismo bando). En la charla, +15 % de contar chismes dentro del bando. G5 reputación: creyentes,
  escépticos y cada bando (cambios de afinidad ≥ 3 con un miembro cuentan ¼); se ve en el glosario (J). G6 diálogo:
  al sacerdote, «☀️ Preguntar por la Fe del Alba» → donar 10 de oro o burlarte (−12 con él, −4 con creyentes cerca, +2 con
  escépticos); a los demás, «¿Vas al Oficio?» (te lo dicen si te aprecian ≥ 0). Crónica: pestaña «☀️ Fe» (`rite`) y tipos
  `faith_mock`, `faith_donation`, `band_defend`. Test #57. La sonda imprime FAITH.
  Sonda (semilla 303, 25 días, sin jugador, 18 vecinos): 3 Oficios con 8 asistentes de media; bandos solo familias (6),
  ninguna pandilla ni seguidores; 2 defensas de bando; chismes 16 sucesos / 98 que los saben (antes 73), 22 olvidos,
  29 versiones deformadas (antes 6: vigilar); calumnias 7, peleas 1, 18 vivos, 78 % de relaciones en la franja media.

### Economía y necesidades ampliadas (bloques E)
- [x] **E1–E7** Hecho (plan y decisiones en `docs/PLAN_ECONOMIA_NECESIDADES.md`). Módulos `VillageNeeds.gd` (higiene,
  posición, vicios, limosna, diálogo), `VillageIllness.gd` (enfermedades) y `VillageCrime.gd` (robos); estado en
  `VillageManager.needs_state` (se guarda: `addict`, `drunk`, `ill`, `immune`, `thefts`, `smell_day`, `craving`, contadores).
  Vecino: `need_hygiene` (guardada), `sick_level`, y **encargos a pie** `start_errand(kind, pos)` / `end_errand()`
  (`errand_kind`: wash, drink, gamble, beg; van segundos después de `rite_pos` en `_get_social_target_pos`, no se
  interrumpen salvo hambre/cansancio/noche, caducan a las 3 h salvo pedir). `VillageNeeds.tick` (cada segundo real desde
  `VillageManager._process`) los termina al llegar; `on_hour` y `daily` desde los relojes del VM.
  E1 higiene: −1,4/h (×1,5 carnicero y herrero; Pulcro más lento, Desaliñado más rápido); a las 7, 8, 18, 19 y 20 h, si
  está libre y por debajo de 45 (+15 × tendencia), va al pozo más cercano o a casa. Por debajo de 20: −5 de humor y dos
  vecinos −1 («Huele mal»). Jugador: `SurvivalComponent.current_hygiene` (−0,04/s, guardada, barra 🧼 en el HUD); se lava
  en los pozos (`_use_water_well`) o al lavarse junto al agua (`wash_bloodstains`); por debajo de 25 cada vecino con el que
  hablas te baja 1 de afinidad una vez al día. E2: resfriado (3–5 días, contagio 10 %/h a ≤ 60 px, leve) y fiebre gris
  (6–10 días, 6 %/h, guarda cama `sick_level` 2, sin tratar desde el día 5 muere un 4 %/día). Inicio diario 0,6 % (+3 %
  si higiene < 30, +0,6 % con lluvia; miasma → fiebre). Tope 3 contagios/día, inmunidad 20 días. El médico trata 3 al día
  (graves primero; acorta a la mitad). Jugador: se contagia; enfermo, el aguante se queda en 65/40; la fiebre sin tratar
  le baja 12 de vida al día **sin matarle** (mínimo 5); el médico te cura por 8 de oro. E3: rico ≥ 160, acomodado ≥ 70,
  humilde ≥ 20, pobre, mendigo (campamento o parado con < 5). Los ricos comen en la taberna más (35 %); envidia pequeña;
  los mendigos piden en la plaza de 9 a 18 y los que pasan dan 1–2 de oro. E4: un robo por noche como mucho; ganas
  según pobreza, mono sin oro y Cleptómano, por (1 − 0,6 × honradez − 0,4 × ley); con honradez ≥ 1 nunca (salvo
  Cleptómano). Víctima: otro vecino (no de su familia ni bando), la caja de un puesto o tú (25 %); se lleva el 20 %
  (máx. 25). Testigo cercano o un 25 % de que alguien lo viera de lejos: si es honrado y no es de su bando, lo denuncia
  y el comisario le obliga a devolverlo con multa (`theft_caught`, público); si no, chisme `theft` (el ladrón calla).
  La víctima −40 hacia él (puede volverse venganza). Tú: denunciar al comisario o guardia lo que sepas, decirle al
  ladrón que lo sabes (callar, +8; o exigir tu oro). E5: a las 19 y 20 h van a beber (3 de oro a la tabernera) o a
  jugar (apuesta 8, gana el 45 %) según Bebedor/Tahúr/vicio y su enganche (+8 por vez, −3/día; enganchado ≥ 50);
  sin oro y enganchados: mono (−6 y más ganas de robar). Borrachos 3 h: el 50 % de las veces cuentan lo que callaban
  (`VillageSecrets.keeps_quiet`). E6: limosna (3) y regalar oro (10) a pobres; invitar a una ronda en la taberna (4):
  te cuenta novedades y un rasgo. Glosario (J): higiene, posición, vicios y enfermedad. Crónica: theft, theft_caught,
  illness, illness_death, player_alms. Test #58. La sonda imprime NEEDS. No hay adicción para el jugador.

### Instituciones y corrupción (bloques I)
- [x] **I1–I6** Hecho por mi cuenta (el usuario pidió terminar hasta el paso 7 sin él; decisiones mías en
  `docs/PLAN_INSTITUCIONES.md`). `scripts/systems/VillageTown.gd`; estado en `VillageManager.town_state` (se guarda:
  `mayor`, `mayor_name`, `next_election`, `treasury`, `pledges`, `banned`, `history`, contadores). I2 alcalde: elecciones
  el primer día y cada 28; candidatos los 3 elegibles (no autoridades, sacerdote, forasteros ni acampados) con más
  2×mando + ambición + oro/100; cada uno se vota a sí mismo; los demás votan por relación (+15 si es de su bando, +5×mando)
  o por la promesa que les pediste. I1 impuestos cada sábado (`get_weekday() == 5`): 5 % del oro por encima de 20 (ricos
  8 %) y 5 % de la caja de cada negocio; el alcalde cobra 5 y reparte 5 a cada pobre o mendigo mientras haya. Sueldos de
  autoridades: siguen saliendo de la Corona. I3 `corruptibility` (Íntegro 0; Sobornable +0,3; honradez, ley, ambición,
  generosidad); corrupto ≥ 0,5. Alcalde corrupto: se queda 30–60 % de cada cobro; 25 % de que alguien lo note (chisme
  `embezzle`, el alcalde calla); con 5 que lo sepan o si lo denuncias al comisario (no corrupto), `expose`: devuelve lo del
  mandato, todos −10 hacia él y elecciones anticipadas sin él (`banned`). Comisario corrupto: el ladrón denunciado le paga
  hasta 15 y se libra (`police_bribe`, estado del robo `bribed`; el testigo −10 al comisario). I5: sobornar al comisario o
  guardia (máx(20, 1,5 × multa); si no es corrupto, multa +10), pedir el voto (afinidad ≥ 30, o 10 de oro a un corrupto),
  denunciar al alcalde. Fama `law` (denunciar +, sobornar −). I4 nobles aplazado al paso 9. Glosario (J): línea del pueblo.
  Crónica: election, taxes, embezzle, embezzle_exposed, police_bribe, player_bribe. Test #59. La sonda imprime TOWN.

### Interfaz
- [x] **HUD1** Barras de estado (`scenes/ui_root.gd`, `_create_stats_box` / `_create_fallback_bar`): recuadro oscuro arriba a
  la izquierda, barras finas con relleno de color y texto blanco (antes `modulate` teñía también el texto). Se ven
  Resistencia, ⚡ Aguante, Hambre y Sueño. Sangre (BLD) y aturdimiento (STN) ocultas por petición del usuario (siguen
  existiendo y actualizándose por dentro).

## 8. Decisiones de diseño ya tomadas (no volver a preguntarlas)

- **Tamaño y niveles**: empezar pequeño, objetivo final una ciudad de 100+ vecinos. Habrá sótanos (mapa aparte debajo del principal) y varios pisos con un sistema de capas tipo Project Zomboid, el mismo para sótanos y pisos (`docs/VISION_Y_FUTURO.md` §6; construir más adelante). Los sistemas nuevos que usen distancias (testigos, oír, ver) deben pasar por una función común para poder añadir «mismo nivel» después.
- **Visión a largo plazo**: pueblo realista con lo bueno y lo malo, profundidad tipo Dwarf Fortress / RimWorld / Song of Syx, construida con 6 piezas comunes y en el orden de `docs/VISION_Y_FUTURO.md` (siguiente tras T2: relaciones de un solo sentido). Las ideas nuevas del usuario se añaden a ese documento.
- **Rasgos**: unos 140 (más de 100; la cifra era orientativa), nombres según el género, oscuros pero raros, un vecino malicioso o Mentiroso puede contarte rasgos falsos («según X»), con ejes de opuestos (no puede ser Trabajador y Holgazán a la vez), unos 6 por vecino, ocultos al principio y descubiertos al interactuar. Los recién llegados tras una muerte se generan solos con el catálogo; las partidas guardadas conservan sus rasgos y se completan.
- **Todo procedural**: el sistema debe funcionar con NPC que lleguen más tarde, no depender de nombres fijos.
- **Solo parejas** (sin bodas ni hijos por ahora). **Todos heterosexuales** por ahora; dejar el campo `orientación` previsto.
- Compatibilidad por: género, edad cercana, personalidad, gustos, relación previa, cercanía por rutina y un poco de azar ("chispa").
- Las parejas **surgen de forma natural, sin plazos ni fechas límite**; nadie "busca pareja". Puede que no surja ninguna en una partida.
- Nadie se empareja con alguien de su mismo hogar/familia. Duelo y viudedad cuando muere la pareja.
- Pareja inicial: **Elena y el Dr. Valen**; resto solteros.
- Edades **numéricas**. Nombres: **200 femeninos + 200 masculinos + apellidos**, estilo variado (latino, europeo, americano).
- **Peleas**: sin muerte; simuladas con dados por dentro (ponderados por oficio, edad, salud, personalidad); en pantalla algo **discreto**
  (dos vecinos frente a frente, movimientos sutiles, algún "💢"); guardias pueden intervenir; consecuencias: heridas leves y relación peor.
  Son **raras y excepcionales**: solo tras una enemistad cultivada durante mucho tiempo, nunca la norma. Una partida larga sin peleas es válida; el pueblo no debe vivir peleándose.
- Jugador: **observador, instigador y mediador** (apoyado en Carisma y Sigilo). Se implementa al final.
- **Calibración**: simulaciones automáticas de cientos de días. Metas de ejemplo para 60 días: 1–3 parejas nuevas; 2–6 peleas en el simulador abstracto, pero en vivo pocas o ninguna (ninguna pareja de
  vecinos pelea >2 veces); ningún vecino sin amigos; más de la mitad de las relaciones entre −20 y +40.
- Arquitectura: **Director Social central** (decide la escena), aldeanos solo ejecutan; relaciones con 4 medidas (afinidad, familiaridad, atracción, tensión),
  enfriamiento sin contacto, "narrador" que dosifica el drama, todos los ajustes en una única tabla de diales, aleatoriedad con semilla.

- **Fe y semana**: religión inventada provisional (Fe del Alba, parecida al cristianismo sin nombres reales); el sacerdote es un personaje propio; los fieles caminan a la capilla de verdad; fin de semana con menos trabajo; los bandos defienden a los suyos con efecto pequeño.
- **Misiones secundarias**: nacen de los vecinos en persona (nunca del tablón), con baja probabilidad, y se ven en un panel propio (tecla L) que tendrá también la historia principal. Sin fecha límite fija; fallan si pasa algo en el mundo (p. ej. muere quien la pidió).
  Tipos aprobados: 1) «Haz las paces por mí» (mediación), 2) «Ensúciale el nombre» (calumnia; da móvil en investigaciones), 3) «¿Quién va contando eso de mí?» (puedes mentir si fuiste tú),
  4) «Encuentra a quien lo mató» (se resuelve con el veredicto), 5) «Averigua qué piensa de mí» (solo información, no fuerza parejas).

## 9. Cómo cerrar una sesión

1. Ejecuta los dos tests. 2. Actualiza la sección 7 (marca bloques). 3. `git add -A && git commit`. 4. Resume al usuario en pocas líneas: hecho, verificado, pendiente.
