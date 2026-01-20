extends CharacterBody2D

@export var dialogue_manager: Node
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.play("idle")


func interact(_player: Node) -> void:
	print("NPC: interact")

	var g := {
		"start": {
			
			"text": "Hola. ¿Qué quieres?",
			"choices": [
				{"label": "¿Dónde estoy?", "next": "where"},
				{"label": "¿Qué hago aquí?", "next": "what"},
				{"label": "Nada.", "next": "END"}
			]
		},
		"where": {
			"text": "Estás la zona de prueba.",
			"choices": [
				{"label": "Volver", "next": "start"},
				{"label": "Cerrar", "next": "END"}
			]
		},
		"what": {
			"text": "Encuentra la llave y abre la puerta, es lo unico que puedes hacer por ahora.",
			"choices": [
				{"label": "Volver", "next": "start"},
				{"label": "Cerrar", "next": "END"}
			]
		}
	}

	if dialogue_manager:
		dialogue_manager.call("start_dialogue", g, "start")
		print("NPC: starting dialogue, manager =", dialogue_manager)
	else:
		push_warning("NPC: dialogue_manager no asignado en el Inspector")
