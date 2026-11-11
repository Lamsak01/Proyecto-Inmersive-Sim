# Inventario del mundo (paso 0 de `docs/PLAN_MUNDO_DESDE_EDITOR.md`)

> Generado por `tools/tests/inventario_mundo.gd` el 2026-11-11. Se movieron **todas** las piezas del editor (373.0, 241.0) px y se miró qué se movió con ellas. Solo cuenta lo que no se mueve solo (vecinos, animales y el jugador quedan fuera).

## Resumen

| Resultado | Cosas |
|---|---:|
| sigue al editor | 5098 |
| se queda en el sitio viejo | 697 |
| se mueve el doble (traducido dos veces) | 885 |
| acaba en otro sitio o no aparece | 103 |

## Por familia (las 60 con más restos)

| Familia | Sigue | Quieto | Doble | Otro sitio | Ejemplo de resto |
|---|---:|---:|---:|---:|---|
| 3D · Nature3D / Nature3D / Lote | 0 | 434 | 0 | 0 | a 45 m de Casa de Comidas 'El Fogón del Valle' |
| 3D · Buildings3D / B3D_building_tavern / MeshInstance3D | 23 | 0 | 161 | 2 | a 5 m de Gran Posada, Taberna y Casino 'El Jabalí Dorado' |
| 3D · Buildings3D / B3D_building_restaurant / MeshInstance3D | 56 | 0 | 135 | 0 | a 6 m de Casa de Comidas 'El Fogón del Valle' |
| 3D · Buildings3D / B3D_building_abandoned_mill / MeshInstance3D | 49 | 0 | 107 | 25 | a 3 m de Molino Viejo Abandonado |
| 3D · Buildings3D / B3D_building_hospital / MeshInstance3D | 17 | 0 | 113 | 3 | a 1 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / B3D_building_police / MeshInstance3D | 37 | 0 | 67 | 4 | a 3 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Streetlights3D / Streetlights3D / MeshInstance3D | 85 | 58 | 0 | 4 | a 4 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Lots3D / Lots3D / MeshInstance3D | 0 | 56 | 0 | 0 | a 28 m de Biblioteca |
| 3D · Buildings3D / Chair / Chair | 18 | 2 | 54 | 0 | a 1 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / Loft3D_building_tavern / MeshInstance3D | 0 | 0 | 48 | 0 | a 1 m de Gran Posada, Taberna y Casino 'El Jabalí Dorado' |
| 3D · Terrain3D / Terrain3D / MeshInstance3D | 0 | 42 | 0 | 0 | a 45 m de Casa de Comidas 'El Fogón del Valle' |
| 3D · Buildings3D / Table_Large2 / Table_Large | 28 | 2 | 17 | 0 | a 1 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Nature3D / Nature3D / MeshInstance3D | 914 | 0 | 0 | 18 | a 181 m de Rancho del Sur |
| 3D · Buildings3D / Mug2 / Mug | 1 | 0 | 18 | 0 | a 3 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Buildings3D / B3D_house_family_lot_m6 / MeshInstance3D | 0 | 18 | 0 | 0 | a 63 m de Biblioteca |
| 3D · Buildings3D / B3D_house_family_lot_l3 / MeshInstance3D | 0 | 18 | 0 | 0 | a 56 m de Granja del Sur |
| 3D · Buildings3D / Node3D / MeshInstance3D | 98 | 6 | 10 | 0 | a 57 m de Granja del Sur |
| Lógica 2D ·  /  / ShopBusinessStall | 0 | 0 | 0 | 15 | a 554 m de Mansión del Señor del Valle |
| 3D · Buildings3D / B3D_mixed_family_tinker / MeshInstance3D | 19 | 0 | 14 | 0 | a 2 m de Taller de Reparaciones |
| 3D · Buildings3D / B3D_building_library / MeshInstance3D | 250 | 0 | 0 | 14 | a 3 m de Biblioteca |
| 3D · Buildings3D / Bed_Twin12 / Bed_Twin1 | 53 | 4 | 7 | 0 | a 3 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Buildings3D / Barrel2 / Barrel | 0 | 0 | 10 | 0 | a 2 m de Casa de Comidas 'El Fogón del Valle' |
| Sitio de vecino: work_position | 32 | 0 | 0 | 10 | a 47 m de Panadería 'La Espiga' |
| 3D · Buildings3D / Nightstand_Shelf2 / Nightstand_Shelf | 3 | 0 | 9 | 0 | a 3 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / Lantern_Wall2 / Lantern_Wall | 6 | 0 | 8 | 0 | a 3 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / B3D_building_town_hall / MeshInstance3D | 39 | 0 | 8 | 0 | a 2 m de Ayuntamiento del Valle |
| 3D · Buildings3D / B3D_building_restaurant / OmniLight3D | 0 | 0 | 7 | 0 | a 5 m de Casa de Comidas 'El Fogón del Valle' |
| 3D · Outpost3D / Outpost3D / MeshInstance3D | 0 | 7 | 0 | 0 | a 15 m de Herrería y Armería 'Yunque Gris' |
| 3D · Buildings3D / B3D_building_tavern / OmniLight3D | 0 | 0 | 6 | 0 | a 9 m de Gran Posada, Taberna y Casino 'El Jabalí Dorado' |
| 3D · Buildings3D / PuertaCuarto / MeshInstance3D | 0 | 0 | 6 | 0 | a 6 m de Gran Posada, Taberna y Casino 'El Jabalí Dorado' |
| 3D · Buildings3D / Chandelier2 / Chandelier | 5 | 0 | 6 | 0 | a 2 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Buildings3D / CandleStick_Triple2 / CandleStick_Triple | 2 | 0 | 6 | 0 | a 1 m de Biblioteca |
| 3D · Buildings3D / B3D_building_police / OmniLight3D | 0 | 0 | 5 | 0 | a 2 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Buildings3D / Workbench2 / Workbench | 13 | 0 | 5 | 0 | a 2 m de Casa Grande de los Rentistas |
| 3D · Buildings3D / Bottle / Bottle | 1 | 0 | 5 | 0 | a 2 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / Skeleton3D / Chest_Wood_Lid | 30 | 2 | 2 | 0 | a 57 m de Granja del Sur |
| Sitio de vecino: home_table_pos | 38 | 3 | 0 | 1 | a 40 m de Sastrería 'El Dedal' |
| Sitio de vecino: bed_position | 38 | 3 | 0 | 1 | a 41 m de Sastrería 'El Dedal' |
| 3D · Buildings3D / Skeleton3D / Chest_Wood_Base | 30 | 2 | 2 | 0 | a 57 m de Granja del Sur |
| 3D · Buildings3D / Node3D / Face | 68 | 4 | 0 | 0 | a 55 m de Granja del Sur |
| 3D · Buildings3D / Node3D / FaceBack | 68 | 4 | 0 | 0 | a 56 m de Granja del Sur |
| 3D · Buildings3D / Book / Book | 3 | 0 | 4 | 0 | a 1 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / CandleStick2 / CandleStick | 5 | 0 | 4 | 0 | a 2 m de Molino Viejo Abandonado |
| 3D · Buildings3D / Shelf_Small_Bottles2 / Shelf_Small_Bottles | 1 | 0 | 4 | 0 | a 4 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / StoppedMillWaterwheel3D / MeshInstance3D | 46 | 0 | 0 | 4 | a 3 m de Molino Viejo Abandonado |
| 3D · Buildings3D / B3D_building_hospital / OmniLight3D | 0 | 0 | 4 | 0 | a 2 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / Book_Stack / Book_Stack | 2 | 0 | 3 | 0 | a 1 m de Biblioteca |
| 3D · Buildings3D / Bookcase / Bookcase | 22 | 2 | 1 | 0 | a 2 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Nature3D / Prop3D_weak_wall / MeshInstance3D | 0 | 3 | 0 | 0 | a 56 m de Casa de Comidas 'El Fogón del Valle' |
| 3D · Buildings3D / Crate_Wooden2 / Crate_Wooden | 0 | 0 | 3 | 0 | a 3 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Buildings3D / Shelf_Simple2 / Shelf_Simple | 0 | 0 | 3 | 0 | a 3 m de Comisaría de Policía y  Cárcel del Valle |
| 3D · Buildings3D / Cauldron2 / Cauldron | 1 | 0 | 3 | 0 | a 6 m de Casa de Comidas 'El Fogón del Valle' |
| 3D · Buildings3D / Loft3D_building_tavern / OmniLight3D | 0 | 0 | 2 | 0 | a 5 m de Gran Posada, Taberna y Casino 'El Jabalí Dorado' |
| 3D · Buildings3D / BookStand2 / BookStand | 1 | 0 | 2 | 0 | a 2 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / B3D_building_abandoned_mill / OmniLight3D | 1 | 0 | 1 | 1 | a 3 m de Molino Viejo Abandonado |
| 3D · Buildings3D / Cabinet2 / Cabinet | 14 | 0 | 2 | 0 | a 2 m de Hospital de Urgencias y  Morgue Forense |
| 3D · Buildings3D / Pot / Pot | 0 | 0 | 2 | 0 | a 7 m de Casa de Comidas 'El Fogón del Valle' |
| 3D · Nature3D / Prop3D_weapon_sword / MeshInstance3D | 0 | 2 | 0 | 0 | a 74 m de Casa de Comidas 'El Fogón del Valle' |
| 3D · Buildings3D / RoofCap_house_family_lot_m6 / MeshInstance3D | 0 | 2 | 0 | 0 | a 63 m de Biblioteca |
| Lógica 2D ·  /  / Area2D | 31 | 2 | 0 | 0 | a 57 m de Granja del Sur |

## Muebles fuera de todo edificio hoy (sin mover nada)

Total: **14** muebles con modelo 3D fuera de la planta de cualquier edificio (con 40 px de margen).

| Mueble | Cuántos | Ejemplo |
|---|---:|---|
| CandleStick_Triple | 2 | a 54 m de Botica y Casa-Jardín 'Raíz Verde' |
| CandleStick | 3 | a 53 m de Botica y Casa-Jardín 'Raíz Verde' |
| Bed_Twin1 | 1 | a 54 m de Botica y Casa-Jardín 'Raíz Verde' |
| BookStand | 1 | a 56 m de Botica y Casa-Jardín 'Raíz Verde' |
| Book | 1 | a 55 m de Botica y Casa-Jardín 'Raíz Verde' |
| Book_Stack | 1 | a 59 m de Botica y Casa-Jardín 'Raíz Verde' |
| Chair | 1 | a 59 m de Botica y Casa-Jardín 'Raíz Verde' |
| Chalice | 1 | a 55 m de Botica y Casa-Jardín 'Raíz Verde' |
| Nightstand_Shelf | 1 | a 53 m de Botica y Casa-Jardín 'Raíz Verde' |
| Table_Large | 1 | a 58 m de Botica y Casa-Jardín 'Raíz Verde' |
| altar-stone | 1 | a 55 m de Botica y Casa-Jardín 'Raíz Verde' |

## Números de posición en el código (sin la carpeta de menús)

Total: **1830** puntos (Vector2 con algún valor ≥ 100 px) y **103** rectángulos fijos; **162** llamadas a la traducción.

| Archivo | Puntos | Rectángulos | Traducciones |
|---|---:|---:|---:|
| `scripts/visuals/WorldStageTerrain3D.gd` | 461 | 27 | 0 |
| `scripts/systems/VillageWorldBuilder.gd` | 230 | 18 | 5 |
| `scripts/visuals/WorldStageBuildings3D.gd` | 232 | 0 | 75 |
| `scripts/systems/EcosystemManager.gd` | 174 | 0 | 0 |
| `scripts/systems/VillageLots.gd` | 121 | 16 | 4 |
| `scripts/systems/VillageTavern.gd` | 71 | 6 | 0 |
| `scripts/obstacles/FishingSpot.gd` | 60 | 1 | 0 |
| `scripts/systems/VillageRestaurant.gd` | 49 | 0 | 0 |
| `scripts/systems/VillageCulture.gd` | 41 | 1 | 1 |
| `scripts/visuals/WorldStageProps3D.gd` | 40 | 0 | 1 |
| `scripts/systems/VillagePlaces.gd` | 32 | 1 | 0 |
| `scripts/systems/VillageManagerEconomy.gd` | 32 | 0 | 0 |
| `scripts/systems/VillageManager.gd` | 28 | 1 | 0 |
| `scripts/systems/VillageManagerBase.gd` | 25 | 0 | 14 |
| `scripts/systems/VillageUnderworld.gd` | 24 | 1 | 1 |
| `scripts/enemies/VillageNPCBase.gd` | 24 | 0 | 0 |
| `scripts/systems/VillageJustice.gd` | 20 | 1 | 5 |
| `scripts/systems/VillageMigration.gd` | 21 | 0 | 6 |
| `scripts/visuals/WorldStageBase3D.gd` | 19 | 1 | 2 |
| `scripts/systems/VillageManagerSocial.gd` | 16 | 1 | 0 |
| `scripts/obstacles/PlayerCart.gd` | 5 | 8 | 0 |
| `scripts/systems/VillageWork.gd` | 12 | 0 | 0 |
| `scripts/obstacles/CampSite.gd` | 12 | 0 | 0 |
| `scripts/visuals/WorldStage3D.gd` | 7 | 5 | 0 |
| `scripts/systems/VillageHousing.gd` | 7 | 1 | 19 |
| `scripts/World.gd` | 7 | 0 | 0 |
| `scripts/enemies/VillageNPCDuties.gd` | 4 | 3 | 0 |
| `scripts/systems/VillageNeeds.gd` | 6 | 0 | 5 |
| `mapa/anclas.gd` | 2 | 4 | 0 |
| `scripts/enemies/VillageNPCSocial.gd` | 5 | 0 | 0 |
| `scripts/systems/VillageClub.gd` | 5 | 0 | 0 |
| `scripts/enemies/VillageNPC.gd` | 3 | 2 | 1 |
| `scripts/enemies/VillageNPCWork.gd` | 3 | 1 | 0 |
| `scripts/enemies/WildAnimal.gd` | 3 | 0 | 0 |
| `mapa/referencia.gd` | 2 | 1 | 0 |
| `scripts/Player.gd` | 2 | 1 | 0 |
| `scripts/systems/VillageCase1.gd` | 3 | 0 | 0 |
| `scripts/systems/VillageNobility.gd` | 2 | 0 | 1 |
| `scripts/systems/VillageManagerPolice.gd` | 2 | 0 | 0 |
| `scripts/systems/VillageCivic.gd` | 2 | 0 | 4 |
| `scripts/enemies/DomesticPet.gd` | 2 | 0 | 0 |
| `scripts/fisica/Agua.gd` | 1 | 1 | 0 |
| `scripts/obstacles/FarmPlot.gd` | 2 | 0 | 0 |
| `scripts/obstacles/ChickenCoop.gd` | 2 | 0 | 0 |
| `scripts/obstacles/HarvestableNode.gd` | 1 | 0 | 0 |
| `scripts/systems/DetectiveCaseData.gd` | 1 | 0 | 0 |
| `scripts/enemies/Raider.gd` | 1 | 0 | 0 |
| `scripts/enemies/VidaAnimal.gd` | 1 | 0 | 0 |
| `scripts/systems/RaidController.gd` | 1 | 0 | 0 |
| `scripts/systems/VillageTrades.gd` | 1 | 0 | 0 |
| `scripts/systems/VillageDesires.gd` | 1 | 0 | 0 |
| `scripts/systems/VillageLineage.gd` | 1 | 0 | 2 |
| `scripts/systems/ai/EnemyAI.gd` | 0 | 1 | 0 |
| `scripts/systems/combat/CombatFeel.gd` | 1 | 0 | 0 |

