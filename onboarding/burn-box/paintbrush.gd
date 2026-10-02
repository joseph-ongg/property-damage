# onboarding/burn-box/paintbrush.gd
extends Node

@onready var grid: MaterialGrid = get_parent()
@onready var picker: OptionButton = $"../UI/HUD/MaterialPicker"

var selected_brush  # selected material ID (wood, stone, air, etc)
var FIRE_ID: int = 1000

func _ready() -> void:
	# add an item to `picker` for each material, plus Fire.
	for item in MaterialGrid.Materials.keys(): 
		var material_id: int = MaterialGrid.Materials[item]
		picker.add_item(item.capitalize(), material_id)
		# Add item icon here in future?
	picker.add_item("FIRE", FIRE_ID)
	picker.item_selected.connect(_on_material_selected)
	
	picker.select(0) # Default to first material 
	selected_brush = picker.get_item_id(0)
	

func _on_material_selected(index: int) -> void:
	# On signal item_selected, set brush to material by id 
	selected_brush = picker.get_item_id(index)
	


# _unhandled_input means clicks on the HUD never reach here.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	var cell := grid.world_to_cell(grid.get_global_mouse_position())
	if not grid.in_bounds(cell.x, cell.y):
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# TODO: paint the selected material at `cell`, or ignite it if Fire is selected.
		if selected_brush == FIRE_ID:
			# for now assume ignite(x, y) exists, come back after implemented
			grid.ignite(cell.x, cell.y) 
		else: 
			grid.set_material(cell.x, cell.y, selected_brush)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# TODO: paint stone at `cell`.
		grid.set_material(cell.x, cell.y, MaterialGrid.Materials.STONE)
		
