# onboarding/burn-box/grid_renderer.gd
extends Node2D

@onready var grid: MaterialGrid = get_parent()

# Air, Stone, Wood, Oil, Ash, Water, Fire
var MatColors = {
	MaterialGrid.Materials.AIR: Color(0.761, 0.758, 0.878, 0.5),
	MaterialGrid.Materials.WOOD: Color(0.395, 0.167, 0.086, 1.0),
	MaterialGrid.Materials.STONE: Color(0.409, 0.409, 0.409, 1.0),
	MaterialGrid.Materials.OIL: Color(0,0,0,1.0),
	MaterialGrid.Materials.ASH: Color(0.176, 0.176, 0.176, 1.0),
	MaterialGrid.Materials.WATER: Color(0.0, 0.435, 0.945, 1.0),
	'FIRE': Color(1.0, 0.231, 0.027, 1.0)
}

func _ready() -> void:
	grid.cell_changed.connect(func(x, y): queue_redraw())

func _process(_delta: float) -> void:
	# queue_redraw()  # redraws every frame; swap for a signal from the grid if you add one
	pass


func _draw() -> void:
	print_debug("Drawn")
	var s := grid.cell_size
	for x in grid.width:
		for y in grid.height:
			var rect := Rect2(x * s, y * s, s, s)
			if not grid.is_burning(x, y):	
				draw_rect(rect, MatColors[grid.get_cell_material(x, y)])  # TODO: draw each cell based on what the grid stores
			else:
				draw_rect(rect, MatColors['FIRE'])

func draw_material():
	pass
