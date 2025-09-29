extends Area2D

@export var speed: float = 800.0
@export var damage: int = 1
@export var lifetime: float = 4.0

var shooter: Node = null
var direction: Vector2 = Vector2.RIGHT

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _physics_process(delta):
	# lifetime
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	# straight movement
	global_position += direction * speed * delta

	# collision check
	if col_shape and col_shape.shape:
		var params = PhysicsShapeQueryParameters2D.new()
		params.shape = col_shape.shape
		params.transform = global_transform
		params.collide_with_bodies = true
		params.collide_with_areas = true
		var results = get_world_2d().direct_space_state.intersect_shape(params, 8)
		for r in results:
			var collider = r.get("collider")
			if not collider or collider == shooter:
				continue
			if collider.is_in_group("Hostile") and collider.has_method("take_damage"):
				collider.take_damage(damage)
				queue_free()
				return
