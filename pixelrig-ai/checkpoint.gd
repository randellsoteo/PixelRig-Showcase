extends Area2D  # Changed from StaticBody2D

func interact():
	var world = get_tree().current_scene
	if world and world.has_method("set_spawn_point"):
		world.set_spawn_point(global_position)
		print("Checkpoint activated at:", global_position)
		var ui_manager = get_tree().get_root().get_node("World/UI")
		ui_manager.show_message("Spawn point set")
