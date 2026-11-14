extends SceneTree

## Constructor de casas (2026-11-13, interiores de tamaño real): rehace la escena de un edificio a partir de su plano
## (tools/casas/plano_*.gd: cuartos, tabiques, ventanas, muebles y marcas) y pone su nueva planta en el mapa.
## El edificio sigue en su sitio del mapa (mismo centro); solo cambia por dentro y de tamaño.
##   flatpak run org.godotengine.Godot --headless --path . -s tools/casas/construir_casa.gd -- res://tools/casas/plano_casa_artesano.gd [id] [espejo] [girar]
## `id`: otra casa con el mismo plano; `espejo`: con los cuartos del este al oeste y al revés; `girar`: puerta al norte.
## Si Godot tiene abiertas la escena del edificio o el mapa: recargarlas SIN guardar después.

const Armar = preload("res://tools/casas/armar_casa.gd")
const LeerPlano = preload("res://tools/casas/leer_plano.gd")
const Marca = preload("res://mapa/marca.gd")
const CasaModelo = preload("res://mapa/casa_modelo.gd")

const MAPA := "res://mapa/Mundo3D.tscn"
const EDIFICIOS := "res://mapa/edificios/%s.tscn"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("CASA: falta el plano (res://tools/casas/plano_*.gd)")
		quit(1)
		return
	var plano: Dictionary = LeerPlano.leer(load(args[0]) as GDScript, args[1] if args.size() > 1 else "", args.has("espejo"), args.has("girar"))
	var ruta: String = EDIFICIOS % plano["ID"]
	var vieja: PackedScene = load(ruta) as PackedScene
	var centro: Vector2 = Marca.propiedades(vieja.get_state(), 0).get("centro_original", Vector2.ZERO)
	var raiz: Node3D = Armar.armar(plano, centro)
	var escena := PackedScene.new()
	var error: int = escena.pack(raiz)
	if error == OK:
		error = ResourceSaver.save(escena, ruta)
	raiz.free()
	if error != OK:
		push_error("CASA: no se pudo guardar %s (error %d)" % [ruta, error])
		quit(1)
		return
	if not CasaModelo.ESCENAS.values().has(ruta): # las casas modelo no tienen pieza en el mapa: se copian en los solares
		_planta_en_el_mapa(plano["ID"], plano["PLANTA_M"], plano["PUERTA_ANCHO_M"])
	print("CASA: %s rehecha (%s m)" % [ruta, plano["PLANTA_M"]])
	quit()


## El mapa guarda copia de la planta y del ancho de la puerta en la pieza del edificio: se ponen las nuevas.
func _planta_en_el_mapa(id: String, planta: Vector2, puerta: float) -> void:
	var texto: String = FileAccess.get_file_as_string(MAPA)
	var cabecera: String = '[node name="%s" type="Node3D" parent="Edificios"' % id
	var ini: int = texto.find(cabecera)
	if ini < 0:
		if texto.find('[node name="%s" parent="Edificios"' % id) < 0:
			push_error("CASA: el mapa no tiene la pieza «%s»" % id)
		return
	var fin: int = texto.find("\n[", ini + 1)
	var bloque: String = texto.substr(ini, fin - ini)
	var nuevo: String = _poner_linea(bloque, "planta_m", "Vector2(%s, %s)" % [String.num(planta.x, 3), String.num(planta.y, 3)])
	nuevo = _poner_linea(nuevo, "puerta_ancho_m", str(puerta))
	var archivo := FileAccess.open(MAPA, FileAccess.WRITE)
	archivo.store_string(texto.substr(0, ini) + nuevo + texto.substr(fin))
	archivo.close()


static func _poner_linea(bloque: String, campo: String, valor: String) -> String:
	var lineas: PackedStringArray = bloque.split("\n")
	for i in range(lineas.size()):
		if lineas[i].begins_with(campo + " = "):
			lineas[i] = "%s = %s" % [campo, valor]
	return "\n".join(lineas)
