extends Node2D

func _ready():
	# Get window size
	var screen_size = get_viewport_rect().size
	
	# Place player at the center
	$Player.position = screen_size / 2
