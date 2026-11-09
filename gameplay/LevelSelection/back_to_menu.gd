extends Node

const MENU_SCENE := "res://gameplay/LevelSelection/map_select.tscn"

@export var show_button: bool = true
@export var button_position: Vector2 = Vector2(12, 12)


func _ready() -> void:
	# Keep working even while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if show_button:
		_add_button()


func _add_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100  # draw above the HUD
	add_child(layer)
	var button := Button.new()
	button.text = "Back to Maps (M)"
	# Players press Enter/Space for gameplay, so the button must never grab focus.
	button.focus_mode = Control.FOCUS_NONE
	button.position = button_position
	button.pressed.connect(go_to_menu)
	layer.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_M:
		go_to_menu()


func go_to_menu() -> void:
	get_tree().paused = false  # don't carry a paused state into the menu
	get_tree().change_scene_to_file(MENU_SCENE)
