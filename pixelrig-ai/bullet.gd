extends Area2D

@export var speed: float = 800.0
@export var damage: int = 1
@export var turn_rate: float = 8.0
@export var lifetime: float = 4.0

var shooter: Node = null

@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _physics_process(delta):
	# lifetime
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	# homing movement
	var dir = Vector2.RIGHT.rotated(rotation)
	var target = _get_nearest_hostile()
	if target:
		var to_target = (target.global_position - global_position).normalized()
		dir = dir.lerp(to_target, turn_rate * delta).normalized()
		rotation = dir.angle()
	global_position += dir * speed * delta

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
			# Only damage hostiles (not their detection area)
			if collider.is_in_group("Hostile") and collider.has_method("take_damage"):
				collider.take_damage(damage)
				queue_free()
				return

func _get_nearest_hostile() -> Node2D:
	var hostiles = get_tree().get_nodes_in_group("Hostile")
	var closest: Node2D = null
	var closest_dist := INF
	for h in hostiles:
		if h and h.is_inside_tree():
			var d = global_position.distance_to(h.global_position)
			if d < closest_dist:
				closest_dist = d
				closest = h
	return closest
