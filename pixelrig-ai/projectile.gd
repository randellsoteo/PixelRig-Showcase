extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

# Detect collision with Player or other bodies
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):  # safer to use groups
		print("Hit the player!")
		# Example: reduce health if you have an HP system
		if body.has_method("take_damage"):
			body.take_damage(1)
			queue_free()  # bullet disappears on impact
