extends SceneTree

func _collect_actions(diag: Dictionary) -> Array:
	var acts: Array = []
	for node_id in diag.keys():
		var node = diag[node_id]
		if typeof(node) != TYPE_DICTIONARY or not node.has("choices"):
			continue
		for c in node["choices"]:
			if typeof(c) == TYPE_DICTIONARY and c.has("action") and str(c["action"]) != "":
				if not (str(c["action"]) in acts):
					acts.append(str(c["action"]))
	return acts

func _initialize() -> void:
	var packed: PackedScene = load("uid://dsoiuct8kdsk3")
	var main_inst: Node = packed.instantiate()
	root.add_child(main_inst)
	current_scene = main_inst
	await process_frame
	await process_frame
	var player = get_first_node_in_group("player")
	if player and player.inventory:
		player.inventory.add_gold(5000)
		for it in ["iron_ore", "wood", "stone", "bandit_scrap", "raw_meat", "leather", "antlers", "fox_pelt", "frog_legs", "bones", "golden_egg", "organ_heart", "steel_ingot"]:
			player.inventory.add_item(it, 5)
	var total_actions: int = 0
	var npcs: Array = []
	for n in get_nodes_in_group("village_npcs"):
		npcs.append(n)
	for n in npcs:
		if not is_instance_valid(n):
			continue
		n.is_dead = false
		n.is_downed = false
		n.sedated_timer = 0.0
		n.is_stunned_flag = false
		n.affinity = 10
		var diag: Dictionary = n._inject_character_lore_into_dialogue(n._build_dialogue())
		var acts: Array = _collect_actions(diag)
		for a in acts:
			n.on_dialogue_action(a)
			total_actions += 1
	print("COVERAGE DONE npcs=%d actions=%d" % [npcs.size(), total_actions])
	quit(0)
