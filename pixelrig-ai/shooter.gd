extends Node2D

@export var projectile_scene: PackedScene
@export var fire_interval: float = 1.5
@export var fire_direction: Vector2 = Vector2.RIGHT

@onready var shoot_timer: Timer = $ShootTimer

func _ready() -> void:
	shoot_timer.wait_time = fire_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		projectile.direction = fire_direction.normalized()
