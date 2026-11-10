extends SceneTree

## Crea res://mapa/EditorMapa.tscn con el río y los puentes tal como están hoy en el juego (Claude Code, 2026-11-09).
## Solo hace falta una vez; si la escena ya existe no la pisa (añade «-- forzar» para rehacerla).
## Uso: timeout 60 flatpak run org.godotengine.Godot --headless --path . -s tools/crear_editor_mapa.gd

const KIND_TO_TIPO := {"ford": 0, "wood_bridge": 1, "stone_wood_bridge": 2}

func _initialize() -> void:
	var path := "res://mapa/EditorMapa.tscn"
	if ResourceLoader.exists(path) and not ("forzar" in OS.get_cmdline_user_args()):
		print("MAPA ya existe; no lo toco")
		quit(0)
		return
	var FS = load("res://scripts/obstacles/FishingSpot.gd")
	var root := Node2D.new()
	root.name = "EditorMapa"
	root.set_script(load("res://mapa/editor_mapa.gd"))
	var ref := Node2D.new()
	ref.name = "Referencia"
	ref.set_script(load("res://mapa/referencia.gd"))
	ref.z_index = -10
	root.add_child(ref)
	var rio := Node2D.new()
	rio.name = "Rio"
	rio.set_script(load("res://mapa/rio.gd"))
	root.add_child(rio)
	var i: int = 0
	for wp in FS.RIVER_WAYPOINTS:
		i += 1
		var m := Marker2D.new()
		m.set_script(load("res://mapa/punto_rio.gd"))
		m.name = "Punto%02d" % i
		m.position = wp
		m.set("ancho", FS.ancho_original(wp.y))
		rio.add_child(m)
	var cr_root := Node2D.new()
	cr_root.name = "Cruces"
	root.add_child(cr_root)
	for cr in FS.RIVER_CROSSINGS:
		var c := Marker2D.new()
		c.set_script(load("res://mapa/cruce_rio.gd"))
		c.name = str(cr["label"]).replace(" ", "")
		c.position = cr["pos"]
		c.set("nombre", str(cr["label"]))
		c.set("tipo", int(KIND_TO_TIPO.get(str(cr["kind"]), 1)))
		c.set("ancho", float(cr["half_h"]) * 2.0)
		c.set("largo", float(cr["half_w"]) * 2.0)
		c.set("altura_arco", float(cr["arch_h"]))
		c.set("id_interno", str(cr["id"]))
		cr_root.add_child(c)
	for n in [ref, rio, cr_root]:
		_own(n, root)
	var ps := PackedScene.new()
	ps.pack(root)
	print("MAPA guardado: ", ResourceSaver.save(ps, path))
	root.free()
	# Comprobación: la escena recién hecha debe dar el río original exacto
	var RF = load("res://mapa/rio_forma.gd")
	var d: Dictionary = RF.leer_escena(path)
	print("MAPA puntos=%d cruces=%d original=%s" % [d["pts"].size(), d["cruces"].size(), str(FS.es_rio_original(d))])
	quit(0)


func _own(n: Node, owner_node: Node) -> void:
	n.owner = owner_node
	for c in n.get_children():
		_own(c, owner_node)
