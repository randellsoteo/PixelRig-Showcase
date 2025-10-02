# Obstacle.gd - Blockages that can be cleared with specific tools
extends StaticBody2D

@export var required_tool_id: String = "wrench"  # What tool clears this obstacle
@export var obstacle_name: String = "Debris"
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null

func interact():
	# Check if player has a tool
	if not SolutionItem.has_item():
		print("You need a tool to clear this obstacle!")
		show_message("Find the right tool to clear this " + obstacle_name)
		return
	
	var item = SolutionItem.get_current_item()
	
	# Check if it's a tool
	if item.type != SolutionItem.ItemType.TOOL:
		print("You need a tool, not a component!")
		show_message("Use a tool to clear this")
		return
	
	# Check if it's the correct tool
	if item.id != required_tool_id:
		print("Wrong tool! This needs:", required_tool_id)
		show_message("This obstacle needs a " + required_tool_id)
		return
	
	# Success! Use tool and clear obstacle
	clear_obstacle()

func clear_obstacle():
	print("Obstacle cleared with", required_tool_id, "!")
	
	# Visual effect (fade out)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()
	
	# Disable collision immediately
	if collision_shape:
		collision_shape.disabled = true
	
	# Use the tool (consumes it)
	SolutionItem.use_item()

func show_message(msg: String):
	print("Obstacle:", msg)
	# You can add floating text here
