@tool
extends "res://scripts/visuals/WorldStageBase3D.gd"
const Suelo = preload("res://scripts/fisica/Suelo.gd") # paso a 3D, paso 2b: profundidad del club y las alcantarillas
const Cartel = preload("res://mapa/cartel.gd") # carteles de madera: los de las puertas (Buildings3D) y los postes de los caminos
const ID_COMISARIA := "building_police"
const MODELO_POZO := "exterior/pozo_clasico.tscn" ## hecho con tools/hornear_pozo.gd
const META_TIPO_3D := "tipo_3d" ## en un dibujo del mapa: qué objeto 3D le toca, si su dibujo no basta para saberlo
const ALTO_POZO_M: float = 2.54
const ALTO_ROCA_SUELTA_M: float = 1.27
const HUNDIDO_ROCA_SUELTA_M: float = 0.148

## Puesto del Paso, cementerio, alcantarillas, objetos de la época, farolas y objetos/props dinámicos 3D.

const ESCENA_PUESTO_PASO := "res://mapa/edificios/puesto_del_paso.tscn"
const ESCENA_SOTANO_CLUB := "res://mapa/edificios/sotano_club_pelea.tscn"
const ESCENA_TRAMPILLA_CLUB := "res://assests/curated_3d/exterior/trampilla_club.tscn"
const ESCENA_BARRERA_SACOS := "res://assests/curated_3d/exterior/barrera_sacos_alambre.tscn"
const ESCENA_TORRE_FOCO := "res://assests/curated_3d/exterior/torre_foco_electrico.tscn"
const ESCENA_FAROLA_CALLE := "res://assests/curated_3d/exterior/farola_calle.tscn"
const ESCENA_LIBRO_CUENTAS := "res://assests/curated_3d/props/libro_cuentas_ayuntamiento.tscn"
const ESCENA_MESA_CASA := "res://assests/curated_3d/props/mesa_casa_jugador.tscn"
const ESCENA_BANCO_CASA := "res://assests/curated_3d/props/banco_trabajo_casa.tscn"
const ESCENA_ESCONDITE_CASA := "res://assests/curated_3d/props/escondite_suelo_casa.tscn"
const ESCENA_ESCALERA_CASA := "res://assests/curated_3d/props/escalera_trampilla_casa.tscn"
const ESCENA_MOSTRADOR_CASA := "res://assests/curated_3d/props/mostrador_tienda_jugador.tscn"
const ESCENA_CAMA_PERRO := "res://assests/curated_3d/props/cama_mascota_perro.tscn"
const ESCENA_CAMA_GATO := "res://assests/curated_3d/props/cama_mascota_gato.tscn"
const CENTRO_SOLAR_PUESTO_BASE := Vector2(1593.0, 47.0)

const ESCENAS_ROBOS := {
	"sello_noble": "res://assests/curated_3d/props/objetivo_robo_sello.tscn",
	"caliz_capilla": "res://assests/curated_3d/props/objetivo_robo_caliz.tscn",
}
const ESCENA_ROBO_LIBRO := "res://assests/curated_3d/props/objetivo_robo_libro.tscn"

const ESCENAS_PROPS_3D := {
	"tent": "res://assests/curated_3d/exterior/tienda_campana.tscn",
	"campfire": "res://assests/curated_3d/exterior/hoguera_caldero.tscn",
	"log_seat": "res://assests/curated_3d/exterior/tronco_asiento.tscn",
	"clothesline": "res://assests/curated_3d/exterior/tendedero_ropa.tscn",
	"weapon_sword": "res://assests/curated_3d/exterior/caballete_espada.tscn",
	"weapon_hammer": "res://assests/curated_3d/exterior/caballete_martillo.tscn",
	"crate": "res://assests/curated_3d/exterior/caja_madera_prop.tscn",
	"barrel": "res://assests/curated_3d/exterior/barril_madera_prop.tscn",
	"weak_wall": "res://assests/curated_3d/exterior/muro_debil_piedra.tscn",
	"sign": "res://assests/curated_3d/exterior/poste_cartel_camino.tscn",
	"wild_herb": "res://assests/curated_3d/nature/mata_hierba_silvestre.tscn",
	"wild_mushroom": "res://assests/curated_3d/nature/grupo_setas_silvestres.tscn",
	"rabbit_burrow": "res://assests/curated_3d/nature/madriguera_conejo.tscn",
	"fox_den": "res://assests/curated_3d/nature/cubil_zorro.tscn",
	"dropped_item": "res://assests/curated_3d/props/bolsa_objeto_caido.tscn",
}

# ==============================================================================
# 4. ASENTAMIENTO FRONTERIZO «PUESTO DEL PASO» (EN EL LINDERO ESTE)
# ==============================================================================
func rebuild_outpost_3d() -> void:
	_clear_children(outpost_root_3d)
	if vm == null or not ResourceLoader.exists(ESCENA_PUESTO_PASO):
		return
	var op: Dictionary = VillageCulture.outpost_state(vm)
	var founded: bool = bool(op.get("founded", false))
	var upgs: Dictionary = op.get("upgrades", {})
	var puesto: Node3D = (load(ESCENA_PUESTO_PASO) as PackedScene).instantiate() as Node3D
	var solar_id: String = VillageCulture.OUTPOST_SOLAR
	puesto.position = to_3d(VillageLots.Solar.a_mundo(solar_id, CENTRO_SOLAR_PUESTO_BASE), 0.0)
	puesto.rotation_degrees.y = VillageLots.Solar.giro(solar_id)
	_mostrar_hijo(puesto, "SolarSinFundar", not founded)
	_mostrar_hijo(puesto, "FuerteFundado", founded)
	_mostrar_hijo(puesto, "MejoraAserradero", founded and bool(upgs.get("sawmill", false)))
	_mostrar_hijo(puesto, "MejoraGranero", founded and bool(upgs.get("granary", false)))
	_mostrar_hijo(puesto, "MejoraAtalaya", founded and bool(upgs.get("watchtower", false)))
	outpost_root_3d.add_child(puesto)


static func _mostrar_hijo(padre: Node3D, nombre: String, ver: bool) -> void:
	var n := padre.get_node_or_null(nombre) as Node3D
	if n != null:
		n.visible = ver

static func _instanciar_escena(padre: Node3D, ruta: String, pos_3d: Vector3, giro_y: float = 0.0) -> Node3D:
	if padre == null or not ResourceLoader.exists(ruta):
		return null
	var inst: Node3D = (load(ruta) as PackedScene).instantiate() as Node3D
	inst.position = pos_3d
	if absf(giro_y) > 0.01:
		inst.rotation_degrees.y = giro_y
	padre.add_child(inst)
	return inst


static func _quitar_luces_en_headless(nodo: Node, es_headless: bool) -> void:
	if not es_headless or nodo == null:
		return
	for c: Node in nodo.find_children("*", "Light3D", true, false):
		c.get_parent().remove_child(c)
		c.free()


# ==============================================================================
# 5. TUMBAS DEL CEMENTERIO, ALCANTARILLAS (-1) Y FAROLAS CON LUZ REAL
# ==============================================================================
func rebuild_graves_3d() -> void:
	_clear_children(graves_root_3d)
	if vm == null:
		return
	_last_buried_count = vm.buried_graves.size()
	for i in range(vm.buried_graves.size()):
		var g_pos: Vector2 = vm._cemetery_burial_pos
		if i < vm._cemetery_grave_positions.size():
			g_pos = vm._cemetery_grave_positions[i]
		else:
			g_pos = vm._cemetery_burial_pos + Vector2(float(i % 6) * 26.0, float(int(float(i) / 6.0) % 3) * 28.0)
		var ruta_tumba: String = "res://assests/curated_3d/graveyard/tumba_enterrada_%d.tscn" % ((i % 4) + 1)
		_instanciar_escena(graves_root_3d, ruta_tumba, to_3d(g_pos, 0.0))


func _build_sewers_3d() -> void:
	_clear_children(sewers_root_3d)
	var escena: PackedScene = EdificioEditorScript.escena(VillageUnderworldScript.ID_RED)
	if escena == null:
		return
	var red: Node3D = escena.instantiate() as Node3D
	var centro_mundo: Vector2 = EdificioEditorScript.a_mundo(VillageUnderworldScript.ID_RED, Vector2(420.0, VillageUnderworldScript.SEWER_Y))
	sewers_root_3d.position = to_3d_flat(centro_mundo, Suelo.PROFUNDIDAD_SOTANO_PX)
	sewers_root_3d.rotation_degrees.y = EdificioEditorScript.giro(VillageUnderworldScript.ID_RED)
	sewers_root_3d.add_child(red)


func _poner_barrera_sacos_3d(pos_2d: Vector2, giro_deg: float) -> void:
	_instanciar_escena(streetlights_root_3d, ESCENA_BARRERA_SACOS, to_3d(pos_2d, 0.0), giro_deg)


func _poner_torre_foco_3d(pos_2d: Vector2, target_2d: Vector2) -> void:
	var pos_torre: Vector3 = to_3d(pos_2d, 0.0)
	var tgt_3d: Vector3 = to_3d(target_2d, 0.5)
	var charco_3d: Vector3 = to_3d(pos_2d.lerp(target_2d, 0.55), 10.0)
	var torre: Node3D = _instanciar_escena(streetlights_root_3d, ESCENA_TORRE_FOCO, pos_torre)
	if torre == null:
		return
	var cabeza := torre.get_node_or_null("CabezaFoco") as Node3D
	var d3: Vector3 = tgt_3d - pos_torre
	if cabeza != null and Vector2(d3.x, d3.z).length_squared() > 0.0001:
		cabeza.rotation.y = atan2(-d3.x, -d3.z)
	var bombilla := torre.get_node_or_null("CabezaFoco/BombillaFoco") as MeshInstance3D
	var haz := torre.get_node_or_null("CabezaFoco/HazFoco") as SpotLight3D
	var charco := torre.get_node_or_null("CharcoLuzSuelo") as OmniLight3D
	if _is_headless:
		_quitar_luces_en_headless(torre, true)
		haz = null
		charco = null
	else:
		if haz != null and (haz.global_position - tgt_3d).length() > 0.05:
			haz.look_at_from_position(haz.global_position, tgt_3d, Vector3.UP)
		if charco != null:
			charco.global_position = charco_3d
	_floodlight_nodes_3d.append({"bulb": bombilla, "spot": haz, "pool": charco})


func _build_epoch_props_3d() -> void:
	var giro_com: float = EdificioEditorScript.giro(ID_COMISARIA)
	colocar_plano = _en_edificio(ID_COMISARIA)
	_poner_barrera_sacos_3d(Vector2(875.0, 52.0), giro_com)
	_poner_barrera_sacos_3d(Vector2(955.0, 52.0), giro_com)
	_poner_torre_foco_3d(Vector2(1048.0, 54.0), Vector2(915.0, 20.0))
	var giro_puesto: float = VillageLots.Solar.giro(VillageCulture.OUTPOST_SOLAR)
	colocar_plano = _en_solar(VillageCulture.OUTPOST_SOLAR)
	_poner_barrera_sacos_3d(Vector2(1528.0, 22.0), giro_puesto)
	_poner_barrera_sacos_3d(Vector2(1528.0, 78.0), giro_puesto)
	_poner_torre_foco_3d(Vector2(1538.0, 18.0), Vector2(1506.0, 50.0))
	colocar_plano = Callable()


## Plano → mundo de un edificio o un solar, para `colocar_plano` (lo dibujado en su plano va con su pieza).
static func _en_edificio(id: String) -> Callable:
	return func(p: Vector2) -> Vector2: return EdificioEditorScript.a_mundo(id, p)


static func _en_solar(id: String) -> Callable:
	return func(p: Vector2) -> Vector2: return VillageLots.Solar.a_mundo(id, p)


func _build_streetlights_3d() -> void:
	_clear_children(streetlights_root_3d)
	_streetlight_nodes_3d.clear()
	_floodlight_nodes_3d.clear()
	if vm == null:
		return
	for sl in vm.streetlights:
		var pos: Vector2 = sl.get("pos", Vector2.ZERO)
		var farola: Node3D = _instanciar_escena(streetlights_root_3d, ESCENA_FAROLA_CALLE, to_3d(pos, 0.0))
		if farola == null:
			continue
		var cristal := farola.get_node_or_null("CristalFarol") as MeshInstance3D
		var omni := farola.get_node_or_null("ResplandorFarol") as OmniLight3D
		var charco := farola.get_node_or_null("CharcoLuzCalle") as SpotLight3D
		if _is_headless:
			_quitar_luces_en_headless(farola, true)
			omni = null
			charco = null
		_streetlight_nodes_3d.append({"bulb": cristal, "light": omni, "charco": charco})
	_build_epoch_props_3d()


func _sync_dynamic_props_3d() -> void:
	# 1. Puertas abatibles 3D
	for d_node in _door_nodes_3d:
		var d_entry: Dictionary = d_node["entry"]
		var pivot: Node3D = d_node["pivot"]
		var badge: MeshInstance3D = d_node["lock_badge"]
		if not is_instance_valid(pivot):
			continue
		var eff_open: bool = bool(d_entry.get("is_open", false)) or float(d_entry.get("npc_pass_timer", 0.0)) > 0.0
		if not d_node.has("estado_sonido"):
			d_node["estado_sonido"] = eff_open
		elif bool(d_node["estado_sonido"]) != eff_open:
			d_node["estado_sonido"] = eff_open
			if AudioManager != null and AudioManager.has_method("sonar_puerta_3d"):
				AudioManager.sonar_puerta_3d(pivot.global_position + Vector3(0.0, 1.0, 0.0), eff_open)
		var door_south: bool = bool(d_node["door_south"])
		pivot.rotation_degrees.y = (-82.0 if door_south else 82.0) if eff_open else 0.0
		if is_instance_valid(badge):
			badge.visible = (not eff_open) and (bool(d_entry.get("is_locked", false)) or bool(d_entry.get("locked_by_player", false)))

	_puertas_interiores.sincronizar(get_tree(), vm, get_process_delta_time())
	_rastros.sincronizar(self)

	# 2. Postigos de ventanas 3D
	for w_node in _window_nodes_3d:
		var w_entry: Dictionary = w_node["entry"]
		var shutter: MeshInstance3D = w_node["shutter"]
		if is_instance_valid(shutter):
			shutter.visible = bool(w_entry.get("is_shuttered", false))

	# 3. Cofres abiertos / cerrados
	var wc = get_node_or_null("/root/WorldClock")
	var cur_d: int = int(wc.current_day) if wc != null else 1
	for ch_node in _chest_nodes_3d:
		var ch_entry: Dictionary = ch_node["entry"]
		var lid: MeshInstance3D = ch_node["lid"]
		if is_instance_valid(lid):
			lid.visible = (int(ch_entry.get("looted_day", -1)) != cur_d)

	# 4. Cuerpos en las 3 camillas de la Morgue
	var active_morgue: int = vm.morgue_active_corpses.size()
	for i in range(_morgue_body_nodes_3d.size()):
		if is_instance_valid(_morgue_body_nodes_3d[i]):
			_morgue_body_nodes_3d[i].visible = (i < active_morgue)

	# 5. Reja corredera de la celda de la Comisaría (cerrada en x=889.5; abierta se desliza tras la reja fija en x=867.5)
	if is_instance_valid(_jail_gate_pivot_3d):
		var gate_locked: bool = is_instance_valid(vm._jail_cell_gate_col) and not vm._jail_cell_gate_col.disabled
		var recorrido: float = 0.0 if gate_locked else REJA_CELDA_RECORRIDO_PX
		_jail_gate_pivot_3d.position = _reja_celda_cerrada + Vector3.LEFT * recorrido * WORLD_SCALE

	# 6. Visibilidad de las alcantarillas y del club del sótano (-1): al bajar bajo el pueblo, ocultar superficie 3D para ver las galerías limpias igual que en 2D
	var in_sewers: bool = VillageUnderworldScript.is_player_in_sewers(vm)
	var in_club: bool = load("res://scripts/systems/VillageClub.gd").is_player_in_club(vm)
	var underground_view: bool = in_sewers or in_club
	if is_instance_valid(sewers_root_3d):
		sewers_root_3d.visible = in_sewers
	for techo in get_tree().get_nodes_in_group("techo_bajo_tierra_3d"):
		(techo as Node3D).visible = first_person_active
	_sync_club_3d()
	if is_instance_valid(buildings_root_3d):
		buildings_root_3d.visible = not underground_view
	if is_instance_valid(lots_root_3d):
		lots_root_3d.visible = not underground_view
	if is_instance_valid(nature_root_3d):
		nature_root_3d.visible = not underground_view
	if is_instance_valid(streetlights_root_3d):
		streetlights_root_3d.visible = not underground_view

	# 7. Piloto luminoso del Cuadro Eléctrico del Taller y objeto físico del robo activo (Bloque FIS2)
	if is_instance_valid(_grid_panel_bulb_3d):
		var sab_on: bool = VillageCulture.is_grid_sabotaged(vm)
		_grid_panel_bulb_3d.material_override = _mat("grid_bulb_err", Color(1.0, 0.25, 0.18), 0.2, 0.0, Color(1.0, 0.20, 0.12), 2.8) if sab_on else _mat("tinker_screen", Color(0.32, 0.96, 0.82), 0.2, 0.0, Color(0.24, 0.92, 0.76), 2.4)
	_sync_heist_target_3d()
	_sync_town_ledger_3d()
	_sync_home_props_3d()

func _sync_home_props_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var p_lots: Array[String] = VillageHousingScript.player_lots(vm, true)
	var hs: Dictionary = VillageHousingScript.state(vm)
	var prim_lot: String = VillageHousingScript.primary_player_lot(vm)
	var has_shop: bool = VillageHousingScript.has_player_shop(vm)
	var ps: Dictionary = hs.get("player_shop", {}) if has_shop else {}
	var shop_lot: String = VillageHousingScript.player_shop_lot(vm) if has_shop else ""
	var parts: PackedStringArray = PackedStringArray()
	for lid in p_lots:
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		var wb: int = 1 if bool(up.get("workbench", false)) else 0
		var st_fl: int = 1 if (lid == prim_lot and bool(hs.get("has_stash", false))) else 0
		var up_fl: int = 1 if bool(up.get("upper_floor", false)) else 0
		var cel_fl: int = 1 if bool(up.get("hidden_cellar", false)) else 0
		var sh_fl: int = 1 if (has_shop and lid == shop_lot) else 0
		var sh_stk: int = clampi(int(ps.get("stock", 0)), 0, 4) if sh_fl == 1 else 0
		var sh_till: int = (1 if int(ps.get("till_gold", 0)) > 0 else 0) if sh_fl == 1 else 0
		var tb_rat: int = clampi(int(hs.get("table_rations", 0)), 0, 12) if lid == prim_lot else 0
		parts.append("%s:%d:%d:%d:%d:%d:%d:%d:%d" % [lid, wb, st_fl, up_fl, cel_fl, sh_fl, sh_stk, sh_till, tb_rat])
	var sig: String = "|".join(parts)
	if sig == _last_home_props_sig and (sig.is_empty() or is_instance_valid(_home_props_3d)):
		return
	_last_home_props_sig = sig
	if is_instance_valid(_home_props_3d):
		_home_props_3d.queue_free()
		_home_props_3d = null
	if sig.is_empty():
		return
	var root: Node3D = Node3D.new()
	root.name = "HomeProps3D"
	stage_root_3d.add_child(root)
	_home_props_3d = root

	var m_oak: StandardMaterial3D = _mat("hp_oak", Color(0.46, 0.30, 0.16), 0.85, 0.05)
	var m_piedra: StandardMaterial3D = _mat("hp_piedra", Color(0.34, 0.33, 0.31), 0.95, 0.0)
	for lid in p_lots:
		var giro_solar: float = VillageLots.Solar.giro(lid)
		colocar_plano = _en_solar(lid)
		var st: Dictionary = VillageLots.lot(vm, lid)
		var up: Dictionary = st.get("upgrades", {})
		var tb_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_table")
		var mesa: Node3D = _instanciar_escena(root, ESCENA_MESA_CASA, to_3d(tb_pos, 0.0), giro_solar)
		if mesa != null:
			_mostrar_hijo(mesa, "ViandasMesa", lid == prim_lot and int(hs.get("table_rations", 0)) > 0)
		if bool(up.get("workbench", false)):
			var wb_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_workbench")
			_instanciar_escena(root, ESCENA_BANCO_CASA, to_3d(wb_pos, 0.0), giro_solar)
		if lid == prim_lot and bool(hs.get("has_stash", false)):
			var st_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_stash")
			_instanciar_escena(root, ESCENA_ESCONDITE_CASA, to_3d(st_pos, 0.0), giro_solar)
		var d_lot: Dictionary = VillageLots.lot_def(lid)
		var casa_tam: Vector2 = VillageLots.house_size(lid)
		if bool(up.get("upper_floor", false)):
			var altillo: MeshInstance3D = _add_box(root, size_3d(casa_tam - Vector2(6.0, 6.0), 1.4), to_3d(d_lot["center"], Suelo.ALTILLO_CASA_PX - 0.7), m_oak)
			altillo.rotation_degrees.y = giro_solar
			altillo.add_to_group("altillo_casa_3d")
		if bool(up.get("hidden_cellar", false)):
			var suelo_sot: MeshInstance3D = _add_box(root, size_3d(casa_tam - Vector2(6.0, 6.0), 1.0), to_3d_flat(d_lot["center"], Suelo.PROFUNDIDAD_SOTANO_PX - 0.5), m_piedra)
			suelo_sot.rotation_degrees.y = giro_solar
			var techo_sot: MeshInstance3D = _add_box(root, size_3d(casa_tam, 2.0), to_3d_flat(d_lot["center"], -1.5), m_piedra)
			techo_sot.rotation_degrees.y = giro_solar
			techo_sot.add_to_group("techo_bajo_tierra_3d")
		if bool(up.get("upper_floor", false)) or bool(up.get("hidden_cellar", false)):
			var sr_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "home_stairs")
			var esc: Node3D = _instanciar_escena(root, ESCENA_ESCALERA_CASA, to_3d(sr_pos, 0.0), giro_solar)
			if esc != null:
				_mostrar_hijo(esc, "PeldanosAltillo", bool(up.get("upper_floor", false)))
		if has_shop and lid == shop_lot:
			var sc_pos: Vector2 = VillageHousingScript.home_prop_pos(vm, lid, "player_shop_counter")
			var most: Node3D = _instanciar_escena(root, ESCENA_MOSTRADOR_CASA, to_3d(sc_pos, 0.0), giro_solar)
			if most != null:
				_mostrar_hijo(most, "MonedasCaja", int(ps.get("till_gold", 0)) > 0)
				_mostrar_hijo(most, "Mercancia_1", int(ps.get("stock", 0)) > 0)
				_mostrar_hijo(most, "Mercancia_2", int(ps.get("stock", 0)) >= 2)
	colocar_plano = Callable()


## P6: sala del club de pelea y su trampilla en la trastienda de la taberna, cargadas desde escenas horneadas en metros.
func _sync_club_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var Club = load("res://scripts/systems/VillageClub.gd")
	var giro_taberna: float = EdificioEditorScript.giro(Club.TAVERN_ID)
	if not is_instance_valid(_club_root_3d) and ResourceLoader.exists(ESCENA_SOTANO_CLUB):
		_club_root_3d = (load(ESCENA_SOTANO_CLUB) as PackedScene).instantiate() as Node3D
		_club_root_3d.name = "FightClub3D"
		_club_root_3d.position = to_3d(Club.CLUB_CENTER, Suelo.PROFUNDIDAD_SOTANO_PX)
		_club_root_3d.rotation_degrees.y = giro_taberna
		stage_root_3d.add_child(_club_root_3d)
	if stage_root_3d.get_node_or_null("ClubTrapdoor3D") == null and ResourceLoader.exists(ESCENA_TRAMPILLA_CLUB):
		var trap: Node3D = (load(ESCENA_TRAMPILLA_CLUB) as PackedScene).instantiate() as Node3D
		trap.name = "ClubTrapdoor3D"
		trap.position = to_3d(Club.TRAPDOOR_POS, 0.0)
		trap.rotation_degrees.y = giro_taberna
		stage_root_3d.add_child(trap)
	var in_club_now: bool = Club.is_player_in_club(vm)
	var open_now: bool = Club.is_open_now(vm)
	if is_instance_valid(_club_root_3d):
		_club_root_3d.visible = in_club_now
	var trap_node := stage_root_3d.get_node_or_null("ClubTrapdoor3D") as Node3D
	if is_instance_valid(trap_node):
		trap_node.visible = not in_club_now
		_mostrar_hijo(trap_node, "ClosedLid", not open_now)
		_mostrar_hijo(trap_node, "OpenHatch", open_now)

## P5: libro de cuentas abierto sobre la mesa del ayuntamiento (cargado desde escena horneada en metros).
func _sync_town_ledger_3d() -> void:
	if vm == null or stage_root_3d == null or is_instance_valid(_town_ledger_3d):
		return
	var pos: Vector2 = load("res://scripts/systems/VillageCollections.gd").ledger_pos()
	_town_ledger_3d = _instanciar_escena(stage_root_3d, ESCENA_LIBRO_CUENTAS, to_3d(pos, 0.0))
	if _town_ledger_3d != null:
		_town_ledger_3d.name = "TownLedger3D"


func _sync_heist_target_3d() -> void:
	if vm == null or stage_root_3d == null:
		return
	var ah: Dictionary = VillageUnderworldScript.state(vm).get("active_heist", {})
	var active: bool = (not ah.is_empty()) and (not bool(ah.get("stolen", false)))
	var sig: String = "%s|%d|%d" % [str(ah.get("id", "")), int(ah.get("pos_x", 0)), int(ah.get("pos_y", 0))] if active else ""
	if sig == _last_heist_sig and (not active or is_instance_valid(_heist_prop_3d)):
		return
	_last_heist_sig = sig
	if is_instance_valid(_heist_prop_3d):
		_heist_prop_3d.queue_free()
		_heist_prop_3d = null
	if not active:
		return
	var h_id: String = str(ah.get("id", "sello_noble"))
	var h_pos := Vector2(float(ah.get("pos_x", 0.0)), float(ah.get("pos_y", 0.0)))
	var ruta: String = String(ESCENAS_ROBOS.get(h_id, ESCENA_ROBO_LIBRO))
	_heist_prop_3d = _instanciar_escena(stage_root_3d, ruta, to_3d(h_pos, 0.0))
	if _heist_prop_3d != null:
		_heist_prop_3d.name = "HeistTarget3D_" + h_id


# ==============================================================================
# OBJETOS QUIETOS 2D -> 3D (pozos, farolas, tablón…)
# ==============================================================================
## Qué versión 3D lleva cada dibujo 2D, según el nombre de su imagen. "hide" = ya tiene 3D propio, solo se esconde.
const TERRAZA_MARGEN_BORDE: float = 6.0 ## borde de la terraza que también se limpia de dibujos planos
const PROP_KIND_BY_TEXTURE := {
	"bench_0.png": "hide",
	"flowers_plants_0.png": "hide",
	"hay_0.png": "hide",
	"hay_2.png": "hide",
	"logs_0.png": "hide",
	"iron_sword.png": "weapon_sword",
	"steel_hammer.png": "weapon_hammer",
	"crate.png": "crate",
	"crates_0.png": "crate", ## caja rompible de la escena del mundo (2026-11-13: antes no tenía 3D y chocaba invisible)
	"barrel.png": "barrel",
	"barrels_0.png": "barrel", ## barril rompible de la escena del mundo (igual)
	"weak_wall.png": "weak_wall",
	"wild_herb.png": "wild_herb",
	"wild_mushroom.png": "wild_mushroom",
}

static func _tex_file(t: Texture2D) -> String:
	if t == null:
		return ""
	var src: String = t.resource_path if not t.resource_path.is_empty() else String(t.get_meta("src_path", ""))
	return src.get_file()


func _prop_kind_for(spr: Node2D) -> String:
	if spr.has_meta(META_TIPO_3D): # marca sin dibujo (2026-11-12) o dibujo que no basta para saber qué es
		return String(spr.get_meta(META_TIPO_3D))
	if not spr is Sprite2D:
		return ""
	var mapped: String = String(PROP_KIND_BY_TEXTURE.get(_tex_file((spr as Sprite2D).texture), ""))
	if not mapped.is_empty():
		return mapped
	var p: Node = spr.get_parent()
	if p != null and p.get_parent() != null and p.get_parent().name == "Items":
		return "dropped_item"
	return ""


## Busca los dibujos 2D de objetos quietos: hijos directos del pueblo, ecosistema (hierbas, setas, madrigueras) y objetos de la escena.
func _scan_props_sources() -> void:
	_prop_sources.clear()
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	for c in vm.entities_root.get_children():
		if c is Sprite2D or (c is Node2D and c.has_meta(META_TIPO_3D)):
			_add_prop_source(c as Node2D)
		elif c is Node2D and String(c.name).begins_with("PetBed_"):
			_build_pet_bed_3d_for(c as Node2D)
	for eco in get_tree().get_nodes_in_group("ecosystem_manager"):
		_collect_child_sprites(eco)
	var w_root: Node = vm.get_parent()
	if w_root != null and is_instance_valid(w_root):
		for container_name in ["Items", "Environment"]:
			var cont: Node = w_root.get_node_or_null(container_name)
			if cont != null:
				_collect_child_sprites(cont)
	_sync_props_3d(false)


func _build_pet_bed_3d_for(bed_node: Node2D) -> void:
	if nature_root_3d == null or bed_node == null:
		return
	var b_name := "PetBed3D_" + String(bed_node.name)
	var old := nature_root_3d.get_node_or_null(b_name)
	if old != null:
		old.queue_free()
	var is_dog: bool = int(bed_node.get_meta("pet_type", 0)) == 0
	var cama: Node3D = _instanciar_escena(nature_root_3d, ESCENA_CAMA_PERRO if is_dog else ESCENA_CAMA_GATO, to_3d(bed_node.global_position, 0.0))
	if cama != null:
		cama.name = b_name


func _add_prop_source(spr: Node2D) -> void:
	var kind := _prop_kind_for(spr)
	if not kind.is_empty():
		_prop_sources.append({"sprite": spr, "kind": kind})


## Recorre un nodo y sus hijos buscando dibujos o marcas con versión 3D.
func _collect_child_sprites(n: Node) -> void:
	for c in n.get_children():
		if c is Sprite2D or c.has_meta(META_TIPO_3D):
			_add_prop_source(c as Node2D)
		if c.get_child_count() > 0:
			_collect_child_sprites(c)


func _sync_props_3d(only_update: bool) -> void:
	if nature_root_3d == null:
		return
	var alive: Dictionary = {}
	for src in _prop_sources:
		var spr_v = src["sprite"]
		if not is_instance_valid(spr_v):
			continue # p. ej. el cartel de un solar que ya se construyó
		var spr: Node2D = spr_v
		var id := spr.get_instance_id()
		alive[id] = true
		var kind: String = src["kind"]
		var variant := kind
		var rec: Dictionary = _prop_nodes.get(id, {})
		var stale: bool = not rec.is_empty() and (String(rec.get("variant", "")) != variant or (rec.get("pos", Vector2.ZERO) as Vector2).distance_squared_to(spr.global_position) > 0.25)
		if stale:
			var old_root = rec.get("root")
			if old_root is Node3D and is_instance_valid(old_root):
				(old_root as Node3D).queue_free()
			rec = {}
		if rec.is_empty() and (not only_update or stale) and kind != "hide":
			var root := Node3D.new()
			root.name = "Prop3D_" + kind
			root.position = to_3d(spr.global_position, 0.0)
			if spr.has_meta("giro_3d"):
				root.rotation_degrees.y = float(spr.get_meta("giro_3d"))
			nature_root_3d.add_child(root)
			_build_prop_3d(root, kind, spr)
			rec = {"root": root, "variant": variant, "pos": spr.global_position}
			_prop_nodes[id] = rec
		var r3 = rec.get("root")
		if r3 is Node3D and is_instance_valid(r3):
			(r3 as Node3D).visible = spr.is_visible_in_tree() and (not spr is Sprite2D or (spr as Sprite2D).texture != null)
		spr.self_modulate.a = 0.0
	_sync_sabotage_fx_3d()
	if only_update:
		return
	for id in _prop_nodes.keys():
		if not alive.has(id):
			var r = _prop_nodes[id].get("root")
			if r is Node3D and is_instance_valid(r):
				(r as Node3D).queue_free()
			_prop_nodes.erase(id)


func _build_prop_3d(root: Node3D, kind: String, spr: Node2D) -> void:
	if kind == "well":
		if not _is_headless and AssetLib.has_curated_assets():
			var pozo: Node3D = AssetLib.instantiate_model(MODELO_POZO, Vector3.ZERO, ALTO_POZO_M, true, true)
			if pozo != null:
				root.add_child(pozo)
		return
	if kind == "roca":
		if not _is_headless and AssetLib.has_curated_assets():
			var rocas: Array[String] = ["nature/Rock_1.obj", "nature/Rock_2.obj", "nature/Rock_3.obj", "nature/Rock_4.obj", "nature/Rock_5.obj"]
			var h: int = absi(hash(spr.global_position.round()))
			var roca: Node3D = AssetLib.instantiate_model(rocas[h % rocas.size()], Vector3.ZERO, ALTO_ROCA_SUELTA_M, true, true)
			if roca != null:
				roca.position = Vector3(0.0, -HUNDIDO_ROCA_SUELTA_M, 0.0)
				roca.rotation_degrees.y = float(h % 360)
				root.add_child(roca)
		return
	var ruta: String = String(ESCENAS_PROPS_3D.get(kind, ""))
	if ruta.is_empty():
		return
	var inst: Node3D = _instanciar_escena(root, ruta, Vector3.ZERO)
	if inst == null:
		return
	_quitar_luces_en_headless(inst, _is_headless)
	if kind == "sign" and spr.has_meta(Cartel.META_TEXTO):
		var tabla := inst.get_node_or_null("TablaCartel") as MeshInstance3D
		if tabla != null:
			_escribir_poste(tabla, String(spr.get_meta(Cartel.META_TEXTO)))


## Oculta las tiras planas 2D de muros/puertas/suelos cuando el 3D está activo (usando `self_modulate.a`
## en lugar de `.visible`, de modo que ningún test de estado de puertas o ventanas se vea afectado).
## Esconde los dibujos planos del mapa que ya tienen versión 3D (pinos, rocas, objetos, fachadas). Desde 2026-11-12 ya no
## hay modo 2D al que volver: se esconden siempre.
## La terraza del restaurante está en el plano del local; los dibujos, en el mundo: se pasan sus 4 esquinas al mundo
## (el local puede estar movido o girado en el editor) y se toma el rectángulo que las abarca.
func _terraza_en_mundo() -> Rect2:
	var t: Rect2 = VillageRestaurant.TERRACE.grow(TERRAZA_MARGEN_BORDE)
	var r := Rect2(VillageRestaurant.al_mundo(t.position), Vector2.ZERO)
	for esquina: Vector2 in [Vector2(t.end.x, t.position.y), t.end, Vector2(t.position.x, t.end.y)]:
		r = r.expand(VillageRestaurant.al_mundo(esquina))
	return r


func _sync_2d_flat_visuals() -> void:
	if vm == null or not is_instance_valid(vm.entities_root):
		return
	var target_a: float = 0.0
	for src in _nature_sources + _prop_sources:
		var spr_n = src.get("sprite")
		if spr_n is CanvasItem and is_instance_valid(spr_n):
			(spr_n as CanvasItem).self_modulate.a = target_a
	var inner_rects: Array[Rect2] = [_terraza_en_mundo()]
	for b in vm.building_footprints:
		inner_rects.append((b["rect"] as Rect2).grow(-3.0))
	for child in vm.entities_root.get_children():
		# Muebles y suelos 2D dentro de los edificios (camas, mesas, alfombras…): el interior 3D ya los tiene.
		if (child is Sprite2D or child is TextureRect or child is Polygon2D) and (child as CanvasItem).z_index <= 0 and not child.has_meta("flat_2d_building_visual"):
			var cpos: Vector2 = (child as Node2D).global_position if child is Node2D else (child as Control).global_position + (child as Control).size * 0.5
			if child is Polygon2D and cpos == Vector2.ZERO and (child as Polygon2D).polygon.size() > 0:
				cpos = (child as Polygon2D).polygon[0]
			for ir in inner_rects:
				if ir.has_point(cpos):
					(child as CanvasItem).self_modulate.a = target_a
					break
		if child.has_meta("flat_2d_building_visual"):
			if child is CanvasItem:
				(child as CanvasItem).self_modulate.a = target_a
		elif child is StaticBody2D:
			for sub in child.get_children():
				if sub is TextureRect:
					(sub as TextureRect).self_modulate.a = target_a
	VillageUnderworldScript.sync_sewer_visibility(vm)
	load("res://scripts/systems/VillageClub.gd").sync_club_visibility(vm)
	for rf in get_tree().get_nodes_in_group("ranch_fence_2d"):
		if rf is CanvasItem and is_instance_valid(rf):
			(rf as CanvasItem).self_modulate.a = target_a


## B4.2: Un taller saboteado echa humo y chispas en 3D hasta que se repara; si llueve, el fuego exterior se apaga.
func _sync_sabotage_fx_3d() -> void:
	if vm == null or not ("shop_businesses" in vm) or not is_instance_valid(nature_root_3d):
		return
	var raining: bool = WorldClock != null and int(WorldClock.current_weather) == 1
	for r_id in vm.shop_businesses.keys():
		var role_int: int = int(r_id)
		var biz: Dictionary = vm.shop_businesses[role_int]
		var sab_d: int = int(biz.get("sabotaged_days", 0))
		var node3d: Node3D = _sabotage_fx_3d.get(role_int) as Node3D if is_instance_valid(_sabotage_fx_3d.get(role_int)) else null
		if sab_d <= 0:
			if node3d != null:
				node3d.queue_free()
			_sabotage_fx_3d.erase(role_int)
			continue
		var s_pos: Vector2 = biz.get("stall_pos", Vector2.ZERO)
		var has_fire: bool = (biz.get("outdoor_fire") == true) and not raining
		if node3d == null:
			node3d = Node3D.new()
			node3d.name = "SabotageFX3D_%d" % role_int
			node3d.position = to_3d(s_pos, 10.0)
			var smoke3 := CPUParticles3D.new()
			smoke3.name = "Smoke3D"
			var sm_mesh := SphereMesh.new()
			sm_mesh.radius = 0.14
			sm_mesh.height = 0.28
			sm_mesh.material = _mat("sab_smoke_3d", Color(0.24, 0.24, 0.27), 0.95, 0.0)
			smoke3.mesh = sm_mesh
			smoke3.amount = 10
			smoke3.lifetime = 1.4
			smoke3.direction = Vector3(0.1, 1.0, -0.05)
			smoke3.spread = 24.0
			smoke3.initial_velocity_min = 0.45
			smoke3.initial_velocity_max = 0.95
			smoke3.gravity = Vector3(0.0, 0.35, 0.0)
			smoke3.emitting = true
			_particulas_a_metros(smoke3)
			node3d.add_child(smoke3)
			var sparks3 := CPUParticles3D.new()
			sparks3.name = "Sparks3D"
			var sp_mesh := BoxMesh.new()
			sp_mesh.size = Vector3(0.06, 0.06, 0.06)
			sp_mesh.material = _mat("sab_spark_3d", Color(1.0, 0.80, 0.25), 0.2, 0.0, Color(1.0, 0.72, 0.18), 2.2)
			sparks3.mesh = sp_mesh
			sparks3.amount = 8
			sparks3.lifetime = 0.45
			sparks3.explosiveness = 0.35
			sparks3.direction = Vector3(0.0, 1.0, 0.0)
			sparks3.spread = 58.0
			sparks3.initial_velocity_min = 0.8
			sparks3.initial_velocity_max = 1.6
			sparks3.gravity = Vector3(0.0, -3.2, 0.0)
			sparks3.emitting = true
			_particulas_a_metros(sparks3)
			node3d.add_child(sparks3)
			var fire3 := CPUParticles3D.new()
			fire3.name = "Fire3D"
			var fi_mesh := SphereMesh.new()
			fi_mesh.radius = 0.11
			fi_mesh.height = 0.24
			fi_mesh.material = _mat("sab_fire_3d", Color(1.0, 0.45, 0.12), 0.3, 0.0, Color(1.0, 0.38, 0.08), 2.5)
			fire3.mesh = fi_mesh
			fire3.amount = 8
			fire3.lifetime = 0.55
			fire3.direction = Vector3(0.0, 1.0, 0.0)
			fire3.spread = 26.0
			fire3.initial_velocity_min = 0.35
			fire3.initial_velocity_max = 0.75
			fire3.gravity = Vector3(0.0, 0.6, 0.0)
			fire3.emitting = has_fire
			_particulas_a_metros(fire3)
			node3d.add_child(fire3)
			if not _is_headless:
				var lt := OmniLight3D.new()
				lt.name = "FireLight3D"
				lt.light_color = Color(1.0, 0.58, 0.20)
				lt.light_energy = 1.15 if has_fire else 0.35
				lt.omni_range = 2.4 * Mapa3D.K
				node3d.add_child(lt)
			nature_root_3d.add_child(node3d)
			_sabotage_fx_3d[role_int] = node3d
		else:
			node3d.position = to_3d(s_pos, 10.0)
			var f3 := node3d.get_node_or_null("Fire3D") as CPUParticles3D
			if f3 != null:
				f3.emitting = has_fire
			var lt3 := node3d.get_node_or_null("FireLight3D") as OmniLight3D
			if lt3 != null:
				lt3.light_energy = 1.15 if has_fire else 0.35


## Texto del poste de un camino en las dos caras de su tabla (mapa/cartel.gd: letras quemadas que encogen si no caben).
func _escribir_poste(tabla: MeshInstance3D, texto: String) -> void:
	var tam: Vector3 = (tabla.mesh as BoxMesh).size
	for giro: float in [0.0, PI]:
		var l: Label3D = Cartel.letras(tam, Cartel.COLOR_LETRAS_PINTADAS)
		Cartel.escribir(l, texto, tam)
		l.position = Basis(Vector3.UP, giro) * l.position
		l.rotation.y = giro
		tabla.add_child(l)
