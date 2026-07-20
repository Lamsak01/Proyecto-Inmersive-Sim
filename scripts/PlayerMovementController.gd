extends Node
class_name PlayerMovementController

@export var max_walk_speed: float = 120.0
@export var sprint_speed: float = 200.0
@export var stealth_speed: float = 60.0
@export var push_force: float = 150.0

var is_sprinting: bool = false
var is_stealthing: bool = false
var current_speed: float = 120.0

@onready var player: CharacterBody2D = get_parent()
@onready var anim: AnimatedSprite2D = $"../Animations"
@onready var stamina_comp: StaminaComponent = $"../StaminaComponent"
@onready var dialogue_manager: Node = player.get("dialogue_manager")

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player) or not is_instance_valid(anim):
        return
        
    # Block movement if dialogue active
    if dialogue_manager and dialogue_manager.has_method("is_active") and dialogue_manager.call("is_active"):
        player.velocity = Vector2.ZERO
        _play_idle()
        player.move_and_slide()
        return
        
    # Check bounds or stun
    if player.has_method("is_stunned") and player.is_stunned():
        player.velocity = player.velocity.move_toward(Vector2.ZERO, 300.0 * delta)
        player.move_and_slide()
        return
        
    _handle_input(delta)
    player.move_and_slide()
    _handle_push()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_C:
            is_stealthing = !is_stealthing

func _handle_input(delta: float) -> void:
    var is_sprint_pressed = Input.is_action_pressed("sprint")
    var input := Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    )
    
    if is_instance_valid(stamina_comp):
        stamina_comp.is_input_blocking = is_sprint_pressed

    if is_stealthing:
        is_sprinting = false
        current_speed = stealth_speed
        player.modulate.a = 0.6
    else:
        player.modulate.a = 1.0
        if is_sprint_pressed and input != Vector2.ZERO and is_instance_valid(stamina_comp):
            if stamina_comp.use_stamina(stamina_comp.sprint_cost * delta):
                is_sprinting = true
                current_speed = sprint_speed
                anim.speed_scale = 1.5
            else:
                is_sprinting = false
                current_speed = max_walk_speed
                anim.speed_scale = 1.0
        else:
            is_sprinting = false
            current_speed = max_walk_speed
            anim.speed_scale = 1.0
            
    # Weakness override
    if player.is_weak:
        current_speed = max_walk_speed * 0.5
        
    if input != Vector2.ZERO:
        player.velocity = input.normalized() * current_speed
        _play_walk(input)
    else:
        player.velocity = Vector2.ZERO
        _play_idle()

func _handle_push() -> void:
    for i in player.get_slide_collision_count():
        var c = player.get_slide_collision(i)
        var collider = c.get_collider()
        if collider is CharacterBody2D and "weight" in collider and collider.has_method("apply_push"):
            if player.weight > collider.weight:
                var push_dir = (collider.global_position - player.global_position).normalized()
                collider.apply_push(push_dir * push_force)

func _play_walk(dir: Vector2) -> void:
    if abs(dir.x) > abs(dir.y):
        if dir.x > 0:
            anim.play("walk_right")
            player.last_dir = "right"
        else:
            anim.play("walk_left")
            player.last_dir = "left"
    else:
        if dir.y > 0:
            anim.play("walk_down")
            player.last_dir = "down"
        else:
            anim.play("walk_up")
            player.last_dir = "up"

func _play_idle() -> void:
    var dir = player.last_dir
    if dir != null:
        anim.play("idle_" + dir)
