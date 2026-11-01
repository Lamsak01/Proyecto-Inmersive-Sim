extends Control
class_name SocialGlossaryUI

## Panel de Glosario de Vecinos y Red Social Dinámica (Estilo RimWorld + Compendio Red Dead Redemption 2):
## Permite consultar la biografía, estado vital, rutina, familia cercana, mejores amigos, rivales principales
## y la tabla completa de relaciones dinámicas (-100 a +100) de cada ciudadano del valle, además de su relación con el Jugador.

var selected_npc: VillageNPC = null

var _npc_list_vbox: VBoxContainer = null
var _portrait_rect: TextureRect = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _tagline_label: Label = null
var _player_rel_label: Label = null
var _player_rel_bar: ProgressBar = null
var _highlights_label: RichTextLabel = null
var _social_table_vbox: VBoxContainer = null
var _refresh_timer: float = 0.0

func _ready() -> void:
	name = "SocialGlossaryUI"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 115
	_build_ui()

func _process(delta: float) -> void:
	if not visible:
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _row_fill_idx < _row_fill_entries.size():
		_fill_rows_step(ROWS_PER_FRAME)
	_refresh_timer += delta
	if _refresh_timer >= 2.0:
		_refresh_timer = 0.0
		refresh_ui(false)

func _make_box_style(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(bw)
	st.set_corner_radius_all(radius)
	return st

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.02, 0.03, 0.05, 0.80)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_panel := PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(780, 440)
	main_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.07, 0.09, 0.13, 0.98), Color(0.76, 0.62, 0.34, 0.95), 2, 8))
	center.add_child(main_panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	main_panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(root_vbox)

	# Cabecera Superior
	var header_hbox := HBoxContainer.new()
	root_vbox.add_child(header_hbox)

	var h_title := Label.new()
	h_title.text = "📖 GLOSARIO DE VECINOS Y RED SOCIAL DEL VALLE (RimWorld / RDR2)"
	h_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_title.add_theme_font_size_override("font_size", 16)
	h_title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.58))
	header_hbox.add_child(h_title)

	var close_btn := Button.new()
	close_btn.text = "✖ Cerrar [J / ESC]"
	close_btn.custom_minimum_size = Vector2(138, 28)
	close_btn.pressed.connect(close_panel)
	header_hbox.add_child(close_btn)

	var sep_top := HSeparator.new()
	root_vbox.add_child(sep_top)

	# Cuerpo en 2 Columnas: Lista de Ciudadanos (Izquierda) + Compendio y Tabla Social RimWorld (Derecha)
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	root_vbox.add_child(body_hbox)

	# Columna Izquierda: Lista de Habitantes
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(235, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.05, 0.06, 0.09, 0.96), Color(0.28, 0.34, 0.44, 0.85), 1, 6))
	body_hbox.add_child(left_panel)

	var left_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		left_margin.add_theme_constant_override(side, 8)
	left_panel.add_child(left_margin)

	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 6)
	left_margin.add_child(left_vbox)

	var list_hdr := Label.new()
	list_hdr.text = "👥 HABITANTES DEL VALLE"
	list_hdr.add_theme_font_size_override("font_size", 12)
	list_hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	left_vbox.add_child(list_hdr)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_vbox.add_child(left_scroll)

	_npc_list_vbox = VBoxContainer.new()
	_npc_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_npc_list_vbox.add_theme_constant_override("separation", 4)
	left_scroll.add_child(_npc_list_vbox)

	# Columna Derecha: Ficha de Compendio + Vínculos Destacados + Tabla Social RimWorld
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.06, 0.08, 0.11, 0.96), Color(0.32, 0.38, 0.48, 0.85), 1, 6))
	body_hbox.add_child(right_panel)

	var right_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		right_margin.add_theme_constant_override(side, 10)
	right_panel.add_child(right_margin)

	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	right_margin.add_child(right_vbox)

	# 1. Tarjeta Biográfica Superior con Retrato 64x64
	var bio_hbox := HBoxContainer.new()
	bio_hbox.add_theme_constant_override("separation", 12)
	right_vbox.add_child(bio_hbox)

	var port_frame := PanelContainer.new()
	port_frame.custom_minimum_size = Vector2(58, 58)
	port_frame.add_theme_stylebox_override("panel", _make_box_style(Color(0.10, 0.12, 0.17, 1.0), Color(0.82, 0.68, 0.36, 0.95), 2, 6))
	bio_hbox.add_child(port_frame)

	_portrait_rect = TextureRect.new()
	_portrait_rect.custom_minimum_size = Vector2(52, 52)
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	port_frame.add_child(_portrait_rect)

	var bio_text_vbox := VBoxContainer.new()
	bio_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bio_text_vbox.add_theme_constant_override("separation", 3)
	bio_hbox.add_child(bio_text_vbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 15)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72))
	bio_text_vbox.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 11)
	_subtitle_label.add_theme_color_override("font_color", Color(0.76, 0.88, 0.98))
	bio_text_vbox.add_child(_subtitle_label)

	_tagline_label = Label.new()
	_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tagline_label.add_theme_font_size_override("font_size", 11)
	_tagline_label.add_theme_color_override("font_color", Color(0.84, 0.84, 0.78))
	bio_text_vbox.add_child(_tagline_label)

	# 2. Barra de Relación con el Jugador ("Tu Amigo / Forastero")
	var player_rel_box := PanelContainer.new()
	player_rel_box.add_theme_stylebox_override("panel", _make_box_style(Color(0.09, 0.12, 0.17, 0.95), Color(0.38, 0.56, 0.74, 0.85), 1, 5))
	right_vbox.add_child(player_rel_box)

	var pr_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pr_margin.add_theme_constant_override(side, 7)
	player_rel_box.add_child(pr_margin)

	var pr_vbox := VBoxContainer.new()
	pr_vbox.add_theme_constant_override("separation", 4)
	pr_margin.add_child(pr_vbox)

	_player_rel_label = Label.new()
	_player_rel_label.add_theme_font_size_override("font_size", 12)
	_player_rel_label.add_theme_color_override("font_color", Color(0.72, 0.96, 0.84))
	pr_vbox.add_child(_player_rel_label)

	_player_rel_bar = ProgressBar.new()
	_player_rel_bar.min_value = -100.0
	_player_rel_bar.max_value = 100.0
	_player_rel_bar.show_percentage = false
	_player_rel_bar.custom_minimum_size = Vector2(0, 10)
	pr_vbox.add_child(_player_rel_bar)

	# 3. Resumen de Vínculos Principales (Familia Cercana, Mejores Amigos y Enemistades Principales)
	var hl_box := PanelContainer.new()
	hl_box.add_theme_stylebox_override("panel", _make_box_style(Color(0.08, 0.10, 0.14, 0.95), Color(0.45, 0.42, 0.28, 0.85), 1, 5))
	right_vbox.add_child(hl_box)

	var hl_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		hl_margin.add_theme_constant_override(side, 7)
	hl_box.add_child(hl_margin)

	_highlights_label = RichTextLabel.new()
	_highlights_label.bbcode_enabled = true
	_highlights_label.fit_content = true
	_highlights_label.scroll_active = false
	_highlights_label.custom_minimum_size = Vector2(0, 52)
	_highlights_label.add_theme_font_size_override("normal_font_size", 11)
	hl_margin.add_child(_highlights_label)

	# 4. Tabla Social Completa Estilo RimWorld (Relación con cada vecino)
	var tbl_hdr := Label.new()
	tbl_hdr.text = "📊 TABLA DE AFINIDAD Y RELACIONES CON OTROS VECINOS (Estilo RimWorld: -100 a +100)"
	tbl_hdr.add_theme_font_size_override("font_size", 12)
	tbl_hdr.add_theme_color_override("font_color", Color(1.0, 0.88, 0.56))
	right_vbox.add_child(tbl_hdr)

	var tbl_scroll := ScrollContainer.new()
	tbl_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tbl_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vbox.add_child(tbl_scroll)

	_social_table_vbox = VBoxContainer.new()
	_social_table_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_social_table_vbox.add_theme_constant_override("separation", 5)
	tbl_scroll.add_child(_social_table_vbox)

func _get_role_icon(role: int) -> String:
	match role:
		VillageNPC.TradeRole.BLACKSMITH: return "⚒️"
		VillageNPC.TradeRole.BUTCHER: return "🥩"
		VillageNPC.TradeRole.CARPENTER: return "🪚"
		VillageNPC.TradeRole.FISHMONGER: return "🐟"
		VillageNPC.TradeRole.HERBALIST: return "🌿"
		VillageNPC.TradeRole.INNKEEPER: return "🍺"
		VillageNPC.TradeRole.DOCTOR: return "🩺"
		VillageNPC.TradeRole.SHERIFF: return "🚓"
		VillageNPC.TradeRole.GUARD: return "🛡️"
		VillageNPC.TradeRole.FAMILY_MEMBER: return "🏠"
		VillageNPC.TradeRole.TRAVELING_MERCHANT: return "🧳"
		VillageNPC.TradeRole.ROYAL_INVESTIGATOR: return "👑"
		_: return "🚶"

func _get_all_sorted_npcs() -> Array[VillageNPC]:
	var arr: Array[VillageNPC] = []
	if not is_inside_tree():
		return arr
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and is_instance_valid(n):
			arr.append(n as VillageNPC)
	arr.sort_custom(func(a: VillageNPC, b: VillageNPC) -> bool:
		if a.is_dead != b.is_dead:
			return not a.is_dead
		if int(a.trade_role) != int(b.trade_role):
			return int(a.trade_role) < int(b.trade_role)
		return a.npc_name < b.npc_name
	)
	return arr

func open_panel(focus_npc: Node = null) -> void:
	if focus_npc is VillageNPC and is_instance_valid(focus_npc):
		selected_npc = focus_npc as VillageNPC
	visible = true
	_relations_initialized = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	refresh_ui()

func close_panel() -> void:
	visible = false

func toggle_panel(focus_npc: Node = null) -> void:
	if visible:
		close_panel()
	else:
		open_panel(focus_npc)

func _get_player_affinity_tier_text(aff: int) -> String:
	if aff >= 45:
		return "🌟 Aliado Familiar (-20% Dto en tienda y dispuesto a darte Coartada)"
	if aff >= 20:
		return "🤝 Amistoso y receptivo contigo"
	if aff >= -10:
		return "😐 Trato neutral de vecino"
	if aff > -35:
		return "😒 Receloso / Desconfiado"
	return "😠 Agraviado (Se niega a comerciar hasta pagar compensación)"

func refresh_ui(rebuild_lists: bool = true) -> void:
	if not is_inside_tree():
		return
	var all_npcs: Array[VillageNPC] = _get_all_sorted_npcs()
	if all_npcs.is_empty():
		return
	if not is_instance_valid(selected_npc) or not (selected_npc in all_npcs):
		selected_npc = all_npcs[0]

	if not _relations_initialized:
		_relations_initialized = true
		for npc_init in all_npcs:
			npc_init.ensure_npc_relationships_initialized()

	# 1. Lista de Vecinos (Izquierda) — los botones se crean UNA sola vez y luego solo se actualiza su texto/estilo (evita micro-lag al cambiar de vecino)
	if rebuild_lists:
		_sync_neighbor_list_buttons(all_npcs)

	# 2. Poblar Ficha Superior del Vecino Seleccionado
	var sel: VillageNPC = selected_npc
	_portrait_rect.texture = sel.get_portrait_texture()
	var state_badge: String = "💀 DIFUNTO" if sel.is_dead else ("🩸 AGONIZANDO" if sel.is_downed else "🟢 VIVO")
	_title_label.text = "%s %s — %s (%s) [%s]" % [_get_role_icon(int(sel.trade_role)), sel.npc_name, sel.npc_role, sel.family_name, state_badge]
	var traits_txt: String = ", ".join(sel.traits) if not sel.traits.is_empty() else "Equilibrado"
	var rom_badge: String = "Soltero/a"
	if sel.person_profile != null:
		var r_st: String = str(sel.person_profile.romance_status)
		if r_st == "partnered":
			rom_badge = "💑 En pareja"
		elif r_st == "widowed":
			rom_badge = "🖤 Viudo/a"
	_subtitle_label.text = "Rutina: %s | %s | 😊 Humor: %d%% | 🍖 %d%% | 💤 %d%% | 💰 %d Oro | Rasgos: %s" % [
		sel.get_activity_description(), rom_badge, int(round(sel.mood)), int(round(sel.need_hunger)), int(round(sel.need_energy)), maxi(0, sel.personal_gold), traits_txt
	]
	_tagline_label.text = "«%s»" % (sel.character_tagline if sel.character_tagline != "" else "Habitante del valle.")

	# 3. Relación con el Jugador
	var extra_p_tags: Array[String] = []
	if sel.witness_alibi_for_player:
		extra_p_tags.append("🤝 Coartada Pactada")
	if sel.witness_silenced_player:
		extra_p_tags.append("🤐 Silenciado")
	if sel.witness_framed_target_name != "":
		extra_p_tags.append("👉 Inculpará a " + sel.witness_framed_target_name)
	var extra_p_str: String = (" | [" + ", ".join(extra_p_tags) + "]") if not extra_p_tags.is_empty() else ""
	_player_rel_label.text = "🧑 Tu Relación con %s: %+d / 100 — %s%s" % [sel.npc_name, sel.affinity, _get_player_affinity_tier_text(sel.affinity), extra_p_str]
	_player_rel_bar.value = clampf(float(sel.affinity), -100.0, 100.0)

	# 4. Calcular Familiares Cercanos, Mejores Amigos y Enemistades Principales
	var family_list: Array[String] = []
	var rel_entries: Array[Dictionary] = []

	for other in all_npcs:
		if other == sel:
			continue
		var rel_val: int = sel.get_relationship_with_npc(other.npc_name)
		var note_str: String = sel.get_relationship_note_with_npc(other.npc_name)
		var same_fam: bool = (sel.family_id != "none" and sel.family_id != "" and sel.family_id != "family_police" and other.family_id == sel.family_id)
		var other_id: String = str(other.person_profile.person_id) if other.person_profile != null else other.npc_id
		var is_partner: bool = (sel.person_profile != null and str(sel.person_profile.partner_id) != "" and str(sel.person_profile.partner_id) == other_id)
		if same_fam:
			var kin_state: String = "💀 Difunto" if other.is_dead else ("😟 Buscando" if is_instance_valid(other._searching_missing_kin) else "🟢 En el valle")
			family_list.append("%s (%s · %+d · %s)" % [other.npc_name, other.npc_role, rel_val, kin_state])
		rel_entries.append({
			"npc": other,
			"name": other.npc_name,
			"role": other.npc_role,
			"val": rel_val,
			"note": note_str,
			"same_fam": same_fam,
			"is_partner": is_partner
		})

	rel_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["val"]) > int(b["val"])
	)

	var best_friends: Array[String] = []
	var main_enemies: Array[String] = []
	for e in rel_entries:
		var v_sc: int = int(e["val"])
		if not bool(e["same_fam"]) and v_sc >= 20 and best_friends.size() < 3:
			best_friends.append("%s (%+d)" % [str(e["name"]), v_sc])
		if v_sc <= -20 and main_enemies.size() < 3:
			main_enemies.append("%s (%+d)" % [str(e["name"]), v_sc])

	var fam_str: String = ", ".join(family_list) if not family_list.is_empty() else "Sin familiares directos en el hogar (Independiente)"
	var friends_str: String = ", ".join(best_friends) if not best_friends.is_empty() else "Trato cordial sin amigos íntimos aún"
	var enemies_str: String = ", ".join(main_enemies) if not main_enemies.is_empty() else "Sin enemistades declaradas actualmente"

	_highlights_label.text = (
		"[color=#ff99aa][b]❤️ Familia Cercana:[/b][/color] %s\n" % fam_str +
		"[color=#88ffaa][b]🌟 Mejores Amigos:[/b][/color] %s\n" % friends_str +
		"[color=#ff8866][b]💢 Enemistades Principales / Rivales:[/b][/color] %s" % enemies_str
	)

	# 5. Tabla Social RimWorld — filas reutilizadas (pool): solo se actualizan textos/colores, sin crear ni destruir nodos
	if not rebuild_lists:
		return
	_sync_social_table_rows(rel_entries)

var _relations_initialized: bool = false
var _list_buttons: Dictionary = {} # VillageNPC -> Button
var _table_rows: Array[Dictionary] = []
var _style_sel_btn: StyleBoxFlat = null
var _style_row_good: StyleBoxFlat = null
var _style_row_bad: StyleBoxFlat = null
var _style_row_neutral: StyleBoxFlat = null

func _ensure_cached_styles() -> void:
	if _style_sel_btn != null:
		return
	_style_sel_btn = _make_box_style(Color(0.20, 0.25, 0.34, 0.98), Color(0.95, 0.78, 0.35, 0.95), 1, 5)
	_style_row_good = _make_box_style(Color(0.09, 0.11, 0.15, 0.94), Color(0.32, 0.65, 0.42, 0.85), 1, 4)
	_style_row_bad = _make_box_style(Color(0.09, 0.11, 0.15, 0.94), Color(0.72, 0.30, 0.30, 0.85), 1, 4)
	_style_row_neutral = _make_box_style(Color(0.09, 0.11, 0.15, 0.94), Color(0.24, 0.30, 0.38, 0.75), 1, 4)

func _select_npc(target: VillageNPC) -> void:
	selected_npc = target
	refresh_ui()

func _sync_neighbor_list_buttons(all_npcs: Array[VillageNPC]) -> void:
	_ensure_cached_styles()
	# Retirar botones de NPC que ya no existen
	for key in _list_buttons.keys():
		if not is_instance_valid(key) or not (key in all_npcs):
			var old_btn: Button = _list_buttons[key]
			if is_instance_valid(old_btn):
				old_btn.queue_free()
			_list_buttons.erase(key)
	var order_idx: int = 0
	for v in all_npcs:
		var btn: Button = _list_buttons.get(v, null)
		if btn == null:
			btn = Button.new()
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.custom_minimum_size = Vector2(0, 32)
			var target_ref: VillageNPC = v
			btn.pressed.connect(func() -> void: _select_npc(target_ref))
			_npc_list_vbox.add_child(btn)
			_list_buttons[v] = btn
		if btn.get_index() != order_idx:
			_npc_list_vbox.move_child(btn, order_idx)
		order_idx += 1
		var st_icon: String = "💀" if v.is_dead else ("😟" if is_instance_valid(v._searching_missing_kin) else ("🩸" if v.is_downed else "🟢"))
		btn.text = "%s %s %s (%s) [Tú: %+d]" % [st_icon, _get_role_icon(int(v.trade_role)), v.npc_name, v.npc_role.split(" ")[0], v.affinity]
		if v == selected_npc:
			btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
			btn.add_theme_stylebox_override("normal", _style_sel_btn)
		else:
			btn.add_theme_color_override("font_color", Color(0.62, 0.55, 0.55) if v.is_dead else Color(0.88, 0.92, 0.96))
			btn.remove_theme_stylebox_override("normal")

func _create_table_row() -> Dictionary:
	var row_panel := PanelContainer.new()
	var row_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		row_margin.add_theme_constant_override(side, 6)
	row_panel.add_child(row_margin)
	var row_hbox := HBoxContainer.new()
	row_hbox.add_theme_constant_override("separation", 10)
	row_margin.add_child(row_hbox)
	var score_lbl := Label.new()
	score_lbl.custom_minimum_size = Vector2(54, 0)
	score_lbl.add_theme_font_size_override("font_size", 13)
	row_hbox.add_child(score_lbl)
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	row_hbox.add_child(info_vbox)
	var name_tier_lbl := Label.new()
	name_tier_lbl.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(name_tier_lbl)
	var reason_lbl := Label.new()
	reason_lbl.add_theme_font_size_override("font_size", 10)
	reason_lbl.add_theme_color_override("font_color", Color(0.76, 0.80, 0.88))
	info_vbox.add_child(reason_lbl)
	var jump_btn := Button.new()
	jump_btn.text = "Ver Ficha ➡️"
	jump_btn.custom_minimum_size = Vector2(88, 24)
	row_hbox.add_child(jump_btn)
	_social_table_vbox.add_child(row_panel)
	var row: Dictionary = {"panel": row_panel, "score": score_lbl, "name": name_tier_lbl, "reason": reason_lbl, "jump": jump_btn, "target": null}
	jump_btn.pressed.connect(func() -> void:
		var tgt = row.get("target")
		if tgt is VillageNPC and is_instance_valid(tgt):
			_select_npc(tgt as VillageNPC)
	)
	return row

var _row_fill_entries: Array[Dictionary] = []
var _row_fill_idx: int = 0
const ROWS_PER_FRAME: int = 5

## Reparte la actualización de la tabla social en varios fotogramas (5 filas por frame) para evitar un tirón al cambiar de vecino.
func _sync_social_table_rows(rel_entries: Array[Dictionary]) -> void:
	_ensure_cached_styles()
	_row_fill_entries = rel_entries
	_row_fill_idx = 0
	# Ocultar de inmediato las filas sobrantes
	for i in range(rel_entries.size(), _table_rows.size()):
		(_table_rows[i]["panel"] as PanelContainer).visible = false
		_table_rows[i]["target"] = null
	_fill_rows_step(ROWS_PER_FRAME)

func _fill_rows_step(max_rows: int) -> void:
	var done: int = 0
	while _row_fill_idx < _row_fill_entries.size() and done < max_rows:
		if _table_rows.size() <= _row_fill_idx:
			_table_rows.append(_create_table_row())
		_fill_table_row(_table_rows[_row_fill_idx], _row_fill_entries[_row_fill_idx])
		_row_fill_idx += 1
		done += 1

func _fill_table_row(row: Dictionary, entry: Dictionary) -> void:
	var panel: PanelContainer = row["panel"]
	panel.visible = true
	var other_npc: VillageNPC = entry["npc"] as VillageNPC
	var r_val: int = int(entry["val"])
	var is_fam: bool = bool(entry["same_fam"])
	var is_part: bool = bool(entry.get("is_partner", false))
	var tier_lbl: String = VillageNPC.get_relationship_tier_label(r_val, is_fam, is_part)
	panel.add_theme_stylebox_override("panel", _style_row_good if r_val >= 35 else (_style_row_bad if r_val <= -25 else _style_row_neutral))
	var sc_col: Color = Color(0.45, 1.0, 0.62) if r_val >= 35 else (Color(0.75, 0.95, 0.75) if r_val >= 12 else (Color(1.0, 0.45, 0.42) if r_val <= -25 else Color(0.85, 0.85, 0.85)))
	var score_lbl: Label = row["score"]
	score_lbl.text = "%+d" % r_val
	score_lbl.add_theme_color_override("font_color", sc_col)
	var dead_tag: String = " [💀 Difunto]" if other_npc.is_dead else ""
	var name_lbl: Label = row["name"]
	name_lbl.text = "%s %s (%s)%s — %s" % [_get_role_icon(int(other_npc.trade_role)), other_npc.npc_name, other_npc.npc_role, dead_tag, tier_lbl]
	name_lbl.add_theme_color_override("font_color", sc_col)
	(row["reason"] as Label).text = "↳ Motivo / Vínculo: %s" % str(entry["note"])
	row["target"] = other_npc
