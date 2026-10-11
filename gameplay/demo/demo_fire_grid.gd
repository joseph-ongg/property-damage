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
		var center := Vector2(cell * cell_size) + Vector2(cell_size / 2.0, cell_size / 2.0)
		var t: float = clampf(_burning[cell] / flame_seconds, 0.0, 1.0)
		# A soft ember cluster is visually less misleading than a solid block of
		# fire floating in the sky. The simulation-facing cell is unchanged.
		draw_circle(center, 12.0, Color(1.0, 0.37, 0.08, 0.11 + t * 0.12))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-5, 7), center + Vector2(-7, 0),
			center + Vector2(-2, -9), center + Vector2(2, -3),
			center + Vector2(5, -12), center + Vector2(8, 2),
			center + Vector2(3, 8)]), Color(1.0, 0.55, 0.19, 0.6 + 0.35 * t))
		draw_circle(center + Vector2(0, 3), 3.5, Color(1.0, 0.93, 0.55, 0.86 * t))
		for offset: Vector2 in [Vector2(-9, -6), Vector2(11, -8), Vector2(3, -15)]:
			draw_rect(Rect2((center + offset).round(), Vector2(2, 2)), Color(1.0, 0.75, 0.27, 0.63 * t))
