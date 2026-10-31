extends Control
class_name MedicalPanelUI

var player: Node2D = null
var target_entity: Node2D = null
var main_panel: PanelContainer = null
var title_label: Label = null
var wash_self_btn: Button = null
var switch_target_btn: Button = null
var regions_box: VBoxContainer = null
var capacities_label: Label = null
var organs_label: Label = null
var wounds_box: VBoxContainer = null
var supplies_label: Label = null

const CAP_NAMES: Dictionary = {
	"consciousness": "🧠 Conciencia",
	"moving": "🦵 Locomoción (Piernas)",
	"manipulation": "💪 Manipulación (Brazos)",
	"breathing": "🫁 Respiración y Bombeo",
	"filtration": "🛡️ Filtración e Inmunidad"
}

func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func _make_box_style(bg: Color, border: Color, bw: int = 2, cr: int = 6, mx: int = 10, my: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(cr)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	return s

func _add_lbl(parent: Node, txt: String, sz: int, col: Color, expand: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	if expand:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(760, 470)
	main_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.08, 0.10, 0.13, 0.97), Color(0.78, 0.28, 0.32), 2, 8, 14, 12))
	center.add_child(main_panel)

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 8)
	main_panel.add_child(root_v)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root_v.add_child(header)

	title_label = _add_lbl(header, "🩺 EXAMEN CLÍNICO Y ANATÓMICO — TU CUERPO", 16, Color(1.0, 0.86, 0.55), true)

	wash_self_btn = Button.new()
	wash_self_btn.text = "💧 Lavarse Manos y Ropa"
	wash_self_btn.add_theme_font_size_override("font_size", 12)
	wash_self_btn.pressed.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("wash_bloodstains"):
			player.call("wash_bloodstains", true)
			refresh_ui()
	)
	header.add_child(wash_self_btn)

	switch_target_btn = Button.new()
	switch_target_btn.text = "🔍 Examinar NPC Cercano"
	switch_target_btn.add_theme_font_size_override("font_size", 12)
	switch_target_btn.pressed.connect(_on_switch_patient_pressed)
	header.add_child(switch_target_btn)

	var close_btn := Button.new()
	close_btn.text = "✕ Cerrar [H / ESC]"
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.pressed.connect(close_panel)
	header.add_child(close_btn)

	supplies_label = _add_lbl(root_v, "", 12, Color(0.75, 0.92, 0.80))

	var body_split := HBoxContainer.new()
	body_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_split.add_theme_constant_override("separation", 12)
	root_v.add_child(body_split)

	# Columna Izquierda: Regiones, Capacidades Vitales y Órganos
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(310, 0)
	left_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.05, 0.07, 0.09, 0.95), Color(0.28, 0.38, 0.48), 1, 6, 10, 8))
	body_split.add_child(left_panel)

	var left_v := VBoxContainer.new()
	left_v.add_theme_constant_override("separation", 6)
	left_panel.add_child(left_v)

	_add_lbl(left_v, "🧍 REGIONES CORPORALES (Project Zomboid)", 13, Color(0.95, 0.78, 0.45))
	regions_box = VBoxContainer.new()
	regions_box.add_theme_constant_override("separation", 4)
	left_v.add_child(regions_box)

	var sep1 := HSeparator.new()
	left_v.add_child(sep1)
	_add_lbl(left_v, "⚡ CAPACIDADES VITALES (RimWorld)", 13, Color(0.55, 0.88, 1.0))
	capacities_label = _add_lbl(left_v, "", 12, Color(0.88, 0.92, 0.96))

	var sep2 := HSeparator.new()
	left_v.add_child(sep2)
	_add_lbl(left_v, "🫀 ÓRGANOS INTERNOS", 13, Color(1.0, 0.62, 0.68))
	organs_label = _add_lbl(left_v, "", 11, Color(0.85, 0.85, 0.90))
	organs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Columna Derecha: Lista de Heridas y Tratamiento Clínico
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.05, 0.07, 0.09, 0.95), Color(0.38, 0.28, 0.32), 1, 6, 10, 8))
	body_split.add_child(right_panel)

	var right_v := VBoxContainer.new()
	right_v.add_theme_constant_override("separation", 6)
	right_panel.add_child(right_v)

	_add_lbl(right_v, "🩹 DIAGNÓSTICO DE HERIDAS Y TRATAMIENTO POR REGIÓN", 13, Color(1.0, 0.75, 0.55))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_v.add_child(scroll)

	wounds_box = VBoxContainer.new()
	wounds_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wounds_box.add_theme_constant_override("separation", 6)
	scroll.add_child(wounds_box)

func toggle_panel(custom_target: Node2D = null) -> void:
	if visible and custom_target == null:
		close_panel()
	else:
		open_panel(custom_target)

func open_panel(custom_target: Node2D = null) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	target_entity = custom_target if is_instance_valid(custom_target) else player
	visible = true
	refresh_ui()

func close_panel() -> void:
	visible = false

func _find_nearby_npc() -> Node2D:
	if not is_instance_valid(player):
		return null
	var best: Node2D = null
	var best_d2: float = 68.0 * 68.0
	for n in get_tree().get_nodes_in_group("village_npcs"):
		if n is Node2D and n != player:
			if "corpse_buried" in n and bool(n.get("corpse_buried")):
				continue
			var d2: float = player.global_position.distance_squared_to((n as Node2D).global_position)
			if d2 <= best_d2:
				best_d2 = d2
				best = n as Node2D
	return best

func _on_switch_patient_pressed() -> void:
	var near_npc := _find_nearby_npc()
	if target_entity == player and is_instance_valid(near_npc):
		target_entity = near_npc
	else:
		target_entity = player
	refresh_ui()

func refresh_ui() -> void:
	if not visible:
		return
	if not is_instance_valid(target_entity):
		target_entity = player
	if not is_instance_valid(target_entity):
		return

	var hc: HealthComponent = target_entity.get_node_or_null("HealthComponent")
	if not hc:
		return

	var near_npc := _find_nearby_npc()
	if is_instance_valid(wash_self_btn):
		var stained_now: bool = is_instance_valid(player) and player.has_method("is_bloodstained") and bool(player.call("is_bloodstained"))
		if stained_now:
			wash_self_btn.text = "🩸💧 Lavarse la Sangre (%ds)" % int(ceil(float(player.get("bloodstained_timer"))))
			wash_self_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
		else:
			wash_self_btn.text = "💧 Lavarse Manos y Ropa"
			wash_self_btn.add_theme_color_override("font_color", Color(0.70, 0.95, 1.0))
	if is_instance_valid(near_npc):
		switch_target_btn.visible = true
		var n_name: String = str(near_npc.get("npc_name")) if "npc_name" in near_npc else near_npc.name
		switch_target_btn.text = ("🧍 Volver a Mi Cuerpo" if target_entity != player else ("🔍 Examinar a %s" % n_name))
	else:
		if target_entity != player:
			target_entity = player
			hc = player.get_node_or_null("HealthComponent")
		switch_target_btn.visible = false

	var pat_name: String = "TU CUERPO (Forastero)" if target_entity == player else ("%s (%s)" % [str(target_entity.get("npc_name")), str(target_entity.get("npc_role"))])
	var dead_tag: String = " [CADÁVER]" if target_entity.get("is_dead") == true else (" [AGONIZANDO]" if target_entity.get("is_downed") == true else "")
	var eff_max_hp: int = int(round(hc.get_effective_max_health()))
	title_label.text = "🩺 %s%s — Resistencia: %d/%d HP  |  🩸 Pérdida Sangre: %d%% (%s)" % [pat_name, dead_tag, int(round(hc.current_health)), eff_max_hp, int(round(hc.current_blood)), hc.get_blood_loss_stage_name()]

	var inv: SimpleInventory = player.get("inventory") if is_instance_valid(player) else null
	if inv:
		supplies_label.text = "🎒 Botiquín disponible: 🩹Vendajes: %d  |  🌿Hierbas: %d  |  🧪Cataplasmas: %d  |  🧰Botiquín Quirúrgico: %d  |  🪵Madera: %d" % [
			inv.get_count("bandage"), inv.get_count("herbs"), inv.get_count("herbal_poultice"), inv.get_count("surgical_kit"), inv.get_count("wood")
		]

	for c in regions_box.get_children():
		c.queue_free()
	for r_id in HealthComponent.REGION_ORDER:
		var r_def: Dictionary = HealthComponent.REGION_DEFS[r_id]
		var m_hp: float = float(r_def["max_hp"])
		var c_hp: float = float(hc.region_hp.get(r_id, m_hp))
		var ratio: float = clampf(c_hp / maxf(1.0, m_hp), 0.0, 1.0)
		var row := HBoxContainer.new()
		regions_box.add_child(row)
		var r_col: Color = Color(0.42, 0.95, 0.52) if ratio >= 0.85 else (Color(0.98, 0.82, 0.35) if ratio >= 0.50 else Color(1.0, 0.38, 0.38))
		_add_lbl(row, "• %s:" % str(r_def["name"]), 12, r_col, true)
		_add_lbl(row, "%d / %d HP (%d%%)" % [int(round(c_hp)), int(round(m_hp)), int(round(ratio * 100.0))], 12, r_col)

	var caps: Dictionary = hc.get_capacities()
	var cap_lines: Array[String] = []
	for k in ["consciousness", "moving", "manipulation", "breathing", "filtration"]:
		var pct: int = int(round(float(caps.get(k, 1.0)) * 100.0))
		cap_lines.append("%s: %d%%" % [str(CAP_NAMES[k]), pct])
	var bleed_dps: float = hc.get_total_wound_bleed_rate() + (hc._bleed_dps if hc._bleed_timer > 0.0 else 0.0)
	var eta_sec: int = hc.get_bleedout_eta_seconds()
	var bleed_str: String = ("ACTIVO (+%.2f%%/s -> Muerte en ~%ds)" % [bleed_dps, eta_sec]) if (hc.is_bleeding or bleed_dps > 0.0) else "Controlado (Regenerando sangre)"
	cap_lines.append("🩸 Pérdida de Sangre: %d%% [%s] — %s" % [int(round(hc.current_blood)), hc.get_blood_loss_stage_name(), bleed_str])
	cap_lines.append("💥 Dolor Acumulado: %d%%  |  🛡️ Tope Resistencia: %d/%d HP" % [int(round(hc.get_total_pain())), int(round(hc.get_effective_max_health())), int(round(hc.max_health))])
	cap_lines.append(hc.get_sickness_summary_label())
	capacities_label.text = "\n".join(cap_lines)

	var org_parts: Array[String] = []
	for o_id in HealthComponent.ORGAN_DEFS.keys():
		var o_name: String = str(HealthComponent.ORGAN_DEFS[o_id]["name"])
		var o_val: int = int(round(float(hc.organ_hp.get(o_id, 100.0))))
		org_parts.append("%s: %d%%" % [o_name, o_val])
	organs_label.text = " · ".join(org_parts)

	for c in wounds_box.get_children():
		c.queue_free()

	var is_corpse: bool = (target_entity.get("is_dead") == true)
	if not is_corpse and hc.has_active_sickness_or_infection():
		var sick_card := PanelContainer.new()
		sick_card.add_theme_stylebox_override("panel", _make_box_style(Color(0.14, 0.16, 0.11, 0.96), Color(0.65, 0.85, 0.35), 1, 5, 8, 6))
		wounds_box.add_child(sick_card)
		var scv := VBoxContainer.new()
		scv.add_theme_constant_override("separation", 4)
		sick_card.add_child(scv)
		var cause_txt: String = (" (Origen: %s)" % hc.last_sickness_cause) if hc.last_sickness_cause != "" else ""
		_add_lbl(scv, "🦠 Cuadro Infeccioso / Toxicológico Activo%s" % cause_txt, 12, Color(0.85, 1.0, 0.45))
		_add_lbl(scv, "   %s" % hc.get_sickness_summary_label(), 11, Color(0.86, 0.92, 0.78))
		var sbtn_row := HBoxContainer.new()
		scv.add_child(sbtn_row)
		_add_treat_btn(sbtn_row, "🍵 Purgar Fiebre y Toxinas (1 Cataplasma o 2 Hierbas)", hc, -1, "cure_sickness")

	if is_instance_valid(player) and player.has_method("is_bloodstained") and bool(player.call("is_bloodstained")):
		var bcard := PanelContainer.new()
		bcard.add_theme_stylebox_override("panel", _make_box_style(Color(0.20, 0.09, 0.11, 0.96), Color(0.95, 0.30, 0.35), 1, 5, 8, 6))
		wounds_box.add_child(bcard)
		var bcv := VBoxContainer.new()
		bcv.add_theme_constant_override("separation", 4)
		bcard.add_child(bcv)
		_add_lbl(bcv, "🩸🖐️ ¡Manos y Ropa Manchadas de Sangre! (%ds restantes)" % int(ceil(float(player.get("bloodstained_timer")))), 12, Color(1.0, 0.50, 0.50))
		_add_lbl(bcv, "   Si el Inquisidor Real Alistair te inspecciona así, sumará +42% de sospecha forense.", 11, Color(0.92, 0.78, 0.78))
		var bbtn_row := HBoxContainer.new()
		bcv.add_child(bbtn_row)
		_add_treat_btn(bbtn_row, "💧 Lavarse la Sangre de las Manos y Ropa", hc, -1, "wash_bloodstains")

	_build_surgery_and_pockets_cards(hc, is_corpse)

	if hc.wounds.is_empty():
		_add_lbl(wounds_box, "✅ Sin heridas abiertas, fracturas ni traumatismos activos.", 13, Color(0.48, 0.95, 0.58))
		return
	for w in hc.wounds:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_box_style(Color(0.11, 0.13, 0.17, 0.96), Color(0.45, 0.32, 0.35), 1, 5, 8, 6))
		wounds_box.add_child(card)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)

		var r_key: String = str(w.get("region", "torso"))
		var r_title: String = str(HealthComponent.REGION_DEFS.get(r_key, {"name": "Torso"})["name"])
		var o_key: String = str(w.get("organ", ""))
		var o_str: String = (" [Órgano: %s]" % str(HealthComponent.ORGAN_DEFS[o_key]["name"])) if (o_key != "" and HealthComponent.ORGAN_DEFS.has(o_key)) else ""
		var w_id: int = int(w.get("id", 0))
		var w_type: String = str(w.get("type", "scratch"))

		var badges: Array[String] = []
		var w_bleed: float = float(w.get("bleed_rate", 0.0))
		var t_qual: int = int(round(float(w.get("tend_quality", 0.0))))
		if w_bleed > 0.0 and not bool(w.get("bandaged", false)) and not bool(w.get("stitched", false)):
			badges.append("🩸Sangrando (+%.2f%%/s)" % w_bleed)
		if bool(w.get("bandaged", false)):
			var dirty: float = float(w.get("bandage_dirty", 0.0))
			if t_qual > 0 and t_qual <= 32:
				badges.append("🖐️Rudimentario (%d%%)" % t_qual)
			else:
				badges.append(("🩹Vendado Sucio (%d%%)" % t_qual) if dirty >= 55.0 else ("🩹Vendado (%d%%)" % t_qual))
		if bool(w.get("stitched", false)):
			badges.append("🧵Suturado (%d%%)" % max(t_qual, 90))
		if bool(w.get("splinted", false)):
			badges.append("🩼Entablillado")
		if bool(w.get("clean", false)):
			badges.append("✨Limpio")
		var inf_pct: int = int(round(float(w.get("infection", 0.0))))
		var imm_pct: int = int(round(maxf(float(w.get("immunity", 0.0)), hc.systemic_immunity)))
		if inf_pct >= 5:
			badges.append("🦠Infección %d%% vs 🛡️Inmunidad %d%%" % [inf_pct, imm_pct])

		var badge_txt: String = ("  [" + " | ".join(badges) + "]") if not badges.is_empty() else "  [⚠️Sin tratar]"
		_add_lbl(cv, "📍 %s%s — %s (Causa: %s)%s" % [r_title, o_str, str(w.get("name", "Herida")), str(w.get("weapon_cause", "Impacto")), badge_txt], 12, Color(1.0, 0.85, 0.65))
		_add_lbl(cv, "   Severidad: %d%%   |   Dolor: +%d%%   |   Calidad Cura: %d%%   |   Infección: %d%% (Inmunidad: %d%%)" % [int(round(float(w.get("severity", 10.0)))), int(round(float(w.get("pain", 5.0)))), t_qual, inf_pct, imm_pct], 11, Color(0.80, 0.84, 0.90))

		if is_corpse:
			continue

		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		cv.add_child(btn_row)

		_add_treat_btn(btn_row, "💧 Lavar", hc, w_id, "wash")
		if not bool(w.get("bandaged", false)) and not bool(w.get("stitched", false)):
			_add_treat_btn(btn_row, "🖐️ Cura Rudimentaria (Gratis)", hc, w_id, "tend_makeshift")
		if not bool(w.get("bandaged", false)) or float(w.get("bandage_dirty", 0.0)) >= 35.0 or t_qual <= 35:
			_add_treat_btn(btn_row, "🩹 Vendar", hc, w_id, "bandage")
		_add_treat_btn(btn_row, "🌿 Cataplasma", hc, w_id, "poultice")
		if w_type in ["deep_wound", "lodged_arrow"] and not bool(w.get("stitched", false)):
			var st_lbl: String = "🏹 Extraer y Suturar" if w_type == "lodged_arrow" else "🧵 Suturar"
			_add_treat_btn(btn_row, st_lbl, hc, w_id, "stitch")
		if w_type == "fracture" and not bool(w.get("splinted", false)):
			_add_treat_btn(btn_row, "🩼 Entablillar", hc, w_id, "splint")

func _add_treat_btn(parent: Node, label_txt: String, hc: HealthComponent, wound_id: int, action: String) -> void:
	var b := Button.new()
	b.text = label_txt
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(func() -> void: _apply_treatment(hc, wound_id, action))
	parent.add_child(b)

func _apply_treatment(hc: HealthComponent, wound_id: int, action: String) -> void:
	if not is_instance_valid(player) or not is_instance_valid(hc):
		return
	var inv: SimpleInventory = player.get("inventory")
	if not inv:
		return

	match action:
		"wash_bloodstains":
			if player.has_method("wash_bloodstains"):
				player.call("wash_bloodstains")
		"wash":
			hc.treat_wound(wound_id, "wash")
			if player.has_method("wash_bloodstains"):
				player.call("wash_bloodstains")
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "💧 Herida lavada y limpia", Color.AQUA, -40.0)
		"tend_makeshift":
			hc.treat_wound(wound_id, "tend_makeshift")
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "🖐️ Vendaje rudimentario aplicado (Sangrado detenido, calidad 25%)", Color(0.95, 0.80, 0.42), -40.0)
		"bandage":
			if inv.has_item("bandage", 1):
				inv.remove_item("bandage", 1)
			elif inv.has_item("herbs", 1):
				inv.remove_item("herbs", 1)
			else:
				if player.has_method("_spawn_floating_text"):
					player.call("_spawn_floating_text", "❌ Necesitas 1 Vendaje o 1 Hierba Medicinal", Color.CORAL, -40.0)
				return
			hc.treat_wound(wound_id, "bandage")
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "🩹 Herida vendada (Sangrado detenido)", Color.SPRING_GREEN, -40.0)
		"poultice":
			if not inv.has_item("herbal_poultice", 1):
				if player.has_method("_spawn_floating_text"):
					player.call("_spawn_floating_text", "❌ Necesitas 1 Cataplasma Curativa", Color.CORAL, -40.0)
				return
			inv.remove_item("herbal_poultice", 1)
			hc.treat_wound(wound_id, "poultice")
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "🌿 Cataplasma aplicada (-Severidad y Dolor)", Color.SPRING_GREEN, -40.0)
		"stitch":
			if inv.has_item("surgical_kit", 1):
				inv.remove_item("surgical_kit", 1)
			elif inv.has_item("bandage", 1) and inv.has_item("sinew_viscera", 1):
				inv.remove_item("bandage", 1)
				inv.remove_item("sinew_viscera", 1)
			else:
				if player.has_method("_spawn_floating_text"):
					player.call("_spawn_floating_text", "❌ Necesitas 1 Botiquín Quirúrgico (o 1 Vendaje + 1 Tendones)", Color.CORAL, -40.0)
				return
			hc.treat_wound(wound_id, "stitch")
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "🧵 Herida profunda suturada con éxito", Color.AQUA, -40.0)
		"splint":
			if inv.has_item("surgical_kit", 1):
				inv.remove_item("surgical_kit", 1)
			elif inv.has_item("wood", 1) and inv.has_item("bandage", 1):
				inv.remove_item("wood", 1)
				inv.remove_item("bandage", 1)
			else:
				if player.has_method("_spawn_floating_text"):
					player.call("_spawn_floating_text", "❌ Necesitas 1 Madera + 1 Vendaje (o 1 Botiquín Quirúrgico)", Color.CORAL, -40.0)
				return
			hc.treat_wound(wound_id, "splint")
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "🩼 Fractura entablillada (+Movilidad)", Color.SPRING_GREEN, -40.0)
		"cure_sickness":
			if inv.has_item("surgical_kit", 1):
				inv.remove_item("surgical_kit", 1)
				hc.cure_sickness(80.0)
			elif inv.has_item("herbal_poultice", 1):
				inv.remove_item("herbal_poultice", 1)
				hc.cure_sickness(55.0)
			elif inv.has_item("herbs", 2):
				inv.remove_item("herbs", 2)
				hc.cure_sickness(45.0)
			else:
				if player.has_method("_spawn_floating_text"):
					player.call("_spawn_floating_text", "❌ Necesitas 1 Cataplasma, 2 Hierbas o 1 Botiquín Quirúrgico", Color.CORAL, -40.0)
				return
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "🍵 Fiebre, infección y toxinas reducidas", Color.SPRING_GREEN, -40.0)
		_:
			_handle_surgery_or_pocket_action(hc, inv, action)
	refresh_ui()

func _build_surgery_and_pockets_cards(hc: HealthComponent, is_corpse: bool) -> void:
	var inv: SimpleInventory = player.get("inventory") if is_instance_valid(player) else null
	var is_npc: bool = is_instance_valid(target_entity) and target_entity != player
	var can_extract: bool = false
	if is_npc:
		var sed_t: float = float(target_entity.get("sedated_timer")) if "sedated_timer" in target_entity else 0.0
		var rot_h: float = float(target_entity.get("corpse_rot_hours")) if "corpse_rot_hours" in target_entity else 0.0
		var in_morgue: bool = ("corpse_in_morgue" in target_entity and bool(target_entity.get("corpse_in_morgue")) and not bool(target_entity.get("corpse_buried")))
		if target_entity.get("is_downed") == true or target_entity.get("is_sleeping") == true or sed_t > 0.0 or target_entity.get("is_stunned_flag") == true or (is_corpse and (rot_h < 12.0 or in_morgue)):
			can_extract = true

	var surg_btns: Array[Dictionary] = []
	for o_id in HealthComponent.ORGAN_ITEM_MAP.keys():
		var o_name: String = str(HealthComponent.ORGAN_DEFS[o_id]["name"])
		var o_hp: float = float(hc.organ_hp.get(o_id, 100.0))
		var item_id: String = str(HealthComponent.ORGAN_ITEM_MAP[o_id])
		if not is_corpse and o_hp < 95.0 and inv and inv.has_item(item_id, 1):
			surg_btns.append({"lbl": "🫀 Trasplantar %s (%d%% -> 100%%)" % [o_name, int(round(o_hp))], "act": "transplant_organ:" + o_id})
		if can_extract and o_hp >= 35.0:
			var warn: String = "⚠️Letal" if (o_id in ["heart", "liver"] or (o_id in ["lungs", "kidneys"] and o_hp <= 55.0)) else "Parcial"
			surg_btns.append({"lbl": "🔪 Extraer %s [%s]" % [o_name, warn], "act": "extract_organ:" + o_id})

	if not surg_btns.is_empty():
		var scard := PanelContainer.new()
		scard.add_theme_stylebox_override("panel", _make_box_style(Color(0.16, 0.10, 0.14, 0.96), Color(0.85, 0.35, 0.55), 1, 5, 8, 6))
		wounds_box.add_child(scard)
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 4)
		scard.add_child(sv)
		_add_lbl(sv, "🔪 Cirugía de Órganos y Trasplantes (RimWorld — Requiere 1 Botiquín Quirúrgico)", 12, Color(1.0, 0.65, 0.80))
		var sflow := HFlowContainer.new()
		sflow.add_theme_constant_override("h_separation", 6)
		sflow.add_theme_constant_override("v_separation", 4)
		sv.add_child(sflow)
		for sb in surg_btns:
			_add_treat_btn(sflow, str(sb["lbl"]), hc, -1, str(sb["act"]))

	if is_npc and target_entity.has_method("get_pocket_summary_text"):
		var pcard := PanelContainer.new()
		pcard.add_theme_stylebox_override("panel", _make_box_style(Color(0.12, 0.13, 0.18, 0.96), Color(0.75, 0.68, 0.35), 1, 5, 8, 6))
		wounds_box.add_child(pcard)
		var pv := VBoxContainer.new()
		pv.add_theme_constant_override("separation", 4)
		pcard.add_child(pv)
		var ch_pct: int = int(round(float(target_entity.call("get_pickpocket_success_chance", player)) * 100.0))
		_add_lbl(pv, "🕵️ Bolsillos de %s (Éxito de Sigilo: %d%%): %s" % [str(target_entity.get("npc_name")), ch_pct, str(target_entity.call("get_pocket_summary_text"))], 12, Color(1.0, 0.90, 0.50))
		var pflow := HFlowContainer.new()
		pflow.add_theme_constant_override("h_separation", 6)
		pflow.add_theme_constant_override("v_separation", 4)
		pv.add_child(pflow)
		if int(target_entity.get("personal_gold")) > 0:
			_add_treat_btn(pflow, "💰 Hurtar Oro (%d)" % int(target_entity.get("personal_gold")), hc, -1, "npc_steal_gold")
		var p_dict: Dictionary = target_entity.get("pocket_items") if "pocket_items" in target_entity else {}
		for pk in p_dict.keys():
			if int(p_dict[pk]) > 0:
				var nm: String = inv.get_item_name(str(pk)) if inv else str(pk)
				_add_treat_btn(pflow, "🤏 Hurtar %s" % nm, hc, -1, "npc_steal_item:" + str(pk))
		if inv:
			for plant_id in ["royal_safe_conduct", "poisoned_stew", "spoiled_food", "organ_heart", "organ_kidney", "organ_liver", "bread", "country_stew"]:
				if inv.has_item(plant_id, 1):
					_add_treat_btn(pflow, "📥 Meter %s" % inv.get_item_name(plant_id), hc, -1, "npc_plant_item:" + plant_id)

func _handle_surgery_or_pocket_action(hc: HealthComponent, inv: SimpleInventory, action: String) -> void:
	if action == "npc_steal_gold" and is_instance_valid(target_entity) and target_entity.has_method("attempt_pickpocket_or_plant"):
		target_entity.call("attempt_pickpocket_or_plant", player, "steal_gold")
	elif action.begins_with("npc_steal_item:") and is_instance_valid(target_entity) and target_entity.has_method("attempt_pickpocket_or_plant"):
		target_entity.call("attempt_pickpocket_or_plant", player, "steal_item", action.get_slice(":", 1))
	elif action.begins_with("npc_plant_item:") and is_instance_valid(target_entity) and target_entity.has_method("attempt_pickpocket_or_plant"):
		target_entity.call("attempt_pickpocket_or_plant", player, "plant_item", action.get_slice(":", 1))
	elif action.begins_with("extract_organ:"):
		if not inv.has_item("surgical_kit", 1):
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "❌ Necesitas 1 Botiquín Quirúrgico para extraer órganos", Color.CORAL, -40.0)
			return
		var o_id: String = action.get_slice(":", 1)
		if is_instance_valid(target_entity) and target_entity != player:
			target_entity.set("last_hit_weapon_name", "Bisturí Quirúrgico (Extracción de Órgano)")
			target_entity.set("last_hit_by_player", true)
		var item_got: String = hc.extract_organ(o_id, "Bisturí Quirúrgico (Extracción de Órgano)")
		if item_got != "":
			inv.remove_item("surgical_kit", 1)
			inv.add_item(item_got, 1)
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "🔪 Extraído: +1 %s" % inv.get_item_name(item_got), Color(1.0, 0.45, 0.65), -44.0)
			var vm = get_tree().get_first_node_in_group("village_manager")
			if vm and is_instance_valid(target_entity) and target_entity is Node2D and vm.has_method("_find_conscious_witness_near"):
				var w = vm.call("_find_conscious_witness_near", (target_entity as Node2D).global_position, 150.0, target_entity)
				if w != null and vm.has_method("report_theft_crime"):
					vm.call("report_theft_crime", str(target_entity.get("family_id")), "Extracción clandestina de órganos a " + str(target_entity.get("npc_name")), (target_entity as Node2D).global_position)
	elif action.begins_with("transplant_organ:"):
		var o_id2: String = action.get_slice(":", 1)
		var req_item: String = str(HealthComponent.ORGAN_ITEM_MAP.get(o_id2, ""))
		if req_item == "" or not inv.has_item(req_item, 1) or not inv.has_item("surgical_kit", 1):
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "❌ Necesitas 1 Botiquín Quirúrgico + 1 %s" % inv.get_item_name(req_item), Color.CORAL, -40.0)
			return
		if hc.transplant_organ(o_id2):
			inv.remove_item("surgical_kit", 1)
			inv.remove_item(req_item, 1)
			if player.has_method("_spawn_floating_text"):
				player.call("_spawn_floating_text", "🫀 ¡Trasplante de %s completado al 100%%!" % inv.get_item_name(req_item), Color.SPRING_GREEN, -44.0)
