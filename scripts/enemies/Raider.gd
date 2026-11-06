extends CharacterBody2D

## Asaltante de una incursión (2026-11-05, Regla «todo es físico»). Bandidos o jabalíes que entran de verdad por el
## camino del este al atardecer y avanzan hacia la plaza. Pelean con guardias, vecinos con arrojo y el jugador; se
## les puede herir con cualquier arma (Hurtbox). Huyen malheridos. Si uno llega a la plaza, saquea.
## Lo coordina RaidController: él decide cuándo se ha ganado o perdido el asalto.

const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")
const BanditModel3DScript = preload("res://scripts/visuals/BanditModel3D.gd")

signal gone(raider: Node, outcome: String) # "killed", "fled", "looted"

const LOOT_POS: Vector2 = Vector2(465, 48) # la plaza
const ENGAGE_RADIUS: float = 110.0
const MELEE_RANGE: float = 22.0

var kind: String = "bandit" # "bandit" o "boar"
var max_hp: float = 40.0
var hp: float = 40.0
var speed: float = 62.0
var hit_damage: float = 7.0
var flee_x: float = 1900.0
var is_dead: bool = false
var fleeing: bool = false
var hit_by_player: bool = false
var facing: Vector2 = Vector2.LEFT
var attack_anim: float = 0.0
var sprite: Sprite2D = null
var target: Node2D = null
var _retarget_t: float = 0.0
var _attack_t: float = 0.6
var _windup_t: float = 0.0
var stagger_timer: float = 0.0
var _done: bool = false


func setup(p_kind: String, pos: Vector2, hp_mult: float = 1.0) -> void:
	kind = p_kind
	name = "Raider_%s_%d" % [kind, get_instance_id()]
	global_position = pos
	flee_x = pos.x + 140.0
	add_to_group("raiders")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = 0
	if kind == "boar":
		max_hp = 34.0 * hp_mult
		speed = 74.0
		hit_damage = 9.0
	else:
		max_hp = 42.0 * hp_mult
		speed = 60.0
		hit_damage = 7.0
	hp = max_hp
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	if kind == "boar":
		sprite.texture = load("res://assests/world/harvest/wild_boar.png")
		sprite.scale = Vector2(1.25, 1.25)
	else:
		sprite.texture = load("res://assests/world/village/villager_guard.png")
		sprite.modulate = Color(0.55, 0.32, 0.30) # ropa oscura de bandido
	add_child(sprite)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 4
	hb.collision_mask = 0
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 11.0
	col.shape = c
	hb.add_child(col)
	hb.hit_received.connect(take_damage)
	add_child(hb)
	if kind == "boar":
		var m = AnimalModel3DScript.attach(self, "animals/animated/Wolf.glb", 14.0, 8.0)
		if m != null:
			m.walk_px_s = 40.0
			m.run_px_s = 66.0
	else:
		BanditModel3DScript.attach(self)


func take_damage(data: DamageData) -> void:
	if is_dead or _done:
		return
	var amount: float = data.amount if data != null else 10.0
	if data != null and is_instance_valid(data.source) and data.source.is_in_group("player"):
		hit_by_player = true
	hp -= amount
	if sprite:
		sprite.modulate = Color(1.0, 0.45, 0.45)
		get_tree().create_timer(0.12).timeout.connect(func():
			if is_instance_valid(sprite):
				sprite.modulate = Color.WHITE if kind == "boar" else Color(0.55, 0.32, 0.30))
	if hp <= 0.0:
		_die()
	elif hp < max_hp * 0.3 and not fleeing:
		fleeing = true
		target = null


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	if sprite:
		sprite.rotation_degrees = 90.0
		sprite.modulate = Color(0.6, 0.45, 0.45, 0.95)
	var hb = get_node_or_null("Hurtbox")
	if hb:
		hb.set_deferred("monitorable", false)
	_finish("killed")
	get_tree().create_timer(30.0).timeout.connect(func():
		if is_instance_valid(self):
			queue_free())


func _finish(outcome: String) -> void:
	if _done:
		return
	_done = true
	gone.emit(self, outcome)


func apply_parry_stagger(duration: float = 0.8) -> void:
	stagger_timer = maxf(stagger_timer, duration)
	_windup_t = 0.0
	_attack_t = maxf(_attack_t, duration)
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = Color(0.65, 0.85, 1.35)


func _physics_process(delta: float) -> void:
	if is_dead or _done:
		return
	if stagger_timer > 0.0:
		stagger_timer = maxf(0.0, stagger_timer - delta)
		_windup_t = 0.0
		velocity = Vector2.ZERO
		if stagger_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE if kind == "boar" else Color(0.55, 0.32, 0.30)
		return
	attack_anim = maxf(0.0, attack_anim - delta * 2.5)
	if fleeing:
		_windup_t = 0.0
		_move_to(Vector2(flee_x, global_position.y), speed * 1.2, delta)
		if global_position.x >= flee_x - 4.0:
			_finish("fled")
			queue_free()
		return
	if _windup_t > 0.0:
		_windup_t = maxf(0.0, _windup_t - delta)
		velocity = Vector2.ZERO
		if _windup_t <= 0.0:
			_attack_t = 1.1
			if sprite:
				sprite.modulate = Color.WHITE if kind == "boar" else Color(0.55, 0.32, 0.30)
			if target != null and is_instance_valid(target) and global_position.distance_to(target.global_position) <= MELEE_RANGE + 6.0:
				_hit(target)
		return
	_retarget_t -= delta
	if _retarget_t <= 0.0:
		_retarget_t = 0.4
		target = _pick_target()
	if target != null and is_instance_valid(target):
		var d: float = global_position.distance_to(target.global_position)
		if d > MELEE_RANGE:
			_move_to(target.global_position, speed, delta)
		else:
			velocity = Vector2.ZERO
			_attack_t -= delta
			if _attack_t <= 0.0:
				_windup_t = 0.40
				attack_anim = 1.0
				if sprite:
					sprite.modulate = Color(1.35, 0.88, 0.42)
		return
	_move_to(LOOT_POS, speed, delta)
	if global_position.distance_to(LOOT_POS) <= 30.0:
		_finish("looted")
		queue_free()


func _move_to(p: Vector2, spd: float, delta: float) -> void:
	var dir: Vector2 = p - global_position
	if dir.length() < 1.0:
		velocity = Vector2.ZERO
		return
	velocity = dir.normalized() * spd
	facing = velocity.normalized()
	global_position += velocity * delta
	if sprite:
		sprite.flip_h = velocity.x > 0.0


## Lo más cercano a lo que pegar: el jugador o un vecino que esté defendiendo (guardias y vecinos con arrojo).
func _pick_target() -> Node2D:
	var best: Node2D = null
	var best_d: float = ENGAGE_RADIUS
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if pl != null and pl.get("is_dead") != true:
		var dp: float = global_position.distance_to(pl.global_position)
		if dp < best_d:
			best_d = dp
			best = pl
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if not (n is VillageNPC) or n.is_dead or n.is_downed or not n.is_conscious():
			continue
		if n.errand_kind != "raid_defend" and not (int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]):
			continue
		var dn: float = global_position.distance_to(n.global_position)
		if dn < best_d:
			best_d = dn
			best = n
	return best


func _hit(t: Node2D) -> void:
	attack_anim = 1.0
	if not t.has_method("take_damage"):
		return
	var d := DamageData.new()
	d.amount = hit_damage
	d.weapon_tag = "Embestida de jabalí" if kind == "boar" else "Tajo de bandido"
	d.source = self
	t.call("take_damage", d)
