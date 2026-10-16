## Adapted from Jackson's real sim/jackson/burn-box-render @ c897a2e.
## Uses exactly his material/Fire colors and cell_changed signal, but draws
## low-opacity pixel markers over solid cells only. His unmodified original
## draws opaque AIR over the entire 960x540 Gameplay room and obscures the
## Design/Art teams' background. Rendering never stores or mutates fire.
class_name GameplayTeamMaterialRenderer
extends Node2D

@export_node_path("Node2D") var grid_path: NodePath
@export_range(0.0, 1.0, 0.05) var material_opacity: float = 0.25
@export_range(0.0, 1.0, 0.05) var fire_opacity: float = 0.62

var _grid: MaterialGrid
var refresh_count: int = 0

# Jackson's original material palette, including fire as an independent state.
const COLORS: Array[Color] = [
	Color(0.761, 0.758, 0.878, 0.5), # AIR (hidden in the room)
	Color(0.395, 0.167, 0.086, 1.0), # WOOD
	Color(0.409, 0.409, 0.409, 1.0), # STONE
	Color(0, 0, 0, 1.0),             # OIL
	Color(0.176, 0.176, 0.176, 1.0),# ASH
	Color(0, 0.435, 0.945, 1.0),   # WATER
]
const FIRE_COLOR := Color(1.0, 0.231, 0.027, 1.0)


func _ready() -> void:
	_grid = get_node_or_null(grid_path) as MaterialGrid
	if _grid == null:
		push_warning("Gameplay material renderer has no Simulation grid")
		return
	_grid.cell_changed.connect(_on_cell_changed)
	queue_redraw()


func _on_cell_changed(_x: int, _y: int) -> void:
	refresh_count += 1
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	var side: float = float(_grid.cell_size)
	for x in _grid.width:
		for y in _grid.height:
			var mat: int = int(_grid.get_cell_material(x, y))
			if mat == MaterialGrid.Materials.AIR:
				continue
			var burning := _grid.is_burning(x, y)
			var ink: Color = FIRE_COLOR if burning else COLORS[clampi(mat, 0, COLORS.size() - 1)]
			ink.a = fire_opacity if burning else material_opacity
			var top_left := Vector2(float(x), float(y)) * side
			# Readable individual material pixels without opaque block rectangles.
			draw_rect(Rect2(top_left, Vector2(side, maxf(2, side * 0.18))), ink)
			ink.a *= 0.50
			draw_rect(Rect2(top_left + Vector2(0, side - 2), Vector2(side, 2)), ink)
