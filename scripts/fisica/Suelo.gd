extends RefCounted

## Suelo: a qué altura está el suelo que pisa alguien en un punto del mapa (en píxeles de altura, sin contar el relieve,
## que lo suma el escenario). Un solo sitio para el cuerpo 3D del protagonista y para los muñecos 3D.
## Paso del mundo a 3D (docs/PLAN_MUNDO_3D.md), 2026-11-10.
## - Paso 1: los pisos son «capas» (elevation_level); dentro de los edificios hay tarima; los puentes y la plaza están algo
##   más altos que el suelo.
## - Paso 2: donde hay varios suelos uno encima de otro (por ahora la posada: Planta 0, escalera y Planta +1), el cuerpo
##   3D pisa el que tiene debajo según su altura, y de ahí sale su piso. Los choques del mapa que son de un solo piso
##   (tabiques de la Planta 0, barandillas y cuartos de la Planta +1) se levantan solo a la altura de ese piso.
## - Paso 2b: el club de peleas (bajo la posada) y las alcantarillas (bajo el centro) están de verdad bajo tierra, a
##   PROFUNDIDAD_SOTANO_PX. Se sigue llegando por la trampilla o la reja con [E]. El sótano de tu casa aún no (paso 2e).

const VillageTavern = preload("res://scripts/systems/VillageTavern.gd")
const VillageRestaurant = preload("res://scripts/systems/VillageRestaurant.gd")
const WorldStageBase3D = preload("res://scripts/visuals/WorldStageBase3D.gd")

const TARIMA_EDIFICIO_PX: float = 2.65 ## suelo de madera dentro de los edificios
const TARIMA_TERRAZA_PX: float = 1.8  ## terraza del restaurante

## Capa 20 del mapa: la llevan siempre los choques de un solo piso, aunque estén «apagados» para el mapa (capa 1) porque
## el protagonista está en otro piso. Solo la mira el cuerpo 3D, que los levanta a la altura de su piso.
const CAPA_PISOS: int = 1 << 19
const PISO_TODOS: int = -99 ## choque normal: de arriba abajo
const PROFUNDIDAD_SOTANO_PX: float = -30.0 ## suelo del club y de las alcantarillas: ~3,2 m bajo la calle


## Altura del suelo (píxeles de altura sobre el relieve) en `pos` para alguien en la capa `nivel`.
static func altura_px(pos: Vector2, nivel: int, vm: Node) -> float:
	if nivel == -1:
		return PROFUNDIDAD_SOTANO_PX if es_bajo_tierra(pos, vm) else 0.0
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


## ¿Está `pos` en un sitio que de verdad está bajo tierra (club de peleas o alcantarillas)? Se mira a través del pueblo
## (`vm`) para no atar este archivo a esos sistemas.
static func es_bajo_tierra(pos: Vector2, vm: Node) -> bool:
	if vm == null or not ("VillageClub" in vm) or not ("VillageUnderworld" in vm):
		return false
	if Rect2(vm.VillageClub.CLUB_CENTER - vm.VillageClub.CLUB_SIZE * 0.5, vm.VillageClub.CLUB_SIZE).grow(12.0).has_point(pos):
		return true
	return vm.VillageUnderworld.zona_alcantarillas().has_point(pos)


## Suelos que hay en `pos` uno encima de otro (px sobre el relieve, de abajo arriba). Vacío si ahí solo hay uno.
static func pisos_en(pos: Vector2) -> Array[float]:
	return VillageTavern.floor_heights_at(pos)


## De los `pisos`, el que pisa alguien cuyos pies están a `alto_px`: el más alto al que llega subiendo como mucho
## `paso_px` (un peldaño); si no llega a ninguno, el de más abajo (y cae hasta él).
static func elegir(pisos: Array[float], alto_px: float, paso_px: float) -> float:
	var mejor: float = pisos[0]
	for h in pisos:
		if h <= alto_px + paso_px and h > mejor:
			mejor = h
	return mejor


## Piso (0 o +1) de alguien que pisa un suelo a `alto_px` donde hay varios.
static func nivel_de(alto_px: float) -> int:
	return 1 if alto_px > VillageTavern.FLOOR_1_H * 0.5 else 0


## Capa del mapa de un choque de un solo piso: la 1 si cuenta ahora para el mapa (`activo`), y siempre la 20.
static func capa(activo: bool) -> int:
	return (1 if activo else 0) | CAPA_PISOS


## ¿Es una barandilla (baja, se puede saltar por encima)?
static func es_barandilla(n: Object) -> bool:
	return n is Node and (n as Node).is_in_group("barandilla")


## De qué piso es un choque del mapa (0, +1 o PISO_TODOS).
static func piso_de_choque(n: Object) -> int:
	if n is Node:
		if (n as Node).is_in_group("tavern_upper_walls"):
			return 1
		if (n as Node).is_in_group("tavern_floor0_walls"):
			return 0
	return PISO_TODOS
