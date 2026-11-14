class_name MascotaTrato
extends RefCounted

## MascotaTrato: lo que pasa cuando el protagonista usa [E] con una mascota: darle de comer si lleva algo que le guste,
## acariciarla o, si está muerta, desollarla (que es un delito). También guarda y carga su estado.
## Pieza de DomesticPet (tanda 4b-3 del paso a 3D, 2026-11-14).

const COMIDA_PERRO: Array[String] = ["raw_meat", "raw_chicken", "cooked_meat"]
const COMIDA_GATO: Array[String] = ["river_trout", "golden_carp", "raw_chicken", "cooked_fish"]
const ACEPTA_COMIDA: float = 80.0     ## con menos saciedad que esto acepta comida aunque ya haya comido hoy
const RACION: float = 42.0
const CURA_AL_COMER: float = 15.0
const AFECTO_COMIDA: float = 20.0
const AFECTO_CARICIA: float = 5.0
const EXPERIENCIA_ANIMALES: int = 8
const DESCANSO_AL_ACARICIAR: float = 10.0 ## aguante que recupera el protagonista
const ANIMO_VECINOS_M: float = 10.1   ## los vecinos a esta distancia se alegran de verla contenta
const ANIMO_VECINOS: float = 6.0


static func usar(m: DomesticPet, player: Node) -> void:
	if player == null or m.corpse_looted:
		return
	var inv: SimpleInventory = player.get("inventory") as SimpleInventory
	if m.is_dead:
		_desollar(m, inv)
	elif m.is_stunned_flag:
		m.decir("%s está aturdido" % m.pet_name, Color.SKY_BLUE)
	elif not _dar_de_comer(m, player, inv):
		_acariciar(m, player)


static func _desollar(m: DomesticPet, inv: SimpleInventory) -> void:
	m.corpse_looted = true
	m.visible = false
	m.al_cambiar_de_estado()
	var vm: Node = m.get_tree().get_first_node_in_group("village_manager")
	if vm != null and vm.has_method("report_pet_assault_crime"):
		vm.call("report_pet_assault_crime", m)
	if inv == null:
		return
	inv.add_item("raw_meat", 1)
	if m.pet_type == DomesticPet.PetType.DOG:
		inv.add_item("leather", 1)
	m.decir("Desollaste a %s" % m.pet_name, Color.ORANGE_RED)


## Si tiene hambre y el protagonista lleva algo que le guste, se lo come. Devuelve si comió.
static func _dar_de_comer(m: DomesticPet, player: Node, inv: SimpleInventory) -> bool:
	if inv == null or (m.is_fed_today and m.need_hunger >= ACEPTA_COMIDA):
		return false
	for comida: String in (COMIDA_PERRO if m.pet_type == DomesticPet.PetType.DOG else COMIDA_GATO):
		if not inv.has_item(comida, 1):
			continue
		var nombre: String = inv.get_item_name(comida)
		inv.remove_item(comida, 1)
		m.is_fed_today = true
		m.digestion_buffer = clampf(m.digestion_buffer + RACION, 0.0, maxf(20.0, 100.0 - m.need_hunger))
		m.health_comp.heal(CURA_AL_COMER)
		var mano: float = 1.0 + (float(player.call("get_skill_bonus", "animals")) if player.has_method("get_skill_bonus") else 0.0)
		m.affection = clampf(m.affection + AFECTO_COMIDA * mano, 0.0, 100.0)
		if player.has_method("add_skill_xp"):
			player.call("add_skill_xp", "animals", EXPERIENCIA_ANIMALES)
		m.decir("%s comió %s (lealtad %d %%)" % [m.pet_name, nombre, int(m.affection)], Color.SPRING_GREEN)
		_alegrar_a_los_vecinos(m)
		return true
	return false


static func _acariciar(m: DomesticPet, player: Node) -> void:
	m.affection = clampf(m.affection + AFECTO_CARICIA, 0.0, 100.0)
	m.decir("%s: %s (afecto %d %%)" % [m.pet_name, "¡Guau guau!" if m.pet_type == DomesticPet.PetType.DOG else "¡Prrr miau!", int(m.affection)], Color.PINK)
	_alegrar_a_los_vecinos(m)
	var aguante: StaminaComponent = player.get_node_or_null("StaminaComponent") as StaminaComponent
	if aguante != null:
		aguante.current_stamina = minf(aguante.max_stamina, aguante.current_stamina + DESCANSO_AL_ACARICIAR)
		aguante.stamina_changed.emit(aguante.current_stamina, aguante.max_stamina)


static func _alegrar_a_los_vecinos(m: DomesticPet) -> void:
	for vecino: Node in m.get_tree().get_nodes_in_group("village_npcs"):
		if vecino.has_method("add_thought") and Lugar.de(vecino).distance_to(m.sitio) <= ANIMO_VECINOS_M:
			vecino.call("add_thought", "Vio a %s feliz (+6)" % m.pet_name, ANIMO_VECINOS)


static func guardar(m: DomesticPet) -> Dictionary:
	return {
		"pet_name": m.pet_name, "is_fed_today": m.is_fed_today, "affection": m.affection,
		"need_hunger": m.need_hunger, "digestion_buffer": m.digestion_buffer, "need_energy": m.need_energy,
		"is_dead": m.is_dead, "corpse_looted": m.corpse_looted,
		"x_m": m.sitio.x, "z_m": m.sitio.y, "hp": m.health_comp.current_health,
	}


static func cargar(m: DomesticPet, data: Dictionary) -> void:
	m.is_fed_today = bool(data.get("is_fed_today", true))
	m.affection = clampf(float(data.get("affection", 75.0)), 0.0, 100.0)
	m.need_hunger = clampf(float(data.get("need_hunger", 90.0)), 0.0, 100.0)
	m.digestion_buffer = clampf(float(data.get("digestion_buffer", 0.0)), 0.0, 100.0)
	m.need_energy = clampf(float(data.get("need_energy", 90.0)), 0.0, 100.0)
	if data.has("x_m") and data.has("z_m"):
		m.sitio = Vector2(float(data["x_m"]), float(data["z_m"]))
	elif data.has("pos_x") and data.has("pos_y"): # partidas de antes de la tanda 4b-3: sitio en el mapa plano
		m.sitio = Lugar.a_suelo(Vector2(float(data["pos_x"]), float(data["pos_y"])))
	if bool(data.get("is_dead", false)):
		m.morir(true)
		m.corpse_looted = bool(data.get("corpse_looted", false))
		m.visible = not m.corpse_looted
	else:
		m.is_dead = false
		m.is_sleeping = false
		m.corpse_looted = false
		m.hostile_timer = 0.0
		m.flee_timer = 0.0
		m.is_stunned_flag = false
		MascotaPelea.calmar(m)
		m.visible = true
		m.stun_comp.clear_stun()
		m.health_comp.stop_bleeding()
		if data.has("hp"):
			m.health_comp.current_health = clampf(float(data["hp"]), 1.0, m.health_comp.max_health)
	m.al_cambiar_de_estado()
