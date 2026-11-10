extends SceneTree

## Prueba del paso del mundo a 3D (docs/PLAN_MUNDO_3D.md). Cada paso añade aquí lo suyo. Sin ventana, ~1 min.
## Uso: timeout 300 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/fisica_3d.gd
## Termina con «FISICA 3D: PASSED» o «FAILED».

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
var _fallos: int = 0


func _ok(c: bool, txt: String) -> void:
	print(("  OK  " if c else "  FALLO  ") + txt)
	if not c:
		_fallos += 1


func _initialize() -> void:
	_paso0_conversion()
	await _paso0b_vista_de_arriba()
	await _paso0_escenario()
	await _paso1_cuerpo()
	print("FISICA 3D: %s (%d fallos)" % ["PASSED" if _fallos == 0 else "FAILED", _fallos])
	quit(1 if _fallos > 0 else 0)


## Paso 0 y 0b: la conversión única va y vuelve sin perder nada, y el mundo es uniforme y en metros.
func _paso0_conversion() -> void:
	var peor_vuelta: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 58
	for _i in range(2000):
		var p := Vector2(rng.randf_range(-2000, 2000), rng.randf_range(-1500, 1500))
		var h: float = rng.randf_range(-80, 200)
		peor_vuelta = maxf(peor_vuelta, (Mapa3D.a_mapa(Mapa3D.a_3d(p, h)) - p).length())
		peor_vuelta = maxf(peor_vuelta, absf(Mapa3D.alto_a_px(Mapa3D.alto_a_3d(h)) - h))
	_ok(peor_vuelta < 1e-3, "mapa → 3D → mapa sin perder posición (peor " + str(peor_vuelta) + " px)")
	var caja := Mapa3D.tam_a_3d(Vector2(10, 10), 0.0)
	_ok(is_equal_approx(caja.x, caja.z), "0b: una caja de 10×10 px es cuadrada en 3D (" + str(caja) + ")")
	var d_ns := Mapa3D.a_3d(Vector2(0, 100)).length()
	var d_eo := Mapa3D.a_3d(Vector2(100, 0)).length()
	_ok(is_equal_approx(d_ns, d_eo), "0b: 100 px norte-sur = 100 px este-oeste en 3D")
	var g := Mapa3D.dir_a_3d(Vector2(1, 1)).normalized()
	_ok(is_equal_approx(rad_to_deg(atan2(g.z, g.x)), 45.0), "0b: la diagonal del mapa es de 45° en 3D")
	# Persona: el muñeco mide ~1,55 en su esqueleto (CharacterRig3D) por la escala del escenario
	var CA = load("res://scripts/visuals/CharacterAvatar3D.gd")
	var alto_persona: float = 1.55 * float(CA.STAGE_K)
	_ok(absf(alto_persona - 1.75) < 0.05, "0b: una persona mide %.2f m (1,75 esperado)" % alto_persona)
	var ojos := Mapa3D.alto_a_3d(load("res://scripts/visuals/WorldStageBase3D.gd").FP_EYE_HEIGHT_PX)
	_ok(ojos > 1.5 and ojos < 1.7, "0b: los ojos en 1.ª persona a %.2f m" % ojos)


## Paso 0b: la vista desde arriba sigue cuadrando con el mapa del pueblo. Una cámara como la del juego (inclinada
## INCLINACION_GRADOS, imagen más baja y luego estirada) debe pintar un punto del mapa (x, y) a altura h justo donde el
## mapa 2D pinta (x, y − h): así se veía antes del paso 0b.
func _paso0b_vista_de_arriba() -> void:
	var W := 1280
	var H := int(round(720 / Mapa3D.ESTIRA_VERTICAL))
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.own_world_3d = true
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 0.1 * Mapa3D.K
	cam.far = 250.0 * Mapa3D.K
	var vis_h := 400.0 # píxeles del mapa que caben de alto en la pantalla
	cam.size = vis_h * Mapa3D.ESCALA / Mapa3D.ESTIRA_VERTICAL
	vp.add_child(cam)
	var centro := Vector2(412, 54)
	var giro := Basis.from_euler(Vector3(deg_to_rad(-Mapa3D.INCLINACION_GRADOS), 0.0, 0.0))
	cam.transform = Transform3D(giro, Mapa3D.a_3d(centro) + giro.z * 65.0 * Mapa3D.K)
	await process_frame
	var px_por_mapa := 720.0 / vis_h # píxeles de imagen (ya estirada a 720 de alto) por píxel del mapa
	var peor := 0.0
	for q in [[Vector2(412, 54), 0.0], [Vector2(500, 120), 30.0], [Vector2(330, -20), 60.0], [Vector2(450, 0), 12.0]]:
		var p: Vector2 = q[0]
		var h: float = q[1]
		var en_imagen := cam.unproject_position(Mapa3D.a_3d(p, h))
		var en_pantalla := Vector2(en_imagen.x, en_imagen.y * Mapa3D.ESTIRA_VERTICAL)
		var esperado := Vector2(W, 720) * 0.5 + (p - Vector2(0, h) - centro) * px_por_mapa
		peor = maxf(peor, en_pantalla.distance_to(esperado))
	vp.queue_free()
	_ok(peor < 1.0, "0b: vista desde arriba cuadra con el mapa (peor %.2f píxeles de pantalla)" % peor)


## Paso 0: el escenario del juego usa la conversión única (to_3d / to_3d_flat / tamaños).
func _paso0_escenario() -> void:
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(20):
		await physics_frame
		await process_frame
	var stage = null
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("WorldStage3D.gd"):
			stage = n
			break
	_ok(stage != null, "hay escenario 3D")
	if stage == null:
		return
	var p := Vector2(412, 54)
	_ok((stage.to_3d_flat(p, 10.0) - Mapa3D.a_3d(p, 10.0)).length() < 1e-5, "to_3d_flat usa Mapa3D")
	var hs: float = stage.terrain_height_px(p)
	_ok((stage.to_3d(p, 10.0) - Mapa3D.a_3d(p, 10.0 + hs)).length() < 1e-5, "to_3d suma el relieve y usa Mapa3D")
	_ok((stage.to_3d(p, -60.0) - Mapa3D.a_3d(p, -60.0)).length() < 1e-5, "bajo tierra (< −40 px) no suma relieve")
	_ok((stage.size_3d(Vector2(30, 20), 40.0) - Mapa3D.tam_a_3d(Vector2(30, 20), 40.0)).length() < 1e-5, "tamaños 3D usan Mapa3D")


## Paso 1: el protagonista anda con su cuerpo 3D: choca con los muros, cruza puertas, salta y aterriza, y sigue los
## cambios de sitio hechos a mano.
func _paso1_cuerpo() -> void:
	var pl = get_first_node_in_group("player")
	var vm = get_first_node_in_group("village_manager")
	var mc = pl.get_node("PlayerMovementController")
	mc.set_physics_process(false) # lo movemos nosotros, paso a paso
	var c: CharacterBody3D = mc.cuerpo()
	_ok(c != null, "1: el protagonista tiene cuerpo 3D")
	if c == null:
		return
	_ok(pl.collision_mask == 0, "1: el protagonista ya no choca en el mapa (choca su cuerpo 3D)")
	# Puerta de la taberna: fuera, andar hacia dentro (las puertas se abren al llegar)
	var puerta: Dictionary = {}
	for d in vm.building_doors:
		if String(d.get("building_id", "")) == "building_tavern":
			puerta = d
	_ok(not puerta.is_empty(), "1: hay puerta de la taberna")
	if puerta.is_empty():
		return
	var fuera: Vector2 = vm.get_door_outward_dir(puerta)
	var rect: Rect2 = puerta["building_rect"]
	pl.global_position = puerta["pos"] + fuera * 30.0
	await _andar(pl, mc, -fuera, 120.0, 1.6)
	_ok(rect.has_point(pl.global_position), "1: cruza la puerta de la taberna y entra (" + str(pl.global_position.round()) + ")")
	_ok(c.choques_copiados() > 0, "1: hay %d choques copiados en 3D alrededor" % c.choques_copiados())
	# Muro: desde dentro, andar hacia un muro lateral sin puerta → se queda dentro
	var lado := Vector2(fuera.y, -fuera.x)
	pl.global_position = rect.get_center()
	await _andar(pl, mc, lado, 120.0, 4.0)
	_ok(rect.grow(-1.0).has_point(pl.global_position), "1: el muro para al protagonista (" + str(pl.global_position.round()) + ")")
	# Salto al aire libre: sube ~1,2 m y vuelve al suelo
	pl.global_position = puerta["pos"] + fuera * 60.0
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.3)
	var y0: float = c.global_position.y
	_ok(pl.start_jump(), "1: salta")
	var cima: float = 0.0
	for _i in range(90):
		pl.velocity = Vector2.ZERO
		mc._mover()
		await physics_frame
		cima = maxf(cima, c.global_position.y - y0)
	_ok(cima > 0.9 and cima < 1.5, "1: el salto sube %.2f m (≈1,2 esperado)" % cima)
	_ok(not pl.is_jumping() and absf(c.global_position.y - y0) < 0.05, "1: y aterriza")
	# Cambio de sitio a mano (cama, escalera, cargar partida…)
	var lejos: Vector2 = puerta["pos"] + fuera * 200.0
	pl.global_position = lejos
	await _andar(pl, mc, Vector2.ZERO, 0.0, 0.1)
	_ok(Mapa3D.a_mapa(c.global_position).distance_to(lejos) < 1.0, "1: el cuerpo sigue al protagonista cuando lo cambian de sitio")
	mc.set_physics_process(true)


func _andar(pl, mc, dir: Vector2, vel: float, segundos: float) -> void:
	for _i in range(int(segundos * 60.0)):
		pl.velocity = dir * vel
		mc._mover()
		await physics_frame
