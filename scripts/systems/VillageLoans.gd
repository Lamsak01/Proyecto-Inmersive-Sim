@tool
extends RefCounted

## H: casas a plazos con interés. Quien no tiene casa y tiene la entrada puede encargarla; el resto lo presta el pueblo
## (si a las arcas les sobra) o, si no, el noble más rico, que se queda con los intereses. Cada día se paga una cuota;
## si no llega, la deuda sube y el prestamista se molesta; tras varios impagos seguidos, la casa pasa al prestamista y
## sus moradores se van. El préstamo vive en el estado del solar (`lots_state[id]["loan"]`), así que se guarda solo.

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageLots = preload("res://scripts/systems/VillageLots.gd")

const DOWN_PAYMENT: int = 15
const INTEREST: float = 0.25
const INSTALLMENT: int = 3
const LATE_FEE: int = 1
const MAX_MISSED: int = 5
const TOWN_RESERVE: int = 40 # lo que las arcas no prestan
const NOBLE_KEEP: int = 50 # lo que el noble no presta

## ¿Quién presta `amount`? {"key": "town", "name": "el pueblo"} o {"key": <clave del noble>, "name": ..., "npc": noble}; {} si nadie.
static func find_lender(vm, amount: int) -> Dictionary:
	if int(vm.town_state.get("treasury", 0)) >= amount + TOWN_RESERVE:
		return {"key": "town", "name": "el pueblo"}
	var best = null
	for n in vm.VillageNobility.nobles(vm):
		if n.is_downed or int(n.personal_gold) < amount + NOBLE_KEEP:
			continue
		if best == null or n.personal_gold > best.personal_gold:
			best = n
	if best == null:
		return {}
	return {"key": best.get_person_key(), "name": str(best.npc_name), "npc": best}

## Prepara el préstamo para que `buyer` (con la ayuda de su pareja, si la hay) pague `cost`. No mueve oro todavía.
static func arrange(vm, buyer, mate, cost: int) -> Dictionary:
	var own: int = int(buyer.personal_gold) + (int(mate.personal_gold) if mate != null else 0)
	if own < DOWN_PAYMENT:
		return {}
	var down: int = mini(own - 5, cost - 1) # se quedan con algo para comer
	if down < DOWN_PAYMENT:
		down = DOWN_PAYMENT
	var principal: int = cost - down
	var lender: Dictionary = find_lender(vm, principal)
	if lender.is_empty():
		return {}
	lender["principal"] = principal
	lender["down"] = down
	return lender

## Entrega el dinero prestado al comprador (y pone la parte de la pareja) para que pueda pagar la obra.
static func disburse(vm, info: Dictionary, buyer, mate) -> void:
	var principal: int = int(info["principal"])
	if str(info["key"]) == "town":
		vm.town_state["treasury"] = int(vm.town_state["treasury"]) - principal
	else:
		info["npc"].personal_gold -= principal
	buyer.personal_gold += principal
	var need: int = int(info["down"]) - int(buyer.personal_gold - principal)
	if need > 0 and mate != null:
		mate.personal_gold -= need
		buyer.personal_gold += need

## Deshace `disburse` si la obra no llegó a encargarse.
static func undo(vm, info: Dictionary, buyer) -> void:
	var principal: int = int(info["principal"])
	buyer.personal_gold -= principal
	if str(info["key"]) == "town":
		vm.town_state["treasury"] = int(vm.town_state["treasury"]) + principal
	else:
		info["npc"].personal_gold += principal

static func open_loan(vm, lot_id: String, buyer, info: Dictionary) -> void:
	var owed: int = int(round(float(int(info["principal"])) * (1.0 + INTEREST)))
	VillageLots.lot(vm, lot_id)["loan"] = {"lender": str(info["key"]), "lender_name": str(info["name"]), "owed": owed, "missed": 0, "principal": int(info["principal"])}
	vm.migration_state["loans_given"] = int(vm.migration_state.get("loans_given", 0)) + 1
	var who: String = "las arcas del pueblo" if str(info["key"]) == "town" else str(info["name"])
	buyer.add_thought("Pedí prestado para mi casa: debo %d (−2)" % owed, -2.0)
	vm.VillageChronicle.add(vm, "loan", "%s pide %d de oro a %s para hacerse una casa (devolverá %d)" % [buyer.npc_name, int(info["principal"]), who, owed], true)

static func _lender_node(vm, key: String):
	if key == "town":
		return null
	var n = vm._get_npcs_by_person_key().get(key, null)
	return n if n != null and is_instance_valid(n) and not n.is_dead else null

static func _credit(vm, key: String, amount: int) -> void:
	var l = _lender_node(vm, key)
	if l != null:
		l.personal_gold += amount
	else:
		vm.town_state["treasury"] = int(vm.town_state.get("treasury", 0)) + amount # muerto el noble, cobra el pueblo

## Cada día: cuotas, recargos y desahucios. Devuelve {"paid", "missed", "evicted", "cleared"}.
static func daily(vm) -> Dictionary:
	var res: Dictionary = {"paid": 0, "missed": 0, "evicted": 0, "cleared": 0}
	var people: Dictionary = vm._get_npcs_by_person_key()
	for l in VillageLots.LOTS:
		var id: String = str(l["id"])
		var st: Dictionary = VillageLots.lot(vm, id)
		if not st.has("loan"):
			continue
		var loan: Dictionary = st["loan"]
		if str(st.get("payer", "")) == "player":
			var pl = VillageNeeds.player_of(vm)
			var inv = pl.get("inventory") if pl != null else null
			var pay_p: int = mini(INSTALLMENT, int(loan["owed"]))
			if inv != null and int(inv.gold) >= pay_p:
				inv.add_gold(-pay_p)
				_credit(vm, str(loan["lender"]), pay_p)
				loan["owed"] = int(loan["owed"]) - pay_p
				loan["missed"] = 0
				res["paid"] = int(res["paid"]) + pay_p
				if int(loan["owed"]) <= 0:
					st.erase("loan")
					res["cleared"] = int(res["cleared"]) + 1
					vm.VillageChronicle.add(vm, "loan_paid", "El Forastero termina de pagar la hipoteca de su casa", true)
				continue
			loan["missed"] = int(loan["missed"]) + 1
			loan["owed"] = int(loan["owed"]) + LATE_FEE
			res["missed"] = int(res["missed"]) + 1
			if int(loan["missed"]) >= MAX_MISSED:
				evict(vm, id, people)
				res["evicted"] = int(res["evicted"]) + 1
			continue
		var owner = people.get(str(st.get("payer", "")), null)
		if owner == null or not is_instance_valid(owner) or owner.is_dead:
			st["payer"] = str(loan["lender"]) # sin deudor, la casa queda para quien prestó
			st.erase("loan")
			continue
		var pay: int = mini(INSTALLMENT, int(loan["owed"]))
		if int(owner.personal_gold) >= pay:
			owner.personal_gold -= pay
			_credit(vm, str(loan["lender"]), pay)
			loan["owed"] = int(loan["owed"]) - pay
			loan["missed"] = 0
			res["paid"] = int(res["paid"]) + pay
			if int(loan["owed"]) <= 0:
				st.erase("loan")
				res["cleared"] = int(res["cleared"]) + 1
				owner.add_thought("¡Terminé de pagar mi casa! (+12)", 12.0)
				vm.VillageChronicle.add(vm, "loan_paid", "%s termina de pagar su casa" % owner.npc_name, true)
			continue
		loan["missed"] = int(loan["missed"]) + 1
		loan["owed"] = int(loan["owed"]) + LATE_FEE
		res["missed"] = int(res["missed"]) + 1
		owner.add_thought("No pude pagar la cuota de la casa (−6)", -6.0)
		var lender = _lender_node(vm, str(loan["lender"]))
		if lender != null:
			lender.modify_npc_relationship(owner, -4, "No me paga lo que me debe", true)
		if int(loan["missed"]) >= MAX_MISSED:
			evict(vm, id, people)
			res["evicted"] = int(res["evicted"]) + 1
	return res

## La casa pasa a quien prestó; sus moradores vuelven a la posada (si hay cama) o a la calle.
static func evict(vm, id: String, people: Dictionary = {}) -> void:
	var st: Dictionary = VillageLots.lot(vm, id)
	if people.is_empty():
		people = vm._get_npcs_by_person_key()
	var loan: Dictionary = st.get("loan", {})
	var lender_key: String = str(loan.get("lender", "town"))
	var lender_name: String = "el pueblo" if lender_key == "town" else str(loan.get("lender_name", "su prestamista"))
	var debtor = people.get(str(st.get("payer", "")), null)
	for k in (st["residents"] as Array).duplicate():
		var n = people.get(str(k), null)
		if n == null or not is_instance_valid(n):
			continue
		n.lodging = ""
		var tav = vm.VillageMigration.free_tavern_bed(vm)
		if tav != null:
			n.bed_position = tav
		else:
			vm.evict_npc_to_vagrant_camp(n, "desahucio")
		n.add_thought("Me han quitado la casa por deudas (−15)", -15.0)
		n.set_meta("evicted_day", int(WorldClock.current_day) if WorldClock else 1) # M18 «Sin techo»
		n.set_meta("evicted_lot", id)
		var lender = _lender_node(vm, lender_key)
		if lender != null:
			n.modify_npc_relationship(lender, -20, "Me echó de mi casa", true)
	st["residents"] = []
	st["payer"] = lender_key
	st.erase("loan")
	var who: String = debtor.npc_name if debtor != null else "Sus dueños"
	vm.VillageChronicle.add(vm, "eviction", "%s pierde su casa por no pagar; ahora es de %s" % [who, lender_name], true)

## Para la ficha: «🏦 Debe 30 a Lord X» (o "" si no debe nada).
static func debt_text(vm, n) -> String:
	var key: String = n.get_person_key()
	for l in VillageLots.LOTS:
		var st: Dictionary = VillageLots.lot(vm, str(l["id"]))
		if st.has("loan") and str(st.get("payer", "")) == key:
			var loan: Dictionary = st["loan"]
			var who: String = "al pueblo" if str(loan["lender"]) == "town" else "a " + str(loan["lender_name"])
			var late: String = " · ⚠️ %d cuotas sin pagar" % int(loan["missed"]) if int(loan["missed"]) > 0 else ""
			return "🏦 Debe %d %s%s" % [int(loan["owed"]), who, late]
	return ""
