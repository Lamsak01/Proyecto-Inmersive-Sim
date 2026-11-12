@tool
extends "res://scripts/systems/quests/QuestType.gd"

## M2 «Cuotas atrasadas»: quien debe su casa y ya ha fallado cuotas teme el desahucio. Puedes pagarle tú unas
## cuotas o pedirle al prestamista (noble o alcalde) que le perdone los recargos. Toca VillageLoans y los nobles.

const VillageLots = preload("res://scripts/systems/VillageLots.gd")
const VillageLoans = preload("res://scripts/systems/VillageLoans.gd")
const MIN_MISSED: int = 2
const PAY_QUOTAS: int = 3

func _init() -> void:
	id = "loan_trouble"
	priority = 15
	gold = 0 # No tiene con qué pagarte: te lo agradecerá de otra forma
	affinity = 22
	needs_alive_target = false

static func loan_of(vm: VillageManager, key: String) -> Dictionary:
	for l in VillageLots.lots():
		var st: Dictionary = VillageLots.lot(vm, str(l["id"]))
		if st.has("loan") and str(st.get("payer", "")) == key:
			return {"lot": str(l["id"]), "loan": st["loan"]}
	return {}

func find_daily_offer(vm: VillageManager, giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	var li: Dictionary = loan_of(vm, giver.get_person_key())
	if li.is_empty() or int(li["loan"]["missed"]) < MIN_MISSED:
		return {}
	var lk: String = str(li["loan"]["lender"])
	return {"target_key": lk if lk != "town" else "", "target_name": str(li["loan"]["lender_name"]), "lot": str(li["lot"])}

func texts(off: Dictionary) -> Dictionary:
	var ln: String = str(off.get("target_name", "el prestamista"))
	return {
		"title": "Que no me quiten la casa",
		"ask": "«Llevo días sin poder pagar la cuota de la casa a %s. Si fallo unas pocas más, me echan a la calle... ¿Se te ocurre algo?»" % ln,
		"desc": "%s debe su casa a %s y va atrasado/a con las cuotas. Puedes pagarle tú %d cuotas (habla con él/ella: 💰) o pedirle %s que le perdone los recargos (🙏; ayuda el Carisma o que te aprecie)." % [str(off.get("giver_name", "")), ln, PAY_QUOTAS, "al alcalde" if str(off.get("target_key", "")) == "" else "a " + ln],
	}

func is_done(vm: VillageManager, q: Dictionary) -> bool:
	if str(VillageLots.lot(vm, str(q["data"].get("lot", ""))).get("payer", "")) != str(q.get("giver_key", "")):
		return false # Le desahuciaron
	var li: Dictionary = loan_of(vm, str(q.get("giver_key", "")))
	return li.is_empty() or int(li["loan"]["missed"]) == 0

func progress_hint(_q: Dictionary) -> String:
	return "«Cada mañana que no pago es un paso más hacia la calle...»"

func failure_reason(vm: VillageManager, q: Dictionary, by_key: Dictionary) -> String:
	var base: String = super.failure_reason(vm, q, by_key)
	if base != "":
		return base
	if str(VillageLots.lot(vm, str(q["data"].get("lot", ""))).get("payer", "")) != str(q.get("giver_key", "")):
		return "Llegaste tarde: a %s le quitaron la casa." % str(q.get("giver_name", ""))
	return ""

func init_data(_vm: VillageManager, _giver: VillageNPC, off: Dictionary) -> Dictionary:
	return {"lot": str(off.get("lot", ""))}

## Quien puede perdonar: el noble prestamista o, si prestó el pueblo, el alcalde.
func _is_lender(vm: VillageManager, npc: VillageNPC, q: Dictionary) -> bool:
	var tk: String = str(q.get("target_key", ""))
	if tk != "":
		return npc.get_person_key() == tk
	return vm.VillageTown.is_mayor(vm, npc)

func add_world_dialogue(vm: VillageManager, npc: VillageNPC, q: Dictionary, _diag: Dictionary, ch_arr: Array) -> void:
	var li: Dictionary = loan_of(vm, str(q.get("giver_key", "")))
	if is_done(vm, q) or li.is_empty():
		return
	if npc.get_person_key() == str(q.get("giver_key", "")):
		var cost: int = mini(int(li["loan"]["owed"]), VillageLoans.INSTALLMENT * PAY_QUOTAS)
		ch_arr.insert(0, {"label": "💰 Pagarle tú %d cuotas de la casa (%d de oro)" % [PAY_QUOTAS, cost], "next": "END", "action": "quest_loan_pay:" + str(q["id"])})
	elif _is_lender(vm, npc, q):
		ch_arr.insert(0, {"label": "🙏 Pedirle que perdone los recargos de %s" % str(q.get("giver_name", "")), "next": "END", "action": "quest_loan_plead:" + str(q["id"])})

func on_extra_action(vm: VillageManager, qm: Node, npc: VillageNPC, action_id: String) -> bool:
	if not (action_id.begins_with("quest_loan_pay:") or action_id.begins_with("quest_loan_plead:")):
		return false
	var q: Dictionary = qm.get_quest(action_id.get_slice(":", 1))
	var li: Dictionary = loan_of(vm, str(q.get("giver_key", ""))) if not q.is_empty() else {}
	if li.is_empty():
		return true
	var loan: Dictionary = li["loan"]
	var player: Node = player_of(npc)
	if action_id.begins_with("quest_loan_pay:"):
		var cost: int = mini(int(loan["owed"]), VillageLoans.INSTALLMENT * PAY_QUOTAS)
		if not charge_player(player, npc, cost):
			return true
		VillageLoans._credit(vm, str(loan["lender"]), cost)
		loan["owed"] = int(loan["owed"]) - cost
		loan["missed"] = 0
		if int(loan["owed"]) <= 0:
			VillageLots.lot(vm, str(li["lot"])).erase("loan")
		npc._spawn_floating_text("🥹 «No sé cómo agradecértelo...»", Color.SPRING_GREEN, -46.0)
		qm.add_note(str(q["id"]), "Pagaste %d de oro de su deuda." % cost)
		return true
	# Pedir clemencia: Carisma 2+ o que el prestamista te aprecie (35+); los codiciosos ceden menos
	var greed: float = preload("res://scripts/data/TraitCatalog.gd").npc_tendency(npc, "generosity")
	var ok: bool = charisma(player) >= 2 or npc.affinity >= 35 or (npc.affinity >= 15 and greed > 0.3)
	if ok:
		loan["owed"] = maxi(int(float(loan.get("principal", 0)) / 2.0), int(loan["owed"]) - int(loan["missed"]) * VillageLoans.LATE_FEE)
		loan["missed"] = 0
		npc.modify_affinity(-3)
		npc._spawn_floating_text("😮‍💨 «Está bien... que empiece de cero con las cuotas.»", Color(0.8, 0.95, 1.0), -46.0)
		qm.add_note(str(q["id"]), "%s le perdonó los recargos." % npc.npc_name)
	else:
		npc.modify_affinity(-5)
		npc._spawn_floating_text("😒 «Una deuda es una deuda. Que pague.»", Color.CORAL, -46.0)
	return true
