extends RefCounted

## Menú principal de los diálogos (versión provisional, 2026-11-13; antes «UI1» en NPCDialogue): arriba solo lo del
## momento (el caso, un encargo, un aviso); debajo siempre «Charlar», «Preguntar por…», «Comerciar», «Más…» y adiós.
## Las opciones las siguen añadiendo los ~20 sistemas de siempre; aquí solo se reparten. Compras y ventas van a la
## ventana de tienda (nodo «tienda»); los datos del vecino, a «Ver ficha».

const DialogoTexto = preload("res://scripts/ui/dialogo/DialogoTexto.gd")
const NPCCharla = preload("res://scripts/enemies/NPCCharla.gd")

const NODO_TIENDA: String = "tienda"
const NODO_MAS: String = "mas_menu"
## Lo que lleva a temas de conversación (va a «Preguntar por…»).
const TALK_NEXT: Array = ["neighbor_opinions", "npc_news", "town_vote", "desire_ask", "faith_lore", "faith_ask", "character_lore", "clan_menu", "lineage_menu", "faith_confess_menu", "town_mayor_menu", "housing_menu", "family_chat"]
const GIFT_ACTIONS: Array = ["give_npc_food_ration", "needs_alms", "needs_gift", "needs_round"]
const SHADY_NEXT: Array = ["pocket_stealth_menu", "witness_manipulation_menu", "forensic_menu", "underworld_menu"]
## Lo del momento: se queda arriba del todo. Por acción o por adónde lleva.
const URGENT_ACTION_PREFIX: Array = ["case1:", "interrog_step", "trial_intervene", "social_stop_fight"]
const URGENT_NEXT: Array = ["quest_offer", "quest_progress", "public_trial_menu", "interrogation_r1"]
const URGENT_LABEL_PREFIX: Array = ["🔎", "🚨", "❗", "⚠️", "⚔️", "✋"]

const L_CHARLAR: String = "Charlar un rato"
const L_PREGUNTAR: String = "Preguntar por…"
const L_COMERCIAR: String = "Comerciar"
const L_MAS: String = "Más…"
const L_REGALAR: String = "Invitar o regalar…"
const L_TURBIO: String = "Lo turbio…"
const L_FICHA: String = "Ver ficha"
const L_VOLVER: String = "Volver"
const L_ADIOS: String = "Adiós"

## `intro_base`: el texto con el que el oficio presenta al vecino (se cambia por un saludo; va entero a la ficha).
static func organizar(npc, diag: Dictionary, intro_base: String, hay_crimen: bool) -> void:
	var start: Dictionary = diag["start"]
	var src: Array = start["choices"]
	var g: Dictionary = {"top": [], "talk": [], "gift": [], "shady": [], "shop": [], "other": [], "profile": []}
	var exit_c: Variant = null
	for i in range(src.size()):
		var c: Variant = src[i]
		if typeof(c) != TYPE_DICTIONARY:
			continue
		if _es_salida(c, i == src.size() - 1):
			exit_c = c
			continue
		var grupo: String = _grupo(c, diag, hay_crimen)
		if grupo == "shop_sub":
			(g["shop"] as Array).append_array(_filas_de_tienda((diag[str(c["next"])] as Dictionary).get("choices", [])))
		elif grupo != "":
			(g[grupo] as Array).append(c)
	g["shop"] = _filas_utiles(npc, g["shop"])
	var back: Dictionary = {"label": L_VOLVER, "next": "start"}
	var top: Array = g["top"]
	NPCCharla.anadir(npc, diag, hay_crimen)
	top.append({"label": L_CHARLAR, "next": "charla"})
	if not (g["talk"] as Array).is_empty():
		diag["talk_menu"] = {"text": "«¿Qué quieres saber?»", "choices": (g["talk"] as Array) + [back]}
		top.append({"label": L_PREGUNTAR, "next": "talk_menu"})
	if not (g["shop"] as Array).is_empty():
		diag[NODO_TIENDA] = {"text": NPCCharla.frase_tienda(npc), "choices": g["shop"], NODO_TIENDA: true}
		top.append({"label": L_COMERCIAR, "next": NODO_TIENDA})
	top.append({"label": L_MAS, "next": NODO_MAS})
	diag[NODO_MAS] = {"text": "«¿Algo más?»", "choices": _menu_mas(npc, diag, g, intro_base, back)}
	top.append(exit_c if exit_c != null else {"label": L_ADIOS, "next": "END"})
	start["choices"] = top
	start["text"] = _texto_inicio(npc, str(start.get("text", "")), intro_base)

## ¿A qué grupo va una opción? "" = se descarta (manipular testigos sin crimen abierto).
static func _grupo(c: Dictionary, diag: Dictionary, hay_crimen: bool) -> String:
	var nx: String = str(c.get("next", ""))
	var act: String = str(c.get("action", ""))
	var lbl: String = str(c.get("label", ""))
	if _es_urgente(nx, act, lbl):
		return "top"
	if act.begins_with("buy:") or act.begins_with("sell:"):
		return "shop"
	if _submenu_de_tienda(diag, nx):
		return "shop_sub"
	if nx in TALK_NEXT or DialogoTexto.limpiar_etiqueta(lbl).begins_with("Preguntar"):
		return "talk"
	if act in GIFT_ACTIONS or act.begins_with("gift_"):
		return "gift"
	if nx in SHADY_NEXT:
		return "shady" if (nx != "witness_manipulation_menu" or hay_crimen) else ""
	if act == "open_social_glossary":
		return "profile"
	return "other"

static func _es_urgente(nx: String, act: String, lbl: String) -> bool:
	if nx in URGENT_NEXT:
		return true
	for p: String in URGENT_ACTION_PREFIX:
		if act.begins_with(p):
			return true
	for p: String in URGENT_LABEL_PREFIX:
		if lbl.begins_with(p):
			return true
	return false

## Un submenú hecho solo de compras o ventas (despiece, órganos…): sus filas van a la tienda.
static func _submenu_de_tienda(diag: Dictionary, nx: String) -> bool:
	if not diag.has(nx) or not (diag[nx] is Dictionary):
		return false
	var hay_venta: bool = false
	for c in (diag[nx] as Dictionary).get("choices", []):
		var act: String = str((c as Dictionary).get("action", "")) if c is Dictionary else ""
		if act.begins_with("buy:") or act.begins_with("sell:"):
			hay_venta = true
		elif str((c as Dictionary).get("next", "")) != "start" and act != "":
			return false
	return hay_venta

static func _filas_de_tienda(opciones: Array) -> Array:
	return opciones.filter(func(c: Variant) -> bool:
		var act: String = str((c as Dictionary).get("action", "")) if c is Dictionary else ""
		return act.begins_with("buy:") or act.begins_with("sell:"))

## Lo que se le puede comprar, y lo que llevas y él compra: si no queda nada, no sale «Comerciar».
static func _filas_utiles(npc, filas: Array) -> Array:
	var jugador = npc._get_player()
	var inv: Object = jugador.get("inventory") if jugador != null else null
	return filas.filter(func(c: Variant) -> bool:
		var partes: PackedStringArray = str((c as Dictionary).get("action", "")).split(":")
		return partes[0] == "buy" or (inv != null and partes.size() >= 2 and int(inv.call("get_count", partes[1])) > 0))

static func _es_salida(c: Dictionary, es_ultima: bool) -> bool:
	var lbl: String = str(c.get("label", ""))
	return "[Salir]" in lbl or (es_ultima and str(c.get("next", "")) == "END" and str(c.get("action", "")) == "")

## «Más…»: regalos, lo turbio, lo que no encaja en otro sitio y la ficha del vecino.
static func _menu_mas(npc, diag: Dictionary, g: Dictionary, intro_base: String, back: Dictionary) -> Array:
	var out: Array = []
	for sub in [["gift_menu", "gift", L_REGALAR, "«¿Qué me ofreces?»"], ["shady_menu", "shady", L_TURBIO, "Con cuidado de que no te vean…"]]:
		var items: Array = g[sub[1]]
		if items.size() >= 2:
			diag[sub[0]] = {"text": sub[3], "choices": items + [{"label": L_VOLVER, "next": NODO_MAS}]}
			out.append({"label": sub[2], "next": sub[0]})
		else:
			out.append_array(items)
	out.append_array(g["other"])
	# La ficha sí enseña los datos: se les quitan los corchetes para que la ventana no los tome por líneas de relleno
	var datos: String = npc._get_needs_status_line().replace("[", "").replace("]", "").replace(" | ", " · ")
	var ficha: String = "%s (%s)\n%s\n\n%s" % [npc.npc_name, npc.npc_role, DialogoTexto.limpiar_texto(intro_base), datos]
	diag["npc_ficha"] = {"text": ficha, "choices": (g["profile"] as Array) + [{"label": L_VOLVER, "next": NODO_MAS}]}
	out.append({"label": L_FICHA, "next": "npc_ficha"})
	out.append(back)
	return out

## El saludo sustituye a la presentación del oficio; lo que otros sistemas añadieron (un rumor, un aviso) se queda.
static func _texto_inicio(npc, texto: String, intro_base: String) -> String:
	if intro_base == "" or not texto.contains(intro_base):
		return texto # otro sistema cambió el texto entero (calabozo…): manda lo suyo
	var extra: String = texto.replace(intro_base, "").strip_edges()
	return (NPCCharla.saludo(npc) + ("\n\n" + extra if extra != "" else "")).strip_edges()
