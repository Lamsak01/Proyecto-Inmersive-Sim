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

## Lo que `teller` cuenta del carácter de `other` en el menú de opiniones (el mismo rasgo al construir y al elegir).
static func hearsay_trait(other: VillageNPC) -> String:
	var unk: Array[String] = unknown_traits(other)
	return unk[0] if not unk.is_empty() else ""

## Texto para el jugador: rasgos conocidos y una ❓ por cada uno sin descubrir.
static func known_traits_text(npc: VillageNPC) -> String:
	var parts: Array[String] = []
	for t in all_traits(npc):
		parts.append(TraitCatalog.npc_display(npc, str(t)) if str(t) in npc.known_traits else "❓")
	return ", ".join(parts) if not parts.is_empty() else "Equilibrado"
