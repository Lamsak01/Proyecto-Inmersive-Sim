extends RefCounted

## Piezas sueltas del constructor de casas (tools/casas/construir_casa.gd), 2026-11-13: cajas con material, muros con
## huecos, hojas de puerta y ventanas. Todo en metros respecto al centro de la casa, con el suelo de la calle en y = 0.

const PARTES = preload("res://scripts/visuals/PartesEdificio3D.gd")

const TEXTURAS := "res://assests/curated_3d/town_textures/"
const ESCALA_TEXTURA: float = 0.2786   ## repetición de las texturas pixeladas (la de los edificios de siempre)
const GROSOR_HOJA_M: float = 0.06
const ALTO_HOJA_M: float = 2.1
const JUEGO_HOJA_M: float = 0.04       ## holgura de la hoja dentro del hueco
const GIRO_HOJA_PARED_Z: float = 90.0  ## en un muro norte-sur la hoja va a lo largo del eje z

static var _materiales: Dictionary = {}


## Material pixelado con textura de la carpeta del pueblo (o solo color si `textura` está vacía).
static func material(textura: String, color: Color = Color.WHITE, metal: float = 0.0) -> StandardMaterial3D:
	var clave: String = "%s|%s|%s" % [textura, color.to_html(), metal]
	if _materiales.has(clave):
		return _materiales[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.88
	m.metallic = metal
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if not textura.is_empty():
		m.albedo_texture = load(TEXTURAS + textura) as Texture2D
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * ESCALA_TEXTURA
	_materiales[clave] = m
	return m


## Caja de tamaño `tam` con la base en `base` (centro de su cara de abajo).
static func caja(padre: Node3D, base: Vector3, tam: Vector3, mat: Material, giro_y: float = 0.0) -> MeshInstance3D:
	var forma := BoxMesh.new()
	forma.size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = forma
	mi.material_override = mat
	mi.rotation_degrees.y = giro_y
	mi.position = base + Vector3(0.0, tam.y * 0.5, 0.0)
	padre.add_child(mi)
	return mi


## Muro recto de `a` a `b` (en el suelo, x-z) con huecos: cada hueco {"en": metros desde `a`, "ancho", "base", "alto"}.
## Bajo y sobre cada hueco queda muro (antepecho de ventana, dintel de puerta).
static func muro(padre: Node3D, a: Vector2, b: Vector2, suelo_y: float, alto: float, grosor: float, huecos: Array, mat: Material) -> void:
	var largo: float = a.distance_to(b)
	var dir: Vector2 = (b - a) / largo
	var giro: float = rad_to_deg(atan2(-dir.y, dir.x))
	var cortes: Array = huecos.duplicate()
	cortes.sort_custom(func(h1: Dictionary, h2: Dictionary) -> bool: return float(h1["en"]) < float(h2["en"]))
	var desde: float = 0.0
	for h: Dictionary in cortes:
		var ini: float = float(h["en"]) - float(h["ancho"]) * 0.5
		var fin: float = float(h["en"]) + float(h["ancho"]) * 0.5
		_tramo(padre, a, dir, giro, desde, ini, suelo_y, alto, grosor, mat)
		var base_h: float = float(h.get("base", 0.0))
		var tope_h: float = base_h + float(h["alto"])
		_tramo(padre, a, dir, giro, ini, fin, suelo_y, base_h, grosor, mat)
		_tramo(padre, a, dir, giro, ini, fin, suelo_y + tope_h, alto - tope_h, grosor, mat)
		desde = fin
	_tramo(padre, a, dir, giro, desde, largo, suelo_y, alto, grosor, mat)


static func _tramo(padre: Node3D, a: Vector2, dir: Vector2, giro: float, ini: float, fin: float, y: float, alto: float, grosor: float, mat: Material) -> void:
	if fin - ini < 0.01 or alto < 0.01:
		return
	var medio: Vector2 = a + dir * (ini + fin) * 0.5
	caja(padre, Vector3(medio.x, y, medio.y), Vector3(fin - ini, alto, grosor), mat, giro)


## Hoja de puerta que gira sobre su bisagra. `a_lo_largo_z`: el muro va de norte a sur. La hoja cubre el hueco de ancho
## `ancho` desde la bisagra. Devuelve el pivote (gira entero al abrir).
static func hoja(padre: Node3D, bisagra: Vector3, ancho: float, a_lo_largo_z: bool, mat: Material) -> Node3D:
	var pivote := Node3D.new()
	pivote.position = bisagra
	padre.add_child(pivote)
	var tabla := Node3D.new()
	tabla.rotation_degrees.y = -GIRO_HOJA_PARED_Z if a_lo_largo_z else 0.0
	pivote.add_child(tabla)
	var w: float = ancho - JUEGO_HOJA_M
	caja(tabla, Vector3(w * 0.5, 0.0, 0.0), Vector3(w, ALTO_HOJA_M, GROSOR_HOJA_M), mat)
	return pivote


## Puerta de un cuarto: se abre sola al acercarse alguien (scripts/visuals/PuertasInteriores3D.gd).
static func puerta_de_cuarto(padre: Node3D, centro: Vector3, ancho: float, a_lo_largo_z: bool, mat: Material, nivel: int = 0) -> void:
	var bisagra: Vector3 = centro - (Vector3(0.0, 0.0, ancho * 0.5) if a_lo_largo_z else Vector3(ancho * 0.5, 0.0, 0.0))
	var pivote: Node3D = hoja(padre, bisagra, ancho, a_lo_largo_z, mat)
	pivote.set_meta(PARTES.ROL, PARTES.PUERTA_CUARTO)
	pivote.set_meta(PARTES.HUECO, centro)
	pivote.set_meta(PARTES.NIVEL, nivel) # la planta en que está (las de arriba se abren para quien está arriba)


## Ventana: marco, cristal (luz) y postigo cerrado escondido. `giro`: 0 en muros este-oeste, 90 en norte-sur.
static func ventana(padre: Node3D, centro: Vector3, ancho: float, alto: float, giro: float, marco: Material, vidrio: Material, abre: bool) -> void:
	var cristal := Node3D.new()
	cristal.position = centro
	cristal.rotation_degrees.y = giro
	padre.add_child(cristal)
	caja(cristal, Vector3(0.0, -alto * 0.5, 0.0), Vector3(ancho, alto, 0.04), vidrio)
	caja(cristal, Vector3(0.0, -alto * 0.5 - 0.06, 0.0), Vector3(ancho + 0.12, 0.06, 0.3), marco)
	caja(cristal, Vector3(0.0, alto * 0.5, 0.0), Vector3(ancho + 0.12, 0.06, 0.3), marco)
	if not abre:
		return
	cristal.set_meta(PARTES.ROL, PARTES.CRISTAL)
	var postigo: MeshInstance3D = caja(padre, centro - Vector3(0.0, alto * 0.5, 0.0), Vector3(ancho, alto, 0.06), marco, giro)
	postigo.visible = false
	postigo.set_meta(PARTES.ROL, PARTES.POSTIGO)
