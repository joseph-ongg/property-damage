## QA-only overlay over original Piskel, never loaded by the actual F5 game.
extends Node2D

func _draw() -> void:
    var stage := get_parent()
    for area in stage.get_node("RoseThorns").get_children():
        for shape in area.get_children():
            var collision := shape as CollisionPolygon2D
            if collision == null:
                continue
            var outline := PackedVector2Array()
            for vertex in collision.polygon:
                outline.append(collision.to_global(vertex))
            if outline.size() > 1:
                outline.append(outline[0])
                draw_polyline(outline, Color(0.94,0.87,0.08,0.98), 1.3, false)
    draw_string(ThemeDB.fallback_font,Vector2(430,90),
        "QA ONLY: source-pixel rose collision contour",
        HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(0.15,0.15,0.10))
