@tool
extends RefCounted

## Fama de los vecinos (-100 a +100) y Maestros Artesanos con estilo propio (`docs/VISION_Y_FUTURO.md`).
## - Cada vecino acumula fama positiva (🌟 Célebre / ✨ Conocido) o negativa (🌑 Infame / 😠 Mal visto) por sus actos:
##   alcanzar maestría en su oficio, ganar peleas, ocupar la alcaldía, o por el contrario ser pillado robando,
##   protagonizar escándalos de infidelidad o ser descubierto en un crimen.
## - Los artesanos con experiencia (`days_in_role >= 6`) e inclinación por el oficio (`craft`, `diligence`, `trade`)
##   alcanzan el título de Maestro Artesano con un estilo de autor propio de su gremio y elaboran Obras Maestras
##   firmadas (`masterwork_piece`) con existencias limitadas.
## - Los vecinos adinerados y nobles compran sus piezas con oro real de su bolsillo (`personal_gold`), y en el
##   mercado de los miércoles sus puestos cobran un suplemento de prestigio.
## - El jugador puede comprar Obras Maestras en su taller, patrocinar con materiales a un artesano prometedor,
##   vender o regalar Obras Maestras a coleccionistas, y hablar bien o mal de un vecino (con tirada de riesgo y espera).
## Estado guardado en `vm.culture_state["fame"]` (se persiste automáticamente con `culture_state`).

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")
const VillageNeeds = preload("res://scripts/systems/VillageNeeds.gd")
const VillageChronicle = preload("res://scripts/systems/VillageChronicle.gd")
const VillageClans = preload("res://scripts/systems/VillageClans.gd")

const MASTERWORK_BUY_COST: int = 35
const MASTERWORK_COLLECTOR_PRICE: int = 50
const PATRON_COST: int = 30
const PATRON_COOLDOWN_DAYS: int = 7
const PRAISE_COOLDOWN_DAYS: int = 3
const CRAFT_INTERVAL_DAYS: int = 3
const MAX_MASTER_STOCK: int = 2
const COMPANION_HIRE_COST: int = 15
const OBSESSION_GIFT_COST: int = 6

const STYLE_BY_ROLE: Dictionary = {
	4: ["Acero Templado al Alba", "Forja de Martillo Doble", "Filo de Espejo"], # BLACKSMITH
	3: ["Corte de Sierra Fina", "Curado al Humo de Encina", "Salazón del Valle"], # BUTCHER
	5: ["Ensamblaje sin Clavos", "Veta de Roble Antiguo", "Talla de Sol Naciente"], # CARPENTER
	6: ["Destilado de Rocío", "Infusión de Raíz Silvestre", "Ungüento de Luna"], # HERBALIST
	7: ["Harina de Piedra Fina", "Ahumado de Río Frío", "Red de Hilo Trenzado"], # FISHMONGER
	14: ["Masa Madre Dorada", "Horno de Leña Dulce", "Corteza Crujiente"], # BAKER
	15: ["Costura de Hilo Fino", "Paño de Gala del Valle", "Bordado Señoril"], # TAILOR
	16: ["Puchero de Fuego Lento", "Caldo de Posada Vieja", "Asado de Camino"], # LODGEKEEPER
	17: ["Espiga de Tierra Negra", "Cosecha Temprana", "Grano Seleccionado"], # FARMER
	18: ["Vellón de Pasto Alto", "Crianza de Monte", "Cuero Engrasado"], # RANCHER
	19: ["Sillar Escuadrado", "Corte de Veta Gris", "Piedra Pulida a Cincel"], # QUARRYMAN
	20: ["Leña Secada al Viento", "Viga de Pino Viejo", "Corte de Hacha Limpia"], # WOODCUTTER
	21: ["Engranaje de Precisión", "Soldadura de Latón", "Resorte Templado"] # TINKER
}

static func state(vm) -> Dictionary:
	if not (vm.culture_state is Dictionary):
		vm.culture_state = {}
	if not vm.culture_state.has("fame") or not (vm.culture_state["fame"] is Dictionary):
		vm.culture_state["fame"] = {}
	var st: Dictionary = vm.culture_state["fame"]
	for k in ["scores", "reasons", "masters", "patron_day", "obsessions", "companion"]:
		if not st.has(k) or not (st[k] is Dictionary):
			st[k] = {}
	if not st.has("last_praise_day"):
		st["last_praise_day"] = -99
	if not st.has("last_probe_day"):
		st["last_probe_day"] = -99
	return st

static func today() -> int:
	return int(WorldClock.current_day) if WorldClock else 1

static func fame_of(vm, npc) -> int:
	if vm == null or npc == null:
		return 0
	return int((state(vm)["scores"] as Dictionary).get(npc.get_person_key(), 0))

static func reason_of(vm, npc) -> String:
	if vm == null or npc == null:
		return ""
	return str((state(vm)["reasons"] as Dictionary).get(npc.get_person_key(), ""))

static func tier_label(score: int) -> String:
	if score >= 50:
		return "🌟 Célebre"
	if score >= 20:
		return "✨ Conocido"
	if score <= -50:
		return "🌑 Infame"
	if score <= -20:
		return "😠 Mal visto"
	return ""

static func summary_badge(vm, npc) -> String:
	if vm == null or npc == null:
		return ""
	var sc: int = fame_of(vm, npc)
	var parts: Array[String] = []
	var tl: String = tier_label(sc)
	if tl != "":
		parts.append("%s (%+d)" % [tl, sc])
	if is_master(vm, npc):
		var m: Dictionary = master_info(vm, npc)
		parts.append("🏆 Estilo «%s»" % str(m.get("style", "Autor")))
	if is_companion(vm, npc):
		parts.append("🛡️ Tu acompañante")
	var obs_st: Dictionary = (state(vm)["obsessions"] as Dictionary).get(npc.get_person_key(), {})
	if not obs_st.is_empty() and bool(obs_st.get("known_by_player", false)):
		parts.append("💘 Obsesionado con %s" % str(obs_st.get("idol_name", "")))
	return " · ".join(parts)

## Bloque PH: Acompañante del jugador (amigo leal con afinidad >= 55 o escolta contratado por 15 de oro/día)
static func is_companion(vm, npc) -> bool:
	if vm == null or npc == null:
		return false
	var comp: Dictionary = state(vm)["companion"]
	return not comp.is_empty() and str(comp.get("key", "")) == npc.get_person_key()

static func companion_npc(vm):
	if vm == null:
		return null
	var comp: Dictionary = state(vm)["companion"]
	var k: String = str(comp.get("key", ""))
	if k == "":
		return null
	var n = vm._get_npcs_by_person_key().get(k, null)
	if n == null or not is_instance_valid(n) or n.is_dead:
		state(vm)["companion"] = {}
		return null
	return n

static func set_companion(vm, npc, mode: String) -> void:
	if vm == null or npc == null or npc.is_dead:
		return
	state(vm)["companion"] = {
		"key": npc.get_person_key(),
		"name": npc.npc_name,
		"mode": mode,
		"since_day": today(),
		"last_backup_day": -99
	}

static func dismiss_companion(vm) -> void:
	if vm == null:
		return
	state(vm)["companion"] = {}

## Bloque PH: Idolatría u obsesión patológica muy rara por un personaje célebre o admirado
static func try_spawn_obsession(vm, forced_stalker = null, forced_idol = null) -> bool:
	if vm == null:
		return false
	var st: Dictionary = state(vm)
	var stalker = forced_stalker
	var idol = forced_idol
	if stalker == null or idol == null:
		var living_npcs: Array = VillageNeeds.living(vm)
		for cand_idol in living_npcs:
			if int(cand_idol.trade_role) == int(VillageNPC.TradeRole.CHILD) or VillageNeeds.is_outsider(cand_idol):
				continue
			if fame_of(vm, cand_idol) >= 35:
				idol = cand_idol
				break
		if idol == null:
			return false
		for cand_s in living_npcs:
			if cand_s == idol or int(cand_s.trade_role) == int(VillageNPC.TradeRole.CHILD) or VillageNeeds.is_outsider(cand_s):
				continue
			if cand_s.family_id != "none" and cand_s.family_id == idol.family_id:
				continue
			if cand_s.person_profile != null and str(cand_s.person_profile.partner_id) != "":
				continue
			if not (st["obsessions"] as Dictionary).has(cand_s.get_person_key()):
				stalker = cand_s
				break
	if stalker == null or idol == null or stalker == idol:
		return false
	var sk: String = stalker.get_person_key()
	st["obsessions"][sk] = {
		"stalker_key": sk,
		"stalker_name": stalker.npc_name,
		"idol_key": idol.get_person_key(),
		"idol_name": idol.npc_name,
		"since_day": today(),
		"gifts_sent": 0,
		"known_by_player": false
	}
	if vm.social_director != null:
		vm.social_director.add_spark_one_way(sk, idol.get_person_key(), 25)
	stalker.modify_npc_relationship(idol, 25, "Idolatría obsesiva hacia %s" % idol.npc_name, true)
	VillageChronicle.add(vm, "obsession_started", "Alguien en el pueblo ha desarrollado una obsesión enfermiza y deja regalos anónimos a %s" % idol.npc_name, false)
	return true

static func add_fame(vm, npc, delta: int, reason: String = "") -> int:
	if vm == null or npc == null or delta == 0:
		return 0
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var old_sc: int = int((st["scores"] as Dictionary).get(key, 0))
	var new_sc: int = clampi(old_sc + delta, -100, 100)
	st["scores"][key] = new_sc
	if reason != "" and (absi(delta) >= 3 or not (st["reasons"] as Dictionary).has(key)):
		st["reasons"][key] = reason
	return new_sc

static func is_master(vm, npc) -> bool:
	if vm == null or npc == null:
		return false
	return (state(vm)["masters"] as Dictionary).has(npc.get_person_key())

static func master_info(vm, npc) -> Dictionary:
	if vm == null or npc == null:
		return {}
	return (state(vm)["masters"] as Dictionary).get(npc.get_person_key(), {})

static func _pick_style_for(npc) -> String:
	var r_id: int = int(npc.trade_role)
	var opts: Array = STYLE_BY_ROLE.get(r_id, ["Sello Tradicional del Valle", "Hechura de Maestro", "Oficio Antiguo"])
	var idx: int = absi(npc.get_person_key().hash()) % opts.size()
	return str(opts[idx])

static func promote_to_master(vm, npc) -> bool:
	if vm == null or npc == null or npc.is_dead:
		return false
	if not (npc.trade_role in VillageNPC.SHOP_ROLES) or is_master(vm, npc):
		return false
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var style: String = _pick_style_for(npc)
	var fem: bool = npc.person_profile != null and str(npc.person_profile.gender) == "F"
	var role_word: String = str(npc.npc_role).split(" ")[0] if str(npc.npc_role) != "" else "Artesano"
	var title: String = ("Maestra " if fem else "Maestro ") + role_word
	st["masters"][key] = {
		"style": style,
		"title": title,
		"role": int(npc.trade_role),
		"since_day": today(),
		"stock": 1,
		"last_craft_day": today()
	}
	add_fame(vm, npc, 25, "Reconocido por su estilo «%s»" % style)
	npc.add_thought("Alcanzar la maestría en mi oficio me llena de orgullo (+12)", 12.0)
	VillageChronicle.add(vm, "master_artisan", "%s alcanzó el rango de %s con su propio estilo («%s»)" % [npc.npc_name, title, style], true)
	return true

static func daily(vm) -> void:
	if vm == null:
		return
	var st: Dictionary = state(vm)
	var cur_day: int = today()
	var living_npcs: Array = VillageNeeds.living(vm)
	for n in living_npcs:
		if int(n.trade_role) == int(VillageNPC.TradeRole.CHILD) or VillageNeeds.is_outsider(n):
			continue
		if n.trade_role in VillageNPC.SHOP_ROLES:
			if not is_master(vm, n):
				var craft_score: float = TraitCatalog.npc_tendency(n, "craft") + 0.5 * TraitCatalog.npc_tendency(n, "diligence") + 0.35 * TraitCatalog.npc_tendency(n, "trade")
				if (int(n.days_in_role) >= 6 and craft_score >= 0.45) or int(n.days_in_role) >= 10:
					promote_to_master(vm, n)
			else:
				var m: Dictionary = st["masters"][n.get_person_key()]
				if not vm.is_trade_sabotaged(int(n.trade_role)) and int(n.sick_level) < 2:
					if cur_day - int(m.get("last_craft_day", 0)) >= CRAFT_INTERVAL_DAYS and int(m.get("stock", 0)) < MAX_MASTER_STOCK:
						m["stock"] = int(m.get("stock", 0)) + 1
						m["last_craft_day"] = cur_day
					# Clientes ricos o nobles compran una pieza firmada con oro real de su bolsillo
					if int(m.get("stock", 0)) > 0 and cur_day % 4 == 0:
						for buyer in living_npcs:
							if buyer == n or int(buyer.trade_role) == int(VillageNPC.TradeRole.CHILD):
								continue
							if (int(buyer.trade_role) == int(VillageNPC.TradeRole.NOBLE) or VillageNeeds.class_of(buyer) == "rico") and int(buyer.personal_gold) >= 45:
								var price: int = 30
								buyer.personal_gold -= price
								n.personal_gold = maxi(0, int(n.personal_gold)) + price
								m["stock"] = maxi(0, int(m.get("stock", 1)) - 1)
								buyer.modify_npc_relationship(n, 4, "Adquirió una pieza de su estilo «%s»" % str(m.get("style", "")), true)
								add_fame(vm, n, 3, "Sus piezas de estilo «%s» se rifan entre los pudientes" % str(m.get("style", "")))
								add_fame(vm, buyer, 2, "Colecciona obras de artesanos maestros")
								break
		if TraitCatalog.npc_tendency(n, "fame") >= 0.5 and randf() < 0.25:
			add_fame(vm, n, 2, "Le gusta hacerse notar en las tertulias del pueblo")
		if vm.VillageTown.is_mayor(vm, n) and fame_of(vm, n) < 25:
			add_fame(vm, n, 2, "Ejerce como alcalde del pueblo")

	# Bloque PH.1: Procesar idolatría / obsesión activa (regalos de su bolsillo, seguimiento y celos extremos)
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for sk in (st["obsessions"] as Dictionary).keys():
		var obs: Dictionary = st["obsessions"][sk]
		var stalker = by_key.get(str(sk), null)
		var idol = by_key.get(str(obs.get("idol_key", "")), null)
		if stalker == null or idol == null or stalker.is_dead or idol.is_dead:
			st["obsessions"].erase(sk)
			continue
		if vm.social_director != null:
			vm.social_director.add_spark_one_way(stalker.get_person_key(), idol.get_person_key(), 4)
		stalker.modify_npc_relationship(idol, 3, "No puedo dejar de pensar en %s" % idol.npc_name, true)
		if int(stalker.personal_gold) >= 16:
			stalker.personal_gold -= OBSESSION_GIFT_COST
			idol.personal_gold += OBSESSION_GIFT_COST
			obs["gifts_sent"] = int(obs.get("gifts_sent", 0)) + 1
			idol.add_thought("Alguien me dejó otro regalo anónimo en la puerta... qué inquietante (-3)", -3.0)
		for o_jeal in living_npcs:
			if o_jeal != stalker and o_jeal != idol and int(o_jeal.trade_role) != int(VillageNPC.TradeRole.CHILD):
				if idol.get_relationship_with_npc(o_jeal.get_person_key()) >= 40 or (idol.person_profile != null and str(idol.person_profile.partner_id) == o_jeal.get_person_key()):
					stalker.modify_npc_relationship(o_jeal, -8, "Celos enfermizos por acercarse a %s" % idol.npc_name, true)
		stalker.start_errand("obsession_follow", idol.global_position + Vector2(20, -14))
	if (st["obsessions"] as Dictionary).is_empty() and randf() < 0.08:
		try_spawn_obsession(vm)

	# Bloque PH.2: Sueldo diario del acompañante contratado (de tu bolsa a su bolsillo)
	var comp = companion_npc(vm)
	if comp != null:
		var comp_info: Dictionary = st["companion"]
		if str(comp_info.get("mode", "")) == "hired":
			var pl_c = VillageNeeds.player_of(vm)
			var inv_c = pl_c.get("inventory") if pl_c != null else null
			if inv_c != null and int(inv_c.gold) >= COMPANION_HIRE_COST:
				inv_c.add_gold(-COMPANION_HIRE_COST)
				comp.personal_gold += COMPANION_HIRE_COST
			else:
				dismiss_companion(vm)
				VillageChronicle.add(vm, "companion_left", "%s dejó de acompañarte al no poder cobrar su jornal de escolta" % comp.npc_name, true)
		elif int(comp.affinity) < 35:
			dismiss_companion(vm)

# ==============================================================================
# Diálogo y mecánicas del jugador
# ==============================================================================
static func add_dialogue_choices(vm, npc, diag: Dictionary, ch_arr: Array) -> void:
	if vm == null or npc == null or int(npc.trade_role) == int(VillageNPC.TradeRole.CHILD):
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var pl = npc._get_player()
	var inv = pl.get("inventory") if pl != null else null
	var sub: Array = []

	# 1. Si es Maestro Artesano: comprar Obra Maestra firmada
	if is_master(vm, npc):
		var m: Dictionary = master_info(vm, npc)
		var stock: int = int(m.get("stock", 0))
		sub.append({
			"label": "🏆🎨 Comprar Obra Maestra de estilo «%s» (-%d Oro) [Disponibles: %d]" % [str(m.get("style", "Autor")), MASTERWORK_BUY_COST, stock],
			"next": "END",
			"action": "fame_buy_masterwork"
		})
	# 2. Si es artesano con taller pero aún no es Maestro: patrocinar su taller con mejores materiales
	elif npc.trade_role in VillageNPC.SHOP_ROLES:
		var last_pat: int = int((st["patron_day"] as Dictionary).get(key, -99))
		if today() - last_pat >= PATRON_COOLDOWN_DAYS:
			sub.append({
				"label": "🛠️💰 Patrocinar su taller con materiales selectos (-%d Oro -> impulsa su maestría)" % PATRON_COST,
				"next": "END",
				"action": "fame_patronize"
			})

	# 3. Si el jugador lleva una Obra Maestra en el inventario: venderla a coleccionista (noble/rico/mercader) o regalarla
	if inv != null and inv.has_method("has_item") and bool(inv.call("has_item", "masterwork_piece", 1)):
		var is_collector: bool = int(npc.trade_role) in [int(VillageNPC.TradeRole.NOBLE), int(VillageNPC.TradeRole.TRAVELING_MERCHANT)] or VillageNeeds.class_of(npc) == "rico"
		if is_collector:
			sub.append({
				"label": "🏺💰 Venderle una Obra Maestra firmada para su colección (hasta %d Oro de su bolsillo)" % MASTERWORK_COLLECTOR_PRICE,
				"next": "END",
				"action": "fame_sell_masterwork"
			})
		sub.append({
			"label": "🏺🎁 Regalarle una Obra Maestra con sello de autor (+22 Afinidad y +8 Fama)",
			"next": "END",
			"action": "fame_gift_masterwork"
		})

	# 4. Elogiar en público o pregonar sus vergüenzas (una vez cada 3 días, con tirada de riesgo)
	if not VillageNeeds.is_outsider(npc) and today() - int(st.get("last_praise_day", -99)) >= PRAISE_COOLDOWN_DAYS:
		sub.append({
			"label": "📣🌟 Hablar maravillas de su nombre por el pueblo (tirada con Carisma)",
			"next": "END",
			"action": "fame_praise"
		})
		sub.append({
			"label": "📣🌑 Pregonar sus faltas para hundir su reputación (riesgo de quedar como difamador)",
			"next": "END",
			"action": "fame_tarnish"
		})

	# 5. Bloque PH.1: Idolatría / obsesión (sin destripar quién es: tantear se ofrece con cualquier adulto una vez al día)
	if not VillageNeeds.is_outsider(npc) and today() != int(st.get("last_probe_day", -99)):
		sub.append({
			"label": "🔍💌 Tantear si sabe algo de regalos o admiradores obsesivos en el vecindario (1/día)",
			"next": "END",
			"action": "fame_probe_obsession"
		})
	if (st["obsessions"] as Dictionary).has(key) and bool(st["obsessions"][key].get("known_by_player", false)):
		sub.append({
			"label": "🧘💬 Hacerle entrar en razón para que deje su obsesión por %s (tirada de Carisma)" % str(st["obsessions"][key].get("idol_name", "")),
			"next": "END",
			"action": "fame_calm_obsessed"
		})
	for sk_w in (st["obsessions"] as Dictionary).keys():
		var obs_w: Dictionary = st["obsessions"][sk_w]
		if str(obs_w.get("idol_key", "")) == key and bool(obs_w.get("known_by_player", false)):
			sub.append({
				"label": "⚠️👁️ Avisarle de que %s es quien le vigila y deja regalos anónimos (recompensa de su bolsillo)" % str(obs_w.get("stalker_name", "")),
				"next": "END",
				"action": "fame_warn_idol:" + str(sk_w)
			})

	# 6. Bloque PH.2: Acompañantes del jugador (invitar por amistad >= 55, contratar como escolta por 15 Oro/día, pedir apoyo o despedir)
	var cur_comp = companion_npc(vm)
	if cur_comp == npc:
		sub.append({
			"label": "👋🚶 Decirle que ya puede volver a sus quehaceres (dejar de acompañarte)",
			"next": "END",
			"action": "fame_companion_dismiss"
		})
	elif cur_comp == null and not VillageNeeds.is_outsider(npc):
		if int(npc.affinity) >= 55:
			sub.append({
				"label": "🤝🚶 Pedirle que te acompañe por el valle como compañero (Gratis por amistad)",
				"next": "END",
				"action": "fame_companion_invite"
			})
		if int(npc.affinity) >= 10:
			sub.append({
				"label": "🛡️💰 Contratarle como escolta y acompañante (-%d Oro/día de tu bolsa)" % COMPANION_HIRE_COST,
				"next": "END",
				"action": "fame_companion_hire"
			})
	elif cur_comp != null and cur_comp != npc and today() != int(st["companion"].get("last_backup_day", -99)):
		sub.append({
			"label": "🛡️🗣️ Pedir a tu acompañante (%s) que te respalde y presione (1/día, con tirada)" % cur_comp.npc_name,
			"next": "END",
			"action": "fame_companion_backup"
		})

	if not sub.is_empty():
		var sc: int = fame_of(vm, npc)
		var tl: String = tier_label(sc)
		var rsn: String = reason_of(vm, npc)
		var header: String = "🌟 Reputación en el valle: %s (%+d)" % [tl if tl != "" else "Vecino corriente", sc]
		if rsn != "":
			header += "\n• Motivo reciente: %s." % rsn
		if is_master(vm, npc):
			var mi: Dictionary = master_info(vm, npc)
			header += "\n• %s — Estilo propio: «%s» (Obras disponibles: %d)." % [str(mi.get("title", "Maestro Artesano")), str(mi.get("style", "")), int(mi.get("stock", 0))]
		sub.append({"label": "⬅️ Volver", "next": "start"})
		diag["fame_menu"] = {"text": header, "choices": sub}
		ch_arr.insert(maxi(0, ch_arr.size() - 1), {"label": "🌟🏆 Fama, prestigio y obras de autor…", "next": "fame_menu"})

static func on_player_action(vm, npc, action_id: String, inv) -> void:
	if vm == null or npc == null:
		return
	var st: Dictionary = state(vm)
	var key: String = npc.get_person_key()
	var pl = npc._get_player()
	var cha: int = int(pl.call("get_skill_level", "charisma")) if pl != null and pl.has_method("get_skill_level") else 0

	if action_id == "fame_buy_masterwork":
		if not is_master(vm, npc):
			return
		var m: Dictionary = st["masters"][key]
		if int(m.get("stock", 0)) <= 0:
			npc._spawn_floating_text("🏆 «Aún estoy trabajando en la siguiente pieza. Vuelve en unos días.»", Color.LIGHT_GRAY, -44.0)
			return
		if inv == null or int(inv.gold) < MASTERWORK_BUY_COST:
			npc._spawn_floating_text("Necesitas %d de oro para adquirir esta Obra Maestra" % MASTERWORK_BUY_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-MASTERWORK_BUY_COST)
		npc.personal_gold = maxi(0, int(npc.personal_gold)) + MASTERWORK_BUY_COST
		m["stock"] = int(m.get("stock", 1)) - 1
		m["last_craft_day"] = today()
		inv.add_item("masterwork_piece", 1)
		npc.modify_affinity(8)
		add_fame(vm, npc, 4, "Vendió una Obra Maestra de estilo «%s»" % str(m.get("style", "")))
		if pl != null and pl.has_method("add_skill_xp"):
			pl.add_skill_xp("crafting", 10)
		npc._spawn_floating_text("🏆🎨 «Lleva mi sello: estilo %s. Cuídala bien.» (-%d Oro)" % [str(m.get("style", "")), MASTERWORK_BUY_COST], Color.GOLD, -46.0)

	elif action_id == "fame_patronize":
		if not (npc.trade_role in VillageNPC.SHOP_ROLES) or is_master(vm, npc):
			return
		if inv == null or int(inv.gold) < PATRON_COST:
			npc._spawn_floating_text("Necesitas %d de oro para patrocinar su taller" % PATRON_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-PATRON_COST)
		npc.personal_gold = maxi(0, int(npc.personal_gold)) + PATRON_COST
		st["patron_day"][key] = today()
		npc.days_in_role = int(npc.days_in_role) + 2
		npc.modify_affinity(12)
		add_fame(vm, npc, 6, "Su taller cuenta con mecenazgo y materiales de primera")
		if int(npc.days_in_role) >= 5:
			promote_to_master(vm, npc)
			var m2: Dictionary = master_info(vm, npc)
			npc._spawn_floating_text("🛠️🌟 «¡Con estos materiales por fin he perfeccionado mi estilo «%s»!»" % str(m2.get("style", "")), Color.GOLD, -46.0)
		else:
			npc._spawn_floating_text("🛠️🤝 «Gracias a tu mecenazgo mi oficio avanza mucho más rápido.»", Color.SPRING_GREEN, -46.0)

	elif action_id == "fame_sell_masterwork":
		if inv == null or not inv.has_method("has_item") or not bool(inv.call("has_item", "masterwork_piece", 1)):
			return
		if int(npc.personal_gold) < 35:
			npc._spawn_floating_text("🏺 «Es una pieza soberbia, pero hoy no llevo suficiente oro encima.»", Color.ORANGE_RED, -44.0)
			return
		inv.remove_item("masterwork_piece", 1)
		var paid: int = VillageClans.pay_from_pocket(npc, MASTERWORK_COLLECTOR_PRICE, inv)
		npc.modify_affinity(10)
		add_fame(vm, npc, 6, "Adquirió una Obra Maestra firmada para su colección")
		npc._spawn_floating_text("🏺💰 «¡Una pieza de autor auténtica! Te pago %d de oro de mi bolsillo.»" % paid, Color.GOLD, -46.0)

	elif action_id == "fame_gift_masterwork":
		if inv == null or not inv.has_method("has_item") or not bool(inv.call("has_item", "masterwork_piece", 1)):
			return
		inv.remove_item("masterwork_piece", 1)
		npc.modify_affinity(22)
		npc.add_thought("Me regalaron una Obra Maestra firmada (+14)", 14.0)
		add_fame(vm, npc, 8, "Recibió una Obra Maestra firmada como obsequio")
		npc._spawn_floating_text("🏺🎁 «¿Una Obra Maestra para mí? ¡No tengo palabras!» (+22 Afinidad)", Color.SPRING_GREEN, -46.0)

	elif action_id == "fame_praise":
		if today() - int(st.get("last_praise_day", -99)) < PRAISE_COOLDOWN_DAYS:
			return
		st["last_praise_day"] = today()
		var chance: float = clampf(0.45 + 0.08 * float(cha) + (0.15 if int(npc.affinity) >= 25 else 0.0), 0.20, 0.88)
		if randf() < chance:
			add_fame(vm, npc, 10, "Sus méritos corren de boca en boca por el pueblo")
			npc.modify_affinity(8)
			if pl != null and pl.has_method("add_skill_xp"):
				pl.add_skill_xp("charisma", 8)
			npc._spawn_floating_text("📣🌟 «Gracias por hablar tan bien de mi trabajo en la plaza.» (+10 Fama)", Color.SPRING_GREEN, -46.0)
		else:
			npc.modify_affinity(-4)
			npc._spawn_floating_text("📣😅 Tus halagos sonaron exagerados y nadie los tomó en serio (-4 Afinidad)", Color.ORANGE_RED, -46.0)

	elif action_id == "fame_tarnish":
		if today() - int(st.get("last_praise_day", -99)) < PRAISE_COOLDOWN_DAYS:
			return
		st["last_praise_day"] = today()
		var honesty_shield: float = 0.15 * TraitCatalog.npc_tendency(npc, "honesty")
		var chance_t: float = clampf(0.38 + 0.08 * float(cha) - honesty_shield, 0.15, 0.80)
		if randf() < chance_t:
			add_fame(vm, npc, -12, "Su nombre anda en boca de todos por malas lenguas")
			npc.modify_affinity(-10)
			npc._spawn_floating_text("📣🌑 Los rumores calaron en la plaza y mancharon su reputación (-12 Fama)", Color.ORANGE, -46.0)
		else:
			npc.modify_affinity(-18)
			for o in VillageNeeds.living(vm):
				if o != npc and int(o.trade_role) != int(VillageNPC.TradeRole.CHILD):
					o.modify_affinity(-3)
			npc._spawn_floating_text("📣💢 «¡Difamador! Todo el pueblo ha visto que mientes.» (-18 Afinidad)", Color.ORANGE_RED, -46.0)

	elif action_id == "fame_probe_obsession":
		if today() == int(st.get("last_probe_day", -99)):
			return
		st["last_probe_day"] = today()
		if not (st["obsessions"] as Dictionary).has(key):
			npc._spawn_floating_text("«¿Regalos anónimos? Ni idea, forastero, yo voy a lo mío.»", Color.LIGHT_GRAY, -44.0)
			return
		var obs_p: Dictionary = st["obsessions"][key]
		var probe_chance: float = clampf(0.48 + 0.10 * float(cha), 0.25, 0.90)
		if randf() < probe_chance:
			obs_p["known_by_player"] = true
			if pl != null and pl.has_method("add_skill_xp"):
				pl.add_skill_xp("charisma", 6)
			npc._spawn_floating_text("😳💌 Se pone nervioso y delata su obsesión enfermiza por %s" % str(obs_p.get("idol_name", "")), Color.GOLD, -46.0)
		else:
			npc.modify_affinity(-4)
			npc._spawn_floating_text("😠 «¡No te metas en mi vida privada!» (-4 Afinidad)", Color.ORANGE_RED, -46.0)

	elif action_id == "fame_calm_obsessed":
		if not (st["obsessions"] as Dictionary).has(key) or not bool(st["obsessions"][key].get("known_by_player", false)):
			return
		var idol_nm: String = str(st["obsessions"][key].get("idol_name", ""))
		var calm_chance: float = clampf(0.45 + 0.10 * float(cha) + (0.15 if int(npc.affinity) >= 20 else 0.0), 0.20, 0.88)
		if randf() < calm_chance:
			st["obsessions"].erase(key)
			npc.end_errand()
			npc.modify_affinity(8)
			npc.add_thought("Me ayudaron a superar mi obsesión por %s (+8)" % idol_nm, 8.0)
			VillageChronicle.add(vm, "obsession_calmed", "Hiciste entrar en razón a %s para que dejara de acosar a %s" % [npc.npc_name, idol_nm], true)
			npc._spawn_floating_text("🧘💬 «Tienes razón... me estaba volviendo loco por %s. Lo dejaré.»" % idol_nm, Color.SPRING_GREEN, -46.0)
		else:
			npc.modify_affinity(-10)
			npc._spawn_floating_text("💢 «¡Tú no entiendes lo que siento por %s!» (-10 Afinidad)" % idol_nm, Color.ORANGE_RED, -46.0)

	elif action_id.begins_with("fame_warn_idol:"):
		var sk_warn: String = action_id.get_slice(":", 1)
		if not (st["obsessions"] as Dictionary).has(sk_warn):
			return
		var obs_warn: Dictionary = st["obsessions"][sk_warn]
		if str(obs_warn.get("idol_key", "")) != key or not bool(obs_warn.get("known_by_player", false)):
			return
		var stalker_npc = vm._get_npcs_by_person_key().get(sk_warn, null)
		var stalker_nm: String = str(obs_warn.get("stalker_name", ""))
		st["obsessions"].erase(sk_warn)
		if stalker_npc != null and not stalker_npc.is_dead:
			stalker_npc.end_errand()
			npc.modify_npc_relationship(stalker_npc, -25, "Me vigilaba y acosaba en secreto", true)
			stalker_npc.modify_affinity(-12)
		var reward: int = VillageClans.pay_from_pocket(npc, 15, inv)
		npc.modify_affinity(14)
		VillageChronicle.add(vm, "obsession_warned", "Avisaste a %s de la obsesión de %s (+%d Oro)" % [npc.npc_name, stalker_nm, reward], true)
		npc._spawn_floating_text("⚠️👁️ «¡Sabía que alguien me seguía! Gracias por avisarme (+%d Oro)»" % reward, Color.GOLD, -46.0)

	elif action_id == "fame_companion_invite":
		if companion_npc(vm) != null or int(npc.affinity) < 55:
			return
		set_companion(vm, npc, "friend")
		npc.add_thought("Acompaño a mi amigo el forastero por el valle (+6)", 6.0)
		VillageChronicle.add(vm, "companion_joined", "%s se unió a ti como compañero de viaje por amistad" % npc.npc_name, true)
		npc._spawn_floating_text("🤝🚶 «¡Cuenta conmigo! Te acompaño a donde vayas.»", Color.SPRING_GREEN, -46.0)

	elif action_id == "fame_companion_hire":
		if companion_npc(vm) != null or int(npc.affinity) < 10:
			return
		if inv == null or int(inv.gold) < COMPANION_HIRE_COST:
			npc._spawn_floating_text("Necesitas %d de oro para contratarle hoy" % COMPANION_HIRE_COST, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-COMPANION_HIRE_COST)
		npc.personal_gold = maxi(0, int(npc.personal_gold)) + COMPANION_HIRE_COST
		set_companion(vm, npc, "hired")
		npc.modify_affinity(6)
		VillageChronicle.add(vm, "companion_hired", "Contrataste a %s como escolta y acompañante (%d Oro/día)" % [npc.npc_name, COMPANION_HIRE_COST], true)
		npc._spawn_floating_text("🛡️💰 «Trato hecho (-%d Oro). Te cubriré las espaldas.»" % COMPANION_HIRE_COST, Color.GOLD, -46.0)

	elif action_id == "fame_companion_dismiss":
		if not is_companion(vm, npc):
			return
		dismiss_companion(vm)
		npc._spawn_floating_text("👋🚶 «Vuelvo a mis quehaceres. Avísame si me necesitas.»", Color.LIGHT_GRAY, -44.0)

	elif action_id == "fame_companion_backup":
		var comp_b = companion_npc(vm)
		if comp_b == null or comp_b == npc or today() == int(st["companion"].get("last_backup_day", -99)):
			return
		st["companion"]["last_backup_day"] = today()
		var comp_pow: float = 0.15 * TraitCatalog.npc_tendency(comp_b, "aggression") + 0.08 * float(cha)
		var win_chance: float = clampf(0.52 + comp_pow, 0.25, 0.88)
		if randf() < win_chance:
			npc.modify_affinity(8)
			if vm.social_director != null:
				var pe: Dictionary = vm.social_director.get_pair_entry(comp_b.get_person_key(), npc.get_person_key())
				pe["tension"] = maxf(0.0, float(pe.get("tension", 0.0)) - 8.0)
			if pl != null and pl.has_method("add_skill_xp"):
				pl.add_skill_xp("charisma", 6)
			npc._spawn_floating_text("🛡️🤝 El respaldo de %s impuso respeto a %s (+8 Afinidad)" % [comp_b.npc_name, npc.npc_name], Color.SPRING_GREEN, -46.0)
		else:
			npc.modify_affinity(-8)
			comp_b.modify_affinity(-3)
			npc._spawn_floating_text("🛡️💢 «¡No me intimidáis ni tú ni %s!» (-8 Afinidad)" % comp_b.npc_name, Color.ORANGE_RED, -46.0)
