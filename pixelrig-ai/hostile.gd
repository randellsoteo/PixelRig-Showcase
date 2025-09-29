#hostile.gd
extends CharacterBody2D

@export var speed: float = 300.0
@export var detection_radius: float = 600.0
@export var knockback_force: float = 400.0
@export var attack_cooldown: float = 1.0
@export var health: int = 5
@export var knockback_duration: float = 0.3
@export var separation_time: float = 0.5

# 🔹 NEW: Reference to an independent spawn marker (not a child!)
@export var spawn_marker_path: NodePath

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var target: Node = null
var can_attack: bool = true
var cooldown_timer: Timer
var spawn_position: Vector2

# Knockback variables
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0
var separation_timer: float = 0.0
var is_knocked_back: bool = false

func _ready():
	add_to_group("Hostile")
	
	# 🔹 IMPORTANT: Store current position FIRST for debugging
	var current_pos = global_position
	
	# 🔹 Get spawn position from external marker OR current position
	if spawn_marker_path:
		var marker = get_node_or_null(spawn_marker_path)
		if marker:
			spawn_position = marker.global_position
			print("✅ Hostile '%s' - Marker: %v | Current: %v | Diff: %v" % [name, spawn_position, current_pos, spawn_position - current_pos])
		else:
			push_warning("Hostile '%s': spawn_marker_path is set but node not found!" % name)
			spawn_position = global_position
	else:
		# Fallback: use current position
		spawn_position = global_position
		print("⚠️ Hostile '%s' has no spawn marker, using current position: %v" % [name, spawn_position])
	
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

# 🔹 Reset hostile to spawn position
func reset_state() -> void:
	# Clear all movement and knockback
	velocity = Vector2.ZERO
	knockback_vector = Vector2.ZERO
	knockback_time = 0.0
	separation_timer = 0.0
	is_knocked_back = false
	
	# Reset attack state
	can_attack = true
	if cooldown_timer:
		cooldown_timer.stop()
	
	# 🔹 CRITICAL: Disable detection temporarily
	if detection_area:
		detection_area.monitoring = false
	
	# Clear target to prevent immediate chase
	target = null
	
	# 🔹 Return to exact spawn position
	global_position = spawn_position
	
	# Reset health (optional - remove if you want damage to persist)
	health = 5
	
	# 🔹 Re-enable detection after a short delay
	await get_tree().create_timer(0.1).timeout
	if detection_area:
		detection_area.monitoring = true
	
	print("🔄 Hostile '%s' reset to: %v" % [name, spawn_position])

func take_damage(amount: int) -> void:
	health -= amount
	print("Hostile HP:", health)
	
	if health <= 0:
		die()

func die() -> void:
	print("💀 Hostile is defeated!")
	queue_free()

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_vector = direction.normalized() * force
	knockback_time = knockback_duration
	separation_timer = separation_time
	is_knocked_back = true

func _physics_process(delta: float) -> void:
	# Handle knockback first
	if knockback_time > 0:
		velocity = knockback_vector
		knockback_time -= delta
		move_and_slide()
		return
	
	# Handle separation period
	if separation_timer > 0:
		separation_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Reset knockback state
	if is_knocked_back:
		is_knocked_back = false
	
	# Normal AI behavior
	if target and can_attack and not is_knocked_back:
		var dist = global_position.distance_to(target.global_position)
		
		# Don't move if too close
		if dist < 50.0:
			velocity = Vector2.ZERO
			move_and_slide()
			return
		
		var factor = clamp(1.0 - (dist / detection_radius), 0.3, 1.0)
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed * factor
		
		move_and_slide()
		
		# Check collisions after movement
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider.has_method("take_damage") and can_attack:
				_attack(collider)
				break
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func _attack(player: Node) -> void:
	if not can_attack:
		return
		
	can_attack = false
	velocity = Vector2.ZERO
	
	# Apply damage
	if player.has_method("take_damage"):
		player.take_damage(1)
	
	# Apply knockback to player
	if player.has_method("apply_knockback"):
		var dir = (player.global_position - global_position).normalized()
		player.apply_knockback(dir, knockback_force)
	
	# Apply separation knockback to self
	var self_knockback_dir = (global_position - player.global_position).normalized()
	apply_knockback(self_knockback_dir, knockback_force * 0.3)
	
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
