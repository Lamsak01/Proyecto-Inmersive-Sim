@tool
extends RefCounted

## Base de un tipo de misión secundaria de vecinos. Cada tipo vive en `scripts/systems/quests/types/`
## y se da de alta con una línea en `QuestRegistry.gd`. Guía completa en `docs/MISIONES.md`.
##
## Ciclo de vida (lo lleva `VillageQuests.gd`, igual para todos los tipos):
##   oferta (❗ sobre quien la pide) → aceptar en el diálogo → misión activa en el panel (L)
##   → `is_done` → volver con quien la pidió y cobrar (`on_turn_in`) → completada.
##   Falla si `failure_reason` devuelve un motivo. Rechazar/abandonar/cobrar/fallar → el vecino espera unos días.

## Identificador interno; se guarda en las partidas, no cambiarlo una vez publicado.
var id: String = ""
## "daily": lo busca el sorteo diario con `find_daily_offer`. "event": lo crea un suceso del mundo (asesinato, rumor...).
var trigger: String = "daily"
## Orden en el sorteo diario: el primer tipo que encuentre oferta para un vecino gana (menor = antes).
var priority: int = 50
var gold: int = 20
var affinity: int = 8
## Si la misión pierde sentido cuando muere el vecino objetivo (`target_key`).
var needs_alive_target: bool = true

# --- Lo que normalmente redefine cada tipo ---------------------------------------------------

## Solo tipos "daily": oferta que haría `giver` hoy, o {} si ninguna. Debe incluir "target_key" y "target_name"
## (pueden ir vacíos) y cualquier dato extra. `ctx` trae cálculos compartidos (p. ej. "worst" y "enmity_choice").
func find_daily_offer(_vm: VillageManager, _giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	return {}

## {"title", "ask" (lo que dice al pedirlo), "desc" (texto del panel)}.
func texts(_off: Dictionary) -> Dictionary:
	return {"title": id, "ask": "«¿Me ayudas?»", "desc": ""}

## Datos propios de la misión al aceptarla (se guardan en q["data"]).
func init_data(_vm: VillageManager, _giver: VillageNPC, _off: Dictionary) -> Dictionary:
	return {}

func is_done(_vm: VillageManager, _q: Dictionary) -> bool:
	return false

## Lo que dice quien la pidió mientras aún no está hecha.
func progress_hint(_q: Dictionary) -> String:
	return "«¿Cómo va eso?»"

## Nodo de diálogo cuando ya está hecha: texto y opciones (las de cobrar usan la acción "quest_turn_in[:modo...]").
func done_dialogue(_vm: VillageManager, _q: Dictionary) -> Dictionary:
	return {"text": "«¡Gracias! Sabía que podía contar contigo.»", "choices": [{"label": "💰 Cobrar", "next": "END", "action": "quest_turn_in"}]}

## Al cobrar. `action_full` es la acción completa elegida (p. ej. "quest_turn_in:lie_good").
func on_turn_in(_vm: VillageManager, qm: Node, giver: VillageNPC, player: Node, q: Dictionary, _action_full: String) -> void:
	pay_and_complete(qm, giver, player, q, gold, affinity)

## Motivo por el que falla hoy, o "" si sigue en pie. Por defecto: muere quien la pidió o el objetivo.
func failure_reason(_vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var giver: VillageNPC = by_key.get(str(q.get("giver_key", "")), null)
	if giver == null or giver.is_dead:
		return "%s ha muerto." % str(q.get("giver_name", "Quien te lo pidió"))
	if needs_alive_target:
		var tgt: VillageNPC = by_key.get(str(q.get("target_key", "")), null)
		if tgt == null or tgt.is_dead:
			return "%s ha muerto; ya no hay nada que hacer." % str(q.get("target_name", "El otro vecino"))
	return ""

## El jugador acaba de convencer a `listener` de algo sobre `target` (modo "good", "bad", "peace" o "match").
func on_player_influence(_vm: VillageManager, _qm: Node, _q: Dictionary, _listener: VillageNPC, _target: VillageNPC, _mode: String) -> void:
	pass

## Opciones extra en el diálogo de OTROS vecinos mientras la misión está activa (p. ej. preguntar por un rumor).
func add_world_dialogue(_vm: VillageManager, _npc: VillageNPC, _q: Dictionary, _diag: Dictionary, _ch_arr: Array) -> void:
	pass

## Acciones de diálogo propias ("quest_<algo>:..."). Devuelve true si la ha gestionado.
func on_extra_action(_vm: VillageManager, _qm: Node, _npc: VillageNPC, _action_id: String) -> bool:
	return false

# --- Ayudas comunes --------------------------------------------------------------------------

static func day() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func has_trait(npc: VillageNPC, traits: Array[String]) -> bool:
	if npc == null or npc.person_profile == null:
		return false
	for t in npc.person_profile.personality:
		if str(t) in traits:
			return true
	return false

static func pay_and_complete(qm: Node, giver: VillageNPC, player: Node, q: Dictionary, gold_v: int, affinity_v: int, extra_note: String = "") -> void:
	if gold_v > 0 and player != null and "inventory" in player and player.inventory:
		player.inventory.add_gold(gold_v)
	giver.modify_affinity(affinity_v)
	var note: String = ("%s te pagó %d de oro." % [giver.npc_name, gold_v]) if gold_v > 0 else ""
	if extra_note != "":
		note = (extra_note + " " + note).strip_edges()
	qm.complete_quest(str(q["id"]), note)
	giver._spawn_floating_text("✅ Misión completada" + (" (+%d Oro)" % gold_v if gold_v > 0 else ""), Color.SPRING_GREEN, -36.0)
