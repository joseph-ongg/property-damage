## Visual preferences only. Audio is outside this branch and owned by Art.
extends Control
const U = preload("res://gameplay/presentation/stylekit.gd")
const FILE := "user://property_damage_visual.cfg"

var fullscreen_toggle: CheckButton


func _ready() -> void:
    U.background(self, "help_backdrop.png")
    U.card(self, Vector2(111, 19), Vector2(738, 79), U.GOLD, 0.97)
    U.text(self, "VISUAL SETTINGS", Vector2(192, 33), Vector2(576, 63), 44, U.GOLD, true)
    U.card(self, Vector2(193, 142), Vector2(574, 238), U.LAVENDER)
    U.text(self, "DISPLAY MODE", Vector2(229, 185), Vector2(238, 33), 20, U.WHITE)
    fullscreen_toggle = CheckButton.new()
    fullscreen_toggle.name = "Fullscreen"
    fullscreen_toggle.text = "FULLSCREEN"
    fullscreen_toggle.position = Vector2(529, 180)
    fullscreen_toggle.button_pressed = _read_fullscreen()
    add_child(fullscreen_toggle)
    fullscreen_toggle.toggled.connect(_set_fullscreen)
    U.text(self, "Original pixel-art assets render with nearest-neighbor filtering.",
        Vector2(217, 260), Vector2(534, 34), 15, U.MUTED, true)
    U.text(self, "Audio settings remain with the Art & Audio subteam.",
        Vector2(222, 300), Vector2(520, 31), 14, U.GOLD, true)
    var back := U.button(self, "RETURN TO TITLE", Vector2(344, 430),
        Vector2(275, 44), U.TEAL)
    back.pressed.connect(_back)
    back.grab_focus()


func _read_fullscreen() -> bool:
    var cfg := ConfigFile.new()
    if cfg.load(FILE) == OK:
        return bool(cfg.get_value("display", "fullscreen", false))
    return false


func _set_fullscreen(enabled: bool) -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("display", "fullscreen", enabled)
    cfg.save(FILE)
    if DisplayServer.get_name() != "headless":
        DisplayServer.window_set_mode(
            DisplayServer.WINDOW_MODE_FULLSCREEN if enabled
            else DisplayServer.WINDOW_MODE_WINDOWED)


func _back() -> void:
    get_tree().change_scene_to_file("res://gameplay/presentation/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        _back()
