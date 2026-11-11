extends RefCounted

## Caso I en el mundo (Claude Code, 2026-11-09): reparte los papeles del caso entre vecinos reales, conecta los diálogos
## del caso (boticario, criada, familiar), coloca el gabinete forzado de la mansión, la página arrancada en casa del
## familiar y los dos secuestradores forasteros escondidos en el molino (el tercero es un vecino con doble vida).
## Todo se guarda en town_state["forensics"]["case1"] y `sync()` es idempotente (se llama cada hora y tras cargar).

const VillageForensics = preload("res://scripts/systems/VillageForensics.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const MillKidnapperScript = preload("res://scripts/enemies/MillKidnapper.gd")

const CASE_ID: String = "case_01_forest_woman"
const MANSION_LOT: String = "f1"
## Días que los forasteros esperan órdenes en el molino antes de irse (decidido por el usuario: «unos días»).
const KIDNAPPERS_LEAVE_AFTER_DAYS: int = 3
## Los dos forasteros del molino. El tercero (lana azul) es un vecino: papel «kidnapper_blue_wool».
const MILL_KIDNAPPERS: Dictionary = {
	"young": {"label": "Muchacho de capa parda", "pos": Vector2(206.0, -1078.0)},
	"driver": {"label": "Carretero forastero", "pos": Vector2(176.0, -1084.0)},
}
## Bandeja de informes en la comisaría: junto a la entrada, a la izquierda del armero y frente al sitio del alguacil
## (el rincón noreste quedaba encerrado por el armero y la mesa).
const REPORT_POS: Vector2 = Vector2(946.0, 111.0)
const ReportDeskScript = preload("res://scripts/systems/Case1ReportDesk.gd")
## Pruebas que se pueden adjuntar al informe (clave del cuaderno → nombre corto).
const REPORT_EVIDENCE: Dictionary = {
	"clue_case1_clearing": "El cuerpo junto al arroyo",
	"m_sangre": "Análisis de sangre",
	"m_estomago": "Contenido del estómago",
	"clue_case1_alchemist_analyze_flask": "El boticario sobre el frasco",
	"clue_case1_noble_maid_recognize_vial": "La criada reconoce el frasco",
	"clue_case1_forced_cabinet": "Gabinete forzado en la mansión",
	"clue_case1_relative_page": "Hoja arrancada con dosis corregidas",
	"clue_old_bridge_left_shoe": "Zapato en el puente viejo",
	"clue_police_archived_report": "Denuncia archivada",
	"clue_library_torn_book": "Libro arrancado de la biblioteca",
	"clue_library_secret_ledger": "Registro de la sala oculta",
	"clue_mill_hemp_cord": "Cordel del molino",
	"clue_mill_red_clay": "Barro rojo del molino",
	"clue_mill_cellar_grate": "Reja del sótano del molino",
	"clue_mill_hayloft": "Pajar del molino",
	"clue_mill_hearth": "Hogar del molino",
	"clue_mill_table_paper": "Papel en la mesa del molino",
	"clue_case1_blue_wool": "Jubón azul rasgado",
}
const BLUE_WOOL_LINE: String = "(Te fijas en su ropa: el jubón de lana azul oscuro tiene una manga rasgada y lleva arañazos recientes en el dorso de la mano.)"


static func state(vm) -> Dictionary:
	var fs: Dictionary = VillageForensics.state(vm)
	if not fs.has("case1") or not (fs["case1"] is Dictionary):
		fs["case1"] = {}
	var st: Dictionary = fs["case1"]
	if not st.has("roles") or not (st["roles"] is Dictionary):
		st["roles"] = {}
	if not st.has("kidnappers") or not (st["kidnappers"] is Dictionary):
		st["kidnappers"] = {}
	for k in MILL_KIDNAPPERS.keys():
		if not (st["kidnappers"] as Dictionary).has(k):
			st["kidnappers"][k] = "alive"
	return st


static func roles(vm) -> Dictionary:
	return state(vm)["roles"]


static func role_of(vm, npc_name: String) -> String:
	var r: Dictionary = roles(vm)
	for role_id in r.keys():
		if str(r[role_id]) == npc_name:
			return str(role_id)
	return ""


static func _today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1


## Un día de margen (decisión del usuario, 2026-11-11): el día 1 llegas y conoces el pueblo; el caso estalla el día 2.
const DIA_DE_MARGEN: int = 1
const AVISO_AMANECER: String = "🔔 Al amanecer, un pastor ha encontrado a una mujer muerta junto al arroyo, al norte del pueblo. El alguacil Vane te espera allí."

static func empezado() -> bool:
	return _today() >= 1 + DIA_DE_MARGEN


## El cuerpo del claro existe desde el principio (así se guarda y carga como un vecino más), pero hasta que empieza el
## caso está escondido: ni se ve, ni se examina, ni lo descubre nadie.
static func mostrar_cuerpo(vm, visible: bool) -> void:
	var cuerpo = vm.entities_root.get_node_or_null("NPC_Case1_Victim")
	if cuerpo == null:
		return
	cuerpo.visible = visible
	cuerpo.corpse_on_ground = visible
	cuerpo._set_area_col_disabled(cuerpo.interact_area, not visible)


static func _avisar_inicio(vm, st: Dictionary) -> void:
	if st.get("aviso_dado") == true:
		return
	st["aviso_dado"] = true
	var jugador = vm.get_tree().get_first_node_in_group("player")
	if jugador != null and jugador.has_method("show_hint"):
		jugador.call("show_hint", AVISO_AMANECER)
	vm._msg_player(jugador, "🔔 Han encontrado un cuerpo junto al arroyo del norte", Color(0.95, 0.80, 0.55))


# ---------------------------------------------------------------- reparto de papeles
static func _assign_roles(vm) -> void:
	var st: Dictionary = state(vm)
	if not (st["roles"] as Dictionary).is_empty():
		return
	var npcs: Array = vm.get_tree().get_nodes_in_group("village_npcs") if vm.is_inside_tree() else []
	if npcs.size() < 6:
		return # el pueblo aún no está poblado: se reintenta en la próxima hora
	var r: Dictionary = DetectiveCaseData.assign_case_roles(CASE_ID, vm)
	r.erase("victim") # la víctima es Clara, el cuerpo guionizado del claro
	r.erase("young_kidnapper") # forastero: está en el molino, no es un vecino
	var used: Dictionary = {}
	for k in r.keys():
		used[str(r[k])] = true
	# La criada, de la misma casa que el señor si la hay
	var head_name: String = str(r.get("noble_head", ""))
	var head = _npc_by_name(vm, head_name)
	if head != null:
		for n in npcs:
			if _usable(n, used) and str(n.get("family_name")) == str(head.get("family_name")) and _gender(n) == "F":
				used.erase(str(r.get("noble_maid", "")))
				r["noble_maid"] = str(n.get("npc_name"))
				used[str(n.get("npc_name"))] = true
				break
	# El tercer secuestrador: un vecino adulto con doble vida (no guardia, cura, médico ni alguacil)
	var best := ""
	for n in npcs:
		if not _usable(n, used):
			continue
		if int(n.get("trade_role")) in [11, 12, 13, 14, 21, 22]:
			continue
		var prof = n.get("person_profile")
		var age: int = int(prof.get("age")) if prof != null else 30
		if _gender(n) == "M" and age >= 20 and age <= 45:
			best = str(n.get("npc_name"))
			break
	if best != "":
		r["kidnapper_blue_wool"] = best
	st["roles"] = r
	st["start_day"] = _today()


static func _usable(n, used: Dictionary) -> bool:
	return is_instance_valid(n) and n.get("is_dead") != true and not used.has(str(n.get("npc_name")))


static func _gender(n) -> String:
	var prof = n.get("person_profile")
	return str(prof.get("gender")) if prof != null else "M"


static func _npc_by_name(vm, npc_name: String):
	if npc_name == "" or not vm.is_inside_tree():
		return null
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if is_instance_valid(n) and str(n.get("npc_name")) == npc_name:
			return n
	return null


# ---------------------------------------------------------------- lugares
## Página arrancada: junto a la cama del familiar (su casa).
static func relative_page_pos(vm) -> Vector2:
	var rel = _npc_by_name(vm, str(roles(vm).get("apparent_culprit_relative", "")))
	if rel == null:
		return Vector2.INF
	var bed: Vector2 = rel.get("bed_position")
	if bed == Vector2.ZERO:
		return Vector2.INF
	return bed + Vector2(0.0, 24.0) # a los pies de la cama, en el suelo (no encima)


## Gabinete de los señores: en el rincón del estudio de la mansión.
static func cabinet_pos() -> Vector2:
	return VillageLots.building_center(MANSION_LOT) + Vector2(-70.0, -40.0)


# ---------------------------------------------------------------- sincronía con el mundo
static func sync(vm) -> void:
	if vm == null or not vm.is_inside_tree():
		return
	if not empezado():
		mostrar_cuerpo(vm, false)
		return
	_assign_roles(vm)
	var st: Dictionary = state(vm)
	if (st["roles"] as Dictionary).is_empty():
		return
	mostrar_cuerpo(vm, true)
	if int(WorldClock.current_hour) >= 6: # el aviso llega al amanecer, no a medianoche mientras duermes
		_avisar_inicio(vm, st)
	# Áreas de [E] (se crean una vez por sesión)
	if vm.get_node_or_null("Case1CabinetArea") == null:
		vm._add_station_area("Case1CabinetArea", cabinet_pos(), 20.0, "case1_forced_cabinet")
		vm._add_prop_collider(cabinet_pos(), Vector2(15.0, 8.5))
		vm.register_no_stand_furniture(cabinet_pos(), Vector2(16.0, 9.0))
	var page_pos: Vector2 = relative_page_pos(vm)
	if page_pos != Vector2.INF and vm.get_node_or_null("Case1RelativePageArea") == null:
		vm._add_station_area("Case1RelativePageArea", load("res://mapa/anclas.gd").desmover(page_pos), 18.0, "case1_relative_page") # page_pos ya es del mundo; la zona se crea desde el mapa original
		st["page_pos"] = [page_pos.x, page_pos.y]
	if vm.get_node_or_null("Case1ReportArea") == null:
		vm._add_station_area("Case1ReportArea", REPORT_POS, 20.0, "case1_report_desk")
		vm._add_prop_collider(REPORT_POS, Vector2(7.0, 5.0))
		vm.register_no_stand_furniture(REPORT_POS, Vector2(7.0, 5.0))
	# Los forasteros se van si el jugador tarda demasiado
	var start_day: int = int(st.get("start_day", _today()))
	for k in MILL_KIDNAPPERS.keys():
		if str(st["kidnappers"][k]) == "alive" and _today() >= start_day + KIDNAPPERS_LEAVE_AFTER_DAYS:
			st["kidnappers"][k] = "left"
	_sync_kidnappers(vm, st)
	if is_instance_valid(vm.world_stage_3d) and vm.world_stage_3d.has_method("sync_case1_props_3d"):
		vm.world_stage_3d.sync_case1_props_3d()


static func _sync_kidnappers(vm, st: Dictionary) -> void:
	for k in MILL_KIDNAPPERS.keys():
		var node_name: String = "Case1Kidnapper_" + str(k)
		var existing = vm.entities_root.get_node_or_null(node_name)
		var alive: bool = str(st["kidnappers"][k]) == "alive"
		if not alive:
			if existing != null and existing.get("is_dead") != true:
				existing.queue_free()
			continue
		if existing != null:
			continue
		var kd = MillKidnapperScript.new()
		vm.entities_root.add_child(kd)
		kd.setup_kidnapper(str(k), str(MILL_KIDNAPPERS[k]["label"]), load("res://mapa/anclas.gd").mover(MILL_KIDNAPPERS[k]["pos"])) # siguen al molino (mapa ×E)
		kd.name = node_name
		kd.gone.connect(func(_r, outcome: String): _on_kidnapper_gone(vm, str(k), outcome))


static func _on_kidnapper_gone(vm, k: String, outcome: String) -> void:
	var st: Dictionary = state(vm)
	if str(st["kidnappers"].get(k, "")) != "alive":
		return
	st["kidnappers"][k] = "killed" if outcome == "killed" else "fled"


# ---------------------------------------------------------------- pistas con [E]
static func try_interact(vm, player: Node2D, pos: Vector2, sel_kind: String) -> bool:
	var st: Dictionary = state(vm)
	var o: Vector2 = load("res://mapa/anclas.gd").desmover(pos) # la bandeja y el gabinete están escritos en el mapa original (mapa ×E)
	if sel_kind == "case1_report_desk" or (sel_kind == "" and o.distance_squared_to(REPORT_POS) <= 14.0 * 14.0):
		open_report(vm)
		return true
	if sel_kind == "case1_forced_cabinet" or (sel_kind == "" and o.distance_squared_to(cabinet_pos()) <= 16.0 * 16.0):
		vm._record_case_clue(
			player,
			"🗄️ Gabinete",
			"🗄️ Un gabinete de nogal con la cerradura de latón arañada: la placa está doblada hacia fuera y hay virutas de madera en el suelo. Dentro, en el estante de terciopelo, queda la huella limpia de un frasco pequeño; el polvo de alrededor no está tocado.",
			"Mansión: gabinete de los señores con la cerradura forzada desde fuera y el hueco de un frasco pequeño en el terciopelo.",
			"Pista: Gabinete forzado",
			"clue_case1_forced_cabinet",
			Color(0.90, 0.80, 0.62)
		)
		return true
	var pp = st.get("page_pos", null)
	var page_pos: Vector2 = Vector2(float(pp[0]), float(pp[1])) if pp is Array and (pp as Array).size() >= 2 else Vector2.INF
	if sel_kind == "case1_relative_page" or (sel_kind == "" and page_pos != Vector2.INF and pos.distance_squared_to(page_pos) <= 14.0 * 14.0):
		vm._record_case_clue(
			player,
			"📃 Hoja suelta",
			"📃 Una hoja de papel viejo, arrancada de un libro: el borde rasgado es irregular. Habla de la belladama gris y de «un sueño que imita la muerte». Al margen hay cantidades tachadas y vueltas a escribir con otra tinta, de puño y letra reciente.",
			"Casa del familiar: hoja arrancada de un libro antiguo sobre la belladama gris, con dosis tachadas y corregidas a mano.",
			"Pista: Hoja arrancada",
			"clue_case1_relative_page",
			Color(0.96, 0.90, 0.74)
		)
		return true
	return false


# ---------------------------------------------------------------- diálogos del caso
static func _detective_ui(vm):
	var ui_root = vm.get_tree().get_first_node_in_group("game_ui")
	if ui_root and "detective_ui" in ui_root and is_instance_valid(ui_root.detective_ui):
		return ui_root.detective_ui
	return null


static func _has_progress(vm, key: String) -> bool:
	var dui = _detective_ui(vm)
	return dui != null and dui.has_method("has_case_progress") and bool(dui.has_case_progress(key))


static func add_dialogue(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null:
		return
	var role_id: String = role_of(vm, str(npc.npc_name))
	if role_id == "":
		return
	var back := {"label": "⬅️ Volver", "next": "start"}
	if role_id == "kidnapper_blue_wool":
		diag["start"]["text"] = str(diag["start"].get("text", "")) + "\n" + BLUE_WOOL_LINE
		diag["case1_blue_wool"] = {"text": BLUE_WOOL_LINE, "choices": [back]}
		ch_arr.insert(0, {"label": "🔎 Fijarte en su ropa", "next": "case1_blue_wool", "action": "case1:blue_wool"})
		return
	var dialogues: Dictionary = DetectiveCaseData.get_case_def(CASE_ID).get("custom_dialogues", {})
	for d_id in dialogues.keys():
		var d: Dictionary = dialogues[d_id]
		if str(d.get("speaker_role", "")) != role_id or d.get("requires_live_capture") == true:
			continue
		var needs: Array = d.get("requires_notes", [d.get("requires_note", "")])
		var ok := true
		for key in needs:
			if str(key) != "" and not _has_progress(vm, str(key)):
				ok = false
		if not ok:
			continue
		var node_id: String = "case1_" + str(d_id)
		diag[node_id] = {"text": str(d.get("line", "")), "choices": [back]}
		ch_arr.insert(0, {"label": str(d.get("ask_label", "🔎 Preguntar por el caso")), "next": node_id, "action": "case1:" + str(d_id)})


static func on_action(vm, npc, action_id: String) -> void:
	var player = vm.get_tree().get_first_node_in_group("player")
	var what: String = action_id.trim_prefix("case1:")
	if what == "blue_wool":
		vm._record_case_clue(player, "👕 " + str(npc.npc_name),
			"Te fijas en el jubón de lana azul oscuro de %s: una manga rasgada y arañazos recientes en la mano." % npc.npc_name,
			"%s: jubón de lana azul oscuro con una manga rasgada y arañazos recientes en el dorso de la mano." % npc.npc_name,
			"Pista: Lana azul", "clue_case1_blue_wool", Color(0.70, 0.80, 0.98))
		return
	var d: Dictionary = DetectiveCaseData.get_case_def(CASE_ID).get("custom_dialogues", {}).get(what, {})
	if d.is_empty():
		return
	vm._record_case_clue(player, "🗣️ " + str(npc.npc_name), str(d.get("line", "")),
		"%s: %s" % [npc.npc_name, str(d.get("line", ""))], "Testimonio: " + str(npc.npc_name),
		"clue_case1_" + what, Color(0.95, 0.88, 0.68))


# ---------------------------------------------------------------- informe del caso (comisaría)
## A quién se puede culpar. El final lo decide esto (PLAN_BETA_MISTERIO §5b): familiar = malo, grupo de
## secuestradores = bueno, el muchacho de capa parda en concreto = perfecto. Culpar a otro inocente = como el malo.
static func report_options(vm) -> Array:
	var r: Dictionary = roles(vm)
	var out: Array = []
	if str(r.get("apparent_culprit_relative", "")) != "":
		out.append({"id": "relative", "label": "El familiar de la víctima: %s" % r["apparent_culprit_relative"], "name": str(r["apparent_culprit_relative"]), "verdict": "bad"})
	out.append({"id": "kidnappers", "label": "Los secuestradores: los dos forasteros del molino y su cómplice del pueblo", "name": "los secuestradores del molino", "verdict": "good"})
	out.append({"id": "young", "label": "El muchacho de capa parda, en concreto", "name": "el muchacho de capa parda", "verdict": "perfect"})
	if str(r.get("alchemist", "")) != "":
		out.append({"id": "alchemist", "label": "El boticario: %s" % r["alchemist"], "name": str(r["alchemist"]), "verdict": "innocent"})
	if str(r.get("noble_maid", "")) != "":
		out.append({"id": "noble_maid", "label": "La criada de la mansión: %s" % r["noble_maid"], "name": str(r["noble_maid"]), "verdict": "innocent"})
	return out


static func report_evidence(vm) -> Array:
	var out: Array = []
	for key in REPORT_EVIDENCE.keys():
		if _has_progress(vm, str(key)):
			out.append(str(key))
	return out


static func _dialogue_manager(vm):
	var tree = vm.get_tree()
	var dm = tree.current_scene.get_node_or_null("Systems/dialogue_manager") if tree.current_scene else null
	if dm == null:
		dm = tree.root.find_child("dialogue_manager", true, false)
	return dm


static func _report_desk(vm):
	var desk = vm.get_node_or_null("Case1ReportDesk")
	if desk == null:
		desk = ReportDeskScript.new()
		desk.name = "Case1ReportDesk"
		vm.add_child(desk)
	desk.vm = vm
	return desk


static func build_report_graph(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	var close := {"label": "Dejarlo para más tarde", "next": "END"}
	if st.get("report") is Dictionary:
		var rep: Dictionary = st["report"]
		return {"start": {"text": "📜 Ya dejaste tu informe en la bandeja el día %d. Culpaste a %s.\nEl alguacil mayor Vane lo tiene sobre su mesa." % [int(rep.get("day", 0)), str(rep.get("name", "?"))], "choices": [{"label": "Cerrar", "next": "END"}]}}
	var ev: Array = report_evidence(vm)
	var ev_lines: Array = []
	for key in ev:
		ev_lines.append(str(REPORT_EVIDENCE[key]))
	# En un solo párrafo: la ventana de diálogo muestra unas 6 líneas
	var ev_txt: String = " · ".join(ev_lines) if not ev_lines.is_empty() else "(Tu cuaderno no tiene aún nada que adjuntar.)"
	var graph := {"start": {
		"text": "📜 INFORME DEL CASO I — La mujer del bosque\nPruebas que adjuntas (%d):\n%s\n\n¿A quién señalas como culpable? Una vez firmado, no se puede cambiar." % [ev.size(), ev_txt],
		"choices": []}}
	for opt in report_options(vm):
		var oid: String = str(opt["id"])
		graph["start"]["choices"].append({"label": str(opt["label"]), "next": "confirm_" + oid})
		graph["confirm_" + oid] = {
			"text": "Vas a firmar el informe culpando a %s.\n¿Lo dejas en la bandeja del alguacil mayor?" % str(opt["name"]),
			"choices": [
				{"label": "✒️ Firmar y dejarlo en la bandeja", "next": "signed_" + oid, "action": "case1_report:" + oid},
				{"label": "⬅️ Pensarlo otra vez", "next": "start"},
			]}
		graph["signed_" + oid] = {"text": _vane_reply(str(opt["verdict"])), "choices": [{"label": "Cerrar", "next": "END"}]}
	graph["start"]["choices"].append(close)
	return graph


## Respuesta del alguacil al recoger el informe. Provisional: el autor puede reescribirla.
static func _vane_reply(verdict: String) -> String:
	match verdict:
		"good":
			return "Dejas el informe en la bandeja. El alguacil mayor Vane lo lee de pie y frunce el ceño.\n«Forasteros escondidos en el molino… y uno de los nuestros ayudándoles. Mandaré a mis hombres al alba.»"
		"perfect":
			return "Dejas el informe en la bandeja. El alguacil mayor Vane se detiene en una línea y da unos golpecitos con el dedo.\n«El muchacho de la capa parda. Si lo tenemos a él, tiraremos del resto.»"
	return "Dejas el informe en la bandeja. El alguacil mayor Vane lo lee despacio y asiente.\n«Con esto basta. Esta misma tarde lo traemos a la celda.»"


static func open_report(vm) -> void:
	var dm = _dialogue_manager(vm)
	if dm == null or not dm.has_method("start_dialogue"):
		return
	if dm.has_method("is_active") and bool(dm.call("is_active")):
		return
	dm.call("start_dialogue", build_report_graph(vm), "start", _report_desk(vm))


## Firma el informe. El final de la demo (detención, fiesta, tumba) se conecta en la parte 5 del plan.
static func submit_report(vm, option_id: String) -> bool:
	var st: Dictionary = state(vm)
	if st.get("report") is Dictionary:
		return false
	for opt in report_options(vm):
		if str(opt["id"]) != option_id:
			continue
		st["report"] = {"culprit": option_id, "name": str(opt["name"]), "verdict": str(opt["verdict"]), "day": _today(), "evidence": report_evidence(vm)}
		if vm.has_method("_hint_player"):
			vm._hint_player("📜 Informe del Caso I entregado: culpas a %s." % str(opt["name"]))
		return true
	return false


static func on_report_action(vm, action_id: String) -> void:
	if vm == null or not action_id.begins_with("case1_report:"):
		return
	submit_report(vm, action_id.trim_prefix("case1_report:"))
