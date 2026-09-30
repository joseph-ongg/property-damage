# onboarding/burn-box/paintbrush.gd
extends Node

const FIRE_BRUSH := -1

@onready var grid: MaterialGrid = get_parent()
var brush: int = MaterialGrid.Cell.WOOD  # a Cell value, or FIRE_BRUSH


func _unhandled_input(event: InputEvent) -> void:
	pass  # TODO (Bryan): _unhandled_input means clicks on the HUD never reach here.
	# Mouse position: grid.world_to_cell(grid.get_global_mouse_position()).
	# Left click/drag: set_cell(brush), or ignite() if brush == FIRE_BRUSH.
	# Right click/drag: set_cell(STONE).
	# Hook MaterialPicker's item_selected signal up to change `brush`.
