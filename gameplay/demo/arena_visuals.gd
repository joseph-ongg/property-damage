## Tile-based visual dressing from collision geometry; doesn't change physics.
extends Node2D

const STONE: Texture2D = preload("res://gameplay/art/stone_tile.png")
const PLANK: Texture2D = preload("res://gameplay/art/wood_platform.png")


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
		if collision.one_way_collision:
			_draw_wood(rect)
		else:
			_draw_stone(rect)


func _draw_stone(rect: Rect2) -> void:
	draw_rect(rect, Color("292f3b"))
	for x in range(int(rect.position.x), int(rect.end.x), 32):
		for y in range(int(rect.position.y), int(rect.end.y), 32):
			draw_texture(STONE, Vector2(x, y))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("b7a17b"))


func _draw_wood(rect: Rect2) -> void:
	draw_rect(rect, Color("292b34"))
	for x in range(int(rect.position.x), int(rect.end.x), 32):
		draw_texture(PLANK, Vector2(x, rect.position.y - 1.0))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), Color("efcf90"))
	for x in range(int(rect.position.x + 10), int(rect.end.x), 28):
		draw_rect(Rect2(x, rect.end.y - 2, 5, 2), Color("c7a96e"))
