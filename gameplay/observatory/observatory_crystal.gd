## Reusable shootable original pixel crystal; awards +5% attack on break.
class_name GameplayObservatoryCrystal
extends GameplayInteractableItem

@export var hue: Color = Color("#80dfdd")


func _ready() -> void:
    max_hp = 8.0
    hit_size = Vector2(36, 58)
    item_name = "ARCANE CRYSTAL"
    tags = ["flammable", "fragile"]
    super._ready()
    damaged.connect(func(_d: float, _p: int) -> void: queue_redraw())
    destroyed.connect(func(_p: int) -> void: queue_redraw())


func _draw() -> void:
    if destroyed_item:
        for i in range(5):
            draw_rect(Rect2(-21.0 + i * 10.0, 15 + i % 2 * 4, 7, 4),
                hue.darkened(0.65))
        return
    draw_colored_polygon(PackedVector2Array([
        Vector2(-16, 1), Vector2(-10, -20), Vector2(0, -31),
        Vector2(17, -6), Vector2(11, 20), Vector2(-11, 20)]), hue)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-7, 0), Vector2(0, -31), Vector2(12, -5),
        Vector2(7, 11), Vector2(-7, 12)]), hue.lightened(0.35))
    draw_line(Vector2(0, -31), Vector2(0, 17), Color("#f6f0df"), 2.0)
    draw_line(Vector2(-13, 3), Vector2(12, -6), hue.darkened(0.2), 1.0)
    if hp < max_hp:
        draw_rect(Rect2(-22, -41, 44, 5), Color("#151b37"))
        draw_rect(Rect2(-22, -41, 44 * hp / max_hp, 5), hue)
    if burning:
        draw_arc(Vector2.ZERO, 26, 0, TAU, 18, Color("#f2c77c"), 2.0)
