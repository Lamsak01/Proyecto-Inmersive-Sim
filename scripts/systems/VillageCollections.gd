extends RefCounted

## Bloque P5 (Claude Code): rentas, «protección» y tributo se APARTAN el sábado y se recogen en persona.
## - Rentas y «protección»: en el puesto de trabajo del dueño del local, con el dueño presente.
## - Tributo del hampa: hablando con el perista de noche (ver `VillageUnderworld.add_dialogue_choices`).
## - Desfalco en el cofre de las arcas y libro de cuentas en la mesa del ayuntamiento (siendo alcalde).
## El oro sigue siendo del que paga hasta que lo recoges (suma cero).

const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageHousing = preload("res://scripts/systems/VillageHousing.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageMayor = preload("res://scripts/systems/VillageMayor.gd")
const VillageCivic = preload("res://scripts/systems/VillageCivic.gd")

const RENT_SHARE: float = 0.15
const MAX_PENDING_DAYS: int = 21 # rentas y tributo: 3 semanas
const RACKET_MISS_LIMIT: int = 2 # «protección»: 2 sábados sin cobrar y el local deja de pagar
const OWNER_NEAR_PX: float = 60.0
const WITNESS_PX: float = 160.0
const LEDGER_OFFSET: Vector2 = Vector2(12, 0) # junto a la mesa del ayuntamiento, sin pisar el libro de los gremios

static func pending(vm) -> Array:
	var ns: Dictionary = VillageNeeds.state(vm)
	if not (ns.get("pending_collections", null) is Array):
		ns["pending_collections"] = []
	return ns["pending_collections"]

static func pending_total(vm, kind: String, role_i: int = -1) -> int:
	var t: int = 0
	for e in pending(vm):
		if str(e.get("kind", "")) == kind and (role_i < 0 or int(e.get("role", -1)) == role_i):
			t += int(e.get("amount", 0))
	return t

static func _remove_entries(vm, kind: String, role_i: int = -1) -> void:
	var keep: Array = []
	for e in pending(vm):
		if str(e.get("kind", "")) == kind and (role_i < 0 or int(e.get("role", -1)) == role_i):
			continue
		keep.append(e)
	var list: Array = pending(vm)
	list.clear()
	list.append_array(keep)

static func _owner(vm, role_i: int):
	var o = vm.trade_npcs.get(role_i, null)
	if o == null or not is_instance_valid(o) or o.is_dead:
		return null
	return o

static func _owner_present(vm, role_i: int) -> bool:
	var o = _owner(vm, role_i)
	return o != null and not o.is_sleeping and not o.is_incapacitated() and o.global_position.distance_to(o.work_position) <= OWNER_NEAR_PX

# ------------------------------------------------------------------ calendario
## Cada medianoche (lo llama `VillageManager` tras `VillageUnderworld.daily`).
static func daily(vm) -> void:
	if vm == null:
		return
	expire_old(vm, VillageUnderworld.today())
	if WorldClock != null and WorldClock.has_method("get_weekday") and int(WorldClock.get_weekday()) == 5:
		on_saturday(vm)
	sync_points(vm)

## Sábado: se aparta lo que te deben; no se mueve oro.
static func on_saturday(vm) -> void:
	var list: Array = pending(vm)
	var d: int = VillageUnderworld.today()
	var deeds: Dictionary = VillageHousing.state(vm).get("commercial_deeds", {})
	for r_key in deeds.keys():
		var role_i: int = int(r_key)
		if vm.shop_businesses.has(role_i):
			var cut: int = int(round(float(int(vm.shop_businesses[role_i].get("vault_gold", 0))) * RENT_SHARE))
			if cut > 0:
				list.append({"kind": "rent", "role": role_i, "amount": cut, "since": d})
	var ust: Dictionary = VillageUnderworld.state(vm)
	var rackets: Dictionary = ust.get("rackets", {})
	for rk in rackets.keys().duplicate():
		var role_r: int = int(rk)
		var missed: int = 0
		for e in list:
			if str(e.get("kind", "")) == "racket" and int(e.get("role", -1)) == role_r:
				missed += 1
		if missed >= RACKET_MISS_LIMIT:
			_drop_racket(vm, rk)
			continue
		list.append({"kind": "racket", "role": role_r, "amount": VillageUnderworld.RACKET_WEEKLY, "since": d})
	if str(ust.get("boss", "fence")) == "player":
		list.append({"kind": "tribute", "role": -1, "amount": VillageUnderworld.BOSS_TRIBUTE, "since": d})

static func _drop_racket(vm, rk) -> void:
	var ust: Dictionary = VillageUnderworld.state(vm)
	var info: Dictionary = (ust.get("rackets", {}) as Dictionary).get(rk, {})
	(ust["rackets"] as Dictionary).erase(rk)
	_remove_entries(vm, "racket", int(rk))
	var o = _owner(vm, int(rk))
	if o != null:
		o.add_thought("El forastero ya no viene a cobrar; ya no le temo (+4)", 4.0)
	var nm: String = o.npc_name if o != null else str(info.get("npc_name", "Un artesano"))
	VillageChronicle.add(vm, "racket_lapsed", "%s dejó de pagarte «protección»: hace dos sábados que nadie va a cobrar" % nm, false)

## Rentas y tributo con más de 21 días se pierden.
static func expire_old(vm, d: int) -> void:
	var keep: Array = []
	for e in pending(vm):
		var k: String = str(e.get("kind", ""))
		if k in ["rent", "tribute"] and d - int(e.get("since", d)) > MAX_PENDING_DAYS:
			if k == "rent":
				var o = _owner(vm, int(e.get("role", -1)))
				VillageChronicle.add(vm, "rent_lapsed", "%s se gastó la renta que no fuiste a cobrar" % (o.npc_name if o != null else "El artesano"), false)
			continue
		keep.append(e)
	var list: Array = pending(vm)
	list.clear()
	list.append_array(keep)

# ------------------------------------------------------------------ cobrar en el local
static func collect_label(vm, kind: String, role_i: int) -> String:
	var amt: int = pending_total(vm, kind, role_i)
	if amt <= 0:
		return ""
	if not _owner_present(vm, role_i):
		return "El dueño no está; vuelve cuando abra"
	if kind == "rent":
		return "Cobrar la renta del local (%d de oro)" % amt
	return "Cobrar la \"protección\" (%d de oro)" % amt

## Cobra lo apartado de un local. Devuelve el oro recibido (-1 si el dueño no está).
static func collect(vm, kind: String, role_i: int, player: Node2D) -> int:
	var amt: int = pending_total(vm, kind, role_i)
	if amt <= 0:
		return 0
	if not _owner_present(vm, role_i):
		_msg(player, "El dueño no está; vuelve cuando abra", Color.LIGHT_GRAY)
		return -1
	var o = _owner(vm, role_i)
	var got: int = 0
	if vm.shop_businesses.has(role_i):
		var vault: int = int(vm.shop_businesses[role_i].get("vault_gold", 0))
		got = mini(amt, vault)
		vm.shop_businesses[role_i]["vault_gold"] = vault - got
	if kind == "racket" and got < amt and o != null:
		var from_pocket: int = mini(amt - got, int(o.personal_gold))
		o.personal_gold -= from_pocket
		got += from_pocket
	_remove_entries(vm, kind, role_i)
	var inv = player.get("inventory") if player != null else null
	if inv != null and got > 0:
		inv.add_gold(got)
	if kind == "rent":
		VillageChronicle.add(vm, "rent_collected", "Cobraste %d de oro de renta en el local de %s" % [got, o.npc_name], false)
		_msg(player, "🏪💰 Renta cobrada: +%d de oro" % got, Color.GOLD)
	else:
		if got == 0:
			o.add_thought("No tengo con qué pagar la «protección»; tengo miedo (-6)", -6.0)
		VillageChronicle.add(vm, "racket_paid", "Cobraste %d de oro de «protección» en el local de %s" % [got, o.npc_name], false)
		_msg(player, "👊💰 «Protección» cobrada: +%d de oro" % got, Color.GOLD)
		var g = _guard_watching(vm, o.work_position)
		if g != null:
			vm.wanted_level = clampi(int(vm.wanted_level) + 1, 1, 5)
			VillageChronicle.add(vm, "racket_seen", "%s te vio cobrar «protección» a %s" % [g.npc_name, o.npc_name], true)
			_msg(player, "👮 ¡%s te ha visto! (Búsqueda +1)" % g.npc_name, Color.ORANGE_RED)
	return got

static func _guard_watching(vm, pos: Vector2):
	for n in VillageNeeds.living(vm):
		if int(n.trade_role) in [int(VillageNPC.TradeRole.GUARD), int(VillageNPC.TradeRole.SHERIFF)]:
			if not n.is_sleeping and not n.is_incapacitated() and n.global_position.distance_to(pos) <= WITNESS_PX:
				return n
	return null

# ------------------------------------------------------------------ tributo (charla con el perista)
static func collect_tribute(vm, fence, inv) -> int:
	var amt: int = pending_total(vm, "tribute")
	if amt <= 0 or fence == null:
		return 0
	var got: int = mini(amt, int(fence.personal_gold))
	fence.personal_gold -= got
	if inv != null and got > 0:
		inv.add_gold(got)
	_remove_entries(vm, "tribute")
	VillageChronicle.add(vm, "underworld_tribute", "Como Jefe del Hampa recogiste tu tributo de los bajos fondos (+%d de oro)" % got, false)
	return got

# ------------------------------------------------------------------ ayuntamiento
static func embezzle_label(vm) -> String:
	if not VillageMayor.is_player_mayor(vm) or int(vm.town_state.get("treasury", 0)) < VillageMayor.EMBEZZLE_AMOUNT:
		return ""
	return "Desviar %d de oro a tu bolsillo" % VillageMayor.EMBEZZLE_AMOUNT

## Lo mismo que `town_player_embezzle`, pero en el cofre y con testigos.
static func embezzle(vm, player: Node2D) -> int:
	if not VillageMayor.is_player_mayor(vm):
		return 0
	var ts: Dictionary = vm.town_state
	var take: int = mini(VillageMayor.EMBEZZLE_AMOUNT, int(ts.get("treasury", 0)))
	if take <= 0:
		return 0
	ts["treasury"] = int(ts["treasury"]) - take
	var inv = player.get("inventory") if player != null else null
	if inv != null:
		inv.add_gold(take)
	if randf() < 0.45:
		ts["player_embezzle_risk"] = int(ts.get("player_embezzle_risk", 0)) + 1
	VillageChronicle.add(vm, "player_embezzle", "Desviaste %d de oro de las arcas municipales a tu bolsillo" % take, false)
	_msg(player, "💼🪙 Desviaste +%d de oro de las arcas" % take, Color.GOLD)
	var wpos: Vector2 = player.global_position if player != null else VillageCivic.hall_spots()["coffers"]
	var wit = vm._find_conscious_witness_near(wpos, WITNESS_PX, null)
	if wit != null:
		ts["player_embezzle_risk"] = int(ts.get("player_embezzle_risk", 0)) + 2
		var line: String = "%s vio al alcalde sacar oro de las arcas" % wit.npc_name
		VillageChronicle.add(vm, "embezzle_seen", line, true)
		vm.record_social_event("player_secret", wit, null, line)
		_msg(player, "👀 ¡%s te ha visto sacar el oro!" % wit.npc_name, Color.ORANGE_RED)
	return take

static func ledger_label(vm) -> String:
	if not VillageMayor.is_player_mayor(vm) or int(vm.town_state.get("player_embezzle_risk", 0)) <= 0:
		return ""
	return "Maquillar el libro de cuentas (−%d oro o Carisma 2)" % VillageMayor.COOK_BOOKS_COST

## Lo mismo que `town_cook_books`. No hay escribano en el pueblo: el oro va a las arcas.
static func cook_books(vm, player: Node2D) -> bool:
	var ts: Dictionary = vm.town_state
	if not VillageMayor.is_player_mayor(vm) or int(ts.get("player_embezzle_risk", 0)) <= 0:
		return false
	var cha: int = int(player.call("get_skill_level", "charisma")) if player != null and player.has_method("get_skill_level") else 0
	if cha < 2:
		var inv = player.get("inventory") if player != null else null
		if inv == null or int(inv.gold) < VillageMayor.COOK_BOOKS_COST:
			_msg(player, "Necesitas %d de oro o Carisma Nv.2 para maquillar las cuentas" % VillageMayor.COOK_BOOKS_COST, Color.ORANGE_RED)
			return false
		if not VillageHousing.press_twice(vm, "cook_books"):
			_msg(player, "Pulsa [E] otra vez para pagar %d de oro" % VillageMayor.COOK_BOOKS_COST, Color.LIGHT_GRAY)
			return false
		inv.add_gold(-VillageMayor.COOK_BOOKS_COST)
		ts["treasury"] = int(ts.get("treasury", 0)) + VillageMayor.COOK_BOOKS_COST
	ts["player_embezzle_risk"] = 0
	_msg(player, "🧹📒 Las cuentas del Ayuntamiento vuelven a cuadrar al céntimo", Color.SPRING_GREEN)
	return true

# ------------------------------------------------------------------ objetos con [E]
static func ledger_pos() -> Vector2:
	return VillageCivic.hall_spots()["desk"] + LEDGER_OFFSET

## Crea los puntos de cobro de los locales que te deben y, una sola vez, el desfalco y el libro del ayuntamiento.
static func sync_points(vm) -> void:
	if vm == null or not vm.is_inside_tree():
		return
	var parent: Node = vm.entities_root if ("entities_root" in vm and is_instance_valid(vm.entities_root)) else vm
	var PropScript = load("res://scripts/obstacles/WorldInteractableProp.gd")
	var tree = vm.get_tree()
	for old in tree.get_nodes_in_group("collect_point"):
		if is_instance_valid(old):
			if old.get_parent() != null:
				old.get_parent().remove_child(old)
			old.queue_free()
	var roles: Dictionary = {}
	for e in pending(vm):
		var k: String = str(e.get("kind", ""))
		if k in ["rent", "racket"]:
			roles["%s:%d" % [k, int(e.get("role", -1))]] = true
	for key in roles.keys():
		var parts: PackedStringArray = str(key).split(":")
		var o = _owner(vm, int(parts[1]))
		if o == null:
			continue
		var p: Node2D = PropScript.new()
		p.global_position = o.work_position + (Vector2(-8, 8) if parts[0] == "rent" else Vector2(8, 8))
		parent.add_child(p)
		p.setup_prop(vm, "collect_point", str(key), "")
	if tree.get_nodes_in_group("town_coffers_prop").is_empty():
		var c: Node2D = PropScript.new()
		c.global_position = VillageCivic.hall_spots()["coffers"] + Vector2(0, 2)
		parent.add_child(c)
		c.setup_prop(vm, "town_coffers", "", "")
	if tree.get_nodes_in_group("town_ledger_prop").is_empty():
		var l: Node2D = PropScript.new()
		l.global_position = ledger_pos()
		parent.add_child(l)
		l.setup_prop(vm, "town_ledger", "", "")

static func _msg(player, txt: String, col: Color) -> void:
	if player != null and is_instance_valid(player) and player.has_method("_spawn_floating_text"):
		player._spawn_floating_text(txt, col, -46.0)
