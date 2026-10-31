extends PanelContainer
class_name TavernGamesUI

## Salón de Casino y Billar — Posada "El Jabalí Dorado" (Póker Hold'em, Blackjack 21, Ruleta y Billar)
## - Congela automáticamente el reloj del mundo (WorldClock.set_activity_pause) y el hambre/sueño para no romper rutinas.
## - Sienta físicamente a los NPCs rivales alrededor de la mesa de juego en la Taberna mientras dura la partida.
## - Incluye Retratos Visuales de los NPCs con sus skins de oficio, rasgos RimWorld y expresiones en vivo,
##   Cartas Gráficas animadas con Tween y Mesa de Billar 2D con física de bolas y barra de potencia.

enum GameTab { POKER, BLACKJACK, ROULETTE, BILLIARDS }

var player: CharacterBody2D = null
var current_tab: GameTab = GameTab.POKER

# Nodos de UI
var header_gold_lbl: Label = null
var header_freeze_lbl: Label = null
var portraits_box: HBoxContainer = null
var table_title_lbl: Label = null
var visual_cards_area: VBoxContainer = null
var cards_display_lbl: Label = null
var table_state_lbl: Label = null
var actions_box: HBoxContainer = null
var status_msg_lbl: Label = null
var tab_info_lbl: Label = null
var pool_canvas: Control = null

# Opponents at the table
var table_npcs: Array[VillageNPC] = []
var npc_reactions: Array[String] = ["😊 Listo para jugar", "😎 Barajando fichas"]

# --- ESTADO DE PÓKER (Texas Hold'em + Psicología Sutil de Tells/Bluffing) ---
enum PokerStage { IDLE, PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN }
enum PokerArchetype {
	STOIC_ROCK,        # Roca Estoica: apenas farolea, casi inmutable; solo apoya el pulgar en sus fichas con mano fuerte
	CALCULATING_SHARK, # Tahúr Calculador: usa tells inversos (calma estudiada al farolear, ceño dudoso con jugada fuerte)
	IMPULSIVE_AGGRESSOR, # Impulsivo: farolea a menudo; tamborilea los dedos o empuja fichas rápido sin mirar cartas al mentir
	CAUTIOUS_READABLE  # Cauto / Transparente: rara vez farolea; desvía la mirada a su jarra al mentir y revisa 2 veces sus cartas si lleva juego
}
var poker_stage: PokerStage = PokerStage.IDLE
var poker_deck: Array[Dictionary] = []
var poker_community: Array[Dictionary] = []
var poker_player_hand: Array[Dictionary] = []
var poker_npc1_hand: Array[Dictionary] = []
var poker_npc2_hand: Array[Dictionary] = []
var poker_npc1_folded: bool = false
var poker_npc2_folded: bool = false
var poker_npc_bluffing: Array[bool] = [false, false]
var poker_pot: int = 0
var poker_player_invested: int = 0
var portrait_cards: Array[Control] = []

# --- ESTADO DE BLACKJACK (21 — Reglas Reales S17, 3:2, Double Down y Surrender) ---
enum BJStage { IDLE, PLAYER_TURN, FINISHED }
var bj_stage: BJStage = BJStage.IDLE
var bj_deck: Array[Dictionary] = []
var bj_player_hand: Array[Dictionary] = []
var bj_dealer_hand: Array[Dictionary] = []
var bj_bet: int = 5

# --- ESTADO DE RULETA EUROPEA REAL (37 Casillas: 0 al 36, Ventaja Banca 2.70%) ---
enum RouletteMode { SUERTES_SENCILLAS, DOCENAS_Y_COLUMNAS, APUESTAS_INTERNAS }
var roulette_mode: RouletteMode = RouletteMode.SUERTES_SENCILLAS
var roulette_chip_values: Array[int] = [5, 10, 25]
var roulette_chip_idx: int = 0
var roulette_chosen_num: int = 17
var roulette_spinning: bool = false
var roulette_spin_timer: float = 0.0
var roulette_current_ball: int = 0
var roulette_bet_type: String = ""
var roulette_bet_amt: int = 5

# --- ESTADO DE BILLAR DE TABERNA (8-BALL POOL) ---
var pool_aim_angle: float = 0.0
var pool_power_phase: float = 0.0
var pool_power: float = 0.72
var pool_balls_moving: bool = false
var pool_cue_pos: Vector2 = Vector2(95, 68)
var pool_cue_vel: Vector2 = Vector2.ZERO
var pool_targets: Array[Dictionary] = []
var pool_score_this_rack: int = 0
const POOL_TABLE_SIZE := Vector2(380, 136)

const SUITS: Array[String] = ["♠", "♥", "♦", "♣"]
const RANKS: Array[String] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
# Los 18 números Rojos oficiales de una Ruleta Europea de 37 casillas (0..36):
const RED_NUMBERS: Array[int] = [
	1, 3, 5, 7, 9, 12, 14, 16, 18,
	19, 21, 23, 25, 27, 30, 32, 34, 36
]
# Orden físico real del cilindro europeo de un solo cero (37 casillas):
const EUROPEAN_WHEEL_ORDER: Array[int] = [
	0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10,
	5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26
]

func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -435.0
	offset_top = -255.0
	offset_right = 435.0
	offset_bottom = 255.0
	z_index = 90

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.12, 0.09, 0.98)
	style.border_color = Color(0.84, 0.68, 0.32, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)

	_reset_pool_rack()
	_build_ui()

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 6)
	add_child(root_vbox)

	# 1. Cabecera con Reloj Congelado y Oro
	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "🎲 Salón de Casino y Billar — Posada 'El Jabalí Dorado'"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	header.add_child(title)

	header_freeze_lbl = Label.new()
	header_freeze_lbl.text = "❄️ Tiempo Pausado (Rutinas Protegidas)   "
	header_freeze_lbl.add_theme_font_size_override("font_size", 12)
	header_freeze_lbl.add_theme_color_override("font_color", Color(0.58, 0.90, 1.0))
	header.add_child(header_freeze_lbl)

	header_gold_lbl = Label.new()
	header_gold_lbl.text = "💰 25 Oro"
	header_gold_lbl.add_theme_font_size_override("font_size", 15)
	header_gold_lbl.add_theme_color_override("font_color", Color.GOLD)
	header.add_child(header_gold_lbl)

	# 2. Selector de Juego ([F1] Póker, [F2] Blackjack, [F3] Ruleta, [F4] Billar)
	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_hbox.add_theme_constant_override("separation", 8)
	root_vbox.add_child(tabs_hbox)

	var btn_poker := Button.new()
	btn_poker.text = "♠️ [F1] Póker Hold'em"
	btn_poker.pressed.connect(func(): _switch_tab(GameTab.POKER))
	tabs_hbox.add_child(btn_poker)

	var btn_bj := Button.new()
	btn_bj.text = "🃏 [F2] Blackjack 21"
	btn_bj.pressed.connect(func(): _switch_tab(GameTab.BLACKJACK))
	tabs_hbox.add_child(btn_bj)

	var btn_roul := Button.new()
	btn_roul.text = "🎡 [F3] Ruleta"
	btn_roul.pressed.connect(func(): _switch_tab(GameTab.ROULETTE))
	tabs_hbox.add_child(btn_roul)

	var btn_pool := Button.new()
	btn_pool.text = "🎱 [F4] Billar de Posada"
	btn_pool.pressed.connect(func(): _switch_tab(GameTab.BILLIARDS))
	tabs_hbox.add_child(btn_pool)

	var btn_exit := Button.new()
	btn_exit.text = "✖ [ESC] Levantarse"
	btn_exit.pressed.connect(func(): close_games())
	tabs_hbox.add_child(btn_exit)

	# 3. Fila de Retratos Visuales de Personajes (Fotos + Rasgos + Expresión)
	portraits_box = HBoxContainer.new()
	portraits_box.alignment = BoxContainer.ALIGNMENT_CENTER
	portraits_box.add_theme_constant_override("separation", 12)
	root_vbox.add_child(portraits_box)

	# 4. Área Central del Tapete Verde
	var felt_panel := PanelContainer.new()
	felt_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var felt_style := StyleBoxFlat.new()
	felt_style.bg_color = Color(0.05, 0.23, 0.14, 0.96)
	felt_style.border_color = Color(0.38, 0.62, 0.42, 0.85)
	felt_style.set_border_width_all(2)
	felt_style.set_corner_radius_all(8)
	felt_style.content_margin_left = 14
	felt_style.content_margin_right = 14
	felt_style.content_margin_top = 8
	felt_style.content_margin_bottom = 8
	felt_panel.add_theme_stylebox_override("panel", felt_style)
	root_vbox.add_child(felt_panel)

	var felt_vbox := VBoxContainer.new()
	felt_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	felt_vbox.add_theme_constant_override("separation", 6)
	felt_panel.add_child(felt_vbox)

	table_title_lbl = Label.new()
	table_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_title_lbl.add_theme_font_size_override("font_size", 14)
	table_title_lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.68))
	felt_vbox.add_child(table_title_lbl)

	visual_cards_area = VBoxContainer.new()
	visual_cards_area.alignment = BoxContainer.ALIGNMENT_CENTER
	visual_cards_area.add_theme_constant_override("separation", 6)
	felt_vbox.add_child(visual_cards_area)

	pool_canvas = Control.new()
	pool_canvas.custom_minimum_size = POOL_TABLE_SIZE
	pool_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pool_canvas.visible = false
	pool_canvas.draw.connect(_draw_pool_table)
	felt_vbox.add_child(pool_canvas)

	cards_display_lbl = Label.new()
	cards_display_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cards_display_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cards_display_lbl.add_theme_font_size_override("font_size", 13)
	cards_display_lbl.add_theme_color_override("font_color", Color.WHITE)
	cards_display_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	cards_display_lbl.add_theme_constant_override("outline_size", 3)
	felt_vbox.add_child(cards_display_lbl)

	table_state_lbl = Label.new()
	table_state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_state_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	table_state_lbl.add_theme_font_size_override("font_size", 11)
	table_state_lbl.add_theme_color_override("font_color", Color(0.80, 0.95, 0.85))
	felt_vbox.add_child(table_state_lbl)

	status_msg_lbl = Label.new()
	status_msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_msg_lbl.add_theme_font_size_override("font_size", 13)
	status_msg_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
	root_vbox.add_child(status_msg_lbl)

	# 5. Botonera de Acciones ([1]-[8])
	actions_box = HBoxContainer.new()
	actions_box.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_box.add_theme_constant_override("separation", 8)
	root_vbox.add_child(actions_box)

	tab_info_lbl = Label.new()
	tab_info_lbl.text = "⌨️ Controles: [1]-[7] Acciones | [F1] Póker [F2] Blackjack [F3] Ruleta [F4] Billar | [A/D] Apuntar Billar | [ESC] Salir"
	tab_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_info_lbl.add_theme_font_size_override("font_size", 10)
	tab_info_lbl.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72))
	root_vbox.add_child(tab_info_lbl)

func open_games(initial_tab: int = 0) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if WorldClock and WorldClock.has_method("set_activity_pause"):
		WorldClock.set_activity_pause(true)
	_select_and_seat_table_npcs()
	visible = true
	_switch_tab(clampi(initial_tab, 0, 3) as GameTab)

func close_games() -> void:
	if not visible:
		return
	# Si el jugador cierra el salón con ESC mientras había una mano/giro en curso, reembolsar su apuesta activa
	if poker_stage in [PokerStage.PRE_FLOP, PokerStage.FLOP, PokerStage.TURN, PokerStage.RIVER] and poker_player_invested > 0:
		_add_player_gold(poker_player_invested)
		poker_stage = PokerStage.IDLE
		poker_pot = 0
		poker_player_invested = 0
	if bj_stage == BJStage.PLAYER_TURN and bj_bet > 0:
		_add_player_gold(bj_bet)
		bj_stage = BJStage.IDLE
	if roulette_spinning and roulette_bet_amt > 0:
		_add_player_gold(roulette_bet_amt)
	roulette_spinning = false
	pool_balls_moving = false
	_unseat_table_npcs()
	if WorldClock and WorldClock.has_method("set_activity_pause"):
		WorldClock.set_activity_pause(false)
	visible = false

func _select_and_seat_table_npcs() -> void:
	_unseat_table_npcs()
	table_npcs.clear()
	var candidates: Array[VillageNPC] = []
	for node in get_tree().get_nodes_in_group("village_npcs"):
		if node is VillageNPC:
			var npc: VillageNPC = node as VillageNPC
			if not npc.is_dead and not npc.is_downed and not npc.is_hostile and not npc.is_stunned_flag and npc.sedated_timer <= 0.0 and npc._carrying_corpse_target == null and npc._reporting_corpse_target == null and npc._being_interviewed_timer <= 0.0 and not (npc.trade_role in [VillageNPC.TradeRole.INNKEEPER, VillageNPC.TradeRole.TRAVELING_MERCHANT, VillageNPC.TradeRole.ROYAL_INVESTIGATOR]):
				if not npc._is_mandatory_work_hours():
					candidates.push_front(npc)
				else:
					candidates.push_back(npc)

	var vm := get_tree().get_first_node_in_group("village_manager")
	var chairs: Array[Vector2] = [Vector2(441, -172), Vector2(489, -172)]
	if vm and vm.has_method("get_poker_chair_positions"):
		chairs = vm.call("get_poker_chair_positions")

	for i in range(mini(2, candidates.size())):
		var chosen_npc: VillageNPC = candidates[i]
		table_npcs.append(chosen_npc)
		var seat_pos: Vector2 = chairs[i] if i < chairs.size() else Vector2(465, -188)
		chosen_npc.set_poker_seating(true, seat_pos)
	npc_reactions = ["😊 Sentado a la mesa", "😎 Listo para apostar"]

func _unseat_table_npcs() -> void:
	for npc in table_npcs:
		if is_instance_valid(npc):
			npc.set_poker_seating(false)

func _get_npc_name(idx: int) -> String:
	if idx < table_npcs.size() and is_instance_valid(table_npcs[idx]):
		return "%s (%s)" % [table_npcs[idx].npc_name, table_npcs[idx].npc_role]
	return "Aldric (Viajero)" if idx == 0 else "Sora (Forastera)"

func _refresh_portraits_bar() -> void:
	if not portraits_box:
		return
	for c in portraits_box.get_children():
		c.queue_free()
	portrait_cards.clear()

	for i in range(2):
		var npc: VillageNPC = table_npcs[i] if i < table_npcs.size() and is_instance_valid(table_npcs[i]) else null
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var c_style := StyleBoxFlat.new()
		c_style.bg_color = Color(0.10, 0.16, 0.14, 0.95)
		c_style.border_color = Color(0.55, 0.72, 0.52, 0.85)
		c_style.set_border_width_all(1)
		c_style.set_corner_radius_all(6)
		c_style.content_margin_left = 8
		c_style.content_margin_right = 8
		c_style.content_margin_top = 4
		c_style.content_margin_bottom = 4
		card.add_theme_stylebox_override("panel", c_style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		card.add_child(hbox)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(54, 54)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if npc and npc.has_method("get_portrait_texture"):
			portrait.texture = npc.get_portrait_texture()
		elif npc and npc.sprite and npc.sprite.texture:
			portrait.texture = npc.sprite.texture
		hbox.add_child(portrait)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)

		var name_lbl := Label.new()
		var traits_txt: String = ", ".join(npc.traits) if (npc and not npc.traits.is_empty()) else "Tahúr"
		name_lbl.text = "%s  [%s]" % [_get_npc_name(i), traits_txt]
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72))
		vbox.add_child(name_lbl)

		var react_lbl := Label.new()
		var mood_val: int = int(round(npc.mood)) if npc else 85
		var react_str: String = npc_reactions[i] if i < npc_reactions.size() else "😊 Atento"
		react_lbl.text = "%s  |  Humor: %d%%" % [react_str, mood_val]
		react_lbl.add_theme_font_size_override("font_size", 10)
		react_lbl.add_theme_color_override("font_color", Color(0.72, 0.95, 0.82))
		vbox.add_child(react_lbl)

		portraits_box.add_child(card)
		portrait_cards.append(card)

func _reward_social_with_table_npcs(affinity_bonus: int = 2, thought_text: String = "Partida divertida en el casino (+8)") -> void:
	for npc in table_npcs:
		if is_instance_valid(npc) and not npc.is_dead:
			npc.need_social = minf(100.0, npc.need_social + 14.0)
			if affinity_bonus != 0:
				npc.affinity = clampi(npc.affinity + affinity_bonus, -100, 100)
			npc.add_thought(thought_text, 8.0)

func _get_player_gold() -> int:
	if player and "inventory" in player and player.inventory:
		return int(player.inventory.gold)
	return 0

func _add_player_gold(delta_gold: int) -> void:
	if player and "inventory" in player and player.inventory:
		player.inventory.add_gold(delta_gold)
	_refresh_header()

func _refresh_header() -> void:
	if header_gold_lbl:
		header_gold_lbl.text = "💰 %d Oro" % _get_player_gold()
	_refresh_portraits_bar()

func _clear_visual_cards() -> void:
	if not visual_cards_area:
		return
	for c in visual_cards_area.get_children():
		c.queue_free()

func _create_card_row(row_title: String, cards: Array[Dictionary], hide_all: bool = false, hide_second: bool = false, placeholder_count: int = 0) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)

	var t_lbl := Label.new()
	t_lbl.text = row_title + "  "
	t_lbl.custom_minimum_size = Vector2(145, 24)
	t_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_size_override("font_size", 12)
	t_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.85))
	row.add_child(t_lbl)

	var total_slots: int = maxi(cards.size(), placeholder_count)
	for i in range(total_slots):
		var card_panel := PanelContainer.new()
		card_panel.custom_minimum_size = Vector2(44, 60)
		var c_style := StyleBoxFlat.new()
		c_style.set_corner_radius_all(5)
		c_style.set_border_width_all(2)

		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL

		if i >= cards.size():
			c_style.bg_color = Color(0.08, 0.28, 0.17, 0.65)
			c_style.border_color = Color(0.32, 0.55, 0.38, 0.65)
			lbl.text = "·"
			lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.60))
		elif hide_all or (hide_second and i == 1):
			c_style.bg_color = Color(0.52, 0.14, 0.18, 0.98)
			c_style.border_color = Color(0.92, 0.76, 0.38, 1.0)
			lbl.text = "🂠"
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.52))
		else:
			var c_data: Dictionary = cards[i]
			var suit_str: String = str(c_data.get("suit", "♠"))
			var rank_str: String = str(c_data.get("rank", "A"))
			var is_red: bool = (suit_str == "♥" or suit_str == "♦")
			c_style.bg_color = Color(0.97, 0.96, 0.92, 1.0)
			c_style.border_color = Color(0.82, 0.22, 0.22, 1.0) if is_red else Color(0.20, 0.22, 0.28, 1.0)
			lbl.text = "%s\n%s" % [rank_str, suit_str]
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", Color(0.84, 0.14, 0.16) if is_red else Color(0.12, 0.14, 0.18))

		card_panel.add_theme_stylebox_override("panel", c_style)
		card_panel.add_child(lbl)
		row.add_child(card_panel)

		# Animación suave de reparto de carta
		card_panel.scale = Vector2(0.82, 0.82)
		var tw := create_tween()
		tw.tween_property(card_panel, "scale", Vector2.ONE, 0.12)

	return row

func _switch_tab(new_tab: GameTab) -> void:
	if roulette_spinning:
		return
	# Si el jugador pulsa la tecla de la pestaña que ya está abierta mientras hay una mano activa, no reiniciar la mano
	if current_tab == new_tab:
		if current_tab == GameTab.POKER and poker_stage in [PokerStage.PRE_FLOP, PokerStage.FLOP, PokerStage.TURN, PokerStage.RIVER]:
			return
		if current_tab == GameTab.BLACKJACK and bj_stage == BJStage.PLAYER_TURN:
			return
	if current_tab != new_tab:
		if poker_stage != PokerStage.IDLE and poker_stage != PokerStage.SHOWDOWN and poker_player_invested > 0:
			_add_player_gold(poker_player_invested)
			poker_stage = PokerStage.IDLE
			poker_pot = 0
			poker_player_invested = 0
		if bj_stage == BJStage.PLAYER_TURN and bj_bet > 0:
			_add_player_gold(bj_bet)
			bj_stage = BJStage.IDLE
			bj_bet = 0
	current_tab = new_tab
	_refresh_header()
	if pool_canvas:
		pool_canvas.visible = (current_tab == GameTab.BILLIARDS)
	if visual_cards_area:
		visual_cards_area.visible = (current_tab == GameTab.POKER or current_tab == GameTab.BLACKJACK)
	if cards_display_lbl:
		cards_display_lbl.visible = (current_tab == GameTab.ROULETTE)

	match current_tab:
		GameTab.POKER:
			poker_stage = PokerStage.IDLE
			status_msg_lbl.text = "♠️ Póker Texas Hold'em (Baraja de 52 cartas). Observa los hábitos de cada aldeano."
			_render_poker_ui()
		GameTab.BLACKJACK:
			bj_stage = BJStage.IDLE
			status_msg_lbl.text = "🃏 Blackjack 21 (Reglas Reales: BJ Natural paga 3:2, Banca se planta en 17, Doblar y Rendirse)."
			_render_blackjack_ui()
		GameTab.ROULETTE:
			roulette_spinning = false
			status_msg_lbl.text = "🎡 Ruleta Europea Real (37 casillas: 0 al 36, ventaja de la casa 2.70%). Elige tu apuesta."
			_render_roulette_ui()
		GameTab.BILLIARDS:
			status_msg_lbl.text = "🎱 Billar de Posada: Apunta con [1]/[2] (o A/D) y golpea con [3] (o Espacio) cuando la barra de potencia esté alta."
			_render_billiards_ui()

func _process(delta: float) -> void:
	if not visible:
		return
	if roulette_spinning:
		roulette_spin_timer -= delta
		var wheel_idx: int = int(floor((1.25 - maxf(0.0, roulette_spin_timer)) * 28.0)) % EUROPEAN_WHEEL_ORDER.size()
		roulette_current_ball = EUROPEAN_WHEEL_ORDER[wheel_idx]
		cards_display_lbl.text = "🎡 Bola rodando por el cilindro europeo (0–36)...  [  %s  ]" % _format_roulette_number(roulette_current_ball)
		if roulette_spin_timer <= 0.0:
			roulette_spinning = false
			_finish_roulette_spin()

	if current_tab == GameTab.BILLIARDS:
		_update_billiards(delta)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_games()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F1:
			_switch_tab(GameTab.POKER)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F2:
			_switch_tab(GameTab.BLACKJACK)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F3:
			_switch_tab(GameTab.ROULETTE)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F4:
			_switch_tab(GameTab.BILLIARDS)
			get_viewport().set_input_as_handled()
			return

		if current_tab == GameTab.BILLIARDS:
			if event.keycode == KEY_A or event.keycode == KEY_LEFT:
				pool_aim_angle -= deg_to_rad(10.0)
				if pool_canvas:
					pool_canvas.queue_redraw()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
				pool_aim_angle += deg_to_rad(10.0)
				if pool_canvas:
					pool_canvas.queue_redraw()
				get_viewport().set_input_as_handled()
				return

		if current_tab == GameTab.ROULETTE and not roulette_spinning:
			if event.physical_keycode == KEY_Q:
				roulette_chip_idx = (roulette_chip_idx + 1) % roulette_chip_values.size()
				_render_roulette_ui()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_TAB:
				roulette_mode = ((int(roulette_mode) + 1) % 3) as RouletteMode
				_render_roulette_ui()
				get_viewport().set_input_as_handled()
				return
			elif event.physical_keycode == KEY_Z or event.keycode == KEY_LEFT:
				roulette_chosen_num = (roulette_chosen_num + 36) % 37
				_render_roulette_ui()
				get_viewport().set_input_as_handled()
				return
			elif event.physical_keycode == KEY_X or event.keycode == KEY_RIGHT:
				roulette_chosen_num = (roulette_chosen_num + 1) % 37
				_render_roulette_ui()
				get_viewport().set_input_as_handled()
				return

		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx: int = int(event.keycode - KEY_1)
			_trigger_action_button(idx)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			var default_btn_idx: int = 2 if current_tab == GameTab.BILLIARDS else 0
			_trigger_action_button(default_btn_idx)
			get_viewport().set_input_as_handled()

func _trigger_action_button(idx: int) -> void:
	if not actions_box or idx < 0 or idx >= actions_box.get_child_count():
		return
	var btn := actions_box.get_child(idx) as Button
	if btn and not btn.disabled:
		btn.pressed.emit()

func _clear_actions() -> void:
	if not actions_box:
		return
	for c in actions_box.get_children():
		c.queue_free()

func _add_action_btn(label_txt: String, callback: Callable, disabled: bool = false) -> void:
	var btn := Button.new()
	btn.text = label_txt
	btn.disabled = disabled
	btn.pressed.connect(callback)
	actions_box.add_child(btn)

func _build_shuffled_deck() -> Array[Dictionary]:
	var d: Array[Dictionary] = []
	for s_idx in range(SUITS.size()):
		for r_idx in range(RANKS.size()):
			d.append({
				"rank": RANKS[r_idx],
				"suit": SUITS[s_idx],
				"val": r_idx + 2
			})
	d.shuffle()
	return d

# ==============================================================================
# 1. PÓKER TEXAS HOLD'EM CON EVAL. 5 DE 7 CARTAS Y TELLS SUTILES DE PERSONALIDAD
# ==============================================================================
func get_npc_poker_archetype(npc_idx: int) -> PokerArchetype:
	var npc: VillageNPC = table_npcs[npc_idx] if (npc_idx >= 0 and npc_idx < table_npcs.size() and is_instance_valid(table_npcs[npc_idx])) else null
	if npc:
		for trait_name in npc.traits:
			var t_low: String = str(trait_name).to_lower()
			if t_low.find("estóico") != -1 or t_low.find("estoico") != -1 or t_low.find("sereno") != -1 or t_low.find("frío") != -1:
				return PokerArchetype.STOIC_ROCK
			if t_low.find("astuto") != -1 or t_low.find("codicioso") != -1 or t_low.find("calculador") != -1 or t_low.find("taimado") != -1:
				return PokerArchetype.CALCULATING_SHARK
			if t_low.find("impulsivo") != -1 or t_low.find("colérico") != -1 or t_low.find("valiente") != -1 or t_low.find("temerario") != -1:
				return PokerArchetype.IMPULSIVE_AGGRESSOR
			if t_low.find("amable") != -1 or t_low.find("trabajador") != -1 or t_low.find("glotón") != -1 or t_low.find("honesto") != -1:
				return PokerArchetype.CAUTIOUS_READABLE
		var h: int = abs(npc.npc_name.hash()) % 4
		return h as PokerArchetype
	return (PokerArchetype.STOIC_ROCK if npc_idx == 0 else PokerArchetype.CALCULATING_SHARK)

func _generate_subtle_poker_tell(npc_idx: int, is_bluffing: bool, hand_category: int, action_label: String) -> String:
	var arch: PokerArchetype = get_npc_poker_archetype(npc_idx)
	var strong_hand: bool = (hand_category >= 2)
	var habit: String = ""

	match arch:
		PokerArchetype.STOIC_ROCK:
			# Casi inmutable: mantiene la misma expresión incluso mintiendo; solo apoya el pulgar en sus fichas con gran juego
			if strong_hand and not is_bluffing:
				habit = "apoya el pulgar en silencio sobre su pila de fichas"
			elif is_bluffing:
				habit = "mantiene la mirada fija en el centro del tapete sin parpadear"
			else:
				habit = "respira con calma sin mover un músculo"
		PokerArchetype.CALCULATING_SHARK:
			# Tell inverso: aparenta serenidad relajada cuando farolea y finge duda cuando lleva una mano monstruosa
			if is_bluffing:
				habit = "sonríe levemente mientras alinea sus fichas con parsimonia"
			elif strong_hand:
				habit = "frunce el ceño un instante como si dudara de sus cartas"
			else:
				habit = "inclina la cabeza midiendo tu pila de oro"
		PokerArchetype.IMPULSIVE_AGGRESSOR:
			# Impaciente: cuando miente, actúa demasiado rápido sin mirar sus cartas o tamborilea los dedos
			if is_bluffing:
				habit = "empuja las fichas de golpe sin volver a mirar sus cartas"
			elif strong_hand:
				habit = "inclina los hombros hacia el bote guardando silencio"
			else:
				habit = "tamborilea dos veces con el índice sobre la madera"
		PokerArchetype.CAUTIOUS_READABLE:
			# Transparente: evita el contacto visual o toca su jarra al farolear; comprueba dos veces sus cartas si lleva juego
			if is_bluffing:
				habit = "desvía la mirada un segundo hacia su jarra antes de hablar"
			elif strong_hand:
				habit = "vuelve a levantar la esquina de sus cartas para asegurarse"
			else:
				habit = "acomoda sus cartas despacio junto al borde"

	_play_subtle_portrait_tell_tween(npc_idx, is_bluffing, arch)
	return "%s · %s" % [action_label, habit]

func _play_subtle_portrait_tell_tween(npc_idx: int, is_bluffing: bool, arch: PokerArchetype) -> void:
	if npc_idx < 0 or npc_idx >= portrait_cards.size():
		return
	var card_ctrl: Control = portrait_cards[npc_idx]
	if not is_instance_valid(card_ctrl):
		return
	var tw := create_tween()
	if arch == PokerArchetype.STOIC_ROCK:
		# Casi imperceptible
		tw.tween_property(card_ctrl, "modulate", Color(0.98, 0.99, 1.0, 1.0), 0.14)
		tw.tween_property(card_ctrl, "modulate", Color.WHITE, 0.14)
	elif arch == PokerArchetype.IMPULSIVE_AGGRESSOR and is_bluffing:
		tw.tween_property(card_ctrl, "scale", Vector2(1.03, 0.98), 0.08)
		tw.tween_property(card_ctrl, "scale", Vector2.ONE, 0.10)
	elif arch == PokerArchetype.CAUTIOUS_READABLE and is_bluffing:
		tw.tween_property(card_ctrl, "modulate", Color(0.94, 0.94, 0.90, 1.0), 0.12)
		tw.tween_property(card_ctrl, "modulate", Color.WHITE, 0.16)
	else:
		tw.tween_property(card_ctrl, "scale", Vector2(1.015, 1.015), 0.11)
		tw.tween_property(card_ctrl, "scale", Vector2.ONE, 0.12)

func _render_poker_ui() -> void:
	_refresh_header()
	_clear_actions()
	_clear_visual_cards()
	table_title_lbl.text = "♠️ Póker Texas Hold'em  |  Bote en la Mesa: 💰 %d Oro" % poker_pot

	if poker_stage == PokerStage.IDLE:
		visual_cards_area.add_child(_create_card_row("Mesa Comunitaria:", [], false, false, 5))
		visual_cards_area.add_child(_create_card_row("Tu Mano:", [], false, false, 2))
		table_state_lbl.text = "Tus rivales están sentados en la mesa de la posada. Cada aldeano reacciona según su personalidad."
		_add_action_btn("[1] Repartir Nueva Mano (Ante: 5 Oro)", _start_poker_hand, _get_player_gold() < 5)
		return

	var show_npcs := (poker_stage == PokerStage.SHOWDOWN)
	visual_cards_area.add_child(_create_card_row("Mesa Comunitaria:", poker_community, false, false, 5))
	visual_cards_area.add_child(_create_card_row("Tu Mano:", poker_player_hand, false, false, 2))

	if show_npcs:
		var opp_cards: Array[Dictionary] = []
		if not poker_npc1_folded:
			opp_cards.append_array(poker_npc1_hand)
		if not poker_npc2_folded:
			opp_cards.append_array(poker_npc2_hand)
		visual_cards_area.add_child(_create_card_row("Cartas Rivales:", opp_cards, false, false, opp_cards.size()))

	table_state_lbl.text = "👤 %s: %s\n👤 %s: %s" % [
		_get_npc_name(0),
		"🏳️ Retirado" if poker_npc1_folded else npc_reactions[0],
		_get_npc_name(1),
		"🏳️ Retirado" if poker_npc2_folded else npc_reactions[1]
	]

	if poker_stage == PokerStage.SHOWDOWN:
		_add_action_btn("[1] Jugar Otra Mano (Ante: 5 Oro)", _start_poker_hand, _get_player_gold() < 5)
	else:
		_add_action_btn("[1] Pasar / Igualar (0 Oro)", func(): _poker_player_bet(0))
		_add_action_btn("[2] Subir Apuesta (+5 Oro)", func(): _poker_player_bet(5), _get_player_gold() < 5)
		_add_action_btn("[3] Subir Fuerte (+10 Oro)", func(): _poker_player_bet(10), _get_player_gold() < 10)
		_add_action_btn("[4] Retirarse (Fold)", _poker_player_fold)

func _start_poker_hand() -> void:
	if _get_player_gold() < 5:
		status_msg_lbl.text = "⚠️ Necesitas al menos 5 Oro para entrar a la mano."
		return
	_add_player_gold(-5)
	poker_pot = 15
	poker_player_invested = 5
	poker_deck = _build_shuffled_deck()
	poker_community.clear()
	poker_player_hand = [poker_deck.pop_back(), poker_deck.pop_back()]
	poker_npc1_hand = [poker_deck.pop_back(), poker_deck.pop_back()]
	poker_npc2_hand = [poker_deck.pop_back(), poker_deck.pop_back()]
	poker_npc1_folded = false
	poker_npc2_folded = false
	poker_npc_bluffing = [false, false]

	var eval1: Dictionary = _evaluate_cards_strength(poker_npc1_hand)
	var eval2: Dictionary = _evaluate_cards_strength(poker_npc2_hand)
	npc_reactions = [
		_generate_subtle_poker_tell(0, false, int(eval1["category"]), "Entra al bote (5 Oro)"),
		_generate_subtle_poker_tell(1, false, int(eval2["category"]), "Entra al bote (5 Oro)")
	]
	poker_stage = PokerStage.PRE_FLOP
	status_msg_lbl.text = "Ronda Pre-Flop: Cartas repartidas. Bote inicial: 15 Oro."
	_render_poker_ui()

func _poker_player_bet(raise_amt: int) -> void:
	if raise_amt > 0:
		if _get_player_gold() < raise_amt:
			return
		_add_player_gold(-raise_amt)
		poker_pot += raise_amt
		poker_player_invested += raise_amt

		if not poker_npc1_folded:
			var dec1: Dictionary = _decide_npc_poker_action(0, poker_npc1_hand, poker_community, raise_amt)
			if bool(dec1["call"]):
				poker_pot += raise_amt
				poker_npc_bluffing[0] = bool(dec1["bluffing"])
				npc_reactions[0] = _generate_subtle_poker_tell(0, poker_npc_bluffing[0], int(dec1["category"]), "Iguala +%d Oro" % raise_amt)
			else:
				poker_npc1_folded = true
				npc_reactions[0] = "🏳️ Deja sus cartas boca abajo (Fold)"
		if not poker_npc2_folded:
			var dec2: Dictionary = _decide_npc_poker_action(1, poker_npc2_hand, poker_community, raise_amt)
			if bool(dec2["call"]):
				poker_pot += raise_amt
				poker_npc_bluffing[1] = bool(dec2["bluffing"])
				npc_reactions[1] = _generate_subtle_poker_tell(1, poker_npc_bluffing[1], int(dec2["category"]), "Ve tus +%d Oro" % raise_amt)
			else:
				poker_npc2_folded = true
				npc_reactions[1] = "🏳️ Se retira de la mano (Fold)"
	else:
		if not poker_npc1_folded:
			var d1: Dictionary = _decide_npc_poker_action(0, poker_npc1_hand, poker_community, 0)
			poker_npc_bluffing[0] = bool(d1["bluffing"])
			npc_reactions[0] = _generate_subtle_poker_tell(0, poker_npc_bluffing[0], int(d1["category"]), "Pasa (Check)")
		if not poker_npc2_folded:
			var d2: Dictionary = _decide_npc_poker_action(1, poker_npc2_hand, poker_community, 0)
			poker_npc_bluffing[1] = bool(d2["bluffing"])
			npc_reactions[1] = _generate_subtle_poker_tell(1, poker_npc_bluffing[1], int(d2["category"]), "Pasa (Check)")

	if poker_npc1_folded and poker_npc2_folded:
		_add_player_gold(poker_pot)
		poker_player_invested = 0
		status_msg_lbl.text = "🏆 ¡Ambos rivales se retiraron! Te llevas el bote de %d Oro." % poker_pot
		poker_stage = PokerStage.SHOWDOWN
		_reward_social_with_table_npcs(2, "Jugó una mano emocionante de Póker (+8)")
		_render_poker_ui()
		return

	match poker_stage:
		PokerStage.PRE_FLOP:
			poker_community.append(poker_deck.pop_back())
			poker_community.append(poker_deck.pop_back())
			poker_community.append(poker_deck.pop_back())
			poker_stage = PokerStage.FLOP
			status_msg_lbl.text = "Flop (3 cartas comunitarias en mesa). ¿Pasas o subes la apuesta?"
		PokerStage.FLOP:
			poker_community.append(poker_deck.pop_back())
			poker_stage = PokerStage.TURN
			status_msg_lbl.text = "Turn (4.ª carta en mesa). Bote actual: %d Oro." % poker_pot
		PokerStage.TURN:
			poker_community.append(poker_deck.pop_back())
			poker_stage = PokerStage.RIVER
			status_msg_lbl.text = "River (5.ª y última carta en mesa). Última ronda de apuestas."
		PokerStage.RIVER:
			poker_stage = PokerStage.SHOWDOWN
			poker_player_invested = 0
			_resolve_poker_showdown()
	_render_poker_ui()

func _poker_player_fold() -> void:
	poker_stage = PokerStage.SHOWDOWN
	poker_player_invested = 0
	var winner_npc := _get_npc_name(0) if not poker_npc1_folded else _get_npc_name(1)
	status_msg_lbl.text = "🏳️ Te retiraste de la mano. %s se lleva el bote de %d Oro." % [winner_npc, poker_pot]
	_reward_social_with_table_npcs(3, "Ganó un bote de Póker en la Posada (+12)")
	_render_poker_ui()

func _decide_npc_poker_action(npc_idx: int, hole: Array[Dictionary], comm: Array[Dictionary], raise_amt: int) -> Dictionary:
	var combined: Array[Dictionary] = []
	combined.append_array(hole)
	combined.append_array(comm)
	var eval_res: Dictionary = _evaluate_cards_strength(combined)
	var cat: int = int(eval_res["category"])
	var arch: PokerArchetype = get_npc_poker_archetype(npc_idx)

	# Si ya tiene Pareja o superior, iguala por valor real (no es farol)
	if cat >= 1:
		return {"call": true, "bluffing": false, "category": cat}

	var high_hole: bool = (hole.size() >= 2 and (int(hole[0]["val"]) >= 12 or int(hole[1]["val"]) >= 12))
	var bluff_prob: float = 0.14
	match arch:
		PokerArchetype.STOIC_ROCK:
			bluff_prob = 0.08
		PokerArchetype.CALCULATING_SHARK:
			bluff_prob = 0.28
		PokerArchetype.IMPULSIVE_AGGRESSOR:
			bluff_prob = 0.36
		PokerArchetype.CAUTIOUS_READABLE:
			bluff_prob = 0.12

	if raise_amt >= 10:
		bluff_prob *= 0.65

	if randf() < bluff_prob:
		return {"call": true, "bluffing": true, "category": cat}

	if high_hole and raise_amt <= 5 and randf() < 0.65:
		return {"call": true, "bluffing": false, "category": cat}

	return {"call": raise_amt == 0, "bluffing": false, "category": cat}

func _should_npc_call(hole: Array[Dictionary], comm: Array[Dictionary], raise_amt: int) -> bool:
	var dec: Dictionary = _decide_npc_poker_action(0, hole, comm, raise_amt)
	return bool(dec["call"])

func _resolve_poker_showdown() -> void:
	var p_all: Array[Dictionary] = []
	p_all.append_array(poker_player_hand)
	p_all.append_array(poker_community)
	var p_eval: Dictionary = _evaluate_cards_strength(p_all)

	var n1_score: int = -1
	var n1_name := "Retirado"
	if not poker_npc1_folded:
		var n1_all: Array[Dictionary] = []
		n1_all.append_array(poker_npc1_hand)
		n1_all.append_array(poker_community)
		var n1_eval: Dictionary = _evaluate_cards_strength(n1_all)
		n1_score = int(n1_eval["score"])
		n1_name = str(n1_eval["name"])
		npc_reactions[0] = "🃏 Muestra: " + n1_name

	var n2_score: int = -1
	var n2_name := "Retirado"
	if not poker_npc2_folded:
		var n2_all: Array[Dictionary] = []
		n2_all.append_array(poker_npc2_hand)
		n2_all.append_array(poker_community)
		var n2_eval: Dictionary = _evaluate_cards_strength(n2_all)
		n2_score = int(n2_eval["score"])
		n2_name = str(n2_eval["name"])
		npc_reactions[1] = "🃏 Muestra: " + n2_name

	var p_score: int = int(p_eval["score"])
	var p_hand_name: String = str(p_eval["name"])

	_reward_social_with_table_npcs(3, "Gran partida de Póker con vecinos (+10)")

	if p_score > n1_score and p_score > n2_score:
		_add_player_gold(poker_pot)
		status_msg_lbl.text = "🏆 ¡GANASTE EL BOTE (+%d Oro) con %s! (Rivales: %s | %s)" % [poker_pot, p_hand_name, n1_name, n2_name]
	elif p_score >= n1_score and p_score >= n2_score and (p_score == n1_score or p_score == n2_score):
		var ties_cnt: int = 1 + (1 if p_score == n1_score else 0) + (1 if p_score == n2_score else 0)
		var split_gold: int = int(ceil(float(poker_pot) / float(ties_cnt)))
		_add_player_gold(split_gold)
		status_msg_lbl.text = "🤝 ¡EMPATE EN EL SHOWDOWN! Bote dividido (+%d Oro con %s)." % [split_gold, p_hand_name]
	elif n1_score >= n2_score:
		status_msg_lbl.text = "💸 %s gana el bote (%d Oro) con %s. (Tu mano: %s)" % [_get_npc_name(0), poker_pot, n1_name, p_hand_name]
	else:
		status_msg_lbl.text = "💸 %s gana el bote (%d Oro) con %s. (Tu mano: %s)" % [_get_npc_name(1), poker_pot, n2_name, p_hand_name]

func _evaluate_cards_strength(cards: Array[Dictionary]) -> Dictionary:
	# Si hay 5 o más cartas (ej. 7 cartas en Texas Hold'em), evalúa las combinaciones de 5 cartas
	# para encontrar la mejor mano exacta de 5 cartas con kickers reales.
	var n: int = cards.size()
	if n < 5:
		return _evaluate_five_card_hand(cards)
	var best_res: Dictionary = {"category": -1, "score": -1, "name": "Carta Alta"}
	for i in range(n - 4):
		for j in range(i + 1, n - 3):
			for k in range(j + 1, n - 2):
				for l in range(k + 1, n - 1):
					for m in range(l + 1, n):
						var five: Array[Dictionary] = [cards[i], cards[j], cards[k], cards[l], cards[m]]
						var cand: Dictionary = _evaluate_five_card_hand(five)
						if int(cand["score"]) > int(best_res["score"]):
							best_res = cand
	return best_res

func _evaluate_five_card_hand(cards: Array[Dictionary]) -> Dictionary:
	var counts: Dictionary = {}
	var suit_counts: Dictionary = {}
	var vals: Array[int] = []

	for c in cards:
		var v: int = int(c["val"])
		var s: String = str(c["suit"])
		counts[v] = int(counts.get(v, 0)) + 1
		suit_counts[s] = int(suit_counts.get(s, 0)) + 1
		if not vals.has(v):
			vals.append(v)
	vals.sort()
	vals.reverse()

	var is_flush: bool = (cards.size() >= 5 and suit_counts.size() == 1)
	var is_straight := false
	var straight_high: int = 0
	if vals.size() == 5:
		if vals[0] - vals[4] == 4:
			is_straight = true
			straight_high = vals[0]
		elif vals == [14, 5, 4, 3, 2]:
			is_straight = true
			straight_high = 5

	var four_val: int = 0
	var three_val: int = 0
	var pairs: Array[int] = []
	var singles: Array[int] = []
	for v_key in vals:
		var cnt: int = int(counts[v_key])
		if cnt == 4:
			four_val = v_key
		elif cnt == 3:
			three_val = v_key
		elif cnt == 2:
			pairs.append(v_key)
		else:
			singles.append(v_key)

	var high_card: int = vals[0] if not vals.is_empty() else 2
	var second_kicker: int = singles[0] if not singles.is_empty() else high_card

	if is_straight and is_flush:
		var sf_name: String = "Escalera Real" if straight_high == 14 else "Escalera de Color"
		return {"category": 8, "score": 800000 + straight_high, "name": sf_name}
	if four_val > 0:
		return {"category": 7, "score": 700000 + four_val * 100 + second_kicker, "name": "Póker"}
	if three_val > 0 and not pairs.is_empty():
		return {"category": 6, "score": 600000 + three_val * 100 + pairs[0], "name": "Full House"}
	if is_flush:
		return {"category": 5, "score": 500000 + high_card * 100 + (vals[1] if vals.size() > 1 else 0), "name": "Color (Flush)"}
	if is_straight:
		return {"category": 4, "score": 400000 + straight_high, "name": "Escalera"}
	if three_val > 0:
		return {"category": 3, "score": 300000 + three_val * 100 + second_kicker, "name": "Trío"}
	if pairs.size() >= 2:
		return {"category": 2, "score": 200000 + pairs[0] * 400 + pairs[1] * 20 + second_kicker, "name": "Doble Pareja"}
	if pairs.size() == 1:
		return {"category": 1, "score": 100000 + pairs[0] * 400 + second_kicker, "name": "Pareja"}
	return {"category": 0, "score": high_card * 100 + (vals[1] if vals.size() > 1 else 0), "name": "Carta Alta"}

# ==============================================================================
# 2. BLACKJACK 21 REAL (Baraja de 52 cartas, S17, BJ Natural 3:2, Doblar y Rendirse)
# ==============================================================================
func _calc_bj_total(hand: Array[Dictionary]) -> int:
	var total: int = 0
	var aces: int = 0
	for c in hand:
		var r: String = str(c["rank"])
		if r == "A":
			total += 11
			aces += 1
		elif r in ["K", "Q", "J", "10"]:
			total += 10
		else:
			total += int(r)
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func _render_blackjack_ui() -> void:
	_refresh_header()
	_clear_actions()
	_clear_visual_cards()
	table_title_lbl.text = "🃏 Blackjack 21 (S17 · Paga 3:2)  |  Apuesta Actual: 💰 %d Oro" % (bj_bet if bj_stage != BJStage.IDLE else 0)

	if bj_stage == BJStage.IDLE:
		visual_cards_area.add_child(_create_card_row("Banca (Marta):", [], false, false, 2))
		visual_cards_area.add_child(_create_card_row("Tu Mano:", [], false, false, 2))
		table_state_lbl.text = "Elige cuánto Oro quieres apostar en esta mano (Baraja francesa real de 52 cartas):"
		_add_action_btn("[1] Apostar 5 Oro", func(): _start_blackjack(5), _get_player_gold() < 5)
		_add_action_btn("[2] Apostar 10 Oro", func(): _start_blackjack(10), _get_player_gold() < 10)
		_add_action_btn("[3] Apostar 25 Oro", func(): _start_blackjack(25), _get_player_gold() < 25)
		return

	var hide_dealer_hole := (bj_stage == BJStage.PLAYER_TURN)
	var p_tot: int = _calc_bj_total(bj_player_hand)
	var d_tot_str: String = "?" if hide_dealer_hole else str(_calc_bj_total(bj_dealer_hand))

	visual_cards_area.add_child(_create_card_row("Banca [%s pts]:" % d_tot_str, bj_dealer_hand, false, hide_dealer_hole))
	visual_cards_area.add_child(_create_card_row("Tu Mano [%d pts]:" % p_tot, bj_player_hand))
	table_state_lbl.text = "Reglas de Casino: Blackjack natural paga 3:2  |  La Banca pide en 16 y se planta en todo 17 (S17)."

	if bj_stage == BJStage.PLAYER_TURN:
		_add_action_btn("[1] Pedir Carta (Hit)", _bj_hit)
		_add_action_btn("[2] Plantarse (Stand)", _bj_stand)
		var is_first_decision: bool = (bj_player_hand.size() == 2)
		var can_double: bool = (is_first_decision and _get_player_gold() >= bj_bet)
		_add_action_btn("[3] Doblar (+%d Oro)" % bj_bet, _bj_double, not can_double)
		_add_action_btn("[4] Rendirse (Recupera %d)" % int(float(bj_bet) * 0.5), _bj_surrender, not is_first_decision)
	else:
		_add_action_btn("[1] Jugar Otra Mano (5 Oro)", func(): _start_blackjack(5), _get_player_gold() < 5)
		_add_action_btn("[2] Jugar Otra Mano (10 Oro)", func(): _start_blackjack(10), _get_player_gold() < 10)
		_add_action_btn("[3] Jugar Otra Mano (25 Oro)", func(): _start_blackjack(25), _get_player_gold() < 25)

func _start_blackjack(bet_amount: int) -> void:
	if _get_player_gold() < bet_amount:
		return
	bj_bet = bet_amount
	_add_player_gold(-bj_bet)
	bj_deck = _build_shuffled_deck()
	bj_player_hand = [bj_deck.pop_back(), bj_deck.pop_back()]
	bj_dealer_hand = [bj_deck.pop_back(), bj_deck.pop_back()]
	bj_stage = BJStage.PLAYER_TURN

	var p_natural: bool = (_calc_bj_total(bj_player_hand) == 21)
	var d_natural: bool = (_calc_bj_total(bj_dealer_hand) == 21)
	if p_natural or d_natural:
		bj_stage = BJStage.FINISHED
		_reward_social_with_table_npcs(2)
		if p_natural and d_natural:
			_add_player_gold(bj_bet)
			status_msg_lbl.text = "🤝 ¡Doble Blackjack Natural (21)! Empate (Push), recuperas tus %d Oro." % bj_bet
		elif p_natural:
			var nat_payout: int = int(round(float(bj_bet) * 2.5))
			_add_player_gold(nat_payout)
			status_msg_lbl.text = "🏆 ¡BLACKJACK NATURAL (21 en 2 cartas)! Pago 3:2 -> Cobras +%d Oro." % nat_payout
		else:
			status_msg_lbl.text = "💸 La Banca tiene Blackjack Natural (21). Pierdes %d Oro." % bj_bet
		_render_blackjack_ui()
		return

	status_msg_lbl.text = "Mano repartida. ¿Pides carta [1], te plantas [2], doblas [3] o te rindes [4]?"
	_render_blackjack_ui()

func _bj_surrender() -> void:
	if bj_stage != BJStage.PLAYER_TURN or bj_player_hand.size() != 2:
		return
	bj_stage = BJStage.FINISHED
	var refund: int = int(float(bj_bet) * 0.5)
	_add_player_gold(refund)
	status_msg_lbl.text = "🏳️ Te rendiste (Surrender). Recuperas la mitad de tu apuesta (+%d Oro)." % refund
	_render_blackjack_ui()

func _bj_hit() -> void:
	if bj_stage != BJStage.PLAYER_TURN:
		return
	bj_player_hand.append(bj_deck.pop_back())
	var tot: int = _calc_bj_total(bj_player_hand)
	if tot > 21:
		bj_stage = BJStage.FINISHED
		status_msg_lbl.text = "💥 ¡Te pasaste de 21 (%d pts)! Pierdes la apuesta de %d Oro." % [tot, bj_bet]
		_reward_social_with_table_npcs(1)
		_render_blackjack_ui()
	elif tot == 21:
		_bj_stand()
	else:
		status_msg_lbl.text = "Tienes %d puntos. ¿Pides otra [1] o te plantas [2]?" % tot
		_render_blackjack_ui()

func _bj_double() -> void:
	if bj_stage != BJStage.PLAYER_TURN or bj_player_hand.size() != 2 or _get_player_gold() < bj_bet:
		return
	_add_player_gold(-bj_bet)
	bj_bet *= 2
	bj_player_hand.append(bj_deck.pop_back())
	if _calc_bj_total(bj_player_hand) > 21:
		bj_stage = BJStage.FINISHED
		status_msg_lbl.text = "💥 Doblaste y te pasaste con %d puntos. Pierdes %d Oro." % [_calc_bj_total(bj_player_hand), bj_bet]
		_render_blackjack_ui()
	else:
		_bj_stand()

func _bj_stand() -> void:
	bj_stage = BJStage.FINISHED
	while _calc_bj_total(bj_dealer_hand) < 17:
		bj_dealer_hand.append(bj_deck.pop_back())

	var p_tot: int = _calc_bj_total(bj_player_hand)
	var d_tot: int = _calc_bj_total(bj_dealer_hand)
	var is_natural_bj: bool = (p_tot == 21 and bj_player_hand.size() == 2)

	_reward_social_with_table_npcs(2)

	if d_tot > 21 or p_tot > d_tot:
		var payout: int = int(round(float(bj_bet) * 2.5)) if is_natural_bj else (bj_bet * 2)
		_add_player_gold(payout)
		var bj_tag := " ¡BLACKJACK NATURAL!" if is_natural_bj else ""
		status_msg_lbl.text = "🏆%s ¡Ganaste con %d frente a %d de la banca! Cobras +%d Oro." % [bj_tag, p_tot, d_tot, payout]
	elif p_tot == d_tot:
		_add_player_gold(bj_bet)
		status_msg_lbl.text = "🤝 Empate (Push) a %d puntos. Recuperas tus %d Oro." % [p_tot, bj_bet]
	else:
		status_msg_lbl.text = "💸 La banca gana con %d frente a tus %d puntos." % [d_tot, p_tot]

	_render_blackjack_ui()

# ==============================================================================
# 3. RULETA EUROPEA REAL DE 37 CASILLAS (0 AL 36 — VENTAJA DE LA CASA 2.70%)
# ==============================================================================
func _format_roulette_number(num: int) -> String:
	if num == 0:
		return "🟢 0 (VERDE)"
	elif RED_NUMBERS.has(num):
		return "🔴 %d (ROJO)" % num
	return "⚫ %d (NEGRO)" % num

func get_roulette_covered_numbers(bet_kind: String, base_num: int) -> Array[int]:
	var b: int = clampi(base_num, 0, 36)
	var n_pos: int = clampi(b, 1, 36)
	match bet_kind:
		"straight", "exact":
			return [b]
		"zero":
			return [0]
		"split":
			# Caballo (2 números contiguos en el paño)
			if b == 0:
				return [0, 1]
			var partner: int = n_pos + 1 if (n_pos % 3 != 0) else (n_pos - 1)
			return [n_pos, partner]
		"street":
			# Calle / Transversal (fila de 3 números)
			var row_start: int = int(float(n_pos - 1) / 3.0) * 3 + 1
			return [row_start, row_start + 1, row_start + 2]
		"corner":
			# Cuadro (esquina de 4 números en el paño)
			var r_idx: int = mini(int(float(n_pos - 1) / 3.0), 10) # filas 0..10 para que r_idx+1 exista
			var c_idx: int = 0 if ((n_pos - 1) % 3 == 0) else 1
			var tl: int = r_idx * 3 + c_idx + 1
			return [tl, tl + 1, tl + 3, tl + 4]
		"six_line":
			# Seisena (dos filas contiguas = 6 números)
			var r6: int = mini(int(float(n_pos - 1) / 3.0), 10)
			var first_n: int = r6 * 3 + 1
			return [first_n, first_n + 1, first_n + 2, first_n + 3, first_n + 4, first_n + 5]
		"dozen_1":
			var d1: Array[int] = []
			for i in range(1, 13): d1.append(i)
			return d1
		"dozen_2":
			var d2: Array[int] = []
			for i in range(13, 25): d2.append(i)
			return d2
		"dozen_3":
			var d3: Array[int] = []
			for i in range(25, 37): d3.append(i)
			return d3
		"col_1":
			var c1: Array[int] = []
			for i in range(1, 37):
				if i % 3 == 1: c1.append(i)
			return c1
		"col_2":
			var c2: Array[int] = []
			for i in range(1, 37):
				if i % 3 == 2: c2.append(i)
			return c2
		"col_3":
			var c3: Array[int] = []
			for i in range(1, 37):
				if i % 3 == 0: c3.append(i)
			return c3
		"red":
			return RED_NUMBERS.duplicate()
		"black":
			var blk: Array[int] = []
			for i in range(1, 37):
				if not RED_NUMBERS.has(i): blk.append(i)
			return blk
		"even":
			var ev: Array[int] = []
			for i in range(2, 37, 2): ev.append(i)
			return ev
		"odd":
			var od: Array[int] = []
			for i in range(1, 37, 2): od.append(i)
			return od
		"low":
			var lw: Array[int] = []
			for i in range(1, 19): lw.append(i)
			return lw
		"high":
			var hg: Array[int] = []
			for i in range(19, 37): hg.append(i)
			return hg
	return [b]

func evaluate_roulette_bet(bet_kind: String, base_num: int, winning_ball: int) -> Dictionary:
	var covered: Array[int] = get_roulette_covered_numbers(bet_kind, base_num)
	var won: bool = covered.has(winning_ball)
	var mult: int = 2
	match bet_kind:
		"straight", "exact", "zero":
			mult = 36 # Pago real 35 a 1 (+ ficha apostada = x36)
		"split":
			mult = 18 # Pago real 17 a 1 (+ ficha = x18)
		"street":
			mult = 12 # Pago real 11 a 1 (+ ficha = x12)
		"corner":
			mult = 9  # Pago real 8 a 1 (+ ficha = x9)
		"six_line":
			mult = 6  # Pago real 5 a 1 (+ ficha = x6)
		"dozen_1", "dozen_2", "dozen_3", "col_1", "col_2", "col_3":
			mult = 3  # Pago real 2 a 1 (+ ficha = x3)
		"red", "black", "even", "odd", "low", "high":
			mult = 2  # Pago real 1 a 1 (+ ficha = x2; el 0 verde pierde)
	return {
		"won": won,
		"multiplier": mult,
		"net_odds": "%d:1" % (mult - 1),
		"covered_numbers": covered
	}

func _render_roulette_ui() -> void:
	_refresh_header()
	_clear_actions()
	var chip: int = roulette_chip_values[roulette_chip_idx]
	var mode_names: Array[String] = [
		"Suertes Sencillas (1:1 · x2)",
		"Docenas y Columnas (2:1 · x3)",
		"Apuestas Internas (Pleno 35:1, Caballo 17:1, Calle 11:1, Cuadro 8:1, Seisena 5:1)"
	]
	table_title_lbl.text = "🎡 Ruleta Europea (0–36)  |  Ficha: 💰 %d Oro ([Q] Ficha)  |  Selector: #%d ([Z/X] Cambiar N.º)" % [chip, roulette_chosen_num]

	var row1 := "🟢[0]  🔴1 ⚫2 🔴3 | ⚫4 🔴5 ⚫6 | 🔴7 ⚫8 🔴9 | ⚫10 ⚫11 🔴12 | ⚫13 🔴14 ⚫15 | 🔴16 ⚫17 🔴18"
	var row2 := "🔴19 ⚫20 🔴21 | ⚫22 🔴23 ⚫24 | 🔴25 ⚫26 🔴27 | ⚫28 ⚫29 🔴30 | ⚫31 🔴32 ⚫33 | 🔴34 ⚫35 🔴36"
	cards_display_lbl.text = "%s\n%s\n\nModo Actual: %s   |   Última Bola:  %s" % [
		row1, row2, mode_names[int(roulette_mode)], _format_roulette_number(roulette_current_ball)
	]

	var split_nums := get_roulette_covered_numbers("split", roulette_chosen_num)
	var street_nums := get_roulette_covered_numbers("street", roulette_chosen_num)
	var corner_nums := get_roulette_covered_numbers("corner", roulette_chosen_num)
	var six_nums := get_roulette_covered_numbers("six_line", roulette_chosen_num)

	var no_gold: bool = (_get_player_gold() < chip) or roulette_spinning

	match roulette_mode:
		RouletteMode.SUERTES_SENCILLAS:
			table_state_lbl.text = "Probabilidad Real: 18/37 (48.65%) — Pago 1:1 (x2). Si sale 🟢 0 pierden las suertes sencillas. [Tab] o [7] para ver Docenas/Internas."
			_add_action_btn("[1] 🔴 Rojo (x2)", func(): _spin_roulette("red", chip), no_gold)
			_add_action_btn("[2] ⚫ Negro (x2)", func(): _spin_roulette("black", chip), no_gold)
			_add_action_btn("[3] Par (x2)", func(): _spin_roulette("even", chip), no_gold)
			_add_action_btn("[4] Impar (x2)", func(): _spin_roulette("odd", chip), no_gold)
			_add_action_btn("[5] 1–18 Falta (x2)", func(): _spin_roulette("low", chip), no_gold)
			_add_action_btn("[6] 19–36 Pasa (x2)", func(): _spin_roulette("high", chip), no_gold)
			_add_action_btn("[7] 🔁 Ver Docenas/Cols", func():
				roulette_mode = RouletteMode.DOCENAS_Y_COLUMNAS
				_render_roulette_ui()
			, roulette_spinning)
		RouletteMode.DOCENAS_Y_COLUMNAS:
			table_state_lbl.text = "Probabilidad Real: 12/37 (32.43%) — Pago 2:1 (x3). Si sale 🟢 0 pierden docenas y columnas. [Tab] o [7] para Apuestas Internas."
			_add_action_btn("[1] 1.ª Docena 1–12 (x3)", func(): _spin_roulette("dozen_1", chip), no_gold)
			_add_action_btn("[2] 2.ª Docena 13–24 (x3)", func(): _spin_roulette("dozen_2", chip), no_gold)
			_add_action_btn("[3] 3.ª Docena 25–36 (x3)", func(): _spin_roulette("dozen_3", chip), no_gold)
			_add_action_btn("[4] Columna 1 (x3)", func(): _spin_roulette("col_1", chip), no_gold)
			_add_action_btn("[5] Columna 2 (x3)", func(): _spin_roulette("col_2", chip), no_gold)
			_add_action_btn("[6] Columna 3 (x3)", func(): _spin_roulette("col_3", chip), no_gold)
			_add_action_btn("[7] 🔁 Ver Plenos/Internas", func():
				roulette_mode = RouletteMode.APUESTAS_INTERNAS
				_render_roulette_ui()
			, roulette_spinning)
		RouletteMode.APUESTAS_INTERNAS:
			table_state_lbl.text = "Internas sobre #%d: Pleno #%d (35:1) | Caballo %s (17:1) | Calle %d–%d (11:1) | Cuadro %d..%d (8:1) | Seisena %d–%d (5:1)" % [
				roulette_chosen_num, roulette_chosen_num, str(split_nums),
				street_nums[0], street_nums[2], corner_nums[0], corner_nums[3], six_nums[0], six_nums[5]
			]
			_add_action_btn("[1] 🎯 Pleno #%d (x36)" % roulette_chosen_num, func(): _spin_roulette("straight", chip), no_gold)
			_add_action_btn("[2] 🟢 Pleno 0 (x36)", func(): _spin_roulette("zero", chip), no_gold)
			_add_action_btn("[3] Caballo %d/%d (x18)" % [split_nums[0], split_nums[1]], func(): _spin_roulette("split", chip), no_gold)
			_add_action_btn("[4] Calle %d–%d (x12)" % [street_nums[0], street_nums[2]], func(): _spin_roulette("street", chip), no_gold)
			_add_action_btn("[5] Cuadro %d..%d (x9)" % [corner_nums[0], corner_nums[3]], func(): _spin_roulette("corner", chip), no_gold)
			_add_action_btn("[6] Seisena %d–%d (x6)" % [six_nums[0], six_nums[5]], func(): _spin_roulette("six_line", chip), no_gold)
			_add_action_btn("[7] 🔁 Suertes Sencillas", func():
				roulette_mode = RouletteMode.SUERTES_SENCILLAS
				_render_roulette_ui()
			, roulette_spinning)
			_add_action_btn("[8] N.º +1 (#%d)" % roulette_chosen_num, func():
				roulette_chosen_num = (roulette_chosen_num + 1) % 37
				_render_roulette_ui()
			, roulette_spinning)

func _spin_roulette(bet_kind: String, amount: int) -> void:
	if roulette_spinning or _get_player_gold() < amount:
		return
	_add_player_gold(-amount)
	roulette_bet_type = bet_kind
	roulette_bet_amt = amount
	roulette_spinning = true
	roulette_spin_timer = 1.15
	status_msg_lbl.text = "🎡 ¡No va más! Cilindro europeo en giro (37 casillas, 0–36) con %d Oro..." % amount
	_render_roulette_ui()

func _finish_roulette_spin() -> void:
	# Probabilidad uniforme exacta 1/37 en los 37 números del cilindro europeo (0 al 36)
	roulette_current_ball = randi() % 37
	var res_num: int = roulette_current_ball
	var eval_res: Dictionary = evaluate_roulette_bet(roulette_bet_type, roulette_chosen_num, res_num)
	var won: bool = bool(eval_res["won"])
	var mult: int = int(eval_res["multiplier"])
	var odds_str: String = str(eval_res["net_odds"])

	_reward_social_with_table_npcs(1)

	if won:
		var prize: int = roulette_bet_amt * mult
		_add_player_gold(prize)
		status_msg_lbl.text = "🎉 ¡Salió %s! ¡Apuesta ganadora (%s -> x%d)! Cobras +%d Oro." % [_format_roulette_number(res_num), odds_str, mult, prize]
	else:
		status_msg_lbl.text = "💨 Salió %s. No hubo suerte en esta tirada (Números cubiertos: %s)." % [_format_roulette_number(res_num), str(eval_res["covered_numbers"])]

	_render_roulette_ui()

# ==============================================================================
# 4. BILLAR DE LA POSADA (8-BALL POOL CON ÁNGULO Y BARRA DE POTENCIA)
# ==============================================================================
func _reset_pool_rack() -> void:
	pool_cue_pos = Vector2(88, 68)
	pool_cue_vel = Vector2.ZERO
	pool_balls_moving = false
	pool_aim_angle = 0.0
	pool_targets = [
		{"pos": Vector2(258, 68), "vel": Vector2.ZERO, "color": Color(0.95, 0.22, 0.20), "num": 1, "pocketed": false},
		{"pos": Vector2(274, 56), "vel": Vector2.ZERO, "color": Color(0.98, 0.82, 0.18), "num": 2, "pocketed": false},
		{"pos": Vector2(274, 80), "vel": Vector2.ZERO, "color": Color(0.22, 0.55, 0.98), "num": 3, "pocketed": false},
		{"pos": Vector2(290, 68), "vel": Vector2.ZERO, "color": Color(0.15, 0.15, 0.18), "num": 8, "pocketed": false}
	]

func _render_billiards_ui() -> void:
	_refresh_header()
	_clear_actions()
	var remaining: int = 0
	for b in pool_targets:
		if not bool(b["pocketed"]):
			remaining += 1
	table_title_lbl.text = "🎱 Billar de la Posada  |  Bolas en Mesa: %d/4  |  Premio por Tronera: 💰 +14 Oro (+25 Oro la Bola 8)" % remaining
	table_state_lbl.text = "Apunta el taco con [1]/[2] (o teclas A/D) y golpea con [3] (o Espacio). Cada tiro cuesta 4 Oro."

	_add_action_btn("[1] ⟲ Apuntar Izq. (-10°)", func():
		pool_aim_angle -= deg_to_rad(10.0)
		if pool_canvas:
			pool_canvas.queue_redraw()
	, pool_balls_moving)
	_add_action_btn("[2] ⟳ Apuntar Der. (+10°)", func():
		pool_aim_angle += deg_to_rad(10.0)
		if pool_canvas:
			pool_canvas.queue_redraw()
	, pool_balls_moving)
	_add_action_btn("[3] 🎱 ¡TIRAR TACO! (-4 Oro)", _shoot_pool_cue, pool_balls_moving or _get_player_gold() < 4)
	_add_action_btn("[4] 🔄 Colocar Nuevo Triángulo", func():
		_reset_pool_rack()
		status_msg_lbl.text = "🎱 Triángulo de bolas recolocado en la mesa."
		_render_billiards_ui()
	, pool_balls_moving)
	if pool_canvas:
		pool_canvas.queue_redraw()

func _shoot_pool_cue() -> void:
	if pool_balls_moving or _get_player_gold() < 4:
		return
	_add_player_gold(-4)
	pool_score_this_rack = 0
	var dir := Vector2(cos(pool_aim_angle), sin(pool_aim_angle))
	var shot_spd: float = lerpf(165.0, 390.0, pool_power)
	pool_cue_vel = dir * shot_spd
	pool_balls_moving = true
	status_msg_lbl.text = "🎱 ¡Tacazo con %d%% de potencia!" % int(round(pool_power * 100.0))
	_render_billiards_ui()

func _update_billiards(delta: float) -> void:
	if not pool_balls_moving:
		pool_power_phase += delta * 2.8
		pool_power = 0.25 + (sin(pool_power_phase) * 0.5 + 0.5) * 0.75
		if pool_canvas:
			pool_canvas.queue_redraw()
		return

	var pockets: Array[Vector2] = [
		Vector2(10, 10), Vector2(POOL_TABLE_SIZE.x * 0.5, 8), Vector2(POOL_TABLE_SIZE.x - 10, 10),
		Vector2(10, POOL_TABLE_SIZE.y - 10), Vector2(POOL_TABLE_SIZE.x * 0.5, POOL_TABLE_SIZE.y - 8), Vector2(POOL_TABLE_SIZE.x - 10, POOL_TABLE_SIZE.y - 10)
	]

	# Mover bola blanca
	pool_cue_pos += pool_cue_vel * delta
	pool_cue_vel = pool_cue_vel.move_toward(Vector2.ZERO, 145.0 * delta)
	_bounce_ball_in_rails(pool_cue_pos, pool_cue_vel, true, -1)

	# Colisión de bola blanca con bolas objetivo
	for i in range(pool_targets.size()):
		var b: Dictionary = pool_targets[i]
		if bool(b["pocketed"]):
			continue
		var b_pos: Vector2 = b["pos"]
		var b_vel: Vector2 = b["vel"]
		var diff: Vector2 = b_pos - pool_cue_pos
		var dist: float = diff.length()
		if dist > 0.001 and dist < 13.5:
			var n: Vector2 = diff / dist
			pool_cue_pos = b_pos - n * 13.5
			var rel_v: Vector2 = pool_cue_vel - b_vel
			var sep_spd: float = rel_v.dot(n)
			if sep_spd > 0.0:
				var impulse: Vector2 = n * sep_spd * 0.92
				pool_cue_vel -= impulse * 0.65
				b["vel"] = b_vel + impulse * 1.12

	# Mover bolas objetivo y comprobar troneras
	var any_moving: bool = pool_cue_vel.length_squared() > 16.0
	for i in range(pool_targets.size()):
		var b: Dictionary = pool_targets[i]
		if bool(b["pocketed"]):
			continue
		var p: Vector2 = b["pos"] + b["vel"] * delta
		var v: Vector2 = (b["vel"] as Vector2).move_toward(Vector2.ZERO, 135.0 * delta)

		if p.x < 12.0 or p.x > POOL_TABLE_SIZE.x - 12.0:
			v.x = -v.x * 0.82
			p.x = clampf(p.x, 12.0, POOL_TABLE_SIZE.x - 12.0)
		if p.y < 12.0 or p.y > POOL_TABLE_SIZE.y - 12.0:
			v.y = -v.y * 0.82
			p.y = clampf(p.y, 12.0, POOL_TABLE_SIZE.y - 12.0)

		b["pos"] = p
		b["vel"] = v
		if v.length_squared() > 16.0:
			any_moving = true

		for pk in pockets:
			if p.distance_to(pk) <= 14.5:
				b["pocketed"] = true
				b["vel"] = Vector2.ZERO
				var b_num: int = int(b["num"])
				var reward: int = 25 if b_num == 8 else 14
				pool_score_this_rack += reward
				_add_player_gold(reward)
				npc_reactions[0] = "👏 ¡Qué gran tiro a la #%d!" % b_num
				status_msg_lbl.text = "🎱🎉 ¡Embocaste la Bola #%d en la tronera! (+%d Oro)" % [b_num, reward]
				_reward_social_with_table_npcs(3, "Vio una carambola maestra de billar (+9)")
				break

	if not any_moving:
		pool_balls_moving = false
		pool_cue_vel = Vector2.ZERO
		var all_cleared := true
		for b in pool_targets:
			if not bool(b["pocketed"]):
				all_cleared = false
				break
		if all_cleared:
			status_msg_lbl.text = "🏆🎱 ¡LIMPIASTE LA MESA DE BILLAR! Nuevo triángulo colocado."
			_reset_pool_rack()
		_render_billiards_ui()

	if pool_canvas:
		pool_canvas.queue_redraw()

func _bounce_ball_in_rails(_pos: Vector2, _vel: Vector2, is_cue: bool, _idx: int) -> void:
	if is_cue:
		if pool_cue_pos.x < 12.0 or pool_cue_pos.x > POOL_TABLE_SIZE.x - 12.0:
			pool_cue_vel.x = -pool_cue_vel.x * 0.82
			pool_cue_pos.x = clampf(pool_cue_pos.x, 12.0, POOL_TABLE_SIZE.x - 12.0)
		if pool_cue_pos.y < 12.0 or pool_cue_pos.y > POOL_TABLE_SIZE.y - 12.0:
			pool_cue_vel.y = -pool_cue_vel.y * 0.82
			pool_cue_pos.y = clampf(pool_cue_pos.y, 12.0, POOL_TABLE_SIZE.y - 12.0)

func _draw_pool_table() -> void:
	if not pool_canvas:
		return
	var sz := POOL_TABLE_SIZE
	# Marco de caoba y tapete esmeralda
	pool_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.38, 0.22, 0.10, 1.0), true)
	pool_canvas.draw_rect(Rect2(Vector2(7, 7), sz - Vector2(14, 14)), Color(0.07, 0.46, 0.28, 1.0), true)
	pool_canvas.draw_rect(Rect2(Vector2(7, 7), sz - Vector2(14, 14)), Color(0.82, 0.68, 0.34, 0.9), false, 1.5)

	# 6 Troneras
	var pockets: Array[Vector2] = [
		Vector2(10, 10), Vector2(sz.x * 0.5, 8), Vector2(sz.x - 10, 10),
		Vector2(10, sz.y - 10), Vector2(sz.x * 0.5, sz.y - 8), Vector2(sz.x - 10, sz.y - 10)
	]
	for pk in pockets:
		pool_canvas.draw_circle(pk, 9.5, Color(0.05, 0.05, 0.06, 1.0))

	# Línea de apuntado y taco cuando las bolas están quietas
	if not pool_balls_moving:
		var aim_dir := Vector2(cos(pool_aim_angle), sin(pool_aim_angle))
		pool_canvas.draw_line(pool_cue_pos, pool_cue_pos + aim_dir * 95.0, Color(1.0, 1.0, 0.75, 0.65), 1.5)
		pool_canvas.draw_line(pool_cue_pos - aim_dir * 12.0, pool_cue_pos - aim_dir * 52.0, Color(0.76, 0.54, 0.28, 1.0), 3.2)

	# Bola Blanca
	pool_canvas.draw_circle(pool_cue_pos, 6.5, Color(0.98, 0.98, 0.96, 1.0))
	pool_canvas.draw_arc(pool_cue_pos, 6.5, 0.0, TAU, 20, Color(0.2, 0.2, 0.25), 1.2)

	# Bolas Objetivo
	var font: Font = ThemeDB.fallback_font
	for b in pool_targets:
		if bool(b["pocketed"]):
			continue
		var bp: Vector2 = b["pos"]
		var bc: Color = b["color"]
		pool_canvas.draw_circle(bp, 6.8, bc)
		pool_canvas.draw_circle(bp, 3.0, Color.WHITE)
		if font:
			pool_canvas.draw_string(font, bp + Vector2(-3, 3), str(b["num"]), HORIZONTAL_ALIGNMENT_CENTER, 8, 8, Color.BLACK)

	# Barra de Potencia en la parte inferior de la mesa
	var bar_bg := Rect2(Vector2(16, sz.y - 18), Vector2(120, 7))
	pool_canvas.draw_rect(bar_bg, Color(0.12, 0.12, 0.16, 0.9), true)
	var p_col := Color(0.30, 0.95, 0.45) if pool_power < 0.7 else Color(1.0, 0.78, 0.22)
	pool_canvas.draw_rect(Rect2(bar_bg.position, Vector2(120.0 * pool_power, 7)), p_col, true)
