## Programmatic pixel-art garden gnome; ordinary breakable item and hitbox.
## The original Piskel Garden source is never altered.
class_name GameplayGardenGnome
extends GameplayInteractableItem

const RED := Color("#ec739b")
const GOLD := Color("#f2ce87")
const SKIN := Color("#f6d9be")
const BLUE := Color("#7191dd")


func _ready() -> void:
    item_name = "GARDEN GNOME"
    max_hp = 5.0
    hit_size = Vector2(28, 47)
    tags = ["flammable", "fragile"]
    super._ready()
    damaged.connect(func(_amount: float, _who: int) -> void: queue_redraw())
    destroyed.connect(func(_who: int) -> void: queue_redraw())


func _draw() -> void:
    if destroyed_item:
        for i in 4:
            draw_rect(Rect2(Vector2(-13 + 8 * i, 10 + (i % 2) * 2), Vector2(7, 4)),
                Color("#737489"), true)
        draw_arc(Vector2(0, 6), 14, 0.0, TAU, 15, Color("#b2a4ad"), 1.2)
        return
    var hat := PackedVector2Array([
        Vector2(-13, -6), Vector2(-8, -22), Vector2(-2, -27),
        Vector2(3, -23), Vector2(12, -6)])
    draw_colored_polygon(hat, RED if hp > 2 else Color("#b85b73"))
    draw_rect(Rect2(-11, -9, 22, 8), GOLD)
    draw_rect(Rect2(-7, -2, 14, 11), SKIN)
    draw_rect(Rect2(-6, 5, 12, 12), Color("#dedee5"))
    draw_rect(Rect2(-10, 13, 20, 9), BLUE)
    draw_rect(Rect2(-11, 21, 8, 4), Color("#2e3553"))
    draw_rect(Rect2(3, 21, 8, 4), Color("#2e3553"))
    draw_rect(Rect2(-5, 0, 3, 3), Color("#252a44"))
    draw_rect(Rect2(3, 0, 3, 3), Color("#252a44"))
    draw_rect(Rect2(-2, 4, 4, 4), RED)
    if burning:
        draw_line(Vector2(-16, -16), Vector2(-11, -25), GOLD, 2.0)
    if hp < max_hp:
        draw_rect(Rect2(-15, -31, 30, 4), Color("#232840"))
        draw_rect(Rect2(-15, -31, 30 * hp / max_hp, 4), RED)
