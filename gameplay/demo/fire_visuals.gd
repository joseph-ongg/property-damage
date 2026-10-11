## 唯一燃烧状态来源：Ethan 的 MaterialGrid。
## EN: Source: Ethan (Miao-Zinan), remote ethan/burn-box-grid, commit 46c3df2.
## 中文：此节点只绘制火星，不维护 _burning 字典，不负责点火或火势传播。
## EN: Only render fire effects here; do not own burning storage, ignition or propagation.
## 参考 Jackson / c897a2e 的 cell_changed 信号驱动重绘。
## EN: Based on Jackson commit c897a2e: redraw in response to cell_changed.
extends Node2D

@export_node_path("Node2D") var grid_path: NodePath

var _grid: MaterialGrid = null
var _burning_cells: Dictionary = {}


func _ready() -> void:
	_grid = get_node_or_null(grid_path) as MaterialGrid
	if _grid == null:
		return
	_grid.cell_changed.connect(_on_cell_changed)
	# 已先加载的存档或测试材料也可以正确呈现。
	# EN: Display burning cells that were already present at startup.
	for x in _grid.width:
		for y in _grid.height:
			if _grid.is_burning(x, y):
				_burning_cells[Vector2i(x, y)] = true
	queue_redraw()


func _on_cell_changed(x: int, y: int) -> void:
	var cell := Vector2i(x, y)
	if _grid.is_burning(x, y):
		_burning_cells[cell] = true
	else:
		_burning_cells.erase(cell)
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	var size: float = float(_grid.cell_size)
	for cell: Vector2i in _burning_cells:
		var center := Vector2(cell) * size + Vector2.ONE * size * 0.5
		var scale := minf(size / 24.0, 1.0)
		# 像素火焰尽量小，避免盖住人物和室内原画。
		# EN: Keep flame pixels subtle so players and the room artwork stay visible.
		draw_circle(center, 12.0 * scale, Color(1.0, 0.37, 0.08, 0.17))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-5, 7) * scale,
			center + Vector2(-7, 0) * scale,
			center + Vector2(-2, -9) * scale,
			center + Vector2(2, -3) * scale,
			center + Vector2(5, -12) * scale,
			center + Vector2(8, 2) * scale,
			center + Vector2(3, 8) * scale]), Color("ff8c36"))
		draw_circle(center + Vector2(0, 3) * scale, 3.3 * scale, Color("ffe7a4"))
