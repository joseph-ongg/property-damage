# onboarding/burn-box/paintbrush.gd
extends Node

@onready var grid: MaterialGrid = get_parent()
@onready var picker: OptionButton = $"../UI/HUD/MaterialPicker"


func _ready() -> void:
	picker.item_selected.connect(_on_material_selected)
	# TODO: add an item to `picker` for each material, plus Fire.


func _on_material_selected(index: int) -> void:
	pass  # TODO: remember which brush is selected.


# _unhandled_input means clicks on the HUD never reach here.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	var cell := grid.world_to_cell(grid.get_global_mouse_position())
	if not grid.in_bounds(cell.x, cell.y):
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pass  # TODO: paint the selected material at `cell`, or ignite it if Fire is selected.
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		pass  # TODO: paint stone at `cell`.
