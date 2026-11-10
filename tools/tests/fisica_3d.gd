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
	await _paso0_escenario()
	print("FISICA 3D: %s (%d fallos)" % ["PASSED" if _fallos == 0 else "FAILED", _fallos])
	quit(1 if _fallos > 0 else 0)


## Paso 0: la conversión única da los mismos números que la fórmula antigua y va y vuelve sin perder nada.
func _paso0_conversion() -> void:
	var s: float = sin(deg_to_rad(58.0))
	var c: float = cos(deg_to_rad(58.0))
	var peor: float = 0.0
	var peor_vuelta: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 58
	for _i in range(2000):
		var p := Vector2(rng.randf_range(-2000, 2000), rng.randf_range(-1500, 1500))
		var h: float = rng.randf_range(-80, 200)
		var antigua := Vector3(p.x * 0.02, (h * 0.02) / c, (p.y * 0.02) / s)
		peor = maxf(peor, (Mapa3D.a_3d(p, h) - antigua).length())
		peor_vuelta = maxf(peor_vuelta, (Mapa3D.a_mapa(Mapa3D.a_3d(p, h)) - p).length())
		peor_vuelta = maxf(peor_vuelta, absf(Mapa3D.alto_a_px(Mapa3D.alto_a_3d(h)) - h))
	_ok(peor < 1e-4, "Mapa3D.a_3d = fórmula antigua (peor diferencia " + str(peor) + " unidades)")
	_ok(peor_vuelta < 1e-3, "mapa → 3D → mapa sin perder posición (peor " + str(peor_vuelta) + " px)")


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
