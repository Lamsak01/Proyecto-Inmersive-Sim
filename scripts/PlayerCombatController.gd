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
## C7 fase 5a: fase exacta del golpe en 1.ª persona ("idle", "windup", "active", "recovery", "shove") y su progreso (0..1)
var swing_phase: String = "idle"
var swing_phase_elapsed: float = 0.0
var swing_phase_duration: float = 0.0
## C7 fase 5b/5c: apuntado con clic derecho (ADS) y recarga manual lenta en 3 pasos (pistola y fusil con munición distinta)
const PISTOL_MAG_MAX: int = 6
const RIFLE_MAG_MAX: int = 5
const RELOAD_STEP_DURATIONS: Array[float] = [0.65, 0.75, 0.60] # 1: sacar cargador, 2: meter cargador, 3: montar cerrojo
const RELOAD_STEP_LABELS: Array[String] = ["1/3 · Sacando cargador…", "2/3 · Insertando cargador…", "3/3 · Montando cerrojo…"]
var is_aiming_firearm: bool = false
var aim_down_sights_blend: float = 0.0
var aim_override: int = -1 ## solo pruebas/capturas: 1 = apuntando, 0 = sin apuntar, -1 = leer clic derecho
var pistol_mag_loaded: int = 6
var rifle_mag_loaded: int = 5
var reload_step: int = 0 ## 0 = sin recargar, 1 = sacar cargador, 2 = meter cargador, 3 = montar cerrojo
var reload_step_elapsed: float = 0.0
var reload_step_progress: float = 0.0
var reload_weapon_kind: String = ""

func is_firearm_weapon(w: WeaponData) -> bool:
	if w == null:
		return false
	return str(w.name).to_lower() in ["flintlock", "pistol", "flintlock_pistol", "rifle", "assault_rifle", "rifle_weapon"]

func is_firearm_equipped() -> bool:
	return is_instance_valid(player) and is_firearm_weapon(player.equipped_weapon)

func is_rifle_weapon(w: WeaponData) -> bool:
	if w == null:
		return false
	return str(w.name).to_lower() in ["rifle", "assault_rifle", "rifle_weapon"]

func get_reserve_ammo_count(is_rifle: bool) -> int:
	var inv = player.get("inventory") if is_instance_valid(player) else null
	if inv == null:
		return 0
	if is_rifle:
		return int(inv.get_count("rifle_ammo"))
	return int(inv.get_count("pistol_ammo")) + int(inv.get_count("powder_charge"))

func _consume_one_reserve_ammo(is_rifle: bool) -> bool:
	var inv = player.get("inventory") if is_instance_valid(player) else null
	if inv == null:
		return false
	if is_rifle:
		if inv.has_item("rifle_ammo", 1):
			inv.remove_item("rifle_ammo", 1)
			return true
		return false
	if inv.has_item("pistol_ammo", 1):
		inv.remove_item("pistol_ammo", 1)
		return true
	if inv.has_item("powder_charge", 1):
		inv.remove_item("powder_charge", 1)
		return true
	return false

func start_manual_reload() -> bool:
	if not is_instance_valid(player) or not is_firearm_equipped():
		return false
	if reload_step > 0:
		return false
	var is_rifle: bool = is_rifle_weapon(player.equipped_weapon)
	var cur_mag: int = rifle_mag_loaded if is_rifle else pistol_mag_loaded
	var max_mag: int = RIFLE_MAG_MAX if is_rifle else PISTOL_MAG_MAX
	var reserve: int = get_reserve_ammo_count(is_rifle)
	if reserve <= 0:
		if player.has_method("show_hint"):
			player.call("show_hint", "⚠️ No te queda munición de %s en la mochila. Cómprala al armero o róbala." % ("fusil" if is_rifle else "pistola"))
		return false
	if cur_mag >= min(max_mag, reserve):
		if player.has_method("show_hint"):
			player.call("show_hint", "🔫 Cargador lleno (%d/%d)." % [cur_mag, max_mag])
		return false
	reload_weapon_kind = "rifle" if is_rifle else "pistol"
	reload_step = 1
	reload_step_elapsed = 0.0
	reload_step_progress = 0.0
	is_aiming_firearm = false
	CombatFeel.play(player, CombatFeel.SFX_EVADE, player.global_position, 1.35, -7.0)
	if player.has_method("show_hint"):
		player.call("show_hint", "🔄 Recargando %s — %s" % [("Fusil del Paso" if is_rifle else "Pistola de Cartuchos"), RELOAD_STEP_LABELS[0]])
	if player.has_method("_spawn_floating_text"):
		player.call("_spawn_floating_text", "🔄 " + RELOAD_STEP_LABELS[0], Color(0.95, 0.86, 0.52), -44.0)
	return true

func cancel_reload(reason: String = "Interrumpido") -> void:
	if reload_step <= 0:
		return
	var was_step: int = reload_step
	var was_rifle: bool = (reload_weapon_kind == "rifle")
	reload_step = 0
	reload_step_elapsed = 0.0
	reload_step_progress = 0.0
	reload_weapon_kind = ""
	# Si te interrumpen mientras estabas metiendo el cargador (paso 2), pierdes un cartucho al suelo
	if was_step == 2:
		_consume_one_reserve_ammo(was_rifle)
	if is_instance_valid(player):
		if player.has_method("_spawn_floating_text"):
			player.call("_spawn_floating_text", "⚠️ ¡Recarga perdida! (%s)" % reason, Color(1.0, 0.42, 0.32), -44.0)
		if player.has_method("show_hint"):
			player.call("show_hint", "⚠️ ¡Recarga interrumpida (%s)! Tienes que empezar la recarga de nuevo con [R]." % reason)

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
	if swing_phase != "idle":
		swing_phase_elapsed += delta
		if swing_phase == "shove" and swing_phase_elapsed >= swing_phase_duration:
			swing_phase = "idle"
			swing_phase_elapsed = 0.0
			swing_phase_duration = 0.0

	# C7 fase 5b/5c: apuntado con clic derecho (ADS) y progresión de la recarga manual en 3 pasos
	var eq_gun: WeaponData = player.equipped_weapon if is_instance_valid(player) else null
	if is_firearm_weapon(eq_gun):
		if reload_step > 0:
			is_aiming_firearm = false
			aim_down_sights_blend = move_toward(aim_down_sights_blend, 0.0, delta * 9.0)
			var step_dur: float = RELOAD_STEP_DURATIONS[clampi(reload_step - 1, 0, 2)]
			reload_step_elapsed += delta
			reload_step_progress = clampf(reload_step_elapsed / maxf(0.05, step_dur), 0.0, 1.0)
			if reload_step_elapsed >= step_dur:
				reload_step_elapsed = 0.0
				reload_step_progress = 0.0
				if reload_step == 1:
					reload_step = 2
					CombatFeel.play(player, CombatFeel.SFX_EVADE, player.global_position, 1.15, -6.0)
					if player.has_method("show_hint"):
						player.call("show_hint", "🔄 Recargando — " + RELOAD_STEP_LABELS[1])
					if player.has_method("_spawn_floating_text"):
						player.call("_spawn_floating_text", "🔄 " + RELOAD_STEP_LABELS[1], Color(0.95, 0.86, 0.52), -44.0)
				elif reload_step == 2:
					reload_step = 3
					CombatFeel.play(player, CombatFeel.SFX_HIT, player.global_position, 1.45, -7.0)
					if player.has_method("show_hint"):
						player.call("show_hint", "🔄 Recargando — " + RELOAD_STEP_LABELS[2])
					if player.has_method("_spawn_floating_text"):
						player.call("_spawn_floating_text", "🔄 " + RELOAD_STEP_LABELS[2], Color(0.95, 0.86, 0.52), -44.0)
				else:
					var is_r: bool = (reload_weapon_kind == "rifle")
					var max_m: int = RIFLE_MAG_MAX if is_r else PISTOL_MAG_MAX
					var res_c: int = get_reserve_ammo_count(is_r)
					var new_loaded: int = mini(max_m, res_c)
					if is_r:
						rifle_mag_loaded = new_loaded
					else:
						pistol_mag_loaded = new_loaded
					reload_step = 0
					reload_weapon_kind = ""
					CombatFeel.play(player, CombatFeel.SFX_HIT, player.global_position, 0.92, -4.0)
					if player.has_method("show_hint"):
						player.call("show_hint", "🔫 ¡Armada y lista! Cargador: %d/%d (Reserva en mochila: %d)" % [new_loaded, max_m, res_c])
					if player.has_method("_spawn_floating_text"):
						player.call("_spawn_floating_text", "🔫 ¡Cargada! (%d/%d)" % [new_loaded, max_m], Color(0.55, 0.96, 0.65), -44.0)
		else:
			var wants_ads: bool = (aim_override == 1) if aim_override >= 0 else Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			if player.has_method("is_rolling") and bool(player.call("is_rolling")):
				wants_ads = false
			is_aiming_firearm = wants_ads
			aim_down_sights_blend = move_toward(aim_down_sights_blend, 1.0 if is_aiming_firearm else 0.0, delta * 7.5)
	else:
		if reload_step > 0:
			cancel_reload("Cambio de arma")
		is_aiming_firearm = false
		aim_down_sights_blend = move_toward(aim_down_sights_blend, 0.0, delta * 9.0)

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
	return Input.is_physical_key_pressed(Teclas.tecla("bloquear") as Key)

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
	swing_phase = "shove"
	swing_phase_elapsed = 0.0
	swing_phase_duration = 0.35
	CombatFeel.play(player, CombatFeel.SFX_SWING, player.global_position, 0.7, -9.0)
	var hit_any: bool = false
	var vm_shove = get_tree().get_first_node_in_group("village_manager")
	var pl_elev_shove: int = int(vm_shove.get("player_elevation_level")) if vm_shove != null and "player_elevation_level" in vm_shove else 0
	for g in ["npcs", "wild_animals", "raiders", "domestic_pets", "enemies"]:
		for t in get_tree().get_nodes_in_group(g):
			if t == player or not (t is Node2D) or not is_instance_valid(t) or t.get("is_dead") == true:
				continue
			var t_elev_v = t.get("elevation_level")
			if vm_shove != null and not vm_shove.alcanza(player.global_position, pl_elev_shove, (t as Node2D).global_position, int(t_elev_v) if t_elev_v != null else 0):
				continue # paso a 3D, paso 5c: por altura de los pies, no por piso
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
	if event is InputEventKey and ((event as InputEventKey).keycode == KEY_SPACE or (event as InputEventKey).physical_keycode == KEY_SPACE or Teclas.es(event, "saltar") or Teclas.es(event, "rodar")):
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
		var is_non_lethal_key: bool = event.is_action_pressed("Interact") or (event is InputEventKey and event.pressed and not event.echo and Teclas.es(event, "bloquear"))
		var is_lethal_key: bool = (_is_attack_key(event) and event.is_pressed() and not event.is_echo()) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and event.pressed and not event.echo and Teclas.es(event, "rodar"))
		if is_non_lethal_key:
			_execute_stealth_takedown(current_prompt_target, false)
			get_viewport().set_input_as_handled()
			return
		elif is_lethal_key:
			_execute_stealth_takedown(current_prompt_target, true)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey and event.pressed and not event.echo and Teclas.es(event, "bloquear"):
		if start_parry():
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and Teclas.es(event, "empujar"):
		if shove():
			get_viewport().set_input_as_handled()
		return

	var equipped: WeaponData = player.equipped_weapon
	var is_firearm: bool = is_firearm_weapon(equipped)
	var is_bow: bool = equipped != null and equipped.is_ranged and not is_firearm

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
	if is_instance_valid(weapon_sprite):
		weapon_sprite.visible = false # el arma dibujada en 2D ya no se usa: la lleva el muñeco 3D
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
	if reload_step > 0 and weapon_data != player.equipped_weapon:
		cancel_reload("Cambio de arma")
	is_aiming_firearm = false
	aim_down_sights_blend = 0.0
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
	if is_firearm_weapon(equipped) and reload_step > 0:
		if player.has_method("show_hint"):
			player.call("show_hint", "🔄 Termina la recarga antes de disparar (paso %d/3)..." % reload_step)
		return
	var chaining: bool = attack_timer > 0.0 and _in_recovery and not equipped.is_ranged and (w_key in COMBO_WEAPONS) and combo_step >= 1 and combo_step < 3
	if attack_timer > 0.0 and not chaining: return
	if equipped == player.get("watering_can_weapon") and player.has_method("is_bloodstained") and bool(player.call("is_bloodstained")):
		if player.has_method("consume_water_charge") and bool(player.call("consume_water_charge")):
			attack_timer = 0.30
			player.call("wash_bloodstains", true)
			return
	var stam_cost: float = 0.0 if is_firearm_weapon(equipped) else (10.0 if equipped.is_ranged else 14.0)
	if not equipped.is_ranged and charge > 0.0:
		stam_cost += 10.0 * charge
	if stamina_comp and stam_cost > 0.0:
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
		if is_firearm_weapon(equipped):
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

	swing_phase = "windup"
	swing_phase_elapsed = 0.0
	swing_phase_duration = maxf(0.01, t_wind)
	if t_wind > 0.0:
		await get_tree().create_timer(t_wind).timeout
	if my_id != _swing_id or not is_instance_valid(player):
		return
	# Paso adelante al soltar el golpe (choca con paredes)
	if player is CharacterBody2D and float(f["lunge"]) > 0.0:
		(player as CharacterBody2D).move_and_collide(current_aim_dir * float(f["lunge"]))
	swing_phase = "active"
	swing_phase_elapsed = 0.0
	swing_phase_duration = maxf(0.01, t_act)
	hitbox_shape.disabled = false
	await get_tree().create_timer(t_act).timeout
	if is_instance_valid(hitbox_shape):
		hitbox_shape.disabled = true
	if my_id != _swing_id:
		return
	_in_recovery = true # C7 fase 3a: ventana para encadenar (espada)
	swing_phase = "recovery"
	swing_phase_elapsed = 0.0
	swing_phase_duration = maxf(0.01, t_rec)
	if t_rec > 0.0:
		await get_tree().create_timer(t_rec).timeout
	if my_id == _swing_id:
		swing_phase = "idle"
		swing_phase_elapsed = 0.0
		swing_phase_duration = 0.0
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
	var scene_root_bow: Node = player.get_tree().current_scene if player.get_tree().current_scene != null else player.get_parent()
	if scene_root_bow != null:
		scene_root_bow.add_child(arrow)

func _fire_flintlock_realtime(equipped: WeaponData) -> void:
	var is_rifle: bool = is_rifle_weapon(equipped)
	if reload_step > 0:
		if player.has_method("show_hint"):
			player.call("show_hint", "🔄 Recargando (%d/3)... Espera a montar el arma." % reload_step)
		return
	var inv = player.get("inventory")
	var mag_now: int = rifle_mag_loaded if is_rifle else pistol_mag_loaded
	if mag_now <= 0:
		CombatFeel.play(player, CombatFeel.SFX_EVADE, player.global_position, 1.65, -8.0)
		if get_reserve_ammo_count(is_rifle) > 0:
			if player.has_method("show_hint"):
				player.call("show_hint", "🔫 ¡Cargador vacío! Iniciando recarga manual [R] (3 pasos)...")
			start_manual_reload()
		else:
			if player.has_method("show_hint"):
				player.call("show_hint", "⚠️ ¡Sin munición de %s! Compra o roba cartuchos en la armería." % ("fusil" if is_rifle else "pistola"))
		return
	if is_rifle:
		rifle_mag_loaded = maxi(0, rifle_mag_loaded - 1)
	else:
		pistol_mag_loaded = maxi(0, pistol_mag_loaded - 1)
		if inv != null and inv.has_item("powder_charge", 1) and not inv.has_item("pistol_ammo", 1):
			inv.remove_item("powder_charge", 1)

	var is_aimed: bool = aim_down_sights_blend >= 0.65
	attack_timer = (0.42 if is_rifle else 0.52)
	var av3d = player.get("avatar_3d")
	if av3d and av3d.has_method("trigger_muzzle_flash"):
		av3d.call("trigger_muzzle_flash")
	WorldStage3DScript.notify_fp_firearm_shot(player, is_rifle, aim_down_sights_blend)
	CombatFeel.play(player, CombatFeel.SFX_HIT, player.global_position, 0.72 if is_rifle else 0.88, -1.0)
	if crosshair:
		crosshair.add_recoil((6.5 if is_rifle else 5.0) * (0.55 if is_aimed else 1.35))

	var spread_rad: float = 0.0
	if is_aimed:
		spread_rad = randf_range(-0.008, 0.008) if is_rifle else randf_range(-0.015, 0.015)
	else:
		spread_rad = randf_range(-0.22, 0.22) if is_rifle else randf_range(-0.18, 0.18)
	var shoot_dir: Vector2 = current_aim_dir.rotated(spread_rad).normalized()
	var pivot_global := player.global_position + Vector2(0, -10)
	var bullet := ArrowProjectile.new()
	bullet.is_bullet = true
	bullet.global_position = pivot_global + shoot_dir * 14.0
	bullet.direction = shoot_dir
	bullet.max_range = 480.0 if is_rifle else 360.0
	bullet.speed = 860.0 if is_rifle else 680.0
	bullet.shooter = player
	bullet.damage_data = equipped.damage_data.copy()
	bullet.damage_data.is_firearm_bullet = true
	bullet.damage_data.firearm_kind = "rifle" if is_rifle else "pistol"
	bullet.damage_data.is_aimed_shot = is_aimed
	bullet.damage_data.weapon_tag = "Fusil de Asalto" if is_rifle else "Arcabuz de Chispa"
	bullet.damage_data.amount = (96.0 if is_aimed else 84.0) if is_rifle else (72.0 if is_aimed else 62.0)
	bullet.damage_data.bleed_buildup = 75.0 if is_rifle else 58.0
	bullet.damage_data.stun_buildup = 48.0 if is_rifle else 34.0
	bullet.damage_data.source = player
	var scene_root_gun: Node = player.get_tree().current_scene if player.get_tree().current_scene != null else player.get_parent()
	if scene_root_gun != null:
		scene_root_gun.add_child(bullet)

	var rem_mag: int = rifle_mag_loaded if is_rifle else pistol_mag_loaded
	var cap_mag: int = RIFLE_MAG_MAX if is_rifle else PISTOL_MAG_MAX
	if player.has_method("_spawn_floating_text"):
		var shot_lbl: String = "💥🔫 ¡Disparo de %s! (%d/%d)" % [("Fusil" if is_rifle else "Pistola"), rem_mag, cap_mag]
		player.call("_spawn_floating_text", shot_lbl, Color(1.0, 0.82, 0.35), -48.0)

	# Alerta sonora potente a todo el entorno cercano (420 px): asusta a civiles y atrae a guardias
	var vm = get_tree().get_first_node_in_group("village_manager")
	var pl_elev: int = int(vm.get("player_elevation_level")) if vm != null and "player_elevation_level" in vm else 0
	if AudioManager:
		AudioManager.emit_noise(player.global_position, 420.0, pl_elev, "gunshot")
	var alerted_guard: bool = false
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and not n.is_dead and not n.is_downed and not n.is_sleeping and not n.is_stunned_flag:
			if vm and vm.has_method("are_on_same_elevation") and not bool(vm.call("are_on_same_elevation", pl_elev, n.elevation_level)):
				continue
			var d_npc: float = (n as Node2D).global_position.distance_to(player.global_position)
			if d_npc <= 420.0:
				var is_guard_npc: bool = int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF)]
				if is_guard_npc:
					alerted_guard = true
					if "investigate_pos" in n:
						n.investigate_pos = player.global_position
					if "investigate_timer" in n:
						n.investigate_timer = maxf(float(n.investigate_timer), 14.0)
					if "alert_flash_timer" in n:
						n.alert_flash_timer = 2.0
					if n.has_method("_spawn_floating_text"):
						n.call("_spawn_floating_text", "🚨 ¡Disparo en el valle! ¡A cubierto!", Color(1.0, 0.32, 0.22), -44.0)
				else:
					if n.has_method("_spawn_floating_text"):
						n.call("_spawn_floating_text", "⚠️ ¡Un disparo de arma de fuego!", Color.ORANGE_RED, -42.0)
	if alerted_guard and vm != null and "wanted_level" in vm:
		var raid_active: bool = bool(vm.get("raid_active")) if "raid_active" in vm else false
		if not raid_active and int(vm.wanted_level) < 1:
			vm.wanted_level = 1

func _on_hitbox_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var target_entity: Node = area.get_parent() if area.get_parent() else area
		var vm_hb = get_tree().get_first_node_in_group("village_manager")
		if vm_hb != null and target_entity is Node2D:
			var t_elev_hb = target_entity.get("elevation_level")
			if not vm_hb.alcanza(player.global_position, int(vm_hb.get("player_elevation_level")), (target_entity as Node2D).global_position, int(t_elev_hb) if t_elev_hb != null else 0):
				return # paso a 3D, paso 5c: por altura de los pies, no por piso
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
		WorldStage3DScript.notify_fp_melee_hit(player, target as Node2D, dir if dir.length_squared() > 0.01 else current_aim_dir, f, _swing_power)
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
	WorldStage3DScript.trigger_fp_camera_shake(amp)
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
