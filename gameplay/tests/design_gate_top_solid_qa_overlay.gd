## Strictly QA-only overlay: original Piskel gate roof collision polygons.
## Never loaded from the normal Garden scene or shipped as new Art Team art.
extends Node2D

func _draw() -> void:
    var stage := get_parent()
    for body in stage.get_node("RoseGateSolids").get_children():
        for item in body.get_children():
            var shape := item as CollisionPolygon2D
            if shape == null or shape.polygon.size() < 3:
                continue
            var points := PackedVector2Array()
            for local in shape.polygon:
                points.append(to_local(shape.to_global(local)))
            points.append(points[0])
            draw_polyline(points, Color("#ffce25"), 2.0, false)
    draw_string(ThemeDB.fallback_font, Vector2(395, 95),
        "QA ONLY: solid source-art gate roof; sides are 5HP thorn contacts",
        HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f5e05b"))
