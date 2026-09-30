# onboarding/burn-box/grid_renderer.gd
extends Node2D

@onready var grid: MaterialGrid = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()  # redraws every frame; swap for a signal from the grid if you add one


func _draw() -> void:
	var s := grid.cell_size
	for x in grid.width:
		for y in grid.height:
			var rect := Rect2(x * s, y * s, s, s)
			draw_rect(rect, Color(0.08, 0.08, 0.1))  # TODO: draw each cell based on what the grid stores
