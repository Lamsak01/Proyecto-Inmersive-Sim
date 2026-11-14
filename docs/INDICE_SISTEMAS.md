# Índice de sistemas (máximo 60 líneas): qué archivo abrir sin escanear el repositorio

> Detalle archivo por archivo (con tamaños) en `docs/MAPA_DEL_CODIGO.md`. Lee solo lo de la tarea del día.

## Carpetas
| Carpeta | Qué hay |
|---|---|
| `scripts/` (sueltos) | Protagonista: `Player.gd`, `PlayerMovementController.gd`, `PlayerCombatController.gd`; `World.gd` monta la partida |
| `scripts/fisica/` | Mundo 3D: `Mapa3D` (mapa ↔ metros), `Cuerpo3D` (cuerpo de todo personaje, siempre), `Poblacion3D` (se lo da al nacer), `TallaCuerpo3D`, `ChoquesMundo3D` (paredes 3D compartidas; `Prismas3D`, `AlturasChoque3D`), `AndarMapa`, `Vista` (ver/oír/alcanzar), `Agua`, `Suelo` |
| `scripts/visuals/` | Escenario 3D: `WorldStage3D` (cámara, manos), `WorldStageTerrain3D`, `WorldStageBuildings3D`, `WorldStageProps3D`, `WorldStageBase3D`; muñecos `CharacterAvatar3D`/`CharacterRig3D`, `AnimalModel3D`, `BanditModel3D`; `AssetLibrary3D` |
| `scripts/enemies/` | Vecinos (`VillageNPCBase/NPC/Social/Work/Duties`, `NPCDialogue`; menú principal `NPCMenuDialogo`, charla `NPCCharla` con frases en `resources/dialogos/`), `WildAnimal`, `DomesticPet`, `Raider`, `DummyEnemy`, `MillKidnapper` |
| `scripts/systems/` | Reglas del pueblo: base `VillageManagerBase/Manager/Economy/Social/Police`, `VillageWorldBuilder`; economía, vida social, crimen y justicia, lugares (`VillageTavern`, `VillageClub`…), gobierno, naturaleza. `VillageSect.gd`: **no tocar** |
| `scripts/systems/combat/` · `quests/` · `ai/` · `game_objectives/` | Golpes y heridas · misiones secundarias · IA · objetivos del Caso I |
| `scripts/obstacles/` | Cosas interactivas: caballo, carro, animales de corral, objetos. Forma del río y del lago: `scripts/fisica/RioLago.gd` |
| `scripts/ui/` · `scenes/ui_root.gd` | Paneles (detective, mapa, mochila, salud, casino, crónica); `InteractionSelector` (tecla E); HUD y pausa; ventana de diálogo y tienda en `scripts/ui/dialogo/` (las mueve `scenes/dialogue_manager.gd`) |
| `scripts/data/` | Datos fijos: nombres, rasgos, frases, fichas de vecinos |
| `scenes/` | `World.tscn`, `MenuPrincipal.tscn`, interfaz |
| `mapa/` | Mapa editable `Mundo3D.tscn` y sus piezas (`pieza.gd`, `edificio.gd`, `mueble.gd`, `marca.gd`, `sitio.gd`, `zona.gd`, `solar.gd`, `planta.gd`, `tabique.gd`, `casa_modelo.gd`, `camino.gd`, `rio.gd`, `anclas.gd`) |
| `shaders/` | `agua.gdshader` y filtros retro |
| `tools/` · `tools/tests/` | Herramientas del mapa (`hornear_*.gd`, `esparcir_arboles.gd`, `screenshot_3d.gd`) · pruebas automáticas |
| `addons/` | Pincel del mapa (nuestro) y Asset Placer (ajeno, no tocar) |
| `assests/curated_3d/` · `assets/` | Modelos 3D en uso · sprites y sonidos |

## Autoloads (`project.godot`)
`Ajustes`, `Teclas`, `AudioManager` (sonidos y oído), `GameManager` (guardar/cargar, modo demo), `ObjectiveManager`
(objetivos del Caso I), `QuestManager`, `WorldClock` (reloj; un día = 18 min reales).

## Especificaciones (`docs/specs/`): abre solo la que toque
| Tema | Archivo |
|---|---|
| Pruebas y comandos de Godot | `PRUEBAS.md` |
| Convenciones y trampas del código | `CONVENCIONES_CODIGO.md` |
| Decisiones de diseño cerradas | `DECISIONES_DISENO.md` |
| Física 3D, pisos, agua, cuerpos | `MUNDO_3D.md` |
| Editor del mapa 3D (registro y plan) · mapa ×3 | `REGISTRO_EDITOR_3D.md`, `PLAN_EDITOR_MAPA.md` · `PLAN_MAPA_X3.md` |
| Época (tecnofeudal) | `REVISION_EPOCA.md` |
| Caso I y demo | `PLAN_PARTIDA_CASO1.md`, `PLAN_BETA_MISTERIO.md` |
| Vida social, relaciones, secretos, deseos, recuerdos, crónica | `PLAN_VIDA_SOCIAL.md`, `PLAN_RELACIONES.md`, `PLAN_SECRETOS.md`, `PLAN_DESEOS.md`, `PLAN_RECUERDOS.md`, `PLAN_CRONICA.md` |
| Economía, instituciones, fe, clanes, crecer el pueblo | `PLAN_ECONOMIA_NECESIDADES.md`, `PLAN_INSTITUCIONES.md`, `PLAN_GRUPOS_FE.md`, `PLAN_CRECER_PUEBLO.md` |
| Sitios de los vecinos (la lógica sigue al mapa) | `PLAN_SITIOS.md` |
| Combate | `PLAN_COMBATE.md` |
| Secta (solo con orden del usuario) | `PLAN_SECTA.md` |
| Misiones secundarias, rasgos, edificios, lore provisional | `MISIONES.md`, `RASGOS_BORRADOR.md`, `BOCETOS_EDIFICIOS.md`, `BOCETO_EDIFICIOS_ANTIGUOS.md` (2026-11-11), `APORTES_CREATIVOS.md` |

## Otros documentos vivos (`docs/`)
`ESTADO_ACTUAL.md` (léelo al empezar), `FALLOS_VISIBLES.md`, `CONTROLES.md`, `VISION_Y_FUTURO.md` (ideas),
`PREGUNTAS_PENDIENTES.md`, `MAPA_DEL_CODIGO.md`, guías del editor para el usuario, `CREDITOS_RECURSOS.md`.
Historial (bloqueado a los agentes): `docs/archivo/`.
