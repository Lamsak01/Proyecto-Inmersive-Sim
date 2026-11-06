extends SceneTree

## Captura fotos del juego en 3D (con ventana real, NO headless) para revisar la estética.
## Uso: flatpak run org.godotengine.Godot --path . -s tools/screenshot_3d.gd -- <carpeta_salida> [horas separadas por comas] [sitios]
## Sitios: caballo, montado (compra el caballo solo en memoria), ciervo, zorro, jabali, perro (junto al primer animal de ese tipo), plaza, iglesia, lago, cementerio, cerca (jugador de cerca), campamento. Por defecto: todos.
## En barrio_lago, caserios y molino levanta casas de muestra en los solares de esos barrios (solo en memoria).
## En «norte» levanta casas en las filas m y u (solo en memoria) para ver las callejas curvas.
## En «casa_jugador» mejora tu casa a casa de piedra (solo en memoria) y enseña también el gallinero.
## En «campamento» siembra cultivos de muestra en el huerto (solo en memoria) para ver cada fase.
## Guarda <carpeta>/<sitio>_<hora>h.png. No toca la partida guardada.

var SPOTS := {
	"plaza": Vector2(465, 48),
	"iglesia": Vector2(650, 150),
	"lago": Vector2(-65, 140),
	"cementerio": Vector2(930, 300),
	"cerca": Vector2(470, 70),
	"retrato": Vector2(470, 60),
	"campamento": Vector2(150, 62),
	"barrio_lago": Vector2(-230, 290),
	"caserios": Vector2(-600, 800),
	"molino": Vector2(1580, 200),
	"casa_jugador": Vector2(100, 40),
	"norte": Vector2(640, -600),
}

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://shots"
	var hours: Array = [10, 18, 23]
	if args.size() > 1 and not args[1].is_empty():
		hours = []
		for h in args[1].split(","):
			hours.append(int(h))
	var spots: Array = SPOTS.keys()
	var grid_mode := false
	if args.size() > 2 and not args[2].is_empty():
		spots = Array(args[2].split(","))
		grid_mode = args[2] == "rejilla"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	root.add_child(packed.instantiate())
	for i in range(30):
		await process_frame
	var wc = root.get_node("/root/WorldClock")
	if wc.has_method("set_activity_pause"):
		wc.set_activity_pause(true)
	var ui := root.find_child("UI", true, false)
	if ui is CanvasLayer:
		(ui as CanvasLayer).visible = false
	if spots.has("campamento"):
		var plots := get_nodes_in_group("farm_plots")
		for i in range(plots.size()):
			var fp = plots[i]
			if i % 4 == 3:
				continue
			fp.crop_type = 1 + (i % 3)
			fp.days_grown = int(i / 3.0)
			fp.is_watered = i % 2 == 0
			fp._refresh_visuals()
	if spots.has("barrio_lago") or spots.has("caserios") or spots.has("molino") or spots.has("norte"):
		var vm_b = root.find_child("VillageManager", true, false)
		var VL = load("res://scripts/systems/VillageLots.gd")
		for lid in ["l1", "l2", "l3", "c1", "c2", "o1", "o2"]:
			if not spots.has("barrio_lago") and not spots.has("caserios") and not spots.has("molino"):
				break
			var st: Dictionary = VL.lot(vm_b, lid)
			st["status"] = "built"
			st["kind"] = "house"
			st["title"] = "🏠 %s" % str(VL.HOUSE_PLOTS[VL.plot_of(lid)]["word"])
			st["beds"] = VL._house_beds(lid)
			VL._draw_lot(vm_b, lid, st)
		if spots.has("norte"):
			for lid2 in ["m1", "m2", "m3", "m4", "m5", "m6", "u0", "u1", "u2", "u4", "u5", "u6", "n0", "n1", "n6"]:
				var st2: Dictionary = VL.lot(vm_b, lid2)
				if str(st2.get("status", "empty")) != "empty":
					continue
				st2["status"] = "built"
				st2["kind"] = "house"
				st2["title"] = "🏠 %s" % str(VL.HOUSE_PLOTS[VL.plot_of(lid2)]["word"])
				st2["beds"] = VL._house_beds(lid2)
				VL._draw_lot(vm_b, lid2, st2)
	if spots.has("casa_jugador"):
		var camp_n = root.find_child("PlayerCampSite", true, false)
		if camp_n != null:
			camp_n.upgrade_player_house(3)
	var player := get_first_node_in_group("player") as Node2D
	var cam := player.get_node_or_null("Camera2D") as Camera2D if player != null else null
	SPOTS["inicio"] = player.global_position
	# Sitios «ciervo», «zorro» y «perro»: junto al primer animal vivo y visible de ese tipo (cámara de cerca).
	for a in get_nodes_in_group("wild_animals"):
		if a.visible and a.is_alive_in_ecosystem():
			var k: String = {1: "ciervo", 2: "zorro", 3: "jabali"}.get(int(a.species), "")
			if k != "" and not SPOTS.has(k):
				SPOTS[k] = a.global_position + Vector2(0, -12)
	# Sitios «caballo» (esperando, con el jugador al lado) y «montado»: compra el caballo solo en memoria.
	if spots.has("caballo") or spots.has("montado"):
		var vm_h = root.find_child("VillageManager", true, false)
		var vcu = vm_h.VillageCulture
		var mh: Dictionary = vcu.mounts_state(vm_h)
		mh["has_horse"] = true
		mh["pos_x"] = 360.0
		mh["pos_y"] = 470.0
		vcu.sync_player_horse(vm_h)
		SPOTS["caballo"] = Vector2(340, 470)
		SPOTS["montado"] = Vector2(360, 470)
	# Sitio «asalto»: monta una incursión solo en memoria y enseña a los atacantes llegando por el este.
	if spots.has("asalto"):
		var vm_r = root.find_child("VillageManager", true, false)
		var vcr = vm_r.VillageCulture
		vcr.raids_state(vm_r)["threat"] = 50
		vcr.start_raid_warning(vm_r, "bandits")
		vcr.raid_on_hour(vm_r, vcr.RAID_GATHER_HOUR)
		vcr.spawn_raid_attackers(vm_r)
		SPOTS["asalto"] = Vector2(1640, 50)
	# Sitio «taller» (Bloque FIS2): dentro del Taller de Reparaciones (e5) para ver la Terminal Lógica dentro y el Cuadro Eléctrico en la fachada norte.
	if spots.has("taller"):
		SPOTS["taller"] = Vector2(1188, 128)
	# Sitio «robo» (Bloque FIS2): activa un robo en memoria y coloca al jugador junto al objeto físico del robo (Cáliz de Plata en el altar de la Capilla).
	if spots.has("robo"):
		var vm_u = root.find_child("VillageManager", true, false)
		var vun = vm_u.VillageUnderworld
		var t_heist: Dictionary = vun.HEIST_TARGETS[1] # Cáliz de Plata de la Capilla en el altar
		var hp: Vector2 = t_heist["pos"]
		vun.state(vm_u)["active_heist"] = {"id": str(t_heist["id"]), "label": str(t_heist["label"]), "pos_x": hp.x, "pos_y": hp.y, "reward": int(t_heist["reward"]), "stolen": false}
		vun.sync_heist_visuals(vm_u)
		SPOTS["robo"] = hp + Vector2(0, -10)
	# Sitios «trampilla» y «tunel» (Bloque FIS3): desbloquea las alcantarillas en memoria para ver la rejilla en la calle y los túneles subterráneos.
	if spots.has("trampilla") or spots.has("tunel"):
		var vm_sw = root.find_child("VillageManager", true, false)
		var vun_sw = vm_sw.VillageUnderworld
		vun_sw.sewers_state(vm_sw)["unlocked"] = true
		SPOTS["trampilla"] = (vun_sw.SEWER_LOCATIONS["cistern"]["pos"] as Vector2) + Vector2(-18, 6)
		SPOTS["tunel"] = vun_sw.SEWER_LOCATIONS["smuggler_tunnel"]["tunnel_pos"] as Vector2
	# Sitios «rancho» y «corral» (Bloque FIS4): prepara ganado vivo en el Rancho del Sur y animales propios en el corral del jugador (solo en memoria).
	if spots.has("rancho") or spots.has("corral"):
		var vm_lv = root.find_child("VillageManager", true, false)
		var vho = vm_lv.VillageHousing
		var hs_lv: Dictionary = vho.state(vm_lv)
		hs_lv["ranch_herd"] = [
			{"species": "sheep", "stage": "adult", "age_days": 6},
			{"species": "rooster", "stage": "adult", "age_days": 6},
			{"species": "sheep", "stage": "juvenile", "age_days": 4},
			{"species": "rooster", "stage": "chick", "age_days": 1},
		]
		hs_lv["player_animals"] = [
			{"species": "sheep", "stage": "adult", "age_days": 6, "power": 3, "fed_day": vho.today()},
			{"species": "rooster", "stage": "adult", "age_days": 6, "power": 2, "fed_day": vho.today()},
			{"species": "rooster", "stage": "chick", "age_days": 1, "power": 1, "fed_day": vho.today()},
		]
		vho.sync_livestock(vm_lv)
		SPOTS["rancho"] = Vector2(354, 468)
		SPOTS["corral"] = Vector2(42, 108)
	for pet in root.find_children("*", "DomesticPet", true, false):
		if int(pet.pet_type) == 0 and pet.visible and not SPOTS.has("perro"):
			SPOTS["perro"] = pet.global_position + Vector2(0, -12)
	if grid_mode:
		# Recorre todo el valle (-920..1000 x -340..1300) con la cámara alejada al máximo, más la posición inicial.
		spots = ["inicio"]
		var gy := -150.0
		while gy <= 1250.0:
			var gx := -700.0
			while gx <= 1000.0:
				var key := "r_%d_%d" % [int(gx), int(gy)]
				SPOTS[key] = Vector2(gx, gy)
				spots.append(key)
				gx += 560.0
			gy += 400.0
	for h in hours:
		wc.current_hour = int(h)
		wc.current_minute = 0
		wc.time_updated.emit(wc.current_day, wc.current_hour, wc.current_minute)
		for s in spots:
			if not SPOTS.has(s):
				print("SIN SITIO ", s)
				continue
			if player != null:
				var vm_loop = root.find_child("VillageManager", true, false)
				if vm_loop != null:
					var vun_loop = vm_loop.VillageUnderworld
					if s == "tunel":
						vun_loop.enter_sewer_location(vm_loop, "smuggler_tunnel", player)
					elif vun_loop.is_player_in_sewers(vm_loop):
						vun_loop.exit_sewers_to_surface(vm_loop)
				player.global_position = SPOTS[s]
				var horse_n = get_first_node_in_group("player_horse")
				if horse_n != null:
					if s == "montado" and not bool(player.get("is_mounted")):
						horse_n.mount(player)
					elif s != "montado" and bool(player.get("is_mounted")):
						horse_n.dismount(player)
				if cam != null:
					cam.zoom = Vector2(8.0, 8.0) if s == "retrato" else (Vector2(5.0, 5.0) if s in ["ciervo", "zorro", "perro", "jabali", "caballo", "montado", "asalto", "robo", "trampilla", "corral"] else (Vector2(4.2, 4.2) if s in ["cerca", "taller", "tunel", "rancho"] else Vector2(2.4, 2.4)))
					if String(s).begins_with("r_") or s == "lago" or s == "norte":
						cam.zoom = Vector2(1.4, 1.4)
					cam.reset_smoothing()
			# En «cerca», el ratón se pone sobre el vecino más cercano para ver su ficha.
			if s == "cerca" and player != null:
				var near_n = null
				for nn in get_nodes_in_group("village_npcs"):
					if not nn.is_dead and (near_n == null or nn.global_position.distance_to(player.global_position) < near_n.global_position.distance_to(player.global_position)):
						near_n = nn
				if near_n != null:
					await process_frame
					root.warp_mouse(root.get_canvas_transform() * near_n.global_position)
			for i in range(90):
				await process_frame
			var img: Image = root.get_texture().get_image()
			var p := "%s/%s_%02dh.png" % [out_dir, s, int(h)]
			img.save_png(p)
			print("SHOT ", p, " fps=", Engine.get_frames_per_second())
	quit(0)
