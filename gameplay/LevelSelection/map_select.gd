extends Control

# Angela's map list remains the source of truth for scene destinations.
const MAPS := [
	{"name": "Living Room", "path": "res://gameplay/playtest_main.tscn"},
	{"name": "Garden", "path": "res://gameplay/LevelSelection/GardenPlaceholder.tscn"},
]
const Selection = preload("res://gameplay/characters/character_selection_state.gd")
const CHARACTER_OPTIONS: Array[String] = ["mage", "ninja", "werewolf"]

@onready var list: VBoxContainer = $CenterContainer/VBoxContainer
var player1_select: OptionButton
var player2_select: OptionButton


func _ready() -> void:
	list.add_theme_constant_override("separation", 12)
	_add_heading("Choose characters")
	player1_select = _add_character_picker("P1 · WASD", Selection.player1_kind)
	player2_select = _add_character_picker("P2 · Arrow Keys", Selection.player2_kind)
	_add_heading("Select map")
	for map in MAPS:
		var button := Button.new()
		button.text = map["name"]
		button.custom_minimum_size = Vector2(360, 62)
		button.add_theme_font_size_override("font_size", 25)
		button.pressed.connect(_load_map.bind(map["path"]))
		list.add_child(button)
	player1_select.grab_focus()


func _add_heading(value: String) -> void:
	var heading := Label.new()
	heading.text = value
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	list.add_child(heading)


func _add_character_picker(label_text: String, chosen: String) -> OptionButton:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 18)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(160, 42)
	label.add_theme_font_size_override("font_size", 18)
	line.add_child(label)
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(200, 42)
	for kind in CHARACTER_OPTIONS:
		picker.add_item(kind.capitalize())
		picker.set_item_metadata(picker.item_count - 1, kind)
	picker.select(maxi(0, CHARACTER_OPTIONS.find(chosen)))
	line.add_child(picker)
	list.add_child(line)
	return picker


func _load_map(path: String) -> void:
	var p1: String = str(player1_select.get_item_metadata(player1_select.selected))
	var p2: String = str(player2_select.get_item_metadata(player2_select.selected))
	if not Selection.choose(p1, p2):
		push_warning("Invalid character selection; remaining in menu")
		return
	get_tree().change_scene_to_file(path)
