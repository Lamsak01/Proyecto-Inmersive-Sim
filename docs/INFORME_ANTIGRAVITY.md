# Informe de Trabajo — Antigravity (2026-11-08)

## ENCARGO DE HOY (2026-11-08, tarde) — Paso a paso
- **1. `[E]` solo sobre lo que miras en 1.ª persona (`scripts/ui/InteractionSelector.gd`, `scripts/Player.gd`):** añadido `_fp_crosshair_score()` para exigir que el objeto esté bajo la cruz del centro (cono horizontal `horiz_cos >= 0.90`, desvío lateral `<= 7–9.5 px`, distancia corta `24–32 px` e inclinación vertical `fp_pitch` acorde a si está en el suelo o a la altura de la vista), evitando que salgan avisos de puertas a tu espalda o trampillas/alcantarillas a tus pies cuando miras al frente o a la escalera. Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/tarde_1_e_solo_al_mirar_3d.png`.
- **2. Quitar `[Alt]` de rodar y actualizar la ayuda `[H]` (`scripts/PlayerMovementController.gd`, `scenes/ui_root.gd`):** retirada la tecla `KEY_ALT` (y cualquier combinación con `alt_pressed`) del disparo de `start_roll()`, dejando rodar únicamente en `[V]` y actualizando la fila `Rodar: V` en el panel de ayuda `[H]`. Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/tarde_2_sin_alt_ayuda_h_3d.png`.
- **3. Salto en el piso de arriba sin atascos ni pérdida de vida, y muerte por accidente al Hospital (`scripts/PlayerMovementController.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/Player.gd`, `scripts/PlayerCombatController.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/enemies/VillageNPCDuties.gd`, `scripts/enemies/DomesticPet.gd`, `scripts/systems/VillageManagerBase.gd`, `scripts/systems/VillageTavern.gd`):** acotada la altura del salto en interiores (`4,8 px`) y de la cámara en 1.ª persona bajo dinteles y techos, corregidos los tabiques de Planta +1 que caían dentro del hueco de puerta (`x = 451`), aislado el choque físico (`body_col`) y el daño entre pisos distintos (`elevation_level != player_elevation_level`), y ajustado `_on_died()` para que solo lleve a la comisaría si hubo delito y te abatió un guardia, trasladando cualquier caída accidental al Hospital. Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/tarde_3_salto_arriba_y_hospital_3d.png`.
- **4. Sillas orientadas hacia su mesa en todos los edificios + comprobación automática (`scripts/visuals/WorldStageBase3D.gd`, `scripts/visuals/WorldStageBuildings3D.gd`, `tools/tests/verify_all.gd`):** añadido `_chair_rot_y_towards(chair_pos, table_pos)` (`rad_to_deg(atan2(d.x, d.y))`, ya que `props/Chair_1.gltf` tiene el asiento hacia `+Z` a `0°`), corregida la rotación de todas las sillas en taberna, póker, casa de comidas (salón, terraza, despacho y trastienda), viviendas y estudios nobiliarios para que miren siempre hacia el centro de su mesa con el respaldo hacia fuera, y ampliada `check_furniture_overlaps()` para verificar automáticamente que toda silla `Chair_*` apunte hacia su mesa (`dot >= 0.80`). Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/tarde_4_sillas_orientadas_3d.png`.
- **5. Vecinos sobre aceras/pavimento sin hundirse y sin superponerse en la calle (`scripts/visuals/WorldStageBase3D.gd`, `scripts/visuals/WorldStageTerrain3D.gd`, `scripts/visuals/CharacterAvatar3D.gd`, `scripts/enemies/VillageNPCSocial.gd`, `scripts/enemies/VillageNPCWork.gd`):** enrasados los bordillos y el empedrado de la plaza y caminos con el terreno (`z0 = -1.0..+0.45 px`) sumando `surface_elevation_offset_px(pos_2d)` a la altura de pies en `CharacterAvatar3D` para que ningún vecino hunda las botas en la acera, y añadida separación entre vecinos también en reposo (`_apply_player_and_doorway_yield`, radio `17 px`) junto con desfases individuales en destinos compartidos (`errand_pos`, `rite_pos`, `_social_partner`). Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/tarde_5_vecinos_acera_sin_solape_3d.png`.

## Resumen del ENCARGO DE HOY y TROCEO DE ARCHIVOS GRANDES (2026-11-08)
- **Completados los 7 puntos del ENCARGO DE HOY** en orden, con capturas en 1.ª persona 3D revisadas visualmente (`docs/capturas_arreglos/hoy_1_*.png` a `hoy_7_*.png`) y entradas marcadas con ✅ en `docs/FALLOS_VISIBLES.md`: (1) arreglado el cierre al pulsar `[E]` sobre el vigía exterior («Roldán · Vigía del Oeste») dándole retrato y modelo 3D; (2) eliminados los solapes de muebles en todos los edificios (`0` solapes en `check_furniture_overlaps()`); (3) subida la taberna a escala adulta en las dos plantas (`34 px` por piso) y corregidos los clientes sentados comiendo/bebiendo en taberna y terraza nocturna; (4) despejado el paso en la plaza entre farola y pozo (`> 57 px`); (5) restaurado el disparo con clic izquierdo (`MOUSE_FILTER_IGNORE` en HUD), modelos 3D de pistola y fusil en manos y expositor en la armería para comprar (`[E]`) o robar (`[F]`); (6) brazos redondeados con manos/dedos, estela fina semitransparente y ocultación de manos de 1.ª persona en vista superior; y (7) salto con `[Espacio]`.
- **Completado el TROCEO DE ARCHIVOS GRANDES** en los 3 archivos de más de 5.000 líneas (`WorldStage3D.gd`, `VillageManager.gd` y `VillageNPC.gd`), divididos por temas en 5 scripts cada uno (`< ~1.480` líneas por archivo) sin cambiar ningún comportamiento visible, con arranque limpio, batería completa `tools/tests/verify_all.gd` en verde (`EXIT_CODE=0`), capturas 3D en 1.ª persona (`troceo_1_*.png` a `troceo_3_*.png`) y mapa del código actualizado en `docs/HANDOFF.md`.

## TROCEO DE ARCHIVOS GRANDES (2026-11-08)
- **1. Troceo de `scripts/visuals/WorldStage3D.gd` (`5.457` líneas -> 5 archivos temáticos `< 1.330` líneas):** dividido sin cambiar ningún comportamiento en `WorldStageBase3D.gd` (`859` lín.: constantes, shaders, matemáticas de relieve y primitivas 3D), `WorldStageProps3D.gd` (`1.307` lín.: Puesto del Paso, cementerio, alcantarillas, objetos de la época, farolas y props dinámicos), `WorldStageBuildings3D.gd` (`1.243` lín.: edificios, interiores, taberna de 2 plantas, trattoria y solares), `WorldStageTerrain3D.gd` (`760` lín.: terreno, caminos, lago, barrios y vegetación) y `WorldStage3D.gd` (`1.328` lín.: ciclo de vida, cámara, 1.ª persona, brazos/armas 3D y cutaway). Verificado con `tools/tests/verify_all.gd` (`EXIT_CODE=0`) y captura en 1.ª persona 3D en `docs/capturas_arreglos/troceo_1_worldstage3d_3d.png`.
- **2. Troceo de `scripts/systems/VillageManager.gd` (`5.555` líneas -> 5 archivos temáticos `< 1.440` líneas):** dividido sin cambiar ningún comportamiento en `VillageManagerBase.gd` (`1.433` lín.: constantes, estado, geometría de edificios, navegación, puertas/ventanas y utilidades base), `VillageManagerSocial.gd` (`698` lín.: autoridades, recién llegados, rumores, morgue/cementerio, mascotas, quedadas, peleas, romances y sucesión), `VillageManagerPolice.gd` (`815` lín.: denuncias, registro de cadáveres, escolta policial y cárcel, tablón de encargos, sangre/huellas, investigaciones y cepos), `VillageManagerEconomy.gd` (`1.380` lín.: puestos comerciales, sabotajes, comidas y despensas, gestión de negocios, sueldos, alquiler de taberna, campamentos y mercader viajero) y `VillageManager.gd` (`1.308` lín.: `setup_village`, `_process`, `_unhandled_input`, `interact`, modales, ciclos horario/diario y guardado/carga). Verificado con `tools/tests/verify_all.gd` (`EXIT_CODE=0`) y captura en 1.ª persona 3D en `docs/capturas_arreglos/troceo_2_villagemanager_3d.png`.
- **3. Troceo de `scripts/enemies/VillageNPC.gd` (`5.800` líneas -> 5 archivos temáticos `< 1.480` líneas):** dividido sin cambiar ningún comportamiento en `VillageNPCBase.gd` (`1.476` lín.: enums `TradeRole`/`ActivityState`, estado, bolsillos, relaciones base, etiquetas, nutrición/sueño y utilidades), `VillageNPCSocial.gd` (`1.202` lín.: charla entre vecinos, búsqueda de desaparecidos, reacción a inconscientes, quedadas, peleas, movimiento y animaciones), `VillageNPCDuties.gd` (`988` lín.: patrulla policial, arrestos, ruido/testigos de combate, reporte y traslado de cadáveres, memoria visual y curación médica), `VillageNPCWork.gd` (`941` lín.: toma de decisiones `_update_needs_and_decisions`, artesanía en taller, expediciones matinales, caza y sucesión de oficio) y `VillageNPC.gd` (`1.276` lín.: `_ready`, `setup_npc`, `_physics_process`, combate hostil, daño/sigilo/muerte, diálogo/robo y guardado/carga). Actualizado el mapa del código en `docs/HANDOFF.md`. Verificado con `tools/tests/verify_all.gd` (`EXIT_CODE=0`) y captura en 1.ª persona 3D en `docs/capturas_arreglos/troceo_3_villagenpc_3d.png`.

## ENCARGO DE HOY (2026-11-08) — Paso a paso
- **1. Cierre del juego al pulsar `[E]` sobre el «Aldeano Guía» (`scenes/dialogue_manager.gd`, `scenes/npc.gd`, `scripts/ui/InteractionSelector.gd`, `scripts/visuals/CharacterAvatar3D.gd`, `scripts/data/NPCData.gd`):** corregido el fallo que intentaba leer `.texture` directamente de un `AnimatedSprite2D` al abrir el diálogo, ajustado `_resolve_target` en `InteractionSelector.gd` para que devuelva al NPC padre cuando el `Area2D` hija tiene `interact()`, y dado nombre propio («Roldán · Vigía del Oeste»), retrato y modelo 3D de explorador fronterizo. Comprobado en 1.ª persona 3D pulsando `[E]` en `docs/capturas_arreglos/hoy_1_aldeano_guia_3d.png`.
- **2. Muebles que se atraviesan en todos los edificios (`scripts/visuals/AssetLibrary3D.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/systems/VillageTavern.gd`, `tools/tests/verify_all.gd`):** corregido en `AssetLibrary3D.instantiate_model` el escalado de muebles rectangulares (`Table_Large.gltf`, `Workbench.gltf`, etc.) para que respeten su huella 2D exacta sin desbordar por usar la altura proyectada `sy`, separadas todas las sillas, mesas, taburetes, cofres y estanterías con `2–3 px` de margen libre en todos los interiores (taberna, trattoria/casa de comidas, viviendas, tiendas, herrería, ayuntamiento, mansiones y comisaría), y añadida la comprobación automática `check_furniture_overlaps()` en `WorldStage3D.gd` y `verify_all.gd` (`0` solapes en todos los edificios). Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/hoy_2_muebles_sin_solape_3d.png`.
- **3. Taberna a escala adulta en las dos plantas y clientes sentados comiendo/bebiendo en la taberna y en la terraza nocturna de la casa de comidas (`scripts/systems/VillageTavern.gd`, `scripts/systems/VillageRestaurant.gd`, `scripts/systems/VillagePlaces.gd`, `scripts/systems/VillageManager.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/visuals/CharacterAvatar3D.gd`, `scripts/visuals/CharacterRig3D.gd`, `scripts/visuals/WorldStage3D.gd`):** subida la altura de ambas plantas de la taberna a `34 px` por planta (`68 px` en total) con puertas y dinteles amplios en los cuartos superiores y altura de cámara corregida en Planta +1; corregido el corte de `ActivityState.EATING` en `_update_needs_and_decisions` que interrumpía la comida `0,5 s` después de comprar el plato cuando `digestion_buffer > 5.0`; ajustado el encaje de pelvis de `Sitting_Idle_Loop` y la rotación de las sillas hacia la mesa; y activadas las cenas y tertulias nocturnas (`18:00–24:00`) en la terraza de la casa de comidas. Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/hoy_3_taberna_escala_y_clientes_3d.png` y `docs/capturas_arreglos/hoy_3b_terraza_noche_3d.png`.
- **4. Plaza: paso cómodo entre farola y pozo (`scripts/systems/VillageWorldBuilder.gd`, `scripts/systems/VillageManager.gd`, `scripts/systems/VillagePlaces.gd`, `scripts/visuals/WorldStage3D.gd`):** separadas las farolas de la plaza a las esquinas norte (`Vector2(392, 10)` y `Vector2(534, 10)`), movido el pozo a `Vector2(416, 62)` y el tablón de encargos al borde norte (`Vector2(476, 14)`), y eliminados dos bancos 3D duplicados en la calzada, abriendo un corredor despejado de más de `57 px`. Comprobado caminando y en 1.ª persona 3D en `docs/capturas_arreglos/hoy_4_plaza_pozo_farola_3d.png`.
- **5. Armas de fuego usables: clic izquierdo dispara, modelo 3D en las manos y compra/robo en la armería (`scenes/ui_root.gd`, `scripts/PlayerCombatController.gd`, `scripts/Player.gd`, `scripts/systems/SimpleInventory.gd`, `scripts/systems/VillageCulture.gd`, `scripts/systems/VillageManager.gd`, `scripts/obstacles/WorldInteractableProp.gd`, `scripts/ui/InteractionSelector.gd`, `scripts/visuals/WorldStage3D.gd`):** configurado `MOUSE_FILTER_IGNORE` en la raíz de `UIRoot` y en los paneles pasivos del HUD para que no traguen los clics de disparo ni apuntado, añadido expositor 3D interactivo (`ArmoryWeaponRack`) en la Herrería y Armería «Yunque Gris» donde comprar (`[E]`) o robar (`[F]`) pistola, fusil y sus cartuchos sin prerrequisitos ocultos, con autoequipado inmediato, ranura `[0]` y modelos 3D detallados en las manos. Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/hoy_5_armas_fuego_3d.png`.
- **6. Combate en 1.ª persona: brazos redondeados con manos y dedos, estela fina y semitransparente, y ocultación en vista desde arriba (`scripts/visuals/WorldStage3D.gd`, `scripts/PlayerCombatController.gd`):** remodelados ambos brazos de 1.ª persona con antebrazos cilíndricos, muñequeras de cuero con anilla de latón, palmas redondeadas y dedos articulados, cambiada la estela de golpe a una cinta fina y semitransparente (`alpha = 0.26 / 0.12`) con chispas puntuales discretas sin bloques blancos, y ocultados `_fp_viewmodel_root` y `weapon_sprite` al volver a la vista desde arriba. Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/hoy_6_combate_brazos_estela_3d.png`.
- **7. Saltar con la tecla `[Espacio]` (`scripts/PlayerMovementController.gd`, `scripts/Player.gd`, `scripts/visuals/CharacterAvatar3D.gd`, `scripts/visuals/WorldStage3D.gd`, `scenes/ui_root.gd`, `tools/tests/verify_all.gd`):** añadido salto vertical (`start_jump()`, `is_jumping()`, `get_jump_height()`) al pulsar `[Espacio]`, pasando el esquive/rodar a `[Alt]` / `[V]` sin alterar `start_roll()`, y aplicando la altura del salto tanto al muñeco 3D como a la cámara y brazos en 1.ª persona. Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/hoy_7_salto_3d.png`.

## Resumen de cierre del Modo Noche (2026-11-08)
- **Qué se hizo:** Se completaron de principio a fin los **6 puntos del Orden de la Noche** de `docs/ENCARGO_SIGUIENTE.md` más la nota nocturna del supervisor, con capturas en 1.ª persona 3D revisadas visualmente tras cada paso y toda la batería de pruebas (`tools/tests/verify_all.gd`, `EXIT_CODE=0`) en verde:
  1. **5 entradas en marcha de `FALLOS_VISIBLES.md`:** relieve de la Fase A suavizado (`< 10°`, caminos y solares planos, muelle y orillas del Lago del Oeste), planta baja de la taberna (suelo subido, pose sentada, Michi fuera, títulos femeninos), planta alta de la taberna (escalera caminable sin `[E]` y barandilla con colisión), e interfaz/partida (mapa `[M]` en papel cálido con marcador «Tú» en azul cobalto según nota del supervisor, puerta de la taberna con doble carril sin atascos y puesto del pescador en el muelle).
  2. **§3 Fase B del relieve (pueblo):** desniveles suaves por terrazas dentro del pueblo con explanadas horizontales y zócalos de piedra bajo cada edificio y solar.
  3. **§3b Aspecto de la época definitiva:** renombrado a «Alguacil mayor» / «alguacil», Casa de Comidas «El Fogón del Valle» (3 propuestas anotadas), inventos del taller («Radio de onda corta», «Cerradura magnética», «Generador diésel») y 5 elementos físicos 3D de la época con colisión (generador diésel y cables, focos en poste, sacos terreros con alambre de espino, barrotes/planchas remachadas y terminales CRT de fósforo verde).
  4. **§3c Ocultar la historia principal actual:** ocultados los 4 capítulos descartados del bloque PP (marca `# [OCULTO_HISTORIA_PRINCIPAL_PP]`) sin borrar el código.
  5. **§3d Combate nuevo en 1.ª persona (`5a` → `5e`):** cuerpo a cuerpo en 1.ª persona (`5a`), disparo con apuntado/retroceso/heridas graves/ruido (`5b`), recarga manual en 3 pasos y munición diferenciada (`5c`), corazas que paran pistola y fusil lejano con abolladuras forenses reparables (`5d`), y guardias/alguacil/bandidos con las mismas reglas, aviso de alto y recarga real (`5e`).
  6. **Fallos pequeños pendientes de `FALLOS_VISIBLES.md`:** quitado el huerto vecinal del camino junto a Aguas Claras, activada la lectura `[E]` en la Biblioteca del Valle, remodelado el Tablón de Encargos 3D con textos legibles en cada pergamino, y poblado el Rancho del Sur con un rebaño vivo de 8 animales 3D variados que crecen, producen y se venden.
- **Qué falló y se deshizo:** Nada tuvo que deshacerse; todos los pasos y pruebas automáticas quedaron resueltos y verificados en verde.
- **Qué preguntas quedan:** Ninguna pregunta nueva bloqueante; quedan solo las notas de conversación con el usuario en `docs/PREGUNTAS_PENDIENTES.md` (bucle jugable para la primera beta en `docs/PROPUESTA_BETA.md` y elección final entre las 3 propuestas de nombre para la casa de comidas del §3b.4, usando por defecto «Casa de Comidas El Fogón del Valle»).

## MODO NOCHE — Detalle paso a paso (2026-11-08)
- **Nota del supervisor (01:15, leyenda del mapa `[M]`):** cambiado en `ValleyMapUI.gd` el color del marcador y etiqueta «Tú» en el mapa grande `[M]` a azul cobalto para que coincida con `🔵 Tú` de la leyenda.
- **§3 Relieve del terreno — Fase B (pueblo, `WorldStage3D.gd`):** añadidos desniveles suaves por terrazas dentro del pueblo (`_village_terrace_height_px`: calles que suben hacia el barrio norte `+4.2..+9.4 px` y hacia el barrio cívico del este `+3.2..+5.2 px`, Plaza Central ligeramente elevada `+2.4 px` con rampa empedrada y bordillos en sus accesos, y vaguada suave `-1.8 px` hacia los campos del sur), manteniendo cada edificio y solar en una explanada horizontal llana con zócalo de piedra enterrado (`-2.5..0.0 px`) para que nada se incline ni flote. Comprobado en 1.ª persona 3D en `docs/capturas_arreglos/relieve_fase_b_plaza_3d.png`, `docs/capturas_arreglos/relieve_fase_b_este_3d.png` y `docs/capturas_arreglos/relieve_fase_b_norte_3d.png`.
- **§3b Aspecto de la época definitiva (tecnofeudal / medieval-balística):**
  - **Lista corta de elementos de la época (§3b.3 — qué y dónde, con colisión y sin tapar puertas ni caminos):**
    1. **Generador diésel y cables gruesos:** generador de hierro fundido con depósito y escape junto al muro este del Taller de Reparaciones (`Vector2(1316, 126)`, colisión `16 × 22 px`), con mangueras/cables gruesos por las fachadas del taller (`e5`), comisaría (`building_police`) y ayuntamiento (`building_town_hall`).
    2. **Focos en poste de madera (`SpotLight3D`):** en la esquina noreste de la Comisaría (`Vector2(994, 96)`) y junto al pórtico norte del Puesto del Paso (`Vector2(1538, 18)`), encendidos de noche y apagados si se sabotea la red eléctrica (`VillageCulture.is_lamps_powered`).
    3. **Sacos terreros y alambre de espino:** parapetados a ambos lados de la fachada norte de la Comisaría (`Vector2(864, 92)` y `Vector2(966, 92)`, dejando libre el corredor de la puerta `x = 893..937`) y flanqueando la barrera del Puesto del Paso (`Vector2(1528, 22)` y `Vector2(1528, 78)`, dejando libre el camino `y = 34..66`).
    4. **Barrotes y planchas remachadas:** rejas de hierro y chapas de acero remachado en las ventanas bajas de la Comisaría (`building_police`) y del Ayuntamiento (`building_town_hall`).
    5. **Terminales de pantalla verde (CRT fósforo verde):** sobre el escritorio de la Comisaría (`Vector2(933, 130)`), en una mesa lateral del Ayuntamiento (`Vector2(718, -442)`) y en la consola del Taller (`Vector2(1188, 122)`), todas operables con `[E]`.
  - **3 propuestas de nombre para la casa de comidas del valle (§3b.4):** 1) **«Casa de Comidas El Fogón del Valle»** (usado por defecto), 2) **«Figón La Caldera»**, 3) **«Mesón del Arroyo»**. Platos cambiados a «Guiso de Trigo y Hogaza» y «Asado de Caza al Fuego».
  - **Inventos del taller (§3b.5):** renombrados a «Radio de onda corta», «Cerradura magnética» y «Generador diésel». Cargo policial renombrado a «Alguacil mayor» / «alguacil» (§3b.1).
- **§3c Ocultar la historia principal actual (`VillageCulture.gd`, `QuestLogUI.gd`):** ocultados sin borrar el código (marca `# [OCULTO_HISTORIA_PRINCIPAL_PP]` y constante `MAIN_STORY_PP_HIDDEN = true`) los 4 capítulos descartados del bloque PP: ocultada la pestaña «Principal» en `[L]`, desactivado el avance y pago de recompensas en el ciclo diario y retiradas sus opciones de diálogo. Comprobado en `docs/capturas_arreglos/ocultar_historia_3c_panel_l.png`.
- **§3d Combate nuevo — Paso 5a (cuerpo a cuerpo en 1.ª persona, `PlayerCombatController.gd`, `Player.gd`, `WorldStage3D.gd`, `CombatFeel.gd`, `CharacterAvatar3D.gd`):** añadido modelo 3D de brazos y manos en 1.ª persona anclado a la cámara con mallas diferenciadas para cada arma equipada, fases claras de golpe (`windup`, `active`, `recovery`, `shove`), estela luminosa de tajo 3D, chispas de impacto 3D sobre el rival, retroceso visible del cuerpo del vecino golpeado y sacudida/viñeta roja al recibir un golpe o bloquear. Comprobado en `docs/capturas_arreglos/combate_5a_golpe_dado_3d.png` y `docs/capturas_arreglos/combate_5a_golpe_recibido_3d.png`.
- **§3d Combate nuevo — Paso 5b (disparar en 1.ª persona, `PlayerCombatController.gd`, `Player.gd`, `PlayerMovementController.gd`, `ArrowProjectile.gd`, `DamageData.gd`, `HealthComponent.gd`, `WorldStage3D.gd`):** añadido apuntado manteniendo clic derecho (acerca el arma al centro con mira, reduce la velocidad al andar y estrecha el campo de visión `70 -> 55`), desvío fuerte al disparar sin apuntar (`±0.22 rad`) frente a precisión apuntando (`±0.008 rad`), retroceso real que levanta la mira hacia arriba y fogonazo 3D (`notify_fp_firearm_shot`), heridas graves por bala (hemorragia severa + fractura ósea en la zona alcanzada, sesgando el impacto hacia torso y cabeza al apuntar) y estruendo (`420 px`) que asusta a los vecinos y atrae a los guardias. Comprobado en `docs/capturas_arreglos/combate_5b_disparo_3d.png`.
- **§3d Combate nuevo — Paso 5c (recarga y munición diferenciada, `PlayerCombatController.gd`, `WorldStage3D.gd`, `SimpleInventory.gd`, `VillageCulture.gd`):** añadida recarga manual lenta en 3 pasos visibles en las manos en 1.ª persona con `[R]` (`1/3 · Sacando cargador…`, `2/3 · Insertando cargador…`, `3/3 · Montando cerrojo…`) que se cancela y se pierde si te golpean, corres o ruedas a mitad, y munición diferenciada para pistola (`pistol_ammo` / `powder_charge`) y fusil (`rifle_ammo` para `assault_rifle`), con registro de venta nominal (`ammo_sales_log`) en la armería/taller o robo furtivo (`steal_armory_ammo`). Comprobado en `docs/capturas_arreglos/combate_5c_recarga_3d.png`.
- **§3d Combate nuevo — Paso 5d (corazas y balas, `HealthComponent.gd`, `WeaponWear.gd`, `WorldStage3D.gd`):** las corazas metálicas (`chest` tier >= 2, de jugador o guardia/alguacil/inquisidor) detienen las balas de pistola y los disparos de fusil a distancia (`>= 95 px`, convirtiéndolos en contusión amortiguada sin sangrado), pero son perforadas por el fusil de cerca (`< 95 px`); cada impacto deja una abolladura (`armor_dents` y `armor_dent_log`) que sirve de pista forense en las autopsias y que el herrero desabolla en el yunque (`weapon_wear_repair_dents`). Además, el casco medieval (`head` tier >= 2) amortigua en parte los disparos a la cabeza (`×0.42`). Comprobado en `docs/capturas_arreglos/combate_5d_coraza_3d.png`.
- **§3d Combate nuevo — Paso 5e (los rivales con las mismas reglas, `VillageNPC.gd`, `Raider.gd`, `CharacterAvatar3D.gd`, `CharacterRig3D.gd`):** el alguacil mayor, el investigador real y los guardias en alerta alta o en el Puesto del Paso llevan fusil policial largo en 3D (`carries_police_rifle()`), mientras que los guardias de patrulla ordinaria llevan pistola y ningún vecino común lleva armas de fuego; antes de abrir fuego dan el alto («✋ ¡Alto en nombre de la ley o disparo!») con margen de `0.90 s` para entregarse o cubrirse; gastan cargador real de `5` balas y se detienen a recargar en 3 pasos (`2.25 s`, interrumpibles si los golpeas o desarmas); y los bandidos de incursión (`Raider.gd`) disparan carabinas viejas de 2 tiros con poca puntería y recarga lenta (`2.6 s`). Comprobado en `docs/capturas_arreglos/combate_5e_guardia_fusil_3d.png`.
- **Paso 6 — Cuatro fallos pequeños pendientes de `FALLOS_VISIBLES.md` (`VillageLots.gd`, `VillageCulture.gd`, `InteractionSelector.gd`, `WorldStage3D.gd`, `VillageHousing.gd`, `LivestockAnimal.gd`, `AnimalModel3D.gd`):** (1) retirado el «Huerto vecinal» del camino junto a la Residencia Aguas Claras; (2) añadida el área interactiva `LibraryReadingArea` en el atril de la Biblioteca del Valle con su tarjeta `[E] Leer un rato en la biblioteca` y ganancia de experiencia diaria en español (`docs/capturas_arreglos/fix_biblioteca_leer_3d.png`); (3) remodelado el Tablón de Encargos 3D en la Plaza con basamentos de piedra, marco de roble, tejadillo, cabecera «ENCARGOS DEL VALLE» y 3 hojas de pergamino con sello de lacre y texto legible desde fuera para los encargos de Gremios, Hospital y Alguacil (`docs/capturas_arreglos/fix_tablon_encargos_3d.png`); y (4) ampliado el corral del Rancho del Sur con abrevadero y pacas de heno y poblado con un rebaño vivo de 8 animales 3D (`vaca`, `toro`, `2 ovejas/alpacas`, `burro`, `caballo` y `2 gallos/gallinas`) con proporción natural en 1.ª persona y ciclo diario de cría, esquileo/ordeño, venta al madurar y reposición (`docs/capturas_arreglos/fix_rancho_rebano_3d.png`).

---

## Actualización rápida (2026-11-08 — «Ritmo y alcance»): 5 entradas de `FALLOS_VISIBLES.md` (Relieve Fase A suave, Taberna pisos 0 y +1, e Interfaz/Puerta/Pescador)
- **1 y 5. Relieve de la Fase A mucho más suave y revisión del lago/llanura (`WorldStage3D.gd`, `FishingSpot.gd`, `InteractionSelector.gd`):** sustituidos los montículos gaussianos por ondulaciones anchas de baja frecuencia (`< 10°`), allanados los caminos exteriores (`_road_flat_mask`) y todos los solares/edificios/caseríos (`0.0 px`), remodelado el bloque `weak_wall`, suavizadas las orillas del arroyo/ciénaga y ampliado el Lago del Oeste con orillas de hierba/juncos, muelle a ras del agua con su tarjeta `[E]` específica y aviso de 1.ª persona sin corte `…`. Comprobado en `docs/capturas_arreglos/relieve_fase_a_suave_lago_3d.png` y `docs/capturas_arreglos/relieve_fase_a_suave_lomas_3d.png` (`ee8db8b`).
- **2. Taberna Planta 0 (`VillageTavern.gd`, `CharacterAvatar3D.gd`, `CharacterRig3D.gd`, `VillageNPC.gd`, `VillageManager.gd`, `DomesticPet.gd`, `VillageUnderworld.gd`, `InteractionSelector.gd`):** subida la cota de suelo interior (`+2.95 px` en taberna, `+2.65 px` en otros interiores) para que nadie hunda los pies; activada pose sentada (`Sitting_Idle_Loop`) en las sillas de mesas; movido `Michi` y su cama al patio exterior; añadido `feminize_role_title` («Posadera», « Panadera», etc.) y bloqueada la selección de rejilla de alcantarilla desde dentro. Comprobado en `docs/capturas_arreglos/fix_taberna_planta0_3d.png` (`cd45038`).
- **3. Taberna, segundo piso (`VillageTavern.gd`, `WorldStage3D.gd`, `VillageManager.gd`, `InteractionSelector.gd`, `CharacterAvatar3D.gd`):** quitado `[E]` de la escalera interior y despejado el tabique en `x = 560..604` para subir y bajar andando con rampa continua (`2.95..22.55 px`); añadida colisión sólida (`tavern_upper_walls`) a la barandilla del balcón/galería y hueco de escalera, más caída automática a Planta 0 fuera del forjado superior. Comprobado en `docs/capturas_arreglos/fix_taberna_piso2_3d.png` (`cd45038`).
- **4. Partida del usuario tras la interfaz nueva (`ValleyMapUI.gd`, `WorldStage3D.gd`, `InteractionSelector.gd`, `scenes/ui_root.gd`, `VillageManager.gd`, `VillageNPC.gd`):** pasado el mapa grande `[M]` a pergamino cálido `#f1e8d4` y tinta `#26211b` con etiquetas sobre su sitio real («Lago del Oeste» en `(-1035, 165)`); quitados en 1.ª persona el aviso `[E]` flotante central duplicado y la línea superior sobre el reloj (pasada a `[H]`); eliminadas las tiras rojas flotantes `banner-red.glb`; separados los carriles de entrada y salida (`±5 px`) sin empuje lateral en el umbral de la puerta de la taberna (comprobado con 6 vecinos entrando y saliendo a la vez a las 12:39: `6/6` cruzan sin atasco); y movido el puesto de pesca del pescador al muelle del Lago del Oeste `(-683, 105)`. Comprobado en `docs/capturas_arreglos/fix_mapa_m_papel_3d.png` y `docs/capturas_arreglos/fix_puerta_taberna_vecinos_3d.png`.

---

## Actualización rápida (2026-11-07 noche — «Ritmo y alcance»): 5 detalles de interfaz + Relieve Fase A (fuera del pueblo)
- **5 detalles de «Revisión de Claude a la interfaz nueva» (`docs/FALLOS_VISIBLES.md:101-106`):** ocultada la etiqueta de nombre sobre vecinos que no están frente al jugador; quitados el contorno amarillo del vecino apuntado y la lista flotante encima del cuerpo; limpiados de inglés, `HP` y coordenadas los bocadillos/avisos/carteles; y reubicados los avisos flotantes (`FloatingText`) sobre la barra de herramientas para que no tapen la tarjeta de `[E]`. Comprobado en 3D (`docs/capturas_arreglos/ui_after_plaza_3d.png`) y subido en `e6c0e92`.
- **Relieve del terreno — Fase A (fuera del pueblo, `scripts/visuals/WorldStage3D.gd`, `scripts/visuals/AnimalModel3D.gd`, `scripts/systems/ai/EnemyAI.gd`):** terreno 3D continuo con lomas en la llanura, colinas y hondonadas en el bosque, y cuencas hundidas con orilla en pendiente en el lago del Oeste y la ciénaga del Sur, manteniendo planos el pueblo, el campamento/huerto/gallinero del jugador, la granja/rancho, la cantera y el Puesto del Paso. Vecinos, animales, carros, caravanas, jugador, árboles, rocas, hierbas, setas, madrigueras, objetos tirados y caminos exteriores siguen la altura del suelo sin flotar ni hundirse.
- **Comprobado en 3 capturas 3D (`docs/capturas_arreglos/relieve_fase_a_llanura_3d.png`, `relieve_fase_a_bosque_3d.png`, `relieve_fase_a_lago_cienaga_3d.png`):** se ven las lomas doradas y verdes sin cuadrícula mirando hacia el pueblo plano (`relieve_fase_a_llanura_3d.png`), los desniveles del bosque con árboles, arbustos y hierbas medicinales 3D apoyados en la ladera (`relieve_fase_a_bosque_3d.png`), y la orilla en cuesta del lago con su rampa al muelle y dos vecinos subiendo por el camino de la colina (`relieve_fase_a_lago_cienaga_3d.png`). Paramos aquí para revisar Fase A antes de pasar a Fase B.

---

## Encargo anterior: 2 pendientes de `FALLOS_VISIBLES.md` (farola frente a puerta de taberna y niebla a franjas) + Punto 1 (`Modo pruebas [F8]`) y Punto 2 (`Interfaz nueva en partida`) de `docs/ENCARGO_SIGUIENTE.md`

### 0. Dos pendientes de `docs/FALLOS_VISIBLES.md` (antes de la cola)

#### 0.1. Farola delante de la puerta de la taberna y revisión de choques frente a puertas
- **Causa real encontrada en el código:**
  - En `scripts/systems/VillageWorldBuilder.gd:519`, una farola (`_spawn_streetlight`) estaba situada en `Vector2(466, -118)`, justo delante de la puerta de la Taberna (`Rect2(436, -138, 36, 12)`, centro X = `454`), bloqueando la línea de salida hacia `OUTSIDE_APPROACH = Vector2(454, -116)`.
  - Además, en `scripts/systems/VillageManager.gd` (`PASADA 1` de `_build_nav_waypoints`), el radio para redirigir destinos desde el interior de un edificio a su puerta era `22.0 px`, de modo que cuando un vecino salía a `OUTSIDE_APPROACH` (a `16 px` de la puerta) la ruta lo devolvía de nuevo hacia `DOOR_POS`, provocando oscilación en el umbral.
- **Solución aplicada (`VillageWorldBuilder.gd`, `VillageTavern.gd`, `VillageManager.gd`, `VillageNPC.gd`):**
  - Movida la farola de `Vector2(466, -118)` a `Vector2(396, -118)` (a la izquierda de la fachada sur, lejos de la puerta `x = 454`).
  - Ajustados `DOOR_POS = Vector2(454.0, -132.0)` y `OUTSIDE_APPROACH = Vector2(454.0, -116.0)` en `VillageTavern.gd`.
  - Reducido a `12.0 px` el umbral de `PASADA 1` en `VillageManager.gd` y ampliado a `10.0 px` el radio de llegada a waypoints en `VillageNPC.gd:2945`.
  - Añadidos `_is_prop_collider_blocking_passage(pos, size)` y `_prune_door_blocking_prop_colliders()` en `VillageManager.gd` para garantizar que ningún colisionador de mueble, farola o decoración invada una caja de `22 × 24 px` alrededor de ninguna puerta exterior ni paso interior del juego.
- **Comprobado visualmente en capturas (`docs/capturas_arreglos/fix0_tavern_door_night_2d.png`, `fix0_tavern_door_night_3d.png`):**
  - El acceso frente a la puerta doble de la Taberna (`x = 454, y = -132..-116`) está completamente libre de obstáculos tanto en 2D como en 3D; la farola luce encendida a la izquierda de la fachada (`x = 396`) sin estorbar el paso.

#### 0.2. Niebla que se veía a franjas horizontales (de día y de noche)
- **Causa real encontrada en el código:**
  - En `scripts/World.gd:201-205` (`_draw_weather_overlay`), cuando `WorldClock.current_weather == Weather.FOG` (`2`), se dibujaban literalmente 6 rectángulos horizontales (`for band in range(6): draw_rect(...)`) que cruzaban toda la pantalla como franjas.
- **Solución aplicada (`scripts/World.gd`, `shaders/retro_post_fx.gdshader`, `scripts/visuals/RetroPostFX.gd`):**
  - Eliminado el bucle de las 6 bandas rectangulares en `scripts/World.gd`.
  - Conectado el estado de niebla meteorológica (`weather_fog`) al shader de pantalla completa `shaders/retro_post_fx.gdshader` (`RetroPostFX.gd`), que aplica una caída radial continua alrededor del jugador combinada con ruido FBM rotado de 3 octavas sin direcciones privilegiadas ni bandas horizontales, respetando además los halos cálidos de farolas y faroles de noche y desactivándose bajo techo.
- **Comprobado visualmente en capturas (`fix0_tavern_door_night_2d.png`, `fix0_tavern_door_night_3d.png` a las 00:37 y `fix0_fog_day_2d.png`, `fix0_fog_day_3d.png` a las 08:14):**
  - Tanto de noche como de día, en 2D y en 3D, la bruma es suave, orgánica y radial, sin una sola franja horizontal.

---

### 1. Punto 1 de `docs/ENCARGO_SIGUIENTE.md`: Modo pruebas del jugador (`[F8]`)
- **Tecla asignada:** **`F8`** (activa y desactiva al instante en partida).
- **Comportamiento implementado (`scripts/Player.gd`, `scripts/systems/SimpleInventory.gd`, `scripts/systems/combat/HealthComponent.gd`, `scripts/systems/combat/StaminaComponent.gd`, `scripts/systems/combat/SurvivalComponent.gd`, `scenes/ui_root.gd`):**
  - Empieza **desactivado** (`test_mode_active = false`) y **no se guarda** en la partida (`to_save_dict()` omite `test_mode_active` y guarda el oro real previo `_pre_test_mode_gold`; `from_save_dict()` lo desactiva si estaba encendido).
  - Mientras está activo:
    - **Vida infinita:** `HealthComponent.take_damage()` e infecciones/venenos/desangrado ignoran el daño al jugador y mantienen su salud al máximo.
    - **Energía infinita:** `StaminaComponent.use_stamina()` devuelve `true` sin restar energía.
    - **Hambre, sueño e higiene fijos al 100 %:** `SurvivalComponent._process()` los mantiene al máximo sin bajar.
    - **Oro infinito (`9999`):** `SimpleInventory.set_test_mode_infinite_gold(true)` fija el oro en `9999` y bloquea cualquier descuento al comprar o gastar; al desactivar `F8`, restaura el oro exacto que tenía el jugador antes de activar el modo pruebas.
      - *Nota de economía:* tal como advirtió el supervisor, el oro infinito en modo pruebas rompe deliberadamente la suma cero mientras está activo; es exclusivamente para pruebas del jugador.
    - **Reacciones intactas de los vecinos:** testigos, denuncias, alarmas, persecuciones e investigaciones funcionan exactamente igual.
    - **Aviso fijo en pantalla:** placa roja **`MODO PRUEBAS`** visible justo debajo del reloj central mientras esté activo.
- **Comprobado visualmente y en pruebas:**
  - Capturas revisadas en 2D y 3D con el modo activo: `docs/capturas_arreglos/test_mode_2d.png` y `docs/capturas_arreglos/test_mode_3d.png` (se ve la placa roja `MODO PRUEBAS` bajo el reloj y `9999 oro` abajo a la derecha).
  - Prueba automática `Block TM1` en `tools/tests/verify_all.gd`: verifica arranque desactivado, activación con `set_test_mode(true)`, inmunidad al daño/sangrado/intoxicación, gasto de energía sin bajada, hambre/sueño fijos, gasto de oro sin bajada, no persistencia en `to_save_dict()`, y restauración del comportamiento normal tras `set_test_mode(false)`.

---

### 2. Punto 2 de `docs/ENCARGO_SIGUIENTE.md`: Interfaz nueva en partida (papel y tinta) y limpieza de letreros flotantes
- **Implementación fiel a `docs/bocetos/interfaz_juego.html` (`scenes/ui_root.gd`, `scripts/ui/InteractionSelector.gd`, `scripts/ui/ValleyMapUI.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/systems/VillageManager.gd`, `scripts/obstacles/HarvestableNode.gd`, `scenes/ui/FloatingText.gd`):**
  1. **Arriba a la izquierda (barras de papel y tinta):**
     - Barras de **Vida** (`❤`, `#b5473f`) y **Energía** (`⚡`, `#6f9a5a`) siempre visibles con etiqueta de papel (`#f1e8d4`) y borde de tinta (`#3a3228`).
     - Barras de **Hambre** (`🍞`, `#c98a3c`) y **Sueño** (`☾`, `#5f7fa6`) ocultas cuando están altas y visibles automáticamente cuando bajan del `75 %` (e higiene `< 65 %`, sangrado/aturdimiento `> 0.5`).
  2. **Arriba al centro (placa de reloj + `MODO PRUEBAS`):**
     - Placa pequeña de papel centrada (`☀ Lunes · 14:22 despejado`), mostrando la etiqueta de velocidad (`×2`, `×4`, `×8`) únicamente cuando no es `×1`, y la placa roja `MODO PRUEBAS` debajo cuando `F8` está activo.
  3. **Arriba a la derecha (minimapa redondo de papel):**
     - Minimapa circular de `118 × 118 px` en `ValleyMapUI.gd` con fondo de pergamino, borde doble de tinta, caminos, edificios, río/lago, vecinos, punto cardinal `N` y etiqueta inferior `Valle · [M] mapa`.
  4. **Izquierda bajo las barras (avisos breves / toasts):**
     - Contenedor `ToastBox` con hasta **3 avisos breves** en tiras de papel que se desvanecen solos y llevan borde izquierdo rojo (`#8f2d26`) cuando son graves (p. ej. hallazgo de cadáver o delito).
  5. **Abajo al centro (tarjeta de papel de `[E]`):**
     - `InteractionPromptCard` con el nombre del objetivo (`Marta`), estado corto (`Muerto`, `Trabajando`, `Con llave`), contador `1/N · Mayús+rueda o G`, filas de acciones (`[E] Examinar el cuerpo de Marta`, `· Registrar bolsillo (41 oro, objetos)`, `· Denunciar hallazgo al alguacil`) y pie explicativo (`Rueda o G: cambiar acción o vecino cercano`).
  6. **Abajo a la izquierda y abajo a la derecha:**
     - Abajo a la izquierda: **3 casillas de mano** (`1`, `2`, `3`) en tarjetas de papel con borde ocre en la herramienta activa.
     - Abajo a la derecha: placa de **oro** (`45 oro`) + botón **`[H] teclas`** que abre/cierra el cuadro modal de papel con todas las teclas (`[U]` abre el panel médico).
  7. **Limpieza total de letreros flotantes en el mundo (`FALLOS_VISIBLES.md` línea 92):**
     - Con varios vecinos y cadáveres juntos, **únicamente el objetivo enfocado** muestra una etiqueta corta (`Marta · Muerto` o `Bram · Trabajando`); el resto de cadáveres o caídos cercanos muestran solo un icono pequeño (`☠`, `🩸`, `💤`, `💫`).
     - Las acciones de `[E]` ya nunca flotan sobre los cuerpos ni sobre los puestos del mundo: aparecen solo en la tarjeta de papel inferior.
     - Las barras de progreso de trabajo/pulso y los bocadillos cortos (`FloatingText.gd`) usan escala compacta con pastilla de tinta y se ocultan o desplazan si hay otro vecino enfocado o hablando al lado, evitando que se monten jamás.
- **Comprobado visualmente en capturas (todas inspeccionadas con `read_file` en `docs/capturas_arreglos/`):**
  - **Antes (plaza con vecinos y cadáveres):** `ui_before_plaza_2d.png` y `ui_before_plaza_3d.png`.
  - **Después (misma escena en 2D y 3D):** `ui_after_plaza_2d.png` y `ui_after_plaza_3d.png` (se ven las 4 barras de vida/energía/hambre/sueño, los 3 avisos breves a la izquierda, el reloj centrado, el minimapa redondo a la derecha, las 3 manos abajo a la izquierda, la tarjeta de `[E]` abajo al centro, `45 oro` + `[H] teclas` abajo a la derecha, y en la plaza solo `Marta · Muerto` con `☠` en los demás cuerpos).
  - **Comprobación en 3 resoluciones sin cortes ni solapes:** `ui_res_1280x720.png` (`1280×720`), `ui_res_1920x1080.png` (`1920×1080`) y `ui_res_2560x1440.png` (`2560×1440`).
  - **Ayuda de teclas `[H]`:** `ui_controls_modal_2d.png`.
- **Comprobado en pruebas automáticas:**
  - Arranque limpio (`--quit-after 3`): `EXIT_CODE=0`, cero errores de script.
  - Suite completa `verify_all.gd` (`timeout 900`): `EXIT_CODE=0` (`Block TM1 OK`, `Block UI2 OK`, `ALL ... TESTS PASSED!`).

---

## Encargo anterior: Corrección de los 11 bloques de fallos visibles detectados en partida (`docs/FALLOS_VISIBLES.md`, 2026-11-07)

Se han corregido los **11 fallos visibles** en el orden indicado, sin tocar los edificios de `docs/BOCETOS_EDIFICIOS.md` ni el relieve del terreno. Para cada arreglo se generaron y revisaron visualmente (`read_file`) capturas reales en **2D** y en **3D** (de día y, cuando aplica, también de noche).

---

### 1. VECINOS FUERA DE SITIO (picando piedra delante de la herrería, cosechando/cuidando ganado en la plaza, talando/guisando/remendando en el parque, guisando en el muelle del lago)
- **Causa real encontrada en el código:**
  1. En `scripts/systems/VillageWorldBuilder.gd` (bucle de creación de oficios secundarios `role_id >= 14`: `BAKER`, `TAILOR`, `LODGEKEEPER`, `FARMER`, `RANCHER`, `STONECUTTER`, `WOODCUTTER`, `TINKER`, `RESTAURATEUR`) y en `scripts/systems/VillageManager.gd::_try_fill_vacant_trade_roles`, el código leía `cfg.get("shop_center", Vector2.ZERO)` para calcular `work_pos` y `bed_pos`. Pero en `VillageTrades.CONFIGS`, esos 9 oficios definen `"work_pos"` y `"bed_pos"`, **no** `"shop_center"`. Por ello `sc` valía `(0, 0)` y caían en las posiciones de respaldo antiguas: el cantero (`STONECUTTER`) delante de la herrería `(305, 18)`, el leñador (`WOODCUTTER`), el arreglador (`TINKER`) y la posadera (`LODGEKEEPER`) dentro del Parque del Roble `(268..340, 226)`, y el cocinero (`RESTAURATEUR`) en el antiguo emplazamiento del lago.
  2. Además, en `scripts/enemies/VillageNPC.gd` (línea 1300), `_is_primary_artisan_workshop_role()` incluía los 9 oficios de `VillageTrades` antes de `VillageWork.is_laborer(self)`, haciendo que ejecutaran `_process_artisan_workshop_crafting_and_supply_runs` en la coordenada errónea en vez de `VillageWork.tick_laborer`.
  3. En `scripts/systems/VillageWork.gd`, los puntos de recolección `GATHER_SPOTS["farmer"]` (`Vector2(510, 62)`), `RANCH_SPOTS` y `WOOD_SPOTS` seguían apuntando a la Plaza Central o al interior de la Granja en vez de los surcos de la Granja del Sur (`s1`/`s2`), el corral vallado del Rancho del Sur (`x = 310..397, y = 400..540`) y el lindero de la Serrería (`s3`).
- **Solución aplicada (`VillageWorldBuilder.gd`, `VillageManager.gd`, `VillageNPC.gd`, `VillageWork.gd`):**
  - `VillageWorldBuilder.gd` y `VillageManager.gd::_try_fill_vacant_trade_roles` usan ahora directamente `cfg["work_pos"]` y `cfg["bed_pos"]` de `VillageTrades.CONFIGS`, sincronizados con las posiciones reales de los solares construidos en `VillageLots`.
  - Actualizados todos los `work_pos`, `GATHER_SPOTS`, `QUARRY_SPOTS`, `FARM_SPOTS`, `RANCH_SPOTS`, `WOOD_SPOTS` y `RESTAURANT_SPOTS` a las posiciones reales tras los Pasos 2 y 3: Cantera `(-167, -330)`, Granja `(-157, 470)`, Rancho `(354, 470)`, Serrería `(-348, 570)`, Taller de Reparaciones `(1230, 122)`, Posada del Camino `(1230, -18)` y Cocina de la Trattoria `(3, -102)`.
- **Qué se ve en las capturas 2D y 3D revisadas (`fix1_smith_2d/3d.png`, `fix1_plaza_2d/3d.png`, `fix1_park_2d/3d.png`, `fix1_dock_2d/3d.png`, `fix1_quarry_2d/3d.png`, `fix1_farm_2d/3d.png`, `fix1_ranch_2d/3d.png`):**
  - Delante de la herrería, en la Plaza Central, dentro del Parque del Roble y sobre el muelle del Lago del Oeste **ya no hay nadie picando piedra, cosechando, cuidando ganado, talando, remendando ni guisando**.
  - En la Cantera `(-167, -330)` se ve al cantero con su barra `⛏️ Picando piedra`; en la Granja del Sur `(-157, 470)` al granjero con `🌾 Segando Trigo`; en el corral del Rancho `(354, 470)` al ganadero con `🐑 Esquilando Lana`; y dentro de la cocina de «Il Corvo» `(3, -102)` al cocinero con `🍝 Amasando la pasta`.

---

### 2. VECINOS ATASCADOS DE NOCHE (día 2, 01:49, con lluvia, en el callejón entre la taberna y la herrería; Nora sin llegar a casa)
- **Causa real encontrada en el código:**
  1. En `scripts/systems/VillageTavern.gd::route`, la condición para decidir si un vecino o su destino estaban «dentro de la taberna» usaba `RECT.grow(4.0)` y, cuando el vecino caminaba por el callejón sur (`y = -132..-74`), ciertos recados o paseos lo desviaban hacia `OUTSIDE_APPROACH = (455, -124)` pegado al muro sur de la taberna de 2 pisos; además, si un vecino quedaba en el borde interior de la taberna sin etiqueta de sala, `room_at` devolvía `""` y no lo sacaba por la puerta sur (`DOOR_POS = (455, -132)`).
  2. En `scripts/systems/VillageNeeds.gd::on_hour`, los paseos nocturnos (`"night_stroll"`) iniciados a las `22:00–23:00` no terminaban a la `01:00`, dejando vecinos deambulando de madrugada por el callejón.
  3. En `scripts/enemies/VillageNPC.gd`, los vecinos que volvían a dormir a casa de madrugada se detenían a iniciar charlas sociales al cruzarse en el callejón estrecho.
- **Solución aplicada (`VillageTavern.gd`, `VillageNeeds.gd`, `VillageNPC.gd`):**
  - `VillageTavern.route` separa limpiamente interior (`RECT.grow(-2.0)`) y exterior (`OUTSIDE_APPROACH = Vector2(455, -116)` en mitad de la calle despejada) y garantiza que cualquier vecino dentro de `RECT` cuyo destino esté fuera salga siempre por `HALL_SOUTH -> DOOR_POS -> OUTSIDE_APPROACH`.
  - En `VillageNPC.gd::_move_towards_point` se añadió rodeo lateral automático ante bloqueos en esquinas de muros y se desactivaron las paradas de charla social cuando el vecino va camino de su cama en horario de sueño. En `VillageNeeds.gd`, `"night_stroll"` concluye a partir de la `01:00` para que se retiren a dormir.
- **Qué se ve en las capturas 2D y 3D nocturnas revisadas (`fix2_alley_night_2d.png`, `fix2_alley_night_3d.png`, tomadas a la 01:49 con lluvia):**
  - El callejón entre la taberna (`y = -132`) y la herrería (`y = -74`) está completamente despejado tanto en 2D como en 3D bajo la lluvia nocturna; no hay vecinos apelotonados ni atascados contra los muros, y Nora duerme en su cama de la Residencia Aguas Claras `(905, -36)`.

---

### 3. CLUB DE PELEAS (sótano debajo de la taberna, entrada/salida solo por trampilla/escalera, trampilla abierta de noche y visible en partida)
- **Causa real encontrada en el código:**
  1. `VillageClub.CELLAR_CENTER` estaba en `Vector2(165, -224)` (al oeste fuera de la huella de la taberna), por lo que al bajar a planta `-1` el jugador y el minimapa saltaban a otro punto del mapa en vez de estar debajo de la taberna.
  2. En `VillageClub.on_hour` y `tick`, los luchadores y espectadores caminaban directamente a coordenadas del sótano en planta `0` o al cerrarse el club a las `03:00` hacían `end_errand()` desde dentro del sótano, saliendo en planta `0` atravesando los muros de la taberna.
  3. La trampilla `club_trapdoor` (`WorldInteractableProp.gd` y `WorldStage3D.gd`) tenía el mismo aspecto visual cerrada y abierta, por lo que parecía siempre cerrada aunque `VillageClub.is_open_now(vm)` fuera `true` (`21:00–03:00`).
- **Solución aplicada (`VillageClub.gd`, `WorldInteractableProp.gd`, `WorldStage3D.gd`, `VillageNPC.gd`):**
  - Se colocó `CELLAR_CENTER = Vector2(434.0, -224.0)` **exactamente debajo del centro de la taberna** (`Rect2(260, -316, 348, 184)`), con su escalerilla `LADDER_POS = Vector2(516.0, -248.0)` alineada bajo la trampilla de la bodega `TRAPDOOR_POS = Vector2(516.0, -286.0)`.
  - Los vecinos entran caminando hasta `TRAPDOOR_POS` en planta `0`, pasan a planta `-1` (`set_meta("in_club_cellar", true)`, ocultándose en la superficie y mostrándose solo cuando el jugador baja al sótano), y al salir caminan primero hasta `LADDER_POS` en planta `-1`, suben a `TRAPDOOR_POS` en planta `0` y salen por la puerta de la taberna usando `VillageTavern.route`, sin atravesar paredes.
  - Se añadieron gráficos 2D (`ClosedTrapdoor2D` vs. `OpenTrapdoor2D` con hueco oscuro y peldaños de madera) y mallas 3D reactivas en tiempo real (`ClosedTrapdoor3D` vs. `OpenTrapdoor3D` con hojas abiertas a 80°, hueco iluminado con luz cálida y peldaños 3D) que se abren automáticamente de `21:00` a `03:00`.
- **Qué se ve en las capturas 2D y 3D revisadas (día y noche, arriba y en el sótano):**
  - En `fix3_8_9_tavern_day_2d.png` y `fix3_8_9_tavern_day_3d.png` (12:30, de día): la trampilla en la sala de bodega/escalera `(516, -286)` se ve **cerrada** con sus tablas y herrajes.
  - En `fix3_tavern_night_2d.png` y `fix3_tavern_night_3d.png` (22:30, de noche): la trampilla se ve **abierta** en 2D y en 3D (con las hojas levantadas, el hueco oscuro, los peldaños de la escalerilla y el resplandor cálido saliendo del sótano).
  - En `fix3_club_cellar_2d.png` y `fix3_club_cellar_3d.png` (22:30, dentro del sótano en planta `-1`): se ve el sótano de piedra con el ring de cuerdas rojas, las antorchas, los bancos, los dos púgiles peleando dentro del ring, el público alrededor, la escalerilla de salida y el minimapa marcando la misma posición de la taberna.

---

### 4. MUEBLES SIN CHOQUE (mesas, sillas, macetas, barriles, cajas, bancos, etc.)
- **Causa real encontrada en el código:**
  - Las mesas y sillas de la terraza y comedor de la Trattoria (`VillageRestaurant.gd`), las mesas y sillas del salón, casino y habitaciones de la Taberna (`VillageTavern.gd`), los muebles de los edificios nuevos (`VillageLots.gd`) y la mayoría de decoraciones (`_spawn_decor_prop` y `_add_sprite_prop` en `VillageManager.gd`: barriles, cajas, bancos, macetas, estanterías, camas, chimeneas, farolas y letreros) se creaban solo como `Polygon2D` o `Sprite2D` sin cuerpo de colisión físico.
- **Solución aplicada (`VillageManager.gd`, `VillageRestaurant.gd`, `VillageTavern.gd`, `VillageLots.gd`, `VillagePlaces.gd`, `VillageWorldBuilder.gd`, `CampSite.gd`):**
  - Se creó `VillageManager._add_prop_collider(pos, size, floor_group_tag)` que registra formas `RectangleShape2D` en un `StaticBody2D` de mobiliario (`PropCollidersBody`, más cuerpos por planta para el piso `+1` de la taberna), respetando un margen de seguridad de `20 px` alrededor de todas las puertas para no bloquear nunca el paso de vecinos ni del jugador.
  - Se añadieron colisionadores ajustados a todas las mesas y sillas de la terraza y comedor de la Trattoria, mesas/sillas/barra/billar/póker/chimenea/camas de la Taberna, bancos de la plaza/parque/mirador, barriles, cajas, macetas, vallas, farolas, letreros, lápidas del cementerio y elementos del campamento (tienda, hoguera con caldero, tronco-asiento, tendedero).
- **Qué se ve en las capturas 2D y 3D revisadas (`fix4_terrace_collision_2d.png`, `fix4_terrace_collision_3d.png`):**
  - El jugador queda detenido físicamente frente a las mesas y sillas de la terraza de la Trattoria «Il Corvo» sin poder atravesarlas ni meterse dentro de los tableros, mientras el pasillo central hacia la puerta de la trattoria permanece libre para caminar.

---

### 5. CEMENTERIO EN 2D Y 3D (más grande, filas de tumbas, caminos, verja y árboles, sin los dos bloques enormes de piedra)
- **Causa real encontrada en el código:**
  - En `VillageWorldBuilder.gd::_spawn_church_and_cemetery`, el cementerio 2D seguía siendo una caja pequeña de `148 × 98 px` con dos rectángulos grises gigantes que ocupaban media parcela y solo 5 lápidas; y en `WorldStage3D.gd::_build_cemetery_3d`, seguían colocándose dos modelos enormes (`crypt.glb` de `24 u` y `altar-stone.glb` de `12 u`) y el tercer modelo de la lista de lápidas (`gravestone-broken.glb`) no existía en disco, dejando 1 de cada 3 tumbas sin lápida 3D.
- **Solución aplicada (`VillageWorldBuilder.gd`, `VillageManager.gd`, `WorldStage3D.gd`):**
  - Se amplió el Cementerio Parroquial a `Rect2(822, 260, 268, 168)` tanto en 2D como en 3D.
  - Se eliminaron por completo los dos bloques de piedra enormes en 2D y en 3D (`crypt.glb` y `altar-stone.glb`).
  - Se construyeron paseos de losas de piedra en cruz (`x = 888` y `y = 344`), verja perimetral de murete de piedra y reja de hierro forjado con colisión física (dejando abierta la entrada oeste en `(822, 344)`), **24 tumbas completas organizadas en 4 filas × 6 columnas** (cada una con bordillo de piedra, túmulo de tierra, lápida o cruz en la cabecera —usando `gravestone-round.glb`, `gravestone-decorative.glb`, `gravestone-wide.glb`, `gravestone-cross.glb`, `gravestone-cross-large.glb`, `cross-wood.glb` y `cross-column.glb`— y flores al pie, tanto en 2D como en 3D) y **6 pinos perimetrales**.
- **Qué se ve en las capturas 2D y 3D revisadas (`fix5_cemetery_2d.png`, `fix5_cemetery_3d.png`):**
  - En **2D (`fix5_cemetery_2d.png`)**: se ve un recinto amplio rodeado por su verja de piedra y hierro y 6 pinos, dividido por caminos de losas en cruz y con las 24 tumbas alineadas en 4 filas × 6 columnas (con su lápida/cruz, tierra y flores), sin los dos bloques grises gigantes.
  - En **3D (`fix5_cemetery_3d.png`)**: se ve exactamente la misma disposición con murete de piedra y reja de forja 3D, caminos de losas, las 24 tumbas con sus 24 lápidas y cruces 3D erguidas y los 6 árboles perimetrales.

---

### 6. COSAS EN 2D PLANO EN EL CAMPAMENTO + DISTANCIA A LA TRATTORIA
- **Causa real encontrada en el código:**
  1. Tras mover la Trattoria a `x = -255` en el Paso 2, el campamento en `x = -532` quedaba a ~250 px del borde oeste de la Trattoria.
  2. En `scenes/World.tscn`, las capas `Environment/Obstacles Small` y `Environment/Obstacles Large` conservaban celdas de tiles 2D antiguos (cajas flotando sobre el agua del lago y un tendedero 2D suelto), y el NPC `Guia` (`scenes/npc.gd`) usaba un sprite morado placeholder de murciélago (`bat_fixed.png` a escala `1.79` —el «objeto morado tirado»—) sin avatar 3D.
  3. En `WorldStage3D.gd::_make_prop_3d`, `"tent"` e `"campfire"` dependían de un `.obj` plano que no cubría la lona/caldero/tronco, y faltaban constructores 3D para `"log_seat"`, `"clothesline"`, `"weapon_sword"`, `"sign"` y las camas de mascotas `PetBed_*`; además, los polígonos 2D de la tienda, hoguera y tronco en `CampSite.gd` no se ocultaban cuando el modo 3D estaba activo.
- **Solución aplicada (`scripts/World.gd`, `scenes/World.tscn`, `CampSite.gd`, `FishingSpot.gd`, `VillagePlaces.gd`, `VillageWorldBuilder.gd`, `VillageManager.gd`, `scenes/npc.gd`, `DummyEnemy.gd`, `DomesticPet.gd`, `WorldStage3D.gd`):**
  - Se desplazó todo el conjunto de **Campamento, Huerto, Gallinero, Compostador, Toby, Espada, Guía, Lago del Oeste y Mirador del Lago `190 px` más al oeste** (`PlayerCampSite` en `(-722, -96)`, `LAKE_NODE_POS` en `(-715, 105)`), dejando **casi `500 px` de campo abierto** entre el campamento y la Trattoria.
  - Se limpiaron las celdas obsoletas de `Obstacles Small` y `Obstacles Large`, se añadió el tendedero del campamento (`ClotheslineSprite` con colisión en `CampSite.gd`) y se reemplazó el sprite morado de `Guia` por `villager_guard.png` en 2D y `CharacterAvatar3D` en 3D (además de modelos 3D para `DummyEnemy.gd` y `DomesticPet.gd`).
  - En `WorldStage3D.gd::_make_prop_3d` y `_sync_props_3d` se construyeron modelos 3D completos para la **tienda de campaña** (tarima de madera, lona triangular a dos aguas, cumbrera, postes, faldones enrollados, saco de dormir con almohada y estacas), **hoguera** (círculo de piedras, leños cruzados, brasas y llamas con luz cálida, trípode de hierro forjado con cadena y caldero con estofado), **tronco-asiento**, **tendedero 3D** (postes, cuerda tensada y 3 prendas 3D tendidas con pinzas, incluida la prenda morada), **espada 3D** (`Sword_Bronze.gltf` sobre taco de madera), **letreros de madera 3D** (`"sign"`) y **camas/cuencos 3D de mascotas** (`PetBed_*`), ocultando todos sus equivalentes 2D planos en modo 3D.
- **Qué se ve en las capturas 2D y 3D revisadas (`fix6_camp_2d.png`, `fix6_camp_3d.png`):**
  - En **2D (`fix6_camp_2d.png`)**: el campamento se ve completo con su tienda, hoguera, tronco, tendedero, espada, perro Toby, compostador, huerto 3×3 y el Guía con sprite de explorador/guardia (sin el murciélago morado tirado), lejos de la Trattoria (como muestra también el minimapa).
  - En **3D (`fix6_camp_3d.png`)**: la tienda de campaña con saco de dormir interior, la hoguera de piedras con fuego, trípode y caldero, el tronco-asiento, el tendedero con ropa colgada en 3D, la espada sobre su bloque de madera, los letreros de madera, la cama y cuenco de Toby, el propio Toby y el Guía se ven **todos en 3D real**, sin ningún elemento plano 2D en el suelo.

---

### 7. CÉSPED (sin cuadrícula repetida de cuadrados y sin el verde menta chillón liso del parque)
- **Causa real encontrada en el código:**
  1. En 3D (`WorldStage3D.gd::GROUND_TERRAIN_SHADER_CODE`), `tex_grass` (`floor_ground_grass.png`, `64×64`) se muestreaba alineado con los ejes X/Z (`w_uv * 0.85` y `w_uv * 3.40`), marcando una cuadrícula repetida de cuadrados en todo el mapa, y la línea `if (blade_rnd > 0.992)` pintaba píxeles cuadrados amarillo fosforito (`vec3(0.94, 0.86, 0.34)`).
  2. En 2D (`scenes/World.tscn`), `Environment/Parallax2D/TextureRect` repetía `grass_background.png` en mosaico directo (`stretch_mode = 1`), dejando ver los bordes cuadrados de cada baldosa.
  3. En el Parque del Roble (`PARK_RECT = Rect2(168, 208, 272, 146)`), `WorldStage3D.gd` ponía una caja sólida sin textura con `m_grass_park = Color(0.24, 0.48, 0.22)` tapando el shader del terreno, y `VillagePlaces.gd` dibujaba un `Polygon2D` verde brillante (`Color(0.30, 0.52, 0.26, 0.55)`) sin caminos interiores.
- **Solución aplicada (`WorldStage3D.gd`, `scripts/World.gd`, `VillagePlaces.gd`):**
  - En `GROUND_TERRAIN_SHADER_CODE` (`WorldStage3D.gd`) se aplicó deformación orgánica de coordenadas (`warp`) y mezcla de 2 proyecciones rotadas (`0.54 rad` y `-0.89 rad`) con ruido multiescala y tonos verdes naturales de pradera (`vec3(0.33, 0.50, 0.24)` / `vec3(0.24, 0.39, 0.18)`), eliminando por completo la cuadrícula y los puntos amarillos chillones.
  - En `scripts/World.gd` se asignó un shader `canvas_item` orgánico multiescala a `Environment/Parallax2D/TextureRect` para que el césped 2D tampoco tenga cuadrícula repetida.
  - En el Parque del Roble (`WorldStage3D.gd` y `VillagePlaces.gd`), se sustituyó la losa lisa verde menta por el shader de césped natural texturizado (`ground_park_sh`), acompañado de sus paseos en cruz de tierra apisonada y bordillo perimetral de piedra tanto en 2D como en 3D.
- **Qué se ve en las capturas 2D y 3D revisadas (`fix7_grass_park_2d.png`, `fix7_grass_park_3d.png`):**
  - Tanto en **2D (`fix7_grass_park_2d.png`)** como en **3D (`fix7_grass_park_3d.png`)**, la hierba general y la del Parque del Roble lucen con variaciones suaves y orgánicas de pradera natural, **sin rastro de cuadrícula de cuadrados ni del color verde menta plano**, y con los caminos en cruz, bordillo de piedra, bancos, macetas y árboles integrados.

---

### 8. APUESTAS EN BUCLE EN LA TABERNA (bocadillos cada 0,2 s en la mesa de póker o billar)
- **Causa real encontrada en el código:**
  - En `scripts/systems/VillageTavern.gd::tick`, el servicio de mesas del camarero (`tick_waiter`) y los bocadillos ambientales de póker/comensales compartían la misma variable estática `_service_timer`. Como `tick_waiter` reiniciaba `_service_timer = 0.25` en cada paso del camarero, el bloque de comentarios de póker se disparaba cada `0,25 s` en bucle continuo.
- **Solución aplicada (`VillageTavern.gd`):**
  - Se separó un temporizador estático independiente `_ambient_timer` (`16.0–24.0 s`) exclusivo para las frases de póker y comedor, dejando `_service_timer` (`0.25 s`) solo para el movimiento del camarero.
- **Qué se ve en las capturas 2D y 3D revisadas (`fix3_8_9_tavern_day_2d.png`, `fix3_8_9_tavern_day_3d.png`, `fix3_tavern_night_2d.png`, `fix3_tavern_night_3d.png`):**
  - Los jugadores sentados a la mesa de póker y los comensales de la taberna conversan de forma espaciada y natural, sin amontonar bocadillos encima de la mesa.

---

### 9. RECTÁNGULO ROJO SEMITRANSPARENTE ENCIMA DE LA TABERNA EN 2D
- **Causa real encontrada en el código:**
  - En `scripts/systems/VillageTavern.gd`, las llamadas a `vm._add_rect_poly(...)` para las alfombras de la taberna (en particular la alfombra roja del casino en `GAMES_POS = (534, -196)`) pasaban el **tamaño completo** pensando que el 2.º parámetro era el tamaño, pero `VillageManager._add_rect_poly(center, half_size, ...)` recibe el **semitamaño** (`half_size`), haciendo el rectángulo el doble de grande (`192 × 140 px`) y desplazado para tapar la mesa de póker y el muro norte.
- **Solución aplicada (`VillageTavern.gd`):**
  - Se corrigieron las llamadas a `_add_rect_poly` en `VillageTavern.gd` pasando el semitamaño real y ajustando la alfombra del casino bajo las mesas de juego (`z_index = -2`).
- **Qué se ve en la captura 2D revisada (`fix3_8_9_tavern_day_2d.png`):**
  - La sala de casino y billar muestra su alfombra encajada limpiamente en el suelo bajo la mesa de póker y la mesa de billar, sin ningún rectángulo rojo transparente invadiendo los muros ni tapando las mesas.

---

### 10. FRANJA ROSA / MORADA SOBRE EL TEJADO DE LA CAPILLA EN 2D
- **Causa real encontrada en el código:**
  - En `scripts/systems/VillageWorldBuilder.gd:389` (`_spawn_church_and_cemetery`), la alfombra púrpura de la nave de la Capilla se creaba en `_church_center + Vector2(0, -2)` con semitamaño `Vector2(18, 34)` (llegando hasta `y = 324 - 36 = 288`, es decir, `10 px` por encima del muro norte de la capilla en `y = 298`).
- **Solución aplicada (`VillageWorldBuilder.gd`, `WorldStage3D.gd`):**
  - Se centró y acortó la alfombra interior de la capilla a `_church_center + Vector2(0, 6)` con semitamaño `Vector2(9, 24)` (`size = Vector2(18, 48)` en 3D), quedando contenida de `y = 306` a `y = 354` dentro de los muros de la nave (`y = 298..374`).
- **Qué se ve en las capturas 2D y 3D revisadas (`fix10_chapel_roof_2d.png`, `fix10_chapel_roof_3d.png`):**
  - En **2D (`fix10_chapel_roof_2d.png`)** y en **3D (`fix10_chapel_roof_3d.png`)**, el muro norte y el tejado de la Capilla de la Fe del Alba están completamente limpios, sin ninguna franja rosa o morada asomando por encima, y la alfombra queda dentro del pasillo central hacia el altar.

---

### 11. LETREROS ENCIMADOS EN LA HERRERÍA («Herrería y Armería Yunque [E]», «Cerrada: el perista vende la llave» y barra de trabajo)
- **Causa real encontrada en el código:**
  1. La rejilla de alcantarilla `smuggler_tunnel` (`Vector2(398, -118)`) ponía su letrero de `InteractionSelector` (`_label.position = pos + Vector2(-110, 8) = Vector2(288, -110)`) **exactamente en la misma coordenada vertical (`y = -110`)** que el título del edificio `⚒️ Herrería y Armería 'Yunque Gris'` (`Vector2(210, -110)`), y `flooded_vault` (`Vector2(248, -90)`) quedaba pegada a la esquina noroeste de la herrería.
  2. Además, las puertas (`d_lbl`), ventanas (`w_lbl`) y mostradores (`stall_label`) mostraban carteles flotantes propios de 2 líneas encima del taller a la vez que `InteractionSelector` mostraba el aviso `[E] ...` y que Thoran mostraba su barra de progreso de forja (`CraftProgressBar`).
- **Solución aplicada (`VillageUnderworld.gd`, `WorldInteractableProp.gd`, `VillageManager.gd`, `InteractionSelector.gd`, `VillageNPC.gd`):**
  - Se reubicaron las rejillas `smuggler_tunnel` a `Vector2(492, -108)` y `flooded_vault` a `Vector2(182, -64)` (fuera de todos los edificios y lejos del cartel de la herrería) y se redujo el radio del `InteractArea` de las rejillas a `14 px`.
  - Se unificaron los avisos contextuales de puertas, ventanas y mostradores de negocio en el único letrero inferior de `InteractionSelector.gd`, desactivando los carteles duplicados `d_lbl`, `w_lbl` y `stall_label` que tapaban el interior de los talleres.
  - En `VillageManager._declutter_title_labels()`, `InteractionSelector._update_label()` y `VillageNPC._update_craft_bar_visual()` se añadieron las barras de trabajo y el selector `[E]` a las cajas de anticolisión de textos para que nunca se monten entre sí.
- **Qué se ve en las capturas 2D y 3D revisadas (`fix11_blacksmith_labels_2d.png`, `fix11_blacksmith_labels_3d.png`):**
  - Tanto en **2D (`fix11_blacksmith_labels_2d.png`)** como en **3D (`fix11_blacksmith_labels_3d.png`)**, con el jugador dentro de la herrería junto a Thoran:
    1. Arriba del muro norte (`y = -110`): se lee limpiamente `⚒️ Herrería y Armería 'Yunque Gris'`.
    2. Sobre Thoran (`y = -67`): se lee limpiamente su barra de trabajo `⚒️ Forjando Lingote Acero 34%` / `23%`.
    3. Debajo de los pies (`y = -24`): se lee limpiamente el único aviso `[E] Hablar con Thoran   (1/5 · Mayús+rueda o G)`.
    4. Ningún letrero pisa a otro y no aparece `"Cerrada: el perista vende la llave"` ni `"Picando piedra"`.

---

### Distinción expresa: Qué está comprobado vs. qué es supuesto
- **Comprobado directamente (con capturas 2D/3D revisadas una por una y con ejecución real del motor):**
  - El arranque limpio sin errores de script (`flatpak run org.godotengine.Godot --headless --quit-after 3` → `EXIT_CODE=0`).
  - La suite completa de pruebas automáticas (`timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd` → `ALL ... TESTS PASSED!`, `EXIT_CODE=0`).
  - Las 22 capturas en 2D y 3D tomadas en las coordenadas y horas reales de los 11 fallos (oficios en su sitio, callejón nocturno a la 01:49 con lluvia sin atascos, trampilla de la taberna cerrada de día y abierta de noche + sótano del club de peleas bajo la taberna en planta `-1`, choque físico en las mesas de la terraza de la trattoria, cementerio grande con 24 tumbas/caminos/verja/árboles en 2D y 3D, campamento en 3D completo a casi 500 px de la trattoria, césped natural sin cuadrícula ni verde menta en 2D y 3D, taberna sin bucle de apuestas ni rectángulo rojo, capilla sin franja rosa/morada sobre el tejado y herrería con los letreros separados y legibles).
- **Supuesto / Pendiente de partida larga del usuario:**
  - En sesiones largas de varios días con decenas de eventos simultáneos, la fluidez de todas las rutas de vecinos se ha verificado mediante simulación acelerada y en la hora crítica reportada (Día 2, `01:49` con lluvia y `22:30` en el club), pero queda sujeta a la prueba jugada libre del usuario.
  - Los edificios nuevos de `docs/BOCETOS_EDIFICIOS.md` (Paso 5) y el relieve del terreno siguen sin tocarse, a la espera de las indicaciones del usuario.


### 1. Qué edificios, lugares y vecinos seguían usando coordenadas antiguas (2D y 3D) y se corrigieron
- **Aprendices y ayudantes familiares de los talleres (`scripts/systems/VillageWorldBuilder.gd`):**
  - **Kael** (aprendiz de herrero en *Forja de Thoran*), **Lina** (aprendiz de carnicero en *Carnicería de Garrick*), **Mila** (hija carpintera en *Aserradero de Bram*) y **Nora** (hermana pescadora en *Pescadería de Corin*) tenían `kin_work_pos = hc + ...` (su casa residencial) en lugar de `sc + ...` (el centro real de su taller comercial). Ahora derivan de `sc` (el taller real).
- **Posada «El Jabalí Dorado» y sus trabajadores/huéspedes (`scripts/systems/VillageManager.gd`, `scripts/systems/VillageMigration.gd`, `scripts/systems/VillageWorldBuilder.gd`):**
  - En `VillageManager.gd` seguían escritas a mano las coordenadas de la posada antigua: `_tavern_bed_pos` (`Vector2(548, -264)` → `VillageTavern.PLAYER_BED_POS`), `_tavern_social_pos` (`Vector2(476, -214)` → `VillageTavern.SOCIAL_POS`), `_tavern_games_pos` (`Vector2(552, -206)` → `VillageTavern.GAMES_POS`), `_tavern_pool_pos` (`Vector2(382, -210)` → `VillageTavern.POOL_POS`) y `_tavern_well_pos` (`Vector2(440, -308)` → `VillageTavern.WELL_POS`).
  - Los **3 huéspedes desempleados iniciales** (`_spawn_unemployed_tavern_guests`) y la **sustituta de la posadera Marta** (`_process_daily_map_edge_arrivals`) usaban las camas y mostrador antiguos (`y = -268`, `(445, -242)`) en lugar de `VillageTavern.GUEST_BEDS` y `VillageTavern.INNKEEPER_WORK_POS` / `MARTA_BED_POS`.
  - En `VillageMigration.gd`, `TAVERN_DAY_SPOTS` seguía apuntando a `(462..508, -214..-198)` en vez del salón real de `VillageTavern`.
  - En `VillageWorldBuilder.gd`, el empedrado del pozo de la taberna seguía en `Rect2(414, -326, 52, 46)` (dentro del salón de la nueva posada) y se creaba un segundo `TavernWaterWellArea` duplicado; ahora usa `Rect2(202, -250, 52, 46)` alrededor de `VillageTavern.WELL_POS = Vector2(228, -224)`.
- **Pescador Corin, Leñador, Herrero Thoran, Herborista Elena y Carnicero Garrick en sus expediciones y puestos (`scripts/enemies/VillageNPC.gd`, `scripts/systems/VillageWork.gd`):**
  - En `VillageNPC.EXPEDITION_TARGETS`, **Corin (`FISHMONGER`)** seguía yendo a pescar a `Vector2(-62, 145)` (donde estaba el lago antes del Paso 2, ahora pradera vacía) en vez de la orilla real del Lago del Oeste (`Vector2(-497, 105)`).
  - **Bram (`CARPENTER`)**, **Thoran (`BLACKSMITH`)**, **Elena (`HERBALIST`)** y **Garrick (`BUTCHER`)** seguían saliendo de expedición a `y = 338..362` (antiguo borde del bosque, hoy ocupado por el Rancho/Granja del Sur) en vez del nuevo Bosque Profundo (`y = 785..810`), y el punto de recolección `fallback_spot` seguía en `Vector2(88, 350)` en vez de `Vector2(88, 785)`.
  - En `VillageWork.gd`, el **Leñador (`WOODCUTTER`)** seguía trabajando en `[Vector2(-350, 560), Vector2(-280, 580)]` (dentro de la Granja del Sur ampliada) en vez del lindero del bosque junto a su serrería (`[Vector2(-470, 625), Vector2(-390, 635)]`).
  - En `VillageNPC.IDLE_STROLL_SPOTS`, los paseos al **Parque del Roble**, **Mirador del Lago** y **Lavadero** conservaban las coordenadas anteriores al Paso 2.
- **Ayuntamiento (`n4`), Biblioteca (`n5`), Mansión Noble (`f1`) y Trattoria «Il Corvo» (`scripts/systems/VillagePlaces.gd`, `scripts/systems/VillageUnderworld.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/ui/DetectiveUI.gd`, `tools/tests/verify_all.gd`):**
  - En `VillagePlaces.gd`, el destino de ocio de la **Biblioteca (`n5`)** seguía en `Vector2(890, -445)` en vez de `Vector2(906, -451)`.
  - En `VillageUnderworld.HEIST_TARGETS`, el `"libro_gremial"` del **Ayuntamiento (`n4`)** seguía en `Vector2(764, -444)` en vez de `Vector2(764, -449)`.
  - En `WorldStage3D.gd`, el escritorio 3D de la **Mansión Noble (`f1`)** seguía con offset fijo `c + Vector2(-28, -16)` (solapando la cama) en vez de `VillageNobility.study_pos(b["id"], c)`.
  - En `DetectiveUI.gd`, `_get_corpse_site_kind` y `_describe_world_site` seguían buscando la **Trattoria «Il Corvo»** en `x > 1000, y > 190` y el **Lago del Oeste** en `x < -60, y > 30`, actualizados ahora a la Calle Mayor (`Rect2(-255, -206, 275, 190)`) y al nuevo lago (`x < -280, y = -130..260`). En `verify_all.gd` (`R2.12`), el paso del comedor al reservado se calculó desde `r1_rs.BASE` en lugar del antiguo `(1150, 350)`.

### 2. Fallo de `verify_all.gd` en `P6b.3a` (saboteador contratado a la 01:00)
- **Causa real:** al registrar `TradeRole.WAITER` (`26`) en `vm.trade_configs` antes de que un camarero titular estuviera asignado en `vm.trade_npcs`, `underworld_hire_saboteur` podía elegir un oficio sin dueño vivo en `trade_npcs`, y `VillageNightJobs.target_pos(vm, job)` devolvía `Vector2.ZERO` cuando `vm.trade_npcs.get(r_id)` era `null`, abortando `on_hour` a la `01:00` antes de asignar `night_job`.
- **Solución (`scripts/systems/VillageNightJobs.gd`, `scripts/systems/VillageUnderworld.gd`):**
  - `VillageNightJobs.target_pos` para `"sabotage"` y `"clan_sabotage"` recurre ahora a `vm.shop_businesses[r_id]["stall_pos"] + Vector2(0, 10)` o `vm.trade_configs[r_id]["work_pos"] + Vector2(0, 10)` si el artesano titular no está en `trade_npcs`.
  - `VillageUnderworld.underworld_hire_saboteur` prioriza negocios con titular vivo en `vm.trade_npcs`.

### 3. Alcantarillas en medio del bosque, invisibles en 3D y con colisión en superficie
- **Causa real:** las cámaras de las alcantarillas (`build_sewers_world` y `_build_sewers_3d`) estaban construidas en `y = 1520` (que tras agrandar el bosque en el Paso 2 quedó en mitad del Bosque Profundo). En 2D su `SewersVisual2D` se veía siempre sobre la hierba del bosque, y en 3D `sewers_root_3d` se ocultaba en superficie (`player_elevation_level != -1`) pero el `StaticBody2D` `SewerTunnelWallsBody` mantenía `collision_layer = 1`, haciendo chocar al jugador contra muros invisibles en el bosque (y lo mismo ocurría con `FightClubWallsBody`).
- **Solución (`scripts/systems/VillageUnderworld.gd`, `scripts/systems/VillageClub.gd`, `scripts/obstacles/WorldInteractableProp.gd`, `scripts/systems/VillageManager.gd`, `scripts/visuals/WorldStage3D.gd`):**
  - Las alcantarillas se trasladaron bajo el centro del pueblo en `SEWER_Y = 63.0` (`x = 260, 420, 580`), justo debajo de sus 3 rejillas de entrada (`(248, -90)`, `(398, -118)`, `(518, 26)`), y el sótano del Club de la Lucha se colocó en `Vector2(165, -224)` bajo el patio oeste de la taberna.
  - `VillageUnderworld.sync_sewer_visibility(vm)` y `VillageClub.sync_club_visibility(vm)` desactivan `collision_layer` (`0`) y ocultan `SewersVisual2D` / `FightClubVisual2D` e iconos de escalerillas/cofres cuando el jugador está en la superficie (`player_elevation_level == 0`), y al bajar (`player_elevation_level == -1`) activan la colisión y muestran las alcantarillas o el club tanto en 2D como en 3D (ocultando los edificios y árboles de la superficie en `WorldStage3D._sync_dynamic_props_3d` para que se vean limpiamente bajo el pueblo).

### 4. Verificación ejecutada
- **Arranque limpio:** `flatpak run org.godotengine.Godot --headless --quit-after 3` → `EXIT_CODE=0`, sin errores de script.
- **Suite completa `verify_all.gd`:** `timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd` → **`EXIT_CODE=0`** (`ALL ... TESTS PASSED!`, incluidos `P6b`, `FIS3`, `R1`, `R2`, `B1–B7` y `D1–D5`).
- Los edificios de `docs/BOCETOS_EDIFICIOS.md` (Paso 5) no se han tocado, a la espera de revisión del usuario.

---

## Encargo anterior: ⛔ Paso 5 (bocetos previos) — Bocetos de todos los edificios y espacios pendientes (`docs/BOCETOS_EDIFICIOS.md`)

### Qué se hizo en este bloque
- **Redacción completa de `docs/BOCETOS_EDIFICIOS.md` antes de construir ningún edificio del Paso 5 (siguiendo la parada obligatoria ⛔ de `docs/ENCARGO_ANTIGRAVITY.md`):**
  - **1. Comisaría y Cárcel Municipal:** 5 estancias (recepción con mostrador de denuncias, despacho del Comisario con caja fuerte y expedientes, sala de interrogatorios, calabozos con 2 celdas de barrotes reales de suelo a techo con camastro y cubo —eliminando las rejas verdes gigantes sueltas y el cajón sin sentido—, y armero de guardia; el cepo pasa al exterior junto a la fachada).
  - **2. Hospital de Caridad y Morgue Forense:** 4 estancias (recepción y consulta del Dr. Valen, sala de hospitalización con 4 camas y biombos, sala de autopsias con mesa forense de drenaje, instrumental y estantes de reactivos conectada al bloque `D2`, y cámara refrigerada de cuerpos con 3 bandejas y bloques de hielo).
  - **3. Capilla de la Fe del Alba:** 4 zonas (nave central con dos filas de bancos y vitrales, altar mayor elevado con el Cáliz, confesionario lateral de madera con celosía y sacristía con el Libro de Defunciones y subida al campanario, sin tocar nada de la secta).
  - **4. Biblioteca y Archivo Municipal (con «Leer un rato `[E]`» funcional):** 4 estancias (vestíbulo de préstamo, gran sala de lectura con mesas y lámparas, sección de ciencias/medicina/herbario y archivo histórico/catastro) y diseño de la mecánica real para **`[E] Leer un rato (30 min)`** con 4 materias útiles para los casos y el personaje (*Tratado de Toxicología y Forense*, *Crónicas y Linajes de las Familias*, *Herbario y Fauna* y *Planos Catastrales y Alcantarillado*).
  - **5. Alcantarillas Ampliadas y Sótano del Club de la Lucha:** diseño diferenciado del sótano clandestino bajo la bodega de la taberna (foso con 4 postes y cuerdas, bancos de público, mesa del corredor de apuestas, abierto de `21:00` a `03:00`) y de la red de alcantarillas ampliada bajo las calles (bóvedas de ladrillo, canal de agua con pasarelas y puentes, 3 escalerillas y escondites de contrabando/pruebas).
  - **6. Rancho del Sur y Gran Corral de Ganado:** casa-establo dividida en 3 salas (venta/aperos, lechería/esquila y vivienda del ganadero) + gran corral vallado exterior poblado con modelos 3D reales de vacas (`Cow.glb`), toro (`Bull.glb`), caballos (`Horse.glb` / `Horse_White.glb`), burro (`Donkey.glb`), alpacas/ovejas (`Alpaca.glb`) y gallinas, integrados con la economía del pueblo.
  - **7. Tablón de Encargos Legible en la Plaza Central:** estructura techada con farol donde cada encargo activo muestra su hoja de pergamino física con título y firmante legibles al acercarse, abriendo el menú con `[E]`.
  - **8. Resto de edificios del pueblo y Tabla de Puertas según fachada:** bocetos de salas, muebles, ocupantes e interacciones para el **Ayuntamiento**, **Escuela**, **Salón «El Candil»**, **Mansiones Nobles**, **Casas de vecinos** y **Talleres/Tiendas con trastienda**, más la tabla de **11 estilos de puertas exteriores distintas** según la fachada de cada edificio.

### Qué queda sin comprobar / pendiente
- **En espera de revisión del usuario (`ESPERANDO_USUARIO`):** tal como ordena el Paso 5 (⛔), no se ha construido aún ninguno de estos edificios en el código para que el usuario revise primero `docs/BOCETOS_EDIFICIOS.md` y dé el visto bueno o indique correcciones antes de construirlos todos seguidos.
- Siguen pendientes de comprobar en Godot (al regreso del usuario) los bloques visuales de los Pasos 1 a 4 realizados hoy sin abrir Godot ni lanzar pruebas por indicación expresa.

---

## Encargo anterior: Paso 4 — Ambiente: cielo con nubes y hora, suelo con textura, árboles nuevos, niebla

### Qué se hizo en este bloque
- **Cielo dinámico con nubes en movimiento, sol/luna y estrellas según la hora (`scripts/visuals/WorldStage3D.gd::SKY_CLOUD_SHADER_CODE`, `setup_stage`, `_update_roof_cutaways_and_lighting`):**
  - En primera persona se sustituyó el fondo azul plano (`Environment.BG_COLOR`) por un recurso `Sky` con el shader `SKY_CLOUD_SHADER_CODE` (`Environment.BG_SKY`).
  - La bóveda celeste interpola de forma continua con la hora y los minutos de `WorldClock` (`hour_f = hour + minute / 60.0`): amanecer rosado-dorado (`05:30–08:00`), día azul celeste con horizonte brumoso (`08:00–17:00`), atardecer ámbar-violeta (`17:00–19:48`) y noche azul índigo con estrellas parpadeantes y luna plateada.
  - Dibuja el disco solar/lunar con su halo atmosférico, mueve la dirección e inclinación de `sun_light` a lo largo del arco diurno y proyecta **dos capas de nubes en movimiento** con ligero pixelado retro e iluminación cálida en sus bordes.
- **Suelo con textura multiescala y matas de hierba y flores silvestres 3D (`scripts/visuals/WorldStage3D.gd::GROUND_TERRAIN_SHADER_CODE`, `_make_ground_shader_mat`, `_build_ground_3d`, `_build_ground_foliage_3d`):**
  - El suelo de pradera (`m_grass`), bosque (`m_forest`) y llanura (`m_plains`) usa ahora el shader `GROUND_TERRAIN_SHADER_CODE`, que combina `floor_ground_grass.png`, `floor_ground_grass_overlay.png` y `floor_ground_dirt.png` en coordenadas de mundo a **3 escalas distintas** (manchas de pradera, baldosa media y brizna nítida a ras de suelo en 1.ª persona), añadiendo briznas claras/oscuras, florecillas y calvas naturales de tierra húmeda.
  - `_build_ground_foliage_3d()` reparte cientos de matas de hierba, tréboles, helechos, espigas y flores silvestres 3D (`nature/Plant_1..3.obj`, `Flowers.obj`, `Wheat.obj`) por las praderas, cunetas, campamento, orilla del lago y linde del bosque (respetando caminos, plaza y edificios y agrupándolos en `MultiMeshInstance3D` mediante `_absorb_into_batches`).
- **Árboles variados por zona y colores de materiales corregidos (`scripts/visuals/WorldStage3D.gd::_make_nature_3d`, `_build_tree_3d`, `scripts/visuals/AssetLibrary3D.gd::_parse_mtl_file`):**
  - `_make_nature_3d` y `_build_tree_3d` alternan ahora robles y hayas frondosos (`CommonTree_1..4.obj`), abedules de corteza blanca (`BirchTree_1..3.obj`) y pinos altos (`PineTree_1..4.obj`) según la zona del valle, en vez de repetir únicamente pinos en todo el mapa.
  - `AssetLibrary3D._parse_mtl_file` normaliza los materiales con sufijo `.001` (`Green.001`, `DarkGreen.001`, `White.001`, `Black.001` en `BirchTree_2.mtl`) y `Leaves` para que todos los abedules y árboles frondosos luzcan con corteza y follaje naturales.
- **Niebla atmosférica según la hora del día y el clima (`scripts/visuals/WorldStage3D.gd::_update_roof_cutaways_and_lighting`):**
  - Configurada la niebla atmosférica (`fog_light_color`, `fog_sun_scatter`, `fog_sky_affect`, `fog_density`) reactiva a la hora (bruma matinal al amanecer, bruma cálida al atardecer, niebla nocturna azulada y bruma suave de horizonte al mediodía) y al clima de `WorldClock` (`"fog"`, `"rain"`, `"storm"` duplican la densidad de niebla y aumentan la cobertura de nubes), desactivándose automáticamente al entrar bajo techo (`pl_indoors`) para mantener nítidos los interiores.

### Qué queda sin comprobar (por orden expresa del usuario hoy)
- **Pendiente de comprobar al regreso del usuario** (siguiendo la instrucción *«HOY NO PASES NINGUNA PRUEBA, NI ARRANQUES GODOT, NI HAGAS CAPTURAS: el usuario las hará al volver»*):
  1. Arranque de Godot y revisión visual en 1.ª persona (`[F6]`/`[F8]`) y en vista 3D a distintas horas del día (amanecer, mediodía, atardecer, noche y día de niebla/lluvia) para comprobar el cielo con nubes en movimiento, el suelo texturizado con matas de hierba y flores 3D, la variedad de robles/abedules/pinos y la niebla atmosférica.

---

## Encargo anterior: Paso 3 — La taberna «El Jabalí Dorado» (2 pisos)

### Qué se hizo en este bloque
- **Edificio mucho más grande y primer edificio de 2 plantas reales (`scripts/systems/VillageTavern.gd`, `scripts/systems/VillageWorldBuilder.gd`, `scripts/systems/VillageManager.gd`, `scripts/obstacles/WorldInteractableProp.gd`, `scripts/visuals/CharacterAvatar3D.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/ui/ValleyMapUI.gd`):**
  - Se amplió la huella de la taberna a `Rect2(Vector2(260, -316), Vector2(348, 184))` con muros de 2 plantas (`wall_h = 44.0`, `22.0 px` por piso).
  - **Planta Baja (`Planta 0`, `elevation_level = 0`):** dividida por tabiques interiores con dinteles en 4 salas comunicadas: **Gran Salón y Comedor** (`salon`, con chimenea de piedra y brasas, 6 mesas de roble con 12 sillas, platos, jarras y 2 arañas de techo), **Barra y Cocina** (`barra_cocina`, con gran mostrador de caoba y latón, 4 taburetes, tiradores de cerveza, estantería de licores, toneles de roble, fogones con caldero y encimera), **Sala de Casino y Billar** (`casino`, con alfombra carmesí, mesa de póker y mesa de billar) y **Vestíbulo de Escalera y Bodega** (`escalera_bodega`).
  - **Primer Piso (`Planta +1`, `elevation_level = 1`, `FLOOR_1_H = 22.0`):** galería alta con barandilla de madera asomada al salón, pasillo alfombrado y **5 cuartos de huéspedes** con puertas y tabiques que alojan las **6 camas reales de la posada** (`(342, -252)` de alquiler + `(400, -252)`, `(435, -252)`, `(468, -252)`, `(502, -252)`, `(538, -252)` para vecinos/viajeros), con mesillas, cofres y alfombras.
  - **Escalera física real (`STAIRS_BOTTOM_POS = Vector2(576, -284)` ↔ `STAIRS_TOP_POS = Vector2(576, -202)`):** 12 peldaños macizos de roble con barandillas en 3D y objeto interactivo `"tavern_stairs"` (`[E] Subir al primer piso (+1: Habitaciones)` / `[E] Bajar a la planta baja (0: Salón)`). El enrutador `VillageTavern.route(...)` guía automáticamente tanto a los vecinos que suben a dormir o bajan por la mañana como entre cualquier sala de ambas plantas, y `CharacterAvatar3D` / `WorldStage3D._update_fp_camera_transform` interpolan suavemente la altura 3D al subir o bajar los peldaños.
- **Mesas con gente sentada comiendo, partida de póker en vivo, Marta tras la barra y Camarero (`scripts/systems/VillageTavern.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/systems/VillagePlaces.gd`, `scripts/systems/VillageNeeds.gd`, `scripts/data/PersonProfile.gd`, `scripts/ui/SocialGlossaryUI.gd`, `scripts/enemies/NPCDialogue.gd`):**
  - **Marta detrás del mostrador:** `INNKEEPER_WORK_POS = Vector2(338, -248)` coloca a la posadera detrás del mostrador de caoba (`BAR_COUNTER_POS = Vector2(338, -234)`) atendiendo la barra.
  - **Nuevo oficio `TradeRole.WAITER` (Camarero, índice 26):** añadido al final de `enum TradeRole` y registrado en `vm.trade_configs` para cubrirse como cualquier oficio vacante (y creado al inicio de la partida). En su horario (`10:00–23:00`), `VillageTavern.tick_waiter` hace que recorra las mesas con comensales sentados, tome nota del pedido, camine al pasa-platos de la barra (`PASS_COUNTER_POS = Vector2(396, -246)`) a recoger las jarras/platos y los sirva en la mesa.
  - **Comensales sentados y jugadores de póker:** los vecinos que comen en la posada o acuden por ocio (`"tavern"`, `"tavern_hall"`, `"tavern_poker"`, o recados `"drink"` / `"gamble"`) eligen una silla libre de las 6 mesas del salón (`DINING_TABLES`) o de las 4 sillas de la mesa de póker (`POKER_CHAIRS`), se sientan mirando a la mesa (`set_poker_seating`) y conversan o comentan las jugadas en vivo (`VillageTavern.tick`). Además, `seed_initial_patrons` sienta comensales y jugadores de póker desde el arranque de la partida para que la taberna nunca se vea vacía.
- **Sótano con el Club de la Lucha Clandestino (`scripts/systems/VillageClub.gd`, `scripts/systems/VillageUnderworld.gd`, `scripts/enemies/NPCDialogue.gd`, `scripts/visuals/WorldStage3D.gd`):**
  - La trampilla `VillageClub.TRAPDOOR_POS = Vector2(516, -286)` está ahora **dentro de la sala trasera de escalera y bodega de la taberna** (entre toneles y bajo un farol cálido, sobre la losa del suelo en `h = 2.5`).
  - El club abre **todas las noches de `21:00` a `03:00`** (`OPEN_FROM = 21`, incluidas las noches impares como la primera noche de partida, salvo cierre policial tras una redada) y es fácil de descubrir preguntando a Marta o al Camarero (`"ask_club_rumor"`: *«¿Qué son esos golpes que se oyen bajo el suelo de la bodega?»*) o mediante los rumores nocturnos de taberna (`FENCE_RUMORS`).
- **Mesa de billar auténtica en 3D (`scripts/visuals/WorldStage3D.gd::_build_billiard_table_3d`):**
  - Eliminado el uso de `Table_Large.gltf` con un rectángulo verde encima. La nueva mesa de billar en `POOL_POS = Vector2(574, -178)` se construye con geometría 3D propia: 4 patas torneadas de caoba con casquillos de latón, faldón perimetral de caoba, pizarra de paño verde esmeralda con línea blanca de saque, 4 bandas elevadas de caoba partidas en el centro, 6 troneras con herrajes de latón y hueco oscuro, bola blanca + triángulo de bolas de colores (amarilla, azul, roja y bola 8 negra) y 2 tacos de madera con virola de tiza azul apoyados sobre las bandas.

### Qué queda sin comprobar (por orden expresa del usuario hoy)
- **Pendiente de comprobar al regreso del usuario** (siguiendo la instrucción *«HOY NO PASES NINGUNA PRUEBA, NI ARRANQUES GODOT, NI HAGAS CAPTURAS: el usuario las hará al volver»*):
  1. Ejecución de `tools/tests/verify_all.gd` (comprobación de rutas, camas de la posada en Planta `+1`, oficio `WAITER` y trampilla del Club de la Lucha).
  2. Arranque de Godot y revisión visual en 3D y 1.ª persona de:
     - La nueva taberna de 2 pisos («El Jabalí Dorado»), la subida/bajada por la escalera física a los 5 cuartos de huéspedes con las 6 camas en Planta `+1`, y el cambio de altura suave de cámara/avatares en los peldaños.
     - Marta atendiendo tras el mostrador, el Camarero yendo de las mesas al pasa-platos de la barra, los vecinos sentados en las 6 mesas de comedor y en las 4 sillas de la mesa de póker, la mesa de billar 3D con troneras, bolas y tacos, y la bajada al Club de la Lucha desde la trampilla de la bodega entre las `21:00` y las `03:00`.

---

## Encargo anterior: Paso 2 — Agrandar y separar el entorno

### Qué se hizo en este bloque
- **Campamento inicial y Lago del Oeste alejados del pueblo (`scripts/World.gd`, `scenes/World.tscn`, `scripts/obstacles/FishingSpot.gd`, `scripts/systems/VillageManager.gd`, `scripts/systems/VillageWorldBuilder.gd`, `scripts/visuals/WorldStage3D.gd`):**
  - El campamento inicial del jugador (`PlayerCampSite` en `Vector2(-532, -96)`), el huerto de 3×3 parcelas (`Vector2(-585, -45)`), el gallinero (`Vector2(-658, -21)`), la aparición inicial del jugador (`Vector2(-489, -56)`) y el perro guardián **Toby** (`Vector2(-495, -52)`, antes suelto en mitad del pueblo) quedan ahora fuera de la aldea, junto al **Lago del Oeste** (`LAKE_NODE_POS = Vector2(-525, 105)`), unidos al pueblo por un camino largo.
  - Se eliminó el segundo embarcadero 3D del sur del lago en `WorldStage3D._build_barrios_3d()`, dejando un único muelle de pesca en la orilla este.
- **Lavadero trasladado al pueblo, Parque del Roble ampliado y retirada del «Huerto vecinal» del camino (`scripts/systems/VillageWork.gd`, `scripts/systems/VillagePlaces.gd`, `scripts/systems/VillageLots.gd`, `scripts/visuals/WorldStage3D.gd`):**
  - El **Lavadero Municipal** (`VillageWork.LAVADERO_POS`) se movió de la orilla del lago a `Vector2(215, 145)` en el pueblo (al oeste de la Botica y al norte del Parque del Roble), registrándose también como fuente de agua en `VillageManager.is_position_near_water_source`.
  - El **Parque del Roble** (`VillagePlaces.PARK_RECT`) se amplió a `Rect2(Vector2(168, 208), Vector2(272, 146))` (casi el doble de superficie), sin el murete bajo que lo encerraba, con paseos en cruz y con los árboles en las esquinas lejos de los bancos.
  - Se retiró de `VillageLots.GAP_POCKETS` el `"garden"` («🥬 Huerto vecinal» en `Vector2(1090, -40)`) que estaba plantado en mitad del camino del este junto a la Residencia Aguas Claras.
- **Trattoria «Il Corvo» trasladada de junto al cementerio a la Calle Mayor (`scripts/systems/VillageRestaurant.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/ui/ValleyMapUI.gd`, `tools/tests/verify_all.gd`):**
  - Se reubicó `VillageRestaurant.BASE` a `Vector2(-255, -206)` (`RECT = Rect2(-255, -206, 275, 190)`), con su puerta sur y su terraza abiertas directamente a la Calle Mayor que entra a la Plaza Central, a más de `1.100 px` del Cementerio Parroquial y sin solapar ningún solar ni camino.
- **Llanura Salvaje y Ciénaga de las Ranas separadas y más amplias (`scripts/systems/VillageWorldBuilder.gd`, `scripts/visuals/WorldStage3D.gd`, `scenes/World.tscn`, `scripts/Player.gd`, `scripts/enemies/VillageNPC.gd`, `scripts/systems/VillageManager.gd`):**
  - La **Llanura Salvaje** ocupa ahora una meseta amplia e irregular al **noroeste** (`x = -2060..-1080, y = -560..-20`, con ruinas de bandidos, cajas y enemigos), separada al otro lado del camino respecto a la **Ciénaga de las Ranas** al **suroeste** (`x = -2020..-1100, y = 110..560`, con laguna pantanosa amplia, sauces, juncos, troncos caídos y sapos).
- **Bosque Profundo ~3,5 veces más grande, más al sur, con borde orgánico, árboles 3D corregidos y fauna que deambula (`scripts/systems/EcosystemManager.gd`, `scripts/enemies/WildAnimal.gd`, `scripts/visuals/AssetLibrary3D.gd`, `scripts/visuals/WorldStage3D.gd`, `scripts/ui/ValleyMapUI.gd`):**
  - **Árboles 3D corregidos (`AssetLibrary3D.gd`, `WorldStage3D.gd`):** el cargador `load_obj_mesh` triangulaba las caras `.obj` en orden antihorario (haciendo que Godot descartara las caras frontales y mostrara las copas huecas por dentro como «bloques arrugados») y `_parse_mtl_file` convertía el material `Wood` de los árboles en un tono rosado. Se corrigió la triangulación a orden horario CW, se activó `CULL_DISABLED` y se normalizaron `Wood`, `DarkWood`, `Green` y `DarkGreen` a marrón corteza y verdes naturales; además, `_scan_nature_sources()` descarta cualquier árbol decorativo que solape edificios o quede a `< 18 px` de otro árbol.
  - **Bosque ~3,5× mayor y con borde irregular (`EcosystemManager.FOREST_POLY`):** alejado al sur (`x ≈ -1360..1640, y ≈ 730..2390`), sin línea perimetral recta, con 60 árboles talables formando claros naturales, 14 vetas de mineral, 42 plantas silvestres, 32 arbustos (`Bush_1/2.obj`, `BushBerries_1/2.obj`) y 12 troncos caídos (`WoodLog.obj`).
  - **Fauna que deambula y se dispersa (`WildAnimal.gd`):** ampliado el radio de pastoreo/exploración de `90..135 px` a `380..450 px`, eliminado el imán constante hacia el centro de la manada/madriguera y añadida una fuerza de separación suave entre animales cercanos para que se repartan por todo el bosque.

### Qué queda sin comprobar (por orden expresa del usuario hoy)
- **Pendiente de comprobar al regreso del usuario** (siguiendo la instrucción *«HOY NO PASES NINGUNA PRUEBA, NI ARRANQUES GODOT, NI HAGAS CAPTURAS: el usuario las hará al volver»*):
  1. Ejecución de `tools/tests/verify_all.gd` (incluyendo las aserciones de navegación de `VillageRestaurant` actualizadas a `r1_rs.BASE`).
  2. Arranque de Godot y revisión visual en partida de:
     - El campamento inicial, huerto 3×3, gallinero, Toby y Lago del Oeste con un único muelle y camino largo hasta la aldea.
     - El Lavadero en el pueblo (`Vector2(215, 145)`), el Parque del Roble ampliado sin murete bajo, la ausencia del «Huerto vecinal» en el camino del este y la Trattoria «Il Corvo» en la Calle Mayor.
     - La Llanura Salvaje (noroeste) separada de la Ciénaga de las Ranas (suroeste), el Bosque Profundo ~3,5× más grande con borde orgánico, los árboles 3D con copas y ramas de color natural y los animales deambulando repartidos por el bosque.

---

## Encargo anterior: Paso 1 — Arreglos rápidos (`1a`, `1b`, `1c`)

### Qué se hizo en este bloque
- **1a. Examen de muertos que no son de un caso (`scripts/enemies/VillageNPC.gd`, `scripts/ui/DetectiveUI.gd`, `tools/tests/verify_all.gd`):**
  - `VillageNPC.stealth_assassinate(player)` ahora inspecciona el arma equipada del jugador (hacha, martillo, pico, hoz, arco o espada), guarda un `last_hit_weapon_name` real (p. ej. `"Hachazo furtivo por la espalda"`) y registra la herida letal correspondiente en `HealthComponent.wounds`.
  - `DetectiveUI.gd` (`_build_case_from_corpse`, `_describe_zone_wounds`, `_do_zone_action`, `_get_default_morgue_tests`, `_build_scene_data_for_corpse`, `_build_board_suspects_for_corpse`) construye el examen del cuerpo (D1), las pruebas de autopsia (D2), las pistas/testigos de la escena (D3) y los sospechosos del tablero (D4) **únicamente a partir del estado real del cadáver** (`HealthComponent.wounds`, `last_hit_weapon_name`, `corpse_rot_hours`, `death_world_pos`, `person_profile.gender`, `VillageForensics`, bolsillos reales). Si una zona no presenta heridas, responde `"nada fuera de lo normal"`. Ningún texto del Caso I («La mujer del bosque»: muñecas atadas, cáñamo, vestido, ceniza) se reutiliza en muertos que no pertenecen a un caso guionizado.
  - Añadido el test `D1.4a–D1.4e` en `tools/tests/verify_all.gd` (asesinato furtivo del carnicero con hacha por la espalda y verificación del examen).
- **1b. Revisión de Claude a D1–D5 (`scripts/ui/DetectiveUI.gd`, `docs/INFORME_ANTIGRAVITY.md`):**
  - **Fondo del examen y de la escena:** desactivada la captura cenital 3D con filtro Sobel de bordes (`set_detective_topdown` / `SKETCH_SHADER_CODE`) que producía ruido ilegible y mostraba suelos/tejados de edificios; sustituida por un **esquema limpio de pocas líneas del sitio real** (`_draw_body_site_schematic` en `SilhouetteCanvas` y `CrimeSceneCanvas`, adaptándose según el lugar a claro del arroyo/bosque, morgue, orilla del lago, calle empedrada o rancho).
  - **Tablero de corcho (`CorkboardCanvas`):** los hilos rojos (`StringsOverlay`, `z_index = 1`) pasan por detrás del cuerpo de las fichas (`z_index = 4`) para no tapar nunca el texto, las chinchetas (`PinsOverlay`, `z_index = 10`) se dibujan encima en el centro superior de cada tarjeta (`pos + Vector2(84, 2)`), y las posiciones iniciales de las fichas se escalonan en altura para evitar cruces sobre otras tarjetas.
  - **Barra de deterioro y corrección de este informe:** añadida en la columna derecha de `1 · Examen del cuerpo` la **barra visual de estado del cadáver en 4 fases** (`1 · Reciente`, `2 · Enfriándose`, `3 · Rígido`, `4 · Deteriorado`, actualizada en `_update_decay_bar()` según las horas transcurridas), y corregida más abajo la sección de D1–D5 para reflejar las **4 pestañas reales**, sin retrato estilizado y con el esqueleto del Caso I + 9 huecos (`case_02`..`case_10`).
- **1c. Fallos visibles pequeños (`AssetLibrary3D.gd`, `CharacterRig3D.gd`, `CharacterAvatar3D.gd`, `VisionCone2D.gd`, `DummyEnemy.gd`, `FishingSpot.gd`, `VillageRestaurant.gd`, `VillageManager.gd`, `VillagePlaces.gd`, `VillageWorldBuilder.gd`, `WorldStage3D.gd`, `docs/FALLOS_VISIBLES.md`):**
  - **Ropa que atraviesa el cuerpo:** `AssetLibrary3D.extract_head_only_mesh` recorta ahora los vértices laterales (`absf(v.x) <= 0.135`, caché `_v2_`) para eliminar los hombros y brazos en T-pose del modelo desnudo bajo la ropa.
  - **Libro gigante y variedad de vecinos:** reducida la escala de `props/Book_5.gltf` a `Vector3(0.18, 0.04, 0.22)` (`-1.0`) y limitado a horario lectivo/culto cerca de `work_position`; repartidos de forma determinista por persona los modelos `peasant`/`ranger` masculinos y femeninos, sus variantes de textura (`T_Peasant_2`, `T_Ranger_3`), los 5 peinados (`Hair_Buns`, `Hair_Long`, `Hair_BuzzedFemale`, `Hair_SimpleParted`, `Hair_Buzzed`), `T_Hair_2`, barba (`Hair_Beard`) y piel clara/oscura.
  - **Conos de depuración de los sapos:** ocultos por defecto en `VisionCone2D.gd` y `DummyEnemy.gd`.
  - **No andar sobre el agua y muelle único:** añadida colisión física (`StaticBody2D` + `CollisionPolygon2D`) al contorno de `LAKE_WATER_WORLD` en `FishingSpot.gd` dejando libre la pasarela del muelle de madera, y ocultado el muelle 2D duplicado en modo 3D.
  - **Cama de la trattoria → Despacho del dueño:** renombrada la estancia `"dueno"` a `"Despacho del dueño"` en `VillageRestaurant.gd` y sustituidas las camas en 2D y 3D por escritorio de madera, sillón del jefe, sillas de confidentes, libro de cuentas, candelabro, estantería y alfombra.
  - **Letreros encimados, Parque del Roble en 3D y lápidas del cementerio:** subidos los títulos de edificios a `-half.y - 36.0` (evitando que `"Esquilando lana 90 %"` pise `"Rancho del Sur"`), subido el cartel `"🌳 Parque del Roble"` a `y = 194`, ocultados en 3D los polígonos y sprites 2D del parque y del cementerio, construido el `Parque del Roble` 3D en su `PARK_RECT` real y reducidas las tumbas/lápidas 3D a proporción humana (`6.8 × 3.2 px` de túmulo y `8.8 px` de lápida).

### Qué queda sin comprobar (por orden expresa del usuario hoy)
- **Pendiente de comprobar al regreso del usuario** (siguiendo la instrucción *«HOY NO PASES NINGUNA PRUEBA, NI ARRANQUES GODOT, NI HAGAS CAPTURAS: el usuario las hará al volver»*):
  1. Ejecución de `tools/tests/verify_all.gd` (incluyendo el nuevo test `D1.4a–D1.4e` de examen de cadáver fuera de caso).
  2. Arranque de Godot y revisión visual en partida / capturas de pantalla (`docs/capturas_paso1/`) de:
     - Examen de un vecino muerto fuera de caso (p. ej. el carnicero asesinado con sigilo) frente al cadáver del Caso I.
     - Esquema limpio de pocas líneas en `1 · Examen del cuerpo` y `3 · Escena del crimen`, y barra de 4 fases de deterioro del cadáver.
     - Tablero de corcho (`[N]`) con los hilos rojos pasando por detrás de las tarjetas hasta las chinchetas superiores.
     - Vecinos con variedad de ropa/peinados/barba/piel, libro pequeño en mano de Anselmo/maestra, hombros del guardia sin atravesar la ropa, sapos sin cono de visión, colisión del agua del lago con muelle único caminable, despacho del dueño en «Il Corvo», letreros del Rancho del Sur y Parque del Roble sin solaparse, y lápidas del cementerio a escala reducida.

---

## Encargo anterior: Herramientas del Detective (Bloques D1, D2, D3, D4 y D5)

Se implementaron los cinco bloques de **Herramientas del Detective** (`D1`–`D5`) siguiendo `docs/PLAN_BETA_MISTERIO.md` (§§5–6) y el boceto visual `docs/bocetos/examen_cuerpo.html`, además de corregir la fachada de la trattoria en `docs/FALLOS_VISIBLES.md`.

> **Atajo de teclado clave:** La **`Tecla N`** (`[N] Tablero`) abre y cierra en cualquier momento el **Tablero del caso** (tablero de corcho del detective), también accesible desde la pestaña `4 · Tablero del caso` dentro de la interfaz forense.

---

## 1. Resumen por Bloque (D1–D5)

### Bloque D1 — Examen de cuerpo (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- **Vista de examen forense basada en `docs/bocetos/examen_cuerpo.html`:**
  - Cabecera oscura con el título del expediente, subtítulo contextual (lugar, hora estimada y estado del cuerpo), barra de **4 pestañas** (`1 · Examen del cuerpo`, `2 · Autopsia en la morgue`, `3 · Escena del crimen`, `4 · Tablero del caso`) y botón `Cerrar [Esc]`.
  - **Columna izquierda (Lienzo de silueta + esquema cenital del lugar):**
    - Fondo con esquema limpio de pocas líneas del lugar real del hallazgo (arroyo y pinos en el claro del bosque, losa clínica en la morgue, orilla y muelle en el lago, empedrado en el pueblo o valla en el rancho) y marcador numérico `[1]`.
    - Silueta anatómica plana dibujada con `_draw()` sin rasgos faciales en dos variantes según el género de la víctima: **femenina** (hombros más estrechos, cintura marcada, caderas suaves y melena oscura dibujada *detrás* de la cabeza) y **masculina** (hombros más anchos y torso recto).
    - **7 zonas clicables (`cabeza`, `cuello`, `torso`, `brazos`, `manos`, `piernas`, `bolsillos`):** muestran marcas anatómicas únicamente para las heridas o hallazgos realmente descubiertos.
  - **Columna derecha (Observación y acciones):**
    - **Barra de deterioro del cadáver en 4 fases** (`1 · Reciente`, `2 · Enfriándose`, `3 · Rígido`, `4 · Deteriorado`) según las horas transcurridas a la intemperie.
    - Botones de acción superficial (`Mirar de cerca`, `Palpar`, `Oler`, `Usar lupa` si llevas `magnifying_glass`, `Vaciar bolsillos`) que suman minutos al reloj del mundo, lista de lo descubierto en la zona con botón `Anote` para pasarlo al cuaderno, y bloque de «Causa aparente» frente a «Causa real».
  - **Tira inferior (`Cuaderno del caso`):** muestra las fichas clavadas manualmente por el jugador.

### Bloque D2 — Autopsia en la morgue con el Dr. Valen (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- Con el cuerpo en la morgue y el médico forense disponible, se habilita la pestaña `2 · Autopsia en la morgue`.
- **4 pruebas internas por pasos con riesgo de fallo:** `Sangre` (`2 / 2` tubos de muestra, elección corazón/brazo, reactivos y tabla de 4 colores), `Garganta y hueso hioides` (corte lento vs. corte rápido que rompe el hueso), `Contenido del estómago` (guardar en frasco sellado vs. tirar) y `Lividez y rigor mortis`.
- Botón `Preguntar al Dr. Valen (+5 min)` en los pasos delicados y actualización progresiva de `Causa real`.

### Bloque D3 — Escena del crimen a oscuras con linterna (`scripts/ui/DetectiveUI.gd`, `scripts/systems/DetectiveCaseData.gd`)
- Vista `3 · Escena del crimen` con el esquema cenital del lugar cubierto por oscuridad nocturna y **círculo de luz cálida del farol** centrado en el cursor del ratón, iluminando solo los indicios dentro de su radio.
- Panel derecho con el detalle del indicio seleccionado (y botón para anotarlo en el cuaderno) más los **testigos cercanos** con acciones `Preguntar (10 min)` y `Presionar (puede cerrarse)`.

### Bloque D4 — Tablero de corcho con chinchetas e hilos rojos (`scripts/ui/DetectiveUI.gd`, `scripts/systems/VillageForensics.gd`)
- Accesible en cualquier momento con la **`Tecla N`** o desde la pestaña `4 · Tablero del caso`.
- Tablero de corcho con **fichas arrastrables** de sospechosos y pistas anotadas a mano, con chincheta superior centrada y **hilos rojos** que van de chincheta a chincheta por detrás del cuerpo de las tarjetas para no tapar el texto.

### Bloque D5 — Estructura de datos para los 10 casos + Fachada de la Trattoria (`scripts/systems/DetectiveCaseData.gd`, `scripts/visuals/WorldStage3D.gd`)
- **Estructura `CASES` (`case_01_forest_woman`..`case_10`) en `DetectiveCaseData.gd`:** contiene el esqueleto completo del **Caso I («La mujer del bosque»)** según `docs/PLAN_BETA_MISTERIO.md` §5 y los **9 huecos estructurados (`case_02`..`case_10`)** con marcas `PENDIENTE_DECISION_USUARIO` en los elementos de trama pendientes de decisión del usuario.
- **Vinculación con NPCs reales (`assign_case_roles`):** vincula los papeles del caso con vecinos vivos sin matar a ningún NPC al iniciar el juego.
- **Corrección de `docs/FALLOS_VISIBLES.md`:** fachada 3D de la trattoria «Il Corvo» con acabado de estuco crema cálido y ladrillo claro.

---

## 2. Verificación Automática (`verify_all.gd`)

Se ejecutó la suite integral `tools/tests/verify_all.gd` en modo headless:

```bash
timeout 900 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/verify_all.gd > /tmp/v.log 2>&1
```

- **Resultado:** `EXIT_CODE=0` — **100 % de los tests en verde**, incluyendo los nuevos bloques de pruebas `D5.1a–D5.1c`, `D1.0–D1.3`, `D2.1a–D2.4`, `D3.1a–D3.2c` y `D4.1a–D4.5`.

---

## 3. Tour Visual de Capturas (`docs/capturas_detective/`)

Todas las capturas fueron generadas con el motor en ejecución real y revisadas visualmente una por una:

| Archivo | Contenido verificado |
| :--- | :--- |
| `docs/capturas_detective/d1_examen_mujer.png` | Vista `1 · Examen del cuerpo` con silueta femenina (melena detrás de la cabeza), marcas anatómicas reveladas, boceto 3D top-down y cuaderno de campo con `"✓ Anotado en el cuaderno"`. |
| `docs/capturas_detective/d1_examen_hombre.png` | Vista `1 · Examen del cuerpo` con silueta masculina (Caso 1, Aldric Vane), zonas reveladas y cuaderno de campo. |
| `docs/capturas_detective/d2_autopsia_morgue.png` | Vista `2 · Autopsia (morgue)` con mesa clínica, frascos de muestras (`2/2`), consejo del Dr. Valen, gráfico de 4 barras de color y causa aparente vs. causa real. |
| `docs/capturas_detective/d3_escena_crimen.png` | Vista `3 · Escena del crimen` a oscuras con el haz cálido de la linterna centrado en el cursor e iluminando las pruebas, más testigos a la derecha. |
| `docs/capturas_detective/d4_tablero_corcho.png` | Vista `4 · Tablero del caso` (`Tecla N`) con tarjetas de víctima, sospechosos y pistas separadas sobre el corcho e hilos rojos tensados por encima de las tarjetas. |
| `docs/capturas_detective/mundo_plaza_dia.png` | Vista general de la plaza central de día con vecinos y edificios. |
| `docs/capturas_detective/mundo_plaza_noche.png` | Vista general de la plaza central de noche con iluminación de farolas. |
| `docs/capturas_detective/mundo_trattoria_dia.png` | Fachada 3D de la Trattoria «Il Corvo» corregida con estuco crema cálido y ladrillo terracota claro. |
| `docs/capturas_detective/mundo_morgue_dia.png` | Exterior del Hospital / Morgue del Dr. Valen y Comisaría de día. |
| `docs/capturas_detective/mundo_bosque_noche.png` | Vista nocturna del bosque periférico. |
