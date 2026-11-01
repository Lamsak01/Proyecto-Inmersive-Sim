extends RefCounted

## Catálogo de habilidades RPG del Jugador (datos puros, sin estado).
## Cada habilidad sube de nivel con experiencia (XP) ganada al practicarla. El bono por nivel lo calcula Player.get_skill_bonus().

const MAX_LEVEL: int = 10
const BONUS_PER_LEVEL: float = 0.05

const SKILLS: Dictionary = {
	"charisma": {"name": "Carisma", "icon": "🗣️", "desc": "Más probabilidad de convencer o sobornar testigos, pedir coartadas con menos relación y lograr clemencia en juicios.", "xp_hint": "Charlar con vecinos y defenderte en interrogatorios."},
	"hunting": {"name": "Caza", "icon": "🏹", "desc": "Tus pruebas de caza ayudan algo más a convencer a testigos. (Más efectos próximamente)", "xp_hint": "Desollar animales salvajes."},
	"crafting": {"name": "Elaboración", "icon": "⚒️", "desc": "Sin efecto todavía: solo acumula experiencia para futuras mejoras.", "xp_hint": "Fundir acero y mejorar herramientas en la herrería."},
	"cooking": {"name": "Cocina", "icon": "🍲", "desc": "Probabilidad de obtener una ración extra al cocinar.", "xp_hint": "Cocinar en la cacerola del campamento."},
	"alchemy": {"name": "Alquimia", "icon": "🧪", "desc": "Sin efecto todavía: solo acumula experiencia para futuras mejoras.", "xp_hint": "Administrar somníferos y tónicos."},
	"animals": {"name": "Trato con Animales", "icon": "🐾", "desc": "Tus mascotas ganan lealtad más rápido.", "xp_hint": "Alimentar y cuidar mascotas."},
	"stealth": {"name": "Sigilo", "icon": "🥷", "desc": "Los guardias te detectan desde menos distancia al escapar de la celda.", "xp_hint": "Aturdir en sigilo y hurtar bolsillos."},
	"medicine": {"name": "Medicina", "icon": "🩺", "desc": "Sin efecto todavía: solo acumula experiencia para futuras mejoras.", "xp_hint": "Tratar y lavar tus heridas."},
}

## Para añadir una habilidad nueva: 1) añade su entrada en SKILLS, 2) llama a player.add_skill_xp("id", cantidad) donde se practique,
## 3) usa player.get_skill_bonus("id") donde deba dar ventaja. Player la registra automáticamente.
static func default_levels() -> Dictionary:
	var d: Dictionary = {}
	for sid in SKILLS.keys():
		d[sid] = 1
	return d

static func skill_ids() -> Array:
	return SKILLS.keys()

static func skill_name(skill_id: String) -> String:
	return str(SKILLS.get(skill_id, {}).get("name", skill_id.capitalize()))

static func skill_icon(skill_id: String) -> String:
	return str(SKILLS.get(skill_id, {}).get("icon", "⭐"))

## XP necesaria para pasar del nivel `level` al siguiente.
static func xp_for_next(level: int) -> int:
	return 30 + level * 25
