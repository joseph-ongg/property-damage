## Physical Gameplay hitbox + original Art & Audio Piskel pixels, partitioned
## by build_garden_stage.py. When a GardenProp is destroyed, its art genuinely
## disappears and the underlying background is revealed, unlike the old
## invisible GamePlayInteractableItem in front of a permanently painted tree.
class_name GameplayGardenProp
extends GameplayInteractableItem

const PROP_DIR := "res://gameplay/garden/art_generated/"
const ACCENT := {
    "rose": Color("#e76f80"),
    "tree": Color("#c0da80"),
    "mushrooms": Color("#9dd7ed"),
}

@export_enum("rose", "tree", "mushrooms") var motif: String = "rose"

var art: Texture2D
var _flash_left: float = 0.0


func _ready() -> void:
    super._ready()
    art = load(PROP_DIR + "garden_prop_%s.png" % motif) as Texture2D
    damaged.connect(_on_damage)
    queue_redraw()


func reset_visual_effects() -> void:
    _flash_left = 0.0
    queue_redraw()


func _on_damage(_amount: float, _source_player: int) -> void:
    _flash_left = 0.2
    queue_redraw()


func _process(delta: float) -> void:
    super._process(delta)
    if _flash_left > 0.0:
        _flash_left = maxf(0.0, _flash_left - delta)
        queue_redraw()


func _draw() -> void:
    if not destroyed_item:
        if art != null:
            # All three source layers have scene-sized, transparent PNGs.
            # This reverses the original Piskel partition exactly at rest.
            draw_texture(art, -global_position)
        if burning:
            _draw_status_runes()
        if hp < max_hp or _flash_left > 0.0:
            _draw_hp_bar()
    else:
        _draw_ash_rune()


func _draw_hp_bar() -> void:
    var anchor := Vector2(-31.0, -minf(78.0, hit_size.y * 0.32))
    var accent: Color = ACCENT.get(motif, Color("#f2cc87"))
    draw_rect(Rect2(anchor, Vector2(62, 8)), Color("#172338"), true)
    draw_rect(Rect2(anchor + Vector2.ONE, Vector2(60.0 * hp / maxf(max_hp, 1.0), 6)),
        Color.WHITE if _flash_left > 0.0 else accent, true)
    draw_rect(Rect2(anchor, Vector2(62, 8)), accent, false, 1.0)
    if _flash_left > 0.0:
        for dx in [-31.0, 30.0]:
            draw_line(Vector2(dx, -12), Vector2(dx, 12), accent, 2.0)


func _draw_status_runes() -> void:
    # Ember accents are only visual; Ethan's MaterialGrid remains the sole
    # authority for actual fire spread and player fire damage.
    var accent := Color("#ffab65")
    var phase := sin(float(Time.get_ticks_msec()) * 0.008)
    for i in 5:
        var px := float(i - 2) * 12.0
        var py := -20.0 - float(i % 2) * 5.0 + phase * 3.0
        draw_rect(Rect2(px, py, 3, 6), accent, true)
    draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 18, Color(1.0, 0.65, 0.37, 0.4), 1.0)


func _draw_ash_rune() -> void:
    # Clear original object pixels and replace with a small ash pile/sigil.
    # This makes destruction unambiguous without baking fake damage into art.
    for offset in [-21.0, -8.0, 5.0, 18.0]:
        draw_rect(Rect2(offset, 7 + int(offset) % 3, 7, 4), Color("#525975"), true)
    draw_line(Vector2(-28, 14), Vector2(28, 14), Color("#c1c3ce"), 2.0)
    draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 12, Color(0.8, 0.75, 0.85, 0.42), 1.0)
