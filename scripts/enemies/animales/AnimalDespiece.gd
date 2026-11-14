class_name AnimalDespiece
extends RefCounted

## AnimalDespiece: el final de un animal salvaje y su vuelta. Al morir queda su cadáver; el protagonista lo despieza con
## [E] (o un zorro se lo come) y desaparece del mundo hasta que le toca renacer. También guarda y carga su estado.
## Pieza de WildAnimal (tanda 4b-2 del paso a 3D, 2026-11-14): todo en metros sobre el suelo.

const EXPERIENCIA_CAZA: int = 12       ## la que gana el protagonista al despiezar
const RENACE_A_M: Vector2 = Vector2(0.34, 1.12) ## (mín., máx.) a qué distancia de su nido reaparece
const VIDA_POR_SANGRE: float = 5.0     ## vida de más por cada nivel de buena sangre
const SANGRE_MAX: int = 3
const SIN_FECHA: int = -1


## Cae muerto donde está: queda su cadáver, que ya no se puede herir, y la zona para despiezarlo.
static func caer_muerto(a: WildAnimal) -> void:
	a.state = WildAnimal.AnimalState.CARCASS
	a.andar = Vector2.ZERO
	a.velocity = Vector3.ZERO
	a.tumbado = true
	a.remove_from_group("wild_animals")
	Diana3D.poner_activa(a, false)
	a._vestir(a, false) # un cadáver no estorba el paso
	AnimalRotulo.callar(a)
	_quitar_zona(a)
	a.zona_despiece = ZonaDespiece.poner(a)


## Lo que da al despiezarlo: carne y piel siempre; huesos, astas, vísceras y grasa según la especie y su sangre.
static func piezas(a: WildAnimal) -> Dictionary:
	var extra: int = maxi(0, a.genetics_tier - 1)
	var de_sangre: int = 1 if a.genetics_tier >= 2 else 0
	var out: Dictionary = {"raw_meat": a.meat_drop + extra, a.pelt_item_id: a.leather_drop + (1 if a.genetics_tier >= SANGRE_MAX else 0)}
	if not a.enable_advanced_anatomy:
		return out
	if a.bones_drop > 0:
		out["bones"] = a.bones_drop + de_sangre
	if a.antlers_drop > 0:
		out["antlers"] = a.antlers_drop
	if a.viscera_drop > 0:
		out["sinew_viscera"] = a.viscera_drop
	if a.fat_drop > 0:
		out["animal_fat"] = a.fat_drop + de_sangre
	return out


## El protagonista lo despieza: se lleva las piezas, gana experiencia de caza y el cadáver desaparece.
static func despiezar(a: WildAnimal, player: Node) -> void:
	if a.state != WildAnimal.AnimalState.CARCASS or player == null:
		return
	var inventario: Variant = player.get("inventory")
	var resumen: Array[String] = []
	var lote: Dictionary = piezas(a)
	for item_id: String in lote:
		if inventario == null or int(lote[item_id]) <= 0:
			continue
		inventario.add_item(item_id, int(lote[item_id]))
		resumen.append("+%d %s" % [int(lote[item_id]), inventario.get_item_name(item_id)])
	if player.has_method("_spawn_floating_text") and not resumen.is_empty():
		player.call("_spawn_floating_text", "Desollado: " + ", ".join(resumen), Color.GOLD, -44.0)
	if player.has_method("add_skill_xp"):
		player.call("add_skill_xp", "hunting", EXPERIENCIA_CAZA)
	acabar_despiece(a)


## Sale del mundo hasta que le toque renacer (despiezado, comido por un zorro o de reserva en el ecosistema).
static func acabar_despiece(a: WildAnimal) -> void:
	a.state = WildAnimal.AnimalState.BUTCHERED
	a.respawn_on_day = int(WorldClock.current_day) + maxi(1, a.respawn_days)
	if a.persistence_id != "":
		GameManager.set_flag(a.persistence_id, a.respawn_on_day)
	esconder(a, true)


## Lo quita de la vista y del juego (`oculto`) o lo devuelve.
static func esconder(a: WildAnimal, oculto: bool) -> void:
	a.visible = not oculto
	a.set_physics_process(not oculto)
	if oculto and a.state == WildAnimal.AnimalState.BUTCHERED:
		a.remove_from_group("wild_animals")
	AnimalRotulo.callar(a)
	Diana3D.poner_activa(a, not oculto and a.is_alive_in_ecosystem())
	if oculto or a.state != WildAnimal.AnimalState.CARCASS:
		_quitar_zona(a)
	a._vestir(a, false)


static func _quitar_zona(a: WildAnimal) -> void:
	if is_instance_valid(a.zona_despiece):
		a.zona_despiece.queue_free()
	a.zona_despiece = null


## Vuelve a la vida junto a su nido, con el hambre y la pelea a cero.
static func renacer(a: WildAnimal) -> void:
	a.state = WildAnimal.AnimalState.GRAZE
	a.respawn_on_day = SIN_FECHA
	a.current_hp = a.max_hp + float(a.genetics_tier - 1) * VIDA_POR_SANGRE
	a.meals_eaten = 0
	a.fed_today = false
	a.has_reserve_day = false
	a.is_on_reserve_day = false
	a.mated_today = false
	a.pending_offspring = false
	a.escaped_first_pounce = false
	a.days_hungry = 0
	a.sitio = a.casa + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(RENACE_A_M.x, RENACE_A_M.y)
	_vivo_de_nuevo(a)
	if a.persistence_id != "":
		GameManager.set_flag(a.persistence_id, SIN_FECHA)
	esconder(a, false)


## Deja a cero todo lo de la pelea y la caza y lo apunta otra vez como animal vivo.
static func _vivo_de_nuevo(a: WildAnimal) -> void:
	a.tumbado = false
	a.hits_taken_count = 0
	a.boar_aggressor = null
	a.boar_aggro_timer = 0.0
	a.boar_charge_windup = 0.0
	a.boar_charge_timer = 0.0
	a.pounce_timer = 0.0
	a.pounce_recovery_timer = 0.0
	a.flee_timer = 0.0
	a.eat_timer = 0.0
	a.mate_timer = 0.0
	a.food_target = null
	a.mate_target = null
	if not a.is_in_group("wild_animals"):
		a.add_to_group("wild_animals")


## (Animales que no lleva el ecosistema) Al entrar o al cargar partida: ¿estaba despiezado y aún no le toca volver?
static func mirar_lo_guardado(a: WildAnimal) -> void:
	if a.managed_by_ecosystem or a.persistence_id == "":
		return
	var guardado: Variant = GameManager.get_flag(a.persistence_id, SIN_FECHA)
	var dia: int = int(guardado) if typeof(guardado) in [TYPE_INT, TYPE_FLOAT] else SIN_FECHA
	if dia > int(WorldClock.current_day):
		a.state = WildAnimal.AnimalState.BUTCHERED
		a.respawn_on_day = dia
		esconder(a, true)
	elif a.state == WildAnimal.AnimalState.BUTCHERED:
		renacer(a)


static func guardar(a: WildAnimal) -> Dictionary:
	return {
		"state": int(a.state), "hp": a.current_hp, "genetics_tier": a.genetics_tier,
		"meals_eaten": a.meals_eaten, "fed_today": a.fed_today, "has_reserve_day": a.has_reserve_day,
		"is_on_reserve_day": a.is_on_reserve_day, "mated_today": a.mated_today, "pending_offspring": a.pending_offspring,
		"offspring_genetics_tier": a.offspring_genetics_tier, "days_hungry": a.days_hungry, "respawn_on_day": a.respawn_on_day,
		"x_m": a.sitio.x, "z_m": a.sitio.y,
	}


static func cargar(a: WildAnimal, data: Dictionary) -> void:
	a.genetics_tier = clampi(int(data.get("genetics_tier", 1)), 1, SANGRE_MAX)
	a.current_hp = float(data.get("hp", a.max_hp))
	a.meals_eaten = int(data.get("meals_eaten", 0))
	a.fed_today = bool(data.get("fed_today", false))
	a.has_reserve_day = bool(data.get("has_reserve_day", false))
	a.is_on_reserve_day = bool(data.get("is_on_reserve_day", false))
	a.mated_today = bool(data.get("mated_today", false))
	a.pending_offspring = bool(data.get("pending_offspring", false))
	a.offspring_genetics_tier = clampi(int(data.get("offspring_genetics_tier", 1)), 1, SANGRE_MAX)
	a.days_hungry = int(data.get("days_hungry", 0))
	a.respawn_on_day = int(data.get("respawn_on_day", SIN_FECHA))
	var estado: int = int(data.get("state", int(WildAnimal.AnimalState.GRAZE)))
	if estado == int(WildAnimal.AnimalState.BUTCHERED):
		a.state = WildAnimal.AnimalState.BUTCHERED
		esconder(a, true)
		return
	if a.state == WildAnimal.AnimalState.IN_BURROW:
		a.salir_de_madriguera()
	a.state = WildAnimal.AnimalState.GRAZE
	_sitio_guardado(a, data)
	_vivo_de_nuevo(a)
	esconder(a, false)
	if estado == int(WildAnimal.AnimalState.CARCASS):
		caer_muerto(a)


## Lo pone donde estaba al guardar. Las partidas de antes de la tanda 4b-2 lo guardaban en el mapa plano (`pos_x`, `pos_y`).
static func _sitio_guardado(a: WildAnimal, data: Dictionary) -> void:
	if data.has("x_m") and data.has("z_m"):
		a.sitio = Vector2(float(data["x_m"]), float(data["z_m"]))
	elif data.has("pos_x") and data.has("pos_y"):
		a.sitio = Lugar.a_suelo(Vector2(float(data["pos_x"]), float(data["pos_y"])))
