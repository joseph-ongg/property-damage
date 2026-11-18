## Garden-only projectile collision adapter. Eva's Health is authoritative.
## Never alter the upstream Magic projectile, other arenas or Austin's items.
class_name GameplayGardenMagicBolt
extends GameplayMagicBolt

const BASE_PLAYER_DAMAGE := 10  # Design/PM: all character attacks start at 10.

var _caster: GameplayPlayer


func initialize(player: GameplayPlayer) -> void:
    _caster = player
    # The shared MagicBolt now handles Ninja/Wizard art in either arena.
    # Garden's subclass only implements its stage-specific hit ordering.
    super.initialize(player)


func _physics_process(delta: float) -> void:
    if _resolved:
        return
    var start := global_position
    var finish := start + Vector2(float(direction) * speed * delta, 0)
    var excluded: Array[RID] = []
    if is_instance_valid(_caster):
        excluded.append(_caster.get_rid())
    var physical_query := PhysicsRayQueryParameters2D.create(
        start, finish, 1 | 2, excluded)
    physical_query.hit_from_inside = true
    var physical_hit := get_world_2d().direct_space_state.intersect_ray(physical_query)
    var closest_distance := (
        start.distance_to(physical_hit["position"])
        if not physical_hit.is_empty() else INF)
    var struck_fence: GameplayGardenFenceSegment = null
    var fence_point := Vector2.ZERO
    # Fence hitboxes are intentionally *coarse* for physics querying. Compare
    # the actual authored Piskel pixels against players/world by distance,
    # so a player in front of the visible fence is not incorrectly blocked.
    var arena := get_parent().get_parent()
    for child in arena.get_node("Fences").get_children():
        var fence := child as GameplayGardenFenceSegment
        var art_hit := fence.first_opaque_hit_on_ray(start, finish)
        if art_hit.is_empty():
            continue
        var distance := start.distance_to(art_hit["position"])
        if distance < closest_distance:
            closest_distance = distance
            struck_fence = fence
            fence_point = art_hit["position"]
    if struck_fence != null and struck_fence.take_hit(caster_index):
        global_position = fence_point
        _resolved = true
        hit.emit("GARDEN FENCE %d" % (struck_fence.segment_index + 1), caster_index)
        queue_free()
        return
    if not physical_hit.is_empty():
        global_position = physical_hit["position"]
        _resolved = true
        var victim := physical_hit["collider"] as GameplayPlayer
        if victim != null:
            var damage := BASE_PLAYER_DAMAGE
            var garden := arena.get_node_or_null("GardenMechanics")
            var saved_fraction := 0.0
            if garden != null and garden.has_method("damage_for_player_attack"):
                # Health i-frames can reject a hit. Do not count the 0.5 HP
                # earned bonus on a projectile that dealt NO damage.
                saved_fraction = float(garden._fractional_damage_by_player.get(caster_index,0.0))
                damage = int(garden.damage_for_player_attack(caster_index))
            var applied := victim.health_component.take_damage(damage)
            if not applied and garden != null:
                garden._fractional_damage_by_player[caster_index] = saved_fraction
            hit.emit("PLAYER %d" % victim.player_index, caster_index)
        queue_free()
        return
    super._physics_process(delta)
