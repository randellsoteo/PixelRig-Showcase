# player.gd
extends CharacterBody2D

@export var speed: float = 400.0
@export var interact_distance: float = 50.0
@export var attack_range: float = 400.0

@onready var sprite: AnimatedSprite2D = $Sprite

var can_move: bool = true
var health: int = 3
var stun_timer: Timer
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0
var knockback_duration: float = 0.3  # Slightly increased for better feel

const BULLET_SCENE = preload("res://Bullet.tscn")

func _ready():
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	add_child(stun_timer)
	stun_timer.timeout.connect(_on_stun_end)

func take_damage(amount: int) -> void:
	health -= amount
	print("Player HP:", health)
	
	if health <= 0:
		die()

func die() -> void:
	print("💀 Player is dead")
	# Clear any ongoing knockback when dying
	knockback_vector = Vector2.ZERO
	knockback_time = 0.0
	
	var world = get_tree().current_scene
	if world and world.has_method("respawn_player"):
		world.respawn_player()

func _reset_all_hostiles() -> void:
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	for hostile in hostiles:
		if hostile and hostile.has_method("reset_state"):
			hostile.reset_state()

# Add this to player.gd
func clear_knockback():
	knockback_vector = Vector2.ZERO
	knockback_time = 0.0
	velocity = Vector2.ZERO

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_vector = direction.normalized() * force
	knockback_time = knockback_duration

func stun(duration: float) -> void:
	can_move = false
	stun_timer.start(duration)

func _on_stun_end() -> void:
	can_move = true

func _physics_process(delta):
	# Handle knockback with stronger force
	if knockback_time > 0:
		velocity = knockback_vector
		knockback_time -= delta
		move_and_slide()
		return
	
	# If stunned, don't process input
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle")
		return
	
	# Handle attack
	if Input.is_action_just_pressed("Attack"):
		var target = _get_nearest_hostile_in_range()
		if target:
			_shoot(target)
		else:
			print("❌ No hostile in range — shooting disabled")
		return
	
	# Normal movement
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_vector * speed
	move_and_slide()
	
	# Animation logic (unchanged)
	if input_vector == Vector2.ZERO:
		sprite.play("idle")
	elif input_vector.x < 0:
		sprite.flip_h = true
		sprite.play("run")
	elif input_vector.x > 0:
		sprite.flip_h = false
		sprite.play("run")
		
	if Input.is_action_just_pressed("Interact"):
		_interact()

# Rest of the functions remain the same...
func _shoot(target: Node2D):
	sprite.play("shoot")
	velocity = Vector2.ZERO
	
	var bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	var dir = (target.global_position - global_position).normalized()
	bullet.global_position = global_position + dir * 24
	bullet.rotation = dir.angle()
	bullet.shooter = self
	bullet.direction = dir

func _get_nearest_hostile_in_range() -> Node2D:
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	var closest: Node2D = null
	var closest_dist := INF
	
	for h in hostiles:
		if h and h.is_inside_tree():
			var d = global_position.distance_to(h.global_position)
			if d < closest_dist and d <= attack_range:
				closest_dist = d
				closest = h
	return closest

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

"""
CODE ni DREW for Immunity Frames
# player.gd
extends CharacterBody2D

@export var speed: float = 400.0
@export var interact_distance: float = 50.0
@export var attack_range: float = 400.0   # 🔹 range to look for enemies when shooting
@onready var sprite: AnimatedSprite2D = $Sprite

var can_move: bool = true
var health: int = 3

# Knockback + stun
var stun_timer: Timer
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0
var knockback_duration: float = 0.2 # how long knockback lasts

# Invulnerability
var is_invulnerable: bool = false
var invuln_timer: Timer
@export var invuln_duration: float = 3.0   # seconds of i-frames

# Reference to the bullet scene
const BULLET_SCENE = preload("res://Bullet.tscn")

func _ready():
	# Stun setup
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	add_child(stun_timer)
	stun_timer.timeout.connect(_on_stun_end)

	# Invulnerability setup
	invuln_timer = Timer.new()
	invuln_timer.one_shot = true
	add_child(invuln_timer)
	invuln_timer.timeout.connect(_on_invuln_end)

func take_damage(amount: int) -> void:
	# 🔹 Ignore damage if invulnerable
	if is_invulnerable:
		print("🛡️ Player is invulnerable! No damage taken.")
		return

	health -= amount
	print("Player HP:", health)

	# 🔹 Activate i-frames
	is_invulnerable = true
	invuln_timer.start(invuln_duration)
	# Optional: flash sprite to indicate i-frames
	_start_invuln_flash()

	if health <= 0:
		die()

func die() -> void:
	print("💀 Player is dead")
	var world = get_tree().current_scene
	if world and world.has_method("respawn_player"):
		world.respawn_player()

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_vector = direction.normalized() * force
	knockback_time = knockback_duration

func stun(duration: float) -> void:
	can_move = false
	stun_timer.start(duration)

func _on_stun_end() -> void:
	can_move = true

func _on_invuln_end() -> void:
	is_invulnerable = false
	print("❌ Invulnerability ended")
	_stop_invuln_flash()

func _physics_process(delta):
	# 🔹 If knockback active, override velocity
	if knockback_time > 0:
		velocity = knockback_vector
		knockback_time -= delta
		move_and_slide()
		return

	# 🔹 If stunned, don't process input
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle")
		return

	# 🔹 Handle attack (only if hostile in range)
	if Input.is_action_just_pressed("Attack"):
		var target = _get_nearest_hostile_in_range()
		if target:
			_shoot(target)
		else:
			print("❌ No hostile in range — shooting disabled")
		return

	# 🔹 Normal movement
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_vector * speed
	move_and_slide()
	
	if input_vector == Vector2.ZERO:
		sprite.play("idle")
	elif input_vector.x < 0:
		sprite.flip_h = true
		sprite.play("run")
	elif input_vector.x > 0:
		sprite.flip_h = false
		sprite.play("run")
		
	if Input.is_action_just_pressed("Interact"):
		_interact()

# 🔹 SHOOTING FUNCTION
func _shoot(target: Node2D):
	sprite.play("shoot")
	velocity = Vector2.ZERO
	
	var bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)

	# 🔹 Guaranteed target
	var dir = (target.global_position - global_position).normalized()

	bullet.global_position = global_position + dir * 24
	bullet.rotation = dir.angle()
	bullet.shooter = self
	bullet.direction = dir  # 🔹 this line gives bullet its direction

# 🔹 Helper: Find nearest hostile in attack_range
func _get_nearest_hostile_in_range() -> Node2D:
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	var closest: Node2D = null
	var closest_dist := INF
	for h in hostiles:
		if h and h.is_inside_tree():
			var d = global_position.distance_to(h.global_position)
			if d < closest_dist and d <= attack_range:
				closest_dist = d
				closest = h
	return closest

# INTERACTION
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

# 🔹 Optional visual feedback for i-frames
func _start_invuln_flash():
	# Makes sprite blink while invulnerable
	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.5)

func _stop_invuln_flash():
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)
""" 
