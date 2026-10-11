## Standalone visual fire store ONLY for testing Gameplay before Simulation is ready.
## Implements the same public methods as MaterialGrid without touching Sim files.
extends Node2D

signal cell_changed(x: int, y: int)

@export var width: int = 30
@export var height: int = 17
@export var cell_size: int = 32
@export var flame_seconds: float = 8.0

var _burning: Dictionary = {}  # Vector2i -> remaining seconds


func world_to_cell(world_position: Vector2) -> Vector2i:
	var local := to_local(world_position)
	return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height


func ignite(x: int, y: int) -> void:
	if not in_bounds(x, y):
		return
	_burning[Vector2i(x, y)] = flame_seconds
	cell_changed.emit(x, y)
	queue_redraw()


func is_burning(x: int, y: int) -> bool:
	return _burning.has(Vector2i(x, y))


func get_cell_material(x: int, y: int) -> int:
	return 1 if in_bounds(x, y) else 0  # WOOD / AIR (demo only)


func extinguish(x: int, y: int) -> void:
	if _burning.erase(Vector2i(x, y)):
		cell_changed.emit(x, y)
		queue_redraw()


func _process(delta: float) -> void:
	if _burning.is_empty():
		return
	for cell: Vector2i in _burning.keys():
		var remaining: float = _burning[cell] - delta
		if remaining <= 0.0:
			_burning.erase(cell)
			cell_changed.emit(cell.x, cell.y)
		else:
			_burning[cell] = remaining
	queue_redraw()


func _draw() -> void:
	# Transparent overlay; the painted moonlit backdrop stays visible.
	for x in range(0, width * cell_size, cell_size):
		draw_line(Vector2(x, 0), Vector2(x, height * cell_size), Color(0.58, 0.68, 0.79, 0.055))
	for y in range(0, height * cell_size, cell_size):
		draw_line(Vector2(0, y), Vector2(width * cell_size, y), Color(0.58, 0.68, 0.79, 0.055))
	for cell: Vector2i in _burning:
		var p := Vector2(cell * cell_size)
		var t: float = clampf(_burning[cell] / flame_seconds, 0.0, 1.0)
		draw_rect(Rect2(p + Vector2(1, 1), Vector2(cell_size - 2, cell_size - 2)), Color(1.0, 0.31, 0.08, 0.32 + t * 0.18))
		draw_rect(Rect2(p + Vector2(2, 2), Vector2(cell_size - 4, cell_size - 4)), Color(1.0, 0.72, 0.24, 0.80), false, 2.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(10, 28), p + Vector2(7, 15), p + Vector2(15, 4), p + Vector2(25, 26), p + Vector2(19, 29)]), Color(1.0, 0.65, 0.11, t))
		draw_circle(p + Vector2(16, 22), 6, Color(1.0, 0.95, 0.53, t))
