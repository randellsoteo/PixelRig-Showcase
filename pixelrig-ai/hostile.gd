extends CharacterBody2D

@export var speed: float = 320.0
@export var detection_radius: float = 600.0
@export var knockback_force: float = 400.0
@export var attack_cooldown: float = 1.0 # seconds between attacks
@export var health: int = 3 # New: Health for the hostile

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var target: Node = null
var can_attack: bool = true
var cooldown_timer: Timer

func _ready():
	add_to_group("Hostile")
	# Detection shape
	var shape = CircleShape2D.new()
	shape.radius = detection_radius
	detection_shape.shape = shape

	# Connect signals
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	# Setup cooldown timer
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	cooldown_timer.timeout.connect(_on_attack_ready)
	
# New: Function to handle taking damage
func take_damage(amount: int) -> void:
	health -= amount
	print("Hostile HP:", health)
	
	if health <= 0:
		die()

# New: Function for when the hostile dies
func die() -> void:
	print("💀 Hostile is defeated!")
	# Removes the hostile from the scene
	queue_free()

func _physics_process(delta: float) -> void:
	if target and can_attack:
		var dist = global_position.distance_to(target.global_position)
		var factor = clamp(1.0 - (dist / detection_radius), 0.3, 1.0)
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed * factor

		# Use move_and_slide() to handle movement and collisions.
		var collision = move_and_slide()

		# Check if a collision occurred.
		if collision:
			# Iterate through all collisions that occurred in the frame.
			for i in range(get_slide_collision_count()):
				var current_collision = get_slide_collision(i)
				if current_collision.get_collider().has_method("take_damage"):
					_attack(current_collision.get_collider())
					# After attacking, stop the hostile's movement.
					velocity = Vector2.ZERO
					return # Exit the function so no further movement is processed this frame.
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _attack(player: Node) -> void:
	if not can_attack:
		return
	can_attack = false # stop further attacks until cooldown
	velocity = Vector2.ZERO

	# Apply damage
	if player.has_method("take_damage"):
		player.take_damage(1)

	# Knockback
	if player.has_method("apply_knockback"):
		var dir = (player.global_position - global_position).normalized()
		player.apply_knockback(dir, knockback_force)

	# Start cooldown
	cooldown_timer.start(attack_cooldown)

func _on_attack_ready():
	can_attack = true

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		target = body

func _on_body_exited(body: Node) -> void:
	if body == target:
		target = null
