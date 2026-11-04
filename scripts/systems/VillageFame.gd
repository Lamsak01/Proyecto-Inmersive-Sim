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
	for k in ["scores", "reasons", "masters", "patron_day"]:
		if not st.has(k) or not (st[k] is Dictionary):
			st[k] = {}
	if not st.has("last_praise_day"):
		st["last_praise_day"] = -99
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
	return " · ".join(parts)

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
