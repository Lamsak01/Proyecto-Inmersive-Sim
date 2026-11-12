extends SceneTree

## Pone una sola vez el cartel de madera (mapa/cartel.gd) en la escena de cada edificio, junto a la puerta y en el
## lado contrario a la ventana (Claude Code, 2026-11-12). No toca un edificio que ya tenga cartel: así no pisa lo
## que el usuario haya movido. Si al lado de la puerta no cabe, lo pone encima de ella y lo avisa.
## Con ventana (sin ella las mallas de la escena se guardarían vacías), ~1 min:
##   flatpak run org.godotengine.Godot --path . -s tools/poner_carteles.gd

const Cartel = preload("res://mapa/cartel.gd")
const Marca = preload("res://mapa/marca.gd")
const Planta = preload("res://mapa/planta.gd")
const CARPETA := "res://mapa/edificios/"
const ALTURA_M: float = 2.4               ## centro del cartel: a la altura de los ojos, algo por encima
const ALTO_PUERTA_M: float = 3.25         ## arriba del hueco de la puerta (para el cartel encima de ella)
const SEPARACION_PARED_M: float = 0.2     ## del centro del muro (donde está la marca) a la cara de fuera
## Pruebas en orden [hueco entre el marco de la puerta y el cartel, ancho del cartel]: primero apartado (deja sitio a
## los postes del porche) y de ancho normal; luego más estrecho; y por último más pegado a la puerta.
const PRUEBAS: Array = [[0.6, 1.5], [0.6, 1.2], [0.6, 1.0], [0.25, 1.5]]
const MEDIA_VENTANA_M: float = 0.8        ## media ventana con su marco
const MARGEN_ESQUINA_M: float = 0.2
## Lado de la puerta → [hacia fuera, a lo largo de la pared, giro del cartel para mirar a la calle].
const LADOS: Dictionary = {
	"south": [Vector3(0, 0, 1), Vector3(1, 0, 0), 0.0],
	"north": [Vector3(0, 0, -1), Vector3(1, 0, 0), PI],
	"east": [Vector3(1, 0, 0), Vector3(0, 0, 1), PI / 2.0],
	"west": [Vector3(-1, 0, 0), Vector3(0, 0, 1), -PI / 2.0],
}


func _initialize() -> void:
	var puestos: int = 0
	for archivo: String in DirAccess.get_files_at(CARPETA):
		if archivo.get_extension() == "tscn":
			puestos += _poner(CARPETA + archivo)
	print("CARTELES: %d puestos" % puestos)
	quit(0)


func _poner(ruta: String) -> int:
	var escena: PackedScene = load(ruta)
	var raiz: Node3D = escena.instantiate()
	var puerta: Node3D = raiz.get_node_or_null(Marca.CARPETA + "/" + Marca.PUERTA)
	var ventana: Node3D = raiz.get_node_or_null(Marca.CARPETA + "/" + Marca.VENTANA)
	if raiz.has_node(Cartel.NOMBRE_NODO) or puerta == null or ventana == null:
		raiz.free()
		return 0
	var cartel := Node3D.new()
	cartel.set_script(Cartel)
	cartel.name = Cartel.NOMBRE_NODO
	var sitio: Array = _sitio(raiz, puerta.position, ventana.position, ruta)
	cartel.transform = sitio[0]
	cartel.set("ancho_m", sitio[1])
	raiz.add_child(cartel)
	cartel.owner = raiz
	var nueva := PackedScene.new()
	var error: int = nueva.pack(raiz)
	if error == OK:
		error = ResourceSaver.save(nueva, ruta)
	raiz.free()
	if error != OK:
		push_error("CARTELES: no pude guardar %s (error %d)" % [ruta, error])
		return 0
	return 1


## [sitio, ancho] del cartel: junto a la puerta, del lado sin ventana; si no cabe, del otro (si no pisa la ventana),
## según PRUEBAS; y si nada cabe, encima de la puerta.
func _sitio(raiz: Node3D, puerta: Vector3, ventana: Vector3, ruta: String) -> Array:
	var media: Vector2 = (raiz.get("planta_m") as Vector2) * 0.5
	var lado: Array = LADOS[Planta._lado_mas_cercano(Vector2(puerta.x, puerta.z), media)] # misma regla que el juego
	var fuera: Vector3 = lado[0]
	var largo: Vector3 = lado[1]
	var media_pared: float = absf(Vector3(media.x, 0.0, media.y).dot(largo))
	var lejos_ventana: float = -signf((ventana - puerta).dot(largo))
	for prueba: Array in PRUEBAS:
		var ancho: float = prueba[1]
		var aparte: float = float(raiz.get("puerta_ancho_m")) * 0.5 + float(prueba[0]) + ancho * 0.5
		for sentido: float in [lejos_ventana if lejos_ventana != 0.0 else 1.0, -lejos_ventana]:
			var centro: Vector3 = puerta + largo * sentido * aparte
			if _cabe(centro, ancho, ventana, largo, media_pared):
				return [_colocado(centro, ALTURA_M, fuera, float(lado[2])), ancho]
	print("CARTELES: en %s no cabe al lado de la puerta; va encima" % ruta.get_file())
	return [_colocado(puerta, ALTO_PUERTA_M + Cartel.ALTO_M, fuera, float(lado[2])), Cartel.ANCHO_M]


## Dentro de la pared (sin pasar de la esquina) y sin tapar la ventana.
func _cabe(centro: Vector3, ancho: float, ventana: Vector3, largo: Vector3, media_pared: float) -> bool:
	var en_pared: bool = absf(centro.dot(largo)) + ancho * 0.5 + MARGEN_ESQUINA_M <= media_pared
	return en_pared and absf((centro - ventana).dot(largo)) >= ancho * 0.5 + MEDIA_VENTANA_M


func _colocado(sobre_muro: Vector3, alto: float, fuera: Vector3, giro: float) -> Transform3D:
	var sitio: Vector3 = sobre_muro + fuera * SEPARACION_PARED_M
	sitio.y = alto
	return Transform3D(Basis(Vector3.UP, giro), sitio)
