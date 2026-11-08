@tool
extends Node2D

## Escenario 3D Low-Poly / Greybox Estilizado del Valle («La Placa de Petri» - Fase 2)
## - Renderiza terreno, caminos, plaza, pozos, parque, mirador del lago, ciénaga, lavadero,
##   cementerio parroquial, farolas con luz real, todos los edificios y solares, interiores 3D,
##   puertas abatibles, postigos de ventanas, tejados con apertura automática (Cutaway),
##   altillos (+1), alcantarillas (-1) y el asentamiento fronterizo «Puesto del Paso».
## - Se sincroniza 1:1 con las coordenadas 2D de colisión y navegación, permitiendo alternar
##   en vivo entre 2D y 3D con la tecla [F10] sin alterar ni una sola regla ni test del juego.

const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")
const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const VillageRestaurant = preload("res://scripts/systems/VillageRestaurant.gd") # R1
const VillageTavern = preload("res://scripts/systems/VillageTavern.gd")
const VillageWorkScript = preload("res://scripts/systems/VillageWork.gd")
const VillageUnderworldScript = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageHousingScript = preload("res://scripts/systems/VillageHousing.gd")
const FishingSpotScript = preload("res://scripts/obstacles/FishingSpot.gd")

const WORLD_SCALE: float = 0.02
const PITCH_DEG: float = 58.0
## Resolución interna: suficiente para que el 3D se lea como 3D (aristas, sombras); las texturas siguen pixeladas.
const VIEWPORT_W: int = 1280
const VIEWPORT_H: int = 720
const RETRO_TRIPLANAR_SCALE: float = 0.78

var vm: Node2D = null
var _is_headless: bool = false
var _sin_p: float = sin(deg_to_rad(PITCH_DEG))
var _cos_p: float = cos(deg_to_rad(PITCH_DEG))

var sub_viewport: SubViewport = null
var stage_sprite: Sprite2D = null
var stage_root_3d: Node3D = null
var cam_3d: Camera3D = null
var sun_light: DirectionalLight3D = null
var fill_light: DirectionalLight3D = null
var world_env: WorldEnvironment = null

var terrain_root_3d: Node3D = null
var buildings_root_3d: Node3D = null
var lots_root_3d: Node3D = null
var streetlights_root_3d: Node3D = null
var sewers_root_3d: Node3D = null
var outpost_root_3d: Node3D = null
var graves_root_3d: Node3D = null

var _mat_cache: Dictionary = {}
var _building_records_3d: Array[Dictionary] = []
var _door_nodes_3d: Array[Dictionary] = []
var _window_nodes_3d: Array[Dictionary] = []
var _chest_nodes_3d: Array[Dictionary] = []
var _building_furniture_rects: Dictionary = {} # key "b_id#floor" -> Array[Dictionary] {name, rect}
var _current_building_id: String = ""
var _current_building_floor: int = 0
var _morgue_body_nodes_3d: Array[Node3D] = []
var _jail_gate_pivot_3d: Node3D = null
var _streetlight_nodes_3d: Array[Dictionary] = []
var _floodlight_nodes_3d: Array[Dictionary] = []
var _last_buried_count: int = -1
var _last_use_3d: bool = true
var _cutaway_accum: float = 0.0
var nature_root_3d: Node3D = null
var _nature_accum: float = 10.0
var _nature_scan_accum: float = 10.0
var _nature_sources: Array = [] # [{"node": Node2D, "kind": "pine"|"rock"|"deco_pine", "sprite": CanvasItem}]
var _nature_nodes: Dictionary = {} # instance_id -> {"tree": Node3D, "stump": Node3D}
## Rendimiento: árboles y rocas iguales se dibujan juntos por zonas (una sola orden a la tarjeta por modelo y zona).
const BATCH_CHUNK_PX: float = 512.0
var _batches: Dictionary = {} # clave -> {"mmi": MultiMeshInstance3D, "entries": [{"xf": Transform3D, "vis": bool}]}
var _batch_dirty: Dictionary = {}
var _prop_sources: Array = [] # [{"sprite": Sprite2D, "kind": String}] objetos quietos 2D con su versión 3D
var _prop_nodes: Dictionary = {} # instance_id del sprite -> {"root": Node3D, "variant": String}
var _extra_hidden_2d: Array = [] # Piezas 2D (suelos, muros, cercas) que se esconden en 3D: casa del jugador y gallinero
var _camp_node: Node2D = null
var _player_house_3d: Node3D = null
var _player_house_roof: Node3D = null
var _player_house_rect: Rect2 = Rect2()
var _player_house_tier: int = -1
var _coop_node: Node2D = null
var _coop_3d: Node3D = null
var _coop_gap_3d: Node3D = null
var _grid_panel_bulb_3d: MeshInstance3D = null
var _heist_prop_3d: Node3D = null
var _last_heist_sig: String = ""
var _club_root_3d: Node3D = null # P6: club de pelea del sótano de la taberna
var _town_ledger_3d: Node3D = null # P5: libro de cuentas en la mesa del ayuntamiento
var _home_props_3d: Node3D = null
var _last_home_props_sig: String = ""
var _sabotage_fx_3d: Dictionary = {} # role_id -> Node3D (humo, chispas y fuego 3D de taller saboteado)
var _sky_mat: ShaderMaterial = null
var _sky_res: Sky = null

const SKY_CLOUD_SHADER_CODE := """
shader_type sky;

uniform vec3 zenith_col : source_color = vec3(0.20, 0.46, 0.82);
uniform vec3 horizon_col : source_color = vec3(0.68, 0.84, 0.96);
uniform vec3 ground_col : source_color = vec3(0.22, 0.34, 0.18);
uniform vec3 sun_dir = vec3(-0.45, 0.65, -0.60);
uniform vec3 sun_col : source_color = vec3(1.0, 0.94, 0.78);
uniform vec3 cloud_lit_col : source_color = vec3(0.98, 0.97, 0.94);
uniform vec3 cloud_shade_col : source_color = vec3(0.62, 0.70, 0.82);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.48;
uniform float star_visibility : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.52;
	for (int i = 0; i < 4; i++) {
		v += amp * noise2(p);
		p = p * 2.07 + vec2(13.7, 9.2);
		amp *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float y = dir.y;
	if (y < 0.0) {
		COLOR = mix(horizon_col, ground_col, clamp(-y * 3.5, 0.0, 1.0));
	} else {
		float h_t = pow(clamp(1.0 - y, 0.0, 1.0), 2.2);
		vec3 sky_base = mix(zenith_col, horizon_col, h_t);
		vec3 s_dir = normalize(sun_dir);
		float sun_dot = max(dot(dir, s_dir), 0.0);
		// Halo solar / lunar y disco celeste
		sky_base += sun_col * pow(sun_dot, 8.0) * 0.28;
		float sun_disc = smoothstep(0.9965, 0.9990, sun_dot);
		sky_base = mix(sky_base, sun_col * 1.35, sun_disc);

		// Estrellas nocturnas en la bóveda superior
		if (star_visibility > 0.01 && y > 0.06) {
			vec2 star_cell = floor(dir.xz / max(y + 0.15, 0.15) * 95.0);
			float sh = hash21(star_cell);
			if (sh > 0.986) {
				float twinkle = 0.65 + 0.35 * sin(TIME * 2.4 + sh * 40.0);
				sky_base += vec3(0.90, 0.94, 1.0) * star_visibility * twinkle * smoothstep(0.06, 0.28, y);
			}
		}

		// Dos capas de nubes con ligero pixelado retro y volumen iluminado por el sol
		if (y > 0.02) {
			vec2 proj = dir.xz / max(y + 0.16, 0.16);
			vec2 p_q = floor(proj * 64.0) / 64.0;
			vec2 uv1 = mix(proj, p_q, 0.35) * 1.15 + vec2(TIME * 0.012, TIME * 0.005);
			vec2 uv2 = proj * 2.35 - vec2(TIME * 0.007, TIME * 0.009);
			float n1 = fbm(uv1);
			float n2 = fbm(uv2);
			float c_val = n1 * 0.72 + n2 * 0.28;
			float thresh = 1.0 - cloud_coverage * 0.78;
			float cloud_mask = smoothstep(thresh, thresh + 0.24, c_val) * smoothstep(0.02, 0.18, y);
			float light_grad = clamp(fbm(uv1 + s_dir.xz * 0.18) - n1 + 0.55, 0.0, 1.0);
			vec3 c_col = mix(cloud_shade_col, cloud_lit_col, light_grad);
			c_col += sun_col * pow(sun_dot, 5.0) * 0.22;
			sky_base = mix(sky_base, c_col, clamp(cloud_mask * 0.90, 0.0, 0.92));
		}
		COLOR = sky_base;
	}
}
"""

const GROUND_TERRAIN_SHADER_CODE := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;

uniform sampler2D tex_grass : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_overlay : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_dirt : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint_primary : source_color = vec3(0.33, 0.50, 0.24);
uniform vec3 tint_secondary : source_color = vec3(0.24, 0.39, 0.18);
uniform vec3 tint_earth : source_color = vec3(0.44, 0.35, 0.24);
uniform float dirt_blend : hint_range(0.0, 1.0) = 0.16;
uniform float use_vertex_biomes : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec4 v_biome;

float g_hash(vec2 p) {
	p = fract(p * vec2(234.17, 567.89));
	p += dot(p, p + 34.56);
	return fract(p.x * p.y);
}

float g_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(g_hash(i), g_hash(i + vec2(1.0, 0.0)), f.x),
		mix(g_hash(i + vec2(0.0, 1.0)), g_hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

vec2 g_rot(vec2 uv, float ang) {
	float c = cos(ang);
	float s = sin(ang);
	return vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_biome = COLOR;
}

void fragment() {
	vec2 w_uv = v_world_pos.xz;
	// Deformación orgánica y mezcla de 2 proyecciones rotadas para eliminar por completo la cuadrícula de baldosas
	vec2 warp = vec2(
		g_noise(w_uv * 0.38 + vec2(3.1, 7.4)) - 0.5,
		g_noise(w_uv * 0.38 + vec2(19.2, 11.8)) - 0.5
	) * 0.65;
	vec2 uv_a = g_rot(w_uv + warp * 1.35, 0.54) * 1.65;
	vec2 uv_b = g_rot(w_uv - warp * 1.15, -0.89) * 2.15 + vec2(0.41, 0.27);
	float rot_mix = smoothstep(0.25, 0.75, g_noise(w_uv * 0.27 + vec2(5.2, 1.9)));

	vec3 g_a = texture(tex_grass, uv_a).rgb;
	vec3 g_b = texture(tex_grass, uv_b).rgb;
	vec3 g_mid = mix(g_a, g_b, rot_mix);
	// Eliminar por completo cualquier borde periódico de baldosa en laderas vistas de lejos
	g_mid = mix(vec3(0.78), g_mid, 0.22);

	vec3 g_over = mix(vec3(0.78), texture(tex_overlay, g_rot(w_uv + warp * 0.8, 1.12) * 1.95 + vec2(0.37, 0.61)).rgb, 0.24);
	vec3 d_tex = mix(vec3(0.75), texture(tex_dirt, g_rot(w_uv + warp * 0.6, 0.33) * 1.75).rgb, 0.32);

	float macro = g_noise(w_uv * 0.14);
	float meso = g_noise(w_uv * 0.55 + warp);
	float micro = g_noise(w_uv * 3.8 + warp * 2.0);
	float blade = g_noise(w_uv * 16.0 + vec2(macro, meso) * 2.5);

	float b_mix = smoothstep(0.25, 0.75, macro * 0.65 + meso * 0.35);
	vec3 meadow_tint = mix(tint_primary, tint_secondary, b_mix);
	float eff_dirt_b = dirt_blend;
	vec3 eff_earth = tint_earth;
	if (use_vertex_biomes > 0.5) {
		vec3 forest_tint = mix(vec3(0.17, 0.29, 0.14), vec3(0.11, 0.21, 0.10), b_mix);
		vec3 plains_tint = mix(vec3(0.31, 0.37, 0.20), vec3(0.23, 0.29, 0.16), b_mix);
		meadow_tint = mix(meadow_tint, forest_tint, clamp(v_biome.r, 0.0, 1.0));
		meadow_tint = mix(meadow_tint, plains_tint, clamp(v_biome.g, 0.0, 1.0));
		eff_dirt_b = clamp(dirt_blend + v_biome.r * 0.14 + v_biome.g * 0.12 + v_biome.b * 0.58, 0.0, 0.92);
		eff_earth = mix(eff_earth, vec3(0.30, 0.22, 0.15), clamp(v_biome.r, 0.0, 1.0));
		eff_earth = mix(eff_earth, vec3(0.35, 0.28, 0.19), clamp(v_biome.g, 0.0, 1.0));
		eff_earth = mix(eff_earth, vec3(0.33, 0.27, 0.19), clamp(v_biome.b, 0.0, 1.0));
	}
	vec3 base_grass = mix(meadow_tint * 0.88, g_mid * 1.18 * meadow_tint, 0.48);
	base_grass = mix(base_grass, g_over * meadow_tint * 1.08, 0.22);
	base_grass *= mix(0.90, 1.10, micro * 0.55 + blade * 0.45);

	// Calvas naturales de tierra húmeda, orillas y laderas empinadas
	float earth_mask = smoothstep(0.68 - eff_dirt_b * 0.42, 0.88, macro * 0.60 + meso * 0.40);
	if (use_vertex_biomes > 0.5) {
		earth_mask = max(earth_mask, clamp(v_biome.b * 0.88, 0.0, 0.92));
	}
	vec3 earth_col = mix(eff_earth * 0.92, d_tex * eff_earth * 1.18, 0.55);
	vec3 surface_col = mix(base_grass, earth_col, clamp(earth_mask, 0.0, 0.88));
	if (use_vertex_biomes > 0.5 && v_biome.a > 0.02) {
		vec3 rock_slope = mix(vec3(0.46, 0.42, 0.35), d_tex * vec3(0.58, 0.53, 0.44), 0.60);
		surface_col = mix(surface_col, rock_slope, clamp(v_biome.a * 0.85, 0.0, 0.78));
	}
	ALBEDO = surface_col;
	ROUGHNESS = mix(0.90, 0.97, max(earth_mask, v_biome.a * use_vertex_biomes));
	METALLIC = 0.0;
}
"""

## B7: Prototipo de vista en primera persona ([F6] o [F8]).
static var first_person_active: bool = false
static var fp_yaw: float = PI * 0.5 # ángulo horizontal en el plano 2D (0 = Este, PI/2 = Sur, -PI/2 = Norte)
static var fp_pitch: float = 0.0    # ángulo vertical en radianes (positivo = mirar arriba, negativo = abajo)
const FP_EYE_HEIGHT_PX: float = 15.5
const FP_MOUSE_SENS: float = 0.0032
const FP_MAX_PITCH: float = 0.85

var fp_hud_layer: CanvasLayer = null
var fp_crosshair: Control = null
var fp_interact_label: Label = null
var fp_mode_badge: Label = null
var fp_lantern_light: OmniLight3D = null
var _fp_viewmodel_root: Node3D = null
var _fp_left_arm: Node3D = null
var _fp_right_arm: Node3D = null
var _fp_weapon_mount: Node3D = null
var _fp_swing_trail: MeshInstance3D = null
var _fp_weapon_meshes: Dictionary = {}
var _fp_walk_bob_t: float = 0.0
var _fp_damage_vignette: ColorRect = null
var _fp_hit_flash_rect: ColorRect = null
var _fp_muzzle_flash_mesh: MeshInstance3D = null
var _fp_muzzle_light: OmniLight3D = null

## C7 fase 5a/5b: estado de sacudida, impacto, retroceso de disparo y daño en primera persona
static var _fp_shake_timer: float = 0.0
static var _fp_shake_amp: float = 0.0
static var _fp_hit_confirm_timer: float = 0.0
static var _fp_hurt_flash_timer: float = 0.0
static var _fp_block_flash_timer: float = 0.0
static var _fp_camera_punch_pitch: float = 0.0
static var _fp_camera_punch_roll: float = 0.0
static var _fp_gun_recoil_kick: float = 0.0
static var _fp_muzzle_flash_timer: float = 0.0
static var _active_stage_instance: Node = null

static func trigger_fp_camera_shake(amp: float = 4.0) -> void:
	_fp_shake_amp = maxf(_fp_shake_amp, clampf(amp * 0.012, 0.015, 0.095))
	_fp_shake_timer = maxf(_fp_shake_timer, 0.14)

static func notify_fp_firearm_shot(_player: Node2D, is_rifle: bool = false, ads_blend: float = 0.0) -> void:
	var recoil_up: float = (0.082 if is_rifle else 0.058) * lerpf(1.0, 0.65, clampf(ads_blend, 0.0, 1.0))
	fp_pitch = clampf(fp_pitch + recoil_up, -FP_MAX_PITCH, FP_MAX_PITCH)
	_fp_gun_recoil_kick = 1.0
	_fp_muzzle_flash_timer = 0.12
	_fp_camera_punch_pitch = 0.075 if is_rifle else 0.055
	_fp_camera_punch_roll = 0.032 * (1.0 if randf() > 0.5 else -1.0)
	trigger_fp_camera_shake(6.2 if is_rifle else 4.8)

static func notify_fp_melee_hit(_player: Node2D, target: Node2D, dir_2d: Vector2, feel: Dictionary, power: float = 1.0) -> void:
	var shk: float = float(feel.get("shake", 3.0)) * maxf(1.0, power)
	trigger_fp_camera_shake(shk)
	_fp_hit_confirm_timer = 0.18
	_fp_camera_punch_pitch = -0.045 * clampf(power, 0.8, 1.8)
	_fp_camera_punch_roll = 0.032 * (1.0 if randf() > 0.5 else -1.0)
	if is_instance_valid(_active_stage_instance) and _active_stage_instance.has_method("_spawn_3d_hit_effect") and is_instance_valid(target):
		_active_stage_instance.call("_spawn_3d_hit_effect", target.global_position, dir_2d, power)

static func notify_fp_player_hit(player: Node2D, attacker: Node, hp_lost: float, _is_ranged: bool = false) -> void:
	var intensity: float = clampf(hp_lost / 18.0, 0.35, 1.25)
	trigger_fp_camera_shake(clampf(hp_lost * 0.45, 2.5, 7.5))
	_fp_hurt_flash_timer = clampf(0.28 + intensity * 0.14, 0.28, 0.48)
	_fp_camera_punch_pitch = 0.065 * intensity
	var roll_sign: float = 1.0
	if is_instance_valid(player) and is_instance_valid(attacker) and attacker is Node2D:
		var rel: Vector2 = ((attacker as Node2D).global_position - player.global_position).normalized()
		roll_sign = 1.0 if rel.dot(get_fp_right_2d()) >= 0.0 else -1.0
	_fp_camera_punch_roll = 0.075 * intensity * roll_sign

static func notify_fp_block_impact(is_parry: bool = false) -> void:
	trigger_fp_camera_shake(2.8 if is_parry else 1.8)
	_fp_block_flash_timer = 0.20 if is_parry else 0.14
	_fp_camera_punch_pitch = 0.032
	_fp_camera_punch_roll = -0.025

## D1/D3: Vista cenital 3D en esquema del lugar del crimen (oculta vecinos y jugador).
var detective_topdown_active: bool = false
var detective_topdown_pos: Vector2 = Vector2.ZERO
var detective_topdown_size: float = 4.2

func set_detective_topdown(active: bool, world_pos_2d: Vector2 = Vector2.ZERO, ortho_size: float = 4.2) -> Texture2D:
	detective_topdown_active = active
	detective_topdown_pos = world_pos_2d
	detective_topdown_size = ortho_size
	if stage_root_3d != null and is_instance_valid(stage_root_3d):
		var chars := stage_root_3d.get_node_or_null("Characters3D") as Node3D
		if chars != null:
			chars.visible = not active
	if not _is_headless:
		if active:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif first_person_active:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if cam_3d != null and not active and not first_person_active:
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
	_update_roof_cutaways_and_lighting()
	_sync_camera_with_2d()
	return sub_viewport.get_texture() if sub_viewport != null else null

static func get_fp_forward_2d() -> Vector2:
	return Vector2(cos(fp_yaw), sin(fp_yaw))

static func get_fp_right_2d() -> Vector2:
	return Vector2(-sin(fp_yaw), cos(fp_yaw))

static func get_fp_aim_world_pos(origin_2d: Vector2, dist: float = 42.0) -> Vector2:
	return origin_2d + get_fp_forward_2d() * dist

static func map_wasd_to_world(raw_input: Vector2) -> Vector2:
	if not first_person_active or raw_input.length_squared() <= 0.0001:
		return raw_input
	var fwd := get_fp_forward_2d()
	var rgt := get_fp_right_2d()
	var mapped := fwd * (-raw_input.y) + rgt * raw_input.x
	if mapped.length_squared() > 1.0:
		mapped = mapped.normalized()
	return mapped

func _exit_tree() -> void:
	if first_person_active:
		first_person_active = false
		fp_pitch = 0.0
		if not _is_headless:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func setup_stage(village_manager: Node2D) -> void:
	vm = village_manager
	name = "WorldStage3D"
	_active_stage_instance = self
	_is_headless = DisplayServer.get_name() == "headless" or Engine.is_editor_hint()
	first_person_active = false
	fp_yaw = PI * 0.5
	fp_pitch = 0.0

	stage_root_3d = Node3D.new()
	stage_root_3d.name = "StageRoot3D"

	terrain_root_3d = Node3D.new()
	terrain_root_3d.name = "Terrain3D"
	stage_root_3d.add_child(terrain_root_3d)

	buildings_root_3d = Node3D.new()
	buildings_root_3d.name = "Buildings3D"
	stage_root_3d.add_child(buildings_root_3d)

	lots_root_3d = Node3D.new()
	lots_root_3d.name = "Lots3D"
	stage_root_3d.add_child(lots_root_3d)

	streetlights_root_3d = Node3D.new()
	streetlights_root_3d.name = "Streetlights3D"
	stage_root_3d.add_child(streetlights_root_3d)

	sewers_root_3d = Node3D.new()
	sewers_root_3d.name = "Sewers3D"
	sewers_root_3d.visible = false
	stage_root_3d.add_child(sewers_root_3d)

	outpost_root_3d = Node3D.new()
	outpost_root_3d.name = "Outpost3D"
	stage_root_3d.add_child(outpost_root_3d)

	graves_root_3d = Node3D.new()
	graves_root_3d.name = "Graves3D"
	stage_root_3d.add_child(graves_root_3d)

	nature_root_3d = Node3D.new()
	nature_root_3d.name = "Nature3D"
	stage_root_3d.add_child(nature_root_3d)

	if not _is_headless:
		sub_viewport = SubViewport.new()
		sub_viewport.name = "WorldSubViewport3D"
		sub_viewport.size = Vector2i(VIEWPORT_W, VIEWPORT_H)
		sub_viewport.transparent_bg = true
		sub_viewport.own_world_3d = true
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sub_viewport.msaa_3d = Viewport.MSAA_DISABLED
		add_child(sub_viewport)

		sub_viewport.add_child(stage_root_3d)

		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		var sky_sh := Shader.new()
		sky_sh.code = SKY_CLOUD_SHADER_CODE
		_sky_mat = ShaderMaterial.new()
		_sky_mat.shader = sky_sh
		_sky_res = Sky.new()
		_sky_res.sky_material = _sky_mat
		env.sky = _sky_res
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.84, 0.86, 0.90)
		env.ambient_light_energy = 0.58
		world_env = WorldEnvironment.new()
		world_env.environment = env
		stage_root_3d.add_child(world_env)

		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight3D"
		# Sol desde arriba a la izquierda: las sombras caen hacia abajo a la derecha, delante de las fachadas, donde se ven.
		sun_light.rotation_degrees = Vector3(-50.0, -135.0, 0.0)
		sun_light.light_energy = 0.96
		sun_light.light_color = Color(1.0, 0.95, 0.86)
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun_light.directional_shadow_max_distance = 140.0
		sun_light.shadow_bias = 0.03
		sun_light.shadow_normal_bias = 1.0
		sun_light.shadow_opacity = 0.78
		stage_root_3d.add_child(sun_light)

		fill_light = DirectionalLight3D.new()
		fill_light.name = "FillLight3D"
		fill_light.rotation_degrees = Vector3(-35.0, 145.0, 0.0)
		fill_light.light_energy = 0.30
		fill_light.light_color = Color(0.72, 0.80, 0.94)
		fill_light.shadow_enabled = false
		stage_root_3d.add_child(fill_light)

		cam_3d = Camera3D.new()
		cam_3d.name = "WorldCamera3D"
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
		cam_3d.near = 0.1
		cam_3d.far = 250.0
		cam_3d.size = 12.0
		cam_3d.current = true
		stage_root_3d.add_child(cam_3d)

		fp_lantern_light = OmniLight3D.new()
		fp_lantern_light.name = "FPLanternLight3D"
		fp_lantern_light.light_color = Color(1.0, 0.84, 0.56)
		fp_lantern_light.light_energy = 0.0
		fp_lantern_light.omni_range = 4.2
		fp_lantern_light.visible = false
		cam_3d.add_child(fp_lantern_light)
		_setup_fp_viewmodel()

		stage_sprite = Sprite2D.new()
		stage_sprite.name = "WorldStageSprite2D"
		stage_sprite.top_level = true
		stage_sprite.z_as_relative = false
		# Por debajo de los objetos 2D del suelo con z = -1 (huertos, camas, pozos…), por encima de los decorados planos
		# (bordes, césped del bosque), que el suelo 3D sustituye.
		stage_sprite.z_index = -2
		stage_sprite.centered = true
		stage_sprite.texture = sub_viewport.get_texture()
		stage_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(stage_sprite)

		_setup_fp_hud_layer()
	else:
		cam_3d = Camera3D.new()
		cam_3d.name = "WorldCamera3D"
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
		cam_3d.near = 0.1
		cam_3d.far = 250.0
		cam_3d.size = 12.0
		stage_root_3d.add_child(cam_3d)
		add_child(stage_root_3d)

	_build_static_terrain_3d()
	_build_sewers_3d()
	_build_streetlights_3d()
	rebuild_all_3d()
	_sync_2d_flat_visuals(CharacterAvatar3DScript.use_3d_characters)

## Relieve del terreno (Fase A — fuera del pueblo, rehecho suave):
## - Todo edificio, solar, barrio, campamento, granja/rancho, cantera y Puesto del Paso queda sobre explanada llana (0.0 px).
## - Todo camino exterior allana su trazado y sus márgenes para no subir y bajar como montaña rusa.
## - Fuera del pueblo devuelve lomas anchas y bajas (pendiente máxima < 12°, sin montículos aislados):
##   * Llanura Salvaje y borde norte: ondulaciones amplias (+10..+18 px).
##   * Bosque Profundo del Sur: lomas boscosas suaves (+12..+20 px) y vaguadas ligeras (-4 px).
##   * Lago del Oeste y Ciénaga de las Ranas: cuencas bajas (-3.8..-4.2 px) con agua a -1.5 px y orillas suaves de hierba.
static func _dist_to_seg_2d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var l2: float = ab.length_squared()
	if l2 <= 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _road_flat_mask(pos_2d: Vector2) -> float:
	var d_min: float = 99999.0
	# Calzada principal Oeste-Este (y = 50)
	d_min = minf(d_min, _dist_to_seg_2d(pos_2d, Vector2(-2150.0, 50.0), Vector2(1800.0, 50.0)))
	# Ramal Norte-Sur de la Llanura Salvaje (x = -1509, hasta las ruinas del norte en y = -285)
	d_min = minf(d_min, _dist_to_seg_2d(pos_2d, Vector2(-1509.0, -285.0), Vector2(-1509.0, 210.0)))
	d_min = minf(d_min, _dist_to_seg_2d(pos_2d, Vector2(-1560.0, -220.0), Vector2(-1460.0, -220.0)))
	# Camino transversal de entrada al Bosque y Caseríos (y = 772)
	d_min = minf(d_min, _dist_to_seg_2d(pos_2d, Vector2(-710.0, 772.0), Vector2(680.0, 772.0)))
	# Camino central del Bosque (x = 143) y bajada desde el pueblo (x = 465)
	d_min = minf(d_min, _dist_to_seg_2d(pos_2d, Vector2(143.0, 640.0), Vector2(143.0, 1080.0)))
	d_min = minf(d_min, _dist_to_seg_2d(pos_2d, Vector2(465.0, 640.0), Vector2(465.0, 790.0)))
	# Senda de los Caseríos del Bosque (x = -680)
	d_min = minf(d_min, _dist_to_seg_2d(pos_2d, Vector2(-680.0, 600.0), Vector2(-680.0, 960.0)))
	return smoothstep(32.0, 155.0, d_min)


## Relieve Fase B (pueblo): desniveles suaves por terrazas dentro del pueblo.
## - Calles que suben suavemente hacia el barrio norte (+4.2 -> +7.0 -> +9.4 px) y hacia el barrio cívico del este (+3.2 -> +5.2 px).
## - Plaza Central ligeramente elevada (+2.4 px) con rampa/escalones suaves.
## - Campos del sur ligeramente más bajos (-2.0 px).
## - Cada solar y edificio se asienta en una terraza/plataforma horizontal llana (pendiente 0° bajo la huella del edificio).
static func _village_terrace_height_px(pos_2d: Vector2) -> float:
	var x: float = pos_2d.x
	var y: float = pos_2d.y

	# 1. Terrazas norte (y < -330): suben suavemente de sur a norte; cada fila (n, m, u, f1, f2, w1) es una meseta llana.
	var north_h: float = 0.0
	if y < -240.0 and x > -400.0 and x < 1520.0:
		var t_n1: float = smoothstep(-245.0, -350.0, y) # subida de la posada/casas hacia la calle norte (n0..n6): +4.2 px
		var t_n2: float = smoothstep(-480.0, -525.0, y) # subida hacia la calleja de atrás (m1..m6, f2): +2.8 px adicionales (total +7.0 px)
		var t_n3: float = smoothstep(-640.0, -685.0, y) # subida hacia la ronda alta (u0..u6): +2.4 px adicionales (total +9.4 px)
		var w_fade: float = smoothstep(-390.0, -140.0, x) * (1.0 - smoothstep(1420.0, 1510.0, x))
		north_h = (t_n1 * 4.2 + t_n2 * 2.8 + t_n3 * 2.4) * w_fade
		# Terraza propia llana para la Cantera del Noroeste (w1: x = -345..-115, y = -410..-250) a +3.5 px
		if x < -95.0 and y < -200.0:
			var qw: float = smoothstep(-380.0, -340.0, x) * (1.0 - smoothstep(-115.0, -65.0, x))
			var qy: float = smoothstep(-210.0, -255.0, y) * (1.0 - smoothstep(-415.0, -455.0, y))
			north_h = lerpf(north_h, 3.5, qw * qy)

	# 2. Terrazas este (x > 640, y in -280..450): barrio residencial/cívico (+3.2 px) y loma del este / Puesto del Paso (+5.2 px)
	var east_h: float = 0.0
	if x > 640.0 and y > -310.0 and y < 460.0:
		var t_e1: float = smoothstep(642.0, 682.0, x) # subida tras cruzar la calle de los talleres hacia casas/hospital/comisaría/capilla: +3.2 px
		var t_e2: float = smoothstep(1015.0, 1072.0, x) # subida hacia los solares del este (e2..e6, Puesto del Paso, Molino): +2.0 px (total +5.2 px)
		var ey_fade: float = smoothstep(-305.0, -245.0, y) * (1.0 - smoothstep(425.0, 458.0, y))
		east_h = (t_e1 * 3.2 + t_e2 * 2.0) * ey_fade

	# 3. Plataforma elevada de la Plaza Central (x in 380..550, y in 4..92): +2.4 px en llano con rampas suaves en los 4 accesos
	var plaza_h: float = 0.0
	if x > 356.0 and x < 574.0 and y > -18.0 and y < 114.0:
		var px_in: float = smoothstep(362.0, 390.0, x) * (1.0 - smoothstep(540.0, 568.0, x))
		var py_in: float = smoothstep(-12.0, 12.0, y) * (1.0 - smoothstep(84.0, 108.0, y))
		plaza_h = 2.4 * px_in * py_in

	# 4. Vaguada suave de los campos del sur y Barrio del Lago (y > 235): -1.8 px en llano bajo granjas, rancho y casitas
	var south_h: float = 0.0
	if y > 220.0 and x > -520.0 and x < 520.0:
		var sy_in: float = smoothstep(225.0, 285.0, y) * (1.0 - smoothstep(595.0, 645.0, y))
		var sx_in: float = smoothstep(-510.0, -430.0, x) * (1.0 - smoothstep(435.0, 505.0, x))
		# El Parque del Roble (x in 168..440, y in 208..354) queda a cota +0.6 px como terraza ajardinada
		var in_park: float = smoothstep(155.0, 172.0, x) * (1.0 - smoothstep(436.0, 452.0, x)) * smoothstep(198.0, 212.0, y) * (1.0 - smoothstep(350.0, 366.0, y))
		south_h = lerpf(-1.8 * sy_in * sx_in, 0.6, in_park)

	return north_h + east_h + plaza_h + south_h


static func terrain_height_px(pos_2d: Vector2) -> float:
	var x: float = pos_2d.x
	var y: float = pos_2d.y

	# 1. Cuenca baja y de orillas suaves del Lago del Oeste (x ~ -1080..-665, y ~ 75..245)
	var lake_h: float = 0.0
	if x < -645.0 and x > -1180.0 and y > 56.0 and y < 295.0:
		var t_east: float = smoothstep(-940.0, -730.0, x)
		var lake_cy: float = lerpf(152.0, 108.0, t_east)
		var lake_ry: float = lerpf(92.0, 44.0, t_east)
		var ld := Vector2((x + 872.0) / 238.0, (y - lake_cy) / lake_ry)
		var lr: float = ld.length()
		if lr < 1.30:
			# Lecho suave (-5.8 px) bajo la lámina de agua (-0.8 px); orillas muy tendidas sin escalón ni zanja
			var basin: float = -5.8 * (1.0 - smoothstep(0.80, 1.26, lr))
			var north_fade: float = smoothstep(56.0, 76.0, y)
			var east_fade: float = clampf((-646.0 - x) / 26.0, 0.0, 1.0)
			lake_h = basin * north_fade * east_fade

	# 2. Cuenca baja de la Ciénaga de las Ranas (x ~ -1960..-1100, y ~ 135..520)
	var marsh_h: float = 0.0
	if x < -1080.0 and y > 105.0 and y < 580.0:
		var mc := Vector2(-1535.0, 328.0)
		var md := Vector2((x - mc.x) / 390.0, (y - mc.y) / 180.0)
		var mr: float = md.length()
		if mr < 1.32:
			var m_basin: float = -3.6 * (1.0 - smoothstep(0.55, 1.12, mr))
			var m_bank: float = 2.2 * smoothstep(0.95, 1.14, mr) * (1.0 - smoothstep(1.16, 1.32, mr))
			marsh_h = m_basin + m_bank

	# 3. Relieve Fase B (pueblo): desniveles suaves por terrazas (calle norte y cívico ligeramente más altos, plaza en plataforma con escalones/rampas, campos del sur algo más bajos), mientras CADA edificio se asienta en un solar/zócalo completamente llano.
	var dx_v: float = (-665.0 - x) if x < -665.0 else ((x - 1785.0) if x > 1785.0 else 0.0)
	var dy_v: float = (-825.0 - y) if y < -825.0 else ((y - 650.0) if y > 650.0 else 0.0)
	var d_village: float = sqrt(dx_v * dx_v + dy_v * dy_v)

	# Claro llano del campamento inicial, huerto 3x3 y gallinero (x in -935..-640, y in -215..72)
	var dx_c: float = (-935.0 - x) if x < -935.0 else ((x + 640.0) if x > -640.0 else 0.0)
	var dy_c: float = (-215.0 - y) if y < -215.0 else ((y - 72.0) if y > 72.0 else 0.0)
	var d_camp: float = sqrt(dx_c * dx_c + dy_c * dy_c)

	# Explanada llana de los Caseríos del Bosque (c1, c2, c3 en x = -610..-600, y = 668..1040)
	var dx_cas: float = (-725.0 - x) if x < -725.0 else ((x + 505.0) if x > -505.0 else 0.0)
	var dy_cas: float = (600.0 - y) if y < 600.0 else ((y - 1045.0) if y > 1045.0 else 0.0)
	var d_cas: float = sqrt(dx_cas * dx_cas + dy_cas * dy_cas)

	if d_camp <= 0.001 or d_cas <= 0.001:
		return 0.0

	# Relieve suave dentro del casco del pueblo y sus terrazas (Fase B):
	if d_village <= 0.001 and absf(lake_h) < 0.001:
		return _village_terrace_height_px(pos_2d)

	var d_out: float = minf(d_village, minf(d_camp, d_cas))
	var village_edge_h: float = _village_terrace_height_px(Vector2(clampf(x, -665.0, 1785.0), clampf(y, -825.0, 650.0))) * (1.0 - smoothstep(0.0, 160.0, d_village))
	var outer_mask: float = smoothstep(0.0, 175.0, d_out) * _road_flat_mask(pos_2d)

	# 4. Lomas anchas y suaves en la Llanura Salvaje y borde exterior (sin montículos aislados; pendiente < 10°)
	var plains_h: float = 0.0
	if x < -665.0 or y < -825.0 or x > 1785.0:
		var w1: float = sin(x * 0.0024 + 0.5) * cos(y * 0.0028 - 0.3)
		var w2: float = sin((x * 0.0036 - y * 0.0030) + 1.4) * 0.55
		var swell: float = maxf(0.0, w1 + w2 * 0.70 + 0.35)
		plains_h = swell * 13.5
		# Horizonte suavemente elevado en el borde lejano del mundo para tapar el corte del suelo
		var rim_w: float = smoothstep(-1850.0, -2550.0, x) * 14.0
		var rim_n: float = smoothstep(-950.0, -1450.0, y) * 12.0
		var rim_e: float = smoothstep(1900.0, 2500.0, x) * 12.0
		plains_h += rim_w + rim_n + rim_e
		var near_water: float = clampf(absf(lake_h + marsh_h) / 2.2, 0.0, 1.0)
		plains_h *= (1.0 - near_water * 0.90)

	# 5. Ondulaciones anchas y bajas en el Bosque Profundo (sur, y > 650)
	var forest_h: float = 0.0
	if y > 650.0:
		var fy: float = smoothstep(650.0, 880.0, y)
		var fw1: float = sin(x * 0.0026 - 0.6) * sin((y - 700.0) * 0.0028 + 0.5)
		var fw2: float = cos(x * 0.0040 + y * 0.0034 + 1.1) * 0.50
		var rim_s: float = smoothstep(2050.0, 2650.0, y) * 14.0
		forest_h = ((fw1 * 11.0 + fw2 * 7.5 + 5.5) + rim_s) * fy

	return (plains_h + forest_h) * outer_mask + village_edge_h + lake_h + marsh_h


func to_3d_flat(pos_2d: Vector2, h_px: float = 0.0) -> Vector3:
	return Vector3(
		pos_2d.x * WORLD_SCALE,
		(h_px * WORLD_SCALE) / _cos_p,
		(pos_2d.y * WORLD_SCALE) / _sin_p
	)


func to_3d(pos_2d: Vector2, h_px: float = 0.0) -> Vector3:
	var eff_h: float = h_px
	if h_px > -40.0:
		eff_h += terrain_height_px(pos_2d)
	return Vector3(
		pos_2d.x * WORLD_SCALE,
		(eff_h * WORLD_SCALE) / _cos_p,
		(pos_2d.y * WORLD_SCALE) / _sin_p
	)


func terrain_normal_3d(pos_2d: Vector2, step_px: float = 10.0) -> Vector3:
	var px1: Vector3 = to_3d(pos_2d + Vector2(step_px, 0.0), 0.0)
	var px0: Vector3 = to_3d(pos_2d - Vector2(step_px, 0.0), 0.0)
	var pz1: Vector3 = to_3d(pos_2d + Vector2(0.0, step_px), 0.0)
	var pz0: Vector3 = to_3d(pos_2d - Vector2(0.0, step_px), 0.0)
	var n: Vector3 = (pz1 - pz0).cross(px1 - px0)
	return n.normalized() if n.length_squared() > 0.000001 else Vector3.UP


func _terrain_biome_color(pos_2d: Vector2, normal_3d: Vector3) -> Color:
	var x: float = pos_2d.x
	var y: float = pos_2d.y
	var edge_wave: float = sin(x * 0.009 + 1.2) * 32.0 + cos(x * 0.021 - 0.5) * 16.0
	var w_forest: float = smoothstep(665.0 + edge_wave, 775.0 + edge_wave, y)
	var w_plains: float = smoothstep(-940.0, -1180.0, x) * smoothstep(20.0, -90.0, y)
	var w_mud: float = 0.0
	# Lecho húmedo solo bajo el agua del Lago del Oeste (la orilla exterior queda de hierba verde)
	var lc := Vector2(-875.0, 152.0)
	var lr: float = Vector2((x - lc.x) / 195.0, (y - lc.y) / 76.0).length()
	if lr < 0.92 and x < -655.0:
		w_mud = maxf(w_mud, (1.0 - smoothstep(0.55, 0.92, lr)) * 0.55)
	# Lecho húmedo de la Ciénaga de las Ranas
	var mc := Vector2(-1535.0, 328.0)
	var mr: float = Vector2((x - mc.x) / 385.0, (y - mc.y) / 175.0).length()
	if mr < 1.05:
		w_mud = maxf(w_mud, (1.0 - smoothstep(0.65, 1.05, mr)) * 0.65)
	var w_slope: float = clampf((1.0 - normal_3d.y) * 2.6, 0.0, 1.0)
	return Color(w_forest, w_plains, w_mud, w_slope)

func size_3d(sz_2d: Vector2, h_px: float) -> Vector3:
	return Vector3(
		maxf(0.02, sz_2d.x * WORLD_SCALE),
		maxf(0.01, (h_px * WORLD_SCALE) / _cos_p),
		maxf(0.02, (sz_2d.y * WORLD_SCALE) / _sin_p)
	)

func _mat(key: String, col: Color, rough: float = 0.82, metal: float = 0.05, emit_col: Color = Color(0, 0, 0, 0), emit_energy: float = 0.0, tex_rel: String = "", norm_rel: String = "", triplanar_scale: float = 0.65) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if not _is_headless and not tex_rel.is_empty():
		var tex := AssetLib.load_texture(tex_rel)
		if tex != null:
			m.albedo_texture = tex
			# Estética retro: la textura pixelada manda; el color del edificio solo la tiñe un poco.
			m.albedo_color = col.lerp(Color.WHITE, 0.55)
			m.uv1_triplanar = true
			# Texturas de 64 px: una repetición cada ~64 px del mapa 2D (densidad parecida al pixel art).
			var ts := RETRO_TRIPLANAR_SCALE if tex_rel.begins_with("town_textures/") else triplanar_scale
			m.uv1_scale = Vector3(ts, ts, ts)
		if not norm_rel.is_empty():
			var ntex := AssetLib.load_texture(norm_rel)
			if ntex != null:
				m.normal_enabled = true
				m.normal_texture = ntex
				m.normal_scale = 0.75
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_energy
	_mat_cache[key] = m
	return m

func _register_furniture_rect(item_name: String, center_2d: Vector2, sz_2d: Vector2, rot_y_deg: float = 0.0) -> void:
	if _current_building_id == "" or sz_2d == Vector2.ZERO:
		return
	var eff_sz := sz_2d
	var ang := fmod(absf(rot_y_deg), 180.0)
	if absf(ang - 90.0) < 35.0:
		eff_sz = Vector2(sz_2d.y, sz_2d.x)
	var key: String = "%s#%d" % [_current_building_id, _current_building_floor]
	if not _building_furniture_rects.has(key):
		_building_furniture_rects[key] = []
	(_building_furniture_rects[key] as Array).append({
		"name": item_name,
		"rect": Rect2(center_2d - eff_sz * 0.5, eff_sz),
		"center": center_2d,
	})

func check_furniture_overlaps(warn_on_overlap: bool = true) -> Array[String]:
	var overlaps: Array[String] = []
	for key in _building_furniture_rects.keys():
		var items: Array = _building_furniture_rects[key]
		for i in range(items.size()):
			var a: Dictionary = items[i]
			var ra: Rect2 = (a["rect"] as Rect2).grow(-0.15)
			if ra.size.x <= 0.0 or ra.size.y <= 0.0:
				continue
			for j in range(i + 1, items.size()):
				var b: Dictionary = items[j]
				var rb: Rect2 = (b["rect"] as Rect2).grow(-0.15)
				if rb.size.x <= 0.0 or rb.size.y <= 0.0:
					continue
				if ra.intersects(rb):
					var msg := "[WorldStage3D] Muebles solapados en %s: '%s' %s choca con '%s' %s" % [
						str(key), str(a["name"]), str(a["rect"]), str(b["name"]), str(b["rect"])
					]
					overlaps.append(msg)
					if warn_on_overlap:
						push_warning(msg)
	return overlaps

func _add_model_2d(parent: Node3D, rel_path: String, center_2d: Vector2, bottom_h_px: float, sz_2d: Vector2 = Vector2.ZERO, height_px: float = 24.0, rot_y_deg: float = 0.0) -> Node3D:
	if _current_building_id != "" and sz_2d != Vector2.ZERO and height_px >= 2.0 and not rel_path.begins_with("graveyard/iron-fence"):
		var floor_base_h: float = 2.0 if _current_building_floor == 0 else VillageTavern.FLOOR_1_H
		if absf(bottom_h_px - floor_base_h) <= 2.5:
			_register_furniture_rect(rel_path.get_file().get_basename(), center_2d, sz_2d, rot_y_deg)
	if _is_headless or not AssetLib.has_curated_assets():
		return null
	var target_sz := Vector3.ZERO
	var fit_h := -1.0
	if sz_2d != Vector2.ZERO:
		target_sz = size_3d(sz_2d, height_px)
	else:
		fit_h = maxf(0.05, (height_px * WORLD_SCALE) / _cos_p)
	var inst := AssetLib.instantiate_model(rel_path, target_sz, fit_h, true, true)
	if inst == null:
		return null
	inst.position = to_3d(center_2d, bottom_h_px)
	if absf(rot_y_deg) > 0.01:
		inst.rotation_degrees.y = rot_y_deg
	parent.add_child(inst)
	return inst

func _add_box_2d(parent: Node3D, center_2d: Vector2, sz_2d: Vector2, bottom_h_px: float, height_px: float, mat: Material, rot_y_deg: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size_3d(sz_2d, height_px)
	mi.mesh = bm
	mi.material_override = mat
	mi.position = to_3d(center_2d, bottom_h_px + height_px * 0.5)
	if absf(rot_y_deg) > 0.01:
		mi.rotation_degrees.y = rot_y_deg
	parent.add_child(mi)
	return mi

func _add_cyl_2d(parent: Node3D, center_2d: Vector2, radius_px: float, bottom_h_px: float, height_px: float, mat: Material, top_radius_px: float = -1.0, radial_segs: int = 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = maxf(0.01, radius_px * WORLD_SCALE)
	cm.top_radius = maxf(0.0, (radius_px if top_radius_px < 0.0 else top_radius_px) * WORLD_SCALE)
	cm.height = maxf(0.01, (height_px * WORLD_SCALE) / _cos_p)
	cm.radial_segments = radial_segs
	mi.mesh = cm
	mi.material_override = mat
	mi.position = to_3d(center_2d, bottom_h_px + height_px * 0.5)
	parent.add_child(mi)
	return mi

## Tejado a dos aguas: prisma triangular cuya cumbrera va a lo largo de X (ridge_x) o de Y del mapa 2D.
func _add_prism_2d(parent: Node3D, center_2d: Vector2, sz_2d: Vector2, bottom_h_px: float, height_px: float, mat: Material, ridge_x: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	var s3 := size_3d(sz_2d, height_px)
	if ridge_x:
		pm.size = Vector3(s3.z, s3.y, s3.x)
		mi.rotation_degrees.y = 90.0
	else:
		pm.size = s3
	mi.mesh = pm
	mi.material_override = mat
	mi.position = to_3d(center_2d, bottom_h_px + height_px * 0.5)
	parent.add_child(mi)
	return mi

## Chapitel de cuatro caras (pirámide) para torres.
func _add_pyramid_2d(parent: Node3D, center_2d: Vector2, sz_2d: Vector2, bottom_h_px: float, height_px: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var s3 := size_3d(sz_2d, height_px)
	cm.top_radius = 0.0
	cm.bottom_radius = 0.5
	cm.height = 1.0
	cm.radial_segments = 4
	cm.rings = 1
	mi.mesh = cm
	mi.scale = Vector3(s3.x * 1.41, s3.y, s3.z * 1.41)
	mi.rotation_degrees.y = 45.0
	mi.material_override = mat
	mi.position = to_3d(center_2d, bottom_h_px + height_px * 0.5)
	parent.add_child(mi)
	return mi

## Panel con una textura pixelada entera en su cara frontal y trasera (puertas, ventanas).
## Las caras laterales quedan del color medio de la textura.
func _make_texture_panel(w_px: float, h_px: float, depth_px: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	var sz := size_3d(Vector2(w_px, depth_px), h_px)
	var core := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sz.x * 0.98, sz.y * 0.98, sz.z * 0.9)
	core.mesh = bm
	core.material_override = _mat("panel_core", Color(0.30, 0.20, 0.12), 0.9, 0.0)
	root.add_child(core)
	for side in [1.0, -1.0]:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(sz.x, sz.y)
		q.mesh = qm
		q.material_override = mat
		q.position = Vector3(0.0, 0.0, sz.z * 0.5 * side + 0.002 * side)
		if side < 0.0:
			q.rotation_degrees.y = 180.0
		q.name = "Face" if side > 0.0 else "FaceBack"
		root.add_child(q)
	return root

## Material para paneles: textura completa (sin repetir), filtrado pixelado y opcionalmente brillante (ventanas de noche).
func _panel_mat(key: String, tex_rel: String, lit: bool) -> StandardMaterial3D:
	var k := "panel_" + key
	if _mat_cache.has(k):
		return _mat_cache[k]
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	var tex := AssetLib.load_texture(tex_rel)
	if tex != null:
		m.albedo_texture = tex
		if lit:
			m.emission_enabled = true
			m.emission_texture = tex
			m.emission = Color(1.0, 0.78, 0.45)
			m.emission_energy_multiplier = 1.6
	if tex_rel.find("window") != -1 or tex_rel.find("door") != -1:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	_mat_cache[k] = m
	return m

func _clear_children(n: Node3D) -> void:
	if n == null:
		return
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

func rebuild_all_3d() -> void:
	if vm == null:
		return
	rebuild_buildings_3d()
	rebuild_lots_3d()
	rebuild_outpost_3d()
	rebuild_graves_3d()
	_sync_2d_flat_visuals(CharacterAvatar3DScript.use_3d_characters)

# ==============================================================================
# 1. TERRENO, CAMINOS, PLAZA, POZOS, PARQUE, LAGO, CIÉNAGA Y CEMENTERIO 3D
# ==============================================================================
func _build_static_terrain_3d() -> void:
	_clear_children(terrain_root_3d)
	_build_ground_3d()
	var m_road := _mat("road_dirt", Color(0.56, 0.46, 0.34), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.55)
	var m_curb := _mat("road_curb", Color(0.62, 0.58, 0.52), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)
	var m_plaza := _mat("plaza_stone", Color(0.66, 0.62, 0.56), 0.85, 0.05, Color.BLACK, 0.0, "town_textures/rf_cobblestone.png", "", 0.65)
	var m_plaza_trim := _mat("plaza_trim", Color(0.72, 0.68, 0.60), 0.80, 0.08, Color.BLACK, 0.0, "town_textures/floor_stone_trimsheet.png", "", 0.75)
	var m_wood := _mat("prop_wood", Color(0.54, 0.36, 0.20), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_dark_wood := _mat("prop_dark_wood", Color(0.38, 0.24, 0.13), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_stone := _mat("prop_stone", Color(0.66, 0.68, 0.72), 0.85, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.70)
	var m_water := _mat("water_blue", Color(0.18, 0.52, 0.74, 0.90), 0.20, 0.15)
	var m_marsh := _mat("water_marsh", Color(0.20, 0.42, 0.30, 0.92), 0.28, 0.10)
	var m_grass_park := _make_ground_shader_mat("ground_park_sh", Color(0.31, 0.48, 0.23), Color(0.23, 0.38, 0.17), Color(0.42, 0.34, 0.23), 0.10)
	var m_pine := _mat("pine_leaf", Color(0.16, 0.38, 0.18), 0.88, 0.0)
	var m_pine_top := _mat("pine_leaf_top", Color(0.22, 0.46, 0.22), 0.86, 0.0)
	var m_iron := _mat("wrought_iron", Color(0.22, 0.24, 0.28), 0.45, 0.75)
	var m_shingle := _mat("roof_shingle_brown", Color(0.56, 0.30, 0.18), 0.82, 0.04, Color.BLACK, 0.0, "town_textures/roof_clay_red_center.png", "", 0.75)

	# Caminos principales y calles con relieve 3D
	var road_rects: Array[Rect2] = [
		Rect2(Vector2(-1950, 36), Vector2(3288, 28)),
		Rect2(Vector2(-688, -88), Vector2(18, 124)),
		Rect2(Vector2(-688, 64), Vector2(18, 36)),
		Rect2(Vector2(-1520, -140), Vector2(22, 176)),
		Rect2(Vector2(-1520, 64), Vector2(22, 120)),
		Rect2(Vector2(452, -132), Vector2(26, 172)),
		Rect2(Vector2(452, 62), Vector2(26, 700)),
		Rect2(Vector2(-380, 760), Vector2(1040, 24)),
		Rect2(Vector2(130, 780), Vector2(26, 260)),
		Rect2(Vector2(140, 130), Vector2(24, 248)),
		Rect2(Vector2(140, 356), Vector2(312, 22)),
		Rect2(Vector2(822, -230), Vector2(24, 466)),
		Rect2(Vector2(215, -310), Vector2(20, 515)),
		Rect2(Vector2(1078, -230), Vector2(20, 480)),
		Rect2(Vector2(1318, -230), Vector2(20, 480)),
		Rect2(Vector2(452, 232), Vector2(885, 20)),
	]
	for rr in road_rects:
		_add_road_strip_3d(terrain_root_3d, rr, 1.2, m_road)
	for lr in VillageLots.ROADS:
		if lr is Rect2:
			_add_road_strip_3d(terrain_root_3d, lr as Rect2, 1.2, m_road)
	_build_barrios_3d(m_wood)
	# Callejas curvas del norte: un tramo de camino por segmento, girado, con una losa en cada codo
	for cr in VillageLots.CURVED_ROADS:
		var cpts: PackedVector2Array = VillageLots.curved_road_points(cr)
		var cw: float = float(cr["w"])
		for i in range(cpts.size() - 1):
			var a: Vector2 = cpts[i]
			var b: Vector2 = cpts[i + 1]
			_add_box_2d(terrain_root_3d, (a + b) * 0.5, Vector2(a.distance_to(b) + 2.0, cw), 0.0, 1.2, m_road, -rad_to_deg((b - a).angle()))

	# Plaza Central Empedrada en plataforma ligeramente elevada (+2.4 px en terreno) con bordillos y rampa empedrada suave en los 4 accesos
	var plaza_r := Rect2(Vector2(388, 12), Vector2(154, 72))
	_add_road_strip_3d(terrain_root_3d, plaza_r, 1.5, m_plaza)
	_add_box_2d(terrain_root_3d, Vector2(plaza_r.get_center().x, plaza_r.position.y), Vector2(plaza_r.size.x, 4.0), 1.5, 1.6, m_plaza_trim)
	_add_box_2d(terrain_root_3d, Vector2(plaza_r.get_center().x, plaza_r.end.y), Vector2(plaza_r.size.x, 4.0), 1.5, 1.6, m_plaza_trim)
	# Bordillos de piedra de la rampa de subida en los 4 accesos de la Plaza y en la subida al barrio del Este
	for access_curb in [
		[Vector2(374.0, 34.0), Vector2(24.0, 2.8)],
		[Vector2(374.0, 66.0), Vector2(24.0, 2.8)],
		[Vector2(556.0, 34.0), Vector2(24.0, 2.8)],
		[Vector2(556.0, 66.0), Vector2(24.0, 2.8)],
		[Vector2(662.0, 34.0), Vector2(28.0, 2.8)],
		[Vector2(662.0, 66.0), Vector2(28.0, 2.8)],
	]:
		_add_box_2d(terrain_root_3d, access_curb[0] as Vector2, access_curb[1] as Vector2, 0.2, 1.6, m_curb)

	# Bancos reales 3D de la Plaza Central
	for bp in [Vector2(436, 76), Vector2(494, 76)]:
		_build_bench_3d(terrain_root_3d, bp, m_wood, m_iron)

	# Tablón de Encargos 3D detallado en la Plaza (Vector2(465, 24)) con 3 pliegos legibles desde fuera
	var nb: Vector2 = vm._notice_board_pos if vm != null else Vector2(465, 24)
	_add_box_2d(terrain_root_3d, nb + Vector2(-10.0, 0.0), Vector2(3.6, 3.6), 0.0, 2.2, m_curb)
	_add_box_2d(terrain_root_3d, nb + Vector2(10.0, 0.0), Vector2(3.6, 3.6), 0.0, 2.2, m_curb)
	_add_box_2d(terrain_root_3d, nb + Vector2(-10.0, 0.0), Vector2(2.6, 2.6), 2.0, 17.5, m_dark_wood)
	_add_box_2d(terrain_root_3d, nb + Vector2(10.0, 0.0), Vector2(2.6, 2.6), 2.0, 17.5, m_dark_wood)
	_add_box_2d(terrain_root_3d, nb, Vector2(24.0, 2.6), 6.2, 11.2, m_dark_wood)
	var m_cork := _mat("notice_cork", Color(0.56, 0.39, 0.23), 0.92, 0.0)
	_add_box_2d(terrain_root_3d, nb + Vector2(0.0, 0.4), Vector2(21.6, 2.2), 7.0, 9.6, m_cork)
	_add_box_2d(terrain_root_3d, nb, Vector2(26.5, 6.2), 17.2, 2.8, m_shingle)
	_add_box_2d(terrain_root_3d, nb + Vector2(0.0, 1.4), Vector2(19.0, 1.0), 15.6, 2.0, m_dark_wood)
	var hdr_lbl := Label3D.new()
	hdr_lbl.text = "ENCARGOS DEL VALLE"
	hdr_lbl.font_size = 22
	hdr_lbl.pixel_size = 0.00075
	hdr_lbl.modulate = Color(0.96, 0.88, 0.62)
	hdr_lbl.outline_size = 2
	hdr_lbl.outline_modulate = Color(0.14, 0.10, 0.06)
	hdr_lbl.shaded = false
	hdr_lbl.double_sided = true
	hdr_lbl.position = to_3d(nb + Vector2(0.0, 2.05), 16.6)
	terrain_root_3d.add_child(hdr_lbl)
	var m_paper := _mat("parchment", Color(0.95, 0.90, 0.76), 0.90, 0.0)
	var m_wax := _mat("notice_wax_seal", Color(0.76, 0.18, 0.16), 0.55, 0.1)
	var sheet_defs := [
		[-6.8, "GREMIOS\n2 Maderas o\n1 Hierro\n28 ORO"],
		[0.0, "HOSPITAL\n2 Hierbas o\nCataplasma\n26 ORO"],
		[6.8, "ALGUACIL\nChatarra o\nAncas Rana\n34 ORO"],
	]
	for s_def in sheet_defs:
		var px: float = float(s_def[0])
		_add_box_2d(terrain_root_3d, nb + Vector2(px, 1.4), Vector2(5.8, 0.5), 7.5, 7.8, m_paper)
		_add_box_2d(terrain_root_3d, nb + Vector2(px, 1.75), Vector2(0.9, 0.4), 14.3, 0.8, m_wax)
		var s_lbl := Label3D.new()
		s_lbl.text = str(s_def[1])
		s_lbl.font_size = 20
		s_lbl.line_spacing = -2.0
		s_lbl.pixel_size = 0.00060
		s_lbl.modulate = Color(0.16, 0.11, 0.06)
		s_lbl.outline_size = 1
		s_lbl.outline_modulate = Color(0.95, 0.90, 0.76)
		s_lbl.shaded = false
		s_lbl.double_sided = true
		s_lbl.position = to_3d(nb + Vector2(px, 2.08), 11.1)
		terrain_root_3d.add_child(s_lbl)

	# (2026-11-06) Los pozos ya no van fijos aquí: los pone _sync_props_3d donde esté cada pozo 2D (también los de solares nuevos).

	# Campos arados 3D de la Granja del Sur (s1: x = -200..-113, s2: x = -77..137, y = 400..540) y explanada de roca de la Cantera (w1: x = -210..-123, y = -400..-260)
	var m_plowed := _mat("farm_plowed_soil", Color(0.38, 0.28, 0.17), 0.94, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.45)
	var m_furrow := _mat("farm_wheat_furrow", Color(0.68, 0.72, 0.26), 0.88, 0.0)
	for f_rect in [Rect2(Vector2(-200.0, 400.0), Vector2(87.0, 140.0)), Rect2(Vector2(-77.0, 400.0), Vector2(214.0, 140.0))]:
		_add_box_2d(terrain_root_3d, f_rect.get_center(), f_rect.size, 0.0, 0.8, m_plowed)
		var fy: float = f_rect.position.y + 10.0
		while fy < f_rect.end.y - 4.0:
			_add_box_2d(terrain_root_3d, Vector2(f_rect.get_center().x, fy), Vector2(f_rect.size.x - 8.0, 4.0), 0.8, 1.4, m_furrow)
			fy += 14.0
	var quarry_r := Rect2(Vector2(-210.0, -400.0), Vector2(87.0, 140.0))
	var m_quarry_rock := _mat("quarry_slab_3d", Color(0.50, 0.48, 0.44), 0.90, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.42)
	_add_box_2d(terrain_root_3d, quarry_r.get_center(), quarry_r.size, 0.0, 1.0, m_quarry_rock)

	# Corral 3D de madera y tierra del Rancho del Sur (x = 304..416, y = 398..544; el ganado vivo lo sincroniza VillageHousing.sync_livestock)
	var ranch_floor_r := Rect2(Vector2(304.0, 398.0), Vector2(112.0, 146.0))
	_add_box_2d(terrain_root_3d, ranch_floor_r.get_center(), ranch_floor_r.size, 0.0, 0.8, m_road)
	for r_side in [
		[Vector2(304.0, 398.0), Vector2(416.0, 398.0)],
		[Vector2(416.0, 398.0), Vector2(416.0, 544.0)],
		[Vector2(416.0, 544.0), Vector2(304.0, 544.0)],
		[Vector2(304.0, 544.0), Vector2(304.0, 398.0)],
	]:
		_build_fence_run_3d(terrain_root_3d, r_side[0] as Vector2, r_side[1] as Vector2, m_wood)
	# Abrevadero de madera con agua y pacas de heno en el corral del Rancho del Sur
	var m_hay := _mat("ranch_hay", Color(0.84, 0.72, 0.34), 0.92, 0.0)
	var m_trough_w := _mat("ranch_trough_water", Color(0.24, 0.52, 0.68), 0.25, 0.1)
	_add_box_2d(terrain_root_3d, Vector2(316.0, 412.0), Vector2(16.0, 6.0), 0.8, 4.2, m_dark_wood)
	_add_box_2d(terrain_root_3d, Vector2(316.0, 412.0), Vector2(13.6, 4.0), 3.6, 1.6, m_trough_w)
	_add_box_2d(terrain_root_3d, Vector2(404.0, 414.0), Vector2(9.0, 7.0), 0.8, 5.2, m_hay)
	_add_box_2d(terrain_root_3d, Vector2(404.0, 423.0), Vector2(8.0, 6.5), 0.8, 4.4, m_hay)

	# Parque del Roble ampliado (Rect2(168, 208, 272, 146)) con césped natural texturizado, bordillo bajo de piedra y bancos despejados
	var park_r := Rect2(Vector2(168.0, 208.0), Vector2(272.0, 146.0))
	var park_c: Vector2 = park_r.get_center()
	_add_box_2d(terrain_root_3d, park_c, park_r.size, 0.0, 0.25, m_grass_park)
	_add_box_2d(terrain_root_3d, Vector2(park_c.x, park_r.position.y), Vector2(park_r.size.x, 3.0), 0.0, 1.4, m_curb)
	_add_box_2d(terrain_root_3d, Vector2(park_c.x, park_r.end.y), Vector2(park_r.size.x, 3.0), 0.0, 1.4, m_curb)
	_add_box_2d(terrain_root_3d, Vector2(park_r.position.x, park_c.y), Vector2(3.0, park_r.size.y), 0.0, 1.4, m_curb)
	_add_box_2d(terrain_root_3d, Vector2(park_r.end.x, park_c.y), Vector2(3.0, park_r.size.y), 0.0, 1.4, m_curb)
	_add_box_2d(terrain_root_3d, Vector2(park_c.x, 280.0), Vector2(park_r.size.x - 16.0, 18.0), 0.0, 0.8, m_road)
	_add_box_2d(terrain_root_3d, park_c, Vector2(18.0, park_r.size.y - 16.0), 0.0, 0.8, m_road)
	var tree_idx := 0
	for tp in [Vector2(188.0, 224.0), Vector2(420.0, 224.0), Vector2(188.0, 338.0), Vector2(420.0, 338.0), Vector2(304.0, 228.0)]:
		_build_tree_3d(terrain_root_3d, tp, m_dark_wood, m_pine, m_pine_top, 1.22 if tp == Vector2(304.0, 228.0) else 0.95, tree_idx)
		tree_idx += 1
	_build_bench_3d(terrain_root_3d, Vector2(236.0, 260.0), m_wood, m_iron)
	_build_bench_3d(terrain_root_3d, Vector2(372.0, 260.0), m_wood, m_iron)
	for fp in [Vector2(248.0, 226.0), Vector2(360.0, 226.0), Vector2(248.0, 334.0), Vector2(360.0, 334.0), Vector2(304.0, 316.0)]:
		_add_cyl_2d(terrain_root_3d, fp, 4.5, 0.0, 4.5, _mat("terracotta_pot", Color(0.68, 0.34, 0.20), 0.85, 0.0), 3.2, 8)
		_add_cyl_2d(terrain_root_3d, fp, 5.2, 4.0, 4.5, m_pine_top, 3.5, 8)
	# Bancos de la plaza y Mirador del Lago en 3D
	_build_bench_3d(terrain_root_3d, Vector2(500.0, 66.0), m_wood, m_iron)
	_build_bench_3d(terrain_root_3d, Vector2(440.0, 80.0), m_wood, m_iron)
	var lv_pos := Vector2(-715.0, 184.0)
	_build_fence_run_3d(terrain_root_3d, lv_pos + Vector2(-34.0, -12.0), lv_pos + Vector2(34.0, -12.0), m_wood)
	_build_bench_3d(terrain_root_3d, lv_pos + Vector2(0.0, -2.0), m_wood, m_iron)

	# Lavadero Municipal, recolocado junto a una fuente/acequia del pueblo (al oeste de la Botica y al norte del Parque)
	var wash_c: Vector2 = VillageWorkScript.LAVADERO_POS
	_add_box_2d(terrain_root_3d, wash_c, Vector2(46, 32), 0.0, 2.0, m_stone)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(32, 14), 2.0, 5.5, m_curb)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(28, 10), 2.5, 4.8, m_water)
	for wp_off in [Vector2(-19, -12), Vector2(19, -12), Vector2(-19, 12), Vector2(19, 12)]:
		_add_box_2d(terrain_root_3d, wash_c + wp_off, Vector2(2.5, 2.5), 2.0, 18.0, m_dark_wood)
	_add_box_2d(terrain_root_3d, wash_c, Vector2(50, 36), 20.0, 4.5, m_shingle)
	_add_model_2d(terrain_root_3d, "props/Bucket_Wooden_1.gltf", wash_c + Vector2(-14, 10), 2.0, Vector2.ZERO, 6.5)
	_add_model_2d(terrain_root_3d, "props/Barrel.gltf", wash_c + Vector2(16, -10), 2.0, Vector2.ZERO, 10.0)

	# Lago del Oeste (junto al campamento inicial, un solo muelle a ras del agua, sin lavadero); sauces en la orilla exterior
	_build_lake_3d()
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", Vector2(-955, 72), -0.6, Vector2.ZERO, 40.0)
	_add_model_2d(terrain_root_3d, "nature/Willow_2.obj", Vector2(-1105, 195), -0.6, Vector2.ZERO, 38.0, 70.0)
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", Vector2(-840, 238), -0.6, Vector2.ZERO, 34.0, 140.0)

	# Ciénaga de las Ranas del Suroeste (cuenca baja con lámina de agua a -1.4 px y arbustos/sauces solo en las orillas secas)
	var marsh_water_pts := PackedVector2Array([
		Vector2(-1860, 210), Vector2(-1620, 165), Vector2(-1340, 180), Vector2(-1200, 250),
		Vector2(-1220, 390), Vector2(-1360, 470), Vector2(-1650, 485), Vector2(-1850, 420),
		Vector2(-1910, 310)
	])
	_add_flat_poly_2d(terrain_root_3d, marsh_water_pts, -1.4, m_marsh, true)
	for rp in [
		Vector2(-1880, 198), Vector2(-1710, 152), Vector2(-1480, 155), Vector2(-1310, 166),
		Vector2(-1185, 255), Vector2(-1205, 415), Vector2(-1560, 500), Vector2(-1865, 435)
	]:
		if _add_model_2d(terrain_root_3d, "nature/Bush_1.obj", rp, -0.5, Vector2.ZERO, 12.0) == null:
			_add_cyl_2d(terrain_root_3d, rp, 4.0, -0.5, 8.0, m_pine, 1.5, 6)
	_add_model_2d(terrain_root_3d, "nature/Willow_2.obj", Vector2(-1895, 205), -0.6, Vector2.ZERO, 36.0)
	_add_model_2d(terrain_root_3d, "nature/Willow_1.obj", Vector2(-1195, 395), -0.6, Vector2.ZERO, 34.0, 110.0)
	_add_model_2d(terrain_root_3d, "nature/Rock_2.obj", Vector2(-1360, 162), -0.6, Vector2.ZERO, 13.0)

	# Matorral, arbustos de bayas y troncos caídos repartidos por el Bosque Profundo ampliado (y = 780..2300)
	var forest_bushes: Array[Vector2] = [
		Vector2(-960, 910), Vector2(-680, 920), Vector2(-460, 870), Vector2(-820, 1080),
		Vector2(-520, 1140), Vector2(-940, 1380), Vector2(-640, 1420), Vector2(-380, 1380),
		Vector2(-820, 1640), Vector2(-480, 1660), Vector2(-720, 1920), Vector2(-380, 2060),
		Vector2(-120, 920), Vector2(180, 910), Vector2(420, 930), Vector2(40, 1140),
		Vector2(340, 1140), Vector2(-40, 1380), Vector2(260, 1360), Vector2(540, 1390),
		Vector2(140, 1620), Vector2(440, 1640), Vector2(-80, 1860), Vector2(280, 1880),
		Vector2(120, 2120), Vector2(460, 2110), Vector2(820, 960), Vector2(1120, 1040),
		Vector2(940, 1220), Vector2(1220, 1360), Vector2(980, 1640), Vector2(1180, 1840)
	]
	var bush_models := ["nature/Bush_1.obj", "nature/Bush_2.obj", "nature/BushBerries_1.obj", "nature/BushBerries_2.obj"]
	for bi in range(forest_bushes.size()):
		var bm: String = bush_models[bi % bush_models.size()]
		_add_model_2d(terrain_root_3d, bm, forest_bushes[bi], -1.0, Vector2.ZERO, 12.5, float((bi * 47) % 360))
	var fallen_logs: Array[Vector2] = [
		Vector2(-860, 1040), Vector2(-490, 1240), Vector2(-740, 1560), Vector2(-560, 1820),
		Vector2(-20, 1090), Vector2(290, 1310), Vector2(80, 1580), Vector2(380, 1810),
		Vector2(180, 2040), Vector2(890, 1180), Vector2(1080, 1490), Vector2(1120, 1920)
	]
	for li in range(fallen_logs.size()):
		_add_model_2d(terrain_root_3d, "nature/WoodLog.obj", fallen_logs[li], -0.8, Vector2.ZERO, 16.0, float((li * 63) % 360))

	# Cercado del Cementerio Parroquial ampliado (Rect2(Vector2(822, 260), Vector2(268, 168))) con caminos en cruz, verja de hierro y piedra y 24 tumbas en filas
	var cem_r := Rect2(Vector2(822.0, 260.0), Vector2(268.0, 168.0))
	var cem_c := cem_r.get_center()
	var m_cem_curb := _mat("cem_curb_stone", Color(0.48, 0.50, 0.54), 0.88, 0.05)
	var m_cem_mound := _mat("cem_mound_earth", Color(0.34, 0.24, 0.16), 0.95, 0.0)
	_add_box_2d(terrain_root_3d, cem_c, cem_r.size, 0.0, 1.0, _mat("cem_ground", Color(0.24, 0.32, 0.22), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.45))
	# Caminos interiores de losas de piedra en cruz (Norte-Sur en x = 888 y Este-Oeste en y = 344)
	_add_box_2d(terrain_root_3d, Vector2(888.0, cem_c.y), Vector2(16.0, cem_r.size.y - 6.0), 1.0, 0.45, m_stone)
	_add_box_2d(terrain_root_3d, Vector2(cem_c.x, 344.0), Vector2(cem_r.size.x - 8.0, 14.0), 1.0, 0.45, m_stone)
	# Zócalo de piedra y verja perimetral de hierro forjado con pilares
	_add_box_2d(terrain_root_3d, Vector2(cem_c.x, cem_r.end.y), Vector2(cem_r.size.x, 3.5), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(cem_c.x, cem_r.end.y), Vector2(cem_r.size.x, 2.2), 4.0, 8.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.position.x, cem_c.y), Vector2(3.5, cem_r.size.y), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.position.x, cem_c.y), Vector2(2.2, cem_r.size.y), 4.0, 8.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.end.x, cem_c.y), Vector2(3.5, cem_r.size.y), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(cem_r.end.x, cem_c.y), Vector2(2.2, cem_r.size.y), 4.0, 8.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(846.0, cem_r.position.y), Vector2(48.0, 3.5), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(846.0, cem_r.position.y), Vector2(48.0, 2.2), 4.0, 8.0, m_iron)
	_add_box_2d(terrain_root_3d, Vector2(998.0, cem_r.position.y), Vector2(184.0, 3.5), 0.0, 4.0, m_cem_curb)
	_add_box_2d(terrain_root_3d, Vector2(998.0, cem_r.position.y), Vector2(184.0, 2.2), 4.0, 8.0, m_iron)
	for pil_p in [Vector2(822, 260), Vector2(870, 260), Vector2(906, 260), Vector2(998, 260), Vector2(1090, 260), Vector2(822, 344), Vector2(1090, 344), Vector2(822, 428), Vector2(956, 428), Vector2(1090, 428)]:
		_add_box_2d(terrain_root_3d, pil_p, Vector2(6.5, 6.5), 0.0, 14.0, m_cem_curb)
	_add_model_2d(terrain_root_3d, "graveyard/iron-fence.glb", Vector2(888.0, cem_r.position.y), 0.0, Vector2.ZERO, 18.0)

	# 4 filas × 6 columnas = 24 tumbas con bordillo, túmulo de tierra y lápidas/cruces variadas (sin los 2 bloques enormes de piedra)
	var stone_models: Array[String] = [
		"graveyard/gravestone-cross.glb",
		"graveyard/gravestone-round.glb",
		"graveyard/gravestone-decorative.glb",
		"graveyard/gravestone-wide.glb",
		"graveyard/cross-column.glb",
		"graveyard/cross-wood.glb",
	]
	var row_ys_3d: Array[float] = [286.0, 316.0, 372.0, 402.0]
	var col_xs_3d: Array[float] = [852.0, 924.0, 954.0, 984.0, 1014.0, 1044.0]
	var g_i3d: int = 0
	for ry in row_ys_3d:
		for cx in col_xs_3d:
			var gp_cem := Vector2(cx, ry)
			_add_box_2d(terrain_root_3d, gp_cem + Vector2(0, 2.5), Vector2(12.0, 13.0), 1.0, 1.2, m_cem_curb)
			_add_box_2d(terrain_root_3d, gp_cem + Vector2(0, 2.5), Vector2(9.2, 10.2), 2.2, 1.4, m_cem_mound)
			var mdl_path: String = stone_models[g_i3d % stone_models.size()]
			_add_model_2d(terrain_root_3d, mdl_path, gp_cem + Vector2(0, -4.5), 1.5, Vector2(7.5, 3.6), 9.6)
			g_i3d += 1

	# Bloque FIS3: Trampillas / rejillas físicas de acceso a las Alcantarillas (-1) en sus posiciones reales de la calle
	var m_sewer_dark := _mat("sewer_dark", Color(0.06, 0.10, 0.08), 0.9, 0.2)
	var m_sewer_brass := _mat("sewer_lock_brass", Color(0.88, 0.72, 0.26), 0.30, 0.85)
	for loc_id in VillageUnderworldScript.SEWER_LOCATIONS.keys():
		var sdef: Dictionary = VillageUnderworldScript.SEWER_LOCATIONS[loc_id]
		var gp: Vector2 = sdef["pos"]
		_add_box_2d(terrain_root_3d, gp, Vector2(18.0, 18.0), 0.0, 1.4, m_curb)
		_add_box_2d(terrain_root_3d, gp, Vector2(14.5, 14.5), 1.4, 1.2, m_iron)
		_add_box_2d(terrain_root_3d, gp, Vector2(11.5, 11.5), 2.0, 0.6, m_sewer_dark)
		for gx in [-3.6, -1.2, 1.2, 3.6]:
			_add_box_2d(terrain_root_3d, gp + Vector2(gx, 0.0), Vector2(0.9, 11.5), 2.1, 1.0, m_iron)
		_add_box_2d(terrain_root_3d, gp, Vector2(11.5, 0.9), 2.1, 1.0, m_iron)
		_add_cyl_2d(terrain_root_3d, gp + Vector2(4.2, 0.0), 1.4, 2.3, 1.4, m_sewer_brass, 1.4, 8)

func _build_tree_3d(parent: Node3D, pos_2d: Vector2, m_trunk: Material, m_leaf1: Material, m_leaf2: Material, scale_f: float = 1.0, variant: int = 0) -> void:
	var tree_files := [
		"nature/CommonTree_1.obj", "nature/CommonTree_2.obj", "nature/BirchTree_1.obj",
		"nature/CommonTree_3.obj", "nature/BirchTree_2.obj", "nature/CommonTree_4.obj",
		"nature/PineTree_1.obj", "nature/BirchTree_3.obj",
	]
	var t_file: String = tree_files[posmod(variant, tree_files.size())]
	if _add_model_2d(parent, t_file, pos_2d, 0.0, Vector2.ZERO, 36.0 * scale_f, float(variant * 67)) != null:
		return
	_add_cyl_2d(parent, pos_2d, 3.2 * scale_f, 0.0, 11.0 * scale_f, m_trunk, 2.4 * scale_f, 8)
	_add_cyl_2d(parent, pos_2d, 12.0 * scale_f, 8.0 * scale_f, 14.0 * scale_f, m_leaf1, 2.0 * scale_f, 9)
	_add_cyl_2d(parent, pos_2d, 9.0 * scale_f, 16.0 * scale_f, 12.0 * scale_f, m_leaf2, 0.8 * scale_f, 9)

func _build_bench_3d(parent: Node3D, pos_2d: Vector2, m_wood: Material, m_iron: Material, rot_y: float = 0.0) -> void:
	if _add_model_2d(parent, "props/Bench.gltf", pos_2d, 0.0, Vector2(18.0, 7.0), 8.5, rot_y) != null:
		return
	_add_box_2d(parent, pos_2d, Vector2(18.0, 6.0), 2.5, 2.0, m_wood)
	_add_box_2d(parent, pos_2d + Vector2(0, -2.5), Vector2(18.0, 1.5), 4.5, 4.5, m_wood)
	_add_box_2d(parent, pos_2d + Vector2(-7, 0), Vector2(2.0, 6.0), 0.0, 3.0, m_iron)
	_add_box_2d(parent, pos_2d + Vector2(7, 0), Vector2(2.0, 6.0), 0.0, 3.0, m_iron)

# ==============================================================================
# 2. EDIFICIOS SÓLIDOS, INTERIORES, PUERTAS, VENTANAS, ALTILLOS (+1) Y CUTAWAY
# ==============================================================================
func _style_for_building(b_id: String) -> Dictionary:
	var wall_col := Color(0.82, 0.76, 0.64)
	var roof_col := Color(0.68, 0.32, 0.22)
	var floor_col := Color(0.56, 0.40, 0.25)
	var trim_col := Color(0.42, 0.28, 0.16)
	var wall_tex := "town_textures/timber_square_clay.png"
	var wall_norm := ""
	var roof_tex := "town_textures/roof_clay_red_center.png"
	var floor_tex := "town_textures/floor_wood_planks.png"
	if b_id in ["building_church", "building_police", "shop_family_smith", "building_tinker", "building_town_hall"]:
		floor_tex = "town_textures/floor_stone_pattern.png"
	elif b_id == "building_hospital":
		floor_tex = "town_textures/floor_tiles_sand_large.png"
	var roof_norm := ""
	var wall_h: float = 28.0
	var roof_h: float = 14.0

	if b_id == "building_tavern":
		wall_tex = "town_textures/wall_timber_structure_cross.png"
		wall_col = Color(0.86, 0.74, 0.56)
		roof_col = Color(0.66, 0.24, 0.20)
		floor_col = Color(0.52, 0.34, 0.20)
		wall_h = 44.0
		roof_h = 20.0
	elif b_id == "building_hospital":
		wall_tex = "town_textures/wall_brick_small_sand.png"
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.90, 0.94, 0.96)
		roof_col = Color(0.28, 0.54, 0.58)
		floor_col = Color(0.80, 0.86, 0.88)
		trim_col = Color(0.48, 0.58, 0.62)
		wall_h = 30.0
	elif b_id == "building_police":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.64, 0.68, 0.74)
		roof_col = Color(0.26, 0.34, 0.48)
		floor_col = Color(0.50, 0.52, 0.56)
		trim_col = Color(0.34, 0.38, 0.46)
		wall_tex = "town_textures/wall_brick_stone_center.png"
		wall_norm = ""
		wall_h = 30.0
	elif b_id == "building_church":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.88, 0.84, 0.78)
		roof_col = Color(0.36, 0.38, 0.44)
		floor_col = Color(0.66, 0.62, 0.58)
		trim_col = Color(0.52, 0.46, 0.42)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 34.0
		roof_h = 18.0
	elif b_id == "building_town_hall":
		wall_col = Color(0.88, 0.82, 0.72)
		roof_col = Color(0.28, 0.42, 0.62)
		floor_col = Color(0.58, 0.42, 0.26)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 32.0
		roof_h = 16.0
	elif b_id == "building_restaurant": # R1: trattoria de estuco/ladrillo claro ocre, teja roja y carpintería verde oscura
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_col = Color(1.0, 0.94, 0.80)
		roof_col = Color(0.64, 0.26, 0.18)
		floor_col = Color(0.74, 0.46, 0.30)
		floor_tex = "town_textures/floor_tiles_tan_large.png"
		trim_col = Color(0.24, 0.40, 0.28)
		wall_h = 32.0
		roof_h = 16.0
	elif b_id == "building_candil":
		wall_col = Color(0.56, 0.38, 0.48)
		roof_col = Color(0.58, 0.22, 0.38)
		floor_col = Color(0.44, 0.24, 0.32)
	elif b_id == "building_manor" or b_id == "building_townhouse":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.84, 0.82, 0.78)
		roof_col = Color(0.26, 0.46, 0.38)
		floor_col = Color(0.56, 0.40, 0.24)
		wall_tex = "town_textures/wall_brick_sand_center.png"
		wall_norm = ""
		wall_h = 32.0
	elif b_id == "building_library":
		wall_tex = "town_textures/timber_square_frame.png"
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.80, 0.70, 0.56)
		roof_col = Color(0.30, 0.44, 0.64)
	elif b_id == "building_school":
		wall_col = Color(0.86, 0.78, 0.62)
		roof_col = Color(0.68, 0.36, 0.24)
	elif b_id == "shop_family_smith" or b_id == "building_tinker":
		roof_tex = "town_textures/roof_clay_grey_center.png"
		wall_col = Color(0.60, 0.58, 0.56)
		roof_col = Color(0.36, 0.34, 0.34)
		floor_col = Color(0.46, 0.44, 0.42)
		wall_tex = "town_textures/wall_stone.png"
		wall_norm = ""
	elif b_id.begins_with("shop_") or b_id.begins_with("mixed_"):
		if (b_id.hash() % 2) == 0:
			wall_tex = "town_textures/wall_timber_structure_cross.png"
		if (b_id.hash() % 3) == 0:
			roof_tex = "town_textures/roof_thatch_center.png"
		wall_col = Color(0.84, 0.74, 0.56)
		roof_col = Color(0.68, 0.34, 0.22)
	elif b_id.begins_with("player_house_"):
		wall_tex = "town_textures/timber_square_planks.png"
		roof_tex = "town_textures/roof_thatch_center.png"
		wall_col = Color(0.86, 0.76, 0.58)
		roof_col = Color(0.28, 0.52, 0.36)

	var wall_emit_col := Color.BLACK
	var wall_emit_e: float = 0.0
	var w_mat := _mat("wall_" + b_id, wall_col, 0.88, 0.04, wall_emit_col, wall_emit_e, wall_tex, wall_norm, 0.70)
	if b_id == "building_restaurant":
		w_mat.albedo_color = Color(0.76, 0.66, 0.52)
		w_mat.uv1_scale = Vector3(2.4, 0.72, 2.4)
	return {
		"wall_mat": w_mat,
		"roof_mat": _mat("roof_" + b_id, roof_col, 0.80, 0.06, Color.BLACK, 0.0, roof_tex, roof_norm, 0.75),
		"floor_mat": _mat("floor_" + b_id, floor_col, 0.88, 0.02, Color.BLACK, 0.0, floor_tex, "", 0.85),
		"trim_mat": _mat("trim_" + b_id, trim_col, 0.84, 0.05, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.85),
		"wall_h": wall_h,
		"roof_h": roof_h,
	}

func rebuild_buildings_3d() -> void:
	_clear_children(buildings_root_3d)
	_building_records_3d.clear()
	_building_furniture_rects.clear()
	_current_building_id = ""
	_current_building_floor = 0
	_door_nodes_3d.clear()
	_window_nodes_3d.clear()
	_chest_nodes_3d.clear()
	_morgue_body_nodes_3d.clear()
	_restaurant_night_nodes.clear()
	_jail_gate_pivot_3d = null
	if vm == null:
		return

	var m_wood := _mat("prop_wood", Color(0.45, 0.29, 0.16), 0.85, 0.02)
	var m_dark_wood := _mat("prop_dark_wood", Color(0.32, 0.20, 0.11), 0.88, 0.02)
	var m_iron := _mat("wrought_iron", Color(0.22, 0.24, 0.28), 0.45, 0.75)
	var m_gold := _mat("brass_gold", Color(0.85, 0.68, 0.24), 0.35, 0.82)
	var m_glass := _mat("win_glass", Color(0.56, 0.82, 0.96, 0.75), 0.15, 0.25)
	var m_plinth := _mat("building_plinth_stone", Color(0.58, 0.56, 0.52), 0.90, 0.03, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)

	for b in vm.building_footprints:
		var b_id: String = str(b.get("id", ""))
		var rect: Rect2 = b["rect"]
		var center: Vector2 = rect.get_center()
		var sz: Vector2 = rect.size
		var half: Vector2 = sz * 0.5
		var door_pos: Vector2 = b["door_pos"]
		var door_south: bool = bool(b["door_south"])
		var style: Dictionary = _style_for_building(b_id)
		# Altura de muro algo mayor y distinta en cada edificio (+0..10 px), salvo la taberna de 2 plantas (44 px exactos: 22 px por planta).
		var wall_h: float = float(style["wall_h"]) if b_id == "building_tavern" else (float(style["wall_h"]) + 4.0 + float(absi(b_id.hash()) % 6) * 2.0)
		var roof_h: float = float(style["roof_h"])
		var m_wall: Material = style["wall_mat"]
		var m_roof: Material = style["roof_mat"]
		var m_floor: Material = style["floor_mat"]
		var m_trim: Material = style["trim_mat"]

		var b_root := Node3D.new()
		b_root.name = "B3D_" + b_id
		buildings_root_3d.add_child(b_root)

		# 1. Zócalo de piedra enterrado (cimentación contra posibles microdesniveles) + losa de suelo 3D y zócalo exterior
		_add_box_2d(b_root, center, sz + Vector2(6, 6), -2.5, 2.5, m_plinth)
		_add_box_2d(b_root, center, sz + Vector2(4, 4), 0.0, 1.5, m_trim)
		_add_box_2d(b_root, center, sz - Vector2(2, 2), 1.5, 1.0, m_floor)

		# 2. Muros perimetrales 3D con hueco de puerta y dintel superior
		var wall_t: float = 6.5
		var door_w: float = 40.0
		for d_entry in vm.building_doors:
			if str(d_entry.get("building_id", "")) == b_id:
				door_w = float(d_entry.get("width", 40.0))
				break

		# Muro izquierdo y derecho + pilares de esquina
		_add_box_2d(b_root, Vector2(rect.position.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
		_add_box_2d(b_root, Vector2(rect.end.x, center.y), Vector2(wall_t, sz.y), 2.0, wall_h, m_wall)
		for c_pt in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			_add_box_2d(b_root, c_pt, Vector2(wall_t + 2.0, wall_t + 2.0), 2.0, wall_h + 1.0, m_trim)

		# Muro cerrado (opuesto a la puerta): si es el muro sur (más cercano a la cámara), se rebaja al abrir el tejado (Cutaway)
		var closed_y: float = (center.y - half.y) if door_south else (center.y + half.y)
		if door_south:
			_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 2.0, wall_h, m_wall)
		else:
			_add_box_2d(b_root, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 2.0, 9.0, m_wall)

		# Muro de la fachada con hueco de puerta + dintel sobre la puerta
		var door_y: float = door_pos.y
		var door_left_x: float = door_pos.x - door_w * 0.5
		var door_right_x: float = door_pos.x + door_w * 0.5
		var left_w: float = maxf(6.0, door_left_x - rect.position.x)
		var right_w: float = maxf(6.0, rect.end.x - door_right_x)
		_add_box_2d(b_root, Vector2(rect.position.x + left_w * 0.5, door_y), Vector2(left_w, wall_t), 2.0, wall_h, m_wall)
		_add_box_2d(b_root, Vector2(rect.end.x - right_w * 0.5, door_y), Vector2(right_w, wall_t), 2.0, wall_h, m_wall)
		# Jambas y dintel de la puerta
		_add_box_2d(b_root, Vector2(door_left_x, door_y), Vector2(3.5, wall_t + 2.0), 2.0, wall_h, m_trim)
		_add_box_2d(b_root, Vector2(door_right_x, door_y), Vector2(3.5, wall_t + 2.0), 2.0, wall_h, m_trim)
		var lintel_mat: Material = m_wall if b_id == "building_restaurant" else m_trim
		if b_id == "building_tavern":
			_add_box_2d(b_root, Vector2(door_pos.x, door_y), Vector2(door_w + 4.0, wall_t + 1.5), 19.0, 3.0, m_trim)
			_add_box_2d(b_root, Vector2(door_pos.x, door_y), Vector2(door_w + 2.0, wall_t), 22.0, wall_h - 20.0, m_wall)
			# Cinta de vigas de entreplanta exterior (h = 22.0) y ventanas del piso superior en la fachada de 2 plantas
			_add_box_2d(b_root, Vector2(center.x, rect.position.y), Vector2(sz.x + 2.5, wall_t + 1.8), 21.2, 2.2, m_trim)
			_add_box_2d(b_root, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.5, wall_t + 1.8), 21.2, 2.2, m_trim)
			_add_box_2d(b_root, Vector2(rect.position.x, center.y), Vector2(wall_t + 1.8, sz.y + 2.5), 21.2, 2.2, m_trim)
			_add_box_2d(b_root, Vector2(rect.end.x, center.y), Vector2(wall_t + 1.8, sz.y + 2.5), 21.2, 2.2, m_trim)
		else:
			_add_box_2d(b_root, Vector2(door_pos.x, door_y), Vector2(door_w + 4.0, wall_t + 1.5), 2.0 + wall_h * 0.72, wall_h * 0.28, lintel_mat)

		# 3. Puerta abatible 3D sincronizada con `vm.building_doors`
		for d_entry in vm.building_doors:
			if str(d_entry.get("building_id", "")) == b_id:
				var hinge_pos := Vector2(door_left_x + 2.0, door_y)
				var pivot := Node3D.new()
				pivot.name = "DoorPivot_" + b_id
				pivot.position = to_3d(hinge_pos, 2.0)
				b_root.add_child(pivot)
				var leaf_w: float = maxf(18.0, door_w - 4.0)
				var leaf_h: float = 17.0 if b_id == "building_tavern" else (wall_h * 0.70)
				if not _is_headless:
					var door_leaf := _make_texture_panel(leaf_w, leaf_h, 3.0, _panel_mat("door_wood", "town_textures/door_wood.png", false))
					door_leaf.position = Vector3((leaf_w * 0.5) * WORLD_SCALE, (leaf_h * 0.5 * WORLD_SCALE) / _cos_p, 0.0)
					pivot.add_child(door_leaf)
				var lock_badge := MeshInstance3D.new()
				var lb_bm := BoxMesh.new()
				lb_bm.size = size_3d(Vector2(3.5, 4.2), 3.5)
				lock_badge.mesh = lb_bm
				lock_badge.material_override = m_gold
				lock_badge.position = Vector3((leaf_w - 4.0) * WORLD_SCALE, (leaf_h * 0.48 * WORLD_SCALE) / _cos_p, 0.0)
				pivot.add_child(lock_badge)
				_door_nodes_3d.append({"entry": d_entry, "pivot": pivot, "lock_badge": lock_badge, "door_south": door_south})
				break

		# 4. Ventana 3D con postigos sincronizada con `vm.building_windows`
		for w_entry in vm.building_windows:
			if str(w_entry.get("building_id", "")) == b_id:
				var w_pos: Vector2 = w_entry.get("pos", Vector2.ZERO)
				var pane: Node3D = null
				if not _is_headless:
					pane = _make_texture_panel(13.0, 12.0, wall_t + 2.4, _panel_mat("win_day", "town_textures/window_square_divided.png", false))
					pane.position = to_3d(w_pos, 10.0 + 6.0)
					b_root.add_child(pane)
				else:
					pane = _add_box_2d(b_root, w_pos, Vector2(11.0, wall_t + 2.4), 12.0, 8.0, m_glass)
				var shutter := _add_box_2d(b_root, w_pos, Vector2(12.0, wall_t + 2.8), 12.0, 8.2, m_dark_wood)
				_window_nodes_3d.append({"entry": w_entry, "pane": pane, "shutter": shutter})
				break

		# §3b.3: Barrotes de hierro y planchas remachadas en ventanas bajas de comisaría y ayuntamiento
		if b_id in ["building_police", "building_town_hall"]:
			var m_rivet := _mat("epoch_rivet_steel", Color(0.18, 0.20, 0.23), 0.52, 0.82)
			for side_s in [-1.0, 1.0]:
				var wx_low: float = center.x + side_s * (half.x * 0.58)
				var wy_low: float = door_y
				# Plancha superior e inferior remachada + 4 barrotes verticales en fachada
				_add_box_2d(b_root, Vector2(wx_low, wy_low), Vector2(16.0, wall_t + 2.8), 8.5, 2.2, m_rivet)
				_add_box_2d(b_root, Vector2(wx_low, wy_low), Vector2(16.0, wall_t + 2.8), 18.2, 2.2, m_rivet)
				_add_box_2d(b_root, Vector2(wx_low, wy_low), Vector2(14.5, wall_t + 1.8), 10.5, 8.0, _mat("epoch_dark_win", Color(0.08, 0.10, 0.12), 0.7, 0.2))
				for bx_i in [-5.4, -1.8, 1.8, 5.4]:
					_add_cyl_2d(b_root, Vector2(wx_low + bx_i, wy_low), 0.55, 8.5, 11.8, m_iron, 0.55, 6)
				# Ventana baja blindada con plancha remachada en muros laterales
				var sx_wall: float = rect.position.x if side_s < 0.0 else rect.end.x
				_add_box_2d(b_root, Vector2(sx_wall, center.y), Vector2(wall_t + 2.6, 16.0), 9.0, 10.0, m_rivet)
				for ry_i in [-5.5, 0.0, 5.5]:
					_add_cyl_2d(b_root, Vector2(sx_wall, center.y + ry_i), 0.55, 8.5, 11.0, m_iron, 0.55, 6)

		# 5. Mobiliario interior 3D específico de cada edificio
		_current_building_id = b_id
		_current_building_floor = 0
		_populate_building_interior_3d(b_root, b_id, rect, door_south, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)

		# 6. Altillo / Primer Piso (+1) 3D (visible cuando estás en nivel +1 o cerca)
		var loft_root := Node3D.new()
		loft_root.name = "Loft3D_" + b_id
		loft_root.visible = false
		b_root.add_child(loft_root)
		_current_building_floor = 1
		if b_id == "building_tavern":
			_build_tavern_floor_1_3d(loft_root, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		else:
			var loft_y: float = center.y + (-half.y * 0.42 if door_south else half.y * 0.42)
			_add_box_2d(loft_root, Vector2(center.x, loft_y), Vector2(sz.x - 10.0, sz.y * 0.42), wall_h - 3.0, 2.0, m_wood)
			_add_box_2d(loft_root, Vector2(center.x, loft_y + (sz.y * 0.20 if door_south else -sz.y * 0.20)), Vector2(sz.x - 12.0, 2.5), wall_h - 1.0, 6.0, m_dark_wood)
			_add_model_2d(loft_root, "props/Chest_Wood.gltf", Vector2(center.x - sz.x * 0.22, loft_y), wall_h - 1.0, Vector2(12.0, 8.0), 6.5)
		_current_building_id = ""
		_current_building_floor = 0

		# 7. Tejado a dos aguas con alero (se retira en modo Cutaway). Cada edificio varía según su id:
		#    orientación de la cumbrera, altura, ala más baja en los edificios anchos, porche sobre la puerta y chimenea.
		var roof_cap := Node3D.new()
		roof_cap.name = "RoofCap_" + b_id
		b_root.add_child(roof_cap)
		# B7: Forjado/techo de tablas bajo la cubierta para que en 1.ª persona se vea el techo cerrado desde dentro
		_add_box_2d(roof_cap, center, sz - Vector2(2.0, 2.0), wall_h, 1.8, m_wood)
		var hv: int = absi(b_id.hash())
		var ov: float = 6.0
		var short_side: float = minf(sz.x, sz.y)
		var rh: float = clampf(short_side * (0.40 + float(hv % 5) * 0.04), 16.0, 46.0)
		var ridge_x: bool = sz.x >= sz.y
		if absf(sz.x - sz.y) < 12.0:
			ridge_x = (hv % 2) == 0
		var roof_base_h: float = wall_h + 2.0
		if sz.x > 118.0 and not (b_id in ["building_church"]):
			# Cuerpo principal + ala más baja (rompe la caja: silueta en L vista desde arriba)
			var main_w: float = sz.x * 0.60
			var wing_w: float = sz.x - main_w
			var main_left: bool = (hv % 2) == 0
			var main_cx: float = rect.position.x + (main_w * 0.5 if main_left else wing_w + main_w * 0.5)
			var wing_cx: float = rect.position.x + (main_w + wing_w * 0.5 if main_left else wing_w * 0.5)
			_add_prism_2d(roof_cap, Vector2(main_cx, center.y), Vector2(main_w + ov * 2.0, sz.y + ov * 2.0), roof_base_h, rh, m_roof, false)
			_add_prism_2d(roof_cap, Vector2(wing_cx, center.y), Vector2(wing_w + ov, sz.y * 0.86 + ov), roof_base_h - 2.0, rh * 0.62, m_roof, true)
		else:
			_add_prism_2d(roof_cap, center, sz + Vector2(ov * 2.0, ov * 2.0), roof_base_h, rh, m_roof, ridge_x)
		# Remate de madera bajo el alero (se ve con el tejado puesto y quitado)
		if not door_south:
			_add_box_2d(roof_cap, Vector2(center.x, closed_y), Vector2(sz.x, wall_t), 11.0, wall_h - 9.0, m_wall)
			_add_box_2d(roof_cap, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		else:
			_add_box_2d(b_root, Vector2(center.x, rect.end.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		_add_box_2d(b_root, Vector2(center.x, rect.position.y), Vector2(sz.x + 2.0, 3.0), wall_h, 2.5, m_trim)
		# Porche sobre la puerta en tiendas y casas (tejadillo inclinado sobre dos postes)
		if (hv % 3) != 0 and not (b_id in ["building_church", "building_police", "building_hospital"]):
			var porch_dir: float = 1.0 if door_south else -1.0
			var porch_c := Vector2(door_pos.x, door_y + porch_dir * 9.0)
			_add_box_2d(b_root, porch_c, Vector2(door_w + 16.0, 18.0), wall_h * 0.70, 2.5, m_roof)
			for px in [-1.0, 1.0]:
				_add_box_2d(b_root, Vector2(door_pos.x + px * (door_w * 0.5 + 6.0), door_y + porch_dir * 16.0), Vector2(2.5, 2.5), 2.0, wall_h * 0.70 - 2.0, m_trim)
		# Chimenea sobre la cumbrera
		var ch_off := Vector2(half.x * (0.30 if (hv % 2) == 0 else -0.30), -half.y * 0.15)
		_add_model_2d(roof_cap, "fantasy_town/chimney.glb", center + ch_off, roof_base_h + rh * 0.35, Vector2(9.0, 9.0), rh * 0.9)
		# Campanario de la iglesia: torre de piedra con chapitel junto a la fachada
		if b_id == "building_church":
			var tower_c := Vector2(center.x, (rect.end.y - 16.0) if door_south else (rect.position.y + 16.0))
			_add_box_2d(roof_cap, tower_c, Vector2(26.0, 22.0), roof_base_h, rh + 22.0, m_wall)
			_add_pyramid_2d(roof_cap, tower_c, Vector2(32.0, 28.0), roof_base_h + rh + 22.0, 34.0, m_roof)

		_building_records_3d.append({
			"id": b_id,
			"rect": rect,
			"root": b_root,
			"roof_cap": roof_cap,
			"loft_root": loft_root,
		})

	_merge_building_meshes()

	# Cofres domésticos 3D sincronizados con `vm.house_chests`
	for ch in vm.house_chests:
		var c_pos: Vector2 = ch.get("pos", Vector2.ZERO)
		var fam_id: String = str(ch.get("family_id", ""))
		var is_tavern_upper: bool = (fam_id == VillageTavern.FAMILY_ID)
		var base_h: float = VillageTavern.FLOOR_1_H if is_tavern_upper else 2.0
		var parent_node: Node3D = buildings_root_3d
		_current_building_id = ""
		_current_building_floor = 1 if is_tavern_upper else 0
		for rec in _building_records_3d:
			var r_rect: Rect2 = rec["rect"]
			if r_rect.grow(8.0).has_point(c_pos):
				_current_building_id = str(rec["id"])
				if is_tavern_upper and is_instance_valid(rec.get("loft_root")):
					parent_node = rec["loft_root"]
				break
		var ch_root := Node3D.new()
		parent_node.add_child(ch_root)
		_add_model_2d(ch_root, "props/Chest_Wood.gltf", c_pos, base_h, Vector2(12.0, 8.5), 7.5)
		var lid := _add_box_2d(ch_root, c_pos, Vector2(11.4, 7.8), base_h + 5.5, 1.8, m_gold)
		_chest_nodes_3d.append({"entry": ch, "lid": lid})
	_current_building_id = ""
	_current_building_floor = 0
	check_furniture_overlaps(true)

## Rendimiento: junta en una sola malla por material las piezas quietas de cada edificio (muros, suelos, muebles).
## Quedan aparte y se siguen moviendo: puertas, ventanas y postigos, cuerpos de la morgue, reja del calabozo, el tejado
## (que se abre) y el altillo (que aparece), estos dos juntados cada uno por su lado.
func _merge_building_meshes() -> void:
	if _is_headless:
		return
	var excl: Dictionary = {}
	for d in _door_nodes_3d:
		for k in ["pivot", "lock_badge"]:
			if d.get(k) is Node:
				excl[d[k]] = true
	for w in _window_nodes_3d:
		for k in ["pane", "shutter"]:
			if w.get(k) is Node:
				excl[w[k]] = true
	for mb in _morgue_body_nodes_3d:
		excl[mb] = true
	for rn in _restaurant_night_nodes: # R1: bombillas de la terraza (se encienden y apagan)
		excl[rn] = true
	if _jail_gate_pivot_3d != null:
		excl[_jail_gate_pivot_3d] = true
	for rec in _building_records_3d:
		var sub: Array = [rec["roof_cap"], rec["loft_root"]]
		var ex_b: Dictionary = excl.duplicate()
		for sn in sub:
			ex_b[sn] = true
		_merge_meshes_under(rec["root"], ex_b)
		for sn in sub:
			_merge_meshes_under(sn, excl)

func _merge_meshes_under(root: Node3D, excl: Dictionary) -> void:
	var found: Array = []
	_collect_merge_meshes(root, root, excl, found)
	if found.size() < 2:
		return
	var inv: Transform3D = root.global_transform.affine_inverse()
	var tools: Dictionary = {} # clave -> {"st": SurfaceTool, "mat": Material, "shadow": int}
	for mi in found:
		var xf: Transform3D = inv * mi.global_transform
		for si in range(mi.mesh.get_surface_count()):
			var mat: Material = mi.material_override
			if mat == null:
				mat = mi.get_surface_override_material(si)
			if mat == null:
				mat = mi.mesh.surface_get_material(si)
			var fmt: int = 0
			var arrs: Array = mi.mesh.surface_get_arrays(si)
			for ai in range(arrs.size()):
				if arrs[ai] != null:
					fmt |= 1 << ai
			var key := "%d_%d_%d" % [mat.get_instance_id() if mat != null else 0, fmt, int(mi.cast_shadow)]
			if not tools.has(key):
				tools[key] = {"st": SurfaceTool.new(), "mat": mat, "shadow": int(mi.cast_shadow)}
			(tools[key]["st"] as SurfaceTool).append_from(mi.mesh, si, xf)
		mi.mesh = null # el nodo se queda (por si tiene hijos), pero ya no se dibuja
	var by_shadow: Dictionary = {}
	for key in tools:
		var t: Dictionary = tools[key]
		var am: ArrayMesh = by_shadow.get(t["shadow"], null)
		if am == null:
			am = ArrayMesh.new()
			by_shadow[t["shadow"]] = am
		(t["st"] as SurfaceTool).commit(am)
		am.surface_set_material(am.get_surface_count() - 1, t["mat"])
	for sh in by_shadow:
		var out := MeshInstance3D.new()
		out.name = "Juntado"
		out.mesh = by_shadow[sh]
		out.cast_shadow = sh
		root.add_child(out)

func _collect_merge_meshes(n: Node, root: Node, excl: Dictionary, out: Array) -> void:
	for c in n.get_children():
		if excl.has(c):
			continue
		if c is Node3D and not (c as Node3D).visible:
			continue
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var ok: bool = mi.mesh != null and mi.skin == null and not (mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).get_blend_shape_count() > 0)
			if ok:
				for si in range(mi.mesh.get_surface_count()):
					if mi.mesh is ArrayMesh and (mi.mesh as ArrayMesh).surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
						ok = false
			if ok:
				out.append(mi)
		_collect_merge_meshes(c, root, excl, out)

func _populate_building_interior_3d(b_root: Node3D, b_id: String, rect: Rect2, door_south: bool, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var c: Vector2 = rect.get_center()
	var m_bed := _mat("bed_linen", Color(0.84, 0.28, 0.24), 0.85, 0.0)
	var m_pillow := _mat("bed_pillow", Color(0.94, 0.92, 0.86), 0.85, 0.0)
	var m_steel := _mat("morgue_steel", Color(0.74, 0.80, 0.84), 0.30, 0.78)
	var m_shroud := _mat("corpse_shroud", Color(0.82, 0.84, 0.78), 0.90, 0.0)
	var m_felt := _mat("green_felt", Color(0.16, 0.48, 0.26), 0.85, 0.0)
	var m_ember := _mat("forge_ember", Color(1.0, 0.42, 0.12), 0.4, 0.0, Color(1.0, 0.38, 0.08), 2.2)

	match b_id:
		"building_restaurant":
			_build_restaurant_3d(b_root, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_tavern":
			_build_tavern_floor_0_3d(b_root, wall_h, m_wall, m_trim, m_wood, m_dark_wood, m_iron, m_gold)
		"building_hospital":
			# Tabique entre Urgencias y Morgue Forense
			_add_box_2d(b_root, Vector2(704, 152), Vector2(56, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, Vector2(786, 152), Vector2(56, 5.5), 2.0, wall_h * 0.85, m_wall)
			_build_bed_3d(b_root, vm._hospital_bed_pos, m_steel, _mat("hosp_sheet", Color(0.32, 0.72, 0.78), 0.8, 0.0), m_pillow)
			_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", vm._hospital_bed_pos + Vector2(-18, -10), 2.0, Vector2(12.0, 6.0), 13.0)
			# 3 Camillas de acero inoxidable de la Morgue + cuerpos cubiertos
			for mp in vm._morgue_table_positions:
				_register_furniture_rect("MorgueTable", mp, Vector2(14.0, 22.0))
				_add_box_2d(b_root, mp, Vector2(14.0, 22.0), 2.0, 7.5, m_steel)
				var body_n := Node3D.new()
				body_n.visible = false
				b_root.add_child(body_n)
				_add_box_2d(body_n, mp, Vector2(9.0, 17.0), 9.5, 4.2, m_shroud)
				_add_box_2d(body_n, mp + Vector2(0, -6.0), Vector2(5.5, 5.5), 13.5, 3.0, m_shroud)
				_morgue_body_nodes_3d.append(body_n)
		"building_police":
			# Tabique de barrotes de acero del calabozo y puerta de reja en Vector2(902, 152)
			_add_model_2d(b_root, "graveyard/iron-fence.glb", Vector2(874, 152), 2.0, Vector2(36, 4.5), wall_h * 0.85)
			_add_model_2d(b_root, "graveyard/iron-fence.glb", Vector2(940, 152), 2.0, Vector2(52, 4.5), wall_h * 0.85)
			_jail_gate_pivot_3d = Node3D.new()
			_jail_gate_pivot_3d.position = to_3d(Vector2(892, 152), 2.0)
			b_root.add_child(_jail_gate_pivot_3d)
			var gate_mesh := MeshInstance3D.new()
			var gm_box := BoxMesh.new()
			gm_box.size = size_3d(Vector2(20.0, 3.0), wall_h * 0.75)
			gate_mesh.mesh = gm_box
			gate_mesh.material_override = m_iron
			gate_mesh.position = Vector3(10.0 * WORLD_SCALE, (wall_h * 0.375 * WORLD_SCALE) / _cos_p, 0.0)
			_jail_gate_pivot_3d.add_child(gate_mesh)
			# Camastro del calabozo, jaula y escritorio del comisario
			_build_bed_3d(b_root, vm._jail_cell_pos + Vector2(-14, 8), m_iron, m_dark_wood, m_pillow)
			_add_model_2d(b_root, "props/Cage_Small.gltf", vm._jail_cell_pos + Vector2(16, 6), 2.0, Vector2(9.0, 9.0), 10.0)
			_add_model_2d(b_root, "props/Workbench.gltf", vm._police_center + Vector2(18, -18), 2.0, Vector2(22, 12), 8.5)
			_add_model_2d(b_root, "props/WeaponStand.gltf", vm._police_center + Vector2(-24, -18), 2.0, Vector2(14, 7), 11.0)
			# §3b.3: Terminal de pantalla verde sobre el escritorio de la Comisaría
			_add_green_crt_terminal_3d(b_root, VillageCulture.POLICE_TERMINAL_POS, 10.5, true)
		"building_church":
			# Altar mayor con velas y bancos de madera 3D
			_add_model_2d(b_root, "graveyard/altar-stone.glb", vm._church_altar_pos, 2.0, Vector2(32.0, 14.0), 11.0)
			_add_model_2d(b_root, "props/CandleStick_Triple.gltf", vm._church_altar_pos + Vector2(-10, 0), 12.0, Vector2(5.0, 5.0), 6.0)
			_add_model_2d(b_root, "props/CandleStick_Triple.gltf", vm._church_altar_pos + Vector2(10, 0), 12.0, Vector2(5.0, 5.0), 6.0)
			for py in [-12.0, 4.0]:
				for px in [-26.0, 26.0]:
					_add_model_2d(b_root, "props/Bench.gltf", c + Vector2(px, py), 2.0, Vector2(26.0, 7.0), 6.5)
		"building_library":
			var m_dir: float = -1.0 if door_south else 1.0
			for sx in [-40.0, -14.0, 14.0, 40.0]:
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(sx, 34.0 * m_dir), 2.0, Vector2(22.0, 8.0), 22.0)
			_add_model_2d(b_root, "props/Table_Large.gltf", VillageCulture.reading_spot(), 2.0, Vector2(22.0, 13.0), 7.5)
			_add_model_2d(b_root, "props/BookStand.gltf", VillageCulture.reading_spot() + Vector2(-19, -8), 2.0, Vector2(8.0, 8.0), 11.0)
		"building_school":
			var m_dir2: float = -1.0 if door_south else 1.0
			for p in [Vector2(-30, 6), Vector2(0, 6), Vector2(30, 6), Vector2(-30, 26), Vector2(0, 26), Vector2(30, 26)]:
				_add_model_2d(b_root, "props/Bench.gltf", c + Vector2(p.x, p.y * m_dir2), 2.0, Vector2(16.0, 9.0), 6.5)
			_add_box_2d(b_root, c + Vector2(0, -26.0 * m_dir2), Vector2(54.0, 4.0), 8.0, 14.0, _mat("chalkboard", Color(0.14, 0.28, 0.18), 0.9, 0.0))
		"shop_family_smith":
			# Fragua encendida, yunque real sobre tronco, piedra de afilar, soporte de armas y mostrador
			_register_furniture_rect("Forge", c + Vector2(-38, -16), Vector2(20.0, 16.0))
			_add_box_2d(b_root, c + Vector2(-38, -16), Vector2(20.0, 16.0), 2.0, 18.0, m_trim)
			_add_box_2d(b_root, c + Vector2(-38, -14), Vector2(12.0, 10.0), 5.0, 6.0, m_ember)
			_add_model_2d(b_root, "props/Anvil_Log.gltf", c + Vector2(-18, 8), 2.0, Vector2(11.0, 9.0), 9.0)
			_add_model_2d(b_root, "props/Whetstone.gltf", c + Vector2(24, -14), 2.0, Vector2(9.0, 7.5), 9.5)
			_add_model_2d(b_root, "props/WeaponStand.gltf", c + Vector2(34, 12), 2.0, Vector2(16.0, 8.0), 12.0)
			_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(2, -16), 2.0, Vector2(24.0, 10.5), 8.5)
		"mixed_family_herbalist":
			_add_box_2d(b_root, c + Vector2(-42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, c + Vector2(42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, -10), 2.0, Vector2(24.0, 10.5), 8.5)
			_add_model_2d(b_root, "props/Cauldron.gltf", c + Vector2(-24, -14), 2.0, Vector2(11.0, 11.0), 9.0)
			_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", c + Vector2(24, -16), 2.0, Vector2(14.0, 6.0), 13.0)
			_build_bed_3d(b_root, c + Vector2(-36, 26), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(36, 26), m_wood, m_bed, m_pillow)
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24), 2.0, Vector2(18.0, 12.0), 7.0)
		"mixed_family_tinker":
			# Tabiques internos, banco de trabajo, camas traseras y mesa
			_add_box_2d(b_root, c + Vector2(-42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_box_2d(b_root, c + Vector2(42, 4), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
			_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, -10), 2.0, Vector2(24.0, 10.5), 8.5)
			_add_model_2d(b_root, "props/Anvil.gltf", c + Vector2(22, -16), 2.0, Vector2(9.0, 7.0), 7.5)
			_build_bed_3d(b_root, c + Vector2(-36, 26), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(36, 26), m_wood, m_bed, m_pillow)
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24), 2.0, Vector2(18.0, 12.0), 7.0)
			# Bloque FIS2 (§2.1): Terminal Lógica Electromecánica física sobre una mesa dentro del taller (TINKER_TERMINAL_POS)
			var t_pos: Vector2 = VillageCulture.TINKER_TERMINAL_POS
			var m_copper := _mat("tinker_copper", Color(0.84, 0.48, 0.22), 0.35, 0.78)
			var m_screen := _mat("tinker_screen", Color(0.14, 0.96, 0.34), 0.2, 0.0, Color(0.10, 0.92, 0.28), 3.1)
			var m_card := _mat("tinker_card", Color(0.92, 0.86, 0.70), 0.85, 0.0)
			if _add_model_2d(b_root, "props/Table_Large.gltf", t_pos, 2.0, Vector2(22.0, 14.0), 8.0) == null:
				_add_box_2d(b_root, t_pos, Vector2(22.0, 14.0), 2.0, 8.0, m_dark_wood)
			_add_box_2d(b_root, t_pos + Vector2(0, -1.0), Vector2(18.0, 10.5), 10.0, 12.5, m_iron) # Chasis de acero alto
			_add_box_2d(b_root, t_pos + Vector2(0, -1.0), Vector2(16.0, 8.8), 11.2, 11.8, m_gold) # Bastidor de latón
			_add_box_2d(b_root, t_pos + Vector2(-1.6, 3.8), Vector2(10.5, 2.6), 12.5, 8.2, m_screen) # Visor fosforescente verde hacia cámara
			_add_box_2d(b_root, t_pos + Vector2(0, 4.6), Vector2(13.0, 3.8), 10.0, 2.4, m_iron) # Teclado mecánico frontal
			_add_cyl_2d(b_root, t_pos + Vector2(4.8, -1.2), 2.8, 22.8, 6.0, m_card, 2.8, 10) # Tambor de tarjetas perforadas
			_add_cyl_2d(b_root, t_pos + Vector2(-4.8, -1.6), 2.2, 22.8, 5.5, m_copper, 2.2, 8) # Bobina de relés
			if not _is_headless:
				var term_lt := OmniLight3D.new()
				term_lt.position = to_3d(t_pos + Vector2(0, 2.0), 18.0)
				term_lt.light_color = Color(0.16, 0.96, 0.36)
				term_lt.light_energy = 1.05
				term_lt.omni_range = 2.0
				b_root.add_child(term_lt)
			# Bloque FIS2 (§2.2): Cuadro Eléctrico físico en la pared exterior norte del taller (TINKER_GRID_PANEL_POS)
			var gp_pos: Vector2 = VillageCulture.TINKER_GRID_PANEL_POS
			_add_cyl_2d(b_root, gp_pos + Vector2(5.5, 0.0), 1.2, 2.0, 34.0, m_iron, 1.2, 8) # Tubo de acometida vertical
			_add_box_2d(b_root, gp_pos + Vector2(0, 1.5), Vector2(16.0, 7.0), 22.0, 16.0, m_iron) # Armario metálico en el muro norte
			_add_box_2d(b_root, gp_pos + Vector2(0, 3.0), Vector2(13.6, 5.5), 23.5, 13.0, m_dark_wood) # Placa aislante
			_add_cyl_2d(b_root, gp_pos + Vector2(-4.4, 5.2), 2.2, 25.0, 11.5, m_copper, 2.2, 8) # Bobina izq
			_add_cyl_2d(b_root, gp_pos + Vector2(4.4, 5.2), 2.2, 25.0, 11.5, m_copper, 2.2, 8) # Bobina der
			for sx in [-2.6, 0.0, 2.6]:
				_add_box_2d(b_root, gp_pos + Vector2(sx, 6.2), Vector2(1.5, 3.5), 27.0, 6.5, m_gold) # 3 palancas seccionadoras
			if is_instance_valid(_grid_panel_bulb_3d):
				_grid_panel_bulb_3d.queue_free()
			_grid_panel_bulb_3d = _add_cyl_2d(buildings_root_3d, gp_pos + Vector2(0, 4.5), 2.6, 38.0, 4.5, m_screen, 2.0, 8)
		"building_mansion", "building_manor":
			# Mansión señorial (f1) o Casa solariega (f2): estudio con escritorio, salón y alcoba
			var nob_lot: String = "f1" if b_id == "building_mansion" else "f2"
			var study_p: Vector2 = load("res://scripts/systems/VillageNobility.gd").study_pos(nob_lot)
			if _add_model_2d(b_root, "props/Workbench.gltf", study_p, 2.0, Vector2(22.0, 11.0), 8.2) == null:
				_add_box_2d(b_root, study_p, Vector2(22.0, 11.0), 2.0, 8.2, m_dark_wood)
			_add_model_2d(b_root, "props/Chair_1.gltf", study_p + Vector2(0, -11.5), 2.0, Vector2(6.0, 6.0), 8.5)
			_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, -8), 2.0, Vector2(26.0, 13.0), 7.5)
			_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(-36, -38), 2.0, Vector2(20.0, 9.0), 16.0)
			_build_bed_3d(b_root, c + Vector2(56, -24), m_wood, m_bed, m_pillow)
			_build_bed_3d(b_root, c + Vector2(56, 22), m_wood, m_bed, m_pillow)
		"building_town_hall":
			# Ayuntamiento (n4): mesa municipal en (764, -444), urna, estanterías y terminal de pantalla verde
			var desk_p: Vector2 = c + Vector2(0, -24)
			if _add_model_2d(b_root, "props/Table_Large.gltf", desk_p, 2.0, Vector2(26.0, 13.0), 8.2) == null:
				_add_box_2d(b_root, desk_p, Vector2(26.0, 13.0), 2.0, 8.2, m_dark_wood)
			_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-42, 6), 2.0, Vector2(16.0, 10.0), 12.0)
			_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(36, 6), 2.0, Vector2(18.0, 9.0), 15.0)
			var th_term_p: Vector2 = VillageCulture.TOWN_HALL_TERMINAL_POS
			if _add_model_2d(b_root, "props/Table_Large.gltf", th_term_p, 2.0, Vector2(20.0, 12.0), 8.0) == null:
				_add_box_2d(b_root, th_term_p, Vector2(20.0, 12.0), 2.0, 8.0, m_dark_wood)
			_add_green_crt_terminal_3d(b_root, th_term_p, 10.0, false)
		"building_shelter":
			var sh_dy: float = -20.0 if door_south else 20.0
			for sh_x in [-42.0, -14.0, 14.0, 42.0]:
				_build_bed_3d(b_root, c + Vector2(sh_x, sh_dy), m_wood, m_bed, m_pillow)
		_:
			if b_id.begins_with("shop_"):
				var stall_y: float = -14.0 if door_south else 14.0
				_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, stall_y), 2.0, Vector2(24.0, 10.5), 8.5)
				_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-28, stall_y), 2.0, Vector2(14.0, 10.0), 13.0)
				_add_model_2d(b_root, "props/Barrel_Apples.gltf", c + Vector2(22, stall_y), 2.0, Vector2(9.0, 9.0), 9.5)
			elif b_id.begins_with("mixed_"):
				var m_dir_mix: float = -1.0 if door_south else 1.0
				_add_box_2d(b_root, c + Vector2(-42, 4.0 * m_dir_mix), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
				_add_box_2d(b_root, c + Vector2(42, 4.0 * m_dir_mix), Vector2(40, 5.5), 2.0, wall_h * 0.85, m_wall)
				_add_model_2d(b_root, "props/Workbench.gltf", c + Vector2(0, -10.0 * m_dir_mix), 2.0, Vector2(24.0, 10.5), 8.5)
				_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-26, -16.0 * m_dir_mix), 2.0, Vector2(14.0, 9.0), 13.0)
				_build_bed_3d(b_root, c + Vector2(-36, 26.0 * m_dir_mix), m_wood, m_bed, m_pillow)
				_build_bed_3d(b_root, c + Vector2(36, 26.0 * m_dir_mix), m_wood, m_bed, m_pillow)
				_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, 24.0 * m_dir_mix), 2.0, Vector2(18.0, 12.0), 7.0)
			elif b_id.begins_with("house_") or b_id.begins_with("player_house_"):
				var bed_dx: float = 26.0 if rect.size.x < 96.0 else 30.0
				var bed_dy: float = (-12.0 if rect.size.y < 70.0 else -18.0) if door_south else (12.0 if rect.size.y < 70.0 else 18.0)
				var tbl_y: float = 2.0 if door_south else -2.0
				var bk_y: float = 16.0 if door_south else -16.0
				_build_bed_3d(b_root, c + Vector2(-bed_dx, bed_dy), m_wood, m_bed, m_pillow)
				if not b_id.begins_with("player_house_"):
					_build_bed_3d(b_root, c + Vector2(bed_dx, bed_dy), m_wood, m_bed, m_pillow)
				_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(2.0, tbl_y), 2.0, Vector2(17.0, 11.0), 7.0)
				_add_model_2d(b_root, "props/Chair_1.gltf", c + Vector2(-12.0, tbl_y), 2.0, Vector2(6.0, 6.0), 8.5, 90.0)
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(bed_dx, bk_y), 2.0, Vector2(14.0, 6.0), 16.0)
			else:
				# Edificios cívicos adicionales
				_add_model_2d(b_root, "props/Table_Large.gltf", c + Vector2(0, -10 if door_south else 10), 2.0, Vector2(24.0, 12.0), 7.5)
				_add_model_2d(b_root, "props/Cabinet.gltf", c + Vector2(-32, 12 if door_south else -12), 2.0, Vector2(16.0, 9.0), 13.0)
				_add_model_2d(b_root, "props/Bookcase_2.gltf", c + Vector2(32, 12 if door_south else -12), 2.0, Vector2(16.0, 9.0), 15.0)

# ==============================================================================
# R1: TRATTORIA «IL CORVO» (comedor, terraza, cocina, cámara frigorífica, bodega, cuarto y reservado)
# ==============================================================================
var _restaurant_night_nodes: Array = [] ## bombillas y luces de la terraza: se encienden al caer la tarde

## Mantel de cuadros rojos y blancos (textura de 2×2 píxeles repetida).
func _checker_cloth_mat() -> StandardMaterial3D:
	if _mat_cache.has("checker_cloth"):
		return _mat_cache["checker_cloth"]
	var m := StandardMaterial3D.new()
	m.roughness = 0.92
	if not _is_headless:
		var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
		img.set_pixel(0, 0, Color(0.42, 0.34, 0.25))
		img.set_pixel(1, 1, Color(0.42, 0.34, 0.25))
		img.set_pixel(1, 0, Color(0.56, 0.46, 0.35))
		img.set_pixel(0, 1, Color(0.56, 0.46, 0.35))
		m.albedo_texture = ImageTexture.create_from_image(img)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(5.0, 5.0, 5.0)
	else:
		m.albedo_color = Color(0.48, 0.39, 0.30)
	_mat_cache["checker_cloth"] = m
	return m

func _restaurant_light(parent: Node3D, pos_2d: Vector2, h_px: float, col: Color, energy: float, rng: float, night_only: bool) -> void:
	if _is_headless:
		return
	var lt := OmniLight3D.new()
	lt.position = to_3d(pos_2d, h_px)
	lt.light_color = col
	lt.light_energy = energy
	lt.omni_range = rng
	lt.shadow_enabled = false
	parent.add_child(lt)
	if night_only:
		_restaurant_night_nodes.append(lt)

## Mesa con mantel de cuadros, vela en botella y dos sillas.
func _restaurant_table_3d(parent: Node3D, p: Vector2, m_wood: Material, round_top: bool) -> void:
	var m_bottle := _mat("chianti_bottle", Color(0.16, 0.42, 0.22, 0.92), 0.2, 0.1)
	var m_flame := _mat("candle_flame", Color(1.0, 0.78, 0.36), 0.4, 0.0, Color(1.0, 0.66, 0.24), 3.0)
	var m_wax := _mat("candle_wax", Color(0.96, 0.92, 0.82), 0.7, 0.0)
	var chair_dx: float = 14.5
	if round_top:
		_register_furniture_rect("TerraceRoundTable", p, Vector2(15.0, 15.0))
		_add_cyl_2d(parent, p, 1.4, 2.0, 7.0, m_wood, 1.4, 8)
		_add_cyl_2d(parent, p, 7.5, 9.0, 0.9, _checker_cloth_mat(), 7.5, 14)
		chair_dx = 12.5
	else:
		_add_model_2d(parent, "props/Table_Large.gltf", p, 2.0, Vector2(18.0, 12.0), 6.8)
		_add_box_2d(parent, p, Vector2(18.6, 12.6), 8.8, 0.7, _checker_cloth_mat())
	_add_cyl_2d(parent, p + Vector2(2, 0), 1.6, 9.6, 4.2, m_bottle, 0.7, 8) # botella de vino con la vela
	_add_cyl_2d(parent, p + Vector2(2, 0), 0.6, 13.8, 1.6, m_wax, 0.6, 6)
	_add_cyl_2d(parent, p + Vector2(2, 0), 0.4, 15.4, 1.0, m_flame, 0.1, 6)
	_add_model_2d(parent, "props/Chair_1.gltf", p + Vector2(-chair_dx, 0), 2.0, Vector2(6.0, 6.0), 8.5, 90.0)
	_add_model_2d(parent, "props/Chair_1.gltf", p + Vector2(chair_dx, 0), 2.0, Vector2(6.0, 6.0), 8.5, -90.0)

func _build_restaurant_3d(b_root: Node3D, wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var R = VillageRestaurant
	var ih: float = wall_h * 0.85
	var m_frost := _mat("frost_tile", Color(0.80, 0.90, 0.96), 0.35, 0.1, Color.BLACK, 0.0, "town_textures/floor_tiles_blue_small.png")
	var m_ice := _mat("ice_block", Color(0.78, 0.92, 1.0, 0.82), 0.1, 0.0)
	var m_meat := _mat("hung_meat", Color(0.66, 0.14, 0.12), 0.6, 0.0)
	var m_fat := _mat("hung_meat_fat", Color(0.92, 0.84, 0.74), 0.7, 0.0)
	var m_steel := _mat("kitchen_steel", Color(0.70, 0.74, 0.78), 0.3, 0.8)
	var m_stove := _mat("stove_iron", Color(0.16, 0.16, 0.18), 0.5, 0.7)
	var m_ember := _mat("stove_ember", Color(1.0, 0.40, 0.12), 0.4, 0.0, Color(1.0, 0.36, 0.08), 2.4)
	var m_rug := _mat("backroom_rug", Color(0.46, 0.08, 0.10), 0.95, 0.0)
	var m_felt := _mat("piano_keys", Color(0.95, 0.94, 0.90), 0.6, 0.0)
	var m_black := _mat("piano_black", Color(0.06, 0.05, 0.05), 0.35, 0.2)
	var m_tile := _mat("kitchen_tile", Color(0.86, 0.84, 0.78), 0.6, 0.0, Color.BLACK, 0.0, "town_textures/floor_tiles_sand_small.png")
	var m_terr := _mat("terrace_slabs", Color(0.70, 0.52, 0.40), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/floor_stone_sand_random.png")
	var m_canvas_g := _mat("parasol_green", Color(0.20, 0.44, 0.26), 0.9, 0.0)
	var m_canvas_w := _mat("parasol_cream", Color(0.95, 0.90, 0.78), 0.9, 0.0)
	var m_bulb := _mat("string_bulb", Color(1.0, 0.86, 0.52), 0.3, 0.0, Color(1.0, 0.78, 0.40), 2.6)
	var m_frame := _mat("painting_frame", Color(0.62, 0.46, 0.18), 0.5, 0.6)
	var m_canvas_p := _mat("painting_canvas", Color(0.30, 0.22, 0.16), 0.9, 0.0)
	var m_plant := _mat("pot_plant", Color(0.22, 0.46, 0.20), 0.9, 0.0)
	var m_pot := _mat("terracotta_pot", Color(0.70, 0.36, 0.22), 0.85, 0.0)

	# --- Tabiques (los mismos huecos que en 2D)
	var x0: float = R.RECT.position.x
	var x1: float = R.RECT.end.x
	var cur: float = x0
	var gaps: Array[float] = []
	for o in R.OPENINGS:
		if str(o["axis"]) == "h":
			gaps.append(float((o["pos"] as Vector2).x))
	gaps.sort()
	for gx in gaps:
		var a: float = gx - R.GAP * 0.5
		if a - cur > 2.0:
			_add_box_2d(b_root, Vector2((cur + a) * 0.5, R.ROW_Y), Vector2(a - cur, 5.5), 2.0, ih, m_wall)
		_add_box_2d(b_root, Vector2(gx, R.ROW_Y), Vector2(R.GAP + 4.0, 5.5), 2.0 + ih * 0.78, ih * 0.22, m_trim) # dintel
		cur = gx + R.GAP * 0.5
	if x1 - cur > 2.0:
		_add_box_2d(b_root, Vector2((cur + x1) * 0.5, R.ROW_Y), Vector2(x1 - cur, 5.5), 2.0, ih, m_wall)
	for vx in [R.BASE.x + 85.0, R.BASE.x + 140.0]:
		_add_box_2d(b_root, Vector2(vx, (R.RECT.position.y + R.ROW_Y) * 0.5), Vector2(5.5, R.ROW_Y - R.RECT.position.y), 2.0, ih, m_wall)
	var top: float = R.RECT.position.y
	var bottom: float = R.RECT.end.y
	var gy: float = R.BASE.y + 135.0
	_add_box_2d(b_root, Vector2(R.KITCHEN_X, (top + gy - R.GAP * 0.5) * 0.5), Vector2(5.5, gy - R.GAP * 0.5 - top), 2.0, ih, m_wall)
	_add_box_2d(b_root, Vector2(R.KITCHEN_X, (gy + R.GAP * 0.5 + bottom) * 0.5), Vector2(5.5, bottom - gy - R.GAP * 0.5), 2.0, ih, m_wall)
	_add_box_2d(b_root, Vector2(R.KITCHEN_X, gy), Vector2(5.5, R.GAP + 4.0), 2.0 + ih * 0.78, ih * 0.22, m_trim)

	# --- Suelos de cada sala sobre el suelo general (baldosa de barro)
	_add_box_2d(b_root, R.ROOMS["cocina"].get_center(), R.ROOMS["cocina"].size - Vector2(6, 6), 2.5, 0.4, m_tile)
	_add_box_2d(b_root, R.ROOMS["camara"].get_center(), R.ROOMS["camara"].size - Vector2(6, 6), 2.5, 0.4, m_frost)
	_add_box_2d(b_root, R.ROOMS["bodega"].get_center(), R.ROOMS["bodega"].size - Vector2(6, 6), 2.5, 0.4, m_dark_wood)
	_add_box_2d(b_root, R.BACKROOM_TABLE, Vector2(58, 46), 2.5, 0.4, m_rug)

	# --- Comedor: mesas con mantel de cuadros, barra, piano, cuadros, plantas y dos arañas de luz
	for t in R.DINING_TABLES:
		_restaurant_table_3d(b_root, t, m_wood, false)
	_register_furniture_rect("RestaurantCounter", R.COUNTER_POS, Vector2(34.0, 9.0))
	_add_box_2d(b_root, R.COUNTER_POS, Vector2(34, 9), 2.0, 10.0, m_dark_wood) # barra
	_add_box_2d(b_root, R.COUNTER_POS, Vector2(36, 10.5), 12.0, 1.0, m_gold) # canto de latón
	_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", R.COUNTER_POS + Vector2(4, 12), 2.0, Vector2(18.0, 5.0), 16.0)
	for bx in [-10.0, -4.0, 8.0]:
		_add_model_2d(b_root, "props/Bottle_1.gltf", R.COUNTER_POS + Vector2(bx, -1), 13.0, Vector2(2.5, 2.5), 5.0)
	_add_model_2d(b_root, "props/Mug.gltf", R.COUNTER_POS + Vector2(2, -1), 13.0, Vector2(3.0, 3.0), 3.5)
	# Piano vertical contra la pared
	_register_furniture_rect("Piano", R.PIANO_POS, Vector2(22.0, 9.0))
	_add_box_2d(b_root, R.PIANO_POS, Vector2(22, 9), 2.0, 16.0, m_black)
	_add_box_2d(b_root, R.PIANO_POS + Vector2(0, -5.0), Vector2(20, 3), 9.0, 1.2, m_felt)
	_register_furniture_rect("PianoBench", R.PIANO_POS + Vector2(0, -9.5), Vector2(10.0, 5.0))
	_add_box_2d(b_root, R.PIANO_POS + Vector2(0, -9.5), Vector2(10, 5), 2.0, 6.0, m_dark_wood) # banqueta
	for pp in [R.BASE + Vector2(40, 83), R.BASE + Vector2(150, 83)]: # cuadros en el tabique del fondo
		_add_box_2d(b_root, pp, Vector2(16, 1.5), 13.0, 11.0, m_frame)
		_add_box_2d(b_root, pp + Vector2(0, 0.6), Vector2(13, 1.0), 14.5, 8.0, m_canvas_p)
	for pl_p in [R.BASE + Vector2(8, 88), R.BASE + Vector2(187, 88), R.BASE + Vector2(187, 184)]:
		_add_cyl_2d(b_root, pl_p, 3.5, 2.0, 5.0, m_pot, 2.8, 10)
		_add_cyl_2d(b_root, pl_p, 4.5, 7.0, 7.0, m_plant, 1.5, 8)
	for ch in [R.BASE + Vector2(46, 132), R.BASE + Vector2(138, 132)]:
		_add_model_2d(b_root, "props/Chandelier.gltf", ch, ih - 8.0, Vector2(12.0, 12.0), 7.0)
		_restaurant_light(b_root, ch, ih - 6.0, Color(1.0, 0.80, 0.52), 1.15, 2.6, false)

	# --- Cocina: fogones con brasas, ollas, encimera, fregadero y cajas de verdura
	_register_furniture_rect("KitchenStove", R.STOVE_POS, Vector2(24.0, 12.0))
	_add_box_2d(b_root, R.STOVE_POS, Vector2(24, 12), 2.0, 10.0, m_stove)
	_add_box_2d(b_root, R.STOVE_POS, Vector2(20, 9), 12.0, 0.6, m_ember)
	_add_model_2d(b_root, "props/Cauldron.gltf", R.STOVE_POS + Vector2(-5, 0), 12.0, Vector2(8.0, 8.0), 6.0)
	_add_model_2d(b_root, "props/Pot_1.gltf", R.STOVE_POS + Vector2(6, 0), 12.0, Vector2(6.0, 6.0), 4.5)
	_add_box_2d(b_root, R.STOVE_POS + Vector2(0, -8), Vector2(26, 3), 22.0, 10.0, m_steel) # campana
	_add_model_2d(b_root, "props/Workbench.gltf", R.KITCHEN_COUNTER, 2.0, Vector2(28.0, 10.0), 10.0)
	_register_furniture_rect("KitchenSink", R.BASE + Vector2(210, 114), Vector2(10.0, 16.0))
	_add_box_2d(b_root, R.BASE + Vector2(210, 114), Vector2(10, 16), 2.0, 9.0, m_steel) # fregadero
	_add_model_2d(b_root, "props/Bucket_Metal.gltf", R.BASE + Vector2(210, 130), 2.0, Vector2(5.0, 5.0), 5.0)
	_add_model_2d(b_root, "props/FarmCrate_Carrot.gltf", R.BASE + Vector2(266, 148), 2.0, Vector2(9.0, 7.0), 6.0)
	_add_model_2d(b_root, "props/FarmCrate_Apple.gltf", R.BASE + Vector2(266, 162), 2.0, Vector2(9.0, 7.0), 6.0)
	_add_model_2d(b_root, "props/Barrel_Apples.gltf", R.BASE + Vector2(210, 178), 2.0, Vector2(8.0, 8.0), 9.0)
	_restaurant_light(b_root, R.BASE + Vector2(235, 126), ih - 4.0, Color(1.0, 0.92, 0.80), 0.9, 2.2, false)

	# --- Cámara frigorífica: paredes forradas de escarcha, bloques de hielo, carne colgada de un riel y marco de acero
	var cam: Rect2 = R.ROOMS["camara"]
	_add_box_2d(b_root, Vector2(cam.get_center().x, cam.position.y + 4.0), Vector2(cam.size.x - 8.0, 2.0), 2.0, ih - 2.0, m_frost)
	_add_box_2d(b_root, Vector2(cam.end.x - 4.0, cam.get_center().y), Vector2(2.0, cam.size.y - 8.0), 2.0, ih - 2.0, m_frost)
	_add_box_2d(b_root, Vector2(cam.position.x + 4.0, cam.get_center().y), Vector2(2.0, cam.size.y - 8.0), 2.0, ih - 2.0, m_frost)
	for ip in [R.BASE + Vector2(206, 8), R.BASE + Vector2(206, 22), R.BASE + Vector2(268, 10), R.BASE + Vector2(268, 24)]:
		_add_box_2d(b_root, ip, Vector2(10, 10), 2.0, 8.0, m_ice)
	_add_box_2d(b_root, R.BASE + Vector2(242, 18), Vector2(46, 1.5), ih - 5.0, 1.5, m_steel) # riel de ganchos
	for mp in [R.BASE + Vector2(226, 18), R.BASE + Vector2(238, 18), R.BASE + Vector2(250, 18), R.BASE + Vector2(260, 18)]:
		_add_box_2d(b_root, mp, Vector2(0.6, 0.6), ih - 9.0, 4.0, m_steel) # gancho
		_add_box_2d(b_root, mp, Vector2(5.5, 4.0), ih - 23.0, 14.0, m_meat) # pieza de carne
		_add_box_2d(b_root, mp + Vector2(0, -1.0), Vector2(5.8, 2.0), ih - 13.0, 3.0, m_fat)
	_add_model_2d(b_root, "props/Crate_Metal.gltf", R.BASE + Vector2(264, 56), 2.0, Vector2(10.0, 10.0), 8.0)
	_add_model_2d(b_root, "props/Crate_Wooden.gltf", R.BASE + Vector2(264, 44), 10.0, Vector2(8.0, 8.0), 6.0)
	var cam_gap: Vector2 = Vector2(R.BASE.x + 235.0, R.ROW_Y)
	for side in [-1.0, 1.0]:
		_add_box_2d(b_root, cam_gap + Vector2(side * (R.GAP * 0.5 + 1.0), 0), Vector2(3.0, 7.0), 2.0, ih, m_steel)
	_add_box_2d(b_root, cam_gap, Vector2(R.GAP + 6.0, 7.0), 2.0 + ih * 0.78, ih * 0.22, m_steel)
	_restaurant_light(b_root, cam.get_center(), ih - 4.0, Color(0.62, 0.82, 1.0), 0.75, 1.8, false)

	# --- Bodega: barriles y botellero
	for bp in [R.BASE + Vector2(96, 48), R.BASE + Vector2(96, 62), R.BASE + Vector2(130, 48)]:
		_add_model_2d(b_root, "props/Barrel.gltf", bp, 2.0, Vector2(10.0, 10.0), 11.0)
	_add_model_2d(b_root, "props/Barrel.gltf", R.BASE + Vector2(96, 55), 13.0, Vector2(9.0, 9.0), 10.0, 90.0)
	_add_model_2d(b_root, "props/Shelf_Simple.gltf", R.WINE_RACK, 2.0, Vector2(30.0, 6.0), 20.0)
	for wy in [6.0, 12.0, 18.0]:
		for wx in [-10.0, -4.0, 2.0, 8.0]:
			_add_cyl_2d(b_root, R.WINE_RACK + Vector2(wx, 0), 1.0, wy, 3.5, _mat("chianti_bottle", Color(0.16, 0.42, 0.22, 0.92), 0.2, 0.1), 0.5, 6)

	# --- Despacho del dueño: escritorio de madera noble, silla de dirección, estantería, libro de cuentas y alfombra
	_add_box_2d(b_root, R.BASE + Vector2(164, 36), Vector2(28, 22), 2.0, 0.5, _mat("office_rug", Color(0.46, 0.14, 0.14), 0.92, 0.0))
	_add_model_2d(b_root, "props/Workbench.gltf", R.OWNER_BED + Vector2(4, 6), 2.0, Vector2(18.0, 10.0), 9.0)
	_add_model_2d(b_root, "props/Chair_1.gltf", R.OWNER_BED + Vector2(4, -5), 2.0, Vector2(6.0, 6.0), 8.5, 0.0)
	_add_model_2d(b_root, "props/Chair_1.gltf", R.OWNER_BED + Vector2(4, 15), 2.0, Vector2(6.0, 6.0), 8.5, 180.0)
	_add_model_2d(b_root, "props/Book_5.gltf", R.OWNER_BED + Vector2(1, 5), 11.0, Vector2(5.0, 4.0), 2.2)
	_add_model_2d(b_root, "props/CandleStick_Triple.gltf", R.OWNER_BED + Vector2(9, 4), 11.0, Vector2(4.0, 4.0), 5.5)
	_add_model_2d(b_root, "props/Shelf_Simple.gltf", R.BASE + Vector2(148, 8), 2.0, Vector2(12.0, 5.0), 18.0)
	_add_model_2d(b_root, "props/Nightstand_Shelf.gltf", R.BASE + Vector2(148, 46), 2.0, Vector2(7.0, 6.0), 8.0)

	# --- Reservado: mesa redonda grande, cinco sillas, candelabro, chimenea y luz roja tenue
	_register_furniture_rect("BackroomRoundTable", R.BACKROOM_TABLE, Vector2(21.0, 21.0))
	_add_cyl_2d(b_root, R.BACKROOM_TABLE, 2.0, 2.0, 7.0, m_dark_wood, 2.0, 8)
	_add_cyl_2d(b_root, R.BACKROOM_TABLE, 12.5, 9.0, 1.0, _mat("backroom_cloth", Color(0.92, 0.90, 0.84), 0.9, 0.0), 12.5, 18)
	_add_model_2d(b_root, "props/CandleStick_Triple.gltf", R.BACKROOM_TABLE, 10.0, Vector2(5.0, 5.0), 7.0)
	for i in range(5):
		var ang: float = TAU * float(i) / 5.0 + PI * 0.5
		var cp: Vector2 = R.BACKROOM_TABLE + Vector2(cos(ang), sin(ang)) * 21.5
		_add_model_2d(b_root, "props/Chair_1.gltf", cp, 2.0, Vector2(6.0, 6.0), 8.5, rad_to_deg(-ang) - 90.0)
	_add_box_2d(b_root, R.BASE + Vector2(8, 12), Vector2(9, 18), 2.0, 16.0, _mat("fireplace_stone", Color(0.50, 0.46, 0.42), 0.9, 0.0))
	_add_box_2d(b_root, R.BASE + Vector2(11, 12), Vector2(3, 12), 3.0, 6.0, m_ember)
	_restaurant_light(b_root, R.BACKROOM_TABLE, ih - 8.0, Color(1.0, 0.46, 0.30), 0.85, 1.8, false)

	# --- Terraza: losas, mesas con sombrilla, macetas, guirnalda de bombillas, toldo verde y letrero
	_add_box_2d(b_root, R.TERRACE.get_center(), R.TERRACE.size, 0.0, 1.2, m_terr)
	for t in R.TERRACE_TABLES:
		_restaurant_table_3d(b_root, t, m_wood, true)
		_add_cyl_2d(b_root, t, 0.6, 9.0, 18.0, m_wood, 0.6, 6) # palo de la sombrilla
		_add_cyl_2d(b_root, t, 13.0, 27.0, 4.0, m_canvas_g if (int(t.x) % 2 == 0) else m_canvas_w, 0.8, 12)
	for pp in [R.BASE + Vector2(4, 232), R.BASE + Vector2(270, 232), R.BASE + Vector2(80, 232), R.BASE + Vector2(120, 232)]:
		_add_cyl_2d(b_root, pp, 3.8, 1.2, 5.5, m_pot, 3.0, 10) # maceta de barro
		_add_cyl_2d(b_root, pp, 3.2, 6.5, 3.0, m_plant, 5.0, 10) # mata redonda
		_add_cyl_2d(b_root, pp, 5.0, 9.5, 3.5, m_plant, 2.0, 10)
	# Postes y guirnalda de bombillas a lo largo de la terraza (se encienden al caer la tarde)
	var posts: Array[Vector2] = [R.BASE + Vector2(2, 234), R.BASE + Vector2(80, 234), R.BASE + Vector2(120, 234), R.BASE + Vector2(208, 234), R.BASE + Vector2(273, 234)]
	for pi in range(posts.size()):
		_add_cyl_2d(b_root, posts[pi], 0.8, 1.2, 30.0, m_iron, 0.8, 6)
		if pi + 1 < posts.size():
			var a2: Vector2 = posts[pi]
			var b2: Vector2 = posts[pi + 1]
			for k in range(1, 6):
				var tk: float = float(k) / 6.0
				var sag: float = 4.0 * sin(tk * PI)
				var bulb := _add_cyl_2d(b_root, a2.lerp(b2, tk), 0.9, 29.0 - sag, 1.6, m_bulb, 0.9, 6)
				_restaurant_night_nodes.append(bulb)
	_restaurant_light(b_root, R.BASE + Vector2(60, 216), 26.0, Color(1.0, 0.80, 0.46), 0.9, 2.4, true)
	_restaurant_light(b_root, R.BASE + Vector2(210, 216), 26.0, Color(1.0, 0.80, 0.46), 0.9, 2.4, true)
	# Toldo verde sobre la puerta y faroles
	var door_c: Vector2 = Vector2(R.DOOR_X, R.RECT.end.y + 6.0)
	_add_box_2d(b_root, door_c, Vector2(R.DOOR_W + 26.0, 12.0), wall_h * 0.72, 2.0, m_canvas_g)
	_add_box_2d(b_root, door_c + Vector2(0, 6.0), Vector2(R.DOOR_W + 26.0, 1.0), wall_h * 0.72 - 3.0, 3.0, m_canvas_w)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", Vector2(R.DOOR_X - 24.0, R.RECT.end.y + 2.0), wall_h * 0.55, Vector2(4.0, 4.0), 6.0)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", Vector2(R.DOOR_X + 24.0, R.RECT.end.y + 2.0), wall_h * 0.55, Vector2(4.0, 4.0), 6.0)
	# Sendero desde el camino del este
	_add_box_2d(b_root, R.PATH_RECT.get_center(), R.PATH_RECT.size, 0.0, 0.8, m_terr)

func _build_bed_3d(parent: Node3D, pos_2d: Vector2, m_frame: Material, m_blanket: Material, m_pillow: Material) -> void:
	_build_bed_3d_at_h(parent, pos_2d, 2.0, m_frame, m_blanket, m_pillow)

func _build_bed_3d_at_h(parent: Node3D, pos_2d: Vector2, base_h: float, m_frame: Material, m_blanket: Material, m_pillow: Material) -> void:
	var bed := _add_model_2d(parent, "props/Bed_Twin1.gltf", pos_2d, base_h, Vector2(15.0, 21.0), 8.5)
	if bed != null:
		return
	_add_box_2d(parent, pos_2d, Vector2(15.0, 21.0), base_h, 4.5, m_frame)
	_add_box_2d(parent, pos_2d + Vector2(0, 2.0), Vector2(13.5, 15.0), base_h + 4.5, 2.0, m_blanket)
	_add_box_2d(parent, pos_2d + Vector2(0, -6.5), Vector2(11.0, 4.5), base_h + 4.5, 2.2, m_pillow)

## Paso 3: Planta Baja (Planta 0) de la Gran Taberna «El Jabalí Dorado» (Salón-Comedor, Barra-Cocina, Casino con Póker y Mesa de Billar real 3D, Escalera al Piso +1 y Bodega con Trampilla del Club).
func _build_tavern_floor_0_3d(b_root: Node3D, _wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, m_iron: Material, m_gold: Material) -> void:
	var T = VillageTavern
	var ih0: float = 19.0
	var m_felt := _mat("tavern_green_felt", Color(0.12, 0.52, 0.28), 0.82, 0.0)
	var m_carpet := _mat("tavern_casino_carpet", Color(0.48, 0.12, 0.14), 0.92, 0.0)
	var m_hall_rug := _mat("tavern_hall_rug", Color(0.56, 0.24, 0.16), 0.90, 0.0)
	var m_tile := _mat("tavern_kitchen_tile", Color(0.76, 0.70, 0.62), 0.75, 0.0, Color.BLACK, 0.0, "town_textures/floor_tiles_sand_small.png")
	var m_stone := _mat("tavern_hearth_stone", Color(0.52, 0.48, 0.44), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png")
	var m_stove := _mat("tavern_stove_iron", Color(0.16, 0.16, 0.18), 0.48, 0.72)
	var m_ember := _mat("tavern_ember", Color(1.0, 0.42, 0.12), 0.35, 0.0, Color(1.0, 0.38, 0.08), 2.4)
	var m_plate := _mat("tavern_plate", Color(0.92, 0.90, 0.84), 0.45, 0.05)
	var m_chip_red := _mat("poker_chip_red", Color(0.84, 0.18, 0.18), 0.55, 0.1)
	var m_chip_blue := _mat("poker_chip_blue", Color(0.18, 0.38, 0.82), 0.55, 0.1)

	# 1. Tabiques interiores de Planta 0 (con los mismos huecos de paso que en VillageTavern.OPENINGS_FLOOR_0)
	var x0: float = T.RECT.position.x
	var x1: float = T.RECT.end.x
	var h_gaps: Array[float] = [432.0, 534.0]
	var cur_x: float = x0
	for gx in h_gaps:
		var a: float = gx - T.GAP * 0.5
		if a - cur_x > 2.0:
			_add_box_2d(b_root, Vector2((cur_x + a) * 0.5, T.MID_WALL_Y), Vector2(a - cur_x, 5.5), 2.0, ih0, m_wall)
		_add_box_2d(b_root, Vector2(gx, T.MID_WALL_Y), Vector2(T.GAP + 4.0, 5.5), 2.0 + ih0 * 0.78, ih0 * 0.22, m_trim)
		cur_x = gx + T.GAP * 0.5
	if 558.0 - cur_x > 2.0:
		_add_box_2d(b_root, Vector2((cur_x + 558.0) * 0.5, T.MID_WALL_Y), Vector2(558.0 - cur_x, 5.5), 2.0, ih0, m_wall)
	_add_box_2d(b_root, Vector2(558.0, -223.0), Vector2(4.8, 42.0), 2.0, ih0, m_wall)

	var y0: float = T.RECT.position.y
	var y1: float = T.RECT.end.y
	var v_gaps: Array[float] = [-276.0, -182.0]
	var cur_y: float = y0
	for gy in v_gaps:
		var ay: float = gy - T.GAP * 0.5
		if ay - cur_y > 2.0:
			_add_box_2d(b_root, Vector2(T.EAST_WING_X, (cur_y + ay) * 0.5), Vector2(5.5, ay - cur_y), 2.0, ih0, m_wall)
		_add_box_2d(b_root, Vector2(T.EAST_WING_X, gy), Vector2(5.5, T.GAP + 4.0), 2.0 + ih0 * 0.78, ih0 * 0.22, m_trim)
		cur_y = gy + T.GAP * 0.5
	if y1 - cur_y > 2.0:
		_add_box_2d(b_root, Vector2(T.EAST_WING_X, (cur_y + y1) * 0.5), Vector2(5.5, y1 - cur_y), 2.0, ih0, m_wall)

	# 2. Alfombras y pavimentos diferenciados por sala en Planta 0
	_add_box_2d(b_root, T.ROOMS_FLOOR_0["barra_cocina"].get_center(), T.ROOMS_FLOOR_0["barra_cocina"].size - Vector2(8, 8), 2.5, 0.35, m_tile)
	_add_box_2d(b_root, T.ROOMS_FLOOR_0["casino"].get_center(), T.ROOMS_FLOOR_0["casino"].size - Vector2(10, 10), 2.5, 0.38, m_carpet)
	_add_box_2d(b_root, Vector2(368.0, -174.0), Vector2(168.0, 56.0), 2.5, 0.35, m_hall_rug)

	# 3. Gran Salón y Comedor: Hogar de piedra con brasas, 6 mesas con 12 sillas, platos, jarras y arañas de techo
	_register_furniture_rect("TavernFireplace", T.FIREPLACE_POS, Vector2(14.0, 32.0))
	_add_box_2d(b_root, T.FIREPLACE_POS, Vector2(14.0, 32.0), 2.0, 18.5, m_stone)
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(2.0, 0.0), Vector2(16.0, 36.0), 14.5, 2.2, m_dark_wood) # Repisa de roble
	_add_box_2d(b_root, T.FIREPLACE_POS + Vector2(5.0, 0.0), Vector2(6.0, 20.0), 2.8, 5.5, m_ember)
	_add_model_2d(b_root, "props/Cauldron.gltf", T.FIREPLACE_POS + Vector2(4.5, 0.0), 6.0, Vector2(7.5, 7.5), 5.5)

	for ti in range(T.DINING_TABLES.size()):
		var tp: Vector2 = T.DINING_TABLES[ti]
		if _add_model_2d(b_root, "props/Table_Large.gltf", tp, 2.0, Vector2(19.0, 12.5), 7.2) == null:
			_add_box_2d(b_root, tp, Vector2(19.0, 12.5), 2.0, 7.2, m_wood)
		# 2 sillas enfrentadas (izquierda y derecha de cada mesa)
		_add_model_2d(b_root, "props/Chair_1.gltf", tp + Vector2(-15.0, 0.0), 2.0, Vector2(6.0, 6.0), 8.5, 90.0)
		_add_model_2d(b_root, "props/Chair_1.gltf", tp + Vector2(15.0, 0.0), 2.0, Vector2(6.0, 6.0), 8.5, -90.0)
		# Platos y jarras servidas sobre la mesa
		_add_cyl_2d(b_root, tp + Vector2(-5.5, -1.5), 2.6, 9.2, 0.5, m_plate, 2.2, 10)
		_add_cyl_2d(b_root, tp + Vector2(5.5, 1.5), 2.6, 9.2, 0.5, m_plate, 2.2, 10)
		_add_model_2d(b_root, "props/Mug.gltf", tp + Vector2(-4.0, 2.5), 9.2, Vector2(3.2, 3.2), 3.6)
		_add_model_2d(b_root, "props/Mug.gltf", tp + Vector2(4.5, -2.5), 9.2, Vector2(3.2, 3.2), 3.6)
		if (ti % 2) == 0:
			_add_model_2d(b_root, "props/CandleStick_Triple.gltf", tp, 9.2, Vector2(3.8, 3.8), 5.0)

	for ch_pos in [Vector2(332.0, -172.0), Vector2(416.0, -172.0)]:
		_add_model_2d(b_root, "props/Chandelier.gltf", ch_pos, 14.5, Vector2(12.0, 12.0), 6.5)
		_restaurant_light(b_root, ch_pos, 15.5, Color(1.0, 0.80, 0.48), 1.15, 2.8, false)

	# Faroles en la fachada sur de la taberna
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", T.DOOR_POS + Vector2(-28.0, 3.0), 15.0, Vector2(4.2, 4.2), 6.2)
	_add_model_2d(b_root, "props/Lantern_Wall.gltf", T.DOOR_POS + Vector2(28.0, 3.0), 15.0, Vector2(4.2, 4.2), 6.2)

	# 4. Barra del Tabernero (con Marta detrás), Pasa-platos del Camarero, Toneles y Cocina
	_register_furniture_rect("TavernBarCounter", T.BAR_COUNTER_POS, Vector2(88.0, 10.0))
	_add_box_2d(b_root, T.BAR_COUNTER_POS, Vector2(86.0, 10.0), 2.0, 10.0, m_dark_wood)
	_add_box_2d(b_root, T.BAR_COUNTER_POS, Vector2(88.0, 11.0), 11.6, 1.2, m_wood)
	_add_box_2d(b_root, T.BAR_COUNTER_POS + Vector2(0.0, 5.4), Vector2(84.0, 1.2), 3.6, 0.9, m_gold) # Barra reposapiés de latón
	# 3 tiradores de cerveza de latón + jarras y botellas
	for tap_x in [-24.0, 0.0, 24.0]:
		_add_cyl_2d(b_root, T.BAR_COUNTER_POS + Vector2(tap_x, -2.0), 1.1, 12.8, 4.2, m_gold, 0.8, 8)
	_add_model_2d(b_root, "props/Mug.gltf", T.BAR_COUNTER_POS + Vector2(-32.0, 1.0), 12.8, Vector2(3.8, 3.8), 4.0)
	_add_model_2d(b_root, "props/Mug.gltf", T.BAR_COUNTER_POS + Vector2(-10.0, 1.5), 12.8, Vector2(3.8, 3.8), 4.0)
	_add_model_2d(b_root, "props/Chalice.gltf", T.BAR_COUNTER_POS + Vector2(12.0, 1.0), 12.8, Vector2(3.8, 3.8), 4.4)
	_add_model_2d(b_root, "props/Bottle_1.gltf", T.BAR_COUNTER_POS + Vector2(34.0, -1.0), 12.8, Vector2(2.8, 2.8), 5.2)
	# 4 taburetes altos frente a la barra
	for st_x in [-33.0, -11.0, 11.0, 33.0]:
		var st_pos: Vector2 = T.BAR_COUNTER_POS + Vector2(st_x, 9.5)
		_register_furniture_rect("BarStool", st_pos, Vector2(6.5, 6.5))
		_add_cyl_2d(b_root, st_pos, 1.2, 2.0, 5.8, m_dark_wood, 1.8, 8)
		_add_cyl_2d(b_root, st_pos, 3.25, 7.8, 1.1, m_wood, 3.25, 10)
	# Pasa-platos del camarero al este de la barra
	var pass_c: Vector2 = T.PASS_COUNTER_POS + Vector2(2.0, 8.0)
	_register_furniture_rect("TavernPassCounter", pass_c, Vector2(21.0, 9.5))
	_add_box_2d(b_root, pass_c, Vector2(20.0, 8.5), 2.0, 9.8, m_dark_wood)
	_add_box_2d(b_root, pass_c, Vector2(21.0, 9.5), 11.6, 1.0, m_gold)
	_add_cyl_2d(b_root, pass_c + Vector2(-4.0, 0.0), 3.2, 12.6, 0.6, m_plate, 2.8, 10)
	_add_model_2d(b_root, "props/Mug.gltf", pass_c + Vector2(4.0, 0.0), 12.6, Vector2(3.5, 3.5), 3.8)
	# Estantería de botellas tras Marta y hilera de grandes toneles de roble
	_add_model_2d(b_root, "props/Shelf_Small_Bottles.gltf", Vector2(346.0, -309.0), 2.0, Vector2(24.0, 5.0), 17.0)
	for bx in [-24.0, -8.0, 8.0, 24.0]:
		_add_model_2d(b_root, "props/Barrel.gltf", T.BARREL_RACK_POS + Vector2(bx, 0.0), 2.0, Vector2(10.0, 10.0), 11.0)
	# Fogones de cocina de la posada y mesa de preparación
	_register_furniture_rect("TavernStove", T.STOVE_POS, Vector2(26.0, 12.0))
	_add_box_2d(b_root, T.STOVE_POS, Vector2(26.0, 12.0), 2.0, 10.0, m_stove)
	_add_box_2d(b_root, T.STOVE_POS, Vector2(21.0, 8.5), 12.0, 0.6, m_ember)
	_add_model_2d(b_root, "props/Cauldron.gltf", T.STOVE_POS + Vector2(-5.5, 0.0), 12.0, Vector2(8.0, 8.0), 6.0)
	_add_model_2d(b_root, "props/Pot_1.gltf", T.STOVE_POS + Vector2(6.5, 0.0), 12.0, Vector2(6.0, 6.0), 4.5)
	_add_model_2d(b_root, "props/Workbench.gltf", T.PREP_POS, 2.0, Vector2(24.0, 9.5), 9.5)
	_restaurant_light(b_root, Vector2(368.0, -268.0), 16.5, Color(1.0, 0.86, 0.60), 1.0, 2.5, false)

	# 5. Sala de Casino y Billar: Mesa de Póker con 4 sillas y fichas + Mesa de Billar Real en 3D
	var gp: Vector2 = T.GAMES_POS
	_register_furniture_rect("PokerTable", gp, Vector2(23.0, 23.0))
	_add_cyl_2d(b_root, gp, 3.2, 2.0, 6.4, m_dark_wood, 5.2, 10) # Pedestal central torneado de la mesa de póker
	_add_cyl_2d(b_root, gp, 11.5, 8.2, 1.4, m_dark_wood, 11.5, 12) # Aro de caoba
	_add_cyl_2d(b_root, gp, 9.8, 9.3, 0.5, m_felt, 9.8, 12) # Paño verde de póker
	# 4 sillas de póker (Oeste, Este, Norte, Sur) sincronizadas con T.POKER_CHAIRS
	_add_model_2d(b_root, "props/Chair_1.gltf", T.POKER_CHAIRS[0], 2.0, Vector2(6.0, 6.0), 8.5, 90.0)
	_add_model_2d(b_root, "props/Chair_1.gltf", T.POKER_CHAIRS[1], 2.0, Vector2(6.0, 6.0), 8.5, -90.0)
	_add_model_2d(b_root, "props/Chair_1.gltf", T.POKER_CHAIRS[2], 2.0, Vector2(6.0, 6.0), 8.5, 0.0)
	_add_model_2d(b_root, "props/Chair_1.gltf", T.POKER_CHAIRS[3], 2.0, Vector2(6.0, 6.0), 8.5, 180.0)
	# Montón de fichas de póker en el bote central y cartas frente a cada jugador
	_add_cyl_2d(b_root, gp + Vector2(-1.4, -0.8), 1.3, 9.8, 1.4, m_gold, 1.3, 8)
	_add_cyl_2d(b_root, gp + Vector2(1.5, 0.6), 1.3, 9.8, 1.1, m_chip_red, 1.3, 8)
	_add_cyl_2d(b_root, gp + Vector2(0.2, -1.6), 1.2, 9.8, 0.9, m_chip_blue, 1.2, 8)
	for c_off in [Vector2(-6.8, 0.0), Vector2(6.8, 0.0), Vector2(0.0, -6.8), Vector2(0.0, 6.8)]:
		_add_box_2d(b_root, gp + c_off, Vector2(2.6, 1.8), 9.8, 0.25, m_plate)

	# Mesa de Billar Real en 3D (sin usar Table_Large ni patas de cama)
	_build_billiard_table_3d(b_root, T.POOL_POS, m_dark_wood, m_wood, m_gold)
	_restaurant_light(b_root, Vector2(546.0, -178.0), 16.5, Color(1.0, 0.84, 0.50), 1.1, 2.4, false)

	# 6. Vestíbulo de Escalera y Bodega: Escalera física real de 12 peldaños (h = 2.0 -> 22.0) y rincón de la Trampilla del Club
	var num_steps: int = 12
	var stair_x: float = T.STAIRS_BOTTOM_POS.x
	var y_bot: float = T.STAIRS_BOTTOM_POS.y
	var y_top: float = T.STAIRS_TOP_POS.y
	var step_dy: float = (y_top - y_bot) / float(num_steps)
	var step_dh: float = (T.FLOOR_1_H - 2.0) / float(num_steps)
	for si in range(num_steps):
		var sy: float = y_bot + (float(si) + 0.5) * step_dy
		var sh: float = 2.0 + float(si) * step_dh
		# Zanca/contorno de soporte bajo el peldaño y huella de roble macizo
		_add_box_2d(b_root, Vector2(stair_x, sy), Vector2(24.0, absf(step_dy) + 0.8), 2.0, sh - 1.5, m_dark_wood)
		_add_box_2d(b_root, Vector2(stair_x, sy), Vector2(26.0, absf(step_dy) + 1.2), sh, step_dh + 0.5, m_wood)
		if (si % 2) == 0:
			for rail_side in [-13.0, 13.0]:
				_add_box_2d(b_root, Vector2(stair_x + rail_side, sy), Vector2(1.4, 1.4), sh + step_dh, 5.5, m_dark_wood)
				_add_box_2d(b_root, Vector2(stair_x + rail_side, sy), Vector2(1.8, absf(step_dy) * 2.2), sh + step_dh + 5.2, 1.1, m_trim)
	# Toneles y cajas de bodega flanqueando la trampilla del Club de la Lucha (516, -286)
	_add_model_2d(b_root, "props/Barrel.gltf", Vector2(498.0, -302.0), 2.0, Vector2(9.5, 9.5), 10.5)
	_add_model_2d(b_root, "props/Barrel.gltf", Vector2(534.0, -302.0), 2.0, Vector2(9.5, 9.5), 10.5)
	_add_model_2d(b_root, "props/Crate_Wooden.gltf", Vector2(498.0, -268.0), 2.0, Vector2(9.0, 9.0), 8.0)
	_restaurant_light(b_root, Vector2(526.0, -276.0), 15.5, Color(1.0, 0.64, 0.32), 0.9, 2.0, false)

## Construye una mesa de billar 3D auténtica: 4 patas torneadas de caoba con casquillos de latón, faldón perimetral,
## pizarra de paño verde esmeralda, 4 bandas de caoba con herrajes dorados, 6 troneras oscuras, triángulo de bolas de colores + blanca y 2 tacos.
func _build_billiard_table_3d(parent: Node3D, pos: Vector2, m_mahogany: Material, m_cue_wood: Material, m_brass: Material) -> void:
	_register_furniture_rect("BilliardTable", pos, Vector2(26.4, 16.8))
	var m_baize := _mat("billiard_baize_emerald", Color(0.08, 0.56, 0.30), 0.78, 0.02)
	var m_pocket := _mat("billiard_pocket_dark", Color(0.07, 0.06, 0.06), 0.92, 0.1)
	var m_cue_ball := _mat("billiard_ball_white", Color(0.97, 0.96, 0.92), 0.18, 0.08)
	var m_ball_yellow := _mat("billiard_ball_yellow", Color(0.95, 0.80, 0.14), 0.20, 0.08)
	var m_ball_blue := _mat("billiard_ball_blue", Color(0.14, 0.36, 0.86), 0.20, 0.08)
	var m_ball_red := _mat("billiard_ball_red", Color(0.86, 0.16, 0.16), 0.20, 0.08)
	var m_ball_eight := _mat("billiard_ball_eight", Color(0.08, 0.08, 0.10), 0.16, 0.12)
	var m_chalk := _mat("billiard_chalk_tip", Color(0.22, 0.58, 0.92), 0.70, 0.0)

	# 1. 4 patas torneadas de caoba con casquillo inferior de latón
	for lx in [-11.2, 11.2]:
		for ly in [-6.6, 6.6]:
			var lp: Vector2 = pos + Vector2(lx, ly)
			_add_cyl_2d(parent, lp, 1.35, 2.0, 1.2, m_brass, 1.15, 10)
			_add_cyl_2d(parent, lp, 1.85, 3.2, 3.8, m_mahogany, 1.30, 10)

	# 2. Faldón / bastidor de caoba maciza y lecho de pizarra con paño verde esmeralda
	_add_box_2d(parent, pos, Vector2(26.4, 16.8), 6.6, 2.1, m_mahogany)
	_add_box_2d(parent, pos, Vector2(23.8, 14.2), 8.7, 0.65, m_baize)
	# Línea de saque blanca sobre el paño
	_add_box_2d(parent, pos + Vector2(-5.8, 0.0), Vector2(0.35, 13.2), 9.36, 0.08, m_cue_ball)

	# 3. Bandas elevadas de caoba (divididas en los lados largos para dejar las 6 troneras) y cantoneras de latón
	for sy in [-7.6, 7.6]:
		_add_box_2d(parent, pos + Vector2(-5.6, sy), Vector2(9.2, 1.5), 8.9, 1.1, m_mahogany)
		_add_box_2d(parent, pos + Vector2(5.6, sy), Vector2(9.2, 1.5), 8.9, 1.1, m_mahogany)
	for sx in [-12.4, 12.4]:
		_add_box_2d(parent, pos + Vector2(sx, 0.0), Vector2(1.5, 11.6), 8.9, 1.1, m_mahogany)

	# 4. 6 Troneras (4 esquinas + 2 centrales) con embocadura de latón y hueco oscuro
	var pockets: Array[Vector2] = [
		Vector2(-11.8, -7.1), Vector2(11.8, -7.1),
		Vector2(-11.8, 7.1), Vector2(11.8, 7.1),
		Vector2(0.0, -7.4), Vector2(0.0, 7.4),
	]
	for pk in pockets:
		_add_cyl_2d(parent, pos + pk, 1.65, 8.85, 1.2, m_brass, 1.65, 10)
		_add_cyl_2d(parent, pos + pk * 0.94, 1.28, 8.95, 1.18, m_pocket, 1.28, 10)

	# 5. Bolas de billar sobre el paño: bola blanca en zona de saque + triángulo de bolas de colores en el punto de pie
	_add_cyl_2d(parent, pos + Vector2(-6.2, 0.6), 0.68, 9.35, 0.95, m_cue_ball, 0.62, 10)
	var rack_balls: Array = [
		[Vector2(3.6, 0.0), m_ball_yellow],
		[Vector2(5.0, -0.8), m_ball_blue],
		[Vector2(5.0, 0.8), m_ball_red],
		[Vector2(6.4, -1.5), m_ball_red],
		[Vector2(6.4, 0.0), m_ball_eight],
		[Vector2(6.4, 1.5), m_ball_yellow],
	]
	for rb in rack_balls:
		_add_cyl_2d(parent, pos + (rb[0] as Vector2), 0.68, 9.35, 0.95, rb[1] as Material, 0.62, 10)

	# 6. 2 Tacos de billar de madera con virola de tiza azul apoyados sobre las bandas
	_add_box_2d(parent, pos + Vector2(-2.0, -4.4), Vector2(15.5, 0.48), 10.05, 0.42, m_cue_wood, 14.0)
	_add_box_2d(parent, pos + Vector2(5.4, -2.5), Vector2(0.9, 0.48), 10.06, 0.44, m_chalk, 14.0)
	_add_box_2d(parent, pos + Vector2(-1.5, 4.8), Vector2(15.5, 0.48), 10.05, 0.42, m_cue_wood, -11.0)
	_add_box_2d(parent, pos + Vector2(5.9, 3.3), Vector2(0.9, 0.48), 10.06, 0.44, m_chalk, -11.0)

## Paso 3: Primer Piso (Planta +1, h = 22.0) de la Gran Taberna «El Jabalí Dorado»:
## galería con barandilla sobre el salón, pasillo superior y 5 cuartos de huéspedes con las 6 camas reales.
func _build_tavern_floor_1_3d(loft_root: Node3D, _wall_h: float, m_wall: Material, m_trim: Material, m_wood: Material, m_dark_wood: Material, _m_iron: Material, _m_gold: Material) -> void:
	var T = VillageTavern
	var h1: float = T.FLOOR_1_H # 22.0
	var ih1: float = 19.5
	var m_bed_red := _mat("tavern_bed_red", Color(0.82, 0.24, 0.22), 0.85, 0.0)
	var m_bed_gold := _mat("tavern_bed_gold", Color(0.84, 0.62, 0.22), 0.85, 0.0)
	var m_pillow := _mat("tavern_bed_pillow", Color(0.95, 0.93, 0.88), 0.85, 0.0)
	var m_rug := _mat("tavern_upper_rug", Color(0.52, 0.18, 0.16), 0.92, 0.0)

	# 1. Forjado de madera de la Planta +1 (deja libre el hueco de la escalera en x = 558..604, y = -290..-206 y el balcón sur en y = -168..-132)
	_add_box_2d(loft_root, Vector2(411.0, -241.0), Vector2(294.0, 146.0), h1 - 1.6, 1.6, m_wood)
	# Relleno del desembarco superior de la escalera (x = 558..604, y = -206..-168)
	_add_box_2d(loft_root, Vector2(581.0, -187.0), Vector2(46.0, 38.0), h1 - 1.6, 1.6, m_wood)
	# Alfombra larga del pasillo de la galería alta
	_add_box_2d(loft_root, Vector2(422.0, T.HALLWAY_Y), Vector2(280.0, 18.0), h1 + 0.1, 0.35, m_rug)

	# 2. Barandilla de madera de la galería alta (asomada al Gran Salón en y = -168.0) y barandilla del hueco de escalera
	_add_box_2d(loft_root, Vector2(434.0, -168.0), Vector2(340.0, 2.6), h1 + 5.2, 1.4, m_dark_wood)
	for bx in range(272, 602, 18):
		_add_box_2d(loft_root, Vector2(float(bx), -168.0), Vector2(1.8, 2.2), h1, 5.2, m_trim)
	_add_box_2d(loft_root, Vector2(558.0, -248.0), Vector2(2.4, 84.0), h1 + 5.2, 1.4, m_dark_wood)
	for by in [-284.0, -264.0, -244.0, -224.0, -208.0]:
		_add_box_2d(loft_root, Vector2(558.0, by), Vector2(2.0, 2.0), h1, 5.2, m_trim)

	# 3. Tabique del pasillo de los 5 dormitorios (y = -216.0, x = 264..558) con sus 5 puertas y dinteles
	var cur_x: float = 264.0
	for dx in T.BEDROOM_DOORS_X:
		var a: float = dx - 11.0
		if a - cur_x > 2.0:
			_add_box_2d(loft_root, Vector2((cur_x + a) * 0.5, -216.0), Vector2(a - cur_x, 5.0), h1, ih1, m_wall)
		_add_box_2d(loft_root, Vector2(dx, -216.0), Vector2(24.0, 5.2), h1 + ih1 * 0.76, ih1 * 0.24, m_trim)
		cur_x = dx + 11.0
	if 558.0 - cur_x > 2.0:
		_add_box_2d(loft_root, Vector2((cur_x + 558.0) * 0.5, -216.0), Vector2(558.0 - cur_x, 5.0), h1, ih1, m_wall)

	# Tabiques divisorios entre los 5 cuartos de huéspedes (y = -314..-216)
	for part_x in [374.0, 418.0, 452.0, 486.0, 558.0]:
		_add_box_2d(loft_root, Vector2(part_x, -265.0), Vector2(4.8, 98.0), h1, ih1, m_wall)

	# 4. Las 6 camas reales en Planta +1 (con mesillas, cofres y alfombras a los pies)
	for bi in range(T.ALL_UPPER_BEDS.size()):
		var bp: Vector2 = T.ALL_UPPER_BEDS[bi]
		var blanket_mat: Material = m_bed_gold if bi == 0 else m_bed_red
		_build_bed_3d_at_h(loft_root, bp, h1, m_wood, blanket_mat, m_pillow)
		_add_model_2d(loft_root, "props/Nightstand_Shelf.gltf", bp + Vector2(0.0, -16.0), h1, Vector2(7.0, 6.0), 7.5)
		_add_box_2d(loft_root, bp + Vector2(0.0, 14.0), Vector2(16.0, 10.0), h1 + 0.1, 0.3, m_rug)
	_add_model_2d(loft_root, "props/Chest_Wood.gltf", Vector2(520.0, -288.0), h1, Vector2(12.0, 8.0), 6.8)

# ==============================================================================
# 3. SOLARES VACÍOS Y OBRAS EN CONSTRUCCIÓN (`VillageLots.LOTS`)
# ==============================================================================
func rebuild_lots_3d() -> void:
	_clear_children(lots_root_3d)
	if vm == null:
		return
	var m_stake := _mat("lot_stake", Color(0.52, 0.36, 0.22), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_scaffold := _mat("lot_scaffold", Color(0.64, 0.48, 0.30), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.80)
	var m_found := _mat("lot_foundation", Color(0.56, 0.54, 0.50), 0.90, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)

	for l_entry in VillageLots.LOTS:
		var l_dict: Dictionary = l_entry
		var id: String = str(l_dict["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		var status: String = str(st.get("status", "empty"))
		if status == "built":
			continue
		var c: Vector2 = VillageLots.lot_def(id)["center"]
		var sz_l: Vector2 = l_dict["size"]
		var h: Vector2 = sz_l * 0.5 - Vector2(6, 6)
		if status == "empty":
			for p in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
				_add_box_2d(lots_root_3d, c + p, Vector2(3.5, 3.5), 0.0, 9.0, m_stake)
		elif status == "building":
			var prog: float = clampf(float(st.get("progress", 0.0)), 0.05, 1.0)
			_add_box_2d(lots_root_3d, c, Vector2(124, 92), 0.0, 2.5, m_found)
			var cur_h: float = 8.0 + 20.0 * prog
			for sx in [-56.0, 0.0, 56.0]:
				for sy in [-40.0, 40.0]:
					_add_box_2d(lots_root_3d, c + Vector2(sx, sy), Vector2(3.5, 3.5), 2.5, cur_h, m_scaffold)
			_add_box_2d(lots_root_3d, c + Vector2(0, -40.0), Vector2(118.0, 3.0), cur_h * 0.6, 2.5, m_scaffold)
			_add_box_2d(lots_root_3d, c + Vector2(0, 40.0), Vector2(118.0, 3.0), cur_h * 0.6, 2.5, m_scaffold)
			_add_model_2d(lots_root_3d, "props/Workbench.gltf", c + Vector2(-28.0, 0.0), 2.5, Vector2(24.0, 14.0), 8.0)

# ==============================================================================
# 4. ASENTAMIENTO FRONTERIZO «PUESTO DEL PASO» (EN EL LINDERO ESTE)
# ==============================================================================
func rebuild_outpost_3d() -> void:
	_clear_children(outpost_root_3d)
	if vm == null:
		return
	var op: Dictionary = VillageCulture.outpost_state(vm)
	var founded: bool = bool(op.get("founded", false))
	var upgs: Dictionary = op.get("upgrades", {})
	var c: Vector2 = VillageCulture.OUTPOST_CENTER
	var gate_p: Vector2 = VillageCulture.OUTPOST_GATE_POS

	var m_road := _mat("road_dirt", Color(0.46, 0.37, 0.25), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.35)
	var m_log := _mat("outpost_log", Color(0.55, 0.40, 0.26), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/floor_wood_planks.png", "", 0.45)
	var m_plank := _mat("outpost_plank", Color(0.68, 0.50, 0.32), 0.85, 0.02, Color.BLACK, 0.0, "town_textures/floor_wood_planks.png", "", 0.45)
	var m_stone := _mat("outpost_stone", Color(0.65, 0.64, 0.60), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)

	# Extensión del camino del este hasta el Puesto del Paso
	_add_box_2d(outpost_root_3d, Vector2(1512, 50), Vector2(72, 26), 0.0, 1.2, m_road)

	if not founded:
		# Solar fronterizo con estacas, mesa de planos y cartel
		for p in [Vector2(-64, -68), Vector2(64, -68), Vector2(64, 68), Vector2(-64, 68)]:
			_add_cyl_2d(outpost_root_3d, c + p, 2.5, 0.0, 11.0, m_log, 2.0, 8)
		_add_box_2d(outpost_root_3d, gate_p, Vector2(4.0, 4.0), 0.0, 16.0, m_log)
		_add_box_2d(outpost_root_3d, gate_p + Vector2(0, -2), Vector2(16.0, 3.0), 11.0, 5.0, m_plank)
		return

	# Explanada fortificada y empalizada de troncos 3D
	_add_box_2d(outpost_root_3d, c, Vector2(152, 164), 0.0, 1.5, m_stone)
	_add_box_2d(outpost_root_3d, c + Vector2(0, -80), Vector2(152, 6), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(0, 80), Vector2(152, 6), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(74, 0), Vector2(6, 164), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(-74, -50), Vector2(6, 60), 1.5, 22.0, m_log)
	_add_box_2d(outpost_root_3d, c + Vector2(-74, 50), Vector2(6, 60), 1.5, 22.0, m_log)
	# Pórtico de entrada en Vector2(1542, 50)
	_add_cyl_2d(outpost_root_3d, gate_p + Vector2(0, -20), 4.0, 1.5, 28.0, m_log, 3.5, 8)
	_add_cyl_2d(outpost_root_3d, gate_p + Vector2(0, 20), 4.0, 1.5, 28.0, m_log, 3.5, 8)
	_add_box_2d(outpost_root_3d, gate_p, Vector2(8.0, 44.0), 25.0, 5.0, m_plank)

	# Cabaña de mando 3D, Arca del asentamiento y Hoguera central encendida
	_add_model_2d(outpost_root_3d, "buildings/House_2.obj", c + Vector2(34, 0), 1.5, Vector2(50, 42), 34.0, -90.0)
	_add_model_2d(outpost_root_3d, "props/Chest_Wood.gltf", c + Vector2(6, 0), 1.5, Vector2(13, 9), 8.0, -90.0)
	_add_model_2d(outpost_root_3d, "exterior/Bonfire_Lit.obj", c + Vector2(-18, 0), 1.5, Vector2(16, 16), 11.0)
	_add_model_2d(outpost_root_3d, "props/Crate_Wooden.gltf", c + Vector2(14, 24), 1.5, Vector2(10, 10), 8.0)
	_add_model_2d(outpost_root_3d, "props/Barrel.gltf", c + Vector2(14, -24), 1.5, Vector2(9, 9), 9.5)
	if not _is_headless:
		var fire_lt := OmniLight3D.new()
		fire_lt.position = to_3d(c + Vector2(-18, 0), 12.0)
		fire_lt.light_color = Color(1.0, 0.65, 0.25)
		fire_lt.light_energy = 1.6
		fire_lt.omni_range = 3.2
		outpost_root_3d.add_child(fire_lt)

	# Mejora 1: Aserradero Fronterizo
	if bool(upgs.get("sawmill", false)):
		var sm_p := c + Vector2(-26, -50)
		_add_model_2d(outpost_root_3d, "buildings/Sawmill.obj", sm_p, 1.5, Vector2(48, 32), 28.0)
		_add_model_2d(outpost_root_3d, "nature/WoodLog.obj", sm_p + Vector2(22, 10), 1.5, Vector2(14, 8), 6.0)

	# Mejora 2: Granero / Molino del Paso
	if bool(upgs.get("granary", false)):
		var gr_p := c + Vector2(-26, 50)
		_add_model_2d(outpost_root_3d, "buildings/Mill.obj", gr_p, 1.5, Vector2(38, 38), 36.0)

	# Mejora 3: Atalaya de Guardia
	if bool(upgs.get("watchtower", false)):
		var wt_p := c + Vector2(-56, -56)
		_add_model_2d(outpost_root_3d, "buildings/Bell_Tower.obj", wt_p, 1.5, Vector2(30, 30), 48.0)

# ==============================================================================
# 5. TUMBAS DEL CEMENTERIO, ALCANTARILLAS (-1) Y FAROLAS CON LUZ REAL
# ==============================================================================
func rebuild_graves_3d() -> void:
	_clear_children(graves_root_3d)
	if vm == null:
		return
	_last_buried_count = vm.buried_graves.size()
	var m_mound := _mat("grave_earth", Color(0.36, 0.25, 0.16), 0.95, 0.0)
	var grave_models: Array[String] = [
		"graveyard/gravestone-cross.glb",
		"graveyard/gravestone-decorative.glb",
		"graveyard/gravestone-round.glb",
		"graveyard/cross-column.glb",
	]

	for i in range(vm.buried_graves.size()):
		var g_pos: Vector2 = vm._cemetery_burial_pos
		if i < vm._cemetery_grave_positions.size():
			g_pos = vm._cemetery_grave_positions[i]
		else:
			g_pos = Vector2(844.0 + float(i % 6) * 26.0, 282.0 + float(int(float(i) / 6.0) % 3) * 28.0)
		_add_box_2d(graves_root_3d, g_pos + Vector2(0, 3), Vector2(7.5, 8.5), 1.0, 1.8, m_mound)
		var g_mdl: String = grave_models[i % grave_models.size()]
		_add_model_2d(graves_root_3d, g_mdl, g_pos + Vector2(0, -4), 1.0, Vector2(6.8, 3.2), 8.8)

func _build_sewers_3d() -> void:
	_clear_children(sewers_root_3d)
	var m_bedrock := _mat("sewer_bedrock", Color(0.08, 0.10, 0.09), 0.96, 0.0)
	var m_brick := _mat("sewer_brick", Color(0.28, 0.34, 0.30), 0.90, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
	var m_walkway := _mat("sewer_walkway", Color(0.36, 0.40, 0.38), 0.88, 0.04, Color.BLACK, 0.0, "town_textures/rf_cobblestone.png", "", 0.45)
	var m_water := _mat("sewer_water", Color(0.14, 0.46, 0.36, 0.92), 0.25, 0.15, Color(0.10, 0.42, 0.30), 0.35)
	var m_iron := _mat("sewer_iron", Color(0.24, 0.27, 0.32), 0.42, 0.78)
	var m_wood := _mat("sewer_wood", Color(0.46, 0.30, 0.16), 0.85, 0.04)
	var m_brass := _mat("sewer_brass", Color(0.90, 0.74, 0.26), 0.28, 0.85, Color(0.85, 0.68, 0.20), 0.45)
	var m_torch := _mat("sewer_torch", Color(1.0, 0.76, 0.32), 0.20, 0.0, Color(1.0, 0.68, 0.22), 2.8)

	var sy: float = VillageUnderworldScript.SEWER_Y
	# Losa oscura de roca subterránea para cubrir el entorno exterior alrededor de la red de túneles bajo el pueblo (y = SEWER_Y)
	_add_box_2d(sewers_root_3d, Vector2(420.0, sy), Vector2(720.0, 320.0), 1.2, 0.8, m_bedrock)

	# 3 cámaras conectadas bajo el centro del pueblo: Bóveda Inundada (260, SEWER_Y), Pasadizo del Contrabandista (420, SEWER_Y) y Cisterna (580, SEWER_Y)
	for loc_id in ["flooded_vault", "smuggler_tunnel", "cistern"]:
		var def: Dictionary = VillageUnderworldScript.SEWER_LOCATIONS[loc_id]
		var ch_p: Vector2 = def["chamber_center"]
		var lad_p: Vector2 = def["ladder_pos"]
		var chs_p: Vector2 = def["chest_pos"]

		# Suelo de piedra, andén seco norte y canal de aguas turbias al sur
		_add_box_2d(sewers_root_3d, ch_p, Vector2(110.0, 80.0), 2.0, 1.4, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, -8.0), Vector2(106.0, 56.0), 3.4, 1.2, m_walkway)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, 26.0), Vector2(106.0, 18.0), 2.6, 1.0, m_water)

		# Muro norte alto y zócalo sur bajo (para que la cámara isométrica vea el interior sin tapar al jugador)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, -43.0), Vector2(116.0, 6.0), 3.0, 20.0, m_brick)
		_add_box_2d(sewers_root_3d, ch_p + Vector2(0.0, 43.0), Vector2(116.0, 6.0), 3.0, 5.0, m_brick)

		# Escalerilla 3D de salida a la calle junto a la boca del túnel
		_add_box_2d(sewers_root_3d, lad_p + Vector2(0.0, -2.0), Vector2(11.0, 8.0), 4.6, 0.8, m_iron)
		_add_box_2d(sewers_root_3d, lad_p + Vector2(-4.0, -10.0), Vector2(1.4, 2.0), 4.6, 20.0, m_iron)
		_add_box_2d(sewers_root_3d, lad_p + Vector2(4.0, -10.0), Vector2(1.4, 2.0), 4.6, 20.0, m_iron)
		for rung_i in range(6):
			_add_box_2d(sewers_root_3d, lad_p + Vector2(0.0, -10.0), Vector2(8.0, 1.2), 6.5 + float(rung_i) * 3.0, 0.9, m_brass)

		# Antorcha mural subterránea junto a la escalerilla
		_add_cyl_2d(sewers_root_3d, lad_p + Vector2(12.0, -13.0), 1.4, 13.0, 5.0, m_wood, 1.0, 6)
		_add_cyl_2d(sewers_root_3d, lad_p + Vector2(12.0, -13.0), 2.2, 18.0, 3.0, m_torch, 1.4, 8)
		if not _is_headless:
			var t_light := OmniLight3D.new()
			t_light.position = to_3d(lad_p + Vector2(12.0, -8.0), 19.0)
			t_light.light_color = Color(1.0, 0.78, 0.42)
			t_light.light_energy = 1.35
			t_light.omni_range = 3.2
			sewers_root_3d.add_child(t_light)

		# Cofre de contrabando 3D sobre losa de piedra + barriles y cajas de alijo
		_add_box_2d(sewers_root_3d, chs_p, Vector2(16.0, 12.0), 4.6, 1.4, m_brick)
		if _add_model_2d(sewers_root_3d, "props/Chest_Wood.gltf", chs_p, 6.0, Vector2(13.0, 9.5), 8.5) == null:
			_add_box_2d(sewers_root_3d, chs_p, Vector2(13.0, 9.0), 6.0, 5.5, m_wood)
			_add_box_2d(sewers_root_3d, chs_p, Vector2(13.4, 9.4), 11.5, 2.5, m_iron)
		_add_box_2d(sewers_root_3d, chs_p + Vector2(0.0, 4.6), Vector2(2.4, 1.4), 8.5, 2.6, m_brass)
		_add_model_2d(sewers_root_3d, "props/Barrel.gltf", ch_p + Vector2(-38.0, 6.0), 4.6, Vector2(9.0, 9.0), 9.5)
		_add_model_2d(sewers_root_3d, "props/Crate_Wooden.gltf", ch_p + Vector2(38.0, 6.0), 4.6, Vector2(11.0, 11.0), 8.5)

	# 2 galerías de conexión entre las 3 cámaras (x = 340 y x = 500) y muros laterales de cierre
	for corr_x in [340.0, 500.0]:
		var cp := Vector2(corr_x, sy)
		_add_box_2d(sewers_root_3d, cp, Vector2(56.0, 42.0), 2.0, 2.4, m_walkway)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, 14.0), Vector2(56.0, 10.0), 2.6, 1.0, m_water)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, -23.0), Vector2(56.0, 6.0), 3.0, 18.0, m_brick)
		_add_box_2d(sewers_root_3d, cp + Vector2(0.0, 23.0), Vector2(56.0, 6.0), 3.0, 5.0, m_brick)
	for sx in [315.0, 365.0, 475.0, 525.0]:
		_add_box_2d(sewers_root_3d, Vector2(sx, sy - 32.0), Vector2(6.0, 22.0), 3.0, 20.0, m_brick)
		_add_box_2d(sewers_root_3d, Vector2(sx, sy + 32.0), Vector2(6.0, 22.0), 3.0, 5.0, m_brick)
	_add_box_2d(sewers_root_3d, Vector2(202.0, sy), Vector2(6.0, 86.0), 3.0, 20.0, m_brick)
	_add_box_2d(sewers_root_3d, Vector2(638.0, sy), Vector2(6.0, 86.0), 3.0, 20.0, m_brick)

func _add_green_crt_terminal_3d(parent: Node3D, pos_2d: Vector2, base_h: float, face_north: bool = false) -> void:
	var m_crt_case := _mat("crt_case_iron", Color(0.18, 0.21, 0.20), 0.55, 0.72)
	var m_crt_bezel := _mat("crt_bezel_dark", Color(0.10, 0.12, 0.11), 0.65, 0.35)
	var m_crt_green := _mat("crt_screen_green", Color(0.12, 0.96, 0.34), 0.15, 0.0, Color(0.10, 0.92, 0.30), 3.4)
	var m_crt_line := _mat("crt_scanline", Color(0.42, 1.0, 0.58), 0.10, 0.0, Color(0.32, 0.98, 0.48), 4.2)
	var dir_y: float = -1.0 if face_north else 1.0
	# Monitor CRT robusto con chasis metálico y pantalla de fósforo verde
	_add_box_2d(parent, pos_2d + Vector2(0, -1.2 * dir_y), Vector2(11.0, 8.2), base_h, 8.6, m_crt_case)
	_add_box_2d(parent, pos_2d + Vector2(0, 2.2 * dir_y), Vector2(9.6, 2.0), base_h + 0.8, 7.0, m_crt_bezel)
	_add_box_2d(parent, pos_2d + Vector2(0, 2.9 * dir_y), Vector2(8.2, 1.0), base_h + 1.4, 5.6, m_crt_green)
	# Líneas de texto fosforescentes en la pantalla
	for ly in [2.4, 3.8, 5.2]:
		_add_box_2d(parent, pos_2d + Vector2(-0.8, 3.3 * dir_y), Vector2(5.6, 0.4), base_h + ly, 0.45, m_crt_line)
	# Teclado mecánico delantero
	_add_box_2d(parent, pos_2d + Vector2(0, 5.0 * dir_y), Vector2(10.2, 3.6), base_h, 1.4, m_crt_case)
	_add_box_2d(parent, pos_2d + Vector2(0, 5.0 * dir_y), Vector2(8.8, 2.4), base_h + 1.2, 0.5, m_crt_bezel)
	if not _is_headless:
		var crt_lt := OmniLight3D.new()
		crt_lt.position = to_3d(pos_2d + Vector2(0, 4.0 * dir_y), base_h + 5.0)
		crt_lt.light_color = Color(0.16, 0.96, 0.38)
		crt_lt.light_energy = 1.15
		crt_lt.omni_range = 2.4
		parent.add_child(crt_lt)

func _add_sandbag_wire_barrier_3d(parent: Node3D, pos_2d: Vector2) -> void:
	var m_bag := _mat("epoch_sandbag", Color(0.50, 0.43, 0.31), 0.95, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.8)
	var m_stake := _mat("epoch_stake_wood", Color(0.30, 0.20, 0.12), 0.90, 0.0)
	var m_wire := _mat("epoch_barbed_wire", Color(0.24, 0.25, 0.27), 0.48, 0.82)
	# Dos hileras escalonadas de sacos terreros
	for bx in [-7.5, -2.5, 2.5, 7.5]:
		_add_box_2d(parent, pos_2d + Vector2(bx, 1.2), Vector2(4.8, 3.4), 0.0, 2.4, m_bag)
		_add_box_2d(parent, pos_2d + Vector2(bx, -1.2), Vector2(4.8, 3.4), 0.0, 2.4, m_bag)
	for bx2 in [-5.0, 0.0, 5.0]:
		_add_box_2d(parent, pos_2d + Vector2(bx2, 0.0), Vector2(4.8, 3.6), 2.3, 2.3, m_bag)
	for bx3 in [-2.5, 2.5]:
		_add_box_2d(parent, pos_2d + Vector2(bx3, 0.0), Vector2(4.6, 3.2), 4.5, 2.0, m_bag)
	# Caballetes en X y rollos de alambre de espino encima y delante
	for sx in [-8.5, 0.0, 8.5]:
		_add_cyl_2d(parent, pos_2d + Vector2(sx, -2.8), 0.65, 0.0, 8.2, m_stake, 0.55, 6)
		_add_cyl_2d(parent, pos_2d + Vector2(sx, 2.8), 0.65, 0.0, 8.2, m_stake, 0.55, 6)
	for wy in [5.2, 6.8, 8.0]:
		_add_box_2d(parent, pos_2d, Vector2(21.0, 0.45), wy, 0.45, m_wire)
	for cx in [-7.0, -3.5, 0.0, 3.5, 7.0]:
		_add_cyl_2d(parent, pos_2d + Vector2(cx, 2.4), 2.2, 2.2, 3.8, m_wire, 2.2, 8)

func _add_floodlight_tower_3d(parent: Node3D, pos_2d: Vector2, target_2d: Vector2, m_bulb_warm: Material, m_bulb_voltaic: Material) -> void:
	var m_pole := _mat("epoch_pole_wood", Color(0.28, 0.19, 0.11), 0.90, 0.0)
	var m_hood := _mat("epoch_hood_iron", Color(0.16, 0.18, 0.21), 0.45, 0.82)
	# Poste alto de madera con cruceta y carcasa de proyector metálico
	_add_cyl_2d(parent, pos_2d, 2.2, 0.0, 35.0, m_pole, 1.5, 8)
	_add_box_2d(parent, pos_2d, Vector2(7.5, 2.2), 31.5, 1.8, m_pole)
	var dir_2d: Vector2 = (target_2d - pos_2d).normalized()
	var head_2d: Vector2 = pos_2d + dir_2d * 2.8
	_add_box_2d(parent, head_2d, Vector2(5.2, 5.2), 33.0, 4.2, m_hood)
	var bulb := _add_cyl_2d(parent, head_2d + dir_2d * 1.6, 2.1, 33.4, 2.6, m_bulb_warm, 2.1, 8)
	var spot: SpotLight3D = null
	var pool: OmniLight3D = null
	if not _is_headless:
		spot = SpotLight3D.new()
		spot.position = to_3d(head_2d, 34.5)
		var tgt_3d: Vector3 = to_3d(target_2d, 0.5)
		spot.spot_range = 9.5
		spot.spot_angle = 42.0
		spot.light_energy = 2.8
		spot.light_color = Color(1.0, 0.90, 0.62)
		parent.add_child(spot)
		if spot.position.distance_to(tgt_3d) > 0.05:
			spot.look_at_from_position(spot.position, tgt_3d, Vector3.UP)
		pool = OmniLight3D.new()
		pool.position = to_3d(pos_2d.lerp(target_2d, 0.55), 10.0)
		pool.omni_range = 5.4
		pool.light_energy = 1.65
		pool.light_color = Color(1.0, 0.88, 0.56)
		parent.add_child(pool)
	_floodlight_nodes_3d.append({
		"bulb": bulb,
		"spot": spot,
		"pool": pool,
		"mat_warm": m_bulb_warm,
		"mat_voltaic": m_bulb_voltaic,
	})

func _build_epoch_props_3d(m_bulb_warm: Material, m_bulb_voltaic: Material) -> void:
	var m_cable := _mat("epoch_thick_cable", Color(0.08, 0.09, 0.11), 0.72, 0.25)
	var m_insul := _mat("epoch_insulator", Color(0.76, 0.78, 0.74), 0.35, 0.10)
	var m_gen_iron := _mat("epoch_gen_iron", Color(0.18, 0.21, 0.22), 0.48, 0.78)
	var m_gen_rust := _mat("epoch_gen_rust", Color(0.38, 0.24, 0.16), 0.75, 0.45)
	var m_brass := _mat("epoch_gen_brass", Color(0.82, 0.64, 0.22), 0.35, 0.85)
	var m_pad := _mat("epoch_gen_pad", Color(0.44, 0.43, 0.40), 0.92, 0.0)

	# 1. Generador diésel junto al muro este del Taller de Reparaciones (e5: Vector2(1316, 126))
	var gp: Vector2 = VillageCulture.TINKER_GENERATOR_POS
	_add_box_2d(streetlights_root_3d, gp, Vector2(18.0, 24.0), 0.0, 2.2, m_pad) # Losa de hormigón
	_add_box_2d(streetlights_root_3d, gp, Vector2(13.5, 18.0), 2.2, 11.5, m_gen_iron) # Bloque motor diésel
	_add_box_2d(streetlights_root_3d, gp + Vector2(0.0, -3.5), Vector2(11.0, 9.0), 13.7, 3.8, m_gen_rust) # Culata con aletas
	_add_cyl_2d(streetlights_root_3d, gp + Vector2(0.0, 5.2), 4.2, 13.5, 6.2, m_gen_rust, 4.2, 10) # Depósito de gasóleo
	_add_cyl_2d(streetlights_root_3d, gp + Vector2(-5.5, -2.0), 4.4, 5.5, 3.0, m_brass, 4.4, 12) # Volante de inercia / alternador
	_add_cyl_2d(streetlights_root_3d, gp + Vector2(5.2, -6.5), 1.1, 13.0, 17.5, m_gen_iron, 1.1, 8) # Tubo de escape vertical
	_add_cyl_2d(streetlights_root_3d, gp + Vector2(5.2, -6.5), 2.0, 21.0, 5.5, m_gen_rust, 2.0, 8) # Silenciador

	# 2. Cables gruesos por las fachadas del Taller (e5), Comisaría y Ayuntamiento hasta el generador
	# Taller (e5: rect x=1166..1304, y=90..194): desde el generador (1316, 126) por el muro este y fachada norte hasta el cuadro eléctrico (1270, 90)
	_add_box_2d(streetlights_root_3d, Vector2(1310.0, 122.0), Vector2(12.0, 1.8), 11.0, 1.8, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(1304.8, 106.0), Vector2(1.8, 34.0), 11.0, 1.8, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(1304.8, 90.0), Vector2(1.8, 2.2), 11.0, 14.5, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(1240.0, 89.2), Vector2(130.0, 1.8), 24.0, 1.6, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(1240.0, 89.2), Vector2(130.0, 1.5), 21.2, 1.4, m_cable)
	for ix_t in [1182.0, 1212.0, 1270.0, 1300.0]:
		_add_cyl_2d(streetlights_root_3d, Vector2(ix_t, 88.5), 1.1, 23.5, 2.6, m_insul, 1.1, 6)

	# Comisaría (building_police: rect x=844..986, y=100..196): cables gruesos por la fachada norte y esquina este hasta el poste del foco
	_add_box_2d(streetlights_root_3d, Vector2(915.0, 99.2), Vector2(140.0, 1.8), 24.5, 1.6, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(915.0, 99.2), Vector2(140.0, 1.5), 21.5, 1.4, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(986.8, 136.0), Vector2(1.8, 72.0), 23.0, 1.6, m_cable)
	_add_box_2d(streetlights_root_3d, Vector2(936.0, 99.0), Vector2(1.6, 1.8), 12.0, 12.5, m_cable) # Bajante hacia la terminal policial
	_add_box_2d(streetlights_root_3d, Vector2(990.0, 97.5), Vector2(9.0, 1.6), 24.5, 1.6, m_cable) # Ramal al poste del foco
	for ix_p in [852.0, 886.0, 944.0, 980.0]:
		_add_cyl_2d(streetlights_root_3d, Vector2(ix_p, 98.5), 1.1, 24.0, 2.6, m_insul, 1.1, 6)

	# Ayuntamiento (building_town_hall: rect x=695..825, y=-468..-372): cables gruesos por la fachada sur y muro oeste hacia la terminal
	if vm != null and VillageCulture.VillageLots.lot(vm, "n4").get("kind", "") == "town_hall":
		_add_box_2d(streetlights_root_3d, Vector2(760.0, -371.2), Vector2(128.0, 1.8), 24.5, 1.6, m_cable)
		_add_box_2d(streetlights_root_3d, Vector2(760.0, -371.2), Vector2(128.0, 1.5), 21.5, 1.4, m_cable)
		_add_box_2d(streetlights_root_3d, Vector2(694.2, -412.0), Vector2(1.8, 82.0), 23.0, 1.6, m_cable)
		_add_box_2d(streetlights_root_3d, Vector2(716.0, -371.0), Vector2(1.6, 1.8), 11.0, 13.5, m_cable)
		for ix_th in [704.0, 734.0, 786.0, 816.0]:
			_add_cyl_2d(streetlights_root_3d, Vector2(ix_th, -370.5), 1.1, 24.0, 2.6, m_insul, 1.1, 6)

	# 3. Sacos terreros y alambre de espino a la entrada de la Comisaría (dejando libre la puerta x=893..937) y en el Puesto del Paso
	_add_sandbag_wire_barrier_3d(streetlights_root_3d, Vector2(864.0, 92.0))
	_add_sandbag_wire_barrier_3d(streetlights_root_3d, Vector2(966.0, 92.0))
	_add_sandbag_wire_barrier_3d(streetlights_root_3d, Vector2(1528.0, 22.0))
	_add_sandbag_wire_barrier_3d(streetlights_root_3d, Vector2(1528.0, 78.0))

	# 4. Focos en poste de madera en la Comisaría y en el Puesto del Paso (se apagan si se sabotea la red eléctrica)
	_add_floodlight_tower_3d(streetlights_root_3d, Vector2(994.0, 96.0), Vector2(915.0, 62.0), m_bulb_warm, m_bulb_voltaic)
	_add_floodlight_tower_3d(streetlights_root_3d, Vector2(1538.0, 18.0), Vector2(1506.0, 50.0), m_bulb_warm, m_bulb_voltaic)

func _build_streetlights_3d() -> void:
	_clear_children(streetlights_root_3d)
	_streetlight_nodes_3d.clear()
	_floodlight_nodes_3d.clear()
	if vm == null:
		return
	var m_bulb_warm := _mat("bulb_warm", Color(1.0, 0.88, 0.52), 0.2, 0.0, Color(1.0, 0.82, 0.40), 2.8)
	var m_bulb_voltaic := _mat("bulb_voltaic", Color(0.55, 0.96, 1.0), 0.2, 0.0, Color(0.45, 0.92, 1.0), 3.4)

	for sl in vm.streetlights:
		var spr: Sprite2D = sl.get("sprite")
		var pos: Vector2 = spr.global_position if is_instance_valid(spr) else Vector2.ZERO
		_add_model_2d(streetlights_root_3d, "graveyard/lightpost-single.glb", pos, 0.0, Vector2(9.0, 9.0), 29.0)
		var bulb := _add_cyl_2d(streetlights_root_3d, pos + Vector2(3.5, 0), 2.2, 23.0, 3.6, m_bulb_warm, 1.6, 8)
		var omni: OmniLight3D = null
		if not _is_headless:
			omni = OmniLight3D.new()
			omni.position = to_3d(pos + Vector2(3.5, 0), 24.0)
			omni.omni_range = 4.8
			omni.light_energy = 1.65
			omni.light_color = Color(1.0, 0.86, 0.52)
			streetlights_root_3d.add_child(omni)
		_streetlight_nodes_3d.append({
			"bulb": bulb,
			"light": omni,
			"mat_warm": m_bulb_warm,
			"mat_voltaic": m_bulb_voltaic,
		})
	_build_epoch_props_3d(m_bulb_warm, m_bulb_voltaic)

# ==============================================================================
# 6. SINCRONIZACIÓN EN VIVO (CÁMARA 3D, PUERTAS, TEJADOS CUTAWAY Y TECLA [F10])
# ==============================================================================
func _setup_fp_hud_layer() -> void:
	if _is_headless:
		return
	fp_hud_layer = CanvasLayer.new()
	fp_hud_layer.name = "FirstPersonHUDLayer"
	fp_hud_layer.layer = 2
	fp_hud_layer.visible = false
	add_child(fp_hud_layer)

	var root_ctrl := Control.new()
	root_ctrl.name = "FPHUDRoot"
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fp_hud_layer.add_child(root_ctrl)

	_fp_damage_vignette = ColorRect.new()
	_fp_damage_vignette.name = "FPDamageVignette"
	_fp_damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fp_damage_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fp_damage_vignette.color = Color(0.75, 0.08, 0.06, 0.0)
	_fp_damage_vignette.visible = false
	root_ctrl.add_child(_fp_damage_vignette)

	_fp_hit_flash_rect = ColorRect.new()
	_fp_hit_flash_rect.name = "FPHitConfirmFlash"
	_fp_hit_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fp_hit_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_fp_hit_flash_rect.position = Vector2(-14, -14)
	_fp_hit_flash_rect.size = Vector2(28, 28)
	_fp_hit_flash_rect.color = Color(1.0, 0.88, 0.42, 0.0)
	_fp_hit_flash_rect.visible = false
	root_ctrl.add_child(_fp_hit_flash_rect)

	fp_crosshair = Control.new()
	fp_crosshair.name = "FPCrosshair"
	fp_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fp_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root_ctrl.add_child(fp_crosshair)
	for rect_def in [
		[Rect2(-7, -1.5, 14, 3), Color(0.05, 0.06, 0.08, 0.85)],
		[Rect2(-1.5, -7, 3, 14), Color(0.05, 0.06, 0.08, 0.85)],
		[Rect2(-6, -0.5, 12, 1), Color(0.98, 0.96, 0.86, 0.95)],
		[Rect2(-0.5, -6, 1, 12), Color(0.98, 0.96, 0.86, 0.95)],
	]:
		var cr := ColorRect.new()
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.position = rect_def[0].position
		cr.size = rect_def[0].size
		cr.color = rect_def[1]
		fp_crosshair.add_child(cr)

	fp_interact_label = Label.new()
	fp_interact_label.name = "FPInteractLabel"
	fp_interact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fp_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fp_interact_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	fp_interact_label.position = Vector2(-220, 18)
	fp_interact_label.custom_minimum_size = Vector2(440, 24)
	fp_interact_label.add_theme_font_size_override("font_size", 14)
	fp_interact_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72))
	fp_interact_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 0.95))
	fp_interact_label.add_theme_constant_override("outline_size", 4)
	fp_interact_label.visible = false
	root_ctrl.add_child(fp_interact_label)

	fp_mode_badge = Label.new()
	fp_mode_badge.name = "FPModeBadge"
	fp_mode_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fp_mode_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fp_mode_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	fp_mode_badge.position = Vector2(-260, 40)
	fp_mode_badge.custom_minimum_size = Vector2(520, 20)
	fp_mode_badge.add_theme_font_size_override("font_size", 11)
	fp_mode_badge.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98, 0.88))
	fp_mode_badge.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 0.92))
	fp_mode_badge.add_theme_constant_override("outline_size", 3)
	fp_mode_badge.text = ""
	fp_mode_badge.visible = false
	root_ctrl.add_child(fp_mode_badge)

func _is_ui_blocking_fp() -> bool:
	if not is_inside_tree():
		return false
	var pl := get_tree().get_first_node_in_group("player")
	if is_instance_valid(pl):
		if pl.has_method("is_any_ui_modal_open") and pl.call("is_any_ui_modal_open") == true:
			return true
		var dm = pl.get("dialogue_manager")
		if dm and dm.has_method("is_active") and dm.call("is_active") == true:
			return true
	return false

func toggle_first_person() -> bool:
	set_first_person(not first_person_active)
	return first_person_active

func set_first_person(enable: bool) -> void:
	if enable:
		if not CharacterAvatar3DScript.use_3d_characters:
			CharacterAvatar3DScript.use_3d_characters = true
			_last_use_3d = true
			_sync_2d_flat_visuals(true)
		first_person_active = true
		fp_pitch = 0.0
		_fp_shake_timer = 0.0
		_fp_shake_amp = 0.0
		_fp_camera_punch_pitch = 0.0
		_fp_camera_punch_roll = 0.0
		var pl := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
		if is_instance_valid(pl):
			var c_ctrl = pl.get_node_or_null("PlayerCombatController")
			if c_ctrl != null and c_ctrl.get("current_aim_dir") is Vector2 and (c_ctrl.get("current_aim_dir") as Vector2).length_squared() > 0.01:
				fp_yaw = (c_ctrl.get("current_aim_dir") as Vector2).angle()
			else:
				match str(pl.get("last_dir")):
					"right": fp_yaw = 0.0
					"left": fp_yaw = PI
					"up": fp_yaw = -PI * 0.5
					_: fp_yaw = PI * 0.5
		_sync_player_aim_from_fp()
		_update_fp_camera_transform()
		_update_roof_cutaways_and_lighting()
		if not _is_headless:
			if is_instance_valid(sub_viewport):
				sub_viewport.transparent_bg = false
			if is_instance_valid(stage_sprite):
				stage_sprite.z_index = 120
			if is_instance_valid(fp_hud_layer):
				fp_hud_layer.visible = true
			if not _is_ui_blocking_fp():
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if is_instance_valid(pl) and pl.has_method("show_hint"):
			pl.call("show_hint", "👁️ Vista en 1.ª persona activada ([P] o [F6] para salir)")
	else:
		first_person_active = false
		fp_pitch = 0.0
		if cam_3d != null:
			cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
			cam_3d.near = 0.1
			cam_3d.far = 250.0
		if not _is_headless:
			if is_instance_valid(sub_viewport):
				sub_viewport.transparent_bg = true
			if is_instance_valid(world_env) and world_env.environment != null:
				world_env.environment.background_mode = Environment.BG_CLEAR_COLOR
				world_env.environment.fog_enabled = false
			if is_instance_valid(stage_sprite):
				stage_sprite.z_index = -2
			if is_instance_valid(fp_hud_layer):
				fp_hud_layer.visible = false
			if is_instance_valid(fp_lantern_light):
				fp_lantern_light.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if _is_ui_blocking_fp() else Input.MOUSE_MODE_HIDDEN)
		_sync_player_aim_from_fp()
		_sync_camera_with_2d()
		_update_roof_cutaways_and_lighting()
		var pl2 := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
		if is_instance_valid(pl2) and pl2.has_method("show_hint"):
			pl2.call("show_hint", "🎥 [P/F6] Vista superior 2.5D restaurada ([F9] alterna 3D/2D)")

func rotate_first_person_view(delta_x_px: float, delta_y_px: float = 0.0) -> void:
	fp_yaw = wrapf(fp_yaw + delta_x_px * FP_MOUSE_SENS, -PI, PI)
	fp_pitch = clampf(fp_pitch - delta_y_px * FP_MOUSE_SENS, -FP_MAX_PITCH, FP_MAX_PITCH)
	_sync_player_aim_from_fp()
	_update_fp_camera_transform()

func _sync_player_aim_from_fp() -> void:
	if not is_inside_tree():
		return
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(pl):
		return
	var av = pl.get("avatar_3d")
	if av != null and is_instance_valid(av.get("_holder")):
		(av.get("_holder") as Node3D).visible = not first_person_active
	if not first_person_active:
		return
	var dir_2d: Vector2 = get_fp_forward_2d()
	var c_ctrl = pl.get_node_or_null("PlayerCombatController")
	if c_ctrl != null and not (c_ctrl.get("_swing_locked") == true):
		c_ctrl.current_aim_dir = dir_2d
		var wp = c_ctrl.get("weapon_pivot")
		if is_instance_valid(wp):
			(wp as Node2D).rotation = dir_2d.angle()
	var ch = pl.get_node_or_null("Crosshair2D")
	if ch != null:
		var dist: float = 75.0 if (ch.get("is_ranged_mode") == true) else 42.0
		ch.aim_offset = dir_2d * dist
		ch.global_position = pl.global_position + Vector2(0, -10) + dir_2d * dist
	if absf(dir_2d.x) >= absf(dir_2d.y):
		pl.last_dir = "right" if dir_2d.x >= 0.0 else "left"
	else:
		pl.last_dir = "down" if dir_2d.y >= 0.0 else "up"

func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _setup_fp_viewmodel() -> void:
	if cam_3d == null or _is_headless:
		return
	_fp_viewmodel_root = Node3D.new()
	_fp_viewmodel_root.name = "FPViewmodelRoot"
	_fp_viewmodel_root.visible = false
	cam_3d.add_child(_fp_viewmodel_root)

	var mat_sleeve := _mat("fp_vm_sleeve", Color(0.24, 0.22, 0.19), 0.90)
	var mat_cuff := _mat("fp_vm_cuff", Color(0.36, 0.26, 0.17), 0.85)
	var mat_skin := _mat("fp_vm_skin", Color(0.84, 0.67, 0.54), 0.78)
	var mat_steel := _mat("fp_vm_steel", Color(0.74, 0.77, 0.82), 0.35, 0.65)
	var mat_dark_iron := _mat("fp_vm_iron", Color(0.26, 0.28, 0.31), 0.50, 0.55)
	var mat_wood := _mat("fp_vm_wood", Color(0.44, 0.29, 0.16), 0.86)
	var mat_gold := _mat("fp_vm_gold", Color(0.76, 0.62, 0.26), 0.42, 0.55)

	# Brazo izquierdo (guardia / equilibrio / arco)
	_fp_left_arm = Node3D.new()
	_fp_left_arm.name = "FPLeftArm"
	_fp_left_arm.position = Vector3(-0.22, -0.21, -0.34)
	_fp_left_arm.rotation_degrees = Vector3(18.0, 16.0, -14.0)
	_fp_viewmodel_root.add_child(_fp_left_arm)
	_add_box(_fp_left_arm, Vector3(0.072, 0.072, 0.22), Vector3(0.0, 0.0, 0.08), mat_sleeve)
	_add_box(_fp_left_arm, Vector3(0.076, 0.076, 0.045), Vector3(0.0, 0.0, -0.03), mat_cuff)
	_add_box(_fp_left_arm, Vector3(0.064, 0.058, 0.085), Vector3(0.0, 0.0, -0.09), mat_skin)

	# Brazo derecho (empuña el arma activa)
	_fp_right_arm = Node3D.new()
	_fp_right_arm.name = "FPRightArm"
	_fp_right_arm.position = Vector3(0.23, -0.20, -0.36)
	_fp_right_arm.rotation_degrees = Vector3(14.0, -14.0, 10.0)
	_fp_viewmodel_root.add_child(_fp_right_arm)
	_add_box(_fp_right_arm, Vector3(0.075, 0.075, 0.24), Vector3(0.0, 0.0, 0.09), mat_sleeve)
	_add_box(_fp_right_arm, Vector3(0.079, 0.079, 0.048), Vector3(0.0, 0.0, -0.03), mat_cuff)
	_add_box(_fp_right_arm, Vector3(0.066, 0.062, 0.09), Vector3(0.0, 0.0, -0.095), mat_skin)

	_fp_weapon_mount = Node3D.new()
	_fp_weapon_mount.name = "FPWeaponMount"
	_fp_weapon_mount.position = Vector3(0.0, 0.01, -0.11)
	_fp_right_arm.add_child(_fp_weapon_mount)

	# Estela luminosa de golpe (solo visible durante la fase "active" del tajo/maza)
	_fp_swing_trail = MeshInstance3D.new()
	var tr_box := BoxMesh.new()
	tr_box.size = Vector3(0.018, 0.42, 0.14)
	_fp_swing_trail.mesh = tr_box
	_fp_swing_trail.position = Vector3(-0.04, 0.22, -0.04)
	var mat_trail := StandardMaterial3D.new()
	mat_trail.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_trail.albedo_color = Color(1.0, 0.94, 0.72, 0.55)
	mat_trail.emission_enabled = true
	mat_trail.emission = Color(1.0, 0.86, 0.48)
	mat_trail.emission_energy_multiplier = 1.6
	mat_trail.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fp_swing_trail.material_override = mat_trail
	_fp_swing_trail.visible = false
	_fp_weapon_mount.add_child(_fp_swing_trail)

	# 1. Espada ("sword")
	var w_sword := Node3D.new()
	_add_box(w_sword, Vector3(0.028, 0.11, 0.032), Vector3(0.0, -0.02, 0.0), mat_wood)
	_add_box(w_sword, Vector3(0.038, 0.028, 0.038), Vector3(0.0, -0.08, 0.0), mat_gold)
	_add_box(w_sword, Vector3(0.14, 0.024, 0.038), Vector3(0.0, 0.04, 0.0), mat_gold)
	_add_box(w_sword, Vector3(0.016, 0.42, 0.044), Vector3(0.0, 0.26, 0.0), mat_steel)
	_add_box(w_sword, Vector3(0.020, 0.05, 0.026), Vector3(0.0, 0.49, 0.0), mat_steel)
	_fp_weapon_mount.add_child(w_sword)
	_fp_weapon_meshes["sword"] = w_sword

	# 2. Martillo ("hammer")
	var w_hammer := Node3D.new()
	_add_box(w_hammer, Vector3(0.032, 0.38, 0.032), Vector3(0.0, 0.14, 0.0), mat_wood)
	_add_box(w_hammer, Vector3(0.09, 0.10, 0.19), Vector3(0.0, 0.34, 0.0), mat_dark_iron)
	_add_box(w_hammer, Vector3(0.096, 0.092, 0.03), Vector3(0.0, 0.34, -0.095), mat_steel)
	_fp_weapon_mount.add_child(w_hammer)
	_fp_weapon_meshes["hammer"] = w_hammer

	# 3. Hacha ("axe")
	var w_axe := Node3D.new()
	_add_box(w_axe, Vector3(0.030, 0.36, 0.032), Vector3(0.0, 0.13, 0.0), mat_wood)
	_add_box(w_axe, Vector3(0.036, 0.11, 0.13), Vector3(0.0, 0.29, -0.04), mat_dark_iron)
	_add_box(w_axe, Vector3(0.018, 0.14, 0.05), Vector3(0.0, 0.29, -0.11), mat_steel)
	_fp_weapon_mount.add_child(w_axe)
	_fp_weapon_meshes["axe"] = w_axe

	# 4. Pico ("pickaxe")
	var w_pick := Node3D.new()
	_add_box(w_pick, Vector3(0.030, 0.36, 0.030), Vector3(0.0, 0.13, 0.0), mat_wood)
	_add_box(w_pick, Vector3(0.034, 0.045, 0.24), Vector3(0.0, 0.31, 0.0), mat_dark_iron)
	_add_box(w_pick, Vector3(0.022, 0.032, 0.06), Vector3(0.0, 0.30, -0.14), mat_steel)
	_fp_weapon_mount.add_child(w_pick)
	_fp_weapon_meshes["pickaxe"] = w_pick

	# 5. Hoz ("sickle")
	var w_sickle := Node3D.new()
	_add_box(w_sickle, Vector3(0.028, 0.14, 0.028), Vector3(0.0, 0.02, 0.0), mat_wood)
	_add_box(w_sickle, Vector3(0.016, 0.16, 0.04), Vector3(0.0, 0.16, -0.02), mat_steel)
	_add_box(w_sickle, Vector3(0.016, 0.05, 0.13), Vector3(0.0, 0.23, -0.08), mat_steel)
	_fp_weapon_mount.add_child(w_sickle)
	_fp_weapon_meshes["sickle"] = w_sickle

	# 6. Arco ("bow")
	var w_bow := Node3D.new()
	_add_box(w_bow, Vector3(0.026, 0.42, 0.032), Vector3(-0.08, 0.14, -0.04), mat_wood)
	_add_box(w_bow, Vector3(0.006, 0.40, 0.006), Vector3(-0.08, 0.14, 0.02), _mat("fp_vm_bowstring", Color(0.86, 0.82, 0.72), 0.8))
	_fp_weapon_mount.add_child(w_bow)
	_fp_weapon_meshes["bow"] = w_bow

	# 7. Pistola de Cartuchos ("flintlock" / "pistol")
	var w_gun := Node3D.new()
	_add_box(w_gun, Vector3(0.036, 0.11, 0.065), Vector3(0.0, 0.00, 0.02), mat_wood)
	_add_box(w_gun, Vector3(0.042, 0.056, 0.24), Vector3(0.0, 0.058, -0.09), mat_dark_iron)
	_add_box(w_gun, Vector3(0.026, 0.030, 0.28), Vector3(0.0, 0.074, -0.14), mat_steel)
	_add_box(w_gun, Vector3(0.008, 0.018, 0.012), Vector3(0.0, 0.096, -0.26), mat_gold) # Punto de mira
	_fp_weapon_mount.add_child(w_gun)
	_fp_weapon_meshes["flintlock"] = w_gun

	# 8. Fusil de Cartuchos del Paso ("rifle")
	var w_rifle := Node3D.new()
	_add_box(w_rifle, Vector3(0.040, 0.095, 0.22), Vector3(0.0, 0.01, 0.10), mat_wood) # Culata de madera
	_add_box(w_rifle, Vector3(0.044, 0.064, 0.34), Vector3(0.0, 0.056, -0.12), mat_dark_iron) # Cajón de mecanismos
	_add_box(w_rifle, Vector3(0.032, 0.12, 0.055), Vector3(0.0, -0.025, -0.14), mat_dark_iron) # Cargador de petaca
	_add_box(w_rifle, Vector3(0.024, 0.026, 0.44), Vector3(0.0, 0.072, -0.32), mat_steel) # Cañón largo
	_add_box(w_rifle, Vector3(0.016, 0.016, 0.045), Vector3(0.030, 0.064, -0.06), mat_gold) # Maneta del cerrojo
	_add_box(w_rifle, Vector3(0.008, 0.022, 0.012), Vector3(0.0, 0.094, -0.50), mat_gold) # Punto de mira delantero
	_fp_weapon_mount.add_child(w_rifle)
	_fp_weapon_meshes["rifle"] = w_rifle

	# Fogonazo 3D en la boca del cañón al disparar
	var mat_mflash := StandardMaterial3D.new()
	mat_mflash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_mflash.albedo_color = Color(1.0, 0.90, 0.42, 0.92)
	mat_mflash.emission_enabled = true
	mat_mflash.emission = Color(1.0, 0.78, 0.22)
	mat_mflash.emission_energy_multiplier = 2.4
	_fp_muzzle_flash_mesh = _add_box(_fp_weapon_mount, Vector3(0.045, 0.045, 0.08), Vector3(0.0, 0.075, -0.42), mat_mflash)
	_fp_muzzle_flash_mesh.visible = false
	_fp_muzzle_light = OmniLight3D.new()
	_fp_muzzle_light.light_color = Color(1.0, 0.82, 0.38)
	_fp_muzzle_light.light_energy = 1.25
	_fp_muzzle_light.omni_range = 3.2
	_fp_muzzle_light.position = Vector3(0.0, 0.08, -0.45)
	_fp_muzzle_light.visible = false
	_fp_weapon_mount.add_child(_fp_muzzle_light)

	# 9. Puños / herramienta genérica ("fists")
	var w_fists := Node3D.new()
	_fp_weapon_mount.add_child(w_fists)
	_fp_weapon_meshes["fists"] = w_fists

func _spawn_3d_hit_effect(pos_2d: Vector2, dir_2d: Vector2, power: float = 1.0) -> void:
	if stage_root_3d == null or _is_headless:
		return
	var elev_h: float = 11.0
	if vm != null:
		elev_h += VillageTavern.elevation_height_for(pos_2d, int(vm.player_elevation_level))
	var hit_3d: Vector3 = to_3d(pos_2d - dir_2d.normalized() * 4.0, elev_h)
	var fx_root := Node3D.new()
	fx_root.name = "HitSpark3D"
	fx_root.position = hit_3d
	stage_root_3d.add_child(fx_root)

	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.86, 0.44)
	flash.light_energy = 2.6 * clampf(power, 0.9, 1.8)
	flash.omni_range = 2.2
	fx_root.add_child(flash)

	var spark_mat := StandardMaterial3D.new()
	spark_mat.albedo_color = Color(1.0, 0.92, 0.56)
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(1.0, 0.80, 0.32)
	spark_mat.emission_energy_multiplier = 2.4
	var dirs: Array[Vector3] = [
		Vector3(0.16, 0.14, -0.08),
		Vector3(-0.15, 0.18, 0.07),
		Vector3(0.08, -0.10, 0.15),
		Vector3(-0.12, 0.08, -0.14),
		Vector3(0.19, 0.04, 0.11),
	]
	var spark_nodes: Array[MeshInstance3D] = []
	for d_v in dirs:
		var sm := _add_box(fx_root, Vector3(0.035, 0.035, 0.09) * clampf(power, 0.9, 1.5), d_v * 0.35, spark_mat)
		sm.rotation = d_v.normalized()
		spark_nodes.append(sm)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "light_energy", 0.0, 0.18)
	for idx in range(spark_nodes.size()):
		var sn: MeshInstance3D = spark_nodes[idx]
		tw.tween_property(sn, "position", dirs[idx] * 1.45, 0.18)
		tw.tween_property(sn, "scale", Vector3.ONE * 0.1, 0.18)
	tw.chain().tween_callback(fx_root.queue_free)

func _update_fp_viewmodel(delta: float, pl: Node2D) -> void:
	if _fp_viewmodel_root == null:
		return
	if not first_person_active or not is_instance_valid(pl) or _is_ui_blocking_fp():
		_fp_viewmodel_root.visible = false
		return
	_fp_viewmodel_root.visible = true

	var c_ctrl = pl.get_node_or_null("PlayerCombatController")
	var eq = pl.get("equipped_weapon")
	var w_key: String = str(eq.get("name")).to_lower() if eq != null else "fists"
	if w_key in ["pistol", "flintlock_pistol"]:
		w_key = "flintlock"
	elif w_key in ["assault_rifle", "rifle_weapon"]:
		w_key = "rifle"
	var mesh_key: String = w_key if _fp_weapon_meshes.has(w_key) else "sword"
	for k in _fp_weapon_meshes.keys():
		var wn: Node3D = _fp_weapon_meshes[k]
		if is_instance_valid(wn):
			wn.visible = (k == mesh_key)

	if _fp_gun_recoil_kick > 0.0:
		_fp_gun_recoil_kick = maxf(0.0, _fp_gun_recoil_kick - delta * 4.8)
	if _fp_muzzle_flash_timer > 0.0:
		_fp_muzzle_flash_timer = maxf(0.0, _fp_muzzle_flash_timer - delta)
	if is_instance_valid(_fp_muzzle_flash_mesh):
		_fp_muzzle_flash_mesh.visible = (_fp_muzzle_flash_timer > 0.0) and (mesh_key in ["flintlock", "rifle"])
		_fp_muzzle_flash_mesh.position = Vector3(0.0, 0.075, -0.58 if mesh_key == "rifle" else -0.34)
	if is_instance_valid(_fp_muzzle_light):
		_fp_muzzle_light.visible = (_fp_muzzle_flash_timer > 0.0) and (mesh_key in ["flintlock", "rifle"])
		_fp_muzzle_light.position = Vector3(0.0, 0.08, -0.62 if mesh_key == "rifle" else -0.38)

	# Balanceo al caminar y respirar
	var vel_2d: Vector2 = pl.get("velocity") if "velocity" in pl else Vector2.ZERO
	var spd_ratio: float = clampf(vel_2d.length() / 120.0, 0.0, 1.35)
	_fp_walk_bob_t += delta * (2.2 + spd_ratio * 6.8)
	var bob_x: float = sin(_fp_walk_bob_t) * (0.004 + 0.014 * spd_ratio)
	var bob_y: float = absf(cos(_fp_walk_bob_t)) * (0.003 + 0.012 * spd_ratio)

	# Peso visual según el arma (martillo y hacha descansan algo más bajos y pesados)
	var heavy_off_y: float = -0.025 if mesh_key in ["hammer", "axe", "pickaxe"] else 0.0
	var r_pos := Vector3(0.23 + bob_x, -0.20 - bob_y + heavy_off_y, -0.36)
	var r_rot := Vector3(14.0, -14.0, 10.0)
	var l_pos := Vector3(-0.22 - bob_x * 0.7, -0.22 - bob_y * 0.8, -0.34)
	var l_rot := Vector3(18.0, 16.0, -14.0)
	var show_trail: bool = false
	var ads_blend: float = 0.0

	if c_ctrl != null:
		var phase: String = str(c_ctrl.get("swing_phase"))
		var p_el: float = float(c_ctrl.get("swing_phase_elapsed"))
		var p_dur: float = maxf(0.01, float(c_ctrl.get("swing_phase_duration")))
		var prog: float = clampf(p_el / p_dur, 0.0, 1.0)
		var c_step: int = int(c_ctrl.get("combo_step"))
		var charging: bool = bool(c_ctrl.get("is_charging"))
		var charge_ratio: float = clampf(float(c_ctrl.get("charge_t")) / 0.65, 0.0, 1.0)
		var parrying: bool = c_ctrl.has_method("is_parrying") and bool(c_ctrl.call("is_parrying"))
		var blocking: bool = bool(c_ctrl.get("is_blocking"))
		var drawing_bow: bool = bool(c_ctrl.get("is_drawing_bow"))
		var bow_tens: float = float(c_ctrl.get("bow_tension"))
		ads_blend = clampf(float(c_ctrl.get("aim_down_sights_blend")) if "aim_down_sights_blend" in c_ctrl else 0.0, 0.0, 1.0)
		var rel_step: int = int(c_ctrl.get("reload_step")) if "reload_step" in c_ctrl else 0
		var rel_prog: float = clampf(float(c_ctrl.get("reload_step_progress")) if "reload_step_progress" in c_ctrl else 0.0, 0.0, 1.0)

		if mesh_key in ["flintlock", "rifle"]:
			# Posición base con arma de fuego (mano izquierda sujeta guardamanos en fusil)
			r_pos = Vector3(0.18 + bob_x * 0.5, -0.17 - bob_y * 0.5, -0.34)
			r_rot = Vector3(4.0, -6.0, 2.0)
			if mesh_key == "rifle":
				l_pos = Vector3(0.04, -0.19 - bob_y * 0.5, -0.44)
				l_rot = Vector3(12.0, 28.0, -18.0)
			# Apuntando al centro (Clic Derecho / ADS): encare preciso alineado con la cruceta central
			if ads_blend > 0.01 and rel_step == 0:
				r_pos = r_pos.lerp(Vector3(0.0, -0.095 if mesh_key == "rifle" else -0.105, -0.28), ads_blend)
				r_rot = r_rot.lerp(Vector3(0.0, 0.0, 0.0), ads_blend)
				l_pos = l_pos.lerp(Vector3(-0.04, -0.14, -0.38), ads_blend)
				l_rot = l_rot.lerp(Vector3(8.0, 18.0, -12.0), ads_blend)
			# Recarga manual en 3 pasos (5c: 1. sacar cargador, 2. meter cargador, 3. montar cerrojo)
			if rel_step == 1:
				r_pos = Vector3(0.10, -0.16, -0.32)
				r_rot = Vector3(18.0, 16.0, -28.0)
				l_pos = Vector3(0.06, -0.16, -0.36).lerp(Vector3(-0.14, -0.34, -0.26), rel_prog)
				l_rot = Vector3(24.0, 32.0, -24.0)
			elif rel_step == 2:
				r_pos = Vector3(0.10, -0.16, -0.32)
				r_rot = Vector3(18.0, 16.0, -28.0)
				l_pos = Vector3(-0.14, -0.34, -0.26).lerp(Vector3(0.06, -0.15, -0.36), rel_prog)
				l_rot = Vector3(28.0, 36.0, -18.0)
			elif rel_step == 3:
				r_pos = Vector3(0.12, -0.15, -0.30 + sin(rel_prog * PI) * 0.04)
				r_rot = Vector3(10.0, 8.0, -12.0)
				l_pos = Vector3(0.08, -0.10, -0.28 + sin(rel_prog * PI) * 0.08)
				l_rot = Vector3(32.0, 42.0, -32.0)
			# Retroceso que levanta el arma tras disparar (5b)
			if _fp_gun_recoil_kick > 0.0:
				r_pos += Vector3(0.0, 0.036 * _fp_gun_recoil_kick, 0.085 * _fp_gun_recoil_kick)
				r_rot += Vector3(26.0 * _fp_gun_recoil_kick, 0.0, 0.0)
				l_pos += Vector3(0.0, 0.025 * _fp_gun_recoil_kick, 0.065 * _fp_gun_recoil_kick)
		elif parrying or blocking:
			# Parada (Q) o guardia alta sostenida: hoja cruzada frente al pecho y antebrazo izquierdo reforzando
			var guard_lift: float = 0.03 if parrying else 0.0
			r_pos = Vector3(0.08, -0.11 + guard_lift, -0.31)
			r_rot = Vector3(8.0, -32.0, 58.0)
			l_pos = Vector3(-0.10, -0.13 + guard_lift, -0.29)
			l_rot = Vector3(28.0, 28.0, -38.0)
		elif drawing_bow:
			l_pos = Vector3(-0.06, -0.14, -0.40)
			l_rot = Vector3(6.0, 6.0, -4.0)
			r_pos = Vector3(0.16, -0.16, lerpf(-0.34, -0.20, bow_tens))
			r_rot = Vector3(10.0, -18.0, 8.0)
		elif charging:
			# Cargando golpe pesado (martillo / hacha): arma alzada atrás con temblor de tensión
			var jitter: float = sin(Time.get_ticks_msec() * 0.045) * 0.006 * charge_ratio
			r_pos = Vector3(0.28 + jitter, lerpf(-0.18, -0.05, charge_ratio), lerpf(-0.34, -0.25, charge_ratio))
			r_rot = Vector3(lerpf(14.0, 54.0, charge_ratio), lerpf(-14.0, -34.0, charge_ratio), lerpf(10.0, -28.0, charge_ratio))
			l_pos = Vector3(-0.20, lerpf(-0.22, -0.16, charge_ratio), -0.32)
			l_rot = Vector3(24.0, 20.0, -20.0)
		elif phase == "windup":
			var e_w: float = 1.0 - pow(1.0 - prog, 2.0)
			if c_step == 2:
				# 2.º golpe de cadena: prepara desde el costado izquierdo
				r_pos = r_pos.lerp(Vector3(-0.12, -0.10, -0.30), e_w)
				r_rot = r_rot.lerp(Vector3(24.0, 32.0, 48.0), e_w)
			elif c_step == 3 or mesh_key in ["hammer", "axe", "pickaxe"]:
				# 3.º golpe o arma pesada: alza sobre la cabeza con peso
				r_pos = r_pos.lerp(Vector3(0.18, -0.03, -0.26), e_w)
				r_rot = r_rot.lerp(Vector3(58.0, -24.0, -22.0), e_w)
			else:
				# 1.er golpe: echa el brazo atrás y arriba a la derecha
				r_pos = r_pos.lerp(Vector3(0.31, -0.08, -0.27), e_w)
				r_rot = r_rot.lerp(Vector3(44.0, -32.0, -26.0), e_w)
			l_pos = l_pos.lerp(Vector3(-0.24, -0.18, -0.30), e_w)
		elif phase == "active":
			show_trail = true
			var e_a: float = pow(prog, 0.65)
			if c_step == 2:
				# Revés de izquierda a derecha
				r_pos = Vector3(-0.12, -0.10, -0.32).lerp(Vector3(0.26, -0.22, -0.44), e_a)
				r_rot = Vector3(12.0, 28.0, 46.0).lerp(Vector3(-38.0, -36.0, -48.0), e_a)
			elif c_step == 3 or mesh_key in ["hammer", "axe", "pickaxe"]:
				# Descarga vertical pesada hacia delante
				r_pos = Vector3(0.14, -0.02, -0.30).lerp(Vector3(0.04, -0.28, -0.48), e_a)
				r_rot = Vector3(54.0, -16.0, -14.0).lerp(Vector3(-64.0, 8.0, 18.0), e_a)
			else:
				# Tajo diagonal de derecha a izquierda hacia el centro
				r_pos = Vector3(0.28, -0.08, -0.30).lerp(Vector3(-0.14, -0.24, -0.46), e_a)
				r_rot = Vector3(38.0, -28.0, -20.0).lerp(Vector3(-46.0, 34.0, 52.0), e_a)
			l_pos = Vector3(-0.25, -0.24, -0.28)
		elif phase == "recovery":
			var e_r: float = smoothstep(0.0, 1.0, prog)
			var start_p := Vector3(-0.12, -0.25, -0.44) if c_step != 2 else Vector3(0.24, -0.24, -0.42)
			var start_r := Vector3(-44.0, 26.0, 44.0) if c_step != 2 else Vector3(-36.0, -32.0, -42.0)
			r_pos = start_p.lerp(r_pos, e_r)
			r_rot = start_r.lerp(r_rot, e_r)
		elif phase == "shove":
			var e_s: float = sin(prog * PI)
			l_pos = l_pos.lerp(Vector3(-0.04, -0.14, -0.52), e_s)
			l_rot = l_rot.lerp(Vector3(-12.0, 8.0, -42.0), e_s)
			r_pos = r_pos.lerp(Vector3(0.26, -0.24, -0.30), e_s)

	if _fp_hurt_flash_timer > 0.0:
		var hk: float = clampf(_fp_hurt_flash_timer / 0.35, 0.0, 1.0)
		r_pos += Vector3(0.03 * hk, -0.04 * hk, 0.05 * hk)
		l_pos += Vector3(-0.04 * hk, -0.02 * hk, 0.05 * hk)

	_fp_right_arm.position = r_pos
	_fp_right_arm.rotation_degrees = r_rot
	_fp_left_arm.position = l_pos
	_fp_left_arm.rotation_degrees = l_rot
	if is_instance_valid(_fp_swing_trail):
		_fp_swing_trail.visible = show_trail

func _update_fp_camera_transform() -> void:
	if cam_3d == null or not first_person_active:
		if _fp_viewmodel_root != null:
			_fp_viewmodel_root.visible = false
		return
	var dt: float = get_process_delta_time()
	if _fp_shake_timer > 0.0:
		_fp_shake_timer = maxf(0.0, _fp_shake_timer - dt)
		if _fp_shake_timer <= 0.0:
			_fp_shake_amp = 0.0
	_fp_camera_punch_pitch = move_toward(_fp_camera_punch_pitch, 0.0, dt * 0.32)
	_fp_camera_punch_roll = move_toward(_fp_camera_punch_roll, 0.0, dt * 0.36)

	var pl := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
	var pl_pos: Vector2 = pl.global_position if is_instance_valid(pl) else Vector2(465, 48)
	var eye_h: float = FP_EYE_HEIGHT_PX
	if is_instance_valid(pl):
		if pl.get("is_mounted") == true:
			eye_h += 6.0
		else:
			var m_ctrl = pl.get_node_or_null("PlayerMovementController")
			if m_ctrl != null and m_ctrl.get("is_stealthing") == true:
				eye_h -= 3.5
	if vm != null:
		var tav_eye_h: float = VillageTavern.elevation_height_for(pl_pos, int(vm.player_elevation_level))
		if tav_eye_h > 3.0:
			eye_h += tav_eye_h
	var eye_3d: Vector3 = to_3d(pl_pos, eye_h)
	if _fp_shake_timer > 0.0 and _fp_shake_amp > 0.0:
		eye_3d += Vector3(
			randf_range(-_fp_shake_amp, _fp_shake_amp),
			randf_range(-_fp_shake_amp, _fp_shake_amp),
			randf_range(-_fp_shake_amp, _fp_shake_amp)
		)
	var dir_2d: Vector2 = get_fp_forward_2d()
	var horiz_3d: Vector3 = Vector3(dir_2d.x, 0.0, dir_2d.y / maxf(0.1, _sin_p)).normalized()
	var eff_pitch: float = clampf(fp_pitch + _fp_camera_punch_pitch, -FP_MAX_PITCH, FP_MAX_PITCH)
	var look_dir_3d: Vector3 = (horiz_3d * cos(eff_pitch) + Vector3(0.0, sin(eff_pitch), 0.0)).normalized()
	cam_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
	var ads_fov_blend: float = 0.0
	if is_instance_valid(pl):
		var c_ctrl_f = pl.get_node_or_null("PlayerCombatController")
		if c_ctrl_f != null and "aim_down_sights_blend" in c_ctrl_f:
			ads_fov_blend = clampf(float(c_ctrl_f.get("aim_down_sights_blend")), 0.0, 1.0)
	cam_3d.fov = lerpf(70.0, 55.0, ads_fov_blend)
	cam_3d.near = 0.03
	cam_3d.far = 250.0
	cam_3d.global_position = eye_3d
	if cam_3d.is_inside_tree():
		cam_3d.look_at(eye_3d + look_dir_3d * 10.0, Vector3.UP)
	else:
		cam_3d.transform = cam_3d.transform.looking_at(eye_3d + look_dir_3d * 10.0, Vector3.UP)
	if absf(_fp_camera_punch_roll) > 0.0005:
		cam_3d.rotate_object_local(Vector3.FORWARD, _fp_camera_punch_roll)
	_update_fp_viewmodel(dt, pl)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F6 or event.physical_keycode == KEY_F6 or ((event.keycode == KEY_P or event.physical_keycode == KEY_P) and not _is_ui_blocking_fp()):
			toggle_first_person()
			get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not first_person_active or _is_headless:
		return
	if _is_ui_blocking_fp():
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		rotate_first_person_view(mm.relative.x, mm.relative.y)

func _update_fp_hud() -> void:
	if fp_hud_layer == null:
		return
	if not first_person_active or not CharacterAvatar3DScript.use_3d_characters:
		fp_hud_layer.visible = false
		return
	var ui_blocked: bool = _is_ui_blocking_fp()
	fp_hud_layer.visible = not ui_blocked
	var dt: float = get_process_delta_time()
	if _fp_hurt_flash_timer > 0.0:
		_fp_hurt_flash_timer = maxf(0.0, _fp_hurt_flash_timer - dt)
	if _fp_hit_confirm_timer > 0.0:
		_fp_hit_confirm_timer = maxf(0.0, _fp_hit_confirm_timer - dt)
	if _fp_block_flash_timer > 0.0:
		_fp_block_flash_timer = maxf(0.0, _fp_block_flash_timer - dt)
	if is_instance_valid(_fp_damage_vignette):
		if _fp_hurt_flash_timer > 0.0:
			_fp_damage_vignette.visible = true
			_fp_damage_vignette.color = Color(0.82, 0.08, 0.06, clampf(_fp_hurt_flash_timer * 0.95, 0.0, 0.42))
		elif _fp_block_flash_timer > 0.0:
			_fp_damage_vignette.visible = true
			_fp_damage_vignette.color = Color(0.42, 0.78, 1.0, clampf(_fp_block_flash_timer * 0.90, 0.0, 0.26))
		else:
			_fp_damage_vignette.visible = false
	if is_instance_valid(_fp_hit_flash_rect):
		if _fp_hit_confirm_timer > 0.0:
			_fp_hit_flash_rect.visible = true
			_fp_hit_flash_rect.color = Color(1.0, 0.88, 0.36, clampf(_fp_hit_confirm_timer * 2.2, 0.0, 0.48))
		else:
			_fp_hit_flash_rect.visible = false
	if fp_interact_label != null:
		fp_interact_label.text = ""
		fp_interact_label.visible = false
	if fp_mode_badge != null:
		var pl_hud := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
		var c_ctrl_hud = pl_hud.get_node_or_null("PlayerCombatController") if is_instance_valid(pl_hud) else null
		var eq_hud = pl_hud.get("equipped_weapon") if is_instance_valid(pl_hud) else null
		var eq_name_hud: String = str(eq_hud.name).to_lower() if (eq_hud != null and "name" in eq_hud) else ""
		if c_ctrl_hud != null and (eq_name_hud == "flintlock" or eq_name_hud == "rifle"):
			var is_rf_hud: bool = (eq_name_hud == "rifle")
			var rel_step_hud: int = int(c_ctrl_hud.get("reload_step"))
			var mag_hud: int = int(c_ctrl_hud.get("rifle_mag_loaded" if is_rf_hud else "pistol_mag_loaded"))
			var cap_hud: int = 5 if is_rf_hud else 6
			var ads_hud: bool = float(c_ctrl_hud.get("aim_down_sights_blend")) >= 0.5
			if rel_step_hud > 0:
				var step_txt: String = "Sacando cargador vacío" if rel_step_hud == 1 else ("Metiendo cargador nuevo" if rel_step_hud == 2 else "Montando el cerrojo")
				fp_mode_badge.text = "🔄 RECARGA MANUAL [Paso %d/3]: %s..." % [rel_step_hud, step_txt]
				fp_mode_badge.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36, 0.96))
			else:
				var w_lbl: String = "🎯 Fusil del Paso" if is_rf_hud else "🔫 Pistola de Chispa"
				var aim_lbl: String = " [MIRA ALZADA]" if ads_hud else " [Clic der. apuntar | R recargar]"
				fp_mode_badge.text = "%s — Cargador: %d/%d%s" % [w_lbl, mag_hud, cap_hud, aim_lbl]
				fp_mode_badge.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 0.92))
			fp_mode_badge.visible = true
		else:
			fp_mode_badge.text = ""
			fp_mode_badge.visible = false
	return

func _process(delta: float) -> void:
	if _is_headless or vm == null:
		return

	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	if not use_3d and first_person_active:
		set_first_person(false)
	if use_3d != _last_use_3d:
		_last_use_3d = use_3d
		_sync_2d_flat_visuals(use_3d)

	if is_instance_valid(stage_sprite):
		stage_sprite.visible = use_3d
	if not use_3d:
		return

	if first_person_active and not _is_ui_blocking_fp():
		var arrow_turn := Vector2(
			float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
			float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
		)
		if arrow_turn.length_squared() > 0.01:
			rotate_first_person_view(arrow_turn.x * 520.0 * delta, arrow_turn.y * 360.0 * delta)
		_sync_player_aim_from_fp()
	_update_fp_hud()

	if vm.buried_graves.size() != _last_buried_count:
		rebuild_graves_3d()

	var _pt: int = Time.get_ticks_usec() if perf_on else 0
	_sync_camera_with_2d()
	if perf_on: _pt = _perf_add("camera", _pt)
	_sync_dynamic_props_3d()
	if perf_on: _pt = _perf_add("dynamic_props", _pt)

	_nature_scan_accum += delta
	if _nature_scan_accum >= 4.0:
		_nature_scan_accum = 0.0
		_scan_nature_sources()
		_sync_2d_flat_visuals(use_3d)
	if perf_on: _pt = _perf_add("nature_scan_4s", _pt)
	_nature_accum += delta
	if _nature_accum >= 0.5:
		_nature_accum = 0.0
		_sync_nature_3d(true)
		if perf_on: _pt = _perf_add("nature_sync_05s", _pt)
		_sync_props_3d(true)
		if perf_on: _pt = _perf_add("props_sync_05s", _pt)

	_cutaway_accum += delta
	if _cutaway_accum >= 0.08:
		_cutaway_accum = 0.0
		_update_roof_cutaways_and_lighting()
	if perf_on: _perf_add("roofs_lighting_008s", _pt)

## B3 (medición): cronómetro por partes; solo lo enciende `tools/tests/perf_3d.gd`. No cambia el comportamiento.
static var perf_on: bool = false
static var perf_usec: Dictionary = {}

static func _perf_add(part: String, since: int) -> int:
	var now: int = Time.get_ticks_usec()
	perf_usec[part] = int(perf_usec.get(part, 0)) + (now - since)
	return now

func _sync_camera_with_2d() -> void:
	if cam_3d == null:
		return
	if detective_topdown_active:
		cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam_3d.rotation_degrees = Vector3(-86.0, 0.0, 0.0)
		cam_3d.near = 0.1
		cam_3d.far = 250.0
		cam_3d.size = maxf(1.5, detective_topdown_size)
		var target_top_3d: Vector3 = to_3d(detective_topdown_pos, 0.0)
		var fwd_top: Vector3 = -cam_3d.global_transform.basis.z.normalized()
		cam_3d.global_position = target_top_3d - fwd_top * 65.0
		return
	if first_person_active:
		_update_fp_camera_transform()
	if stage_sprite == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var cam2d := vp.get_camera_2d()
	var vp_rect := vp.get_visible_rect()
	var center_2d: Vector2 = cam2d.get_screen_center_position() if cam2d != null else Vector2(465, 48)
	var zoom_2d: Vector2 = cam2d.zoom if cam2d != null else Vector2(3.0, 3.0)

	if not first_person_active:
		if cam_3d.projection != Camera3D.PROJECTION_ORTHOGONAL or not is_equal_approx(cam_3d.rotation_degrees.x, -PITCH_DEG):
			cam_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam_3d.rotation_degrees = Vector3(-PITCH_DEG, 0.0, 0.0)
			cam_3d.near = 0.1
			cam_3d.far = 250.0
		var world_vis_h: float = vp_rect.size.y / maxf(0.1, zoom_2d.y)
		cam_3d.size = maxf(1.0, world_vis_h * WORLD_SCALE)

		var target_3d: Vector3 = to_3d(center_2d, 0.0)
		var forward_vec: Vector3 = -cam_3d.global_transform.basis.z.normalized()
		cam_3d.global_position = target_3d - forward_vec * 65.0

	stage_sprite.global_position = center_2d
	stage_sprite.scale = Vector2(
		(vp_rect.size.x / maxf(0.1, zoom_2d.x)) / float(VIEWPORT_W),
		(vp_rect.size.y / maxf(0.1, zoom_2d.y)) / float(VIEWPORT_H)
	)

func _sync_dynamic_props_3d() -> void:
	# 1. Puertas abatibles 3D
	for d_node in _door_nodes_3d:
		var d_entry: Dictionary = d_node["entry"]
		var pivot: Node3D = d_node["pivot"]
		var badge: MeshInstance3D = d_node["lock_badge"]
		if not is_instance_valid(pivot):
			continue
		var eff_open: bool = bool(d_entry.get("is_open", false)) or float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		var door_south: bool = bool(d_node["door_south"])
		pivot.rotation_degrees.y = (-82.0 if door_south else 82.0) if eff_open else 0.0
		if is_instance_valid(badge):
			badge.visible = (not eff_open) and (bool(d_entry.get("is_locked", false)) or bool(d_entry.get("locked_by_player", false)))

	# 2. Postigos de ventanas 3D
	for w_node in _window_nodes_3d:
		var w_entry: Dictionary = w_node["entry"]
		var shutter: MeshInstance3D = w_node["shutter"]
		if is_instance_valid(shutter):
			shutter.visible = bool(w_entry.get("is_shuttered", false))

	# 3. Cofres abiertos / cerrados
	var wc = get_node_or_null("/root/WorldClock")
	var cur_d: int = int(wc.current_day) if wc != null else 1
	for ch_node in _chest_nodes_3d:
		var ch_entry: Dictionary = ch_node["entry"]
		var lid: MeshInstance3D = ch_node["lid"]
		if is_instance_valid(lid):
			lid.visible = (int(ch_entry.get("looted_day", -1)) != cur_d)

	# 4. Cuerpos en las 3 camillas de la Morgue
	var active_morgue: int = vm.morgue_active_corpses.size()
	for i in range(_morgue_body_nodes_3d.size()):
		if is_instance_valid(_morgue_body_nodes_3d[i]):
			_morgue_body_nodes_3d[i].visible = (i < active_morgue)

	# 5. Reja de la celda de la Comisaría
	if is_instance_valid(_jail_gate_pivot_3d):
		var gate_locked: bool = is_instance_valid(vm._jail_cell_gate_col) and not vm._jail_cell_gate_col.disabled
		_jail_gate_pivot_3d.rotation_degrees.y = 0.0 if gate_locked else -80.0

	# 6. Visibilidad de las alcantarillas y del club del sótano (-1): al bajar bajo el pueblo, ocultar superficie 3D para ver las galerías limpias igual que en 2D
	var in_sewers: bool = VillageUnderworldScript.is_player_in_sewers(vm)
	var in_club: bool = load("res://scripts/systems/VillageClub.gd").is_player_in_club(vm)
	var underground_view: bool = in_sewers or in_club
	if is_instance_valid(sewers_root_3d):
		sewers_root_3d.visible = in_sewers
	_sync_club_3d()
	if is_instance_valid(buildings_root_3d):
		buildings_root_3d.visible = not underground_view
	if is_instance_valid(lots_root_3d):
		lots_root_3d.visible = not underground_view
	if is_instance_valid(nature_root_3d):
		nature_root_3d.visible = not underground_view
	if is_instance_valid(streetlights_root_3d):
		streetlights_root_3d.visible = not underground_view

	# 7. Piloto luminoso del Cuadro Eléctrico del Taller y objeto físico del robo activo (Bloque FIS2)
	if is_instance_valid(_grid_panel_bulb_3d):
		var sab_on: bool = VillageCulture.is_grid_sabotaged(vm)
		_grid_panel_bulb_3d.material_override = _mat("grid_bulb_err", Color(1.0, 0.25, 0.18), 0.2, 0.0, Color(1.0, 0.20, 0.12), 2.8) if sab_on else _mat("tinker_screen", Color(0.32, 0.96, 0.82), 0.2, 0.0, Color(0.24, 0.92, 0.76), 2.4)
	_sync_heist_target_3d()
	_sync_town_ledger_3d()
	_sync_home_props_3d()

func _sync_home_props_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var p_lots: Array[String] = VillageHousingScript.player_lots(vm, true)
	var hs: Dictionary = VillageHousingScript.state(vm)
	var prim_lot: String = VillageHousingScript.primary_player_lot(vm)
	var has_shop: bool = VillageHousingScript.has_player_shop(vm)
	var ps: Dictionary = hs.get("player_shop", {}) if has_shop else {}
	var shop_lot: String = VillageHousingScript.player_shop_lot(vm) if has_shop else ""
	var parts: PackedStringArray = PackedStringArray()
	for lid in p_lots:
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		var wb: int = 1 if bool(up.get("workbench", false)) else 0
		var st_fl: int = 1 if (lid == prim_lot and bool(hs.get("has_stash", false))) else 0
		var up_fl: int = 1 if bool(up.get("upper_floor", false)) else 0
		var cel_fl: int = 1 if bool(up.get("hidden_cellar", false)) else 0
		var gd_fl: int = 1 if bool(st.get("has_garden", false)) else 0
		var gd_rdy: int = 1 if (gd_fl == 1 and VillageHousingScript.can_harvest_home_garden(vm, lid)) else 0
		var sh_fl: int = 1 if (has_shop and lid == shop_lot) else 0
		var sh_stk: int = clampi(int(ps.get("stock", 0)), 0, 4) if sh_fl == 1 else 0
		var sh_till: int = (1 if int(ps.get("till_gold", 0)) > 0 else 0) if sh_fl == 1 else 0
		var tb_rat: int = clampi(int(hs.get("table_rations", 0)), 0, 12) if lid == prim_lot else 0
		parts.append("%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [lid, wb, st_fl, up_fl, cel_fl, gd_fl, gd_rdy, sh_fl, sh_stk, sh_till, tb_rat])
	var sig: String = "|".join(parts)
	if sig == _last_home_props_sig and (sig.is_empty() or is_instance_valid(_home_props_3d)):
		return
	_last_home_props_sig = sig
	if is_instance_valid(_home_props_3d):
		_home_props_3d.queue_free()
		_home_props_3d = null
	if sig.is_empty():
		return
	var root: Node3D = Node3D.new()
	root.name = "HomeProps3D"
	stage_root_3d.add_child(root)
	_home_props_3d = root

	var m_oak: StandardMaterial3D = _mat("hp_oak", Color(0.46, 0.30, 0.16), 0.85, 0.05)
	var m_dark: StandardMaterial3D = _mat("hp_dark", Color(0.14, 0.10, 0.06), 0.95, 0.0)
	var m_iron: StandardMaterial3D = _mat("hp_iron", Color(0.28, 0.32, 0.36), 0.45, 0.75)
	var m_gold: StandardMaterial3D = _mat("hp_gold", Color(0.95, 0.78, 0.24), 0.25, 0.85, Color(0.92, 0.74, 0.20), 0.55)
	var m_herb: StandardMaterial3D = _mat("hp_herb", Color(0.30, 0.82, 0.38), 0.45, 0.10, Color(0.20, 0.65, 0.28), 0.35)
	var m_dust: StandardMaterial3D = _mat("hp_dust", Color(0.74, 0.44, 0.96), 0.30, 0.15, Color(0.66, 0.36, 0.90), 0.55)
	var m_soil: StandardMaterial3D = _mat("hp_soil", Color(0.30, 0.20, 0.12), 0.95, 0.0)

	for lid in p_lots:
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		var tb_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_table")
		_add_box_2d(root, tb_pos, Vector2(18.0, 10.6), 2.0, 6.2, m_oak) # Mesa de comedor
		_add_box_2d(root, tb_pos, Vector2(19.4, 11.6), 7.8, 1.0, m_oak) # Tablero de la mesa
		if lid == prim_lot and int(hs.get("table_rations", 0)) > 0:
			_add_cyl_2d(root, tb_pos + Vector2(-3.2, -0.5), 2.2, 8.8, 1.4, m_gold, 2.0, 8) # Hogaza / plato en la mesa
			_add_cyl_2d(root, tb_pos + Vector2(3.2, 0.5), 2.0, 8.8, 2.0, m_herb, 1.6, 8) # Guiso / viandas
		if bool(up.get("workbench", false)):
			var wb_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_workbench")
			if _add_model_2d(root, "props/Workbench_Drawers.gltf", wb_pos, 2.0, Vector2(18.0, 10.0), 8.2) == null:
				_add_box_2d(root, wb_pos, Vector2(18.0, 10.0), 2.0, 7.5, m_oak)
			_add_cyl_2d(root, wb_pos + Vector2(-4.0, -0.5), 2.2, 9.5, 2.6, m_herb, 1.8, 8) # Mortero con cataplasma
			_add_cyl_2d(root, wb_pos + Vector2(3.5, -0.5), 2.0, 9.5, 3.8, m_dust, 1.0, 10) # Alambique de polvo de ocaso
		if lid == prim_lot and bool(hs.get("has_stash", false)):
			var st_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_stash")
			_add_box_2d(root, st_pos, Vector2(13.0, 9.5), 1.8, 0.8, m_dark) # Hueco bajo el suelo
			_add_box_2d(root, st_pos + Vector2(-3.2, 0), Vector2(4.2, 8.8), 2.2, 1.2, m_oak) # Tabla izq
			_add_box_2d(root, st_pos + Vector2(3.4, -0.6), Vector2(4.2, 8.8), 2.6, 1.4, m_oak) # Tabla entreabierta der
			_add_cyl_2d(root, st_pos + Vector2(0, 0.8), 2.2, 2.2, 1.2, m_gold, 2.2, 8) # Monedas ocultas
		if bool(up.get("upper_floor", false)) or bool(up.get("hidden_cellar", false)):
			var sr_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_stairs")
			_add_box_2d(root, sr_pos, Vector2(13.0, 14.0), 1.8, 1.2, m_dark) # Trampilla / base
			_add_box_2d(root, sr_pos, Vector2(11.6, 12.6), 2.4, 1.4, m_oak)
			_add_box_2d(root, sr_pos + Vector2(4.0, 0), Vector2(1.8, 1.8), 3.6, 1.2, m_iron) # Argolla de hierro
			if bool(up.get("upper_floor", false)):
				for step_i in range(4):
					var sy: float = -4.5 + float(step_i) * 3.0
					var sh: float = 4.0 + float(step_i) * 4.2
					_add_box_2d(root, sr_pos + Vector2(0, sy), Vector2(10.0, 2.2), sh, 1.6, m_oak)
		if bool(st.get("has_garden", false)):
			var gd_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_garden")
			_add_box_2d(root, gd_pos, Vector2(22.0, 15.0), 0.2, 2.2, m_oak) # Cerco de madera
			_add_box_2d(root, gd_pos, Vector2(19.6, 12.6), 0.4, 2.4, m_soil) # Tierra labrada
			var crop_mat: StandardMaterial3D = m_herb if VillageHousingScript.can_harvest_home_garden(vm, lid) else m_oak
			for gy in [-3.2, 3.2]:
				for gx in [-6.5, -2.2, 2.2, 6.5]:
					_add_cyl_2d(root, gd_pos + Vector2(gx, gy), 2.0, 2.6, 2.6, crop_mat, 1.4, 7)
		if has_shop and lid == shop_lot:
			var sc_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "player_shop_counter")
			_add_box_2d(root, sc_pos, Vector2(18.0, 9.2), 2.0, 6.8, m_oak) # Cuerpo del mostrador
			_add_box_2d(root, sc_pos, Vector2(19.6, 10.4), 8.6, 1.2, m_oak) # Tablero del mostrador
			_add_box_2d(root, sc_pos + Vector2(4.6, -0.2), Vector2(5.2, 4.4), 9.8, 2.6, m_iron) # Caja de recaudación
			if int(ps.get("till_gold", 0)) > 0:
				_add_cyl_2d(root, sc_pos + Vector2(4.6, -0.2), 1.8, 12.2, 1.2, m_gold, 1.8, 8) # Monedas en la caja
			if int(ps.get("stock", 0)) > 0:
				_add_box_2d(root, sc_pos + Vector2(-4.8, -0.4), Vector2(3.8, 3.6), 9.8, 2.4, m_herb) # Mercancía expuesta 1
				if int(ps.get("stock", 0)) >= 2:
					_add_box_2d(root, sc_pos + Vector2(-1.2, 0.4), Vector2(3.6, 3.4), 9.8, 2.2, m_gold) # Mercancía expuesta 2

## P6: sala del club de pelea (se construye una vez; solo se ve estando dentro).
func _sync_club_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var Club = load("res://scripts/systems/VillageClub.gd")
	if not is_instance_valid(_club_root_3d):
		_club_root_3d = Node3D.new()
		_club_root_3d.name = "FightClub3D"
		stage_root_3d.add_child(_club_root_3d)
		var m_rock := _mat("sewer_bedrock", Color(0.08, 0.10, 0.09), 0.96, 0.0)
		var m_dirt := _mat("club_dirt", Color(0.36, 0.27, 0.18), 0.95, 0.0)
		var m_stone := _mat("sewer_brick", Color(0.28, 0.34, 0.30), 0.90, 0.05, Color.BLACK, 0.0, "town_textures/wall_brick_stone_center.png", "", 0.35)
		var m_rope := _mat("club_rope", Color(0.78, 0.66, 0.42), 0.9, 0.0)
		var m_wood := _mat("sewer_wood", Color(0.46, 0.30, 0.16), 0.85, 0.04)
		var m_iron := _mat("sewer_iron", Color(0.24, 0.27, 0.32), 0.42, 0.78)
		var m_torch := _mat("sewer_torch", Color(1.0, 0.76, 0.32), 0.20, 0.0, Color(1.0, 0.68, 0.22), 2.8)
		var c: Vector2 = Club.CLUB_CENTER
		var sz: Vector2 = Club.CLUB_SIZE
		_add_box_2d(_club_root_3d, c, sz + Vector2(80, 80), 0.0, 1.0, m_rock)
		_add_box_2d(_club_root_3d, c, sz, 1.0, 1.2, m_dirt)
		_add_box_2d(_club_root_3d, c + Vector2(0, -sz.y * 0.5 - 3), Vector2(sz.x + 12, 6), 2.0, 22.0, m_stone) # muro norte alto
		_add_box_2d(_club_root_3d, c + Vector2(0, sz.y * 0.5 + 3), Vector2(sz.x + 12, 6), 2.0, 5.0, m_stone) # zócalo sur bajo
		_add_box_2d(_club_root_3d, c + Vector2(-sz.x * 0.5 - 3, 0), Vector2(6, sz.y), 2.0, 22.0, m_stone)
		_add_box_2d(_club_root_3d, c + Vector2(sz.x * 0.5 + 3, 0), Vector2(6, sz.y), 2.0, 22.0, m_stone)
		# Corro: 12 postes y cuerda entre ellos
		var r: float = Club.RING_RADIUS
		for i in range(12):
			var a0: float = TAU * float(i) / 12.0
			var a1: float = TAU * float(i + 1) / 12.0
			var p0: Vector2 = c + Vector2(cos(a0), sin(a0)) * r
			var p1: Vector2 = c + Vector2(cos(a1), sin(a1)) * r
			_add_cyl_2d(_club_root_3d, p0, 1.2, 2.2, 9.0, m_wood, 1.2, 6)
			var mid: Vector2 = (p0 + p1) * 0.5
			_add_box_2d(_club_root_3d, mid, Vector2(maxf(absf(p1.x - p0.x), 1.2), maxf(absf(p1.y - p0.y), 1.2)), 8.0, 0.8, m_rope)
		# Escalerilla de subida a la trampilla
		var lad: Vector2 = Club.LADDER_POS
		_add_box_2d(_club_root_3d, lad + Vector2(-4, -6), Vector2(1.4, 2.0), 2.4, 22.0, m_iron)
		_add_box_2d(_club_root_3d, lad + Vector2(4, -6), Vector2(1.4, 2.0), 2.4, 22.0, m_iron)
		for k in range(6):
			_add_box_2d(_club_root_3d, lad + Vector2(0, -6), Vector2(8.0, 1.2), 4.0 + float(k) * 3.2, 0.9, m_wood)
		# Faroles en las esquinas
		for off in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var tp: Vector2 = c + Vector2(off.x * (sz.x * 0.5 - 8), off.y * (sz.y * 0.5 - 8))
			_add_cyl_2d(_club_root_3d, tp, 1.4, 2.0, 10.0, m_wood, 1.0, 6)
			_add_cyl_2d(_club_root_3d, tp, 2.2, 12.0, 3.0, m_torch, 1.4, 8)
			if not _is_headless:
				var lt := OmniLight3D.new()
				lt.position = to_3d(tp, 16.0)
				lt.light_color = Color(1.0, 0.78, 0.42)
				lt.light_energy = 1.2
				lt.omni_range = 3.4
				_club_root_3d.add_child(lt)
		# Trampilla en la sala trasera de escalera/bodega de la taberna (sobre la losa del suelo en h = 2.5)
		var trap := Node3D.new()
		trap.name = "ClubTrapdoor3D"
		stage_root_3d.add_child(trap)
		var closed_lid := Node3D.new()
		closed_lid.name = "ClosedLid"
		trap.add_child(closed_lid)
		_add_box_2d(closed_lid, Club.TRAPDOOR_POS, Vector2(16.0, 14.0), 2.5, 1.1, m_wood)
		_add_box_2d(closed_lid, Club.TRAPDOOR_POS + Vector2(0, 4.2), Vector2(12.0, 1.3), 3.6, 0.6, m_iron)
		_add_box_2d(closed_lid, Club.TRAPDOOR_POS + Vector2(0, -4.2), Vector2(12.0, 1.3), 3.6, 0.6, m_iron)
		var open_hatch := Node3D.new()
		open_hatch.name = "OpenHatch"
		trap.add_child(open_hatch)
		# Marco de madera, hueco oscuro hacia el sótano (-1), hoja levantada al norte y peldaños de escalera asomando
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, -7.2), Vector2(16.0, 1.6), 2.5, 1.4, m_wood)
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, 7.2), Vector2(16.0, 1.6), 2.5, 1.4, m_wood)
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(-7.8, 0), Vector2(1.6, 13.0), 2.5, 1.4, m_wood)
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(7.8, 0), Vector2(1.6, 13.0), 2.5, 1.4, m_wood)
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS, Vector2(13.6, 12.2), 2.45, 0.4, m_rock) # Pozo oscuro abierto
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, -7.8), Vector2(15.2, 1.8), 3.2, 11.5, m_wood) # Tapa abierta levantada
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, -6.8), Vector2(12.0, 0.6), 6.0, 1.2, m_iron) # Herraje interior
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(-4.0, -1.5), Vector2(1.2, 1.4), 1.5, 4.8, m_iron) # Larguero izq
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(4.0, -1.5), Vector2(1.2, 1.4), 1.5, 4.8, m_iron) # Larguero der
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, -1.5), Vector2(7.4, 1.0), 3.2, 0.8, m_wood) # Peldaño superior
		_add_box_2d(open_hatch, Club.TRAPDOOR_POS + Vector2(0, 1.5), Vector2(7.4, 1.0), 2.6, 0.8, m_torch) # Resplandor cálido del sótano
		if not _is_headless:
			var t_lt := OmniLight3D.new()
			t_lt.position = to_3d(Club.TRAPDOOR_POS, 5.5)
			t_lt.light_color = Color(1.0, 0.72, 0.28)
			t_lt.light_energy = 1.35
			t_lt.omni_range = 1.8
			open_hatch.add_child(t_lt)
	var in_club_now: bool = Club.is_player_in_club(vm)
	var open_now: bool = Club.is_open_now(vm)
	_club_root_3d.visible = in_club_now
	var trap_node := stage_root_3d.get_node_or_null("ClubTrapdoor3D") as Node3D
	if is_instance_valid(trap_node):
		trap_node.visible = not in_club_now
		var cl_n := trap_node.get_node_or_null("ClosedLid") as Node3D
		var op_n := trap_node.get_node_or_null("OpenHatch") as Node3D
		if is_instance_valid(cl_n):
			cl_n.visible = not open_now
		if is_instance_valid(op_n):
			op_n.visible = open_now

## P5: libro de cuentas abierto sobre la mesa del ayuntamiento (se construye una vez).
func _sync_town_ledger_3d() -> void:
	if vm == null or stage_root_3d == null or is_instance_valid(_town_ledger_3d):
		return
	var pos: Vector2 = load("res://scripts/systems/VillageCollections.gd").ledger_pos()
	var root := Node3D.new()
	root.name = "TownLedger3D"
	stage_root_3d.add_child(root)
	_town_ledger_3d = root
	var m_leather := _mat("ledger_leather", Color(0.40, 0.20, 0.10), 0.82, 0.05)
	var m_page := _mat("heist_page", Color(0.95, 0.90, 0.76), 0.85, 0.0)
	_add_box_2d(root, pos, Vector2(12.0, 8.0), 10.2, 1.0, m_leather) # Tapas abiertas
	_add_box_2d(root, pos + Vector2(-2.9, 0), Vector2(5.4, 6.8), 11.2, 0.8, m_page) # Página izquierda
	_add_box_2d(root, pos + Vector2(2.9, 0), Vector2(5.4, 6.8), 11.2, 0.8, m_page) # Página derecha

func _sync_heist_target_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var ah: Dictionary = VillageUnderworldScript.state(vm).get("active_heist", {})
	var active: bool = (not ah.is_empty()) and (not bool(ah.get("stolen", false)))
	var sig: String = "%s|%d|%d" % [str(ah.get("id", "")), int(ah.get("pos_x", 0)), int(ah.get("pos_y", 0))] if active else ""
	if sig == _last_heist_sig and (not active or is_instance_valid(_heist_prop_3d)):
		return
	_last_heist_sig = sig
	if is_instance_valid(_heist_prop_3d):
		_heist_prop_3d.queue_free()
		_heist_prop_3d = null
	if not active:
		return
	var h_id: String = str(ah.get("id", "sello_noble"))
	var h_pos := Vector2(float(ah.get("pos_x", 0.0)), float(ah.get("pos_y", 0.0)))
	var root := Node3D.new()
	root.name = "HeistTarget3D_" + h_id
	stage_root_3d.add_child(root)
	_heist_prop_3d = root

	var m_gold := _mat("heist_gold", Color(0.96, 0.80, 0.28), 0.25, 0.85, Color(0.95, 0.76, 0.22), 0.65)
	var m_silver := _mat("heist_silver", Color(0.88, 0.92, 0.98), 0.20, 0.90, Color(0.75, 0.85, 1.0), 0.55)
	var m_crimson := _mat("heist_crimson", Color(0.76, 0.14, 0.20), 0.75, 0.05)
	var m_leather := _mat("heist_leather", Color(0.42, 0.22, 0.12), 0.82, 0.05)
	var m_page := _mat("heist_page", Color(0.95, 0.90, 0.76), 0.85, 0.0)

	match h_id:
		"sello_noble":
			# Sobre el escritorio del estudio de la Mansión (altura base ~10.2 px)
			_add_box_2d(root, h_pos, Vector2(11.0, 9.0), 10.2, 2.2, m_crimson) # Cojín de terciopelo
			_add_cyl_2d(root, h_pos + Vector2(-2.0, 0.5), 2.6, 12.4, 1.4, m_crimson, 2.6, 10) # Lacre real
			_add_cyl_2d(root, h_pos + Vector2(1.8, -0.5), 2.2, 12.4, 5.2, m_gold, 1.5, 10) # Matriz de oro del sello
			_add_model_2d(root, "props/Scroll_1.gltf", h_pos + Vector2(-5.0, -2.0), 10.2, Vector2(7.0, 5.0), 3.5)
		"caliz_capilla":
			# Sobre el altar de piedra de la Capilla (altura base ~13.0 px)
			if _add_model_2d(root, "props/Chalice.gltf", h_pos, 13.0, Vector2(8.0, 8.0), 8.5) == null:
				_add_cyl_2d(root, h_pos, 3.2, 13.0, 1.8, m_silver, 2.4, 10)
				_add_cyl_2d(root, h_pos, 1.4, 14.8, 3.2, m_silver, 1.4, 10)
				_add_cyl_2d(root, h_pos, 2.6, 18.0, 3.6, m_gold, 3.8, 12)
			else:
				_add_cyl_2d(root, h_pos, 4.4, 12.4, 0.8, m_gold, 4.4, 12) # Patena dorada bajo el cáliz
		_:
			# Libro Mayor de los Gremios sobre la mesa del Ayuntamiento (altura base ~10.2 px)
			if _add_model_2d(root, "props/Book_5.gltf", h_pos, 10.2, Vector2(13.0, 10.0), 4.5) == null:
				_add_box_2d(root, h_pos, Vector2(13.0, 10.0), 10.2, 1.6, m_leather)
				_add_box_2d(root, h_pos, Vector2(11.4, 8.6), 11.8, 1.8, m_page)
			_add_box_2d(root, h_pos + Vector2(-5.8, 0), Vector2(1.4, 8.8), 10.2, 3.6, m_gold)
			_add_box_2d(root, h_pos + Vector2(5.8, 0), Vector2(1.4, 8.8), 10.2, 3.6, m_gold)

func _update_roof_cutaways_and_lighting() -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
	var pl_pos: Vector2 = pl.global_position if is_instance_valid(pl) else Vector2.INF
	var mouse_pos: Vector2 = get_global_mouse_position() if is_inside_tree() else Vector2.INF
	var elev: int = vm.player_elevation_level if vm != null else 0

	for rec in _building_records_3d:
		var rect: Rect2 = rec["rect"]
		var b_root_node: Node3D = rec.get("root") as Node3D
		var roof_cap: Node3D = rec["roof_cap"]
		var loft_root: Node3D = rec["loft_root"]
		if str(rec.get("id", "")) == "building_tavern" and is_instance_valid(b_root_node):
			b_root_node.visible = (elev != -1)
		if not is_instance_valid(roof_cap):
			continue
		var r_near: Rect2 = rect.grow(38.0)
		var r_inside: Rect2 = rect.grow(8.0)
		# B7: En primera persona los tejados y muros altos NO se retiran al entrar: ves el techo encima y las paredes enteras.
		# D1/D3: En la vista cenital del detective, si el cadáver está dentro de un edificio, se retira su tejado.
		var open_roof: bool = r_near.has_point(detective_topdown_pos) if detective_topdown_active else (false if first_person_active else (r_near.has_point(pl_pos) or r_inside.has_point(mouse_pos)))
		roof_cap.visible = not open_roof
		if is_instance_valid(loft_root):
			var on_tavern_stairs: bool = str(rec.get("id", "")) == "building_tavern" and VillageTavern.elevation_height_for(pl_pos, elev) > 6.0
			loft_root.visible = (first_person_active or elev == 1 or on_tavern_stairs) and r_near.has_point(pl_pos)

	# Casa mejorada del jugador: en primera persona conserva el tejado cerrado
	if is_instance_valid(_player_house_roof):
		_player_house_roof.visible = true if first_person_active else not (_player_house_rect.grow(38.0).has_point(pl_pos) or _player_house_rect.grow(8.0).has_point(mouse_pos))

	# Luz diurna/nocturna, cielo con nubes según la hora, niebla atmosférica y farolas eléctricas 3D
	var wc2 = get_node_or_null("/root/WorldClock") if is_inside_tree() else null
	var gm2 = get_node_or_null("/root/GameManager") if is_inside_tree() else null
	var hour: int = int(wc2.current_hour) if wc2 != null else 12
	var minute: int = int(wc2.current_minute) if wc2 != null and "current_minute" in wc2 else 0
	var hour_f: float = float(hour) + float(minute) / 60.0
	var weather_str: String = str(wc2.current_weather) if wc2 != null and "current_weather" in wc2 else "clear"
	var is_foggy_weather: bool = weather_str in ["fog", "rain", "storm"]
	var is_night: bool = (hour >= 19 or hour < 6)
	var is_dusk: bool = (hour in [6, 7, 17, 18])
	var is_dawn_mist: bool = (hour_f >= 5.0 and hour_f <= 8.0)
	var grid_on: bool = gm2 != null and gm2.get_flag("electric_grid_active", false) == true and VillageCulture.is_lamps_powered(vm)
	var pl_indoors: bool = vm != null and is_finite(pl_pos.x) and vm.has_method("_is_pos_inside_any_building") and bool(vm._is_pos_inside_any_building(pl_pos))

	# Interpolación continua de colores del cielo, nubes, sol/luna y niebla según la hora del día y el clima (§3b.2: ambiente más oscuro, sucio y nublado)
	var zenith_col := Color(0.24, 0.34, 0.46)
	var horizon_col := Color(0.54, 0.59, 0.64)
	var sun_col := Color(0.94, 0.88, 0.74)
	var cloud_lit := Color(0.82, 0.80, 0.77)
	var cloud_shade := Color(0.40, 0.44, 0.50)
	var star_vis: float = 0.0
	var sun_ang: float = clampf((hour_f - 6.0) / 13.0, 0.0, 1.0) * PI
	var sun_dir := Vector3(-cos(sun_ang) * 0.78, maxf(0.16, sin(sun_ang) * 0.86), -0.46).normalized()
	if hour_f >= 5.5 and hour_f < 8.0: # Amanecer plomizo-ámbar
		var t_dawn: float = clampf((hour_f - 5.5) / 2.5, 0.0, 1.0)
		zenith_col = Color(0.05, 0.09, 0.18).lerp(Color(0.24, 0.34, 0.46), t_dawn)
		horizon_col = Color(0.68, 0.42, 0.30).lerp(Color(0.54, 0.59, 0.64), t_dawn)
		sun_col = Color(0.92, 0.60, 0.36).lerp(Color(0.94, 0.88, 0.74), t_dawn)
		cloud_lit = Color(0.84, 0.64, 0.50).lerp(Color(0.82, 0.80, 0.77), t_dawn)
		cloud_shade = Color(0.34, 0.28, 0.38).lerp(Color(0.40, 0.44, 0.50), t_dawn)
		star_vis = 1.0 - t_dawn
	elif hour_f >= 17.0 and hour_f < 19.8: # Atardecer ocre-pizarra
		var t_dusk: float = clampf((hour_f - 17.0) / 2.8, 0.0, 1.0)
		zenith_col = Color(0.22, 0.32, 0.44).lerp(Color(0.03, 0.05, 0.10), t_dusk)
		horizon_col = Color(0.72, 0.40, 0.24).lerp(Color(0.07, 0.09, 0.15), t_dusk)
		sun_col = Color(0.92, 0.54, 0.28).lerp(Color(0.52, 0.62, 0.80), t_dusk)
		cloud_lit = Color(0.84, 0.56, 0.38).lerp(Color(0.18, 0.22, 0.32), t_dusk)
		cloud_shade = Color(0.34, 0.22, 0.30).lerp(Color(0.06, 0.08, 0.14), t_dusk)
		star_vis = t_dusk * 0.70
	elif is_night: # Noche cerrada con nubes bajas oscuras
		zenith_col = Color(0.015, 0.024, 0.052)
		horizon_col = Color(0.042, 0.058, 0.10)
		sun_col = Color(0.52, 0.60, 0.78)
		cloud_lit = Color(0.14, 0.18, 0.26)
		cloud_shade = Color(0.04, 0.06, 0.10)
		sun_dir = Vector3(0.42, 0.68, -0.58).normalized()
		star_vis = 0.75

	var cloud_cov: float = 0.88 if is_foggy_weather else (0.72 if (is_dusk or is_dawn_mist) else 0.64)
	if is_foggy_weather:
		horizon_col = horizon_col.lerp(Color(0.48, 0.52, 0.55), 0.55)
		zenith_col = zenith_col.lerp(Color(0.38, 0.42, 0.46), 0.45)

	if _sky_mat != null:
		_sky_mat.set_shader_parameter("zenith_col", zenith_col)
		_sky_mat.set_shader_parameter("horizon_col", horizon_col)
		_sky_mat.set_shader_parameter("sun_dir", sun_dir)
		_sky_mat.set_shader_parameter("sun_col", sun_col)
		_sky_mat.set_shader_parameter("cloud_lit_col", cloud_lit)
		_sky_mat.set_shader_parameter("cloud_shade_col", cloud_shade)
		_sky_mat.set_shader_parameter("cloud_coverage", cloud_cov)
		_sky_mat.set_shader_parameter("star_visibility", star_vis)

	if is_instance_valid(world_env) and world_env.environment != null:
		var env: Environment = world_env.environment
		if first_person_active:
			env.background_mode = Environment.BG_SKY if _sky_res != null else Environment.BG_COLOR
			env.background_color = horizon_col
			env.ambient_light_color = Color(0.22, 0.26, 0.38) if is_night else (Color(0.76, 0.64, 0.54) if is_dusk else Color(0.72, 0.74, 0.76))
			env.ambient_light_energy = 0.20 if is_night else (0.45 if is_dusk else 0.52)
			env.fog_enabled = not pl_indoors
			env.fog_light_color = Color(0.05, 0.07, 0.11) if is_night else horizon_col.lerp(Color(0.46, 0.48, 0.50), 0.35)
			env.fog_light_energy = 0.72 if not is_night else 0.26
			env.fog_sun_scatter = 0.18 if (is_dusk or is_dawn_mist) else 0.06
			env.fog_sky_affect = 0.62
			var base_fog: float = 0.022 if is_night else (0.0135 if (is_dusk or is_dawn_mist) else 0.0095)
			if is_foggy_weather:
				base_fog *= 2.1
			env.fog_density = base_fog
		else:
			env.background_mode = Environment.BG_CLEAR_COLOR
			env.ambient_light_color = Color(0.74, 0.76, 0.78)
			env.ambient_light_energy = 0.52
			env.fog_enabled = (is_foggy_weather or is_dawn_mist) and not pl_indoors
			env.fog_light_color = horizon_col
			env.fog_density = 0.0055 if is_foggy_weather else 0.0028

	if is_instance_valid(fp_lantern_light):
		if first_person_active:
			var carrying_lantern: bool = is_instance_valid(pl) and pl.get("is_carrying_lantern") == true
			fp_lantern_light.visible = is_night or is_dusk or carrying_lantern
			fp_lantern_light.light_energy = 1.25 if carrying_lantern else (0.60 if is_night else 0.30)
			fp_lantern_light.omni_range = 5.6 if carrying_lantern else 3.4
		else:
			fp_lantern_light.visible = false

	if is_instance_valid(sun_light):
		var yaw_deg: float = lerpf(-115.0, -155.0, clampf((hour_f - 6.0) / 13.0, 0.0, 1.0))
		var pitch_deg: float = -38.0 - 18.0 * sin(sun_ang) if not is_night else -48.0
		sun_light.rotation_degrees = Vector3(pitch_deg, yaw_deg, 0.0)
		if is_night:
			sun_light.light_energy = 0.22 # noches más oscuras para que destaquen los charcos de luz de farolas y focos
			sun_light.light_color = Color(0.46, 0.54, 0.76)
		elif is_dusk or is_dawn_mist:
			sun_light.light_energy = 0.74
			sun_light.light_color = sun_col
		else:
			sun_light.light_energy = 0.96
			sun_light.light_color = Color(0.94, 0.89, 0.79)

	# R1: la terraza de la casa de comidas enciende su guirnalda de bombillas al caer la tarde (17:00–2:00)
	var terrace_on: bool = hour >= 17 or hour < 2
	for rn in _restaurant_night_nodes:
		if is_instance_valid(rn):
			(rn as Node3D).visible = terrace_on

	# Con el circuito de farolas cortado (sabotaje), las calles y los focos quedan a oscuras también de noche.
	var lamps_lit: bool = VillageCulture.is_lamps_powered(vm) and (is_night or grid_on)
	for sl_node in _streetlight_nodes_3d:
		var bulb: MeshInstance3D = sl_node["bulb"]
		var lt: OmniLight3D = sl_node["light"]
		if is_instance_valid(bulb):
			bulb.visible = lamps_lit
			bulb.material_override = sl_node["mat_voltaic"] if grid_on else sl_node["mat_warm"]
		if is_instance_valid(lt):
			lt.visible = lamps_lit
			lt.light_color = Color(0.55, 0.96, 1.0) if grid_on else Color(1.0, 0.82, 0.42)
			lt.light_energy = 2.35 if grid_on else 1.75
	for fl_node in _floodlight_nodes_3d:
		var f_bulb: MeshInstance3D = fl_node.get("bulb")
		var f_spot: SpotLight3D = fl_node.get("spot")
		var f_pool: OmniLight3D = fl_node.get("pool")
		if is_instance_valid(f_bulb):
			f_bulb.visible = lamps_lit
			f_bulb.material_override = fl_node["mat_voltaic"] if grid_on else fl_node["mat_warm"]
		if is_instance_valid(f_spot):
			f_spot.visible = lamps_lit
			f_spot.light_color = Color(0.62, 0.96, 1.0) if grid_on else Color(1.0, 0.90, 0.62)
			f_spot.light_energy = 3.2 if grid_on else 2.6
		if is_instance_valid(f_pool):
			f_pool.visible = lamps_lit
			f_pool.light_color = Color(0.62, 0.96, 1.0) if grid_on else Color(1.0, 0.88, 0.56)
			f_pool.light_energy = 2.1 if grid_on else 1.65

# ==============================================================================
# SUELO 3D Y NATURALEZA (2026-11-05): sustituyen a la hierba y a los pinos dibujados en 2D
# ==============================================================================
func _make_ground_shader_mat(key: String, c_prim: Color, c_sec: Color, c_earth: Color, dirt_b: float) -> Material:
	if _mat_cache.has(key):
		return _mat_cache[key]
	if _is_headless:
		return _mat(key + "_hl", c_prim, 0.95, 0.0)
	var sh := Shader.new()
	sh.code = GROUND_TERRAIN_SHADER_CODE
	var sm := ShaderMaterial.new()
	sm.shader = sh
	var t_grass := AssetLib.load_texture("town_textures/floor_ground_grass.png")
	var t_over := AssetLib.load_texture("town_textures/floor_ground_grass_overlay.png")
	var t_dirt := AssetLib.load_texture("town_textures/floor_ground_dirt.png")
	if t_grass != null:
		sm.set_shader_parameter("tex_grass", t_grass)
	if t_over != null:
		sm.set_shader_parameter("tex_overlay", t_over)
	if t_dirt != null:
		sm.set_shader_parameter("tex_dirt", t_dirt)
	sm.set_shader_parameter("tint_primary", c_prim)
	sm.set_shader_parameter("tint_secondary", c_sec)
	sm.set_shader_parameter("tint_earth", c_earth)
	sm.set_shader_parameter("dirt_blend", dirt_b)
	_mat_cache[key] = sm
	return sm

## Suelo opaco 3D con malla de relieve continuo (Fase A: lomas en la llanura, desniveles en el bosque y cuencas hundidas
## en el lago y la ciénaga; plano dentro del pueblo), normales suaves para el sombreado solar y mezcla de biomas por vértice.
func _build_ground_3d() -> void:
	var m_terrain := _make_ground_shader_mat("ground_terrain_heightfield_sh", Color(0.28, 0.40, 0.21), Color(0.20, 0.30, 0.15), Color(0.37, 0.29, 0.19), 0.26)
	if m_terrain is ShaderMaterial:
		(m_terrain as ShaderMaterial).set_shader_parameter("use_vertex_biomes", 1.0)
	var min_x: float = -3450.0
	var max_x: float = 3050.0
	var min_y: float = -1850.0
	var max_y: float = 3250.0
	var step: float = 34.0
	var nx: int = int(ceil((max_x - min_x) / step))
	var ny: int = int(ceil((max_y - min_y) / step))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iy in range(ny):
		var y0: float = min_y + float(iy) * step
		var y1: float = minf(max_y, y0 + step)
		for ix in range(nx):
			var x0: float = min_x + float(ix) * step
			var x1: float = minf(max_x, x0 + step)
			var p00 := Vector2(x0, y0)
			var p10 := Vector2(x1, y0)
			var p01 := Vector2(x0, y1)
			var p11 := Vector2(x1, y1)
			var v00: Vector3 = to_3d(p00, 0.0)
			var v10: Vector3 = to_3d(p10, 0.0)
			var v01: Vector3 = to_3d(p01, 0.0)
			var v11: Vector3 = to_3d(p11, 0.0)
			var n00: Vector3 = terrain_normal_3d(p00, step * 0.5)
			var n10: Vector3 = terrain_normal_3d(p10, step * 0.5)
			var n01: Vector3 = terrain_normal_3d(p01, step * 0.5)
			var n11: Vector3 = terrain_normal_3d(p11, step * 0.5)
			var c00: Color = _terrain_biome_color(p00, n00)
			var c10: Color = _terrain_biome_color(p10, n10)
			var c01: Color = _terrain_biome_color(p01, n01)
			var c11: Color = _terrain_biome_color(p11, n11)
			# Triángulo 1 (p00, p10, p11)
			st.set_color(c00); st.set_normal(n00); st.add_vertex(v00)
			st.set_color(c10); st.set_normal(n10); st.add_vertex(v10)
			st.set_color(c11); st.set_normal(n11); st.add_vertex(v11)
			# Triángulo 2 (p00, p11, p01)
			st.set_color(c00); st.set_normal(n00); st.add_vertex(v00)
			st.set_color(c11); st.set_normal(n11); st.add_vertex(v11)
			st.set_color(c01); st.set_normal(n01); st.add_vertex(v01)
	var ground_mi := MeshInstance3D.new()
	ground_mi.name = "TerrainHeightfield3D"
	ground_mi.mesh = st.commit()
	ground_mi.material_override = m_terrain
	ground_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	terrain_root_3d.add_child(ground_mi)
	# Árboles perimetrales en el horizonte oeste y norte para cerrar el horizonte visual
	var horizon_trees := [
		Vector2(-2180, -680), Vector2(-2260, -480), Vector2(-2320, -260), Vector2(-2280, -80),
		Vector2(-2340, 120), Vector2(-2290, 340), Vector2(-2220, 560), Vector2(-1980, -820),
		Vector2(-1720, -890), Vector2(-1460, -920), Vector2(-1180, -940), Vector2(-880, -960),
	]
	for hti in range(horizon_trees.size()):
		var htp: Vector2 = horizon_trees[hti]
		var ht_file: String = "nature/PineTree_1.obj" if (hti % 2) == 0 else "nature/CommonTree_2.obj"
		var ht_node := _add_model_2d(terrain_root_3d, ht_file, htp, -1.2, Vector2.ZERO, 54.0 + float(hti % 4) * 6.0, float(hti * 47))
		if ht_node != null and nature_root_3d != null:
			_absorb_into_batches(ht_node, htp)
	# Matas de hierba, tréboles, helechos y flores silvestres 3D repartidas por praderas, cunetas, campamento y linde del bosque
	_build_ground_foliage_3d()

func _add_road_strip_3d(parent: Node3D, rect: Rect2, height_px: float, mat: Material) -> MeshInstance3D:
	var step: float = 20.0
	var nx: int = maxi(1, int(ceil(rect.size.x / step)))
	var ny: int = maxi(1, int(ceil(rect.size.y / step)))
	var dx: float = rect.size.x / float(nx)
	var dy: float = rect.size.y / float(ny)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iy in range(ny):
		var y0: float = rect.position.y + float(iy) * dy
		var y1: float = y0 + dy
		for ix in range(nx):
			var x0: float = rect.position.x + float(ix) * dx
			var x1: float = x0 + dx
			var p00 := Vector2(x0, y0)
			var p10 := Vector2(x1, y0)
			var p01 := Vector2(x0, y1)
			var p11 := Vector2(x1, y1)
			var v00: Vector3 = to_3d(p00, height_px)
			var v10: Vector3 = to_3d(p10, height_px)
			var v01: Vector3 = to_3d(p01, height_px)
			var v11: Vector3 = to_3d(p11, height_px)
			var n00: Vector3 = terrain_normal_3d(p00, 12.0)
			var n10: Vector3 = terrain_normal_3d(p10, 12.0)
			var n01: Vector3 = terrain_normal_3d(p01, 12.0)
			var n11: Vector3 = terrain_normal_3d(p11, 12.0)
			st.set_normal(n00); st.add_vertex(v00)
			st.set_normal(n10); st.add_vertex(v10)
			st.set_normal(n11); st.add_vertex(v11)
			st.set_normal(n00); st.add_vertex(v00)
			st.set_normal(n11); st.add_vertex(v11)
			st.set_normal(n01); st.add_vertex(v01)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _build_ground_foliage_3d() -> void:
	if _is_headless or not AssetLib.has_curated_assets():
		return
	var foliage_models: Array[String] = [
		"nature/Plant_1.obj", "nature/Plant_2.obj", "nature/Plant_3.obj",
		"nature/Flowers.obj", "nature/Plant_1.obj", "nature/Wheat.obj",
	]
	var lake_poly_guard: PackedVector2Array = FishingSpotScript.lake_scaled(1.18, 12.0)
	var marsh_poly_guard := PackedVector2Array([
		Vector2(-1890, 195), Vector2(-1620, 150), Vector2(-1325, 165), Vector2(-1180, 240),
		Vector2(-1200, 405), Vector2(-1345, 485), Vector2(-1660, 500), Vector2(-1875, 435),
		Vector2(-1930, 310)
	])
	var idx: int = 0
	for gx in range(-2050, 1480, 95):
		for gy in range(-520, 1280, 95):
			idx += 1
			var jx: float = float(((idx * 73) % 59) - 29)
			var jy: float = float(((idx * 41) % 59) - 29)
			var fp := Vector2(float(gx) + jx, float(gy) + jy)
			# Saltar calzadas principales, plaza central, lago, ciénaga y huellas de edificios
			if absf(fp.y - 50.0) < 30.0 or (fp.x > 375.0 and fp.x < 555.0 and fp.y > 0.0 and fp.y < 95.0):
				continue
			if Geometry2D.is_point_in_polygon(fp, lake_poly_guard) or Geometry2D.is_point_in_polygon(fp, marsh_poly_guard):
				continue
			if fp.distance_to(FishingSpotScript.LAKE_NODE_POS) < 95.0 or terrain_height_px(fp) < -0.8:
				continue
			if VillageRestaurant.RECT.grow(16.0).has_point(fp) or VillageTavern.RECT.grow(16.0).has_point(fp):
				continue
			if fp.x > 160.0 and fp.x < 1380.0 and fp.y > -480.0 and fp.y < 360.0 and ((idx % 3) != 0):
				continue
			var mdl: String = foliage_models[idx % foliage_models.size()]
			var h_f: float = 4.2 + float(idx % 4) * 1.1
			var node_f := _add_model_2d(terrain_root_3d, mdl, fp, -0.8, Vector2.ZERO, h_f, float((idx * 53) % 360))
			if node_f != null and nature_root_3d != null:
				_absorb_into_batches(node_f, fp)
	_flush_batches()


## Lago 3D con abundante agua azul a cota -1.5 px, orillas suaves de hierba con juncos y piedras, y un único muelle a ras del agua.
func _build_lake_3d() -> void:
	var m_lake := _mat("lake_water", Color(0.24, 0.54, 0.82, 0.92), 0.12, 0.14, Color.BLACK, 0.0, "town_textures/floor_ground_water.png", "", 0.55)
	var m_deep := _mat("lake_deep", Color(0.14, 0.34, 0.60, 0.95), 0.10, 0.12, Color.BLACK, 0.0, "town_textures/floor_ground_water.png", "", 0.55)
	for lm in [m_lake, m_deep]:
		(lm as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_flat_poly_2d(terrain_root_3d, FishingSpotScript.lake_scaled(1.12, 8.0), -1.0, m_lake, true)
	_add_flat_poly_2d(terrain_root_3d, FishingSpotScript.lake_scaled(0.66, 0.0), -0.8, m_deep, true)
	# Un único muelle de madera en la orilla este del lago, a ras del agua (-1.0 px) y sin tablón suelto
	var m_dock := _mat("dock_wood", Color(0.62, 0.44, 0.28), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	var dock_c: Vector2 = FishingSpotScript.LAKE_NODE_POS + Vector2(32.0, 0.0)
	var dock_mi := MeshInstance3D.new()
	var dock_bm := BoxMesh.new()
	dock_bm.size = size_3d(Vector2(44.0, 16.0), 1.6)
	dock_mi.mesh = dock_bm
	dock_mi.material_override = m_dock
	dock_mi.position = to_3d_flat(dock_c, 0.1)
	terrain_root_3d.add_child(dock_mi)
	for px in [-15.0, 0.0, 15.0]:
		for py in [-7.0, 7.0]:
			var post_mi := MeshInstance3D.new()
			var post_bm := BoxMesh.new()
			post_bm.size = size_3d(Vector2(2.4, 2.4), 5.2)
			post_mi.mesh = post_bm
			post_mi.material_override = m_dock
			post_mi.position = to_3d_flat(dock_c + Vector2(px, py), -1.8)
			terrain_root_3d.add_child(post_mi)
	# Juncos, matas ribereñas y piedras a lo largo de la orilla exterior del lago
	var shore_pts: PackedVector2Array = FishingSpotScript.lake_scaled(1.15, 8.0)
	for si in range(shore_pts.size()):
		var sp: Vector2 = shore_pts[si]
		if sp.distance_to(dock_c) < 28.0:
			continue
		if (si % 3) == 0:
			_add_model_2d(terrain_root_3d, "nature/Rock_1.obj" if (si % 2) == 0 else "nature/Rock_2.obj", sp, -0.6, Vector2.ZERO, 7.5, float(si * 53))
		_add_model_2d(terrain_root_3d, "nature/Plant_1.obj" if (si % 2) == 0 else "nature/Plant_3.obj", sp + Vector2(3.0, -2.0), -0.5, Vector2.ZERO, 7.2, float(si * 37))


## Superficie plana con la forma de un polígono del mapa 2D, a una altura dada (si absolute_h es true, no suma el relieve).
func _add_flat_poly_2d(parent: Node3D, pts: PackedVector2Array, h_px: float, mat: Material, absolute_h: bool = false) -> MeshInstance3D:
	var idx := Geometry2D.triangulate_polygon(pts)
	if idx.is_empty():
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in idx:
		st.add_vertex(to_3d_flat(pts[i], h_px) if absolute_h else to_3d(pts[i], h_px))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Bloque AA: detalles fijos de los barrios apartados (molino de viento y leñeros de los caseríos; el lago solo tiene un muelle).
func _build_barrios_3d(m_wood: Material) -> void:
	var mp: Vector2 = VillageLots.EAST_MILL_POS
	# (El molino de Kenney es casi solo aspas y desde arriba parece un palo: va el de Quaternius, con su casa de piedra.)
	_add_model_2d(terrain_root_3d, "buildings/Mill.obj", mp, 0.0, Vector2(40, 40), 52.0)
	for wp in [Vector2(-532, 820), Vector2(-522, 920), Vector2(-528, 1020)]:
		for k in range(3):
			var lg := _add_cyl_2d(terrain_root_3d, wp + Vector2(0, k * 5.0 - 5.0), 2.4, 0.0, 16.0, m_wood, 2.4, 7)
			lg.rotation_degrees.z = 90.0
			lg.position = to_3d(wp + Vector2(0, k * 5.0 - 5.0), 2.4 + (3.6 if k == 1 else 0.0))


## Busca árboles talables, vetas de mineral y pinos decorativos 2D (cada pocos segundos, por si se plantan nuevos).
func _scan_nature_sources() -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	_nature_sources.clear()
	var tree_positions_seen: Array[Vector2] = []
	for n in get_tree().get_nodes_in_group("destructible"):
		if not (n is Node2D) or n.get("harvest_type") == null:
			continue
		var ht: int = int(n.get("harvest_type"))
		var kind := ""
		if ht == 1:
			kind = "pine"
			tree_positions_seen.append((n as Node2D).global_position)
		elif ht == 2:
			kind = "rock"
		if kind.is_empty():
			continue
		_nature_sources.append({"node": n, "kind": kind, "sprite": n.get("sprite")})
	var parents: Array = [vm.entities_root]
	for eco in get_tree().get_nodes_in_group("ecosystem_manager"):
		parents.append(eco)
	for par in parents:
		for c in (par as Node).get_children():
			if c is Sprite2D and _is_pine_texture((c as Sprite2D).texture):
				var tp: Vector2 = (c as Sprite2D).global_position
				# Evitar que árboles decorativos se solapen con muros de edificios, bancos del parque u otros árboles
				var overlaps := false
				if "building_footprints" in vm:
					for b_fp in vm.building_footprints:
						if (b_fp["rect"] as Rect2).grow(12.0).has_point(tp):
							overlaps = true
							break
				if not overlaps:
					for existing_tp in tree_positions_seen:
						if existing_tp.distance_squared_to(tp) < 18.0 * 18.0:
							overlaps = true
							break
				if overlaps:
					(c as Sprite2D).visible = false
					continue
				tree_positions_seen.append(tp)
				_nature_sources.append({"node": c, "kind": "deco_pine", "sprite": c})
	_sync_nature_3d(false)
	_scan_props_sources()


## Crea o actualiza el modelo 3D de cada elemento natural y oculta su dibujo 2D mientras el 3D esté activo.
func _sync_nature_3d(only_update: bool) -> void:
	if nature_root_3d == null:
		return
	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	var alive_ids: Dictionary = {}
	for src in _nature_sources:
		var n_v = src["node"]
		if not is_instance_valid(n_v):
			continue
		var n: Node2D = n_v
		var id := n.get_instance_id()
		alive_ids[id] = true
		var rec: Dictionary = _nature_nodes.get(id, {})
		if rec.is_empty() and not only_update:
			rec = _make_nature_3d(n, String(src["kind"]))
			for k in ["tree", "stump"]:
				var nd = rec.get(k)
				if nd is Node3D:
					_absorb_into_batches(nd as Node3D, n.global_position)
			_nature_nodes[id] = rec
		if rec.is_empty():
			continue
		var depleted: bool = bool(n.get("is_depleted")) if n.get("is_depleted") != null else false
		_set_vis3d(rec.get("tree"), n.is_visible_in_tree() and not depleted)
		_set_vis3d(rec.get("stump"), n.is_visible_in_tree() and depleted)
		var spr = src.get("sprite")
		if spr is CanvasItem and is_instance_valid(spr):
			(spr as CanvasItem).self_modulate.a = 0.0 if use_3d else 1.0
	if only_update:
		_flush_batches()
		return
	for id in _nature_nodes.keys():
		if not alive_ids.has(id):
			var r: Dictionary = _nature_nodes[id]
			for k in ["tree", "stump"]:
				var nd = r.get(k)
				if nd is Node3D and is_instance_valid(nd):
					_set_vis3d(nd, false)
					(nd as Node3D).queue_free()
			_nature_nodes.erase(id)
	_flush_batches()


## Pasa las mallas de un árbol o roca a su grupo por zona; el nodo queda vacío y guarda dónde están sus copias.
func _absorb_into_batches(node: Node3D, pos_2d: Vector2) -> void:
	var refs: Array = []
	var inv: Transform3D = nature_root_3d.global_transform.affine_inverse()
	var cell := Vector2i(floori(pos_2d.x / BATCH_CHUNK_PX), floori(pos_2d.y / BATCH_CHUNK_PX))
	for c in node.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null or mi.material_override != null:
			continue
		var plain := true
		for si in range(mi.mesh.get_surface_count()):
			if mi.get_surface_override_material(si) != null:
				plain = false
		if not plain:
			continue
		var key := "%d_%d_%d_%d" % [mi.mesh.get_instance_id(), int(mi.cast_shadow), cell.x, cell.y]
		var b: Dictionary = _batches.get(key, {})
		if b.is_empty():
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Lote_" + key
			mmi.cast_shadow = mi.cast_shadow
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mi.mesh
			mmi.multimesh = mm
			nature_root_3d.add_child(mmi)
			b = {"mmi": mmi, "entries": []}
			_batches[key] = b
		var entries: Array = b["entries"]
		entries.append({"xf": inv * mi.global_transform, "vis": node.visible})
		refs.append([key, entries.size() - 1])
		_batch_dirty[key] = true
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	if not refs.is_empty():
		node.set_meta("batch_refs", refs)

func _set_vis3d(nd, vis: bool) -> void:
	if not (nd is Node3D) or not is_instance_valid(nd):
		return
	var n3 := nd as Node3D
	if n3.visible == vis:
		return
	n3.visible = vis
	if n3.has_meta("batch_refs"):
		for r in n3.get_meta("batch_refs"):
			var b: Dictionary = _batches.get(str(r[0]), {})
			if not b.is_empty():
				b["entries"][int(r[1])]["vis"] = vis
				_batch_dirty[str(r[0])] = true

func _flush_batches() -> void:
	for key in _batch_dirty.keys():
		var b: Dictionary = _batches.get(key, {})
		if b.is_empty() or not is_instance_valid(b["mmi"]):
			continue
		var mm: MultiMesh = (b["mmi"] as MultiMeshInstance3D).multimesh
		var entries: Array = b["entries"]
		mm.instance_count = 0
		mm.instance_count = entries.size()
		var gone := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, -1000, 0))
		for i in range(entries.size()):
			mm.set_instance_transform(i, entries[i]["xf"] if bool(entries[i]["vis"]) else gone)
	_batch_dirty.clear()


static func _is_pine_texture(t: Texture2D) -> bool:
	if t == null:
		return false
	var src: String = t.resource_path if not t.resource_path.is_empty() else String(t.get_meta("src_path", ""))
	return src.find("pine-tree") != -1 or src.ends_with("world/tree.png")


func _make_nature_3d(n: Node2D, kind: String) -> Dictionary:
	var hv: int = absi(int(n.global_position.x * 13.0 + n.global_position.y * 7.0))
	var pos := n.global_position
	var rot: float = float(hv % 360)
	if kind == "pine" or kind == "deco_pine":
		# Árboles variados por zona: robles/hayas frondosos, abedules de corteza blanca y pinos altos
		var village_trees := [
			"nature/CommonTree_1.obj", "nature/CommonTree_2.obj", "nature/BirchTree_1.obj",
			"nature/CommonTree_3.obj", "nature/BirchTree_2.obj", "nature/PineTree_1.obj",
			"nature/CommonTree_4.obj", "nature/BirchTree_3.obj", "nature/PineTree_2.obj",
		]
		var forest_trees := [
			"nature/PineTree_1.obj", "nature/CommonTree_1.obj", "nature/PineTree_2.obj",
			"nature/BirchTree_1.obj", "nature/PineTree_3.obj", "nature/CommonTree_2.obj",
			"nature/PineTree_4.obj", "nature/CommonTree_3.obj", "nature/BirchTree_2.obj",
			"nature/CommonTree_4.obj", "nature/BirchTree_3.obj",
		]
		var files: Array = forest_trees if pos.y >= 680.0 else village_trees
		var h: float = 52.0 + float(hv % 6) * 6.0
		var t := _add_model_2d(nature_root_3d, files[hv % files.size()], pos, -1.4, Vector2.ZERO, h, rot)
		var stump: Node3D = null
		if kind == "pine":
			stump = _add_cyl_2d(nature_root_3d, pos, 5.0, -1.2, 6.2, _mat("tree_stump", Color(0.45, 0.32, 0.20), 0.9, 0.0, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78), 4.5, 8)
			stump.visible = false
		return {"tree": t, "stump": stump}
	if kind == "rock":
		var rfiles := ["nature/Rock_1.obj", "nature/Rock_2.obj", "nature/Rock_3.obj", "nature/Rock_4.obj", "nature/Rock_5.obj"]
		var r := _add_model_2d(nature_root_3d, rfiles[hv % rfiles.size()], pos, -1.4, Vector2.ZERO, 16.0, rot)
		var low := _add_model_2d(nature_root_3d, rfiles[(hv + 2) % rfiles.size()], pos, -1.2, Vector2.ZERO, 6.0, rot + 40.0)
		if low != null:
			low.visible = false
		return {"tree": r, "stump": low}
	return {}


# ==============================================================================
# OBJETOS QUIETOS 2D -> 3D (pozos, farolas, tablón, campamento, huertos, compostador)
# ==============================================================================
## Qué versión 3D lleva cada dibujo 2D, según el nombre de su imagen. "hide" = ya tiene 3D propio, solo se esconde.
const PROP_KIND_BY_TEXTURE := {
	"water_well.png": "well",
	"compost_bin.png": "compost",
	"questboard_1.png": "hide",
	"lamp-post1.png": "hide",
	"bench_0.png": "hide",
	"flowers_plants_0.png": "hide",
	"pine-tree_0.png": "hide",
	"hay_0.png": "hide",
	"hay_2.png": "hide",
	"logs_0.png": "hide",
	"fish_spot_ripples.png": "hide",
	"camp_tent.png": "tent",
	"campfire_pot.png": "campfire",
	"camp_log_seat.png": "log_seat",
	"clothes-line_0.png": "clothesline",
	"iron_sword.png": "weapon_sword",
	"steel_hammer.png": "weapon_hammer",
	"crate.png": "crate",
	"barrel.png": "barrel",
	"weak_wall.png": "weak_wall",
	"sign_1.png": "sign",
	"ancient_generator.png": "generator",
	"auto_sprinkler.png": "sprinkler",
	"soil_dry.png": "soil",
	"soil_wet.png": "soil",
	"coop_feeder_empty.png": "feeder",
	"coop_feeder_half.png": "feeder",
	"coop_feeder_full.png": "feeder",
	"coop_nest_empty.png": "nest",
	"coop_nest_eggs.png": "nest",
	"wild_herb.png": "wild_herb",
	"wild_mushroom.png": "wild_mushroom",
	"rabbit_burrow.png": "rabbit_burrow",
	"fox_den.png": "fox_den",
}

static func _tex_file(t: Texture2D) -> String:
	if t == null:
		return ""
	var src: String = t.resource_path if not t.resource_path.is_empty() else String(t.get_meta("src_path", ""))
	return src.get_file()


func _prop_kind_for(spr: Sprite2D) -> String:
	if spr.name == "CropSprite":
		return "crop"
	var mapped: String = String(PROP_KIND_BY_TEXTURE.get(_tex_file(spr.texture), ""))
	if not mapped.is_empty():
		return mapped
	var p: Node = spr.get_parent()
	if p != null and p.get_parent() != null and p.get_parent().name == "Items":
		return "dropped_item"
	return ""


## Busca los dibujos 2D de objetos quietos: hijos directos del pueblo, ecosistema (hierbas, setas, madrigueras) y piezas del campamento y los huertos.
func _scan_props_sources() -> void:
	_prop_sources.clear()
	_extra_hidden_2d.clear()
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	for c in vm.entities_root.get_children():
		if c is ChickenCoop:
			_coop_node = c
			for sub in c.get_children():
				if sub is Sprite2D and (sub.name == "FeederSprite" or sub.name == "NestSprite"):
					_add_prop_source(sub as Sprite2D)
				elif sub is Line2D or sub is Polygon2D:
					_extra_hidden_2d.append(sub)
			continue
		if c is Sprite2D:
			_add_prop_source(c as Sprite2D)
		elif c is FarmPlot:
			for sub in c.get_children():
				if sub is Sprite2D:
					_add_prop_source(sub as Sprite2D, true)
		elif c is CampSite:
			_camp_node = c
			_collect_camp_sprites(c)
			var hr: Node = c.get_node_or_null("PlayerHouseRoot")
			if hr != null:
				_collect_canvas_items(hr, _extra_hidden_2d)
		elif c is Node2D and String(c.name).begins_with("PetBed_"):
			_build_pet_bed_3d_for(c as Node2D)
	for eco in get_tree().get_nodes_in_group("ecosystem_manager"):
		_collect_camp_sprites(eco)
	var w_root: Node = vm.get_parent()
	if w_root != null and is_instance_valid(w_root):
		for container_name in ["Items", "Environment"]:
			var cont: Node = w_root.get_node_or_null(container_name)
			if cont != null:
				_collect_camp_sprites(cont)
	_sync_props_3d(false)


func _build_pet_bed_3d_for(bed_node: Node2D) -> void:
	if nature_root_3d == null or bed_node == null:
		return
	var b_name := "PetBed3D_" + String(bed_node.name)
	var old := nature_root_3d.get_node_or_null(b_name)
	if old != null:
		old.queue_free()
	var root := Node3D.new()
	root.name = b_name
	nature_root_3d.add_child(root)
	var pos: Vector2 = bed_node.global_position
	var is_dog: bool = int(bed_node.get_meta("pet_type", 0)) == 0
	var m_frame := _mat("pet_bed_wood", Color(0.46, 0.30, 0.16), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.75)
	var m_cush := _mat("pet_bed_cush_dog" if is_dog else "pet_bed_cush_cat", Color(0.74, 0.28, 0.24) if is_dog else Color(0.72, 0.54, 0.38), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.65)
	var m_bowl := _mat("pet_bowl_brass", Color(0.82, 0.68, 0.30), 0.38, 0.65)
	var m_water := _mat("pet_bowl_water", Color(0.22, 0.56, 0.82), 0.20, 0.10)
	_add_box_2d(root, pos, Vector2(19.0, 11.0), 0.0, 2.2, m_frame)
	_add_box_2d(root, pos + Vector2(0, -4.8), Vector2(19.0, 1.8), 2.2, 2.0, m_frame)
	_add_box_2d(root, pos + Vector2(-8.6, 0), Vector2(1.8, 11.0), 2.2, 1.8, m_frame)
	_add_box_2d(root, pos + Vector2(8.6, 0), Vector2(1.8, 11.0), 2.2, 1.8, m_frame)
	_add_box_2d(root, pos + Vector2(0, 0.5), Vector2(15.0, 7.6), 1.8, 1.8, m_cush)
	_add_cyl_2d(root, pos + Vector2(13.5, 1.0), 2.8, 0.0, 2.2, m_bowl, 2.4, 10)
	_add_cyl_2d(root, pos + Vector2(13.5, 1.0), 2.1, 1.6, 0.8, m_water, 2.1, 10)


func _collect_canvas_items(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is CanvasItem and not (c is Area2D):
			out.append(c)
		if c.get_child_count() > 0:
			_collect_canvas_items(c, out)


func _add_prop_source(spr: Sprite2D, in_plot: bool = false) -> void:
	var kind := "crop" if in_plot and spr.name == "CropSprite" else _prop_kind_for(spr)
	if kind == "crop" and not in_plot:
		return
	if not kind.is_empty():
		_prop_sources.append({"sprite": spr, "kind": kind})


## La casa mejorada del jugador (cabaña o casa de piedra) aún no tiene 3D: sus piezas se quedan en 2D.
func _collect_camp_sprites(n: Node) -> void:
	for c in n.get_children():
		if c.name == "PlayerHouseRoot":
			continue
		if c is Sprite2D:
			_add_prop_source(c as Sprite2D)
		if c.get_child_count() > 0:
			_collect_camp_sprites(c)


func _sync_props_3d(only_update: bool) -> void:
	if nature_root_3d == null:
		return
	var use_3d: bool = CharacterAvatar3DScript.use_3d_characters
	var alive: Dictionary = {}
	for src in _prop_sources:
		var spr_v = src["sprite"]
		if not is_instance_valid(spr_v):
			continue # p. ej. el cartel de un solar que ya se construyó
		var spr: Sprite2D = spr_v
		var id := spr.get_instance_id()
		alive[id] = true
		var kind: String = src["kind"]
		var variant := _tex_file(spr.texture) if kind in ["soil", "crop", "feeder", "nest"] else kind
		var rec: Dictionary = _prop_nodes.get(id, {})
		var stale: bool = not rec.is_empty() and (String(rec.get("variant", "")) != variant or (rec.get("pos", Vector2.ZERO) as Vector2).distance_squared_to(spr.global_position) > 0.25)
		if stale:
			var old_root = rec.get("root")
			if old_root is Node3D and is_instance_valid(old_root):
				(old_root as Node3D).queue_free()
			rec = {}
		if rec.is_empty() and (not only_update or stale) and kind != "hide":
			var root := Node3D.new()
			root.name = "Prop3D_" + kind
			nature_root_3d.add_child(root)
			_build_prop_3d(root, kind, spr)
			rec = {"root": root, "variant": variant, "pos": spr.global_position}
			_prop_nodes[id] = rec
		var r3 = rec.get("root")
		if r3 is Node3D and is_instance_valid(r3):
			(r3 as Node3D).visible = spr.is_visible_in_tree() and spr.texture != null
		spr.self_modulate.a = 0.0 if use_3d else 1.0
	for ci in _extra_hidden_2d:
		if is_instance_valid(ci):
			(ci as CanvasItem).self_modulate.a = 0.0 if use_3d else 1.0
	_sync_player_house_3d()
	_sync_coop_3d()
	_sync_sabotage_fx_3d()
	if only_update:
		return
	for id in _prop_nodes.keys():
		if not alive.has(id):
			var r = _prop_nodes[id].get("root")
			if r is Node3D and is_instance_valid(r):
				(r as Node3D).queue_free()
			_prop_nodes.erase(id)


func _build_prop_3d(root: Node3D, kind: String, spr: Sprite2D) -> void:
	var pos: Vector2 = spr.global_position
	var m_wood := _mat("prop_wood", Color(0.62, 0.46, 0.30), 0.88, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	var m_dark := _mat("prop_dark_wood", Color(0.40, 0.28, 0.18), 0.9, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
	var m_iron := _mat("prop_iron", Color(0.30, 0.31, 0.33), 0.6, 0.5)
	match kind:
		"well":
			if _add_model_2d(root, "exterior/Well.obj", pos, 0.0, Vector2.ZERO, 24.0) == null:
				_add_cyl_2d(root, pos, 8.5, 0.0, 7.5, _mat("well_stone", Color(0.58, 0.57, 0.54), 0.9, 0.02), 8.5, 14)
		"compost":
			_add_box_2d(root, pos, Vector2(18, 13), 0.0, 9.0, m_wood)
			_add_box_2d(root, pos, Vector2(15, 10), 8.6, 1.2, _mat("compost_soil", Color(0.25, 0.18, 0.11), 0.98, 0.0))
		"tent":
			var m_canvas := _mat("tent_canvas", Color(0.84, 0.74, 0.54), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "town_textures/T_Trim_Cloth_Normal.png", 0.55)
			var m_flap := _mat("tent_flap", Color(0.72, 0.60, 0.42), 0.90, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.65)
			var m_bedroll := _mat("tent_bedroll", Color(0.58, 0.24, 0.20), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.70)
			var m_pillow := _mat("tent_pillow", Color(0.92, 0.88, 0.78), 0.90, 0.0)
			# Plataforma base de madera + cuerpo principal de lona a dos aguas + cumbrera y postes de madera
			_add_box_2d(root, pos + Vector2(0, 2), Vector2(34, 24), 0.0, 1.6, m_dark)
			_add_prism_2d(root, pos + Vector2(0, 2), Vector2(32, 22), 1.4, 17.5, m_canvas, false)
			_add_box_2d(root, pos + Vector2(0, 2), Vector2(3.0, 25.0), 17.2, 2.2, m_dark)
			_add_cyl_2d(root, pos + Vector2(0, -9.2), 1.4, 1.4, 17.6, m_dark, 1.4, 8)
			_add_cyl_2d(root, pos + Vector2(0, 13.2), 1.3, 1.4, 17.6, m_dark, 1.3, 8)
			# Entrada abierta con faldones enrollados e interior con saco de dormir y almohada 3D
			_add_box_2d(root, pos + Vector2(0, 12.6), Vector2(8.5, 1.2), 1.6, 10.5, _mat("tent_door", Color(0.16, 0.12, 0.09), 0.96, 0.0))
			_add_cyl_2d(root, pos + Vector2(-4.8, 13.0), 1.6, 1.6, 11.2, m_flap, 1.4, 8)
			_add_cyl_2d(root, pos + Vector2(4.8, 13.0), 1.6, 1.6, 11.2, m_flap, 1.4, 8)
			_add_box_2d(root, pos + Vector2(0, 4.5), Vector2(8.0, 13.0), 1.6, 2.2, m_bedroll)
			_add_box_2d(root, pos + Vector2(0, -0.5), Vector2(6.8, 3.4), 3.6, 1.4, m_pillow)
			# Estacas y vientos tensores en las 4 esquinas
			for stake_off in [Vector2(-18.5, -8.5), Vector2(18.5, -8.5), Vector2(-18.5, 12.5), Vector2(18.5, 12.5)]:
				_add_cyl_2d(root, pos + stake_off, 1.0, 0.0, 4.2, m_dark, 0.8, 6)
				_add_box_2d(root, pos + stake_off * 0.82, Vector2(3.6, 0.9), 2.5, 1.2, m_wood)
		"campfire":
			var m_stone_ring := _mat("campfire_stone", Color(0.48, 0.46, 0.44), 0.92, 0.02)
			var m_ember := _mat("campfire_ember", Color(0.95, 0.34, 0.08), 0.40, 0.0, Color(1.0, 0.36, 0.06), 2.4)
			var m_flame := _mat("campfire_flame", Color(1.0, 0.72, 0.18), 0.25, 0.0, Color(1.0, 0.58, 0.10), 3.0)
			var m_stew := _mat("campfire_stew", Color(0.76, 0.42, 0.18), 0.35, 0.05)
			for i in range(8):
				var ang: float = float(i) * TAU / 8.0
				_add_box_2d(root, pos + Vector2(cos(ang), sin(ang)) * 7.2, Vector2(3.8, 3.2), 0.0, 2.6, m_stone_ring, rad_to_deg(ang))
			_add_cyl_2d(root, pos, 5.8, 0.0, 1.6, m_ember, 5.2, 10)
			_add_box_2d(root, pos, Vector2(13.0, 2.4), 0.8, 2.2, m_dark, 28.0)
			_add_box_2d(root, pos, Vector2(13.0, 2.4), 0.8, 2.2, m_dark, -32.0)
			_add_cyl_2d(root, pos + Vector2(-1.8, 0.8), 2.4, 1.4, 4.8, m_flame, 0.4, 7)
			_add_cyl_2d(root, pos + Vector2(1.8, -0.6), 2.0, 1.4, 4.2, m_flame, 0.3, 7)
			_add_model_2d(root, "exterior/Bonfire_Lit.obj", pos, 0.0, Vector2(16, 16), 9.0)
			_add_model_2d(root, "exterior/Cauldron.obj", pos, 3.2, Vector2(11, 11), 7.8)
			_add_cyl_2d(root, pos, 3.8, 8.8, 1.2, m_stew, 3.8, 10)
			# Trípode de hierro forjado sosteniendo la cacerola sobre la hoguera
			for t_ang in [-2.1, 0.0, 2.1]:
				var leg_p := pos + Vector2(cos(t_ang), sin(t_ang)) * 5.2
				_add_cyl_2d(root, leg_p, 0.75, 0.0, 15.5, m_iron, 0.65, 6)
			_add_cyl_2d(root, pos, 4.8, 14.5, 1.2, m_iron, 4.8, 10)
			_add_cyl_2d(root, pos, 0.6, 9.5, 5.5, m_iron, 0.6, 6)
			if not _is_headless:
				var lt := OmniLight3D.new()
				lt.position = to_3d(pos, 10.0)
				lt.light_color = Color(1.0, 0.62, 0.28)
				lt.light_energy = 1.35
				lt.omni_range = 2.8
				root.add_child(lt)
		"log_seat":
			# Tronco tumbado 3D con corteza, anillos de madera en los extremos y calzos de apoyo
			var m_ring := _mat("log_end_ring", Color(0.78, 0.64, 0.42), 0.85, 0.0)
			var log_mi := _add_cyl_2d(root, pos, 3.8, 0.0, 23.0, m_dark, 3.8, 10)
			log_mi.rotation_degrees.z = 90.0
			log_mi.position = to_3d(pos, 3.8)
			for end_x in [-11.6, 11.6]:
				var cap_mi := _add_cyl_2d(root, pos + Vector2(end_x, 0), 3.4, 0.0, 0.6, m_ring, 3.4, 10)
				cap_mi.rotation_degrees.z = 90.0
				cap_mi.position = to_3d(pos + Vector2(end_x, 0), 3.8)
			_add_box_2d(root, pos + Vector2(-7.0, 0), Vector2(3.0, 8.2), 0.0, 2.2, m_wood)
			_add_box_2d(root, pos + Vector2(7.0, 0), Vector2(3.0, 8.2), 0.0, 2.2, m_wood)
		"clothesline":
			# Tendedero 3D con dos postes de madera, cuerda tensada y 3 prendas tendidas (incluyendo la prenda morada)
			var m_rope := _mat("clothesline_rope", Color(0.76, 0.66, 0.48), 0.90, 0.0)
			var m_cloth_purple := _mat("cloth_purple", Color(0.62, 0.46, 0.84), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
			var m_cloth_tunic := _mat("cloth_tunic", Color(0.58, 0.52, 0.42), 0.90, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
			var m_cloth_teal := _mat("cloth_teal", Color(0.24, 0.58, 0.68), 0.88, 0.0, Color.BLACK, 0.0, "town_textures/T_Trim_Cloth_BaseColor.png", "", 0.7)
			for px in [-13.0, 13.0]:
				_add_box_2d(root, pos + Vector2(px, 3.0), Vector2(3.8, 3.8), 0.0, 2.0, m_dark)
				_add_cyl_2d(root, pos + Vector2(px, 3.0), 1.6, 0.0, 16.5, m_wood, 1.4, 8)
				_add_box_2d(root, pos + Vector2(px, 3.0), Vector2(2.6, 2.8), 13.5, 1.8, m_rope)
			_add_box_2d(root, pos + Vector2(0, 3.0), Vector2(26.0, 1.2), 14.0, 1.0, m_rope)
			# Prenda 1 (izquierda): pantalón/tela morada con dos perneras y pinzas de madera
			_add_box_2d(root, pos + Vector2(-7.2, 3.2), Vector2(5.6, 1.6), 9.5, 4.8, m_cloth_purple)
			_add_box_2d(root, pos + Vector2(-8.6, 3.2), Vector2(2.4, 1.6), 5.2, 4.5, m_cloth_purple)
			_add_box_2d(root, pos + Vector2(-5.8, 3.2), Vector2(2.4, 1.6), 5.2, 4.5, m_cloth_purple)
			# Prenda 2 (centro): casaca/camisa con mangas
			_add_box_2d(root, pos + Vector2(0.0, 3.2), Vector2(6.4, 1.8), 4.8, 9.5, m_cloth_tunic)
			_add_box_2d(root, pos + Vector2(0.0, 3.2), Vector2(9.2, 1.6), 11.2, 3.0, m_cloth_tunic)
			# Prenda 3 (derecha): prenda azul turquesa
			_add_box_2d(root, pos + Vector2(7.4, 3.2), Vector2(5.4, 1.6), 9.5, 4.8, m_cloth_teal)
			_add_box_2d(root, pos + Vector2(6.1, 3.2), Vector2(2.3, 1.6), 5.5, 4.2, m_cloth_teal)
			_add_box_2d(root, pos + Vector2(8.7, 3.2), Vector2(2.3, 1.6), 5.5, 4.2, m_cloth_teal)
			for pin_x in [-8.4, -6.0, -1.8, 1.8, 6.2, 8.6]:
				_add_box_2d(root, pos + Vector2(pin_x, 3.2), Vector2(0.9, 2.0), 14.2, 1.6, m_dark)
		"weapon_sword", "weapon_hammer":
			# Espada / Martillo 3D apoyado sobre un caballete/tocón de armero en el campamento
			var m_steel := _mat("weapon_steel_3d", Color(0.82, 0.85, 0.90), 0.25, 0.85)
			var m_hilt := _mat("weapon_hilt_brass", Color(0.86, 0.68, 0.24), 0.32, 0.80)
			_add_cyl_2d(root, pos + Vector2(0, 2.0), 4.8, 0.0, 4.5, m_dark, 4.2, 10)
			_add_box_2d(root, pos + Vector2(0, 2.0), Vector2(8.0, 3.2), 4.2, 1.6, m_wood)
			var w_mdl_path: String = "props/Sword_Bronze.gltf" if kind == "weapon_sword" else "weapons/Hammer_Double.obj"
			var w_mdl := _add_model_2d(root, w_mdl_path, pos + Vector2(0, 1.5), 4.5, Vector2.ZERO, 15.0, 25.0)
			if w_mdl != null:
				w_mdl.rotation_degrees.z = -28.0
			else:
				_add_box_2d(root, pos + Vector2(0, 1.5), Vector2(2.2, 13.0), 5.5, 1.8, m_steel, -25.0)
				_add_box_2d(root, pos + Vector2(-2.2, 3.5), Vector2(5.8, 1.8), 5.2, 2.0, m_hilt, -25.0)
		"crate":
			if _add_model_2d(root, "exterior/Crate.obj", pos, 0.0, Vector2(14, 14), 12.0) == null:
				_add_box_2d(root, pos, Vector2(14, 14), 0.0, 12.0, m_wood)
		"barrel":
			if _add_model_2d(root, "props/Barrel.gltf", pos, 0.0, Vector2(13, 13), 13.0) == null:
				_add_cyl_2d(root, pos, 6.5, 0.0, 13.0, m_dark, 6.0, 10)
		"weak_wall":
			var m_ww := _mat("weak_wall_stone", Color(0.56, 0.54, 0.50), 0.90, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png", "", 0.70)
			_add_box_2d(root, pos, Vector2(18.0, 28.0), 0.0, 2.0, m_ww)
			_add_box_2d(root, pos + Vector2(0.0, -4.0), Vector2(10.0, 18.0), 2.0, 12.0, m_ww)
			_add_box_2d(root, pos + Vector2(0.0, 7.0), Vector2(10.0, 8.0), 2.0, 7.5, m_ww)
		"sign":
			_add_box_2d(root, pos + Vector2(0, 4.0), Vector2(12.5, 5.2), 0.0, 2.2, m_dark)
			_add_box_2d(root, pos + Vector2(-4.5, 4.0), Vector2(2.4, 2.6), 0.0, 14.5, m_dark)
			_add_box_2d(root, pos + Vector2(4.5, 4.0), Vector2(2.4, 2.6), 0.0, 14.5, m_dark)
			_add_box_2d(root, pos + Vector2(0, 4.4), Vector2(16.5, 3.4), 6.2, 7.6, m_wood)
			_add_prism_2d(root, pos + Vector2(0, 4.2), Vector2(18.5, 5.8), 13.6, 3.6, m_dark, false)
		"generator":
			if _add_model_2d(root, "props/Crate_Metal.gltf", pos, 0.0, Vector2(16, 14), 12.0) == null:
				_add_box_2d(root, pos, Vector2(16, 14), 0.0, 12.0, m_iron)
			_add_cyl_2d(root, pos + Vector2(4, -2), 1.6, 12.0, 6.0, m_iron, 1.6, 8)
		"sprinkler":
			_add_cyl_2d(root, pos, 1.4, 0.0, 7.0, m_iron, 1.4, 8)
			_add_cyl_2d(root, pos, 3.0, 7.0, 1.4, m_iron, 1.6, 8)
		"soil":
			var wet: bool = _tex_file(spr.texture) == "soil_wet.png"
			var m_soil := _mat("plot_soil_wet" if wet else "plot_soil_dry", Color(0.30, 0.21, 0.13) if wet else Color(0.50, 0.37, 0.24), 0.97, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.5)
			_add_box_2d(root, pos, Vector2(21, 21), 0.0, 1.6, m_soil)
			for fy in [-6.0, 0.0, 6.0]:
				_add_box_2d(root, pos + Vector2(0, fy), Vector2(19, 2.6), 1.6, 1.0, m_soil)
		"crop":
			_build_crop_3d(root, pos, _tex_file(spr.texture))
		"feeder":
			# Comedero: artesa de tablas con más o menos grano según lo lleno que esté
			var tf := _tex_file(spr.texture)
			_add_box_2d(root, pos, Vector2(18, 8), 0.0, 4.0, m_wood)
			if tf != "coop_feeder_empty.png":
				var grain_h: float = 1.0 if tf == "coop_feeder_half.png" else 2.2
				_add_box_2d(root, pos, Vector2(15, 5.5), 4.0, grain_h, _mat("coop_grain", Color(0.86, 0.72, 0.36), 0.95, 0.0))
		"nest":
			# Nido: caja baja con paja y, si hay, huevos
			_add_box_2d(root, pos, Vector2(16, 13), 0.0, 4.0, m_dark)
			_add_box_2d(root, pos, Vector2(13, 10), 4.0, 1.2, _mat("coop_straw", Color(0.84, 0.74, 0.42), 0.97, 0.0))
			if _tex_file(spr.texture) == "coop_nest_eggs.png":
				var m_egg := _mat("coop_egg", Color(0.96, 0.92, 0.82), 0.7, 0.0)
				for off in [Vector2(-2.5, -1), Vector2(2.5, 0.5), Vector2(0, 2.5)]:
					_add_cyl_2d(root, pos + off, 1.6, 5.0, 2.4, m_egg, 1.0, 6)
		"wild_herb":
			var m_herb := _mat("forest_herb_3d", Color(0.26, 0.74, 0.34), 0.80, 0.0)
			if _add_model_2d(root, "nature/Flowers.obj", pos, -0.5, Vector2(12, 12), 7.5) == null:
				for off in [Vector2(-2.5, -1.5), Vector2(2.5, -1.0), Vector2(0.0, 2.2)]:
					_add_cyl_2d(root, pos + off, 2.2, 0.0, 5.5, m_herb, 0.6, 6)
		"wild_mushroom":
			var m_stem := _mat("mush_stem_3d", Color(0.92, 0.88, 0.78), 0.88, 0.0)
			var m_cap := _mat("mush_cap_3d", Color(0.82, 0.24, 0.18), 0.78, 0.0)
			for m_off in [Vector2(-2.2, 0.8), Vector2(2.4, -1.2), Vector2(0.2, -2.0)]:
				var sc: float = 1.0 if m_off.x < 0.0 else 0.75
				_add_cyl_2d(root, pos + m_off, 1.1 * sc, -0.4, 3.4 * sc, m_stem, 0.9 * sc, 7)
				_add_cyl_2d(root, pos + m_off, 2.8 * sc, 2.6 * sc, 2.2 * sc, m_cap, 0.6 * sc, 8)
		"rabbit_burrow":
			var m_earth := _mat("burrow_earth_3d", Color(0.42, 0.30, 0.19), 0.95, 0.0)
			var m_hole := _mat("burrow_hole_3d", Color(0.08, 0.06, 0.05), 0.98, 0.0)
			_add_cyl_2d(root, pos, 8.5, -0.8, 3.2, m_earth, 5.2, 10)
			_add_cyl_2d(root, pos + Vector2(0, 1.0), 4.2, 1.6, 1.0, m_hole, 3.8, 8)
		"fox_den":
			var m_den_rock := _mat("fox_den_rock_3d", Color(0.46, 0.43, 0.39), 0.92, 0.02)
			var m_den_earth := _mat("burrow_earth_3d", Color(0.42, 0.30, 0.19), 0.95, 0.0)
			var m_den_hole := _mat("burrow_hole_3d", Color(0.08, 0.06, 0.05), 0.98, 0.0)
			_add_cyl_2d(root, pos, 11.5, -1.0, 5.5, m_den_earth, 7.5, 10)
			_add_box_2d(root, pos + Vector2(0, -3.0), Vector2(14.0, 9.0), 0.0, 6.8, m_den_rock)
			_add_cyl_2d(root, pos + Vector2(0, 2.2), 5.2, 1.2, 2.4, m_den_hole, 4.6, 8)
		"dropped_item":
			var m_pouch := _mat("dropped_pouch_3d", Color(0.68, 0.52, 0.32), 0.85, 0.05)
			_add_cyl_2d(root, pos, 3.4, 0.0, 4.2, m_pouch, 2.0, 8)


## Casa mejorada del jugador (nivel 2 = cabaña de madera, 3 = casa de piedra con cofre). Copia la planta de la 2D
## (CampSite._rebuild_house_visuals): mismo centro, tamaño y puerta de 28 px al sur. En nivel 1 es la tienda de campaña.
func _sync_player_house_3d() -> void:
	if not is_instance_valid(_camp_node) or nature_root_3d == null:
		return
	var tier: int = int(_camp_node.get("house_tier"))
	if tier == _player_house_tier and is_instance_valid(_player_house_3d):
		return
	_player_house_tier = tier
	if is_instance_valid(_player_house_3d):
		_player_house_3d.queue_free()
	_player_house_3d = null
	_player_house_roof = null
	if tier <= 1:
		return
	var root := Node3D.new()
	root.name = "PlayerHouse3D"
	nature_root_3d.add_child(root)
	_player_house_3d = root
	var stone: bool = tier >= 3
	var c: Vector2 = _camp_node.global_position + CampSite.TENT_OFFSET + Vector2(-8, -8)
	var size: Vector2 = Vector2(82, 60) if stone else Vector2(68, 52)
	var half: Vector2 = size * 0.5
	_player_house_rect = Rect2(c - half, size)
	var m_floor := _mat("ph_floor_stone" if stone else "ph_floor_wood", Color(0.62, 0.60, 0.56) if stone else Color(0.62, 0.46, 0.30), 0.9, 0.02, Color.BLACK, 0.0, "town_textures/floor_stone.png" if stone else "town_textures/floor_wood_planks.png", "", 0.55)
	var m_wall := _mat("ph_wall_stone" if stone else "ph_wall_timber", Color(0.70, 0.68, 0.64) if stone else Color(0.80, 0.70, 0.56), 0.9, 0.02, Color.BLACK, 0.0, "town_textures/wall_stone.png" if stone else "town_textures/wall_timber.png", "", 0.55)
	var m_roof := _mat("ph_roof_tile" if stone else "ph_roof_thatch", Color(0.72, 0.42, 0.32) if stone else Color(0.80, 0.68, 0.42), 0.92, 0.0, Color.BLACK, 0.0, "town_textures/roof_clay_red_center.png" if stone else "town_textures/roof_thatch_center.png", "", 0.5)
	var wall_h: float = 30.0 if stone else 26.0
	var t: float = 6.0
	var door_w: float = 28.0
	var side_w: float = (size.x - door_w) * 0.5
	_add_box_2d(root, c, size, 0.0, 1.4, m_floor)
	_add_box_2d(root, c + Vector2(0, -half.y), Vector2(size.x, t), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(-half.x, 0), Vector2(t, size.y), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(half.x, 0), Vector2(t, size.y), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(-half.x + side_w * 0.5, half.y), Vector2(side_w, t), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(half.x - side_w * 0.5, half.y), Vector2(side_w, t), 0.0, wall_h, m_wall)
	_add_box_2d(root, c + Vector2(0, half.y), Vector2(door_w + 4.0, t), wall_h - 6.0, 6.0, m_wall) # dintel
	var roof := Node3D.new()
	roof.name = "PlayerHouseRoof"
	root.add_child(roof)
	_add_prism_2d(roof, c, size + Vector2(10, 10), wall_h, 22.0 if stone else 20.0, m_roof, true)
	_player_house_roof = roof
	var bed_p: Vector2 = _camp_node.global_position + CampSite.TENT_OFFSET + Vector2(0, -4)
	if _add_model_2d(root, "props/Bed_Twin1.gltf", bed_p, 1.4, Vector2(18, 28), 9.0) == null:
		_add_box_2d(root, bed_p, Vector2(18, 28), 1.4, 6.0, m_wall)
	if stone:
		_add_model_2d(root, "props/Chest_Wood.gltf", _camp_node.global_position + CampSite.CHEST_OFFSET, 1.4, Vector2(14, 10), 9.0)
	if not _is_headless:
		var lt := OmniLight3D.new()
		lt.position = to_3d(c, wall_h * 0.7)
		lt.light_color = Color(1.0, 0.80, 0.55)
		lt.light_energy = 0.6
		lt.omni_range = 2.0
		roof.add_child(lt)


## Gallinero: cerca de postes y travesaños 3D en el mismo cuadrado que la 2D (76 x 60 px). El tramo de en medio del
## lado sur desaparece cuando un zorro abre un agujero (`is_breached`) y vuelve al repararlo.
func _sync_coop_3d() -> void:
	if not is_instance_valid(_coop_node) or nature_root_3d == null:
		return
	if is_instance_valid(_coop_3d) and (_coop_3d.get_meta("coop_pos", Vector2.ZERO) as Vector2).distance_squared_to(_coop_node.global_position) > 0.25:
		_coop_3d.queue_free()
		_coop_3d = null
		_coop_gap_3d = null
	if not is_instance_valid(_coop_3d):
		_coop_3d = Node3D.new()
		_coop_3d.name = "ChickenCoop3D"
		nature_root_3d.add_child(_coop_3d)
		var c: Vector2 = _coop_node.global_position
		_coop_3d.set_meta("coop_pos", c)
		var m_post := _mat("coop_post", Color(0.50, 0.34, 0.20), 0.9, 0.02, Color.BLACK, 0.0, "town_textures/rf_planks.png", "", 0.78)
		var m_floor := _mat("coop_floor", Color(0.46, 0.36, 0.22), 0.97, 0.0, Color.BLACK, 0.0, "town_textures/floor_ground_dirt.png", "", 0.5)
		_add_box_2d(_coop_3d, c, Vector2(76, 60), 0.0, 0.8, m_floor)
		var sides: Array = [[Vector2(-38, -30), Vector2(38, -30)], [Vector2(-38, -30), Vector2(-38, 30)], [Vector2(38, -30), Vector2(38, 30)],
			[Vector2(-38, 30), Vector2(-12, 30)], [Vector2(12, 30), Vector2(38, 30)]]
		for sd in sides:
			_build_fence_run_3d(_coop_3d, c + (sd[0] as Vector2), c + (sd[1] as Vector2), m_post)
		_coop_gap_3d = Node3D.new()
		_coop_3d.add_child(_coop_gap_3d)
		_build_fence_run_3d(_coop_gap_3d, c + Vector2(-12, 30), c + Vector2(12, 30), m_post)
	_coop_3d.visible = _coop_node.is_visible_in_tree()
	if is_instance_valid(_coop_gap_3d):
		_coop_gap_3d.visible = not bool(_coop_node.get("is_breached"))


func _build_fence_run_3d(parent: Node3D, a: Vector2, b: Vector2, m: Material) -> void:
	var length: float = a.distance_to(b)
	var n_posts: int = maxi(2, int(ceil(length / 12.0)) + 1)
	for i in range(n_posts):
		_add_box_2d(parent, a.lerp(b, float(i) / float(n_posts - 1)), Vector2(2.4, 2.4), 0.0, 11.0, m)
	var mid: Vector2 = (a + b) * 0.5
	var horiz: bool = absf(b.x - a.x) > absf(b.y - a.y)
	var rail_sz: Vector2 = Vector2(length, 1.4) if horiz else Vector2(1.4, length)
	_add_box_2d(parent, mid, rail_sz, 4.0, 1.4, m)
	_add_box_2d(parent, mid, rail_sz, 8.5, 1.4, m)


## Brote, planta a medias o planta madura según la imagen del cultivo 2D.
func _build_crop_3d(root: Node3D, pos: Vector2, tex_name: String) -> void:
	var m_leaf := _mat("crop_leaf", Color(0.36, 0.62, 0.24), 0.9, 0.0)
	if tex_name.begins_with("sprout"):
		for off in [Vector2(-5, -5), Vector2(5, 0), Vector2(-2, 6)]:
			_add_cyl_2d(root, pos + off, 2.0, 1.6, 5.5, m_leaf, 0.3, 5)
		return
	var mature := tex_name.contains("mature")
	var file := "nature/Plant_2.obj"
	var h := 7.0
	if tex_name.begins_with("wheat"):
		file = "nature/Wheat.obj"
		h = 19.0 if mature else 11.0
	elif tex_name.begins_with("cabbage"):
		file = "nature/Bush_1.obj"
		h = 11.0 if mature else 8.0
	elif tex_name.begins_with("carrot"):
		file = "nature/Plant_1.obj"
		h = 12.0 if mature else 8.0
	if _add_model_2d(root, file, pos, 1.6, Vector2(20, 20), h) == null:
		_add_cyl_2d(root, pos, 5.0, 1.6, h, m_leaf, 2.0, 6)
	if mature and tex_name.begins_with("carrot"):
		var m_carrot := _mat("crop_carrot", Color(0.92, 0.48, 0.14), 0.85, 0.0)
		for off in [Vector2(-4, 3), Vector2(3, 4), Vector2(0, -4)]:
			_add_cyl_2d(root, pos + off, 1.4, 1.6, 1.5, m_carrot, 1.0, 6)


## Oculta las tiras planas 2D de muros/puertas/suelos cuando el 3D está activo (usando `self_modulate.a`
## en lugar de `.visible`, de modo que ningún test de estado de puertas o ventanas se vea afectado).
func _sync_2d_flat_visuals(use_3d: bool) -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	var target_a: float = 0.0 if use_3d else 1.0
	# Pinos, rocas y objetos quietos con versión 3D: se esconden en 3D y vuelven al pasar a 2D (F10).
	for src in _nature_sources + _prop_sources:
		var spr_n = src.get("sprite")
		if spr_n is CanvasItem and is_instance_valid(spr_n):
			(spr_n as CanvasItem).self_modulate.a = target_a
	for ci in _extra_hidden_2d:
		if is_instance_valid(ci):
			(ci as CanvasItem).self_modulate.a = target_a
	var inner_rects: Array[Rect2] = [VillageRestaurant.TERRACE.grow(6.0)]
	for b in vm.building_footprints:
		inner_rects.append((b["rect"] as Rect2).grow(-3.0))
	for child in vm.entities_root.get_children():
		# Muebles y suelos 2D dentro de los edificios (camas, mesas, alfombras…): el interior 3D ya los tiene.
		if (child is Sprite2D or child is TextureRect or child is Polygon2D) and (child as CanvasItem).z_index <= 0 and not child.has_meta("flat_2d_building_visual"):
			var cpos: Vector2 = (child as Node2D).global_position if child is Node2D else (child as Control).global_position + (child as Control).size * 0.5
			if child is Polygon2D and cpos == Vector2.ZERO and (child as Polygon2D).polygon.size() > 0:
				cpos = (child as Polygon2D).polygon[0]
			for ir in inner_rects:
				if ir.has_point(cpos):
					(child as CanvasItem).self_modulate.a = target_a
					break
		if child.has_meta("flat_2d_building_visual"):
			if child is CanvasItem:
				(child as CanvasItem).self_modulate.a = target_a
		elif child is StaticBody2D:
			for sub in child.get_children():
				if sub is TextureRect:
					(sub as TextureRect).self_modulate.a = target_a
	for d_entry in vm.building_doors:
		var sc: Sprite2D = d_entry.get("spr_closed")
		var so: Sprite2D = d_entry.get("spr_open")
		if is_instance_valid(sc):
			sc.self_modulate.a = target_a
		if is_instance_valid(so):
			so.self_modulate.a = target_a
	for w_entry in vm.building_windows:
		var sw: Sprite2D = w_entry.get("sprite")
		if is_instance_valid(sw):
			sw.self_modulate.a = target_a
	VillageUnderworldScript.sync_sewer_visibility(vm)
	load("res://scripts/systems/VillageClub.gd").sync_club_visibility(vm)
	for rf in get_tree().get_nodes_in_group("ranch_fence_2d"):
		if rf is CanvasItem and is_instance_valid(rf):
			(rf as CanvasItem).self_modulate.a = target_a


## B4.2: Un taller saboteado echa humo y chispas en 3D hasta que se repara; si llueve, el fuego exterior se apaga.
func _sync_sabotage_fx_3d() -> void:
	if vm == null or not ("shop_businesses" in vm) or not is_instance_valid(nature_root_3d):
		return
	var raining: bool = WorldClock != null and int(WorldClock.current_weather) == 1
	for r_id in vm.shop_businesses.keys():
		var role_int: int = int(r_id)
		var biz: Dictionary = vm.shop_businesses[role_int]
		var sab_d: int = int(biz.get("sabotaged_days", 0))
		var node3d: Node3D = _sabotage_fx_3d.get(role_int) as Node3D if is_instance_valid(_sabotage_fx_3d.get(role_int)) else null
		if sab_d <= 0:
			if node3d != null:
				node3d.queue_free()
			_sabotage_fx_3d.erase(role_int)
			continue
		var s_pos: Vector2 = biz.get("stall_pos", Vector2.ZERO)
		var has_fire: bool = (biz.get("outdoor_fire") == true) and not raining
		if node3d == null:
			node3d = Node3D.new()
			node3d.name = "SabotageFX3D_%d" % role_int
			node3d.position = to_3d(s_pos, 10.0)
			var smoke3 := CPUParticles3D.new()
			smoke3.name = "Smoke3D"
			var sm_mesh := SphereMesh.new()
			sm_mesh.radius = 0.14
			sm_mesh.height = 0.28
			sm_mesh.material = _mat("sab_smoke_3d", Color(0.24, 0.24, 0.27), 0.95, 0.0)
			smoke3.mesh = sm_mesh
			smoke3.amount = 10
			smoke3.lifetime = 1.4
			smoke3.direction = Vector3(0.1, 1.0, -0.05)
			smoke3.spread = 24.0
			smoke3.initial_velocity_min = 0.45
			smoke3.initial_velocity_max = 0.95
			smoke3.gravity = Vector3(0.0, 0.35, 0.0)
			smoke3.emitting = true
			node3d.add_child(smoke3)
			var sparks3 := CPUParticles3D.new()
			sparks3.name = "Sparks3D"
			var sp_mesh := BoxMesh.new()
			sp_mesh.size = Vector3(0.06, 0.06, 0.06)
			sp_mesh.material = _mat("sab_spark_3d", Color(1.0, 0.80, 0.25), 0.2, 0.0, Color(1.0, 0.72, 0.18), 2.2)
			sparks3.mesh = sp_mesh
			sparks3.amount = 8
			sparks3.lifetime = 0.45
			sparks3.explosiveness = 0.35
			sparks3.direction = Vector3(0.0, 1.0, 0.0)
			sparks3.spread = 58.0
			sparks3.initial_velocity_min = 0.8
			sparks3.initial_velocity_max = 1.6
			sparks3.gravity = Vector3(0.0, -3.2, 0.0)
			sparks3.emitting = true
			node3d.add_child(sparks3)
			var fire3 := CPUParticles3D.new()
			fire3.name = "Fire3D"
			var fi_mesh := SphereMesh.new()
			fi_mesh.radius = 0.11
			fi_mesh.height = 0.24
			fi_mesh.material = _mat("sab_fire_3d", Color(1.0, 0.45, 0.12), 0.3, 0.0, Color(1.0, 0.38, 0.08), 2.5)
			fire3.mesh = fi_mesh
			fire3.amount = 8
			fire3.lifetime = 0.55
			fire3.direction = Vector3(0.0, 1.0, 0.0)
			fire3.spread = 26.0
			fire3.initial_velocity_min = 0.35
			fire3.initial_velocity_max = 0.75
			fire3.gravity = Vector3(0.0, 0.6, 0.0)
			fire3.emitting = has_fire
			node3d.add_child(fire3)
			if not _is_headless:
				var lt := OmniLight3D.new()
				lt.name = "FireLight3D"
				lt.light_color = Color(1.0, 0.58, 0.20)
				lt.light_energy = 1.15 if has_fire else 0.35
				lt.omni_range = 2.4
				node3d.add_child(lt)
			nature_root_3d.add_child(node3d)
			_sabotage_fx_3d[role_int] = node3d
		else:
			node3d.position = to_3d(s_pos, 10.0)
			var f3 := node3d.get_node_or_null("Fire3D") as CPUParticles3D
			if f3 != null:
				f3.emitting = has_fire
			var lt3 := node3d.get_node_or_null("FireLight3D") as OmniLight3D
			if lt3 != null:
				lt3.light_energy = 1.15 if has_fire else 0.35
