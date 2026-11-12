class_name WorldInteractableProp
extends Node2D

## Objeto físico interactivo del mundo («La Placa de Petri» - Bloques FIS2 y FIS3):
## - `"terminal"`: Terminal Lógica Electromecánica sobre mesa dentro del Taller de Reparaciones (`solar e5`).
## - `"grid_panel"`: Cuadro Eléctrico en la pared exterior del Taller de Reparaciones (`solar e5`).
## - `"heist_target"`: Objeto físico de los 3 grandes robos (`sello_noble`, `caliz_capilla`, `libro_gremial`).
## - `"sewer_grate"`: Trampilla/rejilla de calle para bajar a las alcantarillas (`cistern`, `smuggler_tunnel`, `flooded_vault`).
## - `"sewer_ladder"`: Escalerilla subterránea para subir a la trampilla correspondiente de la calle.
## - `"sewer_chest"`: Cofre de contrabando subterráneo (1 por cámara, 1 vez al día).
## Tiene dibujo 2D propio (oculto automáticamente en vista 3D y visible al pulsar [F10]),
## `Area2D` en el grupo `"interactable"` con su letrero contextual `[E] ...`, y acción directa al pulsar [E].

const VillageCulture = preload("res://scripts/systems/VillageCulture.gd")
const VillageUnderworld = preload("res://scripts/systems/VillageUnderworld.gd")
const VillageHousing = preload("res://scripts/systems/VillageHousing.gd")
const VillageCollections = preload("res://scripts/systems/VillageCollections.gd")
const VillageClub = preload("res://scripts/systems/VillageClub.gd")
const VillageTavern = preload("res://scripts/systems/VillageTavern.gd")
const VillageFame = preload("res://scripts/systems/VillageFame.gd")
const CharacterAvatar3DScript = preload("res://scripts/visuals/CharacterAvatar3D.gd")

var vm: Node2D = null
var prop_kind: String = "terminal"
var heist_id: String = ""
var heist_label: String = ""
var sewer_loc_id: String = ""
var npc_name: String = "Objeto"
var npc_role: String = "Mecanismo del Taller"
var interact_area: Area2D = null


func setup_prop(village_manager: Node2D, kind: String, h_id: String = "", h_label: String = "") -> void:
	vm = village_manager
	prop_kind = kind
	heist_id = h_id
	heist_label = h_label
	sewer_loc_id = h_id
	match prop_kind:
		"terminal":
			npc_name = heist_label if not heist_label.is_empty() else "Terminal Lógica Electromecánica"
			npc_role = "Comisaría del Alguacil" if heist_id == "police" else ("Ayuntamiento del Valle" if heist_id == "town_hall" else "Taller de Reparaciones")
			if heist_id.is_empty():
				add_to_group("tinker_terminal")
			add_to_group("tinker_station")
		"armory_rack":
			npc_name = heist_label if not heist_label.is_empty() else "Expositor de Armas y Munición"
			npc_role = "Herrería y Armería «Yunque Gris»"
			add_to_group("armory_rack")
			add_to_group("tinker_station")
		"grid_panel":
			npc_name = "Cuadro Eléctrico General"
			npc_role = "Pared Exterior del Taller"
			add_to_group("tinker_grid_panel")
			add_to_group("tinker_station")
		"heist_target":
			npc_name = heist_label if not heist_label.is_empty() else "Objetivo del Encargo"
			npc_role = "Encargo del Perista"
			add_to_group("heist_target_prop")
		"sewer_grate":
			npc_name = heist_label if not heist_label.is_empty() else "Rejilla de Alcantarilla"
			npc_role = "Acceso a las Alcantarillas"
			add_to_group("sewer_grate")
			add_to_group("sewer_station")
		"sewer_ladder":
			npc_name = "Escalerilla a la Calle"
			npc_role = heist_label if not heist_label.is_empty() else "Salida de Alcantarilla"
			add_to_group("sewer_ladder")
			add_to_group("sewer_station")
		"sewer_chest":
			npc_name = "Cofre de Contrabando"
			npc_role = heist_label if not heist_label.is_empty() else "Alijo Subterráneo"
			add_to_group("sewer_chest")
			add_to_group("sewer_station")
		"home_workbench":
			npc_name = "Banco de Trabajo y Alquimia"
			npc_role = heist_label if not heist_label.is_empty() else "Interior de tu Casa"
			add_to_group("home_workbench")
			add_to_group("home_prop")
		"home_table":
			npc_name = "Mesa del Comedor"
			npc_role = heist_label if not heist_label.is_empty() else "Interior de tu Casa"
			add_to_group("home_table")
			add_to_group("home_prop")
		"home_stash":
			npc_name = "Escondite bajo las Tablas"
			npc_role = heist_label if not heist_label.is_empty() else "Suelo de tu Casa"
			add_to_group("home_stash")
			add_to_group("home_prop")
		"home_stairs":
			npc_name = "Escalera y Trampilla de Casa"
			npc_role = heist_label if not heist_label.is_empty() else "Cambio de Planta"
			add_to_group("home_stairs")
			add_to_group("home_prop")
		"home_garden":
			npc_name = "Huerto Doméstico"
			npc_role = heist_label if not heist_label.is_empty() else "Solar de tu Casa"
			add_to_group("home_garden")
			add_to_group("home_prop")
		"player_shop_counter":
			npc_name = heist_label if not heist_label.is_empty() else "Bazar del Forastero"
			npc_role = "Mostrador y Caja de tu Tienda"
			add_to_group("player_shop_counter")
			add_to_group("home_prop")
		"collect_point": # P5: cobro de renta o «protección» en el local (invisible: basta el letrero)
			npc_name = "Cobro en el local"
			npc_role = "Lo que te deben"
			add_to_group("collect_point")
		"town_coffers": # P5: desviar oro del cofre de las arcas (siendo alcalde)
			npc_name = "Arcas del Pueblo"
			npc_role = "Ayuntamiento"
			add_to_group("town_coffers_prop")
		"town_ledger": # P5: libro de cuentas sobre la mesa del ayuntamiento
			npc_name = "Libro de Cuentas"
			npc_role = "Mesa del Ayuntamiento"
			add_to_group("town_ledger_prop")
		"masterwork_counter": # A1: mostrador del taller del maestro artesano (invisible: basta el letrero)
			npc_name = "Mostrador del Maestro"
			npc_role = "Obras Maestras"
			add_to_group("masterwork_counter")
		"club_trapdoor", "club_ladder", "club_ring", "club_bet": # P6: club de pelea en el sótano de la taberna
			npc_name = {"club_trapdoor": "Trampilla", "club_ladder": "Escalerilla a la Taberna", "club_ring": "Corro de Cuerda", "club_bet": "Apuestas"}[prop_kind]
			npc_role = "Sótano de la Taberna"
			add_to_group("club_prop")
		"tavern_stairs":
			npc_name = "Escalera de la Posada"
			npc_role = "Cambio de Planta (0 / +1)"
			add_to_group("tavern_stairs")
	_build_interact_area()


func _ready() -> void:
	if interact_area == null:
		_build_interact_area()


## Solo la zona de [E]: la pieza se ve en 3D (WorldStageProps3D y escenas de los edificios), sin dibujo plano.
func _build_interact_area() -> void:
	if interact_area == null or not is_instance_valid(interact_area):
		interact_area = Area2D.new()
		interact_area.name = "InteractArea"
		interact_area.collision_layer = 1
		interact_area.collision_mask = 2
		interact_area.add_to_group("interactable")
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 48.0 if prop_kind == "tavern_stairs" else (14.0 if prop_kind == "sewer_grate" else 20.0)
		shape.shape = circle
		interact_area.add_child(shape)
		add_child(interact_area)


func get_interact_label(_player: Node2D = null) -> String:
	if vm != null and vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode")):
		if prop_kind in ["heist_target", "sewer_grate", "sewer_ladder", "sewer_chest", "home_workbench", "home_table", "home_stash", "home_stairs", "home_garden", "player_shop_counter", "collect_point", "town_coffers", "town_ledger", "masterwork_counter", "club_trapdoor", "club_ladder", "club_ring", "club_bet"]:
			return ""
	match prop_kind:
		"terminal":
			return "Usar la Terminal Lógica"
		"armory_rack":
			return "Expositor de Armas y Munición ([F] robar)"
		"grid_panel":
			return "Manipular el cuadro eléctrico"
		"heist_target":
			var lbl: String = heist_label
			if lbl.is_empty() and vm != null:
				lbl = str(VillageUnderworld.state(vm).get("active_heist", {}).get("label", "el objetivo"))
			return "Robar %s" % (lbl if not lbl.is_empty() else "el objetivo")
		"sewer_grate":
			if vm != null and int(vm.player_elevation_level) != 0:
				return ""
			if vm != null and _player != null and vm.has_method("_is_pos_inside_any_building") and bool(vm.call("_is_pos_inside_any_building", _player.global_position)):
				return ""
			var unlocked: bool = vm != null and bool(VillageUnderworld.sewers_state(vm).get("unlocked", false))
			if not unlocked:
				return "Cerrada: el perista vende la llave"
			return "Bajar a las alcantarillas (%s)" % (heist_label if not heist_label.is_empty() else "acceso")
		"sewer_ladder":
			if vm != null and not VillageUnderworld.is_player_in_sewers(vm):
				return ""
			return "Subir a la calle (%s)" % (heist_label if not heist_label.is_empty() else "superficie")
		"sewer_chest":
			if vm != null and not VillageUnderworld.is_player_in_sewers(vm):
				return ""
			if vm != null and VillageUnderworld.is_sewer_chest_looted_today(vm, sewer_loc_id):
				return "Cofre de contrabando (vacío hoy)"
			return "Abrir cofre de contrabando (%s)" % (heist_label if not heist_label.is_empty() else "alijo")
		"home_workbench":
			return "Usar banco de trabajo y alquimia"
		"home_table":
			return VillageHousing.get_home_table_label(vm) if vm != null else "Mesa del comedor"
		"home_stash":
			var hidden_g: int = int(VillageHousing.state(vm).get("stash_gold", 0)) if vm != null else 0
			return "Escondite bajo las tablas (%d Oro oculto)" % hidden_g
		"home_stairs":
			return VillageHousing.get_home_stairs_label(vm, heist_id) if vm != null else "Usar escalera / trampilla"
		"home_garden":
			return VillageHousing.get_home_garden_label(vm, heist_id) if vm != null else "Cosechar el huerto de casa"
		"player_shop_counter":
			return VillageHousing.get_player_shop_counter_label(vm) if vm != null else "Mostrador y caja de tu tienda"
		"collect_point":
			var cp: PackedStringArray = heist_id.split(":")
			return VillageCollections.collect_label(vm, cp[0], int(cp[1])) if vm != null and cp.size() == 2 else ""
		"town_coffers":
			return VillageCollections.embezzle_label(vm) if vm != null else ""
		"town_ledger":
			return VillageCollections.ledger_label(vm) if vm != null else ""
		"masterwork_counter":
			return VillageFame.masterwork_counter_label(vm, vm._get_npcs_by_person_key().get(heist_id, null)) if vm != null else ""
		"club_trapdoor":
			return VillageClub.trapdoor_label(vm) if vm != null else ""
		"club_ladder":
			return "Subir a la taberna" if vm != null and VillageClub.is_player_in_club(vm) else ""
		"club_ring":
			return VillageClub.ring_label(vm, _player) if vm != null else ""
		"club_bet":
			return VillageClub.bet_label(vm, VillageClub.fighter_key_at(vm, heist_id)) if vm != null else ""
		"tavern_stairs":
			return VillageTavern.stairs_label(vm)
	return "Usar"


func interact(player: Node2D) -> void:
	if vm == null or player == null:
		return
	if vm.has_method("is_demo_mode") and bool(vm.call("is_demo_mode")):
		if prop_kind in ["heist_target", "sewer_grate", "sewer_ladder", "sewer_chest", "home_workbench", "home_table", "home_stash", "home_stairs", "home_garden", "player_shop_counter", "collect_point", "town_coffers", "town_ledger", "masterwork_counter", "club_trapdoor", "club_ladder", "club_ring", "club_bet"]:
			return
	match prop_kind:
		"terminal":
			VillageCulture.open_terminal_menu(vm, self, player)
		"armory_rack":
			VillageCulture.open_armory_rack_menu(vm, self, player)
		"grid_panel":
			VillageCulture.open_grid_panel_menu(vm, self, player)
		"heist_target":
			VillageUnderworld.try_interact(vm, player, global_position)
		"sewer_grate":
			VillageUnderworld.interact_sewer_grate(vm, sewer_loc_id, player)
		"sewer_ladder":
			VillageUnderworld.exit_sewer_ladder(vm, sewer_loc_id, player)
		"sewer_chest":
			var inv = player.get("inventory")
			VillageUnderworld.interact_sewer_chest(vm, sewer_loc_id, player, inv)
		"home_workbench":
			VillageHousing.open_home_workbench_menu(vm, self, player)
		"home_table":
			VillageHousing.open_home_table_menu(vm, self, player)
		"home_stash":
			VillageHousing.open_home_stash_menu(vm, self, player)
		"home_stairs":
			VillageHousing.interact_home_stairs(vm, heist_id, self, player)
		"home_garden":
			VillageHousing.interact_home_garden(vm, heist_id, player)
		"player_shop_counter":
			VillageHousing.open_player_shop_counter_menu(vm, self, player)
		"collect_point":
			var cp: PackedStringArray = heist_id.split(":")
			if cp.size() == 2:
				VillageCollections.collect(vm, cp[0], int(cp[1]), player)
		"town_coffers":
			VillageCollections.embezzle(vm, player)
		"town_ledger":
			VillageCollections.cook_books(vm, player)
		"masterwork_counter":
			VillageFame.buy_at_counter(vm, vm._get_npcs_by_person_key().get(heist_id, null), player)
		"club_trapdoor":
			VillageClub.go_down(vm, player)
		"club_ladder":
			VillageClub.go_up(vm, player)
		"club_ring":
			VillageClub.start_player_bout(vm, player)
		"club_bet":
			VillageClub.place_bet(vm, player, VillageClub.fighter_key_at(vm, heist_id))
		"tavern_stairs":
			VillageTavern.use_stairs(vm, player)


func on_dialogue_action(action_id: String) -> void:
	if vm == null:
		return
	var player: Node2D = null
	if is_inside_tree():
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		player = vm.VillageNeeds.player_of(vm)
	var inv = player.get("inventory") if player != null else null
	if action_id.begins_with("housing_"):
		VillageHousing.on_player_action(vm, null, action_id, inv)
	elif action_id.begins_with("underworld_"):
		VillageUnderworld.on_player_action(vm, null, action_id, inv)
	else:
		VillageCulture.on_player_action(vm, null, action_id, inv)
