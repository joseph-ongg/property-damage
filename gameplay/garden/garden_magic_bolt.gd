## Reuse the existing Gameplay magic bolt. Intercept Garden fence *only*;
## do not modify Austin's item code or Eva's player HP / combat rules.
class_name GameplayGardenMagicBolt
extends GameplayMagicBolt


func _physics_process(delta: float) -> void:
    if _resolved:
        return
    var next_position := global_position + Vector2(float(direction) * speed * delta, 0)
    var query := PhysicsRayQueryParameters2D.create(global_position, next_position, 4)
    query.hit_from_inside = true
    var hit_result := get_world_2d().direct_space_state.intersect_ray(query)
    if not hit_result.is_empty():
        var target := hit_result.get("collider") as GameplayGardenFenceSegment
        if target != null and target.take_hit(caster_index):
            _resolved = true
            hit.emit("GARDEN FENCE %d" % (target.segment_index + 1), caster_index)
            queue_free()
            return
    super._physics_process(delta)
