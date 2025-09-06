extends StaticBody2D


@export var tool_name = "Demo Tool"

# Reference to the UI label
@onready var ui_label = get_tree().get_root().get_node("World/UI/TerminalText")

func interact():
	#ui_label.bbcode_enabled = true
	ui_label.text = "Picked up " + tool_name
	queue_free()  # remove the tool from the scene after pickup
