class_name ZonaDespiece
extends Area2D

## ZonaDespiece: TRADUCTOR (se quita con la tanda 7, cuando la tecla E busque en el mundo 3D). El animal salvaje ya es un
## cuerpo 3D, pero la E aún busca áreas «interactable» del mapa plano: mientras es un cadáver, esta área se pone en su
## sitio del mapa y le pasa el [E] del protagonista para despiezarlo. Tanda 4b-2 del paso a 3D, 2026-11-14.

const RADIO_PX: float = 24.0     ## alcance de la E alrededor del cadáver (unidades del mapa plano)
const CAPA_INTERACTUABLE: int = 1
const CAPA_PROTA_MAPA: int = 2

var animal: WildAnimal = null
var animal_name: String = ""     ## con este nombre la E escribe «Despiezar: …»


## Pone la zona en el mapa plano, en el sitio del cadáver `a`. Devuelve null si no hay pueblo donde ponerla.
static func poner(a: WildAnimal) -> Node:
	var vm: Node = a.get_tree().get_first_node_in_group("village_manager")
	var raiz: Node = vm.get("entities_root") as Node if vm != null else null
	if raiz == null:
		return null
	var z := ZonaDespiece.new()
	z.animal = a
	z.animal_name = a.animal_name
	z.collision_layer = CAPA_INTERACTUABLE
	z.collision_mask = CAPA_PROTA_MAPA
	z.add_to_group("interactable")
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RADIO_PX
	forma.shape = circulo
	z.add_child(forma)
	raiz.add_child(z)
	z.global_position = Lugar.en_mapa(a)
	z.body_entered.connect(z._al_acercarse)
	z.body_exited.connect(z._al_alejarse)
	return z


func interact(player: Node) -> void:
	if is_instance_valid(animal):
		animal.interact(player)


func _al_acercarse(quien: Node) -> void:
	if quien.is_in_group("player") and is_instance_valid(animal):
		AnimalRotulo.decir(animal, "[E] Desollar %s" % animal_name)


func _al_alejarse(quien: Node) -> void:
	if quien.is_in_group("player") and is_instance_valid(animal):
		AnimalRotulo.callar(animal)
