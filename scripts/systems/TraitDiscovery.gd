@tool
extends RefCounted

## T3: El jugador no conoce los rasgos de un vecino al principio; los va descubriendo al tratar con él.
## Lo descubierto vive en `VillageNPC.known_traits` (se guarda con la partida). Formas de descubrir:
##   confianza (afinidad 20/40/60/80), su historia personal, Carisma ≥ 3 al conocerle,
##   espiarle en sigilo, verle actuar (calumniar, pelear) y lo que otros vecinos cuentan de él.

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const TRUST_TIERS: Array[int] = [20, 40, 60, 80] # Cada umbral de afinidad que se alcanza revela un rasgo
const FIRST_IMPRESSION_CHARISMA: int = 3
const WITNESS_RADIUS: float = 170.0 # Distancia para «verle actuar»
## T2b: lo que cuenta otro vecino queda como rumor («según X») en `VillageNPC.rumored_traits` hasta que lo compruebes.
## Miente quien es poco honesto o malicioso y se lleva mal con el otro (siempre el mismo bulo para la misma pareja).
const LIE_HONESTY: float = -0.5
const LIE_MALICE: float = 0.8
const LIE_REL: int = -30
const LIE_CHANCE_PCT: int = 60

static func all_traits(npc: VillageNPC) -> Array:
	return npc.person_profile.personality if npc.person_profile != null else npc.traits

static func unknown_traits(npc: VillageNPC) -> Array[String]:
	var res: Array[String] = []
	for t in all_traits(npc):
		if not str(t) in npc.known_traits:
			res.append(str(t))
	return res

## Revela `trait_id` si el vecino lo tiene y aún no se conocía. `how` explica cómo te has enterado.
static func reveal(npc: VillageNPC, trait_id: String, how: String = "") -> bool:
	if npc == null or trait_id == "" or trait_id in npc.known_traits or not trait_id in all_traits(npc):
		return false
	npc.known_traits.append(trait_id)
	_settle_rumors(npc, trait_id)
	npc._spawn_floating_text("💡 %s es %s%s" % [npc.npc_name, TraitCatalog.npc_display(npc, trait_id), (" (" + how + ")") if how != "" else ""], Color(0.95, 0.85, 1.0), -58.0)
	return true

## Revela el primer rasgo aún desconocido (orden fijo: siempre el mismo para la misma persona).
static func reveal_next(npc: VillageNPC, how: String = "") -> bool:
	var unk: Array[String] = unknown_traits(npc)
	return false if unk.is_empty() else reveal(npc, unk[0], how)

## Revela el rasgo desconocido que más empuja una tendencia (p. ej. "malice" al verle calumniar).
static func reveal_by_tendency(npc: VillageNPC, tendency_key: String, how: String = "") -> bool:
	var best: String = ""
	var best_v: float = 0.0
	for t in unknown_traits(npc):
		var v: float = TraitCatalog.tendency([t], tendency_key)
		if v > best_v:
			best_v = v
			best = t
	return false if best == "" else reveal(npc, best, how)

## Si el jugador está cerca y ve lo que hace `npc`, descubre el rasgo que lo explica.
static func on_witnessed_behavior(npc: VillageNPC, tendency_key: String, how: String) -> bool:
	var player = npc._get_player()
	if player == null or not is_instance_valid(player) or npc.global_position.distance_to(player.global_position) > WITNESS_RADIUS:
		return false
	return reveal_by_tendency(npc, tendency_key, how)

## Confianza: cada umbral de afinidad alcanzado revela un rasgo (una sola vez por umbral).
static func check_trust(npc: VillageNPC) -> void:
	while npc.trait_trust_tier < TRUST_TIERS.size() and npc.affinity >= TRUST_TIERS[npc.trait_trust_tier]:
		npc.trait_trust_tier += 1
		reveal_next(npc, "te tiene confianza")

## Al empezar a hablar: primera impresión con Carisma alto y revisión de confianza.
static func on_dialogue_opened(npc: VillageNPC) -> void:
	check_trust(npc)
	if not npc.trait_first_impression_done:
		var player = npc._get_player()
		if player != null and player.has_method("get_skill_level") and int(player.call("get_skill_level", "charisma")) >= FIRST_IMPRESSION_CHARISMA:
			npc.trait_first_impression_done = true
			reveal_next(npc, "le calas a primera vista")

## Al confirmar `trait_id` por tu cuenta: ese rumor ya no hace falta y los rumores que lo contradicen (mismo eje)
## quedan desmentidos. Si ya conoces todos sus rasgos, cualquier otro rumor era falso.
static func _settle_rumors(npc: VillageNPC, trait_id: String) -> void:
	var all_known: bool = unknown_traits(npc).is_empty()
	for r in npc.rumored_traits.keys():
		var rs: String = str(r)
		if rs == trait_id or TraitCatalog.conflicts(rs, trait_id) or all_known:
			npc.rumored_traits.erase(r)

## T2b: ¿`teller` mentiría sobre el carácter de `other`?
static func would_lie_about(teller: VillageNPC, other: VillageNPC) -> bool:
	if teller == null or other == null or teller.person_profile == null:
		return false
	var shady: bool = TraitCatalog.npc_tendency(teller, "honesty") <= LIE_HONESTY or TraitCatalog.npc_tendency(teller, "malice") >= LIE_MALICE
	if not shady or teller.get_relationship_with_npc(other.get_person_key()) > LIE_REL:
		return false
	return abs(("lie:" + teller.get_person_key() + ":" + other.get_person_key()).hash()) % 100 < LIE_CHANCE_PCT

## Lo que `teller` cuenta del carácter de `other` (el mismo rasgo al construir el menú y al elegir). Puede ser falso.
static func hearsay_trait(teller: VillageNPC, other: VillageNPC) -> String:
	if other == null:
		return ""
	if would_lie_about(teller, other):
		var fakes: Array = []
		for t in TraitCatalog.traits_with_tone("h"):
			var ts: String = str(t)
			if not TraitCatalog.is_rare(ts) and not ts in all_traits(other) and not other.rumored_traits.has(ts) and not TraitCatalog.conflicts_with_any(ts, other.known_traits):
				fakes.append(ts)
		fakes.sort()
		if not fakes.is_empty():
			return str(fakes[abs(("fake:" + teller.get_person_key() + ":" + other.get_person_key()).hash()) % fakes.size()])
	for t in unknown_traits(other):
		if not other.rumored_traits.has(t):
			return t
	return ""

## T2b: `teller` te cuenta un rasgo de `other`; queda apuntado como rumor con su fuente.
static func hear_trait(teller: VillageNPC, other: VillageNPC) -> bool:
	var t: String = hearsay_trait(teller, other)
	if t == "" or t in other.known_traits:
		return false
	other.rumored_traits[t] = teller.npc_name
	other._spawn_floating_text("💬 Según %s, %s es %s" % [teller.npc_name, other.npc_name, TraitCatalog.npc_display(other, t)], Color(0.85, 0.85, 0.95), -58.0)
	return true

## Texto para el jugador: rasgos conocidos y una ❓ por cada uno sin descubrir.
static func known_traits_text(npc: VillageNPC) -> String:
	var parts: Array[String] = []
	for t in all_traits(npc):
		parts.append(TraitCatalog.npc_display(npc, str(t)) if str(t) in npc.known_traits else "❓")
	var txt: String = ", ".join(parts) if not parts.is_empty() else "Equilibrado"
	var rumors: Array[String] = []
	for r in npc.rumored_traits.keys():
		rumors.append("%s (según %s)" % [TraitCatalog.npc_display(npc, str(r)), str(npc.rumored_traits[r])])
	return txt + ((" · Se dice: " + ", ".join(rumors)) if not rumors.is_empty() else "")
