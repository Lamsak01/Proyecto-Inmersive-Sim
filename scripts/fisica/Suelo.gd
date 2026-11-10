extends RefCounted

## Suelo: a qué altura está el suelo que pisa alguien en un punto del mapa (en píxeles de altura, sin contar el relieve,
## que lo suma el escenario). Un solo sitio para el cuerpo 3D del protagonista y para los muñecos 3D.
## Paso del mundo a 3D, paso 1 (docs/PLAN_MUNDO_3D.md), 2026-11-10. Hasta el paso 2 los pisos son «capas»
## (elevation_level): la taberna tiene planta alta y escalera; dentro de los edificios hay tarima; los puentes y la plaza
## están algo más altos que el suelo.

const VillageTavern = preload("res://scripts/systems/VillageTavern.gd")
const VillageRestaurant = preload("res://scripts/systems/VillageRestaurant.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const TARIMA_EDIFICIO_PX: float = 2.65 ## suelo de madera dentro de los edificios
const TARIMA_TERRAZA_PX: float = 1.8  ## terraza del restaurante


## Altura del suelo (píxeles de altura sobre el relieve) en `pos` para alguien en la capa `nivel`.
static func altura_px(pos: Vector2, nivel: int, vm: Node) -> float:
	var h_taberna: float = VillageTavern.elevation_height_for(pos, nivel)
	if h_taberna > 0.0:
		return h_taberna
	if nivel != 0:
		return 0.0
	if vm != null and vm.has_method("_is_pos_inside_any_building") and bool(vm.call("_is_pos_inside_any_building", pos)):
		return TARIMA_EDIFICIO_PX
	if VillageRestaurant.TERRACE.grow(6.0).has_point(pos):
		return TARIMA_TERRAZA_PX
	return WorldStageBase3D.surface_elevation_offset_px(pos)
