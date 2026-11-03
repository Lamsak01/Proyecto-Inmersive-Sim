@tool
extends RefCounted

## E4: ladrones (`docs/PLAN_ECONOMIA_NECESIDADES.md`). Por la noche, como mucho un robo en el pueblo:
## a otro vecino, al puesto de un negocio o a ti. Roba quien es pobre, está enganchado y sin oro, o es Cleptómano;
## nunca un Honrado. Si alguien lo ve y es honrado, lo denuncia y el comisario le obliga a devolverlo;
## si no, corre como chisme. La víctima le coge mucha manía (puede acabar en venganza, ver Deseos).
## Datos en `vm.needs_state.thefts`.

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageFaith = preload("res://scripts/systems/VillageFaith.gd")

const DRIVE_POOR: float = 0.03
const DRIVE_BEGGAR: float = 0.05
const DRIVE_CRAVING: float = 0.05
const DRIVE_KLEPTO: float = 0.06
const HONEST_BLOCK: float = 1.0
const PLAYER_TARGET_CHANCE: float = 0.25
const STEAL_SHARE: float = 0.2
const STEAL_CAP: int = 25
const STEAL_MIN_TARGET_GOLD: int = 12
const WITNESS_RADIUS: float = 170.0
const FAR_WITNESS_CHANCE: float = 0.25
const VICTIM_REL: int = -40
const FINE_GOLD: int = 5
const COVER_AFF: int = 8

static func _thefts(vm) -> Array:
	return VillageNeeds.state(vm)["thefts"]

static func by_id(vm, id: int) -> Dictionary:
	for t in _thefts(vm):
		if int(t["id"]) == id:
			return t
	return {}

static func drive(vm, n) -> float:
	if VillageNeeds.is_outsider(n) or int(n.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.PRIEST)]:
		return 0.0
	var honesty: float = TraitCatalog.npc_tendency(n, "honesty")
	var klepto: bool = "Cleptómano" in n.person_profile.personality
	if honesty >= HONEST_BLOCK and not klepto:
		return 0.0
	var d: float = 0.0
	match VillageNeeds.class_of(n):
		"pobre": d += DRIVE_POOR
		"mendigo": d += DRIVE_BEGGAR
	if int(VillageNeeds.state(vm)["craving"].get(n.get_person_key(), -9)) >= VillageNeeds.today() - 1:
		d += DRIVE_CRAVING
	if klepto:
		d += DRIVE_KLEPTO
	return d * clampf(1.0 - 0.6 * honesty - 0.4 * TraitCatalog.npc_tendency(n, "law"), 0.1, 2.0)

static func daily(vm) -> Dictionary:
	var people: Array = VillageNeeds.living(vm)
	people.shuffle()
	for n in people:
		var d: float = drive(vm, n)
		if d > 0.0 and randf() < d:
			return commit(vm, n)
	return {}

## Elige víctima y roba. Devuelve el robo (vacío si no encontró a quién).
static func commit(vm, thief, force_target = null) -> Dictionary:
	var target = force_target
	var kind: String = "npc"
	var pl = VillageNeeds.player_of(vm)
	if target == null:
		var inv = pl.get("inventory") if pl != null else null
		if inv != null and int(inv.gold) >= STEAL_MIN_TARGET_GOLD and randf() < PLAYER_TARGET_CHANCE:
			target = pl
		else:
			var cands: Array = []
			for v in VillageNeeds.living(vm):
				if v != thief and v.personal_gold >= STEAL_MIN_TARGET_GOLD and str(v.family_id) != str(thief.family_id) and not VillageFaith.same_band(vm, thief, v):
					cands.append(v)
			for r in vm.shop_businesses.keys():
				var holder = vm.trade_npcs.get(r, null)
				if is_instance_valid(holder) and holder != thief and int(vm.shop_businesses[r].get("vault_gold", 0)) >= STEAL_MIN_TARGET_GOLD:
					cands.append(r)
			if cands.is_empty():
				return {}
			target = cands[randi() % cands.size()]
	var victim = null
	var amount: int = 0
	if target == pl and pl != null:
		kind = "player"
		amount = clampi(int(int(pl.inventory.gold) * STEAL_SHARE), 1, STEAL_CAP)
		pl.inventory.add_gold(-amount)
	elif target is int:
		kind = "stall"
		var b: Dictionary = vm.shop_businesses[target]
		victim = vm.trade_npcs.get(target, null)
		amount = clampi(int(int(b["vault_gold"]) * STEAL_SHARE), 1, STEAL_CAP)
		b["vault_gold"] = int(b["vault_gold"]) - amount
	else:
		victim = target
		amount = clampi(int(victim.personal_gold * STEAL_SHARE), 1, STEAL_CAP)
		victim.personal_gold -= amount
	thief.personal_gold += amount
	var st: Dictionary = VillageNeeds.state(vm)
	st["theft_uid"] = int(st.get("theft_uid", 0)) + 1
	var t: Dictionary = {
		"id": int(st["theft_uid"]), "day": VillageNeeds.today(), "thief": thief.get_person_key(), "thief_name": thief.npc_name,
		"victim": "player" if kind == "player" else victim.get_person_key(), "victim_name": "ti" if kind == "player" else victim.npc_name,
		"kind": kind, "amount": amount, "witness": "", "status": "open", "player_knows": false, "ev_uid": -1,
	}
	_thefts(vm).append(t)
	while _thefts(vm).size() > 60:
		_thefts(vm).remove_at(0)
	var what: String = "el puesto de %s" % t["victim_name"] if kind == "stall" else t["victim_name"]
	# ¿Lo vio alguien?
	var w = vm._find_conscious_witness_near(thief.global_position, WITNESS_RADIUS, thief)
	if w == null and randf() < FAR_WITNESS_CHANCE:
		var others: Array = []
		for o in VillageNeeds.living(vm):
			if o != thief and o != victim and o.is_conscious():
				others.append(o)
		if not others.is_empty():
			w = others[randi() % others.size()]
	if pl is Node2D and (pl as Node2D).global_position.distance_to(thief.global_position) <= WITNESS_RADIUS:
		t["player_knows"] = true
	if victim != null:
		victim.add_thought("Me han robado %d de oro (-8)" % amount, -8.0)
	if kind == "player" and pl != null and pl.has_method("show_hint"):
		pl.show_hint("💸 Esta noche te han robado %d de oro de la bolsa%s." % [amount, (" (lo has visto: fue %s)" % thief.npc_name) if bool(t["player_knows"]) else ""])
	if w != null:
		t["witness"] = w.get_person_key()
		if TraitCatalog.npc_tendency(w, "honesty") >= 0.0 and TraitCatalog.npc_tendency(w, "law") >= 0.0 and not VillageFaith.same_band(vm, w, thief):
			catch(vm, t, "lo denunció %s" % w.npc_name)
			return t
		var ev: Dictionary = vm.record_social_event("theft", thief, victim, "%s le robó %d de oro a %s" % [thief.npc_name, amount, what])
		ev["known_by"] = {thief.get_person_key(): true, w.get_person_key(): true}
		ev["heard_from"] = {}
		ev["quiet"] = [thief.get_person_key()]
		ev["theft_id"] = int(t["id"])
		t["ev_uid"] = int(ev.get("uid", -1))
	VillageChronicle.add(vm, "theft", "%s le robó %d de oro a %s" % [thief.npc_name, amount, what], kind == "player" and bool(t["player_knows"]))
	return t

## El comisario le obliga a devolverlo y a pagar una multa; se sabe en todo el pueblo.
static func catch(vm, t: Dictionary, how: String) -> void:
	if str(t["status"]) != "open":
		return
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	var thief = by_key.get(str(t["thief"]), null)
	t["status"] = "caught"
	if thief == null:
		return
	var back: int = mini(int(t["amount"]), maxi(0, thief.personal_gold))
	thief.personal_gold -= back
	thief.personal_gold = maxi(0, thief.personal_gold - FINE_GOLD)
	var victim = by_key.get(str(t["victim"]), null)
	if str(t["victim"]) == "player":
		var pl = VillageNeeds.player_of(vm)
		if pl != null:
			pl.inventory.add_gold(back)
	elif str(t["kind"]) == "stall":
		for r in vm.shop_businesses.keys():
			if vm.trade_npcs.get(r, null) == victim:
				vm.shop_businesses[r]["vault_gold"] = int(vm.shop_businesses[r].get("vault_gold", 0)) + back
	elif victim != null:
		victim.personal_gold += back
	if victim != null:
		victim.modify_npc_relationship(thief, VICTIM_REL, "Me robó", true)
	thief.add_thought("Me pillaron robando (-10)", -10.0)
	var ev: Dictionary = vm.record_social_event("theft_caught", thief, victim, "%s robó %d de oro a %s y el comisario le obligó a devolverlo (%s)" % [thief.npc_name, int(t["amount"]), t["victim_name"], how])
	t["ev_uid"] = int(ev.get("uid", -1))
	VillageChronicle.add(vm, "theft_caught", "%s robó a %s y tuvo que devolverlo (%s)" % [thief.npc_name, t["victim_name"], how], true)

## El jugador se entera escuchando chismes.
static func on_player_news(vm, npc) -> void:
	var key: String = npc.get_person_key()
	for t in _thefts(vm):
		if bool(t["player_knows"]) or int(t["ev_uid"]) < 0:
			continue
		for ev in vm.social_event_log:
			if int(ev.get("uid", -2)) == int(t["ev_uid"]) and (ev.get("known_by", {}) as Dictionary).has(key):
				t["player_knows"] = true

static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null:
		return
	var key: String = npc.get_person_key()
	var law: bool = int(npc.trade_role) in [int(VillageNPC.TradeRole.SHERIFF), int(VillageNPC.TradeRole.GUARD)]
	for t in _thefts(vm):
		if str(t["status"]) != "open" or not bool(t["player_knows"]):
			continue
		if law:
			ch_arr.insert(0, {"label": "🚨 Denunciar a %s por robar a %s" % [t["thief_name"], t["victim_name"]], "next": "END", "action": "crime_report:%d" % int(t["id"])})
		elif str(t["thief"]) == key:
			var opts: Array = [{"label": "🤐 Prometerle que no dirás nada", "next": "END", "action": "crime_cover:%d" % int(t["id"])}]
			if str(t["victim"]) == "player":
				opts.push_front({"label": "💰 Exigirle que te devuelva tu oro", "next": "END", "action": "crime_demand:%d" % int(t["id"])})
			opts.append({"label": "⬅️ Volver a la conversación", "next": "start"})
			ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "👀 Decirle que sabes lo del robo", "next": "crime_%d" % int(t["id"])})
			diag["crime_%d" % int(t["id"])] = {"text": "«¿Robar yo? ...Vale. ¿Qué quieres?»", "choices": opts}

static func on_player_action(vm, npc, action_id: String) -> void:
	var t: Dictionary = by_id(vm, int(action_id.get_slice(":", 1)))
	if t.is_empty() or str(t["status"]) != "open":
		return
	if action_id.begins_with("crime_report:"):
		catch(vm, t, "lo denunciaste tú")
		npc.modify_affinity(4)
		VillageFaith.add_rep(vm, "law", 4)
		npc._spawn_floating_text("🚓 «Me encargo. Lo devolverá todo.»", Color(0.7, 0.85, 1.0), -46.0)
	elif action_id.begins_with("crime_cover:"):
		t["status"] = "covered"
		npc.modify_affinity(COVER_AFF)
		npc._spawn_floating_text("😅 «Te debo una.»", Color(1.0, 0.92, 0.65), -46.0)
	elif action_id.begins_with("crime_demand:"):
		if npc.affinity >= -20 and npc.personal_gold > 0:
			var back: int = mini(int(t["amount"]), npc.personal_gold)
			npc.personal_gold -= back
			var pl = VillageNeeds.player_of(vm)
			if pl != null:
				pl.inventory.add_gold(back)
			t["status"] = "returned"
			npc.modify_affinity(-6)
			npc._spawn_floating_text("😒 «Toma, y déjame en paz.»", Color.ORANGE, -46.0)
		else:
			npc.modify_affinity(-8)
			npc._spawn_floating_text("😠 «No sé de qué me hablas.»", Color.ORANGE, -46.0)
