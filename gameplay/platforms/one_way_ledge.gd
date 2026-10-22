## Standalone one-way shelf for Gameplay/Level Design. World layer 1 only.
## Placement, length and material hints are independent from MaterialGrid.
@tool
class_name GameplayOneWayLedge
extends StaticBody2D

signal platform_configured(platform_id: StringName, span_cells: int)

enum Finish { PAINTED_WOOD, STONE, BRASS }

@export var platform_id: StringName = &"ledge"
@export_range(3, 16, 1) var span_cells: int = 6:
	set(value):
		span_cells = clampi(value, 3, 16)
		_update_shape()
@export_enum("Painted Wood", "Stone", "Brass") var visual_finish: int = Finish.PAINTED_WOOD:
	set(value):
		visual_finish = clampi(value, 0, 2)
		queue_redraw()
@export var material_tag: StringName = &"wood"
@export_range(8.0, 32.0, 1.0) var design_cell_size: float = 16.0:
	set(value):
		design_cell_size = maxf(8.0, value)
		_update_shape()

const SURFACE_HEIGHT: float = 12.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_update_shape()
	if not Engine.is_editor_hint():
		platform_configured.emit(platform_id, span_cells)


func surface_width() -> float:
	return float(span_cells) * design_cell_size


func surface_center() -> Vector2:
	return global_position + Vector2(0.0, -SURFACE_HEIGHT * 0.5)


# Expose the physical top in world coordinates; other teams can translate
# positions to their grids using their own authoritative world_to_cell API.
# This never changes or populates Simulation / MaterialGrid storage.
func world_surface_bounds() -> Rect2:
	return Rect2(global_position - Vector2(surface_width() * 0.5, SURFACE_HEIGHT * 0.5), Vector2(surface_width(), SURFACE_HEIGHT))


func _update_shape() -> void:
	var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider != null:
		# Duplicate before resizing: instanced scenes must never mutate each
		# other's shared subresource through a common shape resource.
		if not collider.shape.resource_local_to_scene:
			collider.shape = collider.shape.duplicate()
			collider.shape.resource_local_to_scene = true
		var rect := collider.shape as RectangleShape2D
		if rect != null:
			rect.size = Vector2(surface_width(), SURFACE_HEIGHT)
		collider.one_way_collision = true
	queue_redraw()


func _draw() -> void:
	var w := surface_width()
	var left := -w * 0.5
	var face := Color("4c6370")
	var highlight := Color("d1c9ac")
	var top := Color("809ba0")
	match visual_finish:
		Finish.STONE:
			face = Color("515b66")
			highlight = Color("c7ccd0")
			top = Color("7e8790")
		Finish.BRASS:
			face = Color("735b53")
			highlight = Color("e5c08c")
			top = Color("a68364")
	# Pixel-art ledge: bright narrow upper rim, inset tiled body and two
	# small brackets; players and book sprites stay above this geometry.
	draw_rect(Rect2(left - 2.0, -11.0, w + 4.0, 14.0), Color("263742"))
	draw_rect(Rect2(left, -9.0, w, 10.0), face)
	draw_rect(Rect2(left, -10.0, w, 3.0), top)
	draw_rect(Rect2(left + 2.0, -11.0, w - 4.0, 2.0), highlight)
	for i in span_cells - 1:
		var x := left + (i + 1) * design_cell_size
		draw_line(Vector2(x, -6), Vector2(x, -1), face.darkened(0.26), 1.0)
	for x in [left + design_cell_size, left + w - design_cell_size]:
		draw_rect(Rect2(x - 4, 2, 8, 10), Color("263742", 0.48))
		draw_rect(Rect2(x - 2, 2, 4, 8), face.darkened(0.2))
