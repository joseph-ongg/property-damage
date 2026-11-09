extends Control

# Add a new map here and a button appears automatically.
const MAPS := [
	{"name": "Living Room", "path": "res://gameplay/playtest_main.tscn"},
	{"name": "Garden", "path": "res://gameplay/LevelSelection/GardenPlaceholder.tscn"},
]

@onready var list: VBoxContainer = $CenterContainer/VBoxContainer


func _ready() -> void:
	list.add_theme_constant_override("separation", 20)  # space between buttons
	for map in MAPS:
		var button := Button.new()
		button.text = map["name"]
		button.custom_minimum_size = Vector2(360, 80)  # width, height
		button.add_theme_font_size_override("font_size", 32)
		button.pressed.connect(_load_map.bind(map["path"]))
		list.add_child(button)
	list.get_child(0).grab_focus()  # so the keyboard works right away


func _load_map(path: String) -> void:
	get_tree().change_scene_to_file(path)
