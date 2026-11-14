extends RefCounted

## FlechaFigura3D: lo que se ve de una flecha o de una bala en vuelo (tanda 7a-2 del paso a 3D, 2026-11-14): un astil
## fino con su punta de hierro, o un trazo corto y brillante. Va tumbada a lo largo de −Z, hacia donde mira su proyectil.

const LARGO_M: float = 0.7          ## astil de la flecha
const GROSOR_M: float = 0.008       ## radio del astil
const PUNTA_M: float = 0.07         ## largo de la punta de hierro
const LARGO_BALA_M: float = 0.12
const COLOR_ASTIL: Color = Color(0.55, 0.4, 0.24)
const COLOR_PUNTA: Color = Color(0.22, 0.22, 0.25)
const COLOR_BALA: Color = Color(1.0, 0.92, 0.52)


static func crear(es_bala: bool) -> MeshInstance3D:
	var forma := CylinderMesh.new()
	forma.top_radius = GROSOR_M
	forma.bottom_radius = GROSOR_M
	forma.height = LARGO_BALA_M if es_bala else LARGO_M
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_BALA if es_bala else COLOR_ASTIL
	material.emission_enabled = es_bala
	material.emission = COLOR_BALA
	forma.material = material
	var malla := MeshInstance3D.new()
	malla.mesh = forma
	malla.rotation_degrees.x = -90.0 # el cilindro, tumbado: su extremo +Y pasa a ser el de delante (−Z)
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not es_bala:
		malla.add_child(_punta())
	return malla


## La punta de hierro, delante del astil.
static func _punta() -> MeshInstance3D:
	var cono := CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = GROSOR_M * 2.5
	cono.height = PUNTA_M
	var hierro := StandardMaterial3D.new()
	hierro.albedo_color = COLOR_PUNTA
	cono.material = hierro
	var punta := MeshInstance3D.new()
	punta.mesh = cono
	punta.position.y = (LARGO_M + PUNTA_M) * 0.5
	punta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return punta
