# Mapa del código (para el usuario y cualquier agente)

> Para qué sirve: saber **dónde está lo que quieres arreglar** sin saber programar. Cada carpeta y cada archivo, en una
> línea. Creado el 2026-11-10 (paso 0 del paso a 3D, `docs/PLAN_MUNDO_3D.md`). **Se actualiza en cada bloque que mueva,
> parta o borre archivos.** Entre corchetes, las líneas que tiene; ⚠ = demasiado grande, se ordenará cuando le toque.
>
> Cómo leer un archivo: los de Godot (`.gd`) empiezan con unas líneas con `##` que dicen para qué sirven.

## De un vistazo

| Carpeta | Qué hay | Tamaño |
|---|---|---|
| `scripts/fisica/` | **Nuevo (paso a 3D).** Todo lo físico del mundo 3D: conversión mapa ↔ 3D, cuerpo 3D del protagonista, choques y suelo | 4 archivos |
| `scripts/` (sueltos) | El protagonista: moverse, pelear, el mundo principal | 4 archivos, ~2.800 líneas |
| `scripts/enemies/` | Los vecinos (cerebro, trabajo, vida social, policía, diálogos), animales salvajes, mascotas, asaltantes | 12, ~10.100 |
| `scripts/systems/` | Las reglas del pueblo: reloj, guardado, economía, casas, crimen, justicia, fe, familia, taberna… | 58, ~38.600 |
| `scripts/systems/combat/` | Golpes, heridas, armas, flechas | 12, ~2.000 |
| `scripts/systems/quests/` | Misiones secundarias y sus tipos | 28, ~2.500 |
| `scripts/obstacles/` | Cosas del mundo con las que interactúas: huerto, gallinero, pesca, campamento, caballo, carro, objetos | 10, ~4.700 |
| `scripts/visuals/` | Todo lo que se ve en 3D: escenario, edificios, terreno, muñecos de personas y animales | 11, ~11.400 |
| `scripts/ui/` | Paneles y menús de la partida: detective, mapa, mochila, salud, casino, crónica… | 15, ~9.100 |
| `scripts/ui/menu/` | Menú principal, pausa, ajustes, partidas y créditos | 6, ~800 |
| `scripts/data/` | Datos fijos: nombres, rasgos, frases, fichas de los vecinos | 5, ~1.600 |
| `scenes/` | La escena del pueblo (`World.tscn`), el menú principal y la interfaz de la partida (`ui_root.gd`) | 7, ~2.500 |
| `mapa/` | El editor del mapa 3D (`Mundo3D.tscn`) y sus piezas; el editor 2D del río | 15, ~1.400 |
| `addons/` | Complementos del editor de Godot: pincel del mapa (nuestro) y Asset Placer (de otro autor, no tocar) | — |
| `tools/` | Herramientas y pruebas automáticas (`tools/tests/`). `convertir_escala_0b.py`: conversión de un solo uso del mapa a metros | — |

## El protagonista — `scripts/`
- `Player.gd` [1.143] ⚠ — el jugador: vida, inventario, caballo, interacción, guardar su estado.
- `PlayerMovementController.gd` [394] — andar, correr, rodar, saltar, sigilo. Desde el paso 1 no mueve al jugador él mismo: se lo pasa a su cuerpo 3D (`fisica/Cuerpo3D.gd`).
- `PlayerCombatController.gd` [1.013] ⚠ — atacar, parar, empujar, apuntar.
- `World.gd` [279] — monta el pueblo al empezar la partida, zoom, filtro de color retro.

## Física y mundo 3D — `scripts/fisica/` (nuevo)
- `Mapa3D.gd` [~55] — **el único sitio** que pasa una posición del mapa a 3D y al revés, en metros (1 unidad = 1 m,
  igual en todas direcciones desde el paso 0b). Lo usan el juego, el editor del mapa y las herramientas.
- `Cuerpo3D.gd` [~150] — el cuerpo 3D del protagonista (paso 1): anda, choca, cae y salta en 3D y escribe su sitio en el mapa.
- `ChoquesCercanos3D.gd` [~150] — copias 3D, levantadas como muros, de los choques del mapa que hay cerca de un cuerpo.
- `Suelo.gd` [~30] — a qué altura está el suelo en un punto (tarimas, plaza, puentes, planta alta de la taberna).

## Lo que se ve en 3D — `scripts/visuals/`
- `WorldStageBase3D.gd` [~1.000] ⚠ — base del escenario: relieve del suelo, materiales, cajas y cilindros 3D.
- `WorldStageTerrain3D.gd` [1.663] ⚠ — suelo, caminos, plaza, río, lago, ciénaga, barrios, árboles y plantas.
- `WorldStageBuildings3D.gd` [2.688] ⚠ — edificios, fachadas, tejados, interiores, taberna, trattoria.
- `WorldStageProps3D.gd` [1.320] ⚠ — cementerio, alcantarillas, farolas, objetos del mundo.
- `WorldStage3D.gd` [1.484] ⚠ — la cámara (1.ª persona y desde arriba), brazos y armas en pantalla, ajustes gráficos.
- `CharacterAvatar3D.gd` [910] ⚠ y `CharacterRig3D.gd` [1.195] ⚠ — los muñecos 3D de personas y sus animaciones.
- `AnimalModel3D.gd`, `BanditModel3D.gd` — muñecos 3D de animales y bandidos.
- `AssetLibrary3D.gd` [527] — catálogo de modelos 3D descargados.
- `RetroPostFX.gd` — filtro de color de pantalla.

## Los vecinos — `scripts/enemies/`
- `VillageNPCBase.gd` [1.491] ⚠ — datos del vecino (casa, familia, necesidades), simulación de los lejanos.
- `VillageNPC.gd` [1.296] ⚠ — su día a día: qué hace en cada momento.
- `VillageNPCSocial.gd` [1.332] ⚠ — moverse, hablar entre ellos, letreros.
- `VillageNPCWork.gd` [946] ⚠ — trabajo, oficios, heridas.
- `VillageNPCDuties.gd` [992] ⚠ — policía, investigar, buscar desaparecidos.
- `NPCDialogue.gd` [1.385] ⚠ — menús de diálogo con el jugador.
- `WildAnimal.gd` [1.294] ⚠, `DomesticPet.gd` [627], `Raider.gd`, `DummyEnemy.gd`, `MillKidnapper.gd`, `DetectionArea.gd`.

## Las reglas del pueblo — `scripts/systems/` (por temas)
- **Base del pueblo:** `VillageManagerBase.gd` [1.962] ⚠ (sitios, rutas, choques de vecinos), `VillageManager.gd` [1.583] ⚠,
  `VillageManagerEconomy.gd` [1.386] ⚠, `VillageManagerSocial.gd` [742] ⚠, `VillageManagerPolice.gd` [815] ⚠,
  `VillageWorldBuilder.gd` [863] ⚠ (construye caminos, edificios y muebles al empezar).
- **Tiempo y partida:** `WorldClock.gd` (reloj), `GameManager.gd` (guardar y cargar), `Ajustes.gd`, `Teclas.gd`,
  `QuestManager.gd`, `AudioManager.gd` (sonidos y oído de los enemigos).
- **Economía y vida diaria:** `VillageNeeds.gd`, `VillageWork.gd`, `VillageTrades.gd`, `VillageLots.gd`, `VillageLoans.gd`,
  `VillageHousing.gd` [2.614] ⚠, `VillageCollections.gd`, `VillageCivic.gd`, `VillagePlaces.gd`, `VillageCulture.gd` [2.790] ⚠,
  `SimpleInventory.gd` [647].
- **Vida social y familia:** `SocialDirector.gd` [1.363] ⚠, `VillageSocialLife.gd`, `VillageDesires.gd`, `VillageSecrets.gd`,
  `VillageFamily.gd`, `VillageLineage.gd` [828] ⚠, `VillageClans.gd` [705] ⚠, `VillageFame.gd` [708] ⚠, `VillageChronicle.gd`,
  `GossipMemory.gd`, `TraitDiscovery.gd`.
- **Crimen, justicia y casos:** `VillageCrime.gd`, `VillageJustice.gd` [1.955] ⚠, `VillageForensics.gd` [885] ⚠,
  `VillageCase1.gd`, `DetectiveCaseData.gd`, `Case1ReportDesk.gd`, `VillageNightJobs.gd`, `VillageUnderworld.gd` [1.735] ⚠,
  `VillageFamilia.gd` [1.392] ⚠, `VillageRestaurant.gd`.
- **Lugares concretos:** `VillageTavern.gd` [827] ⚠, `VillageClub.gd` [649], `VillageConfession.gd`, `VillageFaith.gd`.
- **Gobierno:** `VillageMayor.gd` [627], `VillageTown.gd`, `VillageNobility.gd`, `VillageMigration.gd`, `VillageIllness.gd`.
- **Naturaleza:** `EcosystemManager.gd` [675] ⚠, `RaidController.gd`.
- `VillageSect.gd` — **no tocar sin orden expresa del usuario.**

## Cosas del mundo — `scripts/obstacles/`
`CampSite.gd` [1.017] ⚠ (campamento y casa del jugador), `ChickenCoop.gd` [640], `FarmPlot.gd`, `FishingSpot.gd` [698]
(pesca, y la forma del río), `HarvestableNode.gd`, `DestructibleObject.gd`, `LivestockAnimal.gd`, `PlayerCart.gd` [654],
`PlayerHorse.gd`, `WorldInteractableProp.gd`.

## Paneles — `scripts/ui/` y `scenes/ui_root.gd`
`DetectiveUI.gd` [3.407] ⚠ (el más grande del juego), `TavernGamesUI.gd` [1.370] ⚠, `ValleyMapUI.gd` [671] ⚠,
`SocialGlossaryUI.gd`, `MedicalPanelUI.gd`, `InteractionSelector.gd` (qué hace la tecla E), `Crosshair2D.gd` (punto de mira),
`ToolWheelUI.gd`, `QuestLogUI.gd`, `ChronicleUI.gd`, `SkillsPanelUI.gd`, `CharacterShowcase3DUI.gd`.
`scenes/ui_root.gd` [1.580] ⚠ — reparte las teclas de los paneles y abre la pausa.

## Pruebas — `tools/tests/`
`verify_all.gd` (todo el juego, ~15 min), `fisica_3d.gd` (paso a 3D), `puertas_3d.gd` (entrar y salir por todas las puertas), `capturas_fijas.gd` (fotos para comparar, también
desde arriba),
`menu_probe.gd`, `atascos_vecinos.gd`, `guardado_largo.gd`, `social_sim.gd`, `names_check.gd`, `dialogue_coverage.gd`,
`perf_*.gd` (rendimiento). Cómo lanzarlas: `docs/HANDOFF.md` §3 y `docs/PLAN_MUNDO_3D.md` §6.
