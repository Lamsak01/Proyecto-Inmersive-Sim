extends Node

## Registro de misiones del jugador (autoload `QuestManager`).
## Categorías: "side" (secundarias, nacen de la vida de los vecinos) y "main" (historia principal, futura).
## Estados: "active", "completed", "failed". Las misiones ofrecidas aún no aceptadas no entran aquí.

signal quest_changed(quest_id: String)

const CATEGORY_SIDE: String = "side"
const CATEGORY_MAIN: String = "main"
const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"
const STATUS_FAILED: String = "failed"

var quests: Dictionary = {} # id -> Dictionary
var _next_id: int = 1
## Q2: Misiones que un vecino quiere pedir pero el jugador aún no ha aceptado. giver_key -> Dictionary
var offers: Dictionary = {}
## Q2: Día hasta el que un vecino no vuelve a pedir nada. giver_key -> int
var giver_cooldowns: Dictionary = {}

func _current_day() -> int:
	var wc = get_node_or_null("/root/WorldClock")
	return int(wc.current_day) if wc else 1

## Añade una misión activa. Campos útiles: category, type, title, description, giver_key, giver_name,
## target_key, target_name, data (Dictionary libre para cada tipo). Devuelve su id.
func add_quest(info: Dictionary) -> String:
	var qid: String = str(info.get("id", "q%d" % _next_id))
	_next_id += 1
	var q: Dictionary = info.duplicate(true)
	q["id"] = qid
	q["category"] = str(q.get("category", CATEGORY_SIDE))
	q["status"] = STATUS_ACTIVE
	q["day_started"] = _current_day()
	q["day_ended"] = -1
	if not q.has("notes"):
		q["notes"] = []
	if not q.has("data"):
		q["data"] = {}
	quests[qid] = q
	quest_changed.emit(qid)
	return qid

func get_quest(qid: String) -> Dictionary:
	return quests.get(qid, {})

func add_note(qid: String, note: String) -> void:
	if not quests.has(qid) or note == "":
		return
	(quests[qid]["notes"] as Array).append("Día %d: %s" % [_current_day(), note])
	quest_changed.emit(qid)

func _finish(qid: String, status: String, note: String) -> bool:
	if not quests.has(qid) or str(quests[qid].get("status", "")) != STATUS_ACTIVE:
		return false
	quests[qid]["status"] = status
	quests[qid]["day_ended"] = _current_day()
	if note != "":
		(quests[qid]["notes"] as Array).append("Día %d: %s" % [_current_day(), note])
	quest_changed.emit(qid)
	return true

func complete_quest(qid: String, note: String = "") -> bool:
	return _finish(qid, STATUS_COMPLETED, note)

func fail_quest(qid: String, note: String = "") -> bool:
	return _finish(qid, STATUS_FAILED, note)

## Lista de misiones filtrada; las activas primero y, dentro de cada grupo, las más recientes antes.
func get_quests(category: String = "", status: String = "") -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for q in quests.values():
		if category != "" and str(q.get("category", "")) != category:
			continue
		if status != "" and str(q.get("status", "")) != status:
			continue
		res.append(q)
	res.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var aa: bool = str(a.get("status", "")) == STATUS_ACTIVE
		var ba: bool = str(b.get("status", "")) == STATUS_ACTIVE
		if aa != ba:
			return aa
		return int(a.get("day_started", 0)) > int(b.get("day_started", 0))
	)
	return res

func get_active_quests(category: String = "") -> Array[Dictionary]:
	return get_quests(category, STATUS_ACTIVE)

func set_offer(giver_key: String, offer: Dictionary) -> void:
	offers[giver_key] = offer
	quest_changed.emit("")

func remove_offer(giver_key: String) -> void:
	if offers.erase(giver_key):
		quest_changed.emit("")

## Misión activa que pidió este vecino (vacía si no hay).
func get_active_quest_by_giver(giver_key: String) -> Dictionary:
	for q in quests.values():
		if str(q.get("status", "")) == STATUS_ACTIVE and str(q.get("giver_key", "")) == giver_key:
			return q
	return {}

func clear_all() -> void:
	quests.clear()
	offers.clear()
	giver_cooldowns.clear()
	_next_id = 1
	quest_changed.emit("")

func to_save_dict() -> Dictionary:
	return {"quests": quests.duplicate(true), "next_id": _next_id, "offers": offers.duplicate(true), "giver_cooldowns": giver_cooldowns.duplicate(true)}

func from_save_dict(data: Dictionary) -> void:
	quests.clear()
	var saved: Variant = data.get("quests", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for k in saved.keys():
			if typeof(saved[k]) == TYPE_DICTIONARY:
				var q: Dictionary = (saved[k] as Dictionary).duplicate(true)
				# JSON guarda los números como decimales
				for f in ["day_started", "day_ended"]:
					q[f] = int(q.get(f, -1))
				quests[str(k)] = q
	_next_id = maxi(int(data.get("next_id", 1)), quests.size() + 1)
	offers = (data.get("offers", {}) as Dictionary).duplicate(true) if typeof(data.get("offers", {})) == TYPE_DICTIONARY else {}
	giver_cooldowns.clear()
	var cds: Variant = data.get("giver_cooldowns", {})
	if typeof(cds) == TYPE_DICTIONARY:
		for k in cds.keys():
			giver_cooldowns[str(k)] = int(cds[k])
	quest_changed.emit("")
