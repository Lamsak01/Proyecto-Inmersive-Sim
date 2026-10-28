extends Area2D
class_name ConductiveArea

@export var is_wet: bool = true
@export var damage_per_tick: float = 3.0
@export var tick_rate: float = 0.5

var is_energized: bool = false
var power_sources: Array[Node2D] = []
var internal_timer_node: Timer = null

@onready var hurtbox: Hurtbox = $Hurtbox if has_node("Hurtbox") else null

func _ready() -> void:
	# Monitor overlapping areas for power sources
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	if not hurtbox:
		# Dynamically create Hurtbox if not provided in scene
		hurtbox = Hurtbox.new()
		hurtbox.name = "Hurtbox"
		hurtbox.collision_layer = 4 # Default enemy/player hit layer
		hurtbox.collision_mask = 0
		
		# Copy our collision shape to the hurtbox
		for child in get_children():
			if child is CollisionShape2D:
				var shape_dup = child.duplicate()
				hurtbox.add_child(shape_dup)
				
		add_child(hurtbox)
		
	# Setup damage tick timer
	internal_timer_node = Timer.new()
	internal_timer_node.wait_time = tick_rate
	internal_timer_node.autostart = false
	internal_timer_node.timeout.connect(_apply_electrical_damage)
	add_child(internal_timer_node)

func _physics_process(_delta: float) -> void:
	# Check if we are currently energized by checking our tracked sources
	var was_energized = is_energized
	is_energized = false
	
	# Clean up invalid sources
	var valid_sources = []
	for source in power_sources:
		if is_instance_valid(source):
			valid_sources.append(source)
			# Generators and Cables have 'is_powered()' or 'enabled'
			if is_wet:
				if source.has_method("is_powered") and source.is_powered():
					is_energized = true
				elif "enabled" in source and source.enabled:
					is_energized = true
				
	power_sources = valid_sources
	
	# State changed
	if is_energized != was_energized:
		if is_energized:
			modulate = Color(0.5, 0.8, 1.0, 1.5) # Glowing blue/white
			if internal_timer_node.is_stopped():
				internal_timer_node.start()
		else:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
			internal_timer_node.stop()
			
func _apply_electrical_damage() -> void:
	if not is_energized or not hurtbox: return
	
	# Find all entities currently inside our area and zap them
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.has_method("take_damage"):
			var data = DamageData.new()
			data.amount = damage_per_tick
			data.type = CombatConstants.DamageType.ELECTRIC
			data.source = self
			body.take_damage(data)

func _on_area_entered(area: Area2D) -> void:
	# Detectar fuentes de poder via grupos o duck‑typing (evita errores de tipo estático)
	var candidates: Array = [area, area.get_parent()]
	for candidate in candidates:
		if not is_instance_valid(candidate): continue
		if candidate in power_sources: continue
		# Aceptar si pertenece a grupo 'power_nodes', o tiene los métodos característicos
		if candidate.is_in_group("power_nodes") \
			or candidate.has_method("is_powered") \
			or "enabled" in candidate \
			or (candidate is Node and candidate.name.contains("Cable")):
				power_sources.append(candidate)
				break

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent in power_sources:
		power_sources.erase(parent)
	elif area in power_sources:
		power_sources.erase(area)
