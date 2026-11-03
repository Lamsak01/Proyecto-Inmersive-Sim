@tool
extends RefCounted

## Crónica del pueblo (bloques C, `docs/PLAN_CRONICA.md`). Libro de historia que se escribe solo; panel con la tecla O.
## Vive en `VillageManager.chronicle` (los `MAX_ENTRIES` últimos sucesos) y se guarda con la partida.
## Regla: el jugador solo ve lo que podría saber (lo público, lo suyo, lo que vio de cerca o le contaron).
## `SHOW_ALL_DEBUG` = true mientras el juego está en pruebas: se ve todo y lo secreto lleva 🔒.

const MAX_ENTRIES: int = 160
const SHOW_ALL_DEBUG: bool = true # Poner en false para la versión final
const WITNESS_RADIUS: float = 170.0

## Sucesos que no se apuntan (demasiado frecuentes para ser historia).
const SKIP_TYPES: Array[String] = ["hangout"]
## Lo sabe todo el pueblo al momento.
const PUBLIC_TYPES: Array[String] = ["couple", "breakup", "couple_reconciled", "arrival", "departure", "bereavement_ended", "fight", "feud", "reconciliation", "date", "death_found", "case_closed"]
## Lo ha hecho el jugador: lo sabe siempre.
const PLAYER_TYPES: Array[String] = ["player_gossip", "player_mediation", "player_matchmaking", "player_slander", "quest_done", "quest_failed"]

const CATEGORIES: Array[String] = ["all", "love", "conflict", "death", "people", "player"]
const CATEGORY_NAMES: Dictionary = {"all": "📖 Todo", "love": "💞 Amor", "conflict": "💢 Peleas y roces", "death": "💀 Muertes y crímenes", "people": "🧳 Llegadas y marchas", "player": "🧑 Tú"}
const TYPE_CATEGORY: Dictionary = {
	"couple": "love", "breakup": "love", "couple_reconciled": "love", "rejection": "love", "jealousy": "love", "date": "love",
	"romance_interest": "love", "romance_flirt": "love", "romance_dating": "love", "romance_fizzle": "love", "bereavement_ended": "love",
	"fight": "conflict", "feud": "conflict", "reconciliation": "conflict", "npc_slander": "conflict",
	"widowed": "death", "death_found": "death", "case_closed": "death",
	"arrival": "people", "departure": "people",
	"player_gossip": "player", "player_mediation": "player", "player_matchmaking": "player", "player_slander": "player", "quest_done": "player", "quest_failed": "player",
}
const TYPE_ICON: Dictionary = {
	"couple": "💑", "breakup": "💔", "couple_reconciled": "💞", "rejection": "💔", "jealousy": "😠", "date": "🌹",
	"romance_interest": "💗", "romance_flirt": "😊", "romance_dating": "💞", "romance_fizzle": "🥀", "bereavement_ended": "🕯️",
	"fight": "👊", "feud": "⚡", "reconciliation": "🤝", "npc_slander": "🗣️", "widowed": "🖤", "death_found": "💀", "case_closed": "⚖️",
	"arrival": "🧳", "departure": "🚪", "player_gossip": "🗣️", "player_mediation": "🕊️", "player_matchmaking": "💘",
	"player_slander": "🐍", "quest_done": "✅", "quest_failed": "❌",
}

static func _now() -> Dictionary:
	return {
		"day": int(WorldClock.current_day) if WorldClock else 1,
		"hour": int(WorldClock.current_hour) if WorldClock else 12,
		"minute": int(WorldClock.current_minute) if WorldClock else 0,
	}

## Añade una línea a la crónica. `known`: si el jugador ya lo sabe. `ev_uid`: suceso social del que viene (o −1).
static func add(vm: VillageManager, type_str: String, text: String, known: bool, ev_uid: int = -1, extra: Dictionary = {}) -> Dictionary:
	if vm == null or type_str in SKIP_TYPES or text == "":
		return {}
	var e: Dictionary = _now()
	e["type"] = type_str
	e["text"] = text
	e["known"] = known
	e["ev_uid"] = ev_uid
	for k in extra.keys():
		e[k] = extra[k]
	vm.chronicle.append(e)
	while vm.chronicle.size() > MAX_ENTRIES:
		vm.chronicle.remove_at(0)
	return e

## Cada suceso social entra también en la crónica. Lo sabe el jugador si es público, suyo, o si estaba cerca.
static func on_social_event(vm: VillageManager, ev: Dictionary, actor: Node = null, target: Node = null) -> void:
	var t: String = str(ev.get("type", ""))
	if t in SKIP_TYPES:
		return
	var known: bool = t in PUBLIC_TYPES or t in PLAYER_TYPES or _player_near(vm, actor) or _player_near(vm, target)
	var txt: String = str(ev.get("summary", ""))
	if txt == "":
		txt = "%s %s" % [str(ev.get("actor_name", "")), t]
	add(vm, t, txt, known, int(ev.get("uid", -1)))

static func _player_near(vm: VillageManager, n: Node) -> bool:
	if n == null or not is_instance_valid(n) or not (n is Node2D):
		return false
	var p = vm.get_tree().get_first_node_in_group("player") if vm.is_inside_tree() else null
	return p != null and is_instance_valid(p) and (p as Node2D).global_position.distance_to((n as Node2D).global_position) <= WITNESS_RADIUS

## El jugador se entera de un suceso social (se lo cuentan, lo ve...): su línea pasa a verse.
static func learn_event(vm: VillageManager, ev_uid: int) -> void:
	if ev_uid < 0:
		return
	for e in vm.chronicle:
		if int(e.get("ev_uid", -1)) == ev_uid:
			e["known"] = true

## Al preguntar a `npc` por las novedades: lo que te cuenta pasa a la crónica.
static func learn_news_from(vm: VillageManager, npc: VillageNPC) -> void:
	for ev in vm.get_news_known_by(npc):
		learn_event(vm, int(ev.get("uid", -1)))

## Líneas visibles de una categoría, de la más nueva a la más antigua.
static func visible_entries(vm: VillageManager, category: String = "all", show_all: bool = SHOW_ALL_DEBUG) -> Array:
	var res: Array = []
	if vm == null:
		return res
	for i in range(vm.chronicle.size() - 1, -1, -1):
		var e: Dictionary = vm.chronicle[i]
		if not show_all and not bool(e.get("known", false)):
			continue
		if category != "all" and str(TYPE_CATEGORY.get(str(e.get("type", "")), "")) != category:
			continue
		res.append(e)
	return res

static func line_text(e: Dictionary, show_lock: bool = SHOW_ALL_DEBUG) -> String:
	var lock: String = "🔒 " if show_lock and not bool(e.get("known", false)) else ""
	return "%02d:%02d — %s%s %s" % [int(e.get("hour", 0)), int(e.get("minute", 0)), lock, str(TYPE_ICON.get(str(e.get("type", "")), "•")), str(e.get("text", ""))]

## Partidas sin crónica: se empieza con lo que quede en el registro social (lo público como sabido).
static func seed_from_social_log(vm: VillageManager) -> void:
	vm.chronicle.clear()
	for ev in vm.social_event_log:
		var t: String = str(ev.get("type", ""))
		if t in SKIP_TYPES:
			continue
		var e: Dictionary = {"day": int(ev.get("day", 1)), "hour": int(ev.get("hour", 12)), "minute": int(ev.get("minute", 0)), "type": t,
			"text": str(ev.get("summary", "")), "known": t in PUBLIC_TYPES or t in PLAYER_TYPES, "ev_uid": int(ev.get("uid", -1))}
		vm.chronicle.append(e)
	while vm.chronicle.size() > MAX_ENTRIES:
		vm.chronicle.remove_at(0)

## Misiones: al cumplirse o fallar, una línea (una sola vez por misión).
static func on_quest_changed(vm: VillageManager, q: Dictionary) -> void:
	var st: String = str(q.get("status", ""))
	if not st in ["completed", "failed"]:
		return
	var qid: String = str(q.get("id", ""))
	for e in vm.chronicle:
		if str(e.get("quest_id", "")) == qid:
			return
	var t: String = "quest_done" if st == "completed" else "quest_failed"
	var txt: String = ("Cumpliste la misión «%s»" if st == "completed" else "Fallaste la misión «%s»") % str(q.get("title", "Misión"))
	add(vm, t, txt, true, -1, {"quest_id": qid})
