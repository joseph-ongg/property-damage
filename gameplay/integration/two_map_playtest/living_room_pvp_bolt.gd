## EXPERIMENTAL adapter for the two-map F5 playtest only.
## Preserves GameplayMagicBolt's original furniture ignition / item logic.
## Player hits are routed to Eva Health without editing Austin's files.
class_name GameplayLivingRoomPvPBolt
extends GameplayMagicBolt

const BASE_PLAYER_DAMAGE := 10

var _caster: GameplayPlayer


func initialize(player: GameplayPlayer) -> void:
    _caster = player
    super.initialize(player)


func _physics_process(delta: float) -> void:
    if _resolved:
        return

    var before := global_position
    var after := before + Vector2(float(direction) * speed * delta, 0.0)
    var exclude: Array[RID] = []
    if is_instance_valid(_caster):
        exclude.append(_caster.get_rid())
    var query := PhysicsRayQueryParameters2D.create(before, after, 1 | 2, exclude)
    query.hit_from_inside = true
    var first_hit := get_world_2d().direct_space_state.intersect_ray(query)

    # Let the original Living Room projectile handle ALL world, prop, item
    # and fire effects. Its MaterialGrid / FurnitureFireLayer behavior must
    # never be bypassed by the temporary PvP adapter.
    if first_hit.is_empty() or not (first_hit["collider"] is GameplayPlayer):
        super._physics_process(delta)
        return

    var room := get_parent().get_parent()
    var player: GameplayPlayer = first_hit["collider"] as GameplayPlayer

    # The fire mask is separate from physics bodies. Check material before
    # applying PvP damage, so a visible flammable object takes priority.
    var furniture := _ignite_furniture(room, before, first_hit["position"])
    if not furniture.is_empty():
        global_position = first_hit["position"]
        _resolved = true
        hit.emit(furniture, caster_index)
        queue_free()
        return

    global_position = first_hit["position"]
    _resolved = true
    player.health_component.take_damage(BASE_PLAYER_DAMAGE)
    hit.emit("PLAYER %d" % player.player_index, caster_index)
    queue_free()
