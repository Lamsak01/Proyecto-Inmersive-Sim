# HANDOFF — Traspaso del proyecto "La Placa de Petri" (Godot 4.7.2)

> Documento para el siguiente agente de IA (o persona) que continúe el proyecto. **Léelo entero antes de tocar nada.**
> Última actualización: tras el commit `d07afa3` + bloque de traspaso. Plan detallado en `docs/PLAN_VIDA_SOCIAL.md`.

---

## 0. PROMPT LISTO PARA PEGAR AL SIGUIENTE AGENTE

```
Eres un asistente de programación que continúa el proyecto "La Placa de Petri", un Immersive Sim / sandbox 2D top-down
en pixel art hecho en Godot 4.7.2 (GDScript), en la carpeta del proyecto. El usuario NO programa: te habla en español,
quiere respuestas concisas, y confía en ti para las decisiones técnicas.

ANTES DE NADA:
1. Lee docs/HANDOFF.md (este archivo) y docs/PLAN_VIDA_SOCIAL.md.
2. Ejecuta `git log --oneline | head` y `git status` para ver dónde se quedó el trabajo.
3. Ejecuta los dos tests de tools/tests/ (comandos en la sección 3) y confirma que pasan ANTES de cambiar nada.

CÓMO TRABAJAR:
- Responde SIEMPRE en español, breve, con listas. Enlaza archivos con rutas.
- Avanza en BLOQUES PEQUEÑOS (un bloque = una idea verificable). Tras cada bloque: prueba → commit → resumen corto.
- Si el usuario pide un plan o dice "no escribas código", no lo escribas hasta que lo apruebe.
- Sé honesto: distingue lo que verificaste (tests) de lo que solo supones. Nunca digas que algo funciona sin haberlo ejecutado.
- No hagas refactors grandes sin pedirlo. No cambies comportamiento visible sin avisar.
- Pide al usuario datos concretos cuando los necesites (por ejemplo, capturas del panel de errores de Godot con archivo y línea).
- Al terminar cada sesión, actualiza la sección 7 ("Estado y siguiente bloque") de docs/HANDOFF.md y haz commit.

TAREA ACTUAL: construir el sistema de VIDA SOCIAL procedural de los aldeanos siguiendo docs/PLAN_VIDA_SOCIAL.md,
en los bloques de la sección 7. Continúa por el primer bloque sin marcar [x].
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
4. Los NPC nuevos usan un aspecto único (`assests/world/village/villager_traveler.png`). Aceptado por ahora.
5. Reparto actual: **6 mujeres / 11 hombres** entre los 17 vecinos residentes (visitantes aparte). Solo heterosexuales por ahora.
6. Partir `VillageNPC.gd` más allá de lo hecho es arriesgado (funciones muy entrelazadas con decenas de variables). El usuario aceptó parar ahí.
   Si hace falta, extraer módulos nuevos **como clases aparte con `npc` tipado** (técnica usada en `NPCDialogue.gd`) y comprobar con `dialogue_coverage.gd`.
7. Aviso: `get_nodes_in_group("village_npcs")` se llama en ~50 sitios. Con ~17 NPC es aceptable; cuida el rendimiento al añadir sistemas.

## 7. Estado y siguiente bloque

**Estado del código:** limpio, todo commiteado, tests pasando (`verify_all.gd`, `dialogue_coverage.gd`).

### Bloques del sistema de Vida Social (marca [x] al terminar y commitea)

**Fase 0 — Cimientos**
- [ ] **B0.1** `scripts/data/NPCNames.gd`: 200 nombres femeninos, 200 masculinos (variedad latina/europea/americana) y apellidos. Función para elegir un nombre único. Sin tocar el juego.
- [ ] **B0.2** Ficha de persona (`PersonProfile`): id único, género, edad numérica, personalidad (3 rasgos), gustos, estado sentimental. Tabla con los 17 vecinos actuales (género y edad según su historia; el lore puede retocarse).
- [ ] **B0.3** Generador de vecinos nuevos (nombre único, género equilibrado, edad según oficio, personalidad y gustos) y **unificar los 5 puntos de creación** para que lo usen.
- [ ] **B0.4** Migrar las relaciones a claves únicas; que un fallecido no pueda heredarse; limpiar entradas de muertos.
- [ ] **B0.5** Guardado/carga de la ficha y de las relaciones, con valores por defecto para partidas antiguas.
- [ ] **B0.6** Registro de eventos sociales (base de "Noticias del pueblo").
- [ ] **B0.7** Esqueleto del **Director Social** (máx. 2–3 escenas simultáneas) y tabla única de "diales" de ajuste.
- [ ] **B0.8** Pareja inicial **Elena y el Dr. Valen**.
- [ ] **B0.9** Simulador headless de N días con semilla y métricas (objetivos en sección 8).

**Fase 1** Conversaciones con frases · **Fase 2** Pasar tiempo juntos · **Fase 3** Parejas (chispa, etapas, celos, duelo) ·
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
