## 测试地图的材料刷写器，不负责存储燃烧状态。
## 原存储：Ethan / Miao-Zinan，ethan/burn-box-grid @ 46c3df2。
## 中文：这里只决定哪些格子是 WOOD，点火/灭火仍由上游 MaterialGrid 完成。
extends Node

@export var legacy_all_wood: bool = false


func _ready() -> void:
	var grid: MaterialGrid = get_parent() as MaterialGrid
	if grid == null:
		return
	if legacy_all_wood:
		# 旧实验关卡：以前每格都是假木头，维持相同的测试目标。
		for x in grid.width:
			for y in grid.height:
				grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)
		return
	# 默认客厅：仅在地面以及实际家具附近刷上可燃材料。
	# 这是尚未完成真实家具/材料贴图前的关卡调试配置。
	for x in range(2, mini(grid.width, 59)):
		_paint_if_valid(grid, x, 29)
	_paint_band(grid, 9, 21, 20, MaterialGrid.Materials.WOOD) # 书架
	_paint_band(grid, 23, 37, 24, MaterialGrid.Materials.WOOD) # 桌子
	_paint_band(grid, 45, 53, 20, MaterialGrid.Materials.STONE) # 冰箱：不可燃
	_paint_if_valid(grid, 24, 29, MaterialGrid.Materials.OIL) # 少量实验油格


func _paint_band(grid: MaterialGrid, start: int, end: int, y: int, material: MaterialGrid.Materials) -> void:
	for x in range(start, end + 1):
		_paint_if_valid(grid, x, y, material)


func _paint_if_valid(grid: MaterialGrid, x: int, y: int, material: MaterialGrid.Materials = MaterialGrid.Materials.WOOD) -> void:
	if grid.in_bounds(x, y):
		grid.set_cell_material(x, y, material)
