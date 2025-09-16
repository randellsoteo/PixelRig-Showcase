extends StaticBody2D

func interact():
	var world = get_tree().current_scene
	if world and world.has_method("set_spawn_point"):
		world.set_spawn_point(global_position)
		print("✅ Checkpoint activated at:", global_position)
