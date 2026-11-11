extends RefCounted

## AndarMapa: un solo sitio para «dar el paso» de quien se mueve por el mapa con `move_and_slide` (animales, mascotas,
## bandidos, enemigos). Si el actor tiene cuerpo 3D (meta «cuerpo3d», se lo da CuerposDelPueblo3D cuando está cerca del
## protagonista), anda con él y choca en 3D; si no, como siempre en el mapa. Sin cargar nada: así pueden usarlo los
## guiones de los animales sin crear ciclos de carga. Paso a 3D, opción B, 2026-11-12.


static func paso(actor: CharacterBody2D, delta: float) -> void:
	var cuerpo = actor.get_meta("cuerpo3d") if actor.has_meta("cuerpo3d") else null
	if is_instance_valid(cuerpo):
		cuerpo.mover(actor.velocity, delta)
	else:
		actor.move_and_slide()
