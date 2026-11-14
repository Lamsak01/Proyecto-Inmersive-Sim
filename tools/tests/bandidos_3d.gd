extends SceneTree

## Prueba de los bandidos y de los secuestradores del Caso I como cuerpos 3D (paso a 3D, tanda 4b-3b, 2026-11-14).
## Sin ventana, ~40 s. Uso: timeout 200 flatpak run org.godotengine.Godot --headless --path . -s tools/tests/bandidos_3d.gd
## Termina con «BANDIDOS 3D: PASSED» o «FAILED».

const PASOS_POR_S: int = 60
const CAMPO: Vector2 = Vector2(-330.0, 14.0) ## un sitio despejado al oeste del pueblo (metros sobre el suelo)

var _fallos: int = 0
var _vm: Node = null
var _pl: Node2D = null
var _fin: Dictionary = {}


func _ok(c: bool, txt: String) -> void:
	print(("  OK  " if c else "  FALLO  ") + txt)
	if not c:
		_fallos += 1


func _initialize() -> void:
	root.add_child(load("uid://dsoiuct8kdsk3").instantiate())
	for _i in range(40):
		await physics_frame
	_vm = get_first_node_in_group("village_manager")
	_pl = get_first_node_in_group("player") as Node2D
	await _bandido_ataca_y_huye()
	await _secuestrador_espera_y_ataca()
	print("BANDIDOS 3D: %s (%d fallos)" % ["PASSED" if _fallos == 0 else "FAILED", _fallos])
	quit(1 if _fallos > 0 else 0)


func _esperar(segundos: float) -> void:
	for _i in range(int(segundos * PASOS_POR_S)):
		await physics_frame
		_pl.velocity = Vector2.ZERO


func _prota_a(sitio: Vector2) -> void:
	_vm.call("set_player_elevation_level", 0)
	_pl.global_position = Lugar.a_mapa(sitio)
	_pl.velocity = Vector2.ZERO


func _golpe(cuanto: float) -> Object:
	var g = load("res://scripts/systems/combat/DamageData.gd").new()
	g.amount = cuanto
	g.source = _pl
	return g


func _bandido_ataca_y_huye() -> void:
	_prota_a(CAMPO)
	await _esperar(0.3)
	var Raider = load("res://scripts/enemies/Raider.gd")
	var b = Raider.crear(self)
	b.setup("bandit", CAMPO + Vector2(4.0, 0.0), 1.0)
	b.gone.connect(func(_r, como: String): _fin["bandido"] = como)
	b.bandit_ammo_loaded = 0 # sin carabina: que venga a pegar
	b.bandit_reload_timer = 999.0
	_ok(b is CharacterBody3D and not (b is Node2D) and b.is_in_group("raiders") and Diana3D.de(b) != null, "un bandido ES un cuerpo 3D con su diana, sin nodo en el mapa plano")
	var Base = load("res://scripts/fisica/CuerpoBase3D.gd")
	_ok(absf(b.global_position.y - float(Base.suelo_y(b.global_position.x, b.global_position.z, 0, _vm))) < 0.3, "pisa el suelo")
	var vida: float = float(_pl.health_comp.current_health)
	await _esperar(5.0)
	_ok(b.sitio.distance_to(Lugar.de(_pl)) < 1.8, "viene a por el protagonista (está a %.2f m)" % b.sitio.distance_to(Lugar.de(_pl)))
	_ok(float(_pl.health_comp.current_health) < vida, "y le pega (vida %.0f → %.0f)" % [vida, float(_pl.health_comp.current_health)])
	b.take_damage(_golpe(b.max_hp * 0.8))
	_ok(b.fleeing and b.hit_by_player, "malherido, huye")
	var x0: float = b.sitio.x
	await _esperar(1.5)
	_ok(is_instance_valid(b) and b.sitio.x > x0 + 3.0, "corre hacia el este (%.1f m en 1,5 s)" % ((b.sitio.x - x0) if is_instance_valid(b) else 0.0))
	await _esperar(3.0)
	_ok(str(_fin.get("bandido", "")) == "fled" and not is_instance_valid(b), "y al alejarse se da por huido y desaparece")
	var j = Raider.crear(self)
	j.setup("boar", CAMPO + Vector2(3.0, 2.0), 1.0)
	j.gone.connect(func(_r, como: String): _fin["jabali"] = como)
	j.take_damage(_golpe(999.0))
	await _esperar(0.3)
	_ok(j.is_dead and j.tumbado and not Diana3D.de(j).activa and str(_fin.get("jabali", "")) == "killed" and j._forma.disabled, "un golpe mortal lo deja muerto: ni se le hiere ni estorba")
	j.queue_free()
	_pl.health_comp.current_health = _pl.health_comp.max_health


func _secuestrador_espera_y_ataca() -> void:
	var Kid = load("res://scripts/enemies/MillKidnapper.gd")
	_prota_a(CAMPO + Vector2(0.0, 40.0))
	await _esperar(0.3)
	var casa: Vector2 = CAMPO + Vector2(0.0, 40.0) + Vector2(8.0, 0.0)
	var k = Kid.crear(self, Kid)
	k.setup_kidnapper("prueba", "Forastero", casa)
	k.bandit_ammo_loaded = 0
	k.bandit_reload_timer = 999.0
	_ok(k is CharacterBody3D and k.is_in_group("case1_kidnappers") and not k.is_in_group("raiders"), "un secuestrador ES un cuerpo 3D y no cuenta como asaltante")
	await _esperar(3.0)
	_ok(k.sitio.distance_to(casa) < 0.5, "con el protagonista a 8 m se queda en su sitio (a %.2f m)" % k.sitio.distance_to(casa))
	_prota_a(casa + Vector2(-2.5, 0.0))
	var vida: float = float(_pl.health_comp.current_health)
	await _esperar(5.0)
	_ok(float(_pl.health_comp.current_health) < vida, "si te acercas a 2,5 m te ve, viene y te pega (vida %.0f → %.0f)" % [vida, float(_pl.health_comp.current_health)])
	_prota_a(casa + Vector2(-30.0, 0.0))
	await _esperar(6.0)
	_ok(is_instance_valid(k) and k.sitio.distance_to(casa) < 0.6, "y si te alejas, vuelve a su sitio")
	if is_instance_valid(k):
		k.queue_free()
