# Misiones secundarias de vecinos

Guía para añadir tipos nuevos. Meta del usuario: **al menos 25 tipos** (hoy hay 5). Las ideas se pensarán a fondo con el usuario antes de implementarlas: **no inventes tipos sin su aprobación**.

## Reglas de diseño (decididas por el usuario)

- Las misiones nacen **en persona** de un vecino (❗ sobre su cabeza), nunca del tablón de encargos.
- Salen de lo que el mundo ya simula (relaciones, rasgos, sucesos). Son **ocasionales**: como mucho 3 ofertas o misiones de vecinos a la vez.
- No tienen fecha límite fija. Fallan si pasa algo en el mundo; por ejemplo, si muere quien la pidió.
- El panel (tecla **L**) tiene las pestañas «Secundarias» y «Principal». La historia principal usará la categoría `main` del mismo `QuestManager`.
- Nada de forzar parejas: las misiones románticas solo dan información o apagan la ilusión, nunca crean pareja.
- Siempre que se pueda, el jugador elige cómo cerrarla: decir la verdad, mentir o señalar a otro.

## Piezas

| Archivo | Qué hace |
|---|---|
| `scripts/systems/QuestManager.gd` (autoload) | Registro genérico: misiones activas, completadas y fallidas, ofertas y esperas por vecino. Se guarda con la partida. |
| `scripts/ui/QuestLogUI.gd` | Panel L. |
| `scripts/systems/VillageQuests.gd` | Reglas comunes: sorteo diario, caducidad, fallos, diálogo de aceptar, abandonar y cobrar, y ❗. No contiene lógica de ningún tipo concreto. |
| `scripts/systems/quests/QuestType.gd` | Clase base con todo lo que un tipo puede redefinir, documentado. |
| `scripts/systems/quests/QuestRegistry.gd` | Lista de tipos registrados (`TYPE_SCRIPTS`). |
| `scripts/systems/quests/types/` | Un archivo por tipo, más `_PLANTILLA.gd` (no registrada). |

## Cómo añadir un tipo (pasos)

1. Copia `types/_PLANTILLA.gd` a `types/QuestNombre.gd`.
2. En `_init()` rellena:
   - `id`: único; no cambiarlo nunca, porque se guarda en las partidas.
   - `trigger`: `"daily"` (lo busca el sorteo diario) o `"event"` (lo crea un suceso).
   - `priority`, `gold`, `affinity` y `needs_alive_target`.
3. Redefine al menos `texts` (`title`, `ask`, `desc`), `is_done` y `progress_hint`. Si es diario, también `find_daily_offer`.
4. Opcional, según lo que necesite:
   - `init_data`: datos propios al aceptarla.
   - `done_dialogue` y `on_turn_in`: varias formas de cerrarla (verdad, mentira, acusar...).
   - `failure_reason`: motivos propios de fallo.
   - `on_player_influence`: reaccionar cuando el jugador habla bien o mal de alguien, media o hace de celestina.
   - `add_world_dialogue` y `on_extra_action`: opciones nuevas en el diálogo de otros vecinos. Las acciones deben empezar por `quest_`.
5. Si es de tipo `"event"`, añade en `VillageQuests.gd` una función `on_<suceso>` y llámala desde donde ocurre el suceso, como hacen `on_murder_case_opened` y `on_rumor_reached_target`.
6. Añade su ruta a `QuestRegistry.TYPE_SCRIPTS`.
7. Escribe un test en `tools/tests/verify_all.gd` que la ofrezca, la acepte, la cumpla y la cobre. El test #39 ya comprueba sin más trabajo que tenga textos e id únicos.
8. Apúntala en la tabla de abajo, en `CHANGELOG.md` y en `docs/HANDOFF.md`.

Datos útiles para `find_daily_offer`:
- `ctx["worst"]`: el vecino con quien peor se lleva.
- `ctx["enmity_choice"]`: `"peace"`, `"slander"` o `""`.
- `vm.social_director.pair_metrics`: afinidad, chispa, tensión, días de enemistad y peleas de cada pareja.
- `npc.person_profile`: rasgos, edad y estado sentimental.
- `vm.social_event_log`: sucesos con `known_by` (quién lo sabe) y `heard_from` (quién se lo contó a quién).

## Tipos hechos (5 de 25)

| id | Nombre | Cómo nace | Cómo se cumple | Cobro |
|---|---|---|---|---|
| `peace` | Haz las paces por mí | Diaria: enemistad larga y carácter pacífico | Mediar con el rival hasta que vea al otro en ≥ −15 o mejore 12 | 30 oro, +15 |
| `slander` | Ensúciale el nombre | Diaria: enemistad ≤ −40 y carácter rencoroso | Hablar mal del rival a 2 vecinos distintos | 25 oro, +12 |
| `opinion` | Averigua qué piensa de mí | Diaria: soltero con chispa ≥ 14 hacia otro soltero | Ver la opinión del otro en el menú de opiniones; al volver, verdad o mentira | 20 oro, +8 |
| `justice` | Encuentra a quien lo mató | Suceso: se abre un caso de asesinato (60 %, vecino con relación ≥ 40 con la víctima) | Veredicto contra un vecino (falla si te culpan o se archiva) | 40 oro, +20 |
| `rumor` | ¿Quién va contando eso de mí? | Suceso: una calumnia llega al afectado de segunda mano (50 %) | Preguntar «¿quién te lo contó?»; al volver, señalar a alguien o confesar | 25 oro, +10 |

## Ideas pendientes (20 o más)

Están por decidir con el usuario. Antes de implementar cualquiera, presenta la lista y espera su aprobación.
