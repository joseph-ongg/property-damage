## 唯一燃烧状态来源：Ethan 的 MaterialGrid。
## Source: Ethan (Miao-Zinan), remote ethan/burn-box-grid, commit 46c3df2.
## 此节点只绘制火星，不维护 _burning 字典，不负责点火或火势传播。
## Only render fire effects here; do not own burning storage, ignition or propagation.
## 参考 Jackson / c897a2e 的 cell_changed 信号驱动重绘。
## Based on Jackson commit c897a2e: redraw in response to cell_changed.
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
	# Display burning cells that were already present at startup.
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
		# All flame elements snap to whole pixels, matching the pixel projectile.
		# Keep within the MaterialGrid cell and let Ethan own burn state.
		var center := (Vector2(cell) * size + Vector2.ONE * size * 0.5).round()
		var px := maxf(1.0, roundf(size / 16.0))
		draw_rect(Rect2(center + Vector2(-5, 1) * px, Vector2(10, 5) * px), Color("ba391c"))
		draw_rect(Rect2(center + Vector2(-4, -3) * px, Vector2(8, 7) * px), Color("ee681e"))
		draw_rect(Rect2(center + Vector2(-2, -6) * px, Vector2(4, 8) * px), Color("ffa72c"))
		draw_rect(Rect2(center + Vector2(-1, -2) * px, Vector2(2, 4) * px), Color("fff0a4"))
		draw_rect(Rect2(center + Vector2(2, -6) * px, Vector2(2, 2) * px), Color("ffd86d"))
