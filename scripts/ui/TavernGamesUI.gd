extends PanelContainer
class_name TavernGamesUI

## Salón de Juegos de la Taberna "El Jabalí Dorado" (Póker Texas Hold'em, Blackjack 21 y Ruleta)
## - 100% Jugable con Teclado (teclas [1]-[8], [F1]-[F3], [Q], [ESC]) para ThinkPad sin ratón, y también con Clics.
## - En el Póker juegas contra los NPCs reales de la aldea que estén libres o en la Taberna,
##   aumentando su barra de Socialización (💬) y tu Afinidad con ellos mientras juegan.

enum GameTab { POKER, BLACKJACK, ROULETTE }

var player: CharacterBody2D = null
var current_tab: GameTab = GameTab.POKER

# Nodos de UI
var header_gold_lbl: Label = null
var header_npcs_lbl: Label = null
var tab_info_lbl: Label = null
var table_title_lbl: Label = null
var table_state_lbl: Label = null
var cards_display_lbl: Label = null
var actions_box: HBoxContainer = null
var status_msg_lbl: Label = null

# Opponents at the table
var table_npcs: Array[VillageNPC] = []

# --- ESTADO DE PÓKER (Texas Hold'em) ---
enum PokerStage { IDLE, PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN }
var poker_stage: PokerStage = PokerStage.IDLE
var poker_deck: Array[Dictionary] = []
var poker_community: Array[Dictionary] = []
var poker_player_hand: Array[Dictionary] = []
var poker_npc1_hand: Array[Dictionary] = []
var poker_npc2_hand: Array[Dictionary] = []
var poker_npc1_folded: bool = false
var poker_npc2_folded: bool = false
var poker_pot: int = 0
var poker_current_bet: int = 0

# --- ESTADO DE BLACKJACK (21) ---
enum BJStage { IDLE, PLAYER_TURN, FINISHED }
var bj_stage: BJStage = BJStage.IDLE
var bj_deck: Array[Dictionary] = []
var bj_player_hand: Array[Dictionary] = []
var bj_dealer_hand: Array[Dictionary] = []
var bj_bet: int = 5

# --- ESTADO DE RULETA ---
var roulette_chip_values: Array[int] = [5, 10, 20]
var roulette_chip_idx: int = 0
var roulette_chosen_num: int = 7
var roulette_spinning: bool = false
var roulette_spin_timer: float = 0.0
var roulette_current_ball: int = 0
var roulette_bet_type: String = ""
var roulette_bet_amt: int = 5

const SUITS: Array[String] = ["♠", "♥", "♦", "♣"]
const RANKS: Array[String] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const RED_NUMBERS: Array[int] = [1, 3, 5, 7, 9, 11]

func _ready() -> void:
	visible = false
	layout_mode = 1
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -390.0
	offset_top = -225.0
	offset_right = 390.0
	offset_bottom = 225.0
	z_index = 90

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.14, 0.10, 0.97) # Fieltro verde oscuro de mesa de juego
	style.border_color = Color(0.82, 0.65, 0.30, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	add_theme_stylebox_override("panel", style)

	_build_ui()

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	# 1. Cabecera
	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "🎲 Mesa de Juegos — Taberna 'El Jabalí Dorado'"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	header.add_child(title)

	header_gold_lbl = Label.new()
	header_gold_lbl.text = "💰 25 Oro"
	header_gold_lbl.add_theme_font_size_override("font_size", 15)
	header_gold_lbl.add_theme_color_override("font_color", Color.GOLD)
	header.add_child(header_gold_lbl)

	header_npcs_lbl = Label.new()
	header_npcs_lbl.text = "Sentados a la mesa: Aldric y Sora"
	header_npcs_lbl.add_theme_font_size_override("font_size", 11)
	header_npcs_lbl.add_theme_color_override("font_color", Color(0.75, 0.92, 0.82))
	root_vbox.add_child(header_npcs_lbl)

	# 2. Selector de Juego ([F1], [F2], [F3])
	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(tabs_hbox)

	var btn_poker := Button.new()
	btn_poker.text = "♠️ [F1] Póker Hold'em (vs NPCs)"
	btn_poker.pressed.connect(func(): _switch_tab(GameTab.POKER))
	tabs_hbox.add_child(btn_poker)

	var btn_bj := Button.new()
	btn_bj.text = "🃏 [F2] Blackjack 21"
	btn_bj.pressed.connect(func(): _switch_tab(GameTab.BLACKJACK))
	tabs_hbox.add_child(btn_bj)

	var btn_roul := Button.new()
	btn_roul.text = "🎡 [F3] Ruleta de la Posada"
	btn_roul.pressed.connect(func(): _switch_tab(GameTab.ROULETTE))
	tabs_hbox.add_child(btn_roul)

	var btn_exit := Button.new()
	btn_exit.text = "✖ [ESC] Levantarse"
	btn_exit.pressed.connect(func(): close_games())
	tabs_hbox.add_child(btn_exit)

	root_vbox.add_child(HSeparator.new())

	# 3. Área Central del Tapete
	var felt_panel := PanelContainer.new()
	felt_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var felt_style := StyleBoxFlat.new()
	felt_style.bg_color = Color(0.05, 0.22, 0.13, 0.95)
	felt_style.border_color = Color(0.35, 0.58, 0.40, 0.8)
	felt_style.set_border_width_all(2)
	felt_style.set_corner_radius_all(8)
	felt_style.content_margin_left = 14
	felt_style.content_margin_right = 14
	felt_style.content_margin_top = 10
	felt_style.content_margin_bottom = 10
	felt_panel.add_theme_stylebox_override("panel", felt_style)
	root_vbox.add_child(felt_panel)

	var felt_vbox := VBoxContainer.new()
	felt_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	felt_vbox.add_theme_constant_override("separation", 8)
	felt_panel.add_child(felt_vbox)

	table_title_lbl = Label.new()
	table_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_title_lbl.add_theme_font_size_override("font_size", 15)
	table_title_lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.68))
	felt_vbox.add_child(table_title_lbl)

	cards_display_lbl = Label.new()
	cards_display_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cards_display_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cards_display_lbl.add_theme_font_size_override("font_size", 14)
	cards_display_lbl.add_theme_color_override("font_color", Color.WHITE)
	cards_display_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	cards_display_lbl.add_theme_constant_override("outline_size", 3)
	felt_vbox.add_child(cards_display_lbl)

	table_state_lbl = Label.new()
	table_state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_state_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	table_state_lbl.add_theme_font_size_override("font_size", 12)
	table_state_lbl.add_theme_color_override("font_color", Color(0.80, 0.95, 0.85))
	felt_vbox.add_child(table_state_lbl)

	status_msg_lbl = Label.new()
	status_msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_msg_lbl.add_theme_font_size_override("font_size", 13)
	status_msg_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
	root_vbox.add_child(status_msg_lbl)

	# 4. Botonera de Acciones (con atajos de teclado [1]-[8])
	actions_box = HBoxContainer.new()
	actions_box.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_box.add_theme_constant_override("separation", 8)
	root_vbox.add_child(actions_box)

	tab_info_lbl = Label.new()
	tab_info_lbl.text = "⌨️ Modo ThinkPad: Usa las teclas [1]-[8] para jugar, [F1]/[F2]/[F3] para cambiar de juego y [ESC] para salir."
	tab_info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_info_lbl.add_theme_font_size_override("font_size", 10)
	tab_info_lbl.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72))
	root_vbox.add_child(tab_info_lbl)

func open_games(initial_tab: GameTab = GameTab.POKER) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	_select_table_npcs()
	visible = true
	_switch_tab(initial_tab)

func close_games() -> void:
	if not visible:
		return
	roulette_spinning = false
	visible = false

func _select_table_npcs() -> void:
	table_npcs.clear()
	var candidates: Array[VillageNPC] = []
	for node in get_tree().get_nodes_in_group("village_npcs"):
		if node is VillageNPC:
			var npc: VillageNPC = node as VillageNPC
			if not npc.is_dead and not npc.is_sleeping and npc.trade_role != VillageNPC.TradeRole.INNKEEPER:
				# Priorizar NPCs que no estén en turno laboral o que sean viajeros en la taberna
				if not npc._is_mandatory_work_hours():
					candidates.push_front(npc)
				else:
					candidates.push_back(npc)
	for i in range(mini(2, candidates.size())):
		table_npcs.append(candidates[i])

func _get_npc_name(idx: int) -> String:
	if idx < table_npcs.size() and is_instance_valid(table_npcs[idx]):
		return "%s (%s)" % [table_npcs[idx].npc_name, table_npcs[idx].family_name]
	return "Aldric (Viajero)" if idx == 0 else "Sora (Forastera)"

func _reward_social_with_table_npcs(affinity_bonus: int = 2) -> void:
	for npc in table_npcs:
		if is_instance_valid(npc) and not npc.is_dead:
			npc.need_social = minf(100.0, npc.need_social + 14.0)
			if affinity_bonus != 0:
				npc.affinity = clampi(npc.affinity + affinity_bonus, -100, 100)
	if player and player.has_node("SurvivalComponent"):
		var surv: SurvivalComponent = player.get_node("SurvivalComponent")
		surv.restore_sleep(2.0)

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
	if header_npcs_lbl:
		header_npcs_lbl.text = "👥 En la mesa contigo: %s  y  %s" % [_get_npc_name(0), _get_npc_name(1)]

func _switch_tab(new_tab: GameTab) -> void:
	if roulette_spinning:
		return
	current_tab = new_tab
	_refresh_header()
	match current_tab:
		GameTab.POKER:
			poker_stage = PokerStage.IDLE
			status_msg_lbl.text = "Bienvenido al Póker Texas Hold'em. Apuesta inicial (Ante): 5 Oro por jugador."
			_render_poker_ui()
		GameTab.BLACKJACK:
			bj_stage = BJStage.IDLE
			status_msg_lbl.text = "Blackjack 21 contra la Banca de Marta. ¡Acércate a 21 sin pasarte!"
			_render_blackjack_ui()
		GameTab.ROULETTE:
			roulette_spinning = false
			status_msg_lbl.text = "Ruleta de El Jabalí Dorado (Números 0 al 12). Elige tu jugada."
			_render_roulette_ui()

func _process(delta: float) -> void:
	if not visible:
		return
	if roulette_spinning:
		roulette_spin_timer -= delta
		roulette_current_ball = (roulette_current_ball + 1) % 13
		cards_display_lbl.text = "🎡 Girando la Ruleta...  [  %s  ]" % _format_roulette_number(roulette_current_ball)
		if roulette_spin_timer <= 0.0:
			roulette_spinning = false
			_finish_roulette_spin()

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

		# Consumir números y espacio para que no disparen armas ni cambien herramientas fuera de la mesa
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx: int = int(event.keycode - KEY_1)
			_trigger_action_button(idx)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_trigger_action_button(0)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_Q and current_tab == GameTab.ROULETTE and not roulette_spinning:
			roulette_chip_idx = (roulette_chip_idx + 1) % roulette_chip_values.size()
			_render_roulette_ui()
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

# ==============================================================================
# UTILIDADES DE BARAJA DE CARTAS
# ==============================================================================
func _build_shuffled_deck() -> Array[Dictionary]:
	var d: Array[Dictionary] = []
	for s_idx in range(SUITS.size()):
		for r_idx in range(RANKS.size()):
			d.append({
				"rank": RANKS[r_idx],
				"suit": SUITS[s_idx],
				"val": r_idx + 2 # 2..14 (14 = As)
			})
	d.shuffle()
	return d

func _format_cards(cards: Array[Dictionary], hide_all: bool = false, hide_second: bool = false) -> String:
	if cards.is_empty():
		return "—"
	var parts: Array[String] = []
	for i in range(cards.size()):
		if hide_all or (hide_second and i == 1):
			parts.append("[🂠]")
		else:
			var c: Dictionary = cards[i]
			parts.append("[%s%s]" % [str(c["rank"]), str(c["suit"])])
	return " ".join(parts)

# ==============================================================================
# 1. PÓKER TEXAS HOLD'EM (CONTRA 2 NPCS DE LA ALDEA)
# ==============================================================================
func _render_poker_ui() -> void:
	_refresh_header()
	_clear_actions()
	table_title_lbl.text = "♠️ Póker Texas Hold'em  |  Bote en la Mesa: 💰 %d Oro" % poker_pot

	if poker_stage == PokerStage.IDLE:
		cards_display_lbl.text = "Cartas Comunitarias: [ — ] [ — ] [ — ] [ — ] [ — ]\n\nTu Mano: [ — ] [ — ]"
		table_state_lbl.text = "%s: Listo  |  %s: Listo" % [_get_npc_name(0), _get_npc_name(1)]
		_add_action_btn("[1] Repartir Nueva Mano (Ante: 5 Oro)", _start_poker_hand, _get_player_gold() < 5)
		return

	var show_npcs := (poker_stage == PokerStage.SHOWDOWN)
	var comm_str := _format_cards(poker_community)
	while poker_community.size() < 5 and comm_str.split("[").size() - 1 < 5:
		comm_str += " [ · ]"

	var npc1_status := "Retirado (Fold)" if poker_npc1_folded else _format_cards(poker_npc1_hand, not show_npcs)
	var npc2_status := "Retirado (Fold)" if poker_npc2_folded else _format_cards(poker_npc2_hand, not show_npcs)

	cards_display_lbl.text = "Mesa Comunitaria:  %s\n\nTu Mano:  %s" % [comm_str, _format_cards(poker_player_hand)]
	table_state_lbl.text = "👤 %s: %s    |    👤 %s: %s" % [_get_npc_name(0), npc1_status, _get_npc_name(1), npc2_status]

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
	poker_pot = 15 # 5 tuyos + 5 de cada uno de los 2 NPCs
	poker_deck = _build_shuffled_deck()
	poker_community.clear()
	poker_player_hand = [poker_deck.pop_back(), poker_deck.pop_back()]
	poker_npc1_hand = [poker_deck.pop_back(), poker_deck.pop_back()]
	poker_npc2_hand = [poker_deck.pop_back(), poker_deck.pop_back()]
	poker_npc1_folded = false
	poker_npc2_folded = false
	poker_stage = PokerStage.PRE_FLOP
	status_msg_lbl.text = "Ronda Pre-Flop: Cartas repartidas. Bote inicial: 15 Oro."
	_render_poker_ui()

func _poker_player_bet(raise_amt: int) -> void:
	if raise_amt > 0:
		if _get_player_gold() < raise_amt:
			return
		_add_player_gold(-raise_amt)
		poker_pot += raise_amt

		# Reacción de los NPCs a tu subida de apuesta
		if not poker_npc1_folded:
			if _should_npc_call(poker_npc1_hand, poker_community, raise_amt):
				poker_pot += raise_amt
			else:
				poker_npc1_folded = true
		if not poker_npc2_folded:
			if _should_npc_call(poker_npc2_hand, poker_community, raise_amt):
				poker_pot += raise_amt
			else:
				poker_npc2_folded = true

	# Si ambos NPCs se retiraron, ganas el bote inmediatamente
	if poker_npc1_folded and poker_npc2_folded:
		_add_player_gold(poker_pot)
		status_msg_lbl.text = "🏆 ¡Ambos rivales se retiraron! Te llevas el bote de %d Oro." % poker_pot
		poker_stage = PokerStage.SHOWDOWN
		_reward_social_with_table_npcs(2)
		_render_poker_ui()
		return

	match poker_stage:
		PokerStage.PRE_FLOP:
			poker_community.append(poker_deck.pop_back())
			poker_community.append(poker_deck.pop_back())
			poker_community.append(poker_deck.pop_back())
			poker_stage = PokerStage.FLOP
			status_msg_lbl.text = "Flop (3 cartas en mesa). ¿Pasas o subes la apuesta?"
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
			_resolve_poker_showdown()
	_render_poker_ui()

func _poker_player_fold() -> void:
	poker_stage = PokerStage.SHOWDOWN
	var winner_npc := _get_npc_name(0) if not poker_npc1_folded else _get_npc_name(1)
	status_msg_lbl.text = "🏳️ Te retiraste de la mano. %s se lleva el bote de %d Oro." % [winner_npc, poker_pot]
	_reward_social_with_table_npcs(3)
	_render_poker_ui()

func _should_npc_call(hole: Array[Dictionary], comm: Array[Dictionary], raise_amt: int) -> bool:
	var combined: Array[Dictionary] = []
	combined.append_array(hole)
	combined.append_array(comm)
	var eval_res: Dictionary = _evaluate_cards_strength(combined)
	var cat: int = int(eval_res["category"])
	# Si tiene pareja o mejor (cat >= 1), o carta alta muy buena, o farolea (45%), iguala
	if cat >= 1:
		return true
	if int(hole[0]["val"]) >= 12 or int(hole[1]["val"]) >= 12:
		return randf() < 0.80
	return randf() < (0.45 if raise_amt <= 5 else 0.25)

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

	var n2_score: int = -1
	var n2_name := "Retirado"
	if not poker_npc2_folded:
		var n2_all: Array[Dictionary] = []
		n2_all.append_array(poker_npc2_hand)
		n2_all.append_array(poker_community)
		var n2_eval: Dictionary = _evaluate_cards_strength(n2_all)
		n2_score = int(n2_eval["score"])
		n2_name = str(n2_eval["name"])

	var p_score: int = int(p_eval["score"])
	var p_hand_name: String = str(p_eval["name"])

	_reward_social_with_table_npcs(3)

	if p_score >= n1_score and p_score >= n2_score:
		_add_player_gold(poker_pot)
		status_msg_lbl.text = "🏆 ¡GANASTE EL BOTE (+%d Oro) con %s! (Rivales: %s | %s)" % [poker_pot, p_hand_name, n1_name, n2_name]
	elif n1_score >= n2_score:
		status_msg_lbl.text = "💸 %s gana el bote (%d Oro) con %s. (Tu mano: %s)" % [_get_npc_name(0), poker_pot, n1_name, p_hand_name]
	else:
		status_msg_lbl.text = "💸 %s gana el bote (%d Oro) con %s. (Tu mano: %s)" % [_get_npc_name(1), poker_pot, n2_name, p_hand_name]

## Evaluador de fuerza de mano de Póker (devuelve categoría 0..8, puntuación de desempate y nombre en español)
func _evaluate_cards_strength(cards: Array[Dictionary]) -> Dictionary:
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

	var is_flush := false
	for s_key in suit_counts.keys():
		if int(suit_counts[s_key]) >= 5:
			is_flush = true
			break

	var is_straight := false
	var straight_high: int = 0
	if vals.size() >= 5:
		for i in range(vals.size() - 4):
			if vals[i] - vals[i + 4] == 4:
				is_straight = true
				straight_high = vals[i]
				break
		# Escalera baja A-2-3-4-5
		if not is_straight and vals.has(14) and vals.has(5) and vals.has(4) and vals.has(3) and vals.has(2):
			is_straight = true
			straight_high = 5

	var four_val: int = 0
	var three_val: int = 0
	var pairs: Array[int] = []
	for v_key in vals:
		var cnt: int = int(counts[v_key])
		if cnt == 4 and four_val == 0:
			four_val = v_key
		elif cnt == 3 and three_val == 0:
			three_val = v_key
		elif cnt >= 2:
			pairs.append(v_key)

	var high_card: int = vals[0] if not vals.is_empty() else 2

	if is_straight and is_flush:
		return {"category": 8, "score": 80000 + straight_high, "name": "Escalera de Color"}
	if four_val > 0:
		return {"category": 7, "score": 70000 + four_val * 100 + high_card, "name": "Póker"}
	if three_val > 0 and not pairs.is_empty():
		return {"category": 6, "score": 60000 + three_val * 100 + pairs[0], "name": "Full House"}
	if is_flush:
		return {"category": 5, "score": 50000 + high_card, "name": "Color (Flush)"}
	if is_straight:
		return {"category": 4, "score": 40000 + straight_high, "name": "Escalera"}
	if three_val > 0:
		return {"category": 3, "score": 30000 + three_val * 100 + high_card, "name": "Trío"}
	if pairs.size() >= 2:
		return {"category": 2, "score": 20000 + pairs[0] * 100 + pairs[1] * 10, "name": "Doble Pareja"}
	if pairs.size() == 1:
		return {"category": 1, "score": 10000 + pairs[0] * 100 + high_card, "name": "Pareja"}
	return {"category": 0, "score": high_card, "name": "Carta Alta"}

# ==============================================================================
# 2. BLACKJACK (21 CONTRA LA BANCA DE LA TABERNA)
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
	table_title_lbl.text = "🃏 Blackjack 21  |  Apuesta Actual: 💰 %d Oro" % (bj_bet if bj_stage != BJStage.IDLE else 0)

	if bj_stage == BJStage.IDLE:
		cards_display_lbl.text = "Mano de la Banca (Marta):  [ — ] [ — ]\n\nTu Mano:  [ — ] [ — ]"
		table_state_lbl.text = "Elige cuánto Oro quieres apostar en esta mano:"
		_add_action_btn("[1] Apostar 5 Oro", func(): _start_blackjack(5), _get_player_gold() < 5)
		_add_action_btn("[2] Apostar 10 Oro", func(): _start_blackjack(10), _get_player_gold() < 10)
		_add_action_btn("[3] Apostar 25 Oro", func(): _start_blackjack(25), _get_player_gold() < 25)
		return

	var hide_dealer_hole := (bj_stage == BJStage.PLAYER_TURN)
	var p_tot: int = _calc_bj_total(bj_player_hand)
	var d_tot_str: String = "?" if hide_dealer_hole else str(_calc_bj_total(bj_dealer_hand))

	cards_display_lbl.text = "Banca (Marta) [%s pts]:  %s\n\nTu Mano [%d pts]:  %s" % [
		d_tot_str,
		_format_cards(bj_dealer_hand, false, hide_dealer_hole),
		p_tot,
		_format_cards(bj_player_hand)
	]
	table_state_lbl.text = "El As vale 11 o 1 automáticamente. La banca pide hasta 17."

	if bj_stage == BJStage.PLAYER_TURN:
		_add_action_btn("[1] Pedir Carta (Hit)", _bj_hit)
		_add_action_btn("[2] Plantarse (Stand)", _bj_stand)
		var can_double: bool = (bj_player_hand.size() == 2 and _get_player_gold() >= bj_bet)
		_add_action_btn("[3] Doblar Apuesta (+%d Oro)" % bj_bet, _bj_double, not can_double)
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

	if _calc_bj_total(bj_player_hand) == 21:
		_bj_stand()
		return

	status_msg_lbl.text = "Mano repartida. ¿Pides carta [1] o te plantas [2]?"
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
	if bj_stage != BJStage.PLAYER_TURN or _get_player_gold() < bj_bet:
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
# 3. LA RULETA DE LA POSADA (NÚMEROS 0 AL 12)
# ==============================================================================
func _format_roulette_number(num: int) -> String:
	if num == 0:
		return "🟢 0 (VERDE)"
	elif RED_NUMBERS.has(num):
		return "🔴 %d (ROJO)" % num
	return "⚫ %d (NEGRO)" % num

func _render_roulette_ui() -> void:
	_refresh_header()
	_clear_actions()
	var chip: int = roulette_chip_values[roulette_chip_idx]
	table_title_lbl.text = "🎡 Ruleta de la Posada  |  Ficha Actual: 💰 %d Oro ([Q] Cambiar Ficha)  |  N.º Exacto: #%d" % [chip, roulette_chosen_num]

	cards_display_lbl.text = "🟢[0]  🔴[1]  ⚫[2]  🔴[3]  ⚫[4]  🔴[5]  ⚫[6]  🔴[7]  ⚫[8]  🔴[9]  ⚫[10]  🔴[11]  ⚫[12]\n\nÚltimo resultado:  %s" % _format_roulette_number(roulette_current_ball)
	table_state_lbl.text = "Rojo/Negro y Par/Impar pagan x2  |  Cero Verde [0] y Número Exacto (#%d) pagan x10" % roulette_chosen_num

	var no_gold: bool = (_get_player_gold() < chip) or roulette_spinning
	_add_action_btn("[1] 🔴 Rojo (x2)", func(): _spin_roulette("red", chip), no_gold)
	_add_action_btn("[2] ⚫ Negro (x2)", func(): _spin_roulette("black", chip), no_gold)
	_add_action_btn("[3] Par (x2)", func(): _spin_roulette("even", chip), no_gold)
	_add_action_btn("[4] Impar (x2)", func(): _spin_roulette("odd", chip), no_gold)
	_add_action_btn("[5] 🟢 Cero '0' (x10)", func(): _spin_roulette("zero", chip), no_gold)
	_add_action_btn("[6] 🎯 N.º #%d (x10)" % roulette_chosen_num, func(): _spin_roulette("exact", chip), no_gold)
	_add_action_btn("[7] Cambiar N.º (#%d)" % roulette_chosen_num, func():
		roulette_chosen_num = (roulette_chosen_num % 12) + 1
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
	status_msg_lbl.text = "🎡 ¡No va más! Girando la ruleta con %d Oro..." % amount
	_render_roulette_ui()

func _finish_roulette_spin() -> void:
	roulette_current_ball = randi() % 13 # 0..12
	var res_num: int = roulette_current_ball
	var won := false
	var mult: int = 2

	match roulette_bet_type:
		"red":
			won = RED_NUMBERS.has(res_num)
			mult = 2
		"black":
			won = (res_num > 0 and not RED_NUMBERS.has(res_num))
			mult = 2
		"even":
			won = (res_num > 0 and res_num % 2 == 0)
			mult = 2
		"odd":
			won = (res_num > 0 and res_num % 2 == 1)
			mult = 2
		"zero":
			won = (res_num == 0)
			mult = 10
		"exact":
			won = (res_num == roulette_chosen_num)
			mult = 10

	_reward_social_with_table_npcs(1)

	if won:
		var prize: int = roulette_bet_amt * mult
		_add_player_gold(prize)
		status_msg_lbl.text = "🎉 ¡Salió %s! ¡Ganaste +%d Oro (x%d)!" % [_format_roulette_number(res_num), prize, mult]
	else:
		status_msg_lbl.text = "💨 Salió %s. No hubo suerte esta tirada." % _format_roulette_number(res_num)

	_render_roulette_ui()
