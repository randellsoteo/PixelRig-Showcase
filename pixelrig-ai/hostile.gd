extends CharacterBody2D

@export var speed: float = 450.0   # slightly faster than player (400)
@export var detection_radius: float = 200.0

@onready var detection_area: Area2D = $DetectionArea
var target: Node = null

func _ready():
	# Make sure detection radius matches exported variable
	var shape = CircleShape2D.new()
	shape.radius = detection_radius
	$DetectionArea/CollisionShape2D.shape = shape

	# Connect signals
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if target:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		target = body

func _on_body_exited(body: Node) -> void:
	if body == target:
		target = null

func _on_Hostile_body_entered(body: Node) -> void:
	# Collision with Player (not just detection)
	if body.name == "Player" and body.has_method("take_damage"):
		body.take_damage(1)
