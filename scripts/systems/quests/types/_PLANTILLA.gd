@tool
extends "res://scripts/systems/quests/QuestType.gd"

## PLANTILLA (no está registrada). Copia este archivo a `types/QuestNombre.gd`, rellénalo
## y añade su ruta a `QuestRegistry.TYPE_SCRIPTS`. Guía en `docs/MISIONES.md`.
## «Título de ejemplo»: qué le pasa al vecino y qué te pide.

func _init() -> void:
	id = "ejemplo" # Único y estable: se guarda en las partidas
	trigger = "daily" # "daily" o "event"
	priority = 50
	gold = 20
	affinity = 8
	needs_alive_target = true

## Condiciones para que `giver` lo pida hoy. Devuelve {} si no.
func find_daily_offer(_vm: VillageManager, _giver: VillageNPC, _npcs: Array, _ctx: Dictionary) -> Dictionary:
	return {}

func texts(off: Dictionary) -> Dictionary:
	var tn: String = str(off.get("target_name", ""))
	return {
		"title": "Título con %s" % tn,
		"ask": "«Lo que dice el vecino al pedírtelo.»",
		"desc": "Qué tiene que hacer el jugador (texto del panel L).",
	}

func is_done(_vm: VillageManager, _q: Dictionary) -> bool:
	return false

func progress_hint(_q: Dictionary) -> String:
	return "«¿Cómo va eso?»"
