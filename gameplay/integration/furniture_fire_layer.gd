## Invisible, grid-aligned fuel for the room's bookshelf and table artwork.
## MaterialGrid owns every burning state, spread step, and burn timer.
class_name GameplayFurnitureFireLayer
extends Node

var _cells: Dictionary = {}  # Vector2i -> display name for projectile feedback.


func _ready() -> void:
	var grid: MaterialGrid = get_parent() as MaterialGrid
	if grid == null:
		return
	# Spark targets can land just above each platform. Keep those cells linked
	# to the body so a fire lit from above can propagate down through the art.
	_paint_rect(grid, 9, 20, 19, 30, "BOOKSHELF")
	_paint_rect(grid, 23, 37, 23, 25, "TABLE")
	# The open space below the tabletop stays AIR. The two legs connect its
	# surface to the lower stretcher and the wooden floor.
	_paint_rect(grid, 24, 25, 26, 30, "TABLE")
	_paint_rect(grid, 35, 36, 26, 30, "TABLE")
	_paint_rect(grid, 23, 37, 30, 30, "TABLE")


func covers_cell(cell: Vector2i) -> bool:
	return _cells.has(cell)


func furniture_at_cell(cell: Vector2i) -> String:
	return str(_cells.get(cell, ""))


func _paint_rect(grid: MaterialGrid, x_min: int, x_max: int, y_min: int, y_max: int, name: String) -> void:
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			if not grid.in_bounds(x, y):
				continue
			var cell := Vector2i(x, y)
			_cells[cell] = name
			grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)
