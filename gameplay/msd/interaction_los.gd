## Shared reachability rule for optional books and prototype appliance controls.
## World layer 1 walls are solid. One-way platforms are non-blocking for use,
## consistent with the existing furniture pass-through design.
class_name GameplayInteractionLOS
extends RefCounted


static func has_path(actor: Node2D, target: Vector2) -> bool:
	if not is_instance_valid(actor):
		return false
	var origin: Vector2 = actor.global_position
	if origin.is_equal_approx(target):
		return true
	var space := actor.get_world_2d().direct_space_state
	var ignored: Array[RID] = []
	for _index in 12:
		var query := PhysicsRayQueryParameters2D.create(origin, target, 1, ignored)
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			return true
		var collider := hit.collider as CollisionObject2D
		if collider == null:
			return false
		var owner_id: int = collider.shape_find_owner(int(hit.shape))
		var owner: Object = collider.shape_owner_get_owner(owner_id)
		if owner is CollisionShape2D and (owner as CollisionShape2D).one_way_collision:
			ignored.append(collider.get_rid())
			continue
		return false
	return false  # fail closed if a pathological stack of 12 platforms is hit
