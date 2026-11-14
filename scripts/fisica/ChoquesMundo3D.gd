extends Node3D

## ChoquesMundo3D: el juego de paredes 3D del mundo, UNO SOLO y compartido por todos los cuerpos (paso a 3D, tanda 3a,
## 2026-11-14). Sustituye a ChoquesCercanos3D, donde cada cuerpo copiaba para sí, en cada paso, las paredes del mapa plano.
## - El mundo se reparte en celdas. Cuando un cuerpo anda por una celda, sus choques se levantan una vez y se quedan
##   mientras alguien siga cerca; se repasan cada pocos pasos (puertas que se abren, árboles talados…). Desde la tanda 4
##   todos los personajes llevan cuerpo: donde solo andan vecinos o animales sin tocar nada, se repasa despacio.
## - ATAJO pendiente (docs/specs/PLAN_TODO_3D.md): cada pared aún nace de su choque del mapa plano («gemelo»). Cuando cada
##   fuente dé su choque desde su pieza 3D, este archivo solo las guardará.
## - Alturas de verdad: cada choque ocupa su franja (toda la altura, solo planta baja, solo planta alta, bajo tierra,
##   barandilla), así que ya no hace falta saber en qué piso está quien choca. El agua va en su capa: frena a los vecinos.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const Suelo = preload("res://scripts/fisica/Suelo.gd")
const Prismas3D = preload("res://scripts/fisica/Prismas3D.gd")
const AlturasChoque3D = preload("res://scripts/fisica/AlturasChoque3D.gd")

const NOMBRE: String = "ChoquesMundo3D"
const CAPA_MUROS: int = 4          ## capa 3D de las paredes: frenan al protagonista y a los vecinos
const CAPA_AGUA: int = 16          ## capa 3D del agua: solo frena a los vecinos (el protagonista entra y nada)
const CELDA_PX: float = 128.0      ## lado de cada celda del mundo (~7 m)
const MARGEN_PX: float = 6.0       ## lo que la consulta de una celda se asoma a las vecinas
const MAX_POR_CELDA: int = 256
const MASCARA_MAPA: int = 1 | Suelo.CAPA_PISOS ## capas del mapa plano donde viven las paredes
const REPASO_PROTA: int = 2        ## pasos entre repasos de una celda donde está el protagonista (puertas al instante)
const REPASO_VECINO: int = 6       ## de una donde un vecino o un animal está tocando algo (una puerta que se le abre)
const REPASO_TRANQUILO: int = 30   ## y de una donde solo andan sin tocar nada
const CELDA_CADUCA: int = 600      ## pasos sin nadie cerca tras los que una celda suelta sus paredes (10 s)
const LIMPIEZA_CADA: int = 30

var _gemelos: Dictionary = {}      ## «rid:forma» → StaticBody3D
var _usos: Dictionary = {}         ## «rid:forma» → en cuántas celdas está
var _celdas: Dictionary = {}       ## Vector2i → {claves, visto, repaso}
var _consulta := PhysicsShapeQueryParameters2D.new()


## El juego de paredes del mundo que cuelga de `padre` (lo crea la primera vez).
static func de(padre: Node) -> Node3D:
	var m: Node3D = padre.get_node_or_null(NOMBRE) as Node3D
	if m == null:
		m = new()
		m.name = NOMBRE
		padre.add_child(m)
	return m


func _init() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2.ONE * (CELDA_PX + MARGEN_PX * 2.0)
	_consulta.shape = rect
	_consulta.collision_mask = MASCARA_MAPA
	_consulta.collide_with_areas = false
	_consulta.collide_with_bodies = true


## Un cuerpo avisa de que está en `centro` y necesita las paredes a `radio_px` a la redonda, repasadas como mucho hace
## `repaso` pasos (REPASO_PROTA, REPASO_VECINO o REPASO_TRANQUILO).
func interes(espacio: PhysicsDirectSpaceState2D, centro: Vector2, radio_px: float, repaso: int) -> void:
	var paso: int = Engine.get_physics_frames()
	var c0: Vector2i = Vector2i(((centro - Vector2.ONE * radio_px) / CELDA_PX).floor())
	var c1: Vector2i = Vector2i(((centro + Vector2.ONE * radio_px) / CELDA_PX).floor())
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var c := Vector2i(cx, cy)
			if not _celdas.has(c):
				_celdas[c] = {"claves": {}, "visto": paso, "repaso": -CELDA_CADUCA}
			var celda: Dictionary = _celdas[c]
			celda["visto"] = paso
			if paso - int(celda["repaso"]) >= repaso:
				_repasar(espacio, c, celda, paso)


## La pared 3D de un choque del mapa («rid:forma»), si está levantada.
func gemelo(clave: String) -> StaticBody3D:
	return _gemelos.get(clave) as StaticBody3D


func cuantos() -> int:
	return _gemelos.size()


func _physics_process(_delta: float) -> void:
	var paso: int = Engine.get_physics_frames()
	if paso % LIMPIEZA_CADA != 0:
		return
	for c: Vector2i in _celdas.keys():
		if paso - int((_celdas[c] as Dictionary)["visto"]) > CELDA_CADUCA:
			for clave: String in ((_celdas[c] as Dictionary)["claves"] as Dictionary):
				_soltar(clave)
			_celdas.erase(c)


## Pone al día las paredes de una celda: levanta las nuevas, recoloca las que se han movido y suelta las que ya no están.
func _repasar(espacio: PhysicsDirectSpaceState2D, c: Vector2i, celda: Dictionary, paso: int) -> void:
	_consulta.transform = Transform2D(0.0, (Vector2(c) + Vector2.ONE * 0.5) * CELDA_PX)
	var antes: Dictionary = celda["claves"]
	var ahora: Dictionary = {}
	for r: Dictionary in espacio.intersect_shape(_consulta, MAX_POR_CELDA):
		var nodo: StaticBody2D = r["collider"] as StaticBody2D
		if nodo == null: # los personajes chocan entre sí con sus cuerpos 3D, no como paredes
			continue
		var rid: RID = r["rid"]
		var idx: int = int(r["shape"])
		var clave: String = "%d:%d" % [rid.get_id(), idx]
		ahora[clave] = true
		if not antes.has(clave):
			_usos[clave] = int(_usos.get(clave, 0)) + 1
		if not _gemelos.has(clave):
			_gemelos[clave] = _levantar(rid, idx, nodo)
		_colocar(_gemelos[clave] as StaticBody3D, rid, idx)
	for clave: String in antes:
		if not ahora.has(clave):
			_soltar(clave)
	celda["claves"] = ahora
	celda["repaso"] = paso


func _soltar(clave: String) -> void:
	var quedan: int = int(_usos.get(clave, 1)) - 1
	if quedan > 0:
		_usos[clave] = quedan
		return
	_usos.erase(clave)
	var g: StaticBody3D = _gemelos.get(clave) as StaticBody3D
	_gemelos.erase(clave)
	if is_instance_valid(g):
		g.queue_free()


## Levanta la pared 3D de un choque del mapa (null si su forma no se conoce: se recuerda para no reintentarlo).
func _levantar(rid: RID, idx: int, nodo: StaticBody2D) -> StaticBody3D:
	var bajo_tierra: bool = AlturasChoque3D.es_bajo_tierra(nodo)
	var franja: Vector2 = AlturasChoque3D.franja(Suelo.piso_de_choque(nodo), bajo_tierra, Suelo.es_barandilla(nodo))
	var forma: Shape3D = Prismas3D.forma(PhysicsServer2D.body_get_shape(rid, idx), franja.y)
	if forma == null:
		return null
	var cuerpo := StaticBody3D.new()
	cuerpo.collision_layer = CAPA_AGUA if nodo.is_in_group("agua_2d") else CAPA_MUROS
	cuerpo.collision_mask = 0
	cuerpo.set_meta("desde_m", franja.x)
	cuerpo.set_meta("bajo_tierra", bajo_tierra)
	var cs := CollisionShape3D.new()
	cs.shape = forma
	cuerpo.add_child(cs)
	add_child(cuerpo)
	return cuerpo


## Coloca la pared donde está ahora su choque del mapa; si no se ha movido desde la última vez, no hace nada.
func _colocar(cuerpo: StaticBody3D, rid: RID, idx: int) -> void:
	if cuerpo == null:
		return
	var t2: Transform2D = (PhysicsServer2D.body_get_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM) as Transform2D) \
		* PhysicsServer2D.body_get_shape_transform(rid, idx)
	if cuerpo.has_meta("t2") and (cuerpo.get_meta("t2") as Transform2D).is_equal_approx(t2):
		return
	cuerpo.set_meta("t2", t2)
	var o3: Vector3 = Mapa3D.a_3d(t2.origin)
	var en_mapa: Vector2 = t2 * Prismas3D.centro(PhysicsServer2D.body_get_shape(rid, idx))
	var vm: Node = get_tree().get_first_node_in_group("village_manager")
	o3.y = AlturasChoque3D.suelo_y(en_mapa, bool(cuerpo.get_meta("bajo_tierra")), vm) + float(cuerpo.get_meta("desde_m"))
	cuerpo.global_transform = Transform3D(Basis(Mapa3D.dir_a_3d(t2.x), Vector3.UP, Mapa3D.dir_a_3d(t2.y)), o3)
