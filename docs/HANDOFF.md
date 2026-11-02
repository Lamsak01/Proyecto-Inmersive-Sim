# HANDOFF — Traspaso del proyecto "La Placa de Petri" (Godot 4.7.2)

> Documento para el siguiente agente de IA (o persona) que continúe el proyecto. **Léelo entero antes de tocar nada.**
> Última actualización: 2026-11-02, tras cerrar B6.4 (vida social completa). Plan detallado en `docs/PLAN_VIDA_SOCIAL.md`.

---

## 0. PROMPT LISTO PARA PEGAR AL SIGUIENTE AGENTE

```
Eres el asistente técnico principal del proyecto "La Placa de Petri": un Immersive Sim / sandbox 2D top-down en pixel art hecho en Godot 4.7.2 (GDScript). La carpeta es /home/lamsaktp/Proyecto-Inmersive-Sim. Yo NO sé programar. Háblame siempre en español.

ANTES DE HACER NADA:
1. Lee completo docs/HANDOFF.md y docs/PLAN_VIDA_SOCIAL.md.
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

**Estado del código:** vida social completa (Fases 0 a 6) y subida a `main`; los cuatro tests pasan. Refuerzo del código (R1–R5) terminado. M1 (móvil social en investigaciones), Q1 (panel de misiones) Q1–Q4 hechos (5 tipos de misión, con estructura lista para muchos más). **Siguiente:** pensar con el usuario los tipos de misión que faltan hasta llegar a 25 (guía en `docs/MISIONES.md`); no inventarlos sin su aprobación. Historial en `CHANGELOG.md`.

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
  Sin medir: la partida de 60 días tras estos cambios se detuvo en el día 16 a petición del usuario, así que el efecto en quedadas y parejas no está comprobado (más quedadas pueden subir las 3 parejas nuevas por partida). Sin corregir, por menor: un guardia que empiece una escolta durante su pelea tarda hasta 3,5 s.
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
  Son **raras y excepcionales**: solo tras una enemistad cultivada durante mucho tiempo, nunca la norma. Una partida larga sin peleas es válida; el pueblo no debe vivir peleándose.
- Jugador: **observador, instigador y mediador** (apoyado en Carisma y Sigilo). Se implementa al final.
- **Calibración**: simulaciones automáticas de cientos de días. Metas de ejemplo para 60 días: 1–3 parejas nuevas; 2–6 peleas en el simulador abstracto, pero en vivo pocas o ninguna (ninguna pareja de
  vecinos pelea >2 veces); ningún vecino sin amigos; más de la mitad de las relaciones entre −20 y +40.
- Arquitectura: **Director Social central** (decide la escena), aldeanos solo ejecutan; relaciones con 4 medidas (afinidad, familiaridad, atracción, tensión),
  enfriamiento sin contacto, "narrador" que dosifica el drama, todos los ajustes en una única tabla de diales, aleatoriedad con semilla.

- **Misiones secundarias**: nacen de los vecinos en persona (nunca del tablón), con baja probabilidad, y se ven en un panel propio (tecla L) que tendrá también la historia principal. Sin fecha límite fija; fallan si pasa algo en el mundo (p. ej. muere quien la pidió).
  Tipos aprobados: 1) «Haz las paces por mí» (mediación), 2) «Ensúciale el nombre» (calumnia; da móvil en investigaciones), 3) «¿Quién va contando eso de mí?» (puedes mentir si fuiste tú),
  4) «Encuentra a quien lo mató» (se resuelve con el veredicto), 5) «Averigua qué piensa de mí» (solo información, no fuerza parejas).

## 9. Cómo cerrar una sesión

1. Ejecuta los dos tests. 2. Actualiza la sección 7 (marca bloques). 3. `git add -A && git commit`. 4. Resume al usuario en pocas líneas: hecho, verificado, pendiente.
