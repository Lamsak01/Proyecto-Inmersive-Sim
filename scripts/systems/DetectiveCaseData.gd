@tool
extends RefCounted
class_name DetectiveCaseData

## Bloque D5 — Catálogo y formato de datos para los 10 casos principales guionizados.
## Permite que las herramientas del detective (D1: Examen del cuerpo, D2: Autopsia en la morgue,
## D3: Escena del crimen y D4: Tablero del caso) carguen cualquier caso guionizado desde datos puros
## sin tocar el código de la interfaz.
##
## Regla de diseño (ENCARGO_ANTIGRAVITY.md §D5 y PLAN_BETA_MISTERIO.md §5):
## - Lo fijo es la cadena de pistas; lo procedural es quién hace cada papel entre los vecinos reales.
## - Los huecos de la trama que el autor aún no ha decidido quedan marcados explícitamente con
##   `PENDIENTE_DECISION_USUARIO` y NO se inventan.

const PENDING_DECISION := "PENDIENTE_DECISION_USUARIO"

const CASE_01_ID := "case_01_forest_woman"

static var CASES: Dictionary = {
	"case_01_forest_woman": {
		"id": "case_01_forest_woman",
		"number": 1,
		"status": "skeleton_ready",
		"title": "Caso I · «La mujer del bosque»",
		"subtitle": "Caso I · «La mujer del bosque» — hallada al alba junto al arroyo del norte",
		"victim_gender": "F",
		"default_world_pos": Vector2(138, -860),
		"corner_left": "CADÁVER EN EL SUELO · NO MOVIDO",
		"corner_right": "TEMPERATURA AMBIENTE · FRÍO DE MADRUGADA",
		"scene_ground_label": "CLARO JUNTO AL ARROYO · CAMINO DEL NORTE ARRIBA",
		"pending_author_decisions": {
			"herb_name": "Belladama gris",
			"potion_name": "Sueño de cera",
			"how_stolen_potion_is_discovered": "La criada reconoce el frasco y menciona el gabinete de los señores; al registrar el gabinete (con su permiso o a escondidas) se ve la cerradura forzada. Sin marca en el polvo.",
			"potion_stability": {"full_strength_until_hour": 12, "degrades_from_hour": 13, "useless_at_hour": 48},
			"abandoned_house_location": "Molino viejo abandonado junto al arroyo, río arriba del claro donde aparece el cuerpo. Se llega siguiendo el agua. Allí la orilla es de barro rojo (la misma arcilla de los ladrillos de algunas casas del pueblo).",
			"sect_open_thread_hook": "Dos ganchos juntos: (a) en el molino hay una lista de nombres de personas desaparecidas; (b) la regla de las 48 horas obliga a preguntarse quién fabricó el sueño de cera recién hecho: el jugador debe averiguar quién más en el valle sabe prepararlo. Lo que hay detrás es de la secta (lore del usuario): no se explica en este caso.",
			"kidnapper_survival_optional": true
		},
		"roles": {
			"victim": {
				"description": "Mujer hallada muerta al alba junto al arroyo del norte",
				"gender": "F",
				"min_age": 18,
				"max_age": 48,
				"exclude_essential": true
			},
			"alchemist": {
				"description": "Alquimista/boticaria que identifica la hierba de embalsamar",
				"trade_role": 5 # HERBALIST / APOTHECARY
			},
			"priest": {
				"description": "Sacerdote del pueblo que confirma que él no usa esa hierba",
				"trade_role": 13 # PRIEST
			},
			"noble_head": {
				"description": "Noble pudiente al que robaron el frasco de poción sin poder denunciarlo",
				"trade_role": 21 # NOBLE
			},
			"noble_maid": {
				"description": "Criada de la casa noble que reconoce el frasco vacío",
				"gender": "F",
				"prefer_family_of": "noble_head",
				"discovery_gap": "Reconoce el frasco y menciona el gabinete de los señores; en el gabinete se ve la cerradura forzada."
			},
			"apparent_culprit_relative": {
				"description": "Familiar o pareja de la víctima que intentó fingir su muerte con una receta antigua de la biblioteca para salvarla",
				"relation_to_victim": "partner_or_family_or_close",
				"min_affinity_to_victim": 40
			},
			"young_kidnapper": {
				"description": "El más joven de los secuestradores, que la estranguló con las dos manos al ver que se movía",
				"min_age": 18,
				"max_age": 26,
				"prefer_tendency": "malice"
			},
			"witness_woodcutter": {
				"description": "El leñador que oyó el carro de madrugada sin farol",
				"prefer_job": "woodcutter"
			},
			"witness_shepherdess": {
				"description": "La pastora que vio al muchacho de capa parda junto al arroyo",
				"gender": "F"
			}
		},
		"chain_steps": [
			{
				"step": 1,
				"id": "corpse_found_in_forest",
				"summary": "Aparece una mujer muerta en el bosque: estrangulada; el cuerpo huele a una hierba rara.",
				"tool_stage": "D1_D3"
			},
			{
				"step": 2,
				"id": "alchemist_identifies_herb",
				"summary": "El alquimista identifica la hierba: se usaba para embalsamar, pero el cura del pueblo no la usa.",
				"role": "alchemist",
				"herb_name": "Belladama gris"
			},
			{
				"step": 3,
				"id": "trace_rare_potion_to_wealthy",
				"summary": "No crece por aquí (huerto privado o caravana) y la poción se degrada muy rápido: fue premeditado y caro, apuntando a gente pudiente.",
				"potion_name": "Sueño de cera"
			},
			{
				"step": 4,
				"id": "investigate_nobles_and_maid",
				"summary": "Los nobles esconden algo pero no fueron ellos (la poción era suya y se la robaron; no pueden decirlo). Una criada reconoce el frasco.",
				"role": "noble_maid",
				"how_theft_is_discovered": "La criada reconoce el frasco y menciona el gabinete de los señores; al registrar el gabinete (con su permiso o a escondidas) se ve la cerradura forzada. Sin marca en el polvo."
			},
			{
				"step": 5,
				"id": "relative_faked_death_plan",
				"summary": "Un familiar o pareja de la víctima quiso salvarla de unos secuestradores en una casa abandonada mezclando la poción con otra de un libro antiguo de la biblioteca para fingir su muerte; la dosis salió mal y solo la paralizó.",
				"role": "apparent_culprit_relative",
				"abandoned_house_location": "Molino viejo abandonado junto al arroyo, río arriba del claro donde aparece el cuerpo. Se llega siguiendo el agua. Allí la orilla es de barro rojo (la misma arcilla de los ladrillos de algunas casas del pueblo)."
			},
			{
				"step": 6,
				"id": "young_kidnapper_strangles_victim",
				"summary": "Los secuestradores la creyeron muerta; al ver que se movía, el más joven la estranguló por miedo a que los delatara.",
				"role": "young_kidnapper"
			},
			{
				"step": 7,
				"id": "interrogation_and_live_capture",
				"summary": "Lo del familiar se descubre hablando con él; lo de los secuestradores, interrogando a uno si se le captura vivo.",
				"requires_live_capture": true
			},
			{
				"step": 8,
				"id": "open_thread_corruption",
				"summary": "Deja abierta la investigación de la secta y la corrupción del pueblo.",
				"followup_hook": "Lista de desaparecidos en el molino + averiguar quién más sabe preparar el sueño de cera."
			}
		],
		"custom_dialogues": {
			"alchemist_analyze_flask": {
				"speaker_role": "alchemist",
				"requires_note": "m_estomago",
				"line": "«Este líquido verdoso lleva una hierba de embalsamar muy cara: belladama gris. Con ella se hace el sueño de cera, y es muy inestable: a las doce horas empieza a perder fuerza y a los dos días no vale nada. Quien la usó la tenía recién hecha. El padre Anselmo jamás la pide.»"
			},
			"noble_maid_recognize_vial": {
				"speaker_role": "noble_maid",
				"requires_note": "bolsillos:registrar",
				"line": "«Ese frasco sin etiqueta… es del gabinete de los señores. Hace un par de días alguien forzó la cerradura y me mandaron callar. No diga que se lo he contado yo.»"
			},
			"relative_confession": {
				"speaker_role": "apparent_culprit_relative",
				"requires_note": "m_sangre",
				"line": "«¡No quería matarla! La tenían retenida y copié una receta de un libro viejo de la biblioteca para que pareciera muerta y la sacaran de allí… pero la dosis solo la dejó inmóvil.»"
			},
			"kidnapper_captured_interrogation": {
				"speaker_role": "young_kidnapper",
				"requires_live_capture": true,
				"optional": true,
				"line": "«¡Nos dijeron que estaba muerta! Cuando abrió los ojos en mitad de la noche perdí la cabeza… la apretamos y la llevamos en el carro hasta el arroyo.»"
			}
		},
		"body_zones": {
			"cabeza": {
				"title": "Cabeza y rostro",
				"acts": [
					{"id": "mirar", "name": "Mirar de cerca", "cost": 2, "find": "No hay golpe en la frente ni sangre en el pelo. Los ojos tienen puntitos rojos en el blanco; los labios están azulados."},
					{"id": "oler", "name": "Oler boca y nariz", "cost": 2, "find": "Un olor suave y amargo, como a almendra machacada o hueso de melocotón, sale todavía de la boca.", "tag": "Olor: almendra amarga", "note": "Aliento: olor amargo a almendra en la boca (¿algo bebido antes de morir?)."},
					{"id": "palpar", "name": "Palpar cráneo", "cost": 3, "find": "Hueso entero, sin hundimientos. No murió de una pedrada ni de un porrazo en la cabeza."},
					{"id": "lupa", "name": "Usar lupa en el pelo", "cost": 4, "requires_lupa": true, "find": "Entre el pelo hay polen amarillo de sauce y dos briznas de paja seca que no crecen junto al arroyo: vienen de un granero o establo."}
				]
			},
			"cuello": {
				"title": "Cuello y garganta",
				"acts": [
					{"id": "mirar", "name": "Mirar la piel", "cost": 2, "find": "Una franja morada cruza la garganta, pero está borrosa, como si la sangre no hubiera corrido hacia el golpe.", "mark": "m-neck", "note": "Cuello: marca morada horizontal en la garganta, extrañamente pálida por dentro."},
					{"id": "palpar", "name": "Palpar garganta", "cost": 3, "find": "Desde fuera se nota el cartílago duro, pero sin abrir en la morgue no puedes saber si el hueso interno está roto."},
					{"id": "lupa", "name": "Usar lupa en el surco", "cost": 5, "requires_lupa": true, "find": "En los bordes del surco no hay pellejos levantados ni sangre coagulada: apretaron cuando el corazón ya latía muy débil o estaba parado.", "tag": "Surco sin sangrado", "note": "Surco del cuello: sin sangrado en los bordes; puede haberse hecho cuando ya se moría por otra causa."},
					{"id": "interna", "name": "Abrir tráquea", "cost": 0, "locked": true, "find": "Hace falta llevar el cuerpo a la morgue para abrir y ver si el hueso del cuello está roto."}
				]
			},
			"torso": {
				"title": "Pecho y vestido",
				"acts": [
					{"id": "mirar", "name": "Mirar la ropa", "cost": 2, "find": "El vestido de lana está húmedo por la espalda, pero seco en el pecho. No hay cortes ni agujeros de cuchillo."},
					{"id": "palpar", "name": "Palpar costillas y espalda", "cost": 4, "find": "Costillas enteras. Al girar un poco el hombro, ves que la sangre acumulada tras morir (lividez) está en el costado derecho, no en la espalda, aunque yace boca arriba.", "tag": "Cuerpo movido tras morir", "note": "Lividez en el costado derecho aunque yace boca arriba: estuvo horas tumbada de lado en otro sitio antes de traerla aquí."},
					{"id": "interna", "name": "Examinar estómago", "cost": 0, "locked": true, "find": "Hace falta abrir el cuerpo en la morgue para ver qué comió o bebió antes de morir."}
				]
			},
			"brazos": {
				"title": "Brazos y muñecas",
				"acts": [
					{"id": "mirar", "name": "Mirar muñecas", "cost": 2, "find": "Dos marcas rojas estrechas rodean las muñecas, como si la hubieran sujetado por detrás o atado con cuerda fina.", "mark": "m-wrist"},
					{"id": "lupa", "name": "Usar lupa en las marcas", "cost": 4, "requires_lupa": true, "find": "Hay pelusa de cáñamo encerado clavada en la piel: el tipo de cordel que usan en el almacén de grano y en las barcas.", "tag": "Fibra: cáñamo encerado", "note": "Muñecas: restos de cordel de cáñamo encerado (usado en almacén de grano o barcas)."}
				]
			},
			"manos": {
				"title": "Manos y uñas",
				"acts": [
					{"id": "mirar", "name": "Abrir los dedos", "cost": 3, "find": "Los dedos están rígidos (entre 6 y 10 horas muerta). No tiene cortes de haberse defendido de un cuchillo."},
					{"id": "lupa", "name": "Mirar bajo las uñas", "cost": 4, "requires_lupa": true, "find": "Bajo dos uñas de la mano derecha hay hebras de lana teñida de azul oscuro, arrancadas de una manga o capote.", "tag": "Fibra: lana azul oscuro", "note": "Bajo las uñas: lana azul oscuro arrancada de la ropa de otra persona."}
				]
			},
			"piernas": {
				"title": "Piernas y calzado",
				"acts": [
					{"id": "mirar", "name": "Mirar pies y bajos", "cost": 2, "find": "Falta el zapato izquierdo. Los dos talones tienen barro rojo por detrás, como si la hubieran arrastrado sujetándola por las axilas. Junto al claro el barro es pardo, no rojo.", "mark": "m-heel", "tag": "Arrastrada hasta aquí", "note": "Talones con barro rojo y falta el zapato izquierdo: la arrastraron desde otro sitio. El barro rojo es la arcilla de los ladrillos… ¿o de río arriba?"},
					{"id": "oler", "name": "Oler el barro del vestido", "cost": 2, "find": "El barro de las rodillas huele a ceniza de carbón vegetal, no al lodo limpio del arroyo.", "tag": "Barro con ceniza de carbón", "note": "Barro en las rodillas mezclado con ceniza de carbón vegetal (¿carbonera, fragua o horno?)."}
				]
			},
			"bolsillos": {
				"title": "Bolsillos del delantal",
				"acts": [
					{"id": "palpar", "name": "Palpar desde fuera", "cost": 2, "find": "En el bolsillo derecho suena vidrio pequeño y un papel doblado."},
					{"id": "registrar", "name": "Vaciar bolsillo (10 min)", "cost": 10, "find": "Sacas un frasco pequeño vacío sin etiqueta (huele igual que su boca, a almendra amarga) y una nota húmeda donde solo se lee «…después del toque de queda en el puente viejo — V.».", "mark": "m-pocket", "tag": "Objeto: frasco vacío + nota «V.»", "note": "Bolsillo: frasco vacío con olor a almendra amarga y nota rota firmada «V.» citándola en el puente viejo tras el toque de queda.", "loot_corpse": true}
				]
			}
		},
		"morgue_tests": {
			"sangre": {
				"name": "Sangre",
				"vials": 2,
				"steps": [
					{
						"q": "¿De dónde sacas la sangre?",
						"hint": "«Del corazón. La del brazo ya se ha posado.»",
						"opts": [
							["Del corazón", "ok", "Sangre oscura y espesa: buena muestra."],
							["Del brazo", "dud", "Apenas sale. Muestra pobre: lo que veas será dudoso."]
						]
					},
					{
						"q": "Elige el reactivo",
						"hint": "«Para hierbas, la corteza. Para metales, la plata. Para la adormidera, el cobre.»",
						"opts": [
							["Sal de plata", "fail", "Nada. No hay metales. Gastas parte de la muestra."],
							["Tintura de corteza", "ok", "La gota se vuelve verde oscuro en segundos."],
							["Vinagre de cobre", "fail", "Nada. No hay adormidera. Gastas parte de la muestra."]
						]
					},
					{
						"q": "¿Qué indica el verde oscuro?",
						"chart": true,
						"hint": "«Verde oscuro… eso no lo uso yo. Es de embalsamadores.»",
						"opts": [
							["Una hierba de embalsamar", "ok", "Restos de una hierba de embalsamar en la sangre. Paraliza."],
							["Veneno de setas", "dud", "Anotas «setas», pero el color no encaja del todo."],
							["Nada raro", "dud", "Lo das por normal. Algo no te cuadra."]
						]
					}
				],
				"cause": "paralizada por una hierba de embalsamar",
				"note_title": "Autopsia · Sangre",
				"note_tag": "Sangre: hierba paralizante"
			},
			"cuello": {
				"name": "Cuello",
				"vials": 0,
				"steps": [
					{
						"q": "¿Cómo abres el cuello?",
						"hint": "«Despacio, por capas. Si cortas deprisa, rompes lo que buscas.»",
						"opts": [
							["Corte lento, por capas", "ok", "Llegas al hueso de la garganta sin tocarlo."],
							["Corte rápido", "ruin", "Rompes el hueso al cortar: ya no dice nada."]
						]
					},
					{
						"q": "Mira el hueso de la garganta",
						"hint": "",
						"opts": [
							["Mirar", "ok", "Roto por los dos lados: la apretaron con las dos manos."]
						]
					}
				],
				"cause": "estrangulada con las manos",
				"note_title": "Autopsia · Cuello",
				"note_tag": "Hioides roto (dos manos)"
			},
			"estomago": {
				"name": "Estómago",
				"vials": 0,
				"steps": [
					{
						"q": "Abre el estómago",
						"hint": "",
						"opts": [
							["Abrir y vaciar en un cuenco", "ok", "Casi vacío. Un poco de líquido espeso, amargo y verdoso."]
						]
					},
					{
						"q": "¿Qué haces con el líquido?",
						"hint": "«Guárdalo. El alquimista sabrá más que yo.»",
						"opts": [
							["Guardarlo en un frasco sellado", "ok", "Frasco sellado. El alquimista podrá analizarlo."],
							["Tirarlo, ya lo has visto", "ruin", "Se pierde. Nadie podrá analizarlo."]
						]
					}
				],
				"cause": "",
				"note_title": "Autopsia · Estómago",
				"note_tag": "Frasco sellado (líquido amargo)"
			},
			"piel": {
				"name": "Piel y rigidez",
				"vials": 0,
				"steps": [
					{
						"q": "Gira el cuerpo y mira la espalda",
						"hint": "",
						"opts": [
							["Girar el cuerpo", "ok", "Manchas moradas en la espalda y otras en el costado: estuvo tumbada en dos sitios. La movieron horas después de morir."]
						]
					},
					{
						"q": "Prueba la rigidez",
						"hint": "",
						"opts": [
							["Doblar codos y rodillas", "ok", "Rigidez desigual: algunos músculos estaban agarrotados antes de morir, como por algo que paraliza."]
						]
					}
				],
				"cause": "movida horas después",
				"note_title": "Autopsia · Piel y rigidez",
				"note_tag": "Lividez doble (movida)"
			}
		},
		"scene_clues": [
			{"x": 300.0, "y": 150.0, "r": 16.0, "draw_kind": "drag", "k": "Hojarasca", "t": "Dos surcos paralelos desde el camino hasta el cuerpo: la trajeron a rastras.", "m": 10},
			{"x": 214.0, "y": 196.0, "r": 14.0, "draw_kind": "prints", "k": "Huellas", "t": "Huellas de botas pequeñas, de una sola persona. Pisada nerviosa, de alguien joven.", "m": 10},
			{"x": 258.0, "y": 60.0, "r": 16.0, "draw_kind": "wheels", "k": "Camino", "t": "Marcas de rueda de carro que paró aquí de madrugada y se dio la vuelta.", "m": 10},
			{"x": 330.0, "y": 300.0, "r": 12.0, "draw_kind": "herb", "k": "Junto al cuerpo", "t": "Una ramita seca de una hierba que no crece aquí. Huele igual que el pelo de la víctima.", "m": 5},
			{"x": 250.0, "y": 400.0, "r": 18.0, "draw_kind": "circle", "k": "Bajo el cuerpo", "t": "Ni una gota de sangre en el suelo. No la mataron de un golpe, y quizá no aquí.", "m": 5},
			{"x": 200.0, "y": 480.0, "r": 14.0, "draw_kind": "mud", "k": "Orilla del arroyo", "t": "Barro removido en la orilla, como si alguien se hubiera lavado las manos con prisa.", "m": 10}
		],
		"scene_witnesses": [
			{
				"name": "El leñador",
				"npc_ref": null,
				"ask_text": "«Oí un carro de madrugada, sin farol. Raro a esas horas.»",
				"press_ok_text": "«Bajaba hacia los almacenes del sur antes de que cantara el gallo.»",
				"press_bad_text": "«¡Ya te he dicho lo que sé! No me líes.»",
				"can_press_succeed": false,
				"log": []
			},
			{
				"name": "La pastora",
				"npc_ref": null,
				"ask_text": "«Yo no vi nada… bueno, a un muchacho en el arroyo. Se fue corriendo.»",
				"press_ok_text": "«Era joven, con una capa parda. Nunca lo había visto por el pueblo.»",
				"press_bad_text": "«No me pregunte más, señor, tengo miedo.»",
				"can_press_succeed": true,
				"log": []
			}
		],
		"board_suspects": [
			{"id": "s_v", "k": "Sospechoso", "t": "«V.» — firmó la nota del bolsillo citándola en el puente viejo."},
			{"id": "s_alch", "k": "Sospechoso", "t": "El boticario — guarda hierbas de embalsamar bajo llave."},
			{"id": "s_miller", "k": "Sospechoso", "t": "El molinero — tiene carro y cordel de cáñamo encerado."},
			{"id": "s_boy", "k": "Sospechoso", "t": "Muchacho de capa parda — visto corriendo junto al arroyo."}
		]
	},
	"case_02": {"id": "case_02", "number": 2, "status": PENDING_DECISION, "title": "Caso II · [PENDIENTE_DECISION_USUARIO]"},
	"case_03": {"id": "case_03", "number": 3, "status": PENDING_DECISION, "title": "Caso III · [PENDIENTE_DECISION_USUARIO]"},
	"case_04": {"id": "case_04", "number": 4, "status": PENDING_DECISION, "title": "Caso IV · [PENDIENTE_DECISION_USUARIO]"},
	"case_05": {"id": "case_05", "number": 5, "status": PENDING_DECISION, "title": "Caso V · [PENDIENTE_DECISION_USUARIO]"},
	"case_06": {"id": "case_06", "number": 6, "status": PENDING_DECISION, "title": "Caso VI · [PENDIENTE_DECISION_USUARIO]"},
	"case_07": {"id": "case_07", "number": 7, "status": PENDING_DECISION, "title": "Caso VII · [PENDIENTE_DECISION_USUARIO]"},
	"case_08": {"id": "case_08", "number": 8, "status": PENDING_DECISION, "title": "Caso VIII · [PENDIENTE_DECISION_USUARIO]"},
	"case_09": {"id": "case_09", "number": 9, "status": PENDING_DECISION, "title": "Caso IX · [PENDIENTE_DECISION_USUARIO]"},
	"case_10": {"id": "case_10", "number": 10, "status": PENDING_DECISION, "title": "Caso X · [PENDIENTE_DECISION_USUARIO]"}
}


static func get_case_ids() -> Array[String]:
	var out: Array[String] = []
	for k in CASES.keys():
		out.append(str(k))
	return out


static func has_case(case_id: String) -> bool:
	return CASES.has(case_id)


static func get_case_def(case_id: String = CASE_01_ID) -> Dictionary:
	var resolved_id: String = case_id if CASES.has(case_id) else CASE_01_ID
	return (CASES[resolved_id] as Dictionary).duplicate(true)


static func get_body_zones(case_id: String, has_lupa: bool) -> Dictionary:
	var cdef := get_case_def(case_id)
	var raw_zones: Dictionary = cdef.get("body_zones", {})
	var zones: Dictionary = {}
	for z_id in raw_zones.keys():
		var z: Dictionary = raw_zones[z_id]
		var z_copy: Dictionary = {"title": str(z.get("title", z_id))}
		var acts_out: Array = []
		var raw_acts: Array = z.get("acts", [])
		for act in raw_acts:
			if act is Dictionary:
				var act_copy: Dictionary = {}
				for ak in (act as Dictionary).keys():
					act_copy[ak] = act[ak]
				if act_copy.get("requires_lupa") == true:
					act_copy["locked"] = not has_lupa
				acts_out.append(act_copy)
		z_copy["acts"] = acts_out
		zones[z_id] = z_copy
	return zones


static func get_morgue_tests(case_id: String = CASE_01_ID) -> Dictionary:
	var cdef := get_case_def(case_id)
	return cdef.get("morgue_tests", {})


static func get_scene_clues(case_id: String = CASE_01_ID) -> Array[Dictionary]:
	var cdef := get_case_def(case_id)
	var raw: Array = cdef.get("scene_clues", [])
	var out: Array[Dictionary] = []
	for item in raw:
		if item is Dictionary:
			out.append(item)
	return out


static func get_scene_witnesses(case_id: String = CASE_01_ID) -> Array[Dictionary]:
	var cdef := get_case_def(case_id)
	var raw: Array = cdef.get("scene_witnesses", [])
	var out: Array[Dictionary] = []
	for item in raw:
		if item is Dictionary:
			out.append(item)
	return out


static func get_board_suspects(case_id: String = CASE_01_ID) -> Array[Dictionary]:
	var cdef := get_case_def(case_id)
	var raw: Array = cdef.get("board_suspects", [])
	var out: Array[Dictionary] = []
	for item in raw:
		if item is Dictionary:
			out.append(item)
	return out


## Reparte los papeles de un caso guionizado entre los vecinos reales vivos del pueblo según los requisitos de cada rol.
static func assign_case_roles(case_id: String, vm: Node) -> Dictionary:
	var cdef := get_case_def(case_id)
	var roles_def: Dictionary = cdef.get("roles", {})
	var assigned: Dictionary = {}
	if vm == null:
		return assigned

	var used_names: Dictionary = {}
	var npcs: Array = []
	if vm.is_inside_tree() and vm.get_tree() != null:
		npcs = vm.get_tree().get_nodes_in_group("village_npcs")
	elif "trade_npcs" in vm and vm.trade_npcs is Dictionary:
		npcs = (vm.trade_npcs as Dictionary).values()

	# 1. Roles de oficio fijo primero (alquimista, sacerdote, noble)
	for role_id in ["alchemist", "priest", "noble_head"]:
		if not roles_def.has(role_id):
			continue
		var r_spec: Dictionary = roles_def[role_id]
		var wanted_trade: int = int(r_spec.get("trade_role", -1))
		for n in npcs:
			if not is_instance_valid(n) or n.get("is_dead") == true:
				continue
			var n_name: String = str(n.get("npc_name"))
			if used_names.has(n_name):
				continue
			if int(n.get("trade_role")) == wanted_trade:
				assigned[role_id] = n_name
				used_names[n_name] = true
				break
		if not assigned.has(role_id) and "trade_npcs" in vm and (vm.trade_npcs as Dictionary).has(wanted_trade):
			var tn = vm.trade_npcs[wanted_trade]
			if is_instance_valid(tn):
				var tn_name: String = str(tn.get("npc_name"))
				assigned[role_id] = tn_name
				used_names[tn_name] = true

	# 2. Resto de papeles según género, edad y afinidad
	for role_id in roles_def.keys():
		if assigned.has(role_id):
			continue
		var r_spec: Dictionary = roles_def[role_id]
		var wanted_gender: String = str(r_spec.get("gender", ""))
		var min_age: int = int(r_spec.get("min_age", 18))
		var max_age: int = int(r_spec.get("max_age", 90))
		var best_name := ""
		var best_score := -9999.0

		for n in npcs:
			if not is_instance_valid(n) or n.get("is_dead") == true:
				continue
			var t_role: int = int(n.get("trade_role"))
			if t_role == 22: # CHILD
				continue
			var n_name: String = str(n.get("npc_name"))
			if used_names.has(n_name):
				continue
			var prof = n.get("person_profile")
			var g_str: String = str(prof.get("gender")) if prof != null else ("F" if n_name.ends_with("a") else "M")
			var age_val: int = int(prof.get("age")) if prof != null else 30
			var score := 0.0
			if wanted_gender != "" and g_str == wanted_gender:
				score += 20.0
			elif wanted_gender != "":
				score -= 15.0
			if age_val >= min_age and age_val <= max_age:
				score += 10.0
			if r_spec.get("exclude_essential") == true and t_role in [11, 12, 13, 14]: # SHERIFF, DOCTOR, PRIEST, GUARD
				score -= 30.0
			if score > best_score:
				best_score = score
				best_name = n_name

		if best_name != "":
			assigned[role_id] = best_name
			used_names[best_name] = true

	return assigned
