extends CharacterBody2D

@export var dialogue_manager: Node
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@export var enemy_ai: Node # Using generic Node, will cast to EnemyAI if needed
@export var hostility_threshold: int = 2

enum State { NEUTRAL, FRIENDLY, ANGRY, ATTACK }
var current_state: State = State.NEUTRAL
var hostility_meter: int = 0

func _physics_process(_delta: float) -> void:
	if current_state == State.ATTACK and enemy_ai:
		# If AI is active, let it control movement (it sets parent.velocity)
		move_and_slide()
	else:
		# Normal NPC physics (gravity/idle)
		move_and_slide()

func _ready() -> void:
	anim.play("idle")
	if dialogue_manager and dialogue_manager.has_signal("dialogue_finished"):
		if not dialogue_manager.dialogue_finished.is_connected(_on_dialogue_finished):
			dialogue_manager.dialogue_finished.connect(_on_dialogue_finished)

	if enemy_ai:
		# Disable AI by default (Neutral state)
		enemy_ai.set_process(false)
		enemy_ai.set_physics_process(false)
		
		if enemy_ai.has_signal("attack_triggered"):
			enemy_ai.attack_triggered.connect(_on_enemy_ai_attack)
		
	_setup_health()

# --- Combat / Health ---
@onready var health_comp: HealthComponent = HealthComponent.new()

func _setup_health() -> void:
	health_comp.name = "HealthComponent"
	health_comp.max_health = 50.0
	health_comp.current_health = 50.0
	add_child(health_comp)
	health_comp.died.connect(_on_died)
	health_comp.health_changed.connect(_on_health_changed)

func take_damage(data: DamageData) -> void:
	if current_state != State.ATTACK:
		# Aggro on first hit!
		hostility_meter = hostility_threshold + 5
		_on_dialogue_finished("bad_end") # Force hostile state logic

	health_comp.take_damage(data)

func _on_health_changed(current_health: float, _max_health: float) -> void:
	print("NPC Health changed to: ", current_health)
	# Optional: Flash red or play hurt anim

func _on_died() -> void:
	print("NPC Died!")
	set_physics_process(false)
	set_process(false)
	
	if enemy_ai:
		enemy_ai.set_process(false)
		enemy_ai.set_physics_process(false)
	
	# Disable collisions to prevent further hits
	$InteractArea/NpcInteractCollision.set_deferred("disabled", true)
	$"cuerpo solido".set_deferred("disabled", true)
	
	# Visual feedback since we don't have a "dead" animation yet
	anim.modulate = Color(0.5, 0.5, 0.5, 0.5) # Fade out / Grey
	
	# Remove after a short delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_dialogue_finished(last_id: String) -> void:
	match last_id:
		"nice_end":
			current_state = State.FRIENDLY
			hostility_meter = max(0, hostility_meter - 1) # Being nice reduces hostility
			print("NPC is now FRIENDLY")
			
		"bad_end", "neutral_end", "fight":
			current_state = State.ANGRY
			hostility_meter += 1
			print("NPC is now ANGRY. Hostility: ", hostility_meter)
			
			if hostility_meter >= hostility_threshold:
				_trigger_attack()

func _trigger_attack() -> void:
	current_state = State.ATTACK
	print("NPC is ATTACKING!")
	
	if enemy_ai:
		# Enable AI
		enemy_ai.set_process(true)
		enemy_ai.set_physics_process(true)
		
		# Force Aggro on Player
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			if enemy_ai.has_method("notify_damage"):
				enemy_ai.notify_damage(players[0])
			elif enemy_ai.has_method("_change_state"):
				enemy_ai.call("notify_damage", players[0]) 
	else:
		push_warning("NPC: No EnemyAI assigned, cannot attack properly.")

func _on_enemy_ai_attack(damage_data: DamageData) -> void:
	print("NPC Attacking Player!")
	if enemy_ai and "target" in enemy_ai and enemy_ai.target:
		if enemy_ai.target.has_method("take_damage"):
			damage_data.source = self
			enemy_ai.target.take_damage(damage_data)

func interact(_player: Node) -> void:
	if current_state == State.ATTACK:
		print("NPC is hostile and refuses to talk!")
		return
		
	print("NPC: interact | State: ", current_state)
	
	var dialogue_data = {}
	
	match current_state:
		State.NEUTRAL:
			dialogue_data = _get_neutral_dialogue()
		State.FRIENDLY:
			dialogue_data = _get_friendly_dialogue()
		State.ANGRY:
			dialogue_data = _get_angry_dialogue()

	if dialogue_manager:
		dialogue_manager.call("start_dialogue", dialogue_data, "start")
	else:
		push_warning("NPC: dialogue_manager no asignado")

func _get_neutral_dialogue() -> Dictionary:
	return {
		"start": {
			"text": "Hey you! You look lost.",
			"choices": [
				{"label": "Can you help me?", "next": "nice_branch"},
				{"label": "Get out of my way.", "next": "rude_branch"},
				{"label": "...", "next": "END"}
			]
		},
		"nice_branch": {
			"text": "Sure. I saw a key hidden behind the big rock to the east.",
			"choices": [
				{"label": "Thanks!", "next": "nice_end"},
				{"label": "Is that all?", "next": "neutral_end"}
			]
		},
		"nice_end": {"text": "Good luck.", "choices": [{"label": "[End]", "next": "END"}]},
		"neutral_end": {"text": "Don't push it.", "choices": [{"label": "[End]", "next": "END"}]},
		"rude_branch": {
			"text": "Rude! I'm not telling you anything then.",
			"choices": [{"label": "Whatever.", "next": "bad_end"}, {"label": "Sorry!", "next": "start"}]
		},
		"bad_end": {"text": "Hmph!", "choices": [{"label": "[End]", "next": "END"}]}
	}

func _get_friendly_dialogue() -> Dictionary:
	return {
		"start": {
			"text": "Oh, hello again friend! Did you find that key?",
			"choices": [
				{"label": "Not yet.", "next": "encouragement"},
				{"label": "Yes, thanks!", "next": "congrats"}
			]
		},
		"encouragement": {"text": "Keep looking near the rocks!", "choices": [{"label": "Okay.", "next": "END"}]},
		"congrats": {"text": "Great job! Be careful out there.", "choices": [{"label": "Bye!", "next": "END"}]}
	}

func _get_angry_dialogue() -> Dictionary:
	return {
		"start": {
			"text": "You again? I told you to get lost.",
			"choices": [
				{"label": "I'm sorry about before.", "next": "forgive"},
				{"label": "Make me.", "next": "fight"}
			]
		},
		"forgive": {
			"text": "Review: Fine... just don't be rude again.", 
			"choices": [{"label": "I won't.", "next": "nice_end"}] # Resets to Friendly via nice_end logic!
		},
		"fight": {"text": "I'm ignoring you!", "choices": [{"label": "...", "next": "END"}]}
	}
