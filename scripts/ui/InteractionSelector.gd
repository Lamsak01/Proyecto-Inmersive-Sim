extends Node2D

const WorldStage3DScript = preload("res://scripts/visuals/WorldStage3D.gd")
const VillageTavern = preload("res://scripts/systems/VillageTavern.gd")
const Anclas = preload("res://mapa/anclas.gd")

## Selector de la tecla [E] (2026-11-05). Antes, con varias cosas cerca (puerta, mostrador, vecino, cofre, caballo…),
## el juego elegía una por su cuenta. Ahora:
## 1. Encima de lo que se va a usar sale un letrero «[E] …», así sabes qué pasará antes de pulsar.
## 2. Manda el ratón: si el puntero está sobre una de las opciones, esa es la que se usa.
## 3. Si hay varias, [Mayús + rueda] o [G] pasa a la siguiente (el letrero dice «1/3»).
## Solo elige el objetivo: lo que hace cada cosa al usarla no cambia.

const REFRESH_S: float = 0.05
const MOUSE_PICK_PX: float = 16.0
const MOUSE_REACH_PX: float = 55.0

const STATION_LABELS: Dictionary = {
	"well": "Sacar agua del pozo",
	"tavern_games": "Mesa de juego de la posada",
	"tavern_pool": "Mesa de billar",
	"tavern_bed": "Alquilar cama de la posada (8 Oro)",
	"hospital_bed": "Cama de urgencias (10 Oro)",
	"morgue_table": "Mesa de autopsias",
	"police_jail": "Celda y fianza de la comisaría",
	"church_altar": "Altar de la capilla",
	"cemetery_gate": "Puerta del cementerio",
	"notice_board": "Tablón de encargos",
	"library_reading": "Leer un rato en la biblioteca",
	"compost": "Compostador",
	"building_window": "Abrir o cerrar el postigo",
	"house_chest": "Abrir el cofre",
	"shop_business_stall": "Gestionar el negocio",
	"case1_clearing": "Examinar orilla del arroyo",
	"mill_hayloft": "Examinar pajar",
	"mill_hearth": "Examinar hogar de piedra",
	"mill_hemp_cord": "Examinar rollo de cordel",
	"mill_table_paper": "Examinar papel sobre la mesa",
	"mill_cellar_grate": "Examinar reja de hierro",
	"mill_red_clay": "Examinar orilla de arcilla",
	"police_archived_report": "Examinar carpeta de archivo",
	"library_book_lever": "Examinar estantería",
	"library_secret_ledger": "Examinar cuaderno",
	"library_torn_book": "Examinar libro antiguo",
	"old_bridge_left_shoe": "Examinar zapato",
	"case1_forced_cabinet": "Examinar gabinete",
	"case1_relative_page": "Examinar hoja suelta",
	"case1_report_desk": "Entregar informe del caso",
}

var player: Node2D = null
var candidates: Array = [] # [{key, area, target, pos, label}] ordenadas por distancia
var _index: int = 0
var _last_keys: String = ""
var _refresh_t: float = 0.0
var _label: Label = null


func setup(p: Node2D) -> void:
	player = p
	name = "InteractionSelector"
	top_level = true
	z_index = 100
	_label = Label.new()
	_label.name = "PromptLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(220, 14)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	_label.visible = false
	add_child(_label)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_refresh_t -= delta
	if _refresh_t <= 0.0:
		_refresh_t = REFRESH_S
		refresh()
	_update_label()


func _unhandled_input(event: InputEvent) -> void:
	if candidates.size() < 2:
		return
	if player != null and is_instance_valid(player) and player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open")):
		return
	var step: int = 0
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step = 1
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			step = -1
	elif event is InputEventKey and event.pressed and not event.echo and Teclas.es(event, "otra_accion"):
		step = 1
	if step != 0:
		_index = posmod(_index + step, candidates.size())
		_update_label()
		get_viewport().set_input_as_handled()


## Recalcula qué cosas se pueden usar ahora mismo con [E].
func refresh() -> void:
	var out: Array = []
	var pp: Vector2 = player.global_position
	var vm_chk = player.get_tree().get_first_node_in_group("village_manager") if player.is_inside_tree() else null
	var pl_b_id: String = str(vm_chk._get_building_at_pos(pp).get("id", "")) if (vm_chk != null and vm_chk.has_method("_get_building_at_pos")) else ""
	var ia = player.get("interact_area")
	if ia is Area2D and is_instance_valid(ia):
		for a in (ia as Area2D).get_overlapping_areas():
			if not a.is_in_group("interactable") or not a.is_visible_in_tree():
				continue
			var tgt: Node = _resolve_target(a)
			if tgt == null:
				continue
			if pl_b_id != "" and tgt.is_in_group("sewer_grate"):
				continue
			# Paso a 3D, paso 3c: lo que está en el fondo del agua (meta «bajo_el_agua») solo se alcanza buceando
			if a.has_meta("bajo_el_agua") and not _buceando():
				continue
			# Paso a 3D, paso 5d: se llega a lo que está a tu altura (Vista.alcanza), no «a lo de tu piso»
			if vm_chk != null and not vm_chk.alcanza(pp, int(vm_chk.player_elevation_level), (a as Node2D).global_position, _nivel_de(a, tgt, int(vm_chk.player_elevation_level))):
				continue
			var lbl: String = _label_for(a, tgt)
			if lbl == "":
				continue
			var c_pos: Vector2 = (a as Node2D).global_position
			var fp_sc: float = 0.0
			if WorldStage3DScript.first_person_active:
				fp_sc = _fp_crosshair_score(a as Area2D, tgt, c_pos, pp)
				if fp_sc < 0.0:
					continue
			var st_tag: String = str(a.get_meta("village_station")) if a.has_meta("village_station") else ""
			out.append({"key": str(a.get_instance_id()), "area": a, "target": tgt, "pos": c_pos, "label": lbl, "fp_score": fp_sc, "station": st_tag})
	# Montado, «bajar del caballo» va la última: así puedes hablar o abrir puertas sin bajarte.
	var rank := func(c: Dictionary) -> float:
		if WorldStage3DScript.first_person_active:
			return -float(c.get("fp_score", 0.0))
		var d: float = pp.distance_squared_to(c["pos"])
		var t_node: Node = c["target"] as Node
		if t_node.is_in_group("player_horse") and bool(player.get("is_mounted")):
			d += 1000000.0
		elif t_node.is_in_group("player_cart") and (bool(player.get("is_pulling_cart")) or (bool(player.get("is_mounted")) and bool(player.get("is_cart_hitched")))):
			d += 900000.0
		elif t_node.is_in_group("player_livestock"):
			d -= 5000.0
		elif t_node.is_in_group("heist_target_prop") or t_node.is_in_group("tinker_station") or t_node.is_in_group("sewer_station"):
			d -= 120.0
		return d
	out.sort_custom(func(x, y): return rank.call(x) < rank.call(y))
	var keys: String = ",".join(out.map(func(c): return c["key"]))
	if keys != _last_keys:
		_last_keys = keys
		_index = 0
	candidates = out


## En 1.ª persona, [E] solo apunta a lo que está bajo la cruz del centro (en horizontal y vertical) y a poca distancia.
func _fp_crosshair_score(a: Area2D, tgt: Node, c_pos: Vector2, pp: Vector2) -> float:
	if tgt == null or not is_instance_valid(tgt):
		return -1.0
	var to_c: Vector2 = c_pos - pp
	var dist_px: float = to_c.length()
	var tag: String = str(a.get_meta("village_station")) if (a != null and a.has_meta("village_station")) else ""
	var is_floor_obj: bool = false
	var is_low_obj: bool = false
	var max_reach_px: float = 28.0
	var max_lat_px: float = 7.5

	if tgt.is_in_group("sewer_grate") or tgt.is_in_group("club_trapdoor"):
		is_floor_obj = true
		max_reach_px = 24.0
		max_lat_px = 7.0
	elif "prop_kind" in tgt and str(tgt.get("prop_kind")) in ["sewer_grate", "club_trapdoor"]:
		is_floor_obj = true
		max_reach_px = 24.0
		max_lat_px = 7.0
	elif tgt is VillageNPC:
		var n_chk := tgt as VillageNPC
		if (n_chk.is_dead or n_chk.is_downed) and not n_chk.corpse_in_morgue:
			is_floor_obj = true
			max_reach_px = 26.0
			max_lat_px = 8.0
		else:
			max_reach_px = 28.0
			max_lat_px = 7.5
	elif "animal_name" in tgt or "crop_stage" in tgt or String(tgt.name).begins_with("FarmPlot"):
		is_floor_obj = true
		max_reach_px = 26.0
		max_lat_px = 8.0
	elif "pet_name" in tgt or "node_title" in tgt or tgt.is_in_group("heist_target_prop"):
		is_low_obj = true
		max_reach_px = 26.0
		max_lat_px = 7.5
	elif tgt.is_in_group("fishing_spots") or "house_tier" in tgt or String(tgt.name) == "PlayerCampSite" or tgt.is_in_group("player_horse") or tgt.is_in_group("player_cart") or tgt.is_in_group("player_livestock"):
		max_reach_px = 32.0
		max_lat_px = 9.5

	if tag != "":
		match tag:
			"building_door", "building_window":
				max_reach_px = 24.0
				max_lat_px = 7.0
			"house_chest", "tavern_bed", "hospital_bed", "compost":
				is_low_obj = true
				max_reach_px = 25.0
				max_lat_px = 7.5
			"tavern_games", "tavern_pool", "morgue_table", "shop_business_stall", "library_reading", "mill_cellar_grate", "mill_red_clay", "old_bridge_left_shoe", "library_book_lever", "library_secret_ledger", "library_torn_book", "police_archived_report", "mill_table_paper", "mill_hemp_cord", "mill_hearth", "mill_hayloft", "case1_clearing", "case1_forced_cabinet", "case1_relative_page", "case1_report_desk":
				is_low_obj = true
				max_reach_px = 27.0
				max_lat_px = 8.5
			"notice_board", "well", "church_altar", "cemetery_gate", "police_jail":
				max_reach_px = 27.0
				max_lat_px = 8.0

	if dist_px > max_reach_px:
		return -1.0

	var fwd_2d: Vector2 = WorldStage3DScript.get_fp_forward_2d()
	var rgt_2d: Vector2 = WorldStage3DScript.get_fp_right_2d()
	var forward_px: float = to_c.dot(fwd_2d)
	var lateral_px: float = absf(to_c.dot(rgt_2d))
	var pitch: float = WorldStage3DScript.fp_pitch

	if is_floor_obj:
		# Objetos en el suelo (trampilla, alcantarilla, cadáver, parcela): exigen bajar la vista hacia ellos
		if pitch > -0.18:
			return -1.0
		if forward_px < 1.0 or lateral_px > max_lat_px:
			return -1.0
		var horiz_cos_f: float = forward_px / maxf(0.001, dist_px)
		if horiz_cos_f < 0.86:
			return -1.0
		return horiz_cos_f * 100.0 - lateral_px * 2.5 - dist_px * 0.6

	# Puertas, vecinos, mesas, carteles: deben estar delante de la cruz central y no mirando al suelo ni al techo
	if forward_px < 2.5 or lateral_px > max_lat_px:
		return -1.0
	var horiz_cos: float = forward_px / maxf(0.001, dist_px)
	if horiz_cos < 0.90:
		return -1.0

	if is_low_obj:
		if pitch > 0.22 or pitch < -0.65:
			return -1.0
	else:
		if pitch > 0.36 or pitch < -0.42:
			return -1.0

	return horiz_cos * 100.0 - lateral_px * 2.8 - dist_px * 0.5 - absf(pitch) * 12.0


## ¿El protagonista está buceando? (paso 3b)
func _buceando() -> bool:
	var mc = player.get_node_or_null("PlayerMovementController")
	return mc != null and mc.get("buceando") == true


## Piso de un objeto interactuable: el suyo si lo tiene (vecinos); los sitios fijos de la posada, según estén en la galería o
## en el salón; lo demás, el del protagonista (está donde estás tú).
func _nivel_de(a: Area2D, tgt: Node, nivel_prota: int) -> int:
	if "elevation_level" in tgt:
		return int(tgt.get("elevation_level"))
	var pos: Vector2 = Anclas.desmover(a.global_position)
	if a.has_meta("village_station") and VillageTavern.RECT.has_point(pos):
		return 1 if VillageTavern.is_upper_floor_target(pos) else 0
	return nivel_prota


## La opción que se usará al pulsar [E]: la que está bajo el ratón (o bajo la cruz central en 1.ª persona), o la elegida con la rueda.
func selected() -> Dictionary:
	# Un sitio que acaba de desaparecer (objeto recogido, pista cogida) puede seguir en la lista hasta el siguiente repaso
	candidates = candidates.filter(func(c): return is_instance_valid(c.get("area")) and is_instance_valid(c.get("target")))
	if candidates.is_empty():
		return {}
	if WorldStage3DScript.first_person_active:
		var pp: Vector2 = player.global_position
		if _index > 0 and _index < candidates.size():
			var c_idx: Dictionary = candidates[_index]
			if _fp_crosshair_score(c_idx.get("area") as Area2D, c_idx.get("target") as Node, c_idx.get("pos", pp), pp) >= 0.0:
				return c_idx
		var best_fp: Dictionary = {}
		var best_score: float = -1.0
		for c in candidates:
			var score: float = _fp_crosshair_score(c.get("area") as Area2D, c.get("target") as Node, c.get("pos", pp), pp)
			if score >= 0.0 and score > best_score:
				best_score = score
				best_fp = c
		return best_fp
	var mp: Vector2 = player.get_global_mouse_position()
	if player.global_position.distance_to(mp) <= MOUSE_REACH_PX:
		var best: Dictionary = {}
		var best_d: float = MOUSE_PICK_PX
		for c in candidates:
			var d: float = (c["pos"] as Vector2).distance_to(mp)
			if d < best_d:
				best_d = d
				best = c
		if not best.is_empty():
			return best
	return candidates[clampi(_index, 0, candidates.size() - 1)]


## Usa la opción elegida. Devuelve false si no había ninguna.
func use_selected() -> bool:
	var saved_idx: int = _index
	refresh()
	if saved_idx > 0 and saved_idx < candidates.size():
		_index = saved_idx
	var c: Dictionary = selected()
	if c.is_empty() or not is_instance_valid(c["target"]):
		return false
	var tgt: Node = c["target"]
	var area: Area2D = c["area"]
	var vm = player.get_tree().get_first_node_in_group("village_manager")
	if tgt == vm and area.has_meta("village_station"):
		_use_station(vm, area)
	else:
		tgt.call("interact", player)
	_refresh_t = 0.0
	return true


func _use_station(vm, area: Area2D) -> void:
	var tag: String = str(area.get_meta("village_station"))
	var ap: Vector2 = area.global_position
	match tag:
		"building_door":
			var d: Dictionary = vm._find_nearest_door(ap, 18.0)
			if not d.is_empty():
				vm._interact_building_door(player, d)
				return
		"building_window":
			var w: Dictionary = vm._find_nearest_window(ap, 16.0)
			if not w.is_empty():
				vm._interact_building_window(player, w)
				return
		"house_chest":
			for ch in vm.house_chests:
				if (ch["pos"] as Vector2).distance_to(ap) <= 4.0:
					vm._interact_house_chest(player, ch)
					return
		"shop_business_stall":
			var s: Dictionary = vm._find_nearest_business_stall(ap, 18.0)
			if not s.is_empty():
				vm.open_business_management_ui(int(s.get("role", -1)))
				return
	vm.interact(player)


func _resolve_target(a: Node) -> Node:
	var p: Node = a.get_parent()
	if p != null and p.has_method("interact") and ("npc_name" in p or "animal_name" in p or "pet_name" in p or "node_title" in p):
		return p
	if a.has_method("interact"):
		return a
	if p != null and p.has_method("interact"):
		return p
	if p != null and p.get_parent() != null and p.get_parent().has_method("interact"):
		return p.get_parent()
	return null


func _label_for(a: Node, tgt: Node) -> String:
	if a.has_meta("village_station"):
		var tag: String = str(a.get_meta("village_station"))
		var vm = player.get_tree().get_first_node_in_group("village_manager")
		if vm != null and vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode")) and tag in ["tavern_games", "tavern_pool"]:
			return ""
		if tag == "building_door":
			var d: Dictionary = vm._find_nearest_door((a as Node2D).global_position, 18.0) if vm != null else {}
			var opened: bool = bool(d.get("is_open", false))
			var locked: bool = bool(d.get("is_locked", false))
			var b_t: String = str(d.get("building_title", d.get("title", "")))
			var action_t: String = "Cerrar la puerta" if opened else ("Probar picaporte (cerrada con llave · [F] forzar)" if locked else "Abrir la puerta")
			return action_t + ((" · " + b_t) if b_t != "" else "")
		if tag == "building_window":
			var w: Dictionary = vm._find_nearest_window((a as Node2D).global_position, 16.0) if vm != null else {}
			var shut: bool = bool(w.get("is_shuttered", false))
			return "Postigo cerrado ([F] forzar)" if shut else "Colarse por la ventana"
		if tag == "shop_business_stall":
			var s: Dictionary = vm._find_nearest_business_stall((a as Node2D).global_position, 18.0) if vm != null else {}
			var s_title: String = str(s.get("title", "el negocio"))
			return "Gestionar %s ([F] sabotear)" % s_title
		return str(STATION_LABELS.get(tag, "Usar"))
	if tgt.has_method("get_interact_label"):
		return str(tgt.call("get_interact_label", player))
	if tgt is VillageNPC:
		var n: VillageNPC = tgt
		var disp_n: String = "Alguacil mayor Vane" if n.npc_name == "Comisario Vane" else n.npc_name
		if n.is_dead:
			return "Examinar el cuerpo de %s" % disp_n
		if n.is_downed or n.is_stunned_flag or n.sedated_timer > 0.0:
			return "Registrar a %s" % disp_n
		var vm_a = n._get_vm()
		if vm_a != null and not (vm_a.has_method("is_demo_mode") and bool(vm_a.call("is_demo_mode"))) and "VillageUnderworld" in vm_a and vm_a.VillageUnderworld != null:
			var caught_lbl: String = str(vm_a.VillageNightJobs.catch_label(vm_a, n, player))
			if caught_lbl != "":
				return caught_lbl # P6b: lo sorprendes de noche junto a un taller, una casa o una lápida
			var hooded: String = str(vm_a.VillageUnderworld.alley_interact_label(vm_a, n))
			if hooded != "":
				return hooded # P5b: de noche en el callejón, el perista es solo una figura encapuchada
		return "Hablar con %s" % disp_n
	if "animal_name" in tgt:
		return "Despiezar: %s" % str(tgt.get("animal_name"))
	if "pet_name" in tgt:
		return "%s (mascota)" % str(tgt.get("pet_name"))
	if "node_title" in tgt:
		return "Recoger: %s" % str(tgt.get("node_title"))
	if tgt.is_in_group("fishing_spots"):
		return "Pescar en el lago o llenar regadera"
	if "house_tier" in tgt or String(tgt.name) == "PlayerCampSite":
		return "Cocinar, descansar o gestionar campamento"
	if "fence_hp" in tgt or String(tgt.name) == "PlayerChickenCoop":
		return "Atender el gallinero"
	if "crop_stage" in tgt or String(tgt.name).begins_with("FarmPlot"):
		return "Cultivar parcela del huerto"
	return "Usar"


func _update_label() -> void:
	if _label == null:
		return
	var c: Dictionary = selected()
	if c.is_empty():
		_label.visible = false
		return
	var txt: String = "[E] " + str(c["label"])
	if candidates.size() > 1:
		txt += "   (%d/%d · rueda o G)" % [candidates.find(c) + 1, candidates.size()]
	_label.text = txt
	# Las acciones [E] nunca flotan sobre el mundo: se muestran únicamente en la tarjeta de papel inferior del HUD.
	_label.visible = false


func get_prompt_card_data() -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	if player.has_method("is_any_ui_modal_open") and bool(player.call("is_any_ui_modal_open")):
		return {}
	var c: Dictionary = selected()
	if c.is_empty() or not is_instance_valid(c.get("target")):
		return {}
	var tgt: Node = c["target"]
	var area: Area2D = c.get("area") as Area2D
	var sel_idx: int = maxi(0, candidates.find(c))
	var target_name: String = "Objetivo"
	var target_state: String = ""
	var actions: Array[Dictionary] = [
		{"key": "E", "text": str(c.get("label", "Usar")), "selected": true}
	]

	var vm = player.get_tree().get_first_node_in_group("village_manager")
	if tgt is VillageNPC:
		var n: VillageNPC = tgt as VillageNPC
		var fem_n: bool = n.has_method("is_female") and bool(n.call("is_female"))
		target_name = "Alguacil mayor Vane" if n.npc_name == "Comisario Vane" else n.npc_name
		if n.is_dead:
			target_state = ""
		elif n.has_method("get_short_world_state"):
			target_state = str(n.call("get_short_world_state"))
		else:
			target_state = ("Muerta" if fem_n else "Muerto") if n.is_dead else n.npc_role
		if n.is_downed:
			actions.append({"key": "·", "text": "Agonizando (%ds) · llevar al hospital" % maxi(1, int(ceil(n.bleedout_timer))), "selected": false})
		elif (n.sedated_timer > 0.0 or n.is_stunned_flag) and not n.corpse_pocket_looted and n.personal_gold > 0:
			actions.append({"key": "·", "text": "Registrar bolsillo (%d oro)" % maxi(0, n.personal_gold), "selected": false})
	elif "npc_name" in tgt:
		target_name = str(tgt.get("npc_name"))
		if tgt.has_method("get_short_world_state"):
			target_state = str(tgt.call("get_short_world_state"))
		elif "npc_role" in tgt:
			target_state = str(tgt.get("npc_role"))
		else:
			target_state = "Vecino"
		if tgt.is_in_group("armory_rack"):
			actions[0]["text"] = "Comprar o robar pistola, fusil y munición"
			actions.append({"key": "F", "text": "Robar arma o cartuchos del expositor", "selected": false})
	elif area != null and area.has_meta("village_station"):
		var tag: String = str(area.get_meta("village_station"))
		var ap: Vector2 = area.global_position
		match tag:
			"building_door":
				var d: Dictionary = vm._find_nearest_door(ap, 18.0) if vm != null else {}
				target_name = str(d.get("building_title", d.get("title", "Puerta")))
				if target_name == "":
					target_name = "Puerta"
				var opened: bool = bool(d.get("is_open", false))
				var locked: bool = bool(d.get("is_locked", false))
				target_state = "Abierta" if opened else ("Con llave" if locked else "Cerrada")
				actions[0]["text"] = "Cerrar la puerta" if opened else ("Probar picaporte" if locked else "Abrir la puerta")
				if locked and not opened:
					actions.append({"key": "F", "text": "Forzar cerradura", "selected": false})
			"building_window":
				var w: Dictionary = vm._find_nearest_window(ap, 16.0) if vm != null else {}
				target_name = "Ventana"
				var shut: bool = bool(w.get("is_shuttered", false))
				target_state = "Postigo cerrado" if shut else "Abierta"
				if shut:
					actions[0]["text"] = "Inspeccionar postigo"
					actions.append({"key": "F", "text": "Forzar postigo", "selected": false})
			"house_chest":
				target_name = "Cofre privado"
				target_state = "Cerrado"
			"shop_business_stall":
				var s: Dictionary = vm._find_nearest_business_stall(ap, 18.0) if vm != null else {}
				target_name = str(s.get("title", "Mostrador"))
				target_state = "Saboteado" if int(s.get("sabotaged_days", 0)) > 0 else "Negocio"
				actions[0]["text"] = "Gestionar %s" % target_name
				actions.append({"key": "F", "text": "Sabotear taller", "selected": false})
			"well":
				target_name = "Pozo"
				target_state = "Agua limpia"
			"tavern_games":
				target_name = "Mesa de póker"
				target_state = "Posada"
			"tavern_pool":
				target_name = "Mesa de billar"
				target_state = "Posada"
			"tavern_bed":
				target_name = "Cama de posada"
				target_state = "8 oro"
			"hospital_bed":
				target_name = "Cama de urgencias"
				target_state = "10 oro"
			"morgue_table":
				target_name = "Morgue forense"
				target_state = "Autopsias"
			"police_jail":
				target_name = "Comisaría"
				target_state = ("Multa %d oro" % int(vm.get("bounty_gold"))) if (vm != null and int(vm.get("bounty_gold")) > 0) else "Celda"
			"church_altar":
				target_name = "Altar del Alba"
				target_state = "Capilla"
			"cemetery_gate":
				target_name = "Cementerio"
				target_state = "Registro"
			"notice_board":
				target_name = "Tablón de encargos"
				target_state = "Plaza Central"
				var d_nb: int = int(WorldClock.current_day) if WorldClock else 1
				var done_d: Dictionary = vm.get("completed_contracts_today") if (vm != null and "completed_contracts_today" in vm) else {}
				var s1: String = "✓ Hecho" if int(done_d.get(1, -1)) == d_nb else "28 oro"
				var s2: String = "✓ Hecho" if int(done_d.get(2, -1)) == d_nb else "26 oro"
				var s3: String = "✓ Hecho" if int(done_d.get(3, -1)) == d_nb else "34 oro"
				actions = [
					{"key": "E", "text": "Abrir tablón de encargos y noticias", "selected": true},
					{"key": "1", "text": "Gremios: 2 Maderas o 1 Hierro (%s)" % s1, "selected": false},
					{"key": "2", "text": "Hospital: 2 Hierbas o 1 Cataplasma (%s) · Alguacil: Chatarra (%s)" % [s2, s3], "selected": false},
				]
			"library_reading":
				target_name = "Mesa de lectura"
				target_state = "Biblioteca"
			"compost":
				target_name = "Compostador"
				target_state = "Huerto"
			"case1_clearing":
				target_name = "Orilla del arroyo"
				target_state = ""
			"mill_hayloft":
				target_name = "Pajar"
				target_state = ""
			"mill_hearth":
				target_name = "Hogar de piedra"
				target_state = ""
			"mill_hemp_cord":
				target_name = "Rollo de cordel"
				target_state = ""
			"mill_table_paper":
				target_name = "Papel sobre la mesa"
				target_state = ""
			"mill_cellar_grate":
				target_name = "Reja de hierro"
				target_state = ""
			"mill_red_clay":
				target_name = "Orilla de arcilla"
				target_state = ""
			"police_archived_report":
				target_name = "Carpeta de archivo"
				target_state = ""
			"library_book_lever":
				target_name = "Estantería"
				target_state = ""
			"library_secret_ledger":
				target_name = "Cuaderno"
				target_state = ""
			"library_torn_book":
				target_name = "Libro antiguo"
				target_state = ""
			"old_bridge_left_shoe":
				target_name = "Zapato"
				target_state = ""
			"case1_forced_cabinet":
				target_name = "Gabinete"
				target_state = ""
			"case1_relative_page":
				target_name = "Hoja suelta"
				target_state = ""
			"case1_report_desk":
				target_name = "Bandeja de informes"
				target_state = ""
			_:
				target_name = str(STATION_LABELS.get(tag, "Puesto"))
				target_state = "Aldea"
	elif "animal_name" in tgt:
		target_name = str(tgt.get("animal_name"))
		target_state = "Caza"
	elif "pet_name" in tgt:
		target_name = str(tgt.get("pet_name"))
		target_state = "Mascota"
	elif "node_title" in tgt:
		target_name = str(tgt.get("node_title"))
		target_state = "Recurso"
	elif tgt.is_in_group("fishing_spots"):
		target_name = "Muelle del Lago del Oeste"
		target_state = "Pesca y agua"
	elif "house_tier" in tgt or String(tgt.name) == "PlayerCampSite":
		target_name = "Campamento"
		target_state = "Hoguera y descanso"
	elif "fence_hp" in tgt or String(tgt.name) == "PlayerChickenCoop":
		target_name = "Gallinero"
		target_state = "Corral"
	elif "crop_stage" in tgt or String(tgt.name).begins_with("FarmPlot"):
		target_name = "Parcela de cultivo"
		target_state = "Huerto"
	else:
		var raw_l: String = str(c.get("label", "Objeto"))
		target_name = raw_l.split(":")[0] if raw_l.find(":") != -1 else raw_l
		target_state = "Interacción"

	if candidates.size() > 1:
		var max_extra: int = maxi(0, 3 - actions.size())
		for offset in range(1, candidates.size()):
			if max_extra <= 0:
				break
			var next_c: Dictionary = candidates[(sel_idx + offset) % candidates.size()]
			var next_txt: String = str(next_c.get("label", ""))
			if next_txt != "" and next_txt != str(c.get("label", "")):
				actions.append({"key": "·", "text": next_txt, "selected": false})
				max_extra -= 1

	return {
		"target_name": target_name,
		"target_state": target_state,
		"cycle_text": ("%d/%d · Mayús+rueda o G" % [sel_idx + 1, candidates.size()]) if candidates.size() > 1 else "",
		"actions": actions,
		"footer": "Rueda o G: cambiar acción o vecino cercano" if (candidates.size() > 1 or actions.size() > 1) else ""
	}
