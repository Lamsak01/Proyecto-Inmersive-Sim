@tool
extends Node2D
class_name FarmPlot

## Parcela de Cultivo Sistémica (Estilo Project Zomboid Ágil) — Fase 4.2
## Soporta 3 cultivos (Zanahoria: 2 días, Col: 3 días, Trigo: 4 días), riego diario,
## abonado orgánico (+1 día de avance inmediato y +1 cosecha extra), devolución de semillas,
## conexión con el ecosistema ("farm_crops") y persistencia en guardado JSON.
## (Preparado en arquitectura con `require_farming_tools` para futura Regadera, Hoz y Compostador).

enum CropType { NONE, CARROT, CABBAGE, WHEAT }

const CROP_DATA: Dictionary = {
	CropType.CARROT: {
		"name": "Zanahoria",
		"seed_id": "carrot_seeds",
		"product_id": "carrot",
		"days": 2,
		"base_yield": 2,
		"seed_return": 2,
		"stage2_tex": "res://assests/world/farming/carrot_stage2.png",
		"mature_tex": "res://assests/world/farming/carrot_mature.png"
	},
	CropType.CABBAGE: {
		"name": "Col",
		"seed_id": "cabbage_seeds",
		"product_id": "cabbage",
		"days": 3,
		"base_yield": 2,
		"seed_return": 2,
		"stage2_tex": "res://assests/world/farming/cabbage_stage2.png",
		"mature_tex": "res://assests/world/farming/cabbage_mature.png"
	},
	CropType.WHEAT: {
		"name": "Trigo",
		"seed_id": "wheat_seeds",
		"product_id": "wheat",
		"days": 4,
		"base_yield": 3,
		"seed_return": 2,
		"stage2_tex": "res://assests/world/farming/wheat_stage2.png",
		"mature_tex": "res://assests/world/farming/wheat_mature.png"
	}
}

@export var persistence_id: String = ""
## Preparado para Fase futura de Herramientas Agrícolas (Regadera, Hoz de cosecha y Saco de abono)
@export var require_farming_tools: bool = false

var crop_type: CropType = CropType.NONE
var days_grown: int = 0
var is_watered: bool = false
var is_fertilized: bool = false

var soil_sprite: Sprite2D = null
var crop_sprite: Sprite2D = null
var interact_area: Area2D = null
var status_label: Label = null
var _player_inside: bool = false

var _tex_soil_dry: Texture2D = null
var _tex_soil_wet: Texture2D = null
var _tex_sprout: Texture2D = null

func _ready() -> void:
	add_to_group("farm_plots")
	if persistence_id == "":
		persistence_id = "farmplot_" + name + "_" + str(int(global_position.x)) + "_" + str(int(global_position.y))

	_tex_soil_dry = _load_tex("res://assests/world/farming/soil_dry.png")
	_tex_soil_wet = _load_tex("res://assests/world/farming/soil_wet.png")
	_tex_sprout = _load_tex("res://assests/world/farming/sprout_stage1.png")

	soil_sprite = Sprite2D.new()
	soil_sprite.name = "SoilSprite"
	soil_sprite.texture = _tex_soil_dry
	soil_sprite.scale = Vector2(1.35, 1.35)
	soil_sprite.z_index = -1
	add_child(soil_sprite)

	crop_sprite = Sprite2D.new()
	crop_sprite.name = "CropSprite"
	crop_sprite.scale = Vector2(1.25, 1.25)
	crop_sprite.visible = false
	add_child(crop_sprite)

	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 1
	interact_area.collision_mask = 2
	interact_area.add_to_group("interactable")
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 20)
	col.shape = rect
	interact_area.add_child(col)
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	add_child(interact_area)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-115, -30)
	status_label.custom_minimum_size = Vector2(230, 20)
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.72))
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.z_index = 20
	add_child(status_label)

	if not Engine.is_editor_hint():
		if WorldClock:
			WorldClock.day_passed.connect(_on_day_passed)
		if GameManager:
			GameManager.game_loaded.connect(_on_game_loaded)
		_load_saved_state()
	set_process(not Engine.is_editor_hint())
	_refresh_visuals()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not status_label:
		return
	var mouse_near := global_position.distance_squared_to(get_global_mouse_position()) <= 16.0 * 16.0
	if mouse_near or _player_inside:
		_update_status_text()
		status_label.visible = true
	else:
		status_label.visible = false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func is_mature() -> bool:
	if crop_type == CropType.NONE or not CROP_DATA.has(crop_type):
		return false
	return days_grown >= int(CROP_DATA[crop_type]["days"])

func _seed_id_to_crop_type(seed_id: String) -> CropType:
	match seed_id:
		"carrot_seeds": return CropType.CARROT
		"cabbage_seeds": return CropType.CABBAGE
		"wheat_seeds": return CropType.WHEAT
	return CropType.NONE

## Interacción contextual con [E]: Sembrar -> Regar -> Abonar -> Cosechar
func interact(player: Node) -> void:
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory

	# 1. Parcela vacía -> Plantar semilla activa (o cambiar con [R])
	if crop_type == CropType.NONE:
		var seed_id: String = inv.selected_seed_id
		if not inv.has_item(seed_id, 1):
			# Si no tiene de la semilla seleccionada, buscar si tiene alguna de las otras dos
			for alt_seed in SimpleInventory.SEED_ORDER:
				if inv.has_item(alt_seed, 1):
					seed_id = alt_seed
					inv.selected_seed_id = alt_seed
					break
		if not inv.has_item(seed_id, 1):
			if player.has_method("show_hint"):
				player.show_hint("No tienes semillas para plantar. Consigue más cosechando o en la caja del huerto.")
			return

		var new_crop := _seed_id_to_crop_type(seed_id)
		if new_crop == CropType.NONE:
			return

		inv.remove_item(seed_id, 1)
		crop_type = new_crop
		days_grown = 0
		var camp_st: Variant = GameManager.get_flag("player_campsite_state", null) if GameManager else null
		var sprk_on: bool = (typeof(camp_st) == TYPE_DICTIONARY) and bool((camp_st as Dictionary).get("sprinkler_installed", false)) and bool((camp_st as Dictionary).get("generator_active", false))
		is_watered = (WorldClock != null and int(WorldClock.get("current_weather")) == 1) or sprk_on
		is_fertilized = false
		_refresh_visuals()
		_save_state()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🌱 Plantado: %s" % CROP_DATA[crop_type]["name"], Color.SPRING_GREEN, -38.0)
		return

	# 2. Cultivo maduro -> Cosechar producto + recuperar semillas (+1/+2/+3 extra si usas la Hoz [6])
	if is_mature():
		var info: Dictionary = CROP_DATA[crop_type]
		var prod_id: String = str(info["product_id"])
		var seed_id: String = str(info["seed_id"])
		var has_sickle: bool = ("equipped_weapon" in player) and player.equipped_weapon != null and player.equipped_weapon.name == "Sickle"
		var s_bonus: int = 0
		if has_sickle:
			s_bonus = int(player.call("get_sickle_bonus")) if player.has_method("get_sickle_bonus") else 1
		var yield_amt: int = int(info["base_yield"]) + (1 if is_fertilized else 0) + s_bonus
		var seed_amt: int = int(info["seed_return"])

		inv.add_item(prod_id, yield_amt)
		inv.add_item(seed_id, seed_amt)

		if player.has_method("_spawn_floating_text"):
			var sickle_tag := (" (¡Bono Hoz +%d!)" % s_bonus) if has_sickle else ""
			player._spawn_floating_text("🌾 Cosechado%s: +%d %s, +%d Semillas" % [sickle_tag, yield_amt, inv.get_item_name(prod_id), seed_amt], Color.GOLD, -42.0)

		_reset_plot()
		return

	# 3. Cultivo en crecimiento pero Seco -> Regar con [E] (usa carga de la Regadera [7])
	if not is_watered:
		var has_can: bool = ("equipped_weapon" in player) and player.equipped_weapon != null and player.equipped_weapon.name == "WateringCan"
		if not has_can:
			if player.has_method("show_hint"):
				player.show_hint("💧 Equipa tu Regadera [7] para regar esta parcela.")
			return
		if player.has_method("consume_water_charge"):
			if not player.call("consume_water_charge"):
				return
		is_watered = true
		_refresh_visuals()
		_save_state()
		if player.has_method("_spawn_floating_text"):
			if "watering_can_charges" in player and "max_water_charges" in player:
				player._spawn_floating_text("💧 Tierra regada (%d/%d agua)" % [int(player.watering_can_charges), int(player.max_water_charges)], Color.AQUA, -38.0)
			else:
				player._spawn_floating_text("💧 Tierra regada", Color.AQUA, -38.0)
		return

	# 4. Cultivo ya regado y sin abonar -> Abonar con [E] si tienes Abono Orgánico
	if not is_fertilized:
		if inv.has_item("fertilizer", 1):
			inv.remove_item("fertilizer", 1)
			is_fertilized = true
			days_grown += 1
			_refresh_visuals()
			_save_state()
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("✨ Abonado (+1 Día de crecimiento)", Color.GOLD, -40.0)
		else:
			if player.has_method("show_hint"):
				player.show_hint("Cultivo regado. Si fabricas Abono Orgánico en [I], pulsa [E] aquí para acelerar su crecimiento.")
		return

	if player.has_method("show_hint"):
		player.show_hint("Esta planta ya está regada y abonada hoy. Crecerá al amanecer.")

## Permite que los herbívoros del bosque coman este cultivo si invaden la granja por sobrepoblación
func consume_by_animal() -> bool:
	if crop_type == CropType.NONE:
		return false
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("show_hint"):
		player.show_hint("⚠️ ¡Un animal salvaje se ha comido una planta de %s de tu huerto!" % CROP_DATA[crop_type]["name"])
	_reset_plot()
	return true

func _reset_plot() -> void:
	crop_type = CropType.NONE
	days_grown = 0
	is_watered = false
	is_fertilized = false
	_refresh_visuals()
	_save_state()

func water_from_rain_or_sprinkler() -> void:
	if crop_type == CropType.NONE or is_watered:
		return
	is_watered = true
	_refresh_visuals()
	_save_state()

func _on_day_passed(_new_day: int) -> void:
	if crop_type == CropType.NONE:
		return
	var req_days: int = int(CROP_DATA[crop_type]["days"])
	if is_watered and days_grown < req_days:
		days_grown = min(req_days, days_grown + 1)
	# La tierra vuelve a secarse salvo que hoy amanezca con lluvia o el aspersor eléctrico esté activo
	var camp_st: Variant = GameManager.get_flag("player_campsite_state", null) if GameManager else null
	var sprk_on: bool = (typeof(camp_st) == TYPE_DICTIONARY) and bool((camp_st as Dictionary).get("sprinkler_installed", false)) and bool((camp_st as Dictionary).get("generator_active", false))
	is_watered = (WorldClock != null and int(WorldClock.get("current_weather")) == 1) or sprk_on
	_refresh_visuals()
	_save_state()

func _refresh_visuals() -> void:
	if soil_sprite:
		soil_sprite.texture = _tex_soil_wet if is_watered else _tex_soil_dry

	if crop_type == CropType.NONE:
		if is_in_group("farm_crops"):
			remove_from_group("farm_crops")
		if crop_sprite:
			crop_sprite.visible = false
		return

	if not is_in_group("farm_crops"):
		add_to_group("farm_crops")

	if not crop_sprite:
		return

	var info: Dictionary = CROP_DATA[crop_type]
	var req_days: int = int(info["days"])
	crop_sprite.visible = true

	if days_grown <= 0:
		crop_sprite.texture = _tex_sprout
	elif days_grown < req_days:
		crop_sprite.texture = _load_tex(str(info["stage2_tex"]))
	else:
		crop_sprite.texture = _load_tex(str(info["mature_tex"]))

	crop_sprite.modulate = Color(1.08, 1.08, 0.92) if is_fertilized else Color.WHITE

func _update_status_text() -> void:
	if not status_label:
		return
	var player = get_tree().get_first_node_in_group("player")
	var inv: SimpleInventory = player.get("inventory") if player else null

	if crop_type == CropType.NONE:
		var seed_name := "Zanahoria"
		if inv:
			seed_name = inv.get_item_name(inv.selected_seed_id).replace("Semillas de ", "")
		status_label.text = "Parcela Vacía [E: Plantar %s | R: Cambiar]" % seed_name
		status_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.72))
		return

	var info: Dictionary = CROP_DATA[crop_type]
	var c_name: String = str(info["name"])
	var req_days: int = int(info["days"])

	if is_mature():
		status_label.text = "%s (%d/%d d) [✨ ¡Listo! — E: Cosechar]" % [c_name, req_days, req_days]
		status_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
		return

	var has_fert: bool = inv != null and inv.has_item("fertilizer", 1)
	var water_txt := "💧 Regada" if is_watered else "⚠️ Seca (E: Regar [7])"
	var fert_txt := " | ✨ Abonada" if is_fertilized else (" | E: Abonar" if (is_watered and has_fert) else "")
	status_label.text = "%s (%d/%d d) [%s%s]" % [c_name, days_grown, req_days, water_txt, fert_txt]
	status_label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0) if is_watered else Color(1.0, 0.85, 0.45))

func _save_state() -> void:
	if not GameManager or persistence_id == "":
		return
	GameManager.set_flag(persistence_id, {
		"crop": int(crop_type),
		"days": days_grown,
		"watered": is_watered,
		"fertilized": is_fertilized
	})

func _load_saved_state() -> void:
	if not GameManager or persistence_id == "":
		return
	var saved: Variant = GameManager.get_flag(persistence_id, null)
	if typeof(saved) == TYPE_DICTIONARY:
		crop_type = int(saved.get("crop", 0)) as CropType
		days_grown = int(saved.get("days", 0))
		is_watered = bool(saved.get("watered", false))
		is_fertilized = bool(saved.get("fertilized", false))
	else:
		crop_type = CropType.NONE
		days_grown = 0
		is_watered = false
		is_fertilized = false

func _on_game_loaded(_filepath: String) -> void:
	_load_saved_state()
	_refresh_visuals()

func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
