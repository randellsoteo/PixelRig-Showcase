extends CharacterBody2D

@export var speed: float = 400.0
@export var interact_distance: float = 50.0

var can_move: bool = true  # blocks movement when true
var health: int = 3  # starting HP

func take_damage(amount: int) -> void:
	health -= amount
	print("Player HP:", health)
	
	if health <= 0:
		die()

func die() -> void:
	print("💀 Player is dead")

	# Find the world and call respawn
	var world = get_tree().current_scene
	if world and world.has_method("respawn_player"):
		world.respawn_player()
	
	# Reset health
	health = 3

	
func _physics_process(delta):
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_vector * speed
	move_and_slide()

	if Input.is_action_just_pressed("Interact"):
		_interact()

func _interact():
	var space_state = get_world_2d().direct_space_state
	var circle = CircleShape2D.new()
	circle.radius = interact_distance

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = global_transform
	query.collision_mask = 0xFFFFFFFF

	var results = space_state.intersect_shape(query)
	var closest_body: Node = null
	var closest_distance = INF

	for result in results:
		var body = result.collider
		if body == self:
			continue
		if body.has_method("interact"):
			var distance = global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_body = body

	if closest_body:
		closest_body.interact()
