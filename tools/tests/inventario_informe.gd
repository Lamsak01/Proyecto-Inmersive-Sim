extends RefCounted

## Informe del inventario del mundo (Claude Code, 2026-11-11). Compara las dos partidas de tools/tests/inventario_mundo.gd
## y cuenta los números de posición escritos en el código. Escribe docs/INVENTARIO_MUNDO.md para el usuario y los agentes.

const Mapa3D = preload("res://scripts/fisica/Mapa3D.gd")
const INFORME := "res://docs/INVENTARIO_MUNDO.md"
const REFERENCIA := "res://mapa/referencia_mapa.json"
const TOLERANCIA_PX: float = 3.0 ## ~17 cm: menos que eso es «lo mismo»
const FILAS_MAX: int = 60
const CARPETAS_CODIGO: Array[String] = ["res://scripts", "res://mapa"]
const CARPETAS_SIN_MAPA: Array[String] = ["res://scripts/ui"] ## tamaños de ventanas y botones, no sitios del mapa
const MINIMO_POSICION: float = 100.0
const MARGEN_EDIFICIO_PX: float = 40.0 ## ~2 m: un farol de fachada o un banco de la puerta todavía cuentan como «dentro»
## Piezas hechas con cajas (muros, suelos, tejados), luces o bloques ya fusionados (su posición no es la del mueble): lo que interesa fuera de un edificio son los muebles con modelo.
const NO_SON_MUEBLES: Array[String] = ["MeshInstance3D", "OmniLight3D", "SpotLight3D", "CollisionShape3D", "Label3D", "Sprite3D", "Face", "FaceBack", "Juntado"] ## un número de 100 px o más casi siempre es un sitio del mapa, no un tamaño

const SIGUE := "sigue al editor"
const QUIETO := "se queda en el sitio viejo"
const DOBLE := "se mueve el doble (traducido dos veces)"
const MAL := "acaba en otro sitio o no aparece"
const CLASES: Array[String] = [SIGUE, QUIETO, DOBLE, MAL]


## Las piezas sin nombre propio («@MeshInstance3D@123») no se llaman igual en las dos partidas: se emparejan por familia
## y posición. Cada cosa de la partida quieta busca su pareja en la movida, en este orden: movida lo mismo que el editor,
## en el mismo sitio, movida el doble. Cada pareja se usa una sola vez.
static func escribir(quieto: Dictionary, movido: Dictionary, d: Vector2) -> void:
	var familias: Dictionary = {} # familia -> {clase: n, "ejemplo": texto}
	var totales: Dictionary = {}
	for k: String in CLASES:
		totales[k] = 0
	var plantas: Array[Rect2] = _plantas(quieto)
	_quitar_plantas(quieto)
	_quitar_plantas(movido)
	var indice: Dictionary = _indice(movido)
	var edificios: Array = _edificios()
	for clave: String in quieto.keys():
		var fam := _familia(clave)
		var p := Vector2(quieto[clave][0], quieto[clave][1])
		var clase: String = MAL
		for intento: Array in [[SIGUE, d], [QUIETO, Vector2.ZERO], [DOBLE, d * 2.0]]:
			if _gastar(indice, fam, p + (intento[1] as Vector2)):
				clase = intento[0]
				break
		totales[clase] += 1
		if not familias.has(fam):
			familias[fam] = {"ejemplo": ""}
			for k: String in CLASES:
				familias[fam][k] = 0
		familias[fam][clase] += 1
		if clase != SIGUE and String(familias[fam]["ejemplo"]).is_empty():
			familias[fam]["ejemplo"] = _cerca_de(p, edificios)
	var md := PackedStringArray()
	md.append("# Inventario del mundo (paso 0 de `docs/PLAN_MUNDO_DESDE_EDITOR.md`)\n")
	md.append("> Generado por `tools/tests/inventario_mundo.gd` el %s. Se movieron **todas** las piezas del editor %s px y se miró qué se movió con ellas. Solo cuenta lo que no se mueve solo (vecinos, animales y el jugador quedan fuera).\n" % [Time.get_date_string_from_system(), str(d)])
	md.append("## Resumen\n")
	md.append("| Resultado | Cosas |\n|---|---:|")
	for k: String in CLASES:
		md.append("| %s | %d |" % [k, totales[k]])
	md.append("")
	md.append(_tabla_familias(familias))
	md.append(_tabla_fuera(quieto, plantas, edificios))
	md.append(_tabla_codigo())
	var f := FileAccess.open(INFORME, FileAccess.WRITE)
	f.store_string("\n".join(md) + "\n")
	f.close()
	print("INVENTARIO sigue=%d quieto=%d doble=%d mal=%d → %s" % [totales[SIGUE], totales[QUIETO], totales[DOBLE], totales[MAL], INFORME])


## familia -> celda -> cuántas cosas de esa familia hay en esa celda de la partida movida.
static func _indice(movido: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for clave: String in movido.keys():
		var fam := _familia(clave)
		if not out.has(fam):
			out[fam] = {}
		var c := _celda(Vector2(movido[clave][0], movido[clave][1]))
		out[fam][c] = int(out[fam].get(c, 0)) + 1
	return out


static func _celda(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x / TOLERANCIA_PX), roundi(p.y / TOLERANCIA_PX))


## ¿Hay una cosa de esa familia junto a `p` (celda o vecinas)? Si la hay, la gasta para que no empareje dos veces.
static func _gastar(indice: Dictionary, fam: String, p: Vector2) -> bool:
	if not indice.has(fam):
		return false
	var celdas: Dictionary = indice[fam]
	var c := _celda(p)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var k := c + Vector2i(dx, dy)
			if int(celdas.get(k, 0)) > 0:
				celdas[k] = int(celdas[k]) - 1
				return true
	return false


## Familia: tipo de cosa (3D, lógica 2D o sitio de vecino) + parte del escenario + nombre sin números.
static func _familia(clave: String) -> String:
	var partes := clave.split("|")
	if partes[0] == "const":
		return "Sitio en el código: %s.%s" % [partes[1], partes[2]]
	if partes[0] == "vecino":
		return "Sitio de vecino: " + partes[2]
	var ruta := partes[1].split("/")
	var i_raiz: int = ruta.find("StageRoot3D") + 1
	var raiz: String = _base(ruta[i_raiz]) if i_raiz > 0 and i_raiz < ruta.size() - 1 else ""
	var padre: String = _base(ruta[ruta.size() - 2]) if ruta.size() > 1 else ""
	var tipo: String = "3D" if partes[0] == "3d" else "Lógica 2D"
	return "%s · %s / %s / %s" % [tipo, raiz, padre, _base(ruta[ruta.size() - 1])]


## Quita los números de las copias («Farola_12», «@MeshInstance3D@7309», «Zona_3_0») pero no los del nombre («Terrain3D»).
static func _base(nombre: String) -> String:
	var re := RegEx.create_from_string("^@|@\\d*$|(_-?\\d+)+$")
	return re.sub(nombre, "", true)


static func _edificios() -> Array:
	var out: Array = []
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(REFERENCIA))
	if not (datos is Dictionary):
		return out
	var ED: Script = load("res://mapa/edificio.gd")
	for e: Variant in (datos as Dictionary).get("edificios", []):
		var r: Array = e["r"]
		var centro := Vector2(r[0] + r[2] * 0.5, r[1] + r[3] * 0.5) * Mapa3D.E
		out.append([ED.call("nombre_legible", String(e["id"])), centro])
	return out


static func _cerca_de(p: Vector2, edificios: Array) -> String:
	var mejor := "campo abierto"
	var dist_min := INF
	for e: Array in edificios:
		var dist: float = p.distance_to(e[1])
		if dist < dist_min:
			dist_min = dist
			mejor = String(e[0])
	return "a %d m de %s" % [int(dist_min * Mapa3D.ESCALA), mejor]


static func _tabla_familias(familias: Dictionary) -> String:
	var orden: Array = familias.keys()
	orden.sort_custom(func(x: String, y: String) -> bool:
		return _restos(familias[x]) > _restos(familias[y]))
	var t := PackedStringArray(["## Por familia (las %d con más restos)\n" % FILAS_MAX, "| Familia | Sigue | Quieto | Doble | Otro sitio | Ejemplo de resto |", "|---|---:|---:|---:|---:|---|"])
	for fam: String in orden.slice(0, FILAS_MAX):
		var f: Dictionary = familias[fam]
		if _restos(f) == 0:
			break
		t.append("| %s | %d | %d | %d | %d | %s |" % [fam, f[SIGUE], f[QUIETO], f[DOBLE], f[MAL], f["ejemplo"]])
	return "\n".join(t) + "\n"


static func _plantas(datos: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for clave: String in datos.keys():
		if clave.begins_with("edificio|"):
			var v: Array = datos[clave]
			out.append(Rect2(v[0], v[1], v[2], v[3]).grow(MARGEN_EDIFICIO_PX))
	return out


static func _quitar_plantas(datos: Dictionary) -> void:
	for clave: String in datos.keys():
		if clave.begins_with("edificio|"):
			datos.erase(clave)


## Muebles 3D que hoy, sin mover nada, están fuera de cualquier edificio (como el altar de la iglesia sobre la hierba).
static func _tabla_fuera(quieto: Dictionary, plantas: Array[Rect2], edificios: Array) -> String:
	var por_modelo: Dictionary = {} # modelo -> [cuántos, ejemplo]
	var total: int = 0
	for clave: String in quieto.keys():
		if not clave.begins_with("3d|") or not "/Buildings3D/" in clave:
			continue
		var modelo := _base(clave.get_slice("/", clave.get_slice_count("/") - 1))
		if modelo in NO_SON_MUEBLES:
			continue
		var p := Vector2(quieto[clave][0], quieto[clave][1])
		if plantas.any(func(r: Rect2) -> bool: return r.has_point(p)):
			continue
		total += 1
		if not por_modelo.has(modelo):
			por_modelo[modelo] = [0, _cerca_de(p, edificios)]
		por_modelo[modelo][0] += 1
	var t := PackedStringArray(["## Muebles fuera de todo edificio hoy (sin mover nada)\n", "Total: **%d** muebles con modelo 3D fuera de la planta de cualquier edificio (con %d px de margen).\n" % [total, int(MARGEN_EDIFICIO_PX)], "| Mueble | Cuántos | Ejemplo |", "|---|---:|---|"])
	for modelo: String in por_modelo.keys():
		t.append("| %s | %d | %s |" % [modelo, por_modelo[modelo][0], por_modelo[modelo][1]])
	return "\n".join(t) + "\n"


static func _restos(f: Dictionary) -> int:
	return int(f[QUIETO]) + int(f[DOBLE]) + int(f[MAL])


## Números de posición escritos a mano en el código y llamadas a la traducción, por archivo.
static func _tabla_codigo() -> String:
	var re_v := RegEx.create_from_string("Vector2\\(\\s*(-?\\d+(?:\\.\\d+)?)\\s*,\\s*(-?\\d+(?:\\.\\d+)?)\\s*\\)")
	var re_r := RegEx.create_from_string("Rect2\\(\\s*-?\\d|Rect2\\(\\s*Vector2\\(\\s*-?\\d")
	var re_a := RegEx.create_from_string("\\.(a_mundo|estirar|estirar_puntos|colocar_plano)\\(")
	var filas: Array = []
	var total := Vector3i.ZERO
	for ruta: String in _archivos_gd():
		var texto := FileAccess.get_file_as_string(ruta)
		var pos: int = 0
		for m: RegExMatch in re_v.search_all(texto):
			if maxf(absf(float(m.get_string(1))), absf(float(m.get_string(2)))) >= MINIMO_POSICION:
				pos += 1
		var fila := Vector3i(pos, re_r.search_all(texto).size(), re_a.search_all(texto).size())
		total += fila
		if fila.x + fila.y > 0:
			filas.append([ruta.trim_prefix("res://"), fila])
	filas.sort_custom(func(x: Array, y: Array) -> bool: return (x[1] as Vector3i).x + (x[1] as Vector3i).y > (y[1] as Vector3i).x + (y[1] as Vector3i).y)
	var t := PackedStringArray(["## Números de posición en el código (sin la carpeta de menús)\n",
		"Total: **%d** puntos (Vector2 con algún valor ≥ %d px) y **%d** rectángulos fijos; **%d** llamadas a la traducción.\n" % [total.x, int(MINIMO_POSICION), total.y, total.z],
		"| Archivo | Puntos | Rectángulos | Traducciones |", "|---|---:|---:|---:|"])
	for fila: Array in filas.slice(0, FILAS_MAX):
		var v: Vector3i = fila[1]
		t.append("| `%s` | %d | %d | %d |" % [fila[0], v.x, v.y, v.z])
	return "\n".join(t) + "\n"


static func _archivos_gd() -> Array[String]:
	var out: Array[String] = []
	var pendientes: Array[String] = CARPETAS_CODIGO.duplicate()
	while not pendientes.is_empty():
		var dir: String = pendientes.pop_back()
		if dir in CARPETAS_SIN_MAPA:
			continue
		for sub: String in DirAccess.get_directories_at(dir):
			pendientes.append(dir + "/" + sub)
		for f: String in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				out.append(dir + "/" + f)
	return out
