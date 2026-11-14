class_name AnimalRotulo
extends RefCounted

## AnimalRotulo: lo que se lee sobre un animal salvaje: un aviso («Zzz», «¡Jabalí enfurecido!», «[E] Desollar…») o, si el
## protagonista está lo bastante cerca para observarlo, qué está haciendo y cuánto ha comido.
## Pieza de WildAnimal (tanda 4b-2 del paso a 3D, 2026-11-14): un Label3D que mira siempre a la cámara. Antes era un
## texto del mapa plano que salía al pasar el ratón por encima.

const OBSERVA_M: float = 8.0          ## a esta distancia el protagonista ve qué hace el animal
const SOBRE_EL_LOMO_M: float = 0.35   ## altura del rótulo sobre el animal
const TAMANO_LETRA: int = 30
const TAMANO_PUNTO: float = 0.0011   ## tamaño de la letra en pantalla (el rótulo se ve igual de grande de cerca que de lejos)
const BORDE: int = 8
const COLOR_NORMAL: Color = Color(0.95, 0.92, 0.72)
const COLOR_BUENA_SANGRE: Color = Color(1.0, 0.9, 0.45)
const COLOR_SUENO: Color = Color(0.75, 0.85, 1.0, 0.85)
const HACIENDO: Dictionary = {
	WildAnimal.AnimalState.SEEK_FOOD: ["Buscando plantas", "Buscando presa"],
	WildAnimal.AnimalState.STALK_PREY: ["Acechando en sigilo", "Acechando en sigilo"],
	WildAnimal.AnimalState.POUNCE: ["¡Salto de caza!", "¡Salto de caza!"],
	WildAnimal.AnimalState.CHASE_PREY: ["Persiguiendo presa", "Persiguiendo presa"],
	WildAnimal.AnimalState.CHARGE_ATTACK: ["¡Embistiendo!", "¡Embistiendo!"],
	WildAnimal.AnimalState.EATING: ["Comiendo brotes", "Devorando presa"],
	WildAnimal.AnimalState.SEEK_MATE: ["Buscando pareja", "Buscando pareja"],
	WildAnimal.AnimalState.RETURN_HOME: ["Volviendo a su refugio", "Volviendo a su refugio"],
	WildAnimal.AnimalState.SLEEP: ["Durmiendo", "Durmiendo"],
	WildAnimal.AnimalState.FLEE: ["Huyendo asustado", "Huyendo asustado"],
} ## estado → [lo que hace un herbívoro, lo que hace un zorro]
const PASTANDO: Dictionary = {
	WildAnimal.SpeciesType.RABBIT: "Pastando", WildAnimal.SpeciesType.DEER: "En manada",
	WildAnimal.SpeciesType.FOX: "Merodeando", WildAnimal.SpeciesType.BOAR: "Hozando",
}


static func crear(a: WildAnimal) -> Label3D:
	var r := Label3D.new()
	r.name = "Rotulo"
	r.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	r.font_size = TAMANO_LETRA
	r.pixel_size = TAMANO_PUNTO
	r.fixed_size = true
	r.outline_size = BORDE
	r.outline_modulate = Color.BLACK
	r.position.y = float((WildAnimal.MODELOS[a.species] as Array)[1]) + SOBRE_EL_LOMO_M
	r.visible = false
	a.add_child(r)
	return r


static func decir(a: WildAnimal, texto: String, color: Color = COLOR_NORMAL) -> void:
	if a.rotulo == null:
		return
	a.rotulo.text = texto
	a.rotulo.modulate = color
	a.rotulo.visible = true


static func callar(a: WildAnimal) -> void:
	if a.rotulo != null:
		a.rotulo.visible = false


## Pone el rótulo al día: avisos cortos a cualquier distancia y, con el protagonista cerca, lo que está haciendo.
static func poner_al_dia(a: WildAnimal, lejos: bool) -> void:
	if lejos or a.state in WildAnimal.ESTADOS_FUERA:
		if lejos:
			callar(a)
		return
	var pl: Node = a._protagonista()
	if pl != null and a.sitio.distance_to(Lugar.de(pl)) <= OBSERVA_M:
		decir(a, _observado(a), COLOR_BUENA_SANGRE if a.genetics_tier >= 2 else COLOR_NORMAL)
	elif a.state == WildAnimal.AnimalState.FLEE:
		decir(a, "!", Color.ORANGE_RED)
	elif a.state == WildAnimal.AnimalState.SLEEP:
		decir(a, "Zzz", COLOR_SUENO)
	else:
		callar(a)


## «Venado del Valle [En manada | 1/2]»: nombre, qué hace, cuánto ha comido y, si es de buena sangre, su nivel.
static func _observado(a: WildAnimal) -> String:
	var comida: String = "Reserva" if a.is_on_reserve_day else "%d/%d" % [a.meals_eaten, WildAnimal.MAX_MEALS]
	var sangre: String = " | Sangre Nv.%d" % a.genetics_tier if a.genetics_tier >= 2 else ""
	return "%s [%s | %s%s]" % [a.animal_name, _haciendo(a), comida, sangre]


static func _haciendo(a: WildAnimal) -> String:
	if a.state == WildAnimal.AnimalState.GRAZE:
		return "Saciado, descansando" if a.is_fully_satiated() else str(PASTANDO[a.species])
	var textos: Array = HACIENDO.get(a.state, ["", ""])
	return str(textos[1 if a.species == WildAnimal.SpeciesType.FOX else 0])
