class_name MascotaCasa
extends RefCounted

## MascotaCasa: la vida tranquila de una mascota alrededor de su casa. De día pasea cerca, sin meterse en los edificios;
## de noche o cuando está cansada vuelve a su cama y duerme; el perro guardián espanta a los zorros que se acercan.
## Pieza de DomesticPet (tanda 4b-3 del paso a 3D, 2026-11-14): todo en metros sobre el suelo.
## TRADUCTOR: para no pasear por dentro de las casas pregunta al pueblo en el mapa plano (`clamp_point_outside_buildings`).

const HORAS_NOCHE: Vector2i = Vector2i(22, 6)   ## (se acuesta, se levanta)
const SUENO: float = 25.0             ## con menos energía que esto se va a dormir…
const DESCANSADA: float = 92.0        ## …y no se levanta hasta recuperar esto
const SIN_FUERZAS: float = 2.0        ## tan agotada se duerme donde esté
const CAMA_CERCA_M: float = 0.9
const VUELTA_A_LA_CAMA_M_S: float = 2.0
const VUELTA_MAX_S: float = 3.2       ## si en este tiempo no llega a su cama, se duerme donde esté
const PASEO_S: Vector2 = Vector2(2.0, 4.5)
const PASEO_PERRO_M: float = 2.0      ## cuánto se aleja de su casa
const PASEO_GUARDIAN_M: float = 1.57
const PASO_PERRO_M_S: float = 2.0
const PASO_GATO_M_S: float = 1.68
const LLEGA_M: float = 0.22
const HUECO_PROTA_M: float = 0.84     ## se aparta si tiene al protagonista más cerca que esto
const APARTARSE_M_S: float = 3.25
const VIGILA_CADA_S: float = 0.45
const VIGILA_HAMBRE_MIN: float = 15.0 ## con mucha hambre o sueño no vigila
const VIGILA_ENERGIA_MIN: float = 22.0
const ZORRO_CERCA_M: float = 5.5
const ENTRE_LADRIDOS_S: float = 4.5
const ESPECIE_ZORRO: int = 2          ## WildAnimal.SpeciesType.FOX


static func es_de_noche() -> bool:
	var hora: int = int(WorldClock.current_hour)
	return hora >= HORAS_NOCHE.x or hora < HORAS_NOCHE.y


## ¿Le toca dormir? De noche (menos el guardián), si tiene sueño, o si ya duerme y aún no ha descansado.
static func toca_dormir(m: DomesticPet) -> bool:
	return (es_de_noche() and not m.is_guard_dog) or m.need_energy < SUENO or (m.is_sleeping and m.need_energy < DESCANSADA)


## Vuelve a su cama y se duerme (o donde esté, si tarda demasiado o no puede más).
static func dormir(m: DomesticPet, delta: float) -> void:
	var a_casa: Vector2 = m.casa - m.sitio
	if not m.is_sleeping and a_casa.length() > CAMA_CERCA_M and m.vuelta_s < VUELTA_MAX_S and m.need_energy > SIN_FUERZAS:
		m.vuelta_s += delta
		m.andar = a_casa.normalized() * VUELTA_A_LA_CAMA_M_S
		return
	if not m.is_sleeping:
		m.is_sleeping = true
		m.vuelta_s = 0.0
		m.decir("%s se echó a dormir" % m.pet_name, Color(0.75, 0.85, 1.0))
	m.andar = Vector2.ZERO


## Pasea alrededor de su casa y se aparta si el protagonista se le echa encima.
static func pasear(m: DomesticPet, delta: float) -> void:
	m.is_sleeping = false
	m.vuelta_s = 0.0
	m.paseo_s -= delta
	if m.paseo_s <= 0.0:
		m.paseo_s = randf_range(PASEO_S.x, PASEO_S.y)
		m.paseo_meta = _sitio_de_paseo(m)
	var falta: Vector2 = m.paseo_meta - m.sitio
	var paso_m_s: float = (PASO_PERRO_M_S if m.pet_type == DomesticPet.PetType.DOG else PASO_GATO_M_S) * MascotaNecesidades.brio(m)
	m.andar = (falta.normalized() * paso_m_s if falta.length() > LLEGA_M else Vector2.ZERO) + _apartarse_del_prota(m)


static func _sitio_de_paseo(m: DomesticPet) -> Vector2:
	var radio: float = PASEO_GUARDIAN_M if m.is_guard_dog else PASEO_PERRO_M
	var meta: Vector2 = m.casa + Vector2(randf_range(-radio, radio), randf_range(-radio, radio))
	var vm: Node = m.get_tree().get_first_node_in_group("village_manager")
	if vm != null and vm.has_method("clamp_point_outside_buildings"):
		meta = Lugar.a_suelo(vm.call("clamp_point_outside_buildings", Lugar.a_mapa(m.casa), Lugar.a_mapa(meta)))
	return meta


static func _apartarse_del_prota(m: DomesticPet) -> Vector2:
	var pl: Node = m.get_tree().get_first_node_in_group("player")
	if pl == null:
		return Vector2.ZERO
	var de_el: Vector2 = m.sitio - Lugar.de(pl)
	var d: float = de_el.length()
	if d >= HUECO_PROTA_M:
		return Vector2.ZERO
	return (de_el / d if d >= 0.001 else Vector2.RIGHT) * ((HUECO_PROTA_M - d) / HUECO_PROTA_M) * APARTARSE_M_S


## (Perro guardián) Si hay un zorro cerca de su casa, va a por él, lo espanta y ladra.
static func vigilar(m: DomesticPet, delta: float) -> void:
	if m.pet_type != DomesticPet.PetType.DOG or not m.is_guard_dog or m.is_sleeping or m.need_hunger <= VIGILA_HAMBRE_MIN or m.need_energy <= VIGILA_ENERGIA_MIN:
		return
	m.vigila_s -= delta
	if m.vigila_s > 0.0:
		return
	m.vigila_s = VIGILA_CADA_S
	for nodo: Node in m.get_tree().get_nodes_in_group("wild_animals"):
		var zorro: WildAnimal = nodo as WildAnimal
		if zorro == null or int(zorro.species) != ESPECIE_ZORRO or not zorro.is_alive_in_ecosystem() or zorro.sitio.distance_to(m.casa) > ZORRO_CERCA_M:
			continue
		m.paseo_meta = zorro.sitio
		zorro.huir_de(m.sitio)
		if m.ladrido_s <= 0.0:
			m.ladrido_s = ENTRE_LADRIDOS_S
			m.decir("¡GUAU GUAU! (zorro ahuyentado)", Color.GOLD)
			var pl: Node = m.get_tree().get_first_node_in_group("player")
			if pl != null and pl.has_method("show_hint"):
				pl.call("show_hint", "%s ha ladrado y ahuyentado a un zorro que se acercaba." % m.pet_name)
		return
