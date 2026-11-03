@tool
extends RefCounted

## Recuerdos que se degradan (bloques R, `docs/PLAN_RECUERDOS.md`).
## Cada chisme de `VillageManager.social_event_log` guarda, por vecino que lo sabe:
##   ev["mem"][clave]    fuerza del recuerdo 0–100 (si falta: 100 protagonistas, 80 el resto)
##   ev["forgot"][clave] true si ya lo olvidó (sigue en `known_by` para no romper la cadena de quién se lo contó)
##   ev["ver"][clave]    su versión: {"exag": 0–2, "swap_from": nombre, "swap_to": nombre}; vacía = la verdad

const TraitCatalog = preload("res://scripts/data/TraitCatalog.gd")

const MEM_PROTAGONIST: float = 100.0
const MEM_DEFAULT: float = 80.0 # Testigos y partidas viejas
const MEM_HEARD: float = 70.0 # Quien lo oye contar
const MEM_RETELL_BONUS: float = 10.0
const DECAY_PER_DAY: float = 8.0
const DECAY_PROTAGONIST: float = 1.5
const DECAY_MEMORY_WEIGHT: float = 0.4 # Memorioso (+1) baja un 40 % más lento; Olvidadizo (−1), un 40 % más rápido
const DISTORT_BASE: float = 0.08
const DISTORT_PER_LIAR: float = 0.12 # Por cada punto de honestidad negativa
const DISTORT_PER_FORGET: float = 0.20 # Cuanto peor lo recuerda, más se equivoca
const DISTORT_PROTAGONIST_MULT: float = 0.3
const DISTORT_MAX: float = 0.40
const SWAP_SHARE: float = 0.4 # De las deformaciones, cuántas cambian a una persona (el resto exagera)

const EXAG_BY_TYPE: Dictionary = {
	"fight": [" y dicen que corrió la sangre", " y dicen que casi se matan"],
	"breakup": [" y dicen que a gritos", " y dicen que se tiraron los platos a la cabeza"],
	"couple": [" y dicen que ya hablan de boda", " y dicen que esperan un hijo"],
	"rejection": [" y dicen que delante de todos", " y dicen que se rió en su cara"],
	"feud": [" y dicen que no se pueden ni ver", " y dicen que se juraron venganza"],
}
const EXAG_GENERIC: Array = [" (o eso dicen)", ", y dicen que es peor de lo que parece"]

static func _protagonist(ev: Dictionary, key: String) -> bool:
	return key != "" and (key == str(ev.get("actor_id", "")) or key == str(ev.get("target_id", "")))

## ¿Lo sabe y lo recuerda?
static func knows(ev: Dictionary, key: String) -> bool:
	return (ev.get("known_by", {}) as Dictionary).has(key) and not bool((ev.get("forgot", {}) as Dictionary).get(key, false))

static func strength(ev: Dictionary, key: String) -> float:
	var mem: Dictionary = ev.get("mem", {})
	if mem.has(key):
		return float(mem[key])
	return MEM_PROTAGONIST if _protagonist(ev, key) else MEM_DEFAULT

static func _set_strength(ev: Dictionary, key: String, v: float) -> void:
	if not ev.has("mem"):
		ev["mem"] = {}
	ev["mem"][key] = clampf(v, 0.0, 100.0)

static func version(ev: Dictionary, key: String) -> Dictionary:
	return (ev.get("ver", {}) as Dictionary).get(key, {})

static func is_distorted(ev: Dictionary, key: String) -> bool:
	var v: Dictionary = version(ev, key)
	return int(v.get("exag", 0)) > 0 or str(v.get("swap_to", "")) != ""

static func decay_rate(npc: VillageNPC, ev: Dictionary) -> float:
	if _protagonist(ev, npc.get_person_key()):
		return DECAY_PROTAGONIST
	var m: float = TraitCatalog.npc_tendency(npc, "memory")
	return clampf(DECAY_PER_DAY * (1.0 - DECAY_MEMORY_WEIGHT * m), 2.0, 14.0)

## Cada día, cada vecino recuerda un poco peor lo que sabe. Al llegar a 0, lo olvida.
static func daily_decay(vm: VillageManager) -> void:
	var by_key: Dictionary = vm._get_npcs_by_person_key()
	for ev in vm._get_live_gossip():
		for key in (ev["known_by"] as Dictionary).keys():
			var k: String = str(key)
			if not knows(ev, k):
				continue
			var npc: VillageNPC = by_key.get(k, null)
			if npc == null:
				continue
			var s: float = strength(ev, k) - decay_rate(npc, ev)
			_set_strength(ev, k, s)
			if s <= 0.0:
				if not ev.has("forgot"):
					ev["forgot"] = {}
				ev["forgot"][k] = true

## `teller` acaba de contarle `ev` a `listener`: el que lo cuenta lo refresca; el que lo oye se queda con la versión
## de quien se lo contó, quizá deformada un poco más.
static func on_told(vm: VillageManager, ev: Dictionary, teller: VillageNPC, listener: VillageNPC) -> void:
	var tk: String = teller.get_person_key()
	var lk: String = listener.get_person_key()
	_set_strength(ev, tk, strength(ev, tk) + MEM_RETELL_BONUS)
	_set_strength(ev, lk, MEM_HEARD)
	if ev.has("forgot"):
		(ev["forgot"] as Dictionary).erase(lk)
	var ver: Dictionary = version(ev, tk).duplicate()
	var rng: RandomNumberGenerator = vm.social_director.rng if vm.social_director != null else RandomNumberGenerator.new()
	if rng.randf() < distort_chance(ev, teller):
		_distort(vm, ev, ver, teller, listener, rng)
	if not ev.has("ver"):
		ev["ver"] = {}
	if ver.is_empty():
		(ev["ver"] as Dictionary).erase(lk)
	else:
		ev["ver"][lk] = ver

static func distort_chance(ev: Dictionary, teller: VillageNPC) -> float:
	var tk: String = teller.get_person_key()
	var p: float = DISTORT_BASE
	p += DISTORT_PER_LIAR * maxf(0.0, -TraitCatalog.npc_tendency(teller, "honesty"))
	p += DISTORT_PER_FORGET * (1.0 - strength(ev, tk) / 100.0)
	if _protagonist(ev, tk):
		p *= DISTORT_PROTAGONIST_MULT
	return clampf(p, 0.0, DISTORT_MAX)

static func _distort(vm: VillageManager, ev: Dictionary, ver: Dictionary, teller: VillageNPC, listener: VillageNPC, rng: RandomNumberGenerator) -> void:
	var can_swap: bool = str(ver.get("swap_to", "")) == ""
	if can_swap and (rng.randf() < SWAP_SHARE or int(ver.get("exag", 0)) >= 2):
		var names: Array[String] = []
		var swappable: Array = [str(ev.get("target_name", ""))] if str(ev.get("swap_only", "")) == "target" else [str(ev.get("actor_name", "")), str(ev.get("target_name", ""))]
		for nm in swappable:
			if nm != "" and nm != listener.npc_name and nm != teller.npc_name:
				names.append(nm)
		var others: Array = []
		for n in vm.get_tree().get_nodes_in_group("village_npcs"):
			# Nadie que ya salga en el chisme (p. ej. la pareja engañada no puede acabar siendo «el amante»)
			if n is VillageNPC and not n.is_dead and n != teller and n != listener and not (n.npc_name in [str(ev.get("actor_name", "")), str(ev.get("target_name", ""))]) and not str(ev.get("summary", "")).contains(n.npc_name):
				others.append(n.npc_name)
		if not names.is_empty() and not others.is_empty():
			ver["swap_from"] = names[rng.randi() % names.size()]
			ver["swap_to"] = str(others[rng.randi() % others.size()])
			return
	if int(ver.get("exag", 0)) < 2:
		ver["exag"] = int(ver.get("exag", 0)) + 1

## Texto del chisme tal como lo cuenta quien tiene la versión `ver_key` ("" = la verdad).
## `base` es el texto sin deformar (ver `VillageSocialLife.gossip_text`).
static func render(ev: Dictionary, base: String, ver_key: String, with_exag: bool = true, with_swap: bool = true) -> String:
	var v: Dictionary = version(ev, ver_key) if ver_key != "" else {}
	var txt: String = base
	var sf: String = str(v.get("swap_from", ""))
	if with_swap and sf != "":
		txt = txt.replace(sf, str(v.get("swap_to", "")))
	var ex: int = int(v.get("exag", 0))
	if with_exag and ex > 0:
		var opts: Array = EXAG_BY_TYPE.get(str(ev.get("type", "")), EXAG_GENERIC)
		txt = txt.trim_suffix(".") + str(opts[mini(ex, opts.size()) - 1])
	return txt
