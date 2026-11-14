class_name MascotaPelea
extends RefCounted

## MascotaPelea: qué hace una mascota cuando le hacen daño. El gato sale huyendo; el perro se revuelve contra el
## protagonista: lo persigue, avisa y muerde, hasta que se le pasa, lo pierde de vista o lo dejan aturdido.
## Pieza de DomesticPet (tanda 4b-3 del paso a 3D, 2026-11-14): todo en metros sobre el suelo.

const HUIDA_M_S: float = 4.14
const HUIDA_S: float = 6.0
const ENFADO_S: float = 14.0
const PIERDE_DE_VISTA_M: float = 10.64
const ACOSO_M_S: float = 3.81
const MUERDE_DESDE_M: float = 1.0     ## a esta distancia deja de correr y prepara el mordisco
const MUERDE_ALCANZA_M: float = 1.23
const AVISO_S: float = 0.4
const ENTRE_MORDISCOS_S: float = 1.05
const MORDISCO_DANO: float = 9.0
const MORDISCO_SANGRA: float = 18.0


## Le acaban de hacer daño: el perro se enfada con quien fue; el gato huye de él.
static func reaccionar(m: DomesticPet, data: DamageData) -> void:
	if m.pet_type == DomesticPet.PetType.DOG:
		m.is_hostile = true
		m.hostile_timer = ENFADO_S
		m.add_to_group("enemies")
		return
	var agresor: Node = data.source if data != null and is_instance_valid(data.source) else null
	m.flee_timer = HUIDA_S
	m.flee_de = Lugar.de(agresor) if agresor is Node2D or agresor is Node3D else m.sitio


static func huir(m: DomesticPet, delta: float) -> void:
	m.flee_timer -= delta
	m.is_sleeping = false
	var fuera: Vector2 = (m.sitio - m.flee_de).normalized()
	m.andar = (fuera if fuera != Vector2.ZERO else Vector2.RIGHT) * HUIDA_M_S


static func calmar(m: DomesticPet) -> void:
	m.is_hostile = false
	m.bite_windup_timer = 0.0
	m.remove_from_group("enemies")


## Un paso de la pelea del perro con el protagonista.
static func pelear(m: DomesticPet, delta: float) -> void:
	m.andar = Vector2.ZERO
	m.hostile_timer -= delta
	var pl: Node = m.get_tree().get_first_node_in_group("player")
	if m.hostile_timer <= 0.0 or pl == null or _fuera_de_alcance(m, pl):
		calmar(m)
		return
	m.is_sleeping = false
	if m.stagger_timer > 0.0:
		m.stagger_timer = maxf(0.0, m.stagger_timer - delta)
		m.bite_windup_timer = 0.0
	elif m.bite_windup_timer > 0.0:
		m.bite_windup_timer = maxf(0.0, m.bite_windup_timer - delta)
		if m.bite_windup_timer <= 0.0:
			_morder(m, pl)
	elif m.sitio.distance_to(Lugar.de(pl)) > MUERDE_DESDE_M:
		m.andar = (Lugar.de(pl) - m.sitio).normalized() * ACOSO_M_S * MascotaNecesidades.brio(m)
	elif m.attack_cooldown <= 0.0:
		m.bite_windup_timer = AVISO_S
		m.decir("¡!", Color.ORANGE_RED)


## El protagonista está preso, en otro piso o demasiado lejos: el perro lo deja.
static func _fuera_de_alcance(m: DomesticPet, pl: Node) -> bool:
	var vm: Node = m.get_tree().get_first_node_in_group("village_manager")
	if vm != null and (vm.get("player_being_escorted_to_jail") == true or vm.get("player_in_jail") == true or int(vm.get("player_elevation_level")) != 0):
		return true
	return m.sitio.distance_to(Lugar.de(pl)) > PIERDE_DE_VISTA_M


static func _morder(m: DomesticPet, pl: Node) -> void:
	m.attack_cooldown = ENTRE_MORDISCOS_S
	if m.sitio.distance_to(Lugar.de(pl)) > MUERDE_ALCANZA_M or not pl.has_method("take_damage"):
		return
	var brio: float = MascotaNecesidades.brio(m)
	var mordisco := DamageData.new()
	mordisco.amount = MORDISCO_DANO * brio
	mordisco.type = CombatConstants.DamageType.CUT
	mordisco.bleed_buildup = MORDISCO_SANGRA * brio
	mordisco.source = m
	pl.call("take_damage", mordisco)
	m.decir("¡Mordisco de %s!" % m.pet_name, Color.ORANGE_RED)
