# world.gd
extends Node2D

var spawn_point: Vector2

func _ready():
	var player = $Player
	
	# Try to find PlayerStart marker
	if has_node("PlayerStart"):
		var player_start = $PlayerStart
		spawn_point = player_start.global_position
	else:
		# fallback to player's current position
		spawn_point = player.global_position
	
	# place player at spawn point
	player.global_position = spawn_point

func respawn_player():
	var player = $Player
	
	# 🔹 NEW: Reset all hostiles FIRST (before moving player)
	reset_all_hostiles()
	
	# Then respawn the player
	player.global_position = spawn_point
	player.health = 3  # Reset health directly
	player.velocity = Vector2.ZERO  # Clear any remaining velocity
	
	# 🔹 NEW: Clear any ongoing player states
	if player.has_method("clear_knockback"):
		player.clear_knockback()
	
	print("🔄 Respawned at:", spawn_point)

# 🔹 NEW: Reset all hostiles to their spawn positions
func reset_all_hostiles():
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	for hostile in hostiles:
		if hostile and hostile.has_method("reset_state"):
			hostile.reset_state()
	print("🔄 Reset", " ", hostiles.size()," ", "hostiles")

func set_spawn_point(new_point: Vector2):
	spawn_point = new_point
