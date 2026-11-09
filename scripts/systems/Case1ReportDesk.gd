extends Node

## Caso I (Claude Code, 2026-11-09): «hablante» de la bandeja de informes de la comisaría. La ventana de diálogo del
## juego necesita un nodo con nombre y on_dialogue_action(); este lo reenvía a VillageCase1.

var npc_name: String = "Informe del Caso I"
var npc_role: String = "Bandeja del alguacil mayor"
var vm = null


func on_dialogue_action(action_id: String) -> void:
	load("res://scripts/systems/VillageCase1.gd").on_report_action(vm, action_id)
