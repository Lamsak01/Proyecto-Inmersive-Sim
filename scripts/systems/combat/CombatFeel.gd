extends RefCounted

## C7 (rehacer el combate), fase 1: «peso y respuesta». Una sola tabla con cómo se siente cada arma y las reacciones
## comunes a cualquier golpe (empujón, tambaleo, chispa, sonido). Sin `class_name`: se carga con `preload`.
## El daño, el sangrado y el aturdimiento NO cambian (los pone cada arma); aquí solo va el «cómo se siente».

## windup: tiempo de preparación antes de que el golpe pueda dar (se ve venir y se puede castigar)
## active: tiempo en que el golpe puede dar · recovery: tiempo de recuperación tras el golpe (no puedes volver a pegar)
## lunge: paso hacia delante al golpear (px) · knockback: empujón al que recibe (px) · stagger: tambaleo del que recibe (s)
## hitstop: congelado del impacto (s) · shake: temblor de cámara (px) · move_mult: velocidad al andar mientras golpeas
## pitch: tono del sonido (más grave = más pesado)
const WEAPON_FEEL: Dictionary = {
	"sword":   {"windup": 0.08, "active": 0.12, "recovery": 0.16, "lunge": 7.0, "knockback": 9.0,  "stagger": 0.22, "hitstop": 0.050, "shake": 2.5, "move_mult": 0.45, "pitch": 1.05},
	"hammer":  {"windup": 0.18, "active": 0.12, "recovery": 0.28, "lunge": 5.0, "knockback": 20.0, "stagger": 0.45, "hitstop": 0.095, "shake": 5.0, "move_mult": 0.25, "pitch": 0.80},
	"axe":     {"windup": 0.14, "active": 0.12, "recovery": 0.22, "lunge": 6.0, "knockback": 14.0, "stagger": 0.32, "hitstop": 0.075, "shake": 4.0, "move_mult": 0.30, "pitch": 0.90},
	"pickaxe": {"windup": 0.16, "active": 0.12, "recovery": 0.24, "lunge": 5.0, "knockback": 15.0, "stagger": 0.35, "hitstop": 0.080, "shake": 4.0, "move_mult": 0.30, "pitch": 0.88},
	"sickle":  {"windup": 0.05, "active": 0.10, "recovery": 0.12, "lunge": 8.0, "knockback": 6.0,  "stagger": 0.16, "hitstop": 0.035, "shake": 1.8, "move_mult": 0.55, "pitch": 1.20},
	"puños":   {"windup": 0.05, "active": 0.09, "recovery": 0.13, "lunge": 6.0, "knockback": 6.0,  "stagger": 0.18, "hitstop": 0.040, "shake": 2.0, "move_mult": 0.55, "pitch": 1.15},
	"default": {"windup": 0.08, "active": 0.12, "recovery": 0.16, "lunge": 5.0, "knockback": 8.0,  "stagger": 0.20, "hitstop": 0.045, "shake": 2.5, "move_mult": 0.45, "pitch": 1.00},
}

## C7 fase 2: cómo pegan los rivales. push: empujón que te dan (px) · recover: tiempo que se quedan quietos tras dar
## · miss_recover: tras fallar (la ventana para castigarles) · pitch: tono del zumbido del golpe
const ATTACK_FEEL: Dictionary = {
	"porra":     {"push": 9.0,  "recover": 0.30, "miss_recover": 0.60, "pitch": 0.95},
	"puño":      {"push": 5.0,  "recover": 0.28, "miss_recover": 0.55, "pitch": 1.15},
	"bandido":   {"push": 7.0,  "recover": 0.30, "miss_recover": 0.60, "pitch": 1.05},
	"colmillos": {"push": 14.0, "recover": 0.35, "miss_recover": 0.75, "pitch": 0.75},
}

const SFX_SWING: AudioStream = preload("res://assests/audio/swipe.wav")
const SFX_HIT: AudioStream = preload("res://assests/audio/hit.wav")
const SFX_HURT: AudioStream = preload("res://assests/audio/hurt.wav")
const SFX_DIE: AudioStream = preload("res://assests/audio/enemy_die.wav")
const SFX_EVADE: AudioStream = preload("res://assests/audio/evade.wav")

static func feel_for(weapon) -> Dictionary:
	if weapon == null:
		return WEAPON_FEEL["default"]
	var k: String = str(weapon.get("name")).to_lower()
	return WEAPON_FEEL.get(k, WEAPON_FEEL["default"])

static func attack_feel(kind: String) -> Dictionary:
	return ATTACK_FEEL.get(kind, ATTACK_FEEL["puño"])

## Zumbido del golpe de un rival al soltarlo (lo oyes venir aunque no mires).
static func enemy_swing(node: Node2D, kind: String) -> void:
	if node != null:
		play(node, SFX_SWING, node.global_position, float(attack_feel(kind)["pitch"]), -7.0)

## Masa de quien recibe (1 = una persona): el empujón se divide por ella y el tambaleo por su raíz.
## Cada criatura la declara con `hit_mass` (un jabalí ~2,5: la hoz apenas lo mueve; un conejo ~0,5).
static func mass_of(target) -> float:
	if target == null:
		return 1.0
	var m = target.get("hit_mass")
	return maxf(0.3, float(m)) if m != null else 1.0

## Duración total de un golpe (preparación + golpe + recuperación).
static func swing_total(feel: Dictionary) -> float:
	return float(feel["windup"]) + float(feel["active"]) + float(feel["recovery"])

## Sonido corto en un punto del mundo, en el bus de efectos (no hace nada sin escena o sin pantalla).
static func play(node: Node, stream: AudioStream, pos: Vector2, pitch: float = 1.0, volume_db: float = -4.0) -> void:
	if node == null or stream == null or not node.is_inside_tree() or DisplayServer.get_name() == "headless":
		return
	var scene: Node = node.get_tree().current_scene
	if scene == null:
		return
	var sp := AudioStreamPlayer2D.new()
	sp.stream = stream
	sp.global_position = pos
	sp.pitch_scale = pitch * randf_range(0.93, 1.07)
	sp.volume_db = volume_db
	if AudioServer.get_bus_index("SFX") != -1:
		sp.bus = "SFX"
	sp.finished.connect(sp.queue_free)
	scene.add_child(sp)
	sp.play()

## Reacción de quien recibe un golpe cuerpo a cuerpo: empujón (respetando paredes), tambaleo que corta su ataque,
## chispa en el punto del impacto y sonido. `dir` = dirección del golpe.
static func apply_hit_reaction(target: Node, dir: Vector2, feel: Dictionary) -> void:
	if target == null or not is_instance_valid(target) or not (target is Node2D):
		return
	var t2d := target as Node2D
	if bool(target.get("is_dead")):
		play(t2d, SFX_DIE, t2d.global_position, float(feel.get("pitch", 1.0)))
	else:
		play(t2d, SFX_HIT, t2d.global_position, float(feel.get("pitch", 1.0)))
	var mass: float = mass_of(target)
	var push: Vector2 = dir.normalized() * float(feel.get("knockback", 8.0)) / mass
	if target is CharacterBody2D and push != Vector2.ZERO and not bool(target.get("is_dead")) and not bool(target.get("is_downed")):
		(target as CharacterBody2D).move_and_collide(push) # choca con muros: no atraviesa paredes
	if target.has_method("apply_parry_stagger") and not bool(target.get("is_dead")):
		target.call("apply_parry_stagger", float(feel.get("stagger", 0.2)) / sqrt(mass), true)
	spawn_impact_spark(t2d, t2d.global_position + Vector2(0, -8) - dir.normalized() * 4.0, dir)

## Chispa breve en el punto del impacto (unas pocas motas que salen en la dirección del golpe).
static func spawn_impact_spark(near: Node, pos: Vector2, dir: Vector2) -> void:
	if near == null or not near.is_inside_tree() or near.get_tree().current_scene == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 10
	p.lifetime = 0.22
	p.explosiveness = 1.0
	p.direction = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	p.spread = 55.0
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(0, 160)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(1.0, 0.92, 0.75)
	p.z_index = 40
	p.global_position = pos
	near.get_tree().current_scene.add_child(p)
	p.emitting = true
	near.get_tree().create_timer(0.5).timeout.connect(p.queue_free)
