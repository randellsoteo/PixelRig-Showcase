extends Area2D

@export var tool_name = "Demo Tool"
var indicator: Node = null

func _ready():
	# Load and add indicator scene
	var indicator_scene = preload("res://Indicator.tscn")
	indicator = indicator_scene.instantiate()
	indicator.position = Vector2(0, -32)  # above the sprite

func interact():
	var ui_manager = get_tree().get_root().get_node("World/UI")
	ui_manager.show_message("Picked up " + tool_name)
	queue_free()
