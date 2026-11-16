extends Node2D

@export_node_path("Node") var furniture_layer_path: NodePath = NodePath("../MaterialGrid/FurnitureFireLayer")
@export var fade_time: float = 0.4

var _layer: GameplayFurnitureFireLayer
var _grid: MaterialGrid
var _ages: Dictionary = {}  # object id -> seconds since destroyed


func _ready() -> void:
	_layer = get_node_or_null(furniture_layer_path) as GameplayFurnitureFireLayer
	if _layer == null:
		return
	_grid = _layer.get_parent() as MaterialGrid
	_layer.object_destroyed.connect(func(id: String): _ages[id] = 0.0; queue_redraw())


func _process(delta: float) -> void:
	var changed := false
	for id: String in _ages:
		if _ages[id] < fade_time:
			_ages[id] += delta
			changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	var side := float(_grid.cell_size)
	for id: String in _ages:
		var alpha := clampf(_ages[id] / fade_time, 0.0, 1.0)
		for cell: Vector2i in _layer.object_cells(id):
			var h := (cell.x * 73856093) ^ (cell.y * 19349663)  # stable per-cell variation
			var shade := 0.16 + float(posmod(h, 5)) * 0.03
			var top_left := Vector2(cell) * side
			draw_rect(Rect2(top_left, Vector2(side, side)), Color(shade, shade, shade + 0.02, alpha))
			# a few lighter specks so it reads as ash, not a black box
			if posmod(h >> 3, 3) == 0:
				draw_rect(Rect2(top_left + Vector2(3, 4), Vector2(3, 2)), Color(0.45, 0.43, 0.42, alpha))
			if posmod(h >> 5, 4) == 0:
				draw_rect(Rect2(top_left + Vector2(9, 10), Vector2(2, 2)), Color(0.55, 0.52, 0.5, alpha))
