# world.gd
extends Node2D

var spawn_point: Vector2

@onready var player = $Player
@onready var hud = $CanvasLayer/HUD

func _ready():
	# Connect Player → HUD
	player.health_changed.connect(hud.update_health)
	# Initialize HUD when game starts
	hud.update_health(player.health)

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
	
	# 🔹 Reset all hostiles first
	reset_all_hostiles()
	
	# Respawn player
	player.global_position = spawn_point
	player.health = player.max_health  # Reset health
	player.velocity = Vector2.ZERO     # Clear velocity
	
	# Clear knockback state
	if player.has_method("clear_knockback"):
		player.clear_knockback()
	
	# 🔹 NEW: Update HUD to show full hearts again
	hud.update_health(player.health)
	
	print("🔄 Respawned at:", spawn_point)

func reset_all_hostiles():
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	for hostile in hostiles:
		if hostile and hostile.has_method("reset_state"):
			hostile.reset_state()
	print("🔄 Reset", hostiles.size(), "hostiles")

func set_spawn_point(new_point: Vector2):
	spawn_point = new_point
