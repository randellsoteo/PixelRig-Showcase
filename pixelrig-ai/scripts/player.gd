extends CharacterBody2D

@export var speed: float = 200.0
@export var interact_distance: float = 50.0

func _physics_process(delta):
	# Get input vector for 8-axis movement
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Set velocity based on input
	velocity = input_vector * speed
	
	# Move the character
	move_and_slide()
	
	# Handle interaction input
	if Input.is_action_just_pressed("ui_accept"):
		_interact()

func _interact():
	# Create a circle shape for interaction detection
	var circle = CircleShape2D.new()
	circle.radius = interact_distance
	
	# Get all bodies in interaction range
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = global_transform
	query.collision_mask = 0xFFFFFFFF  # Check all layers
	
	var results = space_state.intersect_shape(query)
	
	# Find the closest interactable object
	var closest_distance = INF
	var closest_body = null
	
	for result in results:
		var body = result.collider
		if body == self:
			continue
			
		# Check if the body has an interact method
		if body.has_method("interact"):
			var distance = global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_body = body
	
	# Interact with the closest object
	if closest_body:
		closest_body.interact()
