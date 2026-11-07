@tool
extends RefCounted

## V5e: biblioteca, escuela, mercado semanal y arreglos del Taller de Reparaciones.
## - Biblioteca (solar n5): un sitio de ocio bajo techo (VillagePlaces). Va más quien es curioso; con lluvia es casi
##   el único sitio al que la gente sale. Cada visita suma lecturas al pueblo (para la escuela y la secta, más
##   adelante). El jugador puede leer un rato una vez al día y aprende algo de un oficio.
## - Escuela (solar e3): el edificio está, pero no hay alumnos hasta que haya niños (V9).
## - Mercado (miércoles, 8–13 h): las tiendas con género de sobra montan un puesto en la plaza; los vecinos libres
##   se acercan a comprar algo y a charlar. Si nadie tiene de sobra, no hay mercado.
## - Taller de Reparaciones (solar e5, oficio TINKER): cada día, si un negocio sigue saboteado y su dueño puede
##   pagar, el arreglador gasta un kit y le quita un día de avería.
## Estado en `vm.culture_state` (se guarda). Nombres provisionales (docs/APORTES_CREATIVOS.md).

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageTrades = preload("res://scripts/systems/VillageTrades.gd")
const VillageFame = preload("res://scripts/systems/VillageFame.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const LIBRARY_LOT: String = "n5"
const SCHOOL_LOT: String = "e3"
const LIBRARY_TITLE: String = "📚 Biblioteca"
const SCHOOL_TITLE: String = "🏫 Escuela"
const READ_SKILLS: Array = ["cooking", "alchemy", "medicine", "animals", "crafting"]
const READ_XP: int = 12
const MARKET_WEEKDAY: int = 2 # Miércoles
const MARKET_OPEN: int = 8
const MARKET_CLOSE: int = 13
const MARKET_MIN_STOCK: int = 8 # Solo monta puesto quien tiene género de sobra
const MARKET_SPOTS: Array = [Vector2(422, 26), Vector2(508, 26), Vector2(522, 52), Vector2(488, 46)]
const MARKET_VISIT_CHANCE: float = 0.25
const REPAIR_PRICE: int = 8
const REPAIRS_PER_DAY: int = 2
const GRID_REPAIR_REWARD: int = 12
const SAPLING_COST: int = 6
const MAX_PLANTED_TREES: int = 12 # Tope de pinos sembrados por el jugador
const MILITIA_MAX_BONUS: int = 4
## Incursiones con motivo (nada de calendario): los bandidos se fijan en un pueblo rico y con rutas que corren la voz.
## En pausa (orden del usuario, 2026-11-06: «poco realista»; prefiere crimen de robos y mafias dentro del pueblo).
## Apagado, la amenaza no sube y no hay avisos ni asaltos nuevos; todo el código sigue ahí por si cambia de opinión.
const RAIDS_ENABLED: bool = false
const RAID_RICH_TREASURY: int = 300 # Por encima de esto, las arcas llenas atraen a los bandidos
const RAID_THREAT_WARN: int = 40 # A partir de aquí hay probabilidad diaria de que se decidan a atacar
const RAID_GATHER_HOUR: int = 16 # Los defensores acuden a la entrada del pueblo
const RAID_ATTACK_HOUR: int = 18 # El asalto llega al atardecer
const RAID_GATE_POS: Vector2 = Vector2(1400, 50) # Camino del este, por donde llegan
const RAID_MAX_VOLUNTEERS: int = 3 # Las barricadas pagadas no pasan de +4 por incursión
const ROUTE_CHARTER_COST: int = 25
## Arancel que cada pueblo de fuera paga a las arcas por cada intercambio de su ruta (oro que entra al valle).
const ROUTE_TOWN_TARIFF: int = 4
## Los pueblos de fuera reponen su fondo de comercio cada lunes (ganan dinero vendiendo en otros sitios), hasta este tope.
const ROUTE_WEEKLY_REFILL: int = 20
const ROUTE_BALANCE_CAP: int = 90
const CARAVAN_PLAZA_POS: Vector2 = Vector2(465, 48)
const ROUTE_WEEKDAYS: Dictionary = {
	"high_pass": 0, # Lunes
	"river_port": 1, # Martes
	"sun_plain": 3, # Jueves
}
const ROUTE_CARAVAN_NAMES: Dictionary = {
	"high_pass": "Caravanero de Paso Alto",
	"river_port": "Caravanero de Puerto Fluvial",
	"sun_plain": "Caravanero de Vega del Sol",
}
const AnimalModel3DScript = preload("res://scripts/visuals/AnimalModel3D.gd")
## Lo que paga cada vendedor a las arcas por montar puesto en el mercado del miércoles.
const MARKET_STALL_FEE: int = 4
const MILITIA_COST: int = 15
const EXPEDITION_COST: int = 12
const HORSE_COST: int = 45
const CART_COST: int = 55
const FIREARM_COST: int = 60
const POWDER_PACK_COST: int = 14
const OUTPOST_CHARTER_COST: int = 90
const OUTPOST_SETTLER_BONUS: int = 15
const OUTPOST_UPGRADE_COST: int = 35
const OUTPOST_CENTER: Vector2 = Vector2(1615, 50)
const OUTPOST_GATE_POS: Vector2 = Vector2(1542, 50)
const OUTPOST_WORK_SPOTS: Array = [Vector2(1585, -8), Vector2(1585, 106), Vector2(1642, 48)]
const OUTPOST_UPGRADES: Dictionary = {
	"sawmill": "Aserradero Fronterizo (+1 madera/día y peaje)",
	"granary": "Granero del Paso (+1 trigo/día y raciones)",
	"watchtower": "Atalaya de Guardia (+2 defensa del asentamiento)",
}
const MAIN_STORY_CHAPTERS: Array[Dictionary] = [
	{
		"id": "main_ch1",
		"title": "I. Las Raíces del Valle",
		"description": "Llegaste como forastero a un valle aislado donde conviven arados de madera y farolas de cobre. Gánate un lugar levantando tu propia casa en un solar o alcanzando buena fama entre los vecinos.",
		"reward_gold": 20,
	},
	{
		"id": "main_ch2",
		"title": "II. El Pulso Bajo la Piedra",
		"description": "Bajo el empedrado de la plaza y en las ruinas del exterior descansan bobinas y conductos que nadie recuerda haber tendido. Completa una expedición a las ruinas o explora las alcantarillas del nivel -1.",
		"reward_gold": 25,
	},
	{
		"id": "main_ch3",
		"title": "III. La Máquina de Cobre",
		"description": "Los tomos de la biblioteca y el taller del ingeniero esconden el diseño del generador que alimenta el valle. Desbloquea una tecnología en el árbol de investigación o accede a la terminal lógica electromecánica.",
		"reward_gold": 30,
	},
	{
		"id": "main_ch4",
		"title": "IV. La Placa de Petri",
		"description": "Ahora sabes que el valle fue concebido como un experimento cerrado («La Placa de Petri»). Decide su futuro: funda un asentamiento libre en el paso, alcanza la Alcaldía o encabeza la defensa del pueblo ante una incursión.",
		"reward_gold": 40,
	},
]
const EXPLORATION_SITES: Dictionary = {
	"west_ruins": {"name": "Ruinas de Cobre del Oeste", "item": "copper_coil", "max_stages": 2},
	"north_caves": {"name": "Grutas de Cristal del Norte", "item": "iron_ore", "max_stages": 2},
	"sunken_watchtower": {"name": "Atalaya Hundida del Pantano", "item": "herbs", "max_stages": 2},
}
const TECH_TREE: Dictionary = {
	"waterwheel_gears": {
		"name": "Engranajes Hidráulicos", "cost_gold": 25, "req_points": 3, "prereq": "",
		"desc": "+1 pan diario en panadería y mejor molienda",
	},
	"reinforced_locks": {
		"name": "Cerraduras y Empalizadas de Precisión", "cost_gold": 30, "req_points": 4, "prereq": "waterwheel_gears",
		"desc": "+2 de defensa permanente contra incursiones al pueblo",
	},
	"voltaic_capacitors": {
		"name": "Condensadores Voltaicos", "cost_gold": 35, "req_points": 5, "prereq": "waterwheel_gears",
		"desc": "+1 kit de reparación diario en el taller del ingeniero",
	},
}

static func state(vm) -> Dictionary:
	if not vm.culture_state is Dictionary:
		vm.culture_state = {}
	var defs: Dictionary = {"readings": 0, "player_read_day": -1, "market_day": -1, "market_sellers": {}, "market_sales": 0,
		"markets_held": 0, "repairs": 0, "grid": {}, "forest": {}, "trade_routes": {}, "research": {}, "raids": {}, "exploration": {}, "mounts": {}, "terminal": {}, "outpost": {}, "main_story": {}}
	for k in defs.keys():
		if not vm.culture_state.has(k):
			vm.culture_state[k] = defs[k]
	return vm.culture_state

## Bloque PP: Crear tu propio asentamiento fronterizo («Puesto del Paso») e Historia Principal en 4 capítulos (panel [L])
static func outpost_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("outpost", null) is Dictionary):
		st["outpost"] = {}
	var op: Dictionary = st["outpost"]
	if not op.has("founded"):
		op["founded"] = false
	if not op.has("name"):
		op["name"] = "Puesto del Paso"
	if not (op.get("settlers", null) is Array):
		op["settlers"] = []
	if not (op.get("upgrades", null) is Dictionary):
		op["upgrades"] = {"sawmill": false, "granary": false, "watchtower": false}
	if not op.has("treasury"):
		op["treasury"] = 0
	return op

static func found_outpost(vm, inv) -> bool:
	if vm == null or inv == null:
		return false
	var op: Dictionary = outpost_state(vm)
	if bool(op.get("founded", false)) or int(inv.gold) < OUTPOST_CHARTER_COST:
		return false
	if int(inv.items.get("wood", 0)) < 2 or int(inv.items.get("stone", 0)) < 2:
		return false
	inv.add_gold(-OUTPOST_CHARTER_COST)
	inv.remove_item("wood", 2)
	inv.remove_item("stone", 2)
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + (OUTPOST_CHARTER_COST - 20)
	op["founded"] = true
	op["treasury"] = 20
	sync_outpost_visuals(vm)
	VillageChronicle.add(vm, "outpost_founded", "Fundaste el asentamiento fronterizo «%s» con carta municipal (-%d Oro)" % [str(op["name"]), OUTPOST_CHARTER_COST], true)
	return true

static func recruit_outpost_settler(vm, npc, inv) -> bool:
	if vm == null or npc == null or inv == null:
		return false
	var op: Dictionary = outpost_state(vm)
	var settlers: Array = op["settlers"]
	var pk: String = npc.get_person_key()
	if not bool(op.get("founded", false)) or settlers.size() >= 3 or pk in settlers:
		return false
	if int(npc.trade_role) != int(VillageNPC.TradeRole.UNEMPLOYED) or int(inv.gold) < OUTPOST_SETTLER_BONUS:
		return false
	inv.add_gold(-OUTPOST_SETTLER_BONUS)
	npc.personal_gold += OUTPOST_SETTLER_BONUS
	settlers.append(pk)
	npc.modify_affinity(12)
	npc.add_thought("Me uní como colono fundador al Puesto del Paso (+8)", 8.0)
	VillageChronicle.add(vm, "outpost_settler", "%s se unió como colono a tu asentamiento «%s»" % [npc.npc_name, str(op["name"])], true)
	return true

static func upgrade_outpost(vm, upg_id: String, artisan, inv) -> bool:
	if vm == null or inv == null or not OUTPOST_UPGRADES.has(upg_id):
		return false
	var op: Dictionary = outpost_state(vm)
	var upgs: Dictionary = op["upgrades"]
	if not bool(op.get("founded", false)) or bool(upgs.get(upg_id, false)) or int(inv.gold) < OUTPOST_UPGRADE_COST:
		return false
	inv.add_gold(-OUTPOST_UPGRADE_COST)
	if artisan != null and is_instance_valid(artisan):
		artisan.personal_gold += OUTPOST_UPGRADE_COST
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + OUTPOST_UPGRADE_COST
	upgs[upg_id] = true
	sync_outpost_visuals(vm)
	if "VillageMayor" in vm and vm.VillageMayor != null:
		vm.VillageMayor.announce_town_inauguration(vm, str(OUTPOST_UPGRADES.get(upg_id, upg_id)))
	VillageChronicle.add(vm, "outpost_upgraded", "Construiste %s en tu asentamiento «%s»" % [upg_id, str(op["name"])], true)
	return true

static func process_outpost_daily(vm) -> void:
	if vm == null:
		return
	var op: Dictionary = outpost_state(vm)
	if not bool(op.get("founded", false)):
		return
	var settlers: Array = op["settlers"]
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var active_settlers: int = 0
	for pk in settlers.duplicate():
		var sn = by_key.get(str(pk), null)
		if sn == null or not is_instance_valid(sn) or sn.is_dead:
			settlers.erase(pk)
			continue
		active_settlers += 1
	if active_settlers <= 0:
		return
	var upgs: Dictionary = op["upgrades"]
	var routes: Dictionary = trade_routes_of(vm)
	for r_id in routes.keys():
		var r: Dictionary = routes[r_id]
		var toll: int = mini(3 * active_settlers + (3 if bool(upgs.get("sawmill", false)) else 0), maxi(0, int(r.get("balance", 0))))
		if toll > 0:
			r["balance"] = int(r["balance"]) - toll
			op["treasury"] = int(op.get("treasury", 0)) + toll
			break
	for pk2 in settlers:
		var sn2 = by_key.get(str(pk2), null)
		if sn2 != null and is_instance_valid(sn2) and not sn2.is_dead and int(op.get("treasury", 0)) >= 3:
			op["treasury"] = int(op["treasury"]) - 3
			sn2.personal_gold += 3

static func collect_outpost_treasury(vm, inv) -> int:
	if vm == null or inv == null:
		return 0
	var op: Dictionary = outpost_state(vm)
	if not bool(op.get("founded", false)):
		return 0
	var avail: int = maxi(0, int(op.get("treasury", 0)) - 6)
	if avail <= 0:
		return 0
	op["treasury"] = int(op["treasury"]) - avail
	inv.add_gold(avail)
	return avail

static func main_story_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("main_story", null) is Dictionary):
		st["main_story"] = {}
	var ms: Dictionary = st["main_story"]
	if not ms.has("chapter_idx"):
		ms["chapter_idx"] = 0
	if not ms.has("completed"):
		ms["completed"] = false
	return ms

static func _is_main_chapter_ready(vm, idx: int) -> bool:
	if vm == null:
		return false
	match idx:
		0:
			var has_home: bool = "VillageHousing" in vm and vm.VillageHousing != null and vm.VillageHousing.primary_player_lot(vm) != ""
			var has_rep: bool = "faith_state" in vm and vm.faith_state is Dictionary and int((vm.faith_state.get("rep", {}) as Dictionary).get("law", 0)) >= 10
			return has_home or has_rep or bool(outpost_state(vm).get("founded", false))
		1:
			var disc: int = int(exploration_state(vm).get("discoveries", 0))
			var sew: int = int(vm.VillageUnderworld.sewers_state(vm).get("explored_count", 0)) if "VillageUnderworld" in vm and vm.VillageUnderworld != null else 0
			return disc >= 1 or sew >= 1
		2:
			var unlocked_cnt: int = (research_state(vm).get("unlocked", {}) as Dictionary).size()
			var hacks_cnt: int = int(terminal_state(vm).get("hacks_succeeded", 0))
			return unlocked_cnt >= 1 or hacks_cnt >= 1
		3:
			var op_ok: bool = bool(outpost_state(vm).get("founded", false))
			var mayor_ok: bool = vm.VillageMayor.is_player_mayor(vm)
			var raid_ok: bool = int(raids_state(vm).get("raids_repelled", 0)) >= 1
			return op_ok or mayor_ok or raid_ok
	return false

static func sync_main_story(vm, inv = null) -> int:
	if vm == null:
		return 0
	var qm = vm.get_node_or_null("/root/QuestManager")
	var ms: Dictionary = main_story_state(vm)
	if bool(ms.get("completed", false)):
		return MAIN_STORY_CHAPTERS.size()
	var idx: int = clampi(int(ms.get("chapter_idx", 0)), 0, MAIN_STORY_CHAPTERS.size() - 1)
	var ch: Dictionary = MAIN_STORY_CHAPTERS[idx]
	var qid: String = str(ch["id"])
	if qm != null and qm.get_quest(qid).is_empty():
		qm.add_quest({
			"id": qid,
			"category": "main",
			"type": "main_story",
			"title": str(ch["title"]),
			"description": str(ch["description"]),
			"giver_name": "Crónica del Valle",
		})
	var advanced: int = 0
	while idx < MAIN_STORY_CHAPTERS.size() and _is_main_chapter_ready(vm, idx):
		var cur_ch: Dictionary = MAIN_STORY_CHAPTERS[idx]
		var cur_qid: String = str(cur_ch["id"])
		if qm != null:
			if qm.get_quest(cur_qid).is_empty():
				qm.add_quest({
					"id": cur_qid,
					"category": "main",
					"type": "main_story",
					"title": str(cur_ch["title"]),
					"description": str(cur_ch["description"]),
					"giver_name": "Crónica del Valle",
				})
			qm.complete_quest(cur_qid, "Capítulo completado.")
		var rew: int = mini(int(cur_ch.get("reward_gold", 20)), maxi(0, int(vm.town_state.get("treasury", 0))))
		if rew > 0 and inv != null:
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - rew
			inv.add_gold(rew)
		VillageChronicle.add(vm, "main_story", "👑 Completaste el capítulo de la Historia Principal: %s" % str(cur_ch["title"]), true)
		idx += 1
		advanced += 1
		if idx < MAIN_STORY_CHAPTERS.size() and qm != null:
			var nxt_ch: Dictionary = MAIN_STORY_CHAPTERS[idx]
			if qm.get_quest(str(nxt_ch["id"])).is_empty():
				qm.add_quest({
					"id": str(nxt_ch["id"]),
					"category": "main",
					"type": "main_story",
					"title": str(nxt_ch["title"]),
					"description": str(nxt_ch["description"]),
					"giver_name": "Crónica del Valle",
				})
	ms["chapter_idx"] = idx
	if idx >= MAIN_STORY_CHAPTERS.size():
		ms["completed"] = true
	return advanced

## Bloque PO: Armas de fuego de chispa (flintlock_pistol, powder_charge) y Terminales lógicas / Hackeo electromecánico
static func has_loaded_firearm(inv) -> bool:
	return inv != null and inv.has_item("flintlock_pistol", 1) and inv.has_item("powder_charge", 1)

static func buy_firearm(vm, seller, inv) -> bool:
	if vm == null or seller == null or inv == null:
		return false
	if not has_tech(vm, "reinforced_locks") or inv.has_item("flintlock_pistol", 1) or int(inv.gold) < FIREARM_COST:
		return false
	inv.add_gold(-FIREARM_COST)
	seller.personal_gold += FIREARM_COST
	inv.add_item("flintlock_pistol", 1)
	inv.add_item("powder_charge", 2)
	VillageChronicle.add(vm, "firearm_bought", "Adquiriste un Arcabuz de Chispa con cargas de pólvora en el taller (-%d de oro)" % FIREARM_COST, false)
	return true

static func buy_powder_pack(vm, seller, inv) -> bool:
	if vm == null or seller == null or inv == null or int(inv.gold) < POWDER_PACK_COST:
		return false
	inv.add_gold(-POWDER_PACK_COST)
	seller.personal_gold += POWDER_PACK_COST
	inv.add_item("powder_charge", 2)
	return true

static func fire_flintlock_shot(vm, target_npc, inv) -> bool:
	if vm == null or target_npc == null or not is_instance_valid(target_npc) or not has_loaded_firearm(inv):
		return false
	inv.remove_item("powder_charge", 1)
	target_npc.last_hit_weapon_name = "Arcabuz de Chispa"
	target_npc.last_hit_by_player = true
	if target_npc.health_comp != null:
		target_npc.health_comp.apply_minor_bruise(48.0, 0.10, "Disparo de Arcabuz de Chispa")
	target_npc.modify_affinity(-35)
	if AudioManager:
		AudioManager.emit_noise(target_npc.global_position, 260.0, int(target_npc.elevation_level), "gunshot")
	var witness = vm._find_conscious_witness_near(target_npc.global_position, 260.0, target_npc)
	if witness != null:
		vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
		vm.bounty_gold += 25
	VillageChronicle.add(vm, "firearm_shot", "Disparaste tu Arcabuz de Chispa contra %s" % target_npc.npc_name, witness != null)
	return true

static func terminal_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("terminal", null) is Dictionary):
		st["terminal"] = {}
	var tm: Dictionary = st["terminal"]
	for k in [["last_hack_day", -99], ["hacks_succeeded", 0], ["alarms_triggered", 0]]:
		if not tm.has(k[0]):
			tm[k[0]] = k[1]
	return tm

const TINKER_LOT: String = "e5"
const TINKER_TERMINAL_POS: Vector2 = Vector2(1188.0, 122.0) # Dentro del Taller de Reparaciones (e5), sobre una mesa en el rincón noroeste
const TINKER_GRID_PANEL_POS: Vector2 = Vector2(1270.0, 90.0) # En la pared exterior norte del Taller de Reparaciones (e5), a la derecha de la puerta

static func build_tinker_stations(vm) -> void:
	if vm == null or not ("entities_root" in vm) or not is_instance_valid(vm.entities_root):
		return
	var PropScript = load("res://scripts/obstacles/WorldInteractableProp.gd")
	if PropScript == null:
		return
	if vm.is_inside_tree():
		for old_n in vm.get_tree().get_nodes_in_group("tinker_station"):
			if is_instance_valid(old_n):
				old_n.queue_free()
	var term: Node2D = PropScript.new()
	term.name = "TinkerLogicTerminal"
	term.global_position = TINKER_TERMINAL_POS
	vm.entities_root.add_child(term)
	term.setup_prop(vm, "terminal")

	var panel: Node2D = PropScript.new()
	panel.name = "TinkerElectricPanel"
	panel.global_position = TINKER_GRID_PANEL_POS
	vm.entities_root.add_child(panel)
	panel.setup_prop(vm, "grid_panel")

static func open_terminal_menu(vm, speaker: Node, _player: Node2D = null) -> void:
	if vm == null:
		return
	var dm = vm.get_node_or_null("/root/DialogueManager")
	if dm == null or not dm.has_method("start_dialogue"):
		return
	var tm: Dictionary = terminal_state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	var used_today: bool = (int(tm.get("last_hack_day", -99)) == today)
	var note: String = "\n\n(🔒 Ya manipulaste la terminal hoy; espera a mañana para otra incursión lógica)." if used_today else "\n\n(1 incursión lógica al día; ten cuidado de que nadie te vea manipularla)."
	var graph := {
		"start": {
			"text": "🖥️⚡ TERMINAL LÓGICA ELECTROMECÁNICA\nLa consola de tarjetas perforadas y relés de cobre conecta las arcas del ayuntamiento, el archivo policial y el controlador de red." + note,
			"choices": [
				{"label": "💰🖥️ Desviar reembolso del Registro Fiscal (hasta +18 Oro de las arcas)", "next": "END", "action": "culture_hack_terminal:census_ledger"},
				{"label": "🚓🖥️ Purgar expediente del Archivo Policial (-1 Búsqueda y -25 Recompensa)", "next": "END", "action": "culture_hack_terminal:warrant_archive"},
				{"label": "⚡🖥️ Reprogramar Controlador de Red (+2 lecturas técnicas y repara línea)", "next": "END", "action": "culture_hack_terminal:grid_controller"},
				{"label": "Apartarse de la terminal [Salir]", "next": "END"},
			]
		}
	}
	dm.start_dialogue(graph, "start", speaker)

static func open_grid_panel_menu(vm, speaker: Node, _player: Node2D = null) -> void:
	if vm == null:
		return
	var dm = vm.get_node_or_null("/root/DialogueManager")
	if dm == null or not dm.has_method("start_dialogue"):
		return
	var g: Dictionary = grid_state(vm)
	var is_sab: bool = is_grid_sabotaged(vm)
	var status_line: String = "\n\n⚠️ El cuadro echa chispas (circuito averiado: %s)." % str(g.get("sabotaged_target", "all")) if is_sab else "\n\nLos tres seccionadores de cobre alimentan las farolas, la bomba de riego y el generador general."
	var choices: Array = [
		{"label": "🌑 Cortar el circuito de farolas (Calles a oscuras)", "next": "END", "action": "culture_sabotage_grid:lamps"},
		{"label": "🥀 Cortar la bomba eléctrica de riego (Secar aspersor)", "next": "END", "action": "culture_sabotage_grid:sprinkler"},
		{"label": "💥 Cortocircuitar el generador general (Apagón 2 días)", "next": "END", "action": "culture_sabotage_grid:all"},
	]
	if is_sab:
		choices.append({"label": "🛠️⚡ Empalmar el tendido eléctrico (-1 Bobina de Cobre, +%d Oro del arca)" % GRID_REPAIR_REWARD, "next": "END", "action": "culture_repair_grid"})
	choices.append({"label": "Cerrar la tapa del cuadro [Salir]", "next": "END"})
	var graph := {
		"start": {
			"text": "⚡🔧 CUADRO ELÉCTRICO DEL TALLER" + status_line,
			"choices": choices,
		}
	}
	dm.start_dialogue(graph, "start", speaker)

static func hack_terminal(vm, subsystem: String, inv, force_outcome: int = 0) -> Dictionary:
	if vm == null or not (subsystem in ["census_ledger", "warrant_archive", "grid_controller"]):
		return {"ok": false}
	var tm: Dictionary = terminal_state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	if int(tm.get("last_hack_day", -99)) == today:
		return {"ok": false}
	# Borrar la búsqueda comparte la espera semanal del sótano y del pasadizo
	if subsystem == "warrant_archive" and not vm.VillageHousing.can_purge_wanted(vm):
		return {"ok": false, "wait": true}
	var pl = VillageNeeds.player_of(vm)
	# Si el arreglador u otro vecino despierto te está viendo en ese momento (misma planta y cerca), cuenta como delito
	if force_outcome == 0 and vm.has_method("_find_conscious_witness_near"):
		var check_pos: Vector2 = pl.global_position if pl != null else TINKER_TERMINAL_POS
		var wit = vm._find_conscious_witness_near(check_pos, 120.0, null)
		if wit != null:
			tm["last_hack_day"] = today
			tm["alarms_triggered"] = int(tm.get("alarms_triggered", 0)) + 1
			vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
			vm.bounty_gold = int(vm.bounty_gold) + 25
			if "affinity" in wit:
				wit.affinity = clampi(int(wit.affinity) - 15, -100, 100)
			VillageChronicle.add(vm, "terminal_alarm", "¡%s te sorprendió manipulando la terminal lógica (%s)!" % [str(wit.npc_name), subsystem], true)
			return {"ok": true, "won": false, "witnessed": true, "witness": wit, "subsystem": subsystem, "gold": 0}
	tm["last_hack_day"] = today
	var chance: float = 0.45 + (0.20 if has_tech(vm, "voltaic_capacitors") else 0.0) + (0.15 if (inv != null and inv.has_item("copper_coil", 1)) else 0.0)
	var won: bool = (randf() < chance) if force_outcome == 0 else (force_outcome > 0)
	if won:
		tm["hacks_succeeded"] = int(tm.get("hacks_succeeded", 0)) + 1
		var gain_gold: int = 0
		if subsystem == "census_ledger":
			gain_gold = mini(18, maxi(0, int(vm.town_state.get("treasury", 0))))
			if gain_gold > 0 and inv != null:
				vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - gain_gold
				inv.add_gold(gain_gold)
		elif subsystem == "warrant_archive":
			vm.wanted_level = maxi(0, int(vm.wanted_level) - 1)
			vm.bounty_gold = maxi(0, int(vm.bounty_gold) - 25)
			vm.VillageHousing.mark_wanted_purge(vm)
		elif subsystem == "grid_controller":
			repair_grid(vm)
			state(vm)["readings"] = int(state(vm).get("readings", 0)) + 2
		VillageChronicle.add(vm, "terminal_hacked", "Hackeaste en silencio la terminal lógica (%s)" % subsystem, false)
		return {"ok": true, "won": true, "subsystem": subsystem, "gold": gain_gold}
	tm["alarms_triggered"] = int(tm.get("alarms_triggered", 0)) + 1
	vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
	if pl != null:
		var hc = pl.get("health_comp")
		if hc != null and "current_health" in hc:
			hc.current_health = maxf(1.0, float(hc.current_health) - 12.0)
	VillageChronicle.add(vm, "terminal_alarm", "Saltó la alarma voltaica al intentar hackear la terminal lógica (%s)" % subsystem, true)
	return {"ok": true, "won": false, "subsystem": subsystem, "gold": 0}

const HORSE_DEFAULT_POS: Vector2 = Vector2(360, 470) # junto al Rancho del Sur
const CART_DEFAULT_POS: Vector2 = Vector2(385, 470) # junto al Rancho del Sur, al lado del caballo
const CART_THEFT_CHANCE: float = 0.12
const RANCH_CORRAL_RECT: Rect2 = Rect2(310, 400, 87, 140)
const PlayerHorseScript = preload("res://scripts/obstacles/PlayerHorse.gd")
const PlayerCartScript = preload("res://scripts/obstacles/PlayerCart.gd")

## Si un punto cae dentro de un edificio, lo saca a la calle por delante de su puerta (el caballo no cabe en una tienda).
static func outside_of_buildings(vm, p: Vector2) -> Vector2:
	if vm == null or not ("building_footprints" in vm):
		return p
	for b in vm.building_footprints:
		var r: Rect2 = b["rect"]
		if r.grow(4.0).has_point(p):
			var door: Vector2 = b.get("door_pos", r.get_center())
			var out: Vector2 = Vector2(door.x + 16.0, (r.end.y + 16.0) if bool(b.get("door_south", true)) else (r.position.y - 16.0))
			return outside_of_buildings(vm, out) if out != p else out
	return p

## Crea (o recoloca) el caballo físico del jugador según mounts_state. Si ibas montado, te vuelve a subir.
static func sync_player_horse(vm) -> Node:
	if vm == null:
		return null
	if not has_horse(vm):
		# Partida cargada sin caballo: quita el que hubiera de antes y baja al jugador.
		if vm.is_inside_tree():
			for h_old in vm.get_tree().get_nodes_in_group("player_horse"):
				h_old.queue_free()
		var pl_n = VillageNeeds.player_of(vm)
		if pl_n != null and bool(pl_n.get("is_mounted")):
			pl_n.set("is_mounted", false)
		return null
	var m: Dictionary = mounts_state(vm)
	var pos := Vector2(float(m.get("pos_x", HORSE_DEFAULT_POS.x)), float(m.get("pos_y", HORSE_DEFAULT_POS.y)))
	if not bool(m.get("is_mounted", false)):
		pos = outside_of_buildings(vm, pos)
		m["pos_x"] = pos.x
		m["pos_y"] = pos.y
	var horse = vm.get_tree().get_first_node_in_group("player_horse") if vm.is_inside_tree() else null
	if horse == null or not is_instance_valid(horse) or horse.is_queued_for_deletion():
		horse = PlayerHorseScript.new()
		var parent: Node = vm.entities_root if ("entities_root" in vm and is_instance_valid(vm.entities_root)) else vm
		parent.add_child(horse)
		horse.setup(vm, pos)
	else:
		horse.global_position = pos
	var pl = VillageNeeds.player_of(vm)
	if pl != null:
		if bool(m.get("is_mounted", false)):
			pl.global_position = pos
			horse.mount(pl)
		elif bool(pl.get("is_mounted")):
			pl.set("is_mounted", false)
	return horse

## Crea (o recoloca) la carreta física del jugador según mounts_state.
static func sync_player_cart(vm) -> Node:
	if vm == null:
		return null
	if not has_cart(vm):
		if vm.is_inside_tree():
			for c_old in vm.get_tree().get_nodes_in_group("player_cart"):
				c_old.queue_free()
		var pl_n = VillageNeeds.player_of(vm)
		if pl_n != null:
			pl_n.set("is_pulling_cart", false)
			pl_n.set("is_cart_hitched", false)
		return null
	var m: Dictionary = mounts_state(vm)
	var mode: String = str(m.get("cart_mode", "parked"))
	var pos := Vector2(float(m.get("cart_x", CART_DEFAULT_POS.x)), float(m.get("cart_y", CART_DEFAULT_POS.y)))
	if mode == "parked":
		pos = outside_of_buildings(vm, pos)
		m["cart_x"] = pos.x
		m["cart_y"] = pos.y
	var cart = vm.get_tree().get_first_node_in_group("player_cart") if vm.is_inside_tree() else null
	if cart == null or not is_instance_valid(cart) or cart.is_queued_for_deletion():
		cart = PlayerCartScript.new()
		var parent: Node = vm.entities_root if ("entities_root" in vm and is_instance_valid(vm.entities_root)) else vm
		parent.add_child(cart)
		cart.setup(vm, pos)
	else:
		cart.global_position = pos
	var pl = VillageNeeds.player_of(vm)
	if pl != null:
		if mode == "hand":
			cart.grab_by_hand(pl, true)
		elif mode == "horse":
			cart.hitch_to_horse(pl, true)
		else:
			pl.set("is_pulling_cart", false)
			pl.set("is_cart_hitched", false)
	return cart

static func mounts_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("mounts", null) is Dictionary):
		st["mounts"] = {}
	var m: Dictionary = st["mounts"]
	for k in ["has_horse", "has_cart"]:
		if not m.has(k):
			m[k] = false
	if not m.has("cart_x"):
		m["cart_x"] = CART_DEFAULT_POS.x
	if not m.has("cart_y"):
		m["cart_y"] = CART_DEFAULT_POS.y
	if not m.has("cart_mode"):
		m["cart_mode"] = "parked"
	if not (m.get("cart_cargo", null) is Dictionary):
		m["cart_cargo"] = {}
	return m

static func has_horse(vm) -> bool:
	return vm != null and bool(mounts_state(vm).get("has_horse", false))

static func has_cart(vm) -> bool:
	return vm != null and bool(mounts_state(vm).get("has_cart", false))

static func is_cart_near_player(vm, max_dist: float = 60.0) -> bool:
	if not has_cart(vm):
		return false
	var pl = VillageNeeds.player_of(vm)
	if pl == null:
		return false
	var cart = vm.get_tree().get_first_node_in_group("player_cart") if vm.is_inside_tree() else null
	var m: Dictionary = mounts_state(vm)
	var c_pos: Vector2 = cart.global_position if (cart != null and is_instance_valid(cart)) else Vector2(float(m.get("cart_x", CART_DEFAULT_POS.x)), float(m.get("cart_y", CART_DEFAULT_POS.y)))
	return (pl.global_position as Vector2).distance_to(c_pos) < max_dist

static func is_cart_in_safe_place(vm, pos: Vector2) -> bool:
	if RANCH_CORRAL_RECT.has_point(pos):
		return true
	if vm != null and "VillageHousing" in vm and vm.VillageHousing != null:
		for lid in vm.VillageHousing.player_lots(vm, true):
			var ldef: Dictionary = VillageLots.lot_def(str(lid))
			if not ldef.is_empty() and pos.distance_to(ldef["center"] as Vector2) < 90.0:
				return true
	return false

## Bloque P2: si la carreta duerme aparcada lejos de un lugar seguro con carga dentro, hay un 12 % de robo nocturno.
## Roba el vecino adulto (no forastero) con menos oro: se lleva la mitad hacia abajo (máx. 10) al azar a su bolsillo (suma cero).
static func cart_night_theft(vm, chance: float = CART_THEFT_CHANCE) -> int:
	if vm == null or not has_cart(vm):
		return 0
	var m: Dictionary = mounts_state(vm)
	var cart = vm.get_tree().get_first_node_in_group("player_cart") if vm.is_inside_tree() else null
	if cart != null and is_instance_valid(cart):
		m["cart_x"] = cart.global_position.x
		m["cart_y"] = cart.global_position.y
	if str(m.get("cart_mode", "parked")) != "parked":
		return 0
	var cart_pos := Vector2(float(m.get("cart_x", CART_DEFAULT_POS.x)), float(m.get("cart_y", CART_DEFAULT_POS.y)))
	if is_cart_in_safe_place(vm, cart_pos):
		return 0
	var cargo: Dictionary = m.get("cart_cargo", {})
	var units: Array[String] = []
	for k in cargo.keys():
		var cnt: int = int(cargo[k])
		for _i in range(cnt):
			units.append(str(k))
	var steal_count: int = mini(10, int(floor(float(units.size()) / 2.0)))
	if steal_count <= 0 or randf() >= chance:
		return 0
	var thief = null
	for n in VillageNeeds.living(vm):
		if int(n.trade_role) != int(VillageNPC.TradeRole.CHILD) and not VillageNeeds.is_outsider(n):
			if thief == null or int(n.personal_gold) < int(thief.personal_gold):
				thief = n
	if thief == null:
		return 0
	units.shuffle()
	var stolen_by_item: Dictionary = {}
	for i in range(steal_count):
		var it_id: String = units[i]
		var left: int = int(cargo.get(it_id, 0)) - 1
		if left <= 0:
			cargo.erase(it_id)
		else:
			cargo[it_id] = left
		if thief.has_method("add_pocket_item"):
			thief.add_pocket_item(it_id, 1)
		else:
			thief.pocket_items[it_id] = int(thief.pocket_items.get(it_id, 0)) + 1
		stolen_by_item[it_id] = int(stolen_by_item.get(it_id, 0)) + 1
	if cart != null and is_instance_valid(cart) and cart.has_method("_refresh_cargo_ui"):
		cart._refresh_cargo_ui()
	var witness = vm._find_conscious_witness_near(cart_pos, 160.0, thief) if vm.has_method("_find_conscious_witness_near") else null
	if witness != null:
		VillageChronicle.add(vm, "cart_cargo_robbed", "%s vio a %s llevarse carga de tu carreta" % [str(witness.npc_name), str(thief.npc_name)], true)
	else:
		VillageChronicle.add(vm, "cart_cargo_robbed", "Alguien se llevó carga de tu carreta por la noche", true)
	var pl = VillageNeeds.player_of(vm)
	if pl != null and pl.has_method("show_hint"):
		var parts: Array[String] = []
		for it_id2 in stolen_by_item.keys():
			var it_name: String = str(SimpleInventory.CATALOG.get(it_id2, {}).get("name", it_id2))
			parts.append("%d %s" % [int(stolen_by_item[it_id2]), it_name])
		pl.show_hint("🛒⚠️ Anoche robaron de tu carreta: %s." % ", ".join(parts))
	return steal_count

static func buy_mount(vm, kind: String, seller, inv) -> bool:
	if vm == null or seller == null or inv == null:
		return false
	var m: Dictionary = mounts_state(vm)
	if kind == "horse":
		if bool(m.get("has_horse", false)) or int(inv.gold) < HORSE_COST:
			return false
		inv.add_gold(-HORSE_COST)
		seller.personal_gold += HORSE_COST
		m["has_horse"] = true
		# Regla 2: el caballo existe en el mapa, junto al ganadero que te lo vende.
		var spawn: Vector2 = (seller.global_position + Vector2(26, 6)) if seller is Node2D else HORSE_DEFAULT_POS
		m["pos_x"] = spawn.x
		m["pos_y"] = spawn.y
		m["is_mounted"] = false
		sync_player_horse(vm)
		VillageChronicle.add(vm, "mount", "Compraste un caballo de silla en el Rancho del Sur", true)
		return true
	elif kind == "cart":
		if bool(m.get("has_cart", false)) or int(inv.gold) < CART_COST:
			return false
		inv.add_gold(-CART_COST)
		seller.personal_gold += CART_COST
		m["has_cart"] = true
		m["cart_x"] = CART_DEFAULT_POS.x
		m["cart_y"] = CART_DEFAULT_POS.y
		m["cart_mode"] = "parked"
		if not (m.get("cart_cargo", null) is Dictionary):
			m["cart_cargo"] = {}
		sync_player_cart(vm)
		VillageChronicle.add(vm, "mount", "Compraste una carreta de carga en el Rancho del Sur", true)
		return true
	return false

static func exploration_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("exploration", null) is Dictionary):
		st["exploration"] = {}
	var ex: Dictionary = st["exploration"]
	if not (ex.get("sites", null) is Dictionary):
		ex["sites"] = {}
	var s_dict: Dictionary = ex["sites"]
	for s_id in EXPLORATION_SITES.keys():
		if not s_dict.has(s_id):
			s_dict[s_id] = 0
	if not ex.has("last_exp_day"):
		ex["last_exp_day"] = -99
	if not ex.has("discoveries"):
		ex["discoveries"] = 0
	return ex

static func run_expedition(vm, site_id: String, guide_npc, inv, force_outcome: int = 0) -> Dictionary:
	if vm == null or inv == null or not EXPLORATION_SITES.has(site_id):
		return {"ok": false}
	var ex: Dictionary = exploration_state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	if int(ex.get("last_exp_day", -99)) == today or int(inv.gold) < EXPEDITION_COST:
		return {"ok": false}
	inv.add_gold(-EXPEDITION_COST)
	if guide_npc != null:
		guide_npc.personal_gold += EXPEDITION_COST
	ex["last_exp_day"] = today
	var s_def: Dictionary = EXPLORATION_SITES[site_id]
	var chance: float = 0.60 + (0.15 if has_horse(vm) else 0.0)
	var won: bool = randf() < chance
	if force_outcome == 1:
		won = true
	elif force_outcome == -1:
		won = false
	if won:
		var s_dict: Dictionary = ex["sites"]
		s_dict[site_id] = mini(int(s_def["max_stages"]), int(s_dict.get(site_id, 0)) + 1)
		ex["discoveries"] = int(ex.get("discoveries", 0)) + 1
		var reward_item: String = str(s_def.get("item", "copper_coil"))
		inv.add_item(reward_item, 1)
		state(vm)["readings"] = int(state(vm).get("readings", 0)) + 2
		VillageChronicle.add(vm, "expedition", "🗺️ Tu expedición a %s halló reliquias (%s) y notas para la biblioteca" % [str(s_def["name"]), reward_item], true)
		return {"ok": true, "won": true, "item": reward_item}
	return {"ok": true, "won": false, "item": ""}

static func research_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("research", null) is Dictionary):
		st["research"] = {}
	var rs: Dictionary = st["research"]
	if not (rs.get("unlocked", null) is Dictionary):
		rs["unlocked"] = {}
	if not rs.has("active_tech"):
		rs["active_tech"] = ""
	if not rs.has("progress"):
		rs["progress"] = 0
	return rs

static func has_tech(vm, tech_id: String) -> bool:
	return vm != null and bool((research_state(vm)["unlocked"] as Dictionary).get(tech_id, false))

static func start_research(vm, tech_id: String, engineer = null, inv = null) -> bool:
	if vm == null or not TECH_TREE.has(tech_id) or has_tech(vm, tech_id):
		return false
	var rs: Dictionary = research_state(vm)
	if str(rs.get("active_tech", "")) != "":
		return false
	var t_def: Dictionary = TECH_TREE[tech_id]
	var pre: String = str(t_def.get("prereq", ""))
	if pre != "" and not has_tech(vm, pre):
		return false
	var cost: int = int(t_def.get("cost_gold", 25))
	if inv != null:
		if int(inv.gold) < cost:
			return false
		inv.add_gold(-cost)
		if engineer != null:
			engineer.personal_gold += cost
	rs["active_tech"] = tech_id
	rs["progress"] = 0
	return true

static func advance_research(vm, extra_points: int = 1) -> bool:
	if vm == null:
		return false
	var rs: Dictionary = research_state(vm)
	var active: String = str(rs.get("active_tech", ""))
	if active == "" or not TECH_TREE.has(active):
		return false
	var t_def: Dictionary = TECH_TREE[active]
	var gain: int = maxi(1, extra_points)
	if int(state(vm).get("readings", 0)) >= 3:
		state(vm)["readings"] = int(state(vm)["readings"]) - 3
		gain += 1
	rs["progress"] = int(rs.get("progress", 0)) + gain
	if int(rs["progress"]) >= int(t_def.get("req_points", 3)):
		(rs["unlocked"] as Dictionary)[active] = true
		rs["active_tech"] = ""
		rs["progress"] = 0
		var tinker = vm.trade_npcs.get(VillageTrades.role_of("tinker"))
		if tinker != null and is_instance_valid(tinker) and not tinker.is_dead:
			VillageFame.add_fame(vm, tinker, 10, "Desarrolló la tecnología: %s" % str(t_def["name"]))
		if "VillageMayor" in vm and vm.VillageMayor != null:
			vm.VillageMayor.announce_town_inauguration(vm, str(t_def["name"]))
		VillageChronicle.add(vm, "tech_unlocked", "El taller de ingeniería completó el invento: %s" % str(t_def["name"]), true)
		return true
	return false

static func raids_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("raids", null) is Dictionary):
		st["raids"] = {}
	var rd: Dictionary = st["raids"]
	var r_defs: Dictionary = {
		"threat": 0,
		"active_raid": {},
		"raids_repelled": 0,
		"raids_suffered": 0,
		"militia_bonus": 0,
		"last_raid_day": -99,
	}
	for k in r_defs.keys():
		if not rd.has(k):
			rd[k] = r_defs[k]
	return rd

static func start_raid_warning(vm, kind: String = "bandits") -> Dictionary:
	if vm == null:
		return {}
	var rd: Dictionary = raids_state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	var names: Dictionary = {
		"bandits": "Banda del Paso Negro",
		"boars": "Manada de Jabalíes Furiosos",
		"outiders": "Saqueadores del Norte",
	}
	var lure_txt: String = raid_motive_text(vm)
	var raid: Dictionary = {
		"kind": kind,
		"name": str(names.get(kind, "Banda del Paso Negro")),
		# Más amenaza = banda más grande; cada incursión rechazada, la siguiente viene más preparada
		"strength": 3 + mini(4, int(float(rd.get("threat", 0)) / 15.0)) + mini(3, int(rd.get("raids_repelled", 0))),
		"day_due": today,
		"bounty": 20,
		"motive": lure_txt,
	}
	rd["active_raid"] = raid
	VillageChronicle.add(vm, "raid_warning", "⚠️ Los vigías avistan a %s en el camino del este (%s). Atacarán al atardecer" % [str(raid["name"]), lure_txt], true)
	var pl_w = VillageNeeds.player_of(vm)
	if pl_w != null and pl_w.has_method("show_hint"):
		pl_w.show_hint("⚠️ %s viene hacia el pueblo (%s). Atacará al atardecer: habla con el comisario o un guardia para encabezar la defensa." % [str(raid["name"]), lure_txt])
	return raid

## Por qué vienen: lo que el pueblo deja ver hacia fuera. Devuelve 0 si no hay nada que atraiga a los bandidos.
static func raid_lure(vm) -> int:
	var lure: int = 0
	var treasury_val: int = int(vm.town_state.get("treasury", 0))
	if treasury_val > RAID_RICH_TREASURY:
		lure += mini(5, 1 + int(float(treasury_val - RAID_RICH_TREASURY) / 150.0))
	for r in trade_routes_of(vm).values():
		if bool(r.get("active", false)):
			lure += 1 # Las caravanas corren la voz de lo que hay en el valle
	if bool(outpost_state(vm).get("founded", false)):
		lure += 1
	return lure

static func raid_motive_text(vm) -> String:
	var parts: Array[String] = []
	var treasury_val: int = int(vm.town_state.get("treasury", 0))
	if treasury_val > RAID_RICH_TREASURY:
		parts.append("atraídos por las arcas llenas del pueblo")
	for r in trade_routes_of(vm).values():
		if bool(r.get("active", false)):
			parts.append("las caravanas han corrido la voz")
			break
	if bool(outpost_state(vm).get("founded", false)):
		parts.append("el Puesto del Paso les queda de camino")
	return ", ".join(parts) if not parts.is_empty() else "buscan botín fácil"

## Vecinos adultos con arrojo que salen a defender el pueblo (además de la guardia).
static func raid_volunteers(vm) -> Array:
	var out: Array = []
	for n in VillageNeeds.living(vm):
		if out.size() >= RAID_MAX_VOLUNTEERS:
			break
		if int(n.trade_role) in [int(VillageNPC.TradeRole.CHILD), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)] or VillageNeeds.is_outsider(n):
			continue
		if n.is_downed or n.sick_level >= 2 or not n.is_conscious():
			continue
		if TraitCatalog.npc_tendency(n, "aggression") >= 0.35:
			out.append(n)
	return out

static func raid_defenders(vm) -> Array:
	var out: Array = raid_volunteers(vm)
	for n in _all_npcs(vm):
		if not n.is_dead and not n.is_downed and n.is_conscious() and int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]:
			out.append(n)
	return out

## Cada hora: a media tarde los defensores se reúnen en el camino del este; al atardecer llega el asalto.
static func raid_on_hour(vm, hour: int) -> void:
	var rd: Dictionary = raids_state(vm)
	var raid: Dictionary = rd.get("active_raid", {})
	if raid.is_empty():
		return
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	if today < int(raid.get("day_due", today)):
		return
	if hour == RAID_GATHER_HOUR:
		for n in raid_defenders(vm):
			n.start_errand("raid_defend", RAID_GATE_POS + Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, 30.0)))
			n._spawn_floating_text("🛡️", Color(1.0, 0.85, 0.5), -30.0)
	elif hour >= RAID_ATTACK_HOUR and not bool(raid.get("attack_started", false)):
		# Regla «todo es físico»: el asalto lo deciden los atacantes que aparecen de verdad (RaidController).
		spawn_raid_attackers(vm)

const RaidControllerScript = preload("res://scripts/systems/RaidController.gd")

## Hace aparecer a los atacantes en el camino del este. Devuelve el controlador del asalto (o null si no hay asalto).
static func spawn_raid_attackers(vm) -> Node:
	var rd: Dictionary = raids_state(vm)
	var raid: Dictionary = rd.get("active_raid", {})
	if raid.is_empty() or not vm.is_inside_tree():
		return null
	var old = vm.get_tree().get_first_node_in_group("raid_controller")
	if old != null and is_instance_valid(old) and not old.is_queued_for_deletion():
		return old
	raid["attack_started"] = true
	var ctl = RaidControllerScript.new()
	vm.add_child(ctl)
	var n: int = ctl.start(vm, str(raid.get("kind", "bandits")), int(raid.get("strength", 4)), int(rd.get("militia_bonus", 0)))
	var what: String = "jabalíes" if str(raid.get("kind", "")) == "boars" else "asaltantes"
	VillageChronicle.add(vm, "raid_attack", "⚔️ %s entra por el camino del este: %d %s avanzan hacia la plaza" % [str(raid.get("name", "La banda")), n, what], true)
	var pl = VillageNeeds.player_of(vm)
	if pl != null and pl.has_method("show_hint"):
		pl.show_hint("⚔️ ¡%s ataca por el camino del este! %d %s van hacia la plaza: ayuda a la guardia a pararlos." % [str(raid.get("name", "La banda")), n, what])
	return ctl

static func defense_power(vm, player_joined: bool = false, inv = null) -> int:
	if vm == null:
		return 0
	var pwr: int = int(raids_state(vm).get("militia_bonus", 0))
	if has_tech(vm, "reinforced_locks"):
		pwr += 2
	# La atalaya del asentamiento es permanente (no se gasta como las barricadas)
	if bool(outpost_state(vm).get("founded", false)) and bool((outpost_state(vm)["upgrades"] as Dictionary).get("watchtower", false)):
		pwr += 2
	if player_joined:
		pwr += 1
		if has_loaded_firearm(inv):
			pwr += 3
	for n in _all_npcs(vm):
		if n.is_dead or n.is_downed or not n.is_conscious():
			continue
		if int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]:
			pwr += 1
	pwr += raid_volunteers(vm).size() # Vecinos con arrojo que salen con horcas y hachas
	return pwr

static func resolve_raid(vm, player_joined: bool = false, inv = null, force_outcome: int = 0) -> Dictionary:
	if vm == null:
		return {"repelled": false}
	var rd: Dictionary = raids_state(vm)
	var raid: Dictionary = rd.get("active_raid", {})
	if raid.is_empty():
		return {"repelled": false}
	var str_req: int = int(raid.get("strength", 4))
	var def_pwr: int = defense_power(vm, player_joined, inv)
	if player_joined and has_loaded_firearm(inv):
		inv.remove_item("powder_charge", 1)
	var won: bool = (def_pwr + randi_range(0, 2)) >= str_req
	if force_outcome == 1:
		won = true
	elif force_outcome == -1:
		won = false
	var r_name: String = str(raid.get("name", "Incursión"))
	if vm.is_inside_tree():
		for rr in vm.get_tree().get_nodes_in_group("raiders"):
			if is_instance_valid(rr) and not rr.is_dead:
				rr.fleeing = true
		var ctl_old = vm.get_tree().get_first_node_in_group("raid_controller")
		if ctl_old != null and is_instance_valid(ctl_old) and not bool(ctl_old.get("_resolved")):
			ctl_old.set("_resolved", true)
			ctl_old.queue_free()
	var defenders: Array = raid_defenders(vm)
	for d_n in defenders:
		if d_n.errand_kind == "raid_defend":
			d_n.end_errand()
	rd["active_raid"] = {}
	rd["threat"] = 0
	rd["militia_bonus"] = 0
	rd["last_raid_day"] = int(WorldClock.current_day) if WorldClock else 1
	if won:
		rd["raids_repelled"] = int(rd.get("raids_repelled", 0)) + 1
		var reward: int = 0
		if player_joined and inv != null:
			reward = mini(int(raid.get("bounty", 20)), maxi(0, int(vm.town_state.get("treasury", 0))))
			if reward > 0:
				vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - reward
				inv.add_gold(reward)
		for n in _all_npcs(vm):
			if not n.is_dead:
				n.add_thought("Rechazamos el ataque de %s (+6)" % r_name, 6.0)
		VillageChronicle.add(vm, "raid_repelled", "🛡️ El pueblo rechazó la incursión de %s" % r_name, true)
		return {"repelled": true, "reward": reward}
	else:
		rd["raids_suffered"] = int(rd.get("raids_suffered", 0)) + 1
		var looted: int = mini(30, maxi(0, int(vm.town_state.get("treasury", 0))))
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - looted
		for r_key in vm.shop_businesses.keys():
			vm.shop_businesses[r_key]["sabotaged_days"] = maxi(1, int(vm.shop_businesses[r_key].get("sabotaged_days", 0)))
			break
		for n in defenders:
			if not n.is_dead and n.health_comp != null:
				n.health_comp.apply_minor_bruise(14.0, 0.35, "Incursión de %s" % r_name)
				n.add_thought("Nos arrollaron en el camino del este (-6)", -6.0)
		VillageChronicle.add(vm, "raid_suffered", "🔥 %s asaltaron el pueblo y saquearon %d de oro de las arcas" % [r_name, looted], true)
		return {"repelled": false, "looted": looted}

static func forest_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("forest", null) is Dictionary):
		st["forest"] = {}
	var f: Dictionary = st["forest"]
	for k in ["planted_trees", "soil_fertility"]:
		if not f.has(k):
			f[k] = 0
	if not f.has("last_plant_day"):
		f["last_plant_day"] = -99
	return f

static func can_plant_tree(vm) -> bool:
	var f: Dictionary = forest_state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	return int(f.get("last_plant_day", -99)) != today and int(f.get("planted_trees", 0)) < MAX_PLANTED_TREES

## Los pinos sembrados son nodos del mapa que no se guardan solos: se reponen al cargar y cada mañana.
static func restore_planted_trees(vm) -> int:
	if vm == null or not vm.is_inside_tree():
		return 0
	var eco = vm.get_tree().get_first_node_in_group("ecosystem_manager")
	if eco == null:
		return 0
	var missing: int = int(forest_state(vm).get("planted_trees", 0)) - int(eco.count_planted_pines())
	for i in range(maxi(0, missing)):
		eco.plant_sapling(Vector2.ZERO, false)
	return maxi(0, missing)

static func plant_forest_tree(vm, planter_name: String = "Jugador") -> bool:
	if vm == null or not can_plant_tree(vm):
		return false
	var eco = vm.get_tree().get_first_node_in_group("ecosystem_manager") if vm.is_inside_tree() else null
	if eco != null:
		eco.plant_sapling()
	var f: Dictionary = forest_state(vm)
	f["planted_trees"] = int(f.get("planted_trees", 0)) + 1
	f["soil_fertility"] = mini(10, int(f.get("soil_fertility", 0)) + 2)
	f["last_plant_day"] = int(WorldClock.current_day) if WorldClock else 1
	VillageChronicle.add(vm, "reforest", "%s sembró un pino joven en el bosque, enriqueciendo el suelo y atrayendo fauna" % planter_name, true)
	return true

static func trade_routes_of(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("trade_routes", null) is Dictionary):
		st["trade_routes"] = {}
	var t_routes: Dictionary = st["trade_routes"]
	var route_defs: Dictionary = {
		"high_pass": {
			"name": "Paso Alto (Minas del Norte)",
			"exports": "bread", "export_qty": 2,
			"imports": "iron_ore", "import_qty": 2,
			"seller_role": "baker", "buyer_role": "tinker",
			"balance": 90, "tariff_gold": 8, "active": false, "last_ship_day": -99, "next_caravan_day": -1,
		},
		"river_port": {
			"name": "Puerto Fluvial del Este",
			"exports": "wood", "export_qty": 2,
			"imports": "fish", "import_qty": 2,
			"seller_role": "woodcutter", "buyer_role": "farmer",
			"balance": 90, "tariff_gold": 8, "active": false, "last_ship_day": -99, "next_caravan_day": -1,
		},
		"sun_plain": {
			"name": "Vega del Sol",
			"exports": "clothes", "export_qty": 1,
			"imports": "wheat", "import_qty": 3,
			"seller_role": "tailor", "buyer_role": "baker",
			"balance": 90, "tariff_gold": 10, "active": false, "last_ship_day": -99, "next_caravan_day": -1,
		},
	}
	for r_id in route_defs.keys():
		if not (t_routes.get(r_id, null) is Dictionary):
			t_routes[r_id] = (route_defs[r_id] as Dictionary).duplicate()
		elif not (t_routes[r_id] as Dictionary).has("next_caravan_day"):
			t_routes[r_id]["next_caravan_day"] = -1
	return t_routes

class CaravanMuleArea extends Area2D:
	var mule: Node2D = null

	func get_interact_label(player: Node2D = null) -> String:
		if mule != null and is_instance_valid(mule) and mule.has_method("get_interact_label"):
			return str(mule.call("get_interact_label", player))
		return ""

	func interact(player: Node2D) -> void:
		if mule != null and is_instance_valid(mule) and mule.has_method("interact"):
			mule.call("interact", player)


class CaravanMule extends Node2D:
	var vm: Node = null
	var route_id: String = ""
	var merchant: Node2D = null
	var sprite: Sprite2D = null
	var interact_area: Area2D = null
	var model_3d: Node = null

	func setup(p_vm: Node, p_route_id: String, p_merchant: Node2D, pos: Vector2) -> void:
		vm = p_vm
		route_id = p_route_id
		merchant = p_merchant
		name = "CaravanMule_" + p_route_id
		global_position = pos
		add_to_group("caravan_mule")

		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = load("res://assests/world/harvest/wild_deer.png")
		sprite.modulate = Color(0.55, 0.45, 0.36)
		sprite.scale = Vector2(1.05, 1.05)
		sprite.position = Vector2(0, -5)
		add_child(sprite)

		var area := CaravanMuleArea.new()
		area.name = "InteractArea"
		area.mule = self
		area.collision_layer = 1
		area.collision_mask = 2
		area.add_to_group("interactable")
		var col := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 22.0
		col.shape = c
		area.add_child(col)
		add_child(area)
		interact_area = area

		model_3d = AnimalModel3DScript.attach(self, "animals/animated/Horse.glb", 20.0, 4.0, Color(0.62, 0.52, 0.44))

	func get_interact_label(_player: Node2D = null) -> String:
		if vm != null and "VillageCulture" in vm and vm.VillageCulture != null:
			return vm.VillageCulture.get_mule_shipment_label(vm, route_id)
		return ""

	func interact(player: Node2D) -> void:
		if vm != null and "VillageCulture" in vm and vm.VillageCulture != null:
			vm.VillageCulture.interact_caravan_mule(vm, route_id, player)

	func _physics_process(delta: float) -> void:
		if merchant != null and is_instance_valid(merchant) and not bool(merchant.get("is_dead")):
			var target_p: Vector2 = merchant.global_position + Vector2(22.0, 4.0)
			if global_position.distance_to(target_p) > 3.0:
				global_position = global_position.move_toward(target_p, 78.0 * delta)


static func roll_next_caravan_day(route_id: String, from_day: int, force_delay: int = -1) -> int:
	var base_wd: int = int(ROUTE_WEEKDAYS.get(route_id, 0))
	var start_d: int = maxi(1, from_day)
	var cur_wd: int = (start_d - 1) % 7
	var days_until: int = (base_wd - cur_wd + 7) % 7
	var base_day: int = start_d + days_until
	var delayed: bool = (randf() < 0.30) if force_delay < 0 else (force_delay > 0)
	return base_day + (1 if delayed else 0)

static func ensure_route_caravan_schedule(vm, force_delay: int = -1) -> void:
	if vm == null:
		return
	var routes: Dictionary = trade_routes_of(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	for r_id in routes.keys():
		if not ROUTE_WEEKDAYS.has(str(r_id)):
			continue
		var r: Dictionary = routes[r_id]
		if not bool(r.get("active", false)):
			continue
		if int(r.get("next_caravan_day", -1)) < today:
			var from_d: int = (today + 1) if int(r.get("last_exchange_day", -99)) == today else today
			r["next_caravan_day"] = roll_next_caravan_day(str(r_id), from_d, force_delay)
			routes[r_id] = r

static func get_route_caravan_npc(vm, route_id: String):
	if vm == null or not vm.is_inside_tree():
		return null
	for n in vm.get_tree().get_nodes_in_group("village_npcs"):
		if n is VillageNPC and (n as VillageNPC).merchant_id == route_id and not (n as VillageNPC).is_dead:
			return n
	return null

static func get_route_caravan_mule(vm, route_id: String):
	if vm == null or not vm.is_inside_tree():
		return null
	for m in vm.get_tree().get_nodes_in_group("caravan_mule"):
		if is_instance_valid(m) and str(m.get("route_id")) == route_id:
			return m
	return null

static func is_route_caravan_at_plaza(vm, route_id: String) -> bool:
	var m = get_route_caravan_npc(vm, route_id)
	if m == null or not is_instance_valid(m) or m.is_dead or m.is_downed or m._merchant_leaving:
		return false
	return bool(m.get_meta("at_plaza", false)) or m.global_position.distance_to(CARAVAN_PLAZA_POS) <= 45.0

static func get_mule_shipment_label(vm, route_id: String) -> String:
	var routes: Dictionary = trade_routes_of(vm)
	if not routes.has(route_id):
		return ""
	var r: Dictionary = routes[route_id]
	var pay: int = int(r.get("tariff_gold", 8)) + (4 if is_cart_near_player(vm, 60.0) else 0)
	return "Cargar tu remesa para %s (−%d %s → +%d %s y +%d oro)" % [
		str(r.get("name", route_id)),
		int(r.get("export_qty", 2)),
		str(r.get("exports", "wood")),
		int(r.get("import_qty", 2)),
		str(r.get("imports", "fish")),
		pay,
	]

static func interact_caravan_mule(vm, route_id: String, player: Node2D) -> bool:
	if vm == null or player == null:
		return false
	var inv = player.get("inventory")
	if not is_route_caravan_at_plaza(vm, route_id):
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🐪 Espera a que la caravana acampe en la plaza", Color.LIGHT_GRAY, -42.0)
		return false
	if send_player_shipment(vm, route_id, inv):
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📦🐪 ¡Cargaste tu remesa en la mula y recibiste la mercancía importada!", Color.AQUAMARINE, -44.0)
		return true
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("📦 No tienes la mercancía requerida o hoy ya cargaste una remesa en esta mula", Color.ORANGE_RED, -44.0)
	return false

static func process_caravan_route_exchange(vm, route_id: String) -> int:
	if vm == null:
		return 0
	var routes: Dictionary = trade_routes_of(vm)
	if not routes.has(route_id):
		return 0
	var r: Dictionary = routes[route_id]
	if not bool(r.get("active", false)):
		return 0
	var day_now: int = int(WorldClock.current_day) if WorldClock else 1
	if int(r.get("last_refill_day", -1)) != day_now:
		r["last_refill_day"] = day_now
		r["balance"] = mini(ROUTE_BALANCE_CAP, int(r.get("balance", 0)) + ROUTE_WEEKLY_REFILL)
	if int(r.get("last_exchange_day", -99)) == day_now:
		routes[route_id] = r
		return 0
	r["last_exchange_day"] = day_now
	var pay: int = int(r.get("tariff_gold", 8))
	if int(r.get("balance", 0)) < pay:
		routes[route_id] = r
		return 0
	var seller = vm.trade_npcs.get(VillageTrades.role_of(str(r.get("seller_role", "woodcutter"))))
	var buyer = vm.trade_npcs.get(VillageTrades.role_of(str(r.get("buyer_role", "farmer"))))
	if seller == null or not is_instance_valid(seller) or seller.is_dead:
		routes[route_id] = r
		return 0
	var exp_item: String = str(r.get("exports", "wood"))
	var exp_qty: int = int(r.get("export_qty", 2))
	if int(seller.shop_stock.get(exp_item, 0)) < exp_qty:
		routes[route_id] = r
		return 0
	seller.shop_stock[exp_item] = int(seller.shop_stock.get(exp_item, 0)) - exp_qty
	seller._sync_shop_stock_to_vm()
	var imp_item: String = str(r.get("imports", "fish"))
	var imp_qty: int = int(r.get("import_qty", 2))
	var dst = buyer if (buyer != null and is_instance_valid(buyer) and not buyer.is_dead) else seller
	dst.shop_stock[imp_item] = int(dst.shop_stock.get(imp_item, 0)) + imp_qty
	dst._sync_shop_stock_to_vm()
	r["balance"] = int(r.get("balance", 0)) - pay
	seller.personal_gold = maxi(0, seller.personal_gold) + (pay - 2)
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + 2
	var tariff: int = clampi(int(r.get("balance", 0)), 0, ROUTE_TOWN_TARIFF)
	r["balance"] = int(r["balance"]) - tariff
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + tariff
	var imp_pay: int = clampi(int(dst.personal_gold), 0, imp_qty)
	dst.personal_gold -= imp_pay
	r["balance"] = int(r["balance"]) + imp_pay
	routes[route_id] = r
	return 1

static func spawn_trade_caravan(vm, route_id: String, at_plaza: bool = false, silent: bool = false):
	if vm == null or not ROUTE_WEEKDAYS.has(route_id):
		return null
	var routes: Dictionary = trade_routes_of(vm)
	if not routes.has(route_id) or not bool((routes[route_id] as Dictionary).get("active", false)):
		return null
	if int(vm.merchant_suspension_days.get(route_id, 0)) > 0:
		return null
	var existing = get_route_caravan_npc(vm, route_id)
	var start_pos: Vector2 = CARAVAN_PLAZA_POS if at_plaza else RAID_GATE_POS
	if existing != null and is_instance_valid(existing):
		if at_plaza:
			existing.global_position = CARAVAN_PLAZA_POS
			existing.set_meta("at_plaza", true)
			existing._merchant_leaving = false
			var ex_mule = get_route_caravan_mule(vm, route_id)
			if ex_mule != null and is_instance_valid(ex_mule):
				ex_mule.global_position = CARAVAN_PLAZA_POS + Vector2(22.0, 4.0)
			process_caravan_route_exchange(vm, route_id)
		return existing
	var r: Dictionary = routes[route_id]
	var parent: Node = vm.entities_root if ("entities_root" in vm and is_instance_valid(vm.entities_root)) else vm
	var m_npc := VillageNPC.new()
	m_npc.name = "NPC_Caravan_" + route_id
	m_npc.trade_role = VillageNPC.TradeRole.TRAVELING_MERCHANT
	m_npc.merchant_id = route_id
	m_npc.npc_name = str(ROUTE_CARAVAN_NAMES.get(route_id, "Caravanero de " + str(r.get("name", route_id))))
	m_npc.npc_role = "Caravana de " + str(r.get("name", route_id))
	m_npc.personal_gold = 40
	m_npc.days_in_role = 7
	m_npc.tavern_social_pos = vm._tavern_social_pos
	parent.add_child(m_npc)
	var tex_path: String = "res://assests/world/village/npcs_64/sprite_casimir.png" if route_id != "sun_plain" else "res://assests/world/village/npcs_64/sprite_valeria.png"
	m_npc.setup_npc(vm._load_tex(tex_path), CARAVAN_PLAZA_POS, RAID_GATE_POS, {}, vm._tavern_social_pos, "none", "Ruta de " + str(r.get("name", route_id)))
	m_npc.global_position = start_pos
	m_npc.set_meta("at_plaza", at_plaza)
	m_npc._merchant_leaving = false

	var old_mule = get_route_caravan_mule(vm, route_id)
	if old_mule != null and is_instance_valid(old_mule):
		old_mule.queue_free()
	var mule := CaravanMule.new()
	parent.add_child(mule)
	mule.setup(vm, route_id, m_npc, start_pos + Vector2(22.0, 4.0))

	if at_plaza:
		process_caravan_route_exchange(vm, route_id)
	if not silent and vm.has_method("_hint_player"):
		vm._hint_player("🐪📦 Ha llegado la caravana de %s por el camino del este (en la plaza de 10:00 a 16:00)." % str(r.get("name", route_id)))
	return m_npc

static func despawn_trade_caravan(vm, route_id: String) -> void:
	if vm == null:
		return
	var mule = get_route_caravan_mule(vm, route_id)
	if mule != null and is_instance_valid(mule):
		if mule.get_parent():
			mule.get_parent().remove_child(mule)
		mule.queue_free()
	var m = get_route_caravan_npc(vm, route_id)
	if m != null and is_instance_valid(m) and not m.is_dead:
		if m.get_parent():
			m.get_parent().remove_child(m)
		m.queue_free()

static func update_caravan_merchant_ai(vm, merchant, delta: float) -> void:
	if vm == null or merchant == null or not is_instance_valid(merchant) or merchant.is_dead or merchant.is_downed:
		return
	var route_id: String = str(merchant.merchant_id)
	var h: int = int(WorldClock.current_hour) if WorldClock else 12
	if h >= 16 or h < 8:
		merchant._merchant_leaving = true
		merchant.set_meta("at_plaza", false)
		merchant.current_activity = VillageNPC.ActivityState.WORKING
		merchant._move_towards_point(RAID_GATE_POS, 78.0, delta)
		if merchant.global_position.distance_to(RAID_GATE_POS) <= 18.0:
			despawn_trade_caravan(vm, route_id)
		return
	merchant._merchant_leaving = false
	merchant.current_activity = VillageNPC.ActivityState.WORKING
	merchant._move_towards_point(CARAVAN_PLAZA_POS, 78.0, delta)
	if merchant.global_position.distance_to(CARAVAN_PLAZA_POS) <= 22.0 and not bool(merchant.get_meta("at_plaza", false)):
		merchant.set_meta("at_plaza", true)
		process_caravan_route_exchange(vm, route_id)

static func caravans_on_hour(vm, hour: int) -> void:
	if vm == null:
		return
	ensure_route_caravan_schedule(vm)
	var routes: Dictionary = trade_routes_of(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	var wd: int = int(WorldClock.get_weekday()) if (WorldClock != null and WorldClock.has_method("get_weekday")) else ((maxi(1, today) - 1) % 7)
	for r_id in routes.keys():
		var rid: String = str(r_id)
		if not ROUTE_WEEKDAYS.has(rid):
			continue
		var r: Dictionary = routes[r_id]
		if not bool(r.get("active", false)):
			continue
		var next_d: int = int(r.get("next_caravan_day", -1))
		if hour == 9:
			if next_d == today:
				spawn_trade_caravan(vm, rid, false, false)
			elif wd == int(ROUTE_WEEKDAYS[rid]) and next_d == today + 1:
				VillageChronicle.add(vm, "caravan_delayed", "La caravana de %s se retrasa a mañana: el camino estaba embarrado" % str(r.get("name", rid)), true)
				if vm.has_method("_hint_player"):
					vm._hint_player("🌧️🐪 La caravana de %s se retrasa a mañana: el camino estaba embarrado." % str(r.get("name", rid)))
		elif hour >= 10 and hour < 16 and next_d == today:
			var m = get_route_caravan_npc(vm, rid)
			if m == null:
				spawn_trade_caravan(vm, rid, true, true)
			elif not bool(m.get_meta("at_plaza", false)) and m.global_position.distance_to(CARAVAN_PLAZA_POS) <= 45.0:
				m.set_meta("at_plaza", true)
				process_caravan_route_exchange(vm, rid)
		elif hour == 16:
			var m_leave = get_route_caravan_npc(vm, rid)
			if m_leave != null:
				m_leave._merchant_leaving = true
				m_leave.set_meta("at_plaza", false)
			if next_d <= today:
				r["next_caravan_day"] = roll_next_caravan_day(rid, today + 1)
				routes[r_id] = r

static func open_trade_route(vm, route_id: String, inv = null) -> bool:
	if vm == null:
		return false
	var routes: Dictionary = trade_routes_of(vm)
	if not routes.has(route_id):
		return false
	var r: Dictionary = routes[route_id]
	if bool(r.get("active", false)):
		return false
	if inv != null:
		if int(inv.gold) < ROUTE_CHARTER_COST:
			return false
		inv.add_gold(-ROUTE_CHARTER_COST)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + ROUTE_CHARTER_COST
	r["active"] = true
	routes[route_id] = r
	ensure_route_caravan_schedule(vm)
	VillageChronicle.add(vm, "trade_route", "Se abrió la ruta comercial con %s" % str(r.get("name", route_id)), true)
	return true

static func send_player_shipment(vm, route_id: String, inv) -> bool:
	if vm == null or inv == null:
		return false
	var routes: Dictionary = trade_routes_of(vm)
	if not routes.has(route_id):
		return false
	var r: Dictionary = routes[route_id]
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	if not bool(r.get("active", false)) or int(r.get("last_ship_day", -99)) == today:
		return false
	if ROUTE_WEEKDAYS.has(route_id) and not is_route_caravan_at_plaza(vm, route_id):
		return false
	var exp_item: String = str(r.get("exports", "wood"))
	var exp_qty: int = int(r.get("export_qty", 2))
	var imp_item: String = str(r.get("imports", "fish"))
	var imp_qty: int = int(r.get("import_qty", 2))
	var pay: int = int(r.get("tariff_gold", 8)) + (4 if is_cart_near_player(vm, 60.0) else 0)
	if int(inv.items.get(exp_item, 0)) < exp_qty or int(r.get("balance", 0)) < pay:
		return false
	inv.remove_item(exp_item, exp_qty)
	inv.add_item(imp_item, imp_qty)
	r["balance"] = int(r.get("balance", 0)) - pay
	r["last_ship_day"] = today
	inv.add_gold(pay)
	# Arancel del pueblo de fuera para las arcas también en tus remesas.
	var tariff_p: int = clampi(int(r.get("balance", 0)), 0, ROUTE_TOWN_TARIFF)
	r["balance"] = int(r["balance"]) - tariff_p
	vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + tariff_p
	routes[route_id] = r
	return true

static func process_trade_routes(vm) -> int:
	if vm == null:
		return 0
	ensure_route_caravan_schedule(vm)
	var routes: Dictionary = trade_routes_of(vm)
	var exchanged: int = 0
	var monday: bool = WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 0
	for r_id in routes.keys():
		if ROUTE_WEEKDAYS.has(str(r_id)):
			continue
		var r: Dictionary = routes[r_id]
		if not bool(r.get("active", false)):
			continue
		var day_now: int = int(WorldClock.current_day) if WorldClock else 1
		if monday and int(r.get("last_refill_day", -1)) != day_now:
			r["last_refill_day"] = day_now
			r["balance"] = mini(ROUTE_BALANCE_CAP, int(r.get("balance", 0)) + ROUTE_WEEKLY_REFILL)
		var pay: int = int(r.get("tariff_gold", 8))
		if int(r.get("balance", 0)) < pay:
			continue
		var seller = vm.trade_npcs.get(VillageTrades.role_of(str(r.get("seller_role", "woodcutter"))))
		var buyer = vm.trade_npcs.get(VillageTrades.role_of(str(r.get("buyer_role", "farmer"))))
		if seller == null or not is_instance_valid(seller) or seller.is_dead:
			continue
		var exp_item: String = str(r.get("exports", "wood"))
		var exp_qty: int = int(r.get("export_qty", 2))
		if int(seller.shop_stock.get(exp_item, 0)) < exp_qty:
			continue
		seller.shop_stock[exp_item] = int(seller.shop_stock.get(exp_item, 0)) - exp_qty
		seller._sync_shop_stock_to_vm()
		var imp_item: String = str(r.get("imports", "fish"))
		var imp_qty: int = int(r.get("import_qty", 2))
		var dst = buyer if (buyer != null and is_instance_valid(buyer) and not buyer.is_dead) else seller
		dst.shop_stock[imp_item] = int(dst.shop_stock.get(imp_item, 0)) + imp_qty
		dst._sync_shop_stock_to_vm()
		r["balance"] = int(r.get("balance", 0)) - pay
		seller.personal_gold = maxi(0, seller.personal_gold) + (pay - 2)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + 2
		# Arancel del pueblo de fuera para las arcas (si su fondo lo permite).
		var tariff: int = clampi(int(r.get("balance", 0)), 0, ROUTE_TOWN_TARIFF)
		r["balance"] = int(r["balance"]) - tariff
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + tariff
		# El comprador del valle paga 1 de oro por unidad importada al pueblo de fuera.
		var imp_pay: int = clampi(int(dst.personal_gold), 0, imp_qty)
		dst.personal_gold -= imp_pay
		r["balance"] = int(r["balance"]) + imp_pay
		routes[r_id] = r
		exchanged += 1
	return exchanged

static func grid_state(vm) -> Dictionary:
	var st: Dictionary = state(vm)
	if not (st.get("grid", null) is Dictionary):
		st["grid"] = {}
	var g: Dictionary = st["grid"]
	var g_defs: Dictionary = {
		"sabotaged_days": 0,
		"overloaded_node": "",
		"last_op_day": -99,
		"lamps_disabled": false,
		"sprinkler_disabled": false,
	}
	for k in g_defs.keys():
		if not g.has(k):
			g[k] = g_defs[k]
	return g

static func is_grid_sabotaged(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = grid_state(vm)
	return int(g.get("sabotaged_days", 0)) > 0 or bool(g.get("lamps_disabled", false)) or bool(g.get("sprinkler_disabled", false))

static func is_lamps_powered(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = grid_state(vm)
	return not bool(g.get("lamps_disabled", false))

static func is_sprinkler_powered(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = grid_state(vm)
	return not bool(g.get("sprinkler_disabled", false))

## La red solo tiene corriente si el generador del campamento está encendido.
static func _generator_on() -> bool:
	if GameManager == null:
		return false
	var camp_st: Variant = GameManager.get_flag("player_campsite_state", null)
	return typeof(camp_st) == TYPE_DICTIONARY and bool((camp_st as Dictionary).get("generator_active", false))

static func sabotage_grid(vm, node_target: String = "all", check_risk: bool = false, saboteur: String = "") -> Dictionary:
	if vm == null:
		return {"ok": false, "caught": false}
	var g: Dictionary = grid_state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	g["last_op_day"] = today
	if check_risk and randf() < 0.30:
		vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
		return {"ok": false, "caught": true}
	var target: String = node_target if node_target in ["all", "lamps", "sprinkler"] else "all"
	g["overloaded_node"] = target
	g["saboteur"] = saboteur
	if target == "all":
		g["sabotaged_days"] = 2
		g["lamps_disabled"] = true
		g["sprinkler_disabled"] = true
	elif target == "lamps":
		g["sabotaged_days"] = maxi(1, int(g.get("sabotaged_days", 0)))
		g["lamps_disabled"] = true
	elif target == "sprinkler":
		g["sabotaged_days"] = maxi(1, int(g.get("sabotaged_days", 0)))
		g["sprinkler_disabled"] = true
	if GameManager != null and bool(g.get("lamps_disabled", false)):
		GameManager.set_flag("electric_grid_active", false)
	if GameManager != null:
		GameManager.set_flag("sprinkler_grid_disabled", bool(g.get("sprinkler_disabled", false)))
	vm._update_streetlights_glow()
	var desc_map: Dictionary = {
		"all": "el generador general",
		"lamps": "el circuito de farolas",
		"sprinkler": "la bomba eléctrica de riego",
	}
	VillageChronicle.add(vm, "grid_sabotage", "Alguien saboteó %s: saltaron chispas en el tendido eléctrico" % str(desc_map.get(target, "la red")), true)
	return {"ok": true, "caught": false, "target": target}

static func repair_grid(vm) -> bool:
	if vm == null:
		return false
	var g: Dictionary = grid_state(vm)
	g["sabotaged_days"] = 0
	g["overloaded_node"] = ""
	g["lamps_disabled"] = false
	g["sprinkler_disabled"] = false
	g["saboteur"] = ""
	if GameManager != null:
		GameManager.set_flag("electric_grid_active", _generator_on()) # Reparar no crea corriente si no hay generador
		GameManager.set_flag("sprinkler_grid_disabled", false)
	vm._update_streetlights_glow()
	return true

static func library_pos() -> Vector2:
	return VillageLots.building_center(LIBRARY_LOT)

static func reading_spot() -> Vector2:
	return library_pos() + Vector2(0, -16 if bool(VillageLots.lot_def(LIBRARY_LOT)["door_south"]) else 16)

# ---------------------------------------------------------------- mapa
static func ensure_lots(vm) -> void:
	for e in [[LIBRARY_LOT, "library", LIBRARY_TITLE], [SCHOOL_LOT, "school", SCHOOL_TITLE]]:
		var st: Dictionary = VillageLots.lot(vm, e[0])
		st["status"] = "built"
		st["kind"] = e[1]
		st["progress"] = 1.0
		st["title"] = e[2]
	sync_outpost_visuals(vm)

static func _clear_outpost_visuals(vm) -> void:
	if vm == null:
		return
	for nd in vm.get_meta("outpost_nodes", []):
		if is_instance_valid(nd):
			nd.queue_free()
	vm.set_meta("outpost_nodes", [])

static func sync_outpost_visuals(vm) -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	_clear_outpost_visuals(vm)
	var cap: Dictionary = VillageLots._capture_begin(vm)
	var op: Dictionary = outpost_state(vm)
	var founded: bool = bool(op.get("founded", false))
	var upgs: Dictionary = op.get("upgrades", {})
	var c: Vector2 = OUTPOST_CENTER
	# Extensión del camino del este hacia el Paso Fronterizo
	vm._add_rect_poly(Vector2(1512, 50), Vector2(36, 14), Color(0.46, 0.36, 0.24, 0.92), -3)
	if not founded:
		vm._add_rect_poly(c, Vector2(68, 72), Color(0.28, 0.34, 0.20, 0.45), -3)
		for p in [Vector2(-64, -68), Vector2(64, -68), Vector2(64, 68), Vector2(-64, 68)]:
			vm._add_rect_poly(c + p, Vector2(3, 5), Color(0.48, 0.32, 0.16, 1.0), -1)
		vm._add_rect_poly(OUTPOST_GATE_POS, Vector2(5, 8), Color(0.55, 0.36, 0.18, 1.0), -1)
		vm._add_title_label(c + Vector2(-95, -88), Vector2(190, 14), "🏕️ Solar Fronterizo «Puesto del Paso» [E: Fundar]", Color(0.95, 0.88, 0.62), 7)
	else:
		# Explanada empedrada y empalizada de troncos del Puesto del Paso
		vm._add_rect_poly(c, Vector2(76, 82), Color(0.36, 0.30, 0.22, 0.92), -2)
		vm._add_rect_poly(c + Vector2(0, -80), Vector2(76, 4), Color(0.42, 0.27, 0.14, 1.0), 1)
		vm._add_rect_poly(c + Vector2(0, 80), Vector2(76, 4), Color(0.42, 0.27, 0.14, 1.0), 1)
		vm._add_rect_poly(c + Vector2(74, 0), Vector2(4, 82), Color(0.42, 0.27, 0.14, 1.0), 1)
		vm._add_rect_poly(c + Vector2(-74, -50), Vector2(4, 30), Color(0.42, 0.27, 0.14, 1.0), 1)
		vm._add_rect_poly(c + Vector2(-74, 50), Vector2(4, 30), Color(0.42, 0.27, 0.14, 1.0), 1)
		# Cabaña de mando y arca de recaudación
		vm._add_rect_poly(c + Vector2(32, 0), Vector2(24, 20), Color(0.48, 0.32, 0.18, 1.0), -1)
		vm._add_rect_poly(c + Vector2(8, 0), Vector2(6, 4), Color(0.82, 0.68, 0.24, 1.0), 0)
		# Hoguera central del campamento
		vm._add_rect_poly(c + Vector2(-18, 0), Vector2(6, 6), Color(0.35, 0.35, 0.38, 1.0), -1)
		vm._add_rect_poly(c + Vector2(-18, 0), Vector2(4, 4), Color(1.0, 0.58, 0.18, 0.95), 0)
		if bool(upgs.get("sawmill", false)):
			vm._add_rect_poly(c + Vector2(-28, -52), Vector2(22, 14), Color(0.54, 0.36, 0.20, 1.0), -1)
			vm._add_title_label(c + Vector2(-78, -72), Vector2(100, 12), "🪚 Aserradero", Color(0.95, 0.88, 0.68), 7)
		if bool(upgs.get("granary", false)):
			vm._add_rect_poly(c + Vector2(-28, 52), Vector2(20, 14), Color(0.76, 0.62, 0.32, 1.0), -1)
			vm._add_title_label(c + Vector2(-78, 64), Vector2(100, 12), "🌾 Granero", Color(0.98, 0.90, 0.62), 7)
		if bool(upgs.get("watchtower", false)):
			vm._add_rect_poly(c + Vector2(-58, -58), Vector2(12, 12), Color(0.45, 0.34, 0.22, 1.0), 1)
			vm._add_title_label(c + Vector2(-108, -76), Vector2(100, 12), "🏹 Atalaya", Color(0.88, 0.94, 1.0), 7)
		vm._add_title_label(c + Vector2(-105, -96), Vector2(210, 14), "🏕️ «%s» [E: Arca / Mejoras]" % str(op.get("name", "Puesto del Paso")), Color(1.0, 0.92, 0.58), 8)
	vm.set_meta("outpost_nodes", VillageLots._capture_end(vm, cap)[0])
	if vm.has_method("refresh_world_stage_3d"):
		vm.refresh_world_stage_3d()

static func build(vm, id: String, st: Dictionary) -> void:
	var d: Dictionary = VillageLots.lot_def(id)
	var c: Vector2 = VillageLots.building_center(id)
	var props: String = "res://assests/Comprados/Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props_sprites/"
	var m: float = -1.0 if bool(d["door_south"]) else 1.0
	vm._construct_solid_building("building_" + str(st["kind"]), str(st["title"]), c, Vector2(128, 96), bool(d["door_south"]),
		"res://assests/world/village/floor_wood_planks.png", "res://assests/world/village/wall_timber_h.png",
		"res://assests/world/village/wall_timber_v.png", 42.0, 0.0, Color(0.86, 0.92, 1.0))
	match str(st["kind"]):
		"library":
			for sx in [-40, -14, 14, 40]: # Estanterías al fondo
				vm._add_rect_poly(c + Vector2(sx, 34 * m), Vector2(11, 4), Color(0.42, 0.26, 0.14, 1.0), -1)
				vm._add_rect_poly(c + Vector2(sx, 31 * m), Vector2(9, 1.5), Color(0.75, 0.30, 0.25, 1.0), 0)
			vm._spawn_decor_prop(props + "table_chairs_1.png", reading_spot(), Vector2(0.45, 0.45))
			vm._add_title_label(reading_spot() + Vector2(-50, -22), Vector2(100, 12), "📖 Leer un rato [E]", Color(0.9, 0.95, 1.0), 7)
		"school":
			for p in [Vector2(-30, 6), Vector2(0, 6), Vector2(30, 6), Vector2(-30, 26), Vector2(0, 26), Vector2(30, 26)]:
				vm._add_rect_poly(c + Vector2(p.x, p.y * m), Vector2(9, 5), Color(0.55, 0.38, 0.20, 1.0), -1) # Pupitres
			vm._add_rect_poly(c + Vector2(0, -26 * m), Vector2(30, 3), Color(0.15, 0.25, 0.18, 1.0), -1) # Pizarra
			vm.set_meta("school_sign", vm._add_title_label(c + Vector2(-80, 38 * m - 6), Vector2(160, 12), "Esperando alumnos", Color(0.8, 0.8, 0.8), 7)) # V9 lo actualiza

# ---------------------------------------------------------------- biblioteca
## VillagePlaces: alguien ha llegado a la biblioteca.
static func on_read(vm, n) -> void:
	var st: Dictionary = state(vm)
	st["readings"] = int(st["readings"]) + 1
	n.add_thought("Leí un rato en la biblioteca (+3)", 3.0)
	n.set_meta("read_day", int(WorldClock.current_day) if WorldClock else 1) # M16 «Lo que se lee de noche»

## El jugador pulsa E cerca de la mesa de lectura, las máquinas del Taller de Reparaciones o el asentamiento «Puesto del Paso». Devuelve true si la interacción era suya.
static func try_interact(vm, player, pos: Vector2) -> bool:
	if _try_outpost_interact(vm, player, pos):
		return true
	if pos.distance_to(TINKER_TERMINAL_POS) <= 26.0:
		var term_node: Node = vm.get_tree().get_first_node_in_group("tinker_terminal") if vm.is_inside_tree() else null
		open_terminal_menu(vm, term_node, player)
		return true
	if pos.distance_to(TINKER_GRID_PANEL_POS) <= 26.0:
		var panel_node: Node = vm.get_tree().get_first_node_in_group("tinker_grid_panel") if vm.is_inside_tree() else null
		open_grid_panel_menu(vm, panel_node, player)
		return true
	if VillageLots.lot(vm, LIBRARY_LOT).get("kind", "") != "library" or pos.distance_to(reading_spot()) > 26.0:
		return false
	var st: Dictionary = state(vm)
	var day: int = int(WorldClock.current_day) if WorldClock else 0
	if int(st["player_read_day"]) == day:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("📖 Hoy ya has leído bastante", Color.LIGHT_GRAY, -40.0)
		return true
	st["player_read_day"] = day
	st["readings"] = int(st["readings"]) + 1
	var skill: String = str(READ_SKILLS.pick_random())
	if player.has_method("add_skill_xp"):
		player.add_skill_xp(skill, READ_XP)
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("📖 Lees un buen rato y aprendes algo (+%d %s)" % [READ_XP, skill], Color.LIGHT_SKY_BLUE, -40.0)
	return true

static func _try_outpost_interact(vm, player, pos: Vector2) -> bool:
	if vm == null or player == null:
		return false
	if pos.distance_to(OUTPOST_GATE_POS) > 46.0 and pos.distance_to(OUTPOST_CENTER) > 58.0:
		return false
	var inv = player.get("inventory")
	var op: Dictionary = outpost_state(vm)
	if not bool(op.get("founded", false)):
		# Regla 3: gastar oro en el mundo pide una segunda E de confirmación.
		var can_found: bool = inv != null and int(inv.gold) >= OUTPOST_CHARTER_COST and int(inv.items.get("wood", 0)) >= 2 and int(inv.items.get("stone", 0)) >= 2
		if can_found and not vm.VillageHousing.press_twice(vm, "outpost_found"):
			if player.has_method("show_hint"):
				player.show_hint("🏕️❓ ¿Fundar el Puesto del Paso (-%d Oro, -2 Madera, -2 Piedra)? Pulsa E otra vez para confirmar." % OUTPOST_CHARTER_COST)
			return true
		if found_outpost(vm, inv):
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🏕️📜 ¡Has fundado el «Puesto del Paso» aquí mismo en el lindero este!", Color.GOLD, -44.0)
		else:
			if player.has_method("_spawn_floating_text"):
				player._spawn_floating_text("🏕️ Necesitas %d de oro, 2 Maderas y 2 Piedras para fundar el Puesto del Paso" % OUTPOST_CHARTER_COST, Color.ORANGE_RED, -44.0)
		return true
	var col: int = collect_outpost_treasury(vm, inv)
	if col > 0:
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("💰🏕️ Recaudaste %d de oro del arca del Puesto del Paso" % col, Color.GOLD, -44.0)
		return true
	var upgs: Dictionary = op.get("upgrades", {})
	for up_k in OUTPOST_UPGRADES.keys():
		if not bool(upgs.get(up_k, false)):
			if inv != null and int(inv.gold) >= OUTPOST_UPGRADE_COST and not vm.VillageHousing.press_twice(vm, "outpost_up:" + str(up_k)):
				if player.has_method("show_hint"):
					player.show_hint("🏗️❓ ¿Levantar %s en el Puesto del Paso (-%d Oro)? Pulsa E otra vez para confirmar." % [str(OUTPOST_UPGRADES[up_k]), OUTPOST_UPGRADE_COST])
				return true
			if upgrade_outpost(vm, str(up_k), null, inv):
				if player.has_method("_spawn_floating_text"):
					player._spawn_floating_text("🏗️🏕️ ¡Levantaste %s en el Puesto del Paso!" % str(OUTPOST_UPGRADES[up_k]), Color.GOLD, -44.0)
			else:
				if player.has_method("_spawn_floating_text"):
					player._spawn_floating_text("🏕️ Puesto del Paso (Colonos: %d/3 | Arca: %d oro) — %d de oro para levantar %s" % [(op.get("settlers", []) as Array).size(), int(op.get("treasury", 0)), OUTPOST_UPGRADE_COST, str(OUTPOST_UPGRADES[up_k])], Color.LIGHT_SKY_BLUE, -44.0)
			return true
	if player.has_method("_spawn_floating_text"):
		player._spawn_floating_text("🏕️✨ Puesto del Paso al completo (Colonos: %d/3 | Arca: %d oro)" % [(op.get("settlers", []) as Array).size(), int(op.get("treasury", 0))], Color.AQUAMARINE, -44.0)
	return true

# ---------------------------------------------------------------- mercado
static func is_market_day() -> bool:
	return WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == MARKET_WEEKDAY

static func is_market_open(vm) -> bool:
	return not (state(vm)["market_sellers"] as Dictionary).is_empty()

static func _surplus(n) -> int:
	var best: int = 0
	for k in n.shop_stock.keys():
		best = maxi(best, int(n.shop_stock[k]))
	return best

## 8 h del miércoles: quien tiene género de sobra baja a la plaza (primero los de las afueras, que no tienen
## clientela de paso).
static func open_market(vm) -> int:
	var st: Dictionary = state(vm)
	if is_market_open(vm):
		return 0
	var cands: Array = []
	for r in VillageNPC.SHOP_ROLES:
		var n = vm.trade_npcs.get(r)
		if n == null or not is_instance_valid(n) or n.is_dead or n.is_downed or n.sick_level >= 2 or vm.is_trade_sabotaged(int(r)):
			continue
		if _surplus(n) >= MARKET_MIN_STOCK and not n in cands: # Quien lleva dos negocios monta un solo puesto
			cands.append(n)
	if cands.is_empty():
		return 0
	cands.sort_custom(func(a, b): return a.work_position.distance_to(MARKET_SPOTS[0]) > b.work_position.distance_to(MARKET_SPOTS[0]))
	var sellers: Dictionary = {}
	for i in range(mini(cands.size(), MARKET_SPOTS.size())):
		var n = cands[i]
		var spot: Vector2 = MARKET_SPOTS[i]
		sellers[n.get_person_key()] = {"x": n.work_position.x, "y": n.work_position.y, "spot": i}
		n.work_position = spot
		n.add_thought("Hoy monto puesto en el mercado (+3)", 3.0)
		# Alquiler del puesto: sale de su bolsillo y va a las arcas (si no tiene, paga lo que tenga).
		var fee: int = clampi(int(n.personal_gold), 0, MARKET_STALL_FEE)
		if fee > 0:
			n.personal_gold -= fee
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + fee
			st["market_fees"] = int(st.get("market_fees", 0)) + fee
	st["market_sellers"] = sellers
	st["market_day"] = int(WorldClock.current_day) if WorldClock else 0
	st["markets_held"] = int(st["markets_held"]) + 1
	_draw_market(vm)
	return sellers.size()

static func close_market(vm) -> void:
	var st: Dictionary = state(vm)
	for n in _all_npcs(vm):
		var e = (st["market_sellers"] as Dictionary).get(n.get_person_key())
		if e != null:
			n.work_position = Vector2(float(e["x"]), float(e["y"]))
		if n.errand_kind == "market":
			n.end_errand()
	st["market_sellers"] = {}
	_clear_market(vm)

static func _draw_market(vm) -> void:
	_clear_market(vm)
	var cap: Dictionary = VillageLots._capture_begin(vm)
	for e in (state(vm)["market_sellers"] as Dictionary).values():
		var p: Vector2 = MARKET_SPOTS[int(e["spot"])]
		vm._add_rect_poly(p + Vector2(0, -10), Vector2(14, 4), Color(0.55, 0.36, 0.18, 1.0), -1) # Mesa
		vm._add_rect_poly(p + Vector2(0, -16), Vector2(15, 2), Color(0.85, 0.25, 0.22, 0.95), 0) # Toldo
	vm._add_title_label(Vector2(405, -4), Vector2(120, 12), "🧺 Mercado del Miércoles", Color(1.0, 0.9, 0.6), 7)
	vm.set_meta("market_nodes", VillageLots._capture_end(vm, cap)[0])

static func _clear_market(vm) -> void:
	for nd in vm.get_meta("market_nodes", []):
		if is_instance_valid(nd):
			nd.queue_free()
	vm.set_meta("market_nodes", [])

static func _sellers(vm) -> Array:
	var out: Array = []
	var sellers: Dictionary = state(vm)["market_sellers"]
	for n in _all_npcs(vm):
		if sellers.has(n.get_person_key()) and not n.is_dead:
			out.append(n)
	return out

static func _all_npcs(vm) -> Array:
	return vm.get_tree().get_nodes_in_group("village_npcs").filter(func(n): return n is VillageNPC and is_instance_valid(n))

static func _outpost_on_hour(vm, hour: int) -> void:
	if vm == null:
		return
	var op: Dictionary = outpost_state(vm)
	if not bool(op.get("founded", false)):
		return
	var settlers: Array = op.get("settlers", [])
	if settlers.is_empty():
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for i in range(settlers.size()):
		var pk: String = str(settlers[i])
		var sn = by_key.get(pk, null)
		if sn == null or not is_instance_valid(sn) or sn.is_dead:
			continue
		if hour >= 8 and hour < 17:
			if sn.errand_kind == "" and VillageNeeds.is_free(sn):
				var spot: Vector2 = OUTPOST_WORK_SPOTS[i % OUTPOST_WORK_SPOTS.size()]
				sn.start_errand("outpost_work", spot)
		elif sn.errand_kind == "outpost_work":
			sn.end_errand()

static func on_hour(vm, hour: int) -> void:
	raid_on_hour(vm, hour)
	_outpost_on_hour(vm, hour)
	caravans_on_hour(vm, hour)
	if hour == MARKET_OPEN and is_market_day():
		open_market(vm)
	elif hour >= MARKET_CLOSE and is_market_open(vm):
		close_market(vm)
		return
	if not is_market_open(vm) or hour >= MARKET_CLOSE - 1:
		return
	var sellers: Array = _sellers(vm)
	for n in VillageNeeds.living(vm):
		if n in sellers or not VillageNeeds.is_free(n) or n.personal_gold < 6 or randf() >= MARKET_VISIT_CHANCE:
			continue
		var s = sellers.pick_random()
		n.start_errand("market", s.work_position + Vector2(randf_range(-10, 10), 16))

## VillageNeeds.tick: un vecino llega al mercado; compra algo al puesto más cercano y charla con el vendedor.
static func on_market_arrived(vm, n) -> void:
	n.end_errand()
	var seller = null
	var best: float = INF
	for s in _sellers(vm):
		var d: float = n.global_position.distance_to(s.global_position)
		if d < best:
			best = d
			seller = s
	if seller == null or best > 80.0:
		return
	var item: String = ""
	for k in seller.shop_stock.keys():
		if int(seller.shop_stock[k]) > 0 and (item == "" or int(seller.shop_stock[k]) > int(seller.shop_stock[item])):
			item = str(k)
	var price: int = 7 if (VillageFame.is_master(vm, seller) and n.personal_gold >= 25) else 5
	if item == "" or n.personal_gold < price:
		return
	n.personal_gold -= price
	seller.personal_gold = maxi(0, seller.personal_gold) + price
	seller.shop_stock[item] = int(seller.shop_stock[item]) - 1
	seller._sync_shop_stock_to_vm()
	if VillageFame.is_master(vm, seller):
		var m_info: Dictionary = VillageFame.master_info(vm, seller)
		if int(m_info.get("stock", 0)) > 0:
			m_info["stock"] = maxi(0, int(m_info.get("stock", 1)) - 1)
			m_info["last_sale_day"] = int(WorldClock.current_day) if WorldClock else 1
		VillageFame.add_fame(vm, seller, 1, "Su puesto de autor triunfa en el mercado")
	var fam: String = str(n.family_id) if "family_id" in n else ""
	if fam != "" and vm.house_pantry.has(fam) and _is_food(item):
		vm.house_pantry[fam] = int(vm.house_pantry[fam]) + 1
	n.add_thought("Compré en el mercado (+3)", 3.0)
	n.modify_npc_relationship(seller, 2, "Le compré en el mercado", true)
	state(vm)["market_sales"] = int(state(vm)["market_sales"]) + 1

static func _is_food(item: String) -> bool:
	return item in ["bread", "country_stew", "cooked_meat", "raw_meat", "fish", "wheat", "carrot", "cabbage"]

## Al cargar: si la partida se guardó con el mercado montado, cada vendedor vuelve a su tienda.
static func after_load(vm) -> void:
	if is_market_open(vm):
		close_market(vm)
	restore_planted_trees(vm)
	sync_outpost_visuals(vm)
	# El caballo y la carreta vuelven a su sitio (o bajo/detrás del jugador si los llevabas al guardar)
	sync_player_horse(vm)
	sync_player_cart(vm)
	if "VillageUnderworld" in vm and vm.VillageUnderworld != null:
		vm.VillageUnderworld.sync_heist_visuals(vm)

# ---------------------------------------------------------------- arreglos
## Cada día: rutas comerciales, fertilidad forestal, árbol de investigación, incursiones y arreglos del Taller.
static func daily(vm) -> int:
	process_trade_routes(vm)
	process_outpost_daily(vm)
	restore_planted_trees(vm)
	var pl_d = VillageNeeds.player_of(vm)
	var inv_d = pl_d.get("inventory") if pl_d != null else null
	sync_main_story(vm, inv_d)
	var f_st: Dictionary = forest_state(vm)
	if int(f_st.get("soil_fertility", 0)) >= 2:
		f_st["soil_fertility"] = maxi(0, int(f_st.get("soil_fertility", 0)) - 1)
		var wc = vm.trade_npcs.get(VillageTrades.role_of("woodcutter"))
		if wc != null and is_instance_valid(wc) and not wc.is_dead:
			wc.shop_stock["wood"] = int(wc.shop_stock.get("wood", 0)) + 1
			wc._sync_shop_stock_to_vm()
		var frm = vm.trade_npcs.get(VillageTrades.role_of("farmer"))
		if frm != null and is_instance_valid(frm) and not frm.is_dead:
			frm.shop_stock["wheat"] = int(frm.shop_stock.get("wheat", 0)) + 1
			frm._sync_shop_stock_to_vm()
	# PL.1: Bonificaciones diarias de tecnologías desbloqueadas
	if has_tech(vm, "waterwheel_gears"):
		var bkr = vm.trade_npcs.get(VillageTrades.role_of("baker"))
		if bkr != null and is_instance_valid(bkr) and not bkr.is_dead:
			bkr.shop_stock["bread"] = int(bkr.shop_stock.get("bread", 0)) + 1
			bkr._sync_shop_stock_to_vm()
	# PL.2: Evolución de incursiones contra el pueblo
	var rd: Dictionary = raids_state(vm)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	var act_raid: Dictionary = rd.get("active_raid", {})
	if not act_raid.is_empty() and today > int(act_raid.get("day_due", today)):
		resolve_raid(vm, false, null) # Por si nadie estaba despierto a la hora del asalto
	elif act_raid.is_empty() and not RAIDS_ENABLED:
		rd["threat"] = 0 # Asaltos en pausa: nada de amenaza, avisos ni milicia
	elif act_raid.is_empty():
		# La amenaza sube solo si algo atrae a los bandidos y baja si el pueblo se ve bien defendido o pobre
		var lure: int = raid_lure(vm)
		var deterrent: int = int(float(defense_power(vm)) / 3.0)
		rd["threat"] = clampi(int(rd.get("threat", 0)) + lure - 1 - deterrent, 0, 100)
		if int(rd["threat"]) >= RAID_THREAT_WARN and randf() < float(int(rd["threat"]) - RAID_THREAT_WARN + 10) / 100.0:
			start_raid_warning(vm, "boars" if randf() < 0.3 else "bandits")
	var tinker = vm.trade_npcs.get(VillageTrades.role_of("tinker"))
	if tinker == null or not is_instance_valid(tinker) or tinker.is_dead or tinker.is_downed or vm.is_trade_sabotaged(VillageTrades.role_of("tinker")):
		return 0
	advance_research(vm, 1)
	if has_tech(vm, "voltaic_capacitors"):
		tinker.shop_stock["repair_kit"] = int(tinker.shop_stock.get("repair_kit", 0)) + 1
		tinker._sync_shop_stock_to_vm()
	var done: int = 0
	var g: Dictionary = grid_state(vm)
	if int(g.get("sabotaged_days", 0)) > 0 and int(tinker.shop_stock.get("repair_kit", 0)) > 0 and int(vm.town_state.get("treasury", 0)) >= REPAIR_PRICE:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - REPAIR_PRICE
		tinker.personal_gold = maxi(0, tinker.personal_gold) + REPAIR_PRICE
		tinker.shop_stock["repair_kit"] = int(tinker.shop_stock["repair_kit"]) - 1
		tinker._sync_shop_stock_to_vm()
		g["sabotaged_days"] = maxi(0, int(g.get("sabotaged_days", 0)) - 1)
		if int(g["sabotaged_days"]) <= 0:
			repair_grid(vm)
		done += 1
	for r in vm.shop_businesses.keys():
		if done >= REPAIRS_PER_DAY or int(tinker.shop_stock.get("repair_kit", 0)) <= 0:
			break
		var biz: Dictionary = vm.shop_businesses[r]
		if int(r) == int(tinker.trade_role) or int(biz.get("sabotaged_days", 0)) <= 0:
			continue
		var owner = vm.trade_npcs.get(r)
		if owner == null or not is_instance_valid(owner) or owner.is_dead or owner.personal_gold < REPAIR_PRICE:
			continue
		owner.personal_gold -= REPAIR_PRICE
		tinker.personal_gold = maxi(0, tinker.personal_gold) + REPAIR_PRICE
		tinker.shop_stock["repair_kit"] = int(tinker.shop_stock["repair_kit"]) - 1
		tinker._sync_shop_stock_to_vm()
		biz["sabotaged_days"] = maxi(0, int(biz["sabotaged_days"]) - 1)
		vm._refresh_shop_stall_visual(int(r))
		owner.add_thought("El arreglador me dejó el puesto mejor (+3)", 3.0)
		owner.modify_npc_relationship(tinker, 2, "Me arregló el puesto", true)
		done += 1
	state(vm)["repairs"] = int(state(vm)["repairs"]) + done
	return done

## Bloque PR: Inversión municipal autónoma cuando las arcas tienen superávit (> 350 de oro):
## financia defensa comunal ante amenazas, becas de investigación en el taller del ingeniero y patentes de rutas comerciales.
static func process_municipal_spending(vm) -> int:
	if vm == null:
		return 0
	var spent: int = 0
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	var st: Dictionary = state(vm)
	# 1. Defensa comunal si hay aviso de incursión o amenaza alta
	var rd: Dictionary = raids_state(vm)
	var treasury_val: int = int(vm.town_state.get("treasury", 0))
	if treasury_val >= 350 and int(rd.get("militia_bonus", 0)) < MILITIA_MAX_BONUS and (not (rd.get("active_raid", {}) as Dictionary).is_empty() or int(rd.get("threat", 0)) >= 30):
		vm.town_state["treasury"] = treasury_val - MILITIA_COST
		treasury_val -= MILITIA_COST
		spent += MILITIA_COST
		rd["militia_bonus"] = mini(MILITIA_MAX_BONUS, int(rd.get("militia_bonus", 0)) + 2)
		for g_n in _all_npcs(vm):
			if not g_n.is_dead and int(g_n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]:
				g_n.personal_gold += MILITIA_COST
				break
		VillageChronicle.add(vm, "militia_trained", "El ayuntamiento costeó barricadas y patrullas extra (%d de oro de las arcas)" % MILITIA_COST, true)
	# 2. Beca municipal de investigación al taller del ingeniero
	var rs: Dictionary = research_state(vm)
	var tinker = vm.trade_npcs.get(VillageTrades.role_of("tinker"))
	if treasury_val >= 480 and str(rs.get("active_tech", "")) == "" and tinker != null and is_instance_valid(tinker) and not tinker.is_dead and today - int(st.get("last_town_tech_day", -99)) >= 4:
		for t_id in TECH_TREE.keys():
			if has_tech(vm, str(t_id)):
				continue
			var td: Dictionary = TECH_TREE[t_id]
			var pre: String = str(td.get("prereq", ""))
			if pre != "" and not has_tech(vm, pre):
				continue
			var t_cost: int = int(td.get("cost_gold", 25))
			if treasury_val >= t_cost + 300:
				vm.town_state["treasury"] = treasury_val - t_cost
				treasury_val -= t_cost
				spent += t_cost
				tinker.personal_gold = maxi(0, int(tinker.personal_gold)) + t_cost
				rs["active_tech"] = str(t_id)
				rs["progress"] = 1
				st["last_town_tech_day"] = today
				VillageChronicle.add(vm, "tech_grant", "El ayuntamiento encargó al taller desarrollar «%s» (%d de oro de las arcas)" % [str(td["name"]), t_cost], true)
				break
	# 3. Apertura municipal de ruta comercial con capital de las arcas
	if treasury_val >= 540 and today - int(st.get("last_town_route_day", -99)) >= 5:
		var routes: Dictionary = trade_routes_of(vm)
		for r_id in routes.keys():
			var r: Dictionary = routes[r_id]
			if not bool(r.get("active", false)):
				vm.town_state["treasury"] = treasury_val - ROUTE_CHARTER_COST
				treasury_val -= ROUTE_CHARTER_COST
				spent += ROUTE_CHARTER_COST
				r["active"] = true
				r["balance"] = int(r.get("balance", 90)) + ROUTE_CHARTER_COST
				routes[r_id] = r
				ensure_route_caravan_schedule(vm)
				st["last_town_route_day"] = today
				VillageChronicle.add(vm, "trade_route", "El ayuntamiento financió la patente comercial con %s (%d de oro de las arcas)" % [str(r.get("name", r_id)), ROUTE_CHARTER_COST], true)
				break
	return spent

static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null:
		return
	var role_i: int = int(npc.trade_role)
	var today: int = int(WorldClock.current_day) if WorldClock else 1
	if role_i == int(VillageNPC.TradeRole.TINKER):
		# Bloque FIS2: manipular el cuadro eléctrico se hace en el cuadro físico de la pared exterior del taller, no hablando con el arreglador.
		if is_grid_sabotaged(vm):
			ch_arr.append({"label": "🛠️⚡ Ayudar a reparar el tendido eléctrico (-1 Bobina de Cobre, +%d Oro del arca)" % GRID_REPAIR_REWARD, "next": "END", "action": "culture_repair_grid"})
		# PL.1: Árbol de Investigación e Ingeniería
		var rs: Dictionary = research_state(vm)
		var t_choices: Array = []
		var act_t: String = str(rs.get("active_tech", ""))
		if act_t != "" and TECH_TREE.has(act_t):
			t_choices.append({"label": "🔩 Aportar 1 Chatarra al prototipo de %s (+2 avance)" % str(TECH_TREE[act_t]["name"]), "next": "END", "action": "culture_boost_tech"})
		for t_id in TECH_TREE.keys():
			if has_tech(vm, str(t_id)) or act_t != "":
				continue
			var td: Dictionary = TECH_TREE[t_id]
			var pre: String = str(td.get("prereq", ""))
			if pre != "" and not has_tech(vm, pre):
				continue
			t_choices.append({"label": "🔬 Financiar %s (-%d Oro al ingeniero, %s)" % [str(td["name"]), int(td["cost_gold"]), str(td["desc"])], "next": "END", "action": "culture_start_tech:" + str(t_id)})
		t_choices.append({"label": "⬅️ Volver", "next": "start"})
		ch_arr.append({"label": "🔬⚙️ Árbol de Investigación e Ingeniería", "next": "culture_research_menu"})
		diag["culture_research_menu"] = {
			"text": "«Con libros de la biblioteca, piezas de cobre y financiación puedo diseñar mejoras permanentes para todo el valle.»",
			"choices": t_choices,
		}
	if role_i in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]:
		var rd: Dictionary = raids_state(vm)
		if int(rd.get("militia_bonus", 0)) < MILITIA_MAX_BONUS:
			ch_arr.append({"label": "🛡️📯 Financiar barricadas y milicia contra incursiones (-%d Oro a las arcas, +2 Defensa)" % MILITIA_COST, "next": "END", "action": "culture_fund_militia"})
		var act_r: Dictionary = rd.get("active_raid", {})
		if not act_r.is_empty():
			ch_arr.insert(0, {"label": "⚔️🔥 Unirte a la defensa contra %s (llegan al atardecer por el este; recompensa si peleas)" % str(act_r.get("name", "Incursión")), "next": "END", "action": "culture_lead_defense"})
	if role_i == int(VillageNPC.TradeRole.RANCHER):
		if not has_horse(vm):
			ch_arr.append({"label": "🐎🪙 Comprar Caballo de Silla (-%d Oro al ganadero, velocidad y +15%% en expediciones)" % HORSE_COST, "next": "END", "action": "culture_buy_horse"})
		if not has_cart(vm):
			ch_arr.append({"label": "🛒 Comprar Carreta de Carga (-%d Oro al ganadero): la recoges en el rancho; caben 40 cosas" % CART_COST, "next": "END", "action": "culture_buy_cart"})
	if role_i in [int(VillageNPC.TradeRole.RANCHER), int(VillageNPC.TradeRole.TINKER), int(VillageNPC.TradeRole.TRAVELING_MERCHANT)]:
		var ex: Dictionary = exploration_state(vm)
		if int(ex.get("last_exp_day", -99)) != today:
			var ex_choices: Array = []
			for s_id in EXPLORATION_SITES.keys():
				var s_def: Dictionary = EXPLORATION_SITES[s_id]
				var cur_st: int = int((ex["sites"] as Dictionary).get(s_id, 0))
				ex_choices.append({"label": "🧭 Explorar %s [Etapa %d/%d] (-%d Oro en víveres)" % [str(s_def["name"]), cur_st, int(s_def["max_stages"]), EXPEDITION_COST], "next": "END", "action": "culture_expedition:" + str(s_id)})
			ex_choices.append({"label": "⬅️ Volver", "next": "start"})
			ch_arr.append({"label": "🗺️🧭 Organizar expedición de exploración (1/día)", "next": "culture_expedition_menu"})
			diag["culture_expedition_menu"] = {
				"text": "«Más allá de los lindes del valle quedan ruinas, grutas y atalayas con piezas antiguas y notas para la biblioteca.»",
				"choices": ex_choices,
			}
	if role_i == int(VillageNPC.TradeRole.WOODCUTTER) and can_plant_tree(vm):
		ch_arr.append({"label": "🌲🌱 Sembrar pino joven en el bosque (-1 Semilla de Cultivo, enriquece suelo y fauna)", "next": "END", "action": "culture_plant_tree"})
		ch_arr.append({"label": "🌲🪙 Comprar y plantar plantón de pino (-%d Oro al leñador, enriquece suelo y fauna)" % SAPLING_COST, "next": "END", "action": "culture_buy_sapling"})
	if role_i in [int(VillageNPC.TradeRole.TRAVELING_MERCHANT), int(VillageNPC.TradeRole.WOODCUTTER), int(VillageNPC.TradeRole.BAKER), int(VillageNPC.TradeRole.TAILOR)]:
		var routes: Dictionary = trade_routes_of(vm)
		var r_choices: Array = []
		for r_id in routes.keys():
			var r: Dictionary = routes[r_id]
			var r_name: String = str(r.get("name", r_id))
			if not bool(r.get("active", false)):
				r_choices.append({"label": "📜 Abrir ruta comercial con %s (-%d Oro de arancel municipal)" % [r_name, ROUTE_CHARTER_COST], "next": "END", "action": "culture_open_route:" + str(r_id)})
		if not r_choices.is_empty():
			r_choices.append({"label": "⬅️ Volver", "next": "start"})
			ch_arr.append({"label": "🗺️📦 Rutas comerciales con otros asentamientos", "next": "culture_routes_menu"})
			diag["culture_routes_menu"] = {
				"text": "«Las caravanas regulares conectan nuestro valle con los asentamientos vecinos y traen suministros a cambio de nuestros excedentes.»",
				"choices": r_choices,
			}
	# Bloque PO: Armas de fuego de chispa (con Herrero o Arreglador) y Terminal Lógica / Hackeo
	var pl_po = VillageNeeds.player_of(vm)
	var inv_po = pl_po.get("inventory") if pl_po != null else null
	if role_i in [int(VillageNPC.TradeRole.BLACKSMITH), int(VillageNPC.TradeRole.TINKER)]:
		if has_tech(vm, "reinforced_locks") and (inv_po == null or not inv_po.has_item("flintlock_pistol", 1)):
			ch_arr.append({"label": "🔫🛠️ Encargar Arcabuz de Chispa con 2 cargas de pólvora (-%d Oro)" % FIREARM_COST, "next": "END", "action": "culture_buy_firearm"})
		if has_tech(vm, "reinforced_locks") or (inv_po != null and inv_po.has_item("flintlock_pistol", 1)):
			ch_arr.append({"label": "🧨🪙 Comprar 2 Cargas de Pólvora Negra (-%d Oro)" % POWDER_PACK_COST, "next": "END", "action": "culture_buy_powder"})
	# Disparar desde la conversación quedó retirado (como el robo desde el diálogo): el arma se usa en las incursiones.
	# Bloque FIS2: la Terminal Lógica ya no se hackea hablando con el arreglador; es una máquina física dentro del taller (TINKER_TERMINAL_POS).
	# Bloque PP: Crear tu propio asentamiento fronterizo («Puesto del Paso») e Historia Principal (Panel L)
	var op: Dictionary = outpost_state(vm)
	if role_i in [int(VillageNPC.TradeRole.CARPENTER), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.WOODCUTTER)]:
		if not bool(op.get("founded", false)):
			ch_arr.append({"label": "🏕️📜 Fundar tu propio asentamiento «Puesto del Paso» (-%d Oro, -2 Madera, -2 Piedra)" % OUTPOST_CHARTER_COST, "next": "END", "action": "culture_found_outpost"})
		else:
			var upgs: Dictionary = op["upgrades"]
			for up_k in OUTPOST_UPGRADES.keys():
				if not bool(upgs.get(up_k, false)):
					ch_arr.append({"label": "🏗️🏕️ Levantar %s en tu asentamiento (-%d Oro)" % [str(OUTPOST_UPGRADES[up_k]), OUTPOST_UPGRADE_COST], "next": "END", "action": "culture_upgrade_outpost:" + str(up_k)})
			if int(op.get("treasury", 0)) > 6:
				ch_arr.append({"label": "💰🏕️ Recaudar excedente del arca de tu asentamiento (+%d Oro)" % (int(op.get("treasury", 0)) - 6), "next": "END", "action": "culture_collect_outpost"})
	if bool(op.get("founded", false)) and role_i == int(VillageNPC.TradeRole.UNEMPLOYED) and (op["settlers"] as Array).size() < 3 and not (npc.get_person_key() in (op["settlers"] as Array)):
		ch_arr.append({"label": "🤝🏕️ Reclutarle como colono para tu asentamiento «Puesto del Paso» (-%d Oro de adelanto)" % OUTPOST_SETTLER_BONUS, "next": "END", "action": "culture_recruit_settler"})
	if not bool(main_story_state(vm).get("completed", false)) and role_i in [int(VillageNPC.TradeRole.TINKER), int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.PRIEST)]:
		ch_arr.append({"label": "👑📜 Actualizar tu avance en la Historia Principal del Valle [Panel L]", "next": "END", "action": "culture_sync_main_story"})

static func _msg_actor(vm, npc, txt: String, col: Color, dy: float = -46.0) -> void:
	if npc != null and is_instance_valid(npc) and npc.has_method("_spawn_floating_text"):
		npc._spawn_floating_text(txt, col, dy)
		return
	var pl = VillageNeeds.player_of(vm)
	if pl != null and pl.has_method("_spawn_floating_text"):
		pl._spawn_floating_text(txt, col, dy)

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	if action_id.begins_with("culture_sabotage_grid:"):
		var g: Dictionary = grid_state(vm)
		var today: int = int(WorldClock.current_day) if WorldClock else 1
		if int(g.get("last_op_day", -99)) == today:
			_msg_actor(vm, npc, "⚡ Hoy ya manipulaste el cuadro eléctrico", Color.LIGHT_GRAY, -44.0)
			return
		var target: String = action_id.substr("culture_sabotage_grid:".length())
		# El arreglador o cualquier otro vecino despierto cerca (misma planta) puede verte tocar el cuadro eléctrico
		var pl_sab = VillageNeeds.player_of(vm)
		var sab_pos: Vector2 = pl_sab.global_position if pl_sab != null else TINKER_GRID_PANEL_POS
		var wit_sab = vm._find_conscious_witness_near(sab_pos, 120.0, npc) if vm.has_method("_find_conscious_witness_near") else null
		if wit_sab != null:
			g["last_op_day"] = today
			vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
			if "affinity" in wit_sab:
				wit_sab.affinity = clampi(int(wit_sab.affinity) - 15, -100, 100)
			if npc != null and is_instance_valid(npc) and "affinity" in npc and npc != wit_sab:
				npc.affinity = clampi(int(npc.affinity) - 15, -100, 100)
			_msg_actor(vm, npc, "🚨 ¡%s te vio manipular el cuadro eléctrico! (Búsqueda +1)" % str(wit_sab.npc_name), Color.ORANGE_RED, -46.0)
			return
		var res: Dictionary = sabotage_grid(vm, target, true, "player")
		if bool(res.get("caught", false)):
			var tink = npc if (npc != null and is_instance_valid(npc) and "affinity" in npc) else vm.trade_npcs.get(VillageTrades.role_of("tinker"))
			if tink != null and is_instance_valid(tink) and "affinity" in tink:
				tink.affinity = clampi(int(tink.affinity) - 15, -100, 100)
			_msg_actor(vm, npc, "🚨 «¡Eh! ¡Suelta esos cables! ¡Guardias!» (Búsqueda +1)", Color.ORANGE_RED, -46.0)
		else:
			_msg_actor(vm, npc, "⚡💥 ¡Chispazo! Saboteaste el nodo eléctrico (%s)" % target, Color.CYAN, -46.0)
	elif action_id == "culture_repair_grid":
		if inv == null or int(inv.items.get("copper_coil", 0)) <= 0:
			_msg_actor(vm, npc, "«Necesitamos al menos 1 Bobina de Cobre para empalmar la línea.»", Color.ORANGE_RED, -46.0)
			return
		inv.remove_item("copper_coil", 1)
		var own_mess: bool = str(grid_state(vm).get("saboteur", "")) == "player"
		repair_grid(vm)
		# Si el apagón lo provocaste tú, el ayuntamiento no paga por arreglarlo (sin bucle sabotear-cobrar)
		var pay: int = 0 if own_mess else mini(GRID_REPAIR_REWARD, maxi(0, int(vm.town_state.get("treasury", 0))))
		if pay > 0:
			vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) - pay
			inv.add_gold(pay)
		if npc != null and is_instance_valid(npc) and "affinity" in npc:
			npc.affinity = clampi(int(npc.affinity) + 10, -100, 100)
		_msg_actor(vm, npc, ("🛠️⚡ «¡Línea restablecida! Toma %d de oro del fondo municipal.»" % pay) if pay > 0 else "🛠️⚡ «¡Línea restablecida! Gracias por la ayuda.»", Color.AQUAMARINE, -46.0)
	elif action_id.begins_with("culture_start_tech:"):
		var t_id: String = action_id.substr("culture_start_tech:".length())
		if start_research(vm, t_id, npc, inv):
			npc.affinity = clampi(npc.affinity + 8, -100, 100)
			npc._spawn_floating_text("🔬⚙️ «¡Manos a la obra! Empezaré los planos de %s hoy mismo.»" % str(TECH_TREE[t_id]["name"]), Color.CYAN, -46.0)
		else:
			npc._spawn_floating_text("«No cumples los requisitos o te falta el oro para financiar el proyecto.»", Color.ORANGE_RED, -46.0)
	elif action_id == "culture_boost_tech":
		if inv == null or int(inv.items.get("bandit_scrap", 0)) <= 0:
			npc._spawn_floating_text("«Necesito al menos 1 Chatarra para acelerar el prototipo.»", Color.ORANGE_RED, -46.0)
			return
		inv.remove_item("bandit_scrap", 1)
		var done_t: bool = advance_research(vm, 2)
		npc.affinity = clampi(npc.affinity + 6, -100, 100)
		npc._spawn_floating_text("🔬✨ ¡Invento completado!" if done_t else "🔩⚙️ Prototipo acelerado (+2 avance)", Color.AQUAMARINE, -46.0)
	elif action_id == "culture_fund_militia":
		if int(raids_state(vm).get("militia_bonus", 0)) >= MILITIA_MAX_BONUS:
			npc._spawn_floating_text("«Las barricadas ya están levantadas; más no caben en las calles.»", Color.LIGHT_GRAY, -46.0)
			return
		if inv == null or int(inv.gold) < MILITIA_COST:
			npc._spawn_floating_text("«Necesitamos %d de oro para levantar barricadas y armar turnos.»" % MILITIA_COST, Color.ORANGE_RED, -46.0)
			return
		inv.add_gold(-MILITIA_COST)
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + MILITIA_COST
		var rd2: Dictionary = raids_state(vm)
		rd2["militia_bonus"] = int(rd2.get("militia_bonus", 0)) + 2
		npc.affinity = clampi(npc.affinity + 8, -100, 100)
		npc._spawn_floating_text("🛡️📯 «¡Barricadas listas! El pueblo resistirá mejor el próximo ataque (+2 Defensa).»", Color.GOLD, -46.0)
	elif action_id == "culture_lead_defense":
		# Ya no se resuelve hablando: te unes a la defensa y peleas en el camino del este cuando lleguen.
		npc.affinity = clampi(npc.affinity + 4, -100, 100)
		npc._spawn_floating_text("⚔️🛡️ «¡Contamos contigo! Llegan al atardecer por el camino del este. La recompensa es para quien pelee.»", Color.AQUAMARINE, -46.0)
	elif action_id == "culture_plant_tree":
		if inv == null or int(inv.items.get("crop_seeds", 0)) <= 0:
			npc._spawn_floating_text("«Necesitas al menos 1 Semilla de Cultivo para plantar un pino joven.»", Color.ORANGE_RED, -46.0)
			return
		if not can_plant_tree(vm):
			npc._spawn_floating_text("«Por hoy basta de plantar: el claro necesita descanso.»", Color.LIGHT_GRAY, -46.0)
			return
		inv.remove_item("crop_seeds", 1)
		plant_forest_tree(vm, "El forastero")
		npc.affinity = clampi(npc.affinity + 6, -100, 100)
		npc._spawn_floating_text("🌲🌱 «¡Buen ojo! Ese pino dará sombra, setas y cobijo a los venados.»", Color.SPRING_GREEN, -46.0)
	elif action_id == "culture_buy_sapling":
		if not can_plant_tree(vm):
			npc._spawn_floating_text("«Por hoy basta de plantar: el claro necesita descanso.»", Color.LIGHT_GRAY, -46.0)
			return
		if inv == null or int(inv.gold) < SAPLING_COST:
			npc._spawn_floating_text("«Necesito %d de oro por el plantón de vivero.»" % SAPLING_COST, Color.ORANGE_RED, -46.0)
			return
		inv.add_gold(-SAPLING_COST)
		npc.personal_gold += SAPLING_COST
		plant_forest_tree(vm, npc.npc_name)
		npc.affinity = clampi(npc.affinity + 6, -100, 100)
		npc._spawn_floating_text("🌲🌱 «Lo plantaremos en el claro sur. El bosque te lo agradecerá.»", Color.SPRING_GREEN, -46.0)
	elif action_id.begins_with("culture_open_route:"):
		var r_id: String = action_id.substr("culture_open_route:".length())
		if open_trade_route(vm, r_id, inv):
			npc.affinity = clampi(npc.affinity + 8, -100, 100)
			npc._spawn_floating_text("🗺️📜 ¡Ruta comercial abierta! Las caravanas ya cruzan el paso", Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("«Necesitas %d de oro para pagar la carta de arancel municipal.»" % ROUTE_CHARTER_COST, Color.ORANGE_RED, -46.0)
	elif action_id.begins_with("culture_ship_route:"):
		var r_id2: String = action_id.substr("culture_ship_route:".length())
		if send_player_shipment(vm, r_id2, inv):
			npc._spawn_floating_text("📦🪙 ¡Remesa enviada y mercancía importada recibida!", Color.AQUAMARINE, -46.0)
		else:
			npc._spawn_floating_text("«No tienes la mercancía requerida o hoy ya enviaste una remesa por esta ruta.»", Color.ORANGE_RED, -46.0)
	elif action_id == "culture_buy_horse":
		if buy_mount(vm, "horse", npc, inv):
			npc.affinity = clampi(npc.affinity + 8, -100, 100)
			npc._spawn_floating_text("🐎✨ «¡Buen corcel! Te llevará más rápido y seguro en tus expediciones.»", Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("«Necesitas %d de oro para llevarte el caballo de silla.»" % HORSE_COST, Color.ORANGE_RED, -46.0)
	elif action_id == "culture_buy_cart":
		if buy_mount(vm, "cart", npc, inv):
			npc.affinity = clampi(npc.affinity + 8, -100, 100)
			npc._spawn_floating_text("🛒✨ «¡Trato hecho! Tu carreta de carga te espera junto al corral del rancho.»", Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("«Necesitas %d de oro para llevarte la carreta de carga.»" % CART_COST, Color.ORANGE_RED, -46.0)
	elif action_id.begins_with("culture_expedition:"):
		var s_id2: String = action_id.substr("culture_expedition:".length())
		var exp_res: Dictionary = run_expedition(vm, s_id2, npc, inv)
		if not bool(exp_res.get("ok", false)):
			npc._spawn_floating_text("«Hoy ya saliste de expedición o te faltan %d de oro para los víveres.»" % EXPEDITION_COST, Color.ORANGE_RED, -46.0)
		elif bool(exp_res.get("won", false)):
			npc._spawn_floating_text("🧭✨ ¡Expedición exitosa! Hallaste 1 %s y apuntes para la biblioteca" % str(exp_res.get("item", "")), Color.AQUAMARINE, -46.0)
		else:
			npc._spawn_floating_text("🧭🌧️ La expedición tuvo que regresar por un derrumbe sin hallazgos", Color.LIGHT_GRAY, -46.0)
	elif action_id == "culture_buy_firearm":
		if buy_firearm(vm, npc, inv):
			npc.affinity = clampi(npc.affinity + 8, -100, 100)
			npc._spawn_floating_text("🔫🛠️ «¡Un arcabuz de chispa de cañón estriado! Incluye 2 cargas de pólvora.»", Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("«Necesitas %d de oro y haber investigado Cerraduras de Precisión.»" % FIREARM_COST, Color.ORANGE_RED, -46.0)
	elif action_id == "culture_buy_powder":
		if buy_powder_pack(vm, npc, inv):
			npc._spawn_floating_text("🧨🪙 Compraste 2 Cargas de Pólvora Negra (-%d Oro)" % POWDER_PACK_COST, Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("«Necesitas %d de oro para las cargas de pólvora.»" % POWDER_PACK_COST, Color.ORANGE_RED, -46.0)
	elif action_id.begins_with("culture_hack_terminal:"):
		var sub_id: String = action_id.substr("culture_hack_terminal:".length())
		var hres: Dictionary = hack_terminal(vm, sub_id, inv)
		if bool(hres.get("wait", false)):
			_msg_actor(vm, npc, "🖥️ El archivo policial se revisa a fondo: espera unos días antes de volver a purgarlo", Color.LIGHT_GRAY, -44.0)
		elif not bool(hres.get("ok", false)):
			_msg_actor(vm, npc, "🖥️ Hoy ya intentaste manipular la terminal lógica", Color.LIGHT_GRAY, -44.0)
		elif bool(hres.get("witnessed", false)):
			var w_node = hres.get("witness", null)
			var w_name: String = str(w_node.npc_name) if (w_node != null and is_instance_valid(w_node) and "npc_name" in w_node) else "Un vecino"
			if npc != null and is_instance_valid(npc) and "affinity" in npc and npc != w_node:
				npc.affinity = clampi(int(npc.affinity) - 15, -100, 100)
			_msg_actor(vm, npc, "🚨 ¡%s te vio manipulando la Terminal Lógica! (Búsqueda +1)" % w_name, Color.ORANGE_RED, -46.0)
		elif bool(hres.get("won", false)):
			_msg_actor(vm, npc, "🖥️✨ ¡Hackeo limpio en la terminal lógica (%s)!" % sub_id, Color.AQUAMARINE, -46.0)
		else:
			_msg_actor(vm, npc, "🖥️⚡ ¡Chispazo y alarma lógica! La guardia ha registrado el intento (Búsqueda +1)", Color.ORANGE_RED, -46.0)
	elif action_id == "culture_found_outpost":
		if found_outpost(vm, inv):
			npc._spawn_floating_text("🏕️📜 ¡Has fundado el asentamiento «Puesto del Paso» con 20 de oro en su arca inicial!", Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro, 2 de madera y 2 de piedra para fundar el asentamiento" % OUTPOST_CHARTER_COST, Color.ORANGE_RED, -46.0)
	elif action_id == "culture_recruit_settler":
		if recruit_outpost_settler(vm, npc, inv):
			npc._spawn_floating_text("🤝🏕️ «¡Cuenta conmigo en el Puesto del Paso!»", Color.SPRING_GREEN, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro y hueco en el asentamiento (máx. 3 colonos)" % OUTPOST_SETTLER_BONUS, Color.ORANGE_RED, -44.0)
	elif action_id.begins_with("culture_upgrade_outpost:"):
		var up_id: String = action_id.substr("culture_upgrade_outpost:".length())
		if upgrade_outpost(vm, up_id, npc, inv):
			npc._spawn_floating_text("🏗️🏕️ ¡Mejora construida en tu asentamiento (%s)!" % up_id, Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("Necesitas %d de oro para levantar esa estructura" % OUTPOST_UPGRADE_COST, Color.ORANGE_RED, -44.0)
	elif action_id == "culture_collect_outpost":
		var col: int = collect_outpost_treasury(vm, inv)
		if col > 0:
			npc._spawn_floating_text("💰🏕️ Recaudaste %d de oro del arca de tu asentamiento" % col, Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("El arca del asentamiento solo tiene la reserva para pagar a los colonos", Color.LIGHT_GRAY, -44.0)
	elif action_id == "culture_sync_main_story":
		var adv: int = sync_main_story(vm, inv)
		if adv > 0:
			npc._spawn_floating_text("👑📜 ¡Avanzaste %d capítulo(s) en la Historia Principal! Consulta el panel [L]." % adv, Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("👑📜 Consulta tu capítulo actual en la pestaña «Principal» del panel de misiones [L].", Color.LIGHT_SKY_BLUE, -46.0)
