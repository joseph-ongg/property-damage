## Garden-only projectile collision adapter. Eva's Health is authoritative.
## Never alter the upstream Magic projectile, other arenas or Austin's items.
class_name GameplayGardenMagicBolt
extends GameplayMagicBolt

const BASE_PLAYER_DAMAGE := 10  # Design/PM: all character attacks start at 10.

var _caster: GameplayPlayer
## Explicit Design: Ninja shoots a shuriken, Mage shoots fireball.
## The shuriken silhouette is a visible temporary code-drawn indicator;
## there is no shuriken image among the current Art Team Piskel sources.
var projectile_kind: String = "fireball"


func initialize(player: GameplayPlayer) -> void:
    _caster = player
    projectile_kind = "shuriken" if player.character_kind == "ninja" else "fireball"
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
            if garden != null and garden.has_method("damage_for_player_attack"):
                damage = int(garden.damage_for_player_attack(caster_index))
            # Projectiles stop on all players; Eva's invulnerability decides
            # whether Health accepts the actual damage.
            victim.health_component.take_damage(damage)
            hit.emit("PLAYER %d" % victim.player_index, caster_index)
        queue_free()
        return
    super._physics_process(delta)



func _draw() -> void:
    if projectile_kind != "shuriken":
        super._draw()
        return
    # Temporary shuriken shape, not represented as approved Art Team art.
    # Its physics, speed and base damage are the same as the other fighters.
    draw_set_transform(Vector2.ZERO, _age * 11.0, Vector2.ONE)
    var spikes := PackedVector2Array([
        Vector2(-14, -1), Vector2(-4, -4), Vector2(-1, -14),
        Vector2(4, -4), Vector2(14, -1), Vector2(4, 4),
        Vector2(1, 14), Vector2(-4, 4)])
    draw_colored_polygon(spikes, Color("#aab5c3"))
    draw_circle(Vector2.ZERO, 2.5, Color("#343c48"))
    draw_set_transform(Vector2.ZERO)
