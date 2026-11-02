@tool
extends RefCounted

## Catálogo de tipos de misión secundaria de vecinos. Para añadir un tipo: crea su archivo en `types/`
## (copia `types/_PLANTILLA.gd`) y añade su ruta aquí. Guía en `docs/MISIONES.md`.

const TYPE_SCRIPTS: Array[String] = [
	"res://scripts/systems/quests/types/QuestPeace.gd",
	"res://scripts/systems/quests/types/QuestSlander.gd",
	"res://scripts/systems/quests/types/QuestOpinion.gd",
	"res://scripts/systems/quests/types/QuestJustice.gd",
	"res://scripts/systems/quests/types/QuestRumor.gd",
]

static var _types: Dictionary = {}
static var _daily: Array = []

static func _ensure() -> void:
	if not _types.is_empty():
		return
	for path in TYPE_SCRIPTS:
		var t = (load(path) as GDScript).new()
		assert(str(t.id) != "" and not _types.has(t.id), "QuestRegistry: id vacío o repetido en " + path)
		_types[t.id] = t
		if t.trigger == "daily":
			_daily.append(t)
	_daily.sort_custom(func(a, b) -> bool: return int(a.priority) < int(b.priority))

static func get_type(type_id: String):
	_ensure()
	return _types.get(type_id, null)

static func all_types() -> Array:
	_ensure()
	return _types.values()

## Tipos que busca el sorteo diario, en orden de prioridad.
static func daily_types() -> Array:
	_ensure()
	return _daily
