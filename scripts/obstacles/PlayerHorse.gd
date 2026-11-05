extends Node2D

## Caballo de silla del jugador (2026-11-05). Regla 2 «Todo es físico»: el caballo existe en el mapa; con [E] a su lado
## montas y con [E] otra vez desmontas. Solo montado vas más rápido (PlayerMovementController) y no puedes ir en sigilo.
## Desmontas solo al entrar en un edificio, al acostarte o si te escolta la guardia; el caballo se queda donde lo dejas.
## Su posición y si ibas montado se guardan en VillageCulture.mounts_state (pos_x, pos_y, is_mounted).
## Aspecto: modelo 3D animado (AnimalModel3D, caballo de Quaternius); en 2D (F10) un dibujo provisional teñido.

const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")
const MOUNT_RANGE: float = 26.0

var vm: Node = null
var sprite: Sprite2D = null
var interact_area: Area2D = null
var model_3d: Node = null
var _player: Node2D = null
## Última posición del jinete fuera de un edificio: ahí se queda el caballo si desmontas al entrar.
var _last_outside_pos: Vector2 = Vector2.ZERO


func setup(p_vm: Node, pos: Vector2) -> void:
	vm = p_vm
	name = "PlayerHorse"
	global_position = pos
	_last_outside_pos = pos
	add_to_group("player_horse")
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://assests/world/harvest/wild_deer.png")
	sprite.modulate = Color(0.62, 0.42, 0.28) # provisional: no hay dibujo 2D de caballo
	sprite.scale = Vector2(1.35, 1.35)
	sprite.position = Vector2(0, -6)
	add_child(sprite)
	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 14.0
	col.shape = c
	interact_area.add_child(col)
	add_child(interact_area)
	model_3d = AnimalModel3DScript.attach(self, "animals/animated/Horse.glb", 27.0, 4.0)
	if model_3d != null:
		model_3d.walk_px_s = 100.0
		model_3d.run_px_s = 200.0


func _mstate() -> Dictionary:
	return vm.VillageCulture.mounts_state(vm)


func is_ridden() -> bool:
	return is_instance_valid(_player) and bool(_player.get("is_mounted"))


## Texto del letrero de [E] (InteractionSelector).
func get_interact_label(player: Node2D) -> String:
	return "Bajar del caballo" if bool(player.get("is_mounted")) else "Montar a caballo"


## [E] junto al caballo: montar; [E] montado: desmontar.
func interact(player: Node2D) -> void:
	if player == null:
		return
	if bool(player.get("is_mounted")):
		dismount(player)
		return
	if player.global_position.distance_to(global_position) > MOUNT_RANGE:
		return
	if vm != null and _is_inside_building(player.global_position):
		_say(player, "🐎 Aquí dentro no se puede montar")
		return
	mount(player)


func mount(player: Node2D) -> void:
	_player = player
	player.set("is_mounted", true)
	var mc = player.get_node_or_null("PlayerMovementController")
	if mc != null:
		mc.set("is_stealthing", false)
	_mstate()["is_mounted"] = true
	global_position = player.global_position
	_say(player, "🐎 Montas a caballo ([E] para bajar)")


func dismount(player: Node2D, stay_at: Vector2 = Vector2.INF) -> void:
	if player != null:
		player.set("is_mounted", false)
	_player = null
	if stay_at != Vector2.INF:
		global_position = stay_at
	var m: Dictionary = _mstate()
	m["is_mounted"] = false
	m["pos_x"] = global_position.x
	m["pos_y"] = global_position.y
	if player != null:
		_say(player, "🐎 Bajas del caballo; te espera aquí")


func _physics_process(_delta: float) -> void:
	if vm == null:
		return
	if not is_ridden():
		return
	var p: Vector2 = _player.global_position
	# Bajadas automáticas: entrar en un edificio, acostarse o ir escoltado por la guardia.
	var hc = _player.get_node_or_null("HealthComponent")
	if _is_inside_building(p):
		dismount(_player, _last_outside_pos)
		return
	if (hc != null and bool(hc.get("is_resting_in_bed"))) or bool(vm.get("player_being_escorted_to_jail")) or bool(vm.get("player_in_jail")):
		dismount(_player, p)
		return
	_last_outside_pos = p
	global_position = p
	var m: Dictionary = _mstate()
	m["pos_x"] = p.x
	m["pos_y"] = p.y


func _is_inside_building(p: Vector2) -> bool:
	if not ("building_footprints" in vm):
		return false
	for b in vm.building_footprints:
		if (b["rect"] as Rect2).grow(-3.0).has_point(p):
			return true
	return false


## Hacia dónde mira el caballo en el mapa (para sentar al jinete mirando igual).
func get_facing_2d() -> Vector2:
	if model_3d != null and model_3d.has_method("get_facing_2d"):
		return model_3d.get_facing_2d()
	return Vector2.DOWN


func _say(player: Node2D, txt: String) -> void:
	if player.has_method("show_hint"):
		player.show_hint(txt)
