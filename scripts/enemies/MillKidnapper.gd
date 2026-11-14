extends "res://scripts/enemies/Raider.gd"

## Caso I (Claude Code, 2026-11-09): uno de los dos secuestradores forasteros escondidos en el molino viejo, esperando
## órdenes. Reutiliza el bandido de las incursiones (mismo combate, modelo 3D y huida cuando está malherido), pero no va
## a saquear la plaza: se queda en el molino y solo ataca si ve al protagonista cerca (menos si va agachado/sigiloso).
## Como el bandido, desde la tanda 4b-3b del paso a 3D ES su cuerpo 3D y vive en metros.

const SIGHT_RADIUS: float = 3.58         ## a esta distancia ve al protagonista
const SIGHT_RADIUS_STEALTH: float = 1.46 ## y a esta, si va agachado
const HUIDA_M: float = 14.56             ## huye más lejos que un bandido de incursión
const VUELTA_PASO: float = 0.6           ## vuelve a su sitio sin prisa
const EN_SU_SITIO_M: float = 0.22

var kidnapper_id: String = ""
var display_name: String = ""
var home_pos: Vector2 = Vector2.ZERO     ## su sitio junto al hogar del molino (metros sobre el suelo)


func setup_kidnapper(k_id: String, label: String, donde: Vector2) -> void:
	setup("bandit", donde, 1.0)
	kidnapper_id = k_id
	display_name = label
	home_pos = donde
	flee_x = donde.x + HUIDA_M
	remove_from_group("raiders") # no cuenta para las incursiones
	add_to_group("case1_kidnappers")


func _pick_target() -> Node:
	var pl: Node = get_tree().get_first_node_in_group("player")
	if pl == null or pl.get("is_dead") == true:
		return null
	var radio: float = SIGHT_RADIUS
	if pl.has_method("is_stealthing") and bool(pl.call("is_stealthing")):
		radio = SIGHT_RADIUS_STEALTH
	if hit_by_player:
		radio = ENGAGE_RADIUS # si le has atacado, te persigue
	return pl if sitio.distance_to(Lugar.de(pl)) <= radio else null


## Sin nadie a la vista no va a la plaza: vuelve a su sitio junto al hogar y espera.
func _ir_a_lo_suyo(delta: float) -> void:
	if _pick_target() != null:
		super._ir_a_lo_suyo(delta)
		return
	target = null
	if sitio.distance_to(home_pos) > EN_SU_SITIO_M:
		_ir_hacia(home_pos, speed * VUELTA_PASO)
