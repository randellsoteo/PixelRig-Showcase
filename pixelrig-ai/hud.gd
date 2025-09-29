extends Control

@onready var hearts = [$Heart1, $Heart2, $Heart3]

var full_heart = preload("res://assets/HUD/pixel_heart.png")
var empty_heart = preload("res://assets/HUD/pixel_empty.png")

func update_health(current_health: int):
	for i in range(hearts.size()):
		if i < current_health:
			hearts[i].texture = full_heart
		else:
			hearts[i].texture = empty_heart
