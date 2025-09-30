# player.gd
extends CharacterBody2D

# --- Exported Properties ---
@export var speed: float = 400.0 # Player's movement speed.
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
		velocity = knockback_vector # Move the player using the knockback vector.
		knockback_time -= delta # Decrease remaining knockback time.
		move_and_slide()
		return # Skip all other movement/input logic while knocked back.
	
	# --- 2. Handle Stun ---
	if not can_move:
		velocity = Vector2.ZERO # Stop movement if stunned.
		move_and_slide()
		sprite.play("idle") # Play idle animation while stunned.
		return # Skip all other input logic while stunned.
	
	# --- 3. Handle Attack Input ---
	if Input.is_action_just_pressed("Attack"):
		var target = _get_nearest_hostile_in_range() # Find the closest enemy within attack range.
		if target:
			_shoot(target) # Execute the shooting action.
		else:
			print("❌ No hostile in range — shooting disabled")
		return # Stop movement/animation processing to prioritize the attack.
	
	# --- 4. Normal Movement Input ---
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down") # Get directional input.
	velocity = input_vector * speed # Apply movement speed.
	move_and_slide() # Move the character using its velocity.
	
	# --- 5. Animation Logic ---
	if input_vector == Vector2.ZERO:
		sprite.play("idle")
	elif input_vector.x < 0:
		sprite.flip_h = true # Flip sprite left.
		sprite.play("run")
	elif input_vector.x > 0:
		sprite.flip_h = false # Face sprite right.
		sprite.play("run")
	# (Vertical movement uses horizontal animations by default)
		
	# --- 6. Interaction Input ---
	if Input.is_action_just_pressed("Interact"):
		_interact() # Check and perform interaction with objects.

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
	# Performs a circle cast to find interactable objects.
	var space_state = get_world_2d().direct_space_state
	var circle = CircleShape2D.new()
	circle.radius = interact_distance
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = global_transform # Query at the player's position.
	query.collision_mask = 0xFFFFFFFF # Check all layers.
	var results = space_state.intersect_shape(query)
	
	var closest_body: Node = null
	var closest_distance = INF
	
	for result in results:
		var body = result.collider
		if body == self:
			continue # Ignore self.
		if body.has_method("interact"): # Check if the object is interactable.
			var distance = global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_body = body
	
	if closest_body:
		closest_body.interact() # Call the interact method on the closest interactable object.
