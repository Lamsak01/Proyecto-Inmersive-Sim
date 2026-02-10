extends Node

signal objective_added(objective: Objective)
signal objective_completed(objective: Objective)
signal all_objectives_cleared

var active_objectives: Array[Objective] = []

func add_objective(objective: Objective) -> void:
	if not objective: return
	
	# Prevent duplicates by ID
	for obj in active_objectives:
		if obj.id == objective.id:
			return
			
	active_objectives.append(objective)
	# Connect to the signal but check if already connected to avoid errors
	if not objective.completed.is_connected(_on_objective_completed.bind(objective)):
		objective.completed.connect(_on_objective_completed.bind(objective))
	
	objective_added.emit(objective)
	print("Objective Added: ", objective.description)

func get_objective(id: String) -> Objective:
	for obj in active_objectives:
		if obj.id == id:
			return obj
	return null

func complete_objective(id: String) -> void:
	var obj = get_objective(id)
	if obj and not obj.is_completed:
		obj.complete()

func _on_objective_completed(objective: Objective) -> void:
	print("Objective Completed: ", objective.description)
	objective_completed.emit(objective)
