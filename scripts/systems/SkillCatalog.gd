extends RefCounted

## Catálogo de habilidades RPG del Jugador (datos puros, sin estado).
## Cada habilidad sube de nivel con experiencia (XP) ganada al practicarla. El bono por nivel lo calcula Player.get_skill_bonus().

const MAX_LEVEL: int = 10
const BONUS_PER_LEVEL: float = 0.05

const SKILLS: Dictionary = {
	"charisma": {"name": "Carisma", "icon": "🗣️", "desc": "Mejora tu persuasión: más afinidad al charlar y mejores opciones en interrogatorios.", "xp_hint": "Charlar con vecinos y defenderte en interrogatorios."},
	"hunting": {"name": "Caza", "icon": "🏹", "desc": "Mejora el rendimiento de tus piezas de caza y el desollado.", "xp_hint": "Desollar animales salvajes."},
	"crafting": {"name": "Elaboración", "icon": "⚒️", "desc": "Maestría en forja y mejora de herramientas.", "xp_hint": "Fundir acero y mejorar herramientas en la herrería."},
	"cooking": {"name": "Cocina", "icon": "🍲", "desc": "Probabilidad de obtener una ración extra al cocinar.", "xp_hint": "Cocinar en la cacerola del campamento."},
	"alchemy": {"name": "Alquimia", "icon": "🧪", "desc": "Dominio de elixires y somníferos.", "xp_hint": "Administrar somníferos y tónicos."},
	"animals": {"name": "Trato con Animales", "icon": "🐾", "desc": "Tus mascotas ganan lealtad más rápido.", "xp_hint": "Alimentar y cuidar mascotas."},
	"stealth": {"name": "Sigilo", "icon": "🥷", "desc": "Menos probabilidad de ser detectado y mejor hurto.", "xp_hint": "Aturdir en sigilo y hurtar bolsillos."},
	"medicine": {"name": "Medicina", "icon": "🩺", "desc": "Mejores tratamientos de heridas.", "xp_hint": "Tratar y lavar tus heridas."},
}

static func skill_ids() -> Array:
	return SKILLS.keys()

static func skill_name(skill_id: String) -> String:
	return str(SKILLS.get(skill_id, {}).get("name", skill_id.capitalize()))

static func skill_icon(skill_id: String) -> String:
	return str(SKILLS.get(skill_id, {}).get("icon", "⭐"))

## XP necesaria para pasar del nivel `level` al siguiente.
static func xp_for_next(level: int) -> int:
	return 30 + level * 25
