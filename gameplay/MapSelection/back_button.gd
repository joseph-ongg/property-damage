extends CanvasLayer

const MENU_SCENE := "res://gameplay/MapSelection/map_select.tscn"

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	$BackButton.pressed.connect(_go_back)

func _go_back() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
