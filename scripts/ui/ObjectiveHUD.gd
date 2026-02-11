extends Control

@onready var objectives_container: VBoxContainer = $ObjectivesContainer

# Preload a simple label for objectives, or we can create it in code
var objective_label_settings: LabelSettings

func _ready() -> void:
    # Setup styling
    objective_label_settings = LabelSettings.new()
    objective_label_settings.font_size = 18
    objective_label_settings.outline_size = 4
    objective_label_settings.outline_color = Color.BLACK
    
    # Connect signals
    if ObjectiveManager:
        ObjectiveManager.objective_added.connect(_on_objective_added)
        ObjectiveManager.objective_completed.connect(_on_objective_completed)
        
        # Load existing
        for obj in ObjectiveManager.active_objectives:
            _on_objective_added(obj)
            if obj.is_completed:
                _on_objective_completed(obj)

func _on_objective_added(objective: Objective) -> void:
    var label = Label.new()
    label.text = "- " + objective.description
    label.name = objective.id # Use ID as node name for easy lookup
    label.label_settings = objective_label_settings
    label.set_meta("objective_id", objective.id)
    
    objectives_container.add_child(label)
    
    # Animate in
    label.modulate.a = 0.0
    var tween = create_tween()
    tween.tween_property(label, "modulate:a", 1.0, 0.5)

func _on_objective_completed(objective: Objective) -> void:
    var label = objectives_container.get_node_or_null(objective.id)
    if label:
        label.modulate = Color.GREEN
        label.text = "✔ " + objective.description
        
        # Optional: Fade out after a delay
        var tween = create_tween()
        tween.tween_interval(5.0)
        tween.tween_property(label, "modulate:a", 0.0, 1.0)
        tween.tween_callback(label.queue_free)
