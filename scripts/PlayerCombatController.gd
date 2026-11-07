extends Node
class_name PlayerCombatController

const WorldStage3DScript = preload("res://scripts/visuals/WorldStage3D.gd")

@onready var player: CharacterBody2D = get_parent()
@onready var interact_area: Area2D = $"../InteractArea"
@onready var stamina_comp: StaminaComponent = $"../StaminaComponent"

# Visuals
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D
var crosshair: Crosshair2D
var hitbox_area: Hitbox
var hitbox_shape: CollisionShape2D

var current_prompt_target: Node2D = null
var attack_timer: float = 0.0
var _takedown_check_timer: float = 0.0
var current_aim_dir: Vector2 = Vector2.RIGHT

## Parada con Q (COMBATE-1): ventana corta de ~0.2 s, enfriamiento ~0.5 s si no entra golpe, deja al atacante ~0.8 s sin pegar.
const PARRY_WINDOW: float = 0.20
const PARRY_COOLDOWN: float = 0.50
const PARRY_STAGGER_DURATION: float = 0.80

var parry_window_timer: float = 0.0
var parry_cooldown_timer: float = 0.0

# Sistema de Tensión del Arco (Hold-to-Draw)
var is_drawing_bow: bool = false
var bow_tension: float = 0.0
const BOW_DRAW_DURATION: float = 0.85
var _swing_hit_targets: Array[Node] = []

## C7 fase 1 (peso y respuesta): cómo se siente el golpe en curso (tabla de CombatFeel) y su duración total, que
## también usa el muñeco 3D para su animación. Mientras dura, la dirección del golpe queda fijada (compromiso).
const CombatFeel = preload("res://scripts/systems/combat/CombatFeel.gd")
const WeaponWear = preload("res://scripts/systems/combat/WeaponWear.gd") # C7 fase 4b: armas melladas
var swing_duration: float = 0.36
var swing_move_mult: float = 1.0
var _swing_feel: Dictionary = {}
var _swing_locked: bool = false
var _swing_id: int = 0
## C7 fase 3a: cadena de la espada y golpe cargado de martillo/hacha
const COMBO_WEAPONS: Array[String] = ["sword"] ## volver a pulsar durante la recuperación encadena el siguiente golpe
const CHARGE_WEAPONS: Array[String] = ["hammer", "axe"] ## mantener el clic carga el golpe
const CHARGE_FULL: float = 0.65 ## segundos de carga para el golpe cargado completo
const CHARGE_MIN: float = 0.25 ## por debajo de esto, un toque normal
var combo_step: int = 0 ## 1, 2 o 3 dentro de la cadena actual
var _in_recovery: bool = false
var is_charging: bool = false
var charge_t: float = 0.0
var _charge_from_mouse: bool = true
## C7 fase 3b: bloqueo sostenido (mantener Q tras la parada) y empujón (X)
const BLOCK_DAMAGE_MULT: float = 0.30 ## lo que pasa del golpe al bloquear (la parada perfecta sigue anulándolo)
const BLOCK_DRAIN: float = 2.5 ## energía por segundo con la guardia alta
const SHOVE_RANGE: float = 32.0
const SHOVE_COOLDOWN: float = 0.8
const SHOVE_STAMINA: float = 12.0
const SHOVE_FEEL: Dictionary = {"knockback": 26.0, "stagger": 0.6, "hitstop": 0.04, "shake": 2.5, "pitch": 0.85}
var is_blocking: bool = false
var shove_cooldown: float = 0.0
var _swing_power: float = 1.0 ## multiplicador de daño/empujón/tambaleo del golpe en curso (3.º de la cadena, cargado)

func _ready() -> void:
	_setup_visuals()
	_setup_hitbox()

func _process(delta: float) -> void:
	_update_weapon_visuals()
	
	if is_drawing_bow:
		var equipped: WeaponData = player.equipped_weapon
		if not equipped or not equipped.is_ranged:
			_cancel_bow_draw()
		else:
			bow_tension = clampf(bow_tension + (delta / BOW_DRAW_DURATION), 0.0, 1.0)
			if stamina_comp:
				stamina_comp.use_stamina(6.0 * delta)
				if stamina_comp.current_stamina <= 0.5:
					_release_bow_shot(true)
			if is_drawing_bow:
				if weapon_sprite:
					weapon_sprite.visible = true
					weapon_sprite.rotation_degrees = 0
					weapon_sprite.offset = Vector2(lerpf(6.0, 3.2, bow_tension), -10)
				if crosshair:
					crosshair.is_drawing_bow = true
					crosshair.bow_tension = bow_tension
				# Si el jugador soltó el botón fuera de foco, disparar igualmente
				if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _attack_key_held():
					_release_bow_shot()

	if is_charging:
		var eq_c: WeaponData = player.equipped_weapon
		if eq_c == null or eq_c.is_ranged or not (str(eq_c.name).to_lower() in CHARGE_WEAPONS):
			is_charging = false
			charge_t = 0.0
		else:
			charge_t = minf(CHARGE_FULL, charge_t + delta)
			if weapon_sprite:
				weapon_sprite.visible = true
				weapon_sprite.rotation_degrees = lerpf(-45.0, -95.0, charge_t / CHARGE_FULL)
				weapon_sprite.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.45, 1.1, 0.7), charge_t / CHARGE_FULL)
			# Si se soltó el botón fuera de foco, soltar igualmente
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _attack_key_held():
				release_charge()

	if _takedown_check_timer > 0.0:
		_takedown_check_timer -= delta
	else:
		_takedown_check_timer = 0.08
		_check_stealth_takedown()
	
	if attack_timer > 0.0:
		attack_timer -= delta

func _physics_process(delta: float) -> void:
	if shove_cooldown > 0.0:
		shove_cooldown = maxf(0.0, shove_cooldown - delta)
	if is_blocking:
		if stamina_comp:
			stamina_comp.use_stamina(BLOCK_DRAIN * delta)
		if not _block_key_held() or (stamina_comp and stamina_comp.current_stamina <= 1.0):
			end_block()
	elif parry_window_timer > 0.0:
		parry_window_timer = maxf(0.0, parry_window_timer - delta)
		if parry_window_timer <= 0.0:
			# C7 fase 3b: si sigues con Q pulsada, la parada pasa a guardia alta
			if _block_key_held() and (stamina_comp == null or stamina_comp.current_stamina > 5.0):
				is_blocking = true
				if weapon_sprite:
					weapon_sprite.modulate = Color(0.85, 0.9, 1.1)
			else:
				parry_cooldown_timer = PARRY_COOLDOWN
				if weapon_sprite and attack_timer <= 0.0 and not is_drawing_bow:
					weapon_sprite.visible = false
					weapon_sprite.modulate = Color.WHITE
	elif parry_cooldown_timer > 0.0:
		parry_cooldown_timer = maxf(0.0, parry_cooldown_timer - delta)

func is_parrying() -> bool:
	return parry_window_timer > 0.0

var block_key_override: int = -1 ## solo pruebas: 1 = Q pulsada, 0 = suelta, -1 = leer el teclado
func _block_key_held() -> bool:
	if block_key_override >= 0:
		return block_key_override == 1
	return Input.is_physical_key_pressed(KEY_Q)

func end_block() -> void:
	if not is_blocking:
		return
	is_blocking = false
	parry_cooldown_timer = PARRY_COOLDOWN
	if weapon_sprite and attack_timer <= 0.0 and not is_drawing_bow:
		weapon_sprite.visible = false
		weapon_sprite.modulate = Color.WHITE

## Golpe recibido con la guardia alta: gasta energía según el golpe. Devuelve la parte del daño que pasa
## (BLOCK_DAMAGE_MULT, o 1 si no te quedaba energía: la guardia se rompe).
func block_hit(data: DamageData) -> float:
	var cost: float = 8.0 + (data.amount * 0.6 if data != null else 0.0)
	if stamina_comp and stamina_comp.current_stamina < cost:
		stamina_comp.use_stamina(stamina_comp.current_stamina)
		end_block()
		if player.has_method("_spawn_combat_popup"):
			player.call("_spawn_combat_popup", "💢 ¡Guardia rota!", Color(1.0, 0.5, 0.35))
		return 1.0
	if stamina_comp:
		stamina_comp.use_stamina(cost)
	return BLOCK_DAMAGE_MULT

## C7 fase 3b: empujón con el hombro (X). Casi sin daño; abre distancia y desequilibra. Cuenta como agresión.
func shove() -> bool:
	if not is_instance_valid(player) or attack_timer > 0.0 or is_blocking or is_charging or shove_cooldown > 0.0:
		return false
	if player.has_method("is_rolling") and bool(player.call("is_rolling")):
		return false
	if stamina_comp:
		if stamina_comp.current_stamina < SHOVE_STAMINA:
			return false
		stamina_comp.use_stamina(SHOVE_STAMINA)
	shove_cooldown = SHOVE_COOLDOWN
	attack_timer = 0.35
	swing_duration = 0.35
	swing_move_mult = 0.4
	CombatFeel.play(player, CombatFeel.SFX_SWING, player.global_position, 0.7, -9.0)
	var hit_any: bool = false
	for g in ["npcs", "wild_animals", "raiders", "domestic_pets", "enemies"]:
		for t in get_tree().get_nodes_in_group(g):
			if t == player or not (t is Node2D) or not is_instance_valid(t) or t.get("is_dead") == true:
				continue
			var to_t: Vector2 = (t as Node2D).global_position - player.global_position
			if to_t.length() > SHOVE_RANGE or (to_t.length_squared() > 1.0 and to_t.normalized().dot(current_aim_dir) < 0.3):
				continue
			if t.has_method("take_damage"):
				var d := DamageData.new()
				d.amount = 1.0
				d.type = CombatConstants.DamageType.BLUNT
				d.stun_buildup = 12.0
				d.weapon_tag = "Empujón"
				d.source = player
				t.call("take_damage", d)
			CombatFeel.apply_hit_reaction(t, to_t if to_t.length_squared() > 1.0 else current_aim_dir, SHOVE_FEEL)
			hit_any = true
	if hit_any:
		_apply_camera_shake(float(SHOVE_FEEL["shake"]))
		if AudioManager:
			AudioManager.emit_noise(player.global_position, 115.0, -999, "heavy_hit")
	return true

func start_parry() -> bool:
	if not is_instance_valid(player):
		return false
	var dm = player.get("dialogue_manager")
	if (dm and dm.has_method("is_active") and dm.call("is_active")) or (player.has_method("is_stunned") and player.is_stunned()) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))) or (player.has_method("is_fishing_or_sitting") and bool(player.call("is_fishing_or_sitting"))):
		return false
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and (bool(vm.get("player_in_jail")) or bool(vm.get("player_being_escorted_to_jail"))):
		return false
	if is_instance_valid(current_prompt_target):
		return false
	if player.has_method("is_rolling") and bool(player.call("is_rolling")):
		return false
	if parry_window_timer > 0.0 or parry_cooldown_timer > 0.0:
		return false
	if is_drawing_bow:
		_cancel_bow_draw()
	parry_window_timer = PARRY_WINDOW
	if weapon_sprite:
		weapon_sprite.visible = true
		weapon_sprite.rotation_degrees = 35.0
		weapon_sprite.modulate = Color(0.75, 0.95, 1.35)
	return true

func resolve_parry_hit(attacker: Node) -> void:
	parry_window_timer = 0.0
	parry_cooldown_timer = 0.0
	if weapon_sprite:
		weapon_sprite.visible = false
		weapon_sprite.modulate = Color.WHITE
	if is_instance_valid(attacker) and attacker.has_method("apply_parry_stagger"):
		attacker.call("apply_parry_stagger", PARRY_STAGGER_DURATION)
	if is_instance_valid(player) and player.has_method("_spawn_combat_popup"):
		player.call("_spawn_combat_popup", "🛡️ ¡PARADA!", Color(0.45, 0.95, 1.0))

## La tecla de «aceptar» (Intro) también ataca, pero NUNCA el Espacio: el Espacio es solo para rodar
## (antes rodar soltaba a la vez un golpe y, por la espalda de alguien, hasta lo mataba por sigilo).
func _is_attack_key(event: InputEvent) -> bool:
	if not event.is_action("ui_accept"):
		return false
	if event is InputEventKey and ((event as InputEventKey).keycode == KEY_SPACE or (event as InputEventKey).physical_keycode == KEY_SPACE):
		return false
	return true

func _attack_key_held() -> bool:
	return Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player):
		return
	var dm = player.get("dialogue_manager")
	if (dm and dm.has_method("is_active") and dm.call("is_active")) or (player.has_method("is_stunned") and player.is_stunned()) or (player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open"))) or (player.has_method("is_fishing_or_sitting") and bool(player.call("is_fishing_or_sitting"))):
		if is_drawing_bow:
			_cancel_bow_draw()
		return
	var vm = get_tree().get_first_node_in_group("village_manager")
	if vm and (bool(vm.get("player_in_jail")) or bool(vm.get("player_being_escorted_to_jail"))):
		if is_drawing_bow:
			_cancel_bow_draw()
		return

	# Si hay un objetivo válido de Sigilo por la Espalda (Civil o Enemigo):
	# - Opción NO LETAL (Aturdir): [E] (Interact) o [Q]
	# - Opción LETAL (Asesinar): [Clic Izq.], [ui_accept] o [V]
	if is_instance_valid(current_prompt_target):
		var prio_pt: Vector2 = WorldStage3DScript.get_fp_aim_world_pos(player.global_position, 28.0) if WorldStage3DScript.first_person_active else player.get_global_mouse_position()
		if event.is_action_pressed("Interact") and vm and vm.has_method("try_priority_door_or_corpse_interaction"):
			if bool(vm.call("try_priority_door_or_corpse_interaction", player, prio_pt)):
				get_viewport().set_input_as_handled()
				return
		var is_non_lethal_key: bool = event.is_action_pressed("Interact") or (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_Q or event.keycode == KEY_Q))
		var is_lethal_key: bool = (_is_attack_key(event) and event.is_pressed() and not event.is_echo()) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_V or event.keycode == KEY_V))
		if is_non_lethal_key:
			_execute_stealth_takedown(current_prompt_target, false)
			get_viewport().set_input_as_handled()
			return
		elif is_lethal_key:
			_execute_stealth_takedown(current_prompt_target, true)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_Q or event.physical_keycode == KEY_Q):
		if start_parry():
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_X or event.physical_keycode == KEY_X):
		if shove():
			get_viewport().set_input_as_handled()
		return

	var equipped: WeaponData = player.equipped_weapon
	var is_flintlock: bool = equipped != null and str(equipped.name).to_lower() == "flintlock"
	var is_bow: bool = equipped != null and equipped.is_ranged and not is_flintlock

	if is_bow:
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or _is_attack_key(event):
			if event.is_pressed() and not event.is_echo():
				_start_bow_draw()
			elif not event.is_pressed() and is_drawing_bow:
				_release_bow_shot()
			return

	var is_charge_weapon: bool = equipped != null and not equipped.is_ranged and (str(equipped.name).to_lower() in CHARGE_WEAPONS)
	if is_charge_weapon:
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or _is_attack_key(event):
			if event.is_pressed() and not event.is_echo():
				start_charge(event is InputEventMouseButton)
			elif not event.is_pressed() and is_charging:
				release_charge()
			return

	if _is_attack_key(event) and event.is_pressed() and not event.is_echo():
		attack(false)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		attack(true)

func _execute_stealth_takedown(target: Node2D, lethal: bool) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("hide_prompt"):
		target.hide_prompt()
	current_prompt_target = null

	if lethal:
		if target.has_method("stealth_assassinate"):
			target.call("stealth_assassinate", player)
		elif target.has_method("take_damage"):
			var kill_dmg := DamageData.new()
			kill_dmg.amount = 999.0
			kill_dmg.type = CombatConstants.DamageType.CUT
			kill_dmg.source = player
			target.call("take_damage", kill_dmg)
			if player and player.has_method("show_hint"):
				player.show_hint("🗡️ ¡Eliminación letal en sigilo!")
	else:
		if target.has_method("stealth_knockout"):
			target.call("stealth_knockout", player)
		elif target.has_method("knockout"):
			target.call("knockout")
			if player and player.has_method("show_hint"):
				player.show_hint("💤 ¡Derribo no letal en sigilo!")
	_apply_hitstop()
	_apply_camera_shake()

func _setup_visuals() -> void:
	weapon_pivot = Node2D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector2(0, -10)
	player.call_deferred("add_child", weapon_pivot)
	
	# Punto de mira dinámico en el cursor (estilo Enter the Gungeon / Zero Sievert)
	crosshair = Crosshair2D.new()
	crosshair.name = "Crosshair2D"
	crosshair.player = player
	player.call_deferred("add_child", crosshair)

	weapon_sprite = Sprite2D.new()
	weapon_sprite.name = "WeaponSprite"
	weapon_sprite.centered = false
	weapon_sprite.offset = Vector2(6, -10)
	weapon_sprite.rotation_degrees = -45
	weapon_sprite.visible = false
	weapon_pivot.add_child(weapon_sprite)

func _setup_hitbox() -> void:
	hitbox_area = Hitbox.new()
	hitbox_area.name = "WeaponHitbox"
	hitbox_area.collision_layer = 0
	hitbox_area.collision_mask = 5 # Layers 1 (destructibles/environment) + 3 (enemies/hurtboxes)
	
	hitbox_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	hitbox_shape.shape = circle
	hitbox_shape.position = Vector2(22, 0)
	hitbox_shape.disabled = true
	
	hitbox_area.add_child(hitbox_shape)
	weapon_pivot.add_child(hitbox_area)
	
	hitbox_area.area_entered.connect(_on_hitbox_entered)
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)

func _update_weapon_visuals() -> void:
	if not is_instance_valid(weapon_pivot) or not is_instance_valid(player):
		return
	if WorldStage3DScript.first_person_active:
		if not _swing_locked:
			current_aim_dir = WorldStage3DScript.get_fp_forward_2d()
		weapon_pivot.rotation = current_aim_dir.angle()
		weapon_pivot.z_index = -1 if current_aim_dir.y < -0.35 else 1
		return
	var pivot_global := player.global_position + Vector2(0, -10)
	var aim_pos := crosshair.get_aim_world_position() if is_instance_valid(crosshair) else player.get_global_mouse_position()
	var diff := aim_pos - pivot_global
	if diff.length_squared() > 4.0 and not _swing_locked:
		current_aim_dir = diff.normalized()
	weapon_pivot.rotation = current_aim_dir.angle()
	weapon_pivot.z_index = -1 if current_aim_dir.y < -0.35 else 1

func equip_weapon(weapon_data: WeaponData) -> void:
	if is_drawing_bow:
		_cancel_bow_draw()
	player.equipped_weapon = weapon_data
	if weapon_sprite and weapon_data and weapon_data.icon:
		weapon_sprite.texture = weapon_data.icon
		weapon_sprite.modulate = Color.WHITE
		weapon_sprite.scale = Vector2.ONE
		weapon_sprite.offset = Vector2(6, -10)
		weapon_sprite.rotation_degrees = 0 if weapon_data.is_ranged else -45
		weapon_sprite.visible = false
	if crosshair and weapon_data:
		crosshair.is_ranged_mode = weapon_data.is_ranged
		crosshair.is_drawing_bow = false
		crosshair.bow_tension = 0.0

func _start_bow_draw() -> void:
	var equipped: WeaponData = player.equipped_weapon
	if not equipped or not equipped.is_ranged or attack_timer > 0.0 or (stamina_comp and stamina_comp.current_stamina < 6.0):
		return
	is_drawing_bow = true
	bow_tension = 0.05
	if weapon_sprite:
		weapon_sprite.visible = true
		weapon_sprite.rotation_degrees = 0
		weapon_sprite.offset = Vector2(6, -10)
	if crosshair:
		crosshair.is_drawing_bow = true
		crosshair.bow_tension = bow_tension

func _cancel_bow_draw() -> void:
	is_drawing_bow = false
	bow_tension = 0.0
	if weapon_sprite:
		weapon_sprite.offset = Vector2(6, -10)
		weapon_sprite.visible = false
	if crosshair:
		crosshair.is_drawing_bow = false
		crosshair.bow_tension = 0.0

func _release_bow_shot(skip_release_cost: bool = false) -> void:
	if not is_drawing_bow:
		return
	var equipped: WeaponData = player.equipped_weapon
	var final_tension: float = clampf(bow_tension, 0.12, 1.0)
	is_drawing_bow = false
	bow_tension = 0.0
	if crosshair:
		crosshair.is_drawing_bow = false
		crosshair.bow_tension = 0.0
		crosshair.add_recoil(lerpf(2.5, 5.5, final_tension))
	if not equipped or not equipped.is_ranged:
		if weapon_sprite: weapon_sprite.visible = false
		return
	if stamina_comp and not skip_release_cost and stamina_comp.current_stamina >= 4.0:
		stamina_comp.use_stamina(4.0)
	var hc_bow: HealthComponent = player.get_node_or_null("HealthComponent")
	var manip_bow: float = hc_bow.get_manipulation_capacity() if hc_bow else 1.0
	attack_timer = 0.25 / maxf(0.35, manip_bow)
	_update_weapon_visuals()
	_fire_bow(equipped, final_tension * manip_bow)

## C7 fase 3a: empezar a cargar (martillo/hacha). Un toque corto suelta un golpe normal al soltar.
func start_charge(from_mouse: bool = true) -> void:
	if attack_timer > 0.0 or is_charging:
		return
	is_charging = true
	charge_t = 0.0
	_charge_from_mouse = from_mouse

func release_charge() -> void:
	if not is_charging:
		return
	is_charging = false
	var ratio: float = 0.0 if charge_t < CHARGE_MIN else clampf((charge_t - CHARGE_MIN) / (CHARGE_FULL - CHARGE_MIN), 0.0, 1.0)
	charge_t = 0.0
	if weapon_sprite:
		weapon_sprite.modulate = Color.WHITE
	attack(_charge_from_mouse, ratio)

## `charge` (0–1): solo martillo/hacha; 1 = golpe cargado completo (más daño, empuja y tumba más, cuesta más energía).
func attack(_aim_with_mouse: bool = true, charge: float = 0.0) -> void:
	var equipped: WeaponData = player.equipped_weapon
	if not equipped: return
	var w_key: String = str(equipped.name).to_lower()
	# Cadena de la espada: volver a pulsar durante la recuperación corta lo que queda y suelta el siguiente golpe
	if is_blocking:
		return # con la guardia alta no se golpea
	var chaining: bool = attack_timer > 0.0 and _in_recovery and not equipped.is_ranged and (w_key in COMBO_WEAPONS) and combo_step >= 1 and combo_step < 3
	if attack_timer > 0.0 and not chaining: return
	if equipped == player.get("watering_can_weapon") and player.has_method("is_bloodstained") and bool(player.call("is_bloodstained")):
		if player.has_method("consume_water_charge") and bool(player.call("consume_water_charge")):
			attack_timer = 0.30
			player.call("wash_bloodstains", true)
			return
	var stam_cost: float = 10.0 if equipped.is_ranged else 14.0
	if not equipped.is_ranged and charge > 0.0:
		stam_cost += 10.0 * charge
	if stamina_comp:
		if stamina_comp.current_stamina < stam_cost: return
		stamina_comp.use_stamina(stam_cost)
	var hc_atk: HealthComponent = player.get_node_or_null("HealthComponent")
	var manip_atk: float = hc_atk.get_manipulation_capacity() if hc_atk else 1.0
	var slow_k: float = 1.0 / maxf(0.35, manip_atk) # sin brazo (o con prótesis) todo el golpe va más lento
	if equipped.is_ranged:
		swing_duration = 0.36 * slow_k
		attack_timer = swing_duration
	else:
		combo_step = (combo_step + 1) if chaining else 1
		_swing_feel = CombatFeel.feel_for(equipped).duplicate()
		_swing_power = 1.0
		if combo_step == 3: # el 3.º de la cadena: más lento y más fuerte
			_swing_power = 1.5
			_swing_feel["windup"] = float(_swing_feel["windup"]) * 1.8
			_swing_feel["recovery"] = float(_swing_feel["recovery"]) * 1.5
		elif charge > 0.0: # golpe cargado: la carga ya fue la preparación
			_swing_power = 1.0 + 0.7 * charge
			_swing_feel["windup"] = float(_swing_feel["windup"]) * 0.5
			_swing_feel["recovery"] = float(_swing_feel["recovery"]) * (1.0 + 0.4 * charge)
		_swing_feel["knockback"] = float(_swing_feel["knockback"]) * (1.0 + (_swing_power - 1.0) * 1.6)
		_swing_feel["stagger"] = float(_swing_feel["stagger"]) * (1.0 + (_swing_power - 1.0) * 2.2)
		_swing_feel["hitstop"] = float(_swing_feel["hitstop"]) * (1.0 + (_swing_power - 1.0) * 0.8)
		_swing_feel["shake"] = float(_swing_feel["shake"]) * _swing_power
		swing_duration = CombatFeel.swing_total(_swing_feel) * slow_k
		attack_timer = swing_duration
	if crosshair:
		crosshair.add_recoil(4.5)
	_update_weapon_visuals()
	if equipped.is_ranged:
		if str(equipped.name).to_lower() == "flintlock":
			_fire_flintlock_realtime(equipped)
		else:
			_fire_bow(equipped, 0.5)
		return

	# C7: preparación (se echa el arma atrás) → golpe con un paso adelante → recuperación. Mientras, andas más
	# despacio y la dirección queda fijada; el golpe solo puede dar durante la parte «active».
	var f: Dictionary = _swing_feel
	var t_wind: float = float(f["windup"]) * slow_k
	var t_act: float = float(f["active"]) * slow_k
	var t_rec: float = float(f["recovery"]) * slow_k
	_swing_id += 1
	var my_id: int = _swing_id
	_in_recovery = false
	_swing_locked = true
	swing_move_mult = float(f["move_mult"])
	CombatFeel.play(player, CombatFeel.SFX_SWING, player.global_position, float(f["pitch"]) / sqrt(_swing_power), -8.0)
	if _swing_power >= 1.3 and player.has_method("_spawn_combat_popup"):
		player.call("_spawn_combat_popup", "💥" if combo_step == 3 else "💥 ¡Golpe cargado!", Color(1.0, 0.78, 0.4))
	if weapon_sprite:
		weapon_sprite.visible = true
		weapon_sprite.rotation_degrees = -45
		var tween = create_tween()
		tween.tween_property(weapon_sprite, "rotation_degrees", -80, t_wind).set_ease(Tween.EASE_OUT)
		tween.tween_property(weapon_sprite, "rotation_degrees", 55, t_act).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(weapon_sprite, "rotation_degrees", -45, t_rec)
		tween.tween_callback(func():
			if is_instance_valid(weapon_sprite):
				weapon_sprite.visible = false
		)

	_swing_hit_targets.clear()
	hitbox_area.damage_data = equipped.damage_data.copy()
	if "paralytic_venom_timer" in player and float(player.get("paralytic_venom_timer")) > 0.0:
		hitbox_area.damage_data.stun_buildup += 50.0
	hitbox_area.damage_data.source = player
	if _swing_power > 1.0:
		hitbox_area.damage_data.amount *= _swing_power
		hitbox_area.damage_data.stun_buildup *= _swing_power
	var wear_k: float = WeaponWear.damage_mult(player, equipped) # un arma mellada pega, corta y tala menos
	if wear_k < 1.0:
		hitbox_area.damage_data.amount *= wear_k
		hitbox_area.damage_data.bleed_buildup *= wear_k
		hitbox_area.damage_data.logging_efficiency *= wear_k
		hitbox_area.damage_data.mining_efficiency *= wear_k

	if t_wind > 0.0:
		await get_tree().create_timer(t_wind).timeout
	if my_id != _swing_id or not is_instance_valid(player):
		return
	# Paso adelante al soltar el golpe (choca con paredes)
	if player is CharacterBody2D and float(f["lunge"]) > 0.0:
		(player as CharacterBody2D).move_and_collide(current_aim_dir * float(f["lunge"]))
	hitbox_shape.disabled = false
	await get_tree().create_timer(t_act).timeout
	if is_instance_valid(hitbox_shape):
		hitbox_shape.disabled = true
	if my_id != _swing_id:
		return
	_in_recovery = true # C7 fase 3a: ventana para encadenar (espada)
	if t_rec > 0.0:
		await get_tree().create_timer(t_rec).timeout
	if my_id == _swing_id:
		_in_recovery = false
		_swing_locked = false
		swing_move_mult = 1.0
		_swing_power = 1.0
		if attack_timer <= 0.05:
			combo_step = 0

func _fire_bow(equipped: WeaponData, tension: float = 1.0) -> void:
	var shoot_dir := current_aim_dir
	var pivot_global := player.global_position + Vector2(0, -10)

	if weapon_sprite:
		weapon_sprite.visible = true
		weapon_sprite.rotation_degrees = 0
		weapon_sprite.offset = Vector2(6, -10)
		get_tree().create_timer(0.16).timeout.connect(func():
			if is_instance_valid(weapon_sprite) and not is_drawing_bow:
				weapon_sprite.visible = false
		)

	var arrow := ArrowProjectile.new()
	arrow.global_position = pivot_global + shoot_dir * 12.0
	arrow.direction = shoot_dir
	# El alcance y la velocidad dependen directamente de cuánto tensaste el arco (hasta el doble de largo: 330 px)
	arrow.max_range = lerpf(55.0, 330.0, tension)
	arrow.speed = lerpf(190.0, 380.0, tension)
	arrow.shooter = player
	arrow.damage_data = equipped.damage_data.copy()
	arrow.damage_data.weapon_tag = "Impacto de Flecha (Arco)"
	arrow.damage_data.amount = equipped.damage_data.amount * lerpf(0.55, 1.4, tension)
	if "paralytic_venom_timer" in player and float(player.get("paralytic_venom_timer")) > 0.0:
		arrow.damage_data.stun_buildup += 50.0
	arrow.damage_data.source = player
	player.get_tree().current_scene.add_child(arrow)

func _fire_flintlock_realtime(equipped: WeaponData) -> void:
	var inv = player.get("inventory")
	if inv == null or not inv.has_item("flintlock_pistol", 1) or not inv.has_item("powder_charge", 1):
		if player.has_method("show_hint"):
			player.call("show_hint", "⚠️ Necesitas 1 Carga de Pólvora Negra en la mochila para disparar el Arcabuz de Chispa.")
		return
	inv.remove_item("powder_charge", 1)
	attack_timer = 0.85
	var av3d = player.get("avatar_3d")
	if av3d and av3d.has_method("trigger_muzzle_flash"):
		av3d.call("trigger_muzzle_flash")
	_apply_camera_shake()

	var shoot_dir := current_aim_dir
	var pivot_global := player.global_position + Vector2(0, -10)
	var bullet := ArrowProjectile.new()
	bullet.global_position = pivot_global + shoot_dir * 14.0
	bullet.direction = shoot_dir
	bullet.max_range = 360.0
	bullet.speed = 620.0
	bullet.shooter = player
	bullet.damage_data = equipped.damage_data.copy()
	bullet.damage_data.weapon_tag = "Arcabuz de Chispa"
	bullet.damage_data.amount = 48.0
	bullet.damage_data.source = player
	player.get_tree().current_scene.add_child(bullet)

	if player.has_method("_spawn_floating_text"):
		player.call("_spawn_floating_text", "💥🔫 ¡Estampido de Arcabuz! (-1 Pólvora)", Color(1.0, 0.82, 0.35), -48.0)

	# Alerta sonora a testigos conscientes en 260 px (en el mismo nivel vertical)
	var vm = get_tree().get_first_node_in_group("village_manager")
	var pl_elev: int = int(vm.get("player_elevation_level")) if vm != null and "player_elevation_level" in vm else 0
	if AudioManager:
		AudioManager.emit_noise(player.global_position, 260.0, pl_elev, "gunshot")
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and not n.is_dead and not n.is_downed and not n.is_sleeping and not n.is_stunned_flag:
			if vm and vm.has_method("are_on_same_elevation") and not bool(vm.call("are_on_same_elevation", pl_elev, n.elevation_level)):
				continue
			if (n as Node2D).global_position.distance_to(player.global_position) <= 260.0:
				if n.has_method("_spawn_floating_text"):
					n.call("_spawn_floating_text", "⚠️ ¡Un disparo de arcabuz!", Color.ORANGE_RED, -42.0)

func _on_hitbox_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var target_entity: Node = area.get_parent() if area.get_parent() else area
		if target_entity in _swing_hit_targets:
			return
		_swing_hit_targets.append(target_entity)
		hitbox_area.apply_damage(area)
		_on_melee_impact(target_entity)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body != player and (body.is_in_group("destructible") or body.is_in_group("wild_animals")) and body.has_method("take_damage"):
		if body in _swing_hit_targets:
			return
		_swing_hit_targets.append(body)
		body.take_damage(hitbox_area.damage_data)
		_on_melee_impact(body)

## C7: respuesta del impacto según el arma: empujón, tambaleo, chispa, sonido, congelado y temblor.
func _on_melee_impact(target: Node) -> void:
	if is_instance_valid(player):
		WeaponWear.wear_on_hit(player, player.equipped_weapon, target)
	if _swing_power >= 1.3:
		CombatFeel.try_disarm(target) # golpe fuerte al brazo: suelta el arma
	var f: Dictionary = _swing_feel if not _swing_feel.is_empty() else CombatFeel.WEAPON_FEEL["default"]
	if target is Node2D and is_instance_valid(player):
		var dir: Vector2 = ((target as Node2D).global_position - player.global_position)
		CombatFeel.apply_hit_reaction(target, dir if dir.length_squared() > 0.01 else current_aim_dir, f)
		if AudioManager:
			var is_heavy: bool = _swing_power >= 1.3 or float(f.get("knockback", 8.0)) >= 14.0
			AudioManager.emit_noise(player.global_position, 190.0 if is_heavy else 115.0, -999, "heavy_hit" if is_heavy else "melee_hit")
	_apply_hitstop(float(f.get("hitstop", 0.05)))
	_apply_camera_shake(float(f.get("shake", 4.0)))

func _apply_hitstop(duration: float = 0.05) -> void:
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = WorldClock.get_active_time_scale() if (WorldClock and WorldClock.has_method("get_active_time_scale")) else 1.0

func _apply_camera_shake(amp: float = 4.0) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var shake_tween := create_tween()
		shake_tween.tween_property(cam, "position", Vector2(randf_range(-amp, amp), randf_range(-amp, amp)), 0.03)
		shake_tween.tween_property(cam, "position", Vector2(randf_range(-amp, amp), randf_range(-amp, amp)), 0.03)
		shake_tween.tween_property(cam, "position", Vector2.ZERO, 0.03)

func _check_stealth_takedown() -> void:
	if not interact_area or not is_instance_valid(player):
		return
	var new_target: Node2D = null
	if player.has_method("is_stealthing") and bool(player.call("is_stealthing")):
		var best_dist_sq: float = 29.0 * 29.0
		for n in get_tree().get_nodes_in_group("village_npcs"):
			if n is Node2D and n.has_method("can_be_stealth_targeted") and bool(n.call("can_be_stealth_targeted", player)):
				var d2: float = player.global_position.distance_squared_to((n as Node2D).global_position)
				if d2 <= best_dist_sq:
					best_dist_sq = d2
					new_target = n as Node2D
		if new_target == null:
			for b in interact_area.get_overlapping_bodies():
				if b.is_in_group("enemies") and b.has_method("knockout") and b.get_node_or_null("EnemyAI") and b.get("is_stunned_flag") != true:
					var ai = b.get_node("EnemyAI")
					if ai.current_state in [EnemyAI.State.IDLE, EnemyAI.State.SEARCH] and ai.facing_direction.dot((player.global_position - b.global_position).normalized()) < -0.5:
						new_target = b
						break
	if new_target != current_prompt_target:
		if is_instance_valid(current_prompt_target) and current_prompt_target.has_method("hide_prompt"):
			current_prompt_target.hide_prompt()
		if is_instance_valid(new_target) and new_target.has_method("show_prompt"):
			new_target.show_prompt()
		current_prompt_target = new_target
