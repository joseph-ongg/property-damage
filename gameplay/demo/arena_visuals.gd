## Renders the fake StaticBody2D arena based on its ACTUAL collision shapes.
## Changing platform positions in the test scene keeps visuals in sync.
extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	for world in get_parent().get_children():
		if not world is StaticBody2D:
			continue
		var collision := world.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = collision.shape.size
		var pos: Vector2 = world.position + collision.position
		var rect := Rect2(pos - size * 0.5, size)
		var platform := collision.one_way_collision
		var fill := Color("354d68") if platform else Color("40546c")
		draw_rect(rect, fill)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color("79d3b4") if platform else Color("7095b0"))
		if platform:
			for x in range(int(rect.position.x) + 12, int(rect.end.x), 24):
				draw_rect(Rect2(x, rect.position.y + 6, 11, 2), Color("6681a0"))
