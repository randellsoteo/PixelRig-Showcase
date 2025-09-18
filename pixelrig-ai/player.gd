# player.gd
extends CharacterBody2D

@export var speed: float = 400.0
@export var interact_distance: float = 50.0

var can_move: bool = true
var health: int = 3

var stun_timer: Timer
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0
var knockback_duration: float = 0.2 # how long knockback lasts

# New: Reference to the bullet scene to be instanced
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

func _physics_process(delta):
	# 🔹 If knockback active, override velocity
	if knockback_time > 0:
		velocity = knockback_vector
		knockback_time -= delta
		move_and_slide()
		return

	# 🔹 If stunned, don't process input
	if not can_move:
		move_and_slide()
		return

	# 🔹 Normal movement
	var input_vector = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_vector * speed
	move_and_slide()

	if Input.is_action_just_pressed("Interact"):
		_interact()
	
	# New: Check for the "Attack" input
	if Input.is_action_just_pressed("Attack"):
		_shoot()

# New: Function to handle the player shooting a bullet
func _shoot():
	var bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)

	var dir = Vector2.ZERO
	if velocity.length() > 0:
		dir = velocity.normalized()
	else:
		var last_input = Input.get_vector("Left","Right","Up","Down")
		if last_input.length() > 0:
			dir = last_input.normalized()
		else:
			dir = Vector2.RIGHT

	bullet.rotation = dir.angle()
	bullet.global_position = global_position + dir * 24  # spawn a bit forward
	bullet.shooter = self


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
