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
## Design tags fragile separately from throwable. Garden's specified
## items are throwable but *not* confirmed fragile; do not consume on hit.
@export var fragile: bool = false
signal hit_player(player_index: int, damage: int)
var mushroom_source_index: int = 0
var consumed: bool = false
var last_thrower_index: int = 0
var _impact_spent: bool = false


func _ready() -> void:
    width = 19.0 if kind == Kind.APPLE else 28.0
    if kind == Kind.MUSHROOM:
        width = 36.0
    elif kind == Kind.HOSE_END:
        width = 16.0
    pickup_radius = 62.0
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
        set("hp", get("max_hp"))
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


func _physics_process(delta: float) -> void:
    # The pre-existing GameplayBurnableProp controls gravity, sweep and
    # world collisions. Only Garden-specific player hit response is added.
    var was_flying := flying
    var before := global_position
    # Austin's unmerged base can directly apply damage to its older
    # numeric player.health field. Capture it, then convert that same
    # impact into exactly ONE user-approved Garden HP hit via Eva Health.
    var legacy_before: Dictionary = {}
    var arena := get_parent().get_parent()
    for index in [1,2]:
        var player := arena.get_node_or_null("Player%d" % index) as GameplayPlayer
        if player != null and player.has_method("take_damage"):
            legacy_before[index] = float(player.get("health"))
    super._physics_process(delta)
    if not was_flying or consumed or _impact_spent or carried_by != null:
        return
    for index in [1, 2]:
        var player := arena.get_node_or_null("Player%d" % index) as GameplayPlayer
        if index == last_thrower_index:
            # If a historical base incorrectly hits the thrower in a
            # manually constructed test, restore the authoritative HP.
            if player != null and legacy_before.has(index):
                player.set("health", float(player.health_component.hp))
            continue
        if player == null or player.health_component == null:
            continue
        var legacy_hit := legacy_before.has(index) and (
            float(player.get("health")) < float(legacy_before[index]) - 0.0001)
        var center := player.global_position + Vector2(0, -12)
        var closest := Geometry2D.get_closest_point_to_segment(center, before, global_position)
        if center.distance_to(closest) > 27.0 and not legacy_hit:
            continue
        # An apple/gnome/mushroom/hose head impacts once; invulnerability
        # belongs to Eva and can reject damage without an extra HP store.
        var applied := player.health_component.take_damage(impact_damage)
        # Austin's legacy numeric field is just a temporary mirror in the
        # Garden. Avoid stacking his area-formula hit with the 1 HP Garden
        # provisional damage; Eva remains the source of truth.
        if legacy_before.has(index):
            player.set("health", float(player.health_component.hp))
        _impact_spent = true
        if fragile:
            # Only Design-tagged fragile props are destroyed on impact.
            consumed = true
            flying = false
            flight_velocity = Vector2.ZERO
            visible = false
        else:
            # Ordinary throwable: one impact per flight, then fall to the
            # world and become collectable again after landing.
            flight_velocity = Vector2.ZERO
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
