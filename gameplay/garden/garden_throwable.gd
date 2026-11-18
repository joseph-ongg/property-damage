## Garden adapter around the already-merged GameplayBurnableProp
## prototype, not Austin's separately owned austin/items code.
## Artwork for apples/gnomes has NOT been supplied independently by Art Team.
## Visual placeholders are explicitly named; no fabricated "Art Team" credit.
class_name GameplayGardenThrowable
extends GameplayBurnableProp

enum Kind { APPLE, GNOME, MUSHROOM, HOSE_END }
@export var kind: Kind = Kind.APPLE

const MUSHROOM_RED: Texture2D = preload("res://gameplay/garden/original_art_parts/mushroom_red.png")
const MUSHROOM_BLUE: Texture2D = preload("res://gameplay/garden/original_art_parts/mushroom_blue.png")
const HOSE_END_ART: Texture2D = preload("res://gameplay/garden/original_art_parts/hose_nozzle.png")

## Missing Garden object impact values: 1 HP placeholder as explicitly
## requested. Eva owns invulnerability and the authoritative HP component.
@export_range(1, 100, 1) var impact_damage: int = 1
signal hit_player(player_index: int, damage: int)
var mushroom_source_index: int = 0
var consumed: bool = false
var last_thrower_index: int = 0


func _ready() -> void:
    width = 19.0 if kind == Kind.APPLE else 28.0
    if kind == Kind.MUSHROOM:
        width = 36.0
    elif kind == Kind.HOSE_END:
        width = 16.0
    pickup_radius = 62.0
    add_to_group("garden_throwables")
    queue_redraw()


func can_pick_up(player: GameplayPlayer) -> bool:
    return not consumed and super.can_pick_up(player)


func throw_from(player: GameplayPlayer) -> bool:
    if not super.throw_from(player):
        return false
    last_thrower_index = player.player_index
    return true


func _physics_process(delta: float) -> void:
    # The pre-existing GameplayBurnableProp controls gravity, sweep and
    # world collisions. Only Garden-specific player hit response is added.
    var was_flying := flying
    var before := global_position
    super._physics_process(delta)
    if not was_flying or consumed or carried_by != null:
        return
    var arena := get_parent().get_parent()
    for index in [1, 2]:
        if index == last_thrower_index:
            continue
        var player := arena.get_node_or_null("Player%d" % index) as GameplayPlayer
        if player == null or player.health_component == null:
            continue
        var center := player.global_position + Vector2(0, -12)
        var closest := Geometry2D.get_closest_point_to_segment(center, before, global_position)
        if center.distance_to(closest) > 27.0:
            continue
        # An apple/gnome/mushroom/hose head impacts once; invulnerability
        # belongs to Eva and can reject damage without an extra HP store.
        var applied := player.health_component.take_damage(impact_damage)
        consumed = true
        flying = false
        flight_velocity = Vector2.ZERO
        visible = false
        if applied:
            hit_player.emit(index, impact_damage)
        break


func _process(delta: float) -> void:
    super._process(delta)
    if flying or carried_by != null:
        queue_redraw()


func _draw() -> void:
    if kind == Kind.MUSHROOM:
        # Real Piskel source crop. This is NOT a new/generated mushroom design.
        var texture: Texture2D = MUSHROOM_RED if mushroom_source_index == 0 else MUSHROOM_BLUE
        var art_size: Vector2 = texture.get_size() * 2.0
        draw_texture_rect(texture, Rect2(-art_size * 0.5, art_size), false)
    elif kind == Kind.HOSE_END:
        # The nozzle texture is copied unmodified from garden.piskel.
        var art_size := HOSE_END_ART.get_size() * 2.0
        draw_texture_rect(HOSE_END_ART, Rect2(-art_size * 0.5, art_size), false)
    elif kind == Kind.APPLE:
        # TEMP placeholder: no standalone apple sprite in Art Team Drive.
        draw_rect(Rect2(-5, -5, 10, 10), Color("#d82927"))
        draw_rect(Rect2(-1, -9, 3, 5), Color("#2b7240"))
    else:
        # TEMP placeholder: no standalone gnome sprite in Art Team Drive.
        draw_rect(Rect2(-8, -20, 16, 20), Color("#91a496"), false, 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(-17, -25), "ART?", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#17252a"))
