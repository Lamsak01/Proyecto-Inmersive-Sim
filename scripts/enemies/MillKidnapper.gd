extends "res://scripts/enemies/Raider.gd"

## Caso I (Claude Code, 2026-11-09): uno de los dos secuestradores forasteros escondidos en el molino viejo, esperando
## órdenes. Reutiliza el bandido de las incursiones (mismo combate, modelo 3D y huida cuando está malherido), pero no va
## a saquear la plaza: se queda en el molino y solo ataca si ve al jugador cerca (menos si va agachado/sigiloso).

const SIGHT_RADIUS: float = 64.0
const SIGHT_RADIUS_STEALTH: float = 26.0

var kidnapper_id: String = ""
var display_name: String = ""
var home_pos: Vector2 = Vector2.ZERO


func setup_kidnapper(k_id: String, label: String, pos: Vector2) -> void:
	setup("bandit", pos, 1.0)
	kidnapper_id = k_id
	display_name = label
	home_pos = pos
	flee_x = pos.x + 260.0
	remove_from_group("raiders") # no cuenta para las incursiones
	add_to_group("case1_kidnappers")


func _pick_target() -> Node2D:
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if pl == null or pl.get("is_dead") == true:
		return null
	var radius: float = SIGHT_RADIUS
	if pl.has_method("is_stealthing") and bool(pl.call("is_stealthing")):
		radius = SIGHT_RADIUS_STEALTH
	if hit_by_player:
		radius = ENGAGE_RADIUS # si le has atacado, te persigue
	return pl if global_position.distance_to(pl.global_position) <= radius else null


func _physics_process(delta: float) -> void:
	if is_dead or _done:
		return
	if fleeing or stagger_timer > 0.0 or _windup_t > 0.0 or _recover_t > 0.0:
		super._physics_process(delta)
		return
	var t := _pick_target()
	if t != null:
		super._physics_process(delta)
		return
	# Sin nadie a la vista: vuelve a su sitio junto al hogar y espera (nunca va a la plaza)
	target = null
	if global_position.distance_to(home_pos) > 4.0:
		_move_to(home_pos, speed * 0.6, delta)
	else:
		velocity = Vector2.ZERO
