@tool
extends Node2D

## Escenario 3D Low-Poly / Greybox Estilizado del Valle («La Placa de Petri» - Fase 2)
## - Renderiza terreno, caminos, plaza, pozos, parque, mirador del lago, ciénaga, lavadero,
##   cementerio parroquial, farolas con luz real, todos los edificios y solares, interiores 3D,
##   puertas abatibles, postigos de ventanas, tejados con apertura automática (Cutaway),
##   altillos (+1), alcantarillas (-1) y el asentamiento fronterizo «Puesto del Paso».
## - Se sincroniza 1:1 con las coordenadas del mapa. Toda conversión mapa ↔ 3D pasa por scripts/fisica/Mapa3D.gd
##   (paso del mundo a 3D, docs/PLAN_MUNDO_3D.md).

const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")
const AssetLib = preload("res://scripts/visuals/AssetLibrary3D.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const VillageRestaurant = preload("res://scripts/systems/VillageRestaurant.gd") # R1
const VillageTavern = preload("res://scripts/systems/VillageTavern.gd")
const VillageUnderworldScript = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageHousingScript = preload("res://scripts/systems/VillageHousing.gd")
const RioLagoScript = preload("res://scripts/fisica/RioLago.gd")
const AnclasScript = preload("res://mapa/anclas.gd")
const Zona = preload("res://mapa/zona.gd") ## plaza, lago y ciénaga: su terreno va con su pieza del editor
const EdificioEditorScript = preload("res://mapa/edificio.gd")
const ID_MOLINO := "building_abandoned_mill" ## el molino corta el río: ahí el cauce no se hunde
## Mapa ×E (2026-11-11): mientras se construye el terreno desde las listas del código (coordenadas del mapa original),
## cada posición se estira E veces tal cual (`_add_box_2d`, `_add_cyl_2d`, `_add_model_2d`, polígonos y calles): el
## terreno es el mapa original estirado y no sigue a las piezas movidas (como hasta ahora). Lo que viene del editor o de
## nodos del juego ya está en el mundo actual y se añade con esto apagado.
static var estirar_terreno: bool = false
## Interiores escritos con coordenadas fijas del mapa original (posada, comisaría, trattoria): con esto encendido, cada
## punto que llega a `to_3d` pasa por las anclas (sigue a su edificio, estirado y movido).
static var mover_posiciones: bool = false
const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")

const WORLD_SCALE: float = Mapa3D.ESCALA
const PITCH_DEG: float = Mapa3D.INCLINACION_GRADOS
## Resolución interna: suficiente para que el 3D se lea como 3D (aristas, sombras); las texturas siguen pixeladas.
const VIEWPORT_W: int = 1280
const VIEWPORT_H: int = 720
const RETRO_TRIPLANAR_SCALE: float = 0.78

var vm: Node2D = null
var _is_headless: bool = false
## Editor del mapa (2026-11-09): árboles, arbustos y troncos no se colocan dentro del agua del río (salvo el tronco-puente)
var _permitir_en_rio: bool = false
## Editor del mapa 3D (2026-11-10): la vegetación y rocas del terreno viven en mapa/Mundo3D.tscn → «Vegetacion».
## grabar_vegetacion: el horneado (tools/hornear_vegetacion.gd) anota lo que el código colocaría, sin dibujarlo.
## vegetacion_en_escena: la escena ya la tiene, así que el código deja de colocarla.
static var grabar_vegetacion: bool = false
static var vegetacion_grabada: Array = []
static var vegetacion_en_escena: bool = false
var _construyendo_estatico: bool = false
## Decorado del terreno (puentes, pozos, muelle, vallas, caminos, adornos…) en mapa/Mundo3D.tscn → «Decorado» (2026-11-10).
## Solo el suelo, el agua y las orillas (mallas hechas a mano por código) siguen saliendo del código.
static var decorado_en_escena: bool = false
## Cuánto más «bajo» cuenta un píxel de altura que uno de suelo (≈ 0,53). Los muñecos se estiran 1/_cos_p en vertical
## en la vista desde arriba para cuadrar con las casas; en 1.ª persona no (paso 0b).
var _cos_p: float = Mapa3D.ESCALA / Mapa3D.ALTO

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
var _edificios_de_escena: Dictionary = {} ## id → true de los edificios cargados de su escena (mapa/edificios/)
var _current_building_id: String = ""
var _current_building_floor: int = 0
var _morgue_body_nodes_3d: Array[Node3D] = []
var _jail_gate_pivot_3d: Node3D = null
var _reja_celda_cerrada: Vector3 = Vector3.ZERO ## sitio de la reja cerrada, respecto a su edificio
const REJA_CELDA_RECORRIDO_PX: float = 22.0     ## lo que se desliza hacia el oeste al abrirse
var _puertas_interiores = preload("res://scripts/visuals/PuertasInteriores3D.gd").new() # hojas de los cuartos de la posada
var _rastros = preload("res://scripts/visuals/Rastros3D.gd").new() # sangre, huellas y campamentos de vagabundos
var _streetlight_nodes_3d: Array[Dictionary] = []
var _floodlight_nodes_3d: Array[Dictionary] = []
var _last_buried_count: int = -1
var _cutaway_accum: float = 0.0
var nature_root_3d: Node3D = null
var _nature_accum: float = 10.0
var _nature_scan_accum: float = 10.0
var _nature_sources: Array = [] # [{"node": Node2D, "kind": "pine"|"rock"|"forage_herb"|…}]
var _nature_nodes: Dictionary = {} # instance_id -> {"tree": Node3D, "stump": Node3D}
## Rendimiento: árboles y rocas iguales se dibujan juntos por zonas (una sola orden a la tarjeta por modelo y zona).
const BATCH_CHUNK_PX: float = 512.0
var _batches: Dictionary = {} # clave -> {"mmi": MultiMeshInstance3D, "entries": [{"xf": Transform3D, "vis": bool}]}
var _batch_dirty: Dictionary = {}
var _prop_sources: Array = [] # [{"sprite": Sprite2D, "kind": String}] objetos quietos 2D con su versión 3D
var _prop_nodes: Dictionary = {} # instance_id del sprite -> {"root": Node3D, "variant": String}
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
uniform float escala_mundo = 1.0; // Mapa3D.K: el dibujo del suelo se pensó en la escala vieja (paso 0b)

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
	vec2 w_uv = v_world_pos.xz / escala_mundo;
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
	// Detalle de la textura: más de cerca (se ven las briznas), menos de lejos (ni baldosas ni hormigueo)
	float dist_cam = length(v_world_pos - CAMERA_POSITION_WORLD);
	float detalle = mix(0.46, 0.20, smoothstep(6.0, 40.0, dist_cam));
	g_mid = mix(vec3(0.78), g_mid, detalle);

	vec3 g_over = mix(vec3(0.78), texture(tex_overlay, g_rot(w_uv + warp * 0.8, 1.12) * 1.95 + vec2(0.37, 0.61)).rgb, 0.24);
	vec3 d_tex = mix(vec3(0.75), texture(tex_dirt, g_rot(w_uv + warp * 0.6, 0.33) * 1.75).rgb, 0.32);

	float macro = g_noise(w_uv * 0.14);
	float meso = g_noise(w_uv * 0.55 + warp);
	float micro = g_noise(w_uv * 3.8 + warp * 2.0);
	float blade = g_noise(w_uv * 16.0 + vec2(macro, meso) * 2.5);

	float b_mix = smoothstep(0.25, 0.75, macro * 0.65 + meso * 0.35);
	vec3 meadow_tint = mix(tint_primary, tint_secondary, b_mix);
	// Césped sin dibujo repetido (usuario, 2026-11-07; hecho 2026-11-11): manchas grandes e irregulares de hierba seca
	// (amarillenta) y de hierba espesa (más oscura), con bordes rotos por el ruido fino
	float mancha = g_noise(w_uv * 0.075 + vec2(41.3, 17.7)) * 0.6 + g_noise(w_uv * 0.21 + vec2(8.9, 27.1)) * 0.4;
	float seca = smoothstep(0.56, 0.72, mancha + (micro - 0.5) * 0.10);
	float espesa = smoothstep(0.42, 0.26, mancha + (micro - 0.5) * 0.10);
	meadow_tint = mix(meadow_tint, meadow_tint * vec3(1.30, 1.16, 0.62) + vec3(0.10, 0.07, 0.0), seca * 0.9);
	meadow_tint = mix(meadow_tint, meadow_tint * vec3(0.74, 0.88, 0.72), espesa * 0.7);
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
	// Briznas y calvas pequeñas de cerca (se funden de lejos para que no hormiguee)
	float contraste = mix(0.20, 0.08, smoothstep(6.0, 40.0, dist_cam));
	base_grass *= mix(1.0 - contraste, 1.0 + contraste, micro * 0.45 + blade * 0.55);

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
static var fp_yaw: float = 0.0      # ángulo horizontal en el plano 2D (0 = Este hacia el valle, PI/2 = Sur, -PI/2 = Norte)
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
	_fp_shake_amp = maxf(_fp_shake_amp, clampf(amp * 0.012, 0.015, 0.095) * Mapa3D.K)
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
	if x > 352.0 and x < 578.0 and y > -18.0 and y < 114.0:
		var px_in: float = smoothstep(356.0, 382.0, x) * (1.0 - smoothstep(548.0, 574.0, x))
		var py_in: float = smoothstep(-14.0, 8.0, y) * (1.0 - smoothstep(88.0, 110.0, y))
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


static func _river_bank_terrace_height_px(y: float) -> float:
	var sample_x: float = RioLagoScript.river_center_x(y) + RioLagoScript.river_half_width(y) + 18.0
	# Editor del mapa (2026-11-09): la cota del agua sale del suelo real junto al río (antes, de las terrazas del pueblo con
	# «y» recortada, y el río dibujado más al norte quedaba levantado sobre un terraplén)
	var h_der: float = terrain_height_px(Vector2(sample_x, y)) - _river_cut_px(Vector2(sample_x, y))
	if y >= -825.0 and y <= 650.0:
		return h_der # dentro del pueblo, como siempre (orilla este)
	# Fuera del pueblo el agua no puede quedar por encima de la orilla más baja
	var cx: float = RioLagoScript.river_center_x(y)
	var hw: float = RioLagoScript.river_half_width(y)
	var h_min: float = h_der
	for off in [-18.0, -30.0, 30.0]:
		var sx: float = cx + (hw + absf(off)) * signf(off)
		h_min = minf(h_min, terrain_height_px(Vector2(sx, y)) - _river_cut_px(Vector2(sx, y)))
	# …pero nunca por debajo del lecho (escalones del terreno junto al pueblo dejaban el agua tapada)
	return maxf(h_min, terrain_height_px(Vector2(cx, y)) + 1.4)


## Altura (px, sin relieve) de la lámina de agua del río a la altura `y` del mapa: un poco por encima de la orilla. La
## usan el dibujo del río y el agua de juego (scripts/fisica/Agua.gd).
static func superficie_rio_px(y: float) -> float:
	return _river_bank_terrace_height_px(y) + 0.34


## Parte del hundimiento del cauce en un punto (para no contarla al medir la orilla).
static func _river_cut_px(pos_2d: Vector2) -> float:
	var y: float = pos_2d.y
	if y < RioLagoScript.river_y_start() or y > RioLagoScript.river_y_end() or RioLagoScript.ABANDONED_MILL_RECT.grow(4.0).has_point(EdificioEditorScript.a_plano(ID_MOLINO, pos_2d)):
		return 0.0
	var riv_hw: float = RioLagoScript.river_half_width(y)
	var d_riv: float = absf(pos_2d.x - RioLagoScript.river_center_x(y))
	if d_riv >= riv_hw + 20.0:
		return 0.0
	return -1.8 * (1.0 - smoothstep(riv_hw * 0.5, riv_hw + 20.0, d_riv))


## Árbol, arbusto o tronco cuyo centro cae dentro del agua del río (que el usuario puede redibujar en el editor del mapa).
static func es_vegetacion_en_rio(rel_path: String, center_2d: Vector2) -> bool:
	if not rel_path.begins_with("nature/"):
		return false
	var f: String = rel_path.get_file()
	if not ("Tree" in f or "Willow" in f or "Bush" in f or "WoodLog" in f or "Stump" in f or "Plant" in f or "Grass" in f or "mushroom" in f):
		return false
	return en_cauce_del_rio(center_2d, 2.0)


## Dentro del cauce del río, haya o no puente o vado encima.
static func en_cauce_del_rio(p: Vector2, margen: float = 0.0) -> bool:
	if p.y < RioLagoScript.river_y_start() - 5.0 or p.y > RioLagoScript.river_y_end() + 5.0:
		return false
	var b: Vector2 = RioLagoScript.river_banks_at(p.y)
	return p.x >= b.x - margen and p.x <= b.y + margen


static func surface_elevation_offset_px(pos_2d: Vector2) -> float:
	if RioLagoScript.is_in_river_crossing(pos_2d, 3.0):
		var bank_h: float = _river_bank_terrace_height_px(pos_2d.y)
		var base_t: float = terrain_height_px(pos_2d)
		var cr_boost: float = 1.6 if absf(pos_2d.y - 50.0) <= 24.0 else 0.9
		for cr in RioLagoScript.river_crossings():
			if String(cr.get("kind", "")) == "log" and absf(pos_2d.y - float(cr["pos"].y)) <= float(cr["half_h"]) + 3.0:
				cr_boost = 4.6 # se camina por encima del tronco caído (8 de grosor, apoyado 3 por debajo de la orilla)
		return maxf(0.45, (bank_h - base_t) + cr_boost)
	if Rect2(Vector2(384.0, 8.0), Vector2(162.0, 80.0)).has_point(pos_2d):
		return 0.48
	if _road_flat_mask(pos_2d) < 0.85:
		return 0.28
	return 0.15


## Relieve del terreno en un punto, con memoria por celdas de RELIEVE_CELDA_PX (rendimiento, noche del 2026-11-11): se
## preguntaba cientos de veces por fotograma (cuerpos, muñecos, animales, vista) y cada cálculo recorre el río, el lago,
## la ciénaga, las terrazas y los caminos. El terreno no cambia salvo al cargar otro río (`olvidar_relieve`).
const RELIEVE_CELDA_PX: float = 4.0
static var _relieve_cache: Dictionary = {}

static func terrain_height_px(pos_2d: Vector2) -> float:
	var celda := Vector2i(floori(pos_2d.x / RELIEVE_CELDA_PX), floori(pos_2d.y / RELIEVE_CELDA_PX))
	var h = _relieve_cache.get(celda)
	if h == null:
		h = _terrain_height_px_calc((Vector2(celda) + Vector2(0.5, 0.5)) * RELIEVE_CELDA_PX)
		_relieve_cache[celda] = h
	return h


static func olvidar_relieve() -> void:
	_relieve_cache.clear()


## Distancia (px del mapa original) de `o` al contorno del lago: negativa dentro del agua.
static func _lake_signed_dist_px(o: Vector2) -> float:
	var poli: PackedVector2Array = RioLagoScript.lake_outline()
	var d: float = INF
	for i in range(poli.size()):
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(o, poli[i], poli[(i + 1) % poli.size()])
		d = minf(d, o.distance_to(q))
	return -d if Geometry2D.is_point_in_polygon(o, poli) else d


static func _terrain_height_px_calc(pos_2d: Vector2) -> float:
	# Mapa ×E: las lomas, cuencas y terrazas están escritas en el mapa original → se miran en `o` (el mundo encogido E
	# veces); el río viene del editor (mundo actual) → se mira en `pos_2d`
	var o: Vector2 = Zona.desestirar(pos_2d) # las zonas de terreno (lago, ciénaga, plaza) van con su pieza
	var x: float = o.x
	var y: float = o.y

	# 0. Cuenca suave del Río y del Arroyo del Bosque Norte (y = -1180..940)
	var river_cut_h: float = 0.0
	# Editor del mapa (2026-11-09): el río puede llegar a lomas y bosque; ahí el relieve se allana en su cauce para que el agua no quede bajo tierra
	var river_flat: float = 0.0
	if pos_2d.y >= RioLagoScript.river_y_start() and pos_2d.y <= RioLagoScript.river_y_end() and not RioLagoScript.ABANDONED_MILL_RECT.grow(4.0).has_point(o):
		var riv_cx: float = RioLagoScript.river_center_x(pos_2d.y)
		var riv_hw: float = RioLagoScript.river_half_width(pos_2d.y)
		var d_riv: float = absf(pos_2d.x - riv_cx)
		if d_riv < riv_hw + 20.0:
			river_cut_h = -1.8 * (1.0 - smoothstep(riv_hw * 0.5, riv_hw + 20.0, d_riv))
		river_flat = 1.0 - smoothstep(riv_hw + 12.0, riv_hw + 90.0, d_riv)

	# 1. Cuenca baja y de orillas suaves del Lago del Oeste: sigue el contorno del agua (RioLago.lake_outline), así la
	#    orilla que se ve es la misma que la de nadar, chocar y el muelle (mapa ×E: antes la cuenca era una elipse a ojo)
	var lake_h: float = 0.0
	if x < -600.0 and x > -1180.0 and y > 30.0 and y < 300.0:
		var d_in: float = _lake_signed_dist_px(o) # negativo dentro del agua
		if d_in < 11.0:
			# Lecho suave (-5.8 px) bajo la lámina de agua (-0.8 px); la lámina (-1 px) corta justo en el contorno y la orilla
			# sube tendida en los 11 px de fuera
			lake_h = -5.8 * (1.0 - smoothstep(-29.0, 11.0, d_in))

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
	var north_lim_y: float = -1155.0 if (x > 25.0 and x < 310.0) else -825.0
	var dx_v: float = (-665.0 - x) if x < -665.0 else ((x - 1785.0) if x > 1785.0 else 0.0)
	var dy_v: float = (north_lim_y - y) if y < north_lim_y else ((y - 650.0) if y > 650.0 else 0.0)
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
		return _village_terrace_height_px(o) + river_cut_h

	var d_out: float = minf(d_village, minf(d_camp, d_cas))
	var village_edge_h: float = _village_terrace_height_px(Vector2(clampf(x, -665.0, 1785.0), clampf(y, north_lim_y, 650.0))) * (1.0 - smoothstep(0.0, 160.0, d_village))
	var outer_mask: float = smoothstep(0.0, 175.0, d_out) * _road_flat_mask(o)

	# 4. Lomas anchas y suaves en la Llanura Salvaje y borde exterior (sin montículos aislados; pendiente < 10°)
	var plains_h: float = 0.0
	if x < -665.0 or y < north_lim_y or x > 1785.0:
		var w1: float = sin(x * 0.0024 + 0.5) * cos(y * 0.0028 - 0.3)
		var w2: float = sin((x * 0.0036 - y * 0.0030) + 1.4) * 0.55
		var swell: float = maxf(0.0, w1 + w2 * 0.70 + 0.35)
		plains_h = swell * 13.5
		# Horizonte suavemente elevado en el borde lejano del mundo para tapar el corte del suelo
		var rim_w: float = smoothstep(-1850.0, -2550.0, x) * 14.0
		var rim_n: float = smoothstep(-950.0, -1450.0, y) * 12.0
		var rim_e: float = smoothstep(1900.0, 2500.0, x) * 12.0
		plains_h += rim_w + rim_n + rim_e
		var near_water: float = clampf(absf(lake_h + marsh_h + river_cut_h) / 2.2, 0.0, 1.0)
		plains_h *= (1.0 - near_water * 0.90)

	# 5. Ondulaciones anchas y bajas en el Bosque Profundo (sur, y > 650)
	var forest_h: float = 0.0
	if y > 650.0:
		var fy: float = smoothstep(650.0, 880.0, y)
		var fw1: float = sin(x * 0.0026 - 0.6) * sin((y - 700.0) * 0.0028 + 0.5)
		var fw2: float = cos(x * 0.0040 + y * 0.0034 + 1.1) * 0.50
		var rim_s: float = smoothstep(2050.0, 2650.0, y) * 14.0
		forest_h = ((fw1 * 11.0 + fw2 * 7.5 + 5.5) + rim_s) * fy

	return (plains_h + forest_h) * outer_mask * (1.0 - river_flat) + village_edge_h + lake_h + marsh_h + river_cut_h


## Mapa → 3D sin relieve del suelo.
func to_3d_flat(pos_2d: Vector2, h_px: float = 0.0) -> Vector3:
	if mover_posiciones:
		pos_2d = AnclasScript.mover(pos_2d)
	return Mapa3D.a_3d(pos_2d, h_px)


## Mapa → 3D sobre el relieve del suelo (por debajo de −40 px se entiende «bajo tierra» y no se suma el relieve).
func to_3d(pos_2d: Vector2, h_px: float = 0.0) -> Vector3:
	if mover_posiciones:
		pos_2d = AnclasScript.mover(pos_2d)
	return Mapa3D.a_3d(pos_2d, h_px + (terrain_height_px(pos_2d) if h_px > -40.0 else 0.0))


func terrain_normal_3d(pos_2d: Vector2, step_px: float = 10.0) -> Vector3:
	var px1: Vector3 = to_3d(pos_2d + Vector2(step_px, 0.0), 0.0)
	var px0: Vector3 = to_3d(pos_2d - Vector2(step_px, 0.0), 0.0)
	var pz1: Vector3 = to_3d(pos_2d + Vector2(0.0, step_px), 0.0)
	var pz0: Vector3 = to_3d(pos_2d - Vector2(0.0, step_px), 0.0)
	var n: Vector3 = (pz1 - pz0).cross(px1 - px0)
	return n.normalized() if n.length_squared() > 0.000001 else Vector3.UP


func _terrain_biome_color(pos_2d: Vector2, normal_3d: Vector3) -> Color:
	# Mapa ×E: bosque, llanura, lago y ciénaga están escritos en el mapa original → se miran en el mundo encogido E veces;
	# el río viene del editor (mundo actual) → se mira en `pos_2d`
	var o: Vector2 = Zona.desestirar(pos_2d) # las zonas de terreno (lago, ciénaga, plaza) van con su pieza
	var x: float = o.x
	var y: float = o.y
	var edge_wave: float = sin(x * 0.009 + 1.2) * 32.0 + cos(x * 0.021 - 0.5) * 16.0
	var w_forest: float = maxf(smoothstep(665.0 + edge_wave, 775.0 + edge_wave, y), smoothstep(-735.0, -830.0, y))
	var w_plains: float = smoothstep(-940.0, -1180.0, x) * smoothstep(20.0, -90.0, y)
	var w_mud: float = 0.0
	if pos_2d.y >= RioLagoScript.river_y_start() and pos_2d.y <= RioLagoScript.river_y_end():
		var riv_cx: float = RioLagoScript.river_center_x(pos_2d.y)
		var riv_hw: float = RioLagoScript.river_half_width(pos_2d.y)
		var d_riv: float = absf(pos_2d.x - riv_cx)
		if d_riv < riv_hw + 9.0:
			w_mud = maxf(w_mud, (1.0 - smoothstep(riv_hw * 0.65, riv_hw + 9.0, d_riv)) * 0.62)
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
	return Mapa3D.tam_a_3d(sz_2d, h_px).max(Vector3(0.02, 0.01, 0.02) * Mapa3D.K)

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
			# La medida es de la escala vieja: / K desde el paso 0b para que se repitan igual.
			var ts := (RETRO_TRIPLANAR_SCALE if tex_rel.begins_with("town_textures/") else triplanar_scale) / Mapa3D.K
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
		"rot_y_deg": rot_y_deg,
	})

func check_furniture_overlaps(warn_on_overlap: bool = true) -> Array[String]:
	var overlaps: Array[String] = []
	var table_names: Array[String] = ["Table_Large", "Workbench", "Workbench_Drawers", "TerraceRoundTable", "BackroomRoundTable", "PokerTable"]
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
			# Vigilar orientación de cada silla: el asiento debe mirar hacia su mesa o escritorio más cercano
			if str(a.get("name", "")).begins_with("Chair_"):
				var c_pos: Vector2 = a.get("center", Vector2.ZERO)
				var best_tbl: Dictionary = {}
				var best_d2: float = 36.0 * 36.0
				for k in range(items.size()):
					if k == i:
						continue
					var cand: Dictionary = items[k]
					if str(cand.get("name", "")) in table_names:
						var d2: float = c_pos.distance_squared_to(cand.get("center", Vector2.ZERO))
						if d2 < best_d2:
							best_d2 = d2
							best_tbl = cand
				if best_tbl.is_empty() and _edificios_de_escena.has(str(key).get_slice("#", 0)):
					pass # en una escena las mesas hechas de cajas (póker, veladores) no son piezas: no se puede saber
				elif best_tbl.is_empty():
					var msg_no_t := "[WorldStage3D] Silla sin mesa cercana en %s: '%s' en %s" % [str(key), str(a["name"]), str(c_pos)]
					overlaps.append(msg_no_t)
					if warn_on_overlap:
						push_warning(msg_no_t)
				else:
					var t_pos: Vector2 = best_tbl.get("center", Vector2.ZERO)
					var to_tbl: Vector2 = (t_pos - c_pos).normalized()
					var yaw_r: float = deg_to_rad(float(a.get("rot_y_deg", 0.0)))
					var seat_fwd := Vector2(sin(yaw_r), cos(yaw_r))
					var align_dot: float = seat_fwd.dot(to_tbl)
					if align_dot < 0.80:
						var msg_rot := "[WorldStage3D] Silla al revés o mal orientada en %s: '%s' en %s (rot_y=%.1f°, dot=%.2f con '%s' en %s)" % [
							str(key), str(a["name"]), str(c_pos), float(a.get("rot_y_deg", 0.0)), align_dot, str(best_tbl["name"]), str(t_pos)
						]
						overlaps.append(msg_rot)
						if warn_on_overlap:
							push_warning(msg_rot)
	return overlaps

func _add_model_2d(parent: Node3D, rel_path: String, center_2d: Vector2, bottom_h_px: float, sz_2d: Vector2 = Vector2.ZERO, height_px: float = 24.0, rot_y_deg: float = 0.0) -> Node3D:
	if estirar_terreno:
		center_2d = Zona.estirar(center_2d)
	if not _permitir_en_rio and es_vegetacion_en_rio(rel_path, center_2d):
		return null
	if _construyendo_estatico and not _permitir_en_rio and rel_path.begins_with("nature/") and (grabar_vegetacion or vegetacion_en_escena):
		if grabar_vegetacion:
			vegetacion_grabada.append({"modelo": rel_path, "pos": center_2d, "base": bottom_h_px, "tam": sz_2d, "alto": height_px, "giro": rot_y_deg})
		return null
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
		fit_h = maxf(0.05, Mapa3D.alto_a_3d(height_px))
	var inst := AssetLib.instantiate_model(rel_path, target_sz, fit_h, true, true)
	if inst == null:
		return null
	inst.position = to_3d(center_2d, bottom_h_px)
	if absf(rot_y_deg) > 0.01:
		inst.rotation_degrees.y = rot_y_deg
	parent.add_child(inst)
	return inst

## Partículas (humo, chispas, fuego, polvo) escritas en la escala vieja: tamaño, velocidad, gravedad y zona de salida
## por K (paso 0b). El tamaño se agranda con la escala de cada partícula.
func _particulas_a_metros(p: CPUParticles3D) -> void:
	var k := Mapa3D.K
	p.initial_velocity_min *= k
	p.initial_velocity_max *= k
	p.gravity *= k
	p.emission_box_extents *= k
	p.emission_sphere_radius *= k
	p.scale_amount_min *= k
	p.scale_amount_max *= k


func _add_box_2d(parent: Node3D, center_2d: Vector2, sz_2d: Vector2, bottom_h_px: float, height_px: float, mat: Material, rot_y_deg: float = 0.0, absolute_h: bool = false) -> MeshInstance3D:
	if estirar_terreno:
		center_2d = Zona.estirar(center_2d)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size_3d(sz_2d, height_px)
	mi.mesh = bm
	mi.material_override = mat
	var h_mid: float = bottom_h_px + height_px * 0.5
	mi.position = to_3d_flat(center_2d, h_mid) if absolute_h else to_3d(center_2d, h_mid)
	if absf(rot_y_deg) > 0.01:
		mi.rotation_degrees.y = rot_y_deg
	parent.add_child(mi)
	return mi

func _add_cyl_2d(parent: Node3D, center_2d: Vector2, radius_px: float, bottom_h_px: float, height_px: float, mat: Material, top_radius_px: float = -1.0, radial_segs: int = 12) -> MeshInstance3D:
	if estirar_terreno:
		center_2d = Zona.estirar(center_2d)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = maxf(0.01, radius_px * WORLD_SCALE)
	cm.top_radius = maxf(0.0, (radius_px if top_radius_px < 0.0 else top_radius_px) * WORLD_SCALE)
	cm.height = maxf(0.01, Mapa3D.alto_a_3d(height_px))
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


static var perf_on: bool = false
static var perf_usec: Dictionary = {}

static func _perf_add(part: String, since: int) -> int:
	var now: int = Time.get_ticks_usec()
	perf_usec[part] = int(perf_usec.get(part, 0)) + (now - since)
	return now

