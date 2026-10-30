extends Control

@export var player: CharacterBody2D
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar
@export var blood_bar: ProgressBar
@export var stun_bar: ProgressBar
var hunger_bar: ProgressBar = null
var sleep_bar: ProgressBar = null

var clock_panel: PanelContainer = null
var clock_label: Label = null
var clock_sub_label: Label = null

var inv_panel: PanelContainer = null
var inv_gold_label: Label = null
var inv_armor_stats_label: Label = null
var inv_armor_slots_box: HBoxContainer = null
var inv_items_box: VBoxContainer = null
var inv_recipes_box: VBoxContainer = null
const ValleyMapUIScript = preload("res://scripts/ui/ValleyMapUI.gd")

var tool_wheel: ToolWheelUI = null
var tavern_games: TavernGamesUI = null
var valley_map: Control = null

func _ready() -> void:
	# 1. Find Player if not assigned
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("/root/World/Player")
	
	if not player:
		print("UI: Player not found!")
		return

	# 2. Setup Bars if not assigned
	if not health_bar:
		health_bar = _create_fallback_bar(Color.RED, Vector2(20, 20), "HP")
		add_child(health_bar)
	
	if not stamina_bar:
		stamina_bar = _create_fallback_bar(Color.GREEN, Vector2(20, 46), "STM")
		add_child(stamina_bar)

	if not blood_bar:
		blood_bar = _create_fallback_bar(Color.CRIMSON, Vector2(20, 72), "BLD")
		blood_bar.value = 0.0
		add_child(blood_bar)

	if not stun_bar:
		stun_bar = _create_fallback_bar(Color.GOLD, Vector2(20, 98), "STN")
		stun_bar.value = 0.0
		add_child(stun_bar)

	if not hunger_bar:
		hunger_bar = _create_fallback_bar(Color(0.95, 0.58, 0.22), Vector2(20, 124), "🍖 Hambre")
		hunger_bar.value = 100.0
		add_child(hunger_bar)

	if not sleep_bar:
		sleep_bar = _create_fallback_bar(Color(0.45, 0.72, 1.0), Vector2(20, 150), "💤 Sueño")
		sleep_bar.value = 100.0
		add_child(sleep_bar)

	# 3. Connect Signals
	if player.has_node("HealthComponent"):
		var health: HealthComponent = player.get_node("HealthComponent")
		health.health_changed.connect(_on_health_changed)
		health.blood_changed.connect(_on_blood_changed)
		health_bar.max_value = health.max_health
		health_bar.value = health.current_health
		blood_bar.max_value = health.max_blood
		blood_bar.value = health.current_blood
	
	if player.has_node("StaminaComponent"):
		var stamina: StaminaComponent = player.get_node("StaminaComponent")
		stamina.stamina_changed.connect(_on_stamina_changed)
		stamina.exhausted.connect(_on_exhausted)
		stamina_bar.max_value = stamina.max_stamina
		stamina_bar.value = stamina.current_stamina

	if player.has_node("StunComponent"):
		var stun: StunComponent = player.get_node("StunComponent")
		stun.stun_changed.connect(_on_stun_changed)
		stun_bar.max_value = stun.max_stun
		stun_bar.value = stun.current_stun

	call_deferred("_bind_survival_component")
	
	setup_hint_label()
	_setup_clock_ui()
	_setup_inventory_ui()
	_setup_tool_wheel_ui()
	_setup_tavern_games_ui()
	_setup_valley_map_ui()
	_init_default_objectives()

	if "inventory" in player and player.inventory:
		player.inventory.inventory_changed.connect(_on_inventory_changed)
		if not player.inventory.armor_changed.is_connected(_on_inventory_changed):
			player.inventory.armor_changed.connect(_on_inventory_changed)
		if not player.inventory.gold_changed.is_connected(_on_gold_changed):
			player.inventory.gold_changed.connect(_on_gold_changed)
		_on_inventory_changed()
	else:
		call_deferred("_bind_player_inventory")

func _bind_player_inventory() -> void:
	if player and "inventory" in player and player.inventory:
		if not player.inventory.inventory_changed.is_connected(_on_inventory_changed):
			player.inventory.inventory_changed.connect(_on_inventory_changed)
		if not player.inventory.armor_changed.is_connected(_on_inventory_changed):
			player.inventory.armor_changed.connect(_on_inventory_changed)
		if not player.inventory.gold_changed.is_connected(_on_gold_changed):
			player.inventory.gold_changed.connect(_on_gold_changed)
		_on_inventory_changed()

func _on_gold_changed(_new_gold: int) -> void:
	_on_inventory_changed()

func _bind_survival_component() -> void:
	if player and player.has_node("SurvivalComponent"):
		var surv: SurvivalComponent = player.get_node("SurvivalComponent")
		if not surv.hunger_changed.is_connected(_on_hunger_changed):
			surv.hunger_changed.connect(_on_hunger_changed)
		if not surv.sleep_changed.is_connected(_on_sleep_changed):
			surv.sleep_changed.connect(_on_sleep_changed)
		surv._emit_all()

func _unhandled_input(event: InputEvent) -> void:
	var dm = player.get("dialogue_manager") if player else null
	if (dm and dm.has_method("is_active") and bool(dm.call("is_active"))) or (tavern_games and tavern_games.visible):
		return
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_TAB:
			if event.pressed:
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(true)
				elif tool_wheel:
					if inv_panel and inv_panel.visible:
						inv_panel.visible = false
					if valley_map and bool(valley_map.get("is_full_map_open")):
						valley_map.call("close_full_map")
					tool_wheel.open_wheel()
			else:
				if tool_wheel and tool_wheel.visible:
					tool_wheel.handle_tab_release()
			get_viewport().set_input_as_handled()
			return

		if event.pressed:
			if event.physical_keycode == KEY_I:
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
				_toggle_inventory()
				get_viewport().set_input_as_handled()
			elif event.physical_keycode == KEY_M:
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
				if inv_panel and inv_panel.visible:
					inv_panel.visible = false
				if valley_map and valley_map.has_method("toggle_full_map"):
					valley_map.call("toggle_full_map")
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ESCAPE:
				if tool_wheel and tool_wheel.visible:
					tool_wheel.close_wheel(false)
					get_viewport().set_input_as_handled()
				elif valley_map and bool(valley_map.get("is_full_map_open")):
					valley_map.call("close_full_map")
					get_viewport().set_input_as_handled()
				elif inv_panel and inv_panel.visible:
					inv_panel.visible = false
					get_viewport().set_input_as_handled()

func _setup_tool_wheel_ui() -> void:
	tool_wheel = ToolWheelUI.new()
	tool_wheel.name = "ToolWheelUI"
	tool_wheel.player = player
	add_child(tool_wheel)

func _setup_tavern_games_ui() -> void:
	tavern_games = TavernGamesUI.new()
	tavern_games.name = "TavernGamesUI"
	tavern_games.player = player
	add_child(tavern_games)

func _setup_valley_map_ui() -> void:
	valley_map = ValleyMapUIScript.new()
	valley_map.name = "ValleyMapUI"
	valley_map.set("player", player)
	add_child(valley_map)

func open_tavern_games() -> void:
	if inv_panel and inv_panel.visible:
		inv_panel.visible = false
	if tool_wheel and tool_wheel.visible:
		tool_wheel.close_wheel(false)
	if valley_map and bool(valley_map.get("is_full_map_open")):
		valley_map.call("close_full_map")
	if tavern_games:
		tavern_games.open_games()

func _toggle_inventory() -> void:
	if not inv_panel:
		return
	inv_panel.visible = not inv_panel.visible
	if inv_panel.visible:
		_refresh_inventory_list()

func _on_inventory_changed() -> void:
	if WorldClock:
		_on_clock_time_updated(WorldClock.current_day, WorldClock.current_hour, WorldClock.current_minute)
	if inv_panel and inv_panel.visible:
		_refresh_inventory_list()

func _setup_inventory_ui() -> void:
	inv_panel = PanelContainer.new()
	inv_panel.name = "InventoryPanel"
	inv_panel.visible = false
	inv_panel.layout_mode = 1
	inv_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	inv_panel.offset_left = -430.0
	inv_panel.offset_top = -250.0
	inv_panel.offset_right = 430.0
	inv_panel.offset_bottom = 250.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.11, 0.96)
	style.border_color = Color(0.75, 0.63, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	inv_panel.add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	inv_panel.add_child(main_vbox)

	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "🎒 Mochila, Armadura y Taller de Crafteo"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.65))
	header.add_child(title)

	inv_gold_label = Label.new()
	inv_gold_label.text = "💰 25 Oro"
	inv_gold_label.add_theme_font_size_override("font_size", 16)
	inv_gold_label.add_theme_color_override("font_color", Color.GOLD)
	header.add_child(inv_gold_label)

	# Panel de Equipamiento de Armadura (4 Slots: Casco, Pecho, Piernas, Botas)
	var armor_panel := PanelContainer.new()
	var armor_style := StyleBoxFlat.new()
	armor_style.bg_color = Color(0.11, 0.13, 0.18, 0.95)
	armor_style.border_color = Color(0.45, 0.55, 0.72, 0.85)
	armor_style.set_border_width_all(1)
	armor_style.set_corner_radius_all(6)
	armor_style.content_margin_left = 10
	armor_style.content_margin_right = 10
	armor_style.content_margin_top = 6
	armor_style.content_margin_bottom = 6
	armor_panel.add_theme_stylebox_override("panel", armor_style)
	main_vbox.add_child(armor_panel)

	var armor_vbox := VBoxContainer.new()
	armor_vbox.add_theme_constant_override("separation", 4)
	armor_panel.add_child(armor_vbox)

	inv_armor_stats_label = Label.new()
	inv_armor_stats_label.text = "🛡️ Armadura Equipada: Sin armadura (0% Defensa)"
	inv_armor_stats_label.add_theme_font_size_override("font_size", 12)
	inv_armor_stats_label.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
	armor_vbox.add_child(inv_armor_stats_label)

	inv_armor_slots_box = HBoxContainer.new()
	inv_armor_slots_box.add_theme_constant_override("separation", 8)
	armor_vbox.add_child(inv_armor_slots_box)

	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	main_vbox.add_child(columns)

	# Columna Izquierda: Inventario
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.0
	columns.add_child(left_col)

	var left_title := Label.new()
	left_title.text = "📦 Recursos y Objetos"
	left_title.add_theme_font_size_override("font_size", 14)
	left_title.add_theme_color_override("font_color", Color(0.80, 0.88, 0.98))
	left_col.add_child(left_title)

	var scroll_items := ScrollContainer.new()
	scroll_items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_child(scroll_items)

	inv_items_box = VBoxContainer.new()
	inv_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_items_box.add_theme_constant_override("separation", 6)
	scroll_items.add_child(inv_items_box)

	var vsep := VSeparator.new()
	columns.add_child(vsep)

	# Columna Derecha: Taller de Crafteo
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.05
	columns.add_child(right_col)

	var right_title := Label.new()
	right_title.text = "🔨 Recetas de Crafteo"
	right_title.add_theme_font_size_override("font_size", 14)
	right_title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	right_col.add_child(right_title)

	var scroll_recipes := ScrollContainer.new()
	scroll_recipes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(scroll_recipes)

	inv_recipes_box = VBoxContainer.new()
	inv_recipes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_recipes_box.add_theme_constant_override("separation", 6)
	scroll_recipes.add_child(inv_recipes_box)

	var sep2 := HSeparator.new()
	main_vbox.add_child(sep2)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	main_vbox.add_child(footer)

	var btn_save := Button.new()
	btn_save.text = "💾 [F5] Guardar"
	btn_save.pressed.connect(func():
		if GameManager:
			GameManager.save_game()
	)
	footer.add_child(btn_save)

	var btn_load := Button.new()
	btn_load.text = "📂 [F9] Cargar"
	btn_load.pressed.connect(func():
		if GameManager:
			GameManager.load_game()
	)
	footer.add_child(btn_load)

	var btn_close := Button.new()
	btn_close.text = "✖ [I / ESC] Cerrar"
	btn_close.pressed.connect(func(): inv_panel.visible = false)
	footer.add_child(btn_close)

	add_child(inv_panel)

func _refresh_inventory_list() -> void:
	if not inv_items_box or not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	if inv_gold_label:
		inv_gold_label.text = "💰 %d Oro" % inv.gold

	# Actualizar panel de 4 Slots de Armadura
	if inv_armor_stats_label:
		var a_stats: Dictionary = inv.get_total_armor_stats()
		var def_pct: int = int(round(float(a_stats.get("defense", 0.0)) * 100.0))
		var bleed_pct: int = int(round(float(a_stats.get("bleed_res", 0.0)) * 100.0))
		var stun_pct: int = int(round(float(a_stats.get("stun_res", 0.0)) * 100.0))
		var spd_pct: int = int(round((1.0 + float(a_stats.get("speed_bonus", 0.0))) * 100.0))
		inv_armor_stats_label.text = "🛡️ Armadura Equipada — Defensa: -%d%% Daño | Res. Sangrado: -%d%% | Res. Stun: -%d%% | Velocidad: %d%%" % [def_pct, bleed_pct, stun_pct, spd_pct]

	if inv_armor_slots_box:
		for child in inv_armor_slots_box.get_children():
			child.queue_free()
		var slot_titles: Dictionary = {
			"HEAD": "🪖 Casco",
			"CHEST": "🦺 Pecho",
			"LEGS": "👖 Piernas",
			"BOOTS": "🥾 Botas"
		}
		for slot_key in SimpleInventory.ARMOR_SLOTS:
			var eq_id: String = str(inv.equipped_armor.get(slot_key, ""))
			var slot_card := PanelContainer.new()
			slot_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var sc_style := StyleBoxFlat.new()
			sc_style.bg_color = Color(0.16, 0.20, 0.26, 0.95) if eq_id != "" else Color(0.09, 0.10, 0.13, 0.85)
			sc_style.border_color = Color(0.55, 0.78, 0.95, 0.9) if eq_id != "" else Color(0.28, 0.30, 0.36, 0.6)
			sc_style.set_border_width_all(1)
			sc_style.set_corner_radius_all(4)
			sc_style.content_margin_left = 6
			sc_style.content_margin_right = 6
			sc_style.content_margin_top = 4
			sc_style.content_margin_bottom = 4
			slot_card.add_theme_stylebox_override("panel", sc_style)

			var sc_hbox := HBoxContainer.new()
			sc_hbox.add_theme_constant_override("separation", 6)
			slot_card.add_child(sc_hbox)

			if eq_id != "":
				var icon_tex: Texture2D = inv.get_item_icon(eq_id)
				if icon_tex:
					var tr := TextureRect.new()
					tr.texture = icon_tex
					tr.custom_minimum_size = Vector2(22, 22)
					tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					sc_hbox.add_child(tr)

			var sc_lbl := Label.new()
			sc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sc_lbl.text = "%s:\n%s" % [str(slot_titles.get(slot_key, slot_key)), inv.get_item_name(eq_id) if eq_id != "" else "Vacío"]
			sc_lbl.add_theme_font_size_override("font_size", 10)
			sc_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.85) if eq_id != "" else Color(0.55, 0.58, 0.65))
			sc_hbox.add_child(sc_lbl)

			if eq_id != "":
				var un_btn := Button.new()
				un_btn.text = "✖"
				un_btn.tooltip_text = "Desequipar"
				var cap_slot: String = str(slot_key)
				un_btn.pressed.connect(func():
					inv.unequip_armor_slot(cap_slot, player)
				)
				sc_hbox.add_child(un_btn)

			inv_armor_slots_box.add_child(slot_card)

	for child in inv_items_box.get_children():
		child.queue_free()

	if inv.items.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Tu mochila está vacía.\nTala árboles ([3]), pica rocas ([4]), pesca ([8]) o recoge plantas ([E])."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		inv_items_box.add_child(empty_lbl)
	else:
		for item_id in inv.items.keys():
			var count: int = int(inv.items[item_id])
			if count <= 0:
				continue
			var info: Dictionary = inv.get_item_info(str(item_id))
			var row := PanelContainer.new()
			var row_style := StyleBoxFlat.new()
			row_style.bg_color = Color(0.13, 0.15, 0.20, 0.9)
			row_style.set_corner_radius_all(4)
			row_style.content_margin_left = 10
			row_style.content_margin_right = 10
			row_style.content_margin_top = 6
			row_style.content_margin_bottom = 6
			row.add_theme_stylebox_override("panel", row_style)

			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 10)
			row.add_child(hbox)

			var item_tex: Texture2D = inv.get_item_icon(str(item_id))
			if item_tex:
				var icon_rect := TextureRect.new()
				icon_rect.texture = item_tex
				icon_rect.custom_minimum_size = Vector2(28, 28)
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				hbox.add_child(icon_rect)

			var text_vbox := VBoxContainer.new()
			text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(text_vbox)

			var name_lbl := Label.new()
			name_lbl.text = "%s  x%d   [%s]" % [info.get("name", item_id), count, info.get("category", "Objeto")]
			name_lbl.add_theme_font_size_override("font_size", 13)
			name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
			text_vbox.add_child(name_lbl)

			var desc_lbl := Label.new()
			desc_lbl.text = str(info.get("desc", ""))
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.add_theme_font_size_override("font_size", 11)
			desc_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.82))
			text_vbox.add_child(desc_lbl)

			if info.get("usable", false):
				var use_btn := Button.new()
				var cat_str: String = str(info.get("category", ""))
				if info.has("armor_slot") or cat_str.begins_with("Armadura"):
					use_btn.text = "🛡️ Equipar"
				elif info.get("is_seed", false):
					use_btn.text = "🌱 Semilla"
				else:
					use_btn.text = "🍽️ Usar"
				var captured_id := str(item_id)
				use_btn.pressed.connect(func():
					inv.use_item(captured_id, player)
				)
				hbox.add_child(use_btn)

			inv_items_box.add_child(row)

	# Poblar Recetas de Crafteo con Iconos Visuales
	if inv_recipes_box:
		for child in inv_recipes_box.get_children():
			child.queue_free()

		for recipe in SimpleInventory.RECIPES:
			var res_id: String = str(recipe.get("result", ""))
			var res_amt: int = int(recipe.get("amount", 1))
			var craftable: bool = inv.can_craft(recipe)

			var r_row := PanelContainer.new()
			var r_style := StyleBoxFlat.new()
			r_style.bg_color = Color(0.14, 0.18, 0.15, 0.92) if craftable else Color(0.12, 0.12, 0.15, 0.85)
			r_style.border_color = Color(0.35, 0.75, 0.45, 0.8) if craftable else Color(0.25, 0.25, 0.30, 0.5)
			r_style.set_border_width_all(1)
			r_style.set_corner_radius_all(4)
			r_style.content_margin_left = 10
			r_style.content_margin_right = 10
			r_style.content_margin_top = 6
			r_style.content_margin_bottom = 6
			r_row.add_theme_stylebox_override("panel", r_style)

			var r_hbox := HBoxContainer.new()
			r_hbox.add_theme_constant_override("separation", 10)
			r_row.add_child(r_hbox)

			var rec_tex: Texture2D = inv.get_item_icon(res_id)
			if rec_tex:
				var rec_icon := TextureRect.new()
				rec_icon.texture = rec_tex
				rec_icon.custom_minimum_size = Vector2(28, 28)
				rec_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				rec_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				rec_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				r_hbox.add_child(rec_icon)

			var r_vbox := VBoxContainer.new()
			r_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r_hbox.add_child(r_vbox)

			var r_title := Label.new()
			r_title.text = "%s x%d" % [inv.get_item_name(res_id), res_amt]
			r_title.add_theme_font_size_override("font_size", 13)
			r_title.add_theme_color_override("font_color", Color(0.95, 0.92, 0.72) if craftable else Color(0.75, 0.75, 0.78))
			r_vbox.add_child(r_title)

			var ing_dict: Dictionary = recipe.get("ingredients", {})
			var ing_parts: Array[String] = []
			for ing_id in ing_dict.keys():
				var req: int = int(ing_dict[ing_id])
				var have: int = inv.get_count(str(ing_id))
				ing_parts.append("%s (%d/%d)" % [inv.get_item_name(str(ing_id)), have, req])

			var r_ing_lbl := Label.new()
			r_ing_lbl.text = "Requiere: " + ", ".join(ing_parts)
			r_ing_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			r_ing_lbl.add_theme_font_size_override("font_size", 11)
			r_ing_lbl.add_theme_color_override("font_color", Color(0.65, 0.92, 0.70) if craftable else Color(0.85, 0.55, 0.55))
			r_vbox.add_child(r_ing_lbl)

			var craft_btn := Button.new()
			craft_btn.text = "Fabricar"
			craft_btn.disabled = not craftable
			var captured_recipe: Dictionary = recipe
			craft_btn.pressed.connect(func():
				inv.craft_recipe(captured_recipe, player)
			)
			r_hbox.add_child(craft_btn)

			inv_recipes_box.add_child(r_row)

func _setup_clock_ui() -> void:
	clock_panel = PanelContainer.new()
	clock_panel.name = "WorldClockPanel"
	clock_panel.layout_mode = 1
	clock_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	clock_panel.offset_left = -175.0
	clock_panel.offset_top = 10.0
	clock_panel.offset_right = 175.0
	clock_panel.offset_bottom = 62.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.88)
	style.border_color = Color(0.45, 0.55, 0.72, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	clock_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	clock_panel.add_child(vbox)

	clock_label = Label.new()
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.add_theme_font_size_override("font_size", 15)
	clock_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.78))
	vbox.add_child(clock_label)

	clock_sub_label = Label.new()
	clock_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_sub_label.add_theme_font_size_override("font_size", 11)
	clock_sub_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.88))
	vbox.add_child(clock_sub_label)

	add_child(clock_panel)

	if WorldClock:
		WorldClock.time_updated.connect(_on_clock_time_updated)
		_on_clock_time_updated(WorldClock.current_day, WorldClock.current_hour, WorldClock.current_minute)

func _on_clock_time_updated(_day: int, _hour: int, _minute: int) -> void:
	if not clock_label or not WorldClock:
		return
	var icon := WorldClock.get_phase_icon()
	clock_label.text = "%s %s" % [icon, WorldClock.get_formatted_time()]
	var vis_pct := int(round(WorldClock.get_vision_multiplier() * 100.0))
	var gold_val := 25
	if player and "inventory" in player and player.inventory:
		gold_val = player.inventory.gold
	clock_sub_label.text = "💰 %d Oro | Visión: %d%% | [TAB] Rueda | [I] Mochila | [M] Mapa | [F5/F9] Guardar/Cargar" % [gold_val, vis_pct]

func _init_default_objectives() -> void:
	if not ObjectiveManager:
		return
	var find_sword = load("res://resources/objectives/obj_find_sword.tres")
	if find_sword:
		ObjectiveManager.add_objective(find_sword)
	var kill_frogs = load("res://resources/objectives/obj_kill_frogs.tres")
	if kill_frogs:
		ObjectiveManager.add_objective(kill_frogs)

func setup_hint_label() -> void:
	var hint = get_node_or_null("HintLabel")
	if hint:
		hint.layout_mode = 1
		hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		hint.position.y += 72
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		hint.custom_minimum_size = Vector2(300, 50)
		hint.grow_horizontal = Control.GROW_DIRECTION_BOTH

func _on_health_changed(current: float, max_val: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_val

func _on_stamina_changed(current: float, max_val: float) -> void:
	stamina_bar.value = current
	stamina_bar.max_value = max_val

func _on_blood_changed(current: float, max_val: float) -> void:
	blood_bar.value = current
	blood_bar.max_value = max_val

func _on_stun_changed(current: float, max_val: float) -> void:
	stun_bar.value = current
	stun_bar.max_value = max_val

func _on_hunger_changed(current: float, max_val: float) -> void:
	if hunger_bar:
		hunger_bar.max_value = max_val
		hunger_bar.value = current

func _on_sleep_changed(current: float, max_val: float) -> void:
	if sleep_bar:
		sleep_bar.max_value = max_val
		sleep_bar.value = current

func _on_exhausted() -> void:
	stamina_bar.modulate = Color.GRAY
	get_tree().create_timer(1.0).timeout.connect(func(): stamina_bar.modulate = Color.GREEN)

func _create_fallback_bar(color: Color, pos: Vector2, label_text: String = "") -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(180, 20)
	bar.modulate = color
	bar.show_percentage = false
	if label_text != "":
		var lbl = Label.new()
		lbl.text = label_text
		lbl.position = Vector2(6, 0)
		lbl.add_theme_font_size_override("font_size", 12)
		bar.add_child(lbl)
	return bar
