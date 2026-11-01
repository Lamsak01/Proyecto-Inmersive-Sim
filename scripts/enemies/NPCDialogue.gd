extends RefCounted

## Menús y acciones de diálogo de los habitantes (tiendas, interrogatorios, lore, acciones de las opciones).
## Extraído de VillageNPC.gd. Cada función recibe al NPC como primer parámetro (`npc`); VillageNPC mantiene
## funciones delgadas con los mismos nombres que delegan aquí, así que el resto del proyecto no cambia.

static func _inject_character_lore_into_dialogue(npc: VillageNPC, diag: Dictionary) -> Dictionary:
	if not diag.has("start") or typeof(diag["start"]) != TYPE_DICTIONARY:
		return diag
	var start_node: Dictionary = diag["start"]
	if not start_node.has("choices") or typeof(start_node["choices"]) != TYPE_ARRAY:
		return diag
	var ch_arr: Array = start_node["choices"]
	# Si está agraviado (compensate_family), no añadir charla amistosa hasta reconciliar
	for c in ch_arr:
		if typeof(c) == TYPE_DICTIONARY and str(c.get("action", "")) == "compensate_family":
			return diag

	var insert_idx: int = maxi(0, ch_arr.size() - 1)
	var vm_diag = npc._get_vm()
	if npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
		var has_active_case: bool = false
		if vm_diag:
			if npc.trade_role == VillageNPC.TradeRole.ROYAL_INVESTIGATOR and "active_royal_investigation" in vm_diag:
				has_active_case = bool(vm_diag.active_royal_investigation.get("active", false))
				var r_stg: String = str(vm_diag.active_royal_investigation.get("stage", ""))
				if has_active_case and r_stg in ["PUBLIC_TRIAL_PLAZA", "HUNTING_SCAPEGOAT"]:
					var sc_lbl: String = str(vm_diag.active_royal_investigation.get("verdict_target", "el acusado"))
					ch_arr.insert(0, {"label": "⚖️🔔 ¡INTERVENIR EN EL JUICIO PÚBLICO DE %s! (Salvar su vida / Alegar / Confesar)" % sc_lbl, "next": "public_trial_menu"})
					diag["public_trial_menu"] = {
						"text": "⚖️🔔 JUICIO PÚBLICO EN LA PLAZA CENTRAL — Acusado: %s\n«La sentencia real está a punto de ejecutarse. ¿Tienes algo que declarar ante la Inquisición Real y el pueblo?»" % sc_lbl,
						"choices": [
							{"label": "🗣️📜 [Alegato de Clemencia RPG] «¡Las pruebas contra %s son meramente circunstanciales! Ejecutar a un inocente sería una deshonra para la Corona.»" % sc_lbl, "next": "END", "action": "trial_intervene:clemency"},
							{"label": "💰👑 [Pagar Fianza Real de Indulto (-60 Oro)] «Yo respondo con mi oro por la inocencia de %s para conmutar la pena capital.»" % sc_lbl, "next": "END", "action": "trial_intervene:bail_innocent"},
							{"label": "✋🗡️ [Confesar el Crimen] «¡Soltadlo! %s es inocente, fui yo quien lo hizo.»" % sc_lbl, "next": "END", "action": "trial_intervene:confess"},
							{"label": "👀🤐 Callar y dejar que el Inquisidor ejecute al chivo expiatorio.", "next": "END"}
						]
					}
			elif "active_sheriff_investigation" in vm_diag:
				has_active_case = bool(vm_diag.active_sheriff_investigation.get("active", false))
		if has_active_case:
			ch_arr.insert(0, {"label": "🗣️⚖️ Defenderme en Interrogatorio / Declarar mi Coartada (Persuasión RPG)", "next": "interrogation_r1", "action": "interrog_step:init"})
	if is_instance_valid(npc._reporting_corpse_target) and npc.trade_role != VillageNPC.TradeRole.ROYAL_INVESTIGATOR:
		ch_arr.insert(0, {"label": "🚨🤫 ¡DETENER REPORTE DE %s! (Sobornar, Convencer o Intimidar)" % npc._reporting_corpse_target.npc_name, "next": "witness_manipulation_menu"})
	elif not (npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]):
		ch_arr.insert(insert_idx, {"label": "🤫 Manipular Testigo / Coartada (Silenciar, Sobornar o Inculpar a otro)", "next": "witness_manipulation_menu"})
	ch_arr.insert(insert_idx, {"label": "📖 Conocer la historia personal y el pasado de %s (+10 Relación)" % npc.npc_name, "next": "character_lore", "affinity": 10})
	ch_arr.insert(insert_idx, {"label": "🤝📓 Ver Red Social, Amigos y Rivales de %s [Glosario J]" % npc.npc_name, "next": "END", "action": "open_social_glossary"})
	ch_arr.insert(insert_idx, {"label": "🕵️ Bolsillos de %s: Hurtar o Meter objeto en sigilo [O pulsa H]" % npc.npc_name, "next": "pocket_stealth_menu"})
	if npc.need_hunger < 75.0:
		ch_arr.insert(insert_idx, {"label": "🍲 Darle 1 ración de comida de tu mochila (%s) para que se recupere gradualmente (+18 Relación)" % npc.get_nutrition_status_label(), "next": "start", "action": "give_npc_food_ration"})

	var rep_warn: String = ("\n⚠️ ¡Actualmente está yendo a reportar el cuerpo de %s!" % npc._reporting_corpse_target.npc_name) if is_instance_valid(npc._reporting_corpse_target) else ""
	var silence_stat: String = "✅ Ya pactó silencio" if npc.witness_silenced_player else "👁️ Testigo libre"
	var alibi_stat: String = " | 🤝 Te dará Coartada" if npc.witness_alibi_for_player else ""
	var frame_stat: String = (" | 👉 Inculpará a: " + npc.witness_framed_target_name) if npc.witness_framed_target_name != "" else ""
	var frame_choices: Array = []
	if npc.is_inside_tree():
		var count_f: int = 0
		for n_f in npc.get_tree().get_nodes_in_group("village_npcs"):
			if n_f is VillageNPC and n_f != npc:
				var vf := n_f as VillageNPC
				if not vf.is_dead and not (vf.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR, VillageNPC.TradeRole.TRAVELING_MERCHANT]):
					var cost_lbl: String = "Gratis por Afinidad >= 40" if npc.affinity >= 40 else "-15 Oro"
					frame_choices.append({"label": "👉 Inculpar a %s (%s) [%s]" % [vf.npc_name, vf.npc_role, cost_lbl], "next": "start", "action": "witness_frame_npc:" + vf.npc_name})
					count_f += 1
					if count_f >= 6:
						break
	frame_choices.append({"label": "⬅️ Volver al menú de manipulación", "next": "witness_manipulation_menu"})
	diag["witness_frame_select"] = {
		"text": "👉 Sembrar Rumor / Inculpar a otro habitante:\nElige a quién dirá %s que vio merodeando junto a la escena del crimen cuando lo interrogue el Comisario Vane o el Inquisidor Real:" % npc.npc_name,
		"choices": frame_choices
	}
	diag["witness_manipulation_menu"] = {
		"text": "🤫 Manipulación de Testigo y Coartadas — %s (Relación: %d)%s\nEstado actual: [%s%s%s]" % [npc.npc_name, npc.affinity, rep_warn, silence_stat, alibi_stat, frame_stat],
		"choices": [
			{"label": "🤝 Convencer por Amistad: Pedir Coartada Falsa y Silencio (Requiere Afinidad >= 35 · Gratis)", "next": "start", "action": "witness_convince_alibi"},
			{"label": "💰 Sobornar Testigo: Comprar su silencio y detener reporte (-25 Oro)", "next": "start", "action": "witness_bribe_silence"},
			{"label": "🗡️ Intimidar / Amenazar: Obligar a callar y cancelar reporte (-15 Relación)", "next": "start", "action": "witness_intimidate_silence"},
			{"label": "👉 Sembrar Rumor: «Diles que viste a otro vecino cerca del crimen» (%s)" % ("Gratis" if npc.affinity >= 40 else "-15 Oro"), "next": "witness_frame_select"},
			{"label": "⬅️ Volver a la conversación principal", "next": "start"}
		]
	}

	var p_choices: Array = []
	if npc.personal_gold > 0:
		p_choices.append({"label": "💰 Hurtar Oro del bolsillo (%d Oro)" % npc.personal_gold, "next": "start", "action": "pickpocket_gold"})
	if npc.carries_royal_safe_conduct and int(npc.pocket_items.get("royal_safe_conduct", 0)) <= 0:
		npc.pocket_items["royal_safe_conduct"] = 1
	for pk in npc.pocket_items.keys():
		var cnt: int = int(npc.pocket_items[pk])
		if cnt > 0:
			var p_info: Dictionary = SimpleInventory.CATALOG.get(str(pk), {})
			p_choices.append({"label": "🤏 Hurtar 1x %s (Tiene %d)" % [str(p_info.get("name", pk)), cnt], "next": "start", "action": "pickpocket_item:" + str(pk)})
	var player_ref = npc._get_player()
	if player_ref and "inventory" in player_ref and player_ref.inventory:
		var pinv: SimpleInventory = player_ref.inventory
		for plant_id in ["royal_safe_conduct", "poisoned_stew", "spoiled_food", "sleeping_draught", "organ_heart", "organ_kidney", "organ_liver", "bread", "country_stew"]:
			if pinv.has_item(plant_id, 1):
				p_choices.append({"label": "📥 Meter 1x %s en su bolsillo (Incriminar / Envenenar)" % pinv.get_item_name(plant_id), "next": "start", "action": "plant_pocket_item:" + plant_id})
	p_choices.append({"label": "⬅️ Volver sin tocar nada", "next": "start"})
	diag["pocket_stealth_menu"] = {
		"text": "🕵️ Bolsillos de %s (%s):\nContenido actual: %s\n(Probabilidad de sigilo: %d%% según tu Manipulación, Ganzúa Maestra y Manto Montaraz)" % [npc.npc_name, npc.npc_role, npc.get_pocket_summary_text(), int(round(npc.get_pickpocket_success_chance(player_ref) * 100.0))],
		"choices": p_choices
	}

	diag["character_lore"] = {
		"text": "📜 Historia de %s (%s):\n%s" % [npc.npc_name, npc.npc_role, npc.character_lore],
		"choices": [
			{"label": "🔍 Preguntar por lo que calla o ha observado en el valle (+6 Relación)", "next": "character_secret", "affinity": 6},
			{"label": "⬅️ Volver a la conversación principal", "next": "start"}
		]
	}
	diag["character_secret"] = {"text": "🤫 Confidencia de %s:\n%s" % [npc.npc_name, npc.character_secret], "choices": [{"label": "Guardaré el secreto. [Volver]", "next": "start"}]}

	if npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]:
		var blood_or_wound_hint: String = ""
		if player_ref:
			var p_bld: bool = player_ref.has_method("is_bloodstained") and bool(player_ref.call("is_bloodstained"))
			var p_hc_chk: HealthComponent = player_ref.get_node_or_null("HealthComponent")
			var p_wnd: bool = p_hc_chk != null and p_hc_chk.has_fresh_combat_wounds_or_makeshift()
			if p_bld or p_wnd:
				blood_or_wound_hint = "\n⚠️ (El investigador observa con recelo tus manchas de sangre o vendajes recientes)."
		diag["interrogation_r1"] = {
			"text": "🕵️‍♂️⚖️ INTERROGATORIO OFICIAL DE %s — Ronda 1/3 (Ubicación y Coartada):\n«Forastero, estamos investigando el crimen en el valle. ¿Dónde estabas a esa hora y qué hacías por los alrededores?»%s" % [npc.npc_name, blood_or_wound_hint],
			"choices": [
				{"label": "😰 «¡Yo no fui, ni siquiera pasé por esa calle en todo el día!»", "next": "interrogation_r2", "action": "interrog_step:r1_wrong_nervous"},
				{"label": "🧘 «Estaba realizando encargos de recolección y comercio entre la granja y los talleres; cualquiera pudo verme trabajando con normalidad.»", "next": "interrogation_r2", "action": "interrog_step:r1_correct"},
				{"label": "😤 «Soy libre de andar por donde quiera, no tengo que darle explicaciones a nadie.»", "next": "interrogation_r2", "action": "interrog_step:r1_wrong_hostile"}
			]
		}
		diag["interrogation_r2"] = {
			"text": "🕵️‍♂️⚖️ INTERROGATORIO OFICIAL DE %s — Ronda 2/3 (Pruebas Físicas y Forenses):\n«Hemos revisado la escena del crimen, el rastro de sangre y la autopsia en la Morgue. ¿Cómo explicas tus herramientas, las marcas de tu jornada y la naturaleza del ataque?»" % npc.npc_name,
			"choices": [
				{"label": "🤷 «Me habré manchado con pintura o tropezado en la taberna... pura casualidad.»", "next": "interrogation_r3", "action": "interrog_step:r2_wrong_excuse"},
				{"label": "🏹 «Mis manos y herramientas son de faenar y cazar bestias en el bosque/ciénaga; la herida de la víctima apunta a un asalto premeditado, no a mi oficio.»", "next": "interrogation_r3", "action": "interrog_step:r2_correct"},
				{"label": "👀 «Seguro que un lobo salvaje abrió la puerta, lo atacó y volvió a cerrar.»", "next": "interrogation_r3", "action": "interrog_step:r2_wrong_lie"}
			]
		}
		diag["interrogation_r3"] = {
			"text": "🕵️‍♂️⚖️ INTERROGATORIO OFICIAL DE %s — Ronda 3/3 (Alegato Final de Defensa):\n«Última pregunta antes de anotar mi conclusión en el expediente: ¿por qué debería descartarte como sospechoso de este crimen?»" % npc.npc_name,
			"choices": [
				{"label": "🗣️✨ [Persuasión RPG] «Porque mi declaración es coherente, no tengo móvil contra la víctima y acusar al forastero sin pruebas dejaría libre al verdadero culpable.»", "next": "END", "action": "interrog_step:r3_persuade"},
				{"label": "💰 [Sobornar con 45 Oro] «Quizás esta bolsa de oro ayude a limpiar mi nombre del expediente...»", "next": "END", "action": "interrog_step:r3_bribe"},
				{"label": "🤐 Guardar silencio y concluir el interrogatorio.", "next": "END", "action": "interrog_step:r3_silent"}
			]
		}
	return diag

static func _make_armor_menu(npc: VillageNPC, title: String, menu_key: String, items: Array) -> Dictionary:
	var ch: Array[Dictionary] = []
	for it in items:
		ch.append({"label": str(it[0]), "next": menu_key, "action": "buy_armor:%s:%d" % [str(it[1]), int(it[2])]})
	ch.append({"label": "⬅️ Volver a Categorías de Armadura", "next": "armor_menu"})
	return {"text": title, "choices": ch}

static func _build_blacksmith_dialogue(npc: VillageNPC, needs_line: String) -> Dictionary:
	var player = npc._get_player()
	var catalog_dict: Dictionary = player.get("TOOL_UPGRADE_CATALOG") if (player and "TOOL_UPGRADE_CATALOG" in player) else {}
	var upgrade_choices: Array[Dictionary] = []
	for t_id in ["sword", "hammer", "axe", "pickaxe", "bow", "sickle", "watering_can", "fishing_rod"]:
		var cur_tier: int = int(player.call("get_tool_tier", t_id)) if (player and player.has_method("get_tool_tier")) else 1
		var t_meta: Dictionary = catalog_dict.get(t_id, {})
		var t_title: String = str(t_meta.get("title", t_id))
		if cur_tier >= 3:
			upgrade_choices.append({"label": "★ %s [Nivel 3 Acero Maestro — MÁXIMO]" % t_title, "next": "upgrade_menu"})
		else:
			var next_tier: int = cur_tier + 1
			var tier_info: Dictionary = t_meta.get("tiers", {}).get(next_tier, {})
			var g_cost: int = int(tier_info.get("gold", 25))
			var mats: Dictionary = tier_info.get("mats", {})
			var mat_parts: Array[String] = []
			for m_id in mats.keys():
				mat_parts.append("%d %s" % [int(mats[m_id]), str(SimpleInventory.CATALOG.get(str(m_id), {}).get("name", str(m_id)))])
			upgrade_choices.append({"label": "⬆️ Mejorar %s a Nv.%d (%d Oro + %s)" % [t_title, next_tier, g_cost, ", ".join(mat_parts)], "next": "upgrade_menu", "action": "upgrade_tool:" + t_id})
	upgrade_choices.append({"label": "⬅️ Volver al mostrador de la Herrería", "next": "start"})

	return {
		"start": {
			"text": "Soy %s de la %s (%s). %s%s\n¡Bienvenido a la Gran Herrería y Armería! Aquí forjo armaduras y mejoro tus herramientas." % [npc.npc_name, npc.family_name, npc.npc_role, needs_line, npc._get_market_header_line()],
			"choices": [
				{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
				{"label": "⚒️ Mejorar Armas y Herramientas (Nv.1 -> Nv.2 Hierro -> Nv.3 Acero)", "next": "upgrade_menu"},
				{"label": "🛡️ Comprar Armaduras (Cuero, Hierro y Acero — 4 Piezas)", "next": "armor_menu"},
				{"label": "🔥 Fundir 1 Lingote de Acero (-10 Oro, 2 Mineral Hierro, 1 Madera)", "next": "start", "action": "forge_steel"},
				{"label": "⚙️ Vender 1 Chatarra/Reliquia de Bandido (+%d Oro)" % npc._get_dynamic_sell_price(18), "next": "start", "action": "sell:bandit_scrap:18"},
				{"label": "💎 Vender 1 Mineral de Hierro (+%d Oro)" % npc._get_dynamic_sell_price(14), "next": "start", "action": "sell:iron_ore:14"},
				{"label": "🪨 Vender 1 Piedra (+%d Oro)" % npc._get_dynamic_sell_price(7), "next": "start", "action": "sell:stone:7"},
				{"label": "🪵 Comprar 1 Tablones Reforzados (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(16), int(npc.shop_stock.get("repair_kit", 0))], "next": "start", "action": "buy:repair_kit:16"},
				{"label": "💬 Charlar sobre la forja (+8 Relación)", "next": "family_chat", "affinity": 8},
				{"label": "Nos vemos. [Salir]", "next": "END"}
			]
		},
		"upgrade_menu": {"text": "⚒️ Yunque de Mejora de Herramientas y Armas (Estilo Stardew Valley):\nElige qué herramienta o arma deseas forjar al siguiente nivel:", "choices": upgrade_choices},
		"armor_menu": {
			"text": "🛡️ Armería de Thoran (Casco, Pecho, Piernas y Botas):\nEquípalas desde tu Mochila [I] para reducir daño físico, sangrado y aturdimiento.",
			"choices": [
				{"label": "🟫 Ver Armaduras de Cuero Curtido (Ligeras, sin penalización de velocidad)", "next": "armor_leather"},
				{"label": "⬜ Ver Armaduras de Hierro Forjado (Defensa media, muy resistentes)", "next": "armor_iron"},
				{"label": "🟦 Ver Armaduras de Acero Maestro (Máxima protección del valle)", "next": "armor_steel"},
				{"label": "⬅️ Volver al mostrador", "next": "start"}
			]
		},
		"armor_leather": _make_armor_menu(npc, "🟫 Set de Armadura de Cuero Curtido (Tier 1):", "armor_leather", [
			["🪖 Comprar Capucha de Cuero (-18 Oro) [+6% Def]", "helm_leather", 18], ["🦺 Comprar Jubón de Cuero (-28 Oro) [+12% Def]", "chest_leather", 28],
			["👖 Comprar Grebas de Cuero (-22 Oro) [+8% Def]", "legs_leather", 22], ["🥾 Comprar Botas de Cuero (-16 Oro) [+5% Def, +3% Vel]", "boots_leather", 16],
		]),
		"armor_iron": _make_armor_menu(npc, "⬜ Set de Armadura de Hierro Forjado (Tier 2):", "armor_iron", [
			["🪖 Comprar Yelmo de Hierro (-36 Oro) [+11% Def]", "helm_iron", 36], ["🦺 Comprar Coraza de Hierro (-52 Oro) [+20% Def]", "chest_iron", 52],
			["👖 Comprar Quijotes de Hierro (-42 Oro) [+14% Def]", "legs_iron", 42], ["🥾 Comprar Escarpes de Hierro (-32 Oro) [+9% Def]", "boots_iron", 32],
		]),
		"armor_steel": _make_armor_menu(npc, "🟦 Set de Armadura de Acero Maestro (Tier 3):", "armor_steel", [
			["🪖 Comprar Gran Yelmo de Acero (-68 Oro) [+16% Def]", "helm_steel", 68], ["🦺 Comprar Armadura Real de Acero (-95 Oro) [+28% Def]", "chest_steel", 95],
			["👖 Comprar Grebas de Acero Maestro (-78 Oro) [+20% Def]", "legs_steel", 78], ["🥾 Comprar Botas de Acero Maestro (-62 Oro) [+13% Def]", "boots_steel", 62],
		]),
		"family_chat": {"text": "Ahora tengo mi propio edificio de Herrería separado de nuestra casa familiar. Tráeme mineral de hierro y oro cuando quieras subir tus herramientas a Hierro o Acero Maestro.", "choices": [{"label": "Buen trabajo, maestro Thoran. [Volver]", "next": "start"}]}
	}

static func _build_dialogue(npc: VillageNPC) -> Dictionary:
	var needs_line := npc._get_needs_status_line()
	var discount_tag: String = " [🌟 Aliado Familiar: -20% Dto]" if npc.affinity >= 45 else ""

	# Paso 4: Si la familia está agraviada (`affinity <= -35`) por robo o agresión, exige compensación antes de comerciar
	if npc.affinity <= -35 and not (npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.DOCTOR, VillageNPC.TradeRole.ROYAL_INVESTIGATOR, VillageNPC.TradeRole.TRAVELING_MERCHANT]):
		return {"start": {
			"text": "😠 ¡Soy %s de la %s! Has agraviado a nuestra familia (Afinidad: %d).\nNo comerciaremos contigo hasta que repares el daño o cumplas con la ley." % [npc.npc_name, npc.family_name, npc.affinity],
			"choices": [
				{"label": "💰 Pagar Compensación Familiar (-20 Oro -> Reconciliar a toda la %s)" % npc.family_name, "next": "END", "action": "compensate_family"},
				{"label": "Me marcharé. [Salir]", "next": "END"}
			]
		}}

	match npc.trade_role:
		VillageNPC.TradeRole.DOCTOR:
			return {
				"start": {
					"text": "Soy el %s (%s). %s%s\nDirijo el Hospital y la Morgue. Trato las heridas una por una en la camilla según su urgencia.\n[Stock Hospital: 🩹Vendajes: %d | 🌿Cataplasmas: %d | 🩺Botiquines: %d]" % [
						npc.npc_name, npc.npc_role, needs_line, discount_tag,
						int(npc.shop_stock.get("bandage", 0)), int(npc.shop_stock.get("herbal_poultice", 0)), int(npc.shop_stock.get("surgical_kit", 0))
					],
					"choices": [
						{"label": "🏥 Ingresar en Camilla de Urgencias (Tratamiento secuencial herida por herida) (-10 Oro)", "next": "END", "action": "doctor_heal"},
						{"label": "🩹 Comprar 1 Vendaje Limpio (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(12), int(npc.shop_stock.get("bandage", 0))], "next": "start", "action": "buy:bandage:12"},
						{"label": "🌿 Comprar 1 Cataplasma Curativa (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(10), int(npc.shop_stock.get("herbal_poultice", 0))], "next": "start", "action": "buy:herbal_poultice:10"},
						{"label": "🩺 Comprar 1 Botiquín Quirúrgico (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(24), int(npc.shop_stock.get("surgical_kit", 0))], "next": "start", "action": "buy:surgical_kit:24"},
						{"label": "🫀 Entregar Órganos para Trasplantes / Estudio Anatómico", "next": "organ_bank_menu"},
						{"label": "⚰️ Consultar Informes Forenses de la Morgue", "next": "morgue_info"},
						{"label": "Gracias, doctor. [Salir]", "next": "END"}
					]
				},
				"organ_bank_menu": {
					"text": "🫀 Banco Quirúrgico del Hospital:\n«No haré preguntas incómodas sobre su procedencia si están bien conservados. También puedes usar un Botiquín Quirúrgico desde tu Panel Clínico [H] para trasplantar órganos dañados.»",
					"choices": [
						{"label": "🫀 Vender 1 Corazón Humano (+70 Oro)", "next": "organ_bank_menu", "action": "sell:organ_heart:70"},
						{"label": "🫁 Vender 1 Hígado Humano (+60 Oro)", "next": "organ_bank_menu", "action": "sell:organ_liver:60"},
						{"label": "🫁 Vender 1 Pulmón Humano (+50 Oro)", "next": "organ_bank_menu", "action": "sell:organ_lung:50"},
						{"label": "🫘 Vender 1 Riñón Humano (+45 Oro)", "next": "organ_bank_menu", "action": "sell:organ_kidney:45"},
						{"label": "🥩 Vender 1 Estómago Humano (+40 Oro)", "next": "organ_bank_menu", "action": "sell:organ_stomach:40"},
						{"label": "👁️ Vender 1 Globo Ocular (+35 Oro)", "next": "organ_bank_menu", "action": "sell:organ_eye:35"},
						{"label": "⬅️ Volver a la consulta del Dr. Valen", "next": "start"}
					]
				},
				"morgue_info": {"text": "En la sala trasera está la Morgue Forense con 3 mesas de autopsia. Si ocurre una muerte, puedes acercarte a la camilla y pulsar [E] para leer el dictamen forense: hora exacta, arma empleada y si algún vecino vio entrar al sospechoso.", "choices": [{"label": "Entendido, revisaré las mesas de la Morgue. [Volver]", "next": "start"}]}
			}
		VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD:
			var vm = npc._get_vm()
			var w_lvl: int = int(vm.get("wanted_level")) if vm else 0
			var b_gold: int = int(vm.get("bounty_gold")) if vm else 0
			var status_crime: String = "✅ Sin cargos pendientes" if w_lvl <= 0 else ("🚨 BUSCADO (Nivel %d | Multa: %d Oro)" % [w_lvl, b_gold])
			var sh_inv_line: String = ("\n" + str(vm.call("get_sheriff_investigation_dialogue_summary"))) if (vm and vm.has_method("get_sheriff_investigation_dialogue_summary")) else ""
			return {
				"start": {
					"text": "Soy %s (%s). %s\nEstado Policial: %s%s\nDesde la Comisaría vigilamos las calles, analizamos huellas de sangre e interrogamos empezando por quien reportó el crimen." % [npc.npc_name, npc.npc_role, needs_line, status_crime, sh_inv_line],
					"choices": [
						{"label": "⚖️ Pagar Multa / Fianza Policial para limpiar historial (-%d Oro)" % maxi(15, b_gold), "next": "start", "action": "pay_police_bounty"},
						{"label": "🔒 Entregarse voluntariamente y cumplir condena en la Celda hasta las 06:00 AM", "next": "END", "action": "surrender_to_jail"},
						{"label": "⚙️ Entregar 1 Reliquia/Chatarra de Bandido por Recompensa (+22 Oro)", "next": "start", "action": "sell:bandit_scrap:22"},
						{"label": "💬 Preguntar cómo funciona la investigación de crímenes", "next": "crime_explain"},
						{"label": "Seguiré mi camino. [Salir]", "next": "END"}
					]
				},
				"crime_explain": {"text": "Cuando aparece un cadáver, inspecciono primero las huellas de sangre en la escena para deducir hacia dónde huyó el asesino. Luego interrogo a quien descubrió el cuerpo, le pregunto a quién vio cerca en ese momento y sigo el hilo de testigo en testigo.", "choices": [{"label": "Un sistema lógico e implacable. [Volver]", "next": "start"}]}
			}
		VillageNPC.TradeRole.BUTCHER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s%s%s\n[Stock Carne Cocida: %d | Pollo Asado: %d]" % [npc.npc_name, npc.family_name, npc.npc_role, needs_line, discount_tag, npc._get_market_header_line(), int(npc.shop_stock.get("cooked_meat", 0)), int(npc.shop_stock.get("roasted_chicken", 2))],
					"choices": [
						{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
						{"label": "🥚✨ Vender 1 Huevo Dorado Genética Nv.3 (+%d Oro)" % npc._get_dynamic_sell_price(32), "next": "start", "action": "sell:golden_egg:32"},
						{"label": "🦌 Vender 1 Astas de Ciervo (+%d Oro)" % npc._get_dynamic_sell_price(20), "next": "start", "action": "sell:antlers:20"},
						{"label": "🦊 Vender 1 Piel de Zorro (+%d Oro)" % npc._get_dynamic_sell_price(18), "next": "start", "action": "sell:fox_pelt:18"},
						{"label": "🐸 Vender 1 Ancas de Rana Crudas (+%d Oro)" % npc._get_dynamic_sell_price(11), "next": "start", "action": "sell:frog_legs:11"},
						{"label": "👜 Vender 1 Cuero Animal (+%d Oro)" % npc._get_dynamic_sell_price(10), "next": "start", "action": "sell:leather:10"},
						{"label": "🦴 Vender 1 Huesos / Tendones / Grasa (+%d Oro)" % npc._get_dynamic_sell_price(8), "next": "anatomy_sell"},
						{"label": "🥩 Vender 1 Carne Cruda (+%d Oro) o Pollo Crudo (+%d Oro)" % [npc._get_dynamic_sell_price(8), npc._get_dynamic_sell_price(9)], "next": "start", "action": "sell:raw_meat:8"},
						{"label": "🍖 Comprar 1 Carne Cocida (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(10), int(npc.shop_stock.get("cooked_meat", 0))], "next": "start", "action": "buy:cooked_meat:10"},
						{"label": "💬 Charlar sobre su familia y rutina (+8 Relación)", "next": "family_chat", "affinity": 8},
						{"label": "Hasta luego. [Salir]", "next": "END"}
					]
				},
				"anatomy_sell": {
					"text": "🦴 Compra de Despiece Anatómico Avanzado (Huesos, Tendones y Grasa):",
					"choices": [
						{"label": "🦴 Vender 1 Huesos Limpios (+%d Oro)" % npc._get_dynamic_sell_price(7), "next": "anatomy_sell", "action": "sell:bones:7"},
						{"label": "🧬 Vender 1 Tendones y Vísceras (+%d Oro)" % npc._get_dynamic_sell_price(9), "next": "anatomy_sell", "action": "sell:sinew_viscera:9"},
						{"label": "🕯️ Vender 1 Grasa Animal (+%d Oro)" % npc._get_dynamic_sell_price(8), "next": "anatomy_sell", "action": "sell:animal_fat:8"},
						{"label": "🍗 Vender 1 Pollo Crudo (+%d Oro)" % npc._get_dynamic_sell_price(9), "next": "anatomy_sell", "action": "sell:raw_chicken:9"},
						{"label": "⬅️ Volver al mostrador", "next": "start"}
					]
				},
				"family_chat": {"text": "En nuestra carnicería curtimos pieles y aprovechamos cada pieza anatómica. Si crías animales bien alimentados de Genética Nv.3, sus productos valen una fortuna.", "choices": [{"label": "Entendido. [Volver]", "next": "start"}]}
			}
		VillageNPC.TradeRole.BLACKSMITH:
			return _build_blacksmith_dialogue(npc, needs_line + discount_tag)
		VillageNPC.TradeRole.CARPENTER:
			return {
				"start": {
					"text": "Soy %s de la %s (%s). %s%s%s\n[Stock Tablones: %d | Madera: %d]" % [npc.npc_name, npc.family_name, npc.npc_role, needs_line, discount_tag, npc._get_market_header_line(), int(npc.shop_stock.get("repair_kit", 0)), int(npc.shop_stock.get("wood", 0))],
					"choices": [
						{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
						{"label": "🛖 Construir Cabaña de Madera en tu Campamento (Nv.2: -30 Oro)", "next": "start", "action": "upgrade_camp_house:2:30"},
						{"label": "🏡 Construir Casa de Piedra con Cofre Propio (Nv.3: -55 Oro)", "next": "start", "action": "upgrade_camp_house:3:55"},
						{"label": "⚡ Comprar 1 Bobina de Cobre para Generador/Aspersor (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(16), int(npc.shop_stock.get("copper_coil", 0))], "next": "start", "action": "buy:copper_coil:16"},
						{"label": "🪵 Vender 1 Madera (+%d Oro)" % npc._get_dynamic_sell_price(8), "next": "start", "action": "sell:wood:8"},
						{"label": "🔨 Comprar 1 Tablones Reforzados (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(15), int(npc.shop_stock.get("repair_kit", 0))], "next": "start", "action": "buy:repair_kit:15"},
						{"label": "🌲 Comprar 1 Madera (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(9), int(npc.shop_stock.get("wood", 0))], "next": "start", "action": "buy:wood:9"},
						{"label": "💬 Charlar un rato (+8 Relación)", "next": "family_chat", "affinity": 8},
						{"label": "Hasta pronto. [Salir]", "next": "END"}
					]
				},
				"family_chat": {"text": "Construimos todas las casas de esta aldea con muros sólidos y puertas de madera. Si quieres ampliar tu tienda de campaña a una Cabaña o Casa de Piedra con Cofre, yo mismo te la levanto.", "choices": [{"label": "Así se hace. [Volver]", "next": "start"}]}
			}
		VillageNPC.TradeRole.HERBALIST:
			return {"start": {
				"text": "Soy %s de la %s (%s). %s%s%s\n[Semillas Zanahoria: %d | Col: %d | Trigo: %d]" % [npc.npc_name, npc.family_name, npc.npc_role, needs_line, discount_tag, npc._get_market_header_line(), int(npc.shop_stock.get("carrot_seeds", 0)), int(npc.shop_stock.get("cabbage_seeds", 0)), int(npc.shop_stock.get("wheat_seeds", 0))],
				"choices": [
					{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
					{"label": "🧪 Comprar 1 Somnífero Nocturno (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(18), int(npc.shop_stock.get("sleeping_draught", 0))], "next": "start", "action": "buy:sleeping_draught:18"},
					{"label": "🌿 Comprar 1 Cataplasma Curativa (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(10), int(npc.shop_stock.get("herbal_poultice", 0))], "next": "start", "action": "buy:herbal_poultice:10"},
					{"label": "🩺 Comprar 1 Botiquín Quirúrgico (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(24), int(npc.shop_stock.get("surgical_kit", 0))], "next": "start", "action": "buy:surgical_kit:24"},
					{"label": "🥬 Vender 1 Col de Huerta (+%d Oro)" % npc._get_dynamic_sell_price(12), "next": "start", "action": "sell:cabbage:12"},
					{"label": "🥕 Vender 1 Zanahoria Fresca (+%d Oro)" % npc._get_dynamic_sell_price(8), "next": "start", "action": "sell:carrot:8"},
					{"label": "🌱 Comprar 2 Semillas de Zanahoria (-%d Oro)" % npc._get_dynamic_buy_price(6), "next": "start", "action": "buy2:carrot_seeds:6"},
					{"label": "🌱 Comprar 2 Semillas de Col (-%d Oro)" % npc._get_dynamic_buy_price(8), "next": "start", "action": "buy2:cabbage_seeds:8"},
					{"label": "🌾 Comprar 2 Semillas de Trigo (-%d Oro)" % npc._get_dynamic_buy_price(8), "next": "start", "action": "buy2:wheat_seeds:8"},
					{"label": "Salir.", "next": "END"}
				]
			}}
		VillageNPC.TradeRole.FISHMONGER:
			return {"start": {
				"text": "Soy %s de la %s (%s). %s%s%s\n[Stock Pan: %d | Abono: %d]" % [npc.npc_name, npc.family_name, npc.npc_role, needs_line, discount_tag, npc._get_market_header_line(), int(npc.shop_stock.get("bread", 0)), int(npc.shop_stock.get("fertilizer", 0))],
				"choices": [
					{"label": "📜 Negocio, Escritura de Propiedad y Caja Registradora", "next": "END", "action": "open_business_panel"},
					{"label": "Vender 1 Siluro Nocturno (+%d Oro)" % npc._get_dynamic_sell_price(22), "next": "start", "action": "sell:night_catfish:22"},
					{"label": "Vender 1 Carpa Dorada (+%d Oro)" % npc._get_dynamic_sell_price(15), "next": "start", "action": "sell:golden_carp:15"},
					{"label": "Vender 1 Trucha de Río (+%d Oro)" % npc._get_dynamic_sell_price(10), "next": "start", "action": "sell:river_trout:10"},
					{"label": "Vender 1 Gavilla de Trigo (+%d Oro)" % npc._get_dynamic_sell_price(9), "next": "start", "action": "sell:wheat:9"},
					{"label": "Comprar 1 Hogaza de Pan (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(8), int(npc.shop_stock.get("bread", 0))], "next": "start", "action": "buy:bread:8"},
					{"label": "Comprar 1 Abono Orgánico (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(6), int(npc.shop_stock.get("fertilizer", 0))], "next": "start", "action": "buy:fertilizer:6"},
					{"label": "Salir.", "next": "END"}
				]
			}}
		VillageNPC.TradeRole.INNKEEPER:
			return {"start": {
				"text": "¡Bienvenido a la Posada y Casino El Jabalí Dorado! Soy %s, Chef y Posadera. %s%s%s\nAquí el tiempo se detiene mientras juegas al Póker, Blackjack, Ruleta o Billar con los vecinos." % [npc.npc_name, needs_line, discount_tag, npc._get_market_header_line()],
				"choices": [
					{"label": "🃏🎱 Sentarse a la Mesa de Casino y Billar (Póker, 21, Ruleta y Billar)", "next": "END", "action": "open_tavern_games"},
					{"label": "🛌 Alquilar habitación y dormir hasta las 06:00 AM (-8 Oro)", "next": "END", "action": "rent_tavern_bed"},
					{"label": "🍗 Comprar 1 Pollo Asado Crujiente (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(13), int(npc.shop_stock.get("roasted_chicken", 0))], "next": "start", "action": "buy:roasted_chicken:13"},
					{"label": "🐸 Vender 1 Ancas de Rana al Ajillo (+%d Oro)" % npc._get_dynamic_sell_price(24), "next": "start", "action": "sell:fried_frog_legs:24"},
					{"label": "🍲 Comprar 1 Estofado Campesino (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(14), int(npc.shop_stock.get("country_stew", 0))], "next": "start", "action": "buy:country_stew:14"},
					{"label": "🍞 Comprar 1 Hogaza de Pan (-%d Oro) [Stock: %d]" % [npc._get_dynamic_buy_price(7), int(npc.shop_stock.get("bread", 0))], "next": "start", "action": "buy:bread:7"},
					{"label": "Solo pasaba a saludar. [Salir]", "next": "END"}
				]
			}}
		VillageNPC.TradeRole.FAMILY_MEMBER:
			return {"start": {
				"text": "Soy %s de la %s (%s). %s\n%s" % [npc.npc_name, npc.family_name, npc.npc_role, needs_line, npc.character_tagline],
				"choices": [
					{"label": "🎁 Regalar 1 Hogaza de Pan para su mesa familiar (+22 Relación)", "next": "start", "action": "gift_bread"},
					{"label": "Hasta luego. [Salir]", "next": "END"}
				]
			}}
		VillageNPC.TradeRole.TRAVELING_MERCHANT:
			if npc.merchant_id == "casimir":
				return {
					"start": {
						"text": "Soy %s (%s). %s\nPorto el 📜 Salvoconducto Real de la Cancillería (Presupuesto actual: 💰 %d Oro). Paso una vez por semana para comprar herramientas manufacturadas, lingotes y madera labrada para las cuencas mineras del norte." % [npc.npc_name, npc.npc_role, needs_line, maxi(0, npc.personal_gold)],
						"choices": [
							{"label": "🔥 Vender 1 Lingote de Acero (+38 Oro) [Solo compra manufacturas]", "next": "start", "action": "sell:steel_ingot:38"},
							{"label": "🔨 Vender 1 Tablones Reforzados (+24 Oro)", "next": "start", "action": "sell:repair_kit:24"},
							{"label": "⚡ Vender 1 Bobina de Cobre (+26 Oro)", "next": "start", "action": "sell:copper_coil:26"},
							{"label": "⚙️ Vender 1 Reliquia/Chatarra de Ruinas (+25 Oro)", "next": "start", "action": "sell:bandit_scrap:25"},
							{"label": "💎 Vender 1 Mineral de Hierro (+18 Oro)", "next": "start", "action": "sell:iron_ore:18"},
							{"label": "🗝️👑 Comprar 1 Ganzúa Maestra de Relojero (-48 Oro) [-65% detección al forzar puertas/cofres]", "next": "start", "action": "buy_unlimited:master_lockpick:48"},
							{"label": "🪤👑 Comprar 1 Cepo de Acero de Frontera (-26 Oro) [Trampa desplegable: 35 Daño + 100 Stun]", "next": "start", "action": "buy_unlimited:steel_bear_trap:26"},
							{"label": "🥫👑 Comprar 1 Conserva Real de Extramuros (-22 Oro) [Importación Real]", "next": "start", "action": "buy_unlimited:royal_ration:22"},
							{"label": "📜 Preguntar por su Salvoconducto Real y las Tierras Reales", "next": "safe_conduct_info"},
							{"label": "Buen viaje, Maese Casimir. [Salir]", "next": "END"}
						]
					},
					"safe_conduct_info": {"text": "«Este Salvoconducto Real lleva el sello lacrado del Canciller. Es el único documento que permite cruzar los puestos de guardia que rodean este valle.\n\nY no se te ocurra asaltar a un enviado real: si falto a mi cita en la capital, suspenderán las caravanas durante un mes entero y enviarán al Inquisidor Real Alistair a buscar un culpable.»", "choices": [{"label": "Lo tendré muy en cuenta. [Volver]", "next": "start"}]}
				}
			return {
				"start": {
					"text": "Soy %s (%s). %s\nPorto el 📜 Salvoconducto Real (Presupuesto actual: 💰 %d Oro). En las Tierras Reales cazar está prohibido bajo pena de horca, pero como este valle está tan aislado el Rey lo tolera. Vengo una vez por semana a comprar legalmente pieles y carnes para revenderlas fuera." % [npc.npc_name, npc.npc_role, needs_line, maxi(0, npc.personal_gold)],
					"choices": [
						{"label": "🦌 Vender 1 Astas de Ciervo (+30 Oro) [Alta demanda en la Corte]", "next": "start", "action": "sell:antlers:30"},
						{"label": "🦊 Vender 1 Piel de Zorro (+28 Oro)", "next": "start", "action": "sell:fox_pelt:28"},
						{"label": "🥚✨ Vender 1 Huevo Dorado Genética Nv.3 (+44 Oro)", "next": "start", "action": "sell:golden_egg:44"},
						{"label": "👜 Vender 1 Cuero Curtido (+16 Oro)", "next": "start", "action": "sell:leather:16"},
						{"label": "🍖 Vender 1 Carne Cocida (+15 Oro) o Carne Cruda (+12 Oro)", "next": "start", "action": "sell:cooked_meat:15"},
						{"label": "🦴 Vender 1 Huesos Limpios (+11 Oro)", "next": "start", "action": "sell:bones:11"},
						{"label": "🧥👑 Comprar 1 Manto de Camuflaje Montaraz (-52 Oro) [-40% detección de guardias, animales e Inquisidor]", "next": "start", "action": "buy_unlimited:ranger_camo_cloak:52"},
						{"label": "🧪🐍 Comprar 1 Veneno Paralizante de Extramuros (-28 Oro) [+50 Stun en impactos durante 60s]", "next": "start", "action": "buy_unlimited:royal_paralytic_venom:28"},
						{"label": "🥫👑 Comprar 1 Conserva Real de Extramuros (-22 Oro) [Importación Real]", "next": "start", "action": "buy_unlimited:royal_ration:22"},
						{"label": "📜 Preguntar por las leyes de caza del Reino y su Salvoconducto", "next": "hunting_law_info"},
						{"label": "Buen viaje, Valeria. [Salir]", "next": "END"}
					]
				},
				"hunting_law_info": {"text": "«Fuera de esta frontera todos los ciervos y zorros son propiedad de la Corona. Aquí os dejan cazar porque enviar carros de grano cuesta demasiado.\n\nGracias a mi Salvoconducto Real puedo sacar vuestras pieles legalmente cada semana e inyectar oro fresco en el pueblo. Si alguien me matara, el valle quedaría aislado y arruinado durante semanas... y la Inquisición Real vendría a cobrar sangre.»", "choices": [{"label": "Un negocio redondo para todos. [Volver]", "next": "start"}]}
			}
		VillageNPC.TradeRole.ROYAL_INVESTIGATOR:
			var vm_inv = npc._get_vm()
			var inv_report: String = str(vm_inv.call("get_royal_investigation_dialogue_summary")) if (vm_inv and vm_inv.has_method("get_royal_investigation_dialogue_summary")) else "Expediente Real en curso."
			var detailed_list: String = str(vm_inv.call("get_royal_investigation_detailed_suspects_text")) if (vm_inv and vm_inv.has_method("get_royal_investigation_detailed_suspects_text")) else inv_report
			return {
				"start": {
					"text": "Soy el %s (%s). %s\n%s" % [npc.npc_name, npc.npc_role, needs_line, inv_report],
					"choices": [
						{"label": "📋 Consultar lista detallada de interrogatorios, distancias y coartadas", "next": "suspect_list"},
						{"label": "⚖️ Preguntar por su filosofía y plazo real de investigación", "next": "philosophy_info"},
						{"label": "No le interrumpo más, Inquisidor. [Salir]", "next": "END"}
					]
				},
				"suspect_list": {"text": detailed_list, "choices": [{"label": "Entendido. [Volver]", "next": "start"}]},
				"philosophy_info": {"text": "«La Corona me envió a este rincón olvidado con una única orden: hallar al asesino del mercader real antes de que se reanude la ruta comercial (plazo máximo de 19 días).\n\nNo tengo prisa por cerrar el caso en un solo día: interrogo uno por uno a TODOS los habitantes del pueblo (empezando por quienes estaban más cerca de la escena), compruebo líneas de visión, descarto a quienes estaban lejos del lugar del crimen y verifico coartadas mutuas. Pero cuando concluya el expediente, alguien pagará con su cuello.»", "choices": [{"label": "Una justicia metódica e implacable. [Volver]", "next": "start"}]}
			}
		_:
			var camp_note: String = "\n[⛺ Desahuciado de la Posada: Sobreviviendo en un Campamento Rústico a las afueras por falta de oro]" if npc.is_vagrant_camper else ""
			return {"start": {
				"text": "Soy %s (%s). %s%s\n%s" % [npc.npc_name, npc.npc_role, needs_line, camp_note, npc.character_tagline],
				"choices": [
					{"label": "🍞 Invitarle a una Hogaza de Pan (+20 Relación)", "next": "start", "action": "gift_bread"},
					{"label": "Nos vemos. [Salir]", "next": "END"}
				]
			}}

static func on_dialogue_action(npc: VillageNPC, action_id: String) -> void:
	var player = npc._get_player()
	if not player or not ("inventory" in player) or not player.inventory:
		return
	var inv: SimpleInventory = player.inventory
	var vm = npc._get_vm()

	if action_id == "open_social_glossary":
		var soc_ui = npc.get_tree().root.find_child("SocialGlossaryUI", true, false)
		if soc_ui and soc_ui.has_method("open_panel"):
			soc_ui.call_deferred("open_panel", npc)
		return

	if action_id == "pickpocket_gold":
		npc.attempt_pickpocket_or_plant(player, "steal_gold")
		return

	if action_id.begins_with("pickpocket_item:"):
		npc.attempt_pickpocket_or_plant(player, "steal_item", action_id.get_slice(":", 1))
		return

	if action_id == "plant_pocket_item:" or action_id.begins_with("plant_pocket_item:"):
		npc.attempt_pickpocket_or_plant(player, "plant_item", action_id.get_slice(":", 1))
		return

	if action_id.begins_with("trial_intervene:"):
		var trial_mode: String = action_id.get_slice(":", 1)
		if vm and vm.has_method("resolve_public_trial_intervention"):
			vm.call("resolve_public_trial_intervention", npc, player, trial_mode)
		return

	if action_id.begins_with("interrog_step:"):
		var step_cmd: String = action_id.get_slice(":", 1)
		match step_cmd:
			"init":
				npc._interrog_correct_steps = 0
				npc._interrog_penalty_acc = 0
			"r1_correct":
				npc._interrog_correct_steps += 1
				npc._spawn_floating_text("📝 «Una coartada razonable... sigamos.»", Color(0.75, 0.96, 0.80), -40.0)
			"r1_wrong_nervous":
				npc._interrog_penalty_acc += 14
				npc._spawn_floating_text("🤨 «Te contradices y pareces nervioso (+14% sospecha).»", Color.ORANGE, -40.0)
			"r1_wrong_hostile":
				npc._interrog_penalty_acc += 20
				npc._spawn_floating_text("😠 «Tu actitud hostil solo te incrimina más (+20% sospecha).»", Color.ORANGE_RED, -40.0)
			"r2_correct":
				npc._interrog_correct_steps += 1
				npc._spawn_floating_text("📝 «Tiene sentido para alguien que caza y trabaja en el valle...»", Color(0.75, 0.96, 0.80), -40.0)
			"r2_wrong_excuse":
				npc._interrog_penalty_acc += 16
				npc._spawn_floating_text("🤨 «¿Pintura en la taberna? Qué excusa tan burda (+16% sospecha).»", Color.ORANGE, -40.0)
			"r2_wrong_lie":
				npc._interrog_penalty_acc += 18
				npc._spawn_floating_text("😠 «No te burles de esta investigación (+18% sospecha).»", Color.ORANGE_RED, -40.0)
			"r3_persuade", "r3_bribe", "r3_silent":
				if vm and vm.has_method("resolve_player_interrogation_outcome"):
					vm.call("resolve_player_interrogation_outcome", npc, player, step_cmd, npc._interrog_correct_steps, npc._interrog_penalty_acc)
		return

	if action_id == "witness_convince_alibi":
		var charisma_bonus_aff: int = int(round(float(player.call("get_skill_bonus", "charisma")) * 100.0)) if player.has_method("get_skill_bonus") else 0
		var req_aff: int = maxi(15, 35 - charisma_bonus_aff)
		if npc.affinity < req_aff:
			npc._spawn_floating_text("❌ Necesitas al menos %d de Relación para pedirle una coartada (Actual: %d)" % [req_aff, npc.affinity], Color.ORANGE_RED, -44.0)
			return
		npc.clear_witness_memories_of_player()
		npc.witness_alibi_for_player = true
		npc.add_thought("Acepté cubrir al Forastero como coartada (+4)", 4.0)
		npc._spawn_floating_text("🤝🤫 «Somos amigos: si preguntan, juraré que estuviste conmigo y no vi nada.»", Color.SPRING_GREEN, -46.0)
		return

	if action_id == "witness_bribe_silence":
		if inv.gold < 25:
			npc._spawn_floating_text("❌ Necesitas 25 Oro para sobornar a %s" % npc.npc_name, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-25)
		npc.personal_gold = maxi(0, npc.personal_gold) + 25
		npc.clear_witness_memories_of_player()
		npc.modify_affinity(5)
		npc.add_thought("Recibió una bolsa de oro por guardar silencio (+8)", 8.0)
		npc._spawn_floating_text("💰🤐 «Por mí como si nunca hubieras pasado por aquí...» (-25 Oro)", Color.GOLD, -46.0)
		return

	if action_id == "witness_intimidate_silence":
		npc.clear_witness_memories_of_player()
		npc.modify_affinity(-15)
		npc.add_thought("Amenazado por el Forastero para callar (-15)", -15.0)
		npc._spawn_floating_text("😰🤐 «¡Está bien, no diré ni una palabra a la guardia!» (-15 Relación)", Color.ORANGE, -46.0)
		return

	if action_id.begins_with("witness_frame_npc:"):
		var f_target: String = action_id.get_slice(":", 1)
		if npc.affinity < 40:
			if inv.gold < 15:
				npc._spawn_floating_text("❌ Necesitas 15 Oro (o Afinidad >= 40) para sembrar este rumor", Color.ORANGE_RED, -44.0)
				return
			inv.add_gold(-15)
			npc.personal_gold = maxi(0, npc.personal_gold) + 15
		npc.clear_witness_memories_of_player()
		npc.witness_framed_target_name = f_target
		npc._spawn_floating_text("👉🗣️ «Cuando me interrogue la guardia o el Inquisidor, diré que vi a %s cerca del crimen.»" % f_target, Color.VIOLET, -46.0)
		return

	if action_id == "compensate_family":
		if inv.gold < 20:
			npc._spawn_floating_text("Necesitas 20 Oro para compensar a la familia", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-20)
		npc.affinity = maxi(10, npc.affinity + 50)
		if vm and vm.has_method("modify_family_reputation") and npc.family_id != "none":
			vm.call("modify_family_reputation", npc.family_id, 50, "Compensación familiar pagada", npc)
		npc._spawn_floating_text("🤝 Familia %s reconciliada (-20 Oro)" % npc.family_name, Color.SPRING_GREEN, -44.0)
		return

	if action_id == "doctor_heal":
		if vm and vm.has_method("_use_hospital_emergency_bed"):
			vm.call("_use_hospital_emergency_bed", player)
		return

	if action_id == "pay_police_bounty":
		if vm and vm.has_method("pay_bounty_fine"): vm.call("pay_bounty_fine", player)
		return

	if action_id == "surrender_to_jail":
		if vm and vm.has_method("send_player_to_jail"): vm.call("send_player_to_jail", player)
		return

	if action_id.begins_with("upgrade_camp_house:"):
		if not npc.is_at_shop_counter():
			npc._spawn_floating_text("🚫 Ahora no estoy en la Carpintería. Búscame en mi mostrador en horario laboral.", Color.ORANGE_RED, -44.0)
			return
		var up_parts := action_id.split(":")
		var target_t: int = int(up_parts[1])
		if target_t >= 3 and npc.need_hunger < 46.0:
			npc._spawn_floating_text("🪚🥺 Estoy demasiado débil por la desnutrición (%d%%) para levantar obras Nv.3. Necesito comer y recuperarme gradualmente." % int(round(npc.need_hunger)), Color.ORANGE_RED, -44.0)
			return
		if target_t >= 3 and npc.get_job_efficiency() < 0.75:
			npc._spawn_floating_text("🪚⏳ Aún soy %s: necesito al menos 5 días en el oficio (75%%) para levantar Casas de Piedra Nv.3" % npc.get_job_efficiency_label(), Color.GOLD, -44.0)
			return
		var base_cost: int = int(up_parts[2])
		var final_cost: int = int(round(float(base_cost) * 0.8)) if npc.affinity >= 45 else base_cost
		var camp = npc.get_tree().get_first_node_in_group("campsite")
		if not camp or not camp.has_method("upgrade_player_house"):
			return
		if int(camp.get("house_tier")) >= target_t:
			npc._spawn_floating_text("🏡 Ya tienes esa mejora construida en tu Campamento", Color.GOLD, -44.0)
			return
		if inv.gold < final_cost:
			npc._spawn_floating_text("Necesitas %d Oro para esta obra" % final_cost, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-final_cost)
		camp.call("upgrade_player_house", target_t)
		npc.modify_affinity(15)
		npc._spawn_floating_text("🏡 ¡Bram construyó tu vivienda Nv.%d en el Campamento! (-%d Oro)" % [target_t, final_cost], Color.SPRING_GREEN, -46.0)
		return

	if action_id == "open_business_panel":
		if vm and vm.has_method("open_business_management_ui"): vm.call_deferred("open_business_management_ui", int(npc.trade_role))
		return

	if action_id == "open_tavern_games":
		var games_ui = npc.get_tree().root.find_child("TavernGamesUI", true, false)
		if games_ui and games_ui.has_method("open_games"): games_ui.call_deferred("open_games")
		return

	if action_id == "rent_tavern_bed":
		if inv.gold < 8:
			npc._spawn_floating_text("Necesitas 8 Oro para alquilar cama", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-8)
		var surv: SurvivalComponent = player.get_node_or_null("SurvivalComponent")
		var stam: StaminaComponent = player.get_node_or_null("StaminaComponent")
		var health: HealthComponent = player.get_node_or_null("HealthComponent")
		if surv:
			surv.restore_sleep(100.0)
			surv.restore_hunger(25.0)
		if stam:
			stam.current_stamina = stam.max_stamina
			stam.stamina_changed.emit(stam.current_stamina, stam.max_stamina)
		if health:
			health.heal(40.0)
		if WorldClock:
			WorldClock.sleep_until_morning()
		if player.has_method("_spawn_floating_text"):
			player._spawn_floating_text("🛌 Dormiste en la Taberna (+100% Sueño, +40 HP)", Color.GOLD, -44.0)
		return

	if action_id == "give_npc_food_ration":
		var food_options: Array[String] = ["country_stew", "roasted_chicken", "cooked_meat", "cooked_fish", "fried_frog_legs", "bread", "cabbage", "carrot"]
		for f_id in food_options:
			if inv.remove_item(f_id, 1):
				var f_name: String = inv.get_item_name(f_id)
				var nut_gain: float = 44.0 if f_id in ["country_stew", "roasted_chicken", "cooked_meat", "cooked_fish", "fried_frog_legs"] else 34.0
				npc.feed_npc_gradual(nut_gain)
				npc.need_social = minf(100.0, npc.need_social + 20.0)
				npc.modify_affinity(18)
				if vm and vm.has_method("modify_family_reputation") and npc.family_id != "none":
					vm.call("modify_family_reputation", npc.family_id, 12, "Alimentó a " + npc.npc_name, npc)
				npc.add_thought("Me dieron %s cuando tenía hambre (+15)" % f_name, 15.0)
				npc._spawn_floating_text("🍲↗ ¡Gracias por %s! Digeriendo y recuperando fuerzas gradualmente..." % f_name, Color.SPRING_GREEN, -44.0)
				return
		npc._spawn_floating_text("❌ No llevas ninguna comida en tu mochila (Pan, Carne, Estofado, Pescado, Verdura...)", Color.ORANGE_RED, -44.0)
		return

	if action_id == "gift_bread":
		if inv.remove_item("bread", 1):
			npc.modify_affinity(20)
			if vm and vm.has_method("modify_family_reputation") and npc.family_id != "none":
				vm.call("modify_family_reputation", npc.family_id, 12, "Regalo de pan a " + npc.npc_name, npc)
			npc.feed_npc_gradual(38.0)
			npc.need_social = minf(100.0, npc.need_social + 25.0)
			npc.add_thought("Recibió pan recién horneado (+12)", 12.0)
			npc._spawn_floating_text("🍞↗ ¡Gracias por el pan! (Digeriendo gradualmente)", Color.GOLD, -44.0)
		else:
			npc._spawn_floating_text("No tienes Hogaza de Pan", Color.ORANGE_RED, -44.0)
		return

	if action_id == "forge_steel":
		if not npc.is_at_shop_counter():
			npc._spawn_floating_text("🚫 No estoy junto a la fragua ahora mismo. Vuelve cuando atienda la Herrería.", Color.ORANGE_RED, -44.0)
			return
		if npc.need_hunger < 46.0:
			npc._spawn_floating_text("🔥🥺 Me tiembla el pulso por la desnutrición (%d%%). Necesito comer e ir recuperando fuerzas antes de fundir Acero." % int(round(npc.need_hunger)), Color.ORANGE_RED, -44.0)
			return
		if npc.get_job_efficiency() < 0.65:
			npc._spawn_floating_text("🔥⏳ Aún soy %s: necesito más días de práctica para fundir Lingotes de Acero" % npc.get_job_efficiency_label(), Color.GOLD, -44.0)
			return
		if inv.gold < 10:
			npc._spawn_floating_text("Necesitas 10 Oro para fundir Acero", Color.ORANGE_RED, -44.0)
			return
		if not inv.has_item("iron_ore", 2) or not inv.has_item("wood", 1):
			npc._spawn_floating_text("Requiere 2 Mineral de Hierro y 1 Madera", Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-10)
		inv.remove_item("iron_ore", 2)
		inv.remove_item("wood", 1)
		inv.add_item("steel_ingot", 1)
		if player.has_method("add_skill_xp"):
			player.call("add_skill_xp", "crafting", 10)
		npc.modify_affinity(6)
		npc.add_thought("Forjó acero de primera calidad (+8)", 8.0)
		npc._spawn_floating_text("🔥 +1 Lingote de Acero Forjado (-10 Oro)", Color.CYAN, -44.0)
		return

	if action_id.begins_with("upgrade_tool:"):
		if not npc.is_at_shop_counter():
			npc._spawn_floating_text("🚫 No estoy en el yunque de la Herrería ahora mismo. Vuelve en mi turno de mostrador.", Color.ORANGE_RED, -44.0)
			return
		var t_id: String = action_id.get_slice(":", 1)
		var cur_t_lvl: int = int(player.call("get_tool_tier", t_id)) if player.has_method("get_tool_tier") else 1
		if cur_t_lvl >= 2 and npc.need_hunger < 46.0:
			npc._spawn_floating_text("⚒️🥺 Me tiemblan las manos por la desnutrición (%d%%). Necesito comer y recuperarme gradualmente para forjar Nv.3." % int(round(npc.need_hunger)), Color.ORANGE_RED, -44.0)
			return
		if cur_t_lvl >= 2 and npc.get_job_efficiency() < 0.75:
			npc._spawn_floating_text("⚒️⏳ Aún soy %s: necesito al menos 5 días de experiencia (75%%) para forjar Acero Maestro Nv.3" % npc.get_job_efficiency_label(), Color.GOLD, -44.0)
			return
		if player.has_method("upgrade_tool"):
			if bool(player.call("upgrade_tool", t_id)):
				if player.has_method("add_skill_xp"):
					player.call("add_skill_xp", "crafting", 20)
				npc.modify_affinity(10)
				npc.add_thought("Mejoró un arma/herramienta en la fragua (+10)", 10.0)
		return

	var parts := action_id.split(":")
	if parts.size() != 3:
		return
	var cmd := parts[0]
	var item_id := parts[1]
	var price := int(parts[2])

	# Prohibido comprar o vender en cualquier tienda si el dependiente NO está físicamente atendiendo su mostrador
	if npc.trade_role in [VillageNPC.TradeRole.BLACKSMITH, VillageNPC.TradeRole.BUTCHER, VillageNPC.TradeRole.CARPENTER, VillageNPC.TradeRole.FISHMONGER, VillageNPC.TradeRole.HERBALIST, VillageNPC.TradeRole.INNKEEPER]:
		if not npc.is_at_shop_counter():
			npc._spawn_floating_text("🚫 Estoy fuera del mostrador (%s). No puedo vender ni comprar hasta volver a la tienda." % npc.get_activity_description(), Color.ORANGE_RED, -44.0)
			return

	if cmd == "buy_armor" and item_id.ends_with("_steel") and npc.get_job_efficiency() < 0.75:
		npc._spawn_floating_text("🛡️⏳ Aún soy %s: necesito al menos 5 días en la forja (75%%) para templar Armaduras de Acero Maestro" % npc.get_job_efficiency_label(), Color.GOLD, -44.0)
		return
	# Fase 8: Precios dinámicos de Oferta/Demanda y descuentos de Socio/Dueño (-30%) o Aliado (-20%)
	if cmd == "sell":
		if not (npc.trade_role in [VillageNPC.TradeRole.SHERIFF, VillageNPC.TradeRole.GUARD, VillageNPC.TradeRole.TRAVELING_MERCHANT]):
			price = npc._get_dynamic_sell_price(price)
	elif cmd in ["buy", "buy2", "buy_unlimited"]:
		if npc.trade_role != VillageNPC.TradeRole.TRAVELING_MERCHANT:
			price = npc._get_dynamic_buy_price(price)
	elif cmd == "buy_armor":
		if vm and vm.has_method("is_player_owner_or_partner") and bool(vm.call("is_player_owner_or_partner", int(npc.trade_role))):
			price = maxi(1, int(round(float(price) * 0.70)))
		elif npc.affinity >= 45:
			price = maxi(1, int(round(float(price) * 0.80)))

	var is_partner_shop: bool = (vm and "shop_businesses" in vm and vm.shop_businesses.has(int(npc.trade_role)) and str(vm.shop_businesses[int(npc.trade_role)].get("owner_mode", "NPC")) == "PARTNER")

	if cmd == "buy_armor" or cmd == "buy_unlimited":
		if inv.gold < price:
			npc._spawn_floating_text("Oro insuficiente (%d Oro)" % price, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-price)
		var v_cut0: int = int(round(float(price) * 0.5)) if is_partner_shop else 0
		npc.personal_gold = maxi(0, npc.personal_gold) + (price - v_cut0)
		if v_cut0 > 0:
			vm.shop_businesses[int(npc.trade_role)]["vault_gold"] = int(vm.shop_businesses[int(npc.trade_role)].get("vault_gold", 0)) + v_cut0
		inv.add_item(item_id, 1)
		if cmd == "buy_armor":
			inv.equip_armor_item(item_id, player)
			npc.add_thought("Vendió una pieza de armadura (+8)", 8.0)
		else:
			npc._spawn_floating_text("+1 %s (-%d Oro)" % [inv.get_item_name(item_id), price], Color.SPRING_GREEN, -44.0)
		return

	if cmd == "sell":
		if npc.trade_role == VillageNPC.TradeRole.TRAVELING_MERCHANT and npc.personal_gold < price:
			npc._spawn_floating_text("💰 No me queda suficiente presupuesto esta semana (%d Oro restante). Volveré la próxima semana." % maxi(0, npc.personal_gold), Color.GOLD, -44.0)
			return
		if inv.remove_item(item_id, 1):
			inv.add_gold(price)
			if npc.trade_role == VillageNPC.TradeRole.TRAVELING_MERCHANT:
				npc.personal_gold = maxi(0, npc.personal_gold - price)
			else:
				npc.personal_gold = maxi(0, npc.personal_gold - int(ceil(float(price) * 0.5)))
			npc.shop_stock[item_id] = int(npc.shop_stock.get(item_id, 0)) + 1
			if item_id in ["wood", "iron_ore", "leather", "herbal_poultice", "bread", "fertilizer", "cooked_meat"]:
				npc.workshop_materials[item_id] = int(npc.workshop_materials.get(item_id, 0)) + 1
			if vm and "shop_businesses" in vm and vm.shop_businesses.has(int(npc.trade_role)):
				vm.shop_businesses[int(npc.trade_role)]["stock_override"] = npc.shop_stock.duplicate()
			npc.modify_affinity(4)
			npc._spawn_floating_text("+%d Oro (Vendido %s)" % [price, inv.get_item_name(item_id)], Color.GOLD, -44.0)
		else:
			npc._spawn_floating_text("No tienes %s" % inv.get_item_name(item_id), Color.ORANGE_RED, -44.0)
	elif cmd in ["buy", "buy2"]:
		var qty: int = 2 if cmd == "buy2" else 1
		var avail: int = int(npc.shop_stock.get(item_id, 0))
		if avail < qty:
			npc._spawn_floating_text("Stock insuficiente" if qty > 1 else ("Sin stock hoy de %s" % inv.get_item_name(item_id)), Color.ORANGE_RED, -44.0)
			return
		if inv.gold < price:
			npc._spawn_floating_text("Oro insuficiente (%d Oro)" % price, Color.ORANGE_RED, -44.0)
			return
		inv.add_gold(-price)
		var v_cut: int = int(round(float(price) * 0.5)) if is_partner_shop else 0
		npc.personal_gold = maxi(0, npc.personal_gold) + (price - v_cut)
		npc.shop_stock[item_id] = avail - qty
		if vm and "shop_businesses" in vm and vm.shop_businesses.has(int(npc.trade_role)):
			vm.shop_businesses[int(npc.trade_role)]["stock_override"] = npc.shop_stock.duplicate()
			if v_cut > 0:
				vm.shop_businesses[int(npc.trade_role)]["vault_gold"] = int(vm.shop_businesses[int(npc.trade_role)].get("vault_gold", 0)) + v_cut
		inv.add_item(item_id, qty)
		npc._spawn_floating_text("+%d %s (-%d Oro)" % [qty, inv.get_item_name(item_id), price], Color.SPRING_GREEN, -44.0)
