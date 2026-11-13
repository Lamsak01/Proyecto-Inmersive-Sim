extends RefCounted

## Caso I: las preguntas del detective en Misiones (pestaña del caso). Las abren y cierran las pistas que encuentras,
## verdaderas o falsas; ninguna nombra el molino ni se puede fallar (idea del usuario, 2026-11-13;
## lista aprobada en docs/specs/OBJETIVOS_CASO1.md). Texto provisional.
## Claves: las del cuaderno del detective («zona:acción», «clue_…», «m_…», testigos «w_N»/«w2_N») o especiales con «@»
## («@escena:N» = pista N de la escena del claro, encontrada o anotada).
## Sin preload de VillageCase1 (que carga este archivo): quien llama pasa el estado y cómo mirar el cuaderno.

const PREFIJO: String = "caso1_"
const TIPO: String = "caso1_pregunta"
const CATEGORIA: String = "main" ## pestaña «Caso» del diario de misiones
const PRUEBAS_PARA_INFORME: int = 5

## id → título (la pregunta), por qué surge, claves que la abren (basta una) y claves que la cierran (basta una).
const PREGUNTAS: Array[Dictionary] = [
	{"id": "a0", "t": "El alguacil mayor Vane te manda llamar", "d": "Un guardia te ha traído el recado: Vane te espera en la comisaría.", "abre": ["@aviso"], "cierra": ["case1_encargo_vane"]},
	{"id": "a1", "t": "Han encontrado a una mujer muerta junto al arroyo del norte", "d": "Vane ha dejado a un guardia vigilando el cuerpo. Mírala antes de que se la lleven a la morgue.", "abre": ["case1_encargo_vane"], "cierra": ["cabeza:mirar", "cuello:mirar", "torso:mirar", "clue_case1_clearing"]},
	{"id": "p1", "t": "Labios azules y puntitos rojos en los ojos: ¿murió asfixiada?", "d": "Lo viste al mirarle la cara y el cuello.", "abre": ["cabeza:mirar", "cuello:mirar"], "cierra": ["m_cuello"]},
	{"id": "p2", "t": "Olía a almendra amarga: ¿qué bebió antes de morir?", "d": "El olor salía de su boca y del frasco vacío de su bolsillo.", "abre": ["cabeza:oler", "bolsillos:registrar"], "cierra": ["m_estomago"]},
	{"id": "p3", "t": "Un líquido verdoso en el estómago: ¿quién sabe de hierbas así?", "d": "La autopsia del estómago lo sacó a la luz.", "abre": ["m_estomago"], "cierra": ["clue_case1_alchemist_analyze_flask"]},
	{"id": "p4", "t": "Una poción cara, inestable y recién hecha: ¿quién pudo tenerla?", "d": "Lo dijo el boticario: no la usa ni el sacerdote.", "abre": ["clue_case1_alchemist_analyze_flask"], "cierra": ["clue_case1_noble_maid_recognize_vial"]},
	{"id": "p5", "t": "Alguien forzó el gabinete de los señores: ¿quién?", "d": "La criada reconoció el frasco y habló del gabinete.", "abre": ["clue_case1_noble_maid_recognize_vial"], "cierra": ["clue_case1_forced_cabinet"]},
	{"id": "p6", "t": "Barro rojo en los talones, ceniza en las rodillas, paja en el pelo: ¿dónde estuvo antes?", "d": "Lo llevaba encima; en el claro solo hay barro pardo.", "abre": ["piernas:mirar", "piernas:oler", "cabeza:lupa"], "cierra": ["clue_mill_red_clay"]},
	{"id": "p7", "t": "La ataron con cordel de cáñamo encerado: ¿de dónde sale ese cordel?", "d": "Había pelusa de cordel clavada en sus muñecas.", "abre": ["brazos:lupa"], "cierra": ["clue_mill_hemp_cord"]},
	{"id": "p8", "t": "La movieron ya muerta: ¿quién trajo un carro de madrugada?", "d": "La sangre se le posó en un costado y hay surcos y rodadas en el claro.", "abre": ["torso:palpar", "@escena:0", "@escena:2"], "cierra": ["w_0", "w2_0"]},
	{"id": "p9", "t": "¿Quién es «V.»? La citó en el puente viejo tras el toque de queda", "d": "La nota húmeda de su bolsillo.", "abre": ["bolsillos:registrar"], "cierra": ["clue_old_bridge_left_shoe"]},
	{"id": "p10", "t": "Se defendió: hay lana azul bajo sus uñas", "d": "Hebras de lana teñida de azul oscuro bajo dos uñas de la mano derecha.", "abre": ["manos:lupa"], "cierra": ["clue_case1_blue_wool"]},
	{"id": "p11", "t": "Un muchacho de capa parda corría junto al arroyo", "d": "Lo vio la pastora; nunca lo había visto por el pueblo.", "abre": ["w_1", "w2_1"], "cierra": ["@joven_fuera"]},
	{"id": "p12", "t": "La hoja arrancada viene de un libro: ¿de cuál?", "d": "Estaba junto a una cama, con dosis tachadas y corregidas a mano.", "abre": ["clue_case1_relative_page"], "cierra": ["clue_library_torn_book"]},
	{"id": "p13", "t": "Un libro viejo con dosis corregidas: ¿quién lo usó?", "d": "Al libro de la biblioteca le falta justo esa hoja.", "abre": ["clue_library_torn_book"], "cierra": ["clue_case1_relative_confession"]},
	{"id": "p14", "t": "Su desaparición se denunció y nadie la buscó: ¿por qué?", "d": "Alguien en el pueblo ya la echaba en falta antes de que apareciera.", "abre": ["case1_encargo_vane"], "cierra": ["clue_police_archived_report"]},
	{"id": "p15", "t": "Una fosa a medio cavar junto al cuerpo: ¿quién no terminó de enterrarla?", "d": "La tierra aún estaba húmeda y la pala, clavada en el montón.", "abre": ["clue_case1_grave"], "cierra": ["@joven_fuera", "clue_case1_relative_confession"]},
	{"id": "f1", "t": "El boticario guarda hierbas de embalsamar bajo llave: ¿fue él?", "d": "La sangre tenía restos de una hierba de embalsamar.", "abre": ["m_sangre"], "cierra": ["clue_case1_noble_maid_recognize_vial"]},
	{"id": "f2", "t": "El molinero tiene carro y cordel encerado: ¿fue él?", "d": "Cordel encerado en las muñecas y rodadas de carro en el claro.", "abre": ["brazos:lupa", "@escena:2"], "cierra": ["@joven_fuera", "clue_case1_relative_confession"]},
	{"id": "f3", "t": "Algunas casas del pueblo tienen ladrillos de esa misma arcilla roja: ¿estuvo en una?", "d": "El barro rojo de sus talones.", "abre": ["piernas:mirar"], "cierra": ["clue_mill_red_clay"]},
	{"id": "z", "t": "Entrega tu informe del caso en la comisaría", "d": "Ya tienes pruebas suficientes para señalar a alguien. Una vez firmado, no se cambia.", "abre": ["@pruebas"], "cierra": ["@informe"]},
]

## Abre y cierra las preguntas según el cuaderno. `tiene` es un Callable(clave: String) -> bool.
static func revisar(st: Dictionary, tiene: Callable, pruebas: int) -> void:
	var qm: Node = Engine.get_main_loop().root.get_node_or_null("/root/QuestManager") if Engine.get_main_loop() else null
	if qm == null:
		return
	for p: Dictionary in PREGUNTAS:
		var qid: String = PREFIJO + str(p["id"])
		var q: Dictionary = qm.get_quest(qid)
		if q.is_empty():
			if _alguna(p["abre"], st, tiene, pruebas):
				_abrir(qm, qid, p)
			continue
		if str(q.get("status", "")) == "active" and _alguna(p["cierra"], st, tiene, pruebas):
			qm.complete_quest(qid, "Resuelto con lo que has averiguado.")

static func _abrir(qm: Node, qid: String, p: Dictionary) -> void:
	qm.add_quest({"id": qid, "category": CATEGORIA, "type": TIPO, "title": str(p["t"]), "description": str(p["d"])})
	var jugador = qm.get_tree().get_first_node_in_group("player")
	if jugador != null and jugador.has_method("show_hint"):
		jugador.call("show_hint", "📓 Nueva pregunta del caso: %s  [L] Diario" % str(p["t"]))

static func _alguna(claves: Array, st: Dictionary, tiene: Callable, pruebas: int) -> bool:
	for k in claves:
		if _cumple(str(k), st, tiene, pruebas):
			return true
	return false

static func _cumple(clave: String, st: Dictionary, tiene: Callable, pruebas: int) -> bool:
	match clave:
		"@aviso":
			return str(st.get("aviso", "")) == "dado"
		"@joven_fuera":
			return str((st.get("kidnappers", {}) as Dictionary).get("young", "alive")) != "alive"
		"@pruebas":
			return pruebas >= PRUEBAS_PARA_INFORME
		"@informe":
			return st.get("report") is Dictionary
	return bool(tiene.call(clave)) # cuaderno del detective (y «@escena:N», que mira quien llama)
