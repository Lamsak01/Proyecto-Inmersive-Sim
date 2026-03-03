extends Area2D
class_name DetectionArea

signal targets_changed(targets: Array)

var targets_in_range: Array[Node2D] = []

func _ready() -> void:
    # Typical detection mask (e.g. layer 2 where player is)
    collision_layer = 0
    collision_mask = 2 # Assuming layer 2 is Player
    
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and not targets_in_range.has(body):
        targets_in_range.append(body)
        targets_changed.emit(targets_in_range)

func _on_body_exited(body: Node2D) -> void:
    if targets_in_range.has(body):
        targets_in_range.erase(body)
        targets_changed.emit(targets_in_range)

func get_closest_target(global_pos: Vector2) -> Node2D:
    if targets_in_range.is_empty():
        return null
        
    var closest = null
    var min_dist = INF
    
    # We clean up any nulls/freed nodes just in case
    var valid_targets: Array[Node2D] = []
    
    for t in targets_in_range:
        if is_instance_valid(t):
            valid_targets.append(t)
            var d = global_pos.distance_squared_to(t.global_position)
            if d < min_dist:
                min_dist = d
                closest = t
                
    targets_in_range = valid_targets
    return closest
