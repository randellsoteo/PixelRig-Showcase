# world.gd
extends Node2D

var spawn_point: Vector2

@onready var player = $Player
@onready var hud = $CanvasLayer/HUD
@onready var death_popup = $CanvasLayer/DeathPopup if has_node("CanvasLayer/DeathPopup") else null
@onready var dialogue_system = $DialogueSystem if has_node("DialogueSystem") else null

func _ready():
	# Connect Player → HUD
	player.health_changed.connect(hud.update_health)
	
	# Connect Death Popup signals (if popup exists)
	if death_popup:
		death_popup.respawn_requested.connect(respawn_player)
		death_popup.main_menu_requested.connect(_on_main_menu_requested)
	
	# Connect Dialogue System (if it exists)
	if dialogue_system:
		dialogue_system.dialogue_finished.connect(_on_intro_dialogue_finished)
	
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
	
	# 🎬 Start intro cutscene
	start_intro_cutscene()

func respawn_player():
	# 🔹 Freeze player immediately
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	# 🔹 Reset all hostiles first (and wait for them to finish)
	await reset_all_hostiles()
	
	# 🔹 Respawn player with collision disabled temporarily
	if player.has_method("respawn_at"):
		await player.respawn_at(spawn_point)
	else:
		# Fallback if respawn_at method doesn't exist
		player.global_position = spawn_point
		player.health = player.max_health
		player.velocity = Vector2.ZERO
		if player.has_method("clear_knockback"):
			player.clear_knockback()
	
	# 🔹 Re-enable player physics
	player.set_physics_process(true)
	
	# 🔹 Update HUD to show full hearts again
	hud.update_health(player.health)
	
	print("🔄 Respawned at:", spawn_point)

func reset_all_hostiles():
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	
	print("🔄 Starting reset of", hostiles.size(), "hostiles...")
	
	# Call reset_state on all hostiles
	for hostile in hostiles:
		if hostile and hostile.has_method("reset_state"):
			hostile.reset_state()
	
	# Wait for them all to finish (0.1 seconds + a bit extra)
	await get_tree().create_timer(0.15).timeout
	
	print("✅ All hostiles reset complete!")

func set_spawn_point(new_point: Vector2):
	spawn_point = new_point

func show_death_popup():
	if death_popup:
		death_popup.show_popup()
	else:
		print("⚠️ DeathPopup not found! Auto-respawning...")
		# Fallback: just respawn after a delay
		await get_tree().create_timer(1.0).timeout
		respawn_player()

func _on_main_menu_requested():
	# TODO: Implement scene change to main menu
	print("🏠 Going to main menu (not implemented yet)")
	# When ready, use:
	# get_tree().change_scene_to_file("res://MainMenu.tscn")

# 🎬 Intro Cutscene System
func start_intro_cutscene():
	if not dialogue_system:
		print("⚠️ No DialogueSystem found, skipping intro")
		return
	
	# Disable player control during cutscene
	player.set_physics_process(false)
	
	# Define your intro dialogue with camera pans
	var intro_dialogue = [
		{
			"speaker": "System Alert",
			"text": "Warning! The motherboard is under attack by malware!",
			"camera_target": $hostile.global_position,  # Pan to hostile/problem area
			"pan_duration": 1.5
		},
		{
			"speaker": "System Alert", 
			"text": "Critical system files are corrupted and need immediate repair!",
			"camera_target": Vector2(600, 500),  # Pan to another danger area
			"pan_duration": 1.0
		},
		{
			"speaker": "AI Assistant",
			"text": "You must navigate through the PC and eliminate all threats!",
			"camera_target": player.global_position,  # Pan back to player
			"pan_duration": 1.2
		},
		{
			"text": "Use WASD to move and Space to attack. Good luck!",
			"camera_target": player.global_position,
			"pan_duration": 0.5
		}
	]
	
	dialogue_system.start_dialogue(intro_dialogue)

func _on_intro_dialogue_finished():
	# Re-enable player control after cutscene
	player.set_physics_process(true)
	print("✅ Intro cutscene finished - Game started!")
