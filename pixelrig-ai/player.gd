# player.gd
extends CharacterBody2D

# --- Exported Properties ---
@export var speed: float = 250.0 # Player's movement speed.
@export var interact_distance: float = 50.0 # Range for triggering interactions.
@export var attack_range: float = 400.0 # Range for targeting enemies.

# --- Node References ---
@onready var sprite: AnimatedSprite2D = $Sprite # Reference to the player's AnimatedSprite2D node.

# --- Signals ---
signal health_changed(new_health) # Emitted when player's health changes, usually for UI updates.

# --- State Variables ---
var can_move: bool = true # Flag to control player movement (false when stunned).
var max_health: int = 3 # Maximum possible health.
var health: int = max_health # Current health.
var stun_timer: Timer # Timer used to track the duration of a stun effect.
var knockback_vector: Vector2 = Vector2.ZERO # The current velocity vector for knockback.
var knockback_time: float = 0.0 # Time remaining for the knockback effect.
var knockback_duration: float = 0.3 # Duration of the knockback effect.
var last_direction := Vector2.DOWN # Initialize it to a default facing direction (e.g., front)

# --- Constants ---
const BULLET_SCENE = preload("res://Bullet.tscn") # Preload the bullet scene for fast instantiation.

# --- Built-in Functions ---

func _ready():
	# Initialize the Timer for stun effects.
	stun_timer = Timer.new()
	stun_timer.one_shot = true # The timer runs only once per start.
	add_child(stun_timer) # Add the timer as a child node.
	stun_timer.timeout.connect(_on_stun_end) # Connect the timeout signal to the handler function.

func _physics_process(delta):
	# --- 1. Handle Knockback ---
	if knockback_time > 0:
		velocity = knockback_vector
		knockback_time -= delta
		move_and_slide()
		return
	
	# --- 2. Handle Stun ---
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle-front") # Default to front idle when stunned
		return
	
	# --- 3. Handle Attack Input ---
	if Input.is_action_just_pressed("Attack"):
		var target = _get_nearest_hostile_in_range()
		if target:
			_shoot(target)
		else:
			print("❌ No hostile in range — shooting disabled")
		return
	
	if Input.is_action_just_pressed("Interact"):
		_interact()
	
	# --- 4. Normal Movement Input ---
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	
	# --- IMPORTANT: Update last_direction ONLY if there is current input ---
	if input_vector != Vector2.ZERO:
		last_direction = input_vector.normalized() # Store the direction
		
	velocity = input_vector * speed
	move_and_slide()
	
	# --- 5. Animation Logic (Now using 'last_direction' for Idle) ---
	
	var is_moving = input_vector != Vector2.ZERO
	var animation_to_play = ""
	
	if is_moving:
		# --- Running Animations (Same as before) ---
		if abs(input_vector.x) > abs(input_vector.y): # Prioritize horizontal movement
			if input_vector.x < 0:
				sprite.flip_h = true 
				animation_to_play = "run-right"
			elif input_vector.x > 0:
				sprite.flip_h = false
				animation_to_play = "run-right"
		else: # Prioritize vertical movement or tie
			if input_vector.y < 0:
				sprite.flip_h = false
				animation_to_play = "back-run"
			elif input_vector.y > 0:
				sprite.flip_h = false
				animation_to_play = "front-run"
	else:
		# --- Idle Animations (NEW LOGIC) ---
		
		# Prioritize the direction with the largest magnitude from the stored last_direction
		if abs(last_direction.x) > abs(last_direction.y):
			# Horizontal Idle
			if last_direction.x < 0:
				sprite.flip_h = true # Flip for left
				animation_to_play = "idle-right"
			else: # last_direction.x > 0
				sprite.flip_h = false # No flip for right
				animation_to_play = "idle-right"
		else:
			# Vertical Idle
			if last_direction.y < 0:
				sprite.flip_h = false # Reset flip
				animation_to_play = "idle-back"
			else: # last_direction.y > 0
				sprite.flip_h = false # Reset flip
				animation_to_play = "idle-front"

	# Play the determined animation
	if animation_to_play != "":
		sprite.play(animation_to_play)

# --- Health & Damage Functions ---

func take_damage(amount: int) -> void:
	# Decreases health and handles death.
	health -= amount
	health = clamp(health, 0, max_health) # Ensure health stays within bounds.
	print("Player HP:", health)

	emit_signal("health_changed", health) # Notify UI of health change.

	if health <= 0:
		die()

func die() -> void:
	# Handles the player's death state.
	print("💀 Player is dead")
	
	# Clear any ongoing movement/knockback
	clear_knockback() 
	velocity = Vector2.ZERO
	
	# Stop player movement processing
	set_physics_process(false)
	
	# Show death popup (assumes the world/main scene handles this)
	var world = get_tree().current_scene
	if world and world.has_method("show_death_popup"):
		world.show_death_popup()

# --- Knockback & Stun Functions ---

func clear_knockback():
	# Resets all knockback state variables.
	knockback_vector = Vector2.ZERO
	knockback_time = 0.0

func apply_knockback(direction: Vector2, force: float) -> void:
	# Initiates a knockback effect.
	knockback_vector = direction.normalized() * force # Calculate knockback velocity.
	knockback_time = knockback_duration # Set the duration for knockback.

func stun(duration: float) -> void:
	# Applies a stun effect, disabling movement.
	can_move = false
	stun_timer.start(duration)

func _on_stun_end() -> void:
	# Called when the stun timer finishes.
	can_move = true # Restore movement control.

# --- Respawn & Reset Functions ---

func respawn_at(position: Vector2) -> void:
	# Teleports the player to a new position after death/reset.
	var original_collision_layer = collision_layer
	var original_collision_mask = collision_mask
	# Temporarily disable collision to prevent issues during teleport
	collision_layer = 0
	collision_mask = 0
	
	# Reset state
	velocity = Vector2.ZERO
	clear_knockback()
	can_move = true
	health = max_health # Restore health
	set_physics_process(true) # Re-enable movement processing
	
	global_position = position # Perform the teleport
	
	# Wait a short moment to ensure the teleport is complete before restoring collision
	await get_tree().create_timer(0.1).timeout
	
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
	
	# Optional: Reset enemies
	_reset_all_hostiles()

func _reset_all_hostiles() -> void:
	# Finds all nodes in the "Hostile" group and calls their reset_state method.
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	for hostile in hostiles:
		if hostile and hostile.has_method("reset_state"):
			hostile.reset_state()

# --- Combat Functions ---

func _shoot(target: Node2D):
	# Spawns a bullet aimed at the target.
	sprite.play("shoot") # Play the shooting animation.
	velocity = Vector2.ZERO # Stop movement briefly while shooting.
	
	var bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet) # Add bullet to the main scene tree.
	var dir = (target.global_position - global_position).normalized() # Calculate direction vector.
	
	# Position the bullet slightly in front of the player.
	bullet.global_position = global_position + dir * 24 
	bullet.rotation = dir.angle() # Point the bullet in the direction of fire.
	bullet.shooter = self # Set the shooter property on the bullet.
	bullet.direction = dir # Set the bullet's movement direction.

func _get_nearest_hostile_in_range() -> Node2D:
	# Finds the closest enemy within the attack_range.
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	var closest: Node2D = null
	var closest_dist := INF # Start with infinite distance.
	
	for h in hostiles:
		if h:
			var d = global_position.distance_to(h.global_position)
			if d < closest_dist and d <= attack_range: # Check if closer AND within range.
				closest_dist = d
				closest = h
	return closest

# --- Interaction Function ---

func _interact():
	print("Interact key pressed!")
	
	# Method 1: Shape query (for physics bodies)
	var space_state = get_world_2d().direct_space_state
	var circle = CircleShape2D.new()
	circle.radius = interact_distance
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = global_transform
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true  # ADD THIS LINE - important for Area2D!
	query.collide_with_bodies = true
	var results = space_state.intersect_shape(query)
	
	print("Found ", results.size(), " objects nearby")
	
	var closest_body: Node = null
	var closest_distance = INF
	
	for result in results:
		var body = result.collider
		print("  - Found:", body.name, " | Has interact:", body.has_method("interact"))
		if body == self:
			continue
		if body.has_method("interact"):
			var distance = global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_body = body
	
	if closest_body:
		print("Interacting with:", closest_body.name)
		closest_body.interact()
	else:
		print("No interactable objects found")
