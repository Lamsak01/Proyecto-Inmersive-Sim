class_name MascotaNecesidades
extends RefCounted

## MascotaNecesidades: el hambre y el sueño de una mascota. Digiere poco a poco lo que come, come en casa si su familia
## puede darle, y solo tras tres días enteros sin comer empieza a morirse de hambre. Con hambre anda más despacio.
## Pieza de DomesticPet (tanda 4b-3 del paso a 3D, 2026-11-14).

const DIGIERE_POR_S: float = 0.42
const HAMBRE_POR_S: float = 0.098      ## despierta (100 % → 0 % en unas 72 h de juego)
const HAMBRE_DORMIDA_POR_S: float = 0.055
const DESCANSA_POR_S: float = 1.25
const CANSANCIO_POR_S: float = 0.145
const CANSANCIO_CON_HAMBRE: float = 1.25 ## se cansa más con el estómago vacío…
const HAMBRE_SIN_EFECTO: float = 60.0    ## …hasta este nivel de saciedad
const QUIERE_COMER: float = 70.0       ## por debajo de esto busca su cuenco
const AUN_DIGIERE: float = 10.0
const CUENCO_M: float = 0.78           ## a esta distancia de su casa ya alcanza el cuenco
const RACION_CASA: float = 38.0
const INANICION_CADA_S: float = 3.5
const INANICION_DANO: float = 3.0
const FLOJA: float = 33.33             ## por debajo va a media marcha
const MEDIA: float = 66.67


static func pasar(m: DomesticPet, delta: float) -> void:
	if m.digestion_buffer > 0.0:
		var absorbe: float = minf(m.digestion_buffer, DIGIERE_POR_S * delta)
		m.digestion_buffer -= absorbe
		m.need_hunger = minf(100.0, m.need_hunger + absorbe)
	else:
		m.need_hunger = maxf(0.0, m.need_hunger - (HAMBRE_DORMIDA_POR_S if m.is_sleeping else HAMBRE_POR_S) * delta)
	if m.is_sleeping:
		m.need_energy = minf(100.0, m.need_energy + DESCANSA_POR_S * delta)
	else:
		var con_hambre: float = lerpf(CANSANCIO_CON_HAMBRE, 1.0, clampf(m.need_hunger / HAMBRE_SIN_EFECTO, 0.0, 1.0))
		m.need_energy = maxf(0.0, m.need_energy - CANSANCIO_POR_S * con_hambre * delta)
	if m.need_hunger < QUIERE_COMER and m.digestion_buffer < AUN_DIGIERE and not m.is_hostile and m.flee_timer <= 0.0:
		_comer_en_casa(m)
	if m.need_hunger <= 0.0 and m.digestion_buffer <= 0.0:
		_pasar_hambre(m, delta)


## Va a su casa y, si su familia sigue pudiendo darle, come de su cuenco.
static func _comer_en_casa(m: DomesticPet) -> void:
	if m.sitio.distance_to(m.casa) > CUENCO_M:
		m.paseo_meta = m.casa
		return
	var vm: Node = m.get_tree().get_first_node_in_group("village_manager")
	if m.family_id == "none" or vm == null or not vm.has_method("can_family_feed_pet") or not bool(vm.call("can_family_feed_pet", m.family_id)):
		return
	m.digestion_buffer = clampf(m.digestion_buffer + RACION_CASA, 0.0, maxf(18.0, 100.0 - m.need_hunger))
	m.is_fed_today = true
	m.decir("%s comió en casa" % m.pet_name, Color.SPRING_GREEN)


static func _pasar_hambre(m: DomesticPet, delta: float) -> void:
	m.starve_timer -= delta
	if m.starve_timer > 0.0:
		return
	m.starve_timer = INANICION_CADA_S
	var dano := DamageData.new()
	dano.amount = INANICION_DANO
	m.health_comp.take_damage(dano)
	m.decir("%s se muere de hambre" % m.pet_name, Color.ORANGE_RED)


## Cuánto de su velocidad normal conserva según el hambre que tiene (1 = bien comida).
static func brio(m: DomesticPet) -> float:
	if m.need_hunger < FLOJA:
		return lerpf(0.45, 0.7, clampf(m.need_hunger / FLOJA, 0.0, 1.0))
	if m.need_hunger < MEDIA:
		return lerpf(0.7, 1.0, (m.need_hunger - FLOJA) / (MEDIA - FLOJA))
	return 1.0
