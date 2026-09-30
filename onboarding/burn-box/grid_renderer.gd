# onboarding/burn-box/grid_renderer.gd
extends Node2D

@onready var grid: MaterialGrid = get_parent()

@export var colors: Dictionary = {
	MaterialGrid.Cell.AIR: Color(0.08, 0.08, 0.1),
	MaterialGrid.Cell.WOOD: Color.DARK_GRAY,  # TODO (Jackson): real colors
	MaterialGrid.Cell.STONE: Color.DARK_GRAY,
	MaterialGrid.Cell.OIL: Color.DARK_GRAY,
	MaterialGrid.Cell.ASH: Color.DARK_GRAY,
	MaterialGrid.Cell.WATER: Color.DARK_GRAY,
}
@export var textures: Dictionary = {}  # Cell -> Texture2D. Art's handoff point.
@export var burning_tint := Color(1.0, 0.45, 0.1, 0.6)


func _ready() -> void:
	grid.ticked.connect(queue_redraw)
	grid.cell_changed.connect(func(_x, _y, _m): queue_redraw())


func _draw() -> void:
	var s := grid.cell_size
	for x in grid.width:
		for y in grid.height:
			var m := grid.get_cell(x, y)
			var rect := Rect2(x * s, y * s, s, s)
			if textures.has(m):
				draw_texture_rect(textures[m], rect, false)
			else:
				draw_rect(rect, colors.get(m, Color.MAGENTA))
			if grid.is_burning(x, y):
				draw_rect(rect, burning_tint)  # TODO (Jackson): flicker it, if you have time
