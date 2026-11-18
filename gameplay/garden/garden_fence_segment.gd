## Garden-specific fence target, approved Design: exactly 8 segments at 4 HP.
## Visuals are pixels from Art Team's original garden.piskel (not replacement art).
class_name GameplayGardenFenceSegment
extends StaticBody2D

signal damaged(segment: int, remaining_hp: int, attacker: int)
signal destroyed(segment: int, attacker: int)

const HP_PER_SEGMENT := 4
const ORIGINAL_WIDTH := 426
const STAGE_LEFT := 54.0
const STAGE_CENTER_Y := 270.0

var segment_index: int = 0 # zero-based in source image, one-based in filename
var hp: int = HP_PER_SEGMENT
var destroyed_segment: bool = false
var _visual: Sprite2D
var _collision: CollisionShape2D
var _art_image: Image


func _ready() -> void:
    assert(segment_index >= 0 and segment_index < 8)
    collision_layer = 4  # targeted by Garden magic only, not a wall for players
    collision_mask = 0
    var x0: int = roundi(segment_index * ORIGINAL_WIDTH / 8.0)
    var x1: int = roundi((segment_index + 1) * ORIGINAL_WIDTH / 8.0)
    position = Vector2(STAGE_LEFT + float(x0 + x1), 408.0)

    _visual = Sprite2D.new()
    _visual.name = "ArtTeamFencePixels"
    _visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _visual.texture = load("res://gameplay/garden/original_art_parts/fence_segment_%02d.png" % (segment_index + 1))
    _art_image = _visual.texture.get_image()
    _visual.position = Vector2(0, STAGE_CENTER_Y - position.y)
    _visual.scale = Vector2(2, 2)
    add_child(_visual)

    var hitbox := RectangleShape2D.new()
    hitbox.size = Vector2(float(x1 - x0) * 2.0, 139.0)
    _collision = CollisionShape2D.new()
    _collision.name = "DamageableFenceHitbox"
    _collision.shape = hitbox
    add_child(_collision)


## The rectangle is only a coarse physics candidate. Fence01's actual
## Piskel pixels end above the normal standing Magic shot: an opaque-pixel
## check is essential to avoid "hitting" completely empty sky / grass.
## Sample every world pixel along the ray after the broad-phase raycast.
## The actual source sprite, NOT an approximation, is authoritative.
func first_opaque_hit_on_ray(start_world: Vector2, end_world: Vector2) -> Dictionary:
    if destroyed_segment or collision_layer == 0 or _art_image == null:
        return {}
    var distance := start_world.distance_to(end_world)
    var samples := maxi(1, ceili(distance))
    for step in range(samples + 1):
        var world_point := start_world.lerp(end_world, float(step) / float(samples))
        var local := _visual.to_local(world_point)
        var pixel := Vector2i(floori(local.x + float(_art_image.get_width()) * 0.5),
            floori(local.y + float(_art_image.get_height()) * 0.5))
        if pixel.x < 0 or pixel.y < 0 or pixel.x >= _art_image.get_width() or pixel.y >= _art_image.get_height():
            continue
        if _art_image.get_pixelv(pixel).a > 0.1:
            return {"position":world_point}
    return {}


## The fence is painted irregularly over several fire-grid cells.
## Sampling only its center misses visibly burning edges. This list is
## computed from the *original* Art Team alpha mask and never fabricates art.
func occupied_fire_cells(grid: MaterialGrid) -> Array[Vector2i]:
    var cached: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
        "res://gameplay/garden/original_art_parts/fence_fire_cells.json"))
    # Source-derived exact mask for the default Garden 16px grid.
    if not cached.is_empty() and is_equal_approx(grid.cell_size,16.0) and grid.global_position == Vector2.ZERO:
        var results: Array[Vector2i] = []
        for pair in cached["cells"][str(segment_index+1)]:
            var cell := Vector2i(int(pair[0]),int(pair[1]))
            if grid.in_bounds(cell.x,cell.y):
                results.append(cell)
        return results
    # Non-standard grid geometry: fall back to deriving from the sprite.

    var found: Dictionary = {}
    if _art_image == null:
        return []
    for y in range(_art_image.get_height()):
        for x in range(_art_image.get_width()):
            if _art_image.get_pixel(x,y).a <= 0.1:
                continue
            var local := Vector2(
                float(x) - float(_art_image.get_width()) * 0.5 + 0.5,
                float(y) - float(_art_image.get_height()) * 0.5 + 0.5)
            var world := _visual.to_global(local)
            var cell := grid.world_to_cell(world)
            if grid.in_bounds(cell.x,cell.y):
                found[cell] = true
    var result: Array[Vector2i] = []
    for cell: Vector2i in found.keys():
        result.append(cell)
    return result


func take_hit(attacker: int) -> bool:
    if destroyed_segment:
        return false
    hp = maxi(0, hp - 1)
    damaged.emit(segment_index + 1, hp, attacker)
    if hp == 0:
        destroyed_segment = true
        collision_layer = 0
        if _collision != null:
            _collision.set_deferred("disabled", true)
        if _visual != null:
            _visual.visible = false
        destroyed.emit(segment_index + 1, attacker)
    return true


func restore() -> void:
    hp = HP_PER_SEGMENT
    destroyed_segment = false
    collision_layer = 4
    if _collision != null:
        _collision.set_deferred("disabled", false)
    if _visual != null:
        _visual.visible = true
