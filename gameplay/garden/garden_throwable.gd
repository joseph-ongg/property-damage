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

## Real item pixels are measured from the supplied Piskel crop at its
## existing 2x scene scale. Unknown Art uses the actual 20x20 '?' marker.
## This optional size override exists only for QA / an approved later
## texture's measured pixel footprint; not a guessed damage number.
@export var design_art_size_override: Vector2 = Vector2.ZERO
## Design tags fragile separately from throwable. Garden's specified
## items are throwable but *not* confirmed fragile; do not consume on hit.
@export var fragile: bool = false
## The Design specifies a 3-second burn-damage interval, but gives Garden
## item durability no number. Use 1 HP explicitly as a temporary setting
## only on main's older item prototype. Austin's newer item HP takes over
## automatically when his branch is merged.
@export_range(1, 20, 1) var provisional_burn_hp: int = 1
signal hit_player(player_index: int, damage: int)
## User-visible Design damage feedback (including valid sub-HP impacts).
signal impact_feedback(player_index: int, exact_damage: float,
    applied_hp: int, blocked: bool)
var mushroom_source_index: int = 0
var consumed: bool = false
var last_thrower_index: int = 0
var _impact_spent: bool = false
var _fallback_burn_remaining: int = 1
var _fallback_burn_elapsed: float = 0.0
var _fallback_burning: bool = false
var _fallback_ash: bool = false


func _ready() -> void:
    width = 19.0 if kind == Kind.APPLE else 28.0
    if kind == Kind.MUSHROOM:
        width = 36.0
    elif kind == Kind.HOSE_END:
        width = 16.0
    pickup_radius = 62.0
    _fallback_burn_remaining = provisional_burn_hp
    # Austin's unmerged version inherits an item/tag base with a _ready()
    # implementation; main's prototype has no _ready(). GDScript cannot
    # call an undefined super._ready(), so initialize only the optional
    # shared item metadata here without changing Austin's source files.
    if has_method("has_tag"):
        set("item_name", name.to_upper())
        set("hit_size", Vector2(width, 34.0))
        var item_tags: Variant = get("tags")
        for tag in ["flammable", "throwable"]:
            if not item_tags.has(tag):
                item_tags.append(tag)
        set("tags", item_tags)
        # The Garden Design has no durability value for these particular
        # props. User-approved provisional 1 HP also applies to burning.
        set("max_hp", float(provisional_burn_hp))
        set("hp", float(provisional_burn_hp))
        add_to_group("interactable_items")
        if has_signal("destroyed") and has_method("_on_destroyed"):
            if not is_connected("destroyed", Callable(self, "_on_destroyed")):
                connect("destroyed", Callable(self, "_on_destroyed"))
    add_to_group("garden_throwables")
    queue_redraw()


func can_pick_up(player: GameplayPlayer) -> bool:
    return not consumed and super.can_pick_up(player)


func throw_from(player: GameplayPlayer) -> bool:
    if not super.throw_from(player):
        return false
    last_thrower_index = player.player_index
    _impact_spent = false
    return true


func _throw_pixel_area() -> float:
    var visible_size := Vector2(20.0, 20.0)  # Existing '?' marker pixels
    if kind == Kind.MUSHROOM:
        var painted: Texture2D = MUSHROOM_RED if mushroom_source_index == 0 else MUSHROOM_BLUE
        visible_size = Vector2(painted.get_image().get_used_rect().size) * 2.0
    elif kind == Kind.HOSE_END:
        visible_size = Vector2(HOSE_END_ART.get_image().get_used_rect().size) * 2.0
    if design_art_size_override.x > 0.0 and design_art_size_override.y > 0.0:
        visible_size = design_art_size_override
    return visible_size.x * visible_size.y


func _apply_throw_damage_to_player(target: GameplayPlayer) -> void:
    # Share Austin's exact formula and Eva's integer-HP fractional ledger.
    # Do not call the legacy player's ceili(float) damage path, which used
    # to turn a 0.04HP '?' apple into an unjustified whole 1HP hit.
    var before := target.health_component.hp
    var blocked := target.health_component.is_invulnerable() or not target.health_component.is_alive()
    var exact_damage := _throw_pixel_area() / 10000.0
    super._apply_throw_damage_to_player(target)
    _impact_spent = true
    if fragile:
        consumed = true
        flying = false
        flight_velocity = Vector2.ZERO
        visible = false
    else:
        flight_velocity = Vector2.ZERO
    var applied := before - target.health_component.hp
    impact_feedback.emit(target.player_index, exact_damage, applied, blocked)
    if applied > 0:
        hit_player.emit(target.player_index, applied)


func _physics_process(delta: float) -> void:
    var was_flying := flying
    var before := global_position
    # Preserve Austin's swept world/prop physics. Its player-hit hook now
    # dispatches to this Garden visual-footprint adapter exactly once.
    super._physics_process(delta)
    if not was_flying or consumed or _impact_spent or carried_by != null:
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
        _apply_throw_damage_to_player(player)
        if not _hit_players.has(index):
            _hit_players.append(index)
        break

func _process(delta: float) -> void:
    super._process(delta)
    if not has_method("ignite") and not consumed:
        # Current main has no item-durability class. Garden's tiny fallback
        # samples the SAME MaterialGrid as Simulation; no second fire store.
        # Austin's item class uses its own HP/ignite/_process when available.
        var bridge := get_parent().get_parent().get_node_or_null("FireBridge") as GameplayFireBridge
        var now_burning := bridge != null and bridge.is_burning_world(global_position)
        _fallback_burning = now_burning
        if now_burning:
            _fallback_burn_elapsed += delta
            while _fallback_burn_elapsed >= 3.0 and not consumed:
                _fallback_burn_elapsed -= 3.0
                _fallback_burn_remaining -= 1
                if _fallback_burn_remaining <= 0:
                    _fallback_ash = true
                    consumed = true
                    carried_by = null
                    flying = false
                    flight_velocity = Vector2.ZERO
                    _reset_resting()
        else:
            _fallback_burn_elapsed = 0.0
        if now_burning or _fallback_ash:
            queue_redraw()
    if flying or carried_by != null:
        queue_redraw()


func restore_garden_fire_state() -> void:
    _fallback_burn_remaining = provisional_burn_hp
    _fallback_burn_elapsed = 0.0
    _fallback_burning = false
    _fallback_ash = false
    if has_method("ignite"):
        # Reset only this Garden item's optional Austin-owned durability
        # fields, not the base implementation or any Living Room item.
        for field in ["destroyed_item","burned_to_ash","burning",
                "_fire_contact_latched","_fire_damage_call"]:
            set(field,false)
        for field in ["_burn_age","_burn_damage_age"]:
            set(field,0.0)
        set("hp",get("max_hp"))
    queue_redraw()


func _draw() -> void:
    if _fallback_ash:
        # Explicit debug ash fallback; no fabricated Art Team asset.
        draw_rect(Rect2(-11,4,22,5),Color("#5d5855"))
        draw_rect(Rect2(-7,1,14,3),Color("#81756d"))
        return
    if has_method("draw_burn_sprite") and bool(get("burned_to_ash")):
        call("draw_burn_sprite")
        return
    if kind == Kind.MUSHROOM:
        # Real Piskel source crop. This is NOT a new/generated mushroom design.
        var texture: Texture2D = MUSHROOM_RED if mushroom_source_index == 0 else MUSHROOM_BLUE
        var art_size: Vector2 = texture.get_size() * 2.0
        draw_texture_rect(texture, Rect2(-art_size * 0.5, art_size), false)
    elif kind == Kind.HOSE_END:
        # The nozzle texture is copied unmodified from garden.piskel.
        var art_size := HOSE_END_ART.get_size() * 2.0
        draw_texture_rect(HOSE_END_ART, Rect2(-art_size * 0.5, art_size), false)
    else:
        # Apple and gnome lack a supplied standalone Art sprite. Use the
        # requested small '?' token instead of inventing object artwork.
        var block_color := Color("#ae5650") if kind == Kind.APPLE else Color("#82938c")
        draw_rect(Rect2(-10, -12, 20, 20), block_color)
        draw_rect(Rect2(-10, -12, 20, 20), Color("#f2efe5"), false, 1.5)
        draw_string(ThemeDB.fallback_font, Vector2(-4.5, 3), "?",
            HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#fff6e7"))
    if has_method("draw_burn_sprite"):
        call("draw_burn_sprite")
    elif _fallback_burning:
        draw_rect(Rect2(-5,-17,4,9),Color("#ee6836"))
