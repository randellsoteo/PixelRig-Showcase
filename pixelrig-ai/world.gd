extends Node2D

var spawn_point: Vector2

func _ready():
	var player = $Player
	# Try to find PlayerStart marker
	if has_node("PlayerStart"):
		var player_start = $PlayerStart
		spawn_point = player_start.global_position
	else:
		# fallback to player’s current position
		spawn_point = player.global_position
	
	# place player at spawn point
	player.global_position = spawn_point

func respawn_player():
	var player = $Player
	player.global_position = spawn_point
	player.health = 3 # Reset health directly
	print("🔄 Respawned at:", spawn_point)

func set_spawn_point(new_point: Vector2):
	spawn_point = new_point
