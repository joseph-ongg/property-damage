extends Control

const ROOM_SCENE := "res://gameplay/playtest_main.tscn"
const GARDEN_SCENE := "res://gameplay/garden/garden_level.tscn"

var _launching: bool = false


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		get_window().content_scale_size = Vector2i(960, 540)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_make_label("PROPERTY DAMAGE", Vector2(79, 54), Vector2(700, 55), 42, Color("f8e8c7"))
	_make_label("CHOOSE A LEVEL", Vector2(82, 112), Vector2(500, 30), 18, Color("95d0b8"))
	_make_label("Two players  •  One spark-filled playground", Vector2(83, 143), Vector2(650, 25), 14, Color("bccbd0"))
	_make_label("LIVING ROOM", Vector2(137, 330), Vector2(300, 38), 25, Color("ffe1b8"))
	_make_label("Furniture, books and appliances", Vector2(138, 368), Vector2(300, 23), 14, Color("b5c4c6"))
	_make_label("GARDEN", Vector2(529, 330), Vector2(300, 38), 25, Color("e4f6b8"))
	_make_label("Burnable fence and tree", Vector2(530, 368), Vector2(300, 23), 14, Color("b5c4c6"))
	var room_button := _make_button("PLAY LIVING ROOM", Vector2(135, 412), Color("dfa66f"), ROOM_SCENE)
	_make_button("PLAY GARDEN", Vector2(527, 412), Color("94c76e"), GARDEN_SCENE)
	room_button.grab_focus()
	_make_label("WASD + ARROWS TO MOVE   •   F / ENTER TO SPARK   •   P / ESC TO PAUSE", Vector2(82, 495), Vector2(800, 25), 13, Color("a7b6b8"))
	queue_redraw()


func _make_label(value: String, location: Vector2, dimensions: Vector2, font_size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = location
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ink)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _make_button(value: String, location: Vector2, accent: Color, scene_path: String) -> Button:
	var button := Button.new()
	button.name = "LivingRoomButton" if scene_path == ROOM_SCENE else "GardenButton"
	button.text = value
	button.position = location
	button.size = Vector2(297, 56)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("17232b"))
	button.add_theme_color_override("font_hover_color", Color("0e1b21"))
	button.add_theme_color_override("font_focus_color", Color("17232b"))
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = accent.lightened(0.16) if state == "hover" else accent.darkened(0.15) if state == "pressed" else accent
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = Color.WHITE
			style.set_border_width_all(2)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(func() -> void: _launch(scene_path))
	add_child(button)
	return button


func _launch(scene_path: String) -> void:
	if _launching:
		return
	_launching = true
	get_tree().change_scene_to_file(scene_path)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("101c26"))
	draw_rect(Rect2(0, 0, 960, 7), Color("8cc7b0"))
	draw_circle(Vector2(882, 72), 108, Color("1c3440"))
	for card in [Rect2(115, 184, 340, 294), Rect2(507, 184, 340, 294)]:
		draw_rect(card, Color("1d2d37"))
		draw_rect(card, Color("48636a"), false, 2.0)
	# Living room thumbnail.
	draw_rect(Rect2(135, 205, 297, 113), Color("9b7774"))
	draw_rect(Rect2(135, 286, 297, 32), Color("604747"))
	draw_rect(Rect2(171, 249, 79, 48), Color("4b6d7c"))
	draw_rect(Rect2(184, 236, 53, 16), Color("b9c7b4"))
	draw_rect(Rect2(278, 260, 102, 32), Color("725a4e"))
	draw_rect(Rect2(304, 229, 52, 33), Color("334650"))
	draw_rect(Rect2(395, 231, 22, 59), Color("c3b899"))
	# Garden thumbnail, with fence, tree and rose arbor.
	draw_rect(Rect2(527, 205, 297, 113), Color("daece4"))
	draw_rect(Rect2(527, 289, 297, 29), Color("9bcf3b"))
	for y in [247, 274]:
		draw_rect(Rect2(527, y, 230, 8), Color("a1a58f"))
	for x in [556, 622, 697]:
		draw_rect(Rect2(x, 234, 13, 70), Color("a1a58f"))
	draw_rect(Rect2(753, 225, 33, 75), Color("66574b"))
	draw_circle(Vector2(765, 214), 46, Color("8abe22"))
	draw_rect(Rect2(542, 234, 6, 67), Color("6a8666"))
	draw_rect(Rect2(545, 231, 93, 7), Color("6a8666"))
	for x in range(550, 637, 18):
		draw_circle(Vector2(x, 230), 5, Color("d84b43"))
