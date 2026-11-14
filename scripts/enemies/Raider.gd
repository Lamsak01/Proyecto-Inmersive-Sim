extends CharacterBody2D
const AndarMapa = preload("res://scripts/fisica/AndarMapa.gd") # paso a 3D, tanda 4: todos andan siempre con su cuerpo 3D
const _CombatFeel = preload("res://scripts/systems/combat/CombatFeel.gd") # C7 fase 2: rivales con las mismas reglas

## Asaltante de una incursión (2026-11-05, Regla «todo es físico»). Bandidos o jabalíes que entran de verdad por el
## camino del este al atardecer y avanzan hacia la plaza. Pelean con guardias, vecinos con arrojo y el jugador; se
## les puede herir con cualquier arma (su diana 3D). Huyen malheridos. Si uno llega a la plaza, saquea.
## Lo coordina RaidController: él decide cuándo se ha ganado o perdido el asalto.
## 2026-11-10: se mueven con física (chocan con paredes y muebles, capa 1); si huyendo se quedan parados contra un
## muro HUIDA_ATASCO_S segundos, se dan por huidos (antes atravesaban las paredes).

const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")
const BanditModel3DScript = preload("res://scripts/visuals/BanditModel3D.gd")

signal gone(raider: Node, outcome: String) # "killed", "fled", "looted"

const Sitio = preload("res://mapa/sitio.gd")
const SITIO_BOTIN := "botin_plaza" ## cruz de «Sitios»: a dónde van a saquear (la plaza)
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
var disarmed_until_msec: int = 0 ## C7 fase 4c: el bandido sin su cuchillo pega la mitad
var _recover_t: float = 0.0 ## C7 fase 2: quieto tras soltar un golpe (más si falló)
var bandit_ammo_loaded: int = 2 ## 5e: carabina vieja de bandido (2 cartuchos, poca puntería y recarga lenta)
var bandit_reload_timer: float = 0.0
var _carbine_cd: float = 1.6
## C7 fase 2: masa al recibir golpes (un jabalí apenas se mueve; un bandido, como una persona algo recia)
var hit_mass: float:
	get:
		return 2.5 if kind == "boar" else 1.1
var stagger_timer: float = 0.0
var _done: bool = false
var _huida_parada: float = 0.0 ## segundos seguidos sin avanzar mientras huye
const HUIDA_ATASCO_S: float = 2.0


func setup(p_kind: String, pos: Vector2, hp_mult: float = 1.0) -> void:
	kind = p_kind
	name = "Raider_%s_%d" % [kind, get_instance_id()]
	global_position = pos
	flee_x = pos.x + 140.0
	add_to_group("raiders")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = 1 # paredes y muebles
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
	var cuerpo := CollisionShape2D.new() # el cuerpo con el que choca contra paredes y muebles (los golpes van a su diana 3D)
	var forma := CircleShape2D.new()
	forma.radius = 6.0
	cuerpo.shape = forma
	add_child(cuerpo)
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
	Diana3D.poner_activa(self, false)
	_finish("killed")
	get_tree().create_timer(30.0).timeout.connect(func():
		if is_instance_valid(self):
			queue_free())


func _finish(outcome: String) -> void:
	if _done:
		return
	_done = true
	gone.emit(self, outcome)


func is_disarmed() -> bool:
	return Time.get_ticks_msec() < disarmed_until_msec

func disarm(seconds: float = 20.0) -> bool:
	if kind == "boar" or is_disarmed():
		return false
	disarmed_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)
	_windup_t = 0.0
	return true

func apply_parry_stagger(duration: float = 0.8, quiet: bool = false) -> void:
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
		var antes: Vector2 = global_position
		_move_to(Vector2(flee_x, global_position.y), speed * 1.2, delta)
		var paso_min: float = speed * 1.2 * delta * 0.25 # menos de un cuarto del paso esperado: está contra algo
		_huida_parada = _huida_parada + delta if global_position.distance_to(antes) < paso_min else 0.0
		if global_position.x >= flee_x - 4.0 or _huida_parada >= HUIDA_ATASCO_S:
			_finish("fled")
			queue_free()
		return
	if _recover_t > 0.0:
		_recover_t = maxf(0.0, _recover_t - delta)
		velocity = Vector2.ZERO
		return
	if _windup_t > 0.0:
		_windup_t = maxf(0.0, _windup_t - delta)
		velocity = Vector2.ZERO
		if _windup_t <= 0.0:
			_attack_t = 1.1
			if sprite:
				sprite.modulate = Color.WHITE if kind == "boar" else Color(0.55, 0.32, 0.30)
			var af: Dictionary = _CombatFeel.attack_feel("colmillos" if kind == "boar" else "bandido")
			_CombatFeel.enemy_swing(self, "colmillos" if kind == "boar" else "bandido")
			if target != null and is_instance_valid(target) and global_position.distance_to(target.global_position) <= MELEE_RANGE + 6.0:
				_hit(target)
				_recover_t = float(af["recover"])
			else:
				_recover_t = float(af["miss_recover"])
		return
	_retarget_t -= delta
	if _retarget_t <= 0.0:
		_retarget_t = 0.4
		target = _pick_target()
	if target != null and is_instance_valid(target):
		var d: float = global_position.distance_to(target.global_position)
		if kind == "bandit" and not is_disarmed():
			if bandit_reload_timer > 0.0:
				bandit_reload_timer = maxf(0.0, bandit_reload_timer - delta)
				if bandit_reload_timer <= 0.0:
					bandit_ammo_loaded = 2
			else:
				_carbine_cd = maxf(0.0, _carbine_cd - delta)
		if d > MELEE_RANGE:
			_move_to(target.global_position, speed, delta)
			if kind == "bandit" and not is_disarmed() and bandit_reload_timer <= 0.0 and _carbine_cd <= 0.0 and d >= 40.0 and d <= 125.0:
				if bandit_ammo_loaded > 0:
					bandit_ammo_loaded -= 1
					_carbine_cd = 2.2
					_fire_bandit_carbine(target, d)
					if bandit_ammo_loaded <= 0:
						bandit_reload_timer = 2.6
		else:
			velocity = Vector2.ZERO
			_attack_t -= delta
			if _attack_t <= 0.0:
				_windup_t = 0.40
				attack_anim = 1.0
				if sprite:
					sprite.modulate = Color(1.35, 0.88, 0.42)
		return
	var botin: Vector2 = Sitio.mundo(SITIO_BOTIN)
	_move_to(botin, speed, delta)
	if global_position.distance_to(botin) <= 30.0:
		_finish("looted")
		queue_free()


func _move_to(p: Vector2, spd: float, delta: float) -> void:
	var dir: Vector2 = p - global_position
	if dir.length() < 1.0:
		velocity = Vector2.ZERO
		return
	velocity = dir.normalized() * spd
	facing = velocity.normalized()
	AndarMapa.paso(self, delta) # con su cuerpo 3D: choca con paredes y muebles
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
	d.amount = hit_damage * (0.5 if is_disarmed() else 1.0)
	d.weapon_tag = "Embestida de jabalí" if kind == "boar" else "Tajo de bandido"
	d.knockback_force = float(_CombatFeel.attack_feel("colmillos" if kind == "boar" else "bandido")["push"])
	d.source = self
	t.call("take_damage", d)


func _fire_bandit_carbine(t: Node2D, dist: float) -> void:
	attack_anim = 0.85
	if not is_instance_valid(t) or not t.has_method("take_damage"):
		return
	# Carabina vieja con poca puntería: a media distancia puede errar el tiro
	var hit_chance: float = clampf(0.72 - (dist - 40.0) * 0.003, 0.35, 0.72)
	if randf() > hit_chance:
		return
	var d := DamageData.new()
	d.amount = 9.0
	d.type = CombatConstants.DamageType.CUT
	d.bleed_buildup = 10.0
	d.weapon_tag = "Carabina Vieja de Bandido"
	d.is_ranged_projectile = true
	d.is_firearm_bullet = true
	d.firearm_kind = "pistol"
	d.shot_distance_px = dist
	d.source = self
	t.call("take_damage", d)
